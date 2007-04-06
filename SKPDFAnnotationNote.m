//
//  SKPDFAnnotationNote.m
//  Skim
//
//  Created by Christiaan Hofman on 2/6/07.
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

#import "SKPDFAnnotationNote.h"
#import "SKStringConstants.h"
#import "PDFPage_SKExtensions.h"
#import "SKPDFView.h"

enum {
    SKASTextNote = 'NTxt',
    SKASAnchoredNote = 'NAnc',
    SKASCircleNote = 'NCir',
    SKASSquareNote = 'NSqu',
    SKASHighlightNote = 'NHil',
    SKASUnderlineNote = 'NUnd',
    SKASStrikeOutNote = 'NStr'
};

NSString *SKAnnotationWillChangeNotification = @"SKAnnotationWillChangeNotification";
NSString *SKAnnotationDidChangeNotification = @"SKAnnotationDidChangeNotification";


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

@interface PDFSelection (PDFSelectionPrivateDeclarations)
- (int)numberOfRangesOnPage:(PDFPage *)page;
- (NSRange)rangeAtIndex:(int)index onPage:(PDFPage *)page;
@end

@implementation PDFAnnotation (SKExtensions)

- (id)initWithDictionary:(NSDictionary *)dict{
    [[self initWithBounds:NSZeroRect] release];
    
    NSString *type = [dict objectForKey:@"type"];
    NSRect bounds = NSRectFromString([dict objectForKey:@"bounds"]);
    NSString *contents = [dict objectForKey:@"contents"];
    NSColor *color = [dict objectForKey:@"color"];
    
    if ([type isEqualToString:@"Note"]) {
        self = [[SKPDFAnnotationNote alloc] initWithBounds:bounds];
        NSAttributedString *text = [dict objectForKey:@"text"];
        NSImage *image = [dict objectForKey:@"image"];
        if (image)
            [(SKPDFAnnotationNote *)self setImage:image];
        if (text)
            [(SKPDFAnnotationNote *)self setText:text];
    } else if ([type isEqualToString:@"FreeText"]) {
        self = [[SKPDFAnnotationFreeText alloc] initWithBounds:bounds];
        NSFont *font = [dict objectForKey:@"font"];
        if (font)
            [(SKPDFAnnotationFreeText *)self setFont:font];
    } else if ([type isEqualToString:@"Circle"]) {
        self = [[SKPDFAnnotationCircle alloc] initWithBounds:bounds];
    } else if ([type isEqualToString:@"Square"]) {
        self = [[SKPDFAnnotationSquare alloc] initWithBounds:bounds];
    } else if ([type isEqualToString:@"Highlight"] || [type isEqualToString:@"MarkUp"]) {
        self = [[SKPDFAnnotationMarkup alloc] initWithBounds:bounds markupType:kPDFMarkupTypeHighlight quadrilateralPointsAsStrings:[dict objectForKey:@"quadrilateralPoints"]];
    } else if ([type isEqualToString:@"Underline"]) {
        self = [[SKPDFAnnotationMarkup alloc] initWithBounds:bounds markupType:kPDFMarkupTypeUnderline quadrilateralPointsAsStrings:[dict objectForKey:@"quadrilateralPoints"]];
    } else if ([type isEqualToString:@"StrikeOut"]) {
        self = [[SKPDFAnnotationMarkup alloc] initWithBounds:bounds markupType:kPDFMarkupTypeStrikeOut quadrilateralPointsAsStrings:[dict objectForKey:@"quadrilateralPoints"]];
    } else {
        self = nil;
    }
    
    if (contents)
        [self setContents:contents];
    if (color)
        [self setColor:color];
    
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    [dict setValue:[self type] forKey:@"type"];
    [dict setValue:[self contents] forKey:@"contents"];
    [dict setValue:[self color] forKey:@"color"];
    [dict setValue:NSStringFromRect([self bounds]) forKey:@"bounds"];
    [dict setValue:[NSNumber numberWithUnsignedInt:[self pageIndex]] forKey:@"pageIndex"];
    return dict;
}

- (PDFDestination *)destination{
    NSRect bounds = [self bounds];
    NSPoint point = NSMakePoint(NSMinX(bounds), NSMaxY(bounds));
    return [[[PDFDestination alloc] initWithPage:[self page] atPoint:point] autorelease];
}

- (unsigned int)pageIndex {
    PDFPage *page = [self page];
    return page ? [[page document] indexForPage:page] : NSNotFound;
}

- (NSImage *)image { return nil; }

- (NSAttributedString *)text { return nil; }

- (NSArray *)texts { return nil; }

- (BOOL)isNoteAnnotation { return NO; }

- (BOOL)isTemporaryAnnotation { return NO; }

- (BOOL)isResizable { return NO; }

- (BOOL)isMovable { return NO; }

- (BOOL)isEditable { return NO; }

#pragma mark Scripting support

- (id)init {
    self = nil;
    NSScriptCommand *currentCommand = [NSScriptCommand currentCommand];
    if ([currentCommand isKindOfClass:[NSCreateCommand class]]) {
        unsigned long classCode = [[(NSCreateCommand *)currentCommand createClassDescription] appleEventCode];
       
        if (classCode == 'Note') {
            
            NSMutableDictionary *properties = [[[(NSCreateCommand *)currentCommand resolvedKeyDictionary] mutableCopy] autorelease];
            int type = [[properties objectForKey:@"noteType"] intValue];
            
            if (type == 0) {
                [currentCommand setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
                [currentCommand setScriptErrorString:NSLocalizedString(@"New notes need a type.", @"Error description")];
                return nil;
            } else if (type == SKASHighlightNote || type == SKASStrikeOutNote || type == SKASUnderlineNote) {
                [currentCommand setScriptErrorNumber:NSArgumentsWrongScriptError]; 
                [currentCommand setScriptErrorString:NSLocalizedString(@"Text markups cannot be created in scripts.", @"Error description")];
                return nil;
            }
            
            PDFAnnotation *annotation = nil;
            
            if (type == SKASTextNote)
                annotation = [[SKPDFAnnotationFreeText alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0)];
            else if (type == SKASAnchoredNote)
                annotation = [[SKPDFAnnotationNote alloc] initWithBounds:NSMakeRect(100.0, 100.0, 16.0, 16.0)];
            else if (type == SKASCircleNote)
                annotation = [[SKPDFAnnotationCircle alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0)];
            else if (type == SKASSquareNote)
                annotation = [[SKPDFAnnotationSquare alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0)];
            else if (type == SKASHighlightNote)
                annotation = [[SKPDFAnnotationMarkup alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0) markupType:kPDFMarkupTypeHighlight quadrilateralPointsAsStrings:nil];
            else if (type == SKASStrikeOutNote)
                annotation = [[SKPDFAnnotationMarkup alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0) markupType:kPDFMarkupTypeStrikeOut quadrilateralPointsAsStrings:nil];
             else if (type == SKASUnderlineNote)
                annotation = [[SKPDFAnnotationMarkup alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0) markupType:kPDFMarkupTypeUnderline quadrilateralPointsAsStrings:nil];
           
            self = annotation;
        }
    }
    return self;
}

- (NSScriptObjectSpecifier *)objectSpecifier {
	unsigned index = [[[self page] notes] indexOfObjectIdenticalTo:self];
    if (index != NSNotFound) {
        NSScriptObjectSpecifier *containerRef = [[self page] objectSpecifier];
        return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"notes" index:index] autorelease];
    } else {
        return nil;
    }
}

- (int)noteType {
    if ([[self type] isEqualToString:@"FreeText"])
        return SKASTextNote;
    else if ([[self type] isEqualToString:@"Note"])
        return SKASAnchoredNote;
    else if ([[self type] isEqualToString:@"Circle"])
        return SKASCircleNote;
    else if ([[self type] isEqualToString:@"Square"])
        return SKASSquareNote;
    else if ([[self type] isEqualToString:@"Highlight"] || [[self type] isEqualToString:@"MarkUp"])
        return SKASHighlightNote;
    else if ([[self type] isEqualToString:@"Underline"])
        return SKASUnderlineNote;
    else if ([[self type] isEqualToString:@"StrikeOut"])
        return SKASStrikeOutNote;
    return 0;
}

- (id)textContents;
{
    return [self contents] ? [[[NSTextStorage alloc] initWithString:[self contents]] autorelease] : [NSNull null];
}

- (void)setTextContents:(id)text;
{
    [self setContents:[text string]];
}

- (id)coerceValueForTextContents:(id)value {
    return [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:value toClass:[NSTextStorage class]];
}

- (id)richText {
    return [NSNull null];
}

- (void)setBoundsAsQDRect:(NSData *)inQDBoundsAsData {
    if ([inQDBoundsAsData length] == sizeof(Rect)) {
        const Rect *qdBounds = (const Rect *)[inQDBoundsAsData bytes];
        SKPDFView *pdfView = [[[self page] containingDocument] pdfView];
        NSRect newBounds = NSRectFromRect(*qdBounds);
        if ([self isResizable] == NO)
            newBounds.size = [self bounds].size;
        [pdfView setNeedsDisplayForAnnotation:self];
        [self setBounds:newBounds];
        [pdfView setNeedsDisplayForAnnotation:self];
    }

}

- (NSData *)boundsAsQDRect {
    Rect qdBounds = RectFromNSRect([self bounds]);
    return [NSData dataWithBytes:&qdBounds length:sizeof(Rect)];
}

- (id)handleGoToScriptCommand:(NSScriptCommand *)command {
    [[[[self page] containingDocument] pdfView] scrollAnnotationToVisible:self];
    return nil;
}

@end

#pragma mark -

@implementation SKPDFAnnotationCircle

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        [self setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKCircleNoteColorKey]]];
        [[self border] setLineWidth:2.0];
    }
    return self;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)shouldPrint { return YES; }

- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setContents:(NSString *)contents {
    [super setContents:contents];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setColor:(NSColor *)color {
    [super setColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

@end

#pragma mark -

@implementation SKPDFAnnotationSquare

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        [self setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKSquareNoteColorKey]]];
        [[self border] setLineWidth:2.0];
    }
    return self;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)shouldPrint { return YES; }

- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setContents:(NSString *)contents {
    [super setContents:contents];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setColor:(NSColor *)color {
    [super setColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

@end

#pragma mark -

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

static NSArray *createQuadPointsWithBounds(const NSRect bounds, const NSPoint origin)
{
    NSPoint p0 = NSMakePoint(NSMinX(bounds) - origin.x, NSMaxY(bounds) - origin.y);
    NSPoint p1 = NSMakePoint(NSMaxX(bounds) - origin.x, NSMaxY(bounds) - origin.y);
    NSPoint p2 = NSMakePoint(NSMinX(bounds) - origin.x, NSMinY(bounds) - origin.y);
    NSPoint p3 = NSMakePoint(NSMaxX(bounds) - origin.x, NSMinY(bounds) - origin.y);
    return [[NSArray alloc] initWithObjects:[NSValue valueWithPoint:p0], [NSValue valueWithPoint:p1], [NSValue valueWithPoint:p2], [NSValue valueWithPoint:p3], nil];
}

// adjust the range to remove whitespace and newlines at the end
static void adjustRangeForWhitespaceAndNewlines(NSRange *range, NSString *string)
{
    static NSCharacterSet *nonWhitespaceAndNewlineSet = nil;
    if (nil == nonWhitespaceAndNewlineSet)
        nonWhitespaceAndNewlineSet = [[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet] copy];
    NSRange r = [string rangeOfCharacterFromSet:nonWhitespaceAndNewlineSet options:0 range:*range];
    if (r.length && (r.location != range->location)) {
        range->location = r.location;
        range->length -= (r.length + 1);
    }
    r = [string rangeOfCharacterFromSet:nonWhitespaceAndNewlineSet options:NSBackwardsSearch range:*range];
    if (r.length)
        range->length = r.location - range->location + 1;
    else
        range->length = 0;
}

// returns NO if the only characters in the rect are whitespace
static BOOL lineRectTrimmingWhitespaceForPage(NSRect *lineRect, PDFPage *page)
{
    PDFSelection *selection = [page selectionForRect:*lineRect];
    NSRange r = [selection rangeAtIndex:([selection numberOfRangesOnPage:page] - 1) onPage:page];
    adjustRangeForWhitespaceAndNewlines(&r, [page string]);
    if (r.length) {
        *lineRect = [[page selectionForRange:r] boundsForPage:page];
        return YES;
    }
    return NO;
}    

- (id)initWithBounds:(NSRect)bounds {
    self = [self initWithBounds:bounds markupType:kPDFMarkupTypeHighlight quadrilateralPointsAsStrings:nil];
    return self;
}

- (id)initWithBounds:(NSRect)bounds markupType:(int)type quadrilateralPointsAsStrings:(NSArray *)pointStrings {
    if (self = [super initWithBounds:bounds]) {
        [self setMarkupType:type];
        if (type == kPDFMarkupTypeHighlight)
            [self setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKHighlightNoteColorKey]]];
        else if (type == kPDFMarkupTypeUnderline)
            [self setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKUnderlineNoteColorKey]]];
        else if (type == kPDFMarkupTypeStrikeOut)
            [self setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKStrikeOutNoteColorKey]]];
        
        NSArray *quadPoints = nil;
        if (pointStrings) {
            quadPoints = createPointsFromStrings(pointStrings);
        } else {
            /*
             http://www.cocoabuilder.com/archive/message/cocoa/2007/2/16/178891
              The docs are wrong (as is Adobe's spec).  The ordering is:
              --------
              | 0  1 |
              | 2  3 |
              --------
             */        
            quadPoints = [[NSArray alloc] initWithObjects:
                [NSValue valueWithPoint: NSMakePoint(0.0, NSHeight(bounds))],
                [NSValue valueWithPoint: NSMakePoint(NSWidth(bounds), NSHeight (bounds))],
                [NSValue valueWithPoint: NSMakePoint(0.0, 0.0)],
                [NSValue valueWithPoint: NSMakePoint(NSWidth(bounds), 0.0)], nil];
        }
        [self setQuadrilateralPoints:quadPoints];
        [quadPoints release];
        numberOfLines = 0;
        lineRects = NULL;
    }
    return self;
}

- (void)addLineRect:(NSRect)aRect {
    numberOfLines++;
    lineRects = NSZoneRealloc([self zone], lineRects, numberOfLines * sizeof(NSRect));
    lineRects[numberOfLines - 1] = aRect;
}

- (id)initWithSelection:(PDFSelection *)selection markupType:(int)type {
    NSRect bounds = selection ? [selection boundsForPage:[[selection pages] objectAtIndex:0]] : NSZeroRect;
    if (self = [self initWithBounds:bounds markupType:type quadrilateralPointsAsStrings:nil]) {
        if ([selection respondsToSelector:@selector(numberOfRangesOnPage:)] && [selection respondsToSelector:@selector(rangeAtIndex:onPage:)]) {
            PDFPage *page = [[selection pages] objectAtIndex:0];
            NSMutableArray *quadPoints = [[NSMutableArray alloc] init];
            if (selection) {
                unsigned i, iMax = [selection numberOfRangesOnPage:page];
                for (i = 0; i < iMax; i++) {
                    NSRange range = [selection rangeAtIndex:i onPage:page];
                    unsigned int j, jMax = NSMaxRange(range);
                    NSRect lineRect = NSZeroRect;
                    for (j = range.location; j < jMax; j++) {
                        NSRect charRect = [page characterBoundsAtIndex:j];
                        if (NSEqualRects(lineRect, NSZeroRect)) {
                            lineRect = charRect;
                            /* this test of whether a character is part of a line depends on kerning */
                        } else if (fabs(NSMaxX(lineRect) - NSMinX(charRect)) < 1.0 * NSWidth(charRect) && fabs(NSMinY(lineRect) - NSMinY(charRect)) < 0.1 * NSHeight(charRect) && fabs(NSMaxY(lineRect) - NSMaxY(charRect)) < 0.1 * NSHeight(charRect)) {
                            lineRect = NSUnionRect(lineRect, charRect);
                        } else {
                            if (lineRectTrimmingWhitespaceForPage(&lineRect, page)) {
                                [self addLineRect:lineRect];
                                NSArray *quadLine = createQuadPointsWithBounds(lineRect, [self bounds].origin);
                                [quadPoints addObjectsFromArray:quadLine];
                                [quadLine release];
                            }
                            lineRect = charRect;
                        }
                    }
                    if (NSEqualRects(lineRect, NSZeroRect) == NO && lineRectTrimmingWhitespaceForPage(&lineRect, page)) {
                        [self addLineRect:lineRect];
                        NSArray *quadLine = createQuadPointsWithBounds(lineRect, [self bounds].origin);
                        [quadPoints addObjectsFromArray:quadLine];
                        [quadLine release];
                    }
                }
                
            }
            [self setQuadrilateralPoints:quadPoints];
            [quadPoints release];
        }
    }
    return self;
}

- (void)dealloc
{
    if (lineRects) NSZoneFree([self zone], lineRects);
    [super dealloc];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    NSArray *quadPoints = createStringsFromPoints([self quadrilateralPoints]);
    [dict setValue:quadPoints forKey:@"quadrilateralPoints"];
    [quadPoints release];
    return dict;
}

- (void)regenerateLineRects {
    
    NSArray *quadPoints = [self quadrilateralPoints];
    NSAssert([quadPoints count] % 4 == 0, @"inconsistent number of quad points");

    unsigned j, jMax = [quadPoints count] / 4;
    
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
        lineRect.origin = points[2];
        lineRect.origin.x += [self bounds].origin.x;
        lineRect.origin.y += [self bounds].origin.y;
        [self addLineRect:lineRect];
    }
}

// this allows more precise hit testing of these annotations, since markup may not cover the entire bounds
- (BOOL)linesContainPoint:(NSPoint)point {
    // archived annotations (or annotations we didn't create) won't have these
    if (0 == numberOfLines)
        [self regenerateLineRects];
    
    unsigned i = numberOfLines;
    BOOL isContained = NO;
    while (i-- && NO == isContained)
        isContained = NSPointInRect(point, lineRects[i]);
    return isContained;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)shouldPrint { return YES; }

- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setContents:(NSString *)contents {
    [super setContents:contents];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setColor:(NSColor *)color {
    [super setColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

// fix a bug in PDFKit, the color space sometimes is not correct
- (void)drawWithBox:(CGPDFBox)box inContext:(CGContextRef)context {
    CGContextSaveGState(context);
    SKCGContextSetDefaultRGBColorSpace(context);
    
    [super drawWithBox:box inContext:context];
    
    CGContextRestoreGState(context);
}

@end

#pragma mark -

@implementation SKPDFAnnotationFreeText

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:SKTextNoteFontNameKey]
                                       size:[[NSUserDefaults standardUserDefaults] floatForKey:SKTextNoteFontSizeKey]];
        [self setFont:font];
        [self setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKFreeTextNoteColorKey]]];
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[self font] forKey:@"font"];
    return dict;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)isEditable { return YES; }

- (BOOL)shouldPrint { return YES; }

- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setContents:(NSString *)contents {
    [super setContents:contents];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setColor:(NSColor *)color {
    [super setColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setFont:(NSFont *)font {
    [super setFont:font];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

#pragma mark Scripting support

- (id)textContents {
    NSTextStorage *textContents = [[[NSTextStorage alloc] initWithString:[self contents]] autorelease];
    if ([self font])
        [textContents addAttribute:NSFontAttributeName value:[self font] range:NSMakeRange(0, [textContents length])];
    return [self contents] ? textContents : (id)[NSNull null];
}

@end

#pragma mark -

@implementation SKPDFAnnotationNote

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        [self setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKAnchoredNoteColorKey]]];
        texts = [[NSArray alloc] initWithObjects:[[[SKNoteText alloc] initWithAnnotation:self] autorelease], nil];
        textStorage = [[NSTextStorage allocWithZone:[self zone]] init];
        [textStorage setDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [textStorage release];
    [image release];
    [texts release];
    [super dealloc];
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[self text] forKey:@"text"];
    [dict setValue:[self image] forKey:@"image"];
    return dict;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)isEditable { return YES; }

- (BOOL)shouldPrint { return YES; }

- (void)setBounds:(NSRect)bounds {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"bounds", @"key", nil]];
    [super setBounds:bounds];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"bounds", @"key", nil]];
}

- (void)setContents:(NSString *)contents {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"contents", @"key", nil]];
    [super setContents:contents];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"contents", @"key", nil]];
}

- (void)setColor:(NSColor *)color {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"color", @"key", nil]];
    [super setColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"color", @"key", nil]];
}

- (NSString *)type {
    return @"Note";
}

- (NSImage *)image;
{
    return image;
}

- (void)setImage:(NSImage *)newImage;
{
    if (image != newImage) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
                object:self
              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"image", @"key", nil]];
        [image release];
        image = [newImage retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
                object:self
              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"image", @"key", nil]];
    }
}

- (NSAttributedString *)text;
{
    return [[[NSAttributedString allocWithZone:[self zone]] initWithAttributedString:textStorage] autorelease];
}

- (void)setText:(NSAttributedString *)newText;
{
    if (textStorage != newText) {
        [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withAttributedString:newText];
    }
}

- (NSArray *)texts {
    return texts;
}

- (void)textStorageWillProcessEditing:(NSNotification *)notification;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"text", @"key", nil]];
    [self willChangeValueForKey:@"text"];
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification;
{
    [self didChangeValueForKey:@"text"];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"text", @"key", nil]];
}

#pragma mark Scripting support

- (id)richText;
{
    return textStorage;
}

- (void)setRichText:(id)newText;
{
    if (newText != textStorage) {
        // We are willing to accept either a string or an attributed string.
        if ([newText isKindOfClass:[NSAttributedString class]])
            [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withAttributedString:newText];
        else
            [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:newText];
    }
}

- (id)coerceValueForRichText:(id)value;
{
    // We want to just get Strings unchanged.  We will detect this and do the right thing in setRichText.  We do this because, this way, we will do more reasonable things about attributes when we are receiving plain text.
    if ([value isKindOfClass:[NSString class]])
        return value;
    else
        return [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:value toClass:[NSTextStorage class]];
}

@end

#pragma mark -

// useful for highlighting things; isTemporaryAnnotation is so we know to remove it
@implementation SKPDFAnnotationTemporary

- (BOOL)isTemporaryAnnotation { return YES; }

- (BOOL)shouldPrint { return NO; }

@end

@implementation SKNoteText

- (id)initWithAnnotation:(PDFAnnotation *)anAnnotation {
    if (self = [super init]) {
        annotation = anAnnotation;
        rowHeight = 85.0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAnnotationDidChangeNotification:) 
                                                     name:SKAnnotationDidChangeNotification object:annotation];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (PDFAnnotation *)annotation {
    return annotation;
}

- (NSArray *)texts { return nil; }

- (NSString *)type { return nil; }

- (PDFPage *)page { return nil; }

- (unsigned int)pageIndex { return [annotation pageIndex]; }

- (NSAttributedString *)contents { return [annotation text]; }

- (float)rowHeight {
    return rowHeight;
}

- (void)setRowHeight:(float)newRowHeight {
    rowHeight = newRowHeight;
}

- (void)handleAnnotationDidChangeNotification:(NSNotification *)notification {
    if ([[[notification userInfo] objectForKey:@"key"] isEqualToString:@"text"]) {
        [self willChangeValueForKey:@"contents"];
        [self didChangeValueForKey:@"contents"];
    }
}

@end
