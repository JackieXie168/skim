// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OAProgressView.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import <OmniAppKit/NSImage-OAExtensions.h>
// #import <OmniAppKit/ps.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAProgressView.m,v 1.14 2003/01/15 22:51:44 kc Exp $")

@interface OAProgressView (Private)
- (void)drawProgressInRect:(NSRect)innerBounds;
- (void)spinBarberPoleInRect:(NSRect)innerBounds;
- (void)drawNoProgressPoleInRect:(NSRect)innerBounds;
- (NSImage *)scaleAndRetainRightImage:(NSImage **)images forRect:(NSRect)rect;
@end

@implementation OAProgressView

typedef enum {
    BARBER_IMAGE, GAUGE_IMAGE, NOPROGRESS_IMAGE
} IMAGE_TYPE;

#define IMAGE_COUNT 3
#define IMAGE_TYPE_COUNT 3

static BOOL loadedImages;
static NSImage *poleImages[IMAGE_TYPE_COUNT][IMAGE_COUNT];
static NSImage *coloredPoleImages[IMAGE_TYPE_COUNT][IMAGE_COUNT];

+ (void)initialize;
{
    static BOOL                 initialized = NO;

    [super initialize];
    if (initialized)
        return;
    initialized = YES;

    loadedImages = NO;

}

// Init and dealloc

- initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];

    progress = NSNotFound;
    total = NSNotFound;
    flags.validProgress = NO;
    flags.validTotal = NO;
    flags.turnedOff = NO;

    return self;
}

- (void)dealloc;
{
    [gaugeImage release];
    [barberImage release];
    [noProgressImage release];
    [super dealloc];
}


// NSView subclass

- (BOOL)isOpaque;
{
    return YES;
}

- (void)drawRect:(NSRect)rect
{
    NSRect bounds, innerBounds;

    if (flags.turnedOff) {
        [[NSColor controlColor] set];
        NSRectFill(rect);
        return;
    }
    
    bounds = [self bounds];
    NSDrawDarkBezel(bounds, rect);

    innerBounds = NSInsetRect(bounds, 2.0, 2.0);

    if (flags.validTotal)
        [self drawProgressInRect:innerBounds];
    else if (flags.validProgress)
        [self spinBarberPoleInRect:innerBounds];
    else
        [self drawNoProgressPoleInRect:innerBounds];
}


// Public API

- (void)turnOff;
{
    flags.turnedOff = YES;
    [self setNeedsDisplay:YES];
}


- (void)processedBytes:(unsigned int)amount;
{
    flags.turnedOff = NO;
    progress = amount;
    total = NSNotFound;
    flags.validProgress = progress != NSNotFound;
    flags.validTotal = NO;
    [self setNeedsDisplay:YES];
}

- (void)processedBytes:(unsigned int)amount ofBytes:(unsigned int)totalAmount;
{
    if (totalAmount == 0 || totalAmount == NSNotFound || amount == NSNotFound) {
        [self processedBytes:amount];
        return;
    }
    flags.turnedOff = NO;
    progress = amount;
    total = totalAmount;
    flags.validProgress = YES;
    flags.validTotal = YES;
    [self setNeedsDisplay:YES];
}

@end


@implementation OAProgressView (Private)

- (void)drawProgressInRect:(NSRect)innerBounds;
{
    NSSize gaugeImageSize;
    double ratio;
    unsigned int totalBarWidth, oneThirdWidth;
    unsigned int leftEdgeWidth, rightEdgeWidth, remainingWidth;
    unsigned int drawOffset;

    if (!gaugeImage || [gaugeImage size].height != NSHeight(innerBounds)) {
        [gaugeImage release];
        gaugeImage = [self scaleAndRetainRightImage:coloredPoleImages[GAUGE_IMAGE] forRect:innerBounds];
    }
    gaugeImageSize = [gaugeImage size];

    oneThirdWidth = gaugeImageSize.width / 3;

    ratio = MIN((double)progress / (double)total, 1.0);
    totalBarWidth = (int)(NSWidth(innerBounds) * ratio);

    leftEdgeWidth = MIN(totalBarWidth / 2, oneThirdWidth);
    rightEdgeWidth = MIN(leftEdgeWidth + (totalBarWidth % 2), oneThirdWidth); // Extra pixel goes to right edge for small widths

    [gaugeImage compositeToPoint:NSMakePoint(NSMinX(innerBounds), NSMinY(innerBounds)) fromRect:NSMakeRect(0, 0, leftEdgeWidth, gaugeImageSize.height) operation:NSCompositeSourceOver];
    [gaugeImage compositeToPoint:NSMakePoint(NSMinX(innerBounds) + totalBarWidth - rightEdgeWidth, NSMinY(innerBounds)) fromRect:NSMakeRect(gaugeImageSize.width - rightEdgeWidth, 0, rightEdgeWidth, gaugeImageSize.height) operation:NSCompositeSourceOver];

    drawOffset = leftEdgeWidth;
    remainingWidth = totalBarWidth - leftEdgeWidth - rightEdgeWidth;
    while (remainingWidth > 0) {
        unsigned int drawWidth;

        drawWidth = MIN(remainingWidth, oneThirdWidth);
        [gaugeImage compositeToPoint:NSMakePoint(NSMinX(innerBounds)+drawOffset, NSMinY(innerBounds)) fromRect:NSMakeRect(oneThirdWidth, 0, drawWidth, gaugeImageSize.height) operation:NSCompositeSourceOver];

        remainingWidth -= drawWidth;
        drawOffset += drawWidth;
    }
}

- (void)spinBarberPoleInRect:(NSRect)innerBounds;
{
    NSSize barberImageSize;
    unsigned int oneHalfWidth;
    unsigned int drawOffset, remainingWidth;
    unsigned int lastBarberPoleOffset;

    if (!barberImage || [barberImage size].height != NSHeight(innerBounds)) {
        [barberImage release];
        barberImage = [self scaleAndRetainRightImage:coloredPoleImages[BARBER_IMAGE] forRect:innerBounds];
    }
    barberImageSize = [barberImage size];

    oneHalfWidth = barberImageSize.width / 2;

    lastBarberPoleOffset = (int)(ABS([[NSDate date] timeIntervalSinceReferenceDate]) * 16) % oneHalfWidth;

    drawOffset = 0.0;
    remainingWidth = NSWidth(innerBounds);
    while (remainingWidth > 0) {
        unsigned int drawWidth;

        drawWidth = MIN(remainingWidth, oneHalfWidth);
        [barberImage compositeToPoint:NSMakePoint(NSMinX(innerBounds)+drawOffset, NSMinY(innerBounds)) fromRect:NSMakeRect(lastBarberPoleOffset, 0, drawWidth, barberImageSize.height) operation:NSCompositeSourceOver];

        remainingWidth -= drawWidth;
        drawOffset += drawWidth;
    }
}

- (void)drawNoProgressPoleInRect:(NSRect)innerBounds;
{
    NSSize noProgressImageSize;
    unsigned int drawOffset, remainingWidth;

    if (!noProgressImage || [noProgressImage size].height != NSHeight(innerBounds)) {
        [noProgressImage release];
        noProgressImage = [self scaleAndRetainRightImage:coloredPoleImages[NOPROGRESS_IMAGE] forRect:innerBounds];
    }
    noProgressImageSize = [noProgressImage size];

    drawOffset = 0.0;
    remainingWidth = NSWidth(innerBounds);
    while (remainingWidth > 0) {
        unsigned int drawWidth;

        drawWidth = MIN(remainingWidth, noProgressImageSize.width);
        [noProgressImage compositeToPoint:NSMakePoint(NSMinX(innerBounds)+drawOffset, NSMinY(innerBounds)) fromRect:NSMakeRect(0, 0, drawWidth, noProgressImageSize.height) operation:NSCompositeSourceOver];

        remainingWidth -= drawWidth;
        drawOffset += drawWidth;
    }
}

- (NSImage *)scaleAndRetainRightImage:(NSImage **)images forRect:(NSRect)rect;
{
    NSImage *newImage;
    NSSize oldImageSize;
    unsigned int imageIndex;

    if (!loadedImages) {
        unsigned int imageType, imageIndex;
        NSBundle *thisBundle = [OAProgressView bundle];

        poleImages[BARBER_IMAGE][0] = [[NSImage imageNamed:@"OALargeBarberPole" inBundle:thisBundle] retain];
        poleImages[GAUGE_IMAGE][0] = [[NSImage imageNamed:@"OALargeGaugePole" inBundle:thisBundle] retain];
        poleImages[NOPROGRESS_IMAGE][0] = [[NSImage imageNamed:@"OALargeNoProgressPole" inBundle:thisBundle] retain];
        poleImages[BARBER_IMAGE][1] = [[NSImage imageNamed:@"OARegularBarberPole" inBundle:thisBundle] retain];
        poleImages[GAUGE_IMAGE][1] = [[NSImage imageNamed:@"OARegularGaugePole" inBundle:thisBundle] retain];
        poleImages[NOPROGRESS_IMAGE][1] = [[NSImage imageNamed:@"OARegularNoProgressPole" inBundle:thisBundle] retain];
        poleImages[BARBER_IMAGE][2] = [[NSImage imageNamed:@"OASmallBarberPole" inBundle:thisBundle] retain];
        poleImages[GAUGE_IMAGE][2] = [[NSImage imageNamed:@"OASmallGaugePole" inBundle:thisBundle] retain];
        poleImages[NOPROGRESS_IMAGE][2] = [[NSImage imageNamed:@"OASmallNoProgressPole" inBundle:thisBundle] retain];

        for (imageType = 0; imageType < IMAGE_TYPE_COUNT; imageType++)
            for (imageIndex = 0; imageIndex < IMAGE_COUNT; imageIndex++) {
                NSSize imageSize;

                imageSize = [poleImages[imageType][imageIndex] size];
                coloredPoleImages[imageType][imageIndex] = [[NSImage alloc] initWithSize:imageSize];
                [coloredPoleImages[imageType][imageIndex] lockFocus];
                [[NSColor blueColor] set];
                NSRectFill(NSMakeRect(0,0,imageSize.width,imageSize.height));
                [poleImages[imageType][imageIndex] compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
                [coloredPoleImages[imageType][imageIndex] unlockFocus];
            }
                
        loadedImages = YES;
    }

    for (imageIndex = 0; imageIndex < IMAGE_COUNT; imageIndex++) {
        if (NSHeight(rect) == [images[imageIndex] size].height)
            return [images[imageIndex] retain];
        else if (NSHeight(rect) > [images[imageIndex] size].height)
            break;
    }
    
    if (imageIndex == IMAGE_COUNT)
        imageIndex = IMAGE_COUNT - 1;

    oldImageSize = [images[imageIndex] size];
    newImage = [images[imageIndex] copy];
    [newImage setScalesWhenResized:YES];
    [newImage setSize:NSMakeSize(oldImageSize.width * (NSHeight(rect)/oldImageSize.height), NSHeight(rect))];
    return newImage;
}

@end
