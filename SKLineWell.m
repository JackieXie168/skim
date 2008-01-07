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

static NSDictionary *observationContexts = nil;

static NSString *SKLineWellWillBecomeActiveNotification = @"SKLineWellWillBecomeActiveNotification";

@implementation SKLineWell

+ (void)initialize {
    OBINITIALIZE;
    
    id keys[5] = {@"lineWidth", @"style", @"dashPattern", @"startLineStyle", @"endLineStyle"};
    int values[5] = {2091, 2092, 2093, 2094, 2095};
    observationContexts = (NSDictionary *)CFDictionaryCreate(NULL, (const void **)keys, (const void **)values, 5, &kCFCopyStringDictionaryKeyCallBacks, NULL);
    
    [self exposeBinding:@"lineWidth"];
    [self exposeBinding:@"style"];
    [self exposeBinding:@"dashPattern"];
    [self exposeBinding:@"startLineStyle"];
    [self exposeBinding:@"endLineStyle"];
}

- (Class)valueClassForBinding:(NSString *)binding {
    if ([binding isEqualToString:@"dashPattern"])
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
        active = NO;
        canActivate = YES;
        ignoresLineEndings = NO;
        
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
            lineWidth = [decoder decodeFloatForKey:@"lineWidth"];
            style = [decoder decodeIntForKey:@"style"];
            dashPattern = [[decoder decodeObjectForKey:@"dashPattern"] retain];
            startLineStyle = [decoder decodeIntForKey:@"startLineStyle"];
            endLineStyle = [decoder decodeIntForKey:@"endLineStyle"];
            active = [decoder decodeBoolForKey:@"active"];
            ignoresLineEndings = [decoder decodeBoolForKey:@"ignoresLineEndings"];
            action = NSSelectorFromString([decoder decodeObjectForKey:@"action"]);
            target = [decoder decodeObjectForKey:@"target"];
        } else {
            [decoder decodeValueOfObjCType:@encode(float) at:&lineWidth];
            [decoder decodeValueOfObjCType:@encode(int) at:&style];
            dashPattern = [[decoder decodeObject] retain];
            [decoder decodeValueOfObjCType:@encode(int) at:&startLineStyle];
            [decoder decodeValueOfObjCType:@encode(int) at:&endLineStyle];
            [decoder decodeValueOfObjCType:@encode(BOOL) at:&active];
            [decoder decodeValueOfObjCType:@encode(BOOL) at:&ignoresLineEndings];
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
        [coder encodeFloat:lineWidth forKey:@"lineWidth"];
        [coder encodeInt:style forKey:@"style"];
        [coder encodeObject:dashPattern forKey:@"dashPattern"];
        [coder encodeInt:startLineStyle forKey:@"startLineStyle"];
        [coder encodeInt:endLineStyle forKey:@"endLineStyle"];
        [coder encodeBool:active forKey:@"active"];
        [coder encodeBool:ignoresLineEndings forKey:@"ignoresLineEndings"];
        [coder encodeObject:NSStringFromSelector(action) forKey:@"action"];
        [coder encodeConditionalObject:target forKey:@"target"];
    } else {
        [coder encodeValueOfObjCType:@encode(float) at:&lineWidth];
        [coder encodeValueOfObjCType:@encode(int) at:&style];
        [coder encodeObject:dashPattern];
        [coder encodeValueOfObjCType:@encode(int) at:&startLineStyle];
        [coder encodeValueOfObjCType:@encode(int) at:&endLineStyle];
        [coder encodeValueOfObjCType:@encode(BOOL) at:&active];
        [coder encodeValueOfObjCType:@encode(BOOL) at:&ignoresLineEndings];
        [coder encodeValueOfObjCType:@encode(SEL) at:action];
        [coder encodeConditionalObject:target];
    }
}

- (void)dealloc {
    [self unbind:@"lineWidth"];
    [self unbind:@"style"];
    [self unbind:@"dashPattern"];
    [self unbind:@"startLineStyle"];
    [self unbind:@"endLineStyle"];
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
    
    if ([self ignoresLineEndings] == NO) {
        float offset = 0.5 * lineWidth - floorf(0.5 * lineWidth);
        NSPoint startPoint = NSMakePoint(NSMinX(bounds) + ceilf(0.5 * NSHeight(bounds)), roundf(NSMidY(bounds)) - offset);
        NSPoint endPoint = NSMakePoint(NSMaxX(bounds) - ceilf(0.5 * NSHeight(bounds)), roundf(NSMidY(bounds)) - offset);
        
        switch (startLineStyle) {
            case kPDFLineStyleNone:
                break;
            case kPDFLineStyleSquare:
                [path appendBezierPath:[NSBezierPath bezierPathWithRect:NSMakeRect(startPoint.x - 1.5 * lineWidth, startPoint.y - 1.5 * lineWidth, 3 * lineWidth, 3 * lineWidth)]];
                break;
            case kPDFLineStyleCircle:
                [path appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(startPoint.x - 1.5 * lineWidth, startPoint.y - 1.5 * lineWidth, 3 * lineWidth, 3 * lineWidth)]];
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
                [path appendBezierPath:[NSBezierPath bezierPathWithRect:NSMakeRect(endPoint.x - 1.5 * lineWidth, endPoint.y - 1.5 * lineWidth, 3 * lineWidth, 3 * lineWidth)]];
                break;
            case kPDFLineStyleCircle:
                [path appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(endPoint.x - 1.5 * lineWidth, endPoint.y - 1.5 * lineWidth, 3 * lineWidth, 3 * lineWidth)]];
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
    } else {
        float inset = 7.0 + 0.5 * lineWidth;
        [path appendBezierPath:[NSBezierPath bezierPathWithRect:NSInsetRect(bounds, inset, inset)]];
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
    NSRectEdge sides[8] = {NSMaxYEdge, NSMaxXEdge, NSMinXEdge, NSMinYEdge, NSMaxYEdge, NSMaxXEdge, NSMinXEdge, NSMinYEdge};
    float grays[8];
    
    if ([self isHighlighted] || [self isActive]) {
        grays[0] = 0.3;
        grays[1] = grays[2] = grays[3] = 0.4;
        grays[4] = 0.6;
        grays[5] = grays[6] = grays[7] = 0.7;
    } else {
        grays[0] = 0.5;
        grays[1] = grays[2] = grays[3] = 0.6;
        grays[4] = 0.8;
        grays[5] = grays[6] = grays[7] = 0.9;
    }
    
    rect = NSDrawTiledRects(bounds, rect, sides, grays, 8);
    
    if ([self isActive])
        [[NSColor selectedControlColor] setFill];
    else
        [[NSColor controlBackgroundColor] setFill];
    NSRectFill(rect);

    [[NSBezierPath bezierPathWithRect:rect] addClip];
    
    [[NSColor blackColor] setStroke];
    [NSBezierPath setDefaultLineWidth:1.0];
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
    [NSBezierPath setDefaultLineWidth:1.0];
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
                        [NSNumber numberWithFloat:lineWidth], @"lineWidth", [NSNumber numberWithInt:style], @"style", dashPattern, @"dashPattern", nil];
                    if ([self ignoresLineEndings] == NO) {
                        [dict setObject:[NSNumber numberWithInt:startLineStyle] forKey:@"startLineStyle"];
                        [dict setObject:[NSNumber numberWithInt:endLineStyle] forKey:@"endLineStyle"];
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
        if ([[[notification userInfo] valueForKey:@"exclusive"] boolValue])
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
                        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:exclusive], @"exclusive", nil]];
        
        if (existsActiveLineWell) {
            updatingFromLineInspector = YES;
            [self setLineWidth:[inspector lineWidth]];
            [self setDashPattern:[inspector dashPattern]];
            [self setStyle:[inspector style]];
            if ([self ignoresLineEndings] == NO) {
                [self setStartLineStyle:[inspector startLineStyle]];
                [self setEndLineStyle:[inspector endLineStyle]];
            }
            updatingFromLineInspector = NO;
        } else {
            [inspector setLineWidth:[self lineWidth]];
            [inspector setDashPattern:[self dashPattern]];
            [inspector setStyle:[self style]];
            if ([self ignoresLineEndings] == NO) {
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
        if ([self ignoresLineEndings] == NO) {
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

- (BOOL)ignoresLineEndings {
    return ignoresLineEndings;
}

- (void)setIgnoresLineEndings:(BOOL)flag {
    if (ignoresLineEndings != flag) {
        ignoresLineEndings = flag;
        if ([self isActive]) {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            SKLineInspector *inspector = [SKLineInspector sharedLineInspector];
            if ([self ignoresLineEndings]) {
                [nc removeObserver:self name:SKLineInspectorStartLineStyleDidChangeNotification object:inspector];
                [nc removeObserver:self name:SKLineInspectorEndLineStyleDidChangeNotification object:inspector];
            } else {
                [nc addObserver:self selector:@selector(lineInspectorStartLineStyleChanged:)
                          name:SKLineInspectorStartLineStyleDidChangeNotification object:inspector];
                [nc addObserver:self selector:@selector(lineInspectorEndLineStyleChanged:)
                          name:SKLineInspectorEndLineStyleDidChangeNotification object:inspector];
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
        [self updateValue:[NSNumber numberWithFloat:lineWidth] forKey:@"lineWidth"];
    }
}

- (PDFBorderStyle)style {
    return style;
}

- (void)setStyle:(PDFBorderStyle)newStyle {
    if (newStyle != style) {
        style = newStyle;
        [self updateValue:[NSNumber numberWithInt:newStyle] forKey:@"style"];
    }
}

- (NSArray *)dashPattern {
    return dashPattern;
}

- (void)setDashPattern:(NSArray *)pattern {
    if ([pattern isEqualToArray:dashPattern] == NO && (pattern || dashPattern)) {
        [dashPattern release];
        dashPattern = [pattern copy];
        [self updateValue:dashPattern forKey:@"dashPattern"];
    }
}

- (PDFLineStyle)startLineStyle {
    return startLineStyle;
}

- (void)setStartLineStyle:(PDFLineStyle)newStyle {
    if (newStyle != startLineStyle) {
        startLineStyle = newStyle;
        [self updateValue:[NSNumber numberWithInt:startLineStyle] forKey:@"startLineStyle"];
    }
}

- (PDFLineStyle)endLineStyle {
    return endLineStyle;
}

- (void)setEndLineStyle:(PDFLineStyle)newStyle {
    if (newStyle != endLineStyle) {
        endLineStyle = newStyle;
        [self updateValue:[NSNumber numberWithInt:endLineStyle] forKey:@"endLineStyle"];
    }
}

- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"lineWidth"] || [key isEqualToString:@"style"] || 
        [key isEqualToString:@"startLineStyle"] || [key isEqualToString:@"endLineStyle"]) {
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
    if ([bindingName isEqualToString:@"lineWidth"] || [bindingName isEqualToString:@"style"] || [bindingName isEqualToString:@"dashPattern"] || 
        [bindingName isEqualToString:@"startLineStyle"] || [bindingName isEqualToString:@"endLineStyle"]) {
        
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
    if ([bindingName isEqualToString:@"lineWidth"] || [bindingName isEqualToString:@"style"] || [bindingName isEqualToString:@"dashPattern"] || 
        [bindingName isEqualToString:@"startLineStyle"] || [bindingName isEqualToString:@"endLineStyle"]) {
        
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
    
    if (context == [observationContexts objectForKey:@"lineWidth"])
        key = @"lineWidth";
    else if (context == [observationContexts objectForKey:@"style"])
        key = @"style";
    else if (context == [observationContexts objectForKey:@"dashPattern"])
        key = @"dashPattern";
    else if (context == [observationContexts objectForKey:@"startLineStyle"])
        key = @"startLineStyle";
    else if (context == [observationContexts objectForKey:@"endLineStyle"])
        key = @"endLineStyle";
    
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
    
    if (number = [dict objectForKey:@"lineWidth"])
        [self setLineWidth:[number floatValue]];
    if (number = [dict objectForKey:@"style"])
        [self setStyle:[number intValue]];
    [self setDashPattern:[dict objectForKey:@"dashPattern"]];
    if ([self ignoresLineEndings] == NO) {
        if (number = [dict objectForKey:@"startLineStyle"])
            [self setStartLineStyle:[number intValue]];
        if (number = [dict objectForKey:@"endLineStyle"])
            [self setEndLineStyle:[number intValue]];
    }
    [self sendAction:[self action] to:[self target]];
    
    [self setHighlighted:NO];
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
    
	return dict != nil;
}

@end
