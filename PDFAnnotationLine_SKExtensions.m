//
//  PDFAnnotationLine_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/1/08.
/*
 This software is Copyright (c) 2008-2009
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

#import "PDFAnnotationLine_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "PDFBorder_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "NSUserDefaults_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSData_SKExtensions.h"


FourCharCode SKScriptingLineStyleFromLineStyle(PDFLineStyle lineStyle) {
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

PDFLineStyle SKLineStyleFromScriptingLineStyle(FourCharCode lineStyle) {
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


NSString *SKPDFAnnotationStartPointAsQDPointKey = @"startPointAsQDPoint";
NSString *SKPDFAnnotationEndPointAsQDPointKey = @"endPointAsQDPoint";
NSString *SKPDFAnnotationScriptingStartLineStyleKey = @"scriptingStartLineStyle";
NSString *SKPDFAnnotationScriptingEndLineStyleKey = @"scriptingEndLineStyle";


@implementation PDFAnnotationLine (SKExtensions)

- (id)initSkimNoteWithBounds:(NSRect)bounds { 	 
    if (self = [super initSkimNoteWithBounds:bounds]) { 	 
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

- (BOOL)isResizable { return [self isSkimNote]; }

- (BOOL)isMovable { return [self isSkimNote]; }

- (BOOL)isConvertibleAnnotation { return YES; }

- (BOOL)hitTest:(NSPoint)point {
    CGFloat delta = SKMax(2.0, 0.5 * [self lineWidth]);
    return SKPointNearLineFromPointToPoint(SKSubstractPoints(point, [self bounds].origin), [self startPoint], [self endPoint], 4.0, delta);
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
        [mutableKeys addObject:SKNPDFAnnotationStartLineStyleKey];
        [mutableKeys addObject:SKNPDFAnnotationEndLineStyleKey];
        [mutableKeys addObject:SKNPDFAnnotationStartPointKey];
        [mutableKeys addObject:SKNPDFAnnotationEndPointKey];
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

- (FourCharCode)scriptingNoteType {
    return SKScriptingLineNote;
}

- (void)setStartPointAsQDPoint:(NSData *)inQDPointAsData {
    if (inQDPointAsData && [inQDPointAsData isEqual:[NSNull null]] == NO) {
        NSPoint startPoint = [inQDPointAsData pointValueAsQDPoint];
        
        NSRect bounds = [self bounds];
        NSPoint endPoint = SKIntegralPoint(SKAddPoints([self endPoint], bounds.origin));
        
        bounds = SKIntegralRectFromPoints(startPoint, endPoint);
        
        if (NSWidth(bounds) < 8.0) {
            bounds.size.width = 8.0;
            bounds.origin.x = SKFloor(0.5 * (startPoint.x + endPoint.x) - 4.0);
        }
        if (NSHeight(bounds) < 8.0) {
            bounds.size.height = 8.0;
            bounds.origin.y = SKFloor(0.5 * (startPoint.y + endPoint.y) - 4.0);
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
    startPoint.x = SKFloor(startPoint.x);
    startPoint.y = SKFloor(startPoint.y);
    return [NSData dataWithPointAsQDPoint:startPoint];
}

- (void)setEndPointAsQDPoint:(NSData *)inQDPointAsData {
    if (inQDPointAsData && [inQDPointAsData isEqual:[NSNull null]] == NO) {
        NSPoint endPoint = [inQDPointAsData pointValueAsQDPoint];
        
        NSRect bounds = [self bounds];
        NSPoint startPoint = SKIntegralPoint(SKAddPoints([self startPoint], bounds.origin));
        
        bounds = SKIntegralRectFromPoints(startPoint, endPoint);
        
        if (NSWidth(bounds) < 8.0) {
            bounds.size.width = 8.0;
            bounds.origin.x = SKFloor(0.5 * (startPoint.x + endPoint.x) - 4.0);
        }
        if (NSHeight(bounds) < 8.0) {
            bounds.size.height = 8.0;
            bounds.origin.y = SKFloor(0.5 * (startPoint.y + endPoint.y) - 4.0);
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
    endPoint.x = SKFloor(endPoint.x);
    endPoint.y = SKFloor(endPoint.y);
    return [NSData dataWithPointAsQDPoint:endPoint];
}

- (FourCharCode)scriptingStartLineStyle {
    return SKScriptingLineStyleFromLineStyle([self startLineStyle]);
}

- (FourCharCode)scriptingEndLineStyle {
    return SKScriptingLineStyleFromLineStyle([self endLineStyle]);
}

- (void)setScriptingStartLineStyle:(FourCharCode)style {
    [self setStartLineStyle:SKLineStyleFromScriptingLineStyle(style)];
}

- (void)setScriptingEndLineStyle:(FourCharCode)style {
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
    return [NSNumber numberWithUnsignedInteger:[[self accessibilityValueAttribute] length]];
}

- (id)accessibilityVisibleCharacterRangeAttribute {
    return [NSValue valueWithRange:NSMakeRange(0, [[self accessibilityValueAttribute] length])];
}

@end
