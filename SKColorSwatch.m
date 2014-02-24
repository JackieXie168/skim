//
//  SKColorSwatch.m
//  Skim
//
//  Created by Christiaan Hofman on 7/4/07.
/*
 This software is Copyright (c) 2007-2014
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
#import "SKAccessibilityFauxUIElement.h"
#import "NSEvent_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"

NSString *SKColorSwatchColorsChangedNotification = @"SKColorSwatchColorsChangedNotification";

#define COLORS_KEY      @"colors"

#define TARGET_KEY      @"target"
#define ACTION_KEY      @"action"
#define AUTORESIZES_KEY @"autoResizes"


@interface SKAccessibilityColorSwatchElement : SKAccessibilityIndexedFauxUIElement
@end


@implementation SKColorSwatch

@synthesize action, target, colors, autoResizes;
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
    if ([self infoForBinding:COLORS_KEY])
        [self unbind:COLORS_KEY];
    SKDESTROY(colors);
    [super dealloc];
}

- (BOOL)isOpaque{  return YES; }

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent { return YES; }

- (BOOL)acceptsFirstResponder { return YES; }

- (void)sizeToFit {
    NSRect frame = [self frame];
    NSInteger count = [colors count];
    frame.size.width = count * (NSHeight(frame) - 3.0) + 3.0;
    [self setFrame:frame];
}

- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bounds];
    NSInteger count = [colors count];
    
    bounds.size.width = fmin(NSWidth(bounds), count * (NSHeight(bounds) - 3.0) + 3.0);
    
    NSRectEdge sides[4] = {NSMaxYEdge, NSMaxXEdge, NSMinXEdge, NSMinYEdge};
    CGFloat grays[4] = {0.5, 0.75, 0.75, 0.75};
    
    rect = NSDrawTiledRects(bounds, rect, sides, grays, 4);
    
    [[NSBezierPath bezierPathWithRect:rect] addClip];
    
    NSRect r = NSMakeRect(1.0, 1.0, NSHeight(rect), NSHeight(rect));
    NSInteger i;
    for (i = 0; i < count; i++) {
        NSColor *borderColor = [NSColor colorWithCalibratedWhite:0.66667 alpha:1.0];
        [borderColor set];
        [NSBezierPath setDefaultLineWidth:1.0];
        [NSBezierPath strokeRect:NSInsetRect(r, 0.5, 0.5)];
        borderColor = highlightedIndex == i ? [NSColor selectedControlColor] : [NSColor controlBackgroundColor];
        [borderColor set];
        [[NSBezierPath bezierPathWithRect:NSInsetRect(r, 1.5, 1.5)] stroke];
        [[colors objectAtIndex:i] drawSwatchInRect:NSInsetRect(r, 2.0, 2.0)];
        r.origin.x += NSHeight(r) - 1.0;
    }
    
    if (insertionIndex != -1) {
        [[NSColor selectedControlColor] setFill];
        NSRectFill(NSMakeRect(insertionIndex * (NSHeight(rect) - 1.0), 1.0, 3.0, NSHeight(rect)));
    }
    
    if ([self refusesFirstResponder] == NO && [NSApp isActive] && [[self window] isKeyWindow] && [[self window] firstResponder] == self && focusedIndex != -1) {
        r = NSInsetRect([self bounds], 1.0, 1.0);
        r.size.width = NSHeight(r);
        r.origin.x += focusedIndex * (NSWidth(r) - 1.0);
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRectFill(r);
    }
}

- (void)setKeyboardFocusRingNeedsDisplayInRect:(NSRect)rect {
    [super setKeyboardFocusRingNeedsDisplayInRect:rect];
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint mouseLoc = [theEvent locationInView:self];
    NSInteger i = [self colorIndexAtPoint:mouseLoc];
    
    if ([self isEnabled]) {
        highlightedIndex = i;
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
        [self setNeedsDisplay:YES];
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
                    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
                    [pboard clearContents];
                    [pboard writeObjects:[NSArray arrayWithObjects:color, nil]];
                    
                    NSRect rect = NSMakeRect(0.0, 0.0, 12.0, 12.0);
                    NSImage *image = [[NSImage alloc] initWithSize:rect.size];
                    [image lockFocus];
                    [[NSColor blackColor] set];
                    [NSBezierPath setDefaultLineWidth:1.0];
                    [NSBezierPath strokeRect:NSInsetRect(rect, 0.5, 0.5)];
                    [color drawSwatchInRect:NSInsetRect(rect, 1.0, 1.0)];
                    [image unlockFocus];
                    
                    mouseLoc = [theEvent locationInView:self];
                    mouseLoc.x -= 6.0;
                    mouseLoc.y -= 6.0;
                    [self dragImage:image at:mouseLoc offset:NSZeroSize event:theEvent pasteboard:pboard source:self slideBack:YES];
                    
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

- (void)unhighlight {
    highlightedIndex = -1;
    insertionIndex = -1;
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
}

- (void)performClickAtIndex:(NSInteger)i {
    if ([self isEnabled] && i != -1) {
        clickedIndex = i;
        [self sendAction:[self action] to:[self target]];
        clickedIndex = -1;
        highlightedIndex = i;
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
        [self setNeedsDisplay:YES];
        [self performSelector:@selector(unhighlight) withObject:nil afterDelay:0.2];
    }
}

- (void)performClick:(id)sender {
    [self performClickAtIndex:focusedIndex];
}

- (void)moveRight:(id)sender {
    if (++focusedIndex >= (NSInteger)[colors count])
        focusedIndex = 0;
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    NSAccessibilityPostNotification(self, NSAccessibilityFocusedUIElementChangedNotification);
}

- (void)moveLeft:(id)sender {
    if (--focusedIndex < 0)
        focusedIndex = [colors count] - 1;
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    NSAccessibilityPostNotification(self, NSAccessibilityFocusedUIElementChangedNotification);
}

- (NSInteger)colorIndexAtPoint:(NSPoint)point {
    NSRect rect = NSInsetRect([self bounds], 2.0, 2.0);
    
    if (NSMouseInRect(point, rect, [self isFlipped])) {
        NSInteger i, count = [colors count];
        
        rect.size.width = NSHeight(rect);
        for (i = 0; i < count; i++) {
            if (NSMouseInRect(point, rect, [self isFlipped]))
                return i;
            rect.origin.x += NSWidth(rect) + 1.0;
        }
    }
    return -1;
}

- (NSInteger)insertionIndexAtPoint:(NSPoint)point {
    NSRect rect = NSInsetRect([self bounds], 2.0, 2.0);
    CGFloat w = NSHeight(rect) + 1.0;
    CGFloat x = NSMinX(rect) + w / 2.0;
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

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    return isLocal ? NSDragOperationGeneric : NSDragOperationDelete;
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    if ((operation & NSDragOperationDelete) != 0 && operation != NSDragOperationEvery) {
        if (draggedIndex != -1 && [self isEnabled]) {
            [self willChangeValueForKey:COLORS_KEY];
            [colors removeObjectAtIndex:draggedIndex];
            if (autoResizes)
                [self sizeToFit];
            [self didChangeValueForKey:COLORS_KEY];
            [self notifyColorsChanged];
            [self setNeedsDisplay:YES];
            NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:draggedIndex parent:self], NSAccessibilityUIElementDestroyedNotification);
        }
    }
}

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
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
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
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSColor *color = [NSColor colorFromPasteboard:pboard];
    BOOL isCopy = insertionIndex != -1;
    NSInteger i = isCopy ? insertionIndex : highlightedIndex;
    
    if (i != -1 && color) {
        [self willChangeValueForKey:COLORS_KEY];
        if (isCopy) {
            [colors insertObject:color atIndex:i];
            if (autoResizes)
                [self sizeToFit];
            NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:i parent:self], NSAccessibilityCreatedNotification);
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
    NSPoint localPoint = [self convertPoint:[[self window] convertScreenToBase:point] fromView:nil];
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

- (id)valueForFauxUIElement:(SKAccessibilityFauxUIElement *)element {
    if ([element index] >= (NSInteger)[[self colors] count])
        return nil;
    return [[[self colors] objectAtIndex:[element index]] accessibilityValue];
}

- (NSRect)screenRectForFauxUIElement:(SKAccessibilityFauxUIElement *)element {
    NSRect rect = NSZeroRect;
    if ([element index] < (NSInteger)[[self colors] count]) {
        rect = NSInsetRect([self bounds], 1.0, 1.0);
        rect.size.width = NSHeight(rect);
        rect.origin.x += [element index] * (NSWidth(rect) - 1.0);
        rect = [self convertRect:rect toView:nil];
        rect.origin = [[self window] convertBaseToScreen:rect.origin];
    }
    return rect;
}

- (BOOL)isFauxUIElementFocused:(SKAccessibilityFauxUIElement *)element {
    return focusedIndex == [element index];
}

- (void)fauxUIElement:(SKAccessibilityFauxUIElement *)element setFocused:(BOOL)focused {
    if (focused && [element index] < (NSInteger)[[self colors] count]) {
        [[self window] makeFirstResponder:self];
        focusedIndex = [element index];
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    }
}

- (void)pressFauxUIElement:(SKAccessibilityFauxUIElement *)element {
    if ([element index] < (NSInteger)[[self colors] count])
        [self performClickAtIndex:[element index]];
}

@end

#pragma mark -

@implementation SKAccessibilityColorSwatchElement

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

- (id)accessibilityRoleAttribute {
    return NSAccessibilityColorWellRole;
}

- (id)accessibilityRoleDescriptionAttribute {
    return NSAccessibilityRoleDescriptionForUIElement(self);
}

- (id)accessibilityValueAttribute {
    return [[self parent] valueForFauxUIElement:self];
}

- (NSArray *)accessibilityActionNames {
    return [NSArray arrayWithObject:NSAccessibilityPressAction];
}

@end
