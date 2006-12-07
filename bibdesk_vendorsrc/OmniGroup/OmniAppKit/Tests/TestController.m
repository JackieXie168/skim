// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "TestController.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniAppKit/OmniAppKit.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Tests/TestController.m,v 1.2 2003/01/15 22:51:42 kc Exp $");

@interface NSAttributedString (TestControllerPrivate)
- (void)_old_drawInRectangle:(NSRect)rectangle alignment:(int)alignment verticallyCentered:(BOOL)verticallyCenter;
@end

@implementation TestController

// Init and dealloc

- init;
{
    if ([super init] == nil)
        return nil;

    return self;
}

- (void)dealloc;
{
    [super dealloc];
}


// API

- (IBAction)drawString:(id)sender;
{
    NSAttributedString *attributedString;
    BOOL verticallyCenter;
    int alignment;
    NSRect outputBounds;
    BOOL drawOldStyle;

    attributedString = [drawStringInputField attributedStringValue];
    verticallyCenter = [verticallyCenterCheckbox state] == NSOnState;
    alignment = [[drawStringAlignmentMatrix selectedCell] tag];
    [drawStringOutputView lockFocus];
    [[NSColor whiteColor] set];
    outputBounds = [drawStringOutputView bounds];
    NSRectFill(outputBounds);
    drawOldStyle = [drawOldStyleCheckbox state] == NSOnState;
    NSLog(@"Drawing '%@' in %@ alignment=%d verticallyCenter=%d drawOldStyle=%d", [attributedString string], NSStringFromRect(outputBounds), alignment, verticallyCenter, drawOldStyle);
    if (YES) {
        NSTimeInterval oldStart, newStart, newEnd;
        unsigned int count;

        count = 1000;
        
        oldStart = [NSDate timeIntervalSinceReferenceDate];
        while (count--)
            [attributedString _old_drawInRectangle:outputBounds alignment:alignment verticallyCentered:verticallyCenter];
        newStart = [NSDate timeIntervalSinceReferenceDate];
        count = 1000;
        while (count--)
            [attributedString drawInRectangle:outputBounds alignment:alignment verticallyCentered:verticallyCenter];
        newEnd = [NSDate timeIntervalSinceReferenceDate];
        NSLog(@"oldDuration = %f, newDuration = %f", newStart - oldStart, newEnd - newStart);
    } else if (drawOldStyle) {
        [attributedString _old_drawInRectangle:outputBounds alignment:alignment verticallyCentered:verticallyCenter];
    } else {
        [attributedString drawInRectangle:outputBounds alignment:alignment verticallyCentered:verticallyCenter];
    }
    [drawStringOutputView unlockFocus];
}

@end

@implementation TestController (Notifications)

- (void)awakeFromNib;
{
    [drawStringInputField setAllowsEditingTextAttributes:YES];
}

@end

@implementation NSAttributedString (TestControllerPrivate)

- (void)_old_drawInRectangle:(NSRect)rectangle alignment:(int)alignment verticallyCentered:(BOOL)verticallyCenter;
{
    static NSTextStorage *showStringTextStorage = nil;
    static NSLayoutManager *showStringLayoutManager = nil;
    static NSTextContainer *showStringTextContainer = nil;

    unsigned int originalGlyphCount;
    NSDictionary *attributes;
    NSRange drawGlyphRange, drawGlyphRangeWithoutEllipsis;
    NSRect *rectArray;
    unsigned int rectCount;
    NSSize size;
    NSString *ellipsisString;
    NSSize ellipsisSize;
    BOOL drawEllipsisIfTruncated;

    if ([self length] == 0)
        return;

    if (!showStringTextStorage) {
        showStringTextStorage = [[NSTextStorage alloc] init];

        showStringLayoutManager = [[NSLayoutManager alloc] init];
        [showStringTextStorage addLayoutManager:showStringLayoutManager];

        showStringTextContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(1e7, 1e7)];
        [showStringTextContainer setLineFragmentPadding:0];
        [showStringLayoutManager addTextContainer:showStringTextContainer];
    }

    [showStringTextStorage setAttributedString:self];
    attributes = [self attributesAtIndex:0 longestEffectiveRange:NULL inRange:NSMakeRange(0,1)];

    drawGlyphRange = [showStringLayoutManager glyphRangeForTextContainer:showStringTextContainer];
    if (drawGlyphRange.length == 0)
        return;
    drawGlyphRangeWithoutEllipsis = NSMakeRange(0, 0);
    originalGlyphCount = drawGlyphRange.length;

    ellipsisString = nil;
    ellipsisSize = NSMakeSize(0, 0);

    rectArray = [showStringLayoutManager rectArrayForGlyphRange:drawGlyphRange withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0) inTextContainer:showStringTextContainer rectCount:&rectCount];
    if (rectCount < 1)
        return;

    size = rectArray[0].size;

    if (size.width > NSWidth(rectangle)) {
        NSSize testSize;
        unsigned int lowerCount, upperCount;

        lowerCount = 0;
        upperCount = originalGlyphCount;

        ellipsisString = [NSString horizontalEllipsisString];
        ellipsisSize = [ellipsisString sizeWithAttributes:attributes];

        while (lowerCount + 1 < upperCount) {
            unsigned int middleCount;

            middleCount = (upperCount + lowerCount) / 2;

// #warning WJS: This is slow, I found out.  Use the same algorithm OHLine uses.
            rectArray = [showStringLayoutManager rectArrayForGlyphRange:NSMakeRange(0, middleCount) withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0) inTextContainer:showStringTextContainer rectCount:&rectCount];
            if (rectCount < 1)
                return;

            testSize = rectArray[0].size;

            // DEBUGGING
            //            rectArray[0].origin.x += rectangle.origin.x;
            //            rectArray[0].origin.y += rectangle.origin.y;
            //            NSDottedFrameRect(rectArray[0]);

            if (testSize.width <= NSWidth(rectangle) && drawGlyphRangeWithoutEllipsis.length < middleCount)
                drawGlyphRangeWithoutEllipsis = NSMakeRange(0, middleCount);
            testSize.width += ellipsisSize.width;

            if (testSize.width <= NSWidth(rectangle)) {
                lowerCount = middleCount;
                size = testSize;
            } else
                upperCount = middleCount;
        }

        drawGlyphRange.length = lowerCount;
    }

    if (drawGlyphRange.length != 0) {
        drawEllipsisIfTruncated = YES;
    } else {
        // If we couldn't fit ANY characters with the ellipsis, try drawing some without it (better than drawing nothing)
        drawEllipsisIfTruncated = NO;
        drawGlyphRange = drawGlyphRangeWithoutEllipsis;
    }

    if (drawGlyphRange.length) {
        NSPoint drawPoint;

        // determine drawPoint based on alignment
        drawPoint.y = NSMinY(rectangle);
        switch (alignment) {
            default:
            case NSLeftTextAlignment:
                drawPoint.x = NSMinX(rectangle);
                break;
            case NSCenterTextAlignment:
                drawPoint.x = NSMidX(rectangle) - size.width / 2.0;
                break;
            case NSRightTextAlignment:
                drawPoint.x = NSMaxX(rectangle) - size.width;
                break;
        }

        if (verticallyCenter)
            drawPoint.y = NSMidY(rectangle) - size.height / 2.0;

        [showStringLayoutManager drawGlyphsForGlyphRange:drawGlyphRange atPoint:drawPoint];
        if (drawGlyphRange.length < originalGlyphCount && drawEllipsisIfTruncated) {
            // draw only part of string, then maybe ellipsis if they fit
            drawPoint.x += size.width - ellipsisSize.width;
            [ellipsisString drawAtPoint:drawPoint withAttributes:attributes];
        }
    }
}

@end
