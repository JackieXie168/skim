// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSTextStorage-OAExtensions.h,v 1.7 2004/02/10 04:07:35 kc Exp $

#import <AppKit/NSTextStorage.h>

#import <OmniAppKit/OAFindPattern.h>

@class NSNumber, NSScriptCommand;

@interface NSTextStorage (OAExtensions)

- (NSUndoManager *)undoManager;

//  Older non-OAStyle stuff (see NSTextStorage-OAStyleExtensions.[hm])
- (BOOL)isUnderlined;
- (void)setIsUnderlined:(BOOL)value;
- (NSNumber *)superscriptLevel;
- (void)setSuperscriptLevel:(NSNumber *)value;
- (NSNumber *)baselineOffset;
- (void)setBaselineOffset:(NSNumber *)value;
- (int)textAlignment;
- (void)setTextAlignment:(int)value;

// Regex stuff
+ (NSObject <OAFindPattern>*)findPatternForReplaceCommand:(NSScriptCommand *)command;
- (void)replaceUsingPattern:(NSObject <OAFindPattern>*)aPattern;

@end
