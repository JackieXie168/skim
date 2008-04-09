//
//  SKPDFAnnotationMarkup.m
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

#import "SKPDFAnnotationMarkup.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFBorder_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "PDFSelection_SKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "SKCFCallbacks.h"


NSString *SKPDFAnnotationQuadrilateralPointsKey = @"quadrilateralPoints";

NSString *SKPDFAnnotationSelectionSpecifierKey = @"selectionSpecifier";


void SKCGContextSetDefaultRGBColorSpace(CGContextRef context) {
    CMProfileRef profile;
    CMGetDefaultProfileBySpace(cmRGBData, &profile);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithPlatformColorSpace(profile);
    
    CMCloseProfile(profile);
    CGContextSetStrokeColorSpace(context, colorSpace);
    CGContextSetFillColorSpace(context, colorSpace);
    CGColorSpaceRelease(colorSpace);
}


@interface PDFAnnotation (PDFAnnotationPrivateDeclarations)
- (void)drawWithBox:(CGPDFBox)box inContext:(CGContextRef)context;
@end


@implementation SKPDFAnnotationMarkup

static NSArray *createStringsFromPoints(NSArray *points)
{
    if (points == nil)
        return nil;
    int i, iMax = [points count];
    NSMutableArray *strings = [[NSMutableArray alloc] initWithCapacity:iMax];
    for (i = 0; i < iMax; i++)
        [strings addObject:NSStringFromPoint([[points objectAtIndex:i] pointValue])];
    return strings;
}

static NSArray *createPointsFromStrings(NSArray *strings)
{
    if (strings == nil)
        return nil;
    int i, iMax = [strings count];
    NSMutableArray *points = [[NSMutableArray alloc] initWithCapacity:iMax];
    for (i = 0; i < iMax; i++) {
        NSPoint p = NSPointFromString([strings objectAtIndex:i]);
        NSValue *value = [[NSValue alloc] initWithBytes:&p objCType:@encode(NSPoint)];
        [points addObject:value];
        [value release];
    }
    return points;
}

/*
 http://www.cocoabuilder.com/archive/message/cocoa/2007/2/16/178891
  The docs are wrong (as is Adobe's spec).  The ordering is:
  --------
  | 0  1 |
  | 2  3 |
  --------
 */        
static NSArray *createQuadPointsWithBounds(const NSRect bounds, const NSPoint origin)
{
    NSRect r = NSOffsetRect(bounds, -origin.x, -origin.y);
    NSPoint p0 = SKTopLeftPoint(r);
    NSPoint p1 = SKTopRightPoint(r);
    NSPoint p2 = SKBottomLeftPoint(r);
    NSPoint p3 = SKBottomRightPoint(r);
    return [[NSArray alloc] initWithObjects:[NSValue valueWithPoint:p0], [NSValue valueWithPoint:p1], [NSValue valueWithPoint:p2], [NSValue valueWithPoint:p3], nil];
}

static NSColor *defaultColorForMarkupType(int markupType)
{
    switch (markupType) {
        case kPDFMarkupTypeUnderline:
            return [[NSUserDefaults standardUserDefaults] colorForKey:SKUnderlineNoteColorKey];
        case kPDFMarkupTypeStrikeOut:
            return [[NSUserDefaults standardUserDefaults] colorForKey:SKStrikeOutNoteColorKey];
        case kPDFMarkupTypeHighlight:
            return [[NSUserDefaults standardUserDefaults] colorForKey:SKHighlightNoteColorKey];
    }
    return nil;
}

- (id)initWithBounds:(NSRect)bounds markupType:(int)type quadrilateralPointsAsStrings:(NSArray *)pointStrings {
    if (self = [super initWithBounds:bounds]) {
        [self setShouldPrint:YES];
        [self setMarkupType:type];
        
        NSColor *color = defaultColorForMarkupType(type);
        if (color)
            [self setColor:color];
        
        NSArray *quadPoints = pointStrings ? createPointsFromStrings(pointStrings) : createQuadPointsWithBounds(bounds, bounds.origin);
        [self setQuadrilateralPoints:quadPoints];
        [quadPoints release];
        lineRects = nil;
    }
    return self;
}

- (id)initWithBounds:(NSRect)bounds {
    self = [self initWithBounds:bounds markupType:kPDFMarkupTypeHighlight quadrilateralPointsAsStrings:nil];
    return self;
}

- (id)initWithProperties:(NSDictionary *)dict{
    if (self = [super initWithProperties:dict]) {
        Class stringClass = [NSString class];
        NSString *type = [dict objectForKey:SKPDFAnnotationTypeKey];
        if ([type isKindOfClass:stringClass]) {
            int markupType = kPDFMarkupTypeHighlight;
            if ([type isEqualToString:SKUnderlineString])
                markupType = kPDFMarkupTypeUnderline;
            else if ([type isKindOfClass:stringClass] && [type isEqualToString:SKStrikeOutString])
                markupType = kPDFMarkupTypeStrikeOut;
            if (markupType != [self markupType]) {
                [self setMarkupType:markupType];
                if ([dict objectForKey:SKPDFAnnotationColorKey] == nil) {
                    NSColor *color = defaultColorForMarkupType(markupType);
                    if (color)
                        [self setColor:color];
                }
            }
        }
        
        Class arrayClass = [NSArray class];
        NSArray *pointStrings = [dict objectForKey:SKPDFAnnotationQuadrilateralPointsKey];
        if ([pointStrings isKindOfClass:arrayClass]) {
            NSArray *quadPoints = createPointsFromStrings(pointStrings);
            [self setQuadrilateralPoints:quadPoints];
            [quadPoints release];
        }
        
        lineRects = nil;
    }
    return self;
}

static BOOL adjacentCharacterBounds(NSRect rect1, NSRect rect2) {
    float w = fmaxf(NSWidth(rect2), NSWidth(rect1));
    float h = fmaxf(NSHeight(rect2), NSHeight(rect1));
    // first check the vertical position; allow sub/superscripts
    if (fabsf(NSMinY(rect1) - NSMinY(rect2)) > 0.2 * h && fabsf(NSMaxY(rect1) - NSMaxY(rect2)) > 0.2 * h)
        return NO;
    // compare horizontal position
    // rect1 before rect2
    if (NSMinX(rect1) < NSMinX(rect2))
        return NSMinX(rect2) - NSMaxX(rect1) < 0.4 * w;
    // rect1 after rect2
    if (NSMaxX(rect1) > NSMaxX(rect2))
        return NSMinX(rect1) - NSMaxX(rect2) < 0.4 * w;
    // rect1 on top of rect2
    return YES;
}

- (id)initWithSelection:(PDFSelection *)selection markupType:(int)type {
    NSRect bounds = [[selection pages] count] ? [selection boundsForPage:[[selection pages] objectAtIndex:0]] : NSZeroRect;
    if (selection == nil || NSIsEmptyRect(bounds)) {
        [[self initWithBounds:NSZeroRect] release];
        self = nil;
    } else if (self = [self initWithBounds:bounds markupType:type quadrilateralPointsAsStrings:nil]) {
        PDFPage *page = [[selection pages] objectAtIndex:0];
        NSString *string = [page string];
        NSMutableArray *quadPoints = [[NSMutableArray alloc] init];
        NSRect newBounds = NSZeroRect;
        if (selection) {
            unsigned i, iMax = [selection safeNumberOfRangesOnPage:page];
            NSRect lineRect = NSZeroRect;
            NSRect charRect = NSZeroRect;
            NSRect lastCharRect = NSZeroRect;
            for (i = 0; i < iMax; i++) {
                NSRange range = [selection safeRangeAtIndex:i onPage:page];
                unsigned int j, jMax = NSMaxRange(range);
                for (j = range.location; j < jMax; j++) {
                    lastCharRect = charRect;
                    charRect = [page characterBoundsAtIndex:j];
                    BOOL nonWS = NO == [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[string characterAtIndex:j]];
                    if (NSIsEmptyRect(lineRect)) {
                        // beginning of a line, just ignore whitespace
                        if (nonWS)
                            lineRect = charRect;
                    } else if (adjacentCharacterBounds(lastCharRect, charRect)) {
                        // continuation of a line
                        if (nonWS)
                            lineRect = NSUnionRect(lineRect, charRect);
                    } else {
                        // start of a new line
                        if (NSIsEmptyRect(lineRect) == NO) {
                            if (lineRects == NULL)
                                lineRects = CFArrayCreateMutable(NULL, 0, &SKNSRectArrayCallbacks);
                            CFArrayAppendValue(lineRects, &lineRect);
                            newBounds = NSUnionRect(lineRect, newBounds);
                        }
                        // ignore whitespace at the beginning of the new line
                        lineRect = nonWS ? charRect : NSZeroRect;
                   }
                }
            }
            if (NSIsEmptyRect(lineRect) == NO) {
                if (lineRects == NULL)
                    lineRects = CFArrayCreateMutable(NULL, 0, &SKNSRectArrayCallbacks);
                CFArrayAppendValue(lineRects, &lineRect);
                newBounds = NSUnionRect(lineRect, newBounds);
            }
            if (NSIsEmptyRect(newBounds)) {
                [self release];
                self = nil;
            } else {
                [self setBounds:newBounds];
                iMax = lineRects == NULL ? 0 : CFArrayGetCount(lineRects);
                for (i = 0; i < iMax; i++) {
                    NSArray *quadLine = createQuadPointsWithBounds(*(NSRect *)CFArrayGetValueAtIndex(lineRects, i), [self bounds].origin);
                    [quadPoints addObjectsFromArray:quadLine];
                    [quadLine release];
                }
            }
        }
        [self setQuadrilateralPoints:quadPoints];
        [quadPoints release];
    }
    return self;
}

- (void)dealloc
{
    if (lineRects) CFRelease(lineRects);
    [super dealloc];
}

- (NSDictionary *)properties {
    NSMutableDictionary *dict = [[[super properties] mutableCopy] autorelease];
    NSArray *quadPoints = createStringsFromPoints([self quadrilateralPoints]);
    [dict setValue:quadPoints forKey:SKPDFAnnotationQuadrilateralPointsKey];
    [quadPoints release];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    NSEnumerator *pointEnum = [[self quadrilateralPoints] objectEnumerator];
    NSValue *value;
    NSPoint point;
    NSRect bounds = [self bounds];
    [fdfString appendFDFName:SKFDFAnnotationQuadPointsKey];
    [fdfString appendString:@"["];
    while (value = [pointEnum nextObject]) {
        point = [value pointValue];
        [fdfString appendFormat:@"%f %f ", point.x + NSMinX(bounds), point.y + NSMinY(bounds)];
    }
    [fdfString appendString:@"]"];
    return fdfString;
}

- (void)regenerateLineRects {
    
    NSArray *quadPoints = [self quadrilateralPoints];
    NSAssert([quadPoints count] % 4 == 0, @"inconsistent number of quad points");

    unsigned j, jMax = [quadPoints count] / 4;
    
    if (lineRects == NULL)
        lineRects = CFArrayCreateMutable(NULL, 0, &SKNSRectArrayCallbacks);
    else
        CFArrayRemoveAllValues(lineRects);
    
    for (j = 0; j < jMax; j += 1) {
        
        NSRange range = NSMakeRange(4 * j, 4);

        NSValue *values[4];
        [quadPoints getObjects:values range:range];
        
        NSPoint points[4];
        unsigned i = 0;
        for (i = 0; i < 4; i++)
            points[i] = [values[i] pointValue];
        
        NSRect lineRect;
        lineRect.size.height = points[1].y - points[2].y;
        lineRect.size.width = points[1].x - points[2].x;
        lineRect.origin = SKAddPoints(points[2], [self bounds].origin);
        CFArrayAppendValue(lineRects, &lineRect);
    }
}

- (PDFSelection *)selection {
    if (lineRects == nil)
        [self regenerateLineRects];
    
    PDFSelection *sel, *selection = nil;
    unsigned i, iMax = CFArrayGetCount(lineRects);
    
    for (i = 0; i < iMax; i++) {
        // slightly outset the rect to avoid rounding errors, as selectionForRect is pretty strict
        if (sel = [[self page] selectionForRect:NSInsetRect(*(NSRect *)CFArrayGetValueAtIndex(lineRects, i), -1.0, -1.0)]) {
            if (selection == nil)
                selection = sel;
            else
                [selection addSelection:sel];
        }
    }
    
    return selection;
}

- (BOOL)hitTest:(NSPoint)point {
    if ([super hitTest:point] == NO)
        return NO;
    
    // archived annotations (or annotations we didn't create) won't have these
    if (lineRects == nil)
        [self regenerateLineRects];
    
    unsigned i = CFArrayGetCount(lineRects);
    BOOL isContained = NO;
    
    while (i-- && NO == isContained)
        isContained = NSPointInRect(point, *(NSRect *)CFArrayGetValueAtIndex(lineRects, i));
    
    return isContained;
}

- (NSRect)displayRectForBounds:(NSRect)bounds {
    bounds = [super displayRectForBounds:bounds];
    if ([self markupType] == kPDFMarkupTypeHighlight) {
        float delta = 0.03 * NSHeight(bounds);
        bounds.origin.y -= delta;
        bounds.size.height += delta;
    }
    return bounds;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isMarkup { return YES; }

// fix a bug in PDFKit, the color space sometimes is not correct
- (void)drawWithBox:(CGPDFBox)box inContext:(CGContextRef)context {
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4) {
        CGContextSaveGState(context);
        SKCGContextSetDefaultRGBColorSpace(context);
    }
    [super drawWithBox:box inContext:context];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4) {
        CGContextRestoreGState(context);
    }
}

#pragma mark Scripting support

+ (NSSet *)customScriptingKeys {
    static NSSet *customMarkupScriptingKeys = nil;
    if (customMarkupScriptingKeys == nil) {
        NSMutableSet *customKeys = [[super customScriptingKeys] mutableCopy];
        [customKeys addObject:SKPDFAnnotationSelectionSpecifierKey];
        [customKeys removeObject:SKPDFAnnotationLineWidthKey];
        [customKeys removeObject:SKPDFAnnotationScriptingBorderStyleKey];
        [customKeys removeObject:SKPDFAnnotationDashPatternKey];
        customMarkupScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customMarkupScriptingKeys;
}

- (id)selectionSpecifier {
    PDFSelection *sel = [self selection];
    return sel ? [sel objectSpecifier] : [NSArray array];
}

- (void)setSelectionSpecifier:(id)specifier {
    NSScriptCommand *currentCommand = [NSScriptCommand currentCommand];
    if ([currentCommand isKindOfClass:[NSCreateCommand class]] == NO)
        [currentCommand setScriptErrorNumber:NSReceiversCantHandleCommandScriptError]; 
}

@end

#pragma mark -

@interface PDFAnnotationMarkup (SKExtensions)
@end

@implementation PDFAnnotationMarkup (SKExtensions)

- (BOOL)isConvertibleAnnotation { return YES; }

- (id)copyNoteAnnotation {
    NSArray *quadPoints = createStringsFromPoints([self quadrilateralPoints]);
    SKPDFAnnotationMarkup *annotation = [[SKPDFAnnotationMarkup alloc] initWithBounds:[self bounds] markupType:[self markupType] quadrilateralPointsAsStrings:quadPoints];
    [quadPoints release];
    [annotation setString:[self string]];
    [annotation setColor:[self color]];
    [annotation setBorder:[[[self border] copy] autorelease]];
    return annotation;
}

@end
