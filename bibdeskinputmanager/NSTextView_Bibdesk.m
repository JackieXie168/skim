//
//  NSTextView_Bibdesk.m
//  BibDeskInputManager
//
//  Created by Sven-S. Porst on Sat Jul 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NSTextView_Bibdesk.h"
#import <Foundation/Foundation.h>
#import </usr/include/objc/objc-class.h>
#import </usr/include/objc/Protocol.h>

static BOOL debug = NO;

NSString *BDSKInputManagerID = @"net.sourceforge.bibdesk.inputmanager";

static NSString *kScriptName = @"Bibdesk";
static NSString *kScriptType = @"scpt";
static NSString *kHandlerName = @"getcitekeys";

extern void _objc_resolve_categories_for_class(struct objc_class *cls);

@implementation NSTextView_Bibdesk

+ (void)load{
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier]; // for the app we are loading into
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *array = [NSArray arrayWithContentsOfFile:[libraryPath stringByAppendingPathComponent:@"/Application Support/BibDeskInputManager/EnabledApplications.plist"]];

    if(debug) NSLog(@"We should enable for %@", [array description]);
  
    NSEnumerator *e = [array objectEnumerator];
    NSDictionary *dict;
    BOOL yn = NO;
    
    while(dict = [e nextObject]){
	if([[dict objectForKey:@"BundleID"] isEqualToString:bundleID]){
	    if(debug) NSLog(@"Found a match; enabling autocompletion for %@",[dict description]);
	    yn = YES;
	    break;
	}
    }

    if(yn && [[self superclass] instancesRespondToSelector:@selector(completionsForPartialWordRange:indexOfSelectedItem:)]){
	if(debug) NSLog(@"%@ performing posing for %@", [self class], [self superclass]);
	[self poseAsClass:[NSTextView class]];
	if(debug) [self printSelectorList:[self superclass]];
    }
    
    [pool release];
}

+ (void)printSelectorList:(id)anObject{
    int k = 0;
    void *iterator = 0;
    struct objc_method_list *mlist;
        
    _objc_resolve_categories_for_class([anObject class]);
        
    while( mlist = class_nextMethodList( [anObject class], &iterator ) ){
	for(k=0; k<mlist->method_count; k++){
	     NSLog(@"%@ implements %s",[anObject class], mlist->method_list[k].method_name);
	    if( strcmp( sel_getName(mlist->method_list[k].method_name), "complete:") == 0 ){
		NSLog(@"found a complete: selector with imp (0x%08x)", (int)(mlist->method_list[k].method_imp) );
	    }
	}
    }
}

/* ssp: 2004-07-18
1. Determines whether we are in a cite key context, returns (NSNotFound,0) range otherwise
This will determine any cite command beginning with \cite as well as \fullcite and \bibentry.
Are any others needed?
2. Determines cite key to be completed and returns its range
The cite key will be the text (no spaces) between the insertion point and the next { or , preceding it.
	
The heuristics we use here aren't particularly good. Neither the idea nor the implementation. Basically we simply see whether there was a \cite command recently (within 100 characters) and assume it's ours then. Determining whether we _really_ are in the right context for this seems quite hard as \cite commands can have space, newlines, optional parameters wiht about everything in them.
However, we will simply add the usual completions after our own for safety...
*/
- (NSRange) citeKeyRange {
    NSString * s = [[self textStorage] string];
    int sLen = [s length];
    NSRange r = [self selectedRange];
    int locDiff = 100 - r.location;
    if (locDiff < 0 ) { locDiff = 0; }
    int r2Loc = r.location - 100 + locDiff;
    int r2Len = 100 - locDiff;
    NSRange r2 = NSMakeRange(r2Loc, r2Len);
    
    NSRange backslash = [s rangeOfString:@"\\" options:NSBackwardsSearch range:r2];
    if (backslash.location != NSNotFound) {
	// we've got a backslash
	NSRange cite;
	if (backslash.location + 5 <= sLen) {
	    // string is long enough to avoid range exception
	    cite = [s rangeOfString:@"\\cite" options:NSAnchoredSearch range:NSMakeRange(backslash.location,5)];
	    if ((cite.location == NSNotFound) && (backslash.location + 9 <= sLen)) {
		// make sure there is even more space for matching the longer strings
		cite = [s rangeOfString:@"\\fullcite" options:NSAnchoredSearch range:NSMakeRange(backslash.location,9)];
		if (cite.location == NSNotFound) {
		    // last chance...
		    cite = [s rangeOfString:@"\\bibentry" options:NSAnchoredSearch range:NSMakeRange(backslash.location,9)];
		}
	    }
	    
	    if (cite.location != NSNotFound) {
		// we've found some cite command
		NSRange comma = [s rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@", \n{"] options:NSBackwardsSearch range:r2];
		if (comma.location !=NSNotFound) {
		    // We're pretty sure now we've got the correct partial citekey
		    return NSMakeRange(comma.location+1,r.location-comma.location-1);
		} // comma found
	    } // cite command found
	} // string long enough
    } // backslash found
    return NSMakeRange(NSNotFound,0);
}


/* ssp: 2004-07-18
Override usual behaviour so we can have dots, colons and hyphens in our cite keys
requires X.3
*/
- (NSRange)rangeForUserCompletion {
    NSRange r = [self citeKeyRange];
    if (r.location != NSNotFound) {
	return r;
    }
    return [super rangeForUserCompletion];
}


/* ssp: 2004-07-18
Provide own completions based on results by Bibdesk
Should check whether Bibdesk is available first
setting initial selection in list to second item doesn't work
requires X.3
*/
- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index	{
	NSString * s = [[self textStorage] string];
	NSRange r = [self citeKeyRange];
	
	if (r.location != NSNotFound ){
		//	NSString * beginning = [s substringWithRange:NSMakeRange(charRange.location - 6, 6)];
		NSString * end = [s substringWithRange:r];
		
		// code shamelessly lifted from Buzz Anderson's ASHandlerTest example app
		// Performance gain if we stored the script permanently? But where to store it?
		/* Locate the script within the bundle */
		NSString *scriptPath = [[NSBundle bundleWithIdentifier:BDSKInputManagerID] pathForResource:kScriptName ofType: kScriptType];
		NSURL *scriptURL = [NSURL fileURLWithPath: scriptPath];
		
		NSDictionary *errorInfo = nil;
		NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&errorInfo] autorelease];
		
		/* See if there were any errors loading the script */
		if (script && !errorInfo) {
			
			/* We have to construct an AppleEvent descriptor to contain the arguments for our handler call.  Remember that this list is 1, rather than 0, based. */
			NSAppleEventDescriptor *arguments = [[[NSAppleEventDescriptor alloc] initListDescriptor] autorelease];
			[arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithString:end] atIndex: 1] ;
			
			errorInfo = nil;
			
			/* Call the handler using the method in our special NSAppleScript category */
			NSAppleEventDescriptor *result = [script callHandler: kHandlerName withArguments: arguments errorInfo: &errorInfo];
			
			if (!errorInfo ) {
				
				int n;
				
				if (result &&  (n = [result numberOfItems])) {
					// start with the system's standard completions
					NSMutableArray * returnArray = [[[super completionsForPartialWordRange:charRange indexOfSelectedItem:index] mutableCopy] autorelease];
					
					NSAppleEventDescriptor * stringAEDesc;
					NSString * completionString;
					
					while (n) {
						// run through the list top to bottom, keeping in mind it is 1 based.
						stringAEDesc = [result descriptorAtIndex:n];
						// insert 'identification string at end so we'll recognise our own completions in -insertCompletion:for...
						completionString = [[stringAEDesc stringValue] stringByAppendingString:kBibDeskInsertion];
						
						n--;
						// add in at beginning of array
						[returnArray insertObject:completionString atIndex:0];
					}			
					
					if ([returnArray count]  == 1) {
						// if we have only one item for completion, artificially add a second one, so the user can review the full information before adding it to the document.
						[returnArray addObject:kHint];
						//  also set the index to 1, so the 'heading' line isn't selected initially.
						// THIS DOESN'T SEEM TO WORK!
						// *index = 1;
					}
					
					return returnArray;
				} 
			} // no script running error	
		} // no script loading error
	} // location > 5
	// if in doubt just stick to ordinary completion dictionary
	return [super completionsForPartialWordRange:charRange indexOfSelectedItem:index];
}



/* ssp: 2004-07-18
finish off the completion, inserting just the cite key
requires X.3
*/
- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(int)movement isFinal:(BOOL)flag {
    
	if (!flag || ([word rangeOfString:kBibDeskInsertion].location == NSNotFound)) {
		// this is just a preliminary completion (suggestion) or the word wasn't suggested by us anyway, so let the text system deal with this
		[super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
	}
	else {
		// final step
		
		/*
		 doesn't work
		if([word isEqualToString:kHint]) {
			// don't do anything if we get the heading 
			[super insertCompletion:@"" forPartialWordRange:charRange movement:NSCancelTextMovement isFinal:YES];
			return;
		}
		*/
	
		// strip the comment for this, this assumes cite keys can't have spaces in them
		NSRange firstSpace = [word rangeOfString:@" "];
		NSString * replacementString = [word substringToIndex:firstSpace.location];
		// add a little twist, so we can end completion by entering }
		// sadly NSCancelTextMovement  and NSOtherTextMovement both are 0, so we can't really tell the difference from movement alone
		int newMovement = movement;
		NSEvent * theEvent = [NSApp currentEvent];
		if ((movement == 0) && ([theEvent type] == NSKeyDown)) {
			// we've got a key event
			if ([[theEvent characters] isEqualToString:@"}"]) {
				// with a closing bracket 
				newMovement = NSRightTextMovement;
			}
		}			
		
		[super insertCompletion:replacementString forPartialWordRange:charRange movement:newMovement isFinal:flag];
	}

}

@end
