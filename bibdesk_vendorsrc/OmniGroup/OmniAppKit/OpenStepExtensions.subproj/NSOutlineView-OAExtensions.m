// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.


#import <OmniAppKit/NSOutlineView-OAExtensions.h>

#import <OmniAppKit/NSTableView-OAExtensions.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSOutlineView-OAExtensions.m,v 1.20 2003/04/23 06:19:52 rick Exp $")

@implementation NSOutlineView (OAExtensions)

- (id)selectedItem;
{
    if ([self numberOfSelectedRows] != 1)
        return nil;

    return [self itemAtRow: [self selectedRow]];
}

- (void)setSelectedItem:(id)item;
{
    [self setSelectedItem: item visibility: OATableViewRowVisibilityLeaveUnchanged];
}

- (void)setSelectedItem:(id)item visibility:(OATableViewRowVisibility)visibility;
{
    [self setSelectedItems:[NSArray arrayWithObject:item] visibility:visibility];
}


- (NSArray *)selectedItems;
{
    NSMutableArray *items;
    NSEnumerator *rowEnum;
    NSNumber *row;
    
    items = [NSMutableArray array];
    rowEnum = [self selectedRowEnumerator];
    while ((row = [rowEnum nextObject])) {
        // Apple bug #2854415.  An empty outline will return an enumerator that returns row==0 and itemAtRow: will return nil, causing  us to try to insert nil into the array.
        id item = [self itemAtRow:[row intValue]];
        if (item)
            [items addObject:item];
    }

    return items;
}

- (void)setSelectedItems:(NSArray *)items visibility:(OATableViewRowVisibility)visibility;
{
    NSHashTable *itemTable;
    unsigned int itemIndex, itemCount, rowIndex, rowCount;
    id item;
    BOOL shouldExtendSelection;
    
    itemCount = [items count];
    if (!itemCount)
        return;
        
    // Build a has table of the objects to select to avoid a O(N^2) loop.
    // This also uniques the list of objects nicely, should it not already be.
    itemTable = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, itemCount);
    itemIndex = itemCount;
    while (itemIndex--)
        NSHashInsert(itemTable, [items objectAtIndex:itemIndex]);
        
    // Now, do a O(N) search through all of the rows and select any for which we have objects
    shouldExtendSelection = NO;
    rowCount = [self numberOfRows];
    for (rowIndex = 0; rowIndex < rowCount; rowIndex++) {
        item = [self itemAtRow:rowIndex];
        if (NSHashGet(itemTable, item)) {
            // We should be able to always extend the selection, since we deselected everything above. However, as of OS X DP4, if we do that, it sometimes triggers an assertion and NSLog in NSTableView. (Usually that happens after dragging an item.)
            [self selectRow:rowIndex byExtendingSelection:shouldExtendSelection];
            shouldExtendSelection = YES;
        }
    }

    // If nothing ended up getting selected, clear the selection
    if (!shouldExtendSelection)
        [self deselectAll:nil];

    NSFreeHashTable(itemTable);
     
    [self scrollSelectedRowsToVisibility: visibility];
}

- (void)setSelectedItems:(NSArray *)items;
{
    [self setSelectedItems: items visibility: OATableViewRowVisibilityLeaveUnchanged];
}

- (id)firstItem;
{
    unsigned int count;
    
    count = [_dataSource outlineView: self numberOfChildrenOfItem: nil];
    if (!count)
        return nil;
    return [_dataSource outlineView: self child: 0 ofItem: nil];
}

- (void)expandAllItemsAtLevel:(unsigned int)level;
{
    unsigned int rowCount, rowIndex;
    
    rowCount = [self numberOfRows];
    for (rowIndex = 0; rowIndex < rowCount; rowIndex++) {
        if ([self levelForRow: rowIndex] == level) {
            id item;
            
            item = [self itemAtRow: rowIndex];
            if ([self isExpandable: item] && ![self isItemExpanded: item]) {
                [self expandItem: item];
                rowCount = [self numberOfRows];
            }
        }
    }
}

- (void)expandItemAndChildren:(id)item;
{
    if (item == nil || [_dataSource outlineView:self isItemExpandable:item]) {
        unsigned int childIndex, childCount;

        if (item != nil)
            [self expandItem:item];
    
        childCount = [_dataSource outlineView:self numberOfChildrenOfItem:item];
        for (childIndex = 0; childIndex < childCount; childIndex++)
            [self expandItemAndChildren:[_dataSource outlineView:self child:childIndex ofItem:item]];
    }
}

- (void)collapseItemAndChildren:(id)item;
{
    if (item == nil || [_dataSource outlineView:self isItemExpandable:item]) {
        unsigned int childIndex;

        // Collapse starting from the bottom.  This makes it feasible to have the smooth scrolling on when doing this (since most of the collapsing then happens off screen and thus doesn't get animated).
        childIndex = [_dataSource outlineView:self numberOfChildrenOfItem:item];
        while (childIndex--)
            [self collapseItemAndChildren:[_dataSource outlineView:self child:childIndex ofItem:item]];
            
        if (item != nil)
            [self collapseItem:item];
    }
}

//
// Actions
//

- (IBAction)expandAll:(id)sender;
{
    NSArray *selectedItems;

    selectedItems = [self selectedItems];
    [self expandItemAndChildren:nil];
    [self setSelectedItems:selectedItems];
}

- (IBAction)contractAll:(id)sender;
{
    NSArray *selectedItems;

    selectedItems = [self selectedItems];
    [self collapseItemAndChildren:nil];
    [self setSelectedItems:selectedItems];
}

@end
