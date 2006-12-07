// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSTextStorage-OAExtensions.h,v 1.3 2003/01/15 22:51:39 kc Exp $

#import <AppKit/NSTextStorage.h>

@class NSNumber;

@interface NSTextStorage (OAExtensions)

- (BOOL)isUnderlined;
- (void)setIsUnderlined:(BOOL)value;
- (NSNumber *)superscriptLevel;
- (void)setSuperscriptLevel:(NSNumber *)value;
- (NSNumber *)baselineOffset;
- (void)setBaselineOffset:(NSNumber *)value;
- (int)textAlignment;
- (void)setTextAlignment:(int)value;

@end
