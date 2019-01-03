//
//  SKColorSwatch.m
//  Skim
//
//  Created by Christiaan Hofman on 7/4/07.
/*
 This software is Copyright (c) 2007-2019
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SKColorSwatch.h"
#import "NSColor_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "NSGraphics_SKExtensions.h"
#import "NSShadow_SKExtensions.h"

NSString *SKColorSwatchColorsChangedNotification = @"SKColorSwatchColorsChangedNotification";

#define COLORS_KEY      @"colors"

#define TARGET_KEY      @"target"
#define ACTION_KEY      @"action"
#define AUTORESIZES_KEY @"autoResizes"

#define BEZEL_HEIGHT 23.0
#define BEZEL_INSET 1.0
#define BEZEL_INSET_OLD 0.0
#define COLOR_INSET 2.0
#define COLOR_SEPARATION 1.0

#if SDK_BEFORE(10_7)
@interface NSView (SKLionExtensions)
- (NSRect)focusRingMask;
- (void)drawFocusRingMask;
- (void)noteFocusRingMaskChanged;
@end
#endif

@interface SKAccessibilityColorSwatchElement : NSObject {
    SKColorSwatch *parent;
    NSInteger index;
}
+ (id)elementWithIndex:(NSInteger)anIndex parent:(SKColorSwatch *)aParent;
- (id)initWithIndex:(NSInteger)anIndex parent:(SKColorSwatch *)aParent;
@property (nonatomic, readonly) SKColorSwatch *parent;
@property (nonatomic, readonly) NSInteger index;
@end

@interface SKColorSwatch (SKPrivate)
- (void)dragObject:(id<NSPasteboardWriting>)object withImage:(NSImage *)image fromFrame:(NSRect)frame forEvent:(NSEvent *)event;
@end

@interface SKColorSwatch (SKAccessibilityColorSwatchElementParent)
- (NSRect)screenRectForElementAtIndex:(NSInteger)anIndex;
- (BOOL)isElementAtIndexFocused:(NSInteger)anIndex;
- (void)elementAtIndex:(NSInteger)anIndex setFocused:(BOOL)focused;
- (void)pressElementAtIndex:(NSInteger)anIndex;
@end

#if !DEPLOYMENT_BEFORE(10_7)
@interface SKColorSwatch (SKLionExtensions) <NSDraggingSource>
@end
#endif

@implementation SKColorSwatch

@synthesize colors, autoResizes;
@synthesize clickedColorIndex=clickedIndex;
@dynamic color;

+ (void)initialize {
    SKINITIALIZE;
    
    [self exposeBinding:COLORS_KEY];
}

- (Class)valueClassForBinding:(NSString *)binding {
    if ([binding isEqualToString:COLORS_KEY])
        return [NSArray class];
    else
        return [super valueClassForBinding:binding];
}

- (void)commonInit {
    highlightedIndex = -1;
    insertionIndex = -1;
    focusedIndex = 0;
    clickedIndex = -1;
    draggedIndex = -1;
    modifiedIndex = -1;

    [self registerForDraggedTypes:[NSColor readableTypesForPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]]];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        colors = [[NSMutableArray alloc] initWithObjects:[NSColor whiteColor], nil];
        action = NULL;
        target = nil;
        autoResizes = YES;
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        colors = [[NSMutableArray alloc] initWithArray:[decoder decodeObjectForKey:COLORS_KEY]];
        action = NSSelectorFromString([decoder decodeObjectForKey:ACTION_KEY]);
        target = [decoder decodeObjectForKey:TARGET_KEY];
        autoResizes = [decoder decodeBoolForKey:AUTORESIZES_KEY];
        [self commonInit];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:colors forKey:COLORS_KEY];
    [coder encodeObject:NSStringFromSelector(action) forKey:ACTION_KEY];
    [coder encodeConditionalObject:target forKey:TARGET_KEY];
    [coder encodeBool:autoResizes forKey:AUTORESIZES_KEY];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self infoForBinding:COLORS_KEY])
        SKENSURE_MAIN_THREAD( [self unbind:COLORS_KEY]; );
    SKDESTROY(colors);
    [super dealloc];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent { return YES; }

- (BOOL)acceptsFirstResponder { return YES; }

- (CGFloat)bezelInset {
    return RUNNING_BEFORE(10_10) ? BEZEL_INSET_OLD : BEZEL_INSET;
}

- (NSRect)bezelFrame {
    CGFloat inset = [self bezelInset];
    NSRect bounds = NSInsetRect([self bounds], inset, inset);
    return bounds;
}

- (CGFloat)distanceBetweenColors {
    return NSHeight([self bezelFrame]) - 2.0 * COLOR_INSET + COLOR_SEPARATION;
}

- (NSRect)frameForColorAtIndex:(NSInteger)anIndex {
    NSRect rect = NSInsetRect([self bezelFrame], COLOR_INSET, COLOR_INSET);
    rect.size.width = NSHeight(rect);
    if (anIndex > 0)
        rect.origin.x += anIndex * [self distanceBetweenColors];
    return rect;
}

- (NSSize)sizeForNumberOfColors:(NSUInteger)count {
    CGFloat inset = [self bezelInset];
    CGFloat offset = 2.0 * COLOR_INSET - COLOR_SEPARATION;
    NSSize size;
    size.height = BEZEL_HEIGHT + 2.0 * inset;
    size.width = count * (BEZEL_HEIGHT - offset) + offset + 2.0 * inset;
    return size;
}

- (void)sizeToFit {
    [self setFrameSize:[self sizeForNumberOfColors:[colors count]]];
}

- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bezelFrame];
    NSInteger count = [colors count];
    CGFloat shrinkWidth = [self sizeForNumberOfColors:count].width - NSWidth(bounds);
    NSInteger shrinkIndex = -1;
    
    if (shrinkWidth > 0.0)
        shrinkIndex = modifiedIndex;
    else if (shrinkWidth < 0.0)
        bounds.size.width += shrinkWidth;
    
    // @@ Dark mode
    
    [NSBezierPath setDefaultLineWidth:1.0];
    
    [NSGraphicsContext saveGraphicsState];
    
    CGFloat radius = 0.0;
    NSColor *borderColor = nil;
    NSColor *highlightColor = nil;
    if (RUNNING_BEFORE(10_10)) {
        static const NSRectEdge sides[4] = {NSMaxYEdge, NSMaxXEdge, NSMinXEdge, NSMinYEdge};
        static const CGFloat grays[5] = {0.5, 0.75, 0.75, 0.75, 0.66667};
        rect = NSDrawTiledRects(bounds, rect, sides, grays, 4);
        [[NSColor colorWithCalibratedWhite:grays[4] alpha:1.0] setFill];
        [NSBezierPath fillRect:rect];
        borderColor = [NSColor controlBackgroundColor];
        highlightColor = [NSColor selectedControlColor];
    } else {
        static const CGFloat grays[16] = {0.94, 0.98, 0.7, 0.5,  0.96, 0.96, 0.7, 0.5,  0.34, 0.37, 0.3, 0.55,  0.2, 0.2, 0.3, 0.55};
        NSUInteger offset = SKHasDarkAppearance(self) ? 8 : 0;
        if ([[self window] isMainWindow] == NO && [[self window] isKeyWindow] == NO)
            offset += 4;
        NSColor *startColor = [NSColor colorWithCalibratedWhite:grays[offset] alpha:1.0];
        NSColor *endColor = [NSColor colorWithCalibratedWhite:grays[offset + 1] alpha:1.0];
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor] autorelease];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:4.0 yRadius:4.0];
        [NSGraphicsContext saveGraphicsState];
        [NSShadow setShadowWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.33333] blurRadius:1.2 yOffset:-0.2];
        [startColor setFill];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        [gradient drawInBezierPath:path angle:90.0];
        borderColor = [NSColor colorWithCalibratedWhite:grays[offset + 2] alpha:1.0];
        highlightColor = [NSColor colorWithCalibratedWhite:grays[offset + 3] alpha:1.0];
        radius = 1.5;
    }
    
    [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 1.0, 1.0) xRadius:2.0 * radius yRadius:2.0 * radius] addClip];
    
    NSRect r = [self frameForColorAtIndex:0];
    CGFloat distance = [self distanceBetweenColors];
    NSInteger i;
    for (i = 0; i < count; i++) {
        if (shrinkIndex == i)
            r.size.width -= shrinkWidth;
        if (NSWidth(r) >= 1.0) {
            if (NSWidth(r) > 2.0)
                [[colors objectAtIndex:i] drawSwatchInRect:NSInsetRect(r, 1.0, 1.0)];
            [(highlightedIndex == i ? highlightColor : borderColor) setStroke];
            [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(r, 0.5, 0.5) xRadius:radius yRadius:radius] stroke];
        }
        r.origin.x += distance;
        if (shrinkIndex == i) {
            r.origin.x -= shrinkWidth;
            r.size.width = NSHeight(r);
        }
    }
    
    if (insertionIndex != -1) {
        [highlightColor setFill];
        r = [self frameForColorAtIndex:insertionIndex];
        r.origin.x -= 1.0;
        r.size.width = 1.0;
        NSRectFill(NSInsetRect(r, -1.0, -1.0));
    }
    
    [NSGraphicsContext restoreGraphicsState];

    if (RUNNING_BEFORE(10_7) && [self refusesFirstResponder] == NO && [NSApp isActive] && [[self window] isKeyWindow] && [[self window] firstResponder] == self && focusedIndex != -1) {
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRectFill([self frameForColorAtIndex:focusedIndex]);
    }
}

- (NSRect)focusRingMaskBounds {
    if (focusedIndex == -1)
        return NSZeroRect;
    return [self frameForColorAtIndex:focusedIndex];
}

- (void)drawFocusRingMask {
    NSRect rect = [self focusRingMaskBounds];
    if (NSIsEmptyRect(rect) == NO) {
        if (RUNNING_BEFORE(10_7))
            NSRectFill(rect);
        else
            [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:2.0 yRadius:2.0] fill];
    }
}

- (void)dirty {
    if (RUNNING_BEFORE(10_7))
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
}

- (void)handleKeyOrMainStateChanged:(NSNotification *)note {
    [self setNeedsDisplay:YES];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    NSWindow *oldWindow = [self window];
    NSArray *names = [NSArray arrayWithObjects:NSWindowDidBecomeMainNotification, NSWindowDidResignMainNotification, NSWindowDidBecomeKeyNotification, NSWindowDidResignKeyNotification, nil];
    if (oldWindow) {
        for (NSString *name in names)
            [[NSNotificationCenter defaultCenter] removeObserver:self name:name object:oldWindow];
    }
    if (newWindow) {
        for (NSString *name in names)
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyOrMainStateChanged:) name:name object:newWindow];
    }
    [super viewWillMoveToWindow:newWindow];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    if ([self window])
        [self handleKeyOrMainStateChanged:nil];
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint mouseLoc = [theEvent locationInView:self];
    NSInteger i = [self colorIndexAtPoint:mouseLoc];
    
    if ([self isEnabled]) {
        highlightedIndex = i;
        [self dirty];
    }
    
    if (i != -1) {
        BOOL keepOn = YES;
        while (keepOn) {
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
            switch ([theEvent type]) {
                case NSLeftMouseDragged:
                {
                    if ([self isEnabled]) {
                        highlightedIndex = -1;
                        insertionIndex = -1;
                        [self setNeedsDisplay:YES];
                    }
                    
                    draggedIndex = i;
                    
                    NSColor *color = [colors objectAtIndex:i];
                    
                    // @@ Dark mode
                    
                    NSImage *image = [NSImage bitmapImageWithSize:NSMakeSize(12.0, 12.0) scale:[self backingScale] drawingHandler:^(NSRect rect){
                        [color drawSwatchInRect:NSInsetRect(rect, 1.0, 1.0)];
                        [[NSColor blackColor] set];
                        [NSBezierPath setDefaultLineWidth:1.0];
                        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5) xRadius:1.5 yRadius:1.5] stroke];
                    }];
                    
                    NSRect rect = SKRectFromCenterAndSquareSize([theEvent locationInView:self], 12.0);
                    
                    [self dragObject:color withImage:image fromFrame:rect forEvent:theEvent];
                    
                    keepOn = NO;
                    break;
                }
                case NSLeftMouseUp:
                    if ([self isEnabled]) {
                        highlightedIndex = -1;
                        insertionIndex = -1;
                        clickedIndex = i;
                        [self setNeedsDisplay:YES];
                        [self sendAction:[self action] to:[self target]];
                        clickedIndex = -1;
                    }
                    keepOn = NO;
                    break;
                default:
                    break;
            }
        }
    }
}

- (void)performClickAtIndex:(NSInteger)i {
    if ([self isEnabled] && i != -1) {
        clickedIndex = i;
        [self sendAction:[self action] to:[self target]];
        clickedIndex = -1;
        highlightedIndex = i;
        [self dirty];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            highlightedIndex = -1;
            insertionIndex = -1;
            [self dirty];
        });
    }
}

- (void)performClick:(id)sender {
    [self performClickAtIndex:focusedIndex];
}

- (void)moveRight:(id)sender {
    if (++focusedIndex >= (NSInteger)[colors count])
        focusedIndex = 0;
    if ([self respondsToSelector:@selector(noteFocusRingMaskChanged)])
        [self noteFocusRingMaskChanged];
    [self dirty];
    NSAccessibilityPostNotification(self, NSAccessibilityFocusedUIElementChangedNotification);
}

- (void)moveLeft:(id)sender {
    if (--focusedIndex < 0)
        focusedIndex = [colors count] - 1;
    if ([self respondsToSelector:@selector(noteFocusRingMaskChanged)])
        [self noteFocusRingMaskChanged];
    [self dirty];
    NSAccessibilityPostNotification(self, NSAccessibilityFocusedUIElementChangedNotification);
}

- (NSInteger)colorIndexAtPoint:(NSPoint)point {
    NSRect rect = [self frameForColorAtIndex:0];
    CGFloat distance = [self distanceBetweenColors];
    NSInteger i, count = [colors count];
    
    for (i = 0; i < count; i++) {
        if (NSMouseInRect(point, rect, [self isFlipped]))
            return i;
        rect.origin.x += distance;
    }
    return -1;
}

- (NSInteger)insertionIndexAtPoint:(NSPoint)point {
    NSRect rect = [self frameForColorAtIndex:0];
    CGFloat w = [self distanceBetweenColors];
    CGFloat x = NSMidX(rect);
    NSInteger i, count = [colors count];
    
    for (i = 0; i < count; i++) {
        if (point.x < x)
            return i;
        x += w;
    }
    return count;
}

- (void)notifyColorsChanged {
    NSDictionary *info = [self infoForBinding:COLORS_KEY];
    id observedObject = [info objectForKey:NSObservedObjectKey];
    NSString *observedKeyPath = [info objectForKey:NSObservedKeyPathKey];
    if (observedObject && observedKeyPath) {
        id value = [[colors copy] autorelease];
        NSString *transformerName = [[info objectForKey:NSOptionsKey] objectForKey:NSValueTransformerNameBindingOption];
        if (transformerName && [transformerName isEqual:[NSNull null]] == NO) {
            NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:transformerName];
            value = [valueTransformer reverseTransformedValue:value]; 
        }
        [observedObject setValue:value forKeyPath:observedKeyPath];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SKColorSwatchColorsChangedNotification object:self];
}

#pragma mark Accessors

- (SEL)action { return action; }

- (void)setAction:(SEL)newAction { action = newAction; }

- (id)target { return target; }

- (void)setTarget:(id)newTarget { target = newTarget; }

- (NSArray *)colors {
    return [[colors copy] autorelease];
}

- (void)setColors:(NSArray *)newColors {
    NSArray *oldColors = [self colors];
    [colors setArray:newColors];
    if (autoResizes && [newColors count] != [oldColors count])
        [self sizeToFit];
    if ([self window]) {
        NSUInteger i = [oldColors count], iMax = [newColors count];
        while (i-- > 0)
            NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:i parent:self], NSAccessibilityUIElementDestroyedNotification);
        for (i = 0; i < iMax; i++)
            NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:i parent:self], NSAccessibilityCreatedNotification);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SKColorSwatchColorsChangedNotification object:self];
}

- (NSColor *)color {
    NSInteger i = clickedIndex;
    return i == -1 ? nil : [colors objectAtIndex:i];
}

#pragma mark NSDraggingSource protocol 

#if DEPLOYMENT_BEFORE(10_7)

- (void)dragObject:(id<NSPasteboardWriting>)object withImage:(NSImage *)image fromFrame:(NSRect)frame forEvent:(NSEvent *)event {
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard clearContents];
    [pboard writeObjects:[NSArray arrayWithObjects:object, nil]];
    
    NSPoint dragPoint = frame.origin;
    if ([self isFlipped])
        dragPoint.y += NSHeight(frame);
    
    [self dragImage:image at:dragPoint offset:NSZeroSize event:event pasteboard:pboard source:self slideBack:YES];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    return isLocal ? NSDragOperationGeneric : NSDragOperationDelete;
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    if ((operation & NSDragOperationDelete) != 0 && operation != NSDragOperationEvery) {
        if (draggedIndex != -1 && [self isEnabled]) {
            if (autoResizes) {
                modifiedIndex = draggedIndex;
                NSSize size = [self sizeForNumberOfColors:[colors count] - 1];
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                    [[self animator] setFrameSize:size];
                }
                completionHandler:^{
                    modifiedIndex = -1;
                    [self willChangeValueForKey:COLORS_KEY];
                    [colors removeObjectAtIndex:draggedIndex];
                    [self didChangeValueForKey:COLORS_KEY];
                    [self notifyColorsChanged];
                    [self sizeToFit];
                    [self setNeedsDisplay:YES];
                    NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:draggedIndex parent:self], NSAccessibilityUIElementDestroyedNotification);
                }];
            } else {
                [self willChangeValueForKey:COLORS_KEY];
                [colors removeObjectAtIndex:draggedIndex];
                [self didChangeValueForKey:COLORS_KEY];
                [self notifyColorsChanged];
                [self setNeedsDisplay:YES];
                NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:draggedIndex parent:self], NSAccessibilityUIElementDestroyedNotification);
            }
        }
    }
}

#else

- (void)dragObject:(id<NSPasteboardWriting>)object withImage:(NSImage *)image fromFrame:(NSRect)frame forEvent:(NSEvent *)event {
    NSDraggingItem *dragItem = [[[NSDraggingItem alloc] initWithPasteboardWriter:object] autorelease];
    [dragItem setDraggingFrame:frame contents:image];
    [self beginDraggingSessionWithItems:[NSArray arrayWithObjects:dragItem, nil] event:event source:self];
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return context == NSDraggingContextWithinApplication ? NSDragOperationGeneric : NSDragOperationDelete;
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    if ((operation & NSDragOperationDelete) != 0 && operation != NSDragOperationEvery) {
        if (draggedIndex != -1 && [self isEnabled]) {
            if (autoResizes) {
                modifiedIndex = draggedIndex;
                NSSize size = [self sizeForNumberOfColors:[colors count] - 1];
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                    [[self animator] setFrameSize:size];
                }
                completionHandler:^{
                    modifiedIndex = -1;
                    [self willChangeValueForKey:COLORS_KEY];
                    [colors removeObjectAtIndex:draggedIndex];
                    [self didChangeValueForKey:COLORS_KEY];
                    [self notifyColorsChanged];
                    [self sizeToFit];
                    [self setNeedsDisplay:YES];
                    NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:draggedIndex parent:self], NSAccessibilityUIElementDestroyedNotification);
                }];
            } else {
                [self willChangeValueForKey:COLORS_KEY];
                [colors removeObjectAtIndex:draggedIndex];
                [self didChangeValueForKey:COLORS_KEY];
                [self notifyColorsChanged];
                [self setNeedsDisplay:YES];
                NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:draggedIndex parent:self], NSAccessibilityUIElementDestroyedNotification);
            }
        }
    }
}

#endif

#pragma mark NSDraggingDestination protocol 

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    NSPoint mouseLoc = [self convertPoint:[sender draggingLocation] fromView:nil];
    BOOL isCopy = ([NSEvent standardModifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSAlternateKeyMask;
    NSInteger i = isCopy ? [self insertionIndexAtPoint:mouseLoc] : [self colorIndexAtPoint:mouseLoc];
    NSDragOperation dragOp = isCopy ? NSDragOperationCopy : NSDragOperationGeneric;
    if ([sender draggingSource] == self && isCopy == NO)
        i = -1;
    [self dirty];
    if ([self isEnabled] == NO || i == -1) {
        highlightedIndex = -1;
        insertionIndex = -1;
        dragOp = NSDragOperationNone;
    } else if (isCopy) {
        highlightedIndex = -1;
        insertionIndex = i;
    } else {
        highlightedIndex = i;
        insertionIndex = -1;
    }
    return dragOp;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    highlightedIndex = -1;
    insertionIndex = -1;
    [self dirty];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSColor *color = [NSColor colorFromPasteboard:pboard];
    BOOL isCopy = insertionIndex != -1;
    NSInteger i = isCopy ? insertionIndex : highlightedIndex;
    
    if (i != -1 && color) {
        [self willChangeValueForKey:COLORS_KEY];
        if (isCopy) {
            modifiedIndex = i;
            [colors insertObject:color atIndex:i];
            NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:i parent:self], NSAccessibilityCreatedNotification);
            if (autoResizes) {
                NSSize size = [self sizeForNumberOfColors:[colors count]];
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                    [[self animator] setFrameSize:size];
                }
                completionHandler:^{
                    modifiedIndex = -1;
                    [self sizeToFit];
                }];
            }
        } else {
            [colors replaceObjectAtIndex:i withObject:color];
            NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:i parent:self], NSAccessibilityValueChangedNotification);
        }
        [self didChangeValueForKey:COLORS_KEY];
        [self notifyColorsChanged];
    }
    
    highlightedIndex = -1;
    insertionIndex = -1;
    [self setNeedsDisplay:YES];
    
	return YES;
}

#pragma mark Accessibility

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil) {
        attributes = [[NSArray alloc] initWithObjects:
            NSAccessibilityRoleAttribute,
            NSAccessibilityRoleDescriptionAttribute,
            NSAccessibilityChildrenAttribute,
            NSAccessibilityContentsAttribute,
            NSAccessibilityParentAttribute,
            NSAccessibilityWindowAttribute,
            NSAccessibilityTopLevelUIElementAttribute,
            NSAccessibilityPositionAttribute,
            NSAccessibilitySizeAttribute,
            nil];
    }
    return attributes;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return NSAccessibilityGroupRole;
    } else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
        return NSAccessibilityRoleDescriptionForUIElement(self);
    } else if ([attribute isEqualToString:NSAccessibilityChildrenAttribute] || [attribute isEqualToString:NSAccessibilityContentsAttribute]) {
        NSMutableArray *children = [NSMutableArray array];
        NSInteger i, count = [colors count];
        for (i = 0; i < count; i++)
            [children addObject:[SKAccessibilityColorSwatchElement elementWithIndex:i parent:self]];
        return NSAccessibilityUnignoredChildren(children);
    } else {
        return [super accessibilityAttributeValue:attribute];
    }
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    return NO;
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
}

- (BOOL)accessibilityIsIgnored {
    return NO;
}

- (id)accessibilityHitTest:(NSPoint)point {
    NSPoint localPoint = [self convertPointFromScreen:point];
    NSInteger i = [self colorIndexAtPoint:localPoint];
    if (i != -1) {
        SKAccessibilityColorSwatchElement *color = [[[SKAccessibilityColorSwatchElement alloc] initWithIndex:i parent:self] autorelease];
        return [color accessibilityHitTest:point];
    } else {
        return [super accessibilityHitTest:point];
    }
}

- (id)accessibilityFocusedUIElement {
    if (focusedIndex != -1 && focusedIndex < (NSInteger)[colors count])
        return NSAccessibilityUnignoredAncestor([[[SKAccessibilityColorSwatchElement alloc] initWithIndex:focusedIndex parent:self] autorelease]);
    else
        return NSAccessibilityUnignoredAncestor(self);
}

- (id)valueForElementAtIndex:(NSInteger)anIndex {
    if (anIndex >= (NSInteger)[[self colors] count])
        return nil;
    return [[[self colors] objectAtIndex:anIndex] accessibilityValue];
}

- (NSRect)screenRectForElementAtIndex:(NSInteger)anIndex {
    NSRect rect = NSZeroRect;
    if (anIndex < (NSInteger)[[self colors] count])
        return [self convertRectToScreen:NSInsetRect([self frameForColorAtIndex:anIndex], -1.0, -1.0)];
    return rect;
}

- (BOOL)isElementAtIndexFocused:(NSInteger)anIndex {
    return focusedIndex == anIndex;
}

- (void)elementAtIndex:(NSInteger)anIndex setFocused:(BOOL)focused {
    if (focused && anIndex < (NSInteger)[[self colors] count]) {
        [[self window] makeFirstResponder:self];
        focusedIndex = anIndex;
        if ([self respondsToSelector:@selector(noteFocusRingMaskChanged)])
            [self noteFocusRingMaskChanged];
        [self dirty];
    }
}

- (void)pressElementAtIndex:(NSInteger)anIndex {
    if (anIndex < (NSInteger)[[self colors] count])
        [self performClickAtIndex:anIndex];
}

@end

#pragma mark -

@implementation SKAccessibilityColorSwatchElement

@synthesize parent, index;

+ (id)elementWithIndex:(NSInteger)anIndex parent:(SKColorSwatch *)aParent {
    return [[[self alloc] initWithIndex:anIndex parent:aParent] autorelease];
}

- (id)initWithIndex:(NSInteger)anIndex parent:(SKColorSwatch *)aParent {
    self = [super init];
    if (self) {
        parent = aParent;
        index = anIndex;
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    if ([other isKindOfClass:[self class]] == NO)
        return NO;
    SKAccessibilityColorSwatchElement *otherElement = (SKAccessibilityColorSwatchElement *)other;
    return parent == [otherElement parent] && index == [otherElement index];
}

- (NSUInteger)hash {
    return [parent hash] + ((index + 1) >> 4);
}

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil) {
        attributes = [[NSArray alloc] initWithObjects:
            NSAccessibilityRoleAttribute,
            NSAccessibilityRoleDescriptionAttribute,
            NSAccessibilityValueAttribute,
            NSAccessibilityParentAttribute,
            NSAccessibilityWindowAttribute,
            NSAccessibilityTopLevelUIElementAttribute,
            NSAccessibilityFocusedAttribute,
            NSAccessibilityPositionAttribute,
            NSAccessibilitySizeAttribute,
            nil];
    }
    return attributes;
}


- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return NSAccessibilityColorWellRole;
    } else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
        return NSAccessibilityRoleDescriptionForUIElement(self);
    } else if ([attribute isEqualToString:NSAccessibilityValueAttribute]) {
        return [parent valueForElementAtIndex:index];
    } else if ([attribute isEqualToString:NSAccessibilityParentAttribute]) {
        return NSAccessibilityUnignoredAncestor(parent);
    } else if ([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
        // We're in the same window as our parent.
        return [NSAccessibilityUnignoredAncestor(parent) accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
        // We're in the same top level element as our parent.
        return [NSAccessibilityUnignoredAncestor(parent) accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
        return [NSNumber numberWithBool:[parent isElementAtIndexFocused:index]];
    } else if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
        return [NSValue valueWithPoint:[parent screenRectForElementAtIndex:index].origin];
    } else if ([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
        return [NSValue valueWithSize:[parent screenRectForElementAtIndex:index].size];
    } else {
        return nil;
    }
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    return [attribute isEqualToString:NSAccessibilityFocusedAttribute];
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityFocusedAttribute])
        [parent elementAtIndex:index setFocused:[value boolValue]];
}

- (BOOL)accessibilityIsIgnored {
    return NO;
}

- (id)accessibilityHitTest:(NSPoint)point {
    return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement {
    return NSAccessibilityUnignoredAncestor(self);
}

- (NSArray *)accessibilityActionNames {
    return [NSArray arrayWithObject:NSAccessibilityPressAction];
}

- (NSString *)accessibilityActionDescription:(NSString *)anAction {
    return NSAccessibilityActionDescription(anAction);
}

- (void)accessibilityPerformAction:(NSString *)anAction {
    if ([anAction isEqualToString:NSAccessibilityPressAction])
        [parent pressElementAtIndex:index];
}

@end
