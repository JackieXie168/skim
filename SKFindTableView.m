//
//  SKFindTableView.m
//  Skim
//
//  Created by Christiaan Hofman on 28/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKFindTableView.h"


@implementation SKFindTableView

- (void)dealloc{
    if (trackingRects != NULL)
        CFRelease(trackingRects);
    [super dealloc];
}

- (void)removeTrackingRects {
    if ([[self delegate] respondsToSelector:@selector(tableView:shouldTrackTableColumn:row:)] == NO)
        return;
    
    CFIndex idx = CFArrayGetCount(trackingRects);
    while(idx--)
        [self removeTrackingRect:(NSTrackingRectTag)CFArrayGetValueAtIndex(trackingRects, idx)];
    CFArrayRemoveAllValues(trackingRects);
}

- (void)rebuildTrackingRects {
    if ([[self delegate] respondsToSelector:@selector(tableView:shouldTrackTableColumn:row:)] == NO)
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
            if ([[self delegate] tableView:self shouldTrackTableColumn:tableColumn row:row]) {
                userData = row * [self numberOfColumns] + column;
                tag = [self addTrackingRect:[self frameOfCellAtColumn:column row:row] owner:self userData:NULL assumeInside:NO];
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
    if ([[self delegate] respondsToSelector:@selector(tableView:mouseEnteredTableColumn:row:)]) {
        int userData = (int)[theEvent userData];
        int numCols = [self numberOfColumns];
		int column = userData % numCols;
		int row = userData / numCols;
        if (column != -1 && row != -1) {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
            [[self delegate] tableView:self mouseEnteredTableColumn:tableColumn row:row];
        }
	}
}

- (void)mouseExited:(NSEvent *)theEvent{
    if ([[self delegate] respondsToSelector:@selector(tableView:mouseExitedTableColumn:row:)]) {
        int userData = (int)[theEvent userData];
        int numCols = [self numberOfColumns];
		int column = userData % numCols;
		int row = userData / numCols;
        if (column != -1 && row != -1) {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
            [[self delegate] tableView:self mouseExitedTableColumn:tableColumn row:row];
        }
	}
}

@end
