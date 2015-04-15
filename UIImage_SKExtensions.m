//
//  UIImage_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 7/27/07.
/*
 This software is Copyright (c) 2007-2013
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

#import "UIImage_SKExtensions.h"
#import "UIBezierPath_SKExtensions.h"

@implementation UIImage (SKExtensions)

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

UIImage *toolbarPageUpImage = nil;
UIImage *toolbarPageDownImage = nil;
UIImage *toolbarBackImage = nil;
UIImage *toolbarForwardImage = nil;


- (UIImage *)copyWithMenuBadge {
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    [arrowPath moveToPoint:CGPointMake(27.0, 10.0)];
    [arrowPath addLineToPoint:CGPointMake(22.0, 10.0)];
    [arrowPath addLineToPoint:CGPointMake(24.5, 7.0)];
    [arrowPath closePath];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(27.0, 19.0), NO, 0);
    
    [[UIColor clearColor] setFill];
    UIRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
    [self drawAtPoint:CGPointMake(0.5 * (23.0 - [self size].width), 0.0)];
    [[UIColor colorWithWhite:0.0 alpha:1.0] setFill];
    [arrowPath fill];
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
    
//    NSBezierPath *arrowPath = [NSBezierPath bezierPath];
//    [arrowPath moveToPoint:NSMakePoint(27.0, 10.0)];
//    [arrowPath relativeLineToPoint:NSMakePoint(-5.0, 0.0)];
//    [arrowPath relativeLineToPoint:NSMakePoint(2.5, -3.0)];
//    [arrowPath closePath];
//    
//    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [image lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
//    [NSGraphicsContext restoreGraphicsState];
//    [self drawAtPoint:NSMakePoint(0.5 * (23.0 - [self size].width), 0.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] setFill];
//    [arrowPath fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [image unlockFocus];
//    
//    return image;
}

- (UIImage *)copyWithAddBadge {
    UIBezierPath *addPath = [UIBezierPath bezierPath];
    UIBezierPath *bezierRectPath1 = [UIBezierPath bezierPathWithRect:CGRectMake(17.0, 4.0, 6.0, 2.0)];
    UIBezierPath *bezierRectPath2 = [UIBezierPath bezierPathWithRect:CGRectMake(19.0, 2.0, 2.0, 6.0)];
    [addPath appendPath:bezierRectPath1];
    [addPath appendPath:bezierRectPath2];
    
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:2.0];
    [shadow1 setShadowOffset:CGSizeMake(0.0, 0.0)];
    [shadow1 setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.8]];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(27.0, 19.0), NO, 0);
    
    [[UIColor clearColor] setFill];
    UIRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
    [self drawAtPoint:CGPointMake(0.5 * (27.0 - [self size].width), 0.0)];

    [[UIColor colorWithWhite:1.0 alpha:1.0] setFill];
    [addPath fill];
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
    
//    NSBezierPath *addPath = [NSBezierPath bezierPath];
//    [addPath appendBezierPathWithRect:NSMakeRect(17.0, 4.0, 6.0, 2.0)];
//    [addPath appendBezierPathWithRect:NSMakeRect(19.0, 2.0, 2.0, 6.0)];
//    
//    NSShadow *shadow1 = [[NSShadow alloc] init];
//    [shadow1 setShadowBlurRadius:2.0];
//    [shadow1 setShadowOffset:NSMakeSize(0.0, 0.0)];
//    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8]];
//    
//    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [image lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(NSMakeRect(0.0, 0.0, 27.0, 19.0));
//    [NSGraphicsContext restoreGraphicsState];
//    [self drawAtPoint:NSMakePoint(0.5 * (27.0 - [self size].width), 0.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
//    [NSGraphicsContext saveGraphicsState];
//    [shadow1 set];
//    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
//    [addPath fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [image unlockFocus];
//    
//    [shadow1 release];
//    
//    return image;
}

//- (UIImage *)copyArrowCursorImage {
//    UIImage *arrowCursor = [[NSCursor arrowCursor] image];
//    UIImage *image = [[UIImage alloc] initWithSize:NSMakeSize(24.0, 40.0)];
//    
//    [image lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 24.0, 40.0));
//    [NSGraphicsContext restoreGraphicsState];
//    [arrowCursor drawAtPoint:CGPointMake(0.0, 40.0 - [arrowCursor size].height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//    [self drawAtPoint:CGPointMake(3.0, 0.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//    [image unlockFocus];
//    
//    return image;
//}

//+ (void)drawAddBadgeAtPoint:(CGPoint)point {
//    NSBezierPath *path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(point.x + 2.5, point.y + 6.5)];
//    [path relativeLineToPoint:CGPointMake(4.0, 0.0)];
//    [path relativeLineToPoint:CGPointMake(0.0, -4.0)];
//    [path relativeLineToPoint:CGPointMake(3.0, 0.0)];
//    [path relativeLineToPoint:CGPointMake(0.0, 4.0)];
//    [path relativeLineToPoint:CGPointMake(4.0, 0.0)];
//    [path relativeLineToPoint:CGPointMake(0.0, 3.0)];
//    [path relativeLineToPoint:CGPointMake(-4.0, 0.0)];
//    [path relativeLineToPoint:CGPointMake(0.0, 4.0)];
//    [path relativeLineToPoint:CGPointMake(-3.0, 0.0)];
//    [path relativeLineToPoint:CGPointMake(0.0, -4.0)];
//    [path relativeLineToPoint:CGPointMake(-4.0, 0.0)];
//    [path closePath];
//    
//    NSShadow *shadow1 = [[NSShadow alloc] init];
//    [shadow1 setShadowBlurRadius:1.0];
//    [shadow1 setShadowOffset:NSMakeSize(0.0, 0.0)];
//    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
//    
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
//    [path fill];
//    [shadow1 set];
//    [[NSColor colorWithCalibratedRed:0.257 green:0.351 blue:0.553 alpha:1.0] setStroke];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    
//    [shadow1 release];
//}

+ (void)makeToolbarImages {
//    static UIImage *toolbarFirstPageImage = nil;
//    static UIImage *toolbarLastPageImage = nil;
//    static UIImage *toolbarBackImage = nil;
//    static UIImage *toolbarForwardImage = nil;
//    static UIImage *toolbarZoomInImage = nil;
//    static UIImage *toolbarZoomOutImage = nil;
//    static UIImage *toolbarZoomActualImage = nil;
//    static UIImage *toolbarZoomToFitImage = nil;
//    static UIImage *toolbarZoomToSelectionImage = nil;
//    static UIImage *toolbarRotateRightImage = nil;
//    static UIImage *toolbarRotateLeftImage = nil;
//    static UIImage *toolbarCropImage = nil;
//    static UIImage *toolbarFullScreenImage = nil;
//    static UIImage *toolbarPresentationImage = nil;
//    static UIImage *toolbarSinglePageImage = nil;
//    static UIImage *toolbarTwoUpImage = nil;
//    static UIImage *toolbarSinglePageContinuousImage = nil;
//    static UIImage *toolbarTwoUpContinuousImage = nil;
//    static UIImage *toolbarMediaBoxImage = nil;
//    static UIImage *toolbarCropBoxImage = nil;
//    static UIImage *toolbarLeftPaneImage = nil;
//    static UIImage *toolbarRightPaneImage = nil;
//    static UIImage *toolbarTextNoteMenuImage = nil;
//    static UIImage *toolbarAnchoredNoteMenuImage = nil;
//    static UIImage *toolbarCircleNoteMenuImage = nil;
//    static UIImage *toolbarSquareNoteMenuImage = nil;
//    static UIImage *toolbarHighlightNoteMenuImage = nil;
//    static UIImage *toolbarUnderlineNoteMenuImage = nil;
//    static UIImage *toolbarStrikeOutNoteMenuImage = nil;
//    static UIImage *toolbarLineNoteMenuImage = nil;
//    static UIImage *toolbarInkNoteMenuImage = nil;
//    static UIImage *toolbarAddTextNoteImage = nil;
//    static UIImage *toolbarAddAnchoredNoteImage = nil;
//    static UIImage *toolbarAddCircleNoteImage = nil;
//    static UIImage *toolbarAddSquareNoteImage = nil;
//    static UIImage *toolbarAddHighlightNoteImage = nil;
//    static UIImage *toolbarAddUnderlineNoteImage = nil;
//    static UIImage *toolbarAddStrikeOutNoteImage = nil;
//    static UIImage *toolbarAddLineNoteImage = nil;
//    static UIImage *toolbarAddInkNoteImage = nil;
//    static UIImage *toolbarAddTextNoteMenuImage = nil;
//    static UIImage *toolbarAddAnchoredNoteMenuImage = nil;
//    static UIImage *toolbarAddCircleNoteMenuImage = nil;
//    static UIImage *toolbarAddSquareNoteMenuImage = nil;
//    static UIImage *toolbarAddHighlightNoteMenuImage = nil;
//    static UIImage *toolbarAddUnderlineNoteMenuImage = nil;
//    static UIImage *toolbarAddStrikeOutNoteMenuImage = nil;
//    static UIImage *toolbarAddLineNoteMenuImage = nil;
//    static UIImage *toolbarAddInkNoteMenuImage = nil;
//    static UIImage *toolbarTextToolImage = nil;
//    static UIImage *toolbarMagnifyToolImage = nil;
//    static UIImage *toolbarSelectToolImage = nil;
//    static UIImage *toolbarNewFolderImage = nil;
//    static UIImage *toolbarNewSeparatorImage = nil;
    
    if (toolbarPageUpImage)
        return;
    
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:2.0];
    [shadow1 setShadowOffset:CGSizeMake(0.0, 0.0)];
    [shadow1 setShadowColor:[UIColor colorWithWhite:0.0 alpha:1.0]];
    
    NSShadow *shadow2 = [[NSShadow alloc] init];
    [shadow2 setShadowBlurRadius:2.0];
    [shadow2 setShadowOffset:CGSizeMake(0.0, -1.0)];
    [shadow2 setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    
    NSShadow *shadow3 = [[NSShadow alloc] init];
    [shadow3 setShadowBlurRadius:2.0];
    [shadow3 setShadowOffset:CGSizeMake(0.0, 0.0)];
    [shadow3 setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.8]];
    
    UIColor *fgColor = [UIColor whiteColor];
    
    UIBezierPath *path;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(27.0, 19.0), NO, 0);
    
    [[UIColor clearColor] setFill];
    UIRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
    [fgColor setFill];
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(10.0, 3.0)];
    [path addLineToPoint:CGPointMake(17.0, 3.0)];
    [path addLineToPoint:CGPointMake(17.0, 11.0)];
    [path addLineToPoint:CGPointMake(20.5, 11.0)];
    [path addLineToPoint:CGPointMake(13.5, 18.0)];
    [path addLineToPoint:CGPointMake(6.5, 11.0)];
    [path addLineToPoint:CGPointMake(10.0, 11.0)];
    [path closePath];
    [path fill];

    toolbarPageDownImage = UIGraphicsGetImageFromCurrentImageContext();
 
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(27.0, 19.0), NO, 0);
    
    [[UIColor clearColor] setFill];
    UIRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
    [fgColor setFill];
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(10.0, 17.0)];
    [path addLineToPoint:CGPointMake(17.0, 17.0)];
    [path addLineToPoint:CGPointMake(17.0, 9.0)];
    [path addLineToPoint:CGPointMake(20.5, 9.0)];
    [path addLineToPoint:CGPointMake(13.5, 2.0)];
    [path addLineToPoint:CGPointMake(6.5, 9.0)];
    [path addLineToPoint:CGPointMake(10.0, 9.0)];
    [path closePath];
    [path fill];
    
    toolbarPageUpImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
//    toolbarFirstPageImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarFirstPageImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(10.0, 3.0)];
//    [path lineToPoint:CGPointMake(17.0, 3.0)];
//    [path lineToPoint:CGPointMake(17.0, 6.0)];
//    [path lineToPoint:CGPointMake(10.0, 6.0)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(10.0, 8.0)];
//    [path lineToPoint:CGPointMake(17.0, 8.0)];
//    [path lineToPoint:CGPointMake(17.0, 11.0)];
//    [path lineToPoint:CGPointMake(20.5, 11.0)];
//    [path lineToPoint:CGPointMake(13.5, 18.0)];
//    [path lineToPoint:CGPointMake(6.5, 11.0)];
//    [path lineToPoint:CGPointMake(10.0, 11.0)];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarFirstPageImage unlockFocus];
//    [toolbarFirstPageImage setName:SKImageNameToolbarFirstPage];
//
//    toolbarLastPageImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarLastPageImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(10.0, 17.0)];
//    [path lineToPoint:CGPointMake(17.0, 17.0)];
//    [path lineToPoint:CGPointMake(17.0, 14.0)];
//    [path lineToPoint:CGPointMake(10.0, 14.0)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(10.0, 12.0)];
//    [path lineToPoint:CGPointMake(17.0, 12.0)];
//    [path lineToPoint:CGPointMake(17.0, 9.0)];
//    [path lineToPoint:CGPointMake(20.5, 9.0)];
//    [path lineToPoint:CGPointMake(13.5, 2.0)];
//    [path lineToPoint:CGPointMake(6.5, 9.0)];
//    [path lineToPoint:CGPointMake(10.0, 9.0)];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarLastPageImage unlockFocus];
//    [toolbarLastPageImage setName:SKImageNameToolbarLastPage];
//
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(27.0, 19.0), NO, 0);

    [[UIColor clearColor] setFill];
    UIRectFill(CGRectMake(0.0, 0.0, 27.0, 13.0));
    [fgColor setFill];
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(17.0, 2.5)];
    [path addLineToPoint:CGPointMake(8.5, 7.0)];
    [path addLineToPoint:CGPointMake(17.0, 11.5)];
    [path closePath];
    [path fill];
    
    toolbarBackImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(27.0, 19.0), NO, 0);
    
    [[UIColor clearColor] setFill];
    UIRectFill(CGRectMake(0.0, 0.0, 27.0, 13.0));
    [fgColor setFill];
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(10.0, 2.5)];
    [path addLineToPoint:CGPointMake(18.5, 7.0)];
    [path addLineToPoint:CGPointMake(10.0, 11.5)];
    [path closePath];
    [path fill];
    
    toolbarForwardImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
//    toolbarZoomInImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarZoomInImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path appendBezierPathWithRect:CGRectMake(7.0, 9.0, 13.0, 3.0)];
//    [path appendBezierPathWithRect:CGRectMake(12.0, 4.0, 3.0, 13.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarZoomInImage unlockFocus];
//    [toolbarZoomInImage setName:SKImageNameToolbarZoomIn];
//    
//    toolbarZoomOutImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 9.0)];
//    [toolbarZoomOutImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 9.0));
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path appendBezierPathWithRect:CGRectMake(7.0, 4.0, 13.0, 3.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarZoomOutImage unlockFocus];
//    [toolbarZoomOutImage setName:SKImageNameToolbarZoomOut];
//    
//    toolbarZoomActualImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 14.0)];
//    [toolbarZoomActualImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 14.0));
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path appendBezierPathWithRect:CGRectMake(7.0, 4.0, 13.0, 3.0)];
//    [path appendBezierPathWithRect:CGRectMake(7.0, 9.0, 13.0, 3.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarZoomActualImage unlockFocus];
//    [toolbarZoomActualImage setName:SKImageNameToolbarZoomActual];
//    
//    toolbarZoomToFitImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarZoomToFitImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setStroke];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(6.0, 5.0, 15.0 , 11.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    [path setLineWidth:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(7.0, 6.0, 13.0, 9.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(8.0, 7.0, 11.0, 7.0) angle:90.0];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(8.0, 7.0)];
//    [path lineToPoint:CGPointMake(11.5, 7.0)];
//    [path lineToPoint:CGPointMake(8.0, 10.5)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(19.0, 14.0)];
//    [path lineToPoint:CGPointMake(15.5, 14.0)];
//    [path lineToPoint:CGPointMake(19.0, 10.5)];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarZoomToFitImage unlockFocus];
//    [toolbarZoomToFitImage setName:SKImageNameToolbarZoomToFit];
//    
//    toolbarZoomToSelectionImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarZoomToSelectionImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setStroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(6.0, 14.0)];
//    [path lineToPoint:CGPointMake(6.0, 16.0)];
//    [path lineToPoint:CGPointMake(9.0, 16.0)];
//    [path moveToPoint:CGPointMake(11.0, 16.0)];
//    [path lineToPoint:CGPointMake(16.0, 16.0)];
//    [path moveToPoint:CGPointMake(18.0, 16.0)];
//    [path lineToPoint:CGPointMake(21.0, 16.0)];
//    [path lineToPoint:CGPointMake(21.0, 14.0)];
//    [path moveToPoint:CGPointMake(21.0, 12.0)];
//    [path lineToPoint:CGPointMake(21.0, 9.0)];
//    [path moveToPoint:CGPointMake(21.0, 7.0)];
//    [path lineToPoint:CGPointMake(21.0, 5.0)];
//    [path lineToPoint:CGPointMake(18.0, 5.0)];
//    [path moveToPoint:CGPointMake(16.0, 5.0)];
//    [path lineToPoint:CGPointMake(11.0, 5.0)];
//    [path moveToPoint:CGPointMake(9.0, 5.0)];
//    [path lineToPoint:CGPointMake(6.0, 5.0)];
//    [path lineToPoint:CGPointMake(6.0, 7.0)];
//    [path moveToPoint:CGPointMake(6.0, 9.0)];
//    [path lineToPoint:CGPointMake(6.0, 12.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    [path setLineWidth:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(7.0, 6.0, 13.0, 9.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(8.0, 7.0, 11.0, 7.0) angle:90.0];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(8.0, 7.0)];
//    [path lineToPoint:CGPointMake(11.5, 7.0)];
//    [path lineToPoint:CGPointMake(8.0, 10.5)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(19.0, 14.0)];
//    [path lineToPoint:CGPointMake(15.5, 14.0)];
//    [path lineToPoint:CGPointMake(19.0, 10.5)];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarZoomToSelectionImage unlockFocus];
//    [toolbarZoomToSelectionImage setName:SKImageNameToolbarZoomToSelection];
//    
//    toolbarRotateLeftImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
//    [toolbarRotateLeftImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 21.0));
//    [shadow1 set];
//    [fgColor set];
//    path = [NSBezierPath bezierPath];
//    [path appendBezierPathWithArcWithCenter:CGPointMake(13.5, 10.0) radius:6.0 startAngle:-180.0 endAngle:90.0 clockwise:NO];
//    [path lineToPoint:CGPointMake(13.5, 19.0)];
//    [path lineToPoint:CGPointMake(9.0, 14.5)];
//    [path lineToPoint:CGPointMake(13.5, 10.0)];
//    [path appendBezierPathWithArcWithCenter:CGPointMake(13.5, 10.0) radius:3.0 startAngle:90.0 endAngle:-180.0 clockwise:YES];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarRotateLeftImage unlockFocus];
//    [toolbarRotateLeftImage setName:SKImageNameToolbarRotateLeft];
//    
//    toolbarRotateRightImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
//    [toolbarRotateRightImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 21.0));
//    [shadow1 set];
//    [fgColor set];
//    path = [NSBezierPath bezierPath];
//    [path appendBezierPathWithArcWithCenter:CGPointMake(13.5, 10.0) radius:6.0 startAngle:360.0 endAngle:90.0 clockwise:YES];
//    [path lineToPoint:CGPointMake(13.5, 19.0)];
//    [path lineToPoint:CGPointMake(18.0, 14.5)];
//    [path lineToPoint:CGPointMake(13.5, 10.0)];
//    [path appendBezierPathWithArcWithCenter:CGPointMake(13.5, 10.0) radius:3.0 startAngle:90.0 endAngle:360.0 clockwise:NO];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarRotateRightImage unlockFocus];
//    [toolbarRotateRightImage setName:SKImageNameToolbarRotateRight];
//    
//    toolbarCropImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
//    [toolbarCropImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 21.0));
//    [shadow1 set];
//    [fgColor setStroke];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(6.0, 5.0, 15.0 , 11.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    [path setLineWidth:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(7.0, 6.0, 13.0, 9.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(8.0, 7.0, 11.0, 7.0) angle:90.0];
//    [shadow3 set];
//    [[NSColor colorWithCalibratedRed:1.0 green:0.865 blue:0.296 alpha:1.0] setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(3.0, 7.0, 21.0, 2.0)];
//    [path fill];
//    [[NSColor colorWithCalibratedRed:1.0 green:0.906 blue:0.496 alpha:1.0] setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(17.0, 2.0, 2.0, 17.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarCropImage unlockFocus];
//    [toolbarCropImage setName:SKImageNameToolbarCrop];
//    
//    toolbarFullScreenImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
//    [toolbarFullScreenImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 21.0));
//    [shadow1 set];
//    [fgColor set];
//    path = [NSBezierPath bezierPathWithRoundedRect:CGRectMake(5.0, 4.0, 17.0, 14.0) xRadius:2.0 yRadius:2.0];
//    [path appendBezierPathWithRect:CGRectMake(7.0, 6.0, 13.0, 10.0)];
//    [path moveToPoint:CGPointMake(8.0, 7.0)];
//    [path lineToPoint:CGPointMake(11.0, 7.0)];
//    [path lineToPoint:CGPointMake(8.0, 10.0)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(8.0, 15.0)];
//    [path lineToPoint:CGPointMake(8.0, 12.0)];
//    [path lineToPoint:CGPointMake(11.0, 15.0)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(19.0, 7.0)];
//    [path lineToPoint:CGPointMake(19.0, 10.0)];
//    [path lineToPoint:CGPointMake(16.0, 7.0)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(19.0, 15.0)];
//    [path lineToPoint:CGPointMake(16.0, 15.0)];
//    [path lineToPoint:CGPointMake(19.0, 12.0)];
//    [path closePath];
//    [path setWindingRule:NSEvenOddWindingRule];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarFullScreenImage unlockFocus];
//    [toolbarFullScreenImage setName:SKImageNameToolbarFullScreen];
//    
//    toolbarPresentationImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
//    [toolbarPresentationImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 21.0));
//    [shadow1 set];
//    [fgColor set];
//    path = [NSBezierPath bezierPathWithRoundedRect:CGRectMake(5.0, 4.0, 17.0, 14.0) xRadius:2.0 yRadius:2.0];
//    [path appendBezierPathWithRect:CGRectMake(7.0, 6.0, 13.0, 10.0)];
//    [path moveToPoint:CGPointMake(11.0, 7.0)];
//    [path lineToPoint:CGPointMake(18.5, 11.0)];
//    [path lineToPoint:CGPointMake(11.0, 15.0)];
//    [path setWindingRule:NSEvenOddWindingRule];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarPresentationImage unlockFocus];
//    [toolbarPresentationImage setName:SKImageNameToolbarPresentation];
//    
//    toolbarSinglePageImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarSinglePageImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(9.0, 4.0, 9.0 , 12.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(10.0, 5.0, 7.0 , 10.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(11.0, 6.0, 5.0 , 8.0) angle:90.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarSinglePageImage unlockFocus];
//    [toolbarSinglePageImage setName:SKImageNameToolbarSinglePage];
//    
//    toolbarTwoUpImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarTwoUpImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(4.0, 4.0, 9.0 , 12.0)];
//    [path appendBezierPathWithRect:CGRectMake(14.0, 4.0, 9.0 , 12.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(5.0, 5.0, 7.0 , 10.0) angle:90.0];
//    [gradient drawInRect:CGRectMake(15.0, 5.0, 7.0 , 10.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(6.0, 6.0, 5.0 , 8.0) angle:90.0];
//    [gradient drawInRect:CGRectMake(16.0, 6.0, 5.0 , 8.0) angle:90.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarTwoUpImage unlockFocus];
//    [toolbarTwoUpImage setName:SKImageNameToolbarTwoUp];
//    
//    toolbarSinglePageContinuousImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarSinglePageContinuousImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(9.0, 11.0, 9.0 , 5.0)];
//    [path appendBezierPathWithRect:CGRectMake(9.0, 4.0, 9.0 , 6.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(9.0, 4.0, 9.0 , 12.0)];
//    [path addClip];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(10.0, 12.0, 7.0 , 10.0) angle:90.0];
//    [gradient drawInRect:CGRectMake(10.0, -1.0, 7.0 , 10.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(11.0, 13.0, 5.0 , 8.0) angle:90.0];
//    [gradient drawInRect:CGRectMake(11.0, 0.0, 5.0 , 8.0) angle:90.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarSinglePageContinuousImage unlockFocus];
//    [toolbarSinglePageContinuousImage setName:SKImageNameToolbarSinglePageContinuous];
//    
//    toolbarTwoUpContinuousImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarTwoUpContinuousImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(4.0, 11.0, 9.0 , 5.0)];
//    [path appendBezierPathWithRect:CGRectMake(14.0, 11.0, 9.0 , 5.0)];
//    [path appendBezierPathWithRect:CGRectMake(4.0, 4.0, 9.0 , 6.0)];
//    [path appendBezierPathWithRect:CGRectMake(14.0, 4.0, 9.0 , 6.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(4.0, 4.0, 19.0 , 12.0)];
//    [path addClip];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(5.0, 12.0, 7.0 , 10.0) angle:90.0];
//    [gradient drawInRect:CGRectMake(15.0, 12.0, 7.0 , 10.0) angle:90.0];
//    [gradient drawInRect:CGRectMake(5.0, -1.0, 7.0 , 10.0) angle:90.0];
//    [gradient drawInRect:CGRectMake(15.0, -1.0, 7.0 , 10.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(6.0, 13.0, 5.0 , 8.0) angle:90.0];
//    [gradient drawInRect:CGRectMake(16.0, 13.0, 5.0 , 8.0) angle:90.0];
//    [gradient drawInRect:CGRectMake(6.0, 0.0, 5.0 , 8.0) angle:90.0];
//    [gradient drawInRect:CGRectMake(16.0, 0.0, 5.0 , 8.0) angle:90.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarTwoUpContinuousImage unlockFocus];
//    [toolbarTwoUpContinuousImage setName:SKImageNameToolbarTwoUpContinuous];
//    
//    toolbarMediaBoxImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
//    [toolbarMediaBoxImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 21.0));
//    [shadow1 set];
//    [fgColor setStroke];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(6.0, 5.0, 15.0 , 11.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    [path setLineWidth:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(7.0, 6.0, 13.0, 9.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(8.0, 7.0, 11.0, 7.0) angle:90.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarMediaBoxImage unlockFocus];
//    [toolbarMediaBoxImage setName:SKImageNameToolbarMediaBox];
//    
//    toolbarCropBoxImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
//    [toolbarCropBoxImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 21.0));
//    [shadow1 set];
//    [fgColor setStroke];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(6.0, 5.0, 15.0 , 11.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    [path setLineWidth:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(7.0, 6.0, 13.0, 9.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(8.0, 7.0, 11.0, 7.0) angle:90.0];
//    [shadow3 set];
//    [[NSColor colorWithCalibratedRed:1.0 green:0.865 blue:0.296 alpha:1.0] setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(3.0, 7.0, 21.0, 2.0)];
//    [path fill];
//    [[NSColor colorWithCalibratedRed:1.0 green:0.906 blue:0.496 alpha:1.0] setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(17.0, 2.0, 2.0, 17.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarCropBoxImage unlockFocus];
//    [toolbarCropBoxImage setName:SKImageNameToolbarCropBox];
//    
//    CGFloat outStartGray = 0.925, outEndGray = 1.0, inStartGray = 0.868, inEndGray = 1.0;
//    
//    toolbarLeftPaneImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 17.0)];
//    [toolbarLeftPaneImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 17.0));
//    [shadow3 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(5.0, 4.0, 17.0 , 11.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:outStartGray green:outStartGray blue:outStartGray alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:outEndGray green:outEndGray blue:outEndGray alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(5.0, 4.0, 17.0 , 11.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:inStartGray green:inStartGray blue:inStartGray alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:inEndGray green:inEndGray blue:inEndGray alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(12.0, 5.0, 9.0, 9.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.431 green:0.478 blue:0.589 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.714 green:0.744 blue:0.867 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(10.0, 4.0, 1.0, 11.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.502 green:0.537 blue:0.640 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.761 green:0.784 blue:0.900 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(5.0, 4.0, 5.0, 11.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.382 green:0.435 blue:0.547 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.696 green:0.722 blue:0.843 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(6.0, 5.0, 3.0, 9.0) angle:90.0];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path appendBezierPathWithRect:CGRectMake(6.0, 5.0, 3.0, 1.0)];
//    [path appendBezierPathWithRect:CGRectMake(6.0, 7.0, 3.0, 1.0)];
//    [path appendBezierPathWithRect:CGRectMake(6.0, 9.0, 3.0, 1.0)];
//    [path appendBezierPathWithRect:CGRectMake(6.0, 11.0, 3.0, 1.0)];
//    [path appendBezierPathWithRect:CGRectMake(6.0, 13.0, 3.0, 1.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarLeftPaneImage unlockFocus];
//    [toolbarLeftPaneImage setName:SKImageNameToolbarLeftPane];
//    
//    toolbarRightPaneImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 17.0)];
//    [toolbarRightPaneImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 17.0));
//    [shadow3 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(5.0, 4.0, 17.0 , 11.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:outStartGray green:outStartGray blue:outStartGray alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:outEndGray green:outEndGray blue:outEndGray alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(5.0, 4.0, 17.0 , 11.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:inStartGray green:inStartGray blue:inStartGray alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:inEndGray green:inEndGray blue:inEndGray alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(6.0, 5.0, 9.0, 9.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.431 green:0.478 blue:0.589 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.714 green:0.744 blue:0.867 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(16.0, 4.0, 1.0, 11.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.502 green:0.537 blue:0.640 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.761 green:0.784 blue:0.900 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(17.0, 4.0, 5.0, 11.0) angle:90.0];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.382 green:0.435 blue:0.547 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.696 green:0.722 blue:0.843 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(18.0, 5.0, 3.0, 9.0) angle:90.0];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path appendBezierPathWithRect:CGRectMake(18.0, 5.0, 3.0, 1.0)];
//    [path appendBezierPathWithRect:CGRectMake(18.0, 7.0, 3.0, 1.0)];
//    [path appendBezierPathWithRect:CGRectMake(18.0, 9.0, 3.0, 1.0)];
//    [path appendBezierPathWithRect:CGRectMake(18.0, 11.0, 3.0, 1.0)];
//    [path appendBezierPathWithRect:CGRectMake(18.0, 13.0, 3.0, 1.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarRightPaneImage unlockFocus];
//    [toolbarRightPaneImage setName:SKImageNameToolbarRightPane];
//    
//    toolbarTextNoteMenuImage = [[UIImage imageNamed:SKImageNameTextNote] copyWithMenuBadge];
//    [toolbarTextNoteMenuImage setName:SKImageNameToolbarTextNoteMenu];
//    
//    toolbarAddTextNoteImage = [[UIImage imageNamed:SKImageNameTextNote] copyWithAddBadge];
//    [toolbarAddTextNoteImage setName:SKImageNameToolbarAddTextNote];
//    
//    toolbarAddTextNoteMenuImage = [toolbarAddTextNoteImage copyWithMenuBadge];
//    [toolbarAddTextNoteMenuImage setName:SKImageNameToolbarAddTextNoteMenu];
//    
//    toolbarAnchoredNoteMenuImage = [[UIImage imageNamed:SKImageNameAnchoredNote] copyWithMenuBadge];
//    [toolbarAnchoredNoteMenuImage setName:SKImageNameToolbarAnchoredNoteMenu];
//    
//    toolbarAddAnchoredNoteImage = [[UIImage imageNamed:SKImageNameAnchoredNote] copyWithAddBadge];
//    [toolbarAddAnchoredNoteImage setName:SKImageNameToolbarAddAnchoredNote];
//    
//    toolbarAddAnchoredNoteMenuImage = [toolbarAddAnchoredNoteImage copyWithMenuBadge];
//    [toolbarAddAnchoredNoteMenuImage setName:SKImageNameToolbarAddAnchoredNoteMenu];
//
//    toolbarCircleNoteMenuImage = [[UIImage imageNamed:SKImageNameCircleNote] copyWithMenuBadge];
//    [toolbarCircleNoteMenuImage setName:SKImageNameToolbarCircleNoteMenu];
//    
//    toolbarAddCircleNoteImage = [[UIImage imageNamed:SKImageNameCircleNote] copyWithAddBadge];
//    [toolbarAddCircleNoteImage setName:SKImageNameToolbarAddCircleNote];
//    
//    toolbarAddCircleNoteMenuImage = [toolbarAddCircleNoteImage copyWithMenuBadge];
//    [toolbarAddCircleNoteMenuImage setName:SKImageNameToolbarAddCircleNoteMenu];
//
//    toolbarSquareNoteMenuImage = [[UIImage imageNamed:SKImageNameSquareNote] copyWithMenuBadge];
//    [toolbarSquareNoteMenuImage setName:SKImageNameToolbarSquareNoteMenu];
//    
//    toolbarAddSquareNoteImage = [[UIImage imageNamed:SKImageNameSquareNote] copyWithAddBadge];
//    [toolbarAddSquareNoteImage setName:SKImageNameToolbarAddSquareNote];
//    
//    toolbarAddSquareNoteMenuImage = [toolbarAddSquareNoteImage copyWithMenuBadge];
//    [toolbarAddSquareNoteMenuImage setName:SKImageNameToolbarAddSquareNoteMenu];
//    
//    toolbarHighlightNoteMenuImage = [[UIImage imageNamed:SKImageNameHighlightNote] copyWithMenuBadge];
//    [toolbarHighlightNoteMenuImage setName:SKImageNameToolbarHighlightNoteMenu];
//    
//    toolbarAddHighlightNoteImage = [[UIImage imageNamed:SKImageNameHighlightNote] copyWithAddBadge];
//    [toolbarAddHighlightNoteImage setName:SKImageNameToolbarAddHighlightNote];
//    
//    toolbarAddHighlightNoteMenuImage = [toolbarAddHighlightNoteImage copyWithMenuBadge];
//    [toolbarAddHighlightNoteMenuImage setName:SKImageNameToolbarAddHighlightNoteMenu];
//
//    toolbarUnderlineNoteMenuImage = [[UIImage imageNamed:SKImageNameUnderlineNote] copyWithMenuBadge];
//    [toolbarUnderlineNoteMenuImage setName:SKImageNameToolbarUnderlineNoteMenu];
//    
//    toolbarAddUnderlineNoteImage = [[UIImage imageNamed:SKImageNameUnderlineNote] copyWithAddBadge];
//    [toolbarAddUnderlineNoteImage setName:SKImageNameToolbarAddUnderlineNote];
//    
//    toolbarAddUnderlineNoteMenuImage = [toolbarAddUnderlineNoteImage copyWithMenuBadge];
//    [toolbarAddUnderlineNoteMenuImage setName:SKImageNameToolbarAddUnderlineNoteMenu];
//
//    toolbarStrikeOutNoteMenuImage = [[UIImage imageNamed:SKImageNameStrikeOutNote] copyWithMenuBadge];
//    [toolbarStrikeOutNoteMenuImage setName:SKImageNameToolbarStrikeOutNoteMenu];
//    
//    toolbarAddStrikeOutNoteImage = [[UIImage imageNamed:SKImageNameStrikeOutNote] copyWithAddBadge];
//    [toolbarAddStrikeOutNoteImage setName:SKImageNameToolbarAddStrikeOutNote];
//    
//    toolbarAddStrikeOutNoteMenuImage = [toolbarAddStrikeOutNoteImage copyWithMenuBadge];
//    [toolbarAddStrikeOutNoteMenuImage setName:SKImageNameToolbarAddStrikeOutNoteMenu];
//
//    toolbarLineNoteMenuImage = [[UIImage imageNamed:SKImageNameLineNote] copyWithMenuBadge];
//    [toolbarLineNoteMenuImage setName:SKImageNameToolbarLineNoteMenu];
//    
//    toolbarAddLineNoteImage = [[UIImage imageNamed:SKImageNameLineNote] copyWithAddBadge];
//    [toolbarAddLineNoteImage setName:SKImageNameToolbarAddLineNote];
//    
//    toolbarAddLineNoteMenuImage = [toolbarAddLineNoteImage copyWithMenuBadge];
//    [toolbarAddLineNoteMenuImage setName:SKImageNameToolbarAddLineNoteMenu];
//
//    toolbarInkNoteMenuImage = [[UIImage imageNamed:SKImageNameInkNote] copyWithMenuBadge];
//    [toolbarInkNoteMenuImage setName:SKImageNameToolbarInkNoteMenu];
//    
//    toolbarAddInkNoteImage = [[UIImage imageNamed:SKImageNameInkNote] copyWithAddBadge];
//    [toolbarAddInkNoteImage setName:SKImageNameToolbarAddInkNote];
//    
//    toolbarAddInkNoteMenuImage = [toolbarAddInkNoteImage copyWithMenuBadge];
//    [toolbarAddInkNoteMenuImage setName:SKImageNameToolbarAddInkNoteMenu];
//    
//    toolbarTextToolImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarTextToolImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(7.0, 4.0, 13.0, 13.0)];
//    [path setWindingRule:NSEvenOddWindingRule];
//    [path moveToPoint:CGPointMake(8.5, 6.0)];
//    [path lineToPoint:CGPointMake(12.5, 15.0)];
//    [path lineToPoint:CGPointMake(14.5, 15.0)];
//    [path lineToPoint:CGPointMake(18.5, 6.0)];
//    [path lineToPoint:CGPointMake(16.5, 6.0)];
//    [path lineToPoint:CGPointMake(15.6, 8.0)];
//    [path lineToPoint:CGPointMake(11.4, 8.0)];
//    [path lineToPoint:CGPointMake(10.5, 6.0)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(12.3, 10.0)];
//    [path lineToPoint:CGPointMake(14.7, 10.0)];
//    [path lineToPoint:CGPointMake(13.5, 12.75)];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    [path setClip];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.976 green:0.976 blue:0.976 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.798 green:0.798 blue:0.798 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(7.0, 4.0, 13.0, 6.0) angle:90.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarTextToolImage unlockFocus];
//    [toolbarTextToolImage setName:SKImageNameToolbarTextTool];
//    
//    toolbarMagnifyToolImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarMagnifyToolImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setStroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(15.0, 8.0)];
//    [path lineToPoint:CGPointMake(19.0, 4.0)];
//    [path setLineWidth:3.0];
//    [path stroke];
//    path = [NSBezierPath bezierPath];
//    [path appendBezierPathWithOvalInRect:CGRectMake(7.0, 7.0, 9.0, 9.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    [path setLineWidth:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarMagnifyToolImage unlockFocus];
//    [toolbarMagnifyToolImage setName:SKImageNameToolbarMagnifyTool];
//    
//    toolbarSelectToolImage = [[UIImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
//    [toolbarSelectToolImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 27.0, 19.0));
//    [shadow1 set];
//    [fgColor setStroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(8.0, 14.0)];
//    [path lineToPoint:CGPointMake(8.0, 16.0)];
//    [path lineToPoint:CGPointMake(10.0, 16.0)];
//    [path moveToPoint:CGPointMake(12.0, 16.0)];
//    [path lineToPoint:CGPointMake(15.0, 16.0)];
//    [path moveToPoint:CGPointMake(17.0, 16.0)];
//    [path lineToPoint:CGPointMake(19.0, 16.0)];
//    [path lineToPoint:CGPointMake(19.0, 14.0)];
//    [path moveToPoint:CGPointMake(19.0, 12.0)];
//    [path lineToPoint:CGPointMake(19.0, 9.0)];
//    [path moveToPoint:CGPointMake(19.0, 7.0)];
//    [path lineToPoint:CGPointMake(19.0, 5.0)];
//    [path lineToPoint:CGPointMake(17.0, 5.0)];
//    [path moveToPoint:CGPointMake(15.0, 5.0)];
//    [path lineToPoint:CGPointMake(12.0, 5.0)];
//    [path moveToPoint:CGPointMake(10.0, 5.0)];
//    [path lineToPoint:CGPointMake(8.0, 5.0)];
//    [path lineToPoint:CGPointMake(8.0, 7.0)];
//    [path moveToPoint:CGPointMake(8.0, 9.0)];
//    [path lineToPoint:CGPointMake(8.0, 12.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    [path setLineWidth:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarSelectToolImage unlockFocus];
//    [toolbarSelectToolImage setName:SKImageNameToolbarSelectTool];
//    
//    toolbarNewFolderImage = [[UIImage alloc] initWithSize:NSMakeSize(32.0, 32.0)];
//    [toolbarNewFolderImage lockFocus];
//    [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)] drawInRect:CGRectMake(0.0, 0.0, 32.0, 32.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
//    [[self class] drawAddBadgeAtPoint:CGPointMake(18.0, 18.0)];
//    [toolbarNewFolderImage unlockFocus];
//    [toolbarNewFolderImage setName:SKImageNameToolbarNewFolder];
//    
//    toolbarNewSeparatorImage = [[UIImage alloc] initWithSize:NSMakeSize(32.0, 32.0)];
//    [toolbarNewSeparatorImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(CGRectMake(0.0, 0.0, 32.0, 32.0));
//    [shadow2 set];
//    [[NSColor colorWithCalibratedWhite:0.35 alpha:1.0] setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(2.0, 14.0, 28.0, 4.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor colorWithCalibratedWhite:0.65 alpha:1.0] setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(3.0, 15.0, 26.0, 2.0)];
//    [path fill];
//    [[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(4.0, 16.0, 24.0, 1.0)];
//    [path fill];
//    [[NSColor colorWithCalibratedWhite:0.45 alpha:1.0] setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(3.0, 17.0, 26.0, 1.0)];
//    [path fill];
//    [[self class] drawAddBadgeAtPoint:CGPointMake(18.0, 14.0)];
//    [NSGraphicsContext restoreGraphicsState];
//    [toolbarNewSeparatorImage unlockFocus];
//    [toolbarNewSeparatorImage setName:SKImageNameToolbarNewSeparator];
//    
//    [shadow1 release];
//    [shadow2 release];
//    [shadow3 release];
}

//+ (void)makeNoteImages {
//    static UIImage *textNoteImage = nil;
//    static UIImage *anchoredNoteImage = nil;
//    static UIImage *circleNoteImage = nil;
//    static UIImage *squareNoteImage = nil;
//    static UIImage *highlightNoteImage = nil;
//    static UIImage *underlineNoteImage = nil;
//    static UIImage *strikeOutNoteImage = nil;
//    static UIImage *lineNoteImage = nil;
//    static UIImage *inkNoteImage = nil;
//    
//    if (textNoteImage)
//        return;
//    
//    NSShadow *shadow1 = [[NSShadow alloc] init];
//    [shadow1 setShadowBlurRadius:2.0];
//    [shadow1 setShadowOffset:NSMakeSize(0.0, 0.0)];
//    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
//    
//    NSShadow *shadow2 = [[NSShadow alloc] init];
//    [shadow2 setShadowBlurRadius:2.0];
//    [shadow2 setShadowOffset:NSMakeSize(0.0, -1.0)];
//    [shadow2 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
//    
//    NSShadow *shadow3 = [[NSShadow alloc] init];
//    [shadow3 setShadowBlurRadius:2.0];
//    [shadow3 setShadowOffset:NSMakeSize(0.0, 0.0)];
//    [shadow3 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8]];
//    
//    NSColor *fgColor = [NSColor whiteColor];
//    
//    NSBezierPath *path;
//    NSGradient *gradient;
//    
//    NSRect rect = CGRectMake(0.0, 0.0, 21.0, 19.0);
//    NSSize size = rect.size;
//    
//    [NSBezierPath setDefaultLineWidth:1.0];
//    
//    textNoteImage = [[UIImage alloc] initWithSize:size];
//    [textNoteImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow3 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(5.0, 5.0)];
//    [path lineToPoint:CGPointMake(9.0, 6.0)];
//    [path lineToPoint:CGPointMake(16.0, 13.0)];
//    [path lineToPoint:CGPointMake(16.0, 14.0)];
//    [path lineToPoint:CGPointMake(14.0, 16.0)];
//    [path lineToPoint:CGPointMake(13.0, 16.0)];
//    [path lineToPoint:CGPointMake(6.0, 9.0)];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(9.0, 7.0)];
//    [path lineToPoint:CGPointMake(16.0, 14.0)];
//    [path lineToPoint:CGPointMake(14.0, 16.0)];
//    [path lineToPoint:CGPointMake(7.0, 9.0)];
//    [path closePath];
//    [[NSColor colorWithCalibratedRed:1.0 green:0.835 blue:0.0 alpha:1.0] set];
//    [path fill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(9.0, 6.0)];
//    [path lineToPoint:CGPointMake(16.0, 13.0)];
//    [path lineToPoint:CGPointMake(16.0, 14.0)];
//    [path lineToPoint:CGPointMake(9.0, 7.0)];
//    [path closePath];
//    [[NSColor colorWithCalibratedRed:1.0 green:0.745 blue:0.0 alpha:1.0] set];
//    [path fill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(7.0, 9.0)];
//    [path lineToPoint:CGPointMake(14.0, 16.0)];
//    [path lineToPoint:CGPointMake(13.0, 16.0)];
//    [path lineToPoint:CGPointMake(6.0, 9.0)];
//    [path closePath];
//    [[NSColor colorWithCalibratedRed:1.0 green:0.925 blue:0.0 alpha:1.0] set];
//    [path fill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(6.0, 6.5)];
//    [path lineToPoint:CGPointMake(7.0, 9.0)];
//    [path lineToPoint:CGPointMake(6.0, 9.0)];
//    [path lineToPoint:CGPointMake(5.5, 7.0)];
//    [path closePath];
//    [[NSColor colorWithCalibratedRed:1.0 green:0.98 blue:0.9 alpha:1.0] set];
//    [path fill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(6.5, 6.0)];
//    [path lineToPoint:CGPointMake(9.0, 7.0)];
//    [path lineToPoint:CGPointMake(7.0, 9.0)];
//    [path lineToPoint:CGPointMake(6.0, 6.5)];
//    [path closePath];
//    [[NSColor colorWithCalibratedRed:1.0 green:0.95 blue:0.8 alpha:1.0] set];
//    [path fill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(7.0, 5.5)];
//    [path lineToPoint:CGPointMake(9.0, 6.0)];
//    [path lineToPoint:CGPointMake(9.0, 7.0)];
//    [path lineToPoint:CGPointMake(6.5, 6.0)];
//    [path closePath];
//    [[NSColor colorWithCalibratedRed:0.85 green:0.75 blue:0.6 alpha:1.0] set];
//    [path fill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(5.0, 5.0)];
//    [path lineToPoint:CGPointMake(7.0, 5.5)];
//    [path lineToPoint:CGPointMake(5.5, 7.0)];
//    [path closePath];
//    [[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] set];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [textNoteImage unlockFocus];
//    [textNoteImage setName:SKImageNameTextNote];
//    
//    anchoredNoteImage = [[UIImage alloc] initWithSize:size];
//    [anchoredNoteImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(12.0, 6.0)];
//    [path appendBezierPathWithArcFromPoint:CGPointMake(17.0, 6.0) toPoint:CGPointMake(17.0, 16.0) radius:3.0];
//    [path appendBezierPathWithArcFromPoint:CGPointMake(17.0, 16.0) toPoint:CGPointMake(3.0, 16.0) radius:3.0];
//    [path appendBezierPathWithArcFromPoint:CGPointMake(3.0, 16.0) toPoint:CGPointMake(3.0, 6.0) radius:3.0];
//    [path appendBezierPathWithArcFromPoint:CGPointMake(3.0, 6.0) toPoint:CGPointMake(17.0, 6.0) radius:3.0];
//    [path lineToPoint:CGPointMake(9.0, 6.0)];
//    [path lineToPoint:CGPointMake(8.0, 3.0)];
//    [path closePath];
//    [path appendBezierPathWithRect:CGRectMake(9.0, 7.0, 2.0, 2.0)];
//    [path appendBezierPathWithRect:CGRectMake(9.0, 10.0, 2.0, 4.0)];
//    [path setWindingRule:NSEvenOddWindingRule];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(3.0, 10.0)];
//    [path appendBezierPathWithArcFromPoint:CGPointMake(3.0, 6.0) toPoint:CGPointMake(17.0, 6.0) radius:3.0];
//    [path appendBezierPathWithArcFromPoint:CGPointMake(17.0, 6.0) toPoint:CGPointMake(17.0, 10.0) radius:3.0];
//    [path lineToPoint:CGPointMake(17.0, 10.0)];
//    [path closePath];
//    [path appendBezierPathWithRect:CGRectMake(9.0, 7.0, 2.0, 2.0)];
//    [path setWindingRule:NSEvenOddWindingRule];
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.988 green:0.988 blue:0.988 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.762 green:0.762 blue:0.762 alpha:1.0]] autorelease];
//    [gradient drawInBezierPath:path angle:90.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [anchoredNoteImage unlockFocus];
//    [anchoredNoteImage setName:SKImageNameAnchoredNote];
//    
//    circleNoteImage = [[UIImage alloc] initWithSize:size];
//    [circleNoteImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow2 set];
//    [[NSColor colorWithCalibratedRed:0.768 green:0.0 blue:0.0 alpha:1.0] setStroke];
//    path = [NSBezierPath bezierPathWithOvalInRect:CGRectMake(4.0, 5.0, 13.0, 10.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    [path setLineWidth:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [circleNoteImage unlockFocus];
//    [circleNoteImage setName:SKImageNameCircleNote];
//
//    squareNoteImage = [[UIImage alloc] initWithSize:size];
//    [squareNoteImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow2 set];
//    [[NSColor colorWithCalibratedRed:0.768 green:0.0 blue:0.0 alpha:1.0] setStroke];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(4.0, 5.0, 13.0, 10.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    [path setLineWidth:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [squareNoteImage unlockFocus];
//    [squareNoteImage setName:SKImageNameSquareNote];
//    
//    highlightNoteImage = [[UIImage alloc] initWithSize:size];
//    [highlightNoteImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:1.0 green:0.925 blue:0.0 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:1.0 green:0.745 blue:0.0 alpha:1.0]] autorelease];
//    [gradient drawInRect:CGRectMake(3.0, 2.0, 15.0, 16.0) angle:90.0];
//    NSShadow *redShadow = [[NSShadow alloc] init];
//    [redShadow setShadowBlurRadius:2.0];
//    [redShadow setShadowOffset:NSZeroSize];
//    [redShadow setShadowColor:[NSColor colorWithCalibratedRed:0.7 green:0.0 blue:0.0 alpha:1.0]];
//    [redShadow set];
//    [redShadow release];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(5.5, 5.0)];
//    [path lineToPoint:CGPointMake(9.5, 15.0)];
//    [path lineToPoint:CGPointMake(11.5, 15.0)];
//    [path lineToPoint:CGPointMake(15.5, 5.0)];
//    [path lineToPoint:CGPointMake(13.5, 5.0)];
//    [path lineToPoint:CGPointMake(12.7, 7.0)];
//    [path lineToPoint:CGPointMake(8.3, 7.0)];
//    [path lineToPoint:CGPointMake(7.5, 5.0)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(9.1, 9.0)];
//    [path lineToPoint:CGPointMake(11.9, 9.0)];
//    [path lineToPoint:CGPointMake(10.5, 12.5)];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [highlightNoteImage unlockFocus];
//    [highlightNoteImage setName:SKImageNameHighlightNote];
//
//    underlineNoteImage = [[UIImage alloc] initWithSize:size];
//    [underlineNoteImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(5.5, 6.0)];
//    [path lineToPoint:CGPointMake(9.5, 16.0)];
//    [path lineToPoint:CGPointMake(11.5, 16.0)];
//    [path lineToPoint:CGPointMake(15.5, 6.0)];
//    [path lineToPoint:CGPointMake(13.5, 6.0)];
//    [path lineToPoint:CGPointMake(12.7, 8.0)];
//    [path lineToPoint:CGPointMake(8.3, 8.0)];
//    [path lineToPoint:CGPointMake(7.5, 6.0)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(9.1, 10.0)];
//    [path lineToPoint:CGPointMake(11.9, 10.0)];
//    [path lineToPoint:CGPointMake(10.5, 13.5)];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(2.0, 3.0, 17.0, 2.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [underlineNoteImage unlockFocus];
//    [underlineNoteImage setName:SKImageNameUnderlineNote];
//
//    strikeOutNoteImage = [[UIImage alloc] initWithSize:size];
//    [strikeOutNoteImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow1 set];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(5.5, 4.0)];
//    [path lineToPoint:CGPointMake(9.5, 14.0)];
//    [path lineToPoint:CGPointMake(11.5, 14.0)];
//    [path lineToPoint:CGPointMake(15.5, 4.0)];
//    [path lineToPoint:CGPointMake(13.5, 4.0)];
//    [path lineToPoint:CGPointMake(12.7, 6.0)];
//    [path lineToPoint:CGPointMake(8.3, 6.0)];
//    [path lineToPoint:CGPointMake(7.5, 4.0)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(9.1, 8.0)];
//    [path lineToPoint:CGPointMake(11.9, 8.0)];
//    [path lineToPoint:CGPointMake(10.5, 11.5)];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setFill];
//    path = [NSBezierPath bezierPathWithRect:CGRectMake(2.0, 7.0, 17.0, 2.0)];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [strikeOutNoteImage unlockFocus];
//    [strikeOutNoteImage setName:SKImageNameStrikeOutNote];
//
//    lineNoteImage = [[UIImage alloc] initWithSize:size];
//    [lineNoteImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow2 set];
//    [[NSColor colorWithCalibratedRed:0.706 green:0.0 blue:0.0 alpha:1.0] setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(3.0, 10.0)];
//    [path lineToPoint:CGPointMake(15.0, 10.0)];
//    [path lineToPoint:CGPointMake(15.0, 7.5)];
//    [path lineToPoint:CGPointMake(18.5, 11.0)];
//    [path lineToPoint:CGPointMake(15.0, 14.5)];
//    [path lineToPoint:CGPointMake(15.0, 12.0)];
//    [path lineToPoint:CGPointMake(3.0, 12.0)];
//    [path closePath];
//    [path fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [lineNoteImage unlockFocus];
//    [lineNoteImage setName:SKImageNameLineNote];
//
//    inkNoteImage = [[UIImage alloc] initWithSize:size];
//    [inkNoteImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow2 set];
//    [[NSColor colorWithCalibratedRed:0.706 green:0.0 blue:0.0 alpha:1.0] setStroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(4.0, 9.0)];
//    [path curveToPoint:CGPointMake(10.5, 10.0) controlPoint1:CGPointMake(10.0, 5.0) controlPoint2:CGPointMake(13.0, 5.0)];
//    [path curveToPoint:CGPointMake(17.0, 11.0) controlPoint1:CGPointMake(8.0, 15.0) controlPoint2:CGPointMake(11.0, 15.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    [path setLineWidth:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [inkNoteImage unlockFocus];
//    [inkNoteImage setName:SKImageNameInkNote];
//    
//    [shadow1 release];
//    [shadow2 release];
//    [shadow3 release];
//}
//
//+ (void)makeAdornImages {
//    static UIImage *outlineViewAdornImage = nil;
//    static UIImage *thumbnailViewAdornImage = nil;
//    static UIImage *noteViewAdornImage = nil;
//    static UIImage *snapshotViewAdornImage = nil;
//    static UIImage *findViewAdornImage = nil;
//    static UIImage *groupedFindViewAdornImage = nil;
//    
//    if (outlineViewAdornImage)
//        return;
//    
//    NSShadow *shadow1 = [[NSShadow alloc] init];
//    [shadow1 setShadowBlurRadius:0.0];
//    [shadow1 setShadowOffset:NSMakeSize(0.0, -1.0)];
//    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.1]];
//    
//    NSSize size = NSMakeSize(25.0, 14.0);
//    NSRect rect = {NSZeroPoint, size};
//    
//    NSColor *color = [NSColor colorWithCalibratedWhite:0.0 alpha:0.85];
//    
//    NSBezierPath *path;
//    
//    outlineViewAdornImage = [[UIImage alloc] initWithSize:size];
//    [outlineViewAdornImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow1 set];
//    [color setStroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(7.0, 2.5)];
//    [path lineToPoint:CGPointMake(18.0, 2.5)];
//    [path moveToPoint:CGPointMake(7.0, 5.5)];
//    [path lineToPoint:CGPointMake(18.0, 5.5)];
//    [path moveToPoint:CGPointMake(7.0, 8.5)];
//    [path lineToPoint:CGPointMake(18.0, 8.5)];
//    [path moveToPoint:CGPointMake(7.0, 11.5)];
//    [path lineToPoint:CGPointMake(18.0, 11.5)];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    [outlineViewAdornImage unlockFocus];
//    [outlineViewAdornImage setTemplate:YES];
//    [outlineViewAdornImage setName:SKImageNameOutlineViewAdorn];
//    
//    thumbnailViewAdornImage = [[UIImage alloc] initWithSize:size];
//    [thumbnailViewAdornImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow1 set];
//    [color setStroke];
//    path = [NSBezierPath bezierPath];
//    [path appendBezierPathWithRect:CGRectMake(10.5, 1.5, 4.0, 4.0)];
//    [path appendBezierPathWithRect:CGRectMake(10.5, 8.5, 4.0, 4.0)];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    [thumbnailViewAdornImage unlockFocus];
//    [thumbnailViewAdornImage setTemplate:YES];
//    [thumbnailViewAdornImage setName:SKImageNameThumbnailViewAdorn];
//    
//    noteViewAdornImage = [[UIImage alloc] initWithSize:size];
//    [noteViewAdornImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow1 set];
//    [color setStroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(13.0, 3.5)];
//    [path lineToPoint:CGPointMake(18.0, 3.5)];
//    [path moveToPoint:CGPointMake(13.0, 10.5)];
//    [path lineToPoint:CGPointMake(18.0, 10.5)];
//    [path moveToPoint:CGPointMake(10.0, 1.5)];
//    [path lineToPoint:CGPointMake(7.5, 1.5)];
//    [path lineToPoint:CGPointMake(7.5, 5.5)];
//    [path lineToPoint:CGPointMake(11.5, 5.5)];
//    [path lineToPoint:CGPointMake(11.5, 3.0)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(10.5, 1.5)];
//    [path lineToPoint:CGPointMake(10.5, 2.5)];
//    [path lineToPoint:CGPointMake(11.5, 2.5)];
//    [path moveToPoint:CGPointMake(10.0, 8.5)];
//    [path lineToPoint:CGPointMake(7.5, 8.5)];
//    [path lineToPoint:CGPointMake(7.5, 12.5)];
//    [path lineToPoint:CGPointMake(11.5, 12.5)];
//    [path lineToPoint:CGPointMake(11.5, 10.0)];
//    [path closePath];
//    [path moveToPoint:CGPointMake(10.5, 8.5)];
//    [path lineToPoint:CGPointMake(10.5, 9.5)];
//    [path lineToPoint:CGPointMake(11.5, 9.5)];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    [noteViewAdornImage unlockFocus];
//    [noteViewAdornImage setTemplate:YES];
//    [noteViewAdornImage setName:SKImageNameNoteViewAdorn];
//    
//    snapshotViewAdornImage = [[UIImage alloc] initWithSize:size];
//    [snapshotViewAdornImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow1 set];
//    [color setStroke];
//    path = [NSBezierPath bezierPath];
//    [path appendBezierPathWithRect:CGRectMake(7.5, 1.5, 10.0, 4.0)];
//    [path appendBezierPathWithRect:CGRectMake(7.5, 8.5, 10.0, 4.0)];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    [snapshotViewAdornImage unlockFocus];
//    [snapshotViewAdornImage setTemplate:YES];
//    [snapshotViewAdornImage setName:SKImageNameSnapshotViewAdorn];
//    
//    findViewAdornImage = [[UIImage alloc] initWithSize:size];
//    [findViewAdornImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow1 set];
//    [color setStroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(7.0, 2.5)];
//    [path lineToPoint:CGPointMake(9.0, 2.5)];
//    [path moveToPoint:CGPointMake(7.0, 5.5)];
//    [path lineToPoint:CGPointMake(9.0, 5.5)];
//    [path moveToPoint:CGPointMake(7.0, 8.5)];
//    [path lineToPoint:CGPointMake(9.0, 8.5)];
//    [path moveToPoint:CGPointMake(7.0, 11.5)];
//    [path lineToPoint:CGPointMake(9.0, 11.5)];
//    [path moveToPoint:CGPointMake(10.0, 2.5)];
//    [path lineToPoint:CGPointMake(18.0, 2.5)];
//    [path moveToPoint:CGPointMake(10.0, 5.5)];
//    [path lineToPoint:CGPointMake(18.0, 5.5)];
//    [path moveToPoint:CGPointMake(10.0, 8.5)];
//    [path lineToPoint:CGPointMake(18.0, 8.5)];
//    [path moveToPoint:CGPointMake(10.0, 11.5)];
//    [path lineToPoint:CGPointMake(18.0, 11.5)];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    [findViewAdornImage unlockFocus];
//    [findViewAdornImage setTemplate:YES];
//    [findViewAdornImage setName:SKImageNameFindViewAdorn];
//    
//    groupedFindViewAdornImage = [[UIImage alloc] initWithSize:size];
//    [groupedFindViewAdornImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [shadow1 set];
//    [color setStroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(7.0, 3.0)];
//    [path lineToPoint:CGPointMake(12.0, 3.0)];
//    [path moveToPoint:CGPointMake(7.0, 7.0)];
//    [path lineToPoint:CGPointMake(16.0, 7.0)];
//    [path moveToPoint:CGPointMake(7.0, 11.0)];
//    [path lineToPoint:CGPointMake(18.0, 11.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    [groupedFindViewAdornImage unlockFocus];
//    [groupedFindViewAdornImage setTemplate:YES];
//    [groupedFindViewAdornImage setName:SKImageNameGroupedFindViewAdorn];
//    
//    [shadow1 release];
//}
//
//+ (void)makeTextAlignImages {
//    static UIImage *textAlignLeftImage = nil;
//    static UIImage *textAlignCenterImage = nil;
//    static UIImage *textAlignRightImage = nil;
//    
//    if (textAlignLeftImage)
//        return;
//    
//    NSRect rect = CGRectMake(0.0, 0.0, 16.0, 11.0);
//    NSSize size = rect.size;
//    NSBezierPath *path;
//    
//    textAlignLeftImage = [[UIImage alloc] initWithSize:size];
//    [textAlignLeftImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [[NSColor blackColor] setStroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(1.0, 1.5)];
//    [path lineToPoint:CGPointMake(15.0, 1.5)];
//    [path moveToPoint:CGPointMake(1.0, 3.5)];
//    [path lineToPoint:CGPointMake(12.0, 3.5)];
//    [path moveToPoint:CGPointMake(1.0, 5.5)];
//    [path lineToPoint:CGPointMake(14.0, 5.5)];
//    [path moveToPoint:CGPointMake(1.0, 7.5)];
//    [path lineToPoint:CGPointMake(11.0, 7.5)];
//    [path moveToPoint:CGPointMake(1.0, 9.5)];
//    [path lineToPoint:CGPointMake(15.0, 9.5)];
//    [path setLineWidth:1.0];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    [textAlignLeftImage unlockFocus];
//    [textAlignLeftImage setName:SKImageNameTextAlignLeft];
//    
//    textAlignCenterImage = [[UIImage alloc] initWithSize:size];
//    [textAlignCenterImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [[NSColor blackColor] setStroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(1.0, 1.5)];
//    [path lineToPoint:CGPointMake(15.0, 1.5)];
//    [path moveToPoint:CGPointMake(4.0, 3.5)];
//    [path lineToPoint:CGPointMake(12.0, 3.5)];
//    [path moveToPoint:CGPointMake(2.0, 5.5)];
//    [path lineToPoint:CGPointMake(14.0, 5.5)];
//    [path moveToPoint:CGPointMake(5.0, 7.5)];
//    [path lineToPoint:CGPointMake(11.0, 7.5)];
//    [path moveToPoint:CGPointMake(1.0, 9.5)];
//    [path lineToPoint:CGPointMake(15.0, 9.5)];
//    [path setLineWidth:1.0];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    [textAlignCenterImage unlockFocus];
//    [textAlignCenterImage setName:SKImageNameTextAlignCenter];
//    
//    textAlignRightImage = [[UIImage alloc] initWithSize:size];
//    [textAlignRightImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [[NSColor blackColor] setStroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(1.0, 1.5)];
//    [path lineToPoint:CGPointMake(15.0, 1.5)];
//    [path moveToPoint:CGPointMake(4.0, 3.5)];
//    [path lineToPoint:CGPointMake(15.0, 3.5)];
//    [path moveToPoint:CGPointMake(2.0, 5.5)];
//    [path lineToPoint:CGPointMake(15.0, 5.5)];
//    [path moveToPoint:CGPointMake(5.0, 7.5)];
//    [path lineToPoint:CGPointMake(15.0, 7.5)];
//    [path moveToPoint:CGPointMake(1.0, 9.5)];
//    [path lineToPoint:CGPointMake(15.0, 9.5)];
//    [path setLineWidth:1.0];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    [textAlignRightImage unlockFocus];
//    [textAlignRightImage setName:SKImageNameTextAlignRight];
//}
//
//+ (void)makeCursorImages {
//    static UIImage *resizeDiagonal45CursorImage = nil;
//    static UIImage *resizeDiagonal135CursorImage = nil;
//    static UIImage *zoomInCursorImage = nil;
//    static UIImage *zoomOutCursorImage = nil;
//    static UIImage *cameraCursorImage = nil;
//    static UIImage *openHandBarCursorImage = nil;
//    static UIImage *closedHandBarCursorImage = nil;
//    static UIImage *textNoteCursorImage = nil;
//    static UIImage *anchoredNoteCursorImage = nil;
//    static UIImage *circleNoteCursorImage = nil;
//    static UIImage *squareNoteCursorImage = nil;
//    static UIImage *highlightNoteCursorImage = nil;
//    static UIImage *underlineNoteCursorImage = nil;
//    static UIImage *strikeOutNoteCursorImage = nil;
//    static UIImage *lineNoteCursorImage = nil;
//    static UIImage *inkNoteCursorImage = nil;
//    
//    if (resizeDiagonal45CursorImage)
//        return;
//    
//    NSRect rect = CGRectMake(0.0, 0.0, 16.0, 16.0);
//    NSSize size = rect.size;
//    
//    NSColor *fgColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
//    NSColor *bgColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
//    
//    NSBezierPath *path;
//    
//    resizeDiagonal45CursorImage = [[UIImage alloc] initWithSize:size];
//    [resizeDiagonal45CursorImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSGraphicsContext currentContext] setImageInterpolation:UIImageInterpolationNone];
//    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [bgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(2.0, 2.0)];
//    [path lineToPoint:CGPointMake(8.0, 2.0)];
//    [path lineToPoint:CGPointMake(8.0, 4.0)];
//    [path lineToPoint:CGPointMake(7.0, 5.0)];
//    [path lineToPoint:CGPointMake(8.0, 6.0)];
//    [path lineToPoint:CGPointMake(13.0, 1.0)];
//    [path lineToPoint:CGPointMake(15.0, 3.0)];
//    [path lineToPoint:CGPointMake(10.0, 8.0)];
//    [path lineToPoint:CGPointMake(11.0, 9.0)];
//    [path lineToPoint:CGPointMake(12.0, 8.0)];
//    [path lineToPoint:CGPointMake(14.0, 8.0)];
//    [path lineToPoint:CGPointMake(14.0, 14.0)];
//    [path lineToPoint:CGPointMake(8.0, 14.0)];
//    [path lineToPoint:CGPointMake(8.0, 12.0)];
//    [path lineToPoint:CGPointMake(9.0, 11.0)];
//    [path lineToPoint:CGPointMake(8.0, 10.0)];
//    [path lineToPoint:CGPointMake(3.0, 15.0)];
//    [path lineToPoint:CGPointMake(1.0, 13.0)];
//    [path lineToPoint:CGPointMake(6.0, 8.0)];
//    [path lineToPoint:CGPointMake(5.0, 7.0)];
//    [path lineToPoint:CGPointMake(4.0, 8.0)];
//    [path lineToPoint:CGPointMake(2.0, 8.0)];
//    [path closePath];
//    [path fill];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(3.0, 3.0)];
//    [path lineToPoint:CGPointMake(7.0, 3.0)];
//    [path lineToPoint:CGPointMake(5.5, 4.5)];
//    [path lineToPoint:CGPointMake(8.0, 7.0)];
//    [path lineToPoint:CGPointMake(13.0, 2.0)];
//    [path lineToPoint:CGPointMake(14.0, 3.0)];
//    [path lineToPoint:CGPointMake(9.0, 8.0)];
//    [path lineToPoint:CGPointMake(11.5, 10.5)];
//    [path lineToPoint:CGPointMake(13.0, 9.0)];
//    [path lineToPoint:CGPointMake(13.0, 13.0)];
//    [path lineToPoint:CGPointMake(9.0, 13.0)];
//    [path lineToPoint:CGPointMake(10.5, 11.5)];
//    [path lineToPoint:CGPointMake(8.0, 9.0)];
//    [path lineToPoint:CGPointMake(3.0, 14.0)];
//    [path lineToPoint:CGPointMake(2.0, 13.0)];
//    [path lineToPoint:CGPointMake(7.0, 8.0)];
//    [path lineToPoint:CGPointMake(4.5, 5.5)];
//    [path lineToPoint:CGPointMake(3.0, 7.0)];
//    [path closePath];
//    [path fill];
//    [[NSGraphicsContext currentContext] setImageInterpolation:UIImageInterpolationDefault];
//    [NSGraphicsContext restoreGraphicsState];
//    [resizeDiagonal45CursorImage unlockFocus];
//    [resizeDiagonal45CursorImage setName:SKImageNameResizeDiagonal45Cursor];
//    
//    resizeDiagonal135CursorImage = [[UIImage alloc] initWithSize:size];
//    [resizeDiagonal135CursorImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSGraphicsContext currentContext] setImageInterpolation:UIImageInterpolationNone];
//    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [bgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(14.0, 2.0)];
//    [path lineToPoint:CGPointMake(14.0, 8.0)];
//    [path lineToPoint:CGPointMake(12.0, 8.0)];
//    [path lineToPoint:CGPointMake(11.0, 7.0)];
//    [path lineToPoint:CGPointMake(10.0, 8.0)];
//    [path lineToPoint:CGPointMake(15.0, 13.0)];
//    [path lineToPoint:CGPointMake(13.0, 15.0)];
//    [path lineToPoint:CGPointMake(8.0, 10.0)];
//    [path lineToPoint:CGPointMake(7.0, 11.0)];
//    [path lineToPoint:CGPointMake(8.0, 12.0)];
//    [path lineToPoint:CGPointMake(8.0, 14.0)];
//    [path lineToPoint:CGPointMake(2.0, 14.0)];
//    [path lineToPoint:CGPointMake(2.0, 8.0)];
//    [path lineToPoint:CGPointMake(4.0, 8.0)];
//    [path lineToPoint:CGPointMake(5.0, 9.0)];
//    [path lineToPoint:CGPointMake(6.0, 8.0)];
//    [path lineToPoint:CGPointMake(1.0, 3.0)];
//    [path lineToPoint:CGPointMake(3.0, 1.0)];
//    [path lineToPoint:CGPointMake(8.0, 6.0)];
//    [path lineToPoint:CGPointMake(9.0, 5.0)];
//    [path lineToPoint:CGPointMake(8.0, 4.0)];
//    [path lineToPoint:CGPointMake(8.0, 2.0)];
//    [path closePath];
//    [path fill];
//    [fgColor setFill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(13.0, 3.0)];
//    [path lineToPoint:CGPointMake(13.0, 7.0)];
//    [path lineToPoint:CGPointMake(11.5, 5.5)];
//    [path lineToPoint:CGPointMake(9.0, 8.0)];
//    [path lineToPoint:CGPointMake(14.0, 13.0)];
//    [path lineToPoint:CGPointMake(13.0, 14.0)];
//    [path lineToPoint:CGPointMake(8.0, 9.0)];
//    [path lineToPoint:CGPointMake(5.5, 11.5)];
//    [path lineToPoint:CGPointMake(7.0, 13.0)];
//    [path lineToPoint:CGPointMake(3.0, 13.0)];
//    [path lineToPoint:CGPointMake(3.0, 9.0)];
//    [path lineToPoint:CGPointMake(4.5, 10.5)];
//    [path lineToPoint:CGPointMake(7.0, 8.0)];
//    [path lineToPoint:CGPointMake(2.0, 3.0)];
//    [path lineToPoint:CGPointMake(3.0, 2.0)];
//    [path lineToPoint:CGPointMake(8.0, 7.0)];
//    [path lineToPoint:CGPointMake(10.5, 4.5)];
//    [path lineToPoint:CGPointMake(9.0, 3.0)];
//    [path closePath];
//    [path fill];
//    [[NSGraphicsContext currentContext] setImageInterpolation:UIImageInterpolationDefault];
//    [NSGraphicsContext restoreGraphicsState];
//    [resizeDiagonal135CursorImage unlockFocus];
//    [resizeDiagonal135CursorImage setName:SKImageNameResizeDiagonal135Cursor];
//    
//    zoomInCursorImage = [[UIImage alloc] initWithSize:size];
//    [zoomInCursorImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [bgColor set];
//    path = [NSBezierPath bezierPathWithOvalInRect:CGRectMake(0.0, 3.0, 13.0, 13.0)];
//    [path fill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(15.5, 0.5)];
//    [path lineToPoint:CGPointMake(10.0, 6.0)];
//    [path setLineWidth:4.5];
//    [path stroke];
//    [fgColor setStroke];
//    path = [NSBezierPath bezierPathWithOvalInRect:CGRectMake(2.0, 5.0, 9.0, 9.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(14.5, 1.5)];
//    [path lineToPoint:CGPointMake(9.5, 6.5)];
//    [path setLineWidth:2.5];
//    [path stroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(4.0, 9.5)];
//    [path lineToPoint:CGPointMake(9.0, 9.5)];
//    [path moveToPoint:CGPointMake(6.5, 7.0)];
//    [path lineToPoint:CGPointMake(6.5, 12.0)];
//    [path setLineWidth:1.0];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    [zoomInCursorImage unlockFocus];
//    [zoomInCursorImage setName:SKImageNameZoomInCursor];
//    
//    zoomOutCursorImage = [[UIImage alloc] initWithSize:size];
//    [zoomOutCursorImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [bgColor set];
//    path = [NSBezierPath bezierPathWithOvalInRect:CGRectMake(0.0, 3.0, 13.0, 13.0)];
//    [path fill];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(15.5, 0.5)];
//    [path lineToPoint:CGPointMake(10.0, 6.0)];
//    [path setLineWidth:4.5];
//    [path stroke];
//    [fgColor setStroke];
//    path = [NSBezierPath bezierPathWithOvalInRect:CGRectMake(2.0, 5.0, 9.0, 9.0)];
//    [path setLineWidth:2.0];
//    [path stroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(14.5, 1.5)];
//    [path lineToPoint:CGPointMake(9.5, 6.5)];
//    [path setLineWidth:2.5];
//    [path stroke];
//    path = [NSBezierPath bezierPath];
//    [path moveToPoint:CGPointMake(4.0, 9.5)];
//    [path lineToPoint:CGPointMake(9.0, 9.5)];
//    [path setLineWidth:1.0];
//    [path stroke];
//    [NSGraphicsContext restoreGraphicsState];
//    [zoomOutCursorImage unlockFocus];
//    [zoomOutCursorImage setName:SKImageNameZoomOutCursor];
//    
//    cameraCursorImage = [[UIImage alloc] initWithSize:size];
//    [cameraCursorImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSGraphicsContext currentContext] setImageInterpolation:UIImageInterpolationNone];
//    [[NSColor clearColor] setFill];
//    NSRectFill(rect);
//    [[NSColor whiteColor] set];
//    [[NSBezierPath bezierPathWithRect:CGRectMake(0.0, 2.0, 16.0, 11.0)] fill];
//    [[NSBezierPath bezierPathWithOvalInRect:CGRectMake(3.7, 6.7, 8.6, 8.6)] fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor blackColor] set];
//    [[NSBezierPath bezierPathWithRect:CGRectMake(1.0, 3.0, 14.0, 9.0)] fill];
//    [[NSBezierPath bezierPathWithOvalInRect:CGRectMake(5, 8, 6, 6)] fill];
//    [NSGraphicsContext restoreGraphicsState];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor whiteColor] set];
//    [[NSBezierPath bezierPathWithOvalInRect:CGRectMake(4.3, 4.3, 7.4, 7.4)] stroke];
//    path = [NSBezierPath bezierPath];
//    [path appendBezierPathWithArcWithCenter:CGPointMake(8.0, 8.0) radius:1.8 startAngle:45.0 endAngle:225.0];
//    [path closePath];
//    [path fill];
//    [[NSGraphicsContext currentContext] setImageInterpolation:UIImageInterpolationDefault];
//    [NSGraphicsContext restoreGraphicsState];
//    [cameraCursorImage unlockFocus];
//    [cameraCursorImage setName:SKImageNameCameraCursor];
//    
//    openHandBarCursorImage = [[UIImage alloc] initWithSize:size];
//    [openHandBarCursorImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor blackColor] setFill];
//    [NSBezierPath fillRect:CGRectMake(0.0, 9.0, 16.0, 3.0)];
//    [[[NSCursor openHandCursor] image] drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [openHandBarCursorImage unlockFocus];
//    [openHandBarCursorImage setName:SKImageNameOpenHandBarCursor];
//    
//    closedHandBarCursorImage = [[UIImage alloc] initWithSize:size];
//    [closedHandBarCursorImage lockFocus];
//    [NSGraphicsContext saveGraphicsState];
//    [[NSColor blackColor] setFill];
//    [NSBezierPath fillRect:CGRectMake(0.0, 6.0, 16.0, 3.0)];
//    [[[NSCursor closedHandCursor] image] drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//    [NSGraphicsContext restoreGraphicsState];
//    [closedHandBarCursorImage unlockFocus];
//    [closedHandBarCursorImage setName:SKImageNameClosedHandBarCursor];
//    
//    textNoteCursorImage = [[UIImage imageNamed:SKImageNameTextNote] copyArrowCursorImage];
//    [textNoteCursorImage setName:SKImageNameTextNoteCursor];
//    
//    anchoredNoteCursorImage = [[UIImage imageNamed:SKImageNameAnchoredNote] copyArrowCursorImage];
//    [anchoredNoteCursorImage setName:SKImageNameAnchoredNoteCursor];
//    
//    circleNoteCursorImage = [[UIImage imageNamed:SKImageNameCircleNote] copyArrowCursorImage];
//    [circleNoteCursorImage setName:SKImageNameCircleNoteCursor];
//    
//    squareNoteCursorImage = [[UIImage imageNamed:SKImageNameSquareNote] copyArrowCursorImage];
//    [squareNoteCursorImage setName:SKImageNameSquareNoteCursor];
//    
//    highlightNoteCursorImage = [[UIImage imageNamed:SKImageNameHighlightNote] copyArrowCursorImage];
//    [highlightNoteCursorImage setName:SKImageNameHighlightNoteCursor];
//    
//    underlineNoteCursorImage = [[UIImage imageNamed:SKImageNameUnderlineNote] copyArrowCursorImage];
//    [underlineNoteCursorImage setName:SKImageNameUnderlineNoteCursor];
//    
//    strikeOutNoteCursorImage = [[UIImage imageNamed:SKImageNameStrikeOutNote] copyArrowCursorImage];
//    [strikeOutNoteCursorImage setName:SKImageNameStrikeOutNoteCursor];
//    
//    lineNoteCursorImage = [[UIImage imageNamed:SKImageNameLineNote] copyArrowCursorImage];
//    [lineNoteCursorImage setName:SKImageNameLineNoteCursor];
//    
//    inkNoteCursorImage = [[UIImage imageNamed:SKImageNameInkNote] copyArrowCursorImage];
//    [inkNoteCursorImage setName:SKImageNameInkNoteCursor];
//}

+ (void)makeImages {
//    [self makeNoteImages];
//    [self makeAdornImages];
    [self makeToolbarImages];
//    [self makeTextAlignImages];
//    [self makeCursorImages];
}

@end
