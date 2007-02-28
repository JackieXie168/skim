// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSTableView-OAExtensions.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "NSOutlineView-OAExtensions.h"
#import "NSView-OAExtensions.h"
#import "OATypeAheadSelectionHelper.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSTableView-OAExtensions.m 79079 2006-09-07 22:35:32Z kc $")

@interface NSTableView (OAExtensionsPrivate)
- (BOOL)_copyToPasteboard:(NSPasteboard *)pasteboard;
- (void)_pasteFromPasteboard:(NSPasteboard *)pasteboard;
- (NSString *)_typeAheadLabelForRow:(int)row;
- (BOOL)_processKeyDownCharacter:(unichar)character;
- (void)_buildTooltipsAndRelease;
@end

@interface NSTableView (OATableDelegateDataSourceCoverMethods)
- (BOOL)_dataSourceHandlesPaste;
- (BOOL)_dataSourceHandlesContextMenu;
- (NSMenu *)_contextMenuForRow:(int)row column:(int)column;
- (BOOL)_shouldShowDragImageForRow:(int)row;
- (NSArray *)_columnIdentifiersForDragImage;
- (NSTableColumn *)_typeAheadSelectionColumn;
- (BOOL)_shouldEditNextItemWhenEditingEnds;
@end

@implementation NSTableView (OAExtensions)

static IMP originalKeyDown;
static IMP originalMouseDown;
static IMP originalTextDidEndEditing;
static IMP originalDragImageForRows;

static NSArray *OATableViewRowsInCurrentDrag = nil;
// you'd think this should be instance-specific, but it doesn't have to be -- only one drag can be happening at a time.

static OATypeAheadSelectionHelper *TypeAheadHelper = nil;
// same here -- you can't be typing in two table views at once.


+ (void)didLoad;
{
    originalKeyDown = OBReplaceMethodImplementationWithSelector(self, @selector(keyDown:), @selector(_replacementKeyDown:));
    originalMouseDown = OBReplaceMethodImplementationWithSelector(self, @selector(mouseDown:), @selector(_replacementMouseDown:));
    originalTextDidEndEditing = OBReplaceMethodImplementationWithSelector(self, @selector(textDidEndEditing:), @selector(_replacementTextDidEndEditing:));
    originalDragImageForRows = OBReplaceMethodImplementationWithSelector(self, @selector(dragImageForRows:event:dragImageOffset:), @selector(_replacementDragImageForRows:event:dragImageOffset:));
}


// NSTableView method replacements

- (void)_replacementKeyDown:(NSEvent *)theEvent;
{
    NSString *characters = [theEvent characters];
    unichar firstCharacter = [characters characterAtIndex:0];
    
    // See if there's an item whose title matches what the user is typing.
    // This can only be activated, initially, by typing an alphanumeric character.  This means it's smart enough to know when the user is, say, pressing space emulate a double-click, or pressing space separating two search string words.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DisableTypeAheadSelection"] &&   
        [_dataSource respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)]) {
        NSTableColumn *typeAheadColumn;
        
        typeAheadColumn = [self _typeAheadSelectionColumn];
        if (typeAheadColumn != nil && ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:firstCharacter] || ([TypeAheadHelper isProcessing] && ![[NSCharacterSet controlCharacterSet] characterIsMember:firstCharacter]))) {
            if (TypeAheadHelper == nil)
                TypeAheadHelper = [[OATypeAheadSelectionHelper alloc] init];
            
            // make sure the helper is cached against us (not some other instance), but don't recache on every keyDown either.
            if ([TypeAheadHelper dataSource] != self || ![TypeAheadHelper isProcessing])
                [TypeAheadHelper setDataSource:self];
            
            [TypeAheadHelper processKeyDownCharacter:firstCharacter];
            return;
        }
    }
    
    if ([self _processKeyDownCharacter:firstCharacter])
        return;
    
    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

- (void)_replacementMouseDown:(NSEvent *)event;
{
    // Workaround for bug where triple-click aborts double-click's edit session instead of selecting all of the text in the column to be edited
    if ([event clickCount] < 3)         
        originalMouseDown(self, _cmd, event);
    else if (_editingCell)
        [[[self window] firstResponder] selectAll:nil];
}

- (void)_replacementTextDidEndEditing:(NSNotification *)notification;
{
    int textMovement = [[[notification userInfo] objectForKey:@"NSTextMovement"] intValue];
    if ((textMovement == NSReturnTextMovement || textMovement == NSTabTextMovement) && ![self _shouldEditNextItemWhenEditingEnds]) {
        // This is ugly, but just about the only way to do it. NSTableView is determined to select and edit something else, even the text field that it just finished editing, unless we mislead it about what key was pressed to end editing.
        NSMutableDictionary *newUserInfo;
        NSNotification *newNotification;

        newUserInfo = [NSMutableDictionary dictionaryWithDictionary:[notification userInfo]];
        [newUserInfo setObject:[NSNumber numberWithInt:NSIllegalTextMovement] forKey:@"NSTextMovement"];
        newNotification = [NSNotification notificationWithName:[notification name] object:[notification object] userInfo:newUserInfo];
        originalTextDidEndEditing(self, _cmd, newNotification);

        // For some reason we lose firstResponder status when we do the above.
        [[self window] makeFirstResponder:self];
    } else {
        originalTextDidEndEditing(self, _cmd, notification);
    }
}

- (NSImage *)_replacementDragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset;
{
    NSImage *dragImage;
    NSEnumerator *rowEnumerator;
    id rowNumber;
    NSCachedImageRep *cachedImageRep;
    NSView *contentView;
    NSPoint dragPoint;

    OATableViewRowsInCurrentDrag = [dragRows retain]; // hang on to these so we can use them in -draggedImage:endedAt:operation:.

    if ([self _columnIdentifiersForDragImage] == nil)
        return originalDragImageForRows(self, _cmd, dragRows, dragEvent, dragImageOffset);
    
    cachedImageRep = [[NSCachedImageRep alloc] initWithSize:[self bounds].size depth:[[NSScreen mainScreen] depth] separate:YES alpha:YES];
    contentView = [[cachedImageRep window] contentView];

    [contentView lockFocus];
    rowEnumerator = [dragRows objectEnumerator];
    while ((rowNumber = [rowEnumerator nextObject])) {
        int row = [rowNumber intValue];

        if ([self _shouldShowDragImageForRow:row]) {
            NSArray *dragColumns;
            NSEnumerator *columnEnumerator;
            NSTableColumn *columnIdentifier;

            dragColumns = [self _columnIdentifiersForDragImage];
            if (dragColumns == nil || [dragColumns count] == 0)
                dragColumns = [[self tableColumns] arrayByPerformingSelector:@selector(identifier)];

            columnEnumerator = [dragColumns objectEnumerator];
            while ((columnIdentifier = [columnEnumerator nextObject])) {
                NSTableColumn *tableColumn;
                NSCell *cell;
                NSRect cellRect;
                id objectValue;

                tableColumn = [self tableColumnWithIdentifier:columnIdentifier];
                objectValue = [_dataSource tableView:self objectValueForTableColumn:tableColumn row:row];

                cellRect = [self frameOfCellAtColumn:[[self tableColumns] indexOfObject:tableColumn] row:row];
                cellRect.origin.y = NSMaxY([self bounds]) - NSMaxY(cellRect);
                cell = [tableColumn dataCellForRow:row];

                [cell setCellAttribute:NSCellHighlighted to:0];
                [cell setObjectValue:objectValue];
                if ([cell respondsToSelector:@selector(setDrawsBackground:)])
                    [(NSTextFieldCell *)cell setDrawsBackground:0];
                [cell drawWithFrame:cellRect inView:contentView];
            }
        }
    }
    [contentView unlockFocus];

    dragPoint = [self convertPoint:[dragEvent locationInWindow] fromView:nil];
    dragImageOffset->x = NSMidX([self bounds]) - dragPoint.x;
    dragImageOffset->y = dragPoint.y - NSMidY([self bounds]);

    dragImage = [[NSImage alloc] init];
    [dragImage addRepresentation:cachedImageRep];
    [cachedImageRep release];

    return dragImage;
}


// New API

- (NSArray *)selectedRows;
{
    NSMutableArray *selectedRows;
    NSEnumerator *enumerator;
    NSNumber *rowNumber;

    selectedRows = [NSMutableArray arrayWithCapacity:[self numberOfSelectedRows]];
    enumerator = [self selectedRowEnumerator];
    while ((rowNumber = [enumerator nextObject]))
        [selectedRows addObject:rowNumber];

    return [NSArray arrayWithArray:selectedRows];
}

- (NSRect) rectOfSelectedRows;
{
    NSEnumerator *rowEnum;
    NSNumber *row;
    NSRect rect;
    
    rowEnum = [self selectedRowEnumerator];
    row = [rowEnum nextObject];
    if (!row)
        return NSZeroRect;
    rect = [self rectOfRow: [row intValue]];
    
    while ((row = [rowEnum nextObject])) {
        rect = NSUnionRect(rect, [self rectOfRow: [row intValue]]);
    }
    
    return rect;
}

- (void)scrollSelectedRowsToVisibility: (OATableViewRowVisibility)visibility;
{
    NSRect selectionRect;
    
    if (visibility == OATableViewRowVisibilityLeaveUnchanged)
        return;
    
    selectionRect = [self rectOfSelectedRows];
    if (NSEqualRects(selectionRect, NSZeroRect))
        return;
    
    if (visibility == OATableViewRowVisibilityScrollToVisible)
        [self scrollRectToVisible: selectionRect];
    else if (visibility == OATableViewRowVisibilityScrollToMiddleIfNotVisible) {
        NSRect visibleRect;
        float heightDifference;

        visibleRect = [self visibleRect];
        if (NSContainsRect(visibleRect, selectionRect))
            return;
        
        heightDifference = NSHeight(visibleRect) - NSHeight(selectionRect);
        if (heightDifference > 0) {
            // scroll to a rect equal in height to the visible rect but centered on the selected rect
            selectionRect = NSInsetRect(selectionRect, 0.0, -(heightDifference / 2.0));
        } else {
            // force the top of the selectionRect to the top of the view
            selectionRect.size.height = NSHeight(visibleRect);
        }
        [self scrollRectToVisible: selectionRect];
    }
}

- (NSFont *)font;
{
    NSArray *tableColumns;
    
    tableColumns = [self tableColumns];
    if ([tableColumns count] > 0)
        return [[(NSTableColumn *)[tableColumns objectAtIndex:0] dataCell] font];
    else
        return nil;
}

- (void)setFont:(NSFont *)font;
{
    NSArray *tableColumns;
    unsigned int columnIndex;
    
    tableColumns = [self tableColumns];
    columnIndex = [tableColumns count];
    while (columnIndex--)
        [[(NSTableColumn *)[tableColumns objectAtIndex:columnIndex] dataCell] setFont:font];
}


// NSResponder subclass

- (NSMenu *)menuForEvent:(NSEvent *)event;
{
    NSPoint point;
    int rowIndex, columnIndex;

    if (![self _dataSourceHandlesContextMenu])
        return [super menuForEvent:event];
    
    point = [self convertPoint:[event locationInWindow] fromView:nil];
    rowIndex = [self rowAtPoint:point];
    // Christiaan M. Hofman: fixed bug in following line
    columnIndex = [self columnAtPoint:point]; 
    if (rowIndex >= 0 && columnIndex >= 0) {
        if (![self isRowSelected:rowIndex])
            [self selectRow:rowIndex byExtendingSelection:NO];
    }

    return [self _contextMenuForRow:rowIndex column:columnIndex];
}

- (void)moveUp:(id)sender;
{
    NSEnumerator *selectedRowEnumerator;
    NSNumber *selectedRow;
    int firstSelectedRow = -1;
    
    selectedRowEnumerator = [self selectedRowEnumerator];
    while ((selectedRow = [selectedRowEnumerator nextObject]) != nil) {
        if (firstSelectedRow == -1)
            firstSelectedRow = [selectedRow intValue];
        else
            firstSelectedRow = MIN(firstSelectedRow, [selectedRow intValue]);
    }
    
    if (firstSelectedRow == -1) { // If nothing was selected
        int numberOfRows = [self numberOfRows];
        if (numberOfRows > 0) // If there are rows in the table
            firstSelectedRow = numberOfRows - 1; // Select the last row
        else
            return; // There are no rows: do nothing
    } else if (firstSelectedRow > 0) {
        firstSelectedRow--;
    }

    if ([self delegate] && [[self delegate] respondsToSelector:@selector(tableView:shouldSelectRow:)])
        while (![[self delegate] tableView:self shouldSelectRow:firstSelectedRow])
            if (--firstSelectedRow < 0)
                return;	// If we never find a selectable row, don't do anything
    
    // If the first row was selected, select only the first row.  This is consistent with the behavior of many Apple apps.
    [self selectRow:firstSelectedRow byExtendingSelection:NO];
    [self scrollRowToVisible:firstSelectedRow];
}

- (void)moveDown:(id)sender;
{
    NSEnumerator *selectedRowEnumerator;
    NSNumber *selectedRow;
    int lastSelectedRow = -1;
    
    selectedRowEnumerator = [self selectedRowEnumerator];
    while ((selectedRow = [selectedRowEnumerator nextObject]) != nil) {
        lastSelectedRow = MAX(lastSelectedRow, [selectedRow intValue]);
    }
    
    int numberOfRows = [self numberOfRows];
    if (lastSelectedRow == -1) { // If nothing was selected
        if (numberOfRows > 0) // If there are rows in the table
            lastSelectedRow = 0; // Select the first row
        else
            return; // There are no rows: do nothing
    } else if (lastSelectedRow < numberOfRows - 1) {
        ++lastSelectedRow;
    }
    
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(tableView:shouldSelectRow:)])
        while (![[self delegate] tableView:self shouldSelectRow:lastSelectedRow])
            if (++lastSelectedRow > numberOfRows - 1)
                return;	// If we never find a selectable row, don't do anything
        
    // If the first row was selected, select only the first row.  This is consistent with the behavior of many Apple apps.
    [self selectRow:lastSelectedRow byExtendingSelection:NO];
    [self scrollRowToVisible:lastSelectedRow];
}

- (void)deleteForward:(id)sender;
{
    if ([_dataSource respondsToSelector:@selector(tableView:deleteRows:)]) {
        int selectedRow;
        int originalNumberOfRows, numberOfRows;

        selectedRow = [self selectedRow]; // last selected row if there's a multiple selection -- that's ok.
        if (selectedRow == -1)
            return;

        originalNumberOfRows = [self numberOfRows];
        [_dataSource tableView:self deleteRows:[self selectedRows]];
        [self reloadData];

        // Maintain an appropriate selection after deletions
        numberOfRows = [self numberOfRows];
        selectedRow -= originalNumberOfRows - numberOfRows;
        selectedRow = MIN(selectedRow + 1, numberOfRows - 1);

        if (numberOfRows > 0)
            [self selectRow:selectedRow byExtendingSelection:NO];
    }
}

- (void)deleteBackward:(id)sender;
{
    if ([_dataSource respondsToSelector:@selector(tableView:deleteRows:)]) {
        unsigned int originalNumberOfRows;
        
        if ([self numberOfSelectedRows] == 0)
            return;

        // -selectedRow is last row of multiple selection, no good for trying to select the row before the selection.
        unsigned int selectedRow = [[[self selectedRows] objectAtIndex:0] unsignedIntValue];
        originalNumberOfRows = [self numberOfRows];
        [_dataSource tableView:self deleteRows:[self selectedRows]];
        [self reloadData];
        unsigned int newNumberOfRows = [self numberOfRows];
        
        // Maintain an appropriate selection after deletions
        if (originalNumberOfRows != newNumberOfRows) {
            if (selectedRow == 0) {
                if ([_delegate respondsToSelector:@selector(tableView:shouldSelectRow:)]) {
                    if ([_delegate tableView:self shouldSelectRow:0])
                        [self selectRow:0 byExtendingSelection:NO];
                    else
                        [self moveDown:nil];
                } else {
                    [self selectRow:0 byExtendingSelection:NO];
                }
            } else {
                // Don't try to go past the new # of rows
                selectedRow = MIN(selectedRow - 1, newNumberOfRows - 1);
                
                // Skip all unselectable rows if the delegate responds to -tableView:shouldSelectRow:
                if ([_delegate respondsToSelector:@selector(tableView:shouldSelectRow:)]) {
                    while (selectedRow > 0 && ![_delegate tableView:self shouldSelectRow:selectedRow])
                        selectedRow--;
                }
                
                // If nothing was selected, move down (so that the top row is selected)
                if (selectedRow < 0)
                    [self moveDown:nil];
                else
                    [self selectRow:selectedRow byExtendingSelection:NO];
            }
        }
    }
}

- (void)insertNewline:(id)sender;
{
    if ([_dataSource respondsToSelector:@selector(tableView:insertNewline:)])
        [_dataSource tableView:self insertNewline:sender];
}

- (void)insertTab:(id)sender;
{
    [[self window] selectNextKeyView:nil];
}

- (void)insertBacktab:(id)sender;
{
    [[self window] selectPreviousKeyView:nil];
}

// NSResponder subclass

- (void)scrollPageDown:(id)sender
{
    [self scrollDownByPages:1.0];
}

- (void)scrollPageUp:(id)sender
{
    [self scrollDownByPages:-1.0];
}

- (void)scrollLineDown:(id)sender
{
    [self scrollDownByLines:1.0];
}

- (void)scrollLineUp:(id)sender
{
    [self scrollDownByLines:-1.0];
}

- (void)scrollToBeginningOfDocument:(id)sender
{
    [self scrollToTop];
}

- (void)scrollToEndOfDocument:(id)sender
{
    [self scrollToEnd];
}

// Actions

- (IBAction)delete:(id)sender;
{
    if ([_dataSource respondsToSelector:@selector(delete:)])
        [_dataSource delete:sender];
    else if ([_delegate respondsToSelector:@selector(delete:)])
        [_delegate delete:sender];
    else
        [self deleteBackward:sender];
}

- (IBAction)cut:(id)sender;
{
    if ([_dataSource respondsToSelector:@selector(cut:)]) {
        [_dataSource cut:sender];
    } else if ([_delegate respondsToSelector:@selector(cut:)]) {
        [_delegate cut:sender];
    } else {
        
        if ([self _copyToPasteboard:[NSPasteboard generalPasteboard]])
            [self delete:sender];
    }
}

- (IBAction)copy:(id)sender;
{
    if ([_dataSource respondsToSelector:@selector(copy:)]) {
        [_dataSource copy:sender];
    } else if ([_delegate respondsToSelector:@selector(copy:)]) {
        [_delegate copy:sender];
    } else {

        [self _copyToPasteboard:[NSPasteboard generalPasteboard]];
    }
}

- (IBAction)paste:(id)sender;
{
    if ([_dataSource respondsToSelector:@selector(paste:)]) {
        [_dataSource paste:sender];
    } else if ([_delegate respondsToSelector:@selector(paste:)]) {
        [_delegate paste:sender];
    } else {
        
        if ([self _dataSourceHandlesPaste])
            [self _pasteFromPasteboard:[NSPasteboard generalPasteboard]];
    }
}

- (IBAction)duplicate:(id)sender; // duplicate == copy + paste (but it doesn't use the general pasteboard)
{
    if ([_dataSource respondsToSelector:@selector(duplicate:)]) {
        [_dataSource duplicate:sender];
    } else if ([_delegate respondsToSelector:@selector(duplicate:)]) {
        [_delegate duplicate:sender];
    } else {
        NSPasteboard *tempPasteboard;

        tempPasteboard = [NSPasteboard pasteboardWithUniqueName];
        if ([self _copyToPasteboard:tempPasteboard] && [self _dataSourceHandlesPaste])
            [self _pasteFromPasteboard:tempPasteboard];
    }
}


// NSDraggingSource

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag;
{
    if ([_dataSource respondsToSelector:@selector(tableView:draggingSourceOperationMaskForLocal:)])
        return [_dataSource tableView:self draggingSourceOperationMaskForLocal:flag];
    else if (flag)
        return NSDragOperationEvery;
    else
        return NSDragOperationNone;        
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation;
{
    // We get NSDragOperationDelete now for dragging to the Trash.
    if (operation == NSDragOperationDelete) {
        if ([_dataSource respondsToSelector:@selector(tableView:deleteRows:)]) {
            [_dataSource tableView:self deleteRows:OATableViewRowsInCurrentDrag];
            [self reloadData];
        }
    }
            
    [OATableViewRowsInCurrentDrag release]; // retained at start of drag
}


// Informal OmniFindControllerAware protocol

- (id <OAFindControllerTarget>)omniFindControllerTarget;
{
    if (![_dataSource respondsToSelector:@selector(tableView:itemAtRow:matchesPattern:)])
        return nil;
    return self;
}

// OAFindControllerTarget protocol

- (BOOL)findPattern:(id <OAFindPattern>)pattern backwards:(BOOL)backwards wrap:(BOOL)wrap;
{
    int rowIndex;
    BOOL hasWrapped = NO;
    
    // Can't search an empty table
    if ([self numberOfRows] == 0)
        return NO;
    
    // Start at the first selected item, if any.  If not, start at the first item, if any
    if ([self numberOfSelectedRows])
        rowIndex = [self selectedRow];
    else {
        if (backwards)
            rowIndex = [self numberOfRows] - 1;
        else
            rowIndex = 0;
    }
        
    while (YES) {
        if (rowIndex != [self selectedRow] && [_dataSource tableView:self itemAtRow:rowIndex matchesPattern:pattern]) {
            [self selectRow:rowIndex byExtendingSelection:NO];
            [self scrollRowToVisible:rowIndex];
            return YES;
        }

        if (backwards)
            rowIndex--;
        else
            rowIndex++;

        if (rowIndex < 0 || rowIndex >= [self numberOfRows]) {
            if (wrap && !hasWrapped) {
                hasWrapped = YES;
                if (backwards)
                    rowIndex = [self numberOfRows] - 1;
                else
                    rowIndex = 0;
            } else {
                break;
            }
        }
    }
    
    return NO;
}


// OATypeAheadSelectionDataSource

- (NSArray *)typeAheadSelectionItems;
{
    NSMutableArray *visibleItemLabels;
    int row;

    visibleItemLabels = [NSMutableArray arrayWithCapacity:[self numberOfRows]];
    for (row = 0; row < [self numberOfRows]; row++) {
        id typeAheadLabel = [self _typeAheadLabelForRow:row];
        if (typeAheadLabel)
            [visibleItemLabels addObject:typeAheadLabel];
    }

    return [NSArray arrayWithArray:visibleItemLabels] ;
}

- (NSString *)currentlySelectedItem;
{
    if ([self numberOfSelectedRows] != 1)
        return nil;
    else
        return [self _typeAheadLabelForRow:[self selectedRow]];
}

- (void)typeAheadSelectItemAtIndex:(int)itemIndex;
{
    [self selectRow:itemIndex byExtendingSelection:NO];
    [self scrollRowToVisible:itemIndex];
}


@end

@implementation NSTableView (OAExtensionsPrivate)

- (BOOL)_copyToPasteboard:(NSPasteboard *)pasteboard;
{
    if ([self isKindOfClass:[NSOutlineView class]]) {
        if ([self numberOfSelectedRows] > 0 && [_dataSource respondsToSelector:@selector(outlineView:writeItems:toPasteboard:)])
            return [_dataSource outlineView:(NSOutlineView *)self writeItems:[(NSOutlineView *)self selectedItems] toPasteboard:pasteboard];
        else
            return NO;
    } else {
        if ([self numberOfSelectedRows] > 0 && [_dataSource respondsToSelector:@selector(tableView:writeRows:toPasteboard:)])
            return [_dataSource tableView:self writeRows:[self selectedRows] toPasteboard:pasteboard];
        else
            return NO;
    }
}

- (void)_pasteFromPasteboard:(NSPasteboard *)pasteboard;
{
    [_dataSource tableView:self addItemsFromPasteboard:pasteboard];
}

- (NSString *)_typeAheadLabelForRow:(int)row;
{
    id cellValue = [_dataSource tableView:self objectValueForTableColumn:[self _typeAheadSelectionColumn] row:row];
    if ([cellValue isKindOfClass:[NSString class]])
        return cellValue;
    else if ([cellValue isKindOfClass:[NSAttributedString class]])
        return [(NSAttributedString *)cellValue string];
    else if ([cellValue respondsToSelector:@selector(stringValue)])
        return [cellValue stringValue];
    else
        return @"";
}

- (BOOL)_processKeyDownCharacter:(unichar)character;
{
    switch (character) {
        case ' ':
        {
            SEL doubleAction;

            // Emulate a double-click
            doubleAction = [self doubleAction];
            if (doubleAction != NULL && [self sendAction:doubleAction to:[self target]])
                return YES; // We've performed our action
            break;
        }
    }
    return NO;
}

- (void)_buildTooltipsAndRelease;
{
    //Only do the work if we are going to be around to take advantage of it.
    if ([[self dataSource] retainCount] > 1) {
    }
    
    [[self dataSource] release];
}

@end

@implementation NSTableView (OATableDelegateDataSourceCoverMethods)

- (BOOL)_dataSourceHandlesPaste;
{
    // This is an override point so that OutlineView can get our implementation for free but provide item-based datasource API
    return [_dataSource respondsToSelector:@selector(tableView:addItemsFromPasteboard:)];
}

- (BOOL)_dataSourceHandlesContextMenu;
{
    // This is an override point so that OutlineView can get our implementation for free but provide item-based datasource API
    return [_dataSource respondsToSelector:@selector(tableView:contextMenuForRow:column:)];
}

- (NSMenu *)_contextMenuForRow:(int)row column:(int)column;
{
    // This is an override point so that OutlineView can get our implementation for free but provide item-based datasource API
    OBASSERT([self _dataSourceHandlesContextMenu]); // should already know this by the time we get here
    return [_dataSource tableView:self contextMenuForRow:row column:column];
}

- (BOOL)_shouldShowDragImageForRow:(int)row;
{
    if ([_dataSource respondsToSelector:@selector(tableView:shouldShowDragImageForRow:)])
        return [_dataSource tableView:self shouldShowDragImageForRow:row];
    else
        return YES;
}

- (NSArray *)_columnIdentifiersForDragImage;
{
    if ([_dataSource respondsToSelector:@selector(tableViewColumnIdentifiersForDragImage:)]) {
        NSArray *identifiers;

        identifiers = [_dataSource tableViewColumnIdentifiersForDragImage:self];
        if ([identifiers count] < 1)
            [NSException raise:NSInvalidArgumentException format:@"-tableViewColumnIdentifiersForDragImage: must return at least one valid column identifier"];
        else
            return identifiers;
    }

    return nil; 
}

- (NSTableColumn *)_typeAheadSelectionColumn;
{
    if ([_dataSource respondsToSelector:@selector(tableViewTypeAheadSelectionColumn:)])
        return [_dataSource tableViewTypeAheadSelectionColumn:self];
    else if ([[self tableColumns] count] == 1)
        return ([[self tableColumns] objectAtIndex:0]);
    else
        return nil;
}

- (BOOL)_shouldEditNextItemWhenEditingEnds;
{
    if ([_dataSource respondsToSelector:@selector(tableViewShouldEditNextItemWhenEditingEnds:)])
        return [_dataSource tableViewShouldEditNextItemWhenEditingEnds:self];
    else
        return YES;
}


@end

