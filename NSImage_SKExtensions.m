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
#import "NSBezierPath_SKExtensions.h"

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
NSString *SKImageNameToolbarNewFolder = @"ToolbarNewFolder";
NSString *SKImageNameToolbarNewSeparator = @"ToolbarNewSeparator";

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

+ (void)drawAddBadgeAtPoint:(NSPoint)point {
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(point.x + 2.5, point.y + 6.5)];
    [path relativeLineToPoint:NSMakePoint(4.0, 0.0)];
    [path relativeLineToPoint:NSMakePoint(0.0, -4.0)];
    [path relativeLineToPoint:NSMakePoint(3.0, 0.0)];
    [path relativeLineToPoint:NSMakePoint(0.0, 4.0)];
    [path relativeLineToPoint:NSMakePoint(4.0, 0.0)];
    [path relativeLineToPoint:NSMakePoint(0.0, 3.0)];
    [path relativeLineToPoint:NSMakePoint(-4.0, 0.0)];
    [path relativeLineToPoint:NSMakePoint(0.0, 4.0)];
    [path relativeLineToPoint:NSMakePoint(-3.0, 0.0)];
    [path relativeLineToPoint:NSMakePoint(0.0, -4.0)];
    [path relativeLineToPoint:NSMakePoint(-4.0, 0.0)];
    [path closePath];
    
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:1.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
    
    [NSGraphicsContext saveGraphicsState];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
    [path fill];
    [shadow1 set];
    [[NSColor colorWithCalibratedRed:0.257 green:0.351 blue:0.553 alpha:1.0] setStroke];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
    
    [shadow1 release];
}

+ (void)makeToolbarImages {
    static NSImage *toolbarPageUpImage = nil;
    static NSImage *toolbarPageDownImage = nil;
    static NSImage *toolbarFirstPageImage = nil;
    static NSImage *toolbarLastPageImage = nil;
    static NSImage *toolbarBackImage = nil;
    static NSImage *toolbarForwardImage = nil;
    static NSImage *toolbarZoomInImage = nil;
    static NSImage *toolbarZoomOutImage = nil;
    static NSImage *toolbarZoomActualImage = nil;
    static NSImage *toolbarZoomToFitImage = nil;
    static NSImage *toolbarZoomToSelectionImage = nil;
    static NSImage *toolbarRotateRightImage = nil;
    static NSImage *toolbarRotateLeftImage = nil;
    static NSImage *toolbarCropImage = nil;
    static NSImage *toolbarFullScreenImage = nil;
    static NSImage *toolbarPresentationImage = nil;
    static NSImage *toolbarSinglePageImage = nil;
    static NSImage *toolbarTwoUpImage = nil;
    static NSImage *toolbarSinglePageContinuousImage = nil;
    static NSImage *toolbarTwoUpContinuousImage = nil;
    static NSImage *toolbarMediaBoxImage = nil;
    static NSImage *toolbarCropBoxImage = nil;
    static NSImage *toolbarLeftPaneImage = nil;
    static NSImage *toolbarRightPaneImage = nil;
    static NSImage *toolbarTextNoteMenuImage = nil;
    static NSImage *toolbarAnchoredNoteMenuImage = nil;
    static NSImage *toolbarCircleNoteMenuImage = nil;
    static NSImage *toolbarSquareNoteMenuImage = nil;
    static NSImage *toolbarHighlightNoteMenuImage = nil;
    static NSImage *toolbarUnderlineNoteMenuImage = nil;
    static NSImage *toolbarStrikeOutNoteMenuImage = nil;
    static NSImage *toolbarLineNoteMenuImage = nil;
    static NSImage *toolbarInkNoteMenuImage = nil;
    static NSImage *toolbarAddTextNoteImage = nil;
    static NSImage *toolbarAddAnchoredNoteImage = nil;
    static NSImage *toolbarAddCircleNoteImage = nil;
    static NSImage *toolbarAddSquareNoteImage = nil;
    static NSImage *toolbarAddHighlightNoteImage = nil;
    static NSImage *toolbarAddUnderlineNoteImage = nil;
    static NSImage *toolbarAddStrikeOutNoteImage = nil;
    static NSImage *toolbarAddLineNoteImage = nil;
    static NSImage *toolbarAddInkNoteImage = nil;
    static NSImage *toolbarAddTextNoteMenuImage = nil;
    static NSImage *toolbarAddAnchoredNoteMenuImage = nil;
    static NSImage *toolbarAddCircleNoteMenuImage = nil;
    static NSImage *toolbarAddSquareNoteMenuImage = nil;
    static NSImage *toolbarAddHighlightNoteMenuImage = nil;
    static NSImage *toolbarAddUnderlineNoteMenuImage = nil;
    static NSImage *toolbarAddStrikeOutNoteMenuImage = nil;
    static NSImage *toolbarAddLineNoteMenuImage = nil;
    static NSImage *toolbarAddInkNoteMenuImage = nil;
    static NSImage *toolbarTextToolImage = nil;
    static NSImage *toolbarMagnifyToolImage = nil;
    static NSImage *toolbarSelectToolImage = nil;
    static NSImage *toolbarNewFolderImage = nil;
    static NSImage *toolbarNewSeparatorImage = nil;
    
    if (toolbarPageUpImage)
        return;
    
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:2.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
    
    NSShadow *shadow2 = [[NSShadow alloc] init];
    [shadow2 setShadowBlurRadius:2.0];
    [shadow2 setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow2 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
    
    NSShadow *shadow3 = [[NSShadow alloc] init];
    [shadow3 setShadowBlurRadius:2.0];
    [shadow3 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow3 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8]];
    
    NSColor *fgColor = [NSColor whiteColor];
    
    NSBezierPath *path;
    NSGradient *gradient;
    
    [NSBezierPath setDefaultLineWidth:1.0];
    
    toolbarPageUpImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarPageUpImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarPageUpImage unlockFocus];
    [toolbarPageUpImage setName:SKImageNameToolbarPageUp];
    
    toolbarPageDownImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarPageDownImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarPageDownImage unlockFocus];
    [toolbarPageDownImage setName:SKImageNameToolbarPageDown];
    
    toolbarFirstPageImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarFirstPageImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarFirstPageImage unlockFocus];
    [toolbarFirstPageImage setName:SKImageNameToolbarFirstPage];
    
    toolbarLastPageImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarLastPageImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarLastPageImage unlockFocus];
    [toolbarLastPageImage setName:SKImageNameToolbarLastPage];
    
    toolbarBackImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 13.0)];
    [toolbarBackImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 13.0));
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(17.0, 2.5)];
    [path lineToPoint:NSMakePoint(8.5, 7.0)];
    [path lineToPoint:NSMakePoint(17.0, 11.5)];
    [path closePath];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarBackImage unlockFocus];
    [toolbarBackImage setName:SKImageNameToolbarBack];
    
    toolbarForwardImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 13.0)];
    [toolbarForwardImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 13.0));
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(10.0, 2.5)];
    [path lineToPoint:NSMakePoint(18.5, 7.0)];
    [path lineToPoint:NSMakePoint(10.0, 11.5)];
    [path closePath];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarForwardImage unlockFocus];
    [toolbarForwardImage setName:SKImageNameToolbarForward];
    
    toolbarZoomInImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarZoomInImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(7.0, 9.0, 13.0, 3.0)];
    [path appendBezierPathWithRect:NSMakeRect(12.0, 4.0, 3.0, 13.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarZoomInImage unlockFocus];
    [toolbarZoomInImage setName:SKImageNameToolbarZoomIn];
    
    toolbarZoomOutImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 9.0)];
    [toolbarZoomOutImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 9.0));
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(7.0, 4.0, 13.0, 3.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarZoomOutImage unlockFocus];
    [toolbarZoomOutImage setName:SKImageNameToolbarZoomOut];
    
    toolbarZoomActualImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 14.0)];
    [toolbarZoomActualImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 14.0));
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(7.0, 4.0, 13.0, 3.0)];
    [path appendBezierPathWithRect:NSMakeRect(7.0, 9.0, 13.0, 3.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarZoomActualImage unlockFocus];
    [toolbarZoomActualImage setName:SKImageNameToolbarZoomActual];
    
    toolbarZoomToFitImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarZoomToFitImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
    [shadow1 set];
    [fgColor setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(7.0, 6.0, 13.0, 9.0) angle:90.0];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(8.0, 7.0, 11.0, 7.0) angle:90.0];
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarZoomToFitImage unlockFocus];
    [toolbarZoomToFitImage setName:SKImageNameToolbarZoomToFit];
    
    toolbarZoomToSelectionImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarZoomToSelectionImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
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
    [path setLineWidth:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(7.0, 6.0, 13.0, 9.0) angle:90.0];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(8.0, 7.0, 11.0, 7.0) angle:90.0];
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarZoomToSelectionImage unlockFocus];
    [toolbarZoomToSelectionImage setName:SKImageNameToolbarZoomToSelection];
    
    toolbarRotateLeftImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarRotateLeftImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 21.0));
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarRotateLeftImage unlockFocus];
    [toolbarRotateLeftImage setName:SKImageNameToolbarRotateLeft];
    
    toolbarRotateRightImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarRotateRightImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 21.0));
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarRotateRightImage unlockFocus];
    [toolbarRotateRightImage setName:SKImageNameToolbarRotateRight];
    
    toolbarCropImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarCropImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 21.0));
    [shadow1 set];
    [fgColor setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(7.0, 6.0, 13.0, 9.0) angle:90.0];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(8.0, 7.0, 11.0, 7.0) angle:90.0];
    [shadow3 set];
    [[NSColor colorWithCalibratedRed:1.0 green:0.865 blue:0.296 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 7.0, 21.0, 2.0)];
    [path fill];
    [[NSColor colorWithCalibratedRed:1.0 green:0.906 blue:0.496 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(17.0, 2.0, 2.0, 17.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarCropImage unlockFocus];
    [toolbarCropImage setName:SKImageNameToolbarCrop];
    
    toolbarFullScreenImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarFullScreenImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 21.0));
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarFullScreenImage unlockFocus];
    [toolbarFullScreenImage setName:SKImageNameToolbarFullScreen];
    
    toolbarPresentationImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarPresentationImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 21.0));
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarPresentationImage unlockFocus];
    [toolbarPresentationImage setName:SKImageNameToolbarPresentation];
    
    toolbarSinglePageImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarSinglePageImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(10.0, 5.0, 7.0 , 10.0) angle:90.0];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(11.0, 6.0, 5.0 , 8.0) angle:90.0];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarSinglePageImage unlockFocus];
    [toolbarSinglePageImage setName:SKImageNameToolbarSinglePage];
    
    toolbarTwoUpImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarTwoUpImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 4.0, 9.0 , 12.0)];
    [path appendBezierPathWithRect:NSMakeRect(14.0, 4.0, 9.0 , 12.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(5.0, 5.0, 7.0 , 10.0) angle:90.0];
    [gradient drawInRect:NSMakeRect(15.0, 5.0, 7.0 , 10.0) angle:90.0];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(6.0, 6.0, 5.0 , 8.0) angle:90.0];
    [gradient drawInRect:NSMakeRect(16.0, 6.0, 5.0 , 8.0) angle:90.0];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarTwoUpImage unlockFocus];
    [toolbarTwoUpImage setName:SKImageNameToolbarTwoUp];
    
    toolbarSinglePageContinuousImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarSinglePageContinuousImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 11.0, 9.0 , 5.0)];
    [path appendBezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 6.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
    [path addClip];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(10.0, 12.0, 7.0 , 10.0) angle:90.0];
    [gradient drawInRect:NSMakeRect(10.0, -1.0, 7.0 , 10.0) angle:90.0];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(11.0, 13.0, 5.0 , 8.0) angle:90.0];
    [gradient drawInRect:NSMakeRect(11.0, 0.0, 5.0 , 8.0) angle:90.0];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarSinglePageContinuousImage unlockFocus];
    [toolbarSinglePageContinuousImage setName:SKImageNameToolbarSinglePageContinuous];
    
    toolbarTwoUpContinuousImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarTwoUpContinuousImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 11.0, 9.0 , 5.0)];
    [path appendBezierPathWithRect:NSMakeRect(14.0, 11.0, 9.0 , 5.0)];
    [path appendBezierPathWithRect:NSMakeRect(4.0, 4.0, 9.0 , 6.0)];
    [path appendBezierPathWithRect:NSMakeRect(14.0, 4.0, 9.0 , 6.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 4.0, 19.0 , 12.0)];
    [path addClip];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(5.0, 12.0, 7.0 , 10.0) angle:90.0];
    [gradient drawInRect:NSMakeRect(15.0, 12.0, 7.0 , 10.0) angle:90.0];
    [gradient drawInRect:NSMakeRect(5.0, -1.0, 7.0 , 10.0) angle:90.0];
    [gradient drawInRect:NSMakeRect(15.0, -1.0, 7.0 , 10.0) angle:90.0];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(6.0, 13.0, 5.0 , 8.0) angle:90.0];
    [gradient drawInRect:NSMakeRect(16.0, 13.0, 5.0 , 8.0) angle:90.0];
    [gradient drawInRect:NSMakeRect(6.0, 0.0, 5.0 , 8.0) angle:90.0];
    [gradient drawInRect:NSMakeRect(16.0, 0.0, 5.0 , 8.0) angle:90.0];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarTwoUpContinuousImage unlockFocus];
    [toolbarTwoUpContinuousImage setName:SKImageNameToolbarTwoUpContinuous];
    
    toolbarMediaBoxImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarMediaBoxImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 21.0));
    [shadow1 set];
    [fgColor setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(7.0, 6.0, 13.0, 9.0) angle:90.0];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(8.0, 7.0, 11.0, 7.0) angle:90.0];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarMediaBoxImage unlockFocus];
    [toolbarMediaBoxImage setName:SKImageNameToolbarMediaBox];
    
    toolbarCropBoxImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarCropBoxImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 21.0));
    [shadow1 set];
    [fgColor setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(7.0, 6.0, 13.0, 9.0) angle:90.0];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(8.0, 7.0, 11.0, 7.0) angle:90.0];
    [shadow3 set];
    [[NSColor colorWithCalibratedRed:1.0 green:0.865 blue:0.296 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 7.0, 21.0, 2.0)];
    [path fill];
    [[NSColor colorWithCalibratedRed:1.0 green:0.906 blue:0.496 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(17.0, 2.0, 2.0, 17.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarCropBoxImage unlockFocus];
    [toolbarCropBoxImage setName:SKImageNameToolbarCropBox];
    
    CGFloat outStartGray = 0.925, outEndGray = 1.0, inStartGray = 0.868, inEndGray = 1.0;
    
    toolbarLeftPaneImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 17.0)];
    [toolbarLeftPaneImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 17.0));
    [shadow3 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarLeftPaneImage unlockFocus];
    [toolbarLeftPaneImage setName:SKImageNameToolbarLeftPane];
    
    toolbarRightPaneImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 17.0)];
    [toolbarRightPaneImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 17.0));
    [shadow3 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
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
    [NSGraphicsContext restoreGraphicsState];
    [toolbarRightPaneImage unlockFocus];
    [toolbarRightPaneImage setName:SKImageNameToolbarRightPane];
    
    toolbarTextNoteMenuImage = [[NSImage imageNamed:SKImageNameTextNote] copyWithMenuBadge];
    [toolbarTextNoteMenuImage setName:SKImageNameToolbarTextNoteMenu];
    
    toolbarAddTextNoteImage = [[NSImage imageNamed:SKImageNameTextNote] copyWithAddBadge];
    [toolbarAddTextNoteImage setName:SKImageNameToolbarAddTextNote];
    
    toolbarAddTextNoteMenuImage = [toolbarAddTextNoteImage copyWithMenuBadge];
    [toolbarAddTextNoteMenuImage setName:SKImageNameToolbarAddTextNoteMenu];
    
    toolbarAnchoredNoteMenuImage = [[NSImage imageNamed:SKImageNameAnchoredNote] copyWithMenuBadge];
    [toolbarAnchoredNoteMenuImage setName:SKImageNameToolbarAnchoredNoteMenu];
    
    toolbarAddAnchoredNoteImage = [[NSImage imageNamed:SKImageNameAnchoredNote] copyWithAddBadge];
    [toolbarAddAnchoredNoteImage setName:SKImageNameToolbarAddAnchoredNote];
    
    toolbarAddAnchoredNoteMenuImage = [toolbarAddAnchoredNoteImage copyWithMenuBadge];
    [toolbarAddAnchoredNoteMenuImage setName:SKImageNameToolbarAddAnchoredNoteMenu];

    toolbarCircleNoteMenuImage = [[NSImage imageNamed:SKImageNameCircleNote] copyWithMenuBadge];
    [toolbarCircleNoteMenuImage setName:SKImageNameToolbarCircleNoteMenu];
    
    toolbarAddCircleNoteImage = [[NSImage imageNamed:SKImageNameCircleNote] copyWithAddBadge];
    [toolbarAddCircleNoteImage setName:SKImageNameToolbarAddCircleNote];
    
    toolbarAddCircleNoteMenuImage = [toolbarAddCircleNoteImage copyWithMenuBadge];
    [toolbarAddCircleNoteMenuImage setName:SKImageNameToolbarAddCircleNoteMenu];

    toolbarSquareNoteMenuImage = [[NSImage imageNamed:SKImageNameSquareNote] copyWithMenuBadge];
    [toolbarSquareNoteMenuImage setName:SKImageNameToolbarSquareNoteMenu];
    
    toolbarAddSquareNoteImage = [[NSImage imageNamed:SKImageNameSquareNote] copyWithAddBadge];
    [toolbarAddSquareNoteImage setName:SKImageNameToolbarAddSquareNote];
    
    toolbarAddSquareNoteMenuImage = [toolbarAddSquareNoteImage copyWithMenuBadge];
    [toolbarAddSquareNoteMenuImage setName:SKImageNameToolbarAddSquareNoteMenu];
    
    toolbarHighlightNoteMenuImage = [[NSImage imageNamed:SKImageNameHighlightNote] copyWithMenuBadge];
    [toolbarHighlightNoteMenuImage setName:SKImageNameToolbarHighlightNoteMenu];
    
    toolbarAddHighlightNoteImage = [[NSImage imageNamed:SKImageNameHighlightNote] copyWithAddBadge];
    [toolbarAddHighlightNoteImage setName:SKImageNameToolbarAddHighlightNote];
    
    toolbarAddHighlightNoteMenuImage = [toolbarAddHighlightNoteImage copyWithMenuBadge];
    [toolbarAddHighlightNoteMenuImage setName:SKImageNameToolbarAddHighlightNoteMenu];

    toolbarUnderlineNoteMenuImage = [[NSImage imageNamed:SKImageNameUnderlineNote] copyWithMenuBadge];
    [toolbarUnderlineNoteMenuImage setName:SKImageNameToolbarUnderlineNoteMenu];
    
    toolbarAddUnderlineNoteImage = [[NSImage imageNamed:SKImageNameUnderlineNote] copyWithAddBadge];
    [toolbarAddUnderlineNoteImage setName:SKImageNameToolbarAddUnderlineNote];
    
    toolbarAddUnderlineNoteMenuImage = [toolbarAddUnderlineNoteImage copyWithMenuBadge];
    [toolbarAddUnderlineNoteMenuImage setName:SKImageNameToolbarAddUnderlineNoteMenu];

    toolbarStrikeOutNoteMenuImage = [[NSImage imageNamed:SKImageNameStrikeOutNote] copyWithMenuBadge];
    [toolbarStrikeOutNoteMenuImage setName:SKImageNameToolbarStrikeOutNoteMenu];
    
    toolbarAddStrikeOutNoteImage = [[NSImage imageNamed:SKImageNameStrikeOutNote] copyWithAddBadge];
    [toolbarAddStrikeOutNoteImage setName:SKImageNameToolbarAddStrikeOutNote];
    
    toolbarAddStrikeOutNoteMenuImage = [toolbarAddStrikeOutNoteImage copyWithMenuBadge];
    [toolbarAddStrikeOutNoteMenuImage setName:SKImageNameToolbarAddStrikeOutNoteMenu];

    toolbarLineNoteMenuImage = [[NSImage imageNamed:SKImageNameLineNote] copyWithMenuBadge];
    [toolbarLineNoteMenuImage setName:SKImageNameToolbarLineNoteMenu];
    
    toolbarAddLineNoteImage = [[NSImage imageNamed:SKImageNameLineNote] copyWithAddBadge];
    [toolbarAddLineNoteImage setName:SKImageNameToolbarAddLineNote];
    
    toolbarAddLineNoteMenuImage = [toolbarAddLineNoteImage copyWithMenuBadge];
    [toolbarAddLineNoteMenuImage setName:SKImageNameToolbarAddLineNoteMenu];

    toolbarInkNoteMenuImage = [[NSImage imageNamed:SKImageNameInkNote] copyWithMenuBadge];
    [toolbarInkNoteMenuImage setName:SKImageNameToolbarInkNoteMenu];
    
    toolbarAddInkNoteImage = [[NSImage imageNamed:SKImageNameInkNote] copyWithAddBadge];
    [toolbarAddInkNoteImage setName:SKImageNameToolbarAddInkNote];
    
    toolbarAddInkNoteMenuImage = [toolbarAddInkNoteImage copyWithMenuBadge];
    [toolbarAddInkNoteMenuImage setName:SKImageNameToolbarAddInkNoteMenu];
    
    toolbarTextToolImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarTextToolImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
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
    [NSGraphicsContext saveGraphicsState];
    [path setClip];
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.976 green:0.976 blue:0.976 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.798 green:0.798 blue:0.798 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(7.0, 4.0, 13.0, 6.0) angle:90.0];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarTextToolImage unlockFocus];
    [toolbarTextToolImage setName:SKImageNameToolbarTextTool];
    
    toolbarMagnifyToolImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarMagnifyToolImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
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
    [path setLineWidth:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarMagnifyToolImage unlockFocus];
    [toolbarMagnifyToolImage setName:SKImageNameToolbarMagnifyTool];
    
    toolbarSelectToolImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarSelectToolImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
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
    [path setLineWidth:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarSelectToolImage unlockFocus];
    [toolbarSelectToolImage setName:SKImageNameToolbarSelectTool];
    
    toolbarNewFolderImage = [[NSImage alloc] initWithSize:NSMakeSize(32.0, 32.0)];
    [toolbarNewFolderImage lockFocus];
    [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)] drawInRect:NSMakeRect(0.0, 0.0, 32.0, 32.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [[self class] drawAddBadgeAtPoint:NSMakePoint(18.0, 18.0)];
    [toolbarNewFolderImage unlockFocus];
    [toolbarNewFolderImage setName:SKImageNameToolbarNewFolder];
    
    toolbarNewSeparatorImage = [[NSImage alloc] initWithSize:NSMakeSize(32.0, 32.0)];
    [toolbarNewSeparatorImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, 32.0, 32.0));
    [shadow2 set];
    [[NSColor colorWithCalibratedWhite:0.35 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(2.0, 14.0, 28.0, 4.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor colorWithCalibratedWhite:0.65 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 15.0, 26.0, 2.0)];
    [path fill];
    [[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 16.0, 24.0, 1.0)];
    [path fill];
    [[NSColor colorWithCalibratedWhite:0.45 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 17.0, 26.0, 1.0)];
    [path fill];
    [[self class] drawAddBadgeAtPoint:NSMakePoint(18.0, 14.0)];
    [NSGraphicsContext restoreGraphicsState];
    [toolbarNewSeparatorImage unlockFocus];
    [toolbarNewSeparatorImage setName:SKImageNameToolbarNewSeparator];
    
    [shadow1 release];
    [shadow2 release];
    [shadow3 release];
}

+ (void)makeNoteImages {
    static NSImage *textNoteImage = nil;
    static NSImage *anchoredNoteImage = nil;
    static NSImage *circleNoteImage = nil;
    static NSImage *squareNoteImage = nil;
    static NSImage *highlightNoteImage = nil;
    static NSImage *underlineNoteImage = nil;
    static NSImage *strikeOutNoteImage = nil;
    static NSImage *lineNoteImage = nil;
    static NSImage *inkNoteImage = nil;
    
    if (textNoteImage)
        return;
    
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:2.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
    
    NSShadow *shadow2 = [[NSShadow alloc] init];
    [shadow2 setShadowBlurRadius:2.0];
    [shadow2 setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow2 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
    
    NSShadow *shadow3 = [[NSShadow alloc] init];
    [shadow3 setShadowBlurRadius:2.0];
    [shadow3 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow3 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8]];
    
    NSColor *fgColor = [NSColor whiteColor];
    
    NSBezierPath *path;
    NSGradient *gradient;
    
    NSRect rect = NSMakeRect(0.0, 0.0, 21.0, 19.0);
    NSSize size = rect.size;
    
    [NSBezierPath setDefaultLineWidth:1.0];
    
    textNoteImage = [[NSImage alloc] initWithSize:size];
    [textNoteImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [shadow3 set];
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
    [NSGraphicsContext saveGraphicsState];
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
    [NSGraphicsContext restoreGraphicsState];
    [textNoteImage unlockFocus];
    [textNoteImage setName:SKImageNameTextNote];
    
    anchoredNoteImage = [[NSImage alloc] initWithSize:size];
    [anchoredNoteImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
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
    [NSGraphicsContext saveGraphicsState];
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
    [NSGraphicsContext restoreGraphicsState];
    [anchoredNoteImage unlockFocus];
    [anchoredNoteImage setName:SKImageNameAnchoredNote];
    
    circleNoteImage = [[NSImage alloc] initWithSize:size];
    [circleNoteImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [shadow2 set];
    [[NSColor colorWithCalibratedRed:0.768 green:0.0 blue:0.0 alpha:1.0] setStroke];
    path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(4.0, 5.0, 13.0, 10.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [circleNoteImage unlockFocus];
    [circleNoteImage setName:SKImageNameCircleNote];

    squareNoteImage = [[NSImage alloc] initWithSize:size];
    [squareNoteImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [shadow2 set];
    [[NSColor colorWithCalibratedRed:0.768 green:0.0 blue:0.0 alpha:1.0] setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 5.0, 13.0, 10.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [squareNoteImage unlockFocus];
    [squareNoteImage setName:SKImageNameSquareNote];
    
    highlightNoteImage = [[NSImage alloc] initWithSize:size];
    [highlightNoteImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:1.0 green:0.925 blue:0.0 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:1.0 green:0.745 blue:0.0 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(3.0, 2.0, 15.0, 16.0) angle:90.0];
    NSShadow *redShadow = [[NSShadow alloc] init];
    [redShadow setShadowBlurRadius:2.0];
    [redShadow setShadowOffset:NSZeroSize];
    [redShadow setShadowColor:[NSColor colorWithCalibratedRed:0.7 green:0.0 blue:0.0 alpha:1.0]];
    [redShadow set];
    [redShadow release];
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
    [NSGraphicsContext restoreGraphicsState];
    [highlightNoteImage unlockFocus];
    [highlightNoteImage setName:SKImageNameHighlightNote];

    underlineNoteImage = [[NSImage alloc] initWithSize:size];
    [underlineNoteImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
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
    [NSGraphicsContext saveGraphicsState];
    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(2.0, 3.0, 17.0, 2.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [underlineNoteImage unlockFocus];
    [underlineNoteImage setName:SKImageNameUnderlineNote];

    strikeOutNoteImage = [[NSImage alloc] initWithSize:size];
    [strikeOutNoteImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
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
    [NSGraphicsContext saveGraphicsState];
    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(2.0, 7.0, 17.0, 2.0)];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [strikeOutNoteImage unlockFocus];
    [strikeOutNoteImage setName:SKImageNameStrikeOutNote];

    lineNoteImage = [[NSImage alloc] initWithSize:size];
    [lineNoteImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [shadow2 set];
    [[NSColor colorWithCalibratedRed:0.706 green:0.0 blue:0.0 alpha:1.0] setFill];
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
    [NSGraphicsContext restoreGraphicsState];
    [lineNoteImage unlockFocus];
    [lineNoteImage setName:SKImageNameLineNote];

    inkNoteImage = [[NSImage alloc] initWithSize:size];
    [inkNoteImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [shadow2 set];
    [[NSColor colorWithCalibratedRed:0.706 green:0.0 blue:0.0 alpha:1.0] setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.0, 9.0)];
    [path curveToPoint:NSMakePoint(10.5, 10.0) controlPoint1:NSMakePoint(10.0, 5.0) controlPoint2:NSMakePoint(13.0, 5.0)];
    [path curveToPoint:NSMakePoint(17.0, 11.0) controlPoint1:NSMakePoint(8.0, 15.0) controlPoint2:NSMakePoint(11.0, 15.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [inkNoteImage unlockFocus];
    [inkNoteImage setName:SKImageNameInkNote];
    
    [shadow1 release];
    [shadow2 release];
    [shadow3 release];
}

+ (void)makeAdornImages {
    static NSImage *outlineViewAdornImage = nil;
    static NSImage *thumbnailViewAdornImage = nil;
    static NSImage *noteViewAdornImage = nil;
    static NSImage *snapshotViewAdornImage = nil;
    static NSImage *findViewAdornImage = nil;
    static NSImage *groupedFindViewAdornImage = nil;
    
    if (outlineViewAdornImage)
        return;
    
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:0.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.1]];
    
    NSSize size = NSMakeSize(25.0, 14.0);
    NSRect rect = {NSZeroPoint, size};
    
    NSColor *color = [NSColor colorWithCalibratedWhite:0.0 alpha:0.85];
    
    NSBezierPath *path;
    
    outlineViewAdornImage = [[NSImage alloc] initWithSize:size];
    [outlineViewAdornImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [shadow1 set];
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
    [NSGraphicsContext restoreGraphicsState];
    [outlineViewAdornImage unlockFocus];
    [outlineViewAdornImage setTemplate:YES];
    [outlineViewAdornImage setName:SKImageNameOutlineViewAdorn];
    
    thumbnailViewAdornImage = [[NSImage alloc] initWithSize:size];
    [thumbnailViewAdornImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [shadow1 set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(10.5, 1.5, 4.0, 4.0)];
    [path appendBezierPathWithRect:NSMakeRect(10.5, 8.5, 4.0, 4.0)];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
    [thumbnailViewAdornImage unlockFocus];
    [thumbnailViewAdornImage setTemplate:YES];
    [thumbnailViewAdornImage setName:SKImageNameThumbnailViewAdorn];
    
    noteViewAdornImage = [[NSImage alloc] initWithSize:size];
    [noteViewAdornImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [shadow1 set];
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
    [NSGraphicsContext restoreGraphicsState];
    [noteViewAdornImage unlockFocus];
    [noteViewAdornImage setTemplate:YES];
    [noteViewAdornImage setName:SKImageNameNoteViewAdorn];
    
    snapshotViewAdornImage = [[NSImage alloc] initWithSize:size];
    [snapshotViewAdornImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [shadow1 set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(7.5, 1.5, 10.0, 4.0)];
    [path appendBezierPathWithRect:NSMakeRect(7.5, 8.5, 10.0, 4.0)];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
    [snapshotViewAdornImage unlockFocus];
    [snapshotViewAdornImage setTemplate:YES];
    [snapshotViewAdornImage setName:SKImageNameSnapshotViewAdorn];
    
    findViewAdornImage = [[NSImage alloc] initWithSize:size];
    [findViewAdornImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [shadow1 set];
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
    [NSGraphicsContext restoreGraphicsState];
    [findViewAdornImage unlockFocus];
    [findViewAdornImage setTemplate:YES];
    [findViewAdornImage setName:SKImageNameFindViewAdorn];
    
    groupedFindViewAdornImage = [[NSImage alloc] initWithSize:size];
    [groupedFindViewAdornImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [shadow1 set];
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
    [NSGraphicsContext restoreGraphicsState];
    [groupedFindViewAdornImage unlockFocus];
    [groupedFindViewAdornImage setTemplate:YES];
    [groupedFindViewAdornImage setName:SKImageNameGroupedFindViewAdorn];
    
    [shadow1 release];
}

+ (void)makeTextAlignImages {
    static NSImage *textAlignLeftImage = nil;
    static NSImage *textAlignCenterImage = nil;
    static NSImage *textAlignRightImage = nil;
    
    if (textAlignLeftImage)
        return;
    
    NSRect rect = NSMakeRect(0.0, 0.0, 16.0, 11.0);
    NSSize size = rect.size;
    NSBezierPath *path;
    
    textAlignLeftImage = [[NSImage alloc] initWithSize:size];
    [textAlignLeftImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
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
    [NSGraphicsContext restoreGraphicsState];
    [textAlignLeftImage unlockFocus];
    [textAlignLeftImage setName:SKImageNameTextAlignLeft];
    
    textAlignCenterImage = [[NSImage alloc] initWithSize:size];
    [textAlignCenterImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
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
    [NSGraphicsContext restoreGraphicsState];
    [textAlignCenterImage unlockFocus];
    [textAlignCenterImage setName:SKImageNameTextAlignCenter];
    
    textAlignRightImage = [[NSImage alloc] initWithSize:size];
    [textAlignRightImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
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
    [NSGraphicsContext restoreGraphicsState];
    [textAlignRightImage unlockFocus];
    [textAlignRightImage setName:SKImageNameTextAlignRight];
}

+ (void)makeCursorImages {
    static NSImage *resizeDiagonal45CursorImage = nil;
    static NSImage *resizeDiagonal135CursorImage = nil;
    static NSImage *zoomInCursorImage = nil;
    static NSImage *zoomOutCursorImage = nil;
    static NSImage *cameraCursorImage = nil;
    static NSImage *openHandBarCursorImage = nil;
    static NSImage *closedHandBarCursorImage = nil;
    static NSImage *textNoteCursorImage = nil;
    static NSImage *anchoredNoteCursorImage = nil;
    static NSImage *circleNoteCursorImage = nil;
    static NSImage *squareNoteCursorImage = nil;
    static NSImage *highlightNoteCursorImage = nil;
    static NSImage *underlineNoteCursorImage = nil;
    static NSImage *strikeOutNoteCursorImage = nil;
    static NSImage *lineNoteCursorImage = nil;
    static NSImage *inkNoteCursorImage = nil;
    
    if (resizeDiagonal45CursorImage)
        return;
    
    NSRect rect = NSMakeRect(0.0, 0.0, 16.0, 16.0);
    NSSize size = rect.size;
    
    NSColor *fgColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
    NSColor *bgColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
    
    NSBezierPath *path;
    
    resizeDiagonal45CursorImage = [[NSImage alloc] initWithSize:size];
    [resizeDiagonal45CursorImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
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
    [NSGraphicsContext restoreGraphicsState];
    [resizeDiagonal45CursorImage unlockFocus];
    [resizeDiagonal45CursorImage setName:SKImageNameResizeDiagonal45Cursor];
    
    resizeDiagonal135CursorImage = [[NSImage alloc] initWithSize:size];
    [resizeDiagonal135CursorImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
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
    [NSGraphicsContext restoreGraphicsState];
    [resizeDiagonal135CursorImage unlockFocus];
    [resizeDiagonal135CursorImage setName:SKImageNameResizeDiagonal135Cursor];
    
    zoomInCursorImage = [[NSImage alloc] initWithSize:size];
    [zoomInCursorImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
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
    [NSGraphicsContext restoreGraphicsState];
    [zoomInCursorImage unlockFocus];
    [zoomInCursorImage setName:SKImageNameZoomInCursor];
    
    zoomOutCursorImage = [[NSImage alloc] initWithSize:size];
    [zoomOutCursorImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
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
    [NSGraphicsContext restoreGraphicsState];
    [zoomOutCursorImage unlockFocus];
    [zoomOutCursorImage setName:SKImageNameZoomOutCursor];
    
    cameraCursorImage = [[NSImage alloc] initWithSize:size];
    [cameraCursorImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
    [[NSColor whiteColor] set];
    [[NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 2.0, 16.0, 11.0)] fill];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(3.7, 6.7, 8.6, 8.6)] fill];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor blackColor] set];
    [[NSBezierPath bezierPathWithRect:NSMakeRect(1.0, 3.0, 14.0, 9.0)] fill];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(5, 8, 6, 6)] fill];
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor whiteColor] set];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(4.3, 4.3, 7.4, 7.4)] stroke];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(8.0, 8.0) radius:1.8 startAngle:45.0 endAngle:225.0];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
    [NSGraphicsContext restoreGraphicsState];
    [cameraCursorImage unlockFocus];
    [cameraCursorImage setName:SKImageNameCameraCursor];
    
    openHandBarCursorImage = [[NSImage alloc] initWithSize:size];
    [openHandBarCursorImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor blackColor] setFill];
    [NSBezierPath fillRect:NSMakeRect(0.0, 9.0, 16.0, 3.0)];
    [[[NSCursor openHandCursor] image] drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [openHandBarCursorImage unlockFocus];
    [openHandBarCursorImage setName:SKImageNameOpenHandBarCursor];
    
    closedHandBarCursorImage = [[NSImage alloc] initWithSize:size];
    [closedHandBarCursorImage lockFocus];
    [NSGraphicsContext saveGraphicsState];
    [[NSColor blackColor] setFill];
    [NSBezierPath fillRect:NSMakeRect(0.0, 6.0, 16.0, 3.0)];
    [[[NSCursor closedHandCursor] image] drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    [closedHandBarCursorImage unlockFocus];
    [closedHandBarCursorImage setName:SKImageNameClosedHandBarCursor];
    
    textNoteCursorImage = [[NSImage imageNamed:SKImageNameTextNote] copyArrowCursorImage];
    [textNoteCursorImage setName:SKImageNameTextNoteCursor];
    
    anchoredNoteCursorImage = [[NSImage imageNamed:SKImageNameAnchoredNote] copyArrowCursorImage];
    [anchoredNoteCursorImage setName:SKImageNameAnchoredNoteCursor];
    
    circleNoteCursorImage = [[NSImage imageNamed:SKImageNameCircleNote] copyArrowCursorImage];
    [circleNoteCursorImage setName:SKImageNameCircleNoteCursor];
    
    squareNoteCursorImage = [[NSImage imageNamed:SKImageNameSquareNote] copyArrowCursorImage];
    [squareNoteCursorImage setName:SKImageNameSquareNoteCursor];
    
    highlightNoteCursorImage = [[NSImage imageNamed:SKImageNameHighlightNote] copyArrowCursorImage];
    [highlightNoteCursorImage setName:SKImageNameHighlightNoteCursor];
    
    underlineNoteCursorImage = [[NSImage imageNamed:SKImageNameUnderlineNote] copyArrowCursorImage];
    [underlineNoteCursorImage setName:SKImageNameUnderlineNoteCursor];
    
    strikeOutNoteCursorImage = [[NSImage imageNamed:SKImageNameStrikeOutNote] copyArrowCursorImage];
    [strikeOutNoteCursorImage setName:SKImageNameStrikeOutNoteCursor];
    
    lineNoteCursorImage = [[NSImage imageNamed:SKImageNameLineNote] copyArrowCursorImage];
    [lineNoteCursorImage setName:SKImageNameLineNoteCursor];
    
    inkNoteCursorImage = [[NSImage imageNamed:SKImageNameInkNote] copyArrowCursorImage];
    [inkNoteCursorImage setName:SKImageNameInkNoteCursor];
}

+ (void)makeImages {
    [self makeNoteImages];
    [self makeAdornImages];
    [self makeToolbarImages];
    [self makeTextAlignImages];
    [self makeCursorImages];
}

@end
