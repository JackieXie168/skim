// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSUserDefaults-OAExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSUserDefaults.h>
#import <OmniFoundation/OFPreference.h>

#import <AppKit/NSColor.h>

@class NSFontDescriptor;

@interface NSUserDefaults (OAExtensions)
- (NSColor *)colorForKey:(NSString *)defaultName;
- (NSColor *)grayForKey:(NSString *)defaultName;

- (void)setColor:(NSColor *)color forKey:(NSString *)defaultName;
- (void)setGray:(NSColor *)gray forKey:(NSString *)defaultName;
@end

@interface OFPreference (OAExtensions)
- (NSColor *)colorValue;
- (void)setColorValue:(NSColor *)color;
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
- (NSFontDescriptor *)fontDescriptorValue;
- (void)setFontDescriptorValue:(NSFontDescriptor *)fontDescriptor;
#endif
@end

@interface OFPreferenceWrapper (OAExtensions)
- (NSColor *)colorForKey:(NSString *)defaultName;
- (NSColor *)grayForKey:(NSString *)defaultName;

- (void)setColor:(NSColor *)color forKey:(NSString *)defaultName;
- (void)setGray:(NSColor *)gray forKey:(NSString *)defaultName;
@end


