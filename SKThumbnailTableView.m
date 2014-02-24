//
//  SKThumbnailTableView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/25/07.
/*
 This software is Copyright (c) 2007-2014
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
#import "SKTypeSelectHelper.h"
#import "NSColor_SKExtensions.h"
#import "NSEvent_SKExtensions.h"

#define SKScrollerWillScrollNotification @"SKScrollerWillScrollNotification"
#define SKScrollerDidScrollNotification @"SKScrollerDidScrollNotification"

#define MAX_HIGHLIGHTS 5

@implementation SKThumbnailTableView

@synthesize isScrolling;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
    if ([[self delegate] respondsToSelector:@selector(tableViewHighlightedRows:)]) {
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
                    color = [NSColor alternateSelectedControlColor];
                else
                    color = [NSColor secondarySelectedControlColor];
                break;
            default:
                break;
        }
        
        if (color) {
            [NSGraphicsContext saveGraphicsState];
            
            NSMutableIndexSet *rowIndexes = [[[self selectedRowIndexes] mutableCopy] autorelease];
            NSPointerArray *rows = [[self delegate] tableViewHighlightedRows:self];
            NSInteger i, count = MIN((NSInteger)[rows count], MAX_HIGHLIGHTS);
            
            for (i = 0; i < count; i++) {
                row = (NSInteger)[rows pointerAtIndex:i];
                rect = [self rectOfRow:row];
                if (NSIntersectsRect(rect, clipRect) && [rowIndexes containsIndex:row] == NO) {
                    [[color colorWithAlphaComponent:0.1 * (MAX_HIGHLIGHTS - i)] setFill];
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

- (void)handleScrollerWillScroll:(NSNotification *)note {
    isScrolling = YES;
}

- (void)handleScrollerDidScroll:(NSNotification *)note {
    isScrolling = NO;
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (void)awakeFromNib {
    NSScroller *scroller = [[self enclosingScrollView] verticalScroller];
    if ([scroller isKindOfClass:[SKScroller class]]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScrollerWillScroll:)
                                                     name:SKScrollerWillScrollNotification object:scroller];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScrollerDidScroll:)
                                                     name:SKScrollerDidScrollNotification object:scroller];
    }
}

- (void)setFrame:(NSRect)frameRect {
    BOOL changed = fabs(NSWidth([self frame]) - NSWidth(frameRect)) > 0.0;
    [super setFrame:frameRect];
    if (changed && [[self delegate] respondsToSelector:@selector(tableView:heightOfRow:)])
        [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}

- (void)setFrameSize:(NSSize)frameSize {
    BOOL changed = fabs(NSWidth([self frame]) - frameSize.width) > 0.0;
    [super setFrameSize:frameSize];
    if (changed && [[self delegate] respondsToSelector:@selector(tableView:heightOfRow:)])
        [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (([theEvent modifierFlags] & NSCommandKeyMask) && [[self delegate] respondsToSelector:@selector(tableView:commandSelectRow:)]) {
        NSInteger row = [self rowAtPoint:[theEvent locationInView:self]];
        if (row != -1 && [[self delegate] tableView:self commandSelectRow:row])
            return;
    }
    [super mouseDown:theEvent];
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset{
   	return [super dragImageForRowsWithIndexes:dragRows tableColumns:[[self tableColumns] subarrayWithRange:NSMakeRange(0, 1)] event:dragEvent offset:dragImageOffset];
}

- (id <SKThumbnailTableViewDelegate>)delegate { return (id <SKThumbnailTableViewDelegate>)[super delegate]; }
- (void)setDelegate:(id <SKThumbnailTableViewDelegate>)newDelegate { [super setDelegate:newDelegate]; }

@end

#pragma mark -

@implementation SKScroller

- (void)trackKnob:(NSEvent *)theEvent {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKScrollerWillScrollNotification object:self];
    [super trackKnob:theEvent];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKScrollerDidScrollNotification object:self];
}

@end
