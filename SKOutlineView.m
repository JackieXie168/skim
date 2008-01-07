//
//  SKOutlineView.m
//  Skim
//
//  Created by Christiaan Hofman on 8/22/07.
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

#import "SKOutlineView.h"
#import "SKTypeSelectHelper.h"


@implementation SKOutlineView

- (void)dealloc {
    [typeSelectHelper setDataSource:nil];
    [typeSelectHelper release];
    [super dealloc];
}

- (NSArray *)selectedItems {
    NSMutableArray *items = [NSMutableArray array];
    NSIndexSet *indexes = [self selectedRowIndexes];
    unsigned int index = [indexes firstIndex];
    
    while (index != NSNotFound) {
        [items addObject:[self itemAtRow:index]];
        index = [indexes indexGreaterThanIndex:index];
    }
    return items;
}

- (SKTypeSelectHelper *)typeSelectHelper {
    return typeSelectHelper;
}

- (void)setTypeSelectHelper:(SKTypeSelectHelper *)newTypeSelectHelper {
    if (typeSelectHelper != newTypeSelectHelper) {
        [typeSelectHelper release];
        typeSelectHelper = [newTypeSelectHelper retain];
    }
}

- (void)expandItem:(id)item expandChildren:(BOOL)collapseChildren {
    [super expandItem:item expandChildren:collapseChildren];
    [typeSelectHelper rebuildTypeSelectSearchCache];
}

- (void)collapseItem:(id)item collapseChildren:(BOOL)collapseChildren {
    [super collapseItem:item collapseChildren:collapseChildren];
    [typeSelectHelper rebuildTypeSelectSearchCache];
}

- (void)reloadData{
    [super reloadData];
    [typeSelectHelper rebuildTypeSelectSearchCache];
}

- (void)keyDown:(NSEvent *)theEvent {
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar eventChar = [characters length] > 0 ? [characters characterAtIndex:0] : 0;
	unsigned modifierFlags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    
    if ([typeSelectHelper processKeyDownEvent:theEvent]) {
    } else if (eventChar == NSHomeFunctionKey && (modifierFlags & ~NSFunctionKeyMask) == 0) {
        [self scrollToBeginningOfDocument:nil];
    } else if (eventChar == NSEndFunctionKey && (modifierFlags & ~NSFunctionKeyMask) == 0) {
        [self scrollToEndOfDocument:nil];
	} else if ((eventChar == NSDeleteCharacter || eventChar == NSDeleteFunctionKey) && modifierFlags == 0 && [self canDelete]) {
        [self delete:self];
    } else {
        [super keyDown:theEvent];
    }
}

- (void)scrollToBeginningOfDocument:(id)sender {
    if ([self numberOfRows])
        [self scrollRowToVisible:0];
}

- (void)scrollToEndOfDocument:(id)sender {
    if ([self numberOfRows])
        [self scrollRowToVisible:[self numberOfRows] - 1];
}

- (BOOL)canDelete {
    NSArray *items = [self selectedItems];
    if ([items count] && [[self delegate] respondsToSelector:@selector(outlineView:deleteItems:)]) {
        if ([[self delegate] respondsToSelector:@selector(outlineView:canDeleteItems:)])
           return [[self delegate] outlineView:self canDeleteItems:items];
        else
            return YES;
    }
    return NO;
}

- (void)delete:(id)sender {
    if ([self canDelete])
        [[self delegate] outlineView:self deleteItems:[self selectedItems]];
    else
        NSBeep();
}

- (BOOL)canCopy {
    NSArray *items = [self selectedItems];
    if ([items count] && [[self delegate] respondsToSelector:@selector(outlineView:copyItems:)]) {
        if ([[self delegate] respondsToSelector:@selector(outlineView:canCopyItems:)])
           return [[self delegate] outlineView:self canCopyItems:items];
        else
            return YES;
    }
    return NO;
}

- (void)copy:(id)sender {
    if ([self canCopy])
        [[self delegate] outlineView:self copyItems:[self selectedItems]];
    else
        NSBeep();
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(delete:))
        return [self canDelete];
    else if ([menuItem action] == @selector(copy:))
        return [self canCopy];
    else if ([menuItem action] == @selector(selectAll:))
        return [self allowsMultipleSelection];
    else if ([menuItem action] == @selector(deselectAll:))
        return [self allowsEmptySelection];
    else if ([[SKOutlineView superclass] instancesRespondToSelector:@selector(validateMenuItem:)])
        return [super validateMenuItem:menuItem];
    return YES;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    NSMenu *menu = nil;
    
    if ([[self delegate] respondsToSelector:@selector(outlineView:menuForTableColumn:item:)]) {
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        int row = [self rowAtPoint:mouseLoc];
        int column = [self columnAtPoint:mouseLoc];
        if (row != -1 && column != -1) {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
            menu = [[self delegate] outlineView:self menuForTableColumn:tableColumn item:[self itemAtRow:row]];
        }
    }
    
	return menu;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
    if ([[SKOutlineView superclass] instancesRespondToSelector:_cmd])
        [super draggedImage:anImage endedAt:aPoint operation:operation];
    if ([[self dataSource] respondsToSelector:@selector(outlineView:dragEndedWithOperation:)])
        [[self dataSource] outlineView:self dragEndedWithOperation:operation];
}

- (NSFont *)font {
    NSArray *tableColumns = [self tableColumns];
    return [tableColumns count] ? [[(NSTableColumn *)[tableColumns objectAtIndex:0] dataCell] font] : nil;
}

- (void)setFont:(NSFont *)font {
    static NSLayoutManager *layoutManager = nil;
    if (layoutManager == nil) {
        layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager setTypesetterBehavior:NSTypesetterBehavior_10_2_WithCompatibility];
    }
    
    NSEnumerator *tcEnum = [[self tableColumns] objectEnumerator];
    NSTableColumn *tc;
    
    while (tc = [tcEnum nextObject])
        [[tc dataCell] setFont:font];
    
    [self setRowHeight:[layoutManager defaultLineHeightForFont:font]];
}

@end
