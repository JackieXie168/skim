// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OAOutlineView.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

#import <OmniAppKit/OAPasteboardHelper.h>
#import <OmniAppKit/OADragController.h>
#import <OmniAppKit/OAOutlineEntry.h>
#import <OmniAppKit/NSView-OAExtensions.h>
#import <OmniAppKit/OAFindPattern.h>

#import "OAOutlineDragPoint.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineView.m,v 1.30 2003/01/15 22:51:40 kc Exp $")

@interface OAOutlineView (Private)
- (BOOL)_willAdd:(OAOutlineEntry *)entry;
- (void)_didAdd:(OAOutlineEntry *)entry;
// Dragging help
- (void)findDragSpot:(NSPoint)dragLocation;
- (void)_registerForDragging;
- (OAOutlineEntry *)_entryFromInfoDictionary:(NSDictionary *)info ofType:(NSString *)type;
- (OAOutlineEntry *)_singleEntryFromPasteboard:(NSPasteboard *)pasteboard;
- (void)_moveScroller;
@end

@implementation OAOutlineView

// pixels to tab in for each level
#define DEFAULT_TAB_WIDTH       20
// empty border around list
#define DEFAULT_BORDER_WIDTH     5

NSString *OAOutlineSubListPasteboardType = @"OAOutlineView1.0 sublist";

- initWithFrame:(NSRect)aFrame;
{
    if (![super initWithFrame:aFrame])
	return nil;

    tabWidth = DEFAULT_TAB_WIDTH;
    borderWidth = DEFAULT_BORDER_WIDTH;
    lastTyped = [[NSDate distantPast] retain];
    topLevelEntry = [[OAOutlineEntry alloc] initInView:self];
    flags.enableScroll = NO;
    flags.editable = YES;
    flags.selectable = YES;
    flags.hierarchical = YES;
    flags.internalDrag = NO;
    flags.allowDraggingOut = YES;
    flags.allowDraggingIn = YES;
    flags.dragEntireSublists = YES;
    flags.acceptEntireSublists = YES;
    delegate = nil;

    return self;
}

- (void)dealloc;
{
    [dragPoints release];
    [topLevelEntry release];
    OBASSERT(dragEntry == nil);  // Unless we get deallocated in a drag, which would be bad
    [typed release];
    [lastTyped release];
    [dragSupport release];
    [sublistPasteboardTypes release];
    [formatter release];

    [super dealloc];
}



// NSResponder subclass

- (void)mouseDown:(NSEvent *)event 
{
    NSRect theRect = [self bounds];

    theRect.origin.x += borderWidth;
    theRect.origin.y += borderWidth;
    theRect.size.width -= borderWidth;
    theRect.size.height -= borderWidth*2;
    [[self window] makeFirstResponder:self];

    [topLevelEntry trackMouse:event inRect:theRect ofEntry:nil];
}

#define TYPING_DELAY	1.0

- (void)keyDown:(NSEvent *)event 
{
    OAOutlineEntry *holder;
    BOOL okay = NO;
    OAOutlineEntry *oldSelection, *newSelection = nil;
    OAFindPattern *pattern;
    NSString *eventCharacters;
    unsigned int characterIndex, characterCount;

    holder = [nonretainedSelectedEntry parentEntry];
    eventCharacters = [event characters];
    characterCount = [eventCharacters length];
    for (characterIndex = 0;
         characterIndex < characterCount;
         characterIndex++) {
        unichar key;

        key = [eventCharacters characterAtIndex:characterIndex];
        switch (key) {
            case '\t':
            case NSRightArrowFunctionKey:
                if (nonretainedSelectedEntry && flags.editable && flags.hierarchical)
                    okay = [holder demoteEntry:nonretainedSelectedEntry];
                break;
            case '\031': // Backtab (overloaded ^y).
            case NSLeftArrowFunctionKey:
                if (nonretainedSelectedEntry && flags.editable && flags.hierarchical)
                    okay = [holder promoteEntry:nonretainedSelectedEntry];
                break;
            case NSUpArrowFunctionKey:
                if (flags.selectable && nonretainedSelectedEntry && (newSelection = [nonretainedSelectedEntry previousVisibleEntry])) {
                    [self setSelectionTo:newSelection];
                    okay = YES;
                }
                break;
            case NSDownArrowFunctionKey:
                if (flags.selectable && nonretainedSelectedEntry && (newSelection = [nonretainedSelectedEntry nextVisibleEntry])) {
                    [self setSelectionTo:newSelection];
                    okay = YES;
                }
                break;
            case NSDeleteFunctionKey:
            case NSDeleteCharFunctionKey:
            case '\177': // Delete
            case '\b': // Backspace
                if (nonretainedSelectedEntry) {
                    [self removeItem:self];
                    okay = YES;
                }
                break;
            case '\r': // Carriage return
            case '\n': // Newline
                [self insertItem:self];
                okay = YES;
                break;
            default:
                if ((flags.delegateDidGetKey && [delegate outlineView:self didGetKey:key]) || !flags.allowAutoFinding) {
                    break;
                }

                if (-[lastTyped timeIntervalSinceNow] > TYPING_DELAY) {
                    [typed release];
                    typed = [eventCharacters retain];
                } else {
                    [typed appendString:eventCharacters];
                }
                [lastTyped release];
                lastTyped = [[NSDate alloc] init];
                oldSelection = nonretainedSelectedEntry;
                nonretainedSelectedEntry = nil;
                pattern = [[OAFindPattern alloc] initWithString:typed ignoreCase:YES wholeWord:NO backwards:NO];
                if (![self findPattern:pattern backwards:NO wrap:YES]) {
                    nonretainedSelectedEntry = oldSelection;
                }
                [pattern release];
                break;
        }
    }
    if (!okay)
        NSBeep();
}


// NSView subclass

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
{
    return YES;
}

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)anEvent 
{
    return YES;
}

- (BOOL)isFlipped;
{
    return YES;
}

- (BOOL)needsDisplay;
{
    // Hack, but clever: If auto-display is turned on, we should get called with -needsDisplay before -display is ever called, which gives us a chance to recalculate our heights lazily but still do it BEFORE -display determines the dirty rect and calls -drawRect:.  Note that I left the check in -drawRect:, as well, because there are still situations in which drawRect: could be called without -needsDisplay and with the pendingHeightRecalculation.

    if ([super needsDisplay]) {
        if (flags.hasPendingHeightRecalculation) {
            // We need to recalc our line heights before we draw
            [self recalculateHeightIfNeeded];
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)drawRect:(NSRect)rect;
{
    NSRect listBounds;

    if (flags.hasPendingHeightRecalculation) {
        // We need to recalc our line heights before we draw
        [self recalculateHeightIfNeeded];
        // Redraw everything in sight
        rect = [self visibleRect];
        // Since we were called before heights were recalced, we reset this flag
        // so setNeedsDisplay: will get called later and we'll redraw fully.
        flags.hasPendingHeightRecalculation = YES;
    }
    
    [[self backgroundColor] set];
    NSRectFill(rect);
    listBounds = NSInsetRect([self bounds], borderWidth, borderWidth);
    [topLevelEntry drawRect:rect entryRect:listBounds];
    if (dragEntry && nonretainedCurrentDragPoint) {
        listBounds.origin.x = [nonretainedCurrentDragPoint x];
        listBounds.origin.y = [nonretainedCurrentDragPoint y] - [dragEntry entryHeight] / 2.0;
        listBounds.size.height = [dragEntry entryHeight];
        listBounds.size.width = NSMaxX([self bounds]) - [nonretainedCurrentDragPoint x];
        [dragEntry dragDraw:listBounds inEntry:[nonretainedCurrentDragPoint entry]];
        listBounds.size.width -= 1.0;
    }
}


// NSNibAwaking informal protocol

- (void)awakeFromNib;
{
    NSView *superview;
    id newFormatter;
    id newDragSupport;

    [self setDelegate:delegate];

    // Ken suspects this outlet swizzling is completely unnecessary because the nib should have called -setFormatter: and -setDragSupport: to hook up those outlets in the first place.

    newFormatter = formatter; // inherit retain
    formatter = nil;
    [self setFormatter:newFormatter];
    [newFormatter release];

    newDragSupport = dragSupport; // inherit retain
    dragSupport = nil;
    [self setDragSupport:newDragSupport];
    [newDragSupport release];

    // End of unnecessary outlet swizzling

    [self setAutoresizingMask:NSViewWidthSizable];
    [self setAutoresizesSubviews:YES];
    superview = [self superview];
    if ([superview isKindOfClass:[NSClipView class]]) {
        [superview setAutoresizingMask:NSViewWidthSizable];
        [superview setAutoresizesSubviews:YES];
    }
}


// API

- (OAOutlineEntry *)topLevelEntry;
{
    return topLevelEntry;
}

- (void)setTopLevelEntry:(OAOutlineEntry *)anEntry;
{
    if (topLevelEntry == anEntry)
	return;

    [self setSelectionTo:nil];
    
    [topLevelEntry setOutlineView:nil];
    [topLevelEntry release];

    topLevelEntry = [anEntry retain];
    [topLevelEntry setOutlineView:self];

    [self markNeedsHeightRecalculationAndDisplay];
}

- (id <NSObject, OAOutlineFormatter>)formatter;
{
    return formatter;
}

- (void)setFormatter:(id <NSObject, OAOutlineFormatter>)aFormatter;
{
    if (formatter == aFormatter)
	return;
    [formatter release];
    formatter = [aFormatter retain];
    flags.formatterIsFindable = [formatter conformsToProtocol:@protocol(OAOutlineFindableFormatter)];
    flags.formatterIsEditable = [formatter conformsToProtocol:@protocol(OAOutlineEditableFormatter)];
    [topLevelEntry setFormatter:formatter];
}

- (id <NSObject, OAOutlineDragSupport>)dragSupport;
{
    return dragSupport;
}

- (void)registerWindowForDrags;
{
    NSArray *acceptedTypes;

    acceptedTypes = [dragSupport outlineViewAcceptedPasteboardTypes:self];

    if ([acceptedTypes count] > 0) {
        [[self window] registerForDraggedTypes:acceptedTypes];

        if (flags.acceptEntireSublists)
            [[self window] registerForDraggedTypes:sublistPasteboardTypes];
        [self unregisterDraggedTypes];
    }
}

- (void)setDragSupport:(id <NSObject, OAOutlineDragSupport>)aSupport;
{
    NSString *type;

    if (dragSupport == aSupport)
	return;
    [dragSupport release];
    dragSupport = [aSupport retain];

    [sublistPasteboardTypes release];
    type = [[NSString alloc] initWithFormat:@"%@%@", OAOutlineSubListPasteboardType, NSStringFromClass([dragSupport class])];
    sublistPasteboardTypes = [[NSArray alloc] initWithObjects:type, nil];
    [type release];

    [self _registerForDragging];
}
	
- (OAOutlineEntry *)entryWithChildrenFromPasteboard:(NSPasteboard *)pasteboard;
{
    OAOutlineEntry *result = nil;
    NSString *sublistPasteboardType;

    sublistPasteboardType = [pasteboard availableTypeFromArray:sublistPasteboardTypes];
    if (flags.acceptEntireSublists && sublistPasteboardType) {
        NSDictionary *info;

        info = [pasteboard propertyListForType:sublistPasteboardType];
        if (!info || ![info count])
            return nil;

        sublistPasteboardType = [[dragSupport outlineViewAcceptedPasteboardTypes:self] objectAtIndex:0];
        result = [self _entryFromInfoDictionary:info ofType:sublistPasteboardType];
    }
    if (!result)
        result = [self _singleEntryFromPasteboard:pasteboard];

    return result;
}

- (BOOL)isEditable;
{
    return flags.editable;
}

- (void)setEditable:(BOOL)newEditable;
{
    flags.editable = newEditable;
}

- (NSColor *)backgroundColor;
{
    return [(NSScrollView *)[self superview] backgroundColor];
}

- (void)setBackgroundColor:(NSColor *)aColor;
{
    [(NSScrollView *)[self superview] setBackgroundColor:aColor];
}

- (BOOL)isHierarchical;
{
    return flags.hierarchical;
}

- (void)setHierarchical:(BOOL)newHierarchical;
{
    flags.hierarchical = newHierarchical;
}

- (BOOL)isSelectable;
{
    return flags.selectable;
}

- (void)setSelectable:(BOOL)newSelectable;
{
    flags.selectable = newSelectable;
}

- (BOOL)doesAllowDraggingOut
{
    return flags.allowDraggingOut && dragSupport;
}
	
- (void)allowDraggingOut:(BOOL)newAllowDraggingOut;
{
    flags.allowDraggingOut = newAllowDraggingOut;
}

- (BOOL)doesAllowDraggingIn;
{
    return flags.allowDraggingIn && dragSupport;
}

- (void)allowDraggingIn:(BOOL)newAllowDraggingIn;
{
    flags.allowDraggingIn = newAllowDraggingIn;
}

- (BOOL)doesDragEntireSublists;
{
    return flags.dragEntireSublists;
}

- (void)dragEntireSublists:(BOOL)newDragEntireSublists;
{
    flags.dragEntireSublists = newDragEntireSublists;
}

- (BOOL)doesAcceptEntireSublists;
{
    return flags.acceptEntireSublists;
}

- (void)acceptEntireSublists:(BOOL)newAcceptEntireSublists;
{
    if (flags.acceptEntireSublists == newAcceptEntireSublists)
	return;
    flags.acceptEntireSublists = newAcceptEntireSublists;
    if (dragSupport)
	[self _registerForDragging];
}

- (BOOL)doesAllowAutomaticFind;
{
    return flags.allowAutoFinding;
}

- (void)allowAutomaticFind:(BOOL)newAllowAutomaticFind;
{
    flags.allowAutoFinding = newAllowAutomaticFind;
}

- (OAOutlineEntry *)dragEntry;
{
    return dragEntry;
}

- (void)setTabWidth:(float)aWidth;
{
    tabWidth = aWidth;
    [self markNeedsHeightRecalculationAndDisplay];
}

- (float)tabWidth;
{
    return tabWidth;
}

- (void)setBorderWidth:(float)aWidth;
{
    borderWidth = aWidth;
    [self markNeedsHeightRecalculationAndDisplay];
}

- (float)borderWidth;
{
    return borderWidth;
}

- (BOOL)isOriginalDragPoint;
{
    NSArray *array;
    unsigned int dragSpotIndex;

    array = [[nonretainedCurrentDragPoint entry] childEntries];
    dragSpotIndex = [nonretainedCurrentDragPoint index];
    return flags.internalDrag && dragSpotIndex < [array count] && [array objectAtIndex:dragSpotIndex] == dragEntry;
}

- (void)markNeedsHeightRecalculationAndDisplay;
{
    if (flags.hasPendingHeightRecalculation)
        return;

    flags.hasPendingHeightRecalculation = YES;
    [self performSelector:@selector(recalculateHeightIfNeeded) withObject:nil afterDelay:0.0];
}

- (void)recalculateHeightIfNeeded;
{
    NSRect currentFrame;
    float newHeight;

    // Someone else beat us to it.
    if (!flags.hasPendingHeightRecalculation)
        return;

    if (topLevelEntry) {
        [topLevelEntry recalculateHeight];
        newHeight = [topLevelEntry entryHeight] + borderWidth * 2.0;
    } else
        newHeight = 0;
    currentFrame = [self frame];
    if (NSHeight(currentFrame) != newHeight + 2.0)
        [self setFrameSize:NSMakeSize(NSWidth(currentFrame), newHeight + 2.0)];
    flags.hasPendingHeightRecalculation = NO;
    [self setNeedsDisplay:YES];
}

- (void)setSelectionTo:(OAOutlineEntry *)anEntry;
{
    if (nonretainedSelectedEntry == anEntry)
        return;
        
    if (flags.delegateWillSelect)
        [delegate outlineView:self willSelectEntry:anEntry];

    nonretainedSelectedEntry = anEntry;
    [self markNeedsHeightRecalculationAndDisplay];

    if (nonretainedSelectedEntry) {
        NSArray *topLevelChildren;

        topLevelChildren = [topLevelEntry childEntries];
        if ([topLevelChildren count] && [topLevelChildren objectAtIndex:0] == nonretainedSelectedEntry) {
            // If the first entry is selected, we don't scroll to its rect, because this places the scrollview a few pixels too low, since the rect doesn't start at 0,0.
            [self scrollPoint:NSZeroPoint];
        } else {
            NSRect rect;

            if (flags.hasPendingHeightRecalculation)
                [self recalculateHeightIfNeeded];

            rect = [nonretainedSelectedEntry entryRect];
            rect.size = NSMakeSize(1, [[nonretainedSelectedEntry formatter] entryHeight:nonretainedSelectedEntry]);
            [self scrollRectToVisible:rect];
        }
    }

    if (flags.delegateDidSelect)
        [delegate outlineView:self didSelectEntry:nonretainedSelectedEntry];
    return;
}

- (void)scrollSelectedEntryToCenter;
{
    if (nonretainedSelectedEntry) {
        NSRect entryRect;
        NSRect visibleRect;

        if (flags.hasPendingHeightRecalculation)
            [self recalculateHeightIfNeeded];

        entryRect = [nonretainedSelectedEntry entryRect];
        entryRect.size = NSMakeSize(1, [[nonretainedSelectedEntry formatter] entryHeight:nonretainedSelectedEntry]);
        visibleRect = [self visibleRect];
        [self scrollRectToVisible:NSIntegralRect(NSMakeRect(NSMinX(entryRect), NSMidY(entryRect)-(NSHeight(visibleRect)/2.0), 1, NSHeight(visibleRect)))];
    }
}

- (OAOutlineEntry *)selection;
{
    return nonretainedSelectedEntry;
}

- (void)makeEntriesPerformSelector:(SEL)selector withObject:(id)anObject;
{
    [topLevelEntry makeEntriesPerformSelector:selector withObject:anObject];
}


// Dragging API

- (void)dragSublist:(OAOutlineEntry *)sublist causedByEvent:(NSEvent *)original currentEvent:(NSEvent *)current;
{
    NSImage *dragImage;
    NSPoint dragImageCursorPosition;
    NSPoint dragLocation;
    OAPasteboardHelper *helper;
    NSSize dragImageSize;

    if (!dragSupport || !flags.allowDraggingOut)
	return;

/*
    dragEntry = [sublist retain];
*/
    flags.internalDrag = YES;
    dragImage = [dragSupport outlineView:self dragImageForEntry:sublist];
    dragImageSize = [dragImage size];
    if ([dragSupport respondsToSelector:@selector(outlineView:dragImageCursorPositionForEntry:)]) {
        dragImageCursorPosition = [(id <OAOutlineOptionalDragSupport>)dragSupport outlineView:self dragImageCursorPositionForEntry:sublist];
    } else {
        dragImageCursorPosition.x = dragImageSize.width / 2.0;
        dragImageCursorPosition.y = dragImageSize.height / 2.0;
    }

    dragLocation = [self convertPoint:[original locationInWindow] fromView:nil];
    dragLocation.x -= dragImageCursorPosition.x;
    dragLocation.y += dragImageCursorPosition.y;

    helper = [OAPasteboardHelper helperWithPasteboardNamed:NSDragPboard];
    [dragSupport outlineView:self declareTypesForEntry:sublist pasteboardHelper:helper];
    if (flags.dragEntireSublists && [sublist hasChildren])
	[helper addTypes:sublistPasteboardTypes owner:self];

    [dragSupport outlineView:self startDragOnEntry:sublist fromView:self image:dragImage atPoint:dragLocation event:original pasteboardHelper:helper];

/*    
    [dragEntry release];
    dragEntry = nil;
*/    
    flags.internalDrag = NO;
    [self markNeedsHeightRecalculationAndDisplay];
}

- (NSDictionary *)infoOfType:(NSString *)type forSublist:(OAOutlineEntry *)sublist usingPasteboard:(NSPasteboard *)scratchPasteboard
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    NSMutableArray *subinfo = [[NSMutableArray alloc] init];
    NSEnumerator *enumerator = [[sublist childEntries] objectEnumerator];
    OAOutlineEntry *subentry;

    // This is one ugly-ass Greg hack to trick the sublist into writing out its
    // data, so we can incorporate that into our dictionary.
    [scratchPasteboard declareTypes:[NSArray arrayWithObject:type] owner:sublist];
    [info setObject:[scratchPasteboard propertyListForType:type] forKey:@"info"];

    //
    if ([sublist hidden])
	[info setObject:@"YES" forKey:@"hidden"];
    while((subentry = [enumerator nextObject]))
	[subinfo addObject:[self infoOfType:type forSublist:subentry usingPasteboard:scratchPasteboard]];
    [info setObject:subinfo forKey:@"sublist"];
    [subinfo release];
    return info;
}


// NSPasteboard delegate

- (void)pasteboard:(NSPasteboard *)pasteboard provideDataForType:(NSString *)type;
{
    NSPasteboard *scratchPasteboard;
    NSString *entryType;
    NSDictionary *info;

    if (!nonretainedSelectedEntry || ![type hasPrefix:OAOutlineSubListPasteboardType]) {
        [pasteboard setPropertyList:nil forType:type];
        return;
    }

    entryType = [[dragSupport outlineViewAcceptedPasteboardTypes:self] objectAtIndex:0];
#warning This hits a leak in AppKit with +pasteboardWithUniqueName.  Why are we not just using the supplied pasteboard?
    scratchPasteboard = [NSPasteboard pasteboardWithUniqueName];
    info = [self infoOfType:entryType forSublist:nonretainedSelectedEntry usingPasteboard:scratchPasteboard];
    [scratchPasteboard releaseGlobally];
    
    [pasteboard setPropertyList:info forType:type];
}


// NSDraggingDestination informal protocol

- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender;
{
    if (flags.draggingAlreadyEntered)
        return [self draggingUpdated:sender];

    flags.draggingAlreadyEntered = YES;

    [[self window] makeFirstResponder:self];

    OBASSERT(dragEntry == nil);

    if (flags.internalDrag)
        dragEntry = [nonretainedSelectedEntry retain];
    else {
        // only get single entry for now to keep dragging from being slow with large lists of children
        dragEntry = [[self _singleEntryFromPasteboard:[sender draggingPasteboard]] retain];
        [dragEntry setOutlineView:self];
        [dragEntry recalculateHeight];
    }

    if (dragPoints)
        [dragPoints removeAllObjects];
    else
        dragPoints = [[NSMutableArray alloc] init];

    [topLevelEntry addDragPoints:dragPoints for:dragEntry inRect:NSInsetRect([self bounds], borderWidth, borderWidth)];

    return [self draggingUpdated:sender];
}

- (unsigned int)draggingUpdated:(id <NSDraggingInfo>)sender;
{
    OAOutlineDragPoint *oldPoint;
    unsigned int draggingSourceOperationMask;
    NSPoint dragLocation;
    NSRect visible;

    OBASSERT(dragEntry != nil);

    oldPoint = nonretainedCurrentDragPoint;
    dragLocation = [self convertPoint:[sender draggingLocation] fromView:nil];
    visible = [(NSScrollView *)[self superview] documentVisibleRect];
    if (NSIsEmptyRect(visible))
        return 0;

    if (dragLocation.y < visible.origin.y) {
        scrollDirection = -1;
        dragLocation.y = visible.origin.y;
        if (flags.enableScroll) {
            if (flags.isScrolling)
                [self _moveScroller];
            else
                flags.isScrolling = YES;
        }
    } else if (dragLocation.y > (visible.origin.y + visible.size.height)) {
        scrollDirection = 1;
        dragLocation.y = visible.origin.y + visible.size.height;

        if (flags.enableScroll) {
            if (flags.isScrolling)
                [self _moveScroller];
            else
                flags.isScrolling = YES;
        }
    } else {
        flags.enableScroll = YES;
        flags.isScrolling = NO;
    }

    [self findDragSpot:dragLocation];
    if (oldPoint != nonretainedCurrentDragPoint) {
        NSRect redrawRect;
        float height;

        // I think we've fixed the bug where dragEntry was sometimes nil, but I'm afraid to delete this just in case. --Ken
        height = dragEntry ? [dragEntry entryHeight] : 200.0;
        // When convenient, that last line should be replaced with:
        // OBASSERT(dragEntry != nil);
        // height = [dragEntry entryHeight];
        redrawRect.origin.x = [nonretainedCurrentDragPoint x];
        redrawRect.origin.y = [nonretainedCurrentDragPoint y] - height / 2;
        redrawRect.size.height = height;
        redrawRect.size.width = NSMaxX([self bounds]) - [nonretainedCurrentDragPoint x];
        if (oldPoint) {
            NSRect oldRect;

            oldRect.origin.x = [oldPoint x];
            oldRect.origin.y = [oldPoint y] - height / 2;
            oldRect.size.height = height;
            oldRect.size.width = NSMaxX([self bounds]) - [oldPoint x];
            redrawRect = NSUnionRect(oldRect, redrawRect);
        }

        [self displayRect:redrawRect];
    }
    draggingSourceOperationMask = [sender draggingSourceOperationMask];
    if (draggingSourceOperationMask & NSDragOperationGeneric)
        return NSDragOperationGeneric;
    if (draggingSourceOperationMask & NSDragOperationLink)
        return NSDragOperationLink;
    if (draggingSourceOperationMask & NSDragOperationCopy)
        return NSDragOperationCopy;
    if (draggingSourceOperationMask & NSDragOperationPrivate)
        return NSDragOperationPrivate;

    return NSDragOperationGeneric;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender;
{
    flags.draggingAlreadyEntered = NO;

    if (dragEntry) {
        [dragEntry release];
        dragEntry = nil;
    }
    nonretainedCurrentDragPoint = nil;
    flags.enableScroll = NO;
    flags.isScrolling = NO;

    [self display];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
{
    flags.draggingAlreadyEntered = NO;
    flags.isScrolling = NO;
    flags.enableScroll = NO;
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
{
    NSPoint dragLocation;
    OAOutlineEntry *dragSpotEntry;

    dragLocation = [self convertPoint:[sender draggingLocation] fromView:nil];
    [self findDragSpot:dragLocation];
    dragSpotEntry = [nonretainedCurrentDragPoint entry];

    if (flags.internalDrag) {
        OAOutlineEntry *oldParentEntry;
        unsigned int oldEntryIndex;

        oldParentEntry = [dragEntry parentEntry];
        oldEntryIndex = [oldParentEntry indexOfEntry:dragEntry];
        if (oldParentEntry == dragSpotEntry) {
            unsigned int dragSpotIndex;

            // Since we're moving an entry within the same parent entry, removing the entry from its old position might modify the index of the new position.
            dragSpotIndex = [nonretainedCurrentDragPoint index];
            if (oldEntryIndex < dragSpotIndex)
                [nonretainedCurrentDragPoint setIndex:dragSpotIndex - 1];
        }
        [oldParentEntry removeEntryAtIndex:oldEntryIndex];
    } else {
        NSPasteboard *pasteboard;
        
	// if the drag had children, get the whole sublist
        pasteboard = [sender draggingPasteboard];
        if (flags.acceptEntireSublists && [pasteboard availableTypeFromArray:sublistPasteboardTypes]) {
            [dragEntry release];
            dragEntry = [[self entryWithChildrenFromPasteboard:pasteboard] retain];
        }
    }

    [dragSpotEntry insertEntry:dragEntry atIndex:[nonretainedCurrentDragPoint index]];
    if ([dragSpotEntry hidden])
	[self setSelectionTo:nil];
    else
        [self setSelectionTo:dragEntry];

    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;
{
    flags.draggingAlreadyEntered = NO;

    if (dragEntry) {
        [dragEntry release];
        dragEntry = nil;
    }
    nonretainedCurrentDragPoint = nil;
    flags.enableScroll = NO;
    flags.isScrolling = NO;

    [self markNeedsHeightRecalculationAndDisplay];
}

// Actions

- (IBAction)contractAll:(id)sender;
{
    [topLevelEntry contractAllIncludingSelf:NO];
    // If we just obscured the selection, unset the selection.
    if ([nonretainedSelectedEntry parentEntry] != topLevelEntry)
	[self setSelectionTo:nil];
    [self markNeedsHeightRecalculationAndDisplay];
}

- (IBAction)expandAll:(id)sender;
{
    [topLevelEntry expandAllIncludingSelf:NO];
    [self markNeedsHeightRecalculationAndDisplay];
}

- (IBAction)contractSelection:(id)sender;
{
    if (!nonretainedSelectedEntry) {
	[self contractAll:sender];
        return;
    }
	
    [nonretainedSelectedEntry contractAllIncludingSelf:YES];
    [self markNeedsHeightRecalculationAndDisplay];
}

- (IBAction)expandSelection:(id)sender;
{
    if (!nonretainedSelectedEntry) {
	[self expandAll:sender];
        return;
    }

    [nonretainedSelectedEntry expandAllIncludingSelf:YES];
    [self markNeedsHeightRecalculationAndDisplay];
}

- (IBAction)removeItem:(id)sender;
{
    OAOutlineEntry *entry;

    if (!nonretainedSelectedEntry) {
        NSBeep();
        return;
    }

    if (flags.delegateWillRemove && ![delegate outlineView:self willRemoveEntry:nonretainedSelectedEntry])
        return;

    // If the delegate already said yes, then ignore the editable flag
    if (!flags.delegateWillRemove && !flags.editable) {
        NSBeep();
        return;
    }

    if (![[self window] makeFirstResponder:self])
	return;
    entry = [nonretainedSelectedEntry retain];
    [[entry parentEntry] removeEntry:entry];
    if (flags.delegateDidRemove)
        [delegate outlineView:self didRemoveEntry:entry];
    [entry release];
}

- (IBAction)insertItem:(id)sender;
{
    OAOutlineEntry *parentEntry, *newEntry;

    parentEntry = [nonretainedSelectedEntry parentEntry];

    newEntry = [dragSupport outlineView:self emptyEntryWithParent:parentEntry];
    if (!newEntry)
	return;

    if (parentEntry) {
        unsigned int indexOfSelectedEntry;

        indexOfSelectedEntry = [[parentEntry childEntries] indexOfObject:nonretainedSelectedEntry];
        [parentEntry insertEntry:newEntry atIndex:indexOfSelectedEntry + 1];
    } else
        [topLevelEntry appendEntry:newEntry];
    
    [self setSelectionTo:newEntry];

    if (flags.formatterIsEditable && [(id <OAOutlineEditableFormatter>)formatter isEditable]) {
	[(id <OAOutlineEditableFormatter>)formatter editEntry:newEntry entryRect:[newEntry entryRect]];
    }
}

- (IBAction)cut:(id)sender;
{
    [self copy:self];
    [self removeItem:self];
}

- (IBAction)copy:(id)sender;
{
    OAPasteboardHelper *helper;
    NSPasteboard *pasteboard;
    NSEnumerator *enumerator;
    NSString *type;

    pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    helper = [[OAPasteboardHelper alloc] initWithPasteboard:pasteboard];

    [dragSupport outlineView:self declareTypesForEntry:nonretainedSelectedEntry pasteboardHelper:helper];
    // now force all the data onto the pasteboard since OpenStep/Windows 4.2pr2 has a major bug with changing the owner of the NSGeneralPboard, causing us to break otherwise
    enumerator = [[pasteboard types] objectEnumerator];
    while ((type = [enumerator nextObject]))
        [dragSupport pasteboard:pasteboard provideData:nonretainedSelectedEntry forType:type];

    if (flags.dragEntireSublists) {
        [helper addTypes:sublistPasteboardTypes owner:self];
        [self pasteboard:pasteboard provideDataForType:[sublistPasteboardTypes objectAtIndex:0]];
    }

    [helper release];
}

- (IBAction)paste:(id)sender;
{
    OAOutlineEntry *pasted, *holder;
    unsigned int indexOfSelectedEntry;

    holder = [nonretainedSelectedEntry parentEntry];
    indexOfSelectedEntry = [[holder childEntries] indexOfObject:nonretainedSelectedEntry];
    pasted = [self entryWithChildrenFromPasteboard:[NSPasteboard pasteboardWithName:NSGeneralPboard]];
    if (!pasted)
        return;
    if (holder)
        [holder insertEntry:pasted atIndex:indexOfSelectedEntry + 1];
    else
        [topLevelEntry appendEntry:pasted];
    [self setSelectionTo:pasted];
}

- (IBAction)delete:(id)sender;
{
    [self removeItem:self];
}

// Used by editable formatters

- (BOOL)willEdit;
{
    if (!flags.editable)
        return NO;
    if (flags.delegateWillEdit)
        return [delegate outlineView:self willEditEntry:nonretainedSelectedEntry];
    return YES;
}

- (void)didEdit;
{
    if (flags.delegateDidEdit)
        [delegate outlineView:self didEditEntry:nonretainedSelectedEntry];
}

// OAFindControllerTarget protocol

- (BOOL)findPattern:(id <OAFindPattern>)pattern backwards:(BOOL)backwards wrap:(BOOL)wrap;
{
    OAOutlineEntry *holder;
    OAOutlineEntry *searchIn;

    if (!flags.formatterIsFindable)
	return NO;
    if (nonretainedSelectedEntry)
        searchIn = nonretainedSelectedEntry;
    else {
        searchIn = nil;
        wrap = YES;
    }
    while (1) {
        if (searchIn) {
            if (backwards)
                searchIn = [searchIn previousEntry];
            else
                searchIn = [searchIn nextEntry];
        } else {
            if (!wrap)
                return NO;
            wrap = NO;
            if (backwards)
                searchIn = [topLevelEntry lastEntry];
            else
                searchIn = [[topLevelEntry childEntries] objectAtIndex:0];
        }
        if ([(id <OAOutlineFindableFormatter>)formatter findPattern:pattern forEntry:searchIn]) {
            holder = [searchIn parentEntry];
            while (holder) {
                if ([holder hidden])
                    [holder toggleHidden];
                holder = [holder parentEntry];
            }
            [self setSelectionTo:searchIn];
            return YES;
        }
    }
}


// NSMenuActionResponder informal protocol

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    BOOL noEntries, noSelection;

    noEntries = !topLevelEntry || ![topLevelEntry hasChildren];
    noSelection = noEntries || (nonretainedSelectedEntry == nil);
        
    // Revert menu item changes name
    if ([item action] == @selector(contractAll:) || [item action] == @selector(expandAll:)) {
        return !noEntries;
    }
    if ([item action] == @selector(contractSelection:) || [item action] == @selector(expandSelection:) || [item action] == @selector(removeItem:) || [item action] == @selector(delete:) || [item action] == @selector(cut:) || [item action] == @selector(copy:)) {
        return !noEntries && !noSelection;
    }
    return YES;
}

// Delegate

- (id)delegate;
{
    return delegate;
}

- (void)setDelegate:(id)aDelegate;
{
    delegate = aDelegate;
    flags.delegateWillSelect = [delegate respondsToSelector:@selector(outlineView:willSelectEntry:)];
    flags.delegateDidSelect = [delegate respondsToSelector:@selector(outlineView:didSelectEntry:)];
    flags.delegateWillAdd = [delegate respondsToSelector:@selector(outlineView:willAddEntry:)];
    flags.delegateDidAdd = [delegate respondsToSelector:@selector(outlineView:didAddEntry:)];
    flags.delegateWillEdit = [delegate respondsToSelector:@selector(outlineView:willEditEntry:)];
    flags.delegateDidEdit = [delegate respondsToSelector:@selector(outlineView:didEditEntry:)];
    flags.delegateWillRemove = [delegate respondsToSelector:@selector(outlineView:willRemoveEntry:)];
    flags.delegateDidRemove = [delegate respondsToSelector:@selector(outlineView:didRemoveEntry:)];
    flags.delegateDidPromote = [delegate respondsToSelector:@selector(outlineView:didPromoteEntry:)];
    flags.delegateDidDemote = [delegate respondsToSelector:@selector(outlineView:didDemoteEntry:)];
    flags.delegateDidGetKey = [delegate respondsToSelector:@selector(outlineView:didGetKey:)];
}

@end

@implementation OAOutlineView (Private)

- (BOOL)_willAdd:(OAOutlineEntry *)entry;
{
    if (flags.delegateWillAdd && !flags.performingOperation)
        return [delegate outlineView:self willAddEntry:entry];
    else
        return flags.editable;
}

- (void)_didAdd:(OAOutlineEntry *)entry;
{
    [self markNeedsHeightRecalculationAndDisplay];
    if (flags.delegateDidAdd && !flags.performingOperation)
        [delegate outlineView:self didAddEntry:entry];
}

- (void)_startOperation;
{
    flags.performingOperation = YES;
}

- (void)_didDemote:(OAOutlineEntry *)entry;
{
    if (flags.delegateDidDemote)
        [delegate outlineView:self didDemoteEntry:entry];
    flags.performingOperation = NO;
    [self markNeedsHeightRecalculationAndDisplay];
}

- (void)_didPromote:(OAOutlineEntry *)entry;
{
    if (flags.delegateDidPromote)
        [delegate outlineView:self didPromoteEntry:entry];
    flags.performingOperation = NO;
    [self markNeedsHeightRecalculationAndDisplay];
}


// Dragging help

- (void)findDragSpot:(NSPoint)dragLocation;
{
    int dragPointsCount;
    int low, high;
    OAOutlineDragPoint *closePoint, *nearPoint;
    float y;

    dragPointsCount = [dragPoints count];
    if (dragPointsCount == 0) {
        nonretainedCurrentDragPoint = nil;
	return;
    }

    // Find the drag point just above and below the mouse point
    low = dragPointsCount;
    high = low - 1;
    y = [[dragPoints objectAtIndex:high] y];
    while (low--) {
	float closeY;

	closePoint = [dragPoints objectAtIndex:low];
	closeY = [closePoint y];
        if (dragLocation.y > closeY) {
            if ((y < dragLocation.y) || (dragLocation.y - closeY) < (y - dragLocation.y)) {
                high = low;
                y = closeY;
                while (low--) {
		    closePoint = [dragPoints objectAtIndex:low];
		    closeY = [closePoint y];
                    if (closeY != y)
                        break;
		}
            }
            break;
        }
        if (closeY != y) {
            high = low;
            y = closeY;
        }
    }
    low++;

    // the items between high and low inclusive are all the drag points at the closest y position

    while (high > low && (closePoint = [dragPoints objectAtIndex:high - 1]) &&
           [closePoint x] <= dragLocation.x)
	high--;
    while (low < high && (closePoint = [dragPoints objectAtIndex:low + 1]) &&
           [closePoint x] >= dragLocation.x)
	low++;
    if (low == high) {
        nonretainedCurrentDragPoint = [dragPoints objectAtIndex:low];
	return;
    }

    closePoint = [dragPoints objectAtIndex:low];
    nearPoint = [dragPoints objectAtIndex:high];
    if (dragLocation.x - [nearPoint x] < [closePoint x] - dragLocation.x)
        nonretainedCurrentDragPoint = nearPoint;
    else
        nonretainedCurrentDragPoint = closePoint;
}

- (void)_registerForDragging;
{
    NSArray *acceptedTypes;

    acceptedTypes = [dragSupport outlineViewAcceptedPasteboardTypes:self];

    [self unregisterDraggedTypes];
    if ([acceptedTypes count]) {
	[self registerForDraggedTypes:acceptedTypes];

	if (flags.acceptEntireSublists)
            [self registerForDraggedTypes:sublistPasteboardTypes];
    }
}

- (OAOutlineEntry *)_entryFromInfoDictionary:(NSDictionary *)info ofType:(NSString *)type;
{
    OAOutlineEntry *entry;
    NSEnumerator *enumerator;
    NSDictionary *subinfo;

    enumerator = [[info objectForKey:@"sublist"] objectEnumerator];
    entry = [dragSupport outlineView:self entryFromPropertyList:[info objectForKey:@"info"] pasteboardType:type parentEntry:nil];
    
    if ([info objectForKey:@"hidden"])
        [entry setHidden:YES];
    
    while ((subinfo = [enumerator nextObject]))
        [entry appendEntry:[self _entryFromInfoDictionary:subinfo ofType:type]];
    
    return entry;
}

- (OAOutlineEntry *)_singleEntryFromPasteboard:(NSPasteboard *)pasteboard;
{
    NSString *type;
    NSArray *acceptedTypes;
    id propertyList;

    acceptedTypes = [dragSupport outlineViewAcceptedPasteboardTypes:self];
    
    if (!(type = [pasteboard availableTypeFromArray:acceptedTypes]))
        return nil;

    if (!(propertyList = [pasteboard propertyListForType:type]))
	return nil;

    return [dragSupport outlineView:self entryFromPropertyList:propertyList pasteboardType:type parentEntry:nil];
}

- (void)_moveScroller;
{
    NSClipView *clip = (NSClipView *)[self superview];
    NSRect clipBounds;
    NSRect listFrame;

    clipBounds = [clip bounds];
    listFrame = [self bounds];
    if (listFrame.size.height < clipBounds.size.height) {
        // The whole list fits in the clip view, so position it at the origin of the clip view.  Short-circuit if we're already there.
        if (clipBounds.origin.y == listFrame.origin.y)
            return;
        clipBounds.origin.y = listFrame.origin.y;
    } else {
        clipBounds.origin.y += scrollDirection * 19;
        if (clipBounds.origin.y < listFrame.origin.y)
            clipBounds.origin.y = listFrame.origin.y;
        else if (clipBounds.origin.y + clipBounds.size.height >
                 listFrame.origin.y + listFrame.size.height)
            clipBounds.origin.y = listFrame.origin.y + listFrame.size.height -
              clipBounds.size.height;
    }
    [clip scrollToPoint:clipBounds.origin];
    [[clip superview] reflectScrolledClipView:clip];
}


// Debugging

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [NSMutableDictionary dictionary];
    if (topLevelEntry)
        [debugDictionary setObject:topLevelEntry forKey:@"topLevelEntry"];
    if (dragEntry)
        [debugDictionary setObject:dragEntry forKey:@"dragEntry"];
    if (nonretainedCurrentDragPoint)
        [debugDictionary setObject:nonretainedCurrentDragPoint forKey:@"nonretainedCurrentDragPoint"];
    if (formatter)
	[debugDictionary setObject:formatter forKey:@"formatter"];
    if (nonretainedSelectedEntry)
        [debugDictionary setObject:nonretainedSelectedEntry forKey:@"nonretainedSelectedEntry"];

    return debugDictionary;
}

@end
