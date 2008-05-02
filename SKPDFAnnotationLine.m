//
//  SKPDFAnnotationLine.m
//  Skim
//
//  Created by Christiaan Hofman on 4/1/08.
/*
 This software is Copyright (c) 2008
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

#import "SKPDFAnnotationLine.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFBorder_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"


unsigned long SKScriptingLineStyleFromLineStyle(int lineStyle) {
    switch (lineStyle) {
        case kPDFLineStyleNone: return SKScriptingLineStyleNone;
        case kPDFLineStyleSquare: return SKScriptingLineStyleSquare;
        case kPDFLineStyleCircle: return SKScriptingLineStyleCircle;
        case kPDFLineStyleDiamond: return SKScriptingLineStyleDiamond;
        case kPDFLineStyleOpenArrow: return SKScriptingLineStyleOpenArrow;
        case kPDFLineStyleClosedArrow: return SKScriptingLineStyleClosedArrow;
        default: return SKScriptingLineStyleNone;
    }
}

int SKLineStyleFromScriptingLineStyle(unsigned long lineStyle) {
    switch (lineStyle) {
        case kPDFLineStyleNone: return SKScriptingLineStyleNone;
        case kPDFLineStyleSquare: return SKScriptingLineStyleSquare;
        case kPDFLineStyleCircle: return SKScriptingLineStyleCircle;
        case kPDFLineStyleDiamond: return SKScriptingLineStyleDiamond;
        case kPDFLineStyleOpenArrow: return SKScriptingLineStyleOpenArrow;
        case kPDFLineStyleClosedArrow: return SKScriptingLineStyleClosedArrow;
        default: return SKScriptingLineStyleNone;
    }
}


NSString *SKPDFAnnotationStartLineStyleKey = @"startLineStyle";
NSString *SKPDFAnnotationEndLineStyleKey = @"endLineStyle";
NSString *SKPDFAnnotationStartPointKey = @"startPoint";
NSString *SKPDFAnnotationEndPointKey = @"endPoint";

NSString *SKPDFAnnotationStartPointAsQDPointKey = @"startPointAsQDPoint";
NSString *SKPDFAnnotationEndPointAsQDPointKey = @"endPointAsQDPoint";
NSString *SKPDFAnnotationScriptingStartLineStyleKey = @"scriptingStartLineStyle";
NSString *SKPDFAnnotationScriptingEndLineStyleKey = @"scriptingEndLineStyle";


@implementation SKPDFAnnotationLine

- (id)initNoteWithBounds:(NSRect)bounds {
    if (self = [super initNoteWithBounds:bounds]) {
        [self setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKLineNoteColorKey]];
        [self setStartLineStyle:[[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteStartLineStyleKey]];
        [self setEndLineStyle:[[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteEndLineStyleKey]];
        [self setStartPoint:NSMakePoint(0.0, 0.0)];
        [self setEndPoint:NSMakePoint(NSWidth(bounds), NSHeight(bounds))];
        PDFBorder *border = [[PDFBorder allocWithZone:[self zone]] init];
        [border setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKLineNoteLineWidthKey]];
        [border setDashPattern:[[NSUserDefaults standardUserDefaults] arrayForKey:SKLineNoteDashPatternKey]];
        [border setStyle:[[NSUserDefaults standardUserDefaults] floatForKey:SKLineNoteLineStyleKey]];
        [self setBorder:[border lineWidth] > 0.0 ? border : nil];
        [border release];
    }
    return self;
}

- (id)initWithProperties:(NSDictionary *)dict{
    if (self = [super initWithProperties:dict]) {
        Class stringClass = [NSString class];
        NSString *startPoint = [dict objectForKey:SKPDFAnnotationStartPointKey];
        NSString *endPoint = [dict objectForKey:SKPDFAnnotationEndPointKey];
        NSNumber *startLineStyle = [dict objectForKey:SKPDFAnnotationStartLineStyleKey];
        NSNumber *endLineStyle = [dict objectForKey:SKPDFAnnotationEndLineStyleKey];
        if ([startPoint isKindOfClass:stringClass])
            [self setStartPoint:NSPointFromString(startPoint)];
        if ([endPoint isKindOfClass:stringClass])
            [self setEndPoint:NSPointFromString(endPoint)];
        if ([startLineStyle respondsToSelector:@selector(intValue)])
            [self setStartLineStyle:[startLineStyle intValue]];
        if ([endLineStyle respondsToSelector:@selector(intValue)])
            [self setEndLineStyle:[endLineStyle intValue]];
    }
    return self;
}

- (NSDictionary *)properties {
    NSMutableDictionary *dict = [[[super properties] mutableCopy] autorelease];
    [dict setValue:[NSNumber numberWithInt:[self startLineStyle]] forKey:SKPDFAnnotationStartLineStyleKey];
    [dict setValue:[NSNumber numberWithInt:[self endLineStyle]] forKey:SKPDFAnnotationEndLineStyleKey];
    [dict setValue:NSStringFromPoint([self startPoint]) forKey:SKPDFAnnotationStartPointKey];
    [dict setValue:NSStringFromPoint([self endPoint]) forKey:SKPDFAnnotationEndPointKey];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    [fdfString appendFDFName:SKFDFAnnotationLineStylesKey];
    [fdfString appendString:@"["];
    [fdfString appendFDFName:SKFDFLineStyleFromPDFLineStyle([self startLineStyle])];
    [fdfString appendFDFName:SKFDFLineStyleFromPDFLineStyle([self endLineStyle])];
    [fdfString appendString:@"]"];
    NSPoint startPoint = SKAddPoints([self startPoint], [self bounds].origin);
    NSPoint endPoint = SKAddPoints([self endPoint], [self bounds].origin);
    [fdfString appendFDFName:SKFDFAnnotationLinePointsKey];
    [fdfString appendFormat:@"[%f %f %f %f]", startPoint.x, startPoint.y, endPoint.x, endPoint.y];
    return fdfString;
}

- (BOOL)isNote { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)hitTest:(NSPoint)point {
    NSRect bounds = [self bounds];
    NSPoint startPoint = [self startPoint];
    NSPoint endPoint = [self endPoint];
    
    if ([super hitTest:point]) {
        NSPoint relPoint = SKSubstractPoints(endPoint, startPoint);
        float lengthSquared = relPoint.x * relPoint.x + relPoint.y * relPoint.y;
        float extProduct;
        
        if (lengthSquared < 16.0)
            return YES;
        
        point = SKSubstractPoints(SKSubstractPoints(point, bounds.origin), startPoint);
        extProduct = point.x * relPoint.y - point.y * relPoint.x;
        
        return extProduct * extProduct < 16.0 * lengthSquared;
    } else {
        
        point = SKSubstractPoints(point, bounds.origin);
        return (fabsf(point.x - startPoint.x) < 3.5 && fabsf(point.y - startPoint.y) < 3.5) ||
               (fabsf(point.x - endPoint.x) < 3.5 && fabsf(point.y - endPoint.y) < 3.5);
    }
}

- (NSRect)displayRectForBounds:(NSRect)bounds {
    bounds = [super displayRectForBounds:bounds];
    // need a large padding amount for large line width and cap changes, we may have this depend on the line width
    return NSInsetRect(bounds, -16.0, -16.0);
}

- (NSSet *)keysForValuesToObserveForUndo {
    static NSSet *lineKeys = nil;
    if (lineKeys == nil) {
        NSMutableSet *mutableKeys = [[super keysForValuesToObserveForUndo] mutableCopy];
        [mutableKeys addObject:SKPDFAnnotationStartLineStyleKey];
        [mutableKeys addObject:SKPDFAnnotationEndLineStyleKey];
        [mutableKeys addObject:SKPDFAnnotationStartPointKey];
        [mutableKeys addObject:SKPDFAnnotationEndPointKey];
        lineKeys = [mutableKeys copy];
        [mutableKeys release];
    }
    return lineKeys;
}

#pragma mark Scripting support

+ (NSSet *)customScriptingKeys {
    static NSSet *customLineScriptingKeys = nil;
    if (customLineScriptingKeys == nil) {
        NSMutableSet *customKeys = [[super customScriptingKeys] mutableCopy];
        [customKeys addObject:SKPDFAnnotationStartPointAsQDPointKey];
        [customKeys addObject:SKPDFAnnotationEndPointAsQDPointKey];
        [customKeys addObject:SKPDFAnnotationScriptingStartLineStyleKey];
        [customKeys addObject:SKPDFAnnotationScriptingEndLineStyleKey];
        customLineScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customLineScriptingKeys;
}

- (void)setStartPointAsQDPoint:(NSData *)inQDPointAsData {
    if ([inQDPointAsData length] == sizeof(Point)) {
        const Point *qdPoint = (const Point *)[inQDPointAsData bytes];
        NSPoint startPoint = NSPointFromPoint(*qdPoint);
        
        NSRect bounds = [self bounds];
        NSPoint endPoint = SKIntegralPoint(SKAddPoints([self endPoint], bounds.origin));
        
        bounds = SKIntegralRectFromPoints(startPoint, endPoint);
        
        if (NSWidth(bounds) < 8.0) {
            bounds.size.width = 8.0;
            bounds.origin.x = floorf(0.5 * (startPoint.x + endPoint.x) - 4.0);
        }
        if (NSHeight(bounds) < 8.0) {
            bounds.size.height = 8.0;
            bounds.origin.y = floorf(0.5 * (startPoint.y + endPoint.y) - 4.0);
        }
        
        startPoint = SKSubstractPoints(startPoint, bounds.origin);
        endPoint = SKSubstractPoints(endPoint, bounds.origin);
        
        [self setBounds:bounds];
        [self setStartPoint:startPoint];
        [self setEndPoint:endPoint];
    }

}

- (NSData *)startPointAsQDPoint {
    NSRect bounds = [self bounds];
    NSPoint startPoint = SKAddPoints([self startPoint], bounds.origin);
    startPoint.x = floorf(startPoint.x);
    startPoint.y = floorf(startPoint.y);
    Point qdPoint = PointFromNSPoint(startPoint);
    return [NSData dataWithBytes:&qdPoint length:sizeof(Point)];
}

- (void)setEndPointAsQDPoint:(NSData *)inQDPointAsData {
    if ([inQDPointAsData length] == sizeof(Point)) {
        const Point *qdPoint = (const Point *)[inQDPointAsData bytes];
        NSPoint endPoint = NSPointFromPoint(*qdPoint);
        
        NSRect bounds = [self bounds];
        NSPoint startPoint = SKIntegralPoint(SKAddPoints([self startPoint], bounds.origin));
        
        bounds = SKIntegralRectFromPoints(startPoint, endPoint);
        
        if (NSWidth(bounds) < 8.0) {
            bounds.size.width = 8.0;
            bounds.origin.x = floorf(0.5 * (startPoint.x + endPoint.x) - 4.0);
        }
        if (NSHeight(bounds) < 8.0) {
            bounds.size.height = 8.0;
            bounds.origin.y = floorf(0.5 * (startPoint.y + endPoint.y) - 4.0);
        }
        
        startPoint = SKSubstractPoints(startPoint, bounds.origin);
        endPoint = SKSubstractPoints(endPoint, bounds.origin);
        
        [self setBounds:bounds];
        [self setStartPoint:startPoint];
        [self setEndPoint:endPoint];
    }

}

- (NSData *)endPointAsQDPoint {
    NSRect bounds = [self bounds];
    NSPoint endPoint = SKAddPoints([self endPoint], bounds.origin);
    endPoint.x = floorf(endPoint.x);
    endPoint.y = floorf(endPoint.y);
    Point qdPoint = PointFromNSPoint(endPoint);
    return [NSData dataWithBytes:&qdPoint length:sizeof(Point)];
}

- (unsigned long)scriptingStartLineStyle {
    return SKScriptingLineStyleFromLineStyle([self startLineStyle]);
}

- (unsigned long)scriptingEndLineStyle {
    return SKScriptingLineStyleFromLineStyle([self endLineStyle]);
}

- (void)setScriptingStartLineStyle:(unsigned long)style {
    [self setStartLineStyle:SKLineStyleFromScriptingLineStyle(style)];
}

- (void)setScriptingEndLineStyle:(unsigned long)style {
    [self setEndLineStyle:SKLineStyleFromScriptingLineStyle(style)];
}

#pragma mark Accessibility

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil) {
        attributes = [[[super accessibilityAttributeNames] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:
            NSAccessibilitySelectedTextAttribute,
            NSAccessibilitySelectedTextRangeAttribute,
            NSAccessibilityNumberOfCharactersAttribute,
            NSAccessibilityVisibleCharacterRangeAttribute,
            nil]] retain];
    }
    return attributes;
}

- (id)accessibilityRoleAttribute {
    return NSAccessibilityStaticTextRole;
}

- (id)accessibilitySelectedTextAttribute {
    return @"";
}

- (id)accessibilitySelectedTextRangeAttribute {
    return [NSValue valueWithRange:NSMakeRange(0, 0)];
}

- (id)accessibilityNumberOfCharactersAttribute {
    return [NSNumber numberWithUnsignedInt:[[self accessibilityValueAttribute] length]];
}

- (id)accessibilityVisibleCharacterRangeAttribute {
    return [NSValue valueWithRange:NSMakeRange(0, [[self accessibilityValueAttribute] length])];
}

@end

#pragma mark -

@interface PDFAnnotationLine (SKExtensions)
@end

@implementation PDFAnnotationLine (SKExtensions)

- (BOOL)isConvertibleAnnotation { return YES; }

- (id)copyNoteAnnotation {
    SKPDFAnnotationLine *annotation = [[SKPDFAnnotationLine alloc] initNoteWithBounds:[self bounds]];
    [annotation setString:[self string]];
    [annotation setColor:[self color]];
    [annotation setBorder:[[[self border] copy] autorelease]];
    [annotation setStartPoint:[self startPoint]];
    [annotation setEndPoint:[self endPoint]];
    [annotation setStartLineStyle:[self startLineStyle]];
    [annotation setEndLineStyle:[self endLineStyle]];
    return annotation;
}

@end
