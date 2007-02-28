// Copyright 2004-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/ColorSync/OAColorSpace.h 66043 2005-07-25 21:17:05Z kc $

#import <AppKit/NSColor.h>
#import <OmniAppKit/FrameworkDefines.h>
#import <ApplicationServices/ApplicationServices.h>

@interface OAColorSpace : NSObject <NSCoding>
{
    NSArray *componentNames;
    NSString *spaceName;
}

// API
+ newFromICCData:(NSData *)iccData cache:(NSMutableDictionary *)profileCache;
+ newFromCMProfile:(CMProfileRef)cmProfile cache:(NSMutableDictionary *)profileCache;

- (int)numberOfComponents;
- (NSArray *)componentNames;
- (NSString *)name;
- (OSType)colorSpaceType;

- (NSColor *)colorFromPropertyListRepresentation:(NSDictionary *)dict;
- (NSColor *)colorFromCMColor:(CMColor)aColor;

@end


@interface OAContinuousColorSpace : OAColorSpace
{
    CGColorSpaceRef cgColorSpace;
    OSType geom;
}

- initWithCGColorSpace:(CGColorSpaceRef)colorSpace inputSpace:(OSType)inputSpace name:(NSString *)name;

- (NSColor *)colorWithComponents:(const float *)components;
- (void)setColorWithComponents:(const float *)components;

- (CGColorSpaceRef)cgColorSpace;

@end


@interface OADiscreteColorSpace : OAColorSpace
{
    CMProfileRef cmColorSpace;
    OAContinuousColorSpace *connectionSpace;
    unsigned int colorCount;
    CFStringRef descriptionPrefix, descriptionSuffix;
}

- initWithCMProfile:(CMProfileRef)colorTable cache:(NSMutableDictionary *)profileCache;

- (NSColor *)colorWithName:(NSString *)colorName;
- (NSColor *)colorWithIndex:(unsigned int)colorIndex;

- (NSArray *)colorNames;

@end

OmniAppKit_EXTERN NSString *OAColorSyncException;


