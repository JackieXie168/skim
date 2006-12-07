// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OAOutlineFormatter.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

#import <OmniAppKit/OAOutlineEntry.h>
#import <OmniAppKit/OAOutlineView.h>
#import <OmniAppKit/NSImage-OAExtensions.h>
#import <OmniAppKit/NSView-OAExtensions.h>
#import <OmniFoundation/OFObject.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineFormatter.m,v 1.13 2003/01/15 22:51:40 kc Exp $")

@interface OAOutlineFormatter (Private)
- (BOOL)mouseIsDownOnDisclosureButtonForEvent:(NSEvent *)event inRect:(NSRect)rect ofEntry:(OAOutlineEntry *)anEntry;
@end

@implementation OAOutlineFormatter

static NSImage *collapsed, *collapsedPressed;
static NSImage *expanded, *expandedPressed;
static NSSize imageSize;
static NSSize dragPointSize;
static NSImage *dragPoint;
static void *nonretainedDisclosingEntry = NULL;

+ (void)initialize
{
    static BOOL initialized = NO;
    
    [super initialize];
    if (initialized)
        return;
    initialized = YES;

    collapsed = [[NSImage imageNamed:@"NSTriangleNormalRight"] retain];
    collapsedPressed = [[NSImage imageNamed:@"NSTrianglePressedRight"] retain];
    expanded = [[NSImage imageNamed:@"NSTriangleNormalDown"] retain];
    expandedPressed = [[NSImage imageNamed:@"NSTrianglePressedDown"] retain];
    imageSize = [collapsed size];

    dragPoint = [[NSImage imageNamed:@"OAOutlineDraggingPoint" inBundleForClass:[OAOutlineFormatter class]] retain];
    dragPointSize = [dragPoint size];
}

- init
{
    if (![super init])
	return nil;
    entrySpacing = 0.0;
    return self;
}

- (void)setEntrySpacing:(float)spacing;
{
    entrySpacing = spacing;
}

- (float)entrySpacing;
{
    return entrySpacing;
}

- (float)buttonWidth;
{
    return imageSize.width;
}

- (float)entryHeight:(OAOutlineEntry *)anEntry;
{
    return imageSize.height + entrySpacing;
}

- (void)drawSelectionForEntry:(OAOutlineEntry *)anEntry entryRect:(NSRect)rect;
{
    OAOutlineView *outlineView = [anEntry outlineView];
    NSRect frame;

    frame = [outlineView frame];

    frame.origin.y = NSMinY(rect);
    frame.size.height = NSHeight(rect) - entrySpacing;
    [outlineView drawHorizontalSelectionInRect:frame];
}

- (void)drawEntry:(OAOutlineEntry *)anEntry entryRect:(NSRect)rect selected:(BOOL)selected parent:(BOOL)parent hidden:(BOOL)hidden dragging:(BOOL)dragging;
{
    if (dragging) {
        [dragPoint compositeToPoint:NSMakePoint(NSMinX(rect), NSMidY(rect) + dragPointSize.height / 2.0) operation:NSCompositeSourceOver];
    } else {
        if (selected)
            [self drawSelectionForEntry:anEntry entryRect:rect];

        if ([[anEntry outlineView] isHierarchical]) {
            NSImage *image = nil;

            if (parent) {
                if (nonretainedDisclosingEntry == anEntry)
                    image = hidden ? collapsedPressed : expandedPressed;
                else
                    image = hidden ? collapsed : expanded;
            }

            rect.size.height -= entrySpacing;
            [image compositeToPoint:NSMakePoint(NSMinX(rect), NSMidY(rect) + imageSize.height / 2.0) operation:NSCompositeSourceOver];
        }
    }
}

- (void)mouseDown:(NSEvent *)event inRect:(NSRect)rect ofEntry:(OAOutlineEntry *)anEntry;
{
    OAOutlineView *outlineView;

    outlineView = [anEntry outlineView];
    if ([outlineView isSelectable]) {
        if ([event modifierFlags] & NSShiftKeyMask) {
            // If shift is down, toggle selection
            if ([outlineView selection] == anEntry)
                [outlineView setSelectionTo:nil];
            else
                [outlineView setSelectionTo:anEntry];
        } else
            // else just select current item
            [outlineView setSelectionTo:anEntry];
    }
    if ([self mouseIsDownOnDisclosureButtonForEvent:event inRect:rect ofEntry:anEntry]) {
        nonretainedDisclosingEntry = anEntry;
        [outlineView displayRect:rect];
    }
}

- (void)mouseUp:(NSEvent *)event inRect:(NSRect)rect ofEntry:(OAOutlineEntry *)anEntry;
{
    if ([self mouseIsDownOnDisclosureButtonForEvent:event inRect:rect ofEntry:anEntry])
        [anEntry toggleHidden];
}

- (void)trackMouse:(NSEvent *)mouseDownEvent inRect:(NSRect)rect ofEntry:(OAOutlineEntry *)anEntry;
{
    OAOutlineView *outlineView;
    NSEvent *finalEvent;
    BOOL shouldStartDrag;

    [self mouseDown:mouseDownEvent inRect:rect ofEntry:anEntry];

    outlineView = [anEntry outlineView];
    shouldStartDrag = [outlineView shouldStartDragFromMouseDownEvent:mouseDownEvent dragSlop:5 finalEvent:&finalEvent];

    if (nonretainedDisclosingEntry) {
        nonretainedDisclosingEntry = NULL;
        [[anEntry outlineView] displayRect:rect];
    }
    
    if (!shouldStartDrag)
        [self mouseUp:mouseDownEvent inRect:rect ofEntry:anEntry];
    else if (!([mouseDownEvent modifierFlags] & NSShiftKeyMask))
        [outlineView dragSublist:anEntry causedByEvent:mouseDownEvent currentEvent:finalEvent];
}

@end

@implementation OAOutlineFormatter (Private)

- (BOOL)mouseIsDownOnDisclosureButtonForEvent:(NSEvent *)event inRect:(NSRect)rect ofEntry:(OAOutlineEntry *)anEntry;
{
    NSPoint point;
    OAOutlineView *outlineView;

    outlineView = [anEntry outlineView];

    // If we hit the button, toggle whether we show our children
    point = [outlineView convertPoint:[event locationInWindow] fromView:nil];
    return ([outlineView isHierarchical] && NSMinX(rect) <= point.x && point.x < NSMinX(rect) + imageSize.width);
}

@end