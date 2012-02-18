//
//  NSTableView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 8/20/07.
/*
 This software is Copyright (c) 2007-2012
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

#import "SKTableView.h"
#import "SKTypeSelectHelper.h"
#import "NSEvent_SKExtensions.h"
#import "NSFont_SKExtensions.h"
#import "SKImageToolTipWindow.h"

#define SPACE_CHARACTER 0x20


@interface SKTableView (SKPrivate)
- (void)rebuildTrackingAreas;
@end


@implementation SKTableView

@synthesize typeSelectHelper;
@dynamic canDelete, canCopy, canPaste;

- (void)dealloc {
    SKDESTROY(trackingAreas);
    [typeSelectHelper setDelegate:nil];
    SKDESTROY(typeSelectHelper);
    [super dealloc];
}

- (void)setTypeSelectHelper:(SKTypeSelectHelper *)newTypeSelectHelper {
    if (typeSelectHelper != newTypeSelectHelper) {
        if ([typeSelectHelper delegate] == self)
            [typeSelectHelper setDelegate:nil];
        [typeSelectHelper release];
        typeSelectHelper = [newTypeSelectHelper retain];
        [typeSelectHelper setDelegate:self];
    }
}

- (void)reloadData {
    [super reloadData];
	[self rebuildTrackingAreas];
    [typeSelectHelper rebuildTypeSelectSearchCache];
}

- (void)keyDown:(NSEvent *)theEvent {
    unichar eventChar = [theEvent firstCharacter];
	NSUInteger modifierFlags = [theEvent deviceIndependentModifierFlags];
    
	if ((eventChar == NSNewlineCharacter || eventChar == NSEnterCharacter || eventChar == NSCarriageReturnCharacter) && modifierFlags == 0) {
        if ([self doubleAction] == NULL || [self sendAction:[self doubleAction] to:[self target]] == NO)
            NSBeep();
    } else if ((eventChar == NSDeleteCharacter || eventChar == NSDeleteFunctionKey) && modifierFlags == 0 && [self canDelete]) {
        [self delete:self];
    } else if ((eventChar == SPACE_CHARACTER) && modifierFlags == 0) {
        [[self enclosingScrollView] pageDown:nil];
    } else if ((eventChar == SPACE_CHARACTER) && modifierFlags == NSShiftKeyMask) {
        [[self enclosingScrollView] pageUp:nil];
    } else if (eventChar == NSHomeFunctionKey && (modifierFlags & ~NSFunctionKeyMask) == 0) {
        [self scrollToBeginningOfDocument:nil];
    } else if (eventChar == NSEndFunctionKey && (modifierFlags & ~NSFunctionKeyMask) == 0) {
        [self scrollToEndOfDocument:nil];
    } else if ([typeSelectHelper handleEvent:theEvent] == NO) {
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
    NSIndexSet *indexes = [self selectedRowIndexes];
    if ([indexes count] && [[self delegate] respondsToSelector:@selector(tableView:deleteRowsWithIndexes:)]) {
        if ([[self delegate] respondsToSelector:@selector(tableView:canDeleteRowsWithIndexes:)])
            return [[self delegate] tableView:self canDeleteRowsWithIndexes:indexes];
        else
            return YES;
    }
    return NO;
}

- (void)delete:(id)sender {
    if ([self canDelete])
        [[self delegate] tableView:self deleteRowsWithIndexes:[self selectedRowIndexes]];
    else
        NSBeep();
}

- (BOOL)canCopy {
    NSIndexSet *indexes = [self selectedRowIndexes];
    if ([indexes count] && [[self delegate] respondsToSelector:@selector(tableView:copyRowsWithIndexes:)]) {
        if ([[self delegate] respondsToSelector:@selector(tableView:canCopyRowsWithIndexes:)])
            return [[self delegate] tableView:self canCopyRowsWithIndexes:indexes];
        else
            return YES;
    }
    return NO;
}

- (void)copy:(id)sender {
    if ([self canCopy])
        [[self delegate] tableView:self copyRowsWithIndexes:[self selectedRowIndexes]];
    else
        NSBeep();
}

- (BOOL)canPaste {
    if ([[self delegate] respondsToSelector:@selector(tableView:pasteFromPasteboard:)]) {
        if ([[self delegate] respondsToSelector:@selector(tableView:canPasteFromPasteboard:)])
            return [[self delegate] tableView:self canPasteFromPasteboard:[NSPasteboard generalPasteboard]];
        else
            return YES;
    }
    return NO;
}

- (void)paste:(id)sender {
    if ([self canPaste])
        [[self delegate] tableView:self pasteFromPasteboard:[NSPasteboard generalPasteboard]];
    else
        NSBeep();
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(delete:))
        return [self canDelete];
    else if ([menuItem action] == @selector(copy:))
        return [self canCopy];
    else if ([menuItem action] == @selector(paste:))
        return [self canPaste];
    else if ([menuItem action] == @selector(selectAll:))
        return [self allowsMultipleSelection];
    else if ([menuItem action] == @selector(deselectAll:))
        return [self allowsEmptySelection];
    else if ([[SKTableView superclass] instancesRespondToSelector:@selector(validateMenuItem:)])
        return [super validateMenuItem:menuItem];
    return YES;
}

- (NSFont *)font {
    for (NSTableColumn *tc in [self tableColumns]) {
        NSCell *cell = [tc dataCell];
        if ([cell type] == NSTextCellType)
            return [cell font];
    }
    return nil;
}

- (void)setFont:(NSFont *)font {
    for (NSTableColumn *tc in [self tableColumns]) {
        NSCell *cell = [tc dataCell];
        if ([cell type] == NSTextCellType)
            [cell setFont:font];
    }
    
    [self setRowHeight:[font defaultViewLineHeight]];
    [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}

#pragma mark Tracking

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
    if ([[self delegate] respondsToSelector:@selector(tableView:hasImageContextForTableColumn:row:)] == NO ||
        [[self delegate] respondsToSelector:@selector(tableView:imageContextForTableColumn:row:)] == NO)
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
        
        for (row = rowRange.location; row < NSMaxRange(rowRange); row++) {
            if ([[self delegate] tableView:self hasImageContextForTableColumn:nil row:row]) {
                [self addTrackingAreaForColumn:-1 row:row];
            } else {
                column = [columnIndexes firstIndex];
                while (column != NSNotFound) {
                    tableColumn = [[self tableColumns] objectAtIndex:column];
                    if ([[self delegate] tableView:self hasImageContextForTableColumn:tableColumn row:row])
                        [self addTrackingAreaForColumn:column row:row];
                    column = [columnIndexes indexGreaterThanIndex:column];
                }
            }
        }
    }
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
        NSInteger row = [rowNumber integerValue];
        NSTableColumn *tableColumn = (columnNumber == nil || column == -1) ? nil : [[self tableColumns] objectAtIndex:column];
        id <SKImageToolTipContext> context = [[self delegate] tableView:self imageContextForTableColumn:tableColumn row:row];
        if (context)
            [[SKImageToolTipWindow sharedToolTipWindow] showForImageContext:context atPoint:NSZeroPoint];
    }
}

- (void)mouseExited:(NSEvent *)theEvent{
    NSDictionary *userInfo = [theEvent userData];
    NSNumber *columnNumber = [userInfo objectForKey:@"column"];
    NSNumber *rowNumber = [userInfo objectForKey:@"row"];
    if (columnNumber && rowNumber)
        [[SKImageToolTipWindow sharedToolTipWindow] fadeOut];
}

#pragma mark SKTypeSelectHelper datasource protocol

- (NSArray *)typeSelectHelperSelectionStrings:(SKTypeSelectHelper *)aTypeSelectHelper {
    if ([[self delegate] respondsToSelector:@selector(tableView:typeSelectHelperSelectionStrings:)])
        return [[self delegate] tableView:self typeSelectHelperSelectionStrings:aTypeSelectHelper];
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
    if ([[self delegate] respondsToSelector:@selector(tableView:typeSelectHelper:didFailToFindMatchForSearchString:)])
        [[self delegate] tableView:self typeSelectHelper:aTypeSelectHelper didFailToFindMatchForSearchString:searchString];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)aTypeSelectHelper updateSearchString:(NSString *)searchString {
    if ([[self delegate] respondsToSelector:@selector(tableView:typeSelectHelper:updateSearchString:)])
        [[self delegate] tableView:self typeSelectHelper:aTypeSelectHelper updateSearchString:searchString];
}

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
- (id <SKTableViewDelegate>)delegate {
    return (id <SKTableViewDelegate>)[super delegate];
}

- (void)setDelegate:(id <SKTableViewDelegate>)newDelegate {
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
