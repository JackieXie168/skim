//
//  SKTocOutlineView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/25/07.
/*
 This software is Copyright (c) 2007-2010
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
#import "SKPDFToolTipWindow.h"


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

- (void)addTrackingAreaForColumn:(NSInteger)column row:(NSInteger)row {
    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInteger:row], @"row", [NSNumber numberWithInteger:column], @"column", nil];
    NSRect rect = column == -1 ? [self rectOfRow:row] : [self frameOfCellAtColumn:column row:row];
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:rect options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp owner:self userInfo:userInfo];
    [self addTrackingArea:area];
    [trackingAreas addObject:area];
    [area release];
    [userInfo release];
}

- (void)rebuildTrackingAreas {
    if ([[self delegate] respondsToSelector:@selector(outlineView:PDFContextForTableColumn:item:)] == NO)
        return;
    
    if (trackingAreas == nil)
        trackingAreas = [[NSMutableSet alloc] init];
    else
        [self removeTrackingAreas];
    
    if ([self window]) {
        NSRect visibleRect = [self visibleRect];
        NSRange rowRange = [self rowsInRect:visibleRect];
        NSIndexSet *columnIndexes = [self columnIndexesInRect:visibleRect];
        NSUInteger row, column;
        NSTableColumn *tableColumn;
        id item;
        
        for (row = rowRange.location; row < NSMaxRange(rowRange); row++) {
            item = [self itemAtRow:row];
            if ([[self delegate] outlineView:self hasPDFContextForTableColumn:nil item:item]) {
                [self addTrackingAreaForColumn:-1 row:row];
            } else {
                column = [columnIndexes firstIndex];
                while (column != NSNotFound) {
                    tableColumn = [[self tableColumns] objectAtIndex:column];
                    if ([[self delegate] outlineView:self hasPDFContextForTableColumn:tableColumn item:item])
                        [self addTrackingAreaForColumn:column row:row];
                    column = [columnIndexes indexGreaterThanIndex:column];
                }
            }
        }
    }
}

- (void)reloadData {
    [super reloadData];
	[self rebuildTrackingAreas];
}

- (void)updateTrackingAreas {
	[super updateTrackingAreas];
    [self rebuildTrackingAreas];
}

- (void)noteNumberOfRowsChanged {
	[super noteNumberOfRowsChanged];
	[self rebuildTrackingAreas];
}

- (void)mouseEntered:(NSEvent *)theEvent{
    NSDictionary *userInfo = [theEvent userData];
    NSNumber *columnNumber = [userInfo objectForKey:@"column"];
    NSNumber *rowNumber = [userInfo objectForKey:@"row"];
    if (columnNumber && rowNumber) {
        NSInteger column = [columnNumber integerValue];
        id item = [self itemAtRow:[rowNumber integerValue]];
        NSTableColumn *tableColumn = (columnNumber == nil || column == -1) ? nil : [[self tableColumns] objectAtIndex:column];
        id context = [[self delegate] outlineView:self PDFContextForTableColumn:tableColumn item:item];
        if (context)
            [[SKPDFToolTipWindow sharedToolTipWindow] showForPDFContext:context atPoint:NSZeroPoint];
    }
}

- (void)mouseExited:(NSEvent *)theEvent{
    NSDictionary *userInfo = [theEvent userData];
    NSNumber *columnNumber = [userInfo objectForKey:@"column"];
    NSNumber *rowNumber = [userInfo objectForKey:@"row"];
    if (columnNumber && rowNumber)
        [[SKPDFToolTipWindow sharedToolTipWindow] fadeOut];
}

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
- (id <SKTocOutlineViewDelegate>)delegate {
    return (id <SKTocOutlineViewDelegate>)[super delegate];
}

- (void)setDelegate:(id <SKTocOutlineViewDelegate>)newDelegate {
    [super setDelegate:newDelegate];
	[self rebuildTrackingAreas];
}
#else
- (void)setDelegate:(id)newDelegate {
    [super setDelegate:newDelegate];
	[self rebuildTrackingAreas];
}
#endif

@end
