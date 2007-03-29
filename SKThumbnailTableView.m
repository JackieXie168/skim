//
//  SKThumbnailTableView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/25/07.
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

#import "SKThumbnailTableView.h"


@implementation SKThumbnailTableView

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}

- (void)setFrameSize:(NSSize)frameSize {
    [super setFrameSize:frameSize];
    [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
    if ([[self delegate] respondsToSelector:@selector(tableViewHighlightedRows:)]) {
        NSMutableIndexSet *rowIndexes = [[[self selectedRowIndexes] mutableCopy] autorelease];
        NSArray *rows = [[self delegate] tableViewHighlightedRows:self];
        NSColor *color = ([[self window] isKeyWindow] && [[self window] firstResponder] == self) ? [NSColor alternateSelectedControlColor] : [NSColor secondarySelectedControlColor];
        float factor = 0.5;
        int i, count = [rows count];
        
        [NSGraphicsContext saveGraphicsState];
        for (i = 0; i < count; i++) {
            int row = [[rows objectAtIndex:i] intValue];
            [[[NSColor controlBackgroundColor] blendedColorWithFraction:factor ofColor:color] set];
            factor -= 0.1;
            if ([rowIndexes containsIndex:row] == NO) {
                NSRectFill([self rectOfRow:row]);
                [rowIndexes addIndex:row];
            }
            if (factor <= 0.0) break;
        }
        [NSGraphicsContext restoreGraphicsState];
    }
    [super highlightSelectionInClipRect:clipRect]; 
}

@end

#pragma mark -

@implementation SKSnapshotTableView

- (void)delete:(id)sender {
    if ([[self delegate] respondsToSelector:@selector(tableView:deleteRowsWithIndexes:)]) {
		if ([self selectedRow] == -1)
			NSBeep();
		else
			[[self delegate] tableView:self deleteRowsWithIndexes:[self selectedRowIndexes]];
    }
}

- (void)keyDown:(NSEvent *)theEvent {
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar eventChar = [characters length] > 0 ? [characters characterAtIndex:0] : 0;
	unsigned int modifiers = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    
	if ((eventChar == NSDeleteCharacter || eventChar == NSDeleteFunctionKey) && modifiers == 0)
        [self delete:self];
	else
		[super keyDown:theEvent];
}

@end

#pragma mark -

@implementation SKSnapshotPageCell

- (void)setObjectValue:(id)anObject {
    [super setObjectValue:[anObject valueForKey:@"label"]];
    hasWindow = [[anObject valueForKey:@"hasWindow"] boolValue];
}

- (id)objectValue {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:hasWindow], @"hasWindow", [self stringValue], @"label", nil];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect textRect, imageRect, ignored;
    NSDivideRect(cellFrame, &textRect, &imageRect, 17.0, NSMinYEdge);
    [super drawInteriorWithFrame:textRect inView:controlView];
    if (hasWindow) {
        BOOL isSelected = [self isHighlighted] && [[controlView window] isKeyWindow] && [[[controlView window] firstResponder] isEqual:controlView];
        float radius = 2.0;
        NSBezierPath *path = [NSBezierPath bezierPath];
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        
        [NSGraphicsContext saveGraphicsState];
        
        [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        if (isSelected)
            [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.2]];
        else
            [shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.1]];
        [shadow set];
        
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
        
        if (isSelected)
            [[NSColor colorWithDeviceWhite:1.0 alpha:1.0] set];
        else
            [[NSColor colorWithDeviceWhite:0.0 alpha:0.8] set];
        
        [path fill];
        
        [NSGraphicsContext restoreGraphicsState];
    }
}

@end
