//
//  SKNoteOutlineView.m
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

#import "SKNoteOutlineView.h"
#import <Quartz/Quartz.h>
#import "NSString_SKExtensions.h"
#import "SKTypeSelectHelper.h"


@implementation SKNoteOutlineView

- (void)dealloc {
    [noteTypeSheet release];
    [super dealloc];
}

- (void)awakeFromNib {
    [self noteTypeMenu]; // this sets the menu for the header view
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
        menuItem = [menu addItemWithTitle:[@"FreeText" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:@"FreeText"];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[@"Note" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setState:NSOnState];
        [menuItem setRepresentedObject:@"Note"];
        menuItem = [menu addItemWithTitle:[@"Circle" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:@"Circle"];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[@"Square" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:@"Square"];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[@"Highlight" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:@"Highlight"];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[@"Underline" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:@"Underline"];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[@"StrikeOut" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:@"StrikeOut"];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[@"Line" typeName] action:@selector(toggleDisplayNoteType:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:@"Line"];
        [menuItem setState:NSOnState];
        [menu addItem:[NSMenuItem separatorItem]];
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Show All", @"Menu item title") action:@selector(displayAllNoteTypes:) keyEquivalent:@""];
        [menuItem setTarget:self];
        menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Select", @"Menu item title") stringByAppendingEllipsis] action:@selector(selectNoteTypes:) keyEquivalent:@""];
        [menuItem setTarget:self];
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
    if (NO == [NSBundle loadNibNamed:@"NoteTypeSheet" owner:self]) {
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

#pragma mark -

@implementation SKAnnotationTypeImageCell

- (void)dealloc {
    [type release];
    [super dealloc];
}

- (void)setObjectValue:(id)anObject {
    if ([anObject respondsToSelector:@selector(objectForKey:)]) {
        NSString *newType = [anObject objectForKey:@"type"];
        if (type != newType) {
            [type release];
            type = [newType retain];
        }
        active = [[anObject objectForKey:@"active"] boolValue];
    } else {
        [super setObjectValue:anObject];
    }
}

static void SKAddNamedAndFilteredImageForKey(NSMutableDictionary *images, NSMutableDictionary *filteredImages, NSString *name, NSString *key, CIFilter *filter)
{
    NSImage *image = [NSImage imageNamed:name];
    NSImage *filteredImage = [[NSImage alloc] initWithSize:[image size]];
    CIImage *ciImage = [CIImage imageWithData:[image TIFFRepresentation]];
    
    [filter setValue:ciImage forKey:@"inputImage"];
    ciImage = [filter valueForKey:@"outputImage"];
    
    CGRect cgRect = [ciImage extent];
    NSRect nsRect = *(NSRect*)&cgRect;
    
    [filteredImage lockFocus];
    [ciImage drawAtPoint:NSZeroPoint fromRect:nsRect operation:NSCompositeCopy fraction:1.0];
    [filteredImage unlockFocus];
    
    [images setObject:image forKey:key];
    [filteredImages setObject:filteredImage forKey:key];
    [filteredImage release];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    static NSMutableDictionary *noteImages = nil;
    static NSMutableDictionary *invertedNoteImages = nil;
    
    if (noteImages == nil) {
        CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
        
        noteImages = [[NSMutableDictionary alloc] initWithCapacity:8];
        invertedNoteImages = [[NSMutableDictionary alloc] initWithCapacity:8];
        
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, @"TextNoteAdorn", @"FreeText", filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, @"AnchoredNoteAdorn", @"Note", filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, @"CircleNoteAdorn", @"Circle", filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, @"SquareNoteAdorn", @"Square", filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, @"HighlightNoteAdorn", @"Highlight", filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, @"UnderlineNoteAdorn", @"Underline", filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, @"StrikeOutNoteAdorn", @"StrikeOut", filter);
        SKAddNamedAndFilteredImageForKey(noteImages, invertedNoteImages, @"LineNoteAdorn", @"Line", filter);
    }
    
    BOOL isSelected = [self isHighlighted] && [[controlView window] isKeyWindow] && [[[controlView window] firstResponder] isEqual:controlView];
    NSImage *image = type ? [(isSelected ? invertedNoteImages : noteImages) objectForKey:type] : nil;
    
    if (active) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        if (isSelected)
            [[NSColor colorWithCalibratedWhite:1.0 alpha:0.8] set];
        else
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.7] set];
        NSRect rect = cellFrame;
        rect.origin.y = floorf(NSMinY(rect) + 0.5 * (NSHeight(cellFrame) - NSWidth(cellFrame)));
        rect.size.height = NSWidth(rect);
        [NSBezierPath strokeRect:NSInsetRect(rect, 0.5, 0.5)];
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
    
    [super setObjectValue:image];
    [super drawWithFrame:cellFrame inView:controlView];
}

@end
