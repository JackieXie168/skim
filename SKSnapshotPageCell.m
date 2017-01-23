//
//  SKSnapshotPageCell.m
//  Skim
//
//  Created by Christiaan Hofman on 4/10/08.
/*
 This software is Copyright (c) 2008-2017
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

#import "SKSnapshotPageCell.h"
#import "SKDictionaryFormatter.h"
#import "NSGeometry_SKExtensions.h"
#import "NSShadow_SKExtensions.h"
#import "NSImage_SKExtensions.h"

NSString *SKSnapshotPageCellLabelKey = @"label";
NSString *SKSnapshotPageCellHasWindowKey = @"hasWindow";

#define MIN_CELL_WIDTH 16.0

@implementation SKSnapshotPageCell

static SKDictionaryFormatter *snapshotPageCellFormatter = nil;

+ (void)initialize {
    SKINITIALIZE;
    snapshotPageCellFormatter = [[SKDictionaryFormatter alloc] initWithKey:SKSnapshotPageCellLabelKey];
}

- (id)initTextCell:(NSString *)aString {
    self = [super initTextCell:aString];
    if (self) {
        [self setFormatter:snapshotPageCellFormatter];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
    if (self) {
        if ([self formatter] == nil)
            [self setFormatter:snapshotPageCellFormatter];
	}
	return self;
}

- (NSSize)cellSizeForBounds:(NSRect)aRect {
    NSSize size = [super cellSizeForBounds:aRect];
    size.width = fmin(fmax(size.width, MIN_CELL_WIDTH), NSWidth(aRect));
    return size;
}

+ (NSImage *)windowImage {
    static NSImage *windowImage = nil;
    if (windowImage == nil) {
        windowImage = [[NSImage imageWithSize:NSMakeSize(12.0, 12.0) drawingHandler:^(NSRect dstRect){
            NSBezierPath *path = [NSBezierPath bezierPath];
            [path moveToPoint:NSMakePoint(1.0, 2.0)];
            [path appendBezierPathWithArcWithCenter:NSMakePoint(3.0, 10.0) radius:2.0 startAngle:180.0 endAngle:90.0 clockwise:YES];
            [path appendBezierPathWithArcWithCenter:NSMakePoint(9.0, 10.0) radius:2.0 startAngle:90.0 endAngle:0.0 clockwise:YES];
            [path lineToPoint:NSMakePoint(11.0, 2.0)];
            [path closePath];
            [path appendBezierPath:[NSBezierPath bezierPathWithRect:NSMakeRect(2.0, 3.0, 8.0, 7.0)]];
            [path setWindingRule:NSEvenOddWindingRule];
            [[NSColor blackColor] setFill];
            [path fill];
            return YES;
        }] retain];
        [windowImage setTemplate:YES];
    }
    return windowImage;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect textRect, imageRect;
    NSRectEdge topEdge = [controlView isFlipped] ? NSMinYEdge : NSMaxYEdge;
    NSDivideRect(cellFrame, &textRect, &imageRect, [super cellSizeForBounds:cellFrame].height + 1.0, topEdge);
    
    [super drawInteriorWithFrame:textRect inView:controlView];
    
    id obj = [self objectValue];
    BOOL hasWindow = [obj respondsToSelector:@selector(objectForKey:)] ? [[obj objectForKey:SKSnapshotPageCellHasWindowKey] boolValue] : NO;
    if (hasWindow) {
        NSImageCell *imageCell = [[NSImageCell alloc] initImageCell:[[self class] windowImage]];
        [imageCell setBackgroundStyle:[self backgroundStyle]];
        imageRect = NSOffsetRect(SKSliceRect(SKSliceRect(imageRect, 12.0, topEdge), 12.0, NSMinXEdge), 3.0, 0.0);
        [imageCell drawInteriorWithFrame:imageRect inView:controlView];
        [imageCell release];
    }
}

@end
