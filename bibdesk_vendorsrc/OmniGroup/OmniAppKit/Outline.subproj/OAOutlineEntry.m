// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OAOutlineEntry.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

#import <OmniAppKit/OAOutlineView.h>

#import "OAOutlineDragPoint.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineEntry.m,v 1.16 2003/01/15 22:51:40 kc Exp $")

@interface OAOutlineEntry (Private)

static int sortByDescription(NSObject *left, NSObject *right, void *context);

- (void)setOutlineView:(OAOutlineView *)newOutlineView recurse:(BOOL)shouldRecurse;
- (void)resetParentEntry:(OAOutlineEntry *)newEntry;
- (BOOL)_willAddEntry:(OAOutlineEntry *)childEntry;
- (void)_didAddEntry:(OAOutlineEntry *)childEntry;
- (BOOL)_getRect:(NSRect *)rect ofEntry:(OAOutlineEntry *)anEntry;
- (OAOutlineEntry *)_entryPreceedingChildEntry:(OAOutlineEntry *)childEntry;
- (OAOutlineEntry *)_entryFollowingChildEntry:(OAOutlineEntry *)childEntry;
- (OAOutlineEntry *)_lastVisibleEntry;
- (OAOutlineEntry *)_previousVisibleEntryToChildEntry:(OAOutlineEntry *)childEntry;

@end

@interface OAOutlineView (PrivateForDelegation)
- (BOOL)_willAdd:(OAOutlineEntry *)entry;
- (void)_didAdd:(OAOutlineEntry *)entry;
- (void)_startOperation;
- (void)_didDemote:(OAOutlineEntry *)entry;
- (void)_didPromote:(OAOutlineEntry *)entry;
@end

@implementation OAOutlineEntry

+ (OAOutlineEntry *)entryWithRepresentedObject:(id)anObject inEntry:(OAOutlineEntry *)anEntry;
{
    return [[[self alloc] initWithRepresentedObject:anObject inEntry:anEntry] autorelease];
}

// Init and dealloc

- initInView:(OAOutlineView *)aView;
{
    if (![super init])
	return nil;

    [self setOutlineView:aView];
    totalHeight = 0;
    flags.hidden = NO;
    flags.childrenAllowed = YES;
    nonretainedParentEntry = nil;
    representedObject = nil;
    childEntries = [[NSMutableArray alloc] init];

    return self;
}

- initWithRepresentedObject:(id)anObject inEntry:(OAOutlineEntry *)anEntry;
{
    if (![super init])
	return nil;

    totalHeight = nonretainedOutlineView && anEntry ? [[nonretainedOutlineView formatter] entryHeight:anEntry] : 0.0;
    flags.hidden = NO;
    flags.childrenAllowed = YES;
    nonretainedParentEntry = anEntry;
    [self setOutlineView:[nonretainedParentEntry outlineView]];
    childEntries = [[NSMutableArray alloc] init];
    representedObject = [anObject retain];
    return self;
}

- init;
{
    return [self initInView:nil];
}

- (void)dealloc;
{
    [formatter release];
    [representedObject release];
    [childEntries release];
    [super dealloc];
}

//

- (id)representedObject;
{
    return representedObject;
}

- (void)setRepresentedObject:(id)newRepresentedObject;
{
    if (representedObject != newRepresentedObject) {
        [representedObject release];
        representedObject = [newRepresentedObject retain];
    }
}

- (OAOutlineView *)outlineView;
{
    return nonretainedOutlineView;
}

- (void)setOutlineView:(OAOutlineView *)newOutlineView;
{
    [self setOutlineView:newOutlineView recurse:YES];
}

- (OAOutlineEntry *)parentEntry;
{
    return nonretainedParentEntry;
}

- (BOOL)hasChildren;
{
    // A simple default implementation
    return [childEntries count] != 0;
}

- (NSArray *)childEntries;
{
    return childEntries;
}

- (NSArray *)representedObjectsOfChildEntries;
{
    NSMutableArray *result;
    unsigned int childIndex, childCount;

    result = [NSMutableArray array];

    // Cache the child entries if lazily creating children
    [self childEntries];

    childCount = [childEntries count];
    for (childIndex = 0; childIndex < childCount; childIndex++) {
        id representedObjectOfChildEntry;

        representedObjectOfChildEntry = [[childEntries objectAtIndex:childIndex] representedObject];
        [result addObject:representedObjectOfChildEntry];
    }
    return result;
}

- (NSArray *)allRepresentedObjects;
{
    NSMutableArray *result;
    unsigned int childIndex, childCount;

    result = [NSMutableArray array];
    if (representedObject)
        [result addObject:representedObject];

    // Cache the child entries if lazily creating children
    [self childEntries];

    childCount = [childEntries count];
    for (childIndex = 0; childIndex < childCount; childIndex++)
        [result addObjectsFromArray:[[childEntries objectAtIndex:childIndex] allRepresentedObjects]];
    return result;
}

- (BOOL)hidden;
{
    return flags.hidden;
}

- (void)setHidden:(BOOL)newHidden;
{
    flags.hidden = newHidden;
    [nonretainedOutlineView markNeedsHeightRecalculationAndDisplay];
}

- (void)toggleHidden;
{
    // Use -hasChildren to allow for lazy child creation
    if ([self hasChildren])
        [self setHidden:!flags.hidden];
}

- (BOOL)childrenAllowed;
    // Returns whether children are allowed
{
    return flags.childrenAllowed;
}

- (void)setChildrenAllowed:(BOOL)newChildrenAllowed;
    // Sets whether children are allowed.  If children are not allowed, you cannot create children of this entry.
{
    flags.childrenAllowed = newChildrenAllowed;
}

- (void)addDragPoints:(NSMutableArray *)dragPointList for:(OAOutlineEntry *)aDraggedEntry inRect:(NSRect)listRect;
{
    OAOutlineDragPoint *drag;
    float height;
    float tabWidth;
    float entryHeight;
    OAOutlineEntry *subEntry;
    NSRect subrect;
    unsigned int dragIndex;

    if (aDraggedEntry == self)
        return;

    tabWidth = [nonretainedOutlineView tabWidth];
    entryHeight = [[nonretainedOutlineView formatter] entryHeight:self];
    subrect = listRect;

    drag = [[[OAOutlineDragPoint alloc] init] autorelease];
    [drag setEntry:self];

    // if we're the top-level entry and we have no children, make single drag point for incoming
    if (!nonretainedParentEntry && [childEntries count] == 0) {
	[drag setIndex:0];
        [drag setPosition:NSMakePoint(NSMinX(subrect), NSMinY(subrect) + entryHeight / 2.0)];
	[dragPointList addObject:drag];
	return;
    }

    // If no children are allowed, don't add any drag points.  (Our parent has already added any drag points for us.)
    if (!flags.childrenAllowed)
        return;

    // if we're not the top-level entry, adjust rect to cut out ourself (rect of our children)
    if (nonretainedParentEntry) {
        subrect.origin.y += entryHeight;
        subrect.origin.x += tabWidth;
        subrect.size.width -= tabWidth;
        // height will be set below
    }

    // if we're showing our children, calculate drag points for them
    if (!flags.hidden) {
        // for each child, calculate drag points
        for (dragIndex = 0; dragIndex < [childEntries count]; dragIndex++) {
            // get the next child entry
            subEntry = [childEntries objectAtIndex:dragIndex];
            // adjust the rect height to match the height of the child
            height = [subEntry entryHeight];
            subrect.size.height = height;
	    [drag setIndex:dragIndex];
            // position drag point in upper (we're flipped) left of rect
            [drag setPosition:subrect.origin];
            // if the child is not being dragged...
            if (subEntry != aDraggedEntry) {
                if ((dragIndex == 0) || [childEntries objectAtIndex:dragIndex - 1] != aDraggedEntry) {
                    OAOutlineEntry *previousVisibleEntry;

                    previousVisibleEntry = [subEntry previousVisibleEntry];
                    if (previousVisibleEntry == aDraggedEntry)
                        [drag addDY:-[previousVisibleEntry entryHeight] / 2];
                    // we've got a drag point (upper left of child's rect)
		    [dragPointList addObject:[[drag copy] autorelease]];
                }
                // add any drag points child wants to (IE for it's children)
                [subEntry addDragPoints:dragPointList for:aDraggedEntry
		 inRect:subrect];
            } else {	// but if the child IS being dragged...
                // add a drag point right where the child is now (IE entry doesn't move)
                [drag addDY:[formatter entryHeight:self] / 2];
                [dragPointList addObject:[[drag copy] autorelease]];
            }
            // adjust y origin to move to next child
            subrect.origin.y += height;
        }
    }

    // Add a drag point following our last child
    subEntry = [childEntries lastObject];
    if (subEntry != aDraggedEntry) {
        [drag setPosition:subrect.origin];
	height = entryHeight;
        if ([self nextVisibleEntry] == aDraggedEntry)
	    [drag addDY:height / 2];
        else if ([self _lastVisibleEntry] == aDraggedEntry)
	    [drag addDY:-height / 2];
        [drag setIndex:[childEntries count]];
	[dragPointList addObject:drag];
    }
}

- (void)dragDraw:(NSRect)rect inEntry:(OAOutlineEntry *)anEntry;
{
    // Checking [self hasChildren] to support lazy child creation.

    [[[anEntry outlineView] formatter] drawEntry:anEntry entryRect:rect selected:NO parent:[self hasChildren] hidden:flags.hidden                                         dragging:YES];
}

- (void)makeEntriesPerformSelector:(SEL)selector withObject:(id)anObject;
{
    int childIndex, childCount;

    [representedObject performSelector:selector withObject:anObject];

    // Cache the child entries if lazily creating children
    [self childEntries];

    childCount = [childEntries count];
    for (childIndex = 0; childIndex<childCount; childIndex++)
        [[childEntries objectAtIndex:childIndex] makeEntriesPerformSelector:selector withObject:anObject];
}

- (unsigned int)indexOfEntry:(OAOutlineEntry *)childEntry;
{
    return [childEntries indexOfObjectIdenticalTo:childEntry];
}

- (NSRect)entryRect;
{
    NSRect result;

    if (![nonretainedParentEntry _getRect:&result ofEntry:self]) {
        NSLog(@"Could not find entry rect");
        result = NSZeroRect;
    }
    return result;
}

- (void)recalculateHeight;
{
    unsigned int childIndex;

    totalHeight = representedObject ? [formatter entryHeight:self] : 0.0;
    if (![self hidden] && [self hasChildren]) {
        // Cache the child entries if lazily creating children
        [self childEntries];
        childIndex = [childEntries count];
        while (childIndex--) {
            OAOutlineEntry *childEntry;

            childEntry = [childEntries objectAtIndex:childIndex];
            [childEntry recalculateHeight];
            totalHeight += [childEntry entryHeight];
        }
    }
}

- (void)sortResults;
{
    unsigned int childIndex;

    [childEntries sortUsingFunction:sortByDescription context:nil];

    childIndex = [childEntries count];
    while (childIndex--)
        [[childEntries objectAtIndex:childIndex] sortResults];
}

- (BOOL)promoteEntry:(OAOutlineEntry *)childEntry;
{
    unsigned int index;
    OAOutlineEntry *movedEntry;

    if (!nonretainedParentEntry)
        return NO;

    [nonretainedOutlineView _startOperation];
    index = [childEntries indexOfObjectIdenticalTo:childEntry];
    [childEntries removeObject:[childEntry retain]];
    childEntry->nonretainedParentEntry = nil;
    while (index < [childEntries count] && (movedEntry = [childEntries objectAtIndex:index])) {
	[movedEntry retain];
        [childEntries removeObjectAtIndex:index];
        movedEntry->nonretainedParentEntry = nil;
        [childEntry appendEntry:movedEntry];
        [movedEntry release];
    }
    [nonretainedParentEntry insertEntry:childEntry atIndex:[nonretainedParentEntry indexOfEntry:self] + 1];
    [childEntry release];
    [nonretainedOutlineView _didPromote:childEntry];

    return YES;
}

- (BOOL)demoteEntry:(OAOutlineEntry *)childEntry;
{
    unsigned int index;
    OAOutlineEntry *newParentEntry;

    index = [childEntries indexOfObjectIdenticalTo:childEntry];
    if (index == 0 || index == NSNotFound)
        return NO;

    [nonretainedOutlineView _startOperation];
    newParentEntry = [childEntries objectAtIndex:index - 1];
    [childEntry retain];
    [childEntries removeObjectAtIndex:index];
    childEntry->nonretainedParentEntry = nil;
    [newParentEntry appendEntry:childEntry];
    [childEntry release];
    [nonretainedOutlineView _didDemote:childEntry];

    return YES;
}

- (void)insertEntry:(OAOutlineEntry *)childEntry atIndex:(unsigned int)index;
{
    if (![self _willAddEntry:childEntry])
	return;

    [childEntries insertObject:childEntry atIndex:index];
    [self _didAddEntry:childEntry];
}

- (void)replaceEntry:(OAOutlineEntry *)oldEntry withEntry:(OAOutlineEntry *)newEntry;
{
    if (![self _willAddEntry:newEntry])
        return;

    oldEntry->nonretainedParentEntry = nil;
    [oldEntry nullifyOutlineView];

    [childEntries replaceObjectAtIndex:[childEntries indexOfObjectIdenticalTo:oldEntry] withObject:newEntry];
    [self _didAddEntry:newEntry];
    if (oldEntry == [nonretainedOutlineView selection])
        [nonretainedOutlineView setSelectionTo:newEntry];
}

- (void)appendEntry:(OAOutlineEntry *)childEntry;
{
    [self insertEntry:childEntry atIndex:[childEntries count]];
}

- (void)removeEntry:(OAOutlineEntry *)childEntry;
{
    [self removeEntryAtIndex:[childEntries indexOfObjectIdenticalTo:childEntry]];
}

- (void)removeEntryAtIndex:(unsigned int)index;
{
    OAOutlineEntry *childEntry;
    
    childEntry = [[childEntries objectAtIndex:index] retain];
    [childEntries removeObjectAtIndex:index];
    childEntry->nonretainedParentEntry = nil;
    [childEntry nullifyOutlineView];
    [childEntry release];

    [nonretainedOutlineView markNeedsHeightRecalculationAndDisplay];
}

- (void)empty;
{
    [childEntries makeObjectsPerformSelector:@selector(nullifyOutlineView)];
    [childEntries removeAllObjects];

    [nonretainedOutlineView markNeedsHeightRecalculationAndDisplay];
}

- (void)nullifyOutlineView;
{
    if (self == [nonretainedOutlineView selection])
        [nonretainedOutlineView setSelectionTo:nil];

    [childEntries makeObjectsPerformSelector:@selector(nullifyOutlineView)];
    nonretainedOutlineView = nil;
}

//

- (OAOutlineEntry *)previousEntry;
{
    return [nonretainedParentEntry _entryPreceedingChildEntry:self];
}

- (OAOutlineEntry *)nextEntry;
{
    if ([self hasChildren])
        return [childEntries objectAtIndex:0];
    else
        return [nonretainedParentEntry _entryFollowingChildEntry:self];
}

- (OAOutlineEntry *)previousVisibleEntry;
{
    OAOutlineEntry *previous;
    
    previous = [nonretainedParentEntry _previousVisibleEntryToChildEntry:self];
    if (![previous parentEntry]) {
        // if entry has no parent it's the invisible top-level entry
        return nil;
    }

    return previous;
}

- (OAOutlineEntry *)nextVisibleEntry;
{
    if (!flags.hidden && [childEntries count])
        return [childEntries objectAtIndex:0];
    else
        return [nonretainedParentEntry _entryFollowingChildEntry:self];
}

- (OAOutlineEntry *)lastEntry;
{
    OAOutlineEntry *lastEntry;

    lastEntry = [childEntries lastObject];
    if (!lastEntry)
        return self;
    else
        return [lastEntry lastEntry];
}

//

- (OAOutlineEntry *)findEntryWithRepresentedObject:(id)anObject;
{
    int index = [childEntries count];
    OAOutlineEntry *subEntry, *response;

    if (anObject == representedObject)
        return self;
    while (index--) {
        subEntry = [childEntries objectAtIndex:index];
        if ((response = [subEntry findEntryWithRepresentedObject:anObject]))
            return response;
    }
    return nil;
}


- (OAOutlineEntry *)entryAndRect:(NSRect *)mutableEntryRect ofPoint:(NSPoint)point;
    // -entryAndRect:ofPoint: and -drawRect:entryRect: both assume that the view is flipped
{
    float height;
    float tabWidth;

    height = representedObject ? [formatter entryHeight:self] : 0;
    tabWidth = [nonretainedOutlineView tabWidth];

    if (flags.hidden || ![self hasChildren])
        return self;

    if (nonretainedParentEntry && point.y - NSMinY(*mutableEntryRect) < height) {
        // Hit our representedObject
        mutableEntryRect->size.height = height;
        return self;
    } else { // Hit one of our children
	unsigned int childIndex, childCount;

        if (nonretainedParentEntry) {
            mutableEntryRect->origin.y += height;
            mutableEntryRect->origin.x += tabWidth;
            mutableEntryRect->size.width -= tabWidth;
        }

        childCount = [childEntries count];
        for (childIndex = 0; childIndex < childCount; childIndex++) {
            OAOutlineEntry *subentry;

            subentry = [childEntries objectAtIndex:childIndex];
            height = [subentry entryHeight];
            if (NSMinY(*mutableEntryRect) + height > point.y) {
                mutableEntryRect->size.height = height;
                return [subentry entryAndRect:mutableEntryRect ofPoint:point];
            }
            mutableEntryRect->origin.y += height;
        }
	return nil;
    }
}

//

- (void)contractAllIncludingSelf:(BOOL)includeSelf;
{
    unsigned int index;

    index = [childEntries count];
    while (index--) {
	if (includeSelf)
            [self setHidden:YES];
        [[childEntries objectAtIndex:index] contractAllIncludingSelf:YES];
    }
}

- (void)expandAllIncludingSelf:(BOOL)includeSelf;
{
    unsigned int index;

    index = [childEntries count];
    while (index--) {
	if (includeSelf)
            [self setHidden:NO];
        [[childEntries objectAtIndex:index] expandAllIncludingSelf:YES];
    }
}

//

- (void)pasteboard:(NSPasteboard *)pasteboard provideDataForType:(NSString *)type;
{
    [[nonretainedOutlineView dragSupport] pasteboard:pasteboard provideData:self forType:type];
}

//

- (id <OAOutlineFormatter>)formatter;
{
    return formatter;
}

- (void)setFormatter:(id <OAOutlineFormatter>)aFormatter;
{
    unsigned int childIndex;

    if (formatter == aFormatter)
	return;
    [formatter release];
    formatter = [aFormatter retain];

    childIndex = [childEntries count];
    while (childIndex--)
        [(OAOutlineEntry *)[childEntries objectAtIndex:childIndex] setFormatter:formatter];
}

// OAOutlineEntry protocol

- (float)entryHeight;
{
    return flags.hidden ? [formatter entryHeight:self] : totalHeight;
}

- (void)drawRect:(NSRect)dirty entryRect:(NSRect)rect;
{
    NSRect subrect;
    unsigned int index;
    float height = 0.0;
    float tabWidth;
    OAOutlineEntry *childEntry; 
    BOOL drewStuff = NO;
    
    subrect = rect;
    if (nonretainedParentEntry) {
        height = [formatter entryHeight:self];
        subrect.size.height = height;
        if (!NSIsEmptyRect(NSIntersectionRect(subrect, dirty))) {
            [formatter drawEntry:self entryRect:subrect selected:[nonretainedOutlineView selection] == self parent:[self hasChildren] hidden:flags.hidden dragging:NO];
            // Using [self hasChildren] to support lazy child creation
            drewStuff = YES;
        }
    }
    if (!flags.hidden) {
        if (nonretainedParentEntry) {
            tabWidth = [nonretainedOutlineView tabWidth];
            subrect.origin.y += height;
            subrect.origin.x += tabWidth;
            subrect.size.width -= tabWidth;
        }

        for (index = 0; index < [childEntries count]; index++) {
            childEntry = [childEntries objectAtIndex:index];
            height = [childEntry entryHeight];
            subrect.size.height = height;
            if (!NSIsEmptyRect(NSIntersectionRect(subrect , dirty))) {
                [childEntry drawRect:dirty entryRect:subrect];
                drewStuff = YES;
            } else if (drewStuff)
                break;
            subrect.origin.y += height;
        }       
    }
}

- (void)trackMouse:(NSEvent *)event inRect:(NSRect)rect ofEntry:(OAOutlineEntry *)anEntry;
{
    NSRect subrect;
    NSPoint where;
    OAOutlineEntry *entry;

    subrect = rect;
    where = [nonretainedOutlineView convertPoint:[event locationInWindow] fromView:nil];
    entry = [self entryAndRect:&subrect ofPoint:where];
    if (!entry)
        return;
    
    if (entry == self)
        [formatter trackMouse:event inRect:subrect ofEntry:self];
    else
        [entry trackMouse:event inRect:subrect ofEntry:self];
}

// Debugging

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];

    if (nonretainedParentEntry)
        [debugDictionary setObject:OBShortObjectDescription(nonretainedParentEntry) forKey:@"nonretainedParentEntry"];
    if (nonretainedOutlineView)
        [debugDictionary setObject:OBShortObjectDescription(nonretainedOutlineView) forKey:@"nonretainedOutlineView"];
    if (representedObject)
        [debugDictionary setObject:representedObject forKey:@"representedObject"];
    if (childEntries)
        [debugDictionary setObject:childEntries forKey:@"childEntries"];
    if (formatter)
        [debugDictionary setObject:OBShortObjectDescription(formatter) forKey:@"formatter"];
    [debugDictionary setObject:flags.hidden ? @"YES" : @"NO" forKey:@"flags.hidden"];
    [debugDictionary setObject:[NSString stringWithFormat:@"%.1f", totalHeight] forKey:@"totalHeight"];

    return debugDictionary;
}

@end

@implementation OAOutlineEntry (Private)

static int sortByDescription(NSObject *left, NSObject *right, void *context)
{
    if ([left respondsToSelector:@selector(representedObject)] &&
        [right respondsToSelector:@selector(representedObject)])
        return [(NSString*)[(OAOutlineEntry *)left representedObject] compare:[(OAOutlineEntry *)right representedObject]];
    else if ([left respondsToSelector:@selector(description)] &&
	     [right respondsToSelector:@selector(description)])
	return [(NSString*)[left description] compare:[right description]];
    else
	return NSOrderedSame;
}

- (void)setOutlineView:(OAOutlineView *)newOutlineView recurse:(BOOL)shouldRecurse;
{
    unsigned int childIndex;
    
    if (nonretainedOutlineView == newOutlineView)
	return;
    nonretainedOutlineView = newOutlineView;

    if (formatter != [nonretainedOutlineView formatter]) {
	[formatter release];
	formatter = [[nonretainedOutlineView formatter] retain];
    }

    if (!shouldRecurse)
	return;

    childIndex = [childEntries count];
    while (childIndex--)
        [[childEntries objectAtIndex:childIndex] setOutlineView:nonretainedOutlineView];
}

- (void)resetParentEntry:(OAOutlineEntry *)newEntry;
{
    if (newEntry == nonretainedParentEntry)
        return;
    // THIS ASSERT FAILS WHENEVER I HIT TAB.
    OBASSERT(nonretainedParentEntry == nil);
    nonretainedParentEntry = newEntry;
    [self setOutlineView:[nonretainedParentEntry outlineView]];
}

- (BOOL)_willAddEntry:(OAOutlineEntry *)childEntry;
{
    return nonretainedOutlineView ? [nonretainedOutlineView _willAdd:childEntry] : YES;
}

- (void)_didAddEntry:(OAOutlineEntry *)childEntry;
{
    [childEntry resetParentEntry:self];
    [nonretainedOutlineView _didAdd:childEntry];
}

- (BOOL)_getRect:(NSRect *)returnRect ofEntry:(OAOutlineEntry *)anEntry;
{
    NSRect subrect;
    float borderWidth, height, tabWidth;
    unsigned int index;
    OAOutlineEntry *subEntry;

    if (nonretainedParentEntry) {
        if (![nonretainedParentEntry _getRect:&subrect ofEntry:self])
            return NO;
    } else {
        borderWidth = [nonretainedOutlineView borderWidth];
        subrect = NSInsetRect([nonretainedOutlineView bounds], borderWidth, borderWidth);
    }
    if (anEntry == self) {
        *returnRect = subrect;
        return YES;
    }
    height = [[nonretainedOutlineView formatter] entryHeight:self];
    if (nonretainedParentEntry) {
        tabWidth = [nonretainedOutlineView tabWidth];
        subrect.origin.x += tabWidth;
        subrect.size.width -= tabWidth;
        subrect.origin.y += height;
    }
    for (index = 0; index < [childEntries count]; index++) {
        subEntry = [childEntries objectAtIndex:index];
        if (subEntry == anEntry) {
            subrect.size.height = [subEntry entryHeight];
            *returnRect = subrect;
            return YES;
        }
        subrect.origin.y += [subEntry entryHeight];
    }
    return NO;
}

- (OAOutlineEntry *)_entryPreceedingChildEntry:(OAOutlineEntry *)subEntry;
{
    unsigned int index;
    OAOutlineEntry *previousEntry;

    index = [childEntries indexOfObjectIdenticalTo:subEntry];
    if (index == NSNotFound)
        return nil;
    if (index == 0)
        return self;
    else
        previousEntry = [childEntries objectAtIndex:index-1];
    return [previousEntry lastEntry];    
}

- (OAOutlineEntry *)_entryFollowingChildEntry:(OAOutlineEntry *)childEntry;
{
    unsigned int entryIndex;
    OAOutlineEntry *nextEntry;

    entryIndex = [childEntries indexOfObjectIdenticalTo:childEntry];
    OBASSERT(entryIndex != NSNotFound);
    if (entryIndex + 1 == [childEntries count]) {
        nextEntry = [nonretainedParentEntry _entryFollowingChildEntry:self];
    } else { 
        nextEntry = [childEntries objectAtIndex:entryIndex + 1];
    }
    return nextEntry;
}

- (OAOutlineEntry *)_lastVisibleEntry;
{
    OAOutlineEntry *last = [childEntries lastObject];

    if (!last || flags.hidden)
        return self;
    return [last _lastVisibleEntry];
}

- (OAOutlineEntry *)_previousVisibleEntryToChildEntry:(OAOutlineEntry *)subEntry;
{
    unsigned int index;

    index = [childEntries indexOfObjectIdenticalTo:subEntry];
    if (index == NSNotFound)
        return nil;
    if (index == 0)
        return self;
    else
        return [[childEntries objectAtIndex:index - 1] _lastVisibleEntry];
}

@end
