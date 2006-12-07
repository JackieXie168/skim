// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAFontCache.h,v 1.14 2004/02/10 04:07:31 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSFont;

typedef struct {
    float size;
    unsigned int bold:1;
    unsigned int italic:1;
} OAFontAttributes;

@interface OAFontCache : OFObject

+ (void)refreshFontSubstitutionDefaults;

+ (NSString *)fontFamilyMatchingName:(NSString *)fontFamily;
+ (NSFont *)fontWithFamily:(NSString *)aFamily attributes:(OAFontAttributes)someAttributes;
+ (NSFont *)fontWithFamily:(NSString *)aFamily size:(float)size bold:(BOOL)bold italic:(BOOL)italic;
+ (NSFont *)fontWithFamily:(NSString *)aFamily size:(float)size;

@end
