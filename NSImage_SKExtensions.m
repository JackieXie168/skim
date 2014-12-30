//
//  NSImage_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 7/27/07.
/*
 This software is Copyright (c) 2007-2014
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSImage_SKExtensions.h"


@implementation NSImage (SKExtensions)

NSString *SKImageNameTextNote = @"TextNote";
NSString *SKImageNameAnchoredNote = @"AnchoredNote";
NSString *SKImageNameCircleNote = @"CircleNote";
NSString *SKImageNameSquareNote = @"SquareNote";
NSString *SKImageNameHighlightNote = @"HighlightNote";
NSString *SKImageNameUnderlineNote = @"UnderlineNote";
NSString *SKImageNameStrikeOutNote = @"StrikeOutNote";
NSString *SKImageNameLineNote = @"LineNote";
NSString *SKImageNameInkNote = @"InkNote";

NSString *SKImageNameToolbarPageUp = @"ToolbarPageUp";
NSString *SKImageNameToolbarPageDown = @"ToolbarPageDown";
NSString *SKImageNameToolbarFirstPage = @"ToolbarFirstPage";
NSString *SKImageNameToolbarLastPage = @"ToolbarLastPage";
NSString *SKImageNameToolbarBack = @"ToolbarBack";
NSString *SKImageNameToolbarForward = @"ToolbarForward";
NSString *SKImageNameToolbarZoomIn = @"ToolbarZoomIn";
NSString *SKImageNameToolbarZoomOut = @"ToolbarZoomOut";
NSString *SKImageNameToolbarZoomActual = @"ToolbarZoomActual";
NSString *SKImageNameToolbarZoomToFit = @"ToolbarZoomToFit";
NSString *SKImageNameToolbarZoomToSelection = @"ToolbarZoomToSelection";
NSString *SKImageNameToolbarRotateRight = @"ToolbarRotateRight";
NSString *SKImageNameToolbarRotateLeft = @"ToolbarRotateLeft";
NSString *SKImageNameToolbarCrop = @"ToolbarCrop";
NSString *SKImageNameToolbarFullScreen = @"ToolbarFullScreen";
NSString *SKImageNameToolbarPresentation = @"ToolbarPresentation";
NSString *SKImageNameToolbarSinglePage = @"ToolbarSinglePage";
NSString *SKImageNameToolbarTwoUp = @"ToolbarTwoUp";
NSString *SKImageNameToolbarSinglePageContinuous = @"ToolbarSinglePageContinuous";
NSString *SKImageNameToolbarTwoUpContinuous = @"ToolbarTwoUpContinuous";
NSString *SKImageNameToolbarBookMode = @"ToolbarBookMode";
NSString *SKImageNameToolbarPageBreaks = @"ToolbarPageBreaks";
NSString *SKImageNameToolbarMediaBox = @"ToolbarMediaBox";
NSString *SKImageNameToolbarCropBox = @"ToolbarCropBox";
NSString *SKImageNameToolbarLeftPane = @"ToolbarLeftPane";
NSString *SKImageNameToolbarRightPane = @"ToolbarRightPane";
NSString *SKImageNameToolbarTextNoteMenu = @"ToolbarTextNoteMenu";
NSString *SKImageNameToolbarAnchoredNoteMenu = @"ToolbarAnchoredNoteMenu";
NSString *SKImageNameToolbarCircleNoteMenu = @"ToolbarCircleNoteMenu";
NSString *SKImageNameToolbarSquareNoteMenu = @"ToolbarSquareNoteMenu";
NSString *SKImageNameToolbarHighlightNoteMenu = @"ToolbarHighlightNoteMenu";
NSString *SKImageNameToolbarUnderlineNoteMenu = @"ToolbarUnderlineNoteMenu";
NSString *SKImageNameToolbarStrikeOutNoteMenu = @"ToolbarStrikeOutNoteMenu";
NSString *SKImageNameToolbarLineNoteMenu = @"ToolbarLineNoteMenu";
NSString *SKImageNameToolbarInkNoteMenu = @"ToolbarInkNoteMenu";
NSString *SKImageNameToolbarAddTextNote = @"ToolbarAddTextNote";
NSString *SKImageNameToolbarAddAnchoredNote = @"ToolbarAddAnchoredNote";
NSString *SKImageNameToolbarAddCircleNote = @"ToolbarAddCircleNote";
NSString *SKImageNameToolbarAddSquareNote = @"ToolbarAddSquareNote";
NSString *SKImageNameToolbarAddHighlightNote = @"ToolbarAddHighlightNote";
NSString *SKImageNameToolbarAddUnderlineNote = @"ToolbarAddUnderlineNote";
NSString *SKImageNameToolbarAddStrikeOutNote = @"ToolbarAddStrikeOutNote";
NSString *SKImageNameToolbarAddLineNote = @"ToolbarAddLineNote";
NSString *SKImageNameToolbarAddInkNote = @"ToolbarAddInkNote";
NSString *SKImageNameToolbarAddTextNoteMenu = @"ToolbarAddTextNoteMenu";
NSString *SKImageNameToolbarAddAnchoredNoteMenu = @"ToolbarAddAnchoredNoteMenu";
NSString *SKImageNameToolbarAddCircleNoteMenu = @"ToolbarAddCircleNoteMenu";
NSString *SKImageNameToolbarAddSquareNoteMenu = @"ToolbarAddSquareNoteMenu";
NSString *SKImageNameToolbarAddHighlightNoteMenu = @"ToolbarAddHighlightNoteMenu";
NSString *SKImageNameToolbarAddUnderlineNoteMenu = @"ToolbarAddUnderlineNoteMenu";
NSString *SKImageNameToolbarAddStrikeOutNoteMenu = @"ToolbarAddStrikeOutNoteMenu";
NSString *SKImageNameToolbarAddLineNoteMenu = @"ToolbarAddLineNoteMenu";
NSString *SKImageNameToolbarAddInkNoteMenu = @"ToolbarAddInkNoteMenu";
NSString *SKImageNameToolbarTextTool = @"ToolbarTextTool";
NSString *SKImageNameToolbarMoveTool = @"ToolbarMoveTool";
NSString *SKImageNameToolbarMagnifyTool = @"ToolbarMagnifyTool";
NSString *SKImageNameToolbarSelectTool = @"ToolbarSelectTool";

NSString *SKImageNameOutlineViewAdorn = @"OutlineViewAdorn";
NSString *SKImageNameThumbnailViewAdorn = @"ThumbnailViewAdorn";
NSString *SKImageNameNoteViewAdorn = @"NoteViewAdorn";
NSString *SKImageNameSnapshotViewAdorn = @"SnapshotViewAdorn";
NSString *SKImageNameFindViewAdorn = @"FindViewAdorn";
NSString *SKImageNameGroupedFindViewAdorn = @"GroupedFindViewAdorn";

NSString *SKImageNameTextAlignLeft = @"TextAlignLeft";
NSString *SKImageNameTextAlignCenter = @"TextAlignCenter";
NSString *SKImageNameTextAlignRight = @"TextAlignRight";

NSString *SKImageNameResizeDiagonal45Cursor = @"ResizeDiagonal45Cursor";
NSString *SKImageNameResizeDiagonal135Cursor = @"ResizeDiagonal135Cursor";
NSString *SKImageNameZoomInCursor = @"ZoomInCursor";
NSString *SKImageNameZoomOutCursor = @"ZoomOutCursor";
NSString *SKImageNameCameraCursor = @"CameraCursor";
NSString *SKImageNameTextNoteCursor = @"TextNoteCursor";
NSString *SKImageNameAnchoredNoteCursor = @"AnchoredNoteCursor";
NSString *SKImageNameCircleNoteCursor = @"CircleNoteCursor";
NSString *SKImageNameSquareNoteCursor = @"SquareNoteCursor";
NSString *SKImageNameHighlightNoteCursor = @"HighlightNoteCursor";
NSString *SKImageNameUnderlineNoteCursor = @"UnderlineNoteCursor";
NSString *SKImageNameStrikeOutNoteCursor = @"StrikeOutNoteCursor";
NSString *SKImageNameLineNoteCursor = @"LineNoteCursor";
NSString *SKImageNameInkNoteCursor = @"InkNoteCursor";
NSString *SKImageNameOpenHandBarCursor = @"OpenHandBarCursor";
NSString *SKImageNameClosedHandBarCursor = @"ClosedHandBarCursor";

- (NSImage *)copyWithMenuBadge {
    NSBezierPath *arrowPath = [NSBezierPath bezierPath];
    [arrowPath moveToPoint:NSMakePoint(27.0, 10.0)];
    [arrowPath relativeLineToPoint:NSMakePoint(-5.0, 0.0)];
    [arrowPath relativeLineToPoint:NSMakePoint(2.5, -3.0)];
    [arrowPath closePath];
    
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [image lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
    [NSGraphicsContext restoreGraphicsState];
    [self drawAtPoint:NSMakePoint(0.5 * (23.0 - [self size].width), 0.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] setFill];
    [arrowPath fill];
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    
    return image;
}

- (NSImage *)copyWithAddBadge {
    NSBezierPath *addPath = [NSBezierPath bezierPath];
    [addPath appendBezierPathWithRect:NSMakeRect(17.0, 4.0, 6.0, 2.0)];
    [addPath appendBezierPathWithRect:NSMakeRect(19.0, 2.0, 2.0, 6.0)];
    
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:2.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8]];
    
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [image lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
    [NSGraphicsContext restoreGraphicsState];
    [self drawAtPoint:NSMakePoint(0.5 * (27.0 - [self size].width), 0.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [NSGraphicsContext saveGraphicsState];
    [shadow1 set];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
    [addPath fill];
    [NSGraphicsContext restoreGraphicsState];
    [image unlockFocus];
    
    [shadow1 release];
    
    return image;
}

- (NSImage *)copyArrowCursorImage {
    NSImage *arrowCursor = [[NSCursor arrowCursor] image];
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(24.0, 40.0)];
    
    [image lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 24.0, 40.0));
    [NSGraphicsContext restoreGraphicsState];
    [arrowCursor drawAtPoint:NSMakePoint(0.0, 40.0 - [arrowCursor size].height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [self drawAtPoint:NSMakePoint(3.0, 0.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [image unlockFocus];
    
    return image;
}

static void drawPageBackgroundInRect(NSRect rect) {
    NSGradient *gradient1 = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]];
    NSGradient *gradient2 = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]];
    
    [gradient1 drawInRect:rect angle:90.0];
    [gradient2 drawInRect:NSInsetRect(rect, 1.0, 1.0) angle:90.0];
    
    [gradient1 release];
    [gradient2 release];
}

#define MAKE_IMAGE(name, isTemplate, width, height, instructions)\
do {\
    static NSImage *image = nil;\
    image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];\
    [image lockFocus];\
    [[NSColor clearColor] setFill];\
    NSRectFill(NSMakeRect(0.0, 0.0, width, height));\
    instructions\
    [image unlockFocus];\
    [image setTemplate:isTemplate];\
    [image setName:name];\
} while (0)

#define MAKE_BADGED_IMAGE(name, fromName, copyMethod)\
do {\
    static NSImage *image = nil;\
    image = [[NSImage imageNamed:fromName] copyMethod];\
    [image setName:name];\
} while (0)

+ (void)makeToolbarImages {
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:2.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
    
    NSShadow *shadow2 = [[NSShadow alloc] init];
    [shadow2 setShadowBlurRadius:2.0];
    [shadow2 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow2 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8]];
    
    NSColor *fgColor = [NSColor whiteColor];
    
    NSBezierPath *path;
    NSGradient *gradient;
    
    [NSBezierPath setDefaultLineWidth:1.0];
    
    MAKE_IMAGE(SKImageNameToolbarPageUp, NO, 27.0, 19.0, 
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(10.0, 3.0)];
        [path lineToPoint:NSMakePoint(17.0, 3.0)];
        [path lineToPoint:NSMakePoint(17.0, 11.0)];
        [path lineToPoint:NSMakePoint(20.5, 11.0)];
        [path lineToPoint:NSMakePoint(13.5, 18.0)];
        [path lineToPoint:NSMakePoint(6.5, 11.0)];
        [path lineToPoint:NSMakePoint(10.0, 11.0)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarPageDown, NO, 27.0, 19.0, 
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(10.0, 17.0)];
        [path lineToPoint:NSMakePoint(17.0, 17.0)];
        [path lineToPoint:NSMakePoint(17.0, 9.0)];
        [path lineToPoint:NSMakePoint(20.5, 9.0)];
        [path lineToPoint:NSMakePoint(13.5, 2.0)];
        [path lineToPoint:NSMakePoint(6.5, 9.0)];
        [path lineToPoint:NSMakePoint(10.0, 9.0)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarFirstPage, NO, 27.0, 19.0, 
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(10.0, 3.0)];
        [path lineToPoint:NSMakePoint(17.0, 3.0)];
        [path lineToPoint:NSMakePoint(17.0, 6.0)];
        [path lineToPoint:NSMakePoint(10.0, 6.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(10.0, 8.0)];
        [path lineToPoint:NSMakePoint(17.0, 8.0)];
        [path lineToPoint:NSMakePoint(17.0, 11.0)];
        [path lineToPoint:NSMakePoint(20.5, 11.0)];
        [path lineToPoint:NSMakePoint(13.5, 18.0)];
        [path lineToPoint:NSMakePoint(6.5, 11.0)];
        [path lineToPoint:NSMakePoint(10.0, 11.0)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarLastPage, NO, 27.0, 19.0, 
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(10.0, 17.0)];
        [path lineToPoint:NSMakePoint(17.0, 17.0)];
        [path lineToPoint:NSMakePoint(17.0, 14.0)];
        [path lineToPoint:NSMakePoint(10.0, 14.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(10.0, 12.0)];
        [path lineToPoint:NSMakePoint(17.0, 12.0)];
        [path lineToPoint:NSMakePoint(17.0, 9.0)];
        [path lineToPoint:NSMakePoint(20.5, 9.0)];
        [path lineToPoint:NSMakePoint(13.5, 2.0)];
        [path lineToPoint:NSMakePoint(6.5, 9.0)];
        [path lineToPoint:NSMakePoint(10.0, 9.0)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarBack, NO, 27.0, 13.0, 
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(17.0, 2.5)];
        [path lineToPoint:NSMakePoint(8.5, 7.0)];
        [path lineToPoint:NSMakePoint(17.0, 11.5)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarForward, NO, 27.0, 13.0, 
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(10.0, 2.5)];
        [path lineToPoint:NSMakePoint(18.5, 7.0)];
        [path lineToPoint:NSMakePoint(10.0, 11.5)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomIn, NO, 27.0, 19.0, 
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(7.0, 9.0, 13.0, 3.0)];
        [path appendBezierPathWithRect:NSMakeRect(12.0, 4.0, 3.0, 13.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomOut, NO, 27.0, 9.0, 
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(7.0, 4.0, 13.0, 3.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomActual, NO, 27.0, 14.0, 
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(7.0, 4.0, 13.0, 3.0)];
        [path appendBezierPathWithRect:NSMakeRect(7.0, 9.0, 13.0, 3.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomToFit, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setStroke];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
        [path setLineWidth:2.0];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(7.0, 6.0, 13.0, 9.0));
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(8.0, 7.0)];
        [path lineToPoint:NSMakePoint(11.5, 7.0)];
        [path lineToPoint:NSMakePoint(8.0, 10.5)];
        [path closePath];
        [path moveToPoint:NSMakePoint(19.0, 14.0)];
        [path lineToPoint:NSMakePoint(15.5, 14.0)];
        [path lineToPoint:NSMakePoint(19.0, 10.5)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomToSelection, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setStroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(6.0, 14.0)];
        [path lineToPoint:NSMakePoint(6.0, 16.0)];
        [path lineToPoint:NSMakePoint(9.0, 16.0)];
        [path moveToPoint:NSMakePoint(11.0, 16.0)];
        [path lineToPoint:NSMakePoint(16.0, 16.0)];
        [path moveToPoint:NSMakePoint(18.0, 16.0)];
        [path lineToPoint:NSMakePoint(21.0, 16.0)];
        [path lineToPoint:NSMakePoint(21.0, 14.0)];
        [path moveToPoint:NSMakePoint(21.0, 12.0)];
        [path lineToPoint:NSMakePoint(21.0, 9.0)];
        [path moveToPoint:NSMakePoint(21.0, 7.0)];
        [path lineToPoint:NSMakePoint(21.0, 5.0)];
        [path lineToPoint:NSMakePoint(18.0, 5.0)];
        [path moveToPoint:NSMakePoint(16.0, 5.0)];
        [path lineToPoint:NSMakePoint(11.0, 5.0)];
        [path moveToPoint:NSMakePoint(9.0, 5.0)];
        [path lineToPoint:NSMakePoint(6.0, 5.0)];
        [path lineToPoint:NSMakePoint(6.0, 7.0)];
        [path moveToPoint:NSMakePoint(6.0, 9.0)];
        [path lineToPoint:NSMakePoint(6.0, 12.0)];
        [path setLineWidth:2.0];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(7.0, 6.0, 13.0, 9.0));
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(8.0, 7.0)];
        [path lineToPoint:NSMakePoint(11.5, 7.0)];
        [path lineToPoint:NSMakePoint(8.0, 10.5)];
        [path closePath];
        [path moveToPoint:NSMakePoint(19.0, 14.0)];
        [path lineToPoint:NSMakePoint(15.5, 14.0)];
        [path lineToPoint:NSMakePoint(19.0, 10.5)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarRotateLeft, NO, 27.0, 21.0, 
        [shadow1 set];
        [fgColor set];
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(13.5, 10.0) radius:6.0 startAngle:-180.0 endAngle:90.0 clockwise:NO];
        [path lineToPoint:NSMakePoint(13.5, 19.0)];
        [path lineToPoint:NSMakePoint(9.0, 14.5)];
        [path lineToPoint:NSMakePoint(13.5, 10.0)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(13.5, 10.0) radius:3.0 startAngle:90.0 endAngle:-180.0 clockwise:YES];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarRotateRight, NO, 27.0, 21.0, 
        [shadow1 set];
        [fgColor set];
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(13.5, 10.0) radius:6.0 startAngle:360.0 endAngle:90.0 clockwise:YES];
        [path lineToPoint:NSMakePoint(13.5, 19.0)];
        [path lineToPoint:NSMakePoint(18.0, 14.5)];
        [path lineToPoint:NSMakePoint(13.5, 10.0)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(13.5, 10.0) radius:3.0 startAngle:90.0 endAngle:360.0 clockwise:NO];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarCrop, NO, 27.0, 21.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setStroke];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
        [path setLineWidth:2.0];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(7.0, 6.0, 13.0, 9.0));
        [shadow2 set];
        [[NSColor colorWithCalibratedRed:1.0 green:0.865 blue:0.296 alpha:1.0] setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 7.0, 21.0, 2.0)];
        [path fill];
        [[NSColor colorWithCalibratedRed:1.0 green:0.906 blue:0.496 alpha:1.0] setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(17.0, 2.0, 2.0, 17.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarFullScreen, NO, 27.0, 21.0, 
        [shadow1 set];
        [fgColor set];
        path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.0, 4.0, 17.0, 14.0) xRadius:2.0 yRadius:2.0];
        [path appendBezierPathWithRect:NSMakeRect(7.0, 6.0, 13.0, 10.0)];
        [path moveToPoint:NSMakePoint(8.0, 7.0)];
        [path lineToPoint:NSMakePoint(11.0, 7.0)];
        [path lineToPoint:NSMakePoint(8.0, 10.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(8.0, 15.0)];
        [path lineToPoint:NSMakePoint(8.0, 12.0)];
        [path lineToPoint:NSMakePoint(11.0, 15.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(19.0, 7.0)];
        [path lineToPoint:NSMakePoint(19.0, 10.0)];
        [path lineToPoint:NSMakePoint(16.0, 7.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(19.0, 15.0)];
        [path lineToPoint:NSMakePoint(16.0, 15.0)];
        [path lineToPoint:NSMakePoint(19.0, 12.0)];
        [path closePath];
        [path setWindingRule:NSEvenOddWindingRule];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarPresentation, NO, 27.0, 21.0, 
        [shadow1 set];
        [fgColor set];
        path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.0, 4.0, 17.0, 14.0) xRadius:2.0 yRadius:2.0];
        [path appendBezierPathWithRect:NSMakeRect(7.0, 6.0, 13.0, 10.0)];
        [path moveToPoint:NSMakePoint(11.0, 7.0)];
        [path lineToPoint:NSMakePoint(18.5, 11.0)];
        [path lineToPoint:NSMakePoint(11.0, 15.0)];
        [path setWindingRule:NSEvenOddWindingRule];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarSinglePage, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(10.0, 5.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarTwoUp, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 12.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(6.0, 5.0, 7.0 , 10.0));
        drawPageBackgroundInRect(NSMakeRect(14.0, 5.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarSinglePageContinuous, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
        [path addClip];
        drawPageBackgroundInRect(NSMakeRect(10.0, 11.0, 7.0 , 10.0));
        drawPageBackgroundInRect(NSMakeRect(10.0, 0.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarTwoUpContinuous, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 12.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 4.0, 19.0 , 12.0)];
        [path addClip];
        drawPageBackgroundInRect(NSMakeRect(6.0, 11.0, 7.0 , 10.0));
        drawPageBackgroundInRect(NSMakeRect(14.0, 11.0, 7.0 , 10.0));
        drawPageBackgroundInRect(NSMakeRect(6.0, 0.0, 7.0 , 10.0));
        drawPageBackgroundInRect(NSMakeRect(14.0, 0.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarBookMode, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 9.0, 9.0 , 7.0)];
        [path appendBezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 6.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 4.0, 19.0 , 12.0)];
        [path addClip];
        drawPageBackgroundInRect(NSMakeRect(10.0, 10.0, 7.0 , 10.0));
        drawPageBackgroundInRect(NSMakeRect(6.0, -1.0, 7.0 , 10.0));
        drawPageBackgroundInRect(NSMakeRect(14.0, -1.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarPageBreaks, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 11.0, 9.0 , 5.0)];
        [path appendBezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 5.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
        [path addClip];
        drawPageBackgroundInRect(NSMakeRect(10.0, 12.0, 7.0 , 10.0));
        drawPageBackgroundInRect(NSMakeRect(10.0, -2.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarMediaBox, NO, 27.0, 21.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setStroke];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
        [path setLineWidth:2.0];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(7.0, 6.0, 13.0, 9.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarCropBox, NO, 27.0, 21.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setStroke];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
        [path setLineWidth:2.0];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(7.0, 6.0, 13.0, 9.0));
        [shadow2 set];
        [[NSColor colorWithCalibratedRed:1.0 green:0.865 blue:0.296 alpha:1.0] setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 7.0, 21.0, 2.0)];
        [path fill];
        [[NSColor colorWithCalibratedRed:1.0 green:0.906 blue:0.496 alpha:1.0] setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(17.0, 2.0, 2.0, 17.0)];
        [path fill];
    );
    
    CGFloat outStartGray = 0.925, outEndGray = 1.0, inStartGray = 0.868, inEndGray = 1.0;
    
    MAKE_IMAGE(SKImageNameToolbarLeftPane, NO, 27.0, 17.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow2 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:outStartGray green:outStartGray blue:outStartGray alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:outEndGray green:outEndGray blue:outEndGray alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:inStartGray green:inStartGray blue:inStartGray alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:inEndGray green:inEndGray blue:inEndGray alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(12.0, 5.0, 9.0, 9.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.431 green:0.478 blue:0.589 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.714 green:0.744 blue:0.867 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(10.0, 4.0, 1.0, 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.502 green:0.537 blue:0.640 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.761 green:0.784 blue:0.900 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(5.0, 4.0, 5.0, 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.382 green:0.435 blue:0.547 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.696 green:0.722 blue:0.843 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(6.0, 5.0, 3.0, 9.0) angle:90.0];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(6.0, 5.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(6.0, 7.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(6.0, 9.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(6.0, 11.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(6.0, 13.0, 3.0, 1.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarRightPane, NO, 27.0, 17.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow2 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:outStartGray green:outStartGray blue:outStartGray alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:outEndGray green:outEndGray blue:outEndGray alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:inStartGray green:inStartGray blue:inStartGray alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:inEndGray green:inEndGray blue:inEndGray alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(6.0, 5.0, 9.0, 9.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.431 green:0.478 blue:0.589 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.714 green:0.744 blue:0.867 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(16.0, 4.0, 1.0, 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.502 green:0.537 blue:0.640 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.761 green:0.784 blue:0.900 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(17.0, 4.0, 5.0, 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.382 green:0.435 blue:0.547 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.696 green:0.722 blue:0.843 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(18.0, 5.0, 3.0, 9.0) angle:90.0];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(18.0, 5.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(18.0, 7.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(18.0, 9.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(18.0, 11.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(18.0, 13.0, 3.0, 1.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarTextTool, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(7.0, 4.0, 13.0, 13.0)];
        [path setWindingRule:NSEvenOddWindingRule];
        [path moveToPoint:NSMakePoint(8.5, 6.0)];
        [path lineToPoint:NSMakePoint(12.5, 15.0)];
        [path lineToPoint:NSMakePoint(14.5, 15.0)];
        [path lineToPoint:NSMakePoint(18.5, 6.0)];
        [path lineToPoint:NSMakePoint(16.5, 6.0)];
        [path lineToPoint:NSMakePoint(15.6, 8.0)];
        [path lineToPoint:NSMakePoint(11.4, 8.0)];
        [path lineToPoint:NSMakePoint(10.5, 6.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(12.3, 10.0)];
        [path lineToPoint:NSMakePoint(14.7, 10.0)];
        [path lineToPoint:NSMakePoint(13.5, 12.75)];
        [path closePath];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        [path setClip];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.976 green:0.976 blue:0.976 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.798 green:0.798 blue:0.798 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(7.0, 4.0, 13.0, 6.0) angle:90.0];
    );
    
    MAKE_IMAGE(SKImageNameToolbarMagnifyTool, NO, 27.0, 19.0, 
        [shadow1 set];
        [fgColor setStroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(15.0, 8.0)];
        [path lineToPoint:NSMakePoint(19.0, 4.0)];
        [path setLineWidth:3.0];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithOvalInRect:NSMakeRect(7.0, 7.0, 9.0, 9.0)];
        [path setLineWidth:2.0];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarSelectTool, NO, 27.0, 19.0, 
        [shadow1 set];
        [fgColor setStroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(8.0, 14.0)];
        [path lineToPoint:NSMakePoint(8.0, 16.0)];
        [path lineToPoint:NSMakePoint(10.0, 16.0)];
        [path moveToPoint:NSMakePoint(12.0, 16.0)];
        [path lineToPoint:NSMakePoint(15.0, 16.0)];
        [path moveToPoint:NSMakePoint(17.0, 16.0)];
        [path lineToPoint:NSMakePoint(19.0, 16.0)];
        [path lineToPoint:NSMakePoint(19.0, 14.0)];
        [path moveToPoint:NSMakePoint(19.0, 12.0)];
        [path lineToPoint:NSMakePoint(19.0, 9.0)];
        [path moveToPoint:NSMakePoint(19.0, 7.0)];
        [path lineToPoint:NSMakePoint(19.0, 5.0)];
        [path lineToPoint:NSMakePoint(17.0, 5.0)];
        [path moveToPoint:NSMakePoint(15.0, 5.0)];
        [path lineToPoint:NSMakePoint(12.0, 5.0)];
        [path moveToPoint:NSMakePoint(10.0, 5.0)];
        [path lineToPoint:NSMakePoint(8.0, 5.0)];
        [path lineToPoint:NSMakePoint(8.0, 7.0)];
        [path moveToPoint:NSMakePoint(8.0, 9.0)];
        [path lineToPoint:NSMakePoint(8.0, 12.0)];
        [path setLineWidth:2.0];
        [path stroke];
    );
    
    MAKE_BADGED_IMAGE(SKImageNameToolbarTextNoteMenu, SKImageNameTextNote, copyWithMenuBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddTextNote, SKImageNameTextNote, copyWithAddBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddTextNoteMenu, SKImageNameToolbarAddTextNote, copyWithMenuBadge);
    
    MAKE_BADGED_IMAGE(SKImageNameToolbarAnchoredNoteMenu, SKImageNameAnchoredNote, copyWithMenuBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddAnchoredNote, SKImageNameAnchoredNote, copyWithAddBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddAnchoredNoteMenu, SKImageNameToolbarAddTextNote, copyWithMenuBadge);
    
    MAKE_BADGED_IMAGE(SKImageNameToolbarCircleNoteMenu, SKImageNameCircleNote, copyWithMenuBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddCircleNote, SKImageNameCircleNote, copyWithAddBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddCircleNoteMenu, SKImageNameToolbarAddCircleNote, copyWithMenuBadge);
    
    MAKE_BADGED_IMAGE(SKImageNameToolbarSquareNoteMenu, SKImageNameSquareNote, copyWithMenuBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddSquareNote, SKImageNameSquareNote, copyWithAddBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddSquareNoteMenu, SKImageNameToolbarAddSquareNote, copyWithMenuBadge);
    
    MAKE_BADGED_IMAGE(SKImageNameToolbarHighlightNoteMenu, SKImageNameHighlightNote, copyWithMenuBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddHighlightNote, SKImageNameHighlightNote, copyWithAddBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddHighlightNoteMenu, SKImageNameToolbarAddHighlightNote, copyWithMenuBadge);
        
    MAKE_BADGED_IMAGE(SKImageNameToolbarUnderlineNoteMenu, SKImageNameUnderlineNote, copyWithMenuBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddUnderlineNote, SKImageNameUnderlineNote, copyWithAddBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddUnderlineNoteMenu, SKImageNameToolbarAddUnderlineNote, copyWithMenuBadge);
    
    MAKE_BADGED_IMAGE(SKImageNameToolbarStrikeOutNoteMenu, SKImageNameStrikeOutNote, copyWithMenuBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddStrikeOutNote, SKImageNameStrikeOutNote, copyWithAddBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddStrikeOutNoteMenu, SKImageNameToolbarAddStrikeOutNote, copyWithMenuBadge);
    
    MAKE_BADGED_IMAGE(SKImageNameToolbarLineNoteMenu, SKImageNameLineNote, copyWithMenuBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddLineNote, SKImageNameLineNote, copyWithAddBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddLineNoteMenu, SKImageNameToolbarAddLineNote, copyWithMenuBadge);
    
    MAKE_BADGED_IMAGE(SKImageNameToolbarInkNoteMenu, SKImageNameInkNote, copyWithMenuBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddInkNote, SKImageNameInkNote, copyWithAddBadge);
    MAKE_BADGED_IMAGE(SKImageNameToolbarAddInkNoteMenu, SKImageNameToolbarAddInkNote, copyWithMenuBadge);
    
    [shadow1 release];
    [shadow2 release];
}

+ (void)makeNoteImages {
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:2.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
    
    NSShadow *shadow2 = [[NSShadow alloc] init];
    [shadow2 setShadowBlurRadius:2.0];
    [shadow2 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow2 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8]];
    
    NSShadow *shadow3 = [[NSShadow alloc] init];
    [shadow3 setShadowBlurRadius:2.0];
    [shadow3 setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow3 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
    
    NSColor *fgColor = [NSColor whiteColor];
    NSColor *lineColor = [NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0];
    
    NSBezierPath *path;
    NSGradient *gradient;
    
    [NSBezierPath setDefaultLineWidth:1.0];
    
    MAKE_IMAGE(SKImageNameTextNote, NO, 21.0, 19.0,
        [NSGraphicsContext saveGraphicsState];
        [shadow2 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(5.0, 5.0)];
        [path lineToPoint:NSMakePoint(9.0, 6.0)];
        [path lineToPoint:NSMakePoint(16.0, 13.0)];
        [path lineToPoint:NSMakePoint(16.0, 14.0)];
        [path lineToPoint:NSMakePoint(14.0, 16.0)];
        [path lineToPoint:NSMakePoint(13.0, 16.0)];
        [path lineToPoint:NSMakePoint(6.0, 9.0)];
        [path closePath];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(9.0, 7.0)];
        [path lineToPoint:NSMakePoint(16.0, 14.0)];
        [path lineToPoint:NSMakePoint(14.0, 16.0)];
        [path lineToPoint:NSMakePoint(7.0, 9.0)];
        [path closePath];
        [[NSColor colorWithCalibratedRed:1.0 green:0.835 blue:0.0 alpha:1.0] set];
        [path fill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(9.0, 6.0)];
        [path lineToPoint:NSMakePoint(16.0, 13.0)];
        [path lineToPoint:NSMakePoint(16.0, 14.0)];
        [path lineToPoint:NSMakePoint(9.0, 7.0)];
        [path closePath];
        [[NSColor colorWithCalibratedRed:1.0 green:0.745 blue:0.0 alpha:1.0] set];
        [path fill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(7.0, 9.0)];
        [path lineToPoint:NSMakePoint(14.0, 16.0)];
        [path lineToPoint:NSMakePoint(13.0, 16.0)];
        [path lineToPoint:NSMakePoint(6.0, 9.0)];
        [path closePath];
        [[NSColor colorWithCalibratedRed:1.0 green:0.925 blue:0.0 alpha:1.0] set];
        [path fill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(6.0, 6.5)];
        [path lineToPoint:NSMakePoint(7.0, 9.0)];
        [path lineToPoint:NSMakePoint(6.0, 9.0)];
        [path lineToPoint:NSMakePoint(5.5, 7.0)];
        [path closePath];
        [[NSColor colorWithCalibratedRed:1.0 green:0.98 blue:0.9 alpha:1.0] set];
        [path fill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(6.5, 6.0)];
        [path lineToPoint:NSMakePoint(9.0, 7.0)];
        [path lineToPoint:NSMakePoint(7.0, 9.0)];
        [path lineToPoint:NSMakePoint(6.0, 6.5)];
        [path closePath];
        [[NSColor colorWithCalibratedRed:1.0 green:0.95 blue:0.8 alpha:1.0] set];
        [path fill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(7.0, 5.5)];
        [path lineToPoint:NSMakePoint(9.0, 6.0)];
        [path lineToPoint:NSMakePoint(9.0, 7.0)];
        [path lineToPoint:NSMakePoint(6.5, 6.0)];
        [path closePath];
        [[NSColor colorWithCalibratedRed:0.85 green:0.75 blue:0.6 alpha:1.0] set];
        [path fill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(5.0, 5.0)];
        [path lineToPoint:NSMakePoint(7.0, 5.5)];
        [path lineToPoint:NSMakePoint(5.5, 7.0)];
        [path closePath];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] set];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameAnchoredNote, NO, 21.0, 19.0,
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(12.0, 6.0)];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(17.0, 6.0) toPoint:NSMakePoint(17.0, 16.0) radius:3.0];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(17.0, 16.0) toPoint:NSMakePoint(3.0, 16.0) radius:3.0];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(3.0, 16.0) toPoint:NSMakePoint(3.0, 6.0) radius:3.0];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(3.0, 6.0) toPoint:NSMakePoint(17.0, 6.0) radius:3.0];
        [path lineToPoint:NSMakePoint(9.0, 6.0)];
        [path lineToPoint:NSMakePoint(8.0, 3.0)];
        [path closePath];
        [path appendBezierPathWithRect:NSMakeRect(9.0, 7.0, 2.0, 2.0)];
        [path appendBezierPathWithRect:NSMakeRect(9.0, 10.0, 2.0, 4.0)];
        [path setWindingRule:NSEvenOddWindingRule];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(3.0, 10.0)];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(3.0, 6.0) toPoint:NSMakePoint(17.0, 6.0) radius:3.0];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(17.0, 6.0) toPoint:NSMakePoint(17.0, 10.0) radius:3.0];
        [path lineToPoint:NSMakePoint(17.0, 10.0)];
        [path closePath];
        [path appendBezierPathWithRect:NSMakeRect(9.0, 7.0, 2.0, 2.0)];
        [path setWindingRule:NSEvenOddWindingRule];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.988 green:0.988 blue:0.988 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.762 green:0.762 blue:0.762 alpha:1.0]] autorelease];
        [gradient drawInBezierPath:path angle:90.0];
    );
    
    MAKE_IMAGE(SKImageNameCircleNote, NO, 21.0, 19.0,
        [shadow3 set];
        [lineColor setStroke];
        path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(4.0, 5.0, 13.0, 10.0)];
        [path setLineWidth:2.0];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameSquareNote, NO, 21.0, 19.0,
        [shadow3 set];
        [lineColor setStroke];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 5.0, 13.0, 10.0)];
        [path setLineWidth:2.0];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameHighlightNote, NO, 21.0, 19.0,
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:1.0 green:0.925 blue:0.0 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:1.0 green:0.745 blue:0.0 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(3.0, 2.0, 15.0, 16.0) angle:90.0];
        [shadow1 setShadowColor:lineColor];
        [shadow1 set];
        [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(5.5, 5.0)];
        [path lineToPoint:NSMakePoint(9.5, 15.0)];
        [path lineToPoint:NSMakePoint(11.5, 15.0)];
        [path lineToPoint:NSMakePoint(15.5, 5.0)];
        [path lineToPoint:NSMakePoint(13.5, 5.0)];
        [path lineToPoint:NSMakePoint(12.7, 7.0)];
        [path lineToPoint:NSMakePoint(8.3, 7.0)];
        [path lineToPoint:NSMakePoint(7.5, 5.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(9.1, 9.0)];
        [path lineToPoint:NSMakePoint(11.9, 9.0)];
        [path lineToPoint:NSMakePoint(10.5, 12.5)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameUnderlineNote, NO, 21.0, 19.0,
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(5.5, 6.0)];
        [path lineToPoint:NSMakePoint(9.5, 16.0)];
        [path lineToPoint:NSMakePoint(11.5, 16.0)];
        [path lineToPoint:NSMakePoint(15.5, 6.0)];
        [path lineToPoint:NSMakePoint(13.5, 6.0)];
        [path lineToPoint:NSMakePoint(12.7, 8.0)];
        [path lineToPoint:NSMakePoint(8.3, 8.0)];
        [path lineToPoint:NSMakePoint(7.5, 6.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(9.1, 10.0)];
        [path lineToPoint:NSMakePoint(11.9, 10.0)];
        [path lineToPoint:NSMakePoint(10.5, 13.5)];
        [path closePath];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        [lineColor setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(2.0, 3.0, 17.0, 2.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameStrikeOutNote, NO, 21.0, 19.0,
        [NSGraphicsContext saveGraphicsState];
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(5.5, 4.0)];
        [path lineToPoint:NSMakePoint(9.5, 14.0)];
        [path lineToPoint:NSMakePoint(11.5, 14.0)];
        [path lineToPoint:NSMakePoint(15.5, 4.0)];
        [path lineToPoint:NSMakePoint(13.5, 4.0)];
        [path lineToPoint:NSMakePoint(12.7, 6.0)];
        [path lineToPoint:NSMakePoint(8.3, 6.0)];
        [path lineToPoint:NSMakePoint(7.5, 4.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(9.1, 8.0)];
        [path lineToPoint:NSMakePoint(11.9, 8.0)];
        [path lineToPoint:NSMakePoint(10.5, 11.5)];
        [path closePath];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        [lineColor setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(2.0, 7.0, 17.0, 2.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameLineNote, NO, 21.0, 19.0,
        [shadow3 set];
        [lineColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(3.0, 10.0)];
        [path lineToPoint:NSMakePoint(15.0, 10.0)];
        [path lineToPoint:NSMakePoint(15.0, 7.5)];
        [path lineToPoint:NSMakePoint(18.5, 11.0)];
        [path lineToPoint:NSMakePoint(15.0, 14.5)];
        [path lineToPoint:NSMakePoint(15.0, 12.0)];
        [path lineToPoint:NSMakePoint(3.0, 12.0)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameInkNote, NO, 21.0, 19.0,
        [shadow3 set];
        [lineColor setStroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(4.0, 9.0)];
        [path curveToPoint:NSMakePoint(10.5, 10.0) controlPoint1:NSMakePoint(10.0, 5.0) controlPoint2:NSMakePoint(13.0, 5.0)];
        [path curveToPoint:NSMakePoint(17.0, 11.0) controlPoint1:NSMakePoint(8.0, 15.0) controlPoint2:NSMakePoint(11.0, 15.0)];
        [path setLineWidth:2.0];
        [path stroke];
    );
    
    [shadow1 release];
    [shadow2 release];
    [shadow3 release];
}

+ (void)makeAdornImages {
    NSColor *color = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
    
    NSBezierPath *path;
    
    MAKE_IMAGE(SKImageNameOutlineViewAdorn, YES, 25.0, 14.0, 
        [color setStroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(7.0, 2.5)];
        [path lineToPoint:NSMakePoint(18.0, 2.5)];
        [path moveToPoint:NSMakePoint(7.0, 5.5)];
        [path lineToPoint:NSMakePoint(18.0, 5.5)];
        [path moveToPoint:NSMakePoint(7.0, 8.5)];
        [path lineToPoint:NSMakePoint(18.0, 8.5)];
        [path moveToPoint:NSMakePoint(7.0, 11.5)];
        [path lineToPoint:NSMakePoint(18.0, 11.5)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameThumbnailViewAdorn, YES, 25.0, 14.0, 
        [color setStroke];
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(10.5, 1.5, 4.0, 4.0)];
        [path appendBezierPathWithRect:NSMakeRect(10.5, 8.5, 4.0, 4.0)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameNoteViewAdorn, YES, 25.0, 14.0, 
        [color setStroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(13.0, 3.5)];
        [path lineToPoint:NSMakePoint(18.0, 3.5)];
        [path moveToPoint:NSMakePoint(13.0, 10.5)];
        [path lineToPoint:NSMakePoint(18.0, 10.5)];
        [path moveToPoint:NSMakePoint(10.0, 1.5)];
        [path lineToPoint:NSMakePoint(7.5, 1.5)];
        [path lineToPoint:NSMakePoint(7.5, 5.5)];
        [path lineToPoint:NSMakePoint(11.5, 5.5)];
        [path lineToPoint:NSMakePoint(11.5, 3.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(10.5, 1.5)];
        [path lineToPoint:NSMakePoint(10.5, 2.5)];
        [path lineToPoint:NSMakePoint(11.5, 2.5)];
        [path moveToPoint:NSMakePoint(10.0, 8.5)];
        [path lineToPoint:NSMakePoint(7.5, 8.5)];
        [path lineToPoint:NSMakePoint(7.5, 12.5)];
        [path lineToPoint:NSMakePoint(11.5, 12.5)];
        [path lineToPoint:NSMakePoint(11.5, 10.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(10.5, 8.5)];
        [path lineToPoint:NSMakePoint(10.5, 9.5)];
        [path lineToPoint:NSMakePoint(11.5, 9.5)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameSnapshotViewAdorn, YES, 25.0, 14.0, 
        [color setStroke];
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(7.5, 1.5, 10.0, 4.0)];
        [path appendBezierPathWithRect:NSMakeRect(7.5, 8.5, 10.0, 4.0)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameFindViewAdorn, YES, 25.0, 14.0, 
        [color setStroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(7.0, 2.5)];
        [path lineToPoint:NSMakePoint(9.0, 2.5)];
        [path moveToPoint:NSMakePoint(7.0, 5.5)];
        [path lineToPoint:NSMakePoint(9.0, 5.5)];
        [path moveToPoint:NSMakePoint(7.0, 8.5)];
        [path lineToPoint:NSMakePoint(9.0, 8.5)];
        [path moveToPoint:NSMakePoint(7.0, 11.5)];
        [path lineToPoint:NSMakePoint(9.0, 11.5)];
        [path moveToPoint:NSMakePoint(10.0, 2.5)];
        [path lineToPoint:NSMakePoint(18.0, 2.5)];
        [path moveToPoint:NSMakePoint(10.0, 5.5)];
        [path lineToPoint:NSMakePoint(18.0, 5.5)];
        [path moveToPoint:NSMakePoint(10.0, 8.5)];
        [path lineToPoint:NSMakePoint(18.0, 8.5)];
        [path moveToPoint:NSMakePoint(10.0, 11.5)];
        [path lineToPoint:NSMakePoint(18.0, 11.5)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameGroupedFindViewAdorn, YES, 25.0, 14.0, 
        [color setStroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(7.0, 3.0)];
        [path lineToPoint:NSMakePoint(12.0, 3.0)];
        [path moveToPoint:NSMakePoint(7.0, 7.0)];
        [path lineToPoint:NSMakePoint(16.0, 7.0)];
        [path moveToPoint:NSMakePoint(7.0, 11.0)];
        [path lineToPoint:NSMakePoint(18.0, 11.0)];
        [path setLineWidth:2.0];
        [path stroke];
    );
}

+ (void)makeTextAlignImages {
    NSBezierPath *path;
    
    MAKE_IMAGE(SKImageNameTextAlignLeft, NO, 16.0, 11.0, 
        [[NSColor blackColor] setStroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(1.0, 1.5)];
        [path lineToPoint:NSMakePoint(15.0, 1.5)];
        [path moveToPoint:NSMakePoint(1.0, 3.5)];
        [path lineToPoint:NSMakePoint(12.0, 3.5)];
        [path moveToPoint:NSMakePoint(1.0, 5.5)];
        [path lineToPoint:NSMakePoint(14.0, 5.5)];
        [path moveToPoint:NSMakePoint(1.0, 7.5)];
        [path lineToPoint:NSMakePoint(11.0, 7.5)];
        [path moveToPoint:NSMakePoint(1.0, 9.5)];
        [path lineToPoint:NSMakePoint(15.0, 9.5)];
        [path setLineWidth:1.0];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameTextAlignCenter, NO, 16.0, 11.0, 
        [[NSColor blackColor] setStroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(1.0, 1.5)];
        [path lineToPoint:NSMakePoint(15.0, 1.5)];
        [path moveToPoint:NSMakePoint(4.0, 3.5)];
        [path lineToPoint:NSMakePoint(12.0, 3.5)];
        [path moveToPoint:NSMakePoint(2.0, 5.5)];
        [path lineToPoint:NSMakePoint(14.0, 5.5)];
        [path moveToPoint:NSMakePoint(5.0, 7.5)];
        [path lineToPoint:NSMakePoint(11.0, 7.5)];
        [path moveToPoint:NSMakePoint(1.0, 9.5)];
        [path lineToPoint:NSMakePoint(15.0, 9.5)];
        [path setLineWidth:1.0];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameTextAlignRight, NO, 16.0, 11.0, 
        [[NSColor blackColor] setStroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(1.0, 1.5)];
        [path lineToPoint:NSMakePoint(15.0, 1.5)];
        [path moveToPoint:NSMakePoint(4.0, 3.5)];
        [path lineToPoint:NSMakePoint(15.0, 3.5)];
        [path moveToPoint:NSMakePoint(2.0, 5.5)];
        [path lineToPoint:NSMakePoint(15.0, 5.5)];
        [path moveToPoint:NSMakePoint(5.0, 7.5)];
        [path lineToPoint:NSMakePoint(15.0, 7.5)];
        [path moveToPoint:NSMakePoint(1.0, 9.5)];
        [path lineToPoint:NSMakePoint(15.0, 9.5)];
        [path setLineWidth:1.0];
        [path stroke];
    );
}

+ (void)makeCursorImages {
    NSColor *fgColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
    NSColor *bgColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
    
    NSBezierPath *path;
    
    MAKE_IMAGE(SKImageNameResizeDiagonal45Cursor, NO, 16.0, 16.0, 
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        [bgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(2.0, 2.0)];
        [path lineToPoint:NSMakePoint(8.0, 2.0)];
        [path lineToPoint:NSMakePoint(8.0, 4.0)];
        [path lineToPoint:NSMakePoint(7.0, 5.0)];
        [path lineToPoint:NSMakePoint(8.0, 6.0)];
        [path lineToPoint:NSMakePoint(13.0, 1.0)];
        [path lineToPoint:NSMakePoint(15.0, 3.0)];
        [path lineToPoint:NSMakePoint(10.0, 8.0)];
        [path lineToPoint:NSMakePoint(11.0, 9.0)];
        [path lineToPoint:NSMakePoint(12.0, 8.0)];
        [path lineToPoint:NSMakePoint(14.0, 8.0)];
        [path lineToPoint:NSMakePoint(14.0, 14.0)];
        [path lineToPoint:NSMakePoint(8.0, 14.0)];
        [path lineToPoint:NSMakePoint(8.0, 12.0)];
        [path lineToPoint:NSMakePoint(9.0, 11.0)];
        [path lineToPoint:NSMakePoint(8.0, 10.0)];
        [path lineToPoint:NSMakePoint(3.0, 15.0)];
        [path lineToPoint:NSMakePoint(1.0, 13.0)];
        [path lineToPoint:NSMakePoint(6.0, 8.0)];
        [path lineToPoint:NSMakePoint(5.0, 7.0)];
        [path lineToPoint:NSMakePoint(4.0, 8.0)];
        [path lineToPoint:NSMakePoint(2.0, 8.0)];
        [path closePath];
        [path fill];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(3.0, 3.0)];
        [path lineToPoint:NSMakePoint(7.0, 3.0)];
        [path lineToPoint:NSMakePoint(5.5, 4.5)];
        [path lineToPoint:NSMakePoint(8.0, 7.0)];
        [path lineToPoint:NSMakePoint(13.0, 2.0)];
        [path lineToPoint:NSMakePoint(14.0, 3.0)];
        [path lineToPoint:NSMakePoint(9.0, 8.0)];
        [path lineToPoint:NSMakePoint(11.5, 10.5)];
        [path lineToPoint:NSMakePoint(13.0, 9.0)];
        [path lineToPoint:NSMakePoint(13.0, 13.0)];
        [path lineToPoint:NSMakePoint(9.0, 13.0)];
        [path lineToPoint:NSMakePoint(10.5, 11.5)];
        [path lineToPoint:NSMakePoint(8.0, 9.0)];
        [path lineToPoint:NSMakePoint(3.0, 14.0)];
        [path lineToPoint:NSMakePoint(2.0, 13.0)];
        [path lineToPoint:NSMakePoint(7.0, 8.0)];
        [path lineToPoint:NSMakePoint(4.5, 5.5)];
        [path lineToPoint:NSMakePoint(3.0, 7.0)];
        [path closePath];
        [path fill];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
    );
    
    MAKE_IMAGE(SKImageNameResizeDiagonal135Cursor, NO, 16.0, 16.0, 
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        [bgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(14.0, 2.0)];
        [path lineToPoint:NSMakePoint(14.0, 8.0)];
        [path lineToPoint:NSMakePoint(12.0, 8.0)];
        [path lineToPoint:NSMakePoint(11.0, 7.0)];
        [path lineToPoint:NSMakePoint(10.0, 8.0)];
        [path lineToPoint:NSMakePoint(15.0, 13.0)];
        [path lineToPoint:NSMakePoint(13.0, 15.0)];
        [path lineToPoint:NSMakePoint(8.0, 10.0)];
        [path lineToPoint:NSMakePoint(7.0, 11.0)];
        [path lineToPoint:NSMakePoint(8.0, 12.0)];
        [path lineToPoint:NSMakePoint(8.0, 14.0)];
        [path lineToPoint:NSMakePoint(2.0, 14.0)];
        [path lineToPoint:NSMakePoint(2.0, 8.0)];
        [path lineToPoint:NSMakePoint(4.0, 8.0)];
        [path lineToPoint:NSMakePoint(5.0, 9.0)];
        [path lineToPoint:NSMakePoint(6.0, 8.0)];
        [path lineToPoint:NSMakePoint(1.0, 3.0)];
        [path lineToPoint:NSMakePoint(3.0, 1.0)];
        [path lineToPoint:NSMakePoint(8.0, 6.0)];
        [path lineToPoint:NSMakePoint(9.0, 5.0)];
        [path lineToPoint:NSMakePoint(8.0, 4.0)];
        [path lineToPoint:NSMakePoint(8.0, 2.0)];
        [path closePath];
        [path fill];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(13.0, 3.0)];
        [path lineToPoint:NSMakePoint(13.0, 7.0)];
        [path lineToPoint:NSMakePoint(11.5, 5.5)];
        [path lineToPoint:NSMakePoint(9.0, 8.0)];
        [path lineToPoint:NSMakePoint(14.0, 13.0)];
        [path lineToPoint:NSMakePoint(13.0, 14.0)];
        [path lineToPoint:NSMakePoint(8.0, 9.0)];
        [path lineToPoint:NSMakePoint(5.5, 11.5)];
        [path lineToPoint:NSMakePoint(7.0, 13.0)];
        [path lineToPoint:NSMakePoint(3.0, 13.0)];
        [path lineToPoint:NSMakePoint(3.0, 9.0)];
        [path lineToPoint:NSMakePoint(4.5, 10.5)];
        [path lineToPoint:NSMakePoint(7.0, 8.0)];
        [path lineToPoint:NSMakePoint(2.0, 3.0)];
        [path lineToPoint:NSMakePoint(3.0, 2.0)];
        [path lineToPoint:NSMakePoint(8.0, 7.0)];
        [path lineToPoint:NSMakePoint(10.5, 4.5)];
        [path lineToPoint:NSMakePoint(9.0, 3.0)];
        [path closePath];
        [path fill];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
    );
    
    MAKE_IMAGE(SKImageNameZoomInCursor, NO, 16.0, 16.0, 
        [bgColor set];
        path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0.0, 3.0, 13.0, 13.0)];
        [path fill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(15.5, 0.5)];
        [path lineToPoint:NSMakePoint(10.0, 6.0)];
        [path setLineWidth:4.5];
        [path stroke];
        [fgColor setStroke];
        path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(2.0, 5.0, 9.0, 9.0)];
        [path setLineWidth:2.0];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(14.5, 1.5)];
        [path lineToPoint:NSMakePoint(9.5, 6.5)];
        [path setLineWidth:2.5];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(4.0, 9.5)];
        [path lineToPoint:NSMakePoint(9.0, 9.5)];
        [path moveToPoint:NSMakePoint(6.5, 7.0)];
        [path lineToPoint:NSMakePoint(6.5, 12.0)];
        [path setLineWidth:1.0];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameZoomOutCursor, NO, 16.0, 16.0, 
        [bgColor set];
        path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0.0, 3.0, 13.0, 13.0)];
        [path fill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(15.5, 0.5)];
        [path lineToPoint:NSMakePoint(10.0, 6.0)];
        [path setLineWidth:4.5];
        [path stroke];
        [fgColor setStroke];
        path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(2.0, 5.0, 9.0, 9.0)];
        [path setLineWidth:2.0];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(14.5, 1.5)];
        [path lineToPoint:NSMakePoint(9.5, 6.5)];
        [path setLineWidth:2.5];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(4.0, 9.5)];
        [path lineToPoint:NSMakePoint(9.0, 9.5)];
        [path setLineWidth:1.0];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameCameraCursor, NO, 16.0, 16.0, 
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
        [[NSColor whiteColor] set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 2.0, 16.0, 11.0)] fill];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(3.7, 6.7, 8.6, 8.6)] fill];
        [[NSColor blackColor] set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(1.0, 3.0, 14.0, 9.0)] fill];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(5, 8, 6, 6)] fill];
        [[NSColor whiteColor] set];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(4.3, 4.3, 7.4, 7.4)] stroke];
        path = [NSBezierPath bezierPath];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(8.0, 8.0) radius:1.8 startAngle:45.0 endAngle:225.0];
        [path closePath];
        [path fill];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
    );
    
    MAKE_IMAGE(SKImageNameOpenHandBarCursor, NO, 16.0, 16.0, 
        [[NSColor blackColor] setFill];
        [NSBezierPath fillRect:NSMakeRect(0.0, 9.0, 16.0, 3.0)];
        [[[NSCursor openHandCursor] image] drawInRect:NSMakeRect(0.0, 0.0, 16.0, 16.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    );
    
    MAKE_IMAGE(SKImageNameClosedHandBarCursor, NO, 16.0, 16.0, 
        [[NSColor blackColor] setFill];
        [NSBezierPath fillRect:NSMakeRect(0.0, 6.0, 16.0, 3.0)];
        [[[NSCursor closedHandCursor] image] drawInRect:NSMakeRect(0.0, 0.0, 16.0, 16.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    );
    
    MAKE_BADGED_IMAGE(SKImageNameTextNoteCursor, SKImageNameTextNote, copyArrowCursorImage);
    MAKE_BADGED_IMAGE(SKImageNameAnchoredNoteCursor, SKImageNameAnchoredNote, copyArrowCursorImage);
    MAKE_BADGED_IMAGE(SKImageNameCircleNoteCursor, SKImageNameCircleNote, copyArrowCursorImage);
    MAKE_BADGED_IMAGE(SKImageNameSquareNoteCursor, SKImageNameSquareNote, copyArrowCursorImage);
    MAKE_BADGED_IMAGE(SKImageNameHighlightNoteCursor, SKImageNameHighlightNote, copyArrowCursorImage);
    MAKE_BADGED_IMAGE(SKImageNameUnderlineNoteCursor, SKImageNameUnderlineNote, copyArrowCursorImage);
    MAKE_BADGED_IMAGE(SKImageNameStrikeOutNoteCursor, SKImageNameStrikeOutNote, copyArrowCursorImage);
    MAKE_BADGED_IMAGE(SKImageNameLineNoteCursor, SKImageNameLineNote, copyArrowCursorImage);
    MAKE_BADGED_IMAGE(SKImageNameInkNoteCursor, SKImageNameInkNote, copyArrowCursorImage);
}

+ (void)makeImages {
    [self makeNoteImages];
    [self makeAdornImages];
    [self makeToolbarImages];
    [self makeTextAlignImages];
    [self makeCursorImages];
}

@end
