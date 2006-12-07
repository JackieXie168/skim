// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/NSView-OAExtensions.h>

#import <ApplicationServices/ApplicationServices.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import <OmniAppKit/NSFont-OAExtensions.h>
#import <OmniAppKit/NSApplication-OAExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSView-OAExtensions.m,v 1.53 2004/02/10 04:07:35 kc Exp $")

//#define TIME_LIMIT

@implementation NSView (OAExtensions)

// Drawing

+ (void)drawRoundedRect:(NSRect)rect cornerRadius:(float)radius color:(NSColor *)color isFilled:(BOOL)isFilled;
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    [color set];

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, NSMinX(rect), NSMinY(rect) + radius);
    CGContextAddLineToPoint(context, NSMinX(rect), NSMaxY(rect) - radius);
    CGContextAddArcToPoint(context, NSMinX(rect), NSMaxY(rect), NSMinX(rect) + radius, NSMaxY(rect), radius);
    CGContextAddLineToPoint(context, NSMaxX(rect) - radius, NSMaxY(rect));
    CGContextAddArcToPoint(context, NSMaxX(rect), NSMaxY(rect), NSMaxX(rect), NSMaxY(rect) - radius, radius);
    CGContextAddLineToPoint(context, NSMaxX(rect), NSMinY(rect) + radius);
    CGContextAddArcToPoint(context, NSMaxX(rect), NSMinY(rect), NSMaxX(rect) - radius, NSMinY(rect), radius);
    CGContextAddLineToPoint(context, NSMinX(rect) + radius, NSMinY(rect));
    CGContextAddArcToPoint(context, NSMinX(rect), NSMinY(rect), NSMinX(rect), NSMinY(rect) + radius, radius);
    CGContextClosePath(context);
    if (isFilled) {
        CGContextFillPath(context);
    } else {
        CGContextStrokePath(context);
    }
}

- (void)drawRoundedRect:(NSRect)rect cornerRadius:(float)radius color:(NSColor *)color;
{
    [isa drawRoundedRect:rect cornerRadius:radius color:color isFilled:YES];
}

- (void)drawHorizontalSelectionInRect:(NSRect)rect;
{
    double height;
    
    [[NSColor selectedControlColor] set];
    NSRectFill(rect);

    [[NSColor controlShadowColor] set];
    height = NSHeight(rect);
    rect.size.height = 1.0;
    NSRectFill(rect);
    rect.origin.y += height;
    NSRectFill(rect);
}

- (void) drawSelfAndSubviewsInRect: (NSRect) rect;
{
    unsigned int subviewIndex, subviewCount;
    
    [self drawRect: rect];
    subviewCount = [_subviews count];
    for (subviewIndex = 0; subviewIndex < subviewCount; subviewIndex++) {
        NSRect subviewRect;
        NSView *subview;
        
        subview = [_subviews objectAtIndex: subviewIndex];
        subviewRect = [self convertRect: rect toView: subview];
        subviewRect = NSIntersectionRect(subviewRect, [subview bounds]);
        if (NSWidth(subviewRect) > 0.0) {
            [subview lockFocus];
            [subview drawSelfAndSubviewsInRect: subviewRect];
            [subview unlockFocus];
        }
    }
}


// Scrolling

typedef struct {
    NSView *view;
    float x;
    float y;
} OADeferredScrollEntry;

static OADeferredScrollEntry *scrollEntries;
static unsigned int scrollEntriesAllocated = 0;
static unsigned int scrollEntriesCount = 0;

- (OADeferredScrollEntry *)_deferredScrollEntry;
{
    OADeferredScrollEntry *deferredScrollEntry;

    if (scrollEntriesAllocated == 0) {
        scrollEntriesAllocated = 8;
        scrollEntries = malloc(scrollEntriesAllocated * sizeof(*scrollEntries));
    }
    deferredScrollEntry = scrollEntries + scrollEntriesCount;
    while (deferredScrollEntry-- > scrollEntries)
        if (deferredScrollEntry->view == self)
            return deferredScrollEntry;

    // We didn't find an existing entry, let's make a new one
    if (scrollEntriesCount == scrollEntriesAllocated) {
        scrollEntriesAllocated = scrollEntriesCount + scrollEntriesCount;
        scrollEntries = realloc(scrollEntries, scrollEntriesAllocated * sizeof(*scrollEntries));
    }
    deferredScrollEntry = scrollEntries + scrollEntriesCount;
    deferredScrollEntry->view = [self retain];
    deferredScrollEntry->x = 0.0;
    deferredScrollEntry->y = 0.0;
    scrollEntriesCount++;
    return deferredScrollEntry;
}

- (void)_scrollDownByAdjustedPixels:(float)pixels;
{
    NSRect visibleRect;

    // NSLog(@"-[%@ _scrollDownByAdjustedPixels:%1.0f]", OBShortObjectDescription(self), pixels);
    visibleRect = [self visibleRect];
    if ([self isFlipped])
        visibleRect.origin.y += pixels;
    else
        visibleRect.origin.y -= pixels;
    [self scrollPoint:[self adjustScroll:visibleRect].origin];
}

- (void)_scrollRightByAdjustedPixels:(float)pixels;
{
    NSRect visibleRect;

    // NSLog(@"-[%@ _scrollRightByAdjustedPixels:%1.0f]", OBShortObjectDescription(self), pixels);
    visibleRect = [self visibleRect];
    visibleRect.origin.x += pixels;
    [self scrollPoint:[self adjustScroll:visibleRect].origin];
}

+ (void)performDeferredScrolling;
{
    OADeferredScrollEntry *deferredScrollEntry;

    if (![NSThread inMainThread])
        [NSException raise:NSInternalInconsistencyException format:@"+[NSView(OAExtensions) performDeferredScrolling] is not thread-safe"];

    deferredScrollEntry = scrollEntries + scrollEntriesCount;
    while (deferredScrollEntry-- > scrollEntries) {
        NSView *view;
        float x, y;

        view = deferredScrollEntry->view;
        x = deferredScrollEntry->x;
        y = deferredScrollEntry->y;
        if (x != 0.0)
            [view _scrollRightByAdjustedPixels:x];
        if (y != 0.0)
            [view _scrollDownByAdjustedPixels:y];
        [view release];
    }
    scrollEntriesCount = 0;
}

- (void)scrollDownByAdjustedPixels:(float)pixels;
{
    OADeferredScrollEntry *deferredScrollEntry;

    if (![NSThread inMainThread])
        [NSException raise:NSInternalInconsistencyException format:@"-[NSView(OAExtensions) scrollDownByAdjustedPixels:] is not thread-safe"];

    // NSLog(@"-[%@ scrollDownByAdjustedPixels:%1.0f]", OBShortObjectDescription(self), pixels);
    deferredScrollEntry = [self _deferredScrollEntry];
    deferredScrollEntry->y += pixels;
    [isa queueSelectorOnce:@selector(performDeferredScrolling)];
}

- (void)scrollRightByAdjustedPixels:(float)pixels;
{
    OADeferredScrollEntry *deferredScrollEntry;

    if (![NSThread inMainThread])
        [NSException raise:NSInternalInconsistencyException format:@"-[NSView(OAExtensions) scrollRightByAdjustedPixels:] is not thread-safe"];

    // NSLog(@"-[%@ scrollRightByAdjustedPixels:%1.0f]", OBShortObjectDescription(self), pixels);
    deferredScrollEntry = [self _deferredScrollEntry];
    deferredScrollEntry->x += pixels;
    [isa queueSelectorOnce:@selector(performDeferredScrolling)];
}

- (void)scrollToTop;
{
    [self setFraction:0.0];
}

- (void)scrollToEnd;
{
    [self setFraction:1.0];
}

- (void)scrollDownByPages:(float)pagesToScroll;
{
    float pageScrollAmount;
    
    pageScrollAmount = NSHeight([self visibleRect]) - [[self enclosingScrollView] verticalPageScroll];
    if (pageScrollAmount < 1.0)
        pageScrollAmount = 1.0;
    [self scrollDownByAdjustedPixels:pagesToScroll * pageScrollAmount];
}

- (void)scrollDownByLines:(float)linesToScroll;
{
    float lineScrollAmount;
    
    lineScrollAmount = [[self enclosingScrollView] verticalLineScroll];
    [self scrollDownByAdjustedPixels:linesToScroll * lineScrollAmount];
}

- (void)scrollDownByPercentage:(float)percentage;
{
    [self scrollDownByAdjustedPixels:percentage * NSHeight([self visibleRect])];
}

- (void)scrollRightByPages:(float)pagesToScroll;
{
    float pageScrollAmount;
    
    pageScrollAmount = NSWidth([self visibleRect]) - [[self enclosingScrollView] horizontalPageScroll];
    if (pageScrollAmount < 1.0)
        pageScrollAmount = 1.0;
    [self scrollRightByAdjustedPixels:pagesToScroll * pageScrollAmount];
}

- (void)scrollRightByLines:(float)linesToScroll;
{
    float lineScrollAmount;
    
    lineScrollAmount = [[self enclosingScrollView] horizontalLineScroll];
    [self scrollRightByAdjustedPixels:linesToScroll * lineScrollAmount];
}

- (void)scrollRightByPercentage:(float)percentage;
{
    [self scrollRightByAdjustedPixels:percentage * NSHeight([self visibleRect])];
}

- (NSPoint)scrollPositionAsPercentage;
{
    NSRect bounds, visibleRect;
    NSPoint scrollPosition;

    bounds = [self bounds];
    visibleRect = [self visibleRect];

    if (NSHeight(visibleRect) >= NSHeight(bounds)) {
        scrollPosition.y = 0.0; // We're completely visible
    } else {
        scrollPosition.y = (NSMinY(visibleRect) - NSMinY(bounds)) / (NSHeight(bounds) - NSHeight(visibleRect));
        if (![self isFlipped])
            scrollPosition.y = 1.0 - scrollPosition.y;
        scrollPosition.y = MIN(MAX(scrollPosition.y, 0.0), 1.0);
    }

    if (NSWidth(visibleRect) >= NSWidth(bounds)) {
        scrollPosition.x = 0.0; // We're completely visible
    } else {
        scrollPosition.x = (NSMinX(visibleRect) - NSMinX(bounds)) / (NSWidth(bounds) - NSWidth(visibleRect));
        scrollPosition.x = MIN(MAX(scrollPosition.x, 0.0), 1.0);
    }

    return scrollPosition;
}

- (void)setScrollPositionAsPercentage:(NSPoint)scrollPosition;
{
    NSRect bounds, desiredRect;

    bounds = [self bounds];
    desiredRect = [self visibleRect];
    if (NSHeight(desiredRect) >= NSHeight(bounds))
        return; // We're entirely visible

    scrollPosition.y = MIN(MAX(scrollPosition.y, 0.0), 1.0);
    if (![self isFlipped])
        scrollPosition.y = 1.0 - scrollPosition.y;
    desiredRect.origin.y = NSMinY(bounds) + scrollPosition.y * (NSHeight(bounds) - NSHeight(desiredRect));
    if (NSMinY(desiredRect) < NSMinY(bounds))
        desiredRect.origin.y = NSMinY(bounds);
    else if (NSMaxY(desiredRect) > NSMaxY(bounds))
        desiredRect.origin.y = NSMaxY(bounds) - NSHeight(desiredRect);

    scrollPosition.x = MIN(MAX(scrollPosition.x, 0.0), 1.0);
    desiredRect.origin.x = NSMinX(bounds) + scrollPosition.x * (NSWidth(bounds) - NSWidth(desiredRect));
    if (NSMinX(desiredRect) < NSMinX(bounds))
        desiredRect.origin.x = NSMinX(bounds);
    else if (NSMaxX(desiredRect) > NSMaxX(bounds))
        desiredRect.origin.x = NSMaxX(bounds) - NSHeight(desiredRect);

    [self scrollPoint:desiredRect.origin];
}


- (float)fraction;
{
    NSRect bounds, visibleRect;
    float fraction;

    bounds = [self bounds];
    visibleRect = [self visibleRect];
    if (NSHeight(visibleRect) >= NSHeight(bounds))
        return 0.0; // We're completely visible
    fraction = (NSMinY(visibleRect) - NSMinY(bounds)) / (NSHeight(bounds) - NSHeight(visibleRect));
    if (![self isFlipped])
        fraction = 1.0 - fraction;
    return MIN(MAX(fraction, 0.0), 1.0);
}

- (void)setFraction:(float)fraction;
{
    NSRect bounds, desiredRect;

    bounds = [self bounds];
    desiredRect = [self visibleRect];
    if (NSHeight(desiredRect) >= NSHeight(bounds))
        return; // We're entirely visible

    fraction = MIN(MAX(fraction, 0.0), 1.0);
    if (![self isFlipped])
        fraction = 1.0 - fraction;
    desiredRect.origin.y = NSMinY(bounds) + fraction * (NSHeight(bounds) - NSHeight(desiredRect));
    if (NSMinY(desiredRect) < NSMinY(bounds))
        desiredRect.origin.y = NSMinY(bounds);
    else if (NSMaxY(desiredRect) > NSMaxY(bounds))
        desiredRect.origin.y = NSMaxY(bounds) - NSHeight(desiredRect);
    [self scrollPoint:desiredRect.origin];
}

// Dragging

- (BOOL)shouldStartDragFromMouseDownEvent:(NSEvent *)event dragSlop:(float)dragSlop finalEvent:(NSEvent **)finalEventPointer timeoutDate:(NSDate *)timeoutDate;
{
    NSEvent *currentEvent;
    NSPoint eventLocation;
    NSRect slopRect;

    OBPRECONDITION([event type] == NSLeftMouseDown);

    currentEvent = [NSApp currentEvent];
    if (currentEvent != event) {
        // We've already processed this once, let's try to return the same answer as before.  (This lets you call this method more than once for the same event without it pausing to wait for a whole new set of drag / mouse up events.)
        return [currentEvent type] == NSLeftMouseDragged;
    }

    eventLocation = [event locationInWindow];
    slopRect = NSInsetRect(NSMakeRect(eventLocation.x, eventLocation.y, 0.0, 0.0), -dragSlop, -dragSlop);

    while (1) {
        NSEvent *nextEvent;

        nextEvent = [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask | NSLeftMouseUpMask untilDate:timeoutDate inMode:NSEventTrackingRunLoopMode dequeue:YES];
        if (finalEventPointer != NULL)
            *finalEventPointer = nextEvent;
        if (nextEvent == nil) { // Timeout date reached
            return NO;
        } else if ([nextEvent type] == NSLeftMouseUp) {
            return NO;
        } else if (!NSMouseInRect([nextEvent locationInWindow], slopRect, NO)) {
            return YES;
        }
    }
}

- (BOOL)shouldStartDragFromMouseDownEvent:(NSEvent *)event dragSlop:(float)dragSlop finalEvent:(NSEvent **)finalEventPointer timeoutInterval:(NSTimeInterval)timeoutInterval;
{
    return [self shouldStartDragFromMouseDownEvent:event dragSlop:dragSlop finalEvent:finalEventPointer timeoutDate:[NSDate dateWithTimeIntervalSinceNow:timeoutInterval]];
}

- (BOOL)shouldStartDragFromMouseDownEvent:(NSEvent *)event dragSlop:(float)dragSlop finalEvent:(NSEvent **)finalEventPointer;
{
    return [self shouldStartDragFromMouseDownEvent:event dragSlop:dragSlop finalEvent:finalEventPointer timeoutDate:[NSDate distantFuture]];
}

//
// Resizing
//

#define MIN_MORPH_DIST (5.0)

- (void) morphToFrame: (NSRect) newFrame overTimeInterval: (NSTimeInterval) morphInterval;
{
    NSRect          currentFrame, deltaFrame;
    NSTimeInterval  start, current, elapsed;
    
    currentFrame = [self frame];
    deltaFrame.origin.x = newFrame.origin.x - currentFrame.origin.x;
    deltaFrame.origin.y = newFrame.origin.y - currentFrame.origin.y;
    deltaFrame.size.width = newFrame.size.width - currentFrame.size.width;
    deltaFrame.size.height = newFrame.size.height - currentFrame.size.height;
    
    // If nothing interesting is going on, just jump to the end state
    if (deltaFrame.origin.x < MIN_MORPH_DIST &&
        deltaFrame.origin.y < MIN_MORPH_DIST &&
        deltaFrame.size.width < MIN_MORPH_DIST &&
        deltaFrame.size.height < MIN_MORPH_DIST) {
        [self setFrame: newFrame];
        return;
    }
    
    start = [NSDate timeIntervalSinceReferenceDate];    
    while (YES) {
        float  ratio;
        NSRect stepFrame;
        
        current = [NSDate timeIntervalSinceReferenceDate];
        elapsed = current - start;
        if (elapsed >  morphInterval || [NSApp peekEvent])
            break;

        ratio = elapsed / morphInterval;
        stepFrame.origin.x = currentFrame.origin.x + ratio * deltaFrame.origin.x;
        stepFrame.origin.y = currentFrame.origin.y + ratio * deltaFrame.origin.y;
        stepFrame.size.width = currentFrame.size.width + ratio * deltaFrame.size.width;
        stepFrame.size.height = currentFrame.size.height + ratio * deltaFrame.size.height;
        
        [self setFrame: stepFrame];
        [_window display];
        [_window flushWindow];
    }
    
    // Make sure we don't end up with round off errors
    [self setFrame: newFrame];
    [_window display];
    [_window flushWindow];
}

//
// View fade in/out
//

/*
The approach taken in both -fadeInSubview: and -fadeOutAndRemoveFromSuperview is to build two images and fade between them.  We could build only one image and ask the opaque superview to draw, but this could be arbitrarily expensive.  Instead, by only asking the view to draw once, we can build a more consistently performant method.
*/

- (void) fadeInSubview: (NSView *) subview overTimeInterval: (NSTimeInterval) fadeInterval;
{
    NSBitmapImageRep *oldImageRep;
    NSBitmapImageRep *newImageRep = nil;
    NSImage          *newImage;
    NSTimeInterval    start, current, elapsed;
    NSRect            subviewFrame, subviewBounds, opaqueRect, localRect;
    NSWindow         *window;
    NSView           *opaqueView;
    
    if (!subview)
        return;

    subviewFrame = [subview frame];
    window = [self window];
    if (!window || ![window isVisible]) {
        // Don't lock focus since that'll raise an exception.  Also, we're not
        // visible.  Showing off by yourself is just silly.
        [self addSubview: subview];
        return;
    }
    
    opaqueView = [self opaqueAncestor];

    // Capture the old contents of the window
    [self lockFocus];
    oldImageRep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect: subviewFrame] autorelease];
    [self unlockFocus];
    //[[oldImageRep TIFFRepresentation] writeToFile: @"/tmp/old-fadein.tiff" atomically: YES];
    

    // Some views are really persistent about getting drawn when we don't
    // want them to (like NSOutlineView).  Turning off needs display on 
    // the window and all of its views doesn't work. 
    // We'll put the smack down on that...
    [_window disableFlushWindow];

    NS_DURING {
        [self addSubview: subview];
        subviewBounds = [subview bounds];
        opaqueRect = [subview convertRect: subviewBounds toView: opaqueView];
        
        [opaqueView lockFocus];
        [opaqueView drawSelfAndSubviewsInRect: opaqueRect];
        newImageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: opaqueRect];
        [opaqueView unlockFocus];
        //[[newImageRep TIFFRepresentation] writeToFile: @"/tmp/new-fadein.tiff" atomically: YES];
        localRect = [subview convertRect:[subview bounds] toView:self];
        [subview removeFromSuperview];
    } NS_HANDLER {
        [_window enableFlushWindow];
        [localException raise];
    } NS_ENDHANDLER;
    
    // Make sure all the drawing happens while window flushing is off
    [NSApp peekEvent];
    [_window enableFlushWindow];
    
    newImage = [[[NSImage alloc] initWithSize: opaqueRect.size] autorelease];
    [newImage addRepresentation: newImageRep];
    [newImageRep release];
    
    // Now, fade from the starting image to the ending image
    start = [NSDate timeIntervalSinceReferenceDate];    
    while (YES) {
        current = [NSDate timeIntervalSinceReferenceDate];
        elapsed = current - start;
        if (elapsed >  fadeInterval || [NSApp peekEvent])
            break;

        [self lockFocus];
        [oldImageRep drawAtPoint: localRect.origin];
        [newImage dissolveToPoint: localRect.origin fraction: elapsed / fadeInterval];
        [self unlockFocus];
        
        [window flushWindow];
    }
    
    [self addSubview:subview];
        
    // Make sure the final version gets drawn
    [subview displayRect: subviewBounds];
    [_window flushWindow];
}

/* See notes above -fadeInSubview: for design of this method */
- (void) fadeOutAndRemoveFromSuperviewOverTimeInterval: (NSTimeInterval) fadeInterval;
{
    NSBitmapImageRep *oldImageRep, *newImageRep;
    NSImage          *newImage;
    NSTimeInterval    start, current, elapsed;
    NSView           *superview, *opaqueView;
    NSRect            opaqueRect, superRect;
    NSWindow         *window;
    
    // Hold onto this (since we are going to get removed)
    superview = [self superview];
    if (!superview)
        return;

    window = [superview window];
    if (!window || ![window isVisible]) {
        // Don't lock focus since that'll raise an exception.  Also, we're not
        // visible.  Showing off by yourself is just silly.
        [self removeFromSuperview];
        return;
    }

    opaqueView = [self opaqueAncestor];
    opaqueRect = [self convertRect: _bounds toView: opaqueView];
    superRect = [self convertRect: _bounds toView: superview];
    
    [self lockFocus];
    oldImageRep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect: _bounds] autorelease];
    [self unlockFocus];
    
    // When we get removed, we might get deallocated.  Make sure that this doesn't
    // happen util the animation is done.  Also, tell our window that it doesn't
    // need to be drawn since otherwise the NSEvent stuff below will cause it to get drawn
    [[self retain] autorelease];
    [self removeFromSuperview];
    [window setViewsNeedDisplay: NO];
    
    // Build the new image now that we are out of the way
    [opaqueView lockFocus];
    [opaqueView drawSelfAndSubviewsInRect: opaqueRect];
    newImageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: opaqueRect];
    [opaqueView unlockFocus];
    
    newImage = [[[NSImage alloc] initWithSize: opaqueRect.size] autorelease];
    [newImage addRepresentation: newImageRep];
    [newImageRep release];
    
    
    // Now, fade from the starting image to the ending image
    start = [NSDate timeIntervalSinceReferenceDate];    
    while (YES) {
        current = [NSDate timeIntervalSinceReferenceDate];
        elapsed = current - start;
        if (elapsed >  fadeInterval || [NSApp peekEvent])
            break;

        [superview lockFocus];
        [oldImageRep drawAtPoint: superRect.origin];
        [newImage dissolveToPoint: superRect.origin fraction: elapsed / fadeInterval];
        [superview unlockFocus];
        
        [window flushWindow];
    }

    // Make sure the final version gets drawn
    [opaqueView displayRect: opaqueRect];
    [window flushWindow];
}

- (NSBitmapImageRep *)bitmapForRect:(NSRect)rect;
{
    NSBitmapImageRep *imageRep;
    NSRect boundsRect, intersection;
    
    boundsRect = [self bounds];
    //NSLog(@"visible rect = %@", NSStringFromRect(visibleRect));
    //NSLog(@"requested rect = %@", NSStringFromRect(rect));
    
    intersection = NSIntersectionRect(boundsRect, rect);
    if (!NSEqualRects(rect, intersection)) {
        [NSException raise: NSInvalidArgumentException
                    format: @"-[NSView imageForRect:] -- Requested rect %@ is not totally contained in the bounds rect %@", NSStringFromRect(rect), NSStringFromRect(boundsRect)];
    }

    // Note: This does not include subviews
    [self lockFocus];
    imageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:rect];
    [self unlockFocus];

    return [imageRep autorelease];
}

- (NSImage *)imageForRect:(NSRect)rect;
{
    NSBitmapImageRep *imageRep;
    NSImage *image;
    
    if (!(imageRep = [self bitmapForRect:rect]))
        return nil;
    
    image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
    [image addRepresentation:imageRep];
    
    return image;
}

// Debugging

unsigned int NSViewMaxDebugDepth = 10;

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [NSMutableDictionary dictionary];
    [debugDictionary setObject:OBShortObjectDescription(self) forKey:@"__self__"];
    [debugDictionary setObject:NSStringFromRect([self frame]) forKey:@"01_frame"];
    if (!NSEqualSizes([self bounds].size, [self frame].size) || !NSEqualPoints([self bounds].origin, NSZeroPoint))
        [debugDictionary setObject:NSStringFromRect([self bounds]) forKey:@"02_bounds"];
    if ([[self subviews] count] > 0)
        [debugDictionary setObject:[self subviews] forKey:@"subviews"];
    return debugDictionary;
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned int)level;
{
    if (level < NSViewMaxDebugDepth)
        return [[self debugDictionary] descriptionWithLocale:locale indent:level];
    else
        return [self shortDescription];
}

- (NSString *)description;
{
    return [self descriptionWithLocale:nil indent:0];
}

- (NSString *)shortDescription;
{
    return [super description];
}

- (void)logViewHierarchy:(int)level;
{
    NSArray *subviews;
    int count, index;

    subviews = [self subviews];
    count = [subviews count];

    NSLog(@"%@<%@: %p> frame: %@, bounds: %@, %d children:",
          [NSString spacesOfLength:level * 2], NSStringFromClass([self class]), self,
          NSStringFromRect([self frame]), NSStringFromRect([self bounds]), count);

    for (index = 0; index < count; index++)
        [(NSView *)[subviews objectAtIndex:index] logViewHierarchy:level + 1];
}

- (void)logViewHierarchy;
{
    [self logViewHierarchy:0];
}

@end
