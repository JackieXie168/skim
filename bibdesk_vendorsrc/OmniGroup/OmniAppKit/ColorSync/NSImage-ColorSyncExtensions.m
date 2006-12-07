// Copyright 2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSImage-ColorSyncExtensions.h"
#import "OAColorProfile.h"
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>
#import <OmniBase/assertions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/ColorSync/NSImage-ColorSyncExtensions.m,v 1.2 2003/04/08 20:44:53 kc Exp $");

@implementation NSImage (ColorSyncExtensions)

- (BOOL)containsProfile;
{
    NSArray *representations = [self representations];
    int index = [representations count];
    
    while (index--) {
        NSBitmapImageRep *bitmap = [representations objectAtIndex:index];
        
        if ([bitmap isKindOfClass:[NSPDFImageRep class]])
            return YES;
            
        if (![bitmap isKindOfClass:[NSBitmapImageRep class]])
            continue;
        return [bitmap valueForProperty:NSImageColorSyncProfileData] != nil;
    }
    return NO;
}

- (void)_convertUsingColorWorld:(CMWorldRef)world;
{
    NSArray *representations = [self representations];
    int index = [representations count];

    while (index--) {
        NSBitmapImageRep *bitmap = [representations objectAtIndex:index];
        CMBitmap cmBitmap;
        
        if (![bitmap isKindOfClass:[NSBitmapImageRep class]])
            continue;
        
        if ([bitmap valueForProperty:NSImageColorSyncProfileData] != nil)
            return;
            
        OBASSERT(![bitmap isPlanar]);
        
        cmBitmap.image = [bitmap bitmapData];
        cmBitmap.width = [bitmap pixelsWide];
        cmBitmap.height = [bitmap pixelsHigh];
        cmBitmap.rowBytes = [bitmap bytesPerRow];
        cmBitmap.pixelSize = [bitmap bitsPerPixel];
        if (![bitmap hasAlpha]) {
            switch([bitmap bitsPerSample]) {
            case 5:
                cmBitmap.space = cmRGB16Space; break;
            case 8:
                cmBitmap.space = [bitmap bitsPerPixel] == 24 ? cmRGB24Space : cmRGB32Space; break;
            default:
                OBASSERT_NOT_REACHED("don't know how to support this sample size");
            }
        } else {
            OBASSERT([bitmap bitsPerSample] == 8);
            cmBitmap.space = cmRGBA32PmulSpace;
        }
        cmBitmap.user1 = 0;
        cmBitmap.user2 = 0;

        CWMatchBitmap(world, &cmBitmap, NULL, NULL, NULL);//&cmNewBitmap);
        break;
    }
}

- (void)convertFromProfile:(OAColorProfile *)inProfile toProfile:(OAColorProfile *)outProfile;
{
    CMWorldRef world = [inProfile _rgbConversionWorldForOutput:outProfile];
    
    if (!world)
        return;
    [self _convertUsingColorWorld:world];
}

@end

