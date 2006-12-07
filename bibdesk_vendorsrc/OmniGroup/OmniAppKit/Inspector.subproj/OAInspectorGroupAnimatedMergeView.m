// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAInspectorGroupAnimatedMergeView.h"

#import <AppKit/NSBitmapImageRep.h> // Workaround for 10.1 precomp bug
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorGroupAnimatedMergeView.m,v 1.10 2004/02/10 04:07:33 kc Exp $");

@interface OAInspectorGroupAnimatedMergeView (Private)
- (void)_refreshImage;
@end

@implementation OAInspectorGroupAnimatedMergeView

// Init and dealloc

- initWithFrame:(NSRect)newFrame;
{
    if ([super initWithFrame:newFrame] == nil)
        return nil;
    throbOffset = 0.0;

    return self;
}

- (void)dealloc;
{
    [bitmapImageRep release];
    [super dealloc];
}

// NSView

- (BOOL)isOpaque;
{
    return YES;
}

- (void)drawRect:(NSRect)rect;
{
    [bitmapImageRep drawAtPoint:[self bounds].origin];
}

// API

- (void)setUpperGroupRect:(NSRect)newUpperRect lowerGroupRect:(NSRect)newLowerRect windowFrame:(NSRect)windowFrame;
{
    NSRect newViewFrame = NSMakeRect(0, 0, NSWidth(windowFrame), NSHeight(windowFrame));

    [self setFrame:newViewFrame];
    [self setBounds:windowFrame];

    upperRect = newUpperRect;
    lowerRect = newLowerRect;

    [self _refreshImage];
}

- (void)throbOnce:(NSTimer *)timer;
{
    throbOffset += 0.04;
    if (throbOffset > 1.0)
        throbOffset -= 1.0;

    [self _refreshImage];
    [self setNeedsDisplay:YES];
}

@end

@implementation OAInspectorGroupAnimatedMergeView (NotificationsDelegatesDatasources)
@end

@implementation OAInspectorGroupAnimatedMergeView (Private)

- (void)_refreshImage;
{
#ifdef MAC_OS_X_VERSION_10_2
    NSRect windowFrame = [self bounds];
    unsigned int width = rint(NSWidth(windowFrame));
    unsigned int height = rint(NSHeight(windowFrame));

    NSColor *outgoingPingColor = [NSColor keyboardFocusIndicatorColor];
    float outgoingRed, outgoingGreen, outgoingBlue, outgoingAlpha;
    [[outgoingPingColor colorUsingColorSpaceName:NSDeviceRGBColorSpace] getRed:&outgoingRed green:&outgoingGreen blue:&outgoingBlue alpha:&outgoingAlpha];

    NSColor *incomingPingColor = [NSColor selectedControlColor];
    float incomingRed, incomingGreen, incomingBlue, incomingAlpha;
    [[incomingPingColor colorUsingColorSpaceName:NSDeviceRGBColorSpace] getRed:&incomingRed green:&incomingGreen blue:&incomingBlue alpha:&incomingAlpha];
    

    [bitmapImageRep release];
    bitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:width * 4 bitsPerPixel:32];
    {
        unsigned char *imageBuffer = [bitmapImageRep bitmapData];


        NSPoint bottomMiddleOfUpperGroup = NSMakePoint(NSMidX(upperRect), NSMinY(upperRect));
        NSPoint topMiddleOfLowerGroup = NSMakePoint(NSMidX(lowerRect), NSMaxY(lowerRect));

        double distanceBetweenMiddles = hypot(bottomMiddleOfUpperGroup.x - topMiddleOfLowerGroup.x, bottomMiddleOfUpperGroup.y - topMiddleOfLowerGroup.y);
        const double pingThicknessPixels = 6.0;
        double totalDistancePingTravels = distanceBetweenMiddles + pingThicknessPixels;
        const double pingThicknessPercentageOfTotalDistance = pingThicknessPixels / totalDistancePingTravels;

        double angleFromMiddleLowerToMiddleUpper = atan2(topMiddleOfLowerGroup.y - bottomMiddleOfUpperGroup.y, topMiddleOfLowerGroup.x - bottomMiddleOfUpperGroup.x);
        double angleFromMiddleUpperToMiddleLower = atan2(bottomMiddleOfUpperGroup.y - topMiddleOfLowerGroup.y, bottomMiddleOfUpperGroup.x - topMiddleOfLowerGroup.x);

        unsigned int column;
        for (column = 0; column < width; column++) {
            unsigned int row;
            for (row = 0; row < height; row++) {
                unsigned int pixelOffset = row * width * 4 + column * 4;

                double x = NSMinX(windowFrame) + column;
                double y = NSMaxY(windowFrame) - row;

                NSPoint point = NSMakePoint(x, y);
                if (NSPointInRect(point, upperRect) || NSPointInRect(point, lowerRect)) {
                    imageBuffer[pixelOffset + 0] = 255;
                    imageBuffer[pixelOffset + 1] = 255;
                    imageBuffer[pixelOffset + 2] = 255;
                    imageBuffer[pixelOffset + 3] = 255;
                    continue;
                }

                inline float _one_over_sqrt(float x)
                {
                    const float half = 0.5;
                    const float one  = 1.0;
                    float B, y0, y1;

                    // This'll NaN if it hits frsqrte.  Handle both +0.0 and -0.0
                    if (fabs(x) == 0.0)
                        return x;

                    B = x;
                    asm("frsqrte %0,%1" : "=f" (y0) : "f" (B));

                    /* First refinement step */
                    y1 = y0 + half*y0*(one - B*y0*y0);

                    return y1;
                }
                
                double _alphaForPixelWithTimeAndIsReturning(double startTime, double timeLength, BOOL isReturning) {
                    if (throbOffset <= startTime || throbOffset >= startTime + timeLength)
                        return 0.0;

                    double time = (throbOffset - startTime) / timeLength;

                    NSPoint middleOfCurrentGroup = isReturning ? bottomMiddleOfUpperGroup : topMiddleOfLowerGroup;

                    NSSize sizeToMiddleOfCurrenGroup = (NSSize){x - middleOfCurrentGroup.x,  y - middleOfCurrentGroup.y};
                    double distanceToMiddleOfCurrentGroup = 1.0 / _one_over_sqrt(sizeToMiddleOfCurrenGroup.width * sizeToMiddleOfCurrenGroup.width + sizeToMiddleOfCurrenGroup.height * sizeToMiddleOfCurrenGroup.height);
                    double currentPointPercentageOfTotalDistance = (distanceToMiddleOfCurrentGroup + pingThicknessPixels) / totalDistancePingTravels;

                    double currentPointPercentageThroughPing = (currentPointPercentageOfTotalDistance - time) / pingThicknessPercentageOfTotalDistance;
                    if (currentPointPercentageThroughPing <= 0 || currentPointPercentageThroughPing >= 1.0 )
                        return 0.0;

                    double angleFromCurrentGroupToCurrentPoint = atan2(y - middleOfCurrentGroup.y, x - middleOfCurrentGroup.x);

                    const double pingHalfWidthAngleInRadians = (2.0 * M_PI) / (isReturning ? 20.0 : 5.0);
                    double angleBetweenMiddles = isReturning ? angleFromMiddleLowerToMiddleUpper : angleFromMiddleUpperToMiddleLower;
                    double currentPointAngleOffsetFromOptimal = remainder(angleBetweenMiddles - angleFromCurrentGroupToCurrentPoint, 2.0 * M_PI);
                    double currentPointPercentageOffsetInPing = currentPointAngleOffsetFromOptimal / pingHalfWidthAngleInRadians;

                    if (currentPointPercentageOffsetInPing <= -1.0 || currentPointPercentageOffsetInPing >= 1.0)
                        return 0.0;

                    const double leadingEdgeInPercentiles = 0.2;
                    double percantageThroughPingReduction = (currentPointPercentageThroughPing < (1.0 - leadingEdgeInPercentiles)) ? currentPointPercentageThroughPing : (1.0 - currentPointPercentageThroughPing) / leadingEdgeInPercentiles;
                    double widthReduction = cos(currentPointPercentageOffsetInPing * M_PI / 2.0);
                    double distanceReduction = 1.0 - MAX(0.0, MIN(1.0, (distanceToMiddleOfCurrentGroup - pingThicknessPixels) / distanceBetweenMiddles));
                    return percantageThroughPingReduction * distanceReduction * widthReduction;
                }

                double wave1 = _alphaForPixelWithTimeAndIsReturning(0.0, 0.5, NO);
                double wave2 = _alphaForPixelWithTimeAndIsReturning(0.1, 0.5, NO);
                double returnWave = _alphaForPixelWithTimeAndIsReturning(0.3, 0.4, YES);

                const double _MAXIMUM_SHADOW_THAT_LOOKS_GOOD = 1.0;
                double alpha = MIN(MAX(MAX(wave1, wave2), returnWave) * 255.999999, 255.0) * _MAXIMUM_SHADOW_THAT_LOOKS_GOOD;

                double outgoingWaveStrength = (wave1 + wave2) * 255.999999;
                double incomingWaveStrength = returnWave * 255.999999;

                imageBuffer[pixelOffset + 0] = MIN(outgoingRed * outgoingWaveStrength + incomingRed * incomingWaveStrength, alpha);
                imageBuffer[pixelOffset + 1] = MIN(outgoingGreen * outgoingWaveStrength + incomingGreen * incomingWaveStrength, alpha);
                imageBuffer[pixelOffset + 2] = MIN(outgoingBlue * outgoingWaveStrength + incomingBlue * incomingWaveStrength, alpha);
                imageBuffer[pixelOffset + 3] = alpha;
            }
        }
    }
#endif
}

@end
