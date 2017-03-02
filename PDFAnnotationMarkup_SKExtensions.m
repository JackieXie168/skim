//
//  PDFAnnotationMarkup_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/1/08.
/*
 This software is Copyright (c) 2008-2017
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
#import "PDFPage_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "SKNoteText.h"


NSString *SKPDFAnnotationSelectionSpecifierKey = @"selectionSpecifier";


@interface SKPDFAnnotationMarkupExtraIvars : NSObject {
    NSPointerArray *lineRects;
    NSString *textString;
    SKNoteText *noteText;
}
@property (nonatomic, retain) NSPointerArray *lineRects;
@property (nonatomic, retain) NSString *textString;
@property (nonatomic, retain) SKNoteText *noteText;
@end

@implementation SKPDFAnnotationMarkupExtraIvars
@synthesize lineRects, textString, noteText;
- (void)dealloc {
    SKDESTROY(lineRects);
    SKDESTROY(textString);
    SKDESTROY(noteText);
    [super dealloc];
}
@end

#pragma mark -

@implementation PDFAnnotationMarkup (SKExtensions)

/*
 http://www.cocoabuilder.com/archive/message/cocoa/2007/2/16/178891
  The docs are wrong (as is Adobe's spec).  The ordering on the rotated page is:
 --------
 | 0  1 |
 | 2  3 |
 --------
 */

static void addQuadPointsWithBounds(NSMutableArray *quadPoints, const NSRect bounds, const NSPoint origin, NSInteger rotation)
{
    static NSInteger offset[4] = {0, 1, 3, 2};
    NSRect r = NSOffsetRect(bounds, -origin.x, -origin.y);
    NSInteger i = rotation / 90;
    NSPoint p[4];
    memset(&p, 0, 4 * sizeof(NSPoint));
    p[offset[i]] = SKTopLeftPoint(r);
    p[offset[++i%4]] = SKTopRightPoint(r);
    p[offset[++i%4]] = SKBottomRightPoint(r);
    p[offset[++i%4]] = SKBottomLeftPoint(r);
    for (i = 0; i < 4; i++)
        [quadPoints addObject:[NSValue valueWithPoint:p[i]]];
}

static NSMapTable *extraIvarsTable = nil;

static void (*original_dealloc)(id, SEL) = NULL;

- (void)replacement_dealloc {
    [extraIvarsTable removeObjectForKey:self];
    original_dealloc(self, _cmd);
}

+ (void)load {
    original_dealloc = (void (*)(id, SEL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(dealloc), @selector(replacement_dealloc));
    extraIvarsTable = [[NSMapTable alloc] initWithKeyOptions:NSMapTableZeroingWeakMemory | NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory | NSMapTableObjectPointerPersonality capacity:0];
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

- (SKPDFAnnotationMarkupExtraIvars *)extraIvars {
    SKPDFAnnotationMarkupExtraIvars *extraIvars = [extraIvarsTable objectForKey:self];
    if (extraIvars == nil) {
        extraIvars = [[SKPDFAnnotationMarkupExtraIvars alloc] init];
        [extraIvarsTable setObject:extraIvars forKey:self];
        [extraIvars release];
    }
    return extraIvars;
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
            NSInteger rotation = [page intrinsicRotation];
            NSRect newBounds = NSZeroRect;
            NSPointerArray *lines = nil;
            for (PDFSelection *sel in [selection selectionsByLine]) {
                NSRect lineRect = [sel boundsForPage:page];
                if (NSIsEmptyRect(lineRect) == NO && [[sel string] rangeOfCharacterFromSet:[NSCharacterSet nonWhitespaceAndNewlineCharacterSet]].length) {
                    if (lines == nil)
                        lines = [[NSPointerArray alloc] initForRectPointers];
                    [lines addPointer:&lineRect];
                    newBounds = NSUnionRect(lineRect, newBounds);
                }
            } 
            if (lines == nil) {
                [self release];
                self = nil;
            } else {
                NSMutableArray *quadPoints = [[NSMutableArray alloc] init];
                NSUInteger i, iMax = [lines count];
                for (i = 0; i < iMax; i++)
                    addQuadPointsWithBounds(quadPoints, [lines rectAtIndex:i], newBounds.origin, rotation);
                [self setBounds:newBounds];
                [self setQuadrilateralPoints:quadPoints];
                [[self extraIvars] setLineRects:lines];
                [quadPoints release];
                [lines release];
            }
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

- (NSPointerArray *)lineRects {
    SKPDFAnnotationMarkupExtraIvars *extraIvars = [self extraIvars];
    NSPointerArray *lineRects = [extraIvars lineRects];
    if (lineRects == nil) {
        lineRects = [[NSPointerArray alloc] initForRectPointers];
        
        // archived annotations (or annotations we didn't create) won't have these
        NSArray *quadPoints = [self quadrilateralPoints];
        NSAssert([quadPoints count] % 4 == 0, @"inconsistent number of quad points");
        
        NSUInteger j, jMax = [quadPoints count] / 4;
        NSPoint origin = [self bounds].origin;
        NSRange range = NSMakeRange(0, 4);
        
        while ([lineRects count])
            [lineRects removePointerAtIndex:0];
        
        for (j = 0; j < jMax; j++) {
            
            range.location = 4 * j;
            
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
            [lineRects addPointer:&lineRect];
        }
        
        [extraIvars setLineRects:lineRects];
        [lineRects release];
    }
    return lineRects;
}

- (PDFSelection *)selection {
    NSMutableArray *selections = [NSMutableArray array];
    NSPointerArray *lines = [self lineRects];
    NSUInteger i, iMax = [lines count];
    CGFloat outset = floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6 ? -1.0 : 0.0;
    
    for (i = 0; i < iMax; i++) {
        // slightly outset the rect to avoid rounding errors, as selectionForRect is pretty strict in some OS versions, but unfortunately not in others
        PDFSelection *selection = [[self page] selectionForRect:NSInsetRect([lines rectAtIndex:i], outset, outset)];
        if ([selection hasCharacters])
            [selections addObject:selection];
    }
    return [PDFSelection selectionByAddingSelections:selections];
}

- (BOOL)hitTest:(NSPoint)point {
    if ([super hitTest:point] == NO)
        return NO;
    
    NSPointerArray *lines = [self lineRects];
    NSUInteger i = [lines count];
    BOOL isContained = NO;
    
    while (i-- && NO == isContained)
        isContained = NSPointInRect(point, [lines rectAtIndex:i]);
    
    return isContained;
}

- (CGFloat)boundsOrder {
    NSPointerArray *lines = [self lineRects];
    NSRect bounds = [lines count] > 0 ? [lines rectAtIndex:0] : [self bounds];
    return [[self page] sortOrderForBounds:bounds];
}

- (NSRect)displayRectForBounds:(NSRect)bounds lineWidth:(CGFloat)lineWidth {
    bounds = [super displayRectForBounds:bounds lineWidth:lineWidth];
    if ([self markupType] == kPDFMarkupTypeHighlight) {
        CGFloat delta = -0.03 * NSHeight(bounds);
        bounds = ([[self page] intrinsicRotation] % 180) == 0 ? NSInsetRect(bounds, 0.0, delta) : NSInsetRect(bounds, delta, 0.0);
    }
    return bounds;
}

- (void)drawSelectionHighlightForView:(PDFView *)pdfView inContext:(CGContextRef)context {
    if (NSIsEmptyRect([self bounds]))
        return;
    
    BOOL active = [[pdfView window] isKeyWindow] && [[[pdfView window] firstResponder] isDescendantOf:pdfView];
    NSPointerArray *lines = [self lineRects];
    NSUInteger i, iMax = [lines count];
    CGFloat lineWidth = 1.0 / [pdfView scaleFactor];
    PDFPage *page = [self page];
    CGColorRef color = [(active ? [NSColor alternateSelectedControlColor] : [NSColor disabledControlTextColor]) CGColor];
    
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, color);
    CGContextSetLineWidth(context, lineWidth);
    for (i = 0; i < iMax; i++) {
        NSRect rect = [pdfView convertRect:[pdfView backingAlignedRect:[pdfView convertRect:[lines rectAtIndex:i] fromPage:page]] toPage:page];
        CGContextStrokeRect(context, CGRectInset(NSRectToCGRect(rect), 0.5 * lineWidth, 0.5 * lineWidth));
    }
    CGContextRestoreGState(context);
}

- (BOOL)isMarkup { return YES; }

- (BOOL)hasBorder { return NO; }

- (BOOL)isConvertibleAnnotation { return YES; }

- (BOOL)hasNoteText { return [self isEditable]; }

- (SKNoteText *)noteText {
    if ([self isEditable] == NO)
        return nil;
    SKPDFAnnotationMarkupExtraIvars *extraIvars = [self extraIvars];
    SKNoteText *noteText = [extraIvars noteText];
    if (noteText == nil) {
        noteText = [[SKNoteText alloc] initWithNote:self];
        [extraIvars setNoteText:noteText];
        [noteText release];
    }
    return noteText;
}

- (NSString *)textString {
    if ([self isEditable] == NO)
        return nil;
    SKPDFAnnotationMarkupExtraIvars *extraIvars = [self extraIvars];
    NSString *textString = [extraIvars textString];
    if (textString == nil) {
        textString = [[self selection] cleanedString] ?: @"";
        [extraIvars setTextString:textString];
    }
    return textString;
}

- (NSString *)colorDefaultKey {
    switch ([self markupType]) {
        case kPDFMarkupTypeUnderline: return SKUnderlineNoteColorKey;
        case kPDFMarkupTypeStrikeOut: return SKStrikeOutNoteColorKey;
        case kPDFMarkupTypeHighlight: return SKHighlightNoteColorKey;
    }
    return nil;
}

- (void)autoUpdateString {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableUpdateContentsFromEnclosedTextKey])
        return;
    NSString *selString = [self textString];
    if ([selString length])
        [self setString:selString];
}

- (NSSet *)keysForValuesToObserveForUndo {
    static NSSet *markupKeys = nil;
    if (markupKeys == nil) {
        NSMutableSet *mutableKeys = [[super keysForValuesToObserveForUndo] mutableCopy];
        [mutableKeys removeObject:SKNPDFAnnotationBorderKey];
        markupKeys = [mutableKeys copy];
        [mutableKeys release];
    }
    return markupKeys;
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
