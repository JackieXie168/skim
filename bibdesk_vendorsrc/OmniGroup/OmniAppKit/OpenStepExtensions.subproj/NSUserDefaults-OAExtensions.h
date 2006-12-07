// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSUserDefaults-OAExtensions.h,v 1.5 2003/01/15 22:51:39 kc Exp $

#import <Foundation/NSUserDefaults.h>
#import <OmniFoundation/OFPreference.h>

#import <AppKit/NSColor.h>

@interface NSUserDefaults (OAExtensions)
- (NSColor *)colorForKey:(NSString *)defaultName;
- (NSColor *)grayForKey:(NSString *)defaultName;

- (void)setColor:(NSColor *)color forKey:(NSString *)defaultName;
- (void)setGray:(NSColor *)gray forKey:(NSString *)defaultName;
@end


@interface OFPreferenceWrapper (OAExtensions)
- (NSColor *)colorForKey:(NSString *)defaultName;
- (NSColor *)grayForKey:(NSString *)defaultName;

- (void)setColor:(NSColor *)color forKey:(NSString *)defaultName;
- (void)setGray:(NSColor *)gray forKey:(NSString *)defaultName;
@end


