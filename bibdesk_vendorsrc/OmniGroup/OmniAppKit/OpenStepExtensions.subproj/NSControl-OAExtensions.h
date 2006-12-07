// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSControl-OAExtensions.h,v 1.10 2003/01/15 22:51:36 kc Exp $

#import <AppKit/NSControl.h>
#import <Foundation/NSDate.h>

@class NSMutableDictionary;

@interface NSControl (OAExtensions)

+ (NSTimeInterval)doubleClickDelay;

- (void)setCharacterWrappingStringValue:(NSString *)string;
- (NSMutableDictionary *)attributedStringDictionaryWithCharacterWrapping;

- (void)setStringValueIfDifferent:(NSString *)newString;

@end
