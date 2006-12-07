// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OAGLBitmapPartition.h>

#import <AppKit/NSBitmapImageRep.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDate.h>
#import <string.h>

#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenGL/OAGLBitmapPartition.m,v 1.5 2003/01/15 22:51:35 kc Exp $")

#define SUBTEX(column,row) ((row)*columns + (column))

//#define SAVE_SLICES

#ifdef SAVE_SLICES
#import <AppKit/NSGraphics.h>
#import <Foundation/NSData.h>
#endif

static inline unsigned int _buildSlices(unsigned int *sizes, unsigned int totalSize)
{
    unsigned int count     = 0;
    unsigned int sliceSize = 1 << OAGL_MAX_TEXTURE_SIZE_POWER;
    
    while (totalSize) {
        if (totalSize & sliceSize) {
            totalSize -= sliceSize;
            sizes[count] = sliceSize;
            count++;
        }
        
        sliceSize >>= 1;
    }
    
    return count;
}

static inline void _copyRGBA32ToRGB24(unsigned char *dst, unsigned char *src, unsigned int pixels)
{
    while (pixels--) {
        dst[0] = src[0];
        dst[1] = src[1];
        dst[2] = src[2];
        dst += 3;
        src += 4;
    }
}


static inline unsigned char *_extractSubRect32(unsigned char *image, NSSize size, NSRect subRect)
{
    unsigned char *subImage, *subRow, *imageRow;
    unsigned int subRowSize, imageRowSize;
    unsigned int width, height;
    
    subImage = NSZoneMalloc(NULL, NSWidth(subRect) * NSHeight(subRect) * 3);
    return subImage;
    
    subRow = subImage;
    imageRow = image;
    imageRow += (unsigned int)((size.height - NSMaxY(subRect)) * size.width) * 4;
    imageRow += (unsigned int)NSMinX(subRect) * 4;
    width = NSWidth(subRect);
    height = NSMaxY(subRect) - NSMinY(subRect);
    subRowSize = width * 3;
    imageRowSize = size.width * 4;
    
//    NSLog(@"size = %@, subRect = %@", NSStringFromSize(size), NSStringFromRect(subRect));
//    NSLog(@"width = %d, height = %d", width, height);
//    NSLog(@"subRowSize = %d, imageRowSize = %d", subRowSize, imageRowSize);
    
    while (height--) {
        _copyRGBA32ToRGB24(subRow, imageRow, width);
        //memmove(subRow, imageRow, subRowSize);
        subRow += subRowSize;
        imageRow += imageRowSize;
    }

#ifdef SAVE_SLICES
    {
        NSBitmapImageRep *slice;
        
        slice = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: &subImage
                    pixelsWide: NSWidth(subRect)
                    pixelsHigh: NSHeight(subRect)
                    bitsPerSample: 8
                    samplesPerPixel: 3
                    hasAlpha: NO
                    isPlanar: NO
                    colorSpaceName: NSDeviceRGBColorSpace
                    bytesPerRow: 0
                    bitsPerPixel: 0];
        [[slice TIFFRepresentation] writeToFile: [NSString stringWithFormat: @"/tmp/%dx%d.tiff", (int)NSMinX(subRect), (int)NSMinY(subRect)] atomically: YES];
    }
#endif
    
    return subImage;
}


/*" GL textures must be a power of two on each side (not necessarily the same power of two).  Also, each GL implementation has a maximum texture size.  This class will allow us to represent an arbitrary bitmap as a GL texture for simple use by breaking down the input texture into power of two sized blocks.  Note that we could also choose to have textures that are bigger than what we need and issue texture coordinates that are less than 1 to only get the valid part of the texture, but this approach uses less texture memory and we need to be able to divide the texture into multiple blocks anyway in case the GL implementation limit on texture size is too small for our bitmap to be represented in one texture. "*/
@implementation OAGLBitmapPartition

- initWithBitmap: (NSBitmapImageRep *) bitmap;
{
    NSSize size;
    unsigned int row, column, x, y;
    unsigned char *bitmapBytes;
    GLsizei maxTextureSize;
    
    size = [bitmap size];
    if (size.width > OAGL_MAX_TEXTURE_SIZE || size.height > OAGL_MAX_TEXTURE_SIZE) {
        [self release];
        [NSException raise: NSInvalidArgumentException
                    format: @"Supplied bitmap size of %dx%d exceeds limit of %d.",
                            (int)size.width, (int)size.height, OAGL_MAX_TEXTURE_SIZE];
    }
    
#ifdef SAVE_SLICES
    [[bitmap TIFFRepresentation] writeToFile: @"/tmp/source.tiff" atomically: YES];
#endif

    rows = _buildSlices(heights, size.height);
    columns = _buildSlices(widths, size.width);

#warning TJW: Deal with GL_MAX_TEXTURE_SIZE.  This may make it necessary to have dynamically allocated memory for widths and heights
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
//    NSLog(@"GL_MAX_TEXTURE_SIZE = %d", maxTextureSize);

#warning Try to handle more color spaces and depths.  Sadly, AppKit gives us 32-bit RGBA with 0xff alpha when we grab a snapshot.  We will either need to just use that, or strip the alpha channel
    OBASSERT([bitmap samplesPerPixel] == 4);
    OBASSERT([bitmap bitsPerSample] == 8);
    OBASSERT([bitmap bitsPerPixel] == 32);
    
    format = GL_RGB;

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    textureNames = NSZoneMalloc(NULL, sizeof(*textureNames) * rows * columns);
    textureBytes = NSZoneMalloc(NULL, sizeof(*textureBytes) * rows * columns);
    
    glGenTextures(rows * columns, textureNames);
    
    bitmapBytes = [bitmap bitmapData];

//#define TIME_EXTRACT    
#ifdef TIME_EXTRACT
    {
        unsigned int rep, count = 100;
        NSTimeInterval start, end;
        
        start = [NSDate timeIntervalSinceReferenceDate];
        for (rep = 0; rep < count; rep++) {
            y = 0;
            for (row = 0; row < rows; row++) {
                x = 0;
                for (column = 0; column < columns; column++) {
                    void *subBytes;
                    subBytes = _extractSubRect32(bitmapBytes, size, NSMakeRect(x, y, widths[column], heights[row]));
                    NSZoneFree(NULL, subBytes);
                    x += widths[column];
                }
                y += heights[row];
            }
        }
        end = [NSDate timeIntervalSinceReferenceDate];
        
        NSLog(@"time = %f", (end - start) / count);
    }
#endif

    y = 0;
    for (row = 0; row < rows; row++) {
        x = 0;
        for (column = 0; column < columns; column++) {
            void *subBytes;
            GLuint textureName;

            textureName = textureNames[SUBTEX(column, row)];
            
            // specify that this is a 2D texture
            glBindTexture(GL_TEXTURE_2D, textureName);
            
            // extract a sub image for this texture
            subBytes = _extractSubRect32(bitmapBytes, size, NSMakeRect(x, y, widths[column], heights[row]));
            
            glTexImage2D(GL_TEXTURE_2D,                 // associate pixels with the 2D texture
                        0, format,                      // mipmap level, internal format
                        widths[column], heights[row],
                        0, format, GL_UNSIGNED_BYTE,    // border width, format, component type
                        subBytes);
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

#warning Should be GL_DECAL later
            glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
//            glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

            // We'll hold on to these until we are deallocated.  If we could force
            // the texture to be resident on the card, we could free it now, but
            // this isn't a big deal.
            textureBytes[SUBTEX(column, row)] = subBytes;
            x += widths[column];
        }
        y += heights[row];
    }

    OAGLCheckError(@"-[OAGLBitmapPartition initWithBitmap:]");
    return self;
}

- (void) dealloc;
{
    unsigned int i;
    
    glDeleteTextures(rows * columns, textureNames);
    for (i = 0; i < rows * columns; i++)
        NSZoneFree(NULL, textureBytes[i]);
    NSZoneFree(NULL, textureBytes);
    NSZoneFree(NULL, textureNames);
    [super dealloc];
}

/*" We could have a -drawRect:atPoint: method that would draw only a subset of the rows and columns, clipped and translated according to the supplied rect and point, but the number of tranangles we will be drawing is pretty darn low.  Our fill-rate requirements are going to dominate the speed of this operation, so it is simpler to just have the caller translate us within the viewport and let GL do the clipping. "*/
- (void) draw;
{
    unsigned int row, column;
    unsigned int x, y;
    
    glEnable(GL_TEXTURE_2D);
    
    y = 0;
    for (row = 0; row < rows; row++) {
        x = 0;
        for (column = 0; column < columns; column++) {
            int index;
            
            index = SUBTEX(column,row);
            glBindTexture(GL_TEXTURE_2D, textureNames[index]);

//            NSLog(@"row=%d, column=%d  x=%d, y = %d, width = %d, height = %d",
//                    row, column, x, y, widths[column], heights[row]);
                    
#warning We are not really giving the right coordinates here, I think.  We should probably do the -0.5 ... width-0.5 thing
            glBegin(GL_TRIANGLES);
#if 1
                // Lower-right half
                glColor3ub(255, 255, 0);
                glTexCoord2f(0.0, 1.0);
                glVertex2f(x /*- 0.5*/, y /*- 0.5*/);
                glTexCoord2f(1.0, 1.0);
                glVertex2f(x + widths[column] /*- 0.5*/, y /*- 0.5*/);
                glTexCoord2f(1.0, 0.0);
                glVertex2f(x + widths[column] /*- 0.5*/, y + heights[row] /*- 0.5*/);
#endif
                // Upper-left half
                glColor3ub(255, 0, 255);
                glTexCoord2f(0.0, 1.0);
                glVertex2f(x /*- 0.5*/, y /*- 0.5*/);
                glTexCoord2f(1.0, 0.0);
                glVertex2f(x + widths[column] /*- 0.5*/, y + heights[row] /*- 0.5*/);
                glTexCoord2f(0.0, 0.0);
                glVertex2f(x /*- 0.5*/, y + heights[row] /*- 0.5*/);
                
            glEnd();
            
            x += widths[column];
        }
        y += heights[row];
    }

    glDisable(GL_TEXTURE_2D);
    OAGLCheckError(@"-[OAGLBitmapPartition draw]");
}


@end
