//
//  SKOutlineView.m
//  Skim
//
//  Created by Christiaan Hofman on 8/22/07.
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

#import "SKOutlineView.h"
#import "SKTypeSelectHelper.h"
#import "NSEvent_SKExtensions.h"
#import "NSLayoutManager_SKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKStringConstants.h"

static char SKOutlineViewDefaultsObservationContext;


@implementation SKOutlineView

+ (BOOL)usesDefaultFontSize { return NO; }

- (void)dealloc {
    if ([[self class] usesDefaultFontSize]) {
        @try { [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKTableFontSizeKey]; }
        @catch (id e) {}
    }
    [typeSelectHelper setDataSource:nil];
    [typeSelectHelper release];
    [super dealloc];
}

- (void)awakeFromNib {
    if ([[self class] usesDefaultFontSize]) {
        NSNumber *fontSize = [[NSUserDefaults standardUserDefaults] objectForKey:SKTableFontSizeKey];
        if (fontSize)
            [self setFont:[NSFont systemFontOfSize:[fontSize doubleValue]]];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKTableFontSizeKey context:&SKOutlineViewDefaultsObservationContext];
    }
    if ([[SKOutlineView superclass] instancesRespondToSelector:_cmd])
        [super awakeFromNib];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKOutlineViewDefaultsObservationContext) {
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKTableFontSizeKey]) {
            [self setFont:[NSFont systemFontOfSize:[[NSUserDefaults standardUserDefaults] floatForKey:SKTableFontSizeKey]]];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSArray *)selectedItems {
    NSMutableArray *items = [NSMutableArray array];
    NSIndexSet *indexes = [self selectedRowIndexes];
    NSUInteger idx = [indexes firstIndex];
    
    while (idx != NSNotFound) {
        [items addObject:[self itemAtRow:idx]];
        idx = [indexes indexGreaterThanIndex:idx];
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
        [typeSelectHelper setDataSource:self];
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
    unichar eventChar = [theEvent firstCharacter];
	NSUInteger modifierFlags = [theEvent deviceIndependentModifierFlags];
    
    if (eventChar == NSHomeFunctionKey && (modifierFlags & ~NSFunctionKeyMask) == 0) {
        [self scrollToBeginningOfDocument:nil];
    } else if (eventChar == NSEndFunctionKey && (modifierFlags & ~NSFunctionKeyMask) == 0) {
        [self scrollToEndOfDocument:nil];
	} else if ((eventChar == NSDeleteCharacter || eventChar == NSDeleteFunctionKey) && modifierFlags == 0 && [self canDelete]) {
        [self delete:self];
    } else if ([typeSelectHelper processKeyDownEvent:theEvent] == NO) {
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
        NSInteger row = [self rowAtPoint:mouseLoc];
        NSInteger column = [self columnAtPoint:mouseLoc];
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
    NSEnumerator *tcEnum = [[self tableColumns] objectEnumerator];
    NSTableColumn *tc;
    
    while (tc = [tcEnum nextObject]) {
        NSCell *cell = [tc dataCell];
        if ([cell type] == NSTextCellType)
            return [cell font];
    }
    return nil;
}

- (void)setFont:(NSFont *)font {
    NSEnumerator *tcEnum = [[self tableColumns] objectEnumerator];
    NSTableColumn *tc;
    
    while (tc = [tcEnum nextObject]) {
        NSCell *cell = [tc dataCell];
        if ([cell type] == NSTextCellType)
            [cell setFont:font];
    }
    
    CGFloat rowHeight = [NSLayoutManager defaultViewLineHeightForFont:font];
    if ([self selectionHighlightStyle] == NSTableViewSelectionHighlightStyleSourceList)
        rowHeight += 2.0;
    [self setRowHeight:rowHeight];
    [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}

#pragma mark SKTypeSelectHelper datasource protocol

- (NSArray *)typeSelectHelperSelectionItems:(SKTypeSelectHelper *)aTypeSelectHelper {
    if ([[self delegate] respondsToSelector:@selector(outlineView:typeSelectHelperSelectionItems:)])
        return [[self delegate] outlineView:self typeSelectHelperSelectionItems:aTypeSelectHelper];
    return nil;
}

- (NSUInteger)typeSelectHelperCurrentlySelectedIndex:(SKTypeSelectHelper *)aTypeSelectHelper {
    return [[self selectedRowIndexes] lastIndex];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)aTypeSelectHelper selectItemAtIndex:(NSUInteger)itemIndex {
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
    [self scrollRowToVisible:itemIndex];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)aTypeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString {
    if ([[self delegate] respondsToSelector:@selector(outlineView:typeSelectHelper:didFailToFindMatchForSearchString:)])
        [[self delegate] outlineView:self typeSelectHelper:aTypeSelectHelper didFailToFindMatchForSearchString:searchString];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)aTypeSelectHelper updateSearchString:(NSString *)searchString {
    if ([[self delegate] respondsToSelector:@selector(outlineView:typeSelectHelper:updateSearchString:)])
        [[self delegate] outlineView:self typeSelectHelper:aTypeSelectHelper updateSearchString:searchString];
}

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
- (id <SKOutlineViewDelegate>)delegate {
    return (id <SKOutlineViewDelegate>)[super delegate];
}

- (void)setDelegate:(id <SKOutlineViewDelegate>)newDelegate {
    [super setDelegate:newDelegate];
}

- (id <SKOutlineViewDataSource>)dataSource {
    return (id <SKOutlineViewDataSource>)[super dataSource];
}

- (void)setDataSource:(id <SKOutlineViewDataSource>)newDataSource {
    [super setDataSource:newDataSource];
}
#endif

@end
