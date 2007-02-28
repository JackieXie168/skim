// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OAFontCache.h 68913 2005-10-03 19:36:19Z kc $

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
