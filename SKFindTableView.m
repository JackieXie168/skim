//
//  SKFindTableView.m
//  Skim
//
//  Created by Christiaan Hofman on 7/28/07.
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

#import "SKFindTableView.h"
#import "SKStringConstants.h"
#import "NSObject_SKExtensions.h"


@implementation SKFindTableView

- (void)dealloc{
    if (trackingRects != NULL)
        CFRelease(trackingRects);
    [super dealloc];
}

- (void)awakeFromNib {
    NSNumber *fontSize = [[NSUserDefaults standardUserDefaults] objectForKey:SKTableFontSizeKey];
    if (fontSize)
        [self setFont:[NSFont systemFontOfSize:[fontSize floatValue]]];
}

- (void)removeTrackingRects {
    if (trackingRects) {
        CFIndex idx = CFArrayGetCount(trackingRects);
        while(idx--)
            [self removeTrackingRect:(NSTrackingRectTag)CFArrayGetValueAtIndex(trackingRects, idx)];
        CFArrayRemoveAllValues(trackingRects);
    }
}

- (void)rebuildTrackingRects {
    if ([[self delegate] respondsToSelector:@selector(tableView:shouldTrackTableColumn:row:)] == NO)
        return;
    
    if (trackingRects == nil)
        trackingRects = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
    else
        [self removeTrackingRects];
    
    if ([self window]) {
        NSRange rowRange = [self rowsInRect:[self visibleRect]];
        NSRange columnRange = [self columnsInRect:[self visibleRect]];
        unsigned int row, column;
        NSTableColumn *tableColumn;
        int userData;
        NSTrackingRectTag tag;
        
        for (column = columnRange.location; column < NSMaxRange(columnRange); column++) {
            tableColumn = [[self tableColumns] objectAtIndex:column];
            for (row = rowRange.location; row < NSMaxRange(rowRange); row++) {
                if ([[self delegate] tableView:self shouldTrackTableColumn:tableColumn row:row]) {
                    userData = row * [self numberOfColumns] + column;
                    tag = [self addTrackingRect:[self frameOfCellAtColumn:column row:row] owner:self userData:(void *)userData assumeInside:NO];
                    CFArrayAppendValue(trackingRects, (const void *)tag);
                }
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
    if ([[self delegate] respondsToSelector:@selector(tableView:mouseEnteredTableColumn:row:)]) {
        int userData = (int)[theEvent userData];
        int numCols = [self numberOfColumns];
		int column = userData % numCols;
		int row = userData / numCols;
        NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
        [[self delegate] tableView:self mouseEnteredTableColumn:tableColumn row:row];
	}
}

- (void)mouseExited:(NSEvent *)theEvent{
    if ([[self delegate] respondsToSelector:@selector(tableView:mouseExitedTableColumn:row:)]) {
        int userData = (int)[theEvent userData];
        int numCols = [self numberOfColumns];
		int column = userData % numCols;
		int row = userData / numCols;
        NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
        [[self delegate] tableView:self mouseExitedTableColumn:tableColumn row:row];
	}
}

@end

#pragma mark -

@interface NSLevelIndicatorCell (SKExtensions)
@end

@implementation NSLevelIndicatorCell (SKExtensions)

static void (*originalDrawWithFrameInView)(id, SEL, NSRect, id) = NULL;

// Drawing does not restrict the clip, while in discrete style it heavily uses gaussian blur, leading to unacceptable slow drawing
// see <http://toxicsoftware.com/discrete-nslevelindicatorcell-too-slow/>
- (void)replacementDrawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL drawDiscreteContinuous = ([self levelIndicatorStyle] == NSDiscreteCapacityLevelIndicatorStyle) && ((NSWidth(cellFrame) + 1.0) / [self maxValue] < 3.0);
    if (drawDiscreteContinuous)
        [self setLevelIndicatorStyle:NSContinuousCapacityLevelIndicatorStyle];
    [NSGraphicsContext saveGraphicsState];
    [[NSBezierPath bezierPathWithRect:cellFrame] addClip];
    originalDrawWithFrameInView(self, _cmd, cellFrame, controlView);
    [NSGraphicsContext restoreGraphicsState];
    if (drawDiscreteContinuous)
        [self setLevelIndicatorStyle:NSDiscreteCapacityLevelIndicatorStyle];
}

+ (void)load {
    originalDrawWithFrameInView = (void (*)(id, SEL, NSRect, id))[self setInstanceMethodFromSelector:@selector(replacementDrawWithFrame:inView:) forSelector:@selector(drawWithFrame:inView:)];
}

@end
