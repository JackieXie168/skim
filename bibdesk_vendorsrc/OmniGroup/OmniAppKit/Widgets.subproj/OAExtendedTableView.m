// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAExtendedTableView.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAExtendedTableView.m,v 1.5 2003/01/15 22:51:43 kc Exp $");

@interface OAExtendedTableView (Private)
- (void)_initExtendedTableView;
@end

@implementation OAExtendedTableView

// Init and dealloc

- (id)initWithFrame:(NSRect)rect;
{
    if (![super initWithFrame:rect])
        return nil;

    [self _initExtendedTableView];
    
    return self;
}

- initWithCoder:(NSCoder *)coder;
{
    if (![super initWithCoder:coder])
        return nil;

    [self _initExtendedTableView];
        
    return self;
}

- (void)dealloc;
{
    [super dealloc];
}


// API

- (NSRange)columnRangeForDragImage;
{
    return _dragColumnRange;
}

- (void)setColumnRangeForDragImage:(NSRange)newRange;
{
    _dragColumnRange = newRange;
}

// NSTableView subclass

- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset;
{
    NSImage *dragImage;
    NSEnumerator *enumerator;
    id rowNumber;
    NSCachedImageRep *cachedImageRep;
    NSView *contentView;
    NSPoint dragPoint;
    
    cachedImageRep = [[NSCachedImageRep alloc] initWithSize:[self bounds].size depth:[[NSScreen mainScreen] depth] separate:YES alpha:YES];
    contentView = [[cachedImageRep window] contentView];
    
    [contentView lockFocus];
    enumerator = [dragRows objectEnumerator];
    while ((rowNumber = [enumerator nextObject])) {
        int row = [rowNumber intValue];
        BOOL shouldDrag = YES;
        
        if ([_dataSource respondsToSelector:@selector(tableView:shouldShowDragImageForRow:)])
            shouldDrag = [_dataSource tableView:self shouldShowDragImageForRow:row];
            
        if (shouldDrag) {
            int columnIndex, startColumn, endColumn;
            
            if (_dragColumnRange.length) {
                startColumn = _dragColumnRange.location;
                endColumn = _dragColumnRange.location + _dragColumnRange.length;
            } else {
                startColumn = 0;
                endColumn = [self numberOfColumns];
            }
            
            for (columnIndex = startColumn; columnIndex < endColumn; columnIndex++) {
                NSTableColumn *tableColumn;
                NSCell *cell;
                NSRect cellRect;
                id objectValue;
                
                tableColumn = [[self tableColumns] objectAtIndex:columnIndex];
                objectValue = [_dataSource tableView:self objectValueForTableColumn:tableColumn row:row];
    
                cellRect = [self frameOfCellAtColumn:columnIndex row:row];
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

@end

@implementation OAExtendedTableView (NotificationsDelegatesDatasources)
@end

@implementation OAExtendedTableView (Private)

- (void)_initExtendedTableView;
{
    _dragColumnRange = NSMakeRange(0, 0);
}

@end
