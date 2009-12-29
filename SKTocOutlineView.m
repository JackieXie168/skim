//
//  SKTocOutlineView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/25/07.
/*
 This software is Copyright (c) 2007-2009
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

#import "SKTocOutlineView.h"
#import "SKTypeSelectHelper.h"
#import "NSColor_SKExtensions.h"


@implementation SKTocOutlineView

+ (BOOL)usesDefaultFontSize { return YES; }

- (void)dealloc {
    SKDESTROY(trackingAreas);
    [super dealloc];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
    if ([[self delegate] respondsToSelector:@selector(outlineViewHighlightedRows:)]) {
        NSColor *color = nil;
        NSInteger row;
        NSRect rect;
        
        switch ([self selectionHighlightStyle]) {
            case NSTableViewSelectionHighlightStyleSourceList:
                if ([[self window] isKeyWindow] && [[self window] firstResponder] == self)
                    color = [NSColor keySourceListHighlightColor];
                else if ([[self window] isMainWindow] || [[self window] isKeyWindow])
                    color = [NSColor mainSourceListHighlightColor];
                else
                    color = [NSColor disabledSourceListHighlightColor];
                break;
            case NSTableViewSelectionHighlightStyleRegular:
                if ([[self window] isKeyWindow] && [[self window] firstResponder] == self)
                    color = [NSColor selectedControlColor];
                else
                    color = [NSColor secondarySelectedControlColor];
                break;
            default:
                break;
        }
        
        if (color) {
            [NSGraphicsContext saveGraphicsState];
            
            NSMutableIndexSet *rowIndexes = [[[self selectedRowIndexes] mutableCopy] autorelease];
            NSArray *rows = [[self delegate] outlineViewHighlightedRows:self];
            NSInteger i, count = MIN((NSInteger)[rows count], 5);
            
            for (i = 0; i < count; i++) {
                row = [[rows objectAtIndex:i] integerValue];
                rect = [self rectOfRow:row];
                if (NSIntersectsRect(rect, clipRect) && [rowIndexes containsIndex:row] == NO) {
                    [[color colorWithAlphaComponent:0.5 - 0.1 * i] setFill];
                    [NSBezierPath fillRect:rect];
                }
                [rowIndexes addIndex:row];
            }
            
            [NSGraphicsContext restoreGraphicsState];
        }
    }
    
    [super highlightSelectionInClipRect:clipRect];
}

- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extendSelection {
    [super selectRowIndexes:indexes byExtendingSelection:extendSelection];
    [self setNeedsDisplay:YES];
}

- (void)deselectRow:(NSInteger)row {
    [super deselectRow:row];
    [self setNeedsDisplay:YES];
}

- (BOOL)becomeFirstResponder {
    if ([super becomeFirstResponder]) {
        [self setNeedsDisplay:YES];
        return YES;
    }
    return NO;
}

- (BOOL)resignFirstResponder {
    if ([super resignFirstResponder]) {
        [self setNeedsDisplay:YES];
        return YES;
    }
    return NO;
}

- (void)removeTrackingAreas {
    for (NSTrackingArea *area in trackingAreas)
        [self removeTrackingArea:area];
    [trackingAreas removeAllObjects];
}

- (void)rebuildTrackingAreas {
    if ([[self delegate] respondsToSelector:@selector(outlineView:shouldTrackTableColumn:item:)] == NO)
        return;
    
    if (trackingAreas == nil)
        trackingAreas = [[NSMutableArray alloc] init];
    else
        [self removeTrackingAreas];
    
    if ([self window]) {
        NSRange rowRange = [self rowsInRect:[self visibleRect]];
        NSIndexSet *columnIndexes = [self columnIndexesInRect:[self visibleRect]];
        NSUInteger row, column = [columnIndexes firstIndex];
        NSTableColumn *tableColumn;
        NSDictionary *userInfo;
        NSRect rect;
        NSTrackingArea *area;
        
        while (column != NSNotFound) {
            tableColumn = [[self tableColumns] objectAtIndex:column];
            for (row = rowRange.location; row < NSMaxRange(rowRange); row++) {
                if ([[self delegate] outlineView:self shouldTrackTableColumn:tableColumn item:[self itemAtRow:row]]) {
                    userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInteger:column], @"column", [NSNumber numberWithInteger:row], @"row", nil];
                    rect = [self frameOfCellAtColumn:column row:row];
                    area = [[NSTrackingArea alloc] initWithRect:rect options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:userInfo];
                    [self addTrackingArea:area];
                    [trackingAreas addObject:area];
                    [area release];
                    [userInfo release];
                }
            }
            column = [columnIndexes indexGreaterThanIndex:column];
        }
    }
}

- (void)expandItem:(id)item expandChildren:(BOOL)collapseChildren {
    // NSOutlineView does not call resetCursorRect when expanding
    [super expandItem:item expandChildren:collapseChildren];
	[self rebuildTrackingAreas];
}

- (void)collapseItem:(id)item collapseChildren:(BOOL)collapseChildren {
    // NSOutlineView does not call resetCursorRect when collapsing
    [super collapseItem:item collapseChildren:collapseChildren];
	[self rebuildTrackingAreas];
}

- (void)reloadData{
    [super reloadData];
	[self rebuildTrackingAreas];
}

- (void)updateTrackingAreas {
	[super updateTrackingAreas];
    [self rebuildTrackingAreas];
}

- (void)setDataSource:(id)anObject {
	[super setDataSource:anObject];
	[self rebuildTrackingAreas];
}

- (void)noteNumberOfRowsChanged {
	[super noteNumberOfRowsChanged];
	[self rebuildTrackingAreas];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    if ([self window])
        [self removeTrackingAreas];
}

- (void)viewDidMoveToWindow {
	if ([self window])
        [self rebuildTrackingAreas];
}

- (void)mouseEntered:(NSEvent *)theEvent{
    if ([[self delegate] respondsToSelector:@selector(outlineView:mouseEnteredTableColumn:item:)]) {
        NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
		NSInteger column = [[userInfo valueForKey:@"column"] integerValue];
		NSInteger row = [[userInfo valueForKey:@"row"] integerValue];
        if (userInfo && column != -1 && row != -1) {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
            [[self delegate] outlineView:self mouseEnteredTableColumn:tableColumn item:[self itemAtRow:row]];
        }
	}
}

- (void)mouseExited:(NSEvent *)theEvent{
    if ([[self delegate] respondsToSelector:@selector(outlineView:mouseExitedTableColumn:item:)]) {
        NSDictionary *userInfo = [[theEvent trackingArea] userInfo];
		NSInteger column = [[userInfo valueForKey:@"column"] integerValue];
		NSInteger row = [[userInfo valueForKey:@"row"] integerValue];
        if (userInfo && column != -1 && row != -1) {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
            [[self delegate] outlineView:self mouseExitedTableColumn:tableColumn item:[self itemAtRow:row]];
        }
	}
}

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
- (id <SKTocOutlineViewDelegate>)delegate {
    return (id <SKTocOutlineViewDelegate>)[super delegate];
}

- (void)setDelegate:(id <SKTocOutlineViewDelegate>)newDelegate {
    [super setDelegate:newDelegate];
}
#endif

@end
