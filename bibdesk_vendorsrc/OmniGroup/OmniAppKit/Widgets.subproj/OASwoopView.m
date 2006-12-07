// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OASwoopView.h"

#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OASwoopView.m 66043 2005-07-25 21:17:05Z kc $");

@interface OASwoopView (Private)

- (BOOL)_updatePositionsForTime:(NSTimeInterval)tPlus;
- (int)_indexOfCell:(NSCell *)aCell;
- (struct swooper *)_swooperForCellIndex:(int)cellIndex motion:(short)motionFlags;
- (void)_moveCellIndex:(int)cellIndex to:(NSPoint)destPt delay:(NSTimeInterval)delay motion:(enum OASwoopStyle)kinematics flags:(short)cFlags;
- (BOOL)_removeCell:(NSCell *)delenda;
- (void)_compactCells;
- (void)_reorderCells:(int *)backmap;
- (void)_fixupSwoopIndices:(int *)cellRemap newCellCount:(unsigned int)newCellCount;

/* Items for the swooper flags field */
#define SF_Origin     0x0001    // Swooper affects its cell's origin.
#define SF_Size       0x0002    // Swooper affects its cell's size.
#define SF_Parameter  0x0004    // Swooper affects its cell's user-defined parameter.
#define SF_Motion     0x0007    // Any/all of the above
#define SF_Notify     0x0008    // Call -cellsFinished: when this swooper finishes
    /* If a swooper has any motion flags set, it is in use; when it reaches the end of its duration, the motion flags are reset. If the notify flag is still set then -cellsFinished: is called. */


@end

@implementation OASwoopView

- (id)initWithFrame:(NSRect)frame;
{
    if ([super initWithFrame:frame] == nil)
        return nil;

    cells = malloc(1);
    swoopCellCount = 0;
    swoop = NULL;
    swoopCount = 0;
    motionTimer = nil;
    
    return self;
}

- (void)dealloc;
{
    unsigned int cellIndex;
    
    if (motionTimer) {
        [motionTimer invalidate];
        [motionTimer release];
        motionTimer = nil;
    }

    if (swoop != NULL) {
        free(swoop);
        swoop = NULL;
    }

    for(cellIndex = 0; cellIndex < swoopCellCount; cellIndex ++) {
        NSCell *cell = cells[cellIndex].cell;
        if (cell != nil)
            [cell release];
    }
    free(cells);
    cells = NULL;
    
    [super dealloc];
}

// API

- (void)_motionTimer:arg
{
    BOOL keepGoing;
    NSTimeInterval t;

    t = [NSDate timeIntervalSinceReferenceDate];
    keepGoing = [self _updatePositionsForTime:t];

    if (!keepGoing) {
        [[self retain] autorelease];
        [motionTimer invalidate];
        [motionTimer release];
        motionTimer = nil;
        [self _compactCells];
        [self didMove];
    }
}

- (BOOL)isMoving
{
    return (motionTimer != nil)? YES : NO;
}

- (void)moveCell:(NSCell *)aCell toOrigin:(NSPoint)newOrigin delay:(NSTimeInterval)delay motion:(enum OASwoopStyle)kinematics
{
    [self _moveCellIndex:[self _indexOfCell:aCell] to:newOrigin delay:delay motion:kinematics flags:SF_Origin];
}

- (void)moveCell:(NSCell *)aCell toSize:(NSSize)newSize delay:(NSTimeInterval)delay motion:(enum OASwoopStyle)kinematics
{
    NSPoint newSizePt = (NSPoint){ newSize.width , newSize.height };
    
    [self _moveCellIndex:[self _indexOfCell:aCell] to:newSizePt delay:delay motion:kinematics flags:SF_Size];
}

- (void)moveCell:(NSCell *)aCell toFrame:(NSRect)newFrame delay:(NSTimeInterval)delay motion:(enum OASwoopStyle)kinematics
{
    int cellIndex = [self _indexOfCell:aCell];
    NSPoint newSizePt = (NSPoint){ newFrame.size.width , newFrame.size.height };

    [self _moveCellIndex:cellIndex to:newFrame.origin delay:delay motion:kinematics flags:SF_Origin];
    [self _moveCellIndex:cellIndex to:newSizePt delay:delay motion:kinematics flags:SF_Size];
}

- (void)moveCell:(NSCell *)aCell toParameter:(float)newParameter delay:(NSTimeInterval)delay motion:(enum OASwoopStyle)kinematics;
{
    // The rest of this class animates 2D quantities.  We'll store the parameter in the X coordinate.
    NSPoint parameterPoint = (NSPoint){newParameter, 0.0f};
    [self _moveCellIndex:[self _indexOfCell:aCell] to:parameterPoint delay:delay motion:kinematics flags:SF_Parameter];
}

- (void)setDelayedStart:(BOOL)flag
{
    if (!flag && swoopFlags.delayingStart) {
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval distantPast = [[NSDate distantPast] timeIntervalSinceReferenceDate];
        unsigned int swoopIndex;

        for(swoopIndex = 0; swoopIndex < swoopCount; swoopIndex ++) {
            if (swoop[swoopIndex].began == distantPast)
                swoop[swoopIndex].began = now;
        }
    }

    swoopFlags.delayingStart = ( flag ? 1 : 0 );        
}

- (BOOL)addCellIfAbsent:(NSCell *)newCell frame:(NSRect)newCellFrame parameter:(float)newParameter;
{
    unsigned int cellIndex;
    int lastEmptyIndex;

    lastEmptyIndex = -1;
    for(cellIndex = 0; cellIndex < swoopCellCount; cellIndex ++) {
        if (cells[cellIndex].cell == nil)
            lastEmptyIndex = cellIndex;
        else if (cells[cellIndex].cell == newCell)
            return NO;  // it's not absent; don't add it.
    }
    
    // Cell is not already in our array.

    if (lastEmptyIndex != -1) {
        // ... but we have an empty slot where we can put it.
        cellIndex = lastEmptyIndex;
    } else {
        // ... so we have to extend our array and put the new cell at the end.
        cellIndex = swoopCellCount ++;
        cells = realloc(cells, sizeof(*cells) * swoopCellCount);
    }

    cells[cellIndex].cell = [newCell retain];
    cells[cellIndex].rect = newCellFrame;
    cells[cellIndex].parameter = newParameter;
    [self setNeedsDisplayInRect: newCellFrame];
    
    return YES;
}

- (BOOL)addCellIfAbsent:(NSCell *)newCell frame:(NSRect)newCellFrame;
{
    return [self addCellIfAbsent:newCell frame:newCellFrame parameter:0.0f];
}

- (NSArray *)cells
{
    NSMutableArray *retval;
    unsigned int cellIndex;

    retval = [[NSMutableArray alloc] initWithCapacity:swoopCellCount];
    [retval autorelease];
    for(cellIndex = 0; cellIndex < swoopCellCount; cellIndex ++) {
        NSCell *aCell = cells[cellIndex].cell;
        if (aCell != nil)
            [retval addObject:aCell];
    }
    return retval;
}

- (NSCell *)cellAtPoint:(NSPoint)hit getFrame:(NSRect *)cellFrame_out
{
    int cellIndex;
    
    /* Go from the end of the array backwards, so that if cells overlap we'll get the top one */
    cellIndex = swoopCellCount;
    while (cellIndex --) {
        if (NSMouseInRect(hit, cells[cellIndex].rect, NO)) {
            if (cellFrame_out)
                *cellFrame_out = cells[cellIndex].rect;
            return cells[cellIndex].cell;
        }
    }

    return nil;
}

- (NSRect)frameOfCell:(NSCell *)aCell
{
    return cells[[self _indexOfCell:aCell]].rect;
}

- (NSRect)targetFrameOfCell:(NSCell *)aCell
{
    unsigned int cellIndex = [self _indexOfCell:aCell];
    unsigned int swoopIndex;
    NSRect theFrame;

    theFrame = cells[cellIndex].rect;
    for(swoopIndex = 0; swoopIndex < swoopCount; swoopIndex ++) {
        if (swoop[swoopIndex].cellIndex == (int)cellIndex) {
            float x, y;

            x = swoop[swoopIndex].begins.x + swoop[swoopIndex].slideVector.x;
            y = swoop[swoopIndex].begins.y + swoop[swoopIndex].slideVector.y;

            if (swoop[swoopIndex].flags & SF_Origin) {
                theFrame.origin.x = x;
                theFrame.origin.y = y;
            }
            if (swoop[swoopIndex].flags & SF_Size) {
                theFrame.size.width = x;
                theFrame.size.height = y;
            }
        }
    }

    return theFrame;
}

- (float)parameterOfCell:(NSCell *)aCell;
{
    return cells[[self _indexOfCell:aCell]].parameter;
}

- (int)removeCells:(NSArray *)delenda
{
    unsigned int cellIndex, cellCount, swoopIndex;
    unsigned int cellsDeleted;

    cellsDeleted = 0;
    cellCount = [delenda count];
    for(cellIndex = 0; cellIndex < cellCount; cellIndex ++) {
        if ([self _removeCell:[delenda objectAtIndex:cellIndex]])
            cellsDeleted ++;
    }

    if (cellsDeleted > 0) {
        // Deactivate any animation that was assigned to a deleted cell
        for(swoopIndex = 0; swoopIndex < swoopCount; swoopIndex ++)
            if (swoop[swoopIndex].flags != 0 &&
                cells[swoop[swoopIndex].cellIndex].cell == nil) {
                swoop[swoopIndex].flags = 0;       // mark it idle
                swoop[swoopIndex].cellIndex = -1;  // just for tidyness
                swoop[swoopIndex].duration = -1;
            }
    }

    return cellsDeleted;
}

- (int)removeCellsExcept:(NSSet *)keepThese
{
    unsigned int cellIndex;
    unsigned int cellsDeleted, cellsKept;

    if (keepThese != nil && [keepThese count] == 0)
        keepThese = nil;

    cellsDeleted = 0;
    cellsKept = 0;
    for(cellIndex = 0; cellIndex < swoopCellCount; cellIndex ++) {
        NSCell *aCell = cells[cellIndex].cell;
        if (aCell == nil)
            continue;
        if (keepThese == nil || ![keepThese containsObject:aCell]) {
            [aCell release];
            cells[cellIndex].cell = nil;
            cellsDeleted ++;
        } else
            cellsKept ++;
    }

    if (cellsDeleted > 0) {
        if (cellsKept == 0) {
            // Optimized case: we have no cells left
            if (swoopCount > 0) {
                swoopCount = 0;
                free(swoop);
                swoop = NULL;
            }
            swoopCellCount = 0;
        } else {
            // General case: fix up dangling indices, etc.
            [self _compactCells];
        }
    }

    return cellsDeleted;
}


static int do_insert(int *mapping, int mapIndex, OASwoopView *self, NSArray *ignore)
{
    int cellIndex, swoopCellCount;

    swoopCellCount = self->swoopCellCount;
    for(cellIndex = 0; cellIndex < swoopCellCount; cellIndex ++) {
        NSCell *aCell = self->cells[cellIndex].cell;
        if (aCell != nil && ([ignore indexOfObjectIdenticalTo:aCell] == NSNotFound))
            mapping[mapIndex++] = cellIndex;
    }

    return mapIndex;
}

- (void)orderCells:(NSArray *)cellsToOrder others:(NSWindowOrderingMode)relation;
{
    int *mapping;
    unsigned int newIndex, someCellIndex, someCellCount;

    mapping = malloc(sizeof(*mapping) * (1 + swoopCellCount));
    newIndex = 0;
    
    if (relation == NSWindowBelow)
        newIndex = do_insert(mapping, newIndex, self, cellsToOrder);

    someCellCount = [cellsToOrder count];
    for(someCellIndex = 0; someCellIndex < someCellCount; someCellIndex ++) {
        NSCell *someCell = [cellsToOrder objectAtIndex:someCellIndex];
        unsigned int oldIndex;
        for (oldIndex = 0; oldIndex < swoopCellCount; oldIndex ++)
            if (cells[oldIndex].cell == someCell) {
                mapping[newIndex++] = oldIndex;
                [self setNeedsDisplayInRect:cells[oldIndex].rect];
                break;
            }
        OBASSERT(oldIndex < swoopCellCount);  // Assert that we actually found the specified cell in our array
    }
    
    if (relation == NSWindowAbove)
        newIndex = do_insert(mapping, newIndex, self, cellsToOrder);

    OBASSERT(newIndex <= swoopCellCount);
    if (relation != NSWindowOut) {
        OBASSERT(newIndex == swoopCellCount);
    }
    mapping[newIndex ++] = -1;

    [self _reorderCells:mapping];

    free(mapping);
}

- (void)cellsFinished:(NSArray *)someCells
{
    /* no-op */
}

- (void)willMove
{
    /* no-op */
}

- (void)didMove
{
    /* no-op */
}

// This allows subclasses to do things like handle the 'parameter' for the cell.
- (void)drawCell:(NSCell*)cell withFrame:(NSRect)cellFrame parameter:(float)parameter;
{
    [cell drawWithFrame:cellFrame inView:self parameter:parameter];
}

// NSView subclass

- (void)drawRect:(NSRect)rect;
{
    unsigned int cellIndex;

    for(cellIndex = 0; cellIndex < swoopCellCount; cellIndex++) {
        struct swoopcell *c = &cells[cellIndex];
        if (c->cell != nil && NSIntersectsRect(rect, c->rect))
            [self drawCell:c->cell withFrame:c->rect parameter:c->parameter];
    }
}

@end

@implementation OASwoopView (Private)

- (BOOL)_updatePositionsForTime:(NSTimeInterval)tPlus
{
    NSRect dirty;
    BOOL changing, perhapsDone;
    unsigned int swoopIndex;
    unsigned int cellsJustFinished;

    dirty = NSZeroRect;
    changing = NO;
    perhapsDone = YES;
    cellsJustFinished = 0;

    [self setDelayedStart:NO];

    for(swoopIndex = 0; swoopIndex < swoopCount; swoopIndex++) {
        struct swoopcell *c = &( cells[swoop[swoopIndex].cellIndex] );
        short swooperFlags = swoop[swoopIndex].flags;  // local copy
        float tFraction, pFraction;
        NSRect cFrame;
        NSPoint cPoint;
        float cParameter;
        
        if (swooperFlags == 0)
            continue;
        else if (swoop[swoopIndex].duration < 1e-6)
            tFraction = 1.0;
        else
            tFraction = ( tPlus - swoop[swoopIndex].began ) / swoop[swoopIndex].duration;
            
        if (tFraction >= 1.0) {
            tFraction = 1.0;
            pFraction = 1.0;
            swoop[swoopIndex].flags &= ~ SF_Motion;  // we are done moving this cell
            cellsJustFinished ++;
        } else {
            perhapsDone = NO;

            switch(swoop[swoopIndex].kine) {
                case OASwoop_Linear:
                default:
                    pFraction = tFraction;
                    break;
                case OASwoop_Harmonic:
                    pFraction = 0.5 * ( 1 - cos(tFraction * M_PI) );
                    break;
                case OASwoop_HalfHarmonic:
                    pFraction = sin(tFraction * (M_PI / 2));
                    break;
                case OASwoop_Decay:
                    pFraction = (1 - exp(- tFraction)) / ( 1 - 1 / M_E );
                    break;
                case OASwoop_LinDecel:
                    pFraction = 2 * tFraction - ( tFraction * tFraction );
                    break;
                case OASwoop_Immediate:
                    // This shouldn't occur, but if it does, this is the right way to handle it
                    pFraction = 1.0;
                    break;
            }
        }

        struct swooper *s = &swoop[swoopIndex];
        cPoint.x   = s->begins.x + pFraction * s->slideVector.x;
        cPoint.y   = s->begins.y + pFraction * s->slideVector.y;
        cParameter = s->begins.x + pFraction * s->slideVector.x; // 'parameter' is stored in X component only
            
        cFrame.origin = (swooperFlags & SF_Origin)    ? cPoint                        : c->rect.origin;
        cFrame.size   = (swooperFlags & SF_Size  )    ? ((NSSize){cPoint.x,cPoint.y}) : c->rect.size;
        cParameter    = (swooperFlags & SF_Parameter) ? cPoint.x                      : c->parameter;
        
        if (NSEqualRects(cFrame, c->rect) && cParameter == c->parameter)
            continue;

        if (!changing) {
            changing = YES;
            dirty = c->rect;
        } else {
            dirty = NSUnionRect(dirty, c->rect);
        }
        c->rect = cFrame;
        c->parameter = cParameter;
        dirty = NSUnionRect(dirty, c->rect);
    }  // end of loop over swoop[]

    if (changing)
        [self setNeedsDisplayInRect:dirty];

    if (cellsJustFinished > 0) {
        NSMutableArray *cellsToNotify = [[NSMutableArray alloc] initWithCapacity:cellsJustFinished];

        for(swoopIndex = 0; swoopIndex < swoopCount; swoopIndex++) {
            struct swooper *s = &swoop[swoopIndex];
            if (s->flags == SF_Notify) {
                NSCell *c = cells[s->cellIndex].cell;
                if (c != nil)
                    [cellsToNotify addObject:c];
                s->flags = 0;  // all done
            }
        }
        
        if ([cellsToNotify count] > 0) {
            changing = YES;  // in case -cellsFinished: modifies something
            [self cellsFinished:cellsToNotify];
        }
        [cellsToNotify release];
    }

    return ( changing || !perhapsDone );
}

- (int)_indexOfCell:(NSCell *)aCell
{
    unsigned int cellIndex;

    for (cellIndex = 0; cellIndex < swoopCellCount; cellIndex++) {
        if (cells[cellIndex].cell == aCell)
            return cellIndex;
    }

    [NSException raise:NSInvalidArgumentException format:@"%@ does not contain %@", [self shortDescription], [aCell shortDescription]];
    return NSNotFound;
}

- (struct swooper *)_swooperForCellIndex:(int)cellIndex motion:(short)motionFlags
{
    unsigned int swoopIndex;

    if (cellIndex < 0 || cellIndex >= (signed)swoopCellCount) {
        return NULL;
    }

    /* Look for an existing swoop entry */
    for(swoopIndex = 0; swoopIndex < swoopCount; swoopIndex ++) {
        if (swoop[swoopIndex].cellIndex == cellIndex) {
            short swoopEntryMotionType = swoop[swoopIndex].flags & SF_Motion;
            
            if (swoopEntryMotionType == 0 || swoopEntryMotionType == motionFlags)
                return &( swoop[swoopIndex] );
        }
    }

    return NULL;
}

- (void)_moveCellIndex:(int)cellIndex to:(NSPoint)destPt delay:(NSTimeInterval)delay motion:(enum OASwoopStyle)kinematics flags:(short)cFlags
{
    struct swooper *cellSwoop;
    NSRect curFrame;
    NSPoint curPt;
    NSTimeInterval startTime;
    BOOL shortCircuit;

    if (kinematics & OASwoop_NotifyFinished) {
        kinematics &= ~ OASwoop_NotifyFinished;
        cFlags |= SF_Notify;
    }

    // Caller must be requesting something
    OBASSERT( (cFlags & SF_Motion) != 0 );
    // Caller must not be requesting both things
    OBASSERT( (cFlags & SF_Motion) != SF_Motion );

    cellSwoop = [self _swooperForCellIndex:cellIndex motion:(cFlags & SF_Motion)];
    shortCircuit = NO;

    curFrame = cells[cellIndex].rect;
    if (cFlags & SF_Origin)
        curPt = curFrame.origin;
    else if (cFlags & SF_Size) {
        curPt.x = curFrame.size.width;
        curPt.y = curFrame.size.height;
    } else if (cFlags & SF_Parameter) {
        curPt.x = cells[cellIndex].parameter;
        curPt.y = 0.0f;
    } else {
        OBASSERT_NOT_REACHED("invalid cell flags combination");
        curPt = (NSPoint){0, 0};  // pacify the compiler
    }

    // If the caller isn't requesting notification when this cell finishes, and the cell is already in the requested position, then we can short-circuit.
    if (!(cFlags & SF_Notify) && NSEqualPoints(destPt, curPt))
        shortCircuit = YES;

    // If the motion style is Immediate, move the cell right now instead of via _motionTimer:, which will fire on the next iteration of the runloop.
    if (kinematics == OASwoop_Immediate) {

        [self setNeedsDisplayInRect:curFrame];
        if (cFlags & SF_Origin)
            curFrame.origin = destPt;
        if (cFlags & SF_Size)
            curFrame.size = (NSSize){ destPt.x, destPt.y };
        if (cFlags & SF_Parameter)
            cells[cellIndex].parameter = destPt.x;
        cells[cellIndex].rect = curFrame;
        [self setNeedsDisplayInRect:curFrame];

        shortCircuit = YES;
    }

    if (shortCircuit) {

        // Deactivate an existing swoop entry
        if (cellSwoop != NULL) {
            OBASSERT(cellSwoop->cellIndex == cellIndex);
            cellSwoop->flags &= ~ SF_Motion;
            cellSwoop->duration = -1;
        }

        return;
    }

#if 0
    if (cellSwoop != NULL && kinematics == cellSwoop->kine) {
        // Special case: attempt to retarget the existing swoop. (Not always possible.)
        if ([self _retargetSwoop:cellSwoop to:newOrigin remaining:delay])
            return;
    }
#endif

    // If we don't already have a swooper for this cell, allocate one.
    if (cellSwoop == NULL) {
        swoopCount ++;
        if (swoop == NULL)
            swoop = malloc(sizeof(*swoop));
        else
            swoop = realloc(swoop, swoopCount * sizeof(*swoop));
        cellSwoop = &( swoop[swoopCount-1] );
        cellSwoop->cellIndex = cellIndex;
        cellSwoop->flags = 0;
    }

    if (swoopFlags.delayingStart)
        startTime = [[NSDate distantPast] timeIntervalSinceReferenceDate];
    else
        startTime = [NSDate timeIntervalSinceReferenceDate];

    OBASSERT(cellSwoop->cellIndex >= 0);
    OBASSERT(cellSwoop->cellIndex < (signed)swoopCellCount);
    OBASSERT(cellSwoop->cellIndex == cellIndex);
    OBASSERT(delay >= 0);

    cellSwoop->begins = curPt;
    cellSwoop->slideVector.x = destPt.x - curPt.x;
    cellSwoop->slideVector.y = destPt.y - curPt.y;
    cellSwoop->flags |= cFlags;
    cellSwoop->began = startTime;
    cellSwoop->duration = delay;
    cellSwoop->kine = kinematics;

    if (![self isMoving]) {
        if (motionTimer == nil)
            motionTimer = [[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(_motionTimer:) userInfo:nil repeats:YES] retain];
        [self willMove];
    }
}

- (BOOL)_removeCell:(NSCell *)delenda
{
    unsigned int cellIndex;

    for(cellIndex = 0; cellIndex < swoopCellCount; cellIndex ++) {
        if (cells[cellIndex].cell == delenda) {
            [cells[cellIndex].cell release];
            cells[cellIndex].cell = nil;
            [self setNeedsDisplayInRect: cells[cellIndex].rect];
            return YES;
        }
    }

    // Note: This method is private because it might leave a dangling reference from the swoop[] array into the cells[] array. Since the references are array indices, this is safe (i.e. won't cause a crash), but if a new cell is added, it may go into the newly-vacated slot and start moving around under the control of the old cell's animation. Therefore, after calling this method but before calling addCell: (and ideally before calling _updatePositionsForTime:) you either have to call _fixupCellIndices:, or remove the dangling references yourself, as -removeCells: does.

    return NO;
}

- (void)_compactCells
{
    int *cellRemap;
    int cellIndex, newCellIndex;
    int oldCellCount;
#ifdef DEBUG_SWOOP
    NSMutableString *buf; int i;

    buf = [NSMutableString stringWithString:@"\tBefore:"];
    for(i = 0; i < swoopCellCount; i++)
        [buf appendFormat:@"%p ", cells[i].cell];
#endif

    if (swoopCellCount == 0) {
        OBASSERT(swoopCount == 0);
        return;
    }

    oldCellCount = swoopCellCount;
    cellRemap = malloc(sizeof(*cellRemap) * oldCellCount);

    newCellIndex = 0;
    for(cellIndex = 0; cellIndex < oldCellCount; cellIndex ++) {
        if (cells[cellIndex].cell == nil) {
            cellRemap[cellIndex] = -1;
        } else {
            /* this slot still has a cell in it; find a new slot index to move it to */
            while (newCellIndex < cellIndex && cells[newCellIndex].cell != nil)
                newCellIndex ++;
            cellRemap[cellIndex] = newCellIndex;
            if (newCellIndex != cellIndex) {
                /* copy this cell down into a lower-numbered empty entry */
                OBASSERT(cells[newCellIndex].cell == nil);
                bcopy(&(cells[cellIndex]), &(cells[newCellIndex]), sizeof(*cells));
                cells[cellIndex].cell = nil;
            }
            newCellIndex ++;
        }
    }

#ifdef DEBUG_SWOOP
    [buf appendString:@"\n\tRemap:"];
    for(i = 0; i < oldCellCount; i++)
        [buf appendFormat:@"%d ", cellRemap[i]];
    [buf appendString:@"\n\tAfter:"];
    for(i = 0; i < newCellIndex; i++)
        [buf appendFormat:@"%p ", cells[i].cell];
    NSLog(@"_compactCells\n%@", buf);
#endif
    
    [self _fixupSwoopIndices:cellRemap newCellCount:newCellIndex];
}

- (void)_reorderCells:(int *)backmap
{
    int *cellRemap;
    int oldCellCount, newCellCount;
    int oldCellIndex, newCellIndex;
    struct swoopcell *newCells;

    if (swoopCellCount == 0) {
        OBASSERT(swoopCount == 0);
        return;
    }

    oldCellCount = swoopCellCount;
    cellRemap = malloc(sizeof(*cellRemap) * oldCellCount);
    newCells = malloc(sizeof(*newCells) * oldCellCount);
    
    for(newCellIndex = 0; newCellIndex < oldCellCount; newCellIndex ++)
        cellRemap[newCellIndex] = -1;

    for(newCellIndex = 0; newCellIndex < oldCellCount && backmap[newCellIndex] >= 0; newCellIndex ++) {
        oldCellIndex = backmap[newCellIndex];
        newCells[newCellIndex] = cells[oldCellIndex];
        cells[oldCellIndex].cell = nil;
        cellRemap[oldCellIndex] = newCellIndex;
    }
    newCellCount = newCellIndex;
    for( ; newCellIndex < oldCellCount; newCellIndex ++) {
        newCells[newCellIndex].cell = nil;
    }

    for(oldCellIndex = 0; oldCellIndex < oldCellCount; oldCellIndex ++)
        if (cells[oldCellIndex].cell != nil) {
            [self setNeedsDisplayInRect: cells[oldCellIndex].rect];
            [ (cells[oldCellIndex].cell) release ];
        }
    free(cells);
    cells = newCells;

    [self _fixupSwoopIndices:cellRemap newCellCount:newCellCount];
}

- (void)_fixupSwoopIndices:(int *)cellRemap newCellCount:(unsigned int)newCellCount
{
    unsigned int oldCellCount;
    unsigned int swoopIndex, newSwoopIndex, oldSwoopCount;

    oldCellCount = swoopCellCount;
    OBASSERT(newCellCount <= oldCellCount);
    swoopCellCount = newCellCount;

#ifdef DEBUG_SWOOP
    NSMutableString *buf; int i;
    buf = [NSMutableString stringWithString:@"\tIndices: "];
    for(i = 0; i < oldCellCount; i++)
        [buf appendFormat:@"%d ", cellRemap[i]];
    [buf appendString:@"\n\tBefore: "];
    for(i = 0; i < swoopCount; i++)
        [buf appendFormat:@"%d(%.1f) ", swoop[i].cellIndex, swoop[i].duration];
#endif

    oldSwoopCount = swoopCount;
    newSwoopIndex = 0;
    for(swoopIndex = 0; swoopIndex < oldSwoopCount; swoopIndex ++) {
        if (swoop[swoopIndex].duration >= 0) {
            /* update this entry's cell pointer to its cell's new location */
            if (swoop[swoopIndex].cellIndex >= 0) {
                OBASSERT(swoop[swoopIndex].cellIndex < (signed)oldCellCount);
                swoop[swoopIndex].cellIndex = cellRemap[swoop[swoopIndex].cellIndex];
                OBASSERT(swoop[swoopIndex].cellIndex < (signed)swoopCellCount);
            }
            /* check whether the cell disappeared out from under this entry */
            if (swoop[swoopIndex].cellIndex < 0)
                swoop[swoopIndex].duration = -1;
            else {
                /* Okay, this swoop entry is still in use; find a new index for it */
                while (newSwoopIndex < swoopIndex && swoop[newSwoopIndex].duration >= 0)
                    newSwoopIndex ++;
                if (newSwoopIndex != swoopIndex) {
                    OBASSERT(swoop[newSwoopIndex].duration < 0);
                    bcopy(&(swoop[swoopIndex]), &(swoop[newSwoopIndex]), sizeof(*swoop));
                    swoop[swoopIndex].duration = -1;
                }
                newSwoopIndex ++;
            }
        }
    }
    swoopCount = newSwoopIndex;
    OBASSERT(swoopCount <= oldSwoopCount);

    free(cellRemap);

#ifdef DEBUG_SWOOP
    [buf appendString:@"\n\tAfter:  "];
    for(i = 0; i < swoopCount; i++)
        [buf appendFormat:@"%d(%.1f) ", swoop[i].cellIndex, swoop[i].duration];
    NSLog(@"_fixupSwoopIndices:\n%@", buf);
#endif

    if (swoopCount == 0 && swoop != NULL) {
        free(swoop);
        swoop = NULL;
    }
}

@end


@implementation NSCell (OASwoopViewExtensions)

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView parameter:(float)parameter;
{
    [self drawWithFrame:cellFrame inView:controlView];
}

@end

