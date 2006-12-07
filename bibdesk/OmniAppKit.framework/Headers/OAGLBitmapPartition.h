// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <OmniFoundation/OFObject.h>
#import <OmniAppKit/OAGL.h>

@class NSBitmapImageRep;

#define OAGL_MAX_TEXTURE_SIZE_POWER  (16)
#define OAGL_MAX_TEXTURE_SIZE        ((1<<OAGL_MAX_TEXTURE_SIZE_POWER) - 1)

@interface OAGLBitmapPartition : OFObject
{
    unsigned int rows, columns;
    unsigned int widths[OAGL_MAX_TEXTURE_SIZE_POWER];
    unsigned int heights[OAGL_MAX_TEXTURE_SIZE_POWER];
    GLenum format;
    GLuint *textureNames;
    void **textureBytes;
}


- initWithBitmap: (NSBitmapImageRep *) bitmap;

- (void) draw;

@end
