//
//  SKLineInspector.m
//  Skim
//
//  Created by Christiaan Hofman on 6/20/07.
/*
 This software is Copyright (c) 2007
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

#import "SKLineInspector.h"

NSString *SKLineInspectorLineWidthDidChangeNotification = @"SKLineInspectorLineWidthDidChangeNotification";
NSString *SKLineInspectorLineStyleDidChangeNotification = @"SKLineInspectorLineStyleDidChangeNotification";
NSString *SKLineInspectorDashPatternDidChangeNotification = @"SKLineInspectorDashPatternDidChangeNotification";
NSString *SKLineInspectorStartLineStyleDidChangeNotification = @"SKLineInspectorStartLineStyleDidChangeNotification";
NSString *SKLineInspectorEndLineStyleDidChangeNotification = @"SKLineInspectorEndLineStyleDidChangeNotification";

@implementation SKLineInspector

static SKLineInspector *sharedLineInspector = nil;

+ (id)sharedLineInspector {
    if (sharedLineInspector == nil)
        [[self alloc] init];
    return sharedLineInspector;
}

+ (id)allocWithZone:(NSZone *)zone {
    if (sharedLineInspector == nil)
        return [super allocWithZone:[self zone]];
    else
        return sharedLineInspector;
}

- (id)init {
    if (sharedLineInspector == nil && (self = [super initWithWindowNibName:@"LineInspector"])) {
        sharedLineInspector = self;
        style = kPDFBorderStyleSolid;
        lineWidth = 1.0;
        dashPattern = nil;
        startLineStyle = kPDFLineStyleNone;
        endLineStyle = kPDFLineStyleNone;
    }
    return sharedLineInspector;
}

- (void)dealloc {
    [dashPattern release];
    [super dealloc];
}

- (id)retain { return self; }

- (id)autorelease { return self; }

- (void)release {}

- (unsigned)retainCount { return UINT_MAX; }

- (void)windowDidLoad {
    [self setWindowFrameAutosaveName:@"SKLineInspector"];
    
    [[styleButton cell] setToolTip:NSLocalizedString(@"Solid line style", @"Tool tip message") forSegment:kPDFBorderStyleSolid];
    [[styleButton cell] setToolTip:NSLocalizedString(@"Dashed line style", @"Tool tip message") forSegment:kPDFBorderStyleDashed];
    [[styleButton cell] setToolTip:NSLocalizedString(@"Beveled line style", @"Tool tip message") forSegment:kPDFBorderStyleBeveled];
    [[styleButton cell] setToolTip:NSLocalizedString(@"Inset line style", @"Tool tip message") forSegment:kPDFBorderStyleInset];
    [[styleButton cell] setToolTip:NSLocalizedString(@"Underline line style", @"Tool tip message") forSegment:kPDFBorderStyleUnderline];
    
    [[startLineStyleButton cell] setToolTip:NSLocalizedString(@"No start line style", @"Tool tip message") forSegment:kPDFLineStyleNone];
    [[startLineStyleButton cell] setToolTip:NSLocalizedString(@"Square start line style", @"Tool tip message") forSegment:kPDFLineStyleSquare];
    [[startLineStyleButton cell] setToolTip:NSLocalizedString(@"Circle start line style", @"Tool tip message") forSegment:kPDFLineStyleCircle];
    [[startLineStyleButton cell] setToolTip:NSLocalizedString(@"Diamond start line style", @"Tool tip message") forSegment:kPDFLineStyleDiamond];
    [[startLineStyleButton cell] setToolTip:NSLocalizedString(@"Open arrow start line style", @"Tool tip message") forSegment:kPDFLineStyleOpenArrow];
    [[startLineStyleButton cell] setToolTip:NSLocalizedString(@"Closed arrow start line style", @"Tool tip message") forSegment:kPDFLineStyleClosedArrow];
    
    [[endLineStyleButton cell] setToolTip:NSLocalizedString(@"No end line style", @"Tool tip message") forSegment:kPDFLineStyleNone];
    [[endLineStyleButton cell] setToolTip:NSLocalizedString(@"Square end line style", @"Tool tip message") forSegment:kPDFLineStyleSquare];
    [[endLineStyleButton cell] setToolTip:NSLocalizedString(@"Circle end line style", @"Tool tip message") forSegment:kPDFLineStyleCircle];
    [[endLineStyleButton cell] setToolTip:NSLocalizedString(@"Diamond end line style", @"Tool tip message") forSegment:kPDFLineStyleDiamond];
    [[endLineStyleButton cell] setToolTip:NSLocalizedString(@"Open arrow end line style", @"Tool tip message") forSegment:kPDFLineStyleOpenArrow];
    [[endLineStyleButton cell] setToolTip:NSLocalizedString(@"Closed arrow end line style", @"Tool tip message") forSegment:kPDFLineStyleClosedArrow];

    NSImage *image = nil;
	NSSize size;
    NSBezierPath *path;
    
    size = NSMakeSize(29.0, 12.0);
    
    image = [[NSImage alloc] initWithSize:size];
	[image lockFocus];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 3.0, 17.0, 6.0)];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
	[image unlockFocus];
    [styleButton setImage:image forSegment:kPDFBorderStyleSolid];
    [image release];
    
    image = [[NSImage alloc] initWithSize:size];
	[image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(6.0, 5.0)];
    [path lineToPoint:NSMakePoint(6.0, 3.0)];
    [path lineToPoint:NSMakePoint(9.0, 3.0)];
    [path moveToPoint:NSMakePoint(12.0, 3.0)];
    [path lineToPoint:NSMakePoint(17.0, 3.0)];
    [path moveToPoint:NSMakePoint(20.0, 3.0)];
    [path lineToPoint:NSMakePoint(23.0, 3.0)];
    [path lineToPoint:NSMakePoint(23.0, 5.0)];
    [path moveToPoint:NSMakePoint(23.0, 7.0)];
    [path lineToPoint:NSMakePoint(23.0, 9.0)];
    [path lineToPoint:NSMakePoint(20.0, 9.0)];
    [path moveToPoint:NSMakePoint(17.0, 9.0)];
    [path lineToPoint:NSMakePoint(12.0, 9.0)];
    [path moveToPoint:NSMakePoint(9.0, 9.0)];
    [path lineToPoint:NSMakePoint(6.0, 9.0)];
    [path lineToPoint:NSMakePoint(6.0, 7.0)];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
	[image unlockFocus];
    [styleButton setImage:image forSegment:kPDFBorderStyleDashed];
    [image release];
    
    image = [[NSImage alloc] initWithSize:size];
	[image lockFocus];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 3.0, 17.0, 6.0)];
    [path setLineWidth:2.0];
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.3] setStroke];
    [path stroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(7.0, 3.0)];
    [path lineToPoint:NSMakePoint(23.0, 3.0)];
    [path lineToPoint:NSMakePoint(23.0, 8.0)];
    [path setLineWidth:2.0];
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.5] set];
    [path stroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(5.0, 2.0)];
    [path lineToPoint:NSMakePoint(7.0, 4.0)];
    [path lineToPoint:NSMakePoint(7.0, 2.0)];
    [path closePath];
    [path moveToPoint:NSMakePoint(24.0, 10.0)];
    [path lineToPoint:NSMakePoint(22.0, 8.0)];
    [path lineToPoint:NSMakePoint(24.0, 8.0)];
    [path closePath];
    [path fill];
	[image unlockFocus];
    [styleButton setImage:image forSegment:kPDFBorderStyleBeveled];
    [image release];
    
    image = [[NSImage alloc] initWithSize:size];
	[image lockFocus];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 3.0, 17.0, 6.0)];
    [path setLineWidth:2.0];
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.3] setStroke];
    [path stroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(6.0, 4.0)];
    [path lineToPoint:NSMakePoint(6.0, 9.0)];
    [path lineToPoint:NSMakePoint(22.0, 9.0)];
    [path setLineWidth:2.0];
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.5] set];
    [path stroke];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(5.0, 2.0)];
    [path lineToPoint:NSMakePoint(7.0, 4.0)];
    [path lineToPoint:NSMakePoint(5.0, 4.0)];
    [path closePath];
    [path moveToPoint:NSMakePoint(24.0, 10.0)];
    [path lineToPoint:NSMakePoint(22.0, 8.0)];
    [path lineToPoint:NSMakePoint(22.0, 10.0)];
    [path closePath];
    [path fill];
	[image unlockFocus];
    [styleButton setImage:image forSegment:kPDFBorderStyleInset];
    [image release];
    
    image = [[NSImage alloc] initWithSize:size];
	[image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(6.0, 3.0)];
    [path lineToPoint:NSMakePoint(23.0, 3.0)];
    [path setLineWidth:2.0];
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.65] setStroke];
    [path stroke];
	[image unlockFocus];
    [styleButton setImage:image forSegment:kPDFBorderStyleUnderline];
    [image release];
	
    size = NSMakeSize(24.0, 12.0);
    
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(20.0, 6.0)];
    [path lineToPoint:NSMakePoint(8.0, 6.0)];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
    [image unlockFocus];
    [startLineStyleButton setImage:image forSegment:kPDFLineStyleNone];
	[image release];
	
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.0, 6.0)];
    [path lineToPoint:NSMakePoint(16.0, 6.0)];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
    [image unlockFocus];
    [endLineStyleButton setImage:image forSegment:kPDFLineStyleNone];
	[image release];
	
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(20.0, 6.0)];
    [path lineToPoint:NSMakePoint(8.0, 6.0)];
    [path appendBezierPathWithRect:NSMakeRect(5.0, 3.0, 6.0, 6.0)];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
    [image unlockFocus];
    [startLineStyleButton setImage:image forSegment:kPDFLineStyleSquare];
	[image release];
    
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.0, 6.0)];
    [path lineToPoint:NSMakePoint(16.0, 6.0)];
    [path appendBezierPathWithRect:NSMakeRect(13.0, 3.0, 6.0, 6.0)];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
    [image unlockFocus];
    [endLineStyleButton setImage:image forSegment:kPDFLineStyleSquare];
	[image release];
	
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(20.0, 6.0)];
    [path lineToPoint:NSMakePoint(8.0, 6.0)];
    [path appendBezierPathWithOvalInRect:NSMakeRect(5.0, 3.0, 6.0, 6.0)];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
    [image unlockFocus];
    [startLineStyleButton setImage:image forSegment:kPDFLineStyleCircle];
	[image release];
	
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.0, 6.0)];
    [path lineToPoint:NSMakePoint(16.0, 6.0)];
    [path appendBezierPathWithOvalInRect:NSMakeRect(13.0, 3.0, 6.0, 6.0)];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
    [image unlockFocus];
    [endLineStyleButton setImage:image forSegment:kPDFLineStyleCircle];
	[image release];
	
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(20.0, 6.0)];
    [path lineToPoint:NSMakePoint(8.0, 6.0)];
    [path moveToPoint:NSMakePoint(12.0, 6.0)];
    [path lineToPoint:NSMakePoint(8.0, 10.0)];
    [path lineToPoint:NSMakePoint(4.0, 6.0)];
    [path lineToPoint:NSMakePoint(8.0, 2.0)];
    [path closePath];
    [path setLineWidth:2.0];
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.65] setStroke];
    [path stroke];
    [image unlockFocus];
    [startLineStyleButton setImage:image forSegment:kPDFLineStyleDiamond];
	[image release];
	
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.0, 6.0)];
    [path lineToPoint:NSMakePoint(16.0, 6.0)];
    [path moveToPoint:NSMakePoint(12.0, 6.0)];
    [path lineToPoint:NSMakePoint(16.0, 10.0)];
    [path lineToPoint:NSMakePoint(20.0, 6.0)];
    [path lineToPoint:NSMakePoint(16.0, 2.0)];
    [path closePath];
    [path setLineWidth:2.0];
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.65] setStroke];
    [path stroke];
    [image unlockFocus];
    [endLineStyleButton setImage:image forSegment:kPDFLineStyleDiamond];
	[image release];
	
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(20.0, 6.0)];
    [path lineToPoint:NSMakePoint(8.0, 6.0)];
    [path moveToPoint:NSMakePoint(14.0, 3.0)];
    [path lineToPoint:NSMakePoint(8.0, 6.0)];
    [path lineToPoint:NSMakePoint(14.0, 9.0)];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
    [image unlockFocus];
    [startLineStyleButton setImage:image forSegment:kPDFLineStyleOpenArrow];
	[image release];
	
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.0, 6.0)];
    [path lineToPoint:NSMakePoint(16.0, 6.0)];
    [path moveToPoint:NSMakePoint(10.0, 3.0)];
    [path lineToPoint:NSMakePoint(16.0, 6.0)];
    [path lineToPoint:NSMakePoint(10.0, 9.0)];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
    [image unlockFocus];
    [endLineStyleButton setImage:image forSegment:kPDFLineStyleOpenArrow];
	[image release];
	
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(20.0, 6.0)];
    [path lineToPoint:NSMakePoint(8.0, 6.0)];
    [path moveToPoint:NSMakePoint(14.0, 3.0)];
    [path lineToPoint:NSMakePoint(8.0, 6.0)];
    [path lineToPoint:NSMakePoint(14.0, 9.0)];
    [path closePath];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
    [image unlockFocus];
    [startLineStyleButton setImage:image forSegment:kPDFLineStyleClosedArrow];
	[image release];
	
    image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(4.0, 6.0)];
    [path lineToPoint:NSMakePoint(16.0, 6.0)];
    [path moveToPoint:NSMakePoint(10.0, 3.0)];
    [path lineToPoint:NSMakePoint(16.0, 6.0)];
    [path lineToPoint:NSMakePoint(10.0, 9.0)];
    [path closePath];
    [path setLineWidth:2.0];
    [[NSColor blackColor] setStroke];
    [path stroke];
    [image unlockFocus];
    [endLineStyleButton setImage:image forSegment:kPDFLineStyleClosedArrow];
    
    SKNumberArrayFormatter *formatter = [[SKNumberArrayFormatter alloc] init];
    [dashPatternField setFormatter:formatter];
    [formatter release];
}

- (void)sendActionToTarget:(SEL)selector {
    NSWindow *mainWindow = [NSApp mainWindow];
    NSResponder *responder = [mainWindow firstResponder];
    
    while (responder && [responder respondsToSelector:selector] == NO)
        responder = [responder nextResponder];
    
    [responder performSelector:selector withObject:self];
}

#pragma mark Accessors

- (float)lineWidth {
    return  lineWidth;
}

- (void)setLineWidth:(float)width {
    lineWidth = width;
    [self sendActionToTarget:@selector(changeLineWidth:)];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKLineInspectorLineWidthDidChangeNotification object:self];
}

- (PDFBorderStyle)style {
    return style;
}

- (void)setStyle:(PDFBorderStyle)newStyle {
    if (newStyle != style) {
        style = newStyle;
        [self sendActionToTarget:@selector(changeLineStyle:)];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKLineInspectorLineStyleDidChangeNotification object:self];
    }
}

- (NSArray *)dashPattern {
    return dashPattern;
}

- (void)setDashPattern:(NSArray *)pattern {
    if (pattern != dashPattern) {
        [dashPattern release];
        dashPattern = [pattern copy];
        [self sendActionToTarget:@selector(changeDashPattern:)];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKLineInspectorDashPatternDidChangeNotification object:self];
    }
}

- (PDFLineStyle)startLineStyle {
    return startLineStyle;
}

- (void)setStartLineStyle:(PDFLineStyle)newStyle {
    if (newStyle != startLineStyle) {
        startLineStyle = newStyle;
        [self sendActionToTarget:@selector(changeStartLineStyle:)];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKLineInspectorStartLineStyleDidChangeNotification object:self];
    }
}

- (PDFLineStyle)endLineStyle {
    return endLineStyle;
}

- (void)setEndLineStyle:(PDFLineStyle)newStyle {
    if (newStyle != endLineStyle) {
        endLineStyle = newStyle;
        [self sendActionToTarget:@selector(changeEndLineStyle:)];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKLineInspectorEndLineStyleDidChangeNotification object:self];
    }
}

- (void)setAnnotationStyle:(PDFAnnotation *)annotation {
    NSString *type = [annotation type];
    if ([type isEqualToString:@"FreeText"] || [type isEqualToString:@"Circle"] || [type isEqualToString:@"Square"] || [type isEqualToString:@"Line"]) {
        [self setLineWidth:[[annotation border] lineWidth]];
        [self setDashPattern:[[annotation border] dashPattern]];
        [self setStyle:[[annotation border] style]];
    }
    if ([type isEqualToString:@"Line"]) {
        [self setStartLineStyle:[(PDFAnnotationLine *)annotation startLineStyle]];
        [self setEndLineStyle:[(PDFAnnotationLine *)annotation endLineStyle]];
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

@end

#pragma mark -

@implementation SKNumberArrayFormatter

- (void)commonInit {
    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setFormat:@"0;0;-0"];
    [numberFormatter setMinimum:[NSNumber numberWithFloat:0.0]];
}

 - (id)init {
    if (self = [super init])
        [self commonInit];
    return self;
 }

 - (id)initWithCoder:(NSCoder *)aCoder {
    if (self = [super initWithCoder:aCoder])
        [self commonInit];
    return self;
}

- (void)dealloc {
    [numberFormatter release];
    [super dealloc];
}
 
- (NSString *)stringForObjectValue:(id)obj {
    if ([obj isKindOfClass:[NSNumber class]])
        obj = [NSArray arrayWithObjects:obj, nil];
    
    NSEnumerator *numberEnum = [obj objectEnumerator];
    NSNumber *number;
    NSMutableString *string = [NSMutableString string];
    
    while (number = [numberEnum nextObject]) {
        NSString *s = [numberFormatter stringForObjectValue:number];
        if ([s length]) {
            if ([string length])
                [string appendString:@" "];
            [string appendString:s];
        }
    }
    return string;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs {
    if ([obj isKindOfClass:[NSNumber class]])
        obj = [NSArray arrayWithObjects:obj, nil];
    
    NSEnumerator *numberEnum = [obj objectEnumerator];
    NSNumber *number;
    NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] init] autorelease];
    
    while (number = [numberEnum nextObject]) {
        NSAttributedString *s = [numberFormatter attributedStringForObjectValue:number withDefaultAttributes:attrs];
        if ([s length]) {
            if ([string length])
                [string appendAttributedString:[[[NSAttributedString alloc] initWithString:@" " attributes:attrs] autorelease]];
            [string appendAttributedString:s];
        }
    }
    return string;
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error {
    NSEnumerator *stringEnum = [[string componentsSeparatedByString:@" "] objectEnumerator];
    NSString *s;
    NSNumber *number;
    NSMutableArray *array = [NSMutableArray array];
    BOOL success = YES;
    
    while (success && (s = [stringEnum nextObject])) {
        if ([s length] && (success = [numberFormatter getObjectValue:&number forString:s errorDescription:error]))
            [array addObject:number];
    }
    if (success)
        *obj = array;
    return success;
}

@end
