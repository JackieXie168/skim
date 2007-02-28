//
//  NSTextView_Bibdesk.m
//  BibDeskInputManager
//
//  Created by Sven-S. Porst on Sat Jul 17 2004.
/*
 This software is Copyright (c) 2004,2005,2006
 Sven-S. Porst. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Sven-S. Porst nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSTextView_Bibdesk.h"
#import <Foundation/Foundation.h>
#import <objc/objc-class.h>
#import <objc/Protocol.h>

NSString *BDSKInputManagerID = @"net.sourceforge.bibdesk.inputmanager";
NSString *BDSKInputManagerLoadableApplications = @"Application bundles that we recognize";

static NSString *BDSKInsertionString = nil;

static NSString *BDSKScriptName = @"Bibdesk";
static NSString *BDSKScriptType = @"scpt";
static NSString *BDSKHandlerName = @"getcitekeys";

extern void _objc_resolve_categories_for_class(struct objc_class *cls);

// The functions with an OB prefix are from OmniBase/OBUtilities.m
// and are covered by the Omni source license, and may only be used or
// reproduced in accordance with that license.
// http://www.omnigroup.com/developer/sourcecode/sourcelicense/

static IMP OBBDSKReplaceMethodImplementation(Class aClass, SEL oldSelector, IMP newImp)
{
    struct objc_method *thisMethod;
    IMP oldImp = NULL;
    extern void _objc_flush_caches(Class);
    
    if ((thisMethod = class_getInstanceMethod(aClass, oldSelector))) {
        oldImp = thisMethod->method_imp;
        
        // Replace the method in place
        thisMethod->method_imp = newImp;
        
        // Flush the method cache
        _objc_flush_caches(aClass);
    }
    
    return oldImp;
}

static IMP OBBDSKReplaceMethodImplementationWithSelector(Class aClass, SEL oldSelector, SEL newSelector)
{
    struct objc_method *newMethod;
    
    newMethod = class_getInstanceMethod(aClass, newSelector);
    NSCAssert(newMethod != nil, @"new method must not be nil");
    
    return OBBDSKReplaceMethodImplementation(aClass, oldSelector, newMethod->method_imp);
}

// The compiler won't allow us to call the IMP directly if it returns an NSRange, so I followed Apple's code at
// http://developer.apple.com/documentation/Performance/Conceptual/CodeSpeed/CodeSpeed.pdf
// See also the places where Omni uses OBReplaceMethod... calls in OmniAppKit, which is easier to follow.
static NSRange (*originalRangeIMP)(id, SEL) = NULL;
static void (*originalInsertIMP)(id, SEL, NSString *, NSRange, int, BOOL) = NULL;
static id (*originalCompletionsIMP)(id, SEL, NSRange, int *) = NULL;

@implementation NSTextView_Bibdesk

+ (void)load{
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // ARM: we just leak these strings; since the bundle only gets loaded once, it's not worth replacing dealloc
    if(BDSKInsertionString == nil)
        BDSKInsertionString = [NSLocalizedString(@" (Bibdesk)", @"") retain];

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier]; // for the app we are loading into
    NSArray *array = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:BDSKInputManagerID] objectForKey:BDSKInputManagerLoadableApplications];
  
    NSEnumerator *e = [array objectEnumerator];
    NSString *str;
    BOOL yn = NO;

    while(str = [e nextObject]){
        if([str caseInsensitiveCompare:bundleID] == NSOrderedSame){
            yn = YES;
            break;
        }
    }

    if(yn && [[self superclass] instancesRespondToSelector:@selector(completionsForPartialWordRange:indexOfSelectedItem:)]){
        
        // Class posing was cleaner and probably safer than swizzling, but led to unresolved problems with internationalized versions of TeXShop+OgreKit refusing text input for the Ogre find panel.  I think this is an OgreKit bug.
        originalInsertIMP = (typeof(originalInsertIMP))OBBDSKReplaceMethodImplementationWithSelector(self, @selector(insertCompletion:forPartialWordRange:movement:isFinal:), @selector(replacementInsertCompletion:forPartialWordRange:movement:isFinal:));
        originalRangeIMP = (typeof(originalRangeIMP))OBBDSKReplaceMethodImplementationWithSelector(self,@selector(rangeForUserCompletion),@selector(replacementRangeForUserCompletion));
        
        // have to replace this one since we don't call the delegate method from our implementation, and we don't want to override unless the user chooses to do so
        originalCompletionsIMP = (typeof(originalCompletionsIMP))OBBDSKReplaceMethodImplementationWithSelector(self, @selector(completionsForPartialWordRange:indexOfSelectedItem:),@selector(replacementCompletionsForPartialWordRange:indexOfSelectedItem:));
    }
    
    [pool release];
}

@end

@implementation NSTextView (BDSKCompletion)

#pragma mark -
#pragma mark Reference-searching heuristics

// ** Check to see if it's TeX
//  - look back to see if { ; if no brace, return not TeX
//  - if { found, look back between insertion point and { to find comma; check to see if it's BibTeX, then return the match range
// ** Check to see if it's BibTeX
//  - look back to see if it's jurabib with }{
//  - look back to see if ] ; if no options, then just find the citecommand (or not) by searching back from {
//  - look back to see if ][ ; if so, set ] range again
//  - look back to find [ starting from ]
//  - now we have the last [, see if there is a cite immediately preceding it using rangeOfString:@"cite" || rangeOfString:@"bibentry"
//  - if there were no brackets, but there was a double curly brace, then check for a jurabib citation
// ** After all of this, we've searched back to a brace, and then checked for a cite command with two optional parameters

- (BOOL)isBibTeXCitation:(NSRange)braceRange{
    
    NSString *str = [self string];
    NSRange citeSearchRange = NSMakeRange(NSNotFound, 0);
    NSRange doubleBracketRange = NSMakeRange(NSNotFound, 0);

    NSRange rightBracketRange = [str rangeOfString:@"]" options:NSBackwardsSearch | NSLiteralSearch range:SafeBackwardSearchRange(braceRange, 1)]; // see if there are any optional parameters

    // check for jurabib \citefield, which has two mandatory parameters in curly braces, e.g. \citefield[pagerange]{title}{cite:key}
    NSRange doubleBraceRange = [str rangeOfString:@"}{" options:NSBackwardsSearch | NSLiteralSearch range:SafeBackwardSearchRange( NSMakeRange(braceRange.location + 1, 1), 10)];
    
    if(rightBracketRange.location == NSNotFound && doubleBraceRange.location == NSNotFound){ // no options and not jurabib, so life is easy; look backwards 10 characters from the brace and see if there's a citecommand
        citeSearchRange = SafeBackwardSearchRange(braceRange, 20);
        if([str rangeOfString:@"cite" options:NSBackwardsSearch | NSLiteralSearch range:citeSearchRange].location != NSNotFound ||
           [str rangeOfString:@"bibentry" options:NSBackwardsSearch | NSLiteralSearch range:citeSearchRange].location != NSNotFound){
            return YES;
        } else {
            return NO;
        }
    }
    
    if(doubleBraceRange.location != NSNotFound) // reset the brace range if we have jurabib
        braceRange = [str rangeOfString:@"{" options:NSBackwardsSearch | NSLiteralSearch range:SafeBackwardSearchRange(doubleBraceRange, 10)];
    
    NSRange leftBracketRange = [str rangeOfString:@"[" options:NSBackwardsSearch | NSLiteralSearch range:SafeBackwardSearchRange(braceRange, 100)]; // first occurrence of it, looking backwards
    // next, see if we have two optional parameters; this range is tricky, since we have to go forward one, then do a safe backward search over the previous characters
    if(leftBracketRange.location != NSNotFound)
        doubleBracketRange = [str rangeOfString:@"][" options:NSBackwardsSearch | NSLiteralSearch range:SafeBackwardSearchRange( NSMakeRange(leftBracketRange.location + 1, 3), 3)]; 
    
    if(doubleBracketRange.location != NSNotFound) // if we had two parameters, find the last opening bracket
        leftBracketRange = [str rangeOfString:@"[" options:NSBackwardsSearch | NSLiteralSearch range:SafeBackwardSearchRange(doubleBracketRange, 50)];
    
    if(leftBracketRange.location != NSNotFound){
        citeSearchRange = SafeBackwardSearchRange(leftBracketRange, 20); // could be larger
        if([str rangeOfString:@"cite" options:NSBackwardsSearch | NSLiteralSearch range:citeSearchRange].location != NSNotFound ||
           [str rangeOfString:@"bibentry" options:NSBackwardsSearch | NSLiteralSearch range:citeSearchRange].location != NSNotFound){
            return YES;
        } else {
            return NO;
        }
    }
    
    if(doubleBraceRange.location != NSNotFound){ // jurabib with no options on it
        citeSearchRange = SafeBackwardSearchRange(braceRange, 20); // could be larger
        if([str rangeOfString:@"cite" options:NSBackwardsSearch | NSLiteralSearch range:citeSearchRange].location != NSNotFound ||
           [str rangeOfString:@"bibentry" options:NSBackwardsSearch | NSLiteralSearch range:citeSearchRange].location != NSNotFound){
            return YES;
        } else {
            return NO;
        }
    }        
    
    return NO;
}

- (NSRange)citeKeyRange{
    
    NSString *str = [self string];
    NSRange r = [self selectedRange]; // here's the insertion point
    NSRange commaRange;
    NSRange finalRange;
    unsigned maxLoc;

    NSRange braceRange = [str rangeOfString:@"{" options:NSBackwardsSearch | NSLiteralSearch range:SafeBackwardSearchRange(r, 100)]; // look for an opening brace
    NSRange closingBraceRange = [str rangeOfString:@"}" options:NSBackwardsSearch | NSLiteralSearch range:SafeBackwardSearchRange(r, 100)];
    
    if(closingBraceRange.location != NSNotFound && closingBraceRange.location > braceRange.location) // if our { has a matching }, don't bother
        return finalRange = NSMakeRange(NSNotFound, 0);

    if(braceRange.location != NSNotFound){ // may be TeX
        commaRange = [str rangeOfString:@"," options:NSBackwardsSearch | NSLiteralSearch range:NSUnionRange(braceRange, r)]; // exclude commas in the optional parameters
    } else { // definitely not TeX
         return finalRange = NSMakeRange(NSNotFound, 0);
    }

    if([self isBibTeXCitation:braceRange]){
        if(commaRange.location != NSNotFound && r.location > commaRange.location){
            maxLoc = ( (commaRange.location + 1 > r.location) ? commaRange.location : commaRange.location + 1 );
            finalRange = SafeForwardSearchRange(maxLoc, r.location - commaRange.location - 1, r.location);
        } else {
            maxLoc = ( (braceRange.location + 1 > r.location) ? braceRange.location : braceRange.location + 1 );
            finalRange = SafeForwardSearchRange(maxLoc, r.location - braceRange.location - 1, r.location);
        }
    } else {
        finalRange = NSMakeRange(NSNotFound, 0);
    }

    return finalRange;
}
                
- (NSRange)refLabelRange{
    
    NSString *s = [self string];
    NSRange r = [self selectedRange];
    NSRange searchRange = SafeBackwardSearchRange(r, 12);
    
    // look for standard \ref
    NSRange foundRange = [s rangeOfString:@"\\ref{" options:NSBackwardsSearch range:searchRange];
    
    if(foundRange.location == NSNotFound){
        
        // maybe it's a pageref
        foundRange = [s rangeOfString:@"\\pageref{" options:NSBackwardsSearch range:searchRange];
        
        // could also be an eqref (amsmath)
        if(foundRange.location == NSNotFound)
            foundRange = [s rangeOfString:@"\\eqref{" options:NSBackwardsSearch range:searchRange];
    }
    unsigned idx = NSMaxRange(foundRange);
    idx = (idx < r.location ? r.location - idx : 0);
    
    return NSMakeRange(NSMaxRange(foundRange), idx);
}

#pragma mark -
#pragma mark AppKit overrides

// Override usual behaviour so we can have dots, colons and hyphens in our cite keys
- (NSRange)rangeForBibTeXUserCompletion{
    
    NSRange range = [self citeKeyRange];
    return range.location == NSNotFound ? [self refLabelRange] : range;
}

static BOOL isCompletingTeX = NO;

// we replace this method since the completion controller uses it to update
- (NSRange)replacementRangeForUserCompletion{
    
    NSRange range = [self rangeForBibTeXUserCompletion];
    isCompletingTeX = range.location != NSNotFound;
    
    return range.location != NSNotFound ? range : originalRangeIMP(self, _cmd);
}

// this returns -1 instead of NSNotFound for compatibility with the completion controller indexOfSelectedItem parameter
static inline int
BDIndexOfItemInArrayWithPrefix(NSArray *array, NSString *prefix)
{
    unsigned idx, count = [array count];
    for(idx = 0; idx < count; idx++){
        if([[array objectAtIndex:idx] hasPrefix:prefix])
            return idx;
    }
    
    return -1;
}

// Provide own completions based on results by Bibdesk.  
// Should check whether Bibdesk is available first.  
// Setting initial selection in list to second item doesn't work.  
// Requires X.3
- (NSArray *)replacementCompletionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index{
    
	NSString *s = [self string];
    NSRange refLabelRange = [self refLabelRange];
    
    // don't bother checking for a citekey if this is a \ref
    NSRange keyRange = ( (refLabelRange.location == NSNotFound) ? [self citeKeyRange] : NSMakeRange(NSNotFound, 0) ); 
    NSMutableArray *returnArray = [NSMutableArray array];
    int n;

	if(keyRange.location != NSNotFound){
                
        NSString *end = [[s substringWithRange:keyRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		NSDictionary *errorInfo = nil;
		static NSAppleScript *script = nil;
        if(script == nil){
            NSURL *scriptURL = [NSURL fileURLWithPath:[[NSBundle bundleWithIdentifier:BDSKInputManagerID] pathForResource:BDSKScriptName ofType: BDSKScriptType]];
            script = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&errorInfo];
            if(errorInfo != nil){
                [script release];
                script = nil;
                NSLog(@"*** Failed to initialize script at URL %@ because of error %@", scriptURL, errorInfo);
            }
        }
		
		if (script && !errorInfo) {
			
			/* We have to construct an AppleEvent descriptor to contain the arguments for our handler call.  Remember that this list is 1, rather than 0, based. */
			NSAppleEventDescriptor *arguments = [[NSAppleEventDescriptor alloc] initListDescriptor];
			[arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithString:end] atIndex: 1] ;
			
			/* Call the handler using the method in our special NSAppleScript category */
			NSAppleEventDescriptor *result = [script callHandler: BDSKHandlerName withArguments: arguments errorInfo: &errorInfo];
			[arguments release];
            
			if (!errorInfo) {
				
				if (result &&  (n = [result numberOfItems])) {					
					NSAppleEventDescriptor *stringAEDesc;
					NSString *completionString;
					
					do {
						// run through the list top to bottom, keeping in mind it is 1 based.
						stringAEDesc = [result descriptorAtIndex:n];
						// insert 'identification string at end so we'll recognise our own completions in -insertCompletion:for...
						completionString = [[stringAEDesc stringValue] stringByAppendingString:BDSKInsertionString];
						
						// add in at beginning of array
						[returnArray insertObject:completionString atIndex:0];
					} while(--n);								
				} 
			} // no script running error	
            if(errorInfo) NSLog(@"*** Failed to run script %@ because of error %@", script, errorInfo);

		} // no script loading error
        if(errorInfo) NSLog(@"*** Failed to run script %@ because of error %@", script, errorInfo);
        
        *index = BDIndexOfItemInArrayWithPrefix(returnArray, end);

	} else if(refLabelRange.location != NSNotFound){
        NSString *hint = [s substringWithRange:refLabelRange];

        NSScanner *labelScanner = [[NSScanner alloc] initWithString:s];
        [labelScanner setCharactersToBeSkipped:nil];
        NSString *scanned = nil;
        NSMutableSet *setOfLabels = [NSMutableSet setWithCapacity:10];
        NSString *scanFormat;

        scanFormat = [@"\\label{" stringByAppendingString:hint];
        
        while(![labelScanner isAtEnd]){
            [labelScanner scanUpToString:scanFormat intoString:nil]; // scan for strings with \label{hint in them
            [labelScanner scanString:@"\\label{" intoString:nil];    // scan away the \label{
            [labelScanner scanUpToString:@"}" intoString:&scanned];  // scan up to the next brace
            if(scanned != nil) [setOfLabels addObject:[scanned stringByAppendingString:BDSKInsertionString]]; // add it to the set
        }
        [labelScanner release];
        // return the set as an array, sorted alphabetically
        [returnArray setArray:[[setOfLabels allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]]; 
        *index = BDIndexOfItemInArrayWithPrefix(returnArray, hint);
    } else {
        // return the spellchecker's guesses
        returnArray = (NSMutableArray *)[[NSSpellChecker sharedSpellChecker] completionsForPartialWordRange:charRange inString:s language:nil inSpellDocumentWithTag:[self spellCheckerDocumentTag]];
        *index = BDIndexOfItemInArrayWithPrefix(returnArray, [s substringWithRange:charRange]);        
    }
	return returnArray;
}

// for legacy reasons, rangeForUserCompletion gives us an incorrect range for replacement; since it's compatible with searching and I don't feel like changing all the range code, we'll fix it up here
- (void)fixRange:(NSRange *)range{    
    NSString *string = [self string];
    
    NSRange selRange = [self selectedRange];
    unsigned minLoc = ( (selRange.location > 100) ? 100 : selRange.location);
    NSRange safeRange = NSMakeRange(selRange.location - minLoc, minLoc);
    
    NSRange braceRange = [string rangeOfString:@"{" options:NSBackwardsSearch | NSLiteralSearch range:safeRange]; // look for an opening brace
    NSRange commaRange = [string rangeOfString:@"," options:NSBackwardsSearch | NSLiteralSearch range:safeRange]; // look for a comma
    unsigned maxLoc = [[self string] length];
    
    if(braceRange.location != NSNotFound && braceRange.location < range->location){
        // we found the brace, which must exist if we're here; if not, we won't adjust anything, though
        if(commaRange.location != NSNotFound && commaRange.location > braceRange.location)
            range->location = MIN(commaRange.location + 1, maxLoc);
        else
            range->location = MIN(braceRange.location + 1, maxLoc);
    }
}

// finish off the completion, inserting just the cite key
- (void)replacementInsertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(int)movement isFinal:(BOOL)flag {
    
    if(isCompletingTeX || [self refLabelRange].location != NSNotFound)
        [self fixRange:&charRange];

	if (flag == YES && ([word rangeOfString:BDSKInsertionString].location != NSNotFound)) {
        // this is one of our suggestions, so we need to trim it
        // strip the comment for this, this assumes cite keys can't have spaces in them
		NSRange firstSpace = [word rangeOfString:@" "];
		word = [word substringToIndex:firstSpace.location];
	}
    originalInsertIMP(self, _cmd, word, charRange, movement, flag);
}

@end
