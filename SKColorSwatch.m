//
//  SKColorSwatch.m
//  Skim
//
//  Created by Christiaan Hofman on 7/4/07.
/*
 This software is Copyright (c) 2007-2020
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
#import "SKRuntime.h"

NSString *SKColorSwatchColorsChangedNotification = @"SKColorSwatchColorsChangedNotification";
NSString *SKColorSwatchOrWellWillActivateNotification = @"SKColorSwatchOrWellWillActivateNotification";

#define COLORS_KEY      @"colors"

#define TARGET_KEY      @"target"
#define ACTION_KEY      @"action"
#define AUTORESIZES_KEY @"autoResizes"
#define SELECTS_KEY     @"selects"

#define BEZEL_HEIGHT 23.0
#define BEZEL_INSET 1.0
#define COLOR_INSET 2.0
#define COLOR_OFFSET 3.0

@interface SKAccessibilityColorSwatchElement : NSObject {
    SKColorSwatch *parent;
    NSInteger index;
}
+ (id)elementWithIndex:(NSInteger)anIndex parent:(SKColorSwatch *)aParent;
- (id)initWithIndex:(NSInteger)anIndex parent:(SKColorSwatch *)aParent;
@property (nonatomic, readonly) SKColorSwatch *parent;
@property (nonatomic, readonly) NSInteger index;
@end

@interface NSColorWell (SKExtensions)
@end

@interface SKColorSwatch (SKAccessibilityColorSwatchElementParent)
- (NSRect)screenRectForElementAtIndex:(NSInteger)anIndex;
- (BOOL)isElementAtIndexFocused:(NSInteger)anIndex;
- (void)elementAtIndex:(NSInteger)anIndex setFocused:(BOOL)focused;
- (void)pressElementAtIndex:(NSInteger)anIndex;
@end

@interface SKColorSwatch ()
@property (nonatomic) NSInteger selectedColorIndex;
@property (nonatomic) CGFloat modifyOffset;
- (void)setColor:(NSColor *)color atIndex:(NSInteger)i fromPanel:(BOOL)fromPanel;
@end

@implementation SKColorSwatch

@synthesize colors, autoResizes, selects, clickedColorIndex=clickedIndex, selectedColorIndex=selectedIndex, modifyOffset;
@dynamic color;

+ (void)initialize {
    SKINITIALIZE;
    
    [self exposeBinding:COLORS_KEY];
}

+ (id)defaultAnimationForKey:(NSString *)key {
    if ([key isEqualToString:@"modifyOffset"])
        return [CABasicAnimation animation];
    else
        return [super defaultAnimationForKey:key];
}

- (Class)valueClassForBinding:(NSString *)binding {
    if ([binding isEqualToString:COLORS_KEY])
        return [NSArray class];
    else
        return [super valueClassForBinding:binding];
}

- (void)commonInit {
    dropIndex = -1;
    focusedIndex = 0;
    clickedIndex = -1;
    selectedIndex = -1;
    draggedIndex = -1;
    modifiedIndex = -1;
    moveIndex = -1;

    [self registerForDraggedTypes:[NSColor readableTypesForPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]]];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        colors = [[NSMutableArray alloc] initWithObjects:[NSColor whiteColor], nil];
        action = NULL;
        target = nil;
        autoResizes = YES;
        selects = NO;
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
        selects = [decoder decodeBoolForKey:SELECTS_KEY];
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
    [coder encodeBool:selects forKey:SELECTS_KEY];
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

#pragma mark Layout

- (NSSize)contentSizeForNumberOfColors:(NSUInteger)count height:(CGFloat)height {
    return NSMakeSize(count * (height - COLOR_OFFSET) + COLOR_OFFSET, height);
}

- (NSRect)bezelFrame {
    NSEdgeInsets insets = [self alignmentRectInsets];
    NSRect bounds = [self bounds];
    bounds.origin.x += insets.left;
    bounds.origin.y += insets.bottom;
    bounds.size = [self contentSizeForNumberOfColors:[colors count] height:NSHeight(bounds) - insets.bottom - insets.top];
    return bounds;
}

- (CGFloat)distanceBetweenColors {
    NSEdgeInsets insets = [self alignmentRectInsets];
    return NSHeight([self bounds]) - insets.bottom - insets.top - COLOR_OFFSET;
}

- (NSRect)frameForColorAtIndex:(NSInteger)anIndex {
    NSRect rect = NSInsetRect([self bezelFrame], COLOR_INSET, COLOR_INSET);
    rect.size.width = NSHeight(rect);
    if (anIndex > 0)
        rect.origin.x += anIndex * [self distanceBetweenColors];
    return rect;
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

- (NSSize)sizeForNumberOfColors:(NSUInteger)count {
    NSSize size = [self contentSizeForNumberOfColors:count height:BEZEL_HEIGHT];
    NSEdgeInsets insets = [self alignmentRectInsets];
    size.height += insets.bottom + insets.top;
    size.width += insets.left + insets.right;
    return size;
}

- (NSSize)intrinsicContentSize {
    return [self contentSizeForNumberOfColors:[colors count] height:BEZEL_HEIGHT];
}

- (void)sizeToFit {
    [self setFrameSize:[self sizeForNumberOfColors:[colors count]]];
}

- (NSEdgeInsets)alignmentRectInsets {
    return NSEdgeInsetsMake(BEZEL_INSET, BEZEL_INSET, BEZEL_INSET, BEZEL_INSET);
}

#pragma mark Drawing

- (void)drawSwatchAtIndex:(NSInteger)i inRect:(NSRect)rect borderColor:(NSColor *)borderColor radius:(CGFloat)r disabled:(BOOL)disabled {
    if (NSWidth(rect) < 1.0)
        return;
    if (NSWidth(rect) > 2.0) {
        NSColor *color = [[self colors] objectAtIndex:i];
        if (disabled) {
            color = [color colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
            CGContextSetAlpha([[NSGraphicsContext currentContext] graphicsPort], 0.5);
        }
        [color drawSwatchInRect:NSInsetRect(rect, 1.0, 1.0)];
        if (disabled)
            CGContextSetAlpha([[NSGraphicsContext currentContext] graphicsPort], 1.0);
    }
    [borderColor setStroke];
    [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5) xRadius:r yRadius:r] stroke];
}

- (void)drawBezelInRect:(NSRect)rect disabled:(BOOL)disabled {
    static const CGFloat grays[8] = {0.94, 0.98,  0.96, 0.96,  0.34, 0.37,  0.2, 0.2};
    BOOL isDark = SKHasDarkAppearance(self);
    NSUInteger offset = isDark ? 4 : 0;
    if (disabled)
        offset += 2;
    NSColor *startColor = [NSColor colorWithCalibratedWhite:grays[offset] alpha:1.0];
    NSColor *endColor = [NSColor colorWithCalibratedWhite:grays[offset + 1] alpha:1.0];
    NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor] autorelease];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:4.0 yRadius:4.0];
    [NSGraphicsContext saveGraphicsState];
    [startColor setFill];
    [NSShadow setShadowWithWhite:0.0 alpha:disabled ? 1.0 : 0.6 blurRadius:0.5 yOffset:0.0];
    [path fill];
    if (isDark == NO && disabled == NO) {
        [NSShadow setShadowWithWhite:0.0 alpha:0.25 blurRadius:0.75 yOffset:-0.25];
        [path fill];
    }
    [NSGraphicsContext restoreGraphicsState];
    [gradient drawInBezierPath:path angle:90.0];
    if (isDark || disabled) {
        [NSGraphicsContext saveGraphicsState];
        [path addClip];
        path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:4.0 yRadius:3.0];
        [path appendBezierPathWithRect:[self bounds]];
        [path setWindingRule:NSEvenOddWindingRule];
        if (isDark)
            [NSShadow setShadowWithWhite:1.0 alpha:0.2 blurRadius:0.5 yOffset:-0.5];
        else
            [NSShadow setShadowWithWhite:0.0 alpha:0.15 blurRadius:1.0 yOffset:0.0];
        [startColor setFill];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bezelFrame];
    NSInteger count = [colors count];
    CGFloat distance = [self distanceBetweenColors];
    
    if (modifiedIndex != -1 && moveIndex == -1)
        bounds.size.width -= modifyOffset * distance;
    
    [NSBezierPath setDefaultLineWidth:1.0];
    
    [NSGraphicsContext saveGraphicsState];
    
    CGFloat r1 = 0.0, r2 = 0.0, r3 = 0.0;
    NSColor *borderColor = [NSColor controlBackgroundColor];
    NSColor *highlightColor = [NSColor selectedControlColor];
    NSColor *dropColor = nil;
    BOOL disabled = RUNNING_AFTER(10_13) && [[self window] isMainWindow] == NO && [[self window] isKeyWindow] == NO && ([self isDescendantOf:[[self window] contentView]] == NO || [[self window] isKindOfClass:NSClassFromString(@"NSToolbarSnapshotWindow")]);;
    NSRect bgBounds = [self backingAlignedRect:NSInsetRect(bounds, 0.5, 0.5) options:NSAlignAllEdgesOutward];
    r1 = 3.0 + 0.5 * (NSHeight(bounds) - NSHeight(bgBounds));
    r2 = r1 - 1.0;
    r3 = r2 - 0.5;
    if (SKHasDarkAppearance(self)) {
        borderColor = [NSColor colorWithCalibratedWhite:0.3 alpha:1.0];
        highlightColor = [NSColor colorWithCalibratedWhite:0.55 alpha:1.0];
    } else {
        borderColor = [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
        highlightColor = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0];
    }
    if (dropIndex != -1)
        dropColor = disabled ? [NSColor secondarySelectedControlColor] : [NSColor alternateSelectedControlColor];
    
    [self drawBezelInRect:bgBounds disabled:disabled];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 1.0, 1.0) xRadius:r1 yRadius:r1];
    [path addClip];
    
    NSRect rect = [self frameForColorAtIndex:0];
    NSInteger i;
    for (i = 0; i < count; i++) {
        if (moveIndex != -1 && modifiedIndex == i) {
            rect.origin.x += distance * (1.0 - modifyOffset);
        } else {
            if (moveIndex == (moveIndex > modifiedIndex ? i - 1 : i))
                rect.origin.x += distance * modifyOffset;
            if (modifiedIndex == i && moveIndex == -1)
                rect.size.width -= modifyOffset * distance;
            [self drawSwatchAtIndex:i inRect:rect borderColor:(clickedIndex == i ? highlightColor : borderColor) radius:r3 disabled:disabled];
            if (((dropIndex == i && insert == NO) || selectedIndex == i) && NSWidth(rect) > 0.0) {
                path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:r2 yRadius:r2];
                [path setLineWidth:2.0];
                [((dropIndex == i && insert == NO) ? dropColor : highlightColor) setStroke];
                [path stroke];
            }
            rect.origin.x += distance;
            if (modifiedIndex == i && moveIndex == -1) {
                rect.origin.x -= NSHeight(rect) - NSWidth(rect);
                rect.size.width = NSHeight(rect);
            }
        }
    }
    
    if (moveIndex != -1) {
        rect = [self frameForColorAtIndex:modifiedIndex];
        rect.origin.x += distance * modifyOffset * (moveIndex - modifiedIndex);
        [self drawSwatchAtIndex:modifiedIndex inRect:rect borderColor:dropColor radius:r3 disabled:disabled];
    }
    
    if (dropIndex != -1 && insert) {
        [dropColor setFill];
        rect = [self frameForColorAtIndex:dropIndex];
        rect.origin.x -= 1.0;
        rect.size.width = 1.0;
        NSRectFill(NSInsetRect(rect, -1.0, -1.0));
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (NSRect)focusRingMaskBounds {
    if (focusedIndex == -1)
        return NSZeroRect;
    return [self frameForColorAtIndex:focusedIndex];
}

- (void)drawFocusRingMask {
    if (modifiedIndex != -1)
        return;
    NSRect rect = [self focusRingMaskBounds];
    if (NSIsEmptyRect(rect) == NO) {
        CGFloat r = 2.0 + 0.5 * (NSHeight(rect) - NSHeight([self backingAlignedRect:NSInsetRect(rect, 0.5, 0.5) options:NSAlignAllEdgesOutward]));
        [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:r yRadius:r] fill];
    }
}

#pragma mark Notification handling

- (void)deactivate:(NSNotification *)note {
    [self deactivate];
}

- (void)handleColorPanelColorChanged:(NSNotification *)note {
    if (selectedIndex != -1) {
        NSColor *color = [[NSColorPanel sharedColorPanel] color];
        [self setColor:color atIndex:selectedIndex fromPanel:YES];
    }
}

- (void)handleKeyOrMainStateChanged:(NSNotification *)note {
    if ([[note name] isEqualToString:NSWindowDidResignMainNotification])
        [self deactivate];
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
    [self deactivate];
    [super viewWillMoveToWindow:newWindow];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    if ([self window])
        [self handleKeyOrMainStateChanged:nil];
}

#pragma mark Event handling and actions

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint mouseLoc = [theEvent locationInView:self];
    NSInteger i = [self colorIndexAtPoint:mouseLoc];
    
    if ([self isEnabled]) {
        clickedIndex = i;
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
                        clickedIndex = -1;
                        [self setNeedsDisplay:YES];
                    }
                    
                    draggedIndex = i;
                    
                    NSColor *color = [colors objectAtIndex:i];
                    
                    NSImage *image = [NSImage bitmapImageWithSize:NSMakeSize(12.0, 12.0) scale:[self backingScale] drawingHandler:^(NSRect rect){
                        [color drawSwatchInRect:NSInsetRect(rect, 1.0, 1.0)];
                        [[NSColor blackColor] set];
                        [NSBezierPath setDefaultLineWidth:1.0];
                        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5) xRadius:1.5 yRadius:1.5] stroke];
                    }];
                    
                    NSRect rect = SKRectFromCenterAndSquareSize([theEvent locationInView:self], 12.0);
                    
                    NSDraggingItem *dragItem = [[[NSDraggingItem alloc] initWithPasteboardWriter:color] autorelease];
                    [dragItem setDraggingFrame:rect contents:image];
                    [self beginDraggingSessionWithItems:[NSArray arrayWithObjects:dragItem, nil] event:theEvent source:self];
                    
                    keepOn = NO;
                    break;
                }
                case NSLeftMouseUp:
                    if ([self isEnabled]) {
                        if ([self selects]) {
                            if (selectedIndex != -1 && selectedIndex == i)
                                [self deactivate];
                            else
                                [self selectColorAtIndex:i];
                        }
                        [self sendAction:[self action] to:[self target]];
                        clickedIndex = -1;
                        [self setNeedsDisplay:YES];
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
        if ([self selects]) {
            if (selectedIndex != -1 && selectedIndex == i)
                [self deactivate];
            else
                [self selectColorAtIndex:i];
        }
        [self sendAction:[self action] to:[self target]];
        [self setNeedsDisplay:YES];
        DISPATCH_MAIN_AFTER_SEC(0.2, ^{
            clickedIndex = -1;
            [self setNeedsDisplay:YES];
        });
    }
}

- (void)performClick:(id)sender {
    [self performClickAtIndex:focusedIndex];
}

- (void)moveRight:(id)sender {
    if (++focusedIndex >= (NSInteger)[colors count])
        focusedIndex = 0;
    [self noteFocusRingMaskChanged];
    [self setNeedsDisplay:YES];
    NSAccessibilityPostNotification(self, NSAccessibilityFocusedUIElementChangedNotification);
}

- (void)moveLeft:(id)sender {
    if (--focusedIndex < 0)
        focusedIndex = [colors count] - 1;
    [self noteFocusRingMaskChanged];
    [self setNeedsDisplay:YES];
    NSAccessibilityPostNotification(self, NSAccessibilityFocusedUIElementChangedNotification);
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
    [self deactivate];
    [colors setArray:newColors];
    if (autoResizes && [newColors count] != [oldColors count])
        [self sizeToFit];
    if ([self window]) {
        NSUInteger i = [oldColors count], iMax = [newColors count];
        while (i-- > 0)
            NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:i parent:self], NSAccessibilityUIElementDestroyedNotification);
        for (i = 0; i < iMax; i++)
            NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:i parent:self], NSAccessibilityCreatedNotification);
        [self invalidateIntrinsicContentSize];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SKColorSwatchColorsChangedNotification object:self];
}

- (NSColor *)color {
    NSInteger i = clickedIndex;
    return i == -1 ? nil : [colors objectAtIndex:i];
}

- (void)setEnabled:(BOOL)enabled {
    if (enabled == NO)
        [self deactivate];
    [super setEnabled:enabled];
}

- (void)setModifyOffset:(CGFloat)offset {
    modifyOffset = offset;
    [self setNeedsDisplay:YES];
}

#pragma mark Modification

- (void)selectColorAtIndex:(NSInteger)idx {
    if (idx == -1) {
        [self deactivate];
    } else if ([self selects] && idx != selectedIndex && [self isEnabled] && [[self window] isMainWindow]) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
        if (selectedIndex != -1) {
            [nc removeObserver:self name:NSColorPanelColorDidChangeNotification object:colorPanel];
        } else {
            [nc postNotificationName:SKColorSwatchOrWellWillActivateNotification object:self];
            [nc addObserver:self selector:@selector(deactivate:) name:SKColorSwatchOrWellWillActivateNotification object:nil];
            [nc addObserver:self selector:@selector(deactivate:) name:NSWindowWillCloseNotification object:[NSColorPanel sharedColorPanel]];
        }
        [[[NSApp mainWindow] contentView] deactivateColorWellSubcontrols];
        [[[NSApp keyWindow] contentView] deactivateColorWellSubcontrols];
        [self setSelectedColorIndex:idx];
        [colorPanel setColor:[[self colors] objectAtIndex:selectedIndex]];
        [colorPanel orderFront:nil];
        [nc addObserver:self selector:@selector(handleColorPanelColorChanged:) name:NSColorPanelColorDidChangeNotification object:colorPanel];
        [self setNeedsDisplay:YES];
    }
}

- (void)deactivate {
    if (selectedIndex != -1) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:NSColorPanelColorDidChangeNotification object:[NSColorPanel sharedColorPanel]];
        [nc removeObserver:self name:SKColorSwatchOrWellWillActivateNotification object:nil];
        [self setSelectedColorIndex:-1];
        [self setNeedsDisplay:YES];
    }
}

- (void)setSelects:(BOOL)flag {
    if (flag != selects) {
        if (flag == NO)
            [self deactivate];
        selects = flag;
    }
}

- (void)willChangeColors {
    [self willChangeValueForKey:COLORS_KEY];
}

- (void)didChangeColors {
    [self didChangeValueForKey:COLORS_KEY];
    [self setNeedsDisplay:YES];
    
    NSDictionary *info = [self infoForBinding:COLORS_KEY];
    id observedObject = [info objectForKey:NSObservedObjectKey];
    NSString *observedKeyPath = [info objectForKey:NSObservedKeyPathKey];
    if (observedObject && observedKeyPath) {
        id value = [[colors copy] autorelease];
        NSValueTransformer *valueTransformer = [[info objectForKey:NSOptionsKey] objectForKey:NSValueTransformerBindingOption];
        if (valueTransformer == nil || [valueTransformer isEqual:[NSNull null]]) {
            NSString *transformerName = [[info objectForKey:NSOptionsKey] objectForKey:NSValueTransformerNameBindingOption];
            if (transformerName && [transformerName isEqual:[NSNull null]] == NO)
                valueTransformer = [NSValueTransformer valueTransformerForName:transformerName];
        }
        if (valueTransformer && [valueTransformer isEqual:[NSNull null]] == NO &&
            [[valueTransformer class] allowsReverseTransformation])
            value = [valueTransformer reverseTransformedValue:value];
        [observedObject setValue:value forKeyPath:observedKeyPath];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SKColorSwatchColorsChangedNotification object:self];
}

- (void)setColor:(NSColor *)color atIndex:(NSInteger)i fromPanel:(BOOL)fromPanel {
    if (color && i >= 0 && i < (NSInteger)[colors count]) {
        [self willChangeColors];
        [colors replaceObjectAtIndex:i withObject:color];
        NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:i parent:self], NSAccessibilityValueChangedNotification);
        [self didChangeColors];
        if (fromPanel == NO && selectedIndex == i) {
            NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc removeObserver:self name:NSColorPanelColorDidChangeNotification object:colorPanel];
            [colorPanel setColor:color];
            [nc addObserver:self selector:@selector(handleColorPanelColorChanged:) name:NSColorPanelColorDidChangeNotification object:colorPanel];
        }
    }
}

- (void)setColor:(NSColor *)color atIndex:(NSInteger)i {
    [self setColor:color atIndex:i fromPanel:NO];
}

- (void)insertColor:(NSColor *)color atIndex:(NSInteger)i {
    if (color && i >= 0 && i <= (NSInteger)[colors count]) {
        [self deactivate];
        [self willChangeColors];
        [colors insertObject:color atIndex:i];
        NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:i parent:self], NSAccessibilityCreatedNotification);
        [self invalidateIntrinsicContentSize];
        if (autoResizes) {
            modifiedIndex = i;
            modifyOffset = 1.0;
            NSSize size = [self sizeForNumberOfColors:[colors count]];
            [self noteFocusRingMaskChanged];
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                    [[self animator] setModifyOffset:0.0];
                    [[self animator] setFrameSize:size];
                }
                completionHandler:^{
                    modifiedIndex = -1;
                    [self sizeToFit];
                    [self noteFocusRingMaskChanged];
                }];
        }
        [self didChangeColors];
    }
}

- (void)removeColorAtIndex:(NSInteger)i {
    if (i >= 0 && i < (NSInteger)[colors count]) {
        [self deactivate];
        if (autoResizes) {
            modifiedIndex = i;
            modifyOffset = 0.0;
            NSSize size = [self sizeForNumberOfColors:[colors count] - 1];
            [self noteFocusRingMaskChanged];
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                    [[self animator] setModifyOffset:1.0];
                    [[self animator] setFrameSize:size];
                }
                completionHandler:^{
                    modifiedIndex = -1;
                    [self willChangeColors];
                    [colors removeObjectAtIndex:i];
                    [self didChangeColors];
                    [self sizeToFit];
                    [self invalidateIntrinsicContentSize];
                    [self noteFocusRingMaskChanged];
                    NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:i parent:self], NSAccessibilityUIElementDestroyedNotification);
                }];
        } else {
            [self willChangeColors];
            [colors removeObjectAtIndex:i];
            [self didChangeColors];
            [self invalidateIntrinsicContentSize];
            NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:draggedIndex parent:self], NSAccessibilityUIElementDestroyedNotification);
        }
    }
}

- (void)moveColorAtIndex:(NSInteger)from toIndex:(NSInteger)to {
    if (from >= 0 && to >= 0 && from != to) {
        NSColor *color = [[colors objectAtIndex:from] retain];
        [self deactivate];
        [self willChangeColors];
        [colors removeObjectAtIndex:from];
        [colors insertObject:color atIndex:to];
        [color release];
        NSAccessibilityPostNotification([SKAccessibilityColorSwatchElement elementWithIndex:to parent:self], NSAccessibilityMovedNotification);
        modifyOffset = 1.0;
        modifiedIndex = to;
        moveIndex = from;
        [self noteFocusRingMaskChanged];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                [[self animator] setModifyOffset:0.0];
            }
            completionHandler:^{
                modifiedIndex = -1;
                moveIndex = -1;
                [self setNeedsDisplay];
                [self noteFocusRingMaskChanged];
            }];
        [self didChangeColors];
    }
}

#pragma mark NSDraggingSource protocol 

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return context == NSDraggingContextWithinApplication ? NSDragOperationGeneric : NSDragOperationDelete;
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    if ((operation & NSDragOperationDelete) != 0 && operation != NSDragOperationEvery && draggedIndex != -1 && [self isEnabled])
        [self removeColorAtIndex:draggedIndex];
    draggedIndex = -1;
}

#pragma mark NSDraggingDestination protocol 

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    NSPoint mouseLoc = [self convertPoint:[sender draggingLocation] fromView:nil];
    BOOL isCopy = ([NSEvent standardModifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSAlternateKeyMask;
    BOOL isMove = [sender draggingSource] == self && isCopy == NO;
    NSInteger i = isCopy || isMove ? [self insertionIndexAtPoint:mouseLoc] : [self colorIndexAtPoint:mouseLoc];
    NSDragOperation dragOp = isCopy ? NSDragOperationCopy : NSDragOperationGeneric;
    [self setNeedsDisplay:YES];
    if ([self isEnabled] == NO || i == -1 ||
        (isMove && (i == draggedIndex || i == draggedIndex + 1))) {
        dropIndex = -1;
        insert = NO;
        dragOp = NSDragOperationNone;
    } else {
        dropIndex = i;
        insert = isCopy || isMove;
    }
    return dragOp;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    dropIndex = -1;
    insert = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSColor *color = [NSColor colorFromPasteboard:pboard];
    BOOL isMove = [sender draggingSource] == self && ([NSEvent standardModifierFlags] & NSDeviceIndependentModifierFlagsMask) != NSAlternateKeyMask;
    if (dropIndex != -1) {
        if (isMove)
            [self moveColorAtIndex:draggedIndex toIndex:dropIndex > draggedIndex ? dropIndex - 1 : dropIndex];
        else if (insert)
            [self insertColor:color atIndex:dropIndex];
        else
            [self setColor:color atIndex:dropIndex];
    }
    
    dropIndex = -1;
    insert = NO;
    [self setNeedsDisplay:YES];
    
	return YES;
}

#pragma mark Accessibility

- (NSString *)accessibilityRole {
    return NSAccessibilityGroupRole;
}

- (NSString *)accessibilityRoleDescription {
    return NSAccessibilityRoleDescriptionForUIElement(self);
}

- (NSArray *)accessibilityChildren {
    NSMutableArray *children = [NSMutableArray array];
    NSInteger i, count = [colors count];
    for (i = 0; i < count; i++)
        [children addObject:[SKAccessibilityColorSwatchElement elementWithIndex:i parent:self]];
    return NSAccessibilityUnignoredChildren(children);
}

- (NSArray *)accessibilityContents {
    return [self accessibilityChildren];
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
        [self noteFocusRingMaskChanged];
        [self setNeedsDisplay:YES];
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

- (BOOL)accessibilityElement {
    return YES;
}

- (NSString *)accessibilityRole {
    return NSAccessibilityColorWellRole;
}

- (NSString *)accessibilityRoleDescription {
    return NSAccessibilityRoleDescriptionForUIElement(self);
}

- (id)accessibilityValue {
    return [parent valueForElementAtIndex:index];
}

- (BOOL)isAccessibilityFocused {
    return [parent isElementAtIndexFocused:index];
}

- (void)setAccessibilityFocused:(BOOL)flag {
    [parent elementAtIndex:index setFocused:flag];
}

- (NSRect)accessibilityFrame {
    return [parent screenRectForElementAtIndex:index];
}

- (BOOL)accessibilityPerformPress {
    [parent pressElementAtIndex:index];
    return YES;
}

- (BOOL)accessibilityPerformPick {
    [parent pressElementAtIndex:index];
    return YES;
}

- (id)accessibilityHitTest:(NSPoint)point {
    return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement {
    return NSAccessibilityUnignoredAncestor(self);
}

@end

@implementation NSColorWell (SKExtensions)

static void (*original_activate)(id, SEL, BOOL) = NULL;

- (void)replacement_activate:(BOOL)exclusive {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKColorSwatchOrWellWillActivateNotification object:self];
    original_activate(self, _cmd, exclusive);
}

+ (void)load {
    original_activate = (void (*)(id, SEL, BOOL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(activate:), @selector(replacement_activate:));
}

@end
