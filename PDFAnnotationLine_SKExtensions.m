//
//  PDFAnnotationLine_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/1/08.
/*
 This software is Copyright (c) 2008-2020
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
#import "PDFAnnotationCircle_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "NSUserDefaults_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSGraphics_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import "NSResponder_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKRuntime.h"
#import "NSBezierPath_SKExtensions.h"
#import "NSColor_SKExtensions.h"
#import "PDFView_SKExtensions.h"

NSString *SKPDFAnnotationObservedStartPointKey = @"observedStartPoint";
NSString *SKPDFAnnotationObservedEndPointKey = @"observedEndPoint";

NSString *SKPDFAnnotationStartPointAsQDPointKey = @"startPointAsQDPoint";
NSString *SKPDFAnnotationEndPointAsQDPointKey = @"endPointAsQDPoint";
NSString *SKPDFAnnotationScriptingStartLineStyleKey = @"scriptingStartLineStyle";
NSString *SKPDFAnnotationScriptingEndLineStyleKey = @"scriptingEndLineStyle";

#if SDK_BEFORE(10_12)
@interface PDFAnnotation (SKSierraDeclarations)
// before 10.12 this was a private method, called by drawWithBox:
- (void)drawWithBox:(PDFDisplayBox)box inContext:(CGContextRef)context;
@end
#endif

@implementation PDFAnnotationLine (SKExtensions)

static void (*original_drawWithBox_inContext)(id, SEL, PDFDisplayBox, CGContextRef) = NULL;
static void (*original_setBounds)(id, SEL, NSRect) = NULL;

static inline void addLineTipToPath(CGMutablePathRef path, NSPoint point, CGFloat angle, PDFLineStyle lineStyle, CGFloat lineWidth) {
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(point.x, point.y), angle);
    switch (lineStyle) {
        case kPDFLineStyleNone:
            return;
        case kPDFLineStyleSquare:
            CGPathAddRect(path, &transform, CGRectMake(-1.5 * lineWidth, -1.5 * lineWidth, 3.0 * lineWidth, 3.0 * lineWidth));
            break;
        case kPDFLineStyleCircle:
            CGPathAddEllipseInRect(path, &transform, CGRectMake(-1.5 * lineWidth, -1.5 * lineWidth, 3.0 * lineWidth, 3.0 * lineWidth));
            break;
        case kPDFLineStyleDiamond:
            CGPathMoveToPoint(path, &transform, 1.5 * lineWidth, 0.0);
            CGPathAddLineToPoint(path, &transform, 0.0,  1.5 * lineWidth);
            CGPathAddLineToPoint(path, &transform, -1.5 * lineWidth, 0.0);
            CGPathAddLineToPoint(path, &transform, 0.0,  -1.5 * lineWidth);
            CGPathCloseSubpath(path);
            break;
        case kPDFLineStyleOpenArrow:
            CGPathMoveToPoint(path, &transform, -3.0 * lineWidth, 1.5 * lineWidth);
            CGPathAddLineToPoint(path, &transform, 0.0,  0.0);
            CGPathAddLineToPoint(path, &transform, -3.0 * lineWidth, -1.5 * lineWidth);
            break;
        case kPDFLineStyleClosedArrow:
            CGPathMoveToPoint(path, &transform, -3.0 * lineWidth, 1.5 * lineWidth);
            CGPathAddLineToPoint(path, &transform, 0.0,  0.0);
            CGPathAddLineToPoint(path, &transform, -3.0 * lineWidth, -1.5 * lineWidth);
            CGPathCloseSubpath(path);
            break;
    }
}

- (void)replacement_drawWithBox:(PDFDisplayBox)box inContext:(CGContextRef)context {
    if ([self hasAppearanceStream]) {
        original_drawWithBox_inContext(self, _cmd, box, context);
    } else {
        NSPoint origin = [self bounds].origin;
        NSPoint startPoint = SKAddPoints(origin, [self startPoint]);
        NSPoint endPoint = SKAddPoints(origin, [self endPoint]);
        CGFloat angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x);
        CGFloat lineWidth = [self lineWidth];
        CGMutablePathRef path = CGPathCreateMutable();
        CGContextSaveGState(context);
        [[self page] transformContext:context forBox:box];
        CGContextSetStrokeColorWithColor(context, [[self color] CGColor]);
        CGContextSetLineWidth(context, lineWidth);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        if ([self borderStyle] == kPDFBorderStyleDashed) {
            NSArray *dashPattern = [self dashPattern];
            NSInteger i, count = [dashPattern count];
            CGFloat dash[count];
            for (i = 0; i < count; i++)
                dash[i] = [[dashPattern objectAtIndex:i] doubleValue];
            CGContextSetLineDash(context, 0.0, dash, count);
            CGContextSetLineCap(context, kCGLineCapButt);
        } else {
            CGContextSetLineCap(context, kCGLineCapRound);
        }
        CGPathMoveToPoint(path, NULL, startPoint.x, startPoint.y);
        CGPathAddLineToPoint(path, NULL, endPoint.x, endPoint.y);
        if ([self startLineStyle] != kPDFLineStyleNone)
            addLineTipToPath(path, startPoint, angle + M_PI, [self startLineStyle], lineWidth);
        if ([self endLineStyle] != kPDFLineStyleNone)
            addLineTipToPath(path, endPoint, angle, [self endLineStyle], lineWidth);
        CGContextBeginPath(context);
        CGContextAddPath(context, path);
        CGPathRelease(path);
        CGContextStrokePath(context);
        CGContextRestoreGState(context);
    }
}

- (void)replacement_setBounds:(NSRect)newBounds {
    NSPoint startPoint = [self startPoint];
    NSPoint endPoint = [self endPoint];
    original_setBounds(self, _cmd, newBounds);
    [self setStartPoint:startPoint];
    [self setEndPoint:endPoint];
}

+ (void)load {
    if (RUNNING(10_11))
        original_drawWithBox_inContext = (void (*)(id, SEL, PDFDisplayBox, CGContextRef))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(drawWithBox:inContext:), @selector(replacement_drawWithBox:inContext:));
    if (RUNNING(10_13))
        original_setBounds = (void (*)(id, SEL, NSRect))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(setBounds:), @selector(replacement_setBounds:));
}

- (id)initSkimNoteWithBounds:(NSRect)bounds {
    self = [super initSkimNoteWithBounds:bounds];
    if (self) { 	 
        [self setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKLineNoteColorKey]]; 	 
        NSColor *color = [[NSUserDefaults standardUserDefaults] colorForKey:SKLineNoteInteriorColorKey];
        if ([color alphaComponent] > 0.0)
            [self setInteriorColor:color];
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
    CGFloat r, g, b, a = 0.0;
    [[self interiorColor] getRed:&r green:&g blue:&b alpha:&a];
    if (a > 0.0) {
        [fdfString appendFDFName:SKFDFAnnotationInteriorColorKey];
        [fdfString appendFormat:@"[%f %f %f]", r, g, b];
    }
    return fdfString;
}

- (NSPoint)observedStartPoint {
    return [self startPoint];
}

- (void)setObservedStartPoint:(NSPoint)point {
    [self setStartPoint:point];
}

- (NSPoint)observedEndPoint {
    return [self endPoint];
}

- (void)setObservedEndPoint:(NSPoint)point {
    [self setEndPoint:point];
}

- (BOOL)isLine { return YES; }

- (BOOL)isResizable { return [self isSkimNote]; }

- (BOOL)isMovable { return [self isSkimNote]; }

- (BOOL)hasInteriorColor { return [self isSkimNote]; }

- (BOOL)isConvertibleAnnotation { return YES; }

- (BOOL)hitTest:(NSPoint)point {
    CGFloat delta = fmax(4.0, 0.5 * [self lineWidth]);
    return [self shouldDisplay] && SKPointNearLineFromPointToPoint(SKSubstractPoints(point, [self bounds].origin), [self startPoint], [self endPoint], delta);
}

- (CGFloat)boundsOrder {
    CGFloat delta = ceil(fmax(4.0 * [self lineWidth], 4.0));
    NSPoint origin = [self bounds].origin;
    NSRect startBounds = SKRectFromCenterAndSquareSize(SKAddPoints(origin, [self startPoint]), delta);
    NSRect endBounds = SKRectFromCenterAndSquareSize(SKAddPoints(origin, [self endPoint]), delta);
    PDFPage *page = [self page];
    return fmin([page sortOrderForBounds:startBounds], [page sortOrderForBounds:endBounds]);
}

- (NSRect)displayRectForBounds:(NSRect)bounds lineWidth:(CGFloat)lineWidth {
    NSRect rect = [super displayRectForBounds:bounds lineWidth:lineWidth];
    // need a large padding amount for large line width and cap changes
    CGFloat delta = ceil(fmax(3.0 * lineWidth, 2.0));
    rect = NSInsetRect(rect, -delta, -delta);
    if (NSWidth(bounds) < 2.0 * delta)
        rect = NSInsetRect(rect, -delta, 0.0);
    if (NSHeight(bounds) < 2.0 * delta)
        rect = NSInsetRect(rect, 0.0, -delta);
    return rect;
}

- (SKRectEdges)resizeHandleForPoint:(NSPoint)point scaleFactor:(CGFloat)scaleFactor {
    if ([self isResizable] == NO)
        return 0;
    NSSize size = SKMakeSquareSize(8.0 / scaleFactor);
    point = SKSubstractPoints(point, [self bounds].origin);
    if (NSPointInRect(point, SKRectFromCenterAndSize([self endPoint], size)))
        return SKMaxXEdgeMask;
    else if (NSPointInRect(point, SKRectFromCenterAndSize([self startPoint], size)))
        return SKMinXEdgeMask;
    else
        return 0;
}

- (void)drawSelectionHighlightForView:(PDFView *)pdfView inContext:(CGContextRef)context {
    if (NSIsEmptyRect([self bounds]))
        return;
    BOOL active = RUNNING_AFTER(10_12) ? YES : [[pdfView window] isKeyWindow] && [[[pdfView window] firstResponder] isDescendantOf:pdfView];
    NSPoint origin = [self bounds].origin;
    NSPoint point = SKAddPoints(origin, [self startPoint]);
    CGFloat delta = 4.0 * [pdfView unitWidthOnPage:[self page]];
    SKDrawResizeHandle(context, point, delta, active);
    point = SKAddPoints(origin, [self endPoint]);
    SKDrawResizeHandle(context, point, delta, active);
}

- (NSString *)colorDefaultKey { return SKLineNoteColorKey; }

- (NSSet *)keysForValuesToObserveForUndo {
    static NSSet *lineKeys = nil;
    if (lineKeys == nil) {
        NSMutableSet *mutableKeys = [[super keysForValuesToObserveForUndo] mutableCopy];
        [mutableKeys addObject:SKNPDFAnnotationStartLineStyleKey];
        [mutableKeys addObject:SKNPDFAnnotationEndLineStyleKey];
        [mutableKeys addObject:SKPDFAnnotationObservedStartPointKey];
        [mutableKeys addObject:SKPDFAnnotationObservedEndPointKey];
        [mutableKeys addObject:SKNPDFAnnotationInteriorColorKey];
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
        [customKeys addObject:SKPDFAnnotationScriptingInteriorColorKey];
        customLineScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customLineScriptingKeys;
}

- (void)setStartPointAsQDPoint:(NSData *)inQDPointAsData {
    if ([self isEditable] && inQDPointAsData && [inQDPointAsData isEqual:[NSNull null]] == NO) {
        NSPoint startPoint = [inQDPointAsData pointValueAsQDPoint];
        
        NSRect bounds = [self bounds];
        NSPoint endPoint = SKIntegralPoint(SKAddPoints([self endPoint], bounds.origin));
        
        bounds = SKIntegralRectFromPoints(startPoint, endPoint);
        
        if (NSWidth(bounds) < 8.0) {
            bounds.size.width = 8.0;
            bounds.origin.x = floor(0.5 * (startPoint.x + endPoint.x) - 4.0);
        }
        if (NSHeight(bounds) < 8.0) {
            bounds.size.height = 8.0;
            bounds.origin.y = floor(0.5 * (startPoint.y + endPoint.y) - 4.0);
        }
        
        startPoint = SKSubstractPoints(startPoint, bounds.origin);
        endPoint = SKSubstractPoints(endPoint, bounds.origin);
        
        [self setBounds:bounds];
        [self setObservedStartPoint:startPoint];
        [self setObservedEndPoint:endPoint];
    }

}

- (NSData *)startPointAsQDPoint {
    NSRect bounds = [self bounds];
    NSPoint startPoint = SKAddPoints([self startPoint], bounds.origin);
    startPoint.x = floor(startPoint.x);
    startPoint.y = floor(startPoint.y);
    return [NSData dataWithPointAsQDPoint:startPoint];
}

- (void)setEndPointAsQDPoint:(NSData *)inQDPointAsData {
    if ([self isEditable] && inQDPointAsData && [inQDPointAsData isEqual:[NSNull null]] == NO) {
        NSPoint endPoint = [inQDPointAsData pointValueAsQDPoint];
        
        NSRect bounds = [self bounds];
        NSPoint startPoint = SKIntegralPoint(SKAddPoints([self startPoint], bounds.origin));
        
        bounds = SKIntegralRectFromPoints(startPoint, endPoint);
        
        if (NSWidth(bounds) < 8.0) {
            bounds.size.width = 8.0;
            bounds.origin.x = floor(0.5 * (startPoint.x + endPoint.x) - 4.0);
        }
        if (NSHeight(bounds) < 8.0) {
            bounds.size.height = 8.0;
            bounds.origin.y = floor(0.5 * (startPoint.y + endPoint.y) - 4.0);
        }
        
        startPoint = SKSubstractPoints(startPoint, bounds.origin);
        endPoint = SKSubstractPoints(endPoint, bounds.origin);
        
        [self setBounds:bounds];
        [self setObservedStartPoint:startPoint];
        [self setObservedEndPoint:endPoint];
    }

}

- (NSData *)endPointAsQDPoint {
    NSRect bounds = [self bounds];
    NSPoint endPoint = SKAddPoints([self endPoint], bounds.origin);
    endPoint.x = floor(endPoint.x);
    endPoint.y = floor(endPoint.y);
    return [NSData dataWithPointAsQDPoint:endPoint];
}

- (PDFLineStyle)scriptingStartLineStyle {
    return [self startLineStyle];
}

- (PDFLineStyle)scriptingEndLineStyle {
    return [self endLineStyle];
}

- (void)setScriptingStartLineStyle:(PDFLineStyle)style {
    if ([self isEditable]) {
        [self setStartLineStyle:style];
    }
}

- (void)setScriptingEndLineStyle:(PDFLineStyle)style {
    if ([self isEditable]) {
        [self setEndLineStyle:style];
    }
}

- (NSColor *)scriptingInteriorColor {
    return [self interiorColor];
}

- (void)setScriptingInteriorColor:(NSColor *)newColor {
    if ([self isEditable]) {
        [self setInteriorColor:newColor];
    }
}

@end
