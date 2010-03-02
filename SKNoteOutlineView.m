//
//  SKNoteOutlineView.m
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

#import "SKNoteOutlineView.h"
#import "NSString_SKExtensions.h"
#import "SKTypeSelectHelper.h"
#import <SkimNotes/SkimNotes.h>
#import "NSEvent_SKExtensions.h"
#import "NSMenu_SKExtensions.h"

#define NUMBER_OF_TYPES 9

@implementation SKNoteOutlineView

+ (BOOL)usesDefaultFontSize { return YES; }

- (void)dealloc {
    SKDESTROY(noteTypeSheet);
    [super dealloc];
}

- (void)awakeFromNib {
    if (noteTypeMatrix == nil) {
        [self noteTypeMenu]; // this sets the menu for the header view
        [super awakeFromNib];
    }
}

- (void)resizeRow:(NSInteger)row withEvent:(NSEvent *)theEvent {
    id item = [self itemAtRow:row];
    NSPoint startPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    CGFloat startHeight = [[self delegate] outlineView:self heightOfRowByItem:item];
	BOOL keepGoing = YES;
	
    [[NSCursor resizeUpDownCursor] push];
    
	while (keepGoing) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
            {
                NSPoint currentPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
                CGFloat currentHeight = fmax([self rowHeight], startHeight + currentPoint.y - startPoint.y);
                
                [[self delegate] outlineView:self setHeightOfRow:currentHeight byItem:item];
                [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
                
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
}

- (void)mouseDown:(NSEvent *)theEvent {
    if ([theEvent clickCount] == 1 && [[self delegate] respondsToSelector:@selector(outlineView:canResizeRowByItem:)] && [[self delegate] respondsToSelector:@selector(outlineView:setHeightOfRow:byItem:)]) {
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSInteger row = [self rowAtPoint:mouseLoc];
        
        if (row != -1 && [[self delegate] outlineView:self canResizeRowByItem:[self itemAtRow:row]]) {
            NSRect ignored, rect;
            NSDivideRect([self rectOfRow:row], &rect, &ignored, 5.0, [self isFlipped] ? NSMaxYEdge : NSMinYEdge);
            if (NSMouseInRect(mouseLoc, rect, [self isFlipped]) && NSLeftMouseDragged == [[NSApp nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask) untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:NO] type]) {
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

-(void)resetCursorRects {
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
            NSRect ignored, rect = [self rectOfRow:row];
            NSDivideRect(rect, &rect, &ignored, 5.0, [self isFlipped] ? NSMaxYEdge : NSMinYEdge);
            [self addCursorRect:rect cursor:[NSCursor resizeUpDownCursor]];
        }
    } else {
        [super resetCursorRects];
    }
}

- (NSPredicate *)filterPredicateForSearchString:(NSString *)searchString caseInsensitive:(BOOL)caseInsensitive {
    NSPredicate *filterPredicate = nil;
    NSPredicate *typePredicate = nil;
    NSPredicate *searchPredicate = nil;
    NSArray *types = [self noteTypes];
    if ([types count] < NUMBER_OF_TYPES) {
        NSExpression *lhs = [NSExpression expressionForKeyPath:@"type"];
        NSMutableArray *predicateArray = [NSMutableArray array];
        
        for (NSString *type in types) {
            NSExpression *rhs = [NSExpression expressionForConstantValue:type];
            NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];
            [predicateArray addObject:predicate];
        }
        typePredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
    }
    if (searchString && [searchString isEqualToString:@""] == NO) {
        NSExpression *lhs = [NSExpression expressionForConstantValue:searchString];
        NSExpression *rhs = [NSExpression expressionForKeyPath:@"string"];
        NSUInteger options = NSDiacriticInsensitivePredicateOption;
        if (caseInsensitive)
            options |= NSCaseInsensitivePredicateOption;
        NSPredicate *stringPredicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:options];
        rhs = [NSExpression expressionForKeyPath:@"text.string"];
        NSPredicate *textPredicate = [NSComparisonPredicate predicateWithLeftExpression:lhs rightExpression:rhs modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType options:options];
        searchPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:stringPredicate, textPredicate, nil]];
    }
    if (typePredicate) {
        if (searchPredicate)
            filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:typePredicate, searchPredicate, nil]];
        else
            filterPredicate = typePredicate;
    } else if (searchPredicate) {
        filterPredicate = searchPredicate;
    }
    return filterPredicate;
}

#pragma mark Note Types

- (NSMenu *)noteTypeMenu {
    NSMenu *menu = [[self headerView] menu];
    
    if (menu == nil) {
        menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
        NSMenuItem *menuItem = nil;
        menuItem = [menu addItemWithTitle:[SKNFreeTextString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNFreeTextString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKNNoteString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setState:NSOnState];
        [menuItem setRepresentedObject:SKNNoteString];
        menuItem = [menu addItemWithTitle:[SKNCircleString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNCircleString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKNSquareString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNSquareString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKNHighlightString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNHighlightString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKNUnderlineString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNUnderlineString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKNStrikeOutString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNStrikeOutString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKNLineString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNLineString];
        [menuItem setState:NSOnState];
        menuItem = [menu addItemWithTitle:[SKNInkString typeName] action:@selector(toggleDisplayNoteType:) target:self];
        [menuItem setRepresentedObject:SKNInkString];
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
    NSInteger i;
    
    for (i = 0; i < NUMBER_OF_TYPES; i++) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if ([item state] == NSOnState)
            [types addObject:[item representedObject]];
    }
    return types;
}

- (void)setNoteTypes:(NSArray *)types {
    NSMenu *menu = [self noteTypeMenu];
    NSInteger i;
    
    for (i = 0; i < NUMBER_OF_TYPES; i++) {
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
    NSInteger i;
    for (i = 0; i < NUMBER_OF_TYPES; i++)
        [[menu itemAtIndex:i] setState:NSOnState];
    [self noteTypesUpdated];
}

- (void)noteTypeSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        NSMenu *menu = [self noteTypeMenu];
        NSInteger i;
        for (i = 0; i < NUMBER_OF_TYPES; i++)
            [[menu itemAtIndex:i] setState:[[noteTypeMatrix cellWithTag:i] state]];
        [self noteTypesUpdated];
    }
}

- (IBAction)selectNoteTypes:(id)sender {
    if (noteTypeSheet == nil && NO == [NSBundle loadNibNamed:@"NoteTypeSheet" owner:self]) {
        NSLog(@"Failed to load NoteTypeSheet.nib");
        return;
    }
    
    NSMenu *menu = [self noteTypeMenu];
    NSInteger i;
    for (i = 0; i < NUMBER_OF_TYPES; i++)
        [[noteTypeMatrix cellWithTag:i] setState:[[menu itemAtIndex:i] state]];
	
    [NSApp beginSheet:noteTypeSheet
       modalForWindow:[[self delegate] respondsToSelector:@selector(outlineViewWindowForSheet:)] ? [[self delegate] outlineViewWindowForSheet:self] : [self window]
        modalDelegate:self 
       didEndSelector:@selector(noteTypeSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)dismissNoteTypeSheet:(id)sender {
    [NSApp endSheet:noteTypeSheet returnCode:[sender tag]];
    [noteTypeSheet orderOut:self];
}


#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
- (id <SKNoteOutlineViewDelegate>)delegate {
    return (id <SKNoteOutlineViewDelegate>)[super delegate];
}

- (void)setDelegate:(id <SKNoteOutlineViewDelegate>)newDelegate {
    [super setDelegate:newDelegate];
}
#endif

@end
