// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAShelfView.m,v 1.5 2003/02/12 22:01:15 kc Exp $

#import "OAShelfView.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "OAPasteboardHelper.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAShelfView.m,v 1.5 2003/02/12 22:01:15 kc Exp $")

@interface OAShelfView (Private)
- (NSRect)rectForSpaceAtPoint:(NSPoint)point;
- (void)_declareDragging;
- (void)_resizeContents;
@end

@implementation OAShelfView

static BOOL draggedOutOfAShelf = NO;
static BOOL droppedOntoAnotherShelf = NO;

#define SPACE_INDEX(x,y)   ((spacesAcross * (y)) + (x))
#define CONTENTS(x,y)	   (contents[SPACE_INDEX(x,y)])
#define SELECTED(x,y)	   (selected[SPACE_INDEX(x,y)])

- initWithFrame:(NSRect)frameRect
{
    if (![super initWithFrame:frameRect])
        return nil;

    spaceSize.width = 60;
    spaceSize.height = 80;
    contents = NSZoneCalloc(NULL, 1, sizeof(id));
    selected = NSZoneCalloc(NULL, 1, sizeof(BOOL));
    spacesAcross = 1;
    spacesDown = 1;
    totalSpaces = spacesAcross * spacesDown;
    [self _resizeContents];
    [self _declareDragging];

    return self;
}

- (BOOL)isFlipped;
{
    return YES;
}

- (void)awakeFromNib
{
    [self _declareDragging];
}

- (void)dealloc;
{
    [draggingObjects release];
    NSZoneFree(NULL, contents);
    NSZoneFree(NULL, selected);
    [super dealloc];
}

// Setup

- (void)setSpaceSize:(NSSize)size
{
    spaceSize = size;
    [self _resizeContents];
    [self setNeedsDisplay: YES];
}

- (void)setDelegate:(id <OAShelfViewDelegate>)aDelegate;
{
    delegate = aDelegate;
}

- (void)setFormatter:(id <OAShelfViewFormatter>)aFormatter;
{
    if (formatter == aFormatter)
	return;
    [formatter release];
    formatter = [aFormatter retain];
    [self setNeedsDisplay:YES];
}

- (void)setDragSupport:(id <OAShelfViewDragSupport>)aDragSupport;
{
    dragSupport = [aDragSupport retain];
    [self _declareDragging];
}

- (void)setMoveOnDrag:(BOOL)newMoveOnDrag;
{
    flags.moveOnDrag = newMoveOnDrag;
}

- (void)setEntry:(id)anEntry selected:(BOOL)isSelected atRow:(unsigned int)row andColumn:(unsigned int)column;
{
    NSSize newSize = [self bounds].size;
    BOOL resize = NO;
    id oldEntry;

    if (spacesAcross <= column) {
	newSize.width = (column+1)*spaceSize.width;
	resize = YES;
    }
    if (spacesDown <= row) {
	newSize.height = (row+1)*spaceSize.height;
	resize = YES;
    }
    if (resize)
	[self setFrameSize:newSize];
    if ((oldEntry = CONTENTS(column,row))) {
        [delegate shelfView:self willRemoveEntry:oldEntry];
        [oldEntry release];
    }
    if (anEntry) {
        [delegate shelfView:self willAddEntry:anEntry];
        [anEntry retain];
    }
    CONTENTS(column,row) = anEntry;
    SELECTED(column,row) = isSelected;
    [self setNeedsDisplay: YES];
}

- (unsigned int)addEntries:(NSArray *)entries entryIndex:(unsigned int)entryIndex selected:(BOOL)isSelected startIndex:(unsigned int)start endIndex:(unsigned int)end;
{
    unsigned int spaceIndex;
    NSObject *anEntry;

    for (spaceIndex = start; spaceIndex <= end; spaceIndex++) {
        if (!contents[spaceIndex]) {
            anEntry = [entries objectAtIndex:entryIndex];
            [delegate shelfView:self willAddEntry:anEntry];
            contents[spaceIndex] = [anEntry retain];
            selected[spaceIndex] = isSelected;
            if (++entryIndex == [entries count])
                break;
        }
    }
    return entryIndex;
}

- (void)addEntries:(NSArray *)entries selected:(BOOL)isSelected atRow:(unsigned int)row andColumn:(unsigned int)column;
{
    unsigned int spaceIndex, startSpaceIndex, endOfVisibleSpaces;
    unsigned int entryIndex, entryCount;
    unsigned int newLength;
    NSObject *anEntry;

    [self setNeedsDisplay: YES];

    entryIndex = 0;
    entryCount = [entries count];
    startSpaceIndex = SPACE_INDEX(column,row);
    endOfVisibleSpaces = SPACE_INDEX(spacesAcross-1,spacesDown-1);

    // Start from requested location and add entries in blanks
    entryIndex = [self addEntries:entries entryIndex:entryIndex selected:isSelected startIndex:startSpaceIndex endIndex:endOfVisibleSpaces];
    if (entryIndex == entryCount)
        return;

    // Go back to the beginning and try again
    entryIndex = [self addEntries:entries entryIndex:entryIndex selected:isSelected startIndex:0 endIndex:startSpaceIndex];
    if (entryIndex == entryCount)
        return;

    // Add any more entries off the end of the visible spaces
    entryIndex = [self addEntries:entries entryIndex:entryIndex selected:isSelected startIndex:endOfVisibleSpaces endIndex:totalSpaces-1];
    if (entryIndex == entryCount)
        return;

    // If there aren't enough spaces, extend the arrays
    newLength = totalSpaces + (entryCount - entryIndex);
    contents = NSZoneRealloc(NULL, contents, newLength * sizeof(id));
    selected = NSZoneRealloc(NULL, selected, newLength * sizeof(BOOL));
    for (spaceIndex = totalSpaces; spaceIndex < newLength; spaceIndex++) {
        anEntry = [entries objectAtIndex:entryIndex];
        [delegate shelfView:self willAddEntry:anEntry];
        contents[spaceIndex] = [anEntry retain];
        selected[spaceIndex] = isSelected;
    }
    totalSpaces = newLength;
}

- (BOOL)moveOnDrag;
{
    return flags.moveOnDrag;
}

- (NSSize)spaceSize;
{
    return spaceSize;
}

- (NSMutableArray *)selection;
{
    unsigned int across, down;
    NSMutableArray *selection;

    selection = [NSMutableArray array];
    for (across = 0; across < spacesAcross; across++)
	for (down = 0; down < spacesDown; down++)
	    if (SELECTED(across, down))
                [selection addObject:CONTENTS(across,down)];
    return selection;
}

- (id <OAShelfViewFormatter>)formatter;
{
    return formatter;
}

- (id <OAShelfViewDelegate>)delegate;
{
    return delegate;
}

// Target-action

- (IBAction)selectAll:(id)sender;
{
    unsigned int across, down;

    for (across = 0; across < spacesAcross; across++)
	for (down = 0; down < spacesDown; down++)
	    if (CONTENTS(across, down))
		SELECTED(across, down) = YES;
    [self setNeedsDisplay:YES];
}

- (IBAction)copy:(id)sender;
{
    OAPasteboardHelper *helper;

    helper = [OAPasteboardHelper helperWithPasteboardNamed:NSGeneralPboard];
    [dragSupport declareTypesForEntries:[self selection] pasteboardHelper:helper];
}

- (IBAction)paste:(id)sender;
{
    NSPasteboard *pasteboard;
    NSString *type;
    id propertyList;
    NSArray *results;

    pasteboard = [NSPasteboard generalPasteboard];
    type = [pasteboard availableTypeFromArray:[dragSupport acceptedPasteboardTypes]];
    if (!type)
        return;
    propertyList = [pasteboard propertyListForType:type];
    if (!propertyList)
        return;
    results = [dragSupport entriesFromPropertyList:propertyList ofType:type];
    if ([results count]) {
        int startRow, startColumn = 0;
        BOOL foundSelection = NO;

        // scan backwards for last selected cell
        for (startRow = spacesDown - 1; startRow >= 0; startRow--) {
            for (startColumn = spacesAcross - 1; startColumn >= 0; startColumn--) {
                if ((foundSelection = SELECTED(startColumn, startRow)))
                    break;
            }
            if (foundSelection)
                break;
        }
        if (!foundSelection) {
            // there was no selection, so just start from the top
            startRow = 0;
            startColumn = 0;
        } else {
            // clear the existing selection
            unsigned int a, d;

            for (a = 0; a < spacesAcross; a++)
                for (d = 0; d < spacesDown; d++)
                    SELECTED(a, d) = NO;
        }
        [self addEntries:results selected:YES atRow:startRow andColumn:startColumn];
        [self setNeedsDisplay:YES];
    }
}

- (IBAction)cut:(id)sender;
{
    [self copy:sender];
    [self delete:sender];
}

- (IBAction)delete:(id)sender;
{
    unsigned int a, d;
    NSObject *entry;

    for (a = 0; a < spacesAcross; a++) {
        for (d = 0; d < spacesDown; d++) {
            if (SELECTED(a, d)) {
                entry = CONTENTS(a,d);
                [delegate shelfView:self willRemoveEntry:entry];
                [entry release];
                CONTENTS(a,d) = nil;
                SELECTED(a,d) = NO;
            }
        }
    }
    [self setNeedsDisplay:YES];
}

// Get state out for saving

- (unsigned int)rows;
{
    return spacesDown;
}

- (unsigned int)columns;
{
    return spacesAcross;
}

- (id)entryAtRow:(unsigned int)aRow column:(unsigned int)aColumn;
{
    return CONTENTS(aColumn, aRow);
}

- (BOOL)selectedAtRow:(unsigned int)aRow column:(unsigned int)aColumn;
{
    return SELECTED(aColumn, aRow);
}

// NSView subclass

- (void)setFrameSize:(NSSize)_newSize
{
    [super setFrameSize:_newSize];
    [self _resizeContents];
    [self setNeedsDisplay: YES];
}

- (void)drawRect:(NSRect)rect;
{
    NSRect position, bounds, frame;
    float extraWidthOffset;
    int across, down, startDown;
    int lastAcross, lastDown;
    NSObject *entry;

    [formatter drawBackground:rect ofShelf:self];

    bounds = [self bounds];
    frame = [self frame];

    // Call formatter to draw neccesary spaces
    extraWidthOffset = ((int)bounds.size.width % (int)spaceSize.width) / 2;
    across = (NSMinX(rect) - NSMinX(bounds) - extraWidthOffset) / spaceSize.width;
    lastAcross = (NSMaxX(rect) + spaceSize.width - 1 - NSMinX(bounds) - extraWidthOffset) / spaceSize.width;
    if (lastAcross >= (int)spacesAcross)
	lastAcross = spacesAcross - 1;

    startDown = (NSMinY(rect) - NSMinY(bounds)) / spaceSize.height;
    lastDown = (NSMaxY(rect) + spaceSize.height - 1 - NSMinY(bounds)) / spaceSize.height;
    if (lastDown >= (int)spacesDown)
	lastDown = spacesDown - 1;
    position.size = spaceSize;

    while (across <= lastAcross) {
	position.origin.x = NSMinX(frame) + (across * spaceSize.width) + extraWidthOffset;
	down = startDown;
	while (down <= lastDown) {
	    position.origin.y = NSMinY(frame) + (down * spaceSize.height);
            entry = CONTENTS(across, down);
            if (draggingObjects && !entry && NSPointInRect(dragPoint, position)) {
                [formatter drawEntry:[draggingObjects objectAtIndex:0] inRect:position ofShelf:self selected:NO dragging:YES];
            } else {
                [formatter drawEntry:entry inRect:position ofShelf:self selected:SELECTED(across,down) dragging:NO];
	    }
	    down++;
	}
	across++;
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
{
    return YES;
}

- (BOOL)acceptsFirstResponder;
{
    return YES;
}

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)anEvent;
{
    return YES;
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal;
{
    return NSDragOperationAll;
}

- (BOOL)ignoreModifierKeysWhileDragging;
{
    return YES;
}

- (void)keyDown:(NSEvent *)event 
{
    NSString *eventCharacters;
    unsigned int characterIndex, characterCount;

    eventCharacters = [event characters];
    characterCount = [eventCharacters length];
    for (characterIndex = 0; characterIndex < characterCount; characterIndex++) {
        unichar key;
        BOOL okay;

        key = [eventCharacters characterAtIndex:characterIndex];
        switch (key) {
            case NSDeleteFunctionKey:
            case NSDeleteCharFunctionKey:
            case '\177': // Delete
            case '\b': // Backspace
                [self delete:self];
                okay = YES;
                break;
            default:
                okay = [delegate shelfView:self didGetKey:key];
                break;
        }
        if (!okay)
            NSBeep();
    }
}

- (void)mouseDown:(NSEvent *)event;
{
    // If dragging begins, drag the thing; otherwise select or deselect it
    NSRect bounds;
    NSPoint point;
    unsigned int across, down;
    id clickedEntry;
    float extraWidthOffset;

    point = [self convertPoint:[event locationInWindow] fromView:nil];
    bounds = [self bounds];
    extraWidthOffset = ((int)bounds.size.width % (int)spaceSize.width) / 2;
    across = (point.x - NSMinX(bounds) - extraWidthOffset) / spaceSize.width;
    down = (point.y - NSMinY(bounds)) / spaceSize.height;

    if (across >= spacesAcross || down >= spacesDown || !(clickedEntry = CONTENTS(across, down)))
	return;

    if ([event type] != NSLeftMouseDown)
        return;

    if (!([event modifierFlags] & (NSCommandKeyMask | NSShiftKeyMask))) {
        // turn off every other selection
        unsigned int a, d;

        for (a = 0; a < spacesAcross; a++)
            for (d = 0; d < spacesDown; d++)
                SELECTED(a, d) = NO;
        SELECTED(across, down) = YES;
    } else
        SELECTED(across, down) = !SELECTED(across, down);
    [delegate shelfViewSelectionChanged:self];
    [self display];

    if ([self shouldStartDragFromMouseDownEvent:event dragSlop:10 finalEvent:NULL]) {
        OAPasteboardHelper *helper;
        NSImage *dragImage;
        NSSize imageSize;
        NSPoint where;
        BOOL disappear;

        dragImage = [dragSupport dragImageForEntry:clickedEntry];
        disappear = flags.moveOnDrag && !([event modifierFlags] & NSAlternateKeyMask) && !([event modifierFlags] & NSShiftKeyMask);

        where = [self convertPoint:[event locationInWindow] fromView:nil];

        imageSize = [dragImage size];
        where.x -= imageSize.width / 2;
        where.y += imageSize.height / 2;

        dragOutObject = clickedEntry;
        helper = [OAPasteboardHelper helperWithPasteboardNamed:NSDragPboard];
        if (disappear) {
            CONTENTS(across,down) = nil;
            SELECTED(across,down) = NO;
            [delegate shelfViewChanged:self];
        }
        draggedOutOfAShelf = YES;
        [dragSupport startDragOnEntry:clickedEntry fromView:self image:dragImage atPoint:where event:event pasteboardHelper:helper];
        if (disappear) {
            if (!droppedOntoAnotherShelf)
                [delegate shelfView:self willRemoveEntry:dragOutObject];
            [dragOutObject release];
            dragOutObject = nil;
        }
        draggedOutOfAShelf = NO;
        droppedOntoAnotherShelf = NO;
    } else {
        if ([event clickCount] > 1)
            [delegate shelfViewDoubleClick:self onEntry:clickedEntry];
        else
            [delegate shelfViewClick:self onEntry:clickedEntry];
    }
}

// NSPasteboardOwner informal protocol

- (void)pasteboard:(NSPasteboard *)pasteboard provideDataForType:(NSString *)type;
{
}

// NSDraggingDestination informal protocol

- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender;
{
    NSPasteboard *pasteboard;
    NSArray *types;
    NSString *type;
    id propertyList;

    pasteboard = [sender draggingPasteboard];
    types = [dragSupport acceptedPasteboardTypes];
    type = [pasteboard availableTypeFromArray:types];
    propertyList = [pasteboard propertyListForType:type];
    if (!propertyList)
	return NSDragOperationNone;

    draggingObjects = [[dragSupport entriesFromPropertyList:propertyList ofType:type] retain];

    dragPoint = [sender draggingLocation];
    dragPoint = [self convertPoint:dragPoint fromView:nil];

    return [self draggingUpdated:sender];
}

- (unsigned int)draggingUpdated:(id <NSDraggingInfo>)sender;
{
    NSRect dragRect, newRect, bothRects, bounds;
    NSPoint newPoint;
    unsigned int dragAcross, dragDown;
    float extraWidthOffset;

    bounds = [self bounds];
    newPoint = [sender draggingLocation];

    newPoint = [self convertPoint:newPoint fromView:nil];
    dragRect = [self rectForSpaceAtPoint:dragPoint];
    newRect = [self rectForSpaceAtPoint:newPoint];
    bothRects = NSUnionRect(dragRect, newRect);
    dragPoint = newPoint;

 //   [self displayRect:bothRects];
    [self setNeedsDisplay:YES];

    extraWidthOffset = ((int)bounds.size.width % (int)spaceSize.width) / 2;
    dragAcross = (dragPoint.x - NSMinX(bounds) - extraWidthOffset) / spaceSize.width;
    dragDown = (dragPoint.y - NSMinX(bounds)) / spaceSize.height;
    if ((dragAcross >= spacesAcross) || (dragDown >= spacesAcross))
        return NSDragOperationNone;
    return NSDragOperationGeneric;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender;
{
    [draggingObjects release];
    draggingObjects = nil;
    [self displayRect:[self rectForSpaceAtPoint:dragPoint]];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
{
    if (draggedOutOfAShelf)
        droppedOntoAnotherShelf = YES;
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
{
    NSRect bounds;
    unsigned int dragAcross, dragDown;
    float extraWidthOffset;

    bounds = [self bounds];
    extraWidthOffset = ((int)bounds.size.width % (int)spaceSize.width) / 2;
    dragAcross = (dragPoint.x - NSMinX(bounds) - extraWidthOffset) / spaceSize.width;
    dragDown = (dragPoint.y - NSMinX(bounds)) / spaceSize.height;

    [self addEntries:draggingObjects selected:NO atRow:dragDown andColumn:dragAcross];
    draggingObjects = nil;
    [self setNeedsDisplay:YES];
    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;
{
    [delegate shelfViewChanged:self];
}

@end

@implementation OAShelfView (Private)

- (NSRect)rectForSpaceAtPoint:(NSPoint)point;
{
    unsigned int across, down;
    NSRect bounds, spaceRect;
    float extraWidthOffset;

    bounds = [self bounds];
    extraWidthOffset = ((int)bounds.size.width % (int)spaceSize.width) / 2;
    across = (point.x - NSMinX(bounds) - extraWidthOffset) / spaceSize.width;
    down = (point.y - NSMinY(bounds)) / spaceSize.height;
    spaceRect.size = spaceSize;
    spaceRect.origin.x = (across * spaceSize.width) + NSMinX(bounds) + extraWidthOffset;
    spaceRect.origin.y = (down * spaceSize.height) + NSMinY(bounds);
    return spaceRect;
}

- (void)_declareDragging;
{
    NSArray *types;

    types = [dragSupport acceptedPasteboardTypes];
    if ([types count])
	[self registerForDraggedTypes:types];
}

- (void)_resizeContents;
{
    NSRect bounds;
    unsigned int newAcross, newDown;
    unsigned int newLength, index;

    bounds = [self bounds];
    newAcross = NSWidth(bounds) / spaceSize.width;
    newDown = NSHeight(bounds) / spaceSize.height;
    spacesAcross = newAcross ? newAcross : 1;
    newLength = newAcross * newDown;
    spacesDown = (newLength + spacesAcross - 1) / spacesAcross;

    if (newLength > totalSpaces) {
	contents = NSZoneRealloc(NULL, contents, newLength * sizeof(id));
	for (index = totalSpaces; index < newLength; index++)
	    contents[index] = nil;
        selected = NSZoneRealloc(NULL, selected, newLength * sizeof(BOOL));
	for (index = totalSpaces; index < newLength; index++)
	    selected[index] = NO;
	totalSpaces = newLength;
    }
}

@end
