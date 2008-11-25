//
//  NSTableView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 8/20/07.
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

#import "SKTableView.h"
#import "SKTypeSelectHelper.h"
#import "NSEvent_SKExtensions.h"
#import "NSLayoutManager_SKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKStringConstants.h"

static void *SKTableViewDefaultsObservationContext = (void *)@"SKTableViewDefaultsObservationContext";


@implementation SKTableView

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
            [self setFont:[NSFont systemFontOfSize:[fontSize floatValue]]];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKTableFontSizeKey context:SKTableViewDefaultsObservationContext];
    }
    if ([[SKTableView superclass] instancesRespondToSelector:_cmd])
        [super awakeFromNib];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == SKTableViewDefaultsObservationContext) {
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKTableFontSizeKey]) {
            [self setFont:[NSFont systemFontOfSize:[[NSUserDefaults standardUserDefaults] floatForKey:SKTableFontSizeKey]]];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

- (void)reloadData {
    [super reloadData];
    [typeSelectHelper rebuildTypeSelectSearchCache];
}

- (void)keyDown:(NSEvent *)theEvent {
    unichar eventChar = [theEvent firstCharacter];
	unsigned modifierFlags = [theEvent deviceIndependentModifierFlags];
    
	if ((eventChar == NSDeleteCharacter || eventChar == NSDeleteFunctionKey) && modifierFlags == 0 && [self canDelete]) {
        [self delete:self];
    } else if (eventChar == NSHomeFunctionKey && (modifierFlags & ~NSFunctionKeyMask) == 0) {
        [self scrollToBeginningOfDocument:nil];
    } else if (eventChar == NSEndFunctionKey && (modifierFlags & ~NSFunctionKeyMask) == 0) {
        [self scrollToEndOfDocument:nil];
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
    NSIndexSet *indexes = [self selectedRowIndexes];
    if ([indexes count] && [[self delegate] respondsToSelector:@selector(tableView:deleteRowsWithIndexes:)]) {
        if ([[self delegate] respondsToSelector:@selector(tableView:canDeleteRowsWithIndexes:)])
            return [[self delegate] tableView:self canDeleteRowsWithIndexes:indexes];
        else
            return [[self delegate] respondsToSelector:@selector(tableView:deleteRowsWithIndexes:)];
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
            return [[self delegate] respondsToSelector:@selector(tableView:copyRowsWithIndexes:)];
    }
    return NO;
}

- (void)copy:(id)sender {
    if ([self canCopy])
        [[self delegate] tableView:self copyRowsWithIndexes:[self selectedRowIndexes]];
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
    else if ([[SKTableView superclass] instancesRespondToSelector:@selector(validateMenuItem:)])
        return [super validateMenuItem:menuItem];
    return YES;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    NSMenu *menu = nil;
    
    if ([[self delegate] respondsToSelector:@selector(tableView:menuForTableColumn:row:)]) {
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        int row = [self rowAtPoint:mouseLoc];
        int column = [self columnAtPoint:mouseLoc];
        if (row != -1 && column != -1) {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:column];
            menu = [[self delegate] tableView:self menuForTableColumn:tableColumn row:row];
        }
    }
    
	return menu;
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
    
    [self setRowHeight:[NSLayoutManager defaultViewLineHeightForFont:font]];
    [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRows])]];
}

#pragma mark SKTypeSelectHelper datasource protocol

- (NSArray *)typeSelectHelperSelectionItems:(SKTypeSelectHelper *)aTypeSelectHelper {
    if ([[self delegate] respondsToSelector:@selector(tableView:typeSelectHelperSelectionItems:)])
        return [[self delegate] tableView:self typeSelectHelperSelectionItems:aTypeSelectHelper];
    return nil;
}

- (unsigned int)typeSelectHelperCurrentlySelectedIndex:(SKTypeSelectHelper *)aTypeSelectHelper {
    return [[self selectedRowIndexes] lastIndex];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)aTypeSelectHelper selectItemAtIndex:(unsigned int)itemIndex {
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

@end
