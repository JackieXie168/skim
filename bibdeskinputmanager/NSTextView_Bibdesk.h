//
//  TextView+BD.h
//  TeXShop
//
//  Created by Sven-S. Porst on Sat Jul 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSAppleScript+HandlerCalls.h"

#define kScriptName (@"Bibdesk")
#define kScriptType (@"scpt")
#define kHandlerName (@"getcitekeys")
#define noScriptErr 0


@interface NSTextView_Bibdesk: NSTextView
- (NSRange) citeKeyRange;
- (NSRange)rangeForUserCompletion;
- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index;
- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(int)movement isFinal:(BOOL)flag;

@end
