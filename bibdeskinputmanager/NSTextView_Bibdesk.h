//
//  NSTextView_Bibdesk.h
//  BibDeskInputManager
//
//  Created by Sven-S. Porst on Sat Jul 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSAppleScript+HandlerCalls.h"

extern NSString *BDSKInputManagerID;
#define noScriptErr 0

#warning Can you #define a localized string?
// string to reconise the string we inserted
#define kBibDeskInsertion NSLocalizedString(@" (Bibdesk insertion)", @" (Bibdesk insertion)")
// hint string 
#define kHint NSLocalizedString(@"Hint: Just type } or , to insert the current item.",@"Hint: Just type } or , to insert the current item.")


@interface NSTextView_Bibdesk: NSTextView
/*!
    @method     printSelectorList:
    @abstract   Print a list to standard output of all the selectors to which a class object responds.
                Used only for debugging at this time.
    @param      anObject The object of interest.  Note that [self super] will not get the superclass
                of self; you need to use [self superclass] for this.
*/
+ (void)printSelectorList:(id)anObject;
- (NSRange) citeKeyRange;
- (NSRange)rangeForUserCompletion;
- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index;
- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(int)movement isFinal:(BOOL)flag;

@end
