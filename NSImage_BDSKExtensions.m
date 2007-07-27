//
//  NSImage_BDSKExtensions.m
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

#import "NSImage_BDSKExtensions.h"


@implementation NSImage (BDSKExtensions)

+ (void)makeAdornImages {
    static NSImage *backAdornImage = nil;
    static NSImage *forwardAdornImage = nil;
    static NSImage *outlineViewAdornImage = nil;
    static NSImage *thumbnailViewAdornImage = nil;
    static NSImage *noteViewAdornImage = nil;
    static NSImage *snapshotViewAdornImage = nil;
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
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowBlurRadius:0.0];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.1]];
    
    NSColor *color = [NSColor colorWithCalibratedWhite:0.0 alpha:0.85];
    
    NSSize size = NSMakeSize(25.0, 13.0);
    NSSize noteSize = NSMakeSize(15.0, 11.0);
    NSPoint point = NSMakePoint(2.0, 1.0);
    NSBezierPath *path;
    NSBezierPath *arrowPath = [NSBezierPath bezierPath];
    [arrowPath moveToPoint:NSMakePoint(20.5,4.0)];
    [arrowPath lineToPoint:NSMakePoint(18.0,7.0)];
    [arrowPath lineToPoint:NSMakePoint(23.0,7.0)];
    [arrowPath closePath];
    
    backAdornImage = [[NSImage alloc] initWithSize:size];
    [backAdornImage lockFocus];
    //[shadow set];
    [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(16.0, 2.5)];
    [path lineToPoint:NSMakePoint(7.5, 7.0)];
    [path lineToPoint:NSMakePoint(16.0, 11.5)];
    [path closePath];
    [path fill];
    [backAdornImage unlockFocus];
    [backAdornImage setName:@"BackAdorn"];
    
    forwardAdornImage = [[NSImage alloc] initWithSize:size];
    [forwardAdornImage lockFocus];
    //[shadow set];
    [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] setFill];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(9.0, 2.5)];
    [path lineToPoint:NSMakePoint(17.5, 7.0)];
    [path lineToPoint:NSMakePoint(9.0, 11.5)];
    [path closePath];
    [path fill];
    [forwardAdornImage unlockFocus];
    [forwardAdornImage setName:@"ForwardAdorn"];
    
    outlineViewAdornImage = [[NSImage alloc] initWithSize:size];
    [outlineViewAdornImage lockFocus];
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
    [outlineViewAdornImage unlockFocus];
    [outlineViewAdornImage setName:@"OutlineViewAdorn"];
    
    thumbnailViewAdornImage = [[NSImage alloc] initWithSize:size];
    [thumbnailViewAdornImage lockFocus];
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
    [thumbnailViewAdornImage unlockFocus];
    [thumbnailViewAdornImage setName:@"ThumbnailViewAdorn"];
    
    noteViewAdornImage = [[NSImage alloc] initWithSize:size];
    [noteViewAdornImage lockFocus];
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
    [noteViewAdornImage unlockFocus];
    [noteViewAdornImage setName:@"NoteViewAdorn"];
    
    snapshotViewAdornImage = [[NSImage alloc] initWithSize:size];
    [snapshotViewAdornImage lockFocus];
    [shadow set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithRect:NSMakeRect(8.5, 1.5, 10.0, 4.0)];
    [path appendBezierPathWithRect:NSMakeRect(8.5, 8.5, 10.0, 4.0)];
    [path stroke];
    [snapshotViewAdornImage unlockFocus];
    [snapshotViewAdornImage setName:@"SnapshotViewAdorn"];
    
    textToolAdornImage = [[NSImage alloc] initWithSize:size];
    [textToolAdornImage lockFocus];
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
    [textToolAdornImage unlockFocus];
    [textToolAdornImage setName:@"TextToolAdorn"];
    
    moveToolAdornImage = [[NSImage alloc] initWithSize:size];
    [moveToolAdornImage lockFocus];
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
    [moveToolAdornImage unlockFocus];
    [moveToolAdornImage setName:@"MoveToolAdorn"];
    
    magnifyToolAdornImage = [[NSImage alloc] initWithSize:size];
    [magnifyToolAdornImage lockFocus];
    [shadow set];
    [color setStroke];
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithOvalInRect:NSMakeRect(7.0, 4.0, 8.0, 8.0)];
    [path moveToPoint:NSMakePoint(14.0, 5.0)];
    [path lineToPoint:NSMakePoint(18.0, 1.0)];
    [path setLineWidth:2.0];
    [path stroke];
    [magnifyToolAdornImage unlockFocus];
    [magnifyToolAdornImage setName:@"MagnifyToolAdorn"];
    
    selectToolAdornImage = [[NSImage alloc] initWithSize:size];
    [selectToolAdornImage lockFocus];
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
    [selectToolAdornImage unlockFocus];
    [selectToolAdornImage setName:@"SelectToolAdorn"];
    
    textNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [textNoteAdornImage lockFocus];
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
    [textNoteAdornImage unlockFocus];
    [textNoteAdornImage setName:@"TextNoteAdorn"];

    textNoteToolAdornImage = [[NSImage alloc] initWithSize:size];
    [textNoteToolAdornImage lockFocus];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [textNoteAdornImage compositeToPoint:point operation:NSCompositeCopy];
    [color setFill];
    [arrowPath fill];
    [textNoteToolAdornImage unlockFocus];
    [textNoteToolAdornImage setName:@"TextNoteToolAdorn"];
    
    anchoredNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [anchoredNoteAdornImage lockFocus];
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
    [anchoredNoteAdornImage unlockFocus];
    [anchoredNoteAdornImage setName:@"AnchoredNoteAdorn"];

    anchoredNoteToolAdornImage = [[NSImage alloc] initWithSize:size];
    [anchoredNoteToolAdornImage lockFocus];
    [anchoredNoteAdornImage compositeToPoint:point operation:NSCompositeCopy];
    [shadow set];
    [arrowPath fill];
    [anchoredNoteToolAdornImage unlockFocus];
    [anchoredNoteToolAdornImage setName:@"AnchoredNoteToolAdorn"];
    
    circleNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [circleNoteAdornImage lockFocus];
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
    [circleNoteAdornImage unlockFocus];
    [circleNoteAdornImage setName:@"CircleNoteAdorn"];

    circleNoteToolAdornImage = [[NSImage alloc] initWithSize:size];
    [circleNoteToolAdornImage lockFocus];
    [circleNoteAdornImage compositeToPoint:point operation:NSCompositeCopy];
    [color setFill];
    [arrowPath fill];
    [circleNoteToolAdornImage unlockFocus];
    [circleNoteToolAdornImage setName:@"CircleNoteToolAdorn"];
    
    squareNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [squareNoteAdornImage lockFocus];
    [shadow set];
    [color setStroke];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(5.5, 1.5, 9.0, 5.0)];
    [path moveToPoint:NSMakePoint(5.0, 4.5)];
    [path lineToPoint:NSMakePoint(0.5, 4.5)];
    [path lineToPoint:NSMakePoint(0.5, 10.5)];
    [path lineToPoint:NSMakePoint(10.5, 10.5)];
    [path lineToPoint:NSMakePoint(10.5, 7.0)];
    [path stroke];
    [squareNoteAdornImage unlockFocus];
    [squareNoteAdornImage setName:@"SquareNoteAdorn"];

    squareNoteToolAdornImage = [[NSImage alloc] initWithSize:size];
    [squareNoteToolAdornImage lockFocus];
    [squareNoteAdornImage compositeToPoint:point operation:NSCompositeCopy];
    [color setFill];
    [arrowPath fill];
    [squareNoteToolAdornImage unlockFocus];
    [squareNoteToolAdornImage setName:@"SquareNoteToolAdorn"];
    
    highlightNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [highlightNoteAdornImage lockFocus];
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
    [highlightNoteAdornImage unlockFocus];
    [highlightNoteAdornImage setName:@"HighlightNoteAdorn"];

    highlightNoteToolAdornImage = [[NSImage alloc] initWithSize:size];
    [highlightNoteToolAdornImage lockFocus];
    [highlightNoteAdornImage compositeToPoint:point operation:NSCompositeCopy];
    [color setFill];
    [arrowPath fill];
    [highlightNoteToolAdornImage unlockFocus];
    [highlightNoteToolAdornImage setName:@"HighlightNoteToolAdorn"];
    
    underlineNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [underlineNoteAdornImage lockFocus];
    [shadow set];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.70] setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(1.0, 3.5)];
    [path lineToPoint:NSMakePoint(15.0, 3.5)];
    [path moveToPoint:NSMakePoint(0.0, 6.5)];
    [path lineToPoint:NSMakePoint(12.0, 6.5)];
    [path stroke];
    [underlineNoteAdornImage unlockFocus];
    [underlineNoteAdornImage setName:@"UnderlineNoteAdorn"];

    underlineNoteToolAdornImage = [[NSImage alloc] initWithSize:size];
    [underlineNoteToolAdornImage lockFocus];
    [underlineNoteAdornImage compositeToPoint:point operation:NSCompositeCopy];
    [color setFill];
    [arrowPath fill];
    [underlineNoteToolAdornImage unlockFocus];
    [underlineNoteToolAdornImage setName:@"UnderlineNoteToolAdorn"];
    
    strikeOutNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [strikeOutNoteAdornImage lockFocus];
    [shadow set];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.70] setStroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0.0, 2.5)];
    [path lineToPoint:NSMakePoint(14.0, 8.5)];
    [path moveToPoint:NSMakePoint(0.0, 8.5)];
    [path lineToPoint:NSMakePoint(14.0, 2.5)];
    [path stroke];
    [strikeOutNoteAdornImage unlockFocus];
    [strikeOutNoteAdornImage setName:@"StrikeOutNoteAdorn"];

    strikeOutNoteToolAdornImage = [[NSImage alloc] initWithSize:size];
    [strikeOutNoteToolAdornImage lockFocus];
    [strikeOutNoteAdornImage compositeToPoint:point operation:NSCompositeCopy];
    [color setFill];
    [arrowPath fill];
    [strikeOutNoteToolAdornImage unlockFocus];
    [strikeOutNoteToolAdornImage setName:@"StrikeOutNoteToolAdorn"];
    
    lineNoteAdornImage = [[NSImage alloc] initWithSize:noteSize];
    [lineNoteAdornImage lockFocus];
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
    [lineNoteAdornImage unlockFocus];
    [lineNoteAdornImage setName:@"LineNoteAdorn"];

    lineNoteToolAdornImage = [[NSImage alloc] initWithSize:size];
    [lineNoteToolAdornImage lockFocus];
    [lineNoteAdornImage compositeToPoint:point operation:NSCompositeCopy];
    [color setFill];
    [arrowPath fill];
    [lineNoteToolAdornImage unlockFocus];
    [lineNoteToolAdornImage setName:@"LineNoteToolAdorn"];
    
    [shadow release];
}

@end
