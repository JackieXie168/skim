//
//  SKColorSwatch.m
//  Skim
//
//  Created by Christiaan Hofman on 7/4/07.
/*
 This software is Copyright (c) 2007-2008
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
#import "OBUtilities.h"
#import <Carbon/Carbon.h>

NSString *SKColorSwatchColorsChangedNotification = @"SKColorSwatchColorsChangedNotification";

NSString *SKColorSwatchColorsKey = @"colors";

static NSString *SKColorSwatchTargetKey = @"target";
static NSString *SKColorSwatchActionKey = @"action";

static NSString *SKColorSwatchColorsObservationContext = @"SKColorSwatchColorsObservationContext";


@interface SKAccessibilityColorSwatchElement : NSObject {
    int index;
    SKColorSwatch *colorSwatch;
}
- (id)initWithIndex:(int)anIndex colorSwatch:(SKColorSwatch *)aColorSwatch;
- (int)index;
- (SKColorSwatch *)colorSwatch;
@end


@implementation SKColorSwatch

+ (void)initialize {
    OBINITIALIZE;
    
    [self exposeBinding:SKColorSwatchColorsKey];
}

- (Class)valueClassForBinding:(NSString *)binding {
    if ([binding isEqualToString:SKColorSwatchColorsKey])
        return [NSArray class];
    else
        return [super valueClassForBinding:binding];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        colors = [[NSMutableArray alloc] initWithObjects:[NSColor whiteColor], nil];
        highlightedIndex = -1;
        insertionIndex = -1;
        focusedIndex = 0;
        clickedIndex = -1;
        draggedIndex = -1;
        autoResizes = YES;
        
        bindingInfo = [[NSMutableDictionary alloc] init];
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSColorPboardType, nil]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        if ([decoder allowsKeyedCoding]) {
            colors = [[NSMutableArray alloc] initWithArray:[decoder decodeObjectForKey:SKColorSwatchColorsKey]];
            action = NSSelectorFromString([decoder decodeObjectForKey:SKColorSwatchActionKey]);
            target = [decoder decodeObjectForKey:SKColorSwatchTargetKey];
        } else {
            colors = [[NSMutableArray alloc] initWithArray:[decoder decodeObject]];
            [decoder decodeValueOfObjCType:@encode(SEL) at:&action];
            target = [decoder decodeObject];
        }
        
        highlightedIndex = -1;
        insertionIndex = -1;
        focusedIndex = 0;
        clickedIndex = -1;
        draggedIndex = -1;
        autoResizes = YES;
        
        bindingInfo = [[NSMutableDictionary alloc] init];
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSColorPboardType, nil]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    if ([coder allowsKeyedCoding]) {
        [coder encodeObject:colors forKey:SKColorSwatchColorsKey];
        [coder encodeObject:NSStringFromSelector(action) forKey:SKColorSwatchActionKey];
        [coder encodeConditionalObject:target forKey:SKColorSwatchTargetKey];
    } else {
        [coder encodeObject:colors];
        [coder encodeValueOfObjCType:@encode(SEL) at:action];
        [coder encodeConditionalObject:target];
    }
}

- (void)dealloc {
    [self unbind:SKColorSwatchColorsKey];
    [colors release];
    [bindingInfo release];
    [super dealloc];
}

- (BOOL)isOpaque{  return YES; }

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent { return YES; }

- (BOOL)acceptsFirstResponder { return YES; }

- (void)sizeToFit {
    NSRect frame = [self frame];
    int count = [colors count];
    frame.size.width = count * (NSHeight(frame) - 3.0) + 3.0;
    [self setFrame:frame];
}

- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bounds];
    int count = [colors count];
    
    bounds.size.width = fminf(NSWidth(bounds), count * (NSHeight(bounds) - 3.0) + 3.0);
    
    NSRectEdge sides[4] = {NSMaxYEdge, NSMaxXEdge, NSMinXEdge, NSMinYEdge};
    float grays[4] = {0.5, 0.75, 0.75, 0.75};
    
    rect = NSDrawTiledRects(bounds, rect, sides, grays, 4);
    
    [[NSBezierPath bezierPathWithRect:rect] addClip];
    
    NSRect r = NSMakeRect(1.0, 1.0, NSHeight(rect), NSHeight(rect));
    int i;
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
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    int i = [self colorIndexAtPoint:mouseLoc];
    
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
                    [pboard declareTypes:[NSArray arrayWithObjects:NSColorPboardType, nil] owner:nil];
                    [color writeToPasteboard:pboard];
                    
                    NSRect rect = NSMakeRect(0.0, 0.0, 12.0, 12.0);
                    NSImage *image = [[NSImage alloc] initWithSize:rect.size];
                    [image lockFocus];
                    [[NSColor blackColor] set];
                    [NSBezierPath setDefaultLineWidth:1.0];
                    [NSBezierPath strokeRect:NSInsetRect(rect, 0.5, 0.5)];
                    [color drawSwatchInRect:NSInsetRect(rect, 1.0, 1.0)];
                    [image unlockFocus];
                    
                    mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
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

- (void)performClick:(NSEvent *)theEvent {
    if ([self isEnabled] && focusedIndex != -1) {
        clickedIndex = focusedIndex;
        [self sendAction:[self action] to:[self target]];
        clickedIndex = -1;
        highlightedIndex = focusedIndex;
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
        [self setNeedsDisplay:YES];
        [self performSelector:@selector(unhighlight) withObject:nil afterDelay:0.2];
    }
}

- (void)moveRight:(NSEvent *)theEvent {
    if (++focusedIndex >= (int)[colors count])
        focusedIndex = [colors count] - 1;
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    NSAccessibilityPostNotification(self, NSAccessibilityFocusedUIElementChangedNotification);
}

- (void)moveLeft:(NSEvent *)theEvent {
    if (--focusedIndex < 0)
        focusedIndex = 0;
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    NSAccessibilityPostNotification(self, NSAccessibilityFocusedUIElementChangedNotification);
}

- (int)colorIndexAtPoint:(NSPoint)point {
    NSRect rect = NSInsetRect([self bounds], 2.0, 2.0);
    
    if (NSPointInRect(point, rect)) {
        int i, count = [colors count];
        
        rect.size.width = NSHeight(rect);
        for (i = 0; i < count; i++) {
            if (NSPointInRect(point, rect))
                return i;
            rect.origin.x += NSWidth(rect) + 1.0;
        }
    }
    return -1;
}

- (int)insertionIndexAtPoint:(NSPoint)point {
    NSRect rect = NSInsetRect([self bounds], 2.0, 2.0);
    float w = NSHeight(rect) + 1.0;
    float x = NSMinX(rect) + w / 2.0;
    int i, count = [colors count];
    
    for (i = 0; i < count; i++) {
        if (point.x < x)
            return i;
        x += w;
    }
    return count;
}

#pragma mark Accessors

- (NSArray *)colors {
    return colors;
}

- (void)setColors:(NSArray *)newColors {
    BOOL shouldResize = autoResizes && [newColors count] != [colors count];
    [colors setArray:newColors];
    if (shouldResize)
        [self sizeToFit];
}

- (BOOL)autoResizes {
    return autoResizes;
}

- (void)setAutoResizes:(BOOL)flag {
    autoResizes = flag;
}

- (int)clickedColorIndex {
    return clickedIndex;
}

- (NSColor *)color {
    int i = clickedIndex;
    return i == -1 ? nil : [colors objectAtIndex:i];
}

- (SEL)action {
    return action;
}

- (void)setAction:(SEL)selector {
    if (selector != action) {
        action = selector;
    }
}

- (id)target {
    return target;
}

- (void)setTarget:(id)newTarget {
    if (target != newTarget) {
        target = newTarget;
    }
}

#pragma mark Binding support

- (void)bind:(NSString *)bindingName toObject:(id)observableController withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {	
    if ([bindingName isEqualToString:SKColorSwatchColorsKey]) {
        
        if ([bindingInfo objectForKey:bindingName])
            [self unbind:bindingName];
		
        NSDictionary *bindingsData = [NSDictionary dictionaryWithObjectsAndKeys:observableController, NSObservedObjectKey, [[keyPath copy] autorelease], NSObservedKeyPathKey, [[options copy] autorelease], NSOptionsKey, nil];
		[bindingInfo setObject:bindingsData forKey:bindingName];
        
        [observableController addObserver:self forKeyPath:keyPath options:0 context:SKColorSwatchColorsObservationContext];
        [self observeValueForKeyPath:keyPath ofObject:observableController change:nil context:SKColorSwatchColorsObservationContext];
    } else {
        [super bind:bindingName toObject:observableController withKeyPath:keyPath options:options];
    }
	[self setNeedsDisplay:YES];
}

- (void)unbind:(NSString *)bindingName {
    if ([bindingName isEqualToString:SKColorSwatchColorsKey]) {
        
        NSDictionary *info = [self infoForBinding:bindingName];
        [[info objectForKey:NSObservedObjectKey] removeObserver:self forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
		[bindingInfo removeObjectForKey:bindingName];
    } else {
        [super unbind:bindingName];
    }
    [self setNeedsDisplay:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == SKColorSwatchColorsObservationContext) {
        NSDictionary *info = [self infoForBinding:SKColorSwatchColorsKey];
		id value = [[info objectForKey:NSObservedObjectKey] valueForKeyPath:[info objectForKey:NSObservedKeyPathKey]];
		if (NSIsControllerMarker(value) == NO) {
            NSString *transformerName = [[info objectForKey:NSOptionsKey] objectForKey:NSValueTransformerNameBindingOption];
            if (transformerName) {
                NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:transformerName];
                value = [valueTransformer transformedValue:value]; 
            }
            [self setValue:value forKey:SKColorSwatchColorsKey];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSDictionary *)infoForBinding:(NSString *)bindingName {
	NSDictionary *info = [bindingInfo objectForKey:bindingName];
	if (info == nil)
		info = [super infoForBinding:bindingName];
	return info;
}

#pragma mark NSDraggingSource protocol 

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    return isLocal ? NSDragOperationGeneric : NSDragOperationDelete;
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    if ((operation & NSDragOperationDelete) != 0 && operation != NSDragOperationEvery) {
        if (draggedIndex != -1 && [self isEnabled]) {
            [self willChangeValueForKey:SKColorSwatchColorsKey];
            [colors removeObjectAtIndex:draggedIndex];
            if (autoResizes)
                [self sizeToFit];
            [self didChangeValueForKey:SKColorSwatchColorsKey];
            
            NSDictionary *info = [self infoForBinding:SKColorSwatchColorsKey];
            id observedObject = [info objectForKey:NSObservedObjectKey];
            NSString *observedKeyPath = [info objectForKey:NSObservedKeyPathKey];
            if (observedObject && observedKeyPath) {
                id value = [[colors copy] autorelease];
                NSString *transformerName = [[info objectForKey:NSOptionsKey] objectForKey:NSValueTransformerNameBindingOption];
                if (transformerName) {
                    NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:transformerName];
                    value = [valueTransformer reverseTransformedValue:value]; 
                }
                [observedObject setValue:value forKeyPath:observedKeyPath];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:SKColorSwatchColorsChangedNotification object:self];
            
            [self setNeedsDisplay:YES];
        }
    }
}

#pragma mark NSDraggingDestination protocol 

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    NSPoint mouseLoc = [self convertPoint:[sender draggingLocation] fromView:nil];
    BOOL isCopy = GetCurrentKeyModifiers() == optionKey;
    int i = isCopy ? [self insertionIndexAtPoint:mouseLoc] : [self colorIndexAtPoint:mouseLoc];
    NSDragOperation dragOp = isCopy ? NSDragOperationCopy : NSDragOperationGeneric;
    
    if ([sender draggingSource] == self && draggedIndex == i && isCopy == NO)
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
    int i = isCopy ? insertionIndex : highlightedIndex;
    
    if (i != -1 && color) {
        [self willChangeValueForKey:SKColorSwatchColorsKey];
        if (isCopy) {
            [colors insertObject:color atIndex:i];
            if (autoResizes)
                [self sizeToFit];
        } else {
            [colors replaceObjectAtIndex:i withObject:color];
        }
        [self didChangeValueForKey:SKColorSwatchColorsKey];
        
        NSDictionary *info = [self infoForBinding:SKColorSwatchColorsKey];
        id observedObject = [info objectForKey:NSObservedObjectKey];
        NSString *observedKeyPath = [info objectForKey:NSObservedKeyPathKey];
		if (observedObject && observedKeyPath) {
            id value = [[colors copy] autorelease];
            NSString *transformerName = [[info objectForKey:NSOptionsKey] objectForKey:NSValueTransformerNameBindingOption];
            if (transformerName) {
                NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:transformerName];
                value = [valueTransformer reverseTransformedValue:value]; 
            }
            [observedObject setValue:value forKeyPath:observedKeyPath];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SKColorSwatchColorsChangedNotification object:self];
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
	    NSAccessibilityParentAttribute,
	    NSAccessibilityWindowAttribute,
	    NSAccessibilityTopLevelUIElementAttribute,
	    nil];
    }
    return attributes;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return NSAccessibilityGroupRole;
    } else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
        return NSAccessibilityRoleDescriptionForUIElement(self);
    } else if ([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
        NSMutableArray *children = [NSMutableArray array];
        int i, count = [colors count];
        for (i = 0; i < count; i++)
            [children addObject:[[[SKAccessibilityColorSwatchElement alloc] initWithIndex:i colorSwatch:self] autorelease]];
        return NSAccessibilityUnignoredChildren(children);
    } else if ([attribute isEqualToString:NSAccessibilityParentAttribute]) {
        id parent = [self superview];
        if (parent == nil)
            parent = [self window];
        return NSAccessibilityUnignoredAncestor(parent);
    } else if ([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
        id parent = [self superview];
        if (parent == nil)
            parent = [self window];
        return [NSAccessibilityUnignoredAncestor(parent) accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
        id parent = [self superview];
        if (parent == nil)
            parent = [self window];
        return [NSAccessibilityUnignoredAncestor(parent) accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
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
    int i = [self colorIndexAtPoint:localPoint];
    if (i != -1) {
        SKAccessibilityColorSwatchElement *color = [[[SKAccessibilityColorSwatchElement alloc] initWithIndex:i colorSwatch:self] autorelease];
        return [color accessibilityHitTest:point];
    } else {
        return [super accessibilityHitTest:point];
    }
}

- (id)accessibilityFocusedUIElement {
    if (focusedIndex != -1 && focusedIndex < (int)[colors count])
        return NSAccessibilityUnignoredAncestor([[[SKAccessibilityColorSwatchElement alloc] initWithIndex:focusedIndex colorSwatch:self] autorelease]);
    else
        return NSAccessibilityUnignoredAncestor(self);
}

- (BOOL)isElementFocused:(SKAccessibilityColorSwatchElement *)element {
    return focusedIndex == [element index];
}

- (void)clickElement:(SKAccessibilityColorSwatchElement *)element {
    int i = [element index];
    if ([self isEnabled] && i != -1) {
        clickedIndex = i;
        [self sendAction:[self action] to:[self target]];
        clickedIndex = -1;
        highlightedIndex = focusedIndex;
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
        [self setNeedsDisplay:YES];
        [self performSelector:@selector(unhighlight) withObject:nil afterDelay:0.2];
    }
}

@end

#pragma mark -

@interface NSColor (SKPrivateDeclarations)
- (id)_accessibilityValue;
@end

#pragma mark -

@implementation SKAccessibilityColorSwatchElement

- (id)initWithIndex:(int)anIndex colorSwatch:(SKColorSwatch *)aColorSwatch {
    if (self = [super init]) {
        index = anIndex;
        colorSwatch = aColorSwatch;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[SKAccessibilityColorSwatchElement class]]) {
        SKAccessibilityColorSwatchElement *other = object;
        return index == [other index] && [colorSwatch isEqual:[other colorSwatch]];
    } else {
        return NO;
    }
}

- (unsigned)hash {
    // Equal objects must hash the same.
    return index + [colorSwatch hash];
}

- (int)index {
    return index;
}

- (SKColorSwatch *)colorSwatch {
    return colorSwatch;
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
        return NSAccessibilityButtonRole;
    } else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
        return NSAccessibilityRoleDescriptionForUIElement(self);
    } else if ([attribute isEqualToString:NSAccessibilityValueAttribute]) {
        NSColor *color = [[colorSwatch colors] objectAtIndex:index];
        return [color respondsToSelector:@selector(_accessibilityValue)] ? [color _accessibilityValue] : color;
    } else if ([attribute isEqualToString:NSAccessibilityParentAttribute]) {
        return NSAccessibilityUnignoredAncestor(colorSwatch);
    } else if ([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
        // We're in the same window as our parent.
        return [NSAccessibilityUnignoredAncestor(colorSwatch) accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
        // We're in the same top level element as our parent.
        return [NSAccessibilityUnignoredAncestor(colorSwatch) accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
        return [NSNumber numberWithBool:[colorSwatch isElementFocused:self]];
    } else if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
        NSRect rect = NSInsetRect([colorSwatch bounds], 1.0, 1.0);
        rect.size.width = NSHeight(rect);
        rect.origin.x += index * (NSWidth(rect) - 1.0);
        rect.origin = [colorSwatch convertPoint:rect.origin toView:nil];
        return [NSValue valueWithPoint:rect.origin];
    } else if ([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
        NSRect rect = NSInsetRect([colorSwatch bounds], 1.0, 1.0);
        rect.size.width = NSHeight(rect);
        rect.origin.x += index * (NSWidth(rect) - 1.0);
        rect.size = [colorSwatch convertSize:rect.size toView:nil];
        return [NSValue valueWithSize:rect.size];
    } else {
        return nil;
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
        [colorSwatch clickElement:self];
}

@end
