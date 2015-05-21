//
//  NSImage_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 7/27/07.
/*
 This software is Copyright (c) 2007-2015
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
#import "NSBitmapImageRep_SKExtensions.h"
#import "NSShadow_SKExtensions.h"


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
NSString *SKImageNameToolbarInfo = @"ToolbarInfo";
NSString *SKImageNameToolbarColors = @"ToolbarColors";
NSString *SKImageNameToolbarFonts = @"ToolbarFonts";
NSString *SKImageNameToolbarLines = @"ToolbarLines";
NSString *SKImageNameToolbarPrint = @"ToolbarPrint";
NSString *SKImageNameToolbarCustomize = @"ToolbarCustomize";

NSString *SKImageNameGeneralPreferences = @"GeneralPreferences";
NSString *SKImageNameDisplayPreferences = @"DisplayPreferences";
NSString *SKImageNameNotesPreferences = @"NotesPreferences";
NSString *SKImageNameSyncPreferences = @"SyncPreferences";

NSString *SKImageNameNewFolder = @"NewFolder";
NSString *SKImageNameNewSeparator = @"NewSeparator";

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

NSString *SKImageNameRemoteStateResize = @"RemoteStateResize";
NSString *SKImageNameRemoteStateScroll = @"RemoteStateScroll";

static void drawTextNote();
static void drawAnchoredNote();
static void drawCircleNote();
static void drawSquareNote();
static void drawHighlightNote();
static void drawUnderlineNote();
static void drawStrikeOutNote();
static void drawLineNote();
static void drawInkNote();
static void drawTextNoteTemplate();
static void drawAnchoredNoteTemplate();
static void drawCircleNoteTemplate();
static void drawSquareNoteTemplate();
static void drawHighlightNoteTemplate();
static void drawUnderlineNoteTemplate();
static void drawStrikeOutNoteTemplate();
static void drawLineNoteTemplate();
static void drawInkNoteTemplate();

static void drawMenuBadge();
static void drawAddBadge();
static void drawMenuBadgeTemplate();
static void drawAddBadgeTemplate();

static inline void translate(CGFloat delta);

static inline void drawPageBackgroundInRect(NSRect rect);
static inline void drawPageBackgroundTemplateInRect(NSRect rect);

static inline void drawArrowCursor();

static void drawAddBadgeAtPoint(NSPoint point);

#define MAKE_IMAGE(name, isTemplate, width, height, instructions) \
do { \
    static NSImage *image = nil; \
    image = [[NSImage bitmapImageWithSize:NSMakeSize(width, height) drawingHandler:^(NSRect rect, CGFloat bScale){ \
        instructions \
    }] retain]; \
    [image setTemplate:isTemplate]; \
    [image setName:name]; \
} while (0)

#define APPLY_NOTE_TYPES(macro) \
macro(Text); \
macro(Anchored); \
macro(Circle); \
macro(Square); \
macro(Highlight); \
macro(Underline); \
macro(StrikeOut); \
macro(Line); \
macro(Ink)

#if !defined(MAC_OS_X_VERSION_10_7) || MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7
@interface NSImage (SKMountainLionDeclarations)
+ (NSImage *)imageWithSize:(NSSize)size flipped:(BOOL)drawingHandlerShouldBeCalledWithFlippedContext drawingHandler:(BOOL (^)(NSRect dstRect))drawingHandler;
@end
#endif

@implementation NSImage (SKExtensions)

+ (NSImage *)imageWithSize:(NSSize)size drawingHandler:(BOOL (^)(NSRect dstRect))drawingHandler {
    if ([self respondsToSelector:@selector(imageWithSize:flipped:drawingHandler:)]) {
        return [self imageWithSize:size flipped:NO drawingHandler:drawingHandler];
    } else {
        NSImage *image = [[[self alloc] initWithSize:size] autorelease];
        [image lockFocus];
        if (drawingHandler) drawingHandler((NSRect){NSZeroPoint, size});
        [image unlockFocus];
        return image;
    }
}

+ (NSImage *)bitmapImageWithSize:(NSSize)size scale:(CGFloat)scale drawingHandler:(void (^)(NSRect dstRect, CGFloat backingScale))drawingHandler {
    NSImage *image = [[[self alloc] initWithSize:size] autorelease];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithSize:size scale:scale drawingHandler:drawingHandler];
    [image addRepresentation:imageRep];
    return image;
}

+ (NSImage *)bitmapImageWithSize:(NSSize)size drawingHandler:(void (^)(NSRect dstRect, CGFloat backingScale))drawingHandler {
    NSImage *image = [[[self alloc] initWithSize:size] autorelease];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithSize:size scale:2.0 drawingHandler:drawingHandler];
    [image addRepresentation:imageRep];
    imageRep = [NSBitmapImageRep imageRepWithSize:size scale:1.0 drawingHandler:drawingHandler];
    [image addRepresentation:imageRep];
    return image;
}

+ (void)makeToolbarImages {
    
    MAKE_IMAGE(SKImageNameToolbarPageUp, NO, 27.0, 19.0, 
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(17.0, 2.5)];
        [path lineToPoint:NSMakePoint(8.5, 7.0)];
        [path lineToPoint:NSMakePoint(17.0, 11.5)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarForward, NO, 27.0, 13.0, 
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(10.0, 2.5)];
        [path lineToPoint:NSMakePoint(18.5, 7.0)];
        [path lineToPoint:NSMakePoint(10.0, 11.5)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomIn, NO, 27.0, 19.0, 
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(7.0, 9.0, 13.0, 3.0)];
        [path appendBezierPathWithRect:NSMakeRect(12.0, 4.0, 3.0, 13.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomOut, NO, 27.0, 9.0, 
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(7.0, 4.0, 13.0, 3.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomActual, NO, 27.0, 14.0, 
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(7.0, 4.0, 13.0, 3.0)];
        [path appendBezierPathWithRect:NSMakeRect(7.0, 9.0, 13.0, 3.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomToFit, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
        [path setLineWidth:2.0];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(7.0, 6.0, 13.0, 9.0));
        [[NSColor whiteColor] setFill];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [[NSColor whiteColor] setFill];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] set];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(13.5, 10.0) radius:6.0 startAngle:-180.0 endAngle:90.0 clockwise:NO];
        [path lineToPoint:NSMakePoint(13.5, 19.0)];
        [path lineToPoint:NSMakePoint(9.0, 14.5)];
        [path lineToPoint:NSMakePoint(13.5, 10.0)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(13.5, 10.0) radius:3.0 startAngle:90.0 endAngle:-180.0 clockwise:YES];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarRotateRight, NO, 27.0, 21.0, 
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] set];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
        [path setLineWidth:2.0];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(7.0, 6.0, 13.0, 9.0));
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] blurRadius:2.0 yOffset:0.0];
        [[NSColor colorWithCalibratedRed:1.0 green:0.865 blue:0.296 alpha:1.0] setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 7.0, 21.0, 2.0)];
        [path fill];
        [[NSColor colorWithCalibratedRed:1.0 green:0.906 blue:0.496 alpha:1.0] setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(17.0, 2.0, 2.0, 17.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarFullScreen, NO, 27.0, 21.0, 
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.0, 4.0, 17.0, 14.0) xRadius:2.0 yRadius:2.0];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.0, 4.0, 17.0, 14.0) xRadius:2.0 yRadius:2.0];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(10.0, 5.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarTwoUp, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 12.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(6.0, 5.0, 7.0 , 10.0));
        drawPageBackgroundInRect(NSMakeRect(14.0, 5.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarSinglePageContinuous, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
        [path addClip];
        drawPageBackgroundInRect(NSMakeRect(10.0, 11.0, 7.0 , 10.0));
        drawPageBackgroundInRect(NSMakeRect(10.0, 0.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarTwoUpContinuous, NO, 27.0, 19.0, 
        [NSGraphicsContext saveGraphicsState];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 12.0)];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 9.0, 9.0 , 7.0)];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 11.0, 9.0 , 5.0)];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
        [path setLineWidth:2.0];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(7.0, 6.0, 13.0, 9.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarCropBox, NO, 27.0, 21.0, 
        [NSGraphicsContext saveGraphicsState];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
        [path setLineWidth:2.0];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
        drawPageBackgroundInRect(NSMakeRect(7.0, 6.0, 13.0, 9.0));
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] blurRadius:2.0 yOffset:0.0];
        [[NSColor colorWithCalibratedRed:1.0 green:0.865 blue:0.296 alpha:1.0] setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 7.0, 21.0, 2.0)];
        [path fill];
        [[NSColor colorWithCalibratedRed:1.0 green:0.906 blue:0.496 alpha:1.0] setFill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(17.0, 2.0, 2.0, 17.0)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarLeftPane, NO, 27.0, 17.0, 
        [NSGraphicsContext saveGraphicsState];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.925 green:0.925 blue:0.925 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.868 green:0.868 blue:0.868 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(12.0, 5.0, 9.0, 9.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.431 green:0.478 blue:0.589 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.714 green:0.744 blue:0.867 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(10.0, 4.0, 1.0, 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.502 green:0.537 blue:0.640 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.761 green:0.784 blue:0.900 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(5.0, 4.0, 5.0, 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.382 green:0.435 blue:0.547 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.696 green:0.722 blue:0.843 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(6.0, 5.0, 3.0, 9.0) angle:90.0];
        [[NSColor whiteColor] setFill];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0)];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.925 green:0.925 blue:0.925 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.868 green:0.868 blue:0.868 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(6.0, 5.0, 9.0, 9.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.431 green:0.478 blue:0.589 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.714 green:0.744 blue:0.867 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(16.0, 4.0, 1.0, 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.502 green:0.537 blue:0.640 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.761 green:0.784 blue:0.900 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(17.0, 4.0, 5.0, 11.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.382 green:0.435 blue:0.547 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.696 green:0.722 blue:0.843 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(18.0, 5.0, 3.0, 9.0) angle:90.0];
        [[NSColor whiteColor] setFill];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(7.0, 4.0, 13.0, 13.0)];
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
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.976 green:0.976 blue:0.976 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.798 green:0.798 blue:0.798 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(7.0, 4.0, 13.0, 6.0) angle:90.0];
    );
    
    MAKE_IMAGE(SKImageNameToolbarMoveTool, NO, 27.0, 19.0, 
        [[NSColor whiteColor] setStroke];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(10.5, 3.0)];
        [path curveToPoint:NSMakePoint(8.0, 7.0) controlPoint1:NSMakePoint(10.5, 4.5) controlPoint2:NSMakePoint(10.5, 4.5)];
        [path curveToPoint:NSMakePoint(6.5, 11.0) controlPoint1:NSMakePoint(5.5, 9.5) controlPoint2:NSMakePoint(5.5, 10.0)];
        [path curveToPoint:NSMakePoint(10.0, 9.5) controlPoint1:NSMakePoint(7.5, 12.0) controlPoint2:NSMakePoint(7.5, 12.0)];
        [path curveToPoint:NSMakePoint(9.5, 15.5) controlPoint1:NSMakePoint(7.5, 14.0) controlPoint2:NSMakePoint(7.0, 15.5)];
        [path curveToPoint:NSMakePoint(11.5, 11.5) controlPoint1:NSMakePoint(10.5, 15.5) controlPoint2:NSMakePoint(10.5, 15.5)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(13.0, 15.5) radius:1.5 startAngle:180.0 endAngle:0.0 clockwise:YES];
        [path moveToPoint:NSMakePoint(14.5, 11.0)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(16.0, 14.5) radius:1.5 startAngle:180.0 endAngle:0.0 clockwise:YES];
        [path lineToPoint:NSMakePoint(17.5, 12.5)];
        [path moveToPoint:NSMakePoint(17.5, 10.5)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(19.0, 12.5) radius:1.5 startAngle:180.0 endAngle:0.0 clockwise:YES];
        [path curveToPoint:NSMakePoint(17.5, 3.0) controlPoint1:NSMakePoint(20.5, 8.5) controlPoint2:NSMakePoint(17.5, 7.0)];
        [path setLineJoinStyle:NSRoundLineJoinStyle];
        [path setLineWidth:1.5];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarMagnifyTool, NO, 27.0, 19.0, 
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
        [[NSColor whiteColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
    
    MAKE_IMAGE(SKImageNameToolbarPrint, NO, 27.0, 20.0, 
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(3.0, 13.0)];
        [path lineToPoint:NSMakePoint(5.0, 15.0)];
        [path lineToPoint:NSMakePoint(22.0, 15.0)];
        [path lineToPoint:NSMakePoint(24.0, 13.0)];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(24.0, 5.0) toPoint:NSMakePoint(3.0, 5.0) radius:2.0];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(3.0, 5.0) toPoint:NSMakePoint(3.0, 13.0) radius:2.0];
        [path closePath];
        [NSGraphicsContext saveGraphicsState];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.333] blurRadius:1.0 yOffset:-1.0];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] set];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        [NSGraphicsContext saveGraphicsState];
        [path addClip];
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0] endingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.2]] autorelease];
        [gradient drawInRect:NSMakeRect(5.0, 5.0, 17.0, 6.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] endingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]] autorelease];
        [gradient drawInRect:NSMakeRect(6.0, 5.0, 15.0, 6.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3] endingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]] autorelease];
        [gradient drawInRect:NSMakeRect(3.0, 5.0, 21.0, 3.0) angle:90.0];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0] endingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.6]] autorelease];
        [gradient drawInRect:NSMakeRect(3.0, 11.5, 21.0, 3.5) angle:90.0];
        [NSGraphicsContext restoreGraphicsState];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.316 green:0.488 blue:0.630 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.395 green:0.602 blue:0.792 alpha:1.0]] autorelease];
        [gradient drawInRect:NSMakeRect(6.0, 15.0, 15.0, 2.0) angle:90.0];
        [NSGraphicsContext saveGraphicsState];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 14.0, 27.0, 6.0)];
        [path addClip];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(8.0, 14.0, 11.0, 4.0)];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:1.0 yOffset:0.0];
        [[NSColor whiteColor] set];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        [NSGraphicsContext saveGraphicsState];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(7.0, 2.0, 13.0, 8.0)];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] blurRadius:1.0 yOffset:-1.0];
        [[NSColor whiteColor] set];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 10.0, 2.0, 1.0)];
        [[NSColor colorWithCalibratedRed:1.0 green:0.51 blue:0.16 alpha:1.0] set];
        [path fill];
        gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0] endingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.35]] autorelease];
        [gradient drawInRect:NSMakeRect(7.0, 6.0, 13.0, 4.0) angle:90.0];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.05] set];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(8.0, 3.0, 11.0, 7.0)];
        [path fill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(8.0, 3.0, 4.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(13.0, 3.0, 2.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(16.0, 3.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(8.0, 5.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(12.0, 5.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(16.0, 5.0, 2.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(8.0, 7.0, 7.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(16.0, 7.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(8.0, 9.0, 8.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(16.0, 9.0, 2.0, 1.0)];
        [path fill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(8.0, 3.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(17.0, 3.0, 1.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(8.0, 5.0, 2.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(12.0, 5.0, 2.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(8.0, 7.0, 4.0, 1.0)];
        [path fill];
    );
    
#define MAKE_BADGED_IMAGES(name) \
    MAKE_IMAGE(SKImageNameToolbarAdd ## name ## Note, NO, 27.0, 19.0, \
        translate(3.0); \
        draw ## name ## Note(); \
        drawAddBadge(); \
    ); \
    MAKE_IMAGE(SKImageNameToolbar ## name ## NoteMenu, NO, 27.0, 19.0, \
        drawMenuBadge(); \
        translate(1.0); \
        draw ## name ## Note(); \
    ); \
    MAKE_IMAGE(SKImageNameToolbarAdd ## name ## NoteMenu, NO, 27.0, 19.0, \
        drawMenuBadge(); \
        translate(1.0); \
        draw ## name ## Note(); \
        drawAddBadge(); \
    );
    
    APPLY_NOTE_TYPES(MAKE_BADGED_IMAGES);
    
}

+ (void)makeToolbarTemplateImages {
    
    MAKE_IMAGE(SKImageNameToolbarPageUp, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(9.5, 10.5)];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(9.5, 3.5) toPoint:NSMakePoint(17.5, 3.5) radius:1.0];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(17.5, 3.5) toPoint:NSMakePoint(17.5, 10.5) radius:1.0];
        [path lineToPoint:NSMakePoint(17.5, 10.5)];
        [path lineToPoint:NSMakePoint(20.5, 10.5)];
        [path lineToPoint:NSMakePoint(13.5, 17.5)];
        [path lineToPoint:NSMakePoint(6.5, 10.5)];
        [path closePath];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarPageDown, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(9.5, 9.5)];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(9.5, 16.5) toPoint:NSMakePoint(17.5, 16.5) radius:1.0];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(17.5, 16.5) toPoint:NSMakePoint(17.5, 9.5) radius:1.0];
        [path lineToPoint:NSMakePoint(17.5, 9.5)];
        [path lineToPoint:NSMakePoint(20.5, 9.5)];
        [path lineToPoint:NSMakePoint(13.5, 2.5)];
        [path lineToPoint:NSMakePoint(6.5, 9.5)];
        [path closePath];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarFirstPage, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(9.5, 5.5)];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(9.5, 3.5) toPoint:NSMakePoint(17.5, 3.5) radius:1.0];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(17.5, 3.5) toPoint:NSMakePoint(17.5, 10.5) radius:1.0];
        [path lineToPoint:NSMakePoint(17.5, 5.5)];
        [path closePath];
        [path moveToPoint:NSMakePoint(9.5, 7.5)];
        [path lineToPoint:NSMakePoint(17.5, 7.5)];
        [path lineToPoint:NSMakePoint(17.5, 10.5)];
        [path lineToPoint:NSMakePoint(20.5, 10.5)];
        [path lineToPoint:NSMakePoint(13.5, 17.5)];
        [path lineToPoint:NSMakePoint(6.5, 10.5)];
        [path lineToPoint:NSMakePoint(9.5, 10.5)];
        [path closePath];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarLastPage, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(9.5, 14.5)];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(9.5, 16.5) toPoint:NSMakePoint(17.5, 16.5) radius:1.0];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(17.5, 16.5) toPoint:NSMakePoint(17.5, 9.5) radius:1.0];
        [path lineToPoint:NSMakePoint(17.5, 14.5)];
        [path closePath];
        [path moveToPoint:NSMakePoint(9.5, 12.5)];
        [path lineToPoint:NSMakePoint(17.5, 12.5)];
        [path lineToPoint:NSMakePoint(17.5, 9.5)];
        [path lineToPoint:NSMakePoint(20.5, 9.5)];
        [path lineToPoint:NSMakePoint(13.5, 2.5)];
        [path lineToPoint:NSMakePoint(6.5, 9.5)];
        [path lineToPoint:NSMakePoint(9.5, 9.5)];
        [path closePath];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarBack, YES, 27.0, 17.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(14.0, 4.0)];
        [path lineToPoint:NSMakePoint(8.5, 9.5)];
        [path lineToPoint:NSMakePoint(14.0, 15.0)];
        [path setLineCapStyle:NSRoundLineCapStyle];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarForward, YES, 27.0, 17.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(13.0, 4.0)];
        [path lineToPoint:NSMakePoint(18.5, 9.5)];
        [path lineToPoint:NSMakePoint(13.0, 15.0)];
        [path setLineCapStyle:NSRoundLineCapStyle];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomIn, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithOvalInRect:NSMakeRect(6.5, 6.5, 10.0, 10.0)];
        [path moveToPoint:NSMakePoint(15.0, 8.0)];
        [path lineToPoint:NSMakePoint(20.0, 3.0)];
        [path moveToPoint:NSMakePoint(9.0, 11.5)];
        [path lineToPoint:NSMakePoint(14.0, 11.5)];
        [path moveToPoint:NSMakePoint(11.5, 9.0)];
        [path lineToPoint:NSMakePoint(11.5, 14.0)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomOut, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithOvalInRect:NSMakeRect(6.5, 6.5, 10.0, 10.0)];
        [path moveToPoint:NSMakePoint(15.0, 8.0)];
        [path lineToPoint:NSMakePoint(20.0, 3.0)];
        [path moveToPoint:NSMakePoint(9.0, 11.5)];
        [path lineToPoint:NSMakePoint(14.0, 11.5)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomActual, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithOvalInRect:NSMakeRect(6.5, 6.5, 10.0, 10.0)];
        [path moveToPoint:NSMakePoint(15.0, 8.0)];
        [path lineToPoint:NSMakePoint(20.0, 3.0)];
        [path moveToPoint:NSMakePoint(9.0, 10.5)];
        [path lineToPoint:NSMakePoint(14.0, 10.5)];
        [path moveToPoint:NSMakePoint(9.0, 12.5)];
        [path lineToPoint:NSMakePoint(14.0, 12.5)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomToFit, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.5, 4.5, 16.0 , 12.0) xRadius:1.0 yRadius:1.0];
        [path appendBezierPathWithOvalInRect:NSMakeRect(8.5, 6.5, 8.0, 8.0)];
        [path moveToPoint:NSMakePoint(15.5, 7.5)];
        [path lineToPoint:NSMakePoint(20.0, 3.0)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarZoomToSelection, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(5.5, 14.0)];
        [path lineToPoint:NSMakePoint(5.5, 16.5)];
        [path lineToPoint:NSMakePoint(9.0, 16.5)];
        [path moveToPoint:NSMakePoint(11.0, 16.5)];
        [path lineToPoint:NSMakePoint(16.0, 16.5)];
        [path moveToPoint:NSMakePoint(18.0, 16.5)];
        [path lineToPoint:NSMakePoint(21.5, 16.5)];
        [path lineToPoint:NSMakePoint(21.5, 14.0)];
        [path moveToPoint:NSMakePoint(21.5, 12.0)];
        [path lineToPoint:NSMakePoint(21.5, 9.0)];
        [path moveToPoint:NSMakePoint(21.5, 7.0)];
        [path lineToPoint:NSMakePoint(21.5, 4.5)];
        [path lineToPoint:NSMakePoint(18.0, 4.5)];
        [path moveToPoint:NSMakePoint(16.0, 4.5)];
        [path lineToPoint:NSMakePoint(11.0, 4.5)];
        [path moveToPoint:NSMakePoint(9.0, 4.5)];
        [path lineToPoint:NSMakePoint(5.5, 4.5)];
        [path lineToPoint:NSMakePoint(5.5, 7.0)];
        [path moveToPoint:NSMakePoint(5.5, 9.0)];
        [path lineToPoint:NSMakePoint(5.5, 12.0)];
        [path appendBezierPathWithOvalInRect:NSMakeRect(8.5, 6.5, 8.0, 8.0)];
        [path moveToPoint:NSMakePoint(15.5, 7.5)];
        [path lineToPoint:NSMakePoint(20.0, 3.0)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarRotateLeft, YES, 27.0, 21.0, 
        [[NSColor blackColor] set];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRoundedRect:NSMakeRect(7.5, 4.5, 9.0, 7.0) xRadius:1.0 yRadius:1.0];
        [path moveToPoint:NSMakePoint(20.5, 8.0)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(14.0, 10.0) radius:6.5 startAngle:0.0 endAngle:90.0 clockwise:NO];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(14.0, 14.0)];
        [path lineToPoint:NSMakePoint(14.0, 19.0)];
        [path lineToPoint:NSMakePoint(9.5, 16.5)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarRotateRight, YES, 27.0, 21.0, 
        [[NSColor blackColor] set];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRoundedRect:NSMakeRect(10.5, 4.5, 9.0, 7.0) xRadius:1.0 yRadius:1.0];
        [path moveToPoint:NSMakePoint(6.5, 8.0)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(13.0, 10.0) radius:6.5 startAngle:180.0 endAngle:90.0 clockwise:YES];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(13.0, 14.0)];
        [path lineToPoint:NSMakePoint(13.0, 19.0)];
        [path lineToPoint:NSMakePoint(17.5, 16.5)];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarCrop, YES, 27.0, 21.0, 
        [[NSColor blackColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.5, 4.5, 16.0 , 12.0) xRadius:1.0 yRadius:1.0];
        [path moveToPoint:NSMakePoint(3.0, 7.5)];
        [path lineToPoint:NSMakePoint(24.0, 7.5)];
        [path moveToPoint:NSMakePoint(18.5, 2.0)];
        [path lineToPoint:NSMakePoint(18.5, 19.0)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarFullScreen, YES, 27.0, 19.0, 
        [[NSColor blackColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.5, 4.5, 16.0, 12.0) xRadius:3.0 yRadius:3.0];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(11.0, 8.0)];
        [path lineToPoint:NSMakePoint(14.0, 8.0)];
        [path lineToPoint:NSMakePoint(11.0, 11.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(16.0, 13.0)];
        [path lineToPoint:NSMakePoint(13.0, 13.0)];
        [path lineToPoint:NSMakePoint(16.0, 10.0)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarPresentation, YES, 27.0, 19.0, 
        [[NSColor blackColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.5, 4.5, 16.0, 12.0) xRadius:3.0 yRadius:3.0];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(12.0, 7.0)];
        [path lineToPoint:NSMakePoint(15.5, 10.5)];
        [path lineToPoint:NSMakePoint(12.0, 14.0)];
        [path setLineCapStyle:NSRoundLineCapStyle];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarSinglePage, YES, 27.0, 19.0, 
        [[NSColor blackColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
        [path fill];
        drawPageBackgroundTemplateInRect(NSMakeRect(10.0, 5.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarTwoUp, YES, 27.0, 19.0, 
        [[NSColor blackColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 12.0)];
        [path fill];
        drawPageBackgroundTemplateInRect(NSMakeRect(6.0, 5.0, 7.0 , 10.0));
        drawPageBackgroundTemplateInRect(NSMakeRect(14.0, 5.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarSinglePageContinuous, YES, 27.0, 19.0, 
        [[NSColor blackColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
        [path fill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
        [path addClip];
        drawPageBackgroundTemplateInRect(NSMakeRect(10.0, 11.0, 7.0 , 10.0));
        drawPageBackgroundTemplateInRect(NSMakeRect(10.0, 0.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarTwoUpContinuous, YES, 27.0, 19.0, 
        [[NSColor blackColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 12.0)];
        [path fill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 4.0, 19.0 , 12.0)];
        [path addClip];
        drawPageBackgroundTemplateInRect(NSMakeRect(6.0, 11.0, 7.0 , 10.0));
        drawPageBackgroundTemplateInRect(NSMakeRect(14.0, 11.0, 7.0 , 10.0));
        drawPageBackgroundTemplateInRect(NSMakeRect(6.0, 0.0, 7.0 , 10.0));
        drawPageBackgroundTemplateInRect(NSMakeRect(14.0, 0.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarBookMode, YES, 27.0, 19.0, 
        [[NSColor blackColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 9.0, 9.0 , 7.0)];
        [path appendBezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 6.0)];
        [path fill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 4.0, 19.0 , 12.0)];
        [path addClip];
        drawPageBackgroundTemplateInRect(NSMakeRect(10.0, 10.0, 7.0 , 10.0));
        drawPageBackgroundTemplateInRect(NSMakeRect(6.0, -1.0, 7.0 , 10.0));
        drawPageBackgroundTemplateInRect(NSMakeRect(14.0, -1.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarPageBreaks, YES, 27.0, 19.0, 
        [[NSColor blackColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 11.0, 9.0 , 5.0)];
        [path appendBezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 5.0)];
        [path fill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(9.0, 4.0, 9.0 , 12.0)];
        [path addClip];
        drawPageBackgroundTemplateInRect(NSMakeRect(10.0, 12.0, 7.0 , 10.0));
        drawPageBackgroundTemplateInRect(NSMakeRect(10.0, -2.0, 7.0 , 10.0));
    );
    
    MAKE_IMAGE(SKImageNameToolbarMediaBox, YES, 27.0, 21.0, 
        [[NSColor blackColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.5, 4.5, 16.0 , 12.0) xRadius:1.0 yRadius:1.0];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarCropBox, YES, 27.0, 21.0, 
        [[NSColor blackColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5.5, 4.5, 16.0 , 12.0) xRadius:1.0 yRadius:1.0];
        [path moveToPoint:NSMakePoint(3.0, 7.5)];
        [path lineToPoint:NSMakePoint(24.0, 7.5)];
        [path moveToPoint:NSMakePoint(18.5, 2.0)];
        [path lineToPoint:NSMakePoint(18.5, 19.0)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarLeftPane, YES, 27.0, 17.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(6.5, 3.5, 14.0 , 11.0) xRadius:1.0 yRadius:1.0];
        [path moveToPoint:NSMakePoint(11.5, 4.0)];
        [path lineToPoint:NSMakePoint(11.5, 14.0)];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
        [path moveToPoint:NSMakePoint(8.0, 8.5)];
        [path lineToPoint:NSMakePoint(10.0, 8.5)];
        [path moveToPoint:NSMakePoint(8.0, 10.5)];
        [path lineToPoint:NSMakePoint(10.0, 10.5)];
        [path moveToPoint:NSMakePoint(8.0, 12.5)];
        [path lineToPoint:NSMakePoint(10.0, 12.5)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarRightPane, YES, 27.0, 17.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(6.5, 3.5, 14.0 , 11.0) xRadius:1.0 yRadius:1.0];
        [path moveToPoint:NSMakePoint(15.5, 4.0)];
        [path lineToPoint:NSMakePoint(15.5, 14.0)];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
        [path moveToPoint:NSMakePoint(17.0, 8.5)];
        [path lineToPoint:NSMakePoint(19.0, 8.5)];
        [path moveToPoint:NSMakePoint(17.0, 10.5)];
        [path lineToPoint:NSMakePoint(19.0, 10.5)];
        [path moveToPoint:NSMakePoint(17.0, 12.5)];
        [path lineToPoint:NSMakePoint(19.0, 12.5)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarTextTool, YES, 27.0, 19.0, 
        NSFont *font = [NSFont fontWithName:@"Helvetica" size:12.0];
        NSGlyph glyph = [font glyphWithName:@"A"];
        [[NSColor blackColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(7.5, 4.5, 12.0, 12.0)];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(13.5 - NSMidX([font boundingRectForGlyph:glyph]), 6.0)];
        [path appendBezierPathWithGlyph:glyph inFont:font];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameToolbarMoveTool, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(10.5, 3.0)];
        [path curveToPoint:NSMakePoint(8.0, 7.0) controlPoint1:NSMakePoint(10.5, 4.5) controlPoint2:NSMakePoint(10.5, 4.5)];
        [path curveToPoint:NSMakePoint(6.5, 11.0) controlPoint1:NSMakePoint(5.5, 9.5) controlPoint2:NSMakePoint(5.5, 10.0)];
        [path curveToPoint:NSMakePoint(10.0, 9.5) controlPoint1:NSMakePoint(7.5, 12.0) controlPoint2:NSMakePoint(7.5, 12.0)];
        [path curveToPoint:NSMakePoint(9.5, 15.5) controlPoint1:NSMakePoint(7.5, 14.0) controlPoint2:NSMakePoint(7.0, 15.5)];
        [path curveToPoint:NSMakePoint(11.5, 11.5) controlPoint1:NSMakePoint(10.5, 15.5) controlPoint2:NSMakePoint(10.5, 15.5)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(13.0, 15.5) radius:1.5 startAngle:180.0 endAngle:0.0 clockwise:YES];
        [path moveToPoint:NSMakePoint(14.5, 11.0)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(16.0, 14.5) radius:1.5 startAngle:180.0 endAngle:0.0 clockwise:YES];
        [path lineToPoint:NSMakePoint(17.5, 12.5)];
        [path moveToPoint:NSMakePoint(17.5, 10.5)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(19.0, 12.5) radius:1.5 startAngle:180.0 endAngle:0.0 clockwise:YES];
        [path curveToPoint:NSMakePoint(17.5, 3.0) controlPoint1:NSMakePoint(20.5, 8.5) controlPoint2:NSMakePoint(17.5, 7.0)];
        [path setLineJoinStyle:NSRoundLineJoinStyle];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarMagnifyTool, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithOvalInRect:NSMakeRect(6.5, 6.5, 10.0, 10.0)];
        [path moveToPoint:NSMakePoint(15.0, 8.0)];
        [path lineToPoint:NSMakePoint(20.0, 3.0)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarSelectTool, YES, 27.0, 19.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(7.5, 14.0)];
        [path lineToPoint:NSMakePoint(7.5, 16.5)];
        [path lineToPoint:NSMakePoint(10.0, 16.5)];
        [path moveToPoint:NSMakePoint(12.0, 16.5)];
        [path lineToPoint:NSMakePoint(15.0, 16.5)];
        [path moveToPoint:NSMakePoint(17.0, 16.5)];
        [path lineToPoint:NSMakePoint(19.5, 16.5)];
        [path lineToPoint:NSMakePoint(19.5, 14.0)];
        [path moveToPoint:NSMakePoint(19.5, 12.0)];
        [path lineToPoint:NSMakePoint(19.5, 9.0)];
        [path moveToPoint:NSMakePoint(19.5, 7.0)];
        [path lineToPoint:NSMakePoint(19.5, 4.5)];
        [path lineToPoint:NSMakePoint(17.0, 4.5)];
        [path moveToPoint:NSMakePoint(15.0, 4.5)];
        [path lineToPoint:NSMakePoint(12.0, 4.5)];
        [path moveToPoint:NSMakePoint(10.0, 4.5)];
        [path lineToPoint:NSMakePoint(7.5, 4.5)];
        [path lineToPoint:NSMakePoint(7.5, 7.0)];
        [path moveToPoint:NSMakePoint(7.5, 9.0)];
        [path lineToPoint:NSMakePoint(7.5, 12.0)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameToolbarPrint, YES, 27.0, 20.0, 
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(7.5, 5.5)];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(3.5, 5.5) toPoint:NSMakePoint(3.5, 14.5) radius:2.5];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(3.5, 14.5) toPoint:NSMakePoint(23.5, 14.5) radius:2.5];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(23.5, 14.5) toPoint:NSMakePoint(23.5, 5.5) radius:2.5];
        [path appendBezierPathWithArcFromPoint:NSMakePoint(23.5, 5.5) toPoint:NSMakePoint(3.5, 5.5) radius:2.5];
        [path lineToPoint:NSMakePoint(19.5, 5.5)];
        [path appendBezierPathWithRect:NSMakeRect(7.5, 2.5, 12.0, 8.0)];
        [path appendBezierPathWithRect:NSMakeRect(8.5, 14.5, 10.0, 3.0)];
        [[NSColor blackColor] set];
        [path stroke];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 10.0, 2.0, 1.0)];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.6] set];
        [path fill];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(8.0, 3.0, 11.0, 7.0)];
        [path fill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(8.0, 3.0, 4.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(13.0, 3.0, 2.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(16.0, 3.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(8.0, 5.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(12.0, 5.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(16.0, 5.0, 2.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(8.0, 7.0, 7.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(16.0, 7.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(8.0, 9.0, 8.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(16.0, 9.0, 2.0, 1.0)];
        [path fill];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(8.0, 3.0, 3.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(17.0, 3.0, 1.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(8.0, 5.0, 2.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(12.0, 5.0, 2.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(8.0, 7.0, 4.0, 1.0)];
        [path fill];
    );
    
#define MAKE_BADGED_TEMPLATE_IMAGES(name) \
    MAKE_IMAGE(SKImageNameToolbarAdd ## name ## Note, YES, 27.0, 19.0, \
        translate(3.0); \
        draw ## name ## NoteTemplate(); \
        drawAddBadgeTemplate(); \
    ); \
    MAKE_IMAGE(SKImageNameToolbar ## name ## NoteMenu, YES, 27.0, 19.0, \
        drawMenuBadgeTemplate(); \
        translate(1.0); \
        draw ## name ## NoteTemplate(); \
    ); \
    MAKE_IMAGE(SKImageNameToolbarAdd ## name ## NoteMenu, YES, 27.0, 19.0, \
        drawMenuBadgeTemplate(); \
        translate(1.0); \
        draw ## name ## NoteTemplate(); \
        drawAddBadgeTemplate(); \
    );
    
    APPLY_NOTE_TYPES(MAKE_BADGED_TEMPLATE_IMAGES);
    
}
    
+ (void)makeOtherToolbarImages {
    
    MAKE_IMAGE(SKImageNameToolbarInfo, NO, 27.0, 20.0, 
        [[NSImage imageNamed:NSImageNameInfo] drawInRect:NSMakeRect(4.0, 1.0, 19.0, 19.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    );
    
    MAKE_IMAGE(SKImageNameToolbarColors, NO, 27.0, 20.0, 
        [[NSImage imageNamed:NSImageNameColorPanel] drawInRect:NSMakeRect(4.0, 1.0, 19.0, 19.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    );
    
    MAKE_IMAGE(SKImageNameToolbarFonts, NO, 27.0, 20.0, 
        [[NSImage imageNamed:NSImageNameFontPanel] drawInRect:NSMakeRect(4.0, 1.0, 19.0, 19.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    );
    
    MAKE_IMAGE(SKImageNameToolbarLines, NO, 27.0, 20.0, 
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 14.0, 15.0, 1.0)];
        [path appendBezierPathWithRect:NSMakeRect(6.0, 10.0, 15.0, 2.0)];
        [path appendBezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0, 3.0)];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] blurRadius:1.0 yOffset:0.0];
        [[NSColor colorWithCalibratedRed:0.320 green:0.388 blue:0.484 alpha:1.0] set];
        [path fill];
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.216 green:0.280 blue:0.375 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.357 green:0.430 blue:0.530 alpha:1.0]] autorelease];
        [gradient drawInBezierPath:path angle:90.0];
    );
    
    MAKE_IMAGE(SKImageNameToolbarCustomize, NO, 27.0, 20.0, 
        NSImage *customizeImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarCustomizeIcon)];
        [customizeImage drawInRect:NSMakeRect(4.0, 1.0, 19.0, 19.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    );
    
    MAKE_IMAGE(SKImageNameGeneralPreferences, NO, 32.0, 32.0, 
        NSImage *generalImage = [NSImage imageNamed:NSImageNamePreferencesGeneral];
        [generalImage drawInRect:NSMakeRect(0.0, 0.0, 32.0, 32.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    );
    
    MAKE_IMAGE(SKImageNameDisplayPreferences, NO, 32.0, 32.0, 
        NSImage *colorImage = [NSImage imageNamed:NSImageNameColorPanel];
        NSImage *fontImage = [NSImage imageNamed:NSImageNameFontPanel];
        [colorImage drawInRect:NSMakeRect(0.0, 0.0, 32.0, 32.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
        [fontImage drawInRect:NSMakeRect(-4.0, 0.0, 32.0, 32.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.75];
    );
    
    MAKE_IMAGE(SKImageNameNotesPreferences, NO, 32.0, 32.0, 
        NSImage *clippingImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kClippingTextType)];
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:1.0 green:0.935 blue:0.422 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:1.0 green:0.975 blue:0.768 alpha:1.0]] autorelease];
        [[NSColor blackColor] setFill];
        [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, 32.0, 32.0)];
        [clippingImage drawInRect:NSMakeRect(0.0, 0.0, 32.0, 32.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        CGContextSetBlendMode([[NSGraphicsContext currentContext] graphicsPort], kCGBlendModeMultiply);
        [gradient drawInRect:NSMakeRect(0.0, 0.0, 32.0, 32.0) angle:90.0];
        [clippingImage drawInRect:NSMakeRect(0.0, 0.0, 32.0, 32.0) fromRect:NSZeroRect operation:NSCompositeDestinationAtop fraction:1.0];
    );
    
    MAKE_IMAGE(SKImageNameSyncPreferences, NO, 32.0, 32.0, 
        NSImage *genericDocImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIcon)];
        NSBitmapImageRep *refreshImageRep = [NSBitmapImageRep imageRepWithSize:NSMakeSize(10.0, 12.0) scale:bScale drawingHandler:^(NSRect r, CGFloat s){
            [[NSColor colorWithCalibratedRed:0.25 green:0.35 blue:0.6 alpha:1.0] set];
            NSRectFill(NSMakeRect(0.0, 0.0, 10.0, 12.0));
            [[NSImage imageNamed:NSImageNameRefreshTemplate] drawInRect:NSMakeRect(0.0, 0.0, 10.0, 12.0) fromRect:NSZeroRect operation:NSCompositeDestinationAtop fraction:1.0];
        }];
        [genericDocImage drawInRect:NSMakeRect(0.0, 0.0, 32.0, 32.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
        [NSShadow setShadowWithColor:[NSColor whiteColor] blurRadius:0.0 yOffset:-1.0];
        [refreshImageRep drawInRect:NSMakeRect(11.0, 10.0, 10.0, 12.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    );
    
    MAKE_IMAGE(SKImageNameNewFolder, NO, 32.0, 32.0, 
        [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)] drawInRect:NSMakeRect(0.0, 0.0, 32.0, 32.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
        drawAddBadgeAtPoint(NSMakePoint(18.0, 18.0));
    );
    
    MAKE_IMAGE(SKImageNameNewSeparator, NO, 32.0, 32.0, 
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.6 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.8 alpha:1.0]] autorelease];
        NSBezierPath *path;
        [NSGraphicsContext saveGraphicsState];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] blurRadius:2.0 yOffset:-1.0];
        [[NSColor colorWithCalibratedWhite:0.35 alpha:1.0] setFill];
        [NSBezierPath fillRect:NSMakeRect(2.0, 14.0, 28.0, 4.0)];
        [NSGraphicsContext restoreGraphicsState];
        [[NSColor colorWithCalibratedWhite:0.45 alpha:1.0] setFill];
        [NSBezierPath fillRect:NSMakeRect(3.0, 15.0, 26.0, 3.0)];
        [gradient drawInRect:NSMakeRect(3.0, 15.0, 26.0, 2.0) angle:90.0];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(3.0, 15.0)];
        [path lineToPoint:NSMakePoint(3.0, 17.0)];
        [path lineToPoint:NSMakePoint(5.0, 17.0)];
        [path closePath];
        [gradient drawInBezierPath:path angle:0.0];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(29.0, 15.0)];
        [path lineToPoint:NSMakePoint(29.0, 17.0)];
        [path lineToPoint:NSMakePoint(27.0, 17.0)];
        [path closePath];
        [gradient drawInBezierPath:path angle:180.0];
        drawAddBadgeAtPoint(NSMakePoint(18.0, 14.0));
    );
}

+ (void)makeNoteImages {
    
#define MAKE_NOTE_IMAGE(name) \
    MAKE_IMAGE(SKImageName ## name ## Note, NO, 21.0, 19.0, \
        draw ## name ## Note(); \
    );
    
    APPLY_NOTE_TYPES(MAKE_NOTE_IMAGE);
    
}

+ (void)makeNoteTemplateImages {
    
#define MAKE_NOTE_TEMPLATE_IMAGE(name) \
    MAKE_IMAGE(SKImageName ## name ## Note, YES, 21.0, 19.0, \
        draw ## name ## Note(); \
    );
    
    APPLY_NOTE_TYPES(MAKE_NOTE_TEMPLATE_IMAGE);
    
}

+ (void)makeAdornImages {
    
    MAKE_IMAGE(SKImageNameOutlineViewAdorn, YES, 25.0, 14.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(10.5, 1.5, 4.0, 4.0)];
        [path appendBezierPathWithRect:NSMakeRect(10.5, 8.5, 4.0, 4.0)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameNoteViewAdorn, YES, 25.0, 14.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithRect:NSMakeRect(7.5, 1.5, 10.0, 4.0)];
        [path appendBezierPathWithRect:NSMakeRect(7.5, 8.5, 10.0, 4.0)];
        [path stroke];
    );
    
    MAKE_IMAGE(SKImageNameFindViewAdorn, YES, 25.0, 14.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
    
    MAKE_IMAGE(SKImageNameTextAlignLeft, NO, 16.0, 11.0, 
        [[NSColor blackColor] setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        NSBezierPath *path = [NSBezierPath bezierPath];
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
    
    MAKE_IMAGE(SKImageNameResizeDiagonal45Cursor, NO, 16.0, 16.0, 
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [[NSColor blackColor] setFill];
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
        [[NSColor whiteColor] setFill];
        NSBezierPath *path = [NSBezierPath bezierPath];
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
        [[NSColor blackColor] setFill];
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
        [[NSColor whiteColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0.0, 3.0, 13.0, 13.0)];
        [path fill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(15.5, 0.5)];
        [path lineToPoint:NSMakePoint(10.0, 6.0)];
        [path setLineWidth:4.5];
        [path stroke];
        [[NSColor blackColor] setStroke];
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
        [[NSColor whiteColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0.0, 3.0, 13.0, 13.0)];
        [path fill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(15.5, 0.5)];
        [path lineToPoint:NSMakePoint(10.0, 6.0)];
        [path setLineWidth:4.5];
        [path stroke];
        [[NSColor blackColor] setStroke];
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
        NSBezierPath *path = [NSBezierPath bezierPath];
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
    
#define MAKE_NOTE_CURSOR_IMAGE(name) \
    MAKE_IMAGE(SKImageName ## name ## NoteCursor, NO, 24.0, 40.0, \
        drawArrowCursor(); \
        translate(3.0); \
        draw ## name ## NoteTemplate(); \
    );\
    
    APPLY_NOTE_TYPES(MAKE_NOTE_CURSOR_IMAGE);
    
}

+ (void)makeRemoteStateImages {
    
    MAKE_IMAGE(SKImageNameRemoteStateResize, NO, 60.0, 60.0, 
        NSPoint center = NSMakePoint(30.0, 30.0);
        
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:10.0 yRadius:10.0] fill];
        
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 20.0, 20.0) xRadius:3.0 yRadius:3.0];
        [path appendBezierPath:[NSBezierPath bezierPathWithRect:NSInsetRect(rect, 24.0, 24.0)]];
        
        NSBezierPath *arrow = [NSBezierPath bezierPath];
        [arrow moveToPoint:NSMakePoint(NSMinX(rect) + 10.0, NSMinY(rect) + 10.0)];
        [arrow relativeLineToPoint:NSMakePoint(6.0, 0.0)];
        [arrow relativeLineToPoint:NSMakePoint(-2.0, 2.0)];
        [arrow relativeLineToPoint:NSMakePoint(2.0, 2.0)];
        [arrow relativeLineToPoint:NSMakePoint(2.0, -2.0)];
        [arrow relativeLineToPoint:NSMakePoint(0.0, 6.0)];
        [arrow relativeLineToPoint:NSMakePoint(-6.0, 0.0)];
        [arrow relativeLineToPoint:NSMakePoint(2.0, -2.0)];
        [arrow relativeLineToPoint:NSMakePoint(-2.0, -2.0)];
        [arrow relativeLineToPoint:NSMakePoint(-2.0, 2.0)];
        [arrow closePath];
        
        NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
        [transform translateXBy:center.x yBy:center.y];
        [transform rotateByDegrees:90.0];
        [transform translateXBy:-center.x yBy:-center.y];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        
        arrow = [NSBezierPath bezierPath];
        [arrow moveToPoint:NSMakePoint(NSMinX(rect) + 5.0, NSMidY(rect))];
        [arrow relativeLineToPoint:NSMakePoint(10.0, 5.0)];
        [arrow relativeLineToPoint:NSMakePoint(0.0, -10.0)];
        [arrow closePath];
        [path appendBezierPath:arrow];
        [transform translateXBy:center.x yBy:center.y];
        [transform rotateByDegrees:90.0];
        [transform translateXBy:-center.x yBy:-center.y];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        
        [path setWindingRule:NSEvenOddWindingRule];
        
        [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
        [path fill];
    );
    
    MAKE_IMAGE(SKImageNameRemoteStateScroll, NO, 60.0, 60.0, 
        NSPoint center = NSMakePoint(30.0, 30.0);
        
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:10.0 yRadius:10.0] fill];
        
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 8.0, 8.0)];
        [path appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 9.0, 9.0)]];
        [path appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 25.0, 25.0)]];
        
        NSBezierPath *arrow = [NSBezierPath bezierPath];
        [arrow moveToPoint:NSMakePoint(NSMidX(rect), NSMinY(rect) + 12.0)];
        [arrow relativeLineToPoint:NSMakePoint(7.0, 7.0)];
        [arrow relativeLineToPoint:NSMakePoint(-14.0, 0.0)];
        [arrow closePath];
        
        NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
        [transform translateXBy:center.x yBy:center.y];
        [transform rotateByDegrees:90.0];
        [transform translateXBy:-center.x yBy:-center.y];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        
        [path setWindingRule:NSEvenOddWindingRule];
        
        [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
        [path fill];
    );
    
}

+ (void)makeImages {
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
        [self makeNoteTemplateImages];
        [self makeToolbarTemplateImages];
    } else {
        [self makeNoteImages];
        [self makeToolbarImages];
    }
    [self makeOtherToolbarImages];
    [self makeAdornImages];
    [self makeTextAlignImages];
    [self makeCursorImages];
    [self makeRemoteStateImages];
}

@end


static void drawTextNote() {
    [NSGraphicsContext saveGraphicsState];
    [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] blurRadius:2.0 yOffset:0.0];
    [[NSColor whiteColor] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
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
}

static void drawAnchoredNote() {
    [NSGraphicsContext saveGraphicsState];
    [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
    [[NSColor whiteColor] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
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
    NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.988 green:0.988 blue:0.988 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.762 green:0.762 blue:0.762 alpha:1.0]] autorelease];
    [gradient drawInBezierPath:path angle:90.0];
}

static void drawCircleNote() {
    [NSGraphicsContext saveGraphicsState];
    [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] blurRadius:2.0 yOffset:-1.0];
    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(4.0, 5.0, 13.0, 10.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
}

static void drawSquareNote() {
    [NSGraphicsContext saveGraphicsState];
    [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] blurRadius:2.0 yOffset:-1.0];
    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.0, 5.0, 13.0, 10.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
}

static void drawHighlightNote() {
    NSFont *font = [NSFont fontWithName:@"Helvetica-Bold" size:14.0];
    NSGlyph glyph = [font glyphWithName:@"H"];
    NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:1.0 green:0.925 blue:0.0 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:1.0 green:0.745 blue:0.0 alpha:1.0]] autorelease];
    [gradient drawInRect:NSMakeRect(3.0, 2.0, 15.0, 16.0) angle:90.0];
    [NSGraphicsContext saveGraphicsState];
    [NSShadow setShadowWithColor:[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
    [[NSColor whiteColor] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(10.5 - NSMidX([font boundingRectForGlyph:glyph]), 5.0)];
    [path appendBezierPathWithGlyph:glyph inFont:font];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
}

static void drawUnderlineNote() {
    NSFont *font = [NSFont fontWithName:@"Helvetica-Bold" size:14.0];
    NSGlyph glyph = [font glyphWithName:@"U"];
    [NSGraphicsContext saveGraphicsState];
    [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
    [[NSColor whiteColor] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(10.5 - NSMidX([font boundingRectForGlyph:glyph]), 6.0)];
    [path appendBezierPathWithGlyph:glyph inFont:font];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(2.0, 3.0, 17.0, 2.0)];
    [path fill];
}

static void drawStrikeOutNote() {
    NSFont *font = [NSFont fontWithName:@"Helvetica-Bold" size:14.0];
    NSGlyph glyph = [font glyphWithName:@"S"];
    [NSGraphicsContext saveGraphicsState];
    [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] blurRadius:2.0 yOffset:0.0];
    [[NSColor whiteColor] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(10.5 - NSMidX([font boundingRectForGlyph:glyph]), 5.0)];
    [path appendBezierPathWithGlyph:glyph inFont:font];
    [path fill];
    [NSGraphicsContext restoreGraphicsState];
    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(2.0, 9.0, 17.0, 2.0)];
    [path fill];
}

static void drawLineNote() {
    [NSGraphicsContext saveGraphicsState];
    [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] blurRadius:2.0 yOffset:-1.0];
    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
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
}

static void drawInkNote() {
    [NSGraphicsContext saveGraphicsState];
    [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] blurRadius:2.0 yOffset:-1.0];
    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.0, 9.0)];
    [path curveToPoint:NSMakePoint(10.5, 10.0) controlPoint1:NSMakePoint(10.0, 5.0) controlPoint2:NSMakePoint(13.0, 5.0)];
    [path curveToPoint:NSMakePoint(17.0, 11.0) controlPoint1:NSMakePoint(8.0, 15.0) controlPoint2:NSMakePoint(11.0, 15.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
}

static void drawTextNoteTemplate() {
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.75] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(5.0, 5.0)];
    [path lineToPoint:NSMakePoint(9.0, 6.5)];
    [path lineToPoint:NSMakePoint(9.0, 7.5)];
    [path lineToPoint:NSMakePoint(7.5, 9.0)];
    [path lineToPoint:NSMakePoint(6.5, 9.0)];
    [path closePath];
    [path moveToPoint:NSMakePoint(10.0, 7.0)];
    [path lineToPoint:NSMakePoint(16.0, 13.0)];
    [path lineToPoint:NSMakePoint(16.0, 14.0)];
    [path lineToPoint:NSMakePoint(14.0, 16.0)];
    [path lineToPoint:NSMakePoint(13.0, 16.0)];
    [path lineToPoint:NSMakePoint(7.0, 10.0)];
    [path lineToPoint:NSMakePoint(8.0, 10.0)];
    [path lineToPoint:NSMakePoint(10.0, 8.0)];
    [path closePath];
    [path fill];
}

static void drawAnchoredNoteTemplate() {
    [[NSColor blackColor] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(12.0, 6.5)];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(16.5, 6.5) toPoint:NSMakePoint(16.5, 15.5) radius:4.5];
    [path curveToPoint:NSMakePoint(10.0, 15.5) controlPoint1:NSMakePoint(16.5, 13.5) controlPoint2:NSMakePoint(13.5, 15.5)];
    [path curveToPoint:NSMakePoint(3.5, 11.0) controlPoint1:NSMakePoint(6.5, 15.5) controlPoint2:NSMakePoint(3.5, 13.5)];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(3.5, 6.5) toPoint:NSMakePoint(16.5, 6.5) radius:4.5];
    [path lineToPoint:NSMakePoint(8.5, 4.5)];
    [path closePath];
    [path stroke];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.333] setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(8.0, 11.5)];
    [path lineToPoint:NSMakePoint(12.0, 11.5)];
    [path moveToPoint:NSMakePoint(8.0, 10.5)];
    [path lineToPoint:NSMakePoint(11.0, 10.5)];
    [path stroke];
}

static void drawCircleNoteTemplate() {
    [[NSColor blackColor] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(4.5, 4.5, 12.0, 11.0)];
    [path stroke];
}

static void drawSquareNoteTemplate() {
    [[NSColor blackColor] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(4.5, 4.5, 12.0, 11.0)];
    [path stroke];
}

static void drawHighlightNoteTemplate() {
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:14.0];
    NSGlyph glyph = [font glyphWithName:@"H"];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.25] setFill];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 2.0, 15.0, 16.0)];
    [path fill];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.75] setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(10.5 - NSMidX([font boundingRectForGlyph:glyph]), 5.0)];
    [path appendBezierPathWithGlyph:glyph inFont:font];
    [path fill];
}

static void drawUnderlineNoteTemplate() {
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:14.0];
    NSGlyph glyph = [font glyphWithName:@"U"];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.75] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(10.5 - NSMidX([font boundingRectForGlyph:glyph]), 6.0)];
    [path appendBezierPathWithGlyph:glyph inFont:font];
    [path fill];
    [[NSColor blackColor] setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(2.0, 4.5)];
    [path lineToPoint:NSMakePoint(19.0, 4.5)];
    [path stroke];
}

static void drawStrikeOutNoteTemplate() {
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:14.0];
    NSGlyph glyph = [font glyphWithName:@"S"];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.75] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(10.5 - NSMidX([font boundingRectForGlyph:glyph]), 5.0)];
    [path appendBezierPathWithGlyph:glyph inFont:font];
    [path fill];
    [[NSColor blackColor] setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(2.0, 9.5)];
    [path lineToPoint:NSMakePoint(19.0, 9.5)];
    [path stroke];
}

static void drawLineNoteTemplate() {
    [[NSColor blackColor] setFill];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(3.0, 10.0)];
    [path lineToPoint:NSMakePoint(15.0, 10.0)];
    [path lineToPoint:NSMakePoint(15.0, 7.5)];
    [path lineToPoint:NSMakePoint(18.5, 10.5)];
    [path lineToPoint:NSMakePoint(15.0, 13.5)];
    [path lineToPoint:NSMakePoint(15.0, 11.0)];
    [path lineToPoint:NSMakePoint(3.0, 11.0)];
    [path closePath];
    [path fill];
}

static void drawInkNoteTemplate() {
    [[NSColor blackColor] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.0, 9.0)];
    [path curveToPoint:NSMakePoint(10.5, 10.0) controlPoint1:NSMakePoint(10.0, 5.0) controlPoint2:NSMakePoint(13.0, 5.0)];
    [path curveToPoint:NSMakePoint(17.0, 11.0) controlPoint1:NSMakePoint(8.0, 15.0) controlPoint2:NSMakePoint(11.0, 15.0)];
    [path stroke];
}

static void drawMenuBadge() {
    NSBezierPath *arrowPath = [NSBezierPath bezierPath];
    [arrowPath moveToPoint:NSMakePoint(27.0, 10.0)];
    [arrowPath relativeLineToPoint:NSMakePoint(-5.0, 0.0)];
    [arrowPath relativeLineToPoint:NSMakePoint(2.5, -3.0)];
    [arrowPath closePath];
    [[NSColor blackColor] setFill];
    [arrowPath fill];
}

static void drawMenuBadgeTemplate() {
    NSBezierPath *arrowPath = [NSBezierPath bezierPath];
    [arrowPath moveToPoint:NSMakePoint(26.5, 10.5)];
    [arrowPath relativeLineToPoint:NSMakePoint(-2.0, -2.0)];
    [arrowPath relativeLineToPoint:NSMakePoint(-2.0, 2.0)];
    [[NSColor blackColor] setStroke];
    [arrowPath stroke];
}

static void drawAddBadge() {
    NSBezierPath *addPath = [NSBezierPath bezierPath];
    [addPath appendBezierPathWithRect:NSMakeRect(14.0, 4.0, 6.0, 2.0)];
    [addPath appendBezierPathWithRect:NSMakeRect(16.0, 2.0, 2.0, 6.0)];
    [NSGraphicsContext saveGraphicsState];
    [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] blurRadius:2.0 yOffset:0.0];
    [[NSColor whiteColor] setFill];
    [addPath fill];
    [NSGraphicsContext restoreGraphicsState];
}

static void drawAddBadgeTemplate() {
    NSBezierPath *addPath = [NSBezierPath bezierPath];
    [addPath appendBezierPathWithRect:NSMakeRect(16.0, 4.0, 5.0, 1.0)];
    [addPath appendBezierPathWithRect:NSMakeRect(18.0, 2.0, 1.0, 5.0)];
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeCopy];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.6] setFill];
    [addPath fill];
    [NSGraphicsContext restoreGraphicsState];
}

static inline void translate(CGFloat delta) {
    NSAffineTransform *t = [NSAffineTransform transform];
    [t translateXBy:delta yBy:0.0];
    [t concat];
}

static inline void drawPageBackgroundInRect(NSRect rect) {
    NSGradient *gradient1 = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.337 blue:0.814 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.584 blue:0.872 alpha:1.0]];
    NSGradient *gradient2 = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.431 blue:0.891 alpha:1.0] endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.636 blue:0.944 alpha:1.0]];
    
    [gradient1 drawInRect:rect angle:90.0];
    [gradient2 drawInRect:NSInsetRect(rect, 1.0, 1.0) angle:90.0];
    
    [gradient1 release];
    [gradient2 release];
}

static inline void drawPageBackgroundTemplateInRect(NSRect rect) {
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeCopy];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.25] setFill];
    [NSBezierPath fillRect:rect];
    [NSGraphicsContext restoreGraphicsState];
}

static inline void drawArrowCursor() {
    NSImage *arrowCursor = [[NSCursor arrowCursor] image];
    [arrowCursor drawAtPoint:NSMakePoint(0.0, 40.0 - [arrowCursor size].height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

static void drawAddBadgeAtPoint(NSPoint point) {
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
    
    [NSGraphicsContext saveGraphicsState];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
    [path fill];
    [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] blurRadius:1.0 yOffset:0.0];
    [[NSColor colorWithCalibratedRed:0.257 green:0.351 blue:0.553 alpha:1.0] setStroke];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
}
