//
//  SKSnapshotPageCell.m
//  Skim
//
//  Created by Christiaan Hofman on 4/10/08.
/*
 This software is Copyright (c) 2008
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
#import "SKRuntime.h"

NSString *SKSnapshotPageCellLabelKey = @"label";
NSString *SKSnapshotPageCellHasWindowKey = @"hasWindow";

@implementation SKSnapshotPageCell

static NSShadow *selectedShadow = nil;
static NSShadow *deselectedShadow = nil;
static NSColor *selectedColor = nil;
static NSColor *deselectedColor = nil;

+ (void)initialize
{
    OBINITIALIZE;
    
    selectedShadow = [[NSShadow alloc] init];
    [selectedShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.2]];
    [selectedShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    deselectedShadow = [[NSShadow alloc] init];
    [deselectedShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.2]];
    [deselectedShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    
    selectedColor = [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] copy];
    deselectedColor = [[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] copy];
}

- (id)copyWithZone:(NSZone *)aZone {
    SKSnapshotPageCell *copy = [super copyWithZone:aZone];
    copy->hasWindow = hasWindow;
    return copy;
}

- (void)setObjectValue:(id)anObject {
    if ([anObject isKindOfClass:[NSString class]]) {
        [super setObjectValue:anObject];
    } else {
        [super setObjectValue:[anObject valueForKey:SKSnapshotPageCellLabelKey]];
        hasWindow = [[anObject valueForKey:SKSnapshotPageCellHasWindowKey] boolValue];
    }
}

- (id)objectValue {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:hasWindow], SKSnapshotPageCellHasWindowKey, [self stringValue], SKSnapshotPageCellLabelKey, nil];
}

- (NSSize)cellSize {
    NSSize size = [super cellSize];
    size.width = fmaxf(size.width, 12.0);
    return size;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect textRect, imageRect, ignored;
    NSDivideRect(cellFrame, &textRect, &imageRect, 17.0, NSMinYEdge);
    [super drawInteriorWithFrame:textRect inView:controlView];
    if (hasWindow) {
        BOOL isSelected = [self isHighlighted] && [[controlView window] isKeyWindow] && [[[controlView window] firstResponder] isEqual:controlView];
        float radius = 2.0;
        NSBezierPath *path = [NSBezierPath bezierPath];
        NSShadow *aShadow;
        NSColor *fillColor;
        
        if (isSelected) {
            aShadow = selectedShadow;
            fillColor = selectedColor;
        } else {
            aShadow = deselectedShadow;
            fillColor = deselectedColor;
        }
        
        NSDivideRect(imageRect, &imageRect, &ignored, 10.0, NSMinYEdge);
        imageRect.origin.x += 4.0;
        imageRect.size.width = 10.0;
        
        [path moveToPoint:NSMakePoint(NSMinX(imageRect), NSMaxY(imageRect))];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(imageRect) + radius, NSMinY(imageRect) + radius) radius:radius startAngle:180.0 endAngle:270.0];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(imageRect) - radius, NSMinY(imageRect) + radius) radius:radius startAngle:270.0 endAngle:360.0];
        [path lineToPoint:NSMakePoint(NSMaxX(imageRect), NSMaxY(imageRect))];
        [path closePath];
        
        imageRect = NSInsetRect(imageRect, 1.0, 2.0);
        imageRect.size.height += 1.0;
        
        [path appendBezierPath:[NSBezierPath bezierPathWithRect:imageRect]];
        [path setWindingRule:NSEvenOddWindingRule];
        
        [NSGraphicsContext saveGraphicsState];
        
        [aShadow set];
        [fillColor setFill];

        [path fill];
        
        [NSGraphicsContext restoreGraphicsState];
    }
}

@end
