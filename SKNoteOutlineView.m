//
//  SKNoteOutlineView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/25/07.
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

#import "SKNoteOutlineView.h"
#import "NSString_SKExtensions.h"
#import "SKTypeSelectHelper.h"
#import "PDFAnnotation_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSEvent_SKExtensions.h"
#import "NSMenu_SKExtensions.h"


@implementation SKNoteOutlineView

- (void)dealloc {
    [noteTypeSheet release];
    [super dealloc];
}

- (void)awakeFromNib {
    [self noteTypeMenu]; // this sets the menu for the header view
    NSNumber *fontSize = [[NSUserDefaults standardUserDefaults] objectForKey:SKTableFontSizeKey];
    if (fontSize)
        [self setFont:[NSFont systemFontOfSize:[fontSize floatValue]]];
}

- (BOOL)resizeRow:(int)row withEvent:(NSEvent *)theEvent {
    id item = [self itemAtRow:row];
    NSPoint startPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    float startHeight = [[self delegate] outlineView:self heightOfRowByItem:item];
	BOOL keepGoing = YES;
    BOOL dragged = NO;
	
    [[NSCursor resizeUpDownCursor] push];
    
	while (keepGoing) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
            {
                NSPoint currentPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
                float currentHeight = fmaxf([self rowHeight], startHeight + currentPoint.y - startPoint.y);
                
                [[self delegate] outlineView:self setHeightOfRow:currentHeight byItem:item];
                [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
                
                dragged = YES;
                
                break;
			}
            
            case NSLeftMouseUp:
                keepGoing = NO;
                break;
			
            default:
                break;
        }
    }
    [NSCursor pop];
    
    return dragged;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if ([[self delegate] respondsToSelector:@selector(outlineView:canResizeRowByItem:)] && [[self delegate] respondsToSelector:@selector(outlineView:setHeightOfRow:byItem:)]) {
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        int row = [self rowAtPoint:mouseLoc];
        
        if (row != -1 && [[self delegate] outlineView:self canResizeRowByItem:[self itemAtRow:row]]) {
            NSRect ignored, rect = [self rectOfRow:row];
            NSDivideRect(rect, &rect, &ignored, 5.0, [self isFlipped] ? NSMaxYEdge : NSMinYEdge);
            if (NSPointInRect(mouseLoc, rect) && [self resizeRow:row withEvent:theEvent])
                return;
        }
    }
    [super mouseDown:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent {
    unichar eventChar = [theEvent firstCharacter];
	unsigned modifiers = [theEvent standardModifierFlags];
    
    if ((eventChar == NSNewlineCharacter || eventChar == NSEnterCharacter || eventChar == NSCarriageReturnCharacter) && modifiers == 0) {
        if ([[self delegate] respondsToSelector:@selector(outlineViewInsertNewline:)])
            [[self delegate] outlineViewInsertNewline:self];
        else NSBeep();
    } else {
        [super keyDown:theEvent];
        if ((eventChar == NSDownArrowFunctionKey || eventChar == NSUpArrowFunctionKey) && modifiers == NSCommandKeyMask &&
            [[self delegate] respondsToSelector:@selector(outlineViewCommandKeyPressedDuringNavigation:)]) {
            [[self delegate] outlineViewCommandKeyPressedDuringNavigation:self];
        }
    }
}

- (void)drawRect:(NSRect)aRect {
    [super drawRect:aRect];
    if ([[self delegate] respondsToSelector:@selector(outlineView:canResizeRowByItem:)]) {
        NSRange visibleRows = [self rowsInRect:[self visibleRect]];
        
        if (visibleRows.length == 0)
            return;
        
        unsigned int row;
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
            float x = ceilf(NSMidX(rect));
            float y = NSMaxY(rect) - 1.5;
            
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
    [self resetCursorRects];
}

- (void)collapseItem:(id)item collapseChildren:(BOOL)collapseChildren {
    // NSOutlineView does not call resetCursorRect when collapsing
    [super collapseItem:item collapseChildren:collapseChildren];
    [self resetCursorRects];
}

-(void)resetCursorRects {
    if ([[self delegate] respondsToSelector:@selector(outlineView:canResizeRowByItem:)]) {
        [self discardCursorRects];
        [super resetCursorRects];

        NSRange visibleRows = [self rowsInRect:[self visibleRect]];
        unsigned int row;
        
        if (visibleRows.length == 0)
            return;
        
        for (row = visibleRows.location; row < NSMaxRange(visibleRows); row++) {
            id item = [self itemAtRow:row];
            if ([[self delegate] outlineView:self canResizeRowByItem:item] == NO)
                continue;
            NSRect ignored, rect = [self rectOfRow:row];
            NSDivideRect(rect, &rect, &ignored, 5.0, [self isFlipped] ? NSMaxYEdge : NSMinYEdge);
            [self addCursorRect:rect cursor:[NSCursor resizeUpDownCursor]];
        }
    } else {
        [super resetCursorRects];
    }
}

#pragma mark Note Types

- (NSMenu *)noteTypeMenu {
    NSMenu *menu = [[self headerView] menu];
    
    if (menu == nil) {
        menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
        NSMenuItem *menuItem = nil;
        menuItem = [menu addItemWithTitle:[SKFreeTextString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKFreeTextString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKNoteString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setState:NSOnState];
        [menuItem setRepresentedObject:SKNoteString];
        menuItem = [menu addItemWithTitle:[SKCircleString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKCircleString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKSquareString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKSquareString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKHighlightString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKHighlightString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKUnderlineString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKUnderlineString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKStrikeOutString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKStrikeOutString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKLineString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKLineString];
        [menuItem setState:NSOnState];
        [menu addItem:[NSMenuItem separatorItem]];
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Show All", @"Menu item title") action:@selector(displayAllNoteTypes:) target:self];
        menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Select", @"Menu item title") stringByAppendingEllipsis] action:@selector(selectNoteTypes:) target:self];
        [[self headerView] setMenu:menu];
    }
    
    return menu;
}

- (NSArray *)noteTypes {
    NSMutableArray *types = [NSMutableArray array];
    NSMenu *menu = [self noteTypeMenu];
    int i;
    
    for (i = 0; i < 8; i++) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if ([item state] == NSOnState)
            [types addObject:[item representedObject]];
    }
    return types;
}

- (void)setNoteTypes:(NSArray *)types {
    NSMenu *menu = [self noteTypeMenu];
    int i;
    
    for (i = 0; i < 8; i++) {
        NSMenuItem *item = [menu itemAtIndex:i];
        [item setState:[types containsObject:[item representedObject]] ? NSOnState : NSOffState];
    }
}

- (void)noteTypesUpdated {
    if ([[self delegate] respondsToSelector:@selector(outlineViewNoteTypesDidChange:)])
        [[self delegate] outlineViewNoteTypesDidChange:self];
}

- (IBAction)toggleDisplayNoteType:(id)sender {
    [sender setState:![sender state]];
    [self noteTypesUpdated];
}

- (IBAction)displayAllNoteTypes:(id)sender {
    NSMenu *menu = [self noteTypeMenu];
    int i;
    for (i = 0; i < 8; i++)
        [[menu itemAtIndex:i] setState:NSOnState];
    [self noteTypesUpdated];
}

- (void)noteTypeSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        NSMenu *menu = [self noteTypeMenu];
        int i;
        for (i = 0; i < 8; i++)
            [[menu itemAtIndex:i] setState:[[noteTypeMatrix cellAtRow:i % 4 column:i / 4] state]];
        [self noteTypesUpdated];
    }
}

- (IBAction)selectNoteTypes:(id)sender {
    if (noteTypeSheet == nil && NO == [NSBundle loadNibNamed:@"NoteTypeSheet" owner:self]) {
        NSLog(@"Failed to load NoteTypeSheet.nib");
        return;
    }
    
    NSMenu *menu = [self noteTypeMenu];
    int i;
    for (i = 0; i < 8; i++)
        [[noteTypeMatrix cellAtRow:i % 4 column:i / 4] setState:[[menu itemAtIndex:i] state]];
	
    [NSApp beginSheet:noteTypeSheet
       modalForWindow:[[self delegate] respondsToSelector:@selector(window)] ? [[self delegate] window] : [self window]
        modalDelegate:self 
       didEndSelector:@selector(noteTypeSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)dismissNoteTypeSheet:(id)sender {
    [NSApp endSheet:noteTypeSheet returnCode:[sender tag]];
    [noteTypeSheet orderOut:self];
}

@end
