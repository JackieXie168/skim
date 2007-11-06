//
//  NSImage_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 7/27/07.
/*
 This software is Copyright (c) 2007
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

- (NSImage *)createMenuAdornImage {
    NSBezierPath *arrowPath = [NSBezierPath bezierPath];
    [arrowPath moveToPoint:NSMakePoint(20.5,4.0)];
    [arrowPath lineToPoint:NSMakePoint(18.0,7.0)];
    [arrowPath lineToPoint:NSMakePoint(23.0,7.0)];
    [arrowPath closePath];
    
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(25.0, 13.0)];
    [image lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [self compositeToPoint:NSMakePoint(2.0, 1.0) operation:NSCompositeCopy];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.85] setFill];
    [arrowPath fill];
    [image unlockFocus];
    
    return image;
}

- (NSImage *)createLargeNoteAdornImage {
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(19.0, 11.0)];
    [image lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [self compositeToPoint:NSMakePoint(2.0, 0.0) operation:NSCompositeCopy];
    [image unlockFocus];
    
    return image;
}

+ (void)makeAdornImages {
    static NSImage *backAdornImage = nil;
    static NSImage *forwardAdornImage = nil;
    static NSImage *firstAdornImage = nil;
    static NSImage *lastAdornImage = nil;
    static NSImage *zoomInAdornImage = nil;
    static NSImage *zoomOutAdornImage = nil;
    static NSImage *zoomActualAdornImage = nil;
    static NSImage *outlineViewAdornImage = nil;
    static NSImage *thumbnailViewAdornImage = nil;
    static NSImage *noteViewAdornImage = nil;
    static NSImage *snapshotViewAdornImage = nil;
    static NSImage *findViewAdornImage = nil;
    static NSImage *groupedFindViewAdornImage = nil;
    static NSImage *textToolAdornImage = nil;
    static NSImage *moveToolAdornImage = nil;
    static NSImage *magnifyToolAdornImage = nil;
    static NSImage *selectToolAdornImage = nil;
    static NSImage *textNoteToolAdornImage = nil;
    static NSImage *anchoredNoteToolAdornImage = nil;
    static NSImage *circleNoteToolAdornImage = nil;
    static NSImage *squareNoteToolAdornImage = nil;
    static NSImage *highlightNoteToolAdornImage = nil;
    static NSImage *underlineNoteToolAdornImage = nil;
    static NSImage *strikeOutNoteToolAdornImage = nil;
    static NSImage *lineNoteToolAdornImage = nil;
    static NSImage *textNoteAdornImage = nil;
    static NSImage *anchoredNoteAdornImage = nil;
    static NSImage *circleNoteAdornImage = nil;
    static NSImage *squareNoteAdornImage = nil;
    static NSImage *highlightNoteAdornImage = nil;
    static NSImage *underlineNoteAdornImage = nil;
    static NSImage *strikeOutNoteAdornImage = nil;
    static NSImage *lineNoteAdornImage = nil;
    static NSImage *textNoteAdorn2Image = nil;
    static NSImage *anchoredNoteAdorn2Image = nil;
    static NSImage *circleNoteAdorn2Image = nil;
    static NSImage *squareNoteAdorn2Image = nil;
    static NSImage *highlightNoteAdorn2Image = nil;
    static NSImage *underlineNoteAdorn2Image = nil;
    static NSImage *strikeOutNoteAdorn2Image = nil;
    static NSImage *lineNoteAdorn2Image = nil;
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowBlurRadius:0.0];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.1]];
    
    NSColor *color = [NSColor colorWithCalibratedWhite:0.0 alpha:0.85];
    
    NSSize size = NSMakeSize(25.0, 13.0);
    NSSize noteSize = NSMakeSize(15.0, 11.0);
    NSBezierPath *path;
    
    backAdornImage = [[NSImage alloc] initWithSize:size];
    [backAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    //[shadow set];
    [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(16.0, 2.5)];
    [path lineToPoint:NSMakePoint(7.5, 7.0)];
    [path lineToPoint:NSMakePoint(16.0, 11.5)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [backAdornImage unlockFocus];
    [backAdornImage setName:@"BackAdorn"];
    
    forwardAdornImage = [[NSImage alloc] initWithSize:size];
    [forwardAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    //[shadow set];
    [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(9.0, 2.5)];
    [path lineToPoint:NSMakePoint(17.5, 7.0)];
    [path lineToPoint:NSMakePoint(9.0, 11.5)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [forwardAdornImage unlockFocus];
    [forwardAdornImage setName:@"ForwardAdorn"];
    
    firstAdornImage = [[NSImage alloc] initWithSize:size];
    [firstAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    //[shadow set];
    [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(18.0, 2.5)];
    [path lineToPoint:NSMakePoint(9.5, 7.0)];
    [path lineToPoint:NSMakePoint(18.0, 11.5)];
    [path closePath];
    [path appendBezierPathWithRect:NSMakeRect(5.0, 3.0, 3.0, 8.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [firstAdornImage unlockFocus];
    [firstAdornImage setName:@"FirstAdorn"];
    
    lastAdornImage = [[NSImage alloc] initWithSize:size];
    [lastAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    //[shadow set];
    [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(7.0, 2.5)];
    [path lineToPoint:NSMakePoint(15.5, 7.0)];
    [path lineToPoint:NSMakePoint(7.0, 11.5)];
    [path closePath];
    [path appendBezierPathWithRect:NSMakeRect(17.0, 3.0, 3.0, 8.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [lastAdornImage unlockFocus];
    [lastAdornImage setName:@"LastAdorn"];
    
    zoomInAdornImage = [[NSImage alloc] initWithSize:size];
    [zoomInAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
    [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] setFill];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(8.0, 6.0, 11.0, 3.0)];
    [path appendBezierPathWithRect:NSMakeRect(12.0, 2.0, 3.0, 11.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [zoomInAdornImage unlockFocus];
    [zoomInAdornImage setName:@"ZoomInAdorn"];
    
    zoomOutAdornImage = [[NSImage alloc] initWithSize:size];
    [zoomOutAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
    [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] setFill];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(6.0, 6.0, 11.0, 3.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [zoomOutAdornImage unlockFocus];
    [zoomOutAdornImage setName:@"ZoomOutAdorn"];
    
    zoomActualAdornImage = [[NSImage alloc] initWithSize:size];
    [zoomActualAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
    [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] setFill];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(7.0, 4.0, 11.0, 3.0)];
    [path appendBezierPathWithRect:NSMakeRect(7.0, 8.0, 11.0, 3.0)];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [zoomActualAdornImage unlockFocus];
    [zoomActualAdornImage setName:@"ZoomActualAdorn"];
    
    outlineViewAdornImage = [[NSImage alloc] initWithSize:size];
    [outlineViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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
    [outlineViewAdornImage setName:@"OutlineViewAdorn"];
    
    thumbnailViewAdornImage = [[NSImage alloc] initWithSize:size];
    [thumbnailViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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
    [thumbnailViewAdornImage setName:@"ThumbnailViewAdorn"];
    
    noteViewAdornImage = [[NSImage alloc] initWithSize:size];
    [noteViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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
    [noteViewAdornImage setName:@"NoteViewAdorn"];
    
    snapshotViewAdornImage = [[NSImage alloc] initWithSize:size];
    [snapshotViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(8.5, 1.5, 10.0, 4.0)];
    [path appendBezierPathWithRect:NSMakeRect(8.5, 8.5, 10.0, 4.0)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [snapshotViewAdornImage unlockFocus];
    [snapshotViewAdornImage setName:@"SnapshotViewAdorn"];
    
    findViewAdornImage = [[NSImage alloc] initWithSize:size];
    [findViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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
    [findViewAdornImage setName:@"FindViewAdorn"];
    
    groupedFindViewAdornImage = [[NSImage alloc] initWithSize:size];
    [groupedFindViewAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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
    [groupedFindViewAdornImage setName:@"GroupedFindViewAdorn"];
    
    textToolAdornImage = [[NSImage alloc] initWithSize:size];
    [textToolAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
    [color setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(7.5, 2.0)];
    [path lineToPoint:NSMakePoint(11.5, 12.0)];
    [path lineToPoint:NSMakePoint(13.5, 12.0)];
    [path lineToPoint:NSMakePoint(17.5, 2.0)];
    [path lineToPoint:NSMakePoint(15.5, 2.0)];
    [path lineToPoint:NSMakePoint(14.3, 5.0)];
    [path lineToPoint:NSMakePoint(10.2, 5.0)];
    [path lineToPoint:NSMakePoint(9.0, 2.0)];
    [path closePath];
    [path moveToPoint:NSMakePoint(10.6, 6.0)];
    [path lineToPoint:NSMakePoint(13.9, 6.0)];
    [path lineToPoint:NSMakePoint(12.25, 10.125)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [textToolAdornImage unlockFocus];
    [textToolAdornImage setName:@"TextToolAdorn"];
    
    moveToolAdornImage = [[NSImage alloc] initWithSize:size];
    [moveToolAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
    [[NSColor blackColor] set];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(9.0, 5.5)];
    [path lineToPoint:NSMakePoint(7.0, 7.5)];
    [path lineToPoint:NSMakePoint(9.0, 9.5)];
    [path lineToPoint:NSMakePoint(9.0, 8.0)];
    [path lineToPoint:NSMakePoint(12.0, 8.0)];
    [path lineToPoint:NSMakePoint(12.0, 11.0)];
    [path lineToPoint:NSMakePoint(10.5, 11.0)];
    [path lineToPoint:NSMakePoint(12.5, 13.0)];
    [path lineToPoint:NSMakePoint(14.5, 11.0)];
    [path lineToPoint:NSMakePoint(13.0, 11.0)];
    [path lineToPoint:NSMakePoint(13.0, 8.0)];
    [path lineToPoint:NSMakePoint(16.0, 8.0)];
    [path lineToPoint:NSMakePoint(16.0, 9.5)];
    [path lineToPoint:NSMakePoint(18.0, 7.5)];
    [path lineToPoint:NSMakePoint(16.0, 5.5)];
    [path lineToPoint:NSMakePoint(16.0, 7.0)];
    [path lineToPoint:NSMakePoint(13.0, 7.0)];
    [path lineToPoint:NSMakePoint(13.0, 4.0)];
    [path lineToPoint:NSMakePoint(14.5, 4.0)];
    [path lineToPoint:NSMakePoint(12.5, 2.0)];
    [path lineToPoint:NSMakePoint(10.5, 4.0)];
    [path lineToPoint:NSMakePoint(12.0, 4.0)];
    [path lineToPoint:NSMakePoint(12.0, 7.0)];
    [path lineToPoint:NSMakePoint(9.0, 7.0)];
    [path closePath];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [moveToolAdornImage unlockFocus];
    [moveToolAdornImage setName:@"MoveToolAdorn"];
    
    magnifyToolAdornImage = [[NSImage alloc] initWithSize:size];
    [magnifyToolAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithOvalInRect:NSMakeRect(7.0, 4.0, 8.0, 8.0)];
    [path moveToPoint:NSMakePoint(14.0, 5.0)];
    [path lineToPoint:NSMakePoint(18.0, 1.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [magnifyToolAdornImage unlockFocus];
    [magnifyToolAdornImage setName:@"MagnifyToolAdorn"];
    
    selectToolAdornImage = [[NSImage alloc] initWithSize:size];
    [selectToolAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(7.5, 9.0)];
    [path lineToPoint:NSMakePoint(7.5, 11.5)];
    [path lineToPoint:NSMakePoint(10.0, 11.5)];
    [path moveToPoint:NSMakePoint(11.0, 11.5)];
    [path lineToPoint:NSMakePoint(14.0, 11.5)];
    [path moveToPoint:NSMakePoint(15.0, 11.5)];
    [path lineToPoint:NSMakePoint(17.5, 11.5)];
    [path lineToPoint:NSMakePoint(17.5, 9.0)];
    [path moveToPoint:NSMakePoint(17.5, 8.0)];
    [path lineToPoint:NSMakePoint(17.5, 6.0)];
    [path moveToPoint:NSMakePoint(17.5, 5.0)];
    [path lineToPoint:NSMakePoint(17.5, 2.5)];
    [path lineToPoint:NSMakePoint(15.0, 2.5)];
    [path moveToPoint:NSMakePoint(14.0, 2.5)];
    [path lineToPoint:NSMakePoint(11.0, 2.5)];
    [path moveToPoint:NSMakePoint(10.0, 2.5)];
    [path lineToPoint:NSMakePoint(7.5, 2.5)];
    [path lineToPoint:NSMakePoint(7.5, 5.0)];
    [path moveToPoint:NSMakePoint(7.5, 6.0)];
    [path lineToPoint:NSMakePoint(7.5, 8.0)];
    [path stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    [selectToolAdornImage unlockFocus];
    [selectToolAdornImage setName:@"SelectToolAdorn"];
    
    textNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [textNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    //[shadow set];
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

    textNoteAdorn2Image = [textNoteAdornImage createLargeNoteAdornImage];
    [textNoteAdorn2Image setName:@"TextNoteAdorn2"];

    textNoteToolAdornImage = [textNoteAdornImage createMenuAdornImage];
    [textNoteToolAdornImage setName:@"TextNoteToolAdorn"];
    
    anchoredNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [anchoredNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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

    anchoredNoteAdorn2Image = [anchoredNoteAdornImage createLargeNoteAdornImage];
    [anchoredNoteAdorn2Image setName:@"AnchoredNoteAdorn2"];

    anchoredNoteToolAdornImage = [anchoredNoteAdornImage createMenuAdornImage];
    [anchoredNoteToolAdornImage setName:@"AnchoredNoteToolAdorn"];
    
    circleNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [circleNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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

    circleNoteAdorn2Image = [circleNoteAdornImage createLargeNoteAdornImage];
    [circleNoteAdorn2Image setName:@"CircleNoteAdorn2"];

    circleNoteToolAdornImage = [circleNoteAdornImage createMenuAdornImage];
    [circleNoteToolAdornImage setName:@"CircleNoteToolAdorn"];
    
    squareNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [squareNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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

    squareNoteAdorn2Image = [squareNoteAdornImage createLargeNoteAdornImage];
    [squareNoteAdorn2Image setName:@"SquareNoteAdorn2"];

    squareNoteToolAdornImage = [squareNoteAdornImage createMenuAdornImage];
    [squareNoteToolAdornImage setName:@"SquareNoteToolAdorn"];
    
    highlightNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [highlightNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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

    highlightNoteAdorn2Image = [highlightNoteAdornImage createLargeNoteAdornImage];
    [highlightNoteAdorn2Image setName:@"HighlightNoteAdorn2"];

    highlightNoteToolAdornImage = [highlightNoteAdornImage createMenuAdornImage];
    [highlightNoteToolAdornImage setName:@"HighlightNoteToolAdorn"];
    
    underlineNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [underlineNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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

    underlineNoteAdorn2Image = [underlineNoteAdornImage createLargeNoteAdornImage];
    [underlineNoteAdorn2Image setName:@"UnderlineNoteAdorn2"];

    underlineNoteToolAdornImage = [underlineNoteAdornImage createMenuAdornImage];
    [underlineNoteToolAdornImage setName:@"UnderlineNoteToolAdorn"];
    
    strikeOutNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [strikeOutNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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

    strikeOutNoteAdorn2Image = [strikeOutNoteAdornImage createLargeNoteAdornImage];
    [strikeOutNoteAdorn2Image setName:@"StrikeOutNoteAdorn2"];

    strikeOutNoteToolAdornImage = [strikeOutNoteAdornImage createMenuAdornImage];
    [strikeOutNoteToolAdornImage setName:@"StrikeOutNoteToolAdorn"];
    
    lineNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [lineNoteAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [shadow set];
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

    lineNoteAdorn2Image = [lineNoteAdornImage createLargeNoteAdornImage];
    [lineNoteAdorn2Image setName:@"LineNoteAdorn2"];

    lineNoteToolAdornImage = [lineNoteAdornImage createMenuAdornImage];
    [lineNoteToolAdornImage setName:@"LineNoteToolAdorn"];
    
    [shadow release];
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
