//
//  TextView+BD.m
//  TeXShop
//
//  Created by Sven-S. Porst on Sat Jul 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NSTextView_Bibdesk.h"


@implementation NSTextView_Bibdesk

+ (void)load{
    [self poseAsClass:[NSTextView class]];
}

/* ssp: 2004-07-18
1. Determines whether we are in a cite key context, returns (NSNotFound,0) range otherwise
This will determine any cite command beginning with \cite as well as \fullcite and \bibentry.
Are any others needed?
2. Determines cite key to be completed and returns its range
The cite key will be the text (no spaces) between the insertion point and the next { or , preceding it.
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
	NSString *scriptPath = [[NSBundle bundleWithIdentifier:@"net.sourceforge.bibdesk.inputmanager"] pathForResource:kScriptName ofType: kScriptType];
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
		    NSMutableArray * returnArray = [NSMutableArray arrayWithCapacity:2];
		    if (n == 1) {
			// if we have only one item for completion, artificially add a second one, so the user can review the full information before adding it to the document.
			[returnArray addObject:NSLocalizedString(@"Hint: Just type } or , to insert the current item.",@"Hint: Just type } or , to insert the current item.")];
			//  also set the index to 1, so the 'heading' line isn't selected initially.
			// THIS DOESN'T SEEM TO WORK!
			*index = 1;
		    }
		    
		    NSAppleEventDescriptor * stringAEDesc;
		    NSString * completionString;
		    
		    while (n) {
			// run through the list top to bottom, keeping in mind it is 1 based.
			stringAEDesc = [result descriptorAtIndex:n];
			completionString = [stringAEDesc stringValue];
			
			n--;
			
			[returnArray insertObject:completionString atIndex:0];
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
    
    if (!flag) {
	// this is just a preliminary completion (suggestion)
	[super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
    } 
    else {
	// final step
	if([word isEqualToString:NSLocalizedString(@"Matching publications:",@"Matching publications:")]) {
	    // don't do anything if we get the heading
	    [super insertCompletion:@"" forPartialWordRange:charRange movement:NSCancelTextMovement isFinal:YES];
	    return;
	}
	
	if ((movement == NSReturnTextMovement) || (movement == NSRightTextMovement) || (movement == NSLeftTextMovement) || ( movement == NSTabTextMovement) || ( movement == NSBacktabTextMovement) ||[[[NSApp currentEvent] characters] isEqualToString:@"}"]) {
	    // we actually want to insert
	    
	    // strip the comment for this, this assumes cite keys can't have spaces in them
	    NSRange firstSpace = [word rangeOfString:@" "];
	    NSString * replacementString = [word substringToIndex:firstSpace.location];
	    
	    // [[[self textStorage] mutableString] replaceCharactersInRange:NSMakeRange(charRange.location,[word length]) withString:replacementString];
	    [super insertCompletion:replacementString forPartialWordRange:charRange movement:movement isFinal:flag];
	}
	else {
	    // in case of cancellation act as usual.
	    [super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
	}
    }
}

@end
