//
//  SKLineWell.m
//  Skim
//
//  Created by Christiaan Hofman on 6/22/07.
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

#import "SKLineWell.h"
#import "SKLineInspector.h"
#import "OBUtilities.h"

NSString *SKLineStylePboardType = @"SKLineStylePboardType";

NSString *SKLineWellLineWidthKey = @"lineWidth";
NSString *SKLineWellStyleKey = @"style";
NSString *SKLineWellDashPatternKey = @"dashPattern";
NSString *SKLineWellStartLineStyleKey = @"startLineStyle";
NSString *SKLineWellEndLineStyleKey = @"endLineStyle";

static NSString *SKLineWellDisplayStyleKey = @"displayStyle";
static NSString *SKLineWellActiveKey = @"active";
static NSString *SKLineWellActionKey = @"action";
static NSString *SKLineWellTargetKey = @"target";


static NSDictionary *observationContexts = nil;

static NSString *SKLineWellWillBecomeActiveNotification = @"SKLineWellWillBecomeActiveNotification";
static NSString *SKLineWellExclusiveKey = @"exclusive";

@implementation SKLineWell

+ (void)initialize {
    OBINITIALIZE;
    
    id keys[5] = {SKLineWellLineWidthKey, SKLineWellStyleKey, SKLineWellDashPatternKey, SKLineWellStartLineStyleKey, SKLineWellEndLineStyleKey};
    int values[5] = {2091, 2092, 2093, 2094, 2095};
    observationContexts = (NSDictionary *)CFDictionaryCreate(NULL, (const void **)keys, (const void **)values, 5, &kCFCopyStringDictionaryKeyCallBacks, NULL);
    
    [self exposeBinding:SKLineWellLineWidthKey];
    [self exposeBinding:SKLineWellStyleKey];
    [self exposeBinding:SKLineWellDashPatternKey];
    [self exposeBinding:SKLineWellStartLineStyleKey];
    [self exposeBinding:SKLineWellEndLineStyleKey];
}

- (Class)valueClassForBinding:(NSString *)binding {
    if ([binding isEqualToString:SKLineWellDashPatternKey])
        return [NSArray class];
    else
        return [NSNumber class];
}

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        lineWidth = 1.0;
        style = kPDFBorderStyleSolid;
        dashPattern = nil;
        startLineStyle = kPDFLineStyleNone;
        endLineStyle = kPDFLineStyleNone;
        displayStyle = SKLineWellDisplayStyleLine;
        active = NO;
        canActivate = YES;
        
        target = nil;
        action = NULL;
        
        bindingInfo = [[NSMutableDictionary alloc] init];
        
        existsActiveLineWell = NO;
        
        updatingFromLineInspector = NO;
        updatingFromBinding = NO;
        
        [self registerForDraggedTypes:[NSArray arrayWithObjects:SKLineStylePboardType, nil]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        if ([decoder allowsKeyedCoding]) {
            lineWidth = [decoder decodeFloatForKey:SKLineWellLineWidthKey];
            style = [decoder decodeIntForKey:SKLineWellStyleKey];
            dashPattern = [[decoder decodeObjectForKey:SKLineWellDashPatternKey] retain];
            startLineStyle = [decoder decodeIntForKey:SKLineWellStartLineStyleKey];
            endLineStyle = [decoder decodeIntForKey:SKLineWellEndLineStyleKey];
            displayStyle = [decoder decodeIntForKey:SKLineWellDisplayStyleKey];
            active = [decoder decodeBoolForKey:SKLineWellActiveKey];
            action = NSSelectorFromString([decoder decodeObjectForKey:SKLineWellActionKey]);
            target = [decoder decodeObjectForKey:SKLineWellTargetKey];
        } else {
            [decoder decodeValueOfObjCType:@encode(float) at:&lineWidth];
            [decoder decodeValueOfObjCType:@encode(int) at:&style];
            dashPattern = [[decoder decodeObject] retain];
            [decoder decodeValueOfObjCType:@encode(int) at:&startLineStyle];
            [decoder decodeValueOfObjCType:@encode(int) at:&endLineStyle];
            [decoder decodeValueOfObjCType:@encode(int) at:&displayStyle];
            [decoder decodeValueOfObjCType:@encode(BOOL) at:&active];
            [decoder decodeValueOfObjCType:@encode(SEL) at:&action];
            target = [decoder decodeObject];
        }
        
        bindingInfo = [[NSMutableDictionary alloc] init];
        
        existsActiveLineWell = NO;
        
        updatingFromLineInspector = NO;
        updatingFromBinding = NO;
        
        [self registerForDraggedTypes:[NSArray arrayWithObjects:SKLineStylePboardType, nil]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    if ([coder allowsKeyedCoding]) {
        [coder encodeFloat:lineWidth forKey:SKLineWellLineWidthKey];
        [coder encodeInt:style forKey:SKLineWellStyleKey];
        [coder encodeObject:dashPattern forKey:SKLineWellDashPatternKey];
        [coder encodeInt:startLineStyle forKey:SKLineWellStartLineStyleKey];
        [coder encodeInt:endLineStyle forKey:SKLineWellEndLineStyleKey];
        [coder encodeInt:displayStyle forKey:SKLineWellDisplayStyleKey];
        [coder encodeBool:active forKey:SKLineWellActiveKey];
        [coder encodeObject:NSStringFromSelector(action) forKey:SKLineWellActionKey];
        [coder encodeConditionalObject:target forKey:SKLineWellTargetKey];
    } else {
        [coder encodeValueOfObjCType:@encode(float) at:&lineWidth];
        [coder encodeValueOfObjCType:@encode(int) at:&style];
        [coder encodeObject:dashPattern];
        [coder encodeValueOfObjCType:@encode(int) at:&startLineStyle];
        [coder encodeValueOfObjCType:@encode(int) at:&endLineStyle];
        [coder encodeValueOfObjCType:@encode(int) at:&displayStyle];
        [coder encodeValueOfObjCType:@encode(BOOL) at:&active];
        [coder encodeValueOfObjCType:@encode(SEL) at:action];
        [coder encodeConditionalObject:target];
    }
}

- (void)dealloc {
    [self unbind:SKLineWellLineWidthKey];
    [self unbind:SKLineWellStyleKey];
    [self unbind:SKLineWellDashPatternKey];
    [self unbind:SKLineWellStartLineStyleKey];
    [self unbind:SKLineWellEndLineStyleKey];
    [bindingInfo release];
    if (active)
        [self deactivate];
    [dashPattern release];
    [super dealloc];
}

- (BOOL)isOpaque{  return YES; }

- (BOOL)acceptsFirstResponder { return [self canActivate]; }

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent { return [self canActivate]; }

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    [self deactivate];
    [super viewWillMoveToWindow:newWindow];
}

- (NSBezierPath *)path {
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSRect bounds = [self bounds];
    
    if ([self displayStyle] == SKLineWellDisplayStyleLine) {
        float offset = 0.5 * lineWidth - floorf(0.5 * lineWidth);
        NSPoint startPoint = NSMakePoint(NSMinX(bounds) + ceilf(0.5 * NSHeight(bounds)), roundf(NSMidY(bounds)) - offset);
        NSPoint endPoint = NSMakePoint(NSMaxX(bounds) - ceilf(0.5 * NSHeight(bounds)), roundf(NSMidY(bounds)) - offset);
        
        switch (startLineStyle) {
            case kPDFLineStyleNone:
                break;
            case kPDFLineStyleSquare:
                [path appendBezierPathWithRect:NSMakeRect(startPoint.x - 1.5 * lineWidth, startPoint.y - 1.5 * lineWidth, 3 * lineWidth, 3 * lineWidth)];
                break;
            case kPDFLineStyleCircle:
                [path appendBezierPathWithOvalInRect:NSMakeRect(startPoint.x - 1.5 * lineWidth, startPoint.y - 1.5 * lineWidth, 3 * lineWidth, 3 * lineWidth)];
                break;
            case kPDFLineStyleDiamond:
                [path moveToPoint:NSMakePoint(startPoint.x - 2.0 * lineWidth, startPoint.y)];
                [path lineToPoint:NSMakePoint(startPoint.x,  startPoint.y + 2.0 * lineWidth)];
                [path lineToPoint:NSMakePoint(startPoint.x + 2.0 * lineWidth, startPoint.y)];
                [path lineToPoint:NSMakePoint(startPoint.x,  startPoint.y - 2.0 * lineWidth)];
                [path closePath];
                break;
            case kPDFLineStyleOpenArrow:
                [path moveToPoint:NSMakePoint(startPoint.x + 3.0 * lineWidth, startPoint.y - 1.5 * lineWidth)];
                [path lineToPoint:NSMakePoint(startPoint.x,  startPoint.y)];
                [path lineToPoint:NSMakePoint(startPoint.x + 3.0 * lineWidth, startPoint.y + 1.5 * lineWidth)];
                break;
            case kPDFLineStyleClosedArrow:
                [path moveToPoint:NSMakePoint(startPoint.x + 3.0 * lineWidth, startPoint.y - 1.5 * lineWidth)];
                [path lineToPoint:NSMakePoint(startPoint.x,  startPoint.y)];
                [path lineToPoint:NSMakePoint(startPoint.x + 3.0 * lineWidth, startPoint.y + 1.5 * lineWidth)];
                [path closePath];
                break;
        }
        
        [path moveToPoint:startPoint];
        [path lineToPoint:endPoint];
        
        switch (endLineStyle) {
            case kPDFLineStyleNone:
                break;
            case kPDFLineStyleSquare:
                [path appendBezierPathWithRect:NSMakeRect(endPoint.x - 1.5 * lineWidth, endPoint.y - 1.5 * lineWidth, 3 * lineWidth, 3 * lineWidth)];
                break;
            case kPDFLineStyleCircle:
                [path appendBezierPathWithOvalInRect:NSMakeRect(endPoint.x - 1.5 * lineWidth, endPoint.y - 1.5 * lineWidth, 3 * lineWidth, 3 * lineWidth)];
                break;
            case kPDFLineStyleDiamond:
                [path moveToPoint:NSMakePoint(endPoint.x + 2.0 * lineWidth, endPoint.y)];
                [path lineToPoint:NSMakePoint(endPoint.x,  endPoint.y + 2.0 * lineWidth)];
                [path lineToPoint:NSMakePoint(endPoint.x - 2.0 * lineWidth, endPoint.y)];
                [path lineToPoint:NSMakePoint(endPoint.x,  endPoint.y - 2.0 * lineWidth)];
                [path closePath];
                break;
            case kPDFLineStyleOpenArrow:
                [path moveToPoint:NSMakePoint(endPoint.x - 3.0 * lineWidth, endPoint.y - 1.5 * lineWidth)];
                [path lineToPoint:NSMakePoint(endPoint.x,  endPoint.y)];
                [path lineToPoint:NSMakePoint(endPoint.x - 3.0 * lineWidth, endPoint.y + 1.5 * lineWidth)];
                break;
            case kPDFLineStyleClosedArrow:
                [path moveToPoint:NSMakePoint(endPoint.x - 3.0 * lineWidth, endPoint.y - 1.5 * lineWidth)];
                [path lineToPoint:NSMakePoint(endPoint.x,  endPoint.y)];
                [path lineToPoint:NSMakePoint(endPoint.x - 3.0 * lineWidth, endPoint.y + 1.5 * lineWidth)];
                [path closePath];
                break;
        }
    } else if ([self displayStyle] == SKLineWellDisplayStyleRectangle) {
        float inset = 7.0 + 0.5 * lineWidth;
        [path appendBezierPathWithRect:NSInsetRect(bounds, inset, inset)];
    } else {
        float inset = 7.0 + 0.5 * lineWidth;
        [path appendBezierPathWithOvalInRect:NSInsetRect(bounds, inset, inset)];
    }
    
    [path setLineWidth:lineWidth];
    
    if (style == kPDFBorderStyleDashed) {
        int i, count = [dashPattern count];
        if (count) {
            float pattern[count];
            for (i = 0; i < count; i++)
                pattern[i] = [[dashPattern objectAtIndex:i] floatValue];
            [path setLineDash:pattern count:count phase:0.0];
        }
    }
    
    return path;
}

- (void)drawRect:(NSRect)rect {
    [NSGraphicsContext saveGraphicsState];
    
    NSRect bounds = [self bounds];
    NSColor *bgColor = [self isActive] ? [NSColor selectedControlColor] : [NSColor controlBackgroundColor];
    NSColor *edgeColor = [NSColor colorWithCalibratedWhite:0 alpha:[self isHighlighted] ? 0.33 : .11];
    
    [bgColor setFill];
    NSRectFill(bounds);
    
    [edgeColor setStroke];
    [[NSBezierPath bezierPathWithRect:NSInsetRect(bounds, 0.5, 0.5)] stroke];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:bounds];
    [path appendBezierPathWithRect:NSInsetRect(bounds, -2.0, -2.0)];
    [path setWindingRule:NSEvenOddWindingRule];
    NSShadow *shadow1 = [[NSShadow new] autorelease];
    [shadow1 setShadowBlurRadius:2.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.7]];
    [shadow1 set];
    [[NSColor blackColor] setFill];
    [path fill];
    
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    
    [[NSBezierPath bezierPathWithRect:NSInsetRect(bounds, 2.0, 2.0)] addClip];
    
    [[NSColor blackColor] setStroke];
    if (lineWidth > 0.0)
        [[self path] stroke];
    
    [NSGraphicsContext restoreGraphicsState];
    
    if ([self refusesFirstResponder] == NO && [NSApp isActive] && [[self window] isKeyWindow] && [[self window] firstResponder] == self) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRectFill(bounds);
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (NSImage *)dragImage {
    NSRect bounds = [self bounds];
    NSRect sourceRect = NSInsetRect(bounds, 1.0, 1.0);
    NSRect targetRect = {NSZeroPoint, sourceRect.size};
    NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
    
    [image lockFocus];
    [[NSColor darkGrayColor] set];
    NSRectFill(bounds);
    [[NSColor controlBackgroundColor] setFill];
    NSRectFill(NSInsetRect(bounds, 2.0, 2.0));
    if (lineWidth > 0.0)
        [[self path] stroke];
    [image unlockFocus];
    
    NSImage *dragImage = [[[NSImage alloc] initWithSize:targetRect.size] autorelease];
    
    [dragImage lockFocus];
    [image drawInRect:targetRect fromRect:sourceRect operation:NSCompositeCopy fraction:0.7];
    [dragImage unlockFocus];
    [image release];
    
    return dragImage;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if ([self isEnabled]) {
        [self setHighlighted:YES];
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
        [self setNeedsDisplay:YES];
        unsigned int modifiers = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
		BOOL keepOn = YES;
        while (keepOn) {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
			switch ([theEvent type]) {
				case NSLeftMouseDragged:
                {
                    [self setHighlighted:NO];
                    [self setNeedsDisplay:YES];
                    
                    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
                    [pboard declareTypes:[NSArray arrayWithObjects:SKLineStylePboardType, nil] owner:nil];
                    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithFloat:lineWidth], SKLineWellLineWidthKey, [NSNumber numberWithInt:style], SKLineWellStyleKey, dashPattern, SKLineWellDashPatternKey, nil];
                    if ([self displayStyle] == SKLineWellDisplayStyleLine) {
                        [dict setObject:[NSNumber numberWithInt:startLineStyle] forKey:SKLineWellStartLineStyleKey];
                        [dict setObject:[NSNumber numberWithInt:endLineStyle] forKey:SKLineWellEndLineStyleKey];
                    }
                    [pboard setPropertyList:dict forType:SKLineStylePboardType];
                    
                    NSRect bounds = [self bounds];
                    NSPoint imageLoc = NSMakePoint(NSMinX(bounds) + 1.0, NSMinY(bounds) + 1.0);
                    [self dragImage:[self dragImage] at:imageLoc offset:NSZeroSize event:theEvent pasteboard:pboard source:self slideBack:YES];
                    
                    keepOn = NO;
                    break;
				}
                case NSLeftMouseUp:
                    [self setHighlighted:NO];
                    [self setNeedsDisplay:YES];
                    if ([self isActive])
                        [self deactivate];
                    else
                        [self activate:(modifiers & NSShiftKeyMask) == 0];
                    keepOn = NO;
                    break;
				default:
                    break;
            }
        }
    }
}

- (void)performClick:(id)sender {
    if ([self isEnabled]) {
        if ([self isActive])
            [self deactivate];
        else
            [self activate:YES];
    }
}

- (void)existsActiveLineWell {
    existsActiveLineWell = YES;
}

- (void)lineWellWillBecomeActive:(NSNotification *)notification {
    id sender = [notification object];
    if (sender != self && [self isActive]) {
        if ([[[notification userInfo] valueForKey:SKLineWellExclusiveKey] boolValue])
            [self deactivate];
        else
            [sender existsActiveLineWell];
    }
}

- (void)lineInspectorWindowWillClose:(NSNotification *)notification {
    [self deactivate];
}

- (void)activate:(BOOL)exclusive {
    if ([self canActivate]) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        SKLineInspector *inspector = [SKLineInspector sharedLineInspector];
        
        existsActiveLineWell = NO;
        
        [nc postNotificationName:SKLineWellWillBecomeActiveNotification object:self
                        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:exclusive], SKLineWellExclusiveKey, nil]];
        
        if (existsActiveLineWell) {
            updatingFromLineInspector = YES;
            [self setLineWidth:[inspector lineWidth]];
            [self setDashPattern:[inspector dashPattern]];
            [self setStyle:[inspector style]];
            if ([self displayStyle] == SKLineWellDisplayStyleLine) {
                [self setStartLineStyle:[inspector startLineStyle]];
                [self setEndLineStyle:[inspector endLineStyle]];
            }
            updatingFromLineInspector = NO;
        } else {
            [inspector setLineWidth:[self lineWidth]];
            [inspector setDashPattern:[self dashPattern]];
            [inspector setStyle:[self style]];
            if ([self displayStyle] == SKLineWellDisplayStyleLine) {
                [inspector setStartLineStyle:[self startLineStyle]];
                [inspector setEndLineStyle:[self endLineStyle]];
            }
        }
        [[inspector window] orderFront:self];
        
        [nc addObserver:self selector:@selector(lineWellWillBecomeActive:)
                   name:SKLineWellWillBecomeActiveNotification object:nil];
        [nc addObserver:self selector:@selector(lineInspectorWindowWillClose:)
                   name:NSWindowWillCloseNotification object:[inspector window]];
        [nc addObserver:self selector:@selector(lineInspectorLineWidthChanged:)
                   name:SKLineInspectorLineWidthDidChangeNotification object:inspector];
        [nc addObserver:self selector:@selector(lineInspectorLineStyleChanged:)
                   name:SKLineInspectorLineStyleDidChangeNotification object:inspector];
        [nc addObserver:self selector:@selector(lineInspectorDashPatternChanged:)
                   name:SKLineInspectorDashPatternDidChangeNotification object:inspector];
        if ([self displayStyle] == SKLineWellDisplayStyleLine) {
            [nc addObserver:self selector:@selector(lineInspectorStartLineStyleChanged:)
                       name:SKLineInspectorStartLineStyleDidChangeNotification object:inspector];
            [nc addObserver:self selector:@selector(lineInspectorEndLineStyleChanged:)
                       name:SKLineInspectorEndLineStyleDidChangeNotification object:inspector];
        } 
        
        active = YES;
        
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
        [self setNeedsDisplay:YES];
    }
}

- (void)deactivate {
    if ([self isActive]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        active = NO;
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
        [self setNeedsDisplay:YES];
    }
}

- (void)updateValue:(id)value forKey:(NSString *)key {
    if (updatingFromBinding == NO) {
        NSDictionary *info = [self infoForBinding:key];
		[[info objectForKey:NSObservedObjectKey] setValue:value forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
    }
    if ([self isActive] && updatingFromLineInspector == NO)
        [[SKLineInspector sharedLineInspector] setValue:value forKey:key];
    [self setNeedsDisplay:YES];
}

#pragma mark Accessors

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

- (BOOL)isActive {
    return active;
}

- (BOOL)canActivate {
    return canActivate;
}

- (void)setCanActivate:(BOOL)flag {
    if (canActivate != flag) {
        canActivate = flag;
        if ([self isActive] && canActivate == NO)
            [self deactivate];
    }
}

- (BOOL)isHighlighted {
    return isHighlighted;
}

- (void)setHighlighted:(BOOL)flag {
    if (isHighlighted != flag) {
        isHighlighted = flag;
    }
}

- (SKLineWellDisplayStyle)displayStyle {
    return displayStyle;
}

- (void)setDisplayStyle:(SKLineWellDisplayStyle)newStyle {
    if (displayStyle != newStyle) {
        displayStyle = newStyle;
        if ([self isActive]) {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            SKLineInspector *inspector = [SKLineInspector sharedLineInspector];
            if ([self displayStyle] == SKLineWellDisplayStyleLine) {
                [nc addObserver:self selector:@selector(lineInspectorStartLineStyleChanged:)
                          name:SKLineInspectorStartLineStyleDidChangeNotification object:inspector];
                [nc addObserver:self selector:@selector(lineInspectorEndLineStyleChanged:)
                          name:SKLineInspectorEndLineStyleDidChangeNotification object:inspector];
            } else {
                [nc removeObserver:self name:SKLineInspectorStartLineStyleDidChangeNotification object:inspector];
                [nc removeObserver:self name:SKLineInspectorEndLineStyleDidChangeNotification object:inspector];
            }
        }
        [self setNeedsDisplay:YES];
    }
}

- (float)lineWidth {
    return lineWidth;
}

- (void)setLineWidth:(float)width {
    if (fabsf(lineWidth - width) > 0.00001) {
        lineWidth = width;
        [self updateValue:[NSNumber numberWithFloat:lineWidth] forKey:SKLineWellLineWidthKey];
    }
}

- (PDFBorderStyle)style {
    return style;
}

- (void)setStyle:(PDFBorderStyle)newStyle {
    if (newStyle != style) {
        style = newStyle;
        [self updateValue:[NSNumber numberWithInt:newStyle] forKey:SKLineWellStyleKey];
    }
}

- (NSArray *)dashPattern {
    return dashPattern;
}

- (void)setDashPattern:(NSArray *)pattern {
    if ([pattern isEqualToArray:dashPattern] == NO && (pattern || dashPattern)) {
        [dashPattern release];
        dashPattern = [pattern copy];
        [self updateValue:dashPattern forKey:SKLineWellDashPatternKey];
    }
}

- (PDFLineStyle)startLineStyle {
    return startLineStyle;
}

- (void)setStartLineStyle:(PDFLineStyle)newStyle {
    if (newStyle != startLineStyle) {
        startLineStyle = newStyle;
        [self updateValue:[NSNumber numberWithInt:startLineStyle] forKey:SKLineWellStartLineStyleKey];
    }
}

- (PDFLineStyle)endLineStyle {
    return endLineStyle;
}

- (void)setEndLineStyle:(PDFLineStyle)newStyle {
    if (newStyle != endLineStyle) {
        endLineStyle = newStyle;
        [self updateValue:[NSNumber numberWithInt:endLineStyle] forKey:SKLineWellEndLineStyleKey];
    }
}

- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:SKLineWellLineWidthKey] || [key isEqualToString:SKLineWellStyleKey] || 
        [key isEqualToString:SKLineWellStartLineStyleKey] || [key isEqualToString:SKLineWellEndLineStyleKey]) {
        [self setValue:[NSNumber numberWithInt:0] forKey:key];
    } else {
        [super setNilValueForKey:key];
    }
}

#pragma mark Notification handlers

- (void)lineInspectorLineWidthChanged:(NSNotification *)notification {
    BOOL savedUpdatingFromLineInspector = updatingFromLineInspector;
    updatingFromLineInspector = YES;
    [self setLineWidth:[[notification object] lineWidth]];
    [self sendAction:[self action] to:[self target]];
    updatingFromLineInspector = savedUpdatingFromLineInspector;
}

- (void)lineInspectorLineStyleChanged:(NSNotification *)notification {
    BOOL savedUpdatingFromLineInspector = updatingFromLineInspector;
    updatingFromLineInspector = YES;
    [self setStyle:[[notification object] style]];
    [self sendAction:[self action] to:[self target]];
    updatingFromLineInspector = savedUpdatingFromLineInspector;
}

- (void)lineInspectorDashPatternChanged:(NSNotification *)notification {
    BOOL savedUpdatingFromLineInspector = updatingFromLineInspector;
    updatingFromLineInspector = YES;
    [self setDashPattern:[[notification object] dashPattern]];
    [self sendAction:[self action] to:[self target]];
    updatingFromLineInspector = savedUpdatingFromLineInspector;
}

- (void)lineInspectorStartLineStyleChanged:(NSNotification *)notification {
    BOOL savedUpdatingFromLineInspector = updatingFromLineInspector;
    updatingFromLineInspector = YES;
    [self setStartLineStyle:[[notification object] startLineStyle]];
    [self sendAction:[self action] to:[self target]];
    updatingFromLineInspector = savedUpdatingFromLineInspector;
}

- (void)lineInspectorEndLineStyleChanged:(NSNotification *)notification {
    BOOL savedUpdatingFromLineInspector = updatingFromLineInspector;
    updatingFromLineInspector = YES;
    [self setEndLineStyle:[[notification object] endLineStyle]];
    [self sendAction:[self action] to:[self target]];
    updatingFromLineInspector = savedUpdatingFromLineInspector;
}

#pragma mark Binding support

- (void)bind:(NSString *)bindingName toObject:(id)observableController withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {	
    if ([bindingName isEqualToString:SKLineWellLineWidthKey] || [bindingName isEqualToString:SKLineWellStyleKey] || [bindingName isEqualToString:SKLineWellDashPatternKey] || 
        [bindingName isEqualToString:SKLineWellStartLineStyleKey] || [bindingName isEqualToString:SKLineWellEndLineStyleKey]) {
        
        if ([bindingInfo objectForKey:bindingName])
            [self unbind:bindingName];
		
        NSDictionary *bindingsData = [NSDictionary dictionaryWithObjectsAndKeys:observableController, NSObservedObjectKey, [[keyPath copy] autorelease], NSObservedKeyPathKey, [[options copy] autorelease], NSOptionsKey, nil];
		[bindingInfo setObject:bindingsData forKey:bindingName];
        
        void *context = (void *)[observationContexts objectForKey:bindingName];
        [observableController addObserver:self forKeyPath:keyPath options:0 context:context];
        [self observeValueForKeyPath:keyPath ofObject:observableController change:nil context:context];
    } else {
        [super bind:bindingName toObject:observableController withKeyPath:keyPath options:options];
    }
	[self setNeedsDisplay:YES];
}

- (void)unbind:(NSString *)bindingName {
    if ([bindingName isEqualToString:SKLineWellLineWidthKey] || [bindingName isEqualToString:SKLineWellStyleKey] || [bindingName isEqualToString:SKLineWellDashPatternKey] || 
        [bindingName isEqualToString:SKLineWellStartLineStyleKey] || [bindingName isEqualToString:SKLineWellEndLineStyleKey]) {
        
        NSDictionary *info = [self infoForBinding:bindingName];
        [[info objectForKey:NSObservedObjectKey] removeObserver:self forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
		[bindingInfo removeObjectForKey:bindingName];
    } else {
        [super unbind:bindingName];
    }
    [self setNeedsDisplay:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSString *key = nil;
    
    if (context == [observationContexts objectForKey:SKLineWellLineWidthKey])
        key = SKLineWellLineWidthKey;
    else if (context == [observationContexts objectForKey:SKLineWellStyleKey])
        key = SKLineWellStyleKey;
    else if (context == [observationContexts objectForKey:SKLineWellDashPatternKey])
        key = SKLineWellDashPatternKey;
    else if (context == [observationContexts objectForKey:SKLineWellStartLineStyleKey])
        key = SKLineWellStartLineStyleKey;
    else if (context == [observationContexts objectForKey:SKLineWellEndLineStyleKey])
        key = SKLineWellEndLineStyleKey;
    
    if (key) {
        NSDictionary *info = [self infoForBinding:key];
		id value = [[info objectForKey:NSObservedObjectKey] valueForKeyPath:[info objectForKey:NSObservedKeyPathKey]];
		if (NSIsControllerMarker(value) == NO) {
            updatingFromBinding = YES;
            [self setValue:value forKey:key];
            updatingFromBinding = NO;
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
    return NSDragOperationGeneric;
}

#pragma mark NSDraggingDestination protocol 

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    if ([self isEnabled] && [sender draggingSource] != self && [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKLineStylePboardType, nil]]) {
        [self setHighlighted:YES];
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
        [self setNeedsDisplay:YES];
        return NSDragOperationEvery;
    } else
        return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    if ([self isEnabled] && [sender draggingSource] != self && [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKLineStylePboardType, nil]]) {
        [self setHighlighted:NO];
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return [self isEnabled] && [sender draggingSource] != self && [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKLineStylePboardType, nil]];
} 

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDictionary *dict = [pboard propertyListForType:SKLineStylePboardType];
    NSNumber *number;
    
    if (number = [dict objectForKey:SKLineWellLineWidthKey])
        [self setLineWidth:[number floatValue]];
    if (number = [dict objectForKey:SKLineWellStyleKey])
        [self setStyle:[number intValue]];
    [self setDashPattern:[dict objectForKey:SKLineWellDashPatternKey]];
    if ([self displayStyle] == SKLineWellDisplayStyleLine) {
        if (number = [dict objectForKey:SKLineWellStartLineStyleKey])
            [self setStartLineStyle:[number intValue]];
        if (number = [dict objectForKey:SKLineWellEndLineStyleKey])
            [self setEndLineStyle:[number intValue]];
    }
    [self sendAction:[self action] to:[self target]];
    
    [self setHighlighted:NO];
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
    
	return dict != nil;
}

#pragma mark Accessibility

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil) {
	attributes = [[NSArray alloc] initWithObjects:
	    NSAccessibilityRoleAttribute,
	    NSAccessibilityRoleDescriptionAttribute,
        NSAccessibilityValueAttribute,
        NSAccessibilityHelpAttribute,
	    NSAccessibilityFocusedAttribute,
	    NSAccessibilityParentAttribute,
	    NSAccessibilityWindowAttribute,
	    NSAccessibilityTopLevelUIElementAttribute,
        NSAccessibilityTitleUIElementAttribute,
	    NSAccessibilityPositionAttribute,
	    NSAccessibilitySizeAttribute,
	    nil];
    }
    return attributes;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return NSAccessibilityCheckBoxRole;
    } else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
        return NSAccessibilityRoleDescription(NSAccessibilityCheckBoxRole, nil);
    } else if ([attribute isEqualToString:NSAccessibilityValueAttribute]) {
        return [NSNumber numberWithBool:[self isActive]];
    } else if ([attribute isEqualToString:NSAccessibilityHelpAttribute]) {
        return [self toolTip];
    } else if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
        // Just check if the app thinks we're focused.
        id focusedElement = [NSApp accessibilityAttributeValue:NSAccessibilityFocusedUIElementAttribute];
        return [NSNumber numberWithBool:[focusedElement isEqual:self]];
    } else if ([attribute isEqualToString:NSAccessibilityParentAttribute]) {
        return NSAccessibilityUnignoredAncestor([self superview]);
    } else if ([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
        // We're in the same window as our parent.
        return [NSAccessibilityUnignoredAncestor([self superview]) accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
        // We're in the same top level element as our parent.
        return [NSAccessibilityUnignoredAncestor([self superview]) accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else if ([attribute isEqualToString:NSAccessibilityTitleUIElementAttribute]) {
        return titleUIElement;
    } else if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
        return [NSValue valueWithPoint:[[self window] convertBaseToScreen:[self convertPoint:[self bounds].origin toView:nil]]];
    } else if ([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
        return [NSValue valueWithSize:[self convertSize:[self bounds].size toView:nil]];
    } else {
        return nil;
    }
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
        return [self canActivate];
    } else {
        return NO;
    }
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityFocusedAttribute]) {
        [[self window] makeFirstResponder:self];
    }
}


// actions

- (NSArray *)accessibilityActionNames {
    return [NSArray arrayWithObject:NSAccessibilityPressAction];
}

- (NSString *)accessibilityActionDescription:(NSString *)anAction {
    return NSAccessibilityActionDescription(anAction);
}

- (void)accessibilityPerformAction:(NSString *)anAction {
    if ([anAction isEqualToString:NSAccessibilityPressAction])
        [self performClick:self];
}


// misc

- (BOOL)accessibilityIsIgnored {
    return NO;
}

- (id)accessibilityHitTest:(NSPoint)point {
    return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement {
    return NSAccessibilityUnignoredAncestor(self);
}

@end
