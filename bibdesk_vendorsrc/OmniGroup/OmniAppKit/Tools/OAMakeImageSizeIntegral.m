// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <Cocoa/Cocoa.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Tools/OAMakeImageSizeIntegral.m,v 1.7 2004/02/10 05:14:01 kc Exp $")

// This is intended to strip bogus DPI settings. Photoshop will save 72.00001 DPI which can lead to hard to find bugs later.
// It'll probably also come in handy in stripping layers.

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSFileManager *manager = [NSFileManager defaultManager];
    unsigned int totalOriginalImageSize = 0;
    unsigned int totalTIFFSize = 0;
    unsigned int totalPNGImageSize = 0;
    unsigned int totalBestImageSize = 0;

    if (argc < 2) {
        fprintf(stderr, "usage: %s file1.tiff [... fileN.tiff]\n", argv[0]);
        return 1;
    }

    // Can't lockFocus on an image w/o a CG context
    [NSApplication sharedApplication];

    int argi;
    for (argi = 1; argi < argc; argi++) {
        NSString *imagePath = [manager stringWithFileSystemRepresentation:argv[argi] length:strlen(argv[argi])];

        NS_DURING {
            NSData *originalData = [[NSData alloc] initWithContentsOfFile:imagePath];
            unsigned int originalImageSize = [originalData length];
            NSImage *image = [[NSImage alloc] initWithData:originalData];
            [image setScalesWhenResized:NO];

            if (image == nil)
                [NSException raise:NSGenericException format:@"Unable to load image"];
    
            NSSize size = [image size];
            NSSize integralSize = (NSSize){rint(size.width), rint(size.height)};
            if (!NSEqualSizes(size, integralSize)) {
                NSLog(@"  %@: Fixing size; was (%g,%g), now (%g,%g)", imagePath, size.width, size.height, integralSize.width, integralSize.height);
                [image setSize:integralSize];
    
                NSArray *reps = [image representations];
                unsigned int repIndex = [reps count];
                if (repIndex != 1) {
                    // We currently composite just one representation, so skip this file if we see more
                    [NSException raise:NSGenericException format:@"Unable to process images with multiple (%d) representations", repIndex];
                }

                while (repIndex--) {
                    NSImageRep *rep = [reps objectAtIndex:repIndex];
                    [rep setSize:integralSize];
                }
            }
    
            // -TIFFRepresentation seems to keep the source DPI, which is nice, but we want to write out a new image, killing the original DPI
            NSImage *newImage = [[NSImage alloc] initWithSize:integralSize];
            [newImage lockFocus];
            [image compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
            [newImage unlockFocus];
            [image release];

            NSData *lzwData = [newImage TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:0.0];
            NSData *packbitsData = [newImage TIFFRepresentationUsingCompression:NSTIFFCompressionPackBits factor:0.0];
            NSBitmapImageRep *bitmapImageRep = [NSBitmapImageRep imageRepWithData:lzwData];
            NSData *pngData = [bitmapImageRep representationUsingType:NSPNGFileType properties:nil];
            [newImage release];

            totalOriginalImageSize += originalImageSize;
            totalTIFFSize += MIN(originalImageSize, MIN([lzwData length], [packbitsData length]));
            totalPNGImageSize += [pngData length];
            unsigned int bestSize = MIN(MIN(MIN([lzwData length], [packbitsData length]), [pngData length]), originalImageSize);
            totalBestImageSize += bestSize;
            if ([pngData length] > bestSize) {
                NSLog(@"PNG loses for %@ by %d", imagePath, [pngData length] - bestSize);
            }
            NSData *tiffData = [lzwData length] <= [packbitsData length] ? lzwData : packbitsData;
            if (![tiffData writeToFile:imagePath atomically:YES])
                [NSException raise:NSGenericException format:@"Unable to store image"];
            if (![pngData writeToFile:[[imagePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"] atomically:YES])
                [NSException raise:NSGenericException format:@"Unable to store image"];
        } NS_HANDLER {
            NSLog(@"%@: Unable to process image: %@", imagePath, [localException reason]);
        } NS_ENDHANDLER;
        [pool release];
        pool = [[NSAutoreleasePool alloc] init];
    }
    NSLog(@"totalOriginalImageSize = %d", totalOriginalImageSize);
    NSLog(@"totalTIFFSize = %d", totalTIFFSize);
    NSLog(@"totalPNGImageSize = %d", totalPNGImageSize);
    NSLog(@"totalBestImageSize = %d", totalBestImageSize);
    [pool release];

    return 0;
}
