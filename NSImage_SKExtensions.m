//
//  NSImage_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 7/27/07.
/*
 This software is Copyright (c) 2007-2008
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
#import "NSBezierPath_BDSKExtensions.h"
#import "NSBezierPath_CoreImageExtensions.h"

@implementation NSImage (SKExtensions)

- (NSImage *)createMenuImage {
    NSBezierPath *arrowPath = [NSBezierPath bezierPath];
    [arrowPath moveToPoint:NSMakePoint(23.5, 7.0)];
    [arrowPath lineToPoint:NSMakePoint(21.0, 10.0)];
    [arrowPath lineToPoint:NSMakePoint(26.0, 10.0)];
    [arrowPath closePath];
    
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [image lockFocus];
    [self compositeToPoint:NSMakePoint(-2.0, 0.0) operation:NSCompositeCopy];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.85] setFill];
    [arrowPath fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [image unlockFocus];
    
    return image;
}

- (NSImage *)createAddImage {
    NSBezierPath *addPath = [NSBezierPath bezierPath];
    addPath = [NSBezierPath bezierPath];
    [addPath appendBezierPathWithRect:NSMakeRect(17.0, 4.0, 6.0, 2.0)];
    [addPath appendBezierPathWithRect:NSMakeRect(19.0, 2.0, 2.0, 6.0)];
    
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:2.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8]];
    
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [image lockFocus];
    [self compositeToPoint:NSMakePoint(0.0, 0.0) operation:NSCompositeCopy];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
    [addPath fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [image unlockFocus];
    
    return image;
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
    static NSImage *toolbarMediaBoxImage = nil;
    static NSImage *toolbarCropBoxImage = nil;
    static NSImage *toolbarLeftPaneImage = nil;
    static NSImage *toolbarRightPaneImage = nil;
    static NSImage *toolbarTextNoteImage = nil;
    static NSImage *toolbarAnchoredNoteImage = nil;
    static NSImage *toolbarCircleNoteImage = nil;
    static NSImage *toolbarSquareNoteImage = nil;
    static NSImage *toolbarHighlightNoteImage = nil;
    static NSImage *toolbarUnderlineNoteImage = nil;
    static NSImage *toolbarStrikeOutNoteImage = nil;
    static NSImage *toolbarLineNoteImage = nil;
    static NSImage *toolbarTextNoteMenuImage = nil;
    static NSImage *toolbarAnchoredNoteMenuImage = nil;
    static NSImage *toolbarCircleNoteMenuImage = nil;
    static NSImage *toolbarSquareNoteMenuImage = nil;
    static NSImage *toolbarHighlightNoteMenuImage = nil;
    static NSImage *toolbarUnderlineNoteMenuImage = nil;
    static NSImage *toolbarStrikeOutNoteMenuImage = nil;
    static NSImage *toolbarLineNoteMenuImage = nil;
    static NSImage *toolbarAddTextNoteImage = nil;
    static NSImage *toolbarAddAnchoredNoteImage = nil;
    static NSImage *toolbarAddCircleNoteImage = nil;
    static NSImage *toolbarAddSquareNoteImage = nil;
    static NSImage *toolbarAddHighlightNoteImage = nil;
    static NSImage *toolbarAddUnderlineNoteImage = nil;
    static NSImage *toolbarAddStrikeOutNoteImage = nil;
    static NSImage *toolbarAddLineNoteImage = nil;
    static NSImage *toolbarAddTextNoteMenuImage = nil;
    static NSImage *toolbarAddAnchoredNoteMenuImage = nil;
    static NSImage *toolbarAddCircleNoteMenuImage = nil;
    static NSImage *toolbarAddSquareNoteMenuImage = nil;
    static NSImage *toolbarAddHighlightNoteMenuImage = nil;
    static NSImage *toolbarAddUnderlineNoteMenuImage = nil;
    static NSImage *toolbarAddStrikeOutNoteMenuImage = nil;
    static NSImage *toolbarAddLineNoteMenuImage = nil;
    static NSImage *toolbarTextToolImage = nil;
    static NSImage *toolbarMoveToolImage = nil;
    static NSImage *toolbarMagnifyToolImage = nil;
    static NSImage *toolbarSelectToolImage = nil;
    static NSImage *toolbarNewFolderImage = nil;
    static NSImage *smallFolderImage = nil;
    
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:2.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, 0.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.8]];
    
    NSShadow *shadow2 = [[NSShadow alloc] init];
    [shadow2 setShadowBlurRadius:2.0];
    [shadow2 setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow2 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
    
    NSColor *fgColor = [NSColor whiteColor];
    
    BOOL isTiger = floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4;
    
    if (isTiger) {
        [shadow1 setShadowBlurRadius:1.0];
        [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
        fgColor = [NSColor blackColor];
    }
    
    NSBezierPath *path;
    
    [NSBezierPath setDefaultLineWidth:1.0];
    
    toolbarPageUpImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarPageUpImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
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
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarPageUpImage unlockFocus];
    [toolbarPageUpImage setName:@"ToolbarPageUp"];
    
    toolbarPageDownImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarPageDownImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
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
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarPageUpImage unlockFocus];
    [toolbarPageDownImage setName:@"ToolbarPageDown"];
    
    toolbarFirstPageImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarFirstPageImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
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
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarFirstPageImage unlockFocus];
    [toolbarFirstPageImage setName:@"ToolbarFirstPage"];
    
    toolbarLastPageImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarLastPageImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
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
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarLastPageImage unlockFocus];
    [toolbarLastPageImage setName:@"ToolbarLastPage"];
    
    toolbarBackImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 13.0)];
    [toolbarBackImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(17.0, 2.5)];
    [path lineToPoint:NSMakePoint(8.5, 7.0)];
    [path lineToPoint:NSMakePoint(17.0, 11.5)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarBackImage unlockFocus];
    [toolbarBackImage setName:@"ToolbarBack"];
    
    toolbarForwardImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 13.0)];
    [toolbarForwardImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(10.0, 2.5)];
    [path lineToPoint:NSMakePoint(18.5, 7.0)];
    [path lineToPoint:NSMakePoint(10.0, 11.5)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarForwardImage unlockFocus];
    [toolbarForwardImage setName:@"ToolbarForward"];
    
    toolbarZoomInImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarZoomInImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(7.0, 9.0, 13.0, 3.0)];
    [path appendBezierPathWithRect:NSMakeRect(12.0, 4.0, 3.0, 13.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarZoomInImage unlockFocus];
    [toolbarZoomInImage setName:@"ToolbarZoomIn"];
    
    toolbarZoomOutImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 9.0)];
    [toolbarZoomOutImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(7.0, 4.0, 13.0, 3.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarZoomOutImage unlockFocus];
    [toolbarZoomOutImage setName:@"ToolbarZoomOut"];
    
    toolbarZoomActualImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 14.0)];
    [toolbarZoomActualImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(7.0, 4.0, 13.0, 3.0)];
    [path appendBezierPathWithRect:NSMakeRect(7.0, 9.0, 13.0, 3.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarZoomActualImage unlockFocus];
    [toolbarZoomActualImage setName:@"ToolbarZoomActual"];
    
    toolbarZoomToFitImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarZoomToFitImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(7.0, 6.0, 13.0, 9.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.0 green:0.337 blue:0.814 alpha:1.0] endColor:[CIColor colorWithRed:0.0 green:0.584 blue:0.872 alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(8.0, 7.0, 11.0, 7.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.0 green:0.431 blue:0.891 alpha:1.0] endColor:[CIColor colorWithRed:0.0 green:0.636 blue:0.944 alpha:1.0]];
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
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarZoomToFitImage unlockFocus];
    [toolbarZoomToFitImage setName:@"ToolbarZoomToFit"];
    
    toolbarZoomToSelectionImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarZoomToSelectionImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(6.0, 14.0)];
    [path lineToPoint:NSMakePoint(6.0, 16.0)];
    [path lineToPoint:NSMakePoint(9.0, 16.0)];
    [path moveToPoint:NSMakePoint(11.0, 16.0)];
    [path lineToPoint:NSMakePoint(15.0, 16.0)];
    [path moveToPoint:NSMakePoint(17.0, 16.0)];
    [path lineToPoint:NSMakePoint(21.0, 16.0)];
    [path lineToPoint:NSMakePoint(21.0, 14.0)];
    [path moveToPoint:NSMakePoint(21.0, 12.0)];
    [path lineToPoint:NSMakePoint(21.0, 9.0)];
    [path moveToPoint:NSMakePoint(21.0, 7.0)];
    [path lineToPoint:NSMakePoint(21.0, 5.0)];
    [path lineToPoint:NSMakePoint(17.0, 5.0)];
    [path moveToPoint:NSMakePoint(15.0, 5.0)];
    [path lineToPoint:NSMakePoint(11.0, 5.0)];
    [path moveToPoint:NSMakePoint(9.0, 5.0)];
    [path lineToPoint:NSMakePoint(6.0, 5.0)];
    [path lineToPoint:NSMakePoint(6.0, 7.0)];
    [path moveToPoint:NSMakePoint(6.0, 9.0)];
    [path lineToPoint:NSMakePoint(6.0, 12.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(7.0, 6.0, 13.0, 9.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.0 green:0.337 blue:0.814 alpha:1.0] endColor:[CIColor colorWithRed:0.0 green:0.584 blue:0.872 alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(8.0, 7.0, 11.0, 7.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.0 green:0.431 blue:0.891 alpha:1.0] endColor:[CIColor colorWithRed:0.0 green:0.636 blue:0.944 alpha:1.0]];
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
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarZoomToSelectionImage unlockFocus];
    [toolbarZoomToSelectionImage setName:@"ToolbarZoomToSelection"];
    
    toolbarRotateLeftImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarRotateLeftImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
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
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarRotateLeftImage unlockFocus];
    [toolbarRotateLeftImage setName:@"ToolbarRotateLeft"];
    
    toolbarRotateRightImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarRotateRightImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
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
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarRotateRightImage unlockFocus];
    [toolbarRotateRightImage setName:@"ToolbarRotateRight"];
    
    toolbarCropImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarCropImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 5.0, 15.0 , 11.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 6.0, 13.0, 9.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.0 green:0.337 blue:0.814 alpha:1.0] endColor:[CIColor colorWithRed:0.0 green:0.584 blue:0.872 alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(7.0, 7.0, 11.0, 7.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.0 green:0.431 blue:0.891 alpha:1.0] endColor:[CIColor colorWithRed:0.0 green:0.636 blue:0.944 alpha:1.0]];
    [shadow1 set];
    [[NSColor colorWithCalibratedRed:1.0 green:0.865 blue:0.296 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 7.0, 21.0, 2.0)];
    [path fill];
    [[NSColor colorWithCalibratedRed:1.0 green:0.906 blue:0.496 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(17.0, 2.0, 2.0, 17.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarCropImage unlockFocus];
    [toolbarCropImage setName:@"ToolbarCrop"];
    
    toolbarFullScreenImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarFullScreenImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor set];
    path = [NSBezierPath bezierPathWithRoundRectInRect:NSMakeRect(5.0, 4.0, 17.0, 14.0) radius:2.0];
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
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarFullScreenImage unlockFocus];
    [toolbarFullScreenImage setName:@"ToolbarFullScreen"];
    
    toolbarPresentationImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarPresentationImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor set];
    path = [NSBezierPath bezierPathWithRoundRectInRect:NSMakeRect(5.0, 4.0, 17.0, 14.0) radius:2.0];
    [path appendBezierPathWithRect:NSMakeRect(7.0, 6.0, 13.0, 10.0)];
    [path moveToPoint:NSMakePoint(11.0, 7.0)];
    [path lineToPoint:NSMakePoint(18.5, 11.0)];
    [path lineToPoint:NSMakePoint(11.0, 15.0)];
    [path setWindingRule:NSEvenOddWindingRule];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarPresentationImage unlockFocus];
    [toolbarPresentationImage setName:@"ToolbarPresentation"];
    
    toolbarMediaBoxImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarMediaBoxImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(7.0, 6.0, 13.0, 9.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.0 green:0.337 blue:0.814 alpha:1.0] endColor:[CIColor colorWithRed:0.0 green:0.584 blue:0.872 alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(8.0, 7.0, 11.0, 7.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.0 green:0.431 blue:0.891 alpha:1.0] endColor:[CIColor colorWithRed:0.0 green:0.636 blue:0.944 alpha:1.0]];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarMediaBoxImage unlockFocus];
    [toolbarMediaBoxImage setName:@"ToolbarMediaBox"];
    
    toolbarCropBoxImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 21.0)];
    [toolbarCropBoxImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 15.0 , 11.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(7.0, 6.0, 13.0, 9.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.0 green:0.337 blue:0.814 alpha:1.0] endColor:[CIColor colorWithRed:0.0 green:0.584 blue:0.872 alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(8.0, 7.0, 11.0, 7.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.0 green:0.431 blue:0.891 alpha:1.0] endColor:[CIColor colorWithRed:0.0 green:0.636 blue:0.944 alpha:1.0]];
    [shadow1 set];
    [[NSColor colorWithCalibratedRed:1.0 green:0.865 blue:0.296 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(3.0, 7.0, 21.0, 2.0)];
    [path fill];
    [[NSColor colorWithCalibratedRed:1.0 green:0.906 blue:0.496 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(17.0, 2.0, 2.0, 17.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarCropBoxImage unlockFocus];
    [toolbarCropBoxImage setName:@"ToolbarCropBox"];
    
    float outStartGray = 0.925, outEndGray = 1.0, inStartGray = 0.868, inEndGray = 1.0;
    if (isTiger) {
        outStartGray = 0.0;
        outEndGray = 0.1;
        inStartGray = 0.15;
        inEndGray = 0.3;
    }
    
    toolbarLeftPaneImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 17.0)];
    [toolbarLeftPaneImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:outStartGray green:outStartGray blue:outStartGray alpha:1.0] endColor:[CIColor colorWithRed:outEndGray green:outEndGray blue:outEndGray alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(12.0, 5.0, 9.0, 9.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:inStartGray green:inStartGray blue:inStartGray alpha:1.0] endColor:[CIColor colorWithRed:inEndGray green:inEndGray blue:inEndGray alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(10.0, 4.0, 1.0, 11.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.431 green:0.478 blue:0.589 alpha:1.0] endColor:[CIColor colorWithRed:0.714 green:0.744 blue:0.867 alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 5.0, 11.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.502 green:0.537 blue:0.640 alpha:1.0] endColor:[CIColor colorWithRed:0.761 green:0.784 blue:0.900 alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 3.0, 9.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.382 green:0.435 blue:0.547 alpha:1.0] endColor:[CIColor colorWithRed:0.696 green:0.722 blue:0.843 alpha:1.0]];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(6.0, 5.0, 3.0, 1.0)];
    [path appendBezierPathWithRect:NSMakeRect(6.0, 7.0, 3.0, 1.0)];
    [path appendBezierPathWithRect:NSMakeRect(6.0, 9.0, 3.0, 1.0)];
    [path appendBezierPathWithRect:NSMakeRect(6.0, 11.0, 3.0, 1.0)];
    [path appendBezierPathWithRect:NSMakeRect(6.0, 13.0, 3.0, 1.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarLeftPaneImage unlockFocus];
    [toolbarLeftPaneImage setName:@"ToolbarLeftPane"];
    
    toolbarRightPaneImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 17.0)];
    [toolbarRightPaneImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 4.0, 17.0 , 11.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:outStartGray green:outStartGray blue:outStartGray alpha:1.0] endColor:[CIColor colorWithRed:outEndGray green:outEndGray blue:outEndGray alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 5.0, 9.0, 9.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:inStartGray green:inStartGray blue:inStartGray alpha:1.0] endColor:[CIColor colorWithRed:inEndGray green:inEndGray blue:inEndGray alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(16.0, 4.0, 1.0, 11.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.431 green:0.478 blue:0.589 alpha:1.0] endColor:[CIColor colorWithRed:0.714 green:0.744 blue:0.867 alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(17.0, 4.0, 5.0, 11.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.502 green:0.537 blue:0.640 alpha:1.0] endColor:[CIColor colorWithRed:0.761 green:0.784 blue:0.900 alpha:1.0]];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(18.0, 5.0, 3.0, 9.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.382 green:0.435 blue:0.547 alpha:1.0] endColor:[CIColor colorWithRed:0.696 green:0.722 blue:0.843 alpha:1.0]];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(18.0, 5.0, 3.0, 1.0)];
    [path appendBezierPathWithRect:NSMakeRect(18.0, 7.0, 3.0, 1.0)];
    [path appendBezierPathWithRect:NSMakeRect(18.0, 9.0, 3.0, 1.0)];
    [path appendBezierPathWithRect:NSMakeRect(18.0, 11.0, 3.0, 1.0)];
    [path appendBezierPathWithRect:NSMakeRect(18.0, 13.0, 3.0, 1.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarRightPaneImage unlockFocus];
    [toolbarRightPaneImage setName:@"ToolbarRightPane"];
    
    toolbarTextNoteImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarTextNoteImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(8.0, 5.0)];
    [path lineToPoint:NSMakePoint(12.0, 6.0)];
    [path lineToPoint:NSMakePoint(19.0, 13.0)];
    [path lineToPoint:NSMakePoint(19.0, 14.0)];
    [path lineToPoint:NSMakePoint(17.0, 16.0)];
    [path lineToPoint:NSMakePoint(16.0, 16.0)];
    [path lineToPoint:NSMakePoint(9.0, 9.0)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(12.0, 7.0)];
    [path lineToPoint:NSMakePoint(19.0, 14.0)];
    [path lineToPoint:NSMakePoint(17.0, 16.0)];
    [path lineToPoint:NSMakePoint(10.0, 9.0)];
    [path closePath];
    [[NSColor colorWithCalibratedRed:1.0 green:0.835 blue:0.0 alpha:1.0] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(12.0, 6.0)];
    [path lineToPoint:NSMakePoint(19.0, 13.0)];
    [path lineToPoint:NSMakePoint(19.0, 14.0)];
    [path lineToPoint:NSMakePoint(12.0, 7.0)];
    [path closePath];
    [[NSColor colorWithCalibratedRed:1.0 green:0.745 blue:0.0 alpha:1.0] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(10.0, 9.0)];
    [path lineToPoint:NSMakePoint(17.0, 16.0)];
    [path lineToPoint:NSMakePoint(16.0, 16.0)];
    [path lineToPoint:NSMakePoint(9.0, 9.0)];
    [path closePath];
    [[NSColor colorWithCalibratedRed:1.0 green:0.925 blue:0.0 alpha:1.0] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(9.0, 6.5)];
    [path lineToPoint:NSMakePoint(10.0, 9.0)];
    [path lineToPoint:NSMakePoint(9.0, 9.0)];
    [path lineToPoint:NSMakePoint(8.5, 7.0)];
    [path closePath];
    [[NSColor colorWithCalibratedRed:1.0 green:0.98 blue:0.9 alpha:1.0] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(9.5, 6.0)];
    [path lineToPoint:NSMakePoint(12.0, 7.0)];
    [path lineToPoint:NSMakePoint(10.0, 9.0)];
    [path lineToPoint:NSMakePoint(9.0, 6.5)];
    [path closePath];
    [[NSColor colorWithCalibratedRed:1.0 green:0.95 blue:0.8 alpha:1.0] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(10.0, 5.5)];
    [path lineToPoint:NSMakePoint(12.0, 6.0)];
    [path lineToPoint:NSMakePoint(12.0, 7.0)];
    [path lineToPoint:NSMakePoint(9.5, 6.0)];
    [path closePath];
    [[NSColor colorWithCalibratedRed:0.85 green:0.75 blue:0.6 alpha:1.0] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(8.0, 5.0)];
    [path lineToPoint:NSMakePoint(10.0, 5.5)];
    [path lineToPoint:NSMakePoint(8.5, 7.0)];
    [path closePath];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] set];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarTextNoteImage unlockFocus];
    [toolbarTextNoteImage setName:@"ToolbarTextNote"];
    
    toolbarTextNoteMenuImage = [toolbarTextNoteImage createMenuImage];
    [toolbarTextNoteMenuImage setName:@"ToolbarTextNoteMenu"];
    
    toolbarAddTextNoteImage = [toolbarTextNoteImage createAddImage];
    [toolbarAddTextNoteImage setName:@"ToolbarAddTextNote"];
    
    toolbarAddTextNoteMenuImage = [toolbarAddTextNoteImage createMenuImage];
    [toolbarAddTextNoteMenuImage setName:@"ToolbarAddTextNoteMenu"];
    
    toolbarAnchoredNoteImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarAnchoredNoteImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(15.0, 6.0)];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(20.0, 6.0) toPoint:NSMakePoint(20.0, 16.0) radius:3.0];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(20.0, 16.0) toPoint:NSMakePoint(6.0, 16.0) radius:3.0];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(6.0, 16.0) toPoint:NSMakePoint(6.0, 6.0) radius:3.0];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(6.0, 6.0) toPoint:NSMakePoint(20.0, 6.0) radius:3.0];
    [path lineToPoint:NSMakePoint(12.0, 6.0)];
    [path lineToPoint:NSMakePoint(11.0, 3.0)];
    [path closePath];
    [path appendBezierPathWithRect:NSMakeRect(12.0, 7.0, 2.0, 2.0)];
    [path appendBezierPathWithRect:NSMakeRect(12.0, 10.0, 2.0, 4.0)];
    [path setWindingRule:NSEvenOddWindingRule];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(6.0, 10.0)];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(6.0, 6.0) toPoint:NSMakePoint(20.0, 6.0) radius:3.0];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(20.0, 6.0) toPoint:NSMakePoint(20.0, 10.0) radius:3.0];
    [path lineToPoint:NSMakePoint(20.0, 10.0)];
    [path closePath];
    [path appendBezierPathWithRect:NSMakeRect(12.0, 7.0, 2.0, 2.0)];
    [path setWindingRule:NSEvenOddWindingRule];
    if (isTiger == NO)
        [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.988 green:0.988 blue:0.988 alpha:1.0] endColor:[CIColor colorWithRed:0.762 green:0.762 blue:0.762 alpha:1.0]];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarAnchoredNoteImage unlockFocus];
    [toolbarAnchoredNoteImage setName:@"ToolbarAnchoredNote"];
    
    toolbarAnchoredNoteMenuImage = [toolbarAnchoredNoteImage createMenuImage];
    [toolbarAnchoredNoteMenuImage setName:@"ToolbarAnchoredNoteMenu"];
    
    toolbarAddAnchoredNoteImage = [toolbarAnchoredNoteImage createAddImage];
    [toolbarAddAnchoredNoteImage setName:@"ToolbarAddAnchoredNote"];
    
    toolbarAddAnchoredNoteMenuImage = [toolbarAddAnchoredNoteImage createMenuImage];
    [toolbarAddAnchoredNoteMenuImage setName:@"ToolbarAddAnchoredNoteMenu"];

    toolbarCircleNoteImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarCircleNoteImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow2 set];
    [[NSColor colorWithCalibratedRed:0.768 green:0.0 blue:0.0 alpha:1.0] setStroke];
    path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(7.0, 5.0, 13.0, 10.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarCircleNoteImage unlockFocus];
    [toolbarCircleNoteImage setName:@"ToolbarCircleNote"];
    
    toolbarCircleNoteMenuImage = [toolbarCircleNoteImage createMenuImage];
    [toolbarCircleNoteMenuImage setName:@"ToolbarCircleNoteMenu"];
    
    toolbarAddCircleNoteImage = [toolbarCircleNoteImage createAddImage];
    [toolbarAddCircleNoteImage setName:@"ToolbarAddCircleNote"];
    
    toolbarAddCircleNoteMenuImage = [toolbarAddCircleNoteImage createMenuImage];
    [toolbarAddCircleNoteMenuImage setName:@"ToolbarAddCircleNoteMenu"];

    toolbarSquareNoteImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarSquareNoteImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow2 set];
    [[NSColor colorWithCalibratedRed:0.768 green:0.0 blue:0.0 alpha:1.0] setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(7.0, 5.0, 13.0, 10.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarSquareNoteImage unlockFocus];
    [toolbarSquareNoteImage setName:@"ToolbarSquareNote"];
    
    toolbarSquareNoteMenuImage = [toolbarSquareNoteImage createMenuImage];
    [toolbarSquareNoteMenuImage setName:@"ToolbarSquareNoteMenu"];
    
    toolbarAddSquareNoteImage = [toolbarSquareNoteImage createAddImage];
    [toolbarAddSquareNoteImage setName:@"ToolbarAddSquareNote"];
    
    toolbarAddSquareNoteMenuImage = [toolbarAddSquareNoteImage createMenuImage];
    [toolbarAddSquareNoteMenuImage setName:@"ToolbarAddSquareNoteMenu"];
    
    toolbarHighlightNoteImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarHighlightNoteImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 2.0, 15.0, 16.0)];
    [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:1.0 green:0.925 blue:0.0 alpha:1.0] endColor:[CIColor colorWithRed:1.0 green:0.745 blue:0.0 alpha:1.0]];
    NSShadow *redShadow = [[NSShadow alloc] init];
    [redShadow setShadowBlurRadius:2.0];
    [redShadow setShadowOffset:NSZeroSize];
    [redShadow setShadowColor:[NSColor colorWithCalibratedRed:0.7 green:0.0 blue:0.0 alpha:1.0]];
    [redShadow set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(8.5, 5.0)];
    [path lineToPoint:NSMakePoint(12.5, 15.0)];
    [path lineToPoint:NSMakePoint(14.5, 15.0)];
    [path lineToPoint:NSMakePoint(18.5, 5.0)];
    [path lineToPoint:NSMakePoint(16.5, 5.0)];
    [path lineToPoint:NSMakePoint(15.7, 7.0)];
    [path lineToPoint:NSMakePoint(11.3, 7.0)];
    [path lineToPoint:NSMakePoint(10.5, 5.0)];
    [path closePath];
    [path moveToPoint:NSMakePoint(12.1, 9.0)];
    [path lineToPoint:NSMakePoint(14.9, 9.0)];
    [path lineToPoint:NSMakePoint(13.5, 12.5)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarHighlightNoteImage unlockFocus];
    [toolbarHighlightNoteImage setName:@"ToolbarHighlightNote"];
    
    toolbarHighlightNoteMenuImage = [toolbarHighlightNoteImage createMenuImage];
    [toolbarHighlightNoteMenuImage setName:@"ToolbarHighlightNoteMenu"];
    
    toolbarAddHighlightNoteImage = [toolbarHighlightNoteImage createAddImage];
    [toolbarAddHighlightNoteImage setName:@"ToolbarAddHighlightNote"];
    
    toolbarAddHighlightNoteMenuImage = [toolbarAddHighlightNoteImage createMenuImage];
    [toolbarAddHighlightNoteMenuImage setName:@"ToolbarAddHighlightNoteMenu"];

    toolbarUnderlineNoteImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarUnderlineNoteImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(8.5, 6.0)];
    [path lineToPoint:NSMakePoint(12.5, 16.0)];
    [path lineToPoint:NSMakePoint(14.5, 16.0)];
    [path lineToPoint:NSMakePoint(18.5, 6.0)];
    [path lineToPoint:NSMakePoint(16.5, 6.0)];
    [path lineToPoint:NSMakePoint(15.7, 8.0)];
    [path lineToPoint:NSMakePoint(11.3, 8.0)];
    [path lineToPoint:NSMakePoint(10.5, 6.0)];
    [path closePath];
    [path moveToPoint:NSMakePoint(12.1, 10.0)];
    [path lineToPoint:NSMakePoint(14.9, 10.0)];
    [path lineToPoint:NSMakePoint(13.5, 13.5)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 3.0, 17.0, 2.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarUnderlineNoteImage unlockFocus];
    [toolbarUnderlineNoteImage setName:@"ToolbarUnderlineNote"];
    
    toolbarUnderlineNoteMenuImage = [toolbarUnderlineNoteImage createMenuImage];
    [toolbarUnderlineNoteMenuImage setName:@"ToolbarUnderlineNoteMenu"];
    
    toolbarAddUnderlineNoteImage = [toolbarUnderlineNoteImage createAddImage];
    [toolbarAddUnderlineNoteImage setName:@"ToolbarAddUnderlineNote"];
    
    toolbarAddUnderlineNoteMenuImage = [toolbarAddUnderlineNoteImage createMenuImage];
    [toolbarAddUnderlineNoteMenuImage setName:@"ToolbarAddUnderlineNoteMenu"];

    toolbarStrikeOutNoteImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarStrikeOutNoteImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(8.5, 4.0)];
    [path lineToPoint:NSMakePoint(12.5, 14.0)];
    [path lineToPoint:NSMakePoint(14.5, 14.0)];
    [path lineToPoint:NSMakePoint(18.5, 4.0)];
    [path lineToPoint:NSMakePoint(16.5, 4.0)];
    [path lineToPoint:NSMakePoint(15.7, 6.0)];
    [path lineToPoint:NSMakePoint(11.3, 6.0)];
    [path lineToPoint:NSMakePoint(10.5, 4.0)];
    [path closePath];
    [path moveToPoint:NSMakePoint(12.1, 8.0)];
    [path lineToPoint:NSMakePoint(14.9, 8.0)];
    [path lineToPoint:NSMakePoint(13.5, 11.5)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [[NSColor colorWithCalibratedRed:0.766 green:0.0 blue:0.0 alpha:1.0] setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.0, 7.0, 17.0, 2.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarStrikeOutNoteImage unlockFocus];
    [toolbarStrikeOutNoteImage setName:@"ToolbarStrikeOutNote"];
    
    toolbarStrikeOutNoteMenuImage = [toolbarStrikeOutNoteImage createMenuImage];
    [toolbarStrikeOutNoteMenuImage setName:@"ToolbarStrikeOutNoteMenu"];
    
    toolbarAddStrikeOutNoteImage = [toolbarStrikeOutNoteImage createAddImage];
    [toolbarAddStrikeOutNoteImage setName:@"ToolbarAddStrikeOutNote"];
    
    toolbarAddStrikeOutNoteMenuImage = [toolbarAddStrikeOutNoteImage createMenuImage];
    [toolbarAddStrikeOutNoteMenuImage setName:@"ToolbarAddStrikeOutNoteMenu"];

    toolbarLineNoteImage = [[NSImage alloc] initWithSize:NSMakeSize(27.0, 19.0)];
    [toolbarLineNoteImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow2 set];
    [[NSColor colorWithCalibratedRed:0.706 green:0.0 blue:0.0 alpha:1.0] setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(6.0, 9.0)];
    [path lineToPoint:NSMakePoint(18.0, 9.0)];
    [path lineToPoint:NSMakePoint(18.0, 6.5)];
    [path lineToPoint:NSMakePoint(21.5, 10.0)];
    [path lineToPoint:NSMakePoint(18.0, 13.5)];
    [path lineToPoint:NSMakePoint(18.0, 11.0)];
    [path lineToPoint:NSMakePoint(6.0, 11.0)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarLineNoteImage unlockFocus];
    [toolbarLineNoteImage setName:@"ToolbarLineNote"];
    
    toolbarLineNoteMenuImage = [toolbarLineNoteImage createMenuImage];
    [toolbarLineNoteMenuImage setName:@"ToolbarLineNoteMenu"];
    
    toolbarAddLineNoteImage = [toolbarLineNoteImage createAddImage];
    [toolbarAddLineNoteImage setName:@"ToolbarAddLineNote"];
    
    toolbarAddLineNoteMenuImage = [toolbarAddLineNoteImage createMenuImage];
    [toolbarAddLineNoteMenuImage setName:@"ToolbarAddLineNoteMenu"];
    
    toolbarTextToolImage = [[NSImage alloc] initWithSize:NSMakeSize(25.0, 19.0)];
    [toolbarTextToolImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setFill];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 4.0, 13.0, 13.0)];
    [path setWindingRule:NSEvenOddWindingRule];
    [path moveToPoint:NSMakePoint(7.5, 6.0)];
    [path lineToPoint:NSMakePoint(11.5, 15.0)];
    [path lineToPoint:NSMakePoint(13.5, 15.0)];
    [path lineToPoint:NSMakePoint(17.5, 6.0)];
    [path lineToPoint:NSMakePoint(15.5, 6.0)];
    [path lineToPoint:NSMakePoint(14.6, 8.0)];
    [path lineToPoint:NSMakePoint(10.4, 8.0)];
    [path lineToPoint:NSMakePoint(9.5, 6.0)];
    [path closePath];
    [path moveToPoint:NSMakePoint(11.3, 10.0)];
    [path lineToPoint:NSMakePoint(13.7, 10.0)];
    [path lineToPoint:NSMakePoint(12.5, 12.75)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [path setClip];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 4.0, 13.0, 6.0)];
    if (isTiger == NO)
        [path fillPathVerticallyWithStartColor:[CIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1.0] endColor:[CIColor colorWithRed:0.798 green:0.798 blue:0.798 alpha:1.0]];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarTextToolImage unlockFocus];
    [toolbarTextToolImage setName:@"ToolbarTextTool"];
    
    if (isTiger) {
        toolbarMoveToolImage = [[NSImage alloc] initWithSize:NSMakeSize(25.0, 17.0)];
        [toolbarMoveToolImage lockFocus];
        [[NSGraphicsContext currentContext] saveGraphicsState];
        [shadow1 set];
        [fgColor setFill];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(9.0, 7.5)];
        [path lineToPoint:NSMakePoint(7.0, 9.5)];
        [path lineToPoint:NSMakePoint(9.0, 11.5)];
        [path lineToPoint:NSMakePoint(9.0, 10.0)];
        [path lineToPoint:NSMakePoint(12.0, 10.0)];
        [path lineToPoint:NSMakePoint(12.0, 13.0)];
        [path lineToPoint:NSMakePoint(10.5, 13.0)];
        [path lineToPoint:NSMakePoint(12.5, 15.0)];
        [path lineToPoint:NSMakePoint(14.5, 13.0)];
        [path lineToPoint:NSMakePoint(13.0, 13.0)];
        [path lineToPoint:NSMakePoint(13.0, 10.0)];
        [path lineToPoint:NSMakePoint(16.0, 10.0)];
        [path lineToPoint:NSMakePoint(16.0, 11.5)];
        [path lineToPoint:NSMakePoint(18.0, 9.5)];
        [path lineToPoint:NSMakePoint(16.0, 7.5)];
        [path lineToPoint:NSMakePoint(16.0, 9.0)];
        [path lineToPoint:NSMakePoint(13.0, 9.0)];
        [path lineToPoint:NSMakePoint(13.0, 6.0)];
        [path lineToPoint:NSMakePoint(14.5, 6.0)];
        [path lineToPoint:NSMakePoint(12.5, 4.0)];
        [path lineToPoint:NSMakePoint(10.5, 6.0)];
        [path lineToPoint:NSMakePoint(12.0, 6.0)];
        [path lineToPoint:NSMakePoint(12.0, 9.0)];
        [path lineToPoint:NSMakePoint(9.0, 9.0)];
        [path closePath];
        [path fill];
        [[NSGraphicsContext currentContext] restoreGraphicsState];
        [toolbarMoveToolImage unlockFocus];
        [toolbarMoveToolImage setName:@"ToolbarMoveTool"];
    }
    
    toolbarMagnifyToolImage = [[NSImage alloc] initWithSize:NSMakeSize(25.0, 19.0)];
    [toolbarMagnifyToolImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(14.0, 8.0)];
    [path lineToPoint:NSMakePoint(18.0, 4.0)];
    [path setLineWidth:3.0];
    [path stroke];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithOvalInRect:NSMakeRect(6.0, 7.0, 9.0, 9.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarMagnifyToolImage unlockFocus];
    [toolbarMagnifyToolImage setName:@"ToolbarMagnifyTool"];
    
    toolbarSelectToolImage = [[NSImage alloc] initWithSize:NSMakeSize(25.0, 19.0)];
    [toolbarSelectToolImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [fgColor setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(7.0, 14.0)];
    [path lineToPoint:NSMakePoint(7.0, 16.0)];
    [path lineToPoint:NSMakePoint(9.0, 16.0)];
    [path moveToPoint:NSMakePoint(11.0, 16.0)];
    [path lineToPoint:NSMakePoint(14.0, 16.0)];
    [path moveToPoint:NSMakePoint(16.0, 16.0)];
    [path lineToPoint:NSMakePoint(18.0, 16.0)];
    [path lineToPoint:NSMakePoint(18.0, 14.0)];
    [path moveToPoint:NSMakePoint(18.0, 12.0)];
    [path lineToPoint:NSMakePoint(18.0, 9.0)];
    [path moveToPoint:NSMakePoint(18.0, 7.0)];
    [path lineToPoint:NSMakePoint(18.0, 5.0)];
    [path lineToPoint:NSMakePoint(16.0, 5.0)];
    [path moveToPoint:NSMakePoint(14.0, 5.0)];
    [path lineToPoint:NSMakePoint(11.0, 5.0)];
    [path moveToPoint:NSMakePoint(9.0, 5.0)];
    [path lineToPoint:NSMakePoint(7.0, 5.0)];
    [path lineToPoint:NSMakePoint(7.0, 7.0)];
    [path moveToPoint:NSMakePoint(7.0, 9.0)];
    [path lineToPoint:NSMakePoint(7.0, 12.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [path setLineWidth:1.0];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [toolbarSelectToolImage unlockFocus];
    [toolbarSelectToolImage setName:@"ToolbarSelectTool"];
    
	IconRef iconRef;
	OSErr err = GetIconRef(kOnSystemDisk, kSystemIconsCreator, kGenericFolderIcon, &iconRef);
    CGRect rect;
    
    if (err == noErr) {
        toolbarNewFolderImage = [[NSImage alloc] initWithSize:NSMakeSize(32.0, 32.0)];
        [toolbarNewFolderImage lockFocus];
        rect = CGRectMake(0.0, 0.0, 32.0, 32.0);
        PlotIconRefInContext((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],
                             &rect,
                             kAlignAbsoluteCenter, //kAlignNone,
                             kTransformNone,
                             NULL /*inLabelColor*/,
                             kPlotIconRefNormalFlags,
                             iconRef); 
        [[NSImage imageNamed:@"ToolbarAddBadge"] drawInRect:NSMakeRect(18.0, 18.0, 14.0, 14.0)
                                                   fromRect:NSMakeRect(0.0, 0.0, 14.0, 14.0)
                                                  operation:NSCompositeSourceOver
                                                   fraction:1.0];
        [toolbarNewFolderImage unlockFocus];
        [toolbarNewFolderImage setName:@"ToolbarNewFolder"];
        
        smallFolderImage = [[NSImage alloc] initWithSize:NSMakeSize(16.0, 16.0)];
        [smallFolderImage lockFocus];
        rect = CGRectMake(0.0, 0.0, 16.0, 16.0);
        PlotIconRefInContext((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],
                             &rect,
                             kAlignAbsoluteCenter, //kAlignNone,
                             kTransformNone,
                             NULL /*inLabelColor*/,
                             kPlotIconRefNormalFlags,
                             iconRef); 
        [smallFolderImage unlockFocus];
        [smallFolderImage setName:@"SmallFolder"];
        
        err = ReleaseIconRef(iconRef);
    }
    
    [shadow1 release];
    [shadow2 release];
}

+ (void)makeAdornImages {
    static NSImage *outlineViewAdornImage = nil;
    static NSImage *thumbnailViewAdornImage = nil;
    static NSImage *noteViewAdornImage = nil;
    static NSImage *snapshotViewAdornImage = nil;
    static NSImage *findViewAdornImage = nil;
    static NSImage *groupedFindViewAdornImage = nil;
    static NSImage *textNoteAdornImage = nil;
    static NSImage *anchoredNoteAdornImage = nil;
    static NSImage *circleNoteAdornImage = nil;
    static NSImage *squareNoteAdornImage = nil;
    static NSImage *highlightNoteAdornImage = nil;
    static NSImage *underlineNoteAdornImage = nil;
    static NSImage *strikeOutNoteAdornImage = nil;
    static NSImage *lineNoteAdornImage = nil;
    
    NSShadow *shadow1 = [[NSShadow alloc] init];
    [shadow1 setShadowBlurRadius:0.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.1]];
    
    NSSize size = NSMakeSize(25.0, 13.0);
    NSSize noteSize = NSMakeSize(15.0, 11.0);
    
    // this looks nicer on Leopard
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4)
        size.height = 14.0;
    
    NSColor *color = [NSColor colorWithCalibratedWhite:0.0 alpha:0.85];
    
    NSBezierPath *path;
    
    outlineViewAdornImage = [[NSImage alloc] initWithSize:size];
    [outlineViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(8.0, 2.5)];
    [path lineToPoint:NSMakePoint(19.0, 2.5)];
    [path moveToPoint:NSMakePoint(8.0, 5.5)];
    [path lineToPoint:NSMakePoint(19.0, 5.5)];
    [path moveToPoint:NSMakePoint(8.0, 8.5)];
    [path lineToPoint:NSMakePoint(19.0, 8.5)];
    [path moveToPoint:NSMakePoint(8.0, 11.5)];
    [path lineToPoint:NSMakePoint(19.0, 11.5)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [outlineViewAdornImage unlockFocus];
    if ([outlineViewAdornImage respondsToSelector:@selector(setTemplate:)])
        [outlineViewAdornImage setTemplate:YES];
    [outlineViewAdornImage setName:@"OutlineViewAdorn"];
    
    thumbnailViewAdornImage = [[NSImage alloc] initWithSize:size];
    [thumbnailViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(14.0, 3.5)];
    [path lineToPoint:NSMakePoint(19.0, 3.5)];
    [path moveToPoint:NSMakePoint(14.0, 10.5)];
    [path lineToPoint:NSMakePoint(19.0, 10.5)];
    [path appendBezierPathWithRect:NSMakeRect(8.5, 1.5, 4.0, 4.0)];
    [path appendBezierPathWithRect:NSMakeRect(8.5, 8.5, 4.0, 4.0)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [thumbnailViewAdornImage unlockFocus];
    if ([thumbnailViewAdornImage respondsToSelector:@selector(setTemplate:)])
        [thumbnailViewAdornImage setTemplate:YES];
    [thumbnailViewAdornImage setName:@"ThumbnailViewAdorn"];
    
    noteViewAdornImage = [[NSImage alloc] initWithSize:size];
    [noteViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(14.0, 3.5)];
    [path lineToPoint:NSMakePoint(19.0, 3.5)];
    [path moveToPoint:NSMakePoint(14.0, 10.5)];
    [path lineToPoint:NSMakePoint(19.0, 10.5)];
    [path moveToPoint:NSMakePoint(11.0, 1.5)];
    [path lineToPoint:NSMakePoint(8.5, 1.5)];
    [path lineToPoint:NSMakePoint(8.5, 5.5)];
    [path lineToPoint:NSMakePoint(12.5, 5.5)];
    [path lineToPoint:NSMakePoint(12.5, 3.0)];
    [path closePath];
    [path moveToPoint:NSMakePoint(11.5, 1.5)];
    [path lineToPoint:NSMakePoint(11.5, 2.5)];
    [path lineToPoint:NSMakePoint(12.5, 2.5)];
    [path moveToPoint:NSMakePoint(11.0, 8.5)];
    [path lineToPoint:NSMakePoint(8.5, 8.5)];
    [path lineToPoint:NSMakePoint(8.5, 12.5)];
    [path lineToPoint:NSMakePoint(12.5, 12.5)];
    [path lineToPoint:NSMakePoint(12.5, 10.0)];
    [path closePath];
    [path moveToPoint:NSMakePoint(11.5, 8.5)];
    [path lineToPoint:NSMakePoint(11.5, 9.5)];
    [path lineToPoint:NSMakePoint(12.5, 9.5)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [noteViewAdornImage unlockFocus];
    if ([noteViewAdornImage respondsToSelector:@selector(setTemplate:)])
        [noteViewAdornImage setTemplate:YES];
    [noteViewAdornImage setName:@"NoteViewAdorn"];
    
    snapshotViewAdornImage = [[NSImage alloc] initWithSize:size];
    [snapshotViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(8.5, 1.5, 10.0, 4.0)];
    [path appendBezierPathWithRect:NSMakeRect(8.5, 8.5, 10.0, 4.0)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [snapshotViewAdornImage unlockFocus];
    if ([snapshotViewAdornImage respondsToSelector:@selector(setTemplate:)])
        [snapshotViewAdornImage setTemplate:YES];
    [snapshotViewAdornImage setName:@"SnapshotViewAdorn"];
    
    findViewAdornImage = [[NSImage alloc] initWithSize:size];
    [findViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(8.0, 2.5)];
    [path lineToPoint:NSMakePoint(19.0, 2.5)];
    [path moveToPoint:NSMakePoint(8.0, 5.5)];
    [path lineToPoint:NSMakePoint(19.0, 5.5)];
    [path moveToPoint:NSMakePoint(8.0, 8.5)];
    [path lineToPoint:NSMakePoint(19.0, 8.5)];
    [path moveToPoint:NSMakePoint(8.0, 11.5)];
    [path lineToPoint:NSMakePoint(19.0, 11.5)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [findViewAdornImage unlockFocus];
    if ([findViewAdornImage respondsToSelector:@selector(setTemplate:)])
        [findViewAdornImage setTemplate:YES];
    [findViewAdornImage setName:@"FindViewAdorn"];
    
    groupedFindViewAdornImage = [[NSImage alloc] initWithSize:size];
    [groupedFindViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(8.0, 3.0)];
    [path lineToPoint:NSMakePoint(13.0, 3.0)];
    [path moveToPoint:NSMakePoint(8.0, 7.0)];
    [path lineToPoint:NSMakePoint(17.0, 7.0)];
    [path moveToPoint:NSMakePoint(8.0, 11.0)];
    [path lineToPoint:NSMakePoint(19.0, 11.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [groupedFindViewAdornImage unlockFocus];
    if ([groupedFindViewAdornImage respondsToSelector:@selector(setTemplate:)])
        [groupedFindViewAdornImage setTemplate:YES];
    [groupedFindViewAdornImage setName:@"GroupedFindViewAdorn"];
    
    textNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [textNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    //[shadow1 set];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.5, 3.5)];
    [path lineToPoint:NSMakePoint(11.5, 10.5)];
    [path lineToPoint:NSMakePoint(11.0, 11.0)];
    [path lineToPoint:NSMakePoint(4.0, 4.0)];
    [path closePath];
    [[NSColor colorWithCalibratedWhite:0.4 alpha:0.85] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.0, 4.0)];
    [path lineToPoint:NSMakePoint(11.0, 11.0)];
    [path lineToPoint:NSMakePoint(10.0, 11.0)];
    [path lineToPoint:NSMakePoint(3.0, 4.0)];
    [path closePath];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.85] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(6.0, 1.0)];
    [path lineToPoint:NSMakePoint(13.0, 8.0)];
    [path lineToPoint:NSMakePoint(13.0, 9.0)];
    [path lineToPoint:NSMakePoint(11.5, 10.5)];
    [path lineToPoint:NSMakePoint(4.5, 3.5)];
    [path lineToPoint:NSMakePoint(6.0, 2.0)];
    [path closePath];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.85] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(3.0, 1.5)];
    [path lineToPoint:NSMakePoint(4.0, 4.0)];
    [path lineToPoint:NSMakePoint(3.0, 4.0)];
    [path lineToPoint:NSMakePoint(2.5, 2.0)];
    [path closePath];
    [[NSColor colorWithCalibratedWhite:0.3 alpha:0.85] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(3.5, 1.0)];
    [path lineToPoint:NSMakePoint(6.0, 2.0)];
    [path lineToPoint:NSMakePoint(4.0, 4.0)];
    [path lineToPoint:NSMakePoint(3.0, 1.5)];
    [path closePath];
    [[NSColor colorWithCalibratedWhite:0.8 alpha:0.85] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.0, 0.5)];
    [path lineToPoint:NSMakePoint(6.0, 1.0)];
    [path lineToPoint:NSMakePoint(6.0, 2.0)];
    [path lineToPoint:NSMakePoint(3.5, 1.0)];
    [path closePath];
    [[NSColor colorWithCalibratedWhite:0.1 alpha:0.85] set];
    [path fill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(2.0, 0.0)];
    [path lineToPoint:NSMakePoint(4.0, 0.5)];
    [path lineToPoint:NSMakePoint(2.5, 2.0)];
    [path closePath];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.95] set];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [textNoteAdornImage unlockFocus];
    [textNoteAdornImage setName:@"TextNoteAdorn"];
    
    anchoredNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [anchoredNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(9.5, 0.5)];
    [path lineToPoint:NSMakePoint(2.5, 0.5)];
    [path lineToPoint:NSMakePoint(2.5, 10.5)];
    [path lineToPoint:NSMakePoint(12.5, 10.5)];
    [path lineToPoint:NSMakePoint(12.5, 3.5)];
    [path closePath];
    [path moveToPoint:NSMakePoint(9.5, 0.5)];
    [path lineToPoint:NSMakePoint(9.5, 3.5)];
    [path lineToPoint:NSMakePoint(12.5, 3.5)];
    [path moveToPoint:NSMakePoint(4.0, 4.5)];
    [path lineToPoint:NSMakePoint(8.0, 4.5)];
    [path moveToPoint:NSMakePoint(4.0, 6.5)];
    [path lineToPoint:NSMakePoint(11.0, 6.5)];
    [path moveToPoint:NSMakePoint(4.0, 8.5)];
    [path lineToPoint:NSMakePoint(11.0, 8.5)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [anchoredNoteAdornImage unlockFocus];
    [anchoredNoteAdornImage setName:@"AnchoredNoteAdorn"];
    
    circleNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [circleNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [color setStroke];
    NSBezierPath *clipPath = [NSBezierPath bezierPath];
    [clipPath moveToPoint:NSMakePoint(0.0, 0.0)];
    [clipPath lineToPoint:NSMakePoint(5.0, 0.0)];
    [clipPath lineToPoint:NSMakePoint(5.0, 7.0)];
    [clipPath lineToPoint:NSMakePoint(15.0, 7.0)];
    [clipPath lineToPoint:NSMakePoint(15.0, 11.0)];
    [clipPath lineToPoint:NSMakePoint(0.0, 11.0)];
    [clipPath closePath];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithOvalInRect:NSMakeRect(5.5, 0.5, 9.0, 6.0)];
    [path stroke];
    path = [NSBezierPath bezierPath];
    [clipPath addClip];
    [path appendBezierPathWithOvalInRect:NSMakeRect(0.5, 3.5, 10.0, 7.0)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [circleNoteAdornImage unlockFocus];
    [circleNoteAdornImage setName:@"CircleNoteAdorn"];

    squareNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [squareNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [color setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.5, 1.5, 9.0, 5.0)];
    [path moveToPoint:NSMakePoint(5.0, 4.5)];
    [path lineToPoint:NSMakePoint(0.5, 4.5)];
    [path lineToPoint:NSMakePoint(0.5, 10.5)];
    [path lineToPoint:NSMakePoint(10.5, 10.5)];
    [path lineToPoint:NSMakePoint(10.5, 7.0)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [squareNoteAdornImage unlockFocus];
    [squareNoteAdornImage setName:@"SquareNoteAdorn"];

    
    highlightNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [highlightNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.70] setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(5.0, 5.0)];
    [path lineToPoint:NSMakePoint(0.0, 5.0)];
    [path lineToPoint:NSMakePoint(0.0, 8.0)];
    [path lineToPoint:NSMakePoint(12.0, 8.0)];
    [path lineToPoint:NSMakePoint(12.0, 6.0)];
    [path lineToPoint:NSMakePoint(15.0, 6.0)];
    [path lineToPoint:NSMakePoint(15.0, 3.0)];
    [path lineToPoint:NSMakePoint(5.0, 3.0)];
    [path lineToPoint:NSMakePoint(5.0, 5.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [highlightNoteAdornImage unlockFocus];
    [highlightNoteAdornImage setName:@"HighlightNoteAdorn"];
    
    underlineNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [underlineNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.70] setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(1.0, 3.5)];
    [path lineToPoint:NSMakePoint(15.0, 3.5)];
    [path moveToPoint:NSMakePoint(0.0, 6.5)];
    [path lineToPoint:NSMakePoint(12.0, 6.5)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [underlineNoteAdornImage unlockFocus];
    [underlineNoteAdornImage setName:@"UnderlineNoteAdorn"];
    
    strikeOutNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [strikeOutNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.70] setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0.0, 2.5)];
    [path lineToPoint:NSMakePoint(14.0, 8.5)];
    [path moveToPoint:NSMakePoint(0.0, 8.5)];
    [path lineToPoint:NSMakePoint(14.0, 2.5)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [strikeOutNoteAdornImage unlockFocus];
    [strikeOutNoteAdornImage setName:@"StrikeOutNoteAdorn"];
    
    lineNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [lineNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow1 set];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.70] setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(2.0, 1.0)];
    [path lineToPoint:NSMakePoint(14.0, 10.0)];
    [path moveToPoint:NSMakePoint(8.0, 8.5)];
    [path lineToPoint:NSMakePoint(14.0, 10.0)];
    [path lineToPoint:NSMakePoint(11.0, 5.0)];
    [path setLineWidth:1.2];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [lineNoteAdornImage unlockFocus];
    [lineNoteAdornImage setName:@"LineNoteAdorn"];
    
    [shadow1 release];
}

+ (NSImage *)iconWithSize:(NSSize)iconSize forToolboxCode:(OSType) code {
	IconRef iconref;
	OSErr myErr = GetIconRef (kOnSystemDisk, kSystemIconsCreator, code, &iconref);
	
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(iconSize.width, iconSize.height)]; 
	CGRect rect =  CGRectMake(0.0, 0.0, iconSize.width, iconSize.height);
	
	[image lockFocus];
	PlotIconRefInContext((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],
                         &rect,
						 kAlignAbsoluteCenter, //kAlignNone,
						 kTransformNone,
						 NULL /*inLabelColor*/,
						 kPlotIconRefNormalFlags,
						 iconref); 
	[image unlockFocus]; 
	
	myErr = ReleaseIconRef(iconref);
	
	return [image autorelease];
}

+ (NSImage *)imageWithIconForToolboxCode:(OSType) code {
    return [self iconWithSize:NSMakeSize(32,32) forToolboxCode:code];
}

+ (NSImage *)missingFileImage {
    static NSImage *image = nil;
    if(image == nil){
        image = [[NSImage alloc] initWithSize:NSMakeSize(32, 32)];
        NSImage *genericDocImage = [self iconWithSize:NSMakeSize(32, 32) forToolboxCode:kGenericDocumentIcon];
        NSImage *questionMark = [self iconWithSize:NSMakeSize(20, 20) forToolboxCode:kQuestionMarkIcon];
        [image lockFocus];
        [genericDocImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:0.7];
        [questionMark compositeToPoint:NSMakePoint(6, 4) operation:NSCompositeSourceOver fraction:0.7];
        [image unlockFocus];
    }
    return image;
}

+ (NSImage *)smallMissingFileImage {
    static NSImage *image = nil;
    if(image == nil){
        image = [[NSImage alloc] initWithSize:NSMakeSize(16, 16)];
        NSImage *genericDocImage = [self iconWithSize:NSMakeSize(16, 16) forToolboxCode:kGenericDocumentIcon];
        NSImage *questionMark = [self iconWithSize:NSMakeSize(10, 10) forToolboxCode:kQuestionMarkIcon];
        [image lockFocus];
        [genericDocImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:0.7];
        [questionMark compositeToPoint:NSMakePoint(3, 2) operation:NSCompositeSourceOver fraction:0.7];
        [image unlockFocus];
    }
    return image;
}

- (void)drawFlippedInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(float)delta {
    [NSGraphicsContext saveGraphicsState];
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:0.0 yBy:NSMaxY(dstRect)];
    [transform scaleXBy:1.0 yBy:-1.0];
    [transform translateXBy:0.0 yBy:-NSMinY(dstRect)];
    [transform concat];
    [self drawInRect:dstRect fromRect:srcRect operation:op fraction:delta];
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawFlipped:(BOOL)isFlipped inRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op fraction:(float)delta {
    if (isFlipped)
        [self drawFlippedInRect:dstRect fromRect:srcRect operation:op fraction:delta];
    else
        [self drawInRect:dstRect fromRect:srcRect operation:op fraction:delta];
}

@end
