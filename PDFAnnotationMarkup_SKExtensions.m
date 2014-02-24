//
//  PDFAnnotationMarkup_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/1/08.
/*
 This software is Copyright (c) 2008-2014
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

#import "PDFAnnotationMarkup_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "PDFAnnotationInk_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "PDFSelection_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import "NSCharacterSet_SKExtensions.h"
#import "SKRuntime.h"
#import "NSPointerArray_SKExtensions.h"
#import "NSColor_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "NSResponder_SKExtensions.h"


NSString *SKPDFAnnotationSelectionSpecifierKey = @"selectionSpecifier";


@implementation PDFAnnotationMarkup (SKExtensions)

/*
 http://www.cocoabuilder.com/archive/message/cocoa/2007/2/16/178891
  The docs are wrong (as is Adobe's spec).  The ordering at zero rotation is:
  --------
  | 0  1 |
  | 2  3 |
  --------
 */        
static NSArray *createQuadPointsWithBounds(const NSRect bounds, const NSPoint origin, NSInteger rotation)
{
    NSRect r = NSOffsetRect(bounds, -origin.x, -origin.y);
    NSInteger offset = rotation / 90;
    NSPoint p[4];
    memset(&p, 0, 4 * sizeof(NSPoint));
    p[offset] = SKTopLeftPoint(r);
    p[(++offset)%4] = SKTopRightPoint(r);
    p[(++offset)%4] = SKBottomRightPoint(r);
    p[(++offset)%4] = SKBottomLeftPoint(r);
    return [[NSArray alloc] initWithObjects:[NSValue valueWithPoint:p[0]], [NSValue valueWithPoint:p[1]], [NSValue valueWithPoint:p[3]], [NSValue valueWithPoint:p[2]], nil];
}

static NSMapTable *lineRectsTable = nil;

static void (*original_dealloc)(id, SEL) = NULL;

- (void)replacement_dealloc {
    [lineRectsTable removeObjectForKey:self];
    original_dealloc(self, _cmd);
}

+ (void)load {
    original_dealloc = (void (*)(id, SEL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(dealloc), @selector(replacement_dealloc));
    lineRectsTable = [[NSMapTable alloc] initWithKeyOptions:NSMapTableZeroingWeakMemory | NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory | NSMapTableObjectPointerPersonality capacity:0];
}

- (NSPointerArray *)lineRects {
    NSPointerArray *lineRects = [lineRectsTable objectForKey:self];
    if (lineRects == NULL) {
        lineRects = [[NSPointerArray alloc] initForRectPointers];
        [lineRectsTable setObject:lineRects forKey:self];
        [lineRects release];;
    }
    return lineRects;
}

- (BOOL)hasLineRects {
    return [lineRectsTable objectForKey:self] != nil;
}

+ (NSColor *)defaultSkimNoteColorForMarkupType:(NSInteger)markupType
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

- (id)initSkimNoteWithBounds:(NSRect)bounds markupType:(NSInteger)type {
    self = [super initSkimNoteWithBounds:bounds];
    if (self) {
        [self setMarkupType:type];
        
        NSColor *color = [[self class] defaultSkimNoteColorForMarkupType:type];
        if (color)
            [self setColor:color];
    }
    return self;
}

- (id)initSkimNoteWithBounds:(NSRect)bounds {
    self = [self initSkimNoteWithBounds:bounds markupType:kPDFMarkupTypeHighlight];
    return self;
}

- (id)initSkimNoteWithSelection:(PDFSelection *)selection markupType:(NSInteger)type {
    NSRect bounds = [selection hasCharacters] ? [selection boundsForPage:[selection safeFirstPage]] : NSZeroRect;
    if ([selection hasCharacters] == NO || NSIsEmptyRect(bounds)) {
        [[self initWithBounds:NSZeroRect] release];
        self = nil;
    } else {
        self = [self initSkimNoteWithBounds:bounds markupType:type];
        if (self) {
            PDFPage *page = [selection safeFirstPage];
            NSInteger rotation = [page rotation];
            NSMutableArray *quadPoints = [[NSMutableArray alloc] init];
            NSRect newBounds = NSZeroRect;
            if (selection) {
                NSUInteger i, iMax;
                NSRect lineRect = NSZeroRect;
                for (PDFSelection *sel in [selection selectionsByLine]) {
                    lineRect = [sel boundsForPage:page];
                    if (NSIsEmptyRect(lineRect) == NO && [[sel string] rangeOfCharacterFromSet:[NSCharacterSet nonWhitespaceAndNewlineCharacterSet]].length) {
                         [[self lineRects] addPointer:&lineRect];
                         newBounds = NSUnionRect(lineRect, newBounds);
                    }
                } 
                if (NSIsEmptyRect(newBounds)) {
                    [self release];
                    self = nil;
                } else {
                    [self setBounds:newBounds];
                    if ([self hasLineRects]) {
                        NSPointerArray *lines = [self lineRects];
                        iMax = [lines count];
                        for (i = 0; i < iMax; i++) {
                            NSArray *quadLine = createQuadPointsWithBounds(*(NSRectPointer)[lines pointerAtIndex:i], [self bounds].origin, rotation);
                            [quadPoints addObjectsFromArray:quadLine];
                            [quadLine release];
                        }
                    }
                }
            }
            [self setQuadrilateralPoints:quadPoints];
            [quadPoints release];
        }
    }
    return self;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    NSPoint point;
    NSRect bounds = [self bounds];
    [fdfString appendFDFName:SKFDFAnnotationQuadrilateralPointsKey];
    [fdfString appendString:@"["];
    for (NSValue *value in [self quadrilateralPoints]) {
        point = [value pointValue];
        [fdfString appendFormat:@"%f %f ", point.x + NSMinX(bounds), point.y + NSMinY(bounds)];
    }
    [fdfString appendString:@"]"];
    return fdfString;
}

- (void)regenerateLineRects {
    
    NSArray *quadPoints = [self quadrilateralPoints];
    NSAssert([quadPoints count] % 4 == 0, @"inconsistent number of quad points");

    NSPointerArray *lines = [self lineRects];
    NSUInteger j = [lines count], jMax = [quadPoints count] / 4;
    NSPoint origin = [self bounds].origin;
    
    while ([lines count])
        [lines removePointerAtIndex:0];
    
    for (j = 0; j < jMax; j++) {
        
        NSRange range = NSMakeRange(4 * j, 4);

        NSValue *values[4];
        [quadPoints getObjects:values range:range];
        
        NSPoint point;
        NSUInteger i;
        CGFloat minX = CGFLOAT_MAX, maxX = -CGFLOAT_MAX, minY = CGFLOAT_MAX, maxY = -CGFLOAT_MAX;
        for (i = 0; i < 4; i++) {
            point = [values[i] pointValue];
            minX = fmin(minX, point.x);
            maxX = fmax(maxX, point.x);
            minY = fmin(minY, point.y);
            maxY = fmax(maxY, point.y);
        }
        
        NSRect lineRect = NSMakeRect(origin.x + minX, origin.y + minY, maxX - minX, maxY - minY);
        [lines addPointer:&lineRect];
    }
}

- (PDFSelection *)selection {
    if ([self hasLineRects] == NO)
        [self regenerateLineRects];
    
    PDFSelection *sel, *selection = nil;
    NSPointerArray *lines = [self lineRects];
    NSUInteger i, iMax = [lines count];
    
    for (i = 0; i < iMax; i++) {
        // slightly outset the rect to avoid rounding errors, as selectionForRect is pretty strict in some OS versions, but unfortunately not in others
        if ((sel = [[self page] selectionForRect:NSInsetRect(*(NSRectPointer)[lines pointerAtIndex:i], -1.0, -1.0)]) && [sel hasCharacters]) {
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
    if ([self hasLineRects] == NO)
        [self regenerateLineRects];
    
    NSPointerArray *lines = [self lineRects];
    NSUInteger i = [lines count];
    BOOL isContained = NO;
    
    while (i-- && NO == isContained)
        isContained = NSPointInRect(point, *(NSRectPointer)[lines pointerAtIndex:i]);
    
    return isContained;
}

- (NSRect)displayRectForBounds:(NSRect)bounds lineWidth:(CGFloat)lineWidth {
    bounds = [super displayRectForBounds:bounds lineWidth:lineWidth];
    if ([self markupType] == kPDFMarkupTypeHighlight) {
        CGFloat delta = 0.03 * NSHeight(bounds);
        bounds.origin.y -= delta;
        bounds.size.height += delta;
    }
    return bounds;
}

- (void)drawSelectionHighlightForView:(PDFView *)pdfView {
    if (NSIsEmptyRect([self bounds]))
        return;
    // archived annotations (or annotations we didn't create) won't have these
    if ([self hasLineRects] == NO)
        [self regenerateLineRects];
    
    BOOL active = [[pdfView window] isKeyWindow] && [[[pdfView window] firstResponder] isDescendantOf:pdfView];
    NSPointerArray *lines = [self lineRects];
    NSUInteger i, iMax = [lines count];
    CGFloat lineWidth = 1.0 / [pdfView scaleFactor];
    PDFPage *page = [self page];
    
    [NSGraphicsContext saveGraphicsState];
    [(active ? [NSColor selectionHighlightColor] : [NSColor disabledSelectionHighlightColor]) setFill];
    for (i = 0; i < iMax; i++)
        NSFrameRectWithWidth([pdfView convertRect:NSIntegralRect([pdfView convertRect:*(NSRectPointer)[lines pointerAtIndex:i] fromPage:page]) toPage:page], lineWidth);
    [NSGraphicsContext restoreGraphicsState];
}

- (BOOL)isMarkup { return YES; }

- (BOOL)hasBorder { return NO; }

- (BOOL)isConvertibleAnnotation { return YES; }

- (void)autoUpdateString {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableUpdateContentsFromEnclosedTextKey])
        return;
    NSString *selString = [[self selection] cleanedString];
    if ([selString length])
        [self setString:selString];
}

#pragma mark Scripting support

+ (NSSet *)customScriptingKeys {
    static NSSet *customMarkupScriptingKeys = nil;
    if (customMarkupScriptingKeys == nil) {
        NSMutableSet *customKeys = [[super customScriptingKeys] mutableCopy];
        [customKeys addObject:SKPDFAnnotationSelectionSpecifierKey];
        [customKeys addObject:SKPDFAnnotationScriptingPointListsKey];
        [customKeys removeObject:SKNPDFAnnotationLineWidthKey];
        [customKeys removeObject:SKPDFAnnotationScriptingBorderStyleKey];
        [customKeys removeObject:SKNPDFAnnotationDashPatternKey];
        customMarkupScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customMarkupScriptingKeys;
}

- (id)selectionSpecifier {
    PDFSelection *sel = [self selection];
    return [sel hasCharacters] ? [sel objectSpecifier] : [NSArray array];
}

- (NSArray *)scriptingPointLists {
    NSPoint origin = [self bounds].origin;
    NSMutableArray *pointLists = [NSMutableArray array];
    NSMutableArray *pointValues;
    NSPoint point;
    NSInteger i, j, iMax = [[self quadrilateralPoints] count] / 4;
    for (i = 0; i < iMax; i++) {
        pointValues = [[NSMutableArray alloc] initWithCapacity:iMax];
        for (j = 0; j < 4; j++) {
            point = [[[self quadrilateralPoints] objectAtIndex:4 * i + j] pointValue];
            [pointValues addObject:[NSData dataWithPointAsQDPoint:SKAddPoints(point, origin)]];
        }
        [pointLists addObject:pointValues];
        [pointValues release];
    }
    return pointLists;
}

@end
