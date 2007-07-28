//
//  SKOutlineView.m
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

#import "SKOutlineView.h"


@implementation SKOutlineView

- (void)dealloc {
    if (trackingRects != NULL)
        CFRelease(trackingRects);
    [super dealloc];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
    if ([[self delegate] respondsToSelector:@selector(outlineViewHighlightedRows:)]) {
        NSMutableIndexSet *rowIndexes = [[[self selectedRowIndexes] mutableCopy] autorelease];
        NSArray *rows = [[self delegate] outlineViewHighlightedRows:self];
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

- (void)removeTrackingRects {
    if ([[self delegate] respondsToSelector:@selector(outlineView:shouldTrackTableColumn:item:)] == NO)
        return;
    
    CFIndex idx = CFArrayGetCount(trackingRects);
    while(idx--)
        [self removeTrackingRect:(NSTrackingRectTag)CFArrayGetValueAtIndex(trackingRects, idx)];
    CFArrayRemoveAllValues(trackingRects);
}

- (void)rebuildTrackingRects {
    if ([[self delegate] respondsToSelector:@selector(outlineView:shouldTrackTableColumn:item:)] == NO)
        return;
    
    if (trackingRects == nil)
        trackingRects = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
    else
        [self removeTrackingRects];
    
    NSRange rowRange = [self rowsInRect:[self visibleRect]];
    NSRange columnRange = [self columnsInRect:[self visibleRect]];
    unsigned int row, column;
	NSTableColumn *tableColumn;
    int userData;
    NSTrackingRectTag tag;
    
    for (column = columnRange.location; column < NSMaxRange(columnRange); column++) {
        tableColumn = [[self tableColumns] objectAtIndex:column];
		for (row = rowRange.location; row < NSMaxRange(rowRange); row++) {
            if ([[self delegate] outlineView:self shouldTrackTableColumn:tableColumn item:[self itemAtRow:row]]) {
                userData = row * [self numberOfColumns] + column;
                tag = [self addTrackingRect:[self frameOfCellAtColumn:column row:row] owner:self userData:(void *)userData assumeInside:NO];
                CFArrayAppendValue(trackingRects, (const void *)tag);
            }
        }
    }
}

- (void)reloadData{
    [super reloadData];
	[self rebuildTrackingRects];
}

- (void)resetCursorRects {
	[super resetCursorRects];
    [self rebuildTrackingRects];
}

- (void)setDataSource:(id)anObject {
	[super setDataSource:anObject];
	[self rebuildTrackingRects];
}

- (void)noteNumberOfRowsChanged {
	[super noteNumberOfRowsChanged];
	[self rebuildTrackingRects];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    if ([self window])
        [self removeTrackingRects];
}

- (void)viewDidMoveToWindow {
	if ([self window])
        [self rebuildTrackingRects];
}

- (void)mouseEntered:(NSEvent *)theEvent{
    if ([[self delegate] respondsToSelector:@selector(outlineView:mouseEnteredTableColumn:item:)]) {
        int userData = (int)[theEvent userData];
        int numCols = [self numberOfColumns];
		int column = userData % numCols;
		int row = userData / numCols;
        if (column != -1 && row != -1) {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
            [[self delegate] outlineView:self mouseEnteredTableColumn:tableColumn item:[self itemAtRow:row]];
        }
	}
}

- (void)mouseExited:(NSEvent *)theEvent{
    if ([[self delegate] respondsToSelector:@selector(outlineView:mouseExitedTableColumn:item:)]) {
        int userData = (int)[theEvent userData];
        int numCols = [self numberOfColumns];
		int column = userData % numCols;
		int row = userData / numCols;
        if (column != -1 && row != -1) {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
            [[self delegate] outlineView:self mouseExitedTableColumn:tableColumn item:[self itemAtRow:row]];
        }
	}
}

@end
