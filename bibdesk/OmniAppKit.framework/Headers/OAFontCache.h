// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <OmniFoundation/OFObject.h>

@class NSFont;

typedef struct {
    float size;
    unsigned int bold:1;
    unsigned int italic:1;
} OAFontAttributes;

@interface OAFontCache : OFObject

+ (NSString *)fontFamilyMatchingName:(NSString *)fontFamily;
+ (NSFont *)fontWithFamily:(NSString *)aFamily attributes:(OAFontAttributes)someAttributes;
+ (NSFont *)fontWithFamily:(NSString *)aFamily size:(float)size bold:(BOOL)bold italic:(BOOL)italic;
+ (NSFont *)fontWithFamily:(NSString *)aFamily size:(float)size;

@end
