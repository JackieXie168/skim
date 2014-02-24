//
//  SKNoteOutlineView.m
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

#import "SKNoteOutlineView.h"
#import "SKTypeSelectHelper.h"
#import "NSEvent_SKExtensions.h"
#import "SKColorCell.h"
#import "SKApplication.h"
#import "NSGeometry_SKExtensions.h"
#import "NSMenu_SKExtensions.h"

#define NUMBER_OF_TYPES 9

#define PAGE_COLUMNID   @"page"
#define NOTE_COLUMNID   @"note"
#define TYPE_COLUMNID   @"type"
#define COLOR_COLUMNID  @"color"
#define AUTHOR_COLUMNID @"author"
#define DATE_COLUMNID   @"date"

#define SMALL_COLUMN_WIDTH 32.0

#define RESIZE_EDGE_HEIGHT 5.0

@interface SKNoteOutlineView (SKPrivate)
@end

@implementation SKNoteOutlineView

static inline NSString *titleForTableColumnIdentifier(NSString *identifier) {
    if ([identifier isEqualToString:NOTE_COLUMNID])
        return NSLocalizedString(@"Note", @"Table header title");
    else if ([identifier isEqualToString:TYPE_COLUMNID])
        return NSLocalizedString(@"Type", @"Table header title");
    else if ([identifier isEqualToString:COLOR_COLUMNID])
        return NSLocalizedString(@"Color", @"Table header title");
    else if ([identifier isEqualToString:PAGE_COLUMNID])
        return NSLocalizedString(@"Page", @"Table header title");
    else if ([identifier isEqualToString:AUTHOR_COLUMNID])
        return NSLocalizedString(@"Author", @"Table header title");
    else if ([identifier isEqualToString:DATE_COLUMNID])
        return NSLocalizedString(@"Date", @"Table header title");
    else
        return nil;
}

- (void)awakeFromNib {
    [[self tableColumnWithIdentifier:COLOR_COLUMNID] setDataCell:[[[SKColorCell alloc] init] autorelease]];
    
    NSMenu *menu = [NSMenu menu];
    
    for (NSTableColumn *tc in [self tableColumns]) {
        NSString *identifier = [tc identifier];
        NSString *title = titleForTableColumnIdentifier(identifier);
        NSMenuItem *menuItem = [menu addItemWithTitle:title action:@selector(toggleTableColumn:) target:self];
        [menuItem setRepresentedObject:identifier];
        if ([tc maxWidth] >= SMALL_COLUMN_WIDTH)
            [[tc headerCell] setTitle:title];
    }
    
    [[self headerView] setMenu:menu];
}

- (void)resizeRow:(NSInteger)row withEvent:(NSEvent *)theEvent {
    id item = [self itemAtRow:row];
    NSPoint startPoint = [theEvent locationInView:self];
    CGFloat startHeight = [[self delegate] outlineView:self heightOfRowByItem:item];
	
    [[NSCursor resizeUpDownCursor] push];
    
	while ([theEvent type] != NSLeftMouseUp) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		if ([theEvent type] == NSLeftMouseDragged) {
            NSPoint currentPoint = [theEvent locationInView:self];
            CGFloat currentHeight = fmax([self rowHeight], startHeight + currentPoint.y - startPoint.y);
            
            [[self delegate] outlineView:self setHeight:currentHeight ofRowByItem:item];
            [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
        }
    }
    [NSCursor pop];
}

- (void)mouseDown:(NSEvent *)theEvent {
    if ([theEvent clickCount] == 1 && [[self delegate] respondsToSelector:@selector(outlineView:canResizeRowByItem:)] && [[self delegate] respondsToSelector:@selector(outlineView:setHeight:ofRowByItem:)]) {
        NSPoint mouseLoc = [theEvent locationInView:self];
        NSInteger row = [self rowAtPoint:mouseLoc];
        
        if (row != -1 && [[self delegate] outlineView:self canResizeRowByItem:[self itemAtRow:row]]) {
            NSRect rect = SKSliceRect([self rectOfRow:row], RESIZE_EDGE_HEIGHT, [self isFlipped] ? NSMaxYEdge : NSMinYEdge);
            if (NSMouseInRect(mouseLoc, rect, [self isFlipped]) && [NSApp willDragMouse]) {
                [self resizeRow:row withEvent:theEvent];
                return;
            }
        }
    }
    [super mouseDown:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent {
    unichar eventChar = [theEvent firstCharacter];
	NSUInteger modifiers = [theEvent standardModifierFlags];
    
    [super keyDown:theEvent];
    
    if ((eventChar == NSDownArrowFunctionKey || eventChar == NSUpArrowFunctionKey) && modifiers == NSCommandKeyMask &&
        [[self delegate] respondsToSelector:@selector(outlineViewCommandKeyPressedDuringNavigation:)]) {
        [[self delegate] outlineViewCommandKeyPressedDuringNavigation:self];
    }
}

- (void)drawRect:(NSRect)aRect {
    [super drawRect:aRect];
    if ([[self delegate] respondsToSelector:@selector(outlineView:canResizeRowByItem:)]) {
        NSRange visibleRows = [self rowsInRect:aRect];
        
        if (visibleRows.length == 0)
            return;
        
        NSUInteger row;
        BOOL isFirstResponder = [[self window] isKeyWindow] && [[self window] firstResponder] == self;
        
        [NSGraphicsContext saveGraphicsState];
        [NSBezierPath setDefaultLineWidth:1.0];
        
        for (row = visibleRows.location; row < NSMaxRange(visibleRows); row++) {
            id item = [self itemAtRow:row];
            if ([[self delegate] outlineView:self canResizeRowByItem:item] == NO)
                continue;
            
            BOOL isHighlighted = isFirstResponder && [self isRowSelected:row];
            NSColor *color = [NSColor colorWithCalibratedWhite:isHighlighted ? 1.0 : 0.5 alpha:0.7];
            NSRect rect = [self rectOfRow:row];
            CGFloat x = ceil(NSMidX(rect));
            CGFloat y = NSMaxY(rect) - 1.5;
            
            [color set];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(x - 1.0, y) toPoint:NSMakePoint(x + 1.0, y)];
            y -= 2.0;
            [NSBezierPath strokeLineFromPoint:NSMakePoint(x - 3.0, y) toPoint:NSMakePoint(x + 3.0, y)];
        }
        
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)expandItem:(id)item expandChildren:(BOOL)collapseChildren {
    // NSOutlineView does not call resetCursorRect when expanding
    [super expandItem:item expandChildren:collapseChildren];
    [[self window] invalidateCursorRectsForView:self];
}

- (void)collapseItem:(id)item collapseChildren:(BOOL)collapseChildren {
    // NSOutlineView does not call resetCursorRect when collapsing
    [super collapseItem:item collapseChildren:collapseChildren];
    [[self window] invalidateCursorRectsForView:self];
}

- (void)resetCursorRects {
    if ([[self delegate] respondsToSelector:@selector(outlineView:canResizeRowByItem:)]) {
        [self discardCursorRects];
        [super resetCursorRects];

        NSRange visibleRows = [self rowsInRect:[self visibleRect]];
        NSUInteger row;
        
        if (visibleRows.length == 0)
            return;
        
        for (row = visibleRows.location; row < NSMaxRange(visibleRows); row++) {
            id item = [self itemAtRow:row];
            if ([[self delegate] outlineView:self canResizeRowByItem:item] == NO)
                continue;
            [self addCursorRect:SKSliceRect([self rectOfRow:row], RESIZE_EDGE_HEIGHT, [self isFlipped] ? NSMaxYEdge : NSMinYEdge) cursor:[NSCursor resizeUpDownCursor]];
        }
    } else {
        [super resetCursorRects];
    }
}

- (void)toggleTableColumn:(id)sender {
    NSTableColumn *tc = [self tableColumnWithIdentifier:[sender representedObject]];
    [tc setHidden:[tc isHidden] == NO];
    if ([self outlineTableColumn] == tc && [tc isHidden])
        [self collapseItem:nil collapseChildren:YES];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(toggleTableColumn:)) {
        [menuItem setState:[[self tableColumnWithIdentifier:[menuItem representedObject]] isHidden] ? NSOffState : NSOnState];
        return YES;
    } else if ([[SKNoteOutlineView superclass] instancesRespondToSelector:_cmd]) {
        return [super validateMenuItem:menuItem];
    }
    return YES;
}

#pragma mark Delegate

- (id <SKNoteOutlineViewDelegate>)delegate { return (id <SKNoteOutlineViewDelegate>)[super delegate]; }
- (void)setDelegate:(id <SKNoteOutlineViewDelegate>)newDelegate { [super setDelegate:newDelegate]; }

@end
