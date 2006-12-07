// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OATableView.h"

#import <OmniBase/OmniBase.h>
#import <AppKit/AppKit.h>

#import "NSString-OAExtensions.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATableView.m,v 1.11 2003/01/15 22:51:45 kc Exp $")

@interface OATableView (Private)

- (void)startDrag:(NSEvent *)event;

@end

@implementation OATableView

- (id)initWithFrame:(NSRect)rect;
{
    if (![super initWithFrame:rect])
        return nil;

    flags.shouldEditNextItemWhenEditingEnds = YES;

    return self;
}

- initWithCoder:(NSCoder *)coder;
{
    if (!(self = [super initWithCoder:coder]))
        return nil;

    flags.shouldEditNextItemWhenEditingEnds = YES;
    
    return self;
}

// API

- (BOOL)shouldEditNextItemWhenEditingEnds;
{
    return flags.shouldEditNextItemWhenEditingEnds;
}

- (void)setShouldEditNextItemWhenEditingEnds:(BOOL)value;
{
    flags.shouldEditNextItemWhenEditingEnds = value;
}

- (IBAction)copy:(id)sender;
{
    int selectedRow, selectedColumn;
    selectedRow = [self selectedRow];
    selectedColumn = [self selectedColumn];

    if (selectedRow >= 0 || selectedColumn >= 0) {
        if ([[self dataSource] respondsToSelector:@selector(tableView:copyObjectValueForTableColumn:row:toPasteboard:)]) {
            NSTableColumn *column;

            if (selectedColumn >= 0)
                column = [[self tableColumns] objectAtIndex:selectedColumn];
            else
                column = nil;
        
            [[self dataSource] tableView:self copyObjectValueForTableColumn:column row:selectedRow toPasteboard:[NSPasteboard generalPasteboard]];
        }
    }
}

// NSView

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
{
    return YES;
}

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)anEvent 
{
    return YES;
}

// NSTableView

- (void)textDidEndEditing:(NSNotification *)notification;
{
    if (flags.shouldEditNextItemWhenEditingEnds == NO && [[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement) {
        // This is ugly, but just about the only way to do it. NSTableView is determined to select and edit something else, even the text field that it just finished editing, unless we mislead it about what key was pressed to end editing.
        NSMutableDictionary *newUserInfo;
        NSNotification *newNotification;
        
        newUserInfo = [NSMutableDictionary dictionaryWithDictionary:[notification userInfo]];
        [newUserInfo setObject:[NSNumber numberWithInt:NSIllegalTextMovement] forKey:@"NSTextMovement"];
        newNotification = [NSNotification notificationWithName:[notification name] object:[notification object] userInfo:newUserInfo];
        [super textDidEndEditing:newNotification];

        // For some reason we lose firstResponder status when when we do the above.
        [[self window] makeFirstResponder:self];
    } else {
        [super textDidEndEditing:notification];
    }
}

// NSControl

- (void)keyDown:(NSEvent *)theEvent;
{
    NSString *characters;
    unichar firstCharacter;

    characters = [theEvent characters];
    firstCharacter = [characters characterAtIndex:0];

    // All three of these are mapped to "insertNewline:" in the standard key bindings.
    // 0x03 = Keypad enter = ^C (really!)
    if (firstCharacter == 0x03 || firstCharacter == '\n' || firstCharacter == '\r') {
        SEL doubleAction;
        id target;
        
        if ([self numberOfSelectedRows] > 0 && (target = [self target]) && (doubleAction = [self doubleAction])) {
            [target performSelector:doubleAction withObject:self];
            return;
        }
    }

    [super keyDown:theEvent];
}

#warning We should remove our drag code in favor of NSTableView's new implementation
- (void)mouseDown:(NSEvent *)event;
{
    NSPoint eventLocationInWindow, eventLocation;
    int columnIndex, rowIndex;
    NSRect slopRect;
    const int dragSlop = 4;
    NSEvent *mouseDragCurrentEvent;

    if (![[self dataSource] respondsToSelector:@selector(tableView:copyObjectValueForTableColumn:row:toPasteboard:)]) {
        [super mouseDown:event];
        return;
    }

    eventLocationInWindow = [event locationInWindow];
    eventLocation = [self convertPoint:eventLocationInWindow fromView:nil];
    columnIndex = [self columnAtPoint:eventLocation];
    rowIndex = [self rowAtPoint:eventLocation];
    if (rowIndex == -1 || columnIndex == -1)
        return;

    slopRect = NSInsetRect(NSMakeRect(eventLocationInWindow.x, eventLocationInWindow.y, 0.0, 0.0), -dragSlop, -dragSlop);
    while (1) {
        NSEvent *nextEvent;

        nextEvent = [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:NO];
        mouseDragCurrentEvent = nextEvent;

        if ([nextEvent type] == NSLeftMouseUp) {
            break;
        } else {
            [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
            if (!NSMouseInRect([nextEvent locationInWindow], slopRect, NO)) {
                [self startDrag:event];
                return;
            }
        }
    }

    [super mouseDown:event];
}

// NSDraggingSource

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal;
{
    if (isLocal)
        return NSDragOperationGeneric;
    else
        return NSDragOperationCopy;
}

@end


@implementation OATableView (Private)

- (void)startDrag:(NSEvent *)event;
{
    NSPoint eventLocation;
    int dragSourceRow;
    int selectedRow;
    NSRect rowFrame;
    double xOffsetOfFirstColumn;
    NSRect imageFrame;
    NSCachedImageRep *cachedImageRep;
    NSView *contentView;
    NSPasteboard *pasteboard;
    NSImage *dragImage = nil;
    
    eventLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    dragSourceRow = [self rowAtPoint:eventLocation];

    selectedRow = [self selectedRow];
    [self selectRow:dragSourceRow byExtendingSelection:NO];

    rowFrame = [self rectOfRow:dragSourceRow];
    xOffsetOfFirstColumn = [self frameOfCellAtColumn:0 row:dragSourceRow].origin.x;
    imageFrame = NSMakeRect(0, 0, NSWidth(rowFrame)-xOffsetOfFirstColumn, NSHeight(rowFrame));

    if ([[self dataSource] respondsToSelector:@selector(tableView:dragImageForTableColumn:row:)])
        dragImage = [[[self dataSource] tableView:self dragImageForTableColumn:nil row:dragSourceRow] retain];
    
    if (dragImage == nil) {
        // Cache an image for the current row
        cachedImageRep = [[NSCachedImageRep alloc] initWithSize:imageFrame.size depth:[[NSScreen mainScreen] depth] separate:YES alpha:YES];
        contentView = [[cachedImageRep window] contentView];
    
        [contentView lockFocus];
        {
            int columnIndex, columnCount;
        
            [[NSColor colorWithDeviceWhite:0.0 alpha:0.0] set];
            NSRectFillUsingOperation(imageFrame, NSCompositeCopy);
    
            columnCount = [self numberOfColumns];
            for (columnIndex = 0; columnIndex < columnCount; columnIndex++) {
                NSTableColumn *tableColumn;
                NSCell *cell;
                NSRect cellRect;
                id objectValue;
                
                tableColumn = [[self tableColumns] objectAtIndex:columnIndex];
                objectValue = [[self dataSource] tableView:self objectValueForTableColumn:tableColumn row:dragSourceRow];
    
                cellRect = [self frameOfCellAtColumn:columnIndex row:dragSourceRow];
                cellRect.origin = NSMakePoint(NSMinX(cellRect) - xOffsetOfFirstColumn, 0);
                cell = [tableColumn dataCellForRow:dragSourceRow];
                
                if ([objectValue isKindOfClass:[NSString class]])
                    [objectValue drawOutlinedWithFont:nil color:nil backgroundColor:nil rectangle:[cell titleRectForBounds:cellRect]];
                else {
                    [cell setCellAttribute:NSCellHighlighted to:0];
                    [cell setObjectValue:objectValue];
            
                    [cell drawWithFrame:cellRect inView:contentView];
                }
            }
        }
        [contentView unlockFocus];
    
        dragImage = [[NSImage alloc] init];
        [dragImage addRepresentation:cachedImageRep];
        [cachedImageRep release];
    }
    
    // Let's start the drag.
    pasteboard = [NSPasteboard pasteboardWithName: NSDragPboard];
    [[self dataSource] tableView:self copyObjectValueForTableColumn:[[self tableColumns] objectAtIndex:0] row:dragSourceRow toPasteboard:pasteboard];
    
    [self dragImage:dragImage at:NSMakePoint(NSMinX(rowFrame)+xOffsetOfFirstColumn, NSMaxY(rowFrame) - 1) offset:NSMakeSize(0, 0) event:event pasteboard:pasteboard source:self slideBack:YES];

    [dragImage release];
    
    [self selectRow:selectedRow byExtendingSelection:NO];
}

@end


// Fix a bug in NSTableView (#2654382).
// If the user clicks in a cell which is a popup menu, the click will drag the row instead of popping up the menu.
// Supposedly this method may become public at some point, at which time we should reevaluate this code.
// (NOTE: This is part of NSTableView's new dragging implementation, not ours implemented above!)

@interface NSTableView (PrivateAppKit)

- (BOOL)_dragShouldBeginFromMouseDown: (NSEvent *)theEvent;

@end

@implementation OATableView (PrivateAppKitOverride)

- (BOOL)_dragShouldBeginFromMouseDown: (NSEvent *)theEvent
{
    NSPoint locationInView;
    int columnIndex;
    
    locationInView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    columnIndex = [self columnAtPoint:locationInView];
    if (columnIndex >= 0) {
        NSTableColumn *tableColumn;
        int row;
        NSCell *dataCell;
 
        tableColumn = [[self tableColumns] objectAtIndex:columnIndex];
        row = [self rowAtPoint:locationInView];
        dataCell = [tableColumn dataCellForRow:row];

        if ([dataCell isKindOfClass:[NSPopUpButtonCell class]])
            return NO;
        // We should probably check for other kinds of cells, like NSButtonCell in general. Anything that does anything in response to one click.
    }

    return [super _dragShouldBeginFromMouseDown:theEvent];
}

@end
