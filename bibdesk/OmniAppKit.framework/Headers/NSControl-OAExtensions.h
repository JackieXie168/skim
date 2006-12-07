// Copyright 1998-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <AppKit/NSControl.h>
#import <Foundation/NSDate.h>

@class NSMutableDictionary;

@interface NSControl (OAExtensions)

+ (NSTimeInterval)doubleClickDelay;

- (void)setCharacterWrappingStringValue:(NSString *)string;
- (NSMutableDictionary *)attributedStringDictionaryWithCharacterWrapping;

- (void)setStringValueIfDifferent:(NSString *)newString;

@end
