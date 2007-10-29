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
#import "PDFSelection_SKExtensions.h"
#import "SKPDFView.h"
#import "OBUtilities.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSString_SKExtensions.h"

enum {
    SKASTextNote = 'NTxt',
    SKASAnchoredNote = 'NAnc',
    SKASCircleNote = 'NCir',
    SKASSquareNote = 'NSqu',
    SKASHighlightNote = 'NHil',
    SKASUnderlineNote = 'NUnd',
    SKASStrikeOutNote = 'NStr',
    SKASLineNote = 'NLin'
};

enum {
    SKASTextAnnotationIconComment = 'ICmt',
    SKASTextAnnotationIconKey = 'IKey',
    SKASTextAnnotationIconNote = 'INot',
    SKASTextAnnotationIconHelp = 'IHlp',
    SKASTextAnnotationIconNewParagraph = 'INPa',
    SKASTextAnnotationIconParagraph = 'IPar',
    SKASTextAnnotationIconInsert = 'IIns'
};

enum {
    SKASLineStyleNone = 'LSNo',
    SKASLineStyleSquare = 'LSSq',
    SKASLineStyleCircle = 'LSCi',
    SKASLineStyleDiamond = 'LSDi',
    SKASLineStyleOpenArrow = 'LSOA',
    SKASLineStyleClosedArrow = 'LSCA'
};

enum {
    SKASBorderStyleSolid = 'Soli',
    SKASBorderStyleDashed = 'Dash',
    SKASBorderStyleBeveled = 'Bevl',
    SKASBorderStyleInset = 'Inst',
    SKASBorderStyleUnderline = 'Undl'
};

#define TYPE_KEY                    @"type"
#define BOUNDS_KEY                  @"bounds"
#define PAGE_INDEX_KEY              @"pageIndex"
#define CONTENTS_KEY                @"contents"
#define COLOR_KEY                   @"color"
#define LINE_WIDTH_KEY              @"lineWidth"
#define BORDER_STYLE_KEY            @"borderStyle"
#define DASH_PATTERN_KEY            @"dashPattern"
#define INTERIOR_COLOR_KEY          @"interiorColor"
#define QUADRILATERAL_POINTS_KEY    @"quadrilateralPoints"
#define FONT_KEY                    @"font"
#define ICON_TYPE_KEY               @"iconType"
#define TEXT_KEY                    @"text"
#define IMAGE_KEY                   @"image"
#define START_LINE_STYLE_KEY        @"startLineStyle"
#define END_LINE_STYLE_KEY          @"endLineStyle"
#define START_POINT_KEY             @"startPoint"
#define END_POINT_KEY               @"endPoint"

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


@interface PDFBorder (SKExtensions)
- (id)copyWithZone:(NSZone *)aZone;
@end

@implementation PDFBorder (SKExtensions)

- (id)copyWithZone:(NSZone *)aZone {
    PDFBorder *copy = [[PDFBorder alloc] init];
    [copy setDashPattern:[self dashPattern]];
    [copy setLineWidth:[self lineWidth]];
    [copy setDashPattern:[self dashPattern]];
    [copy setStyle:[self style]];
    [copy setHorizontalCornerRadius:[self horizontalCornerRadius]];
    [copy setVerticalCornerRadius:[self verticalCornerRadius]];
    return copy;
}

@end


@interface PDFAnnotationFreeText (SKPDFAnnotationFreeTextPrivateDeclarations)
- (int)rotation;
- (void)setRotation:(int)rotation;
@end


@interface PDFAnnotation (PDFAnnotationPrivateDeclarations)
- (void)drawWithBox:(CGPDFBox)box inContext:(CGContextRef)context;
- (void)setPage:(id)page;
@end


@interface PDFAnnotation (SKPDFAnnotationPrivate)
- (id)initWithBounds:(NSRect)bounds dictionary:(NSDictionary *)dict;
- (void)replacementSetBounds:(NSRect)bounds;
- (void)replacementSetContents:(NSString *)contents;
- (void)replacementSetColor:(NSColor *)color;
- (void)replacementSetBorder:(PDFBorder *)border;
@end


static IMP originalSetBounds = NULL;
static IMP originalSetContents = NULL;
static IMP originalSetColor = NULL;
static IMP originalSetBorder = NULL;

@implementation PDFAnnotation (SKExtensions)

+ (void)load {
    originalSetBounds = OBReplaceMethodImplementationWithSelector(self, @selector(setBounds:), @selector(replacementSetBounds:));
    originalSetContents = OBReplaceMethodImplementationWithSelector(self, @selector(setContents:), @selector(replacementSetContents:));
    originalSetColor = OBReplaceMethodImplementationWithSelector(self, @selector(setColor:), @selector(replacementSetColor:));
    originalSetBorder = OBReplaceMethodImplementationWithSelector(self, @selector(setBorder:), @selector(replacementSetBorder:));
}

- (id)initWithBounds:(NSRect)bounds dictionary:(NSDictionary *)dict{
    [[self initWithBounds:NSZeroRect] release];
    return nil;
}

- (id)initWithDictionary:(NSDictionary *)dict{
    [[self initWithBounds:NSZeroRect] release];
    
    NSString *type = [dict objectForKey:TYPE_KEY];
    NSRect bounds = NSRectFromString([dict objectForKey:BOUNDS_KEY]);
    Class annotationClass = NULL;
    
    if ([type isEqualToString:SKNoteString])
        annotationClass = [SKPDFAnnotationNote class];
    else if ([type isEqualToString:SKFreeTextString])
        annotationClass = [SKPDFAnnotationFreeText class];
    else if ([type isEqualToString:SKCircleString])
        annotationClass = [SKPDFAnnotationCircle class];
    else if ([type isEqualToString:SKSquareString])
        annotationClass = [SKPDFAnnotationSquare class];
    else if ([type isEqualToString:SKHighlightString] || [type isEqualToString:SKMarkUpString] || [type isEqualToString:SKUnderlineString] || [type isEqualToString:SKStrikeOutString])
        annotationClass = [SKPDFAnnotationMarkup class];
    else if ([type isEqualToString:SKLineString])
        annotationClass = [SKPDFAnnotationLine class];
    
    if (self = [[annotationClass alloc] initWithBounds:bounds dictionary:dict]) {
        NSString *contents = [dict objectForKey:CONTENTS_KEY];
        NSColor *color = [dict objectForKey:COLOR_KEY];
        NSNumber *lineWidth = [dict objectForKey:LINE_WIDTH_KEY];
        NSNumber *borderStyle = [dict objectForKey:BORDER_STYLE_KEY];
        NSArray *dashPattern = [dict objectForKey:DASH_PATTERN_KEY];
        
        if (contents)
            originalSetContents(self, @selector(setContents:), contents);
        if (color)
            originalSetColor(self, @selector(setColor:), color);
        if (lineWidth == nil && borderStyle == nil && dashPattern == nil) {
            if ([self border])
                originalSetBorder(self, @selector(setBorder:), nil);
        } else {
            if ([self border] == nil)
                originalSetBorder(self, @selector(setBorder:), [[[PDFBorder alloc] init] autorelease]);
            if (lineWidth)
                [[self border] setLineWidth:[lineWidth floatValue]];
            if (borderStyle)
                [[self border] setStyle:[lineWidth intValue]];
            if (dashPattern)
                [[self border] setDashPattern:dashPattern];
        }
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    [dict setValue:[self type] forKey:TYPE_KEY];
    [dict setValue:[self contents] forKey:CONTENTS_KEY];
    [dict setValue:[self color] forKey:COLOR_KEY];
    [dict setValue:NSStringFromRect([self bounds]) forKey:BOUNDS_KEY];
    [dict setValue:[NSNumber numberWithUnsignedInt:[self pageIndex]] forKey:PAGE_INDEX_KEY];
    if ([self border]) {
        [dict setValue:[NSNumber numberWithFloat:[[self border] lineWidth]] forKey:LINE_WIDTH_KEY];
        [dict setValue:[NSNumber numberWithInt:[[self border] style]] forKey:BORDER_STYLE_KEY];
        [dict setValue:[[self border] dashPattern] forKey:DASH_PATTERN_KEY];
    }
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *string = [NSMutableString string];
    NSRect bounds = [self bounds];
    float r, g, b, a = 0.0;
    PDFBorder *border = [self border];
    NSString *contents = [self contents];
    [[self color] getRed:&r green:&g blue:&b alpha:&a];
    [string appendString:@"/Type/Annot/Subtype/"];
    [string appendString:[[self type] isEqualToString:SKNoteString] ? SKTextString : [self type]];
    [string appendFormat:@"/Rect[%f %f %f %f]", NSMinX(bounds), NSMinY(bounds), NSMaxX(bounds), NSMaxY(bounds)];
    [string appendFormat:@"/Page %i", [self pageIndex]];
    [string appendString:@"/F 4"];
    if (a > 0.0)
        [string appendFormat:@"/C[%f %f %f]", r, g, b];
    if (border) {
        [string appendFormat:@"/BS<</W %f/S", [border lineWidth]];
        switch ([border style]) {
            case kPDFBorderStyleSolid:
                [string appendString:@"/S"];
                break;
            case kPDFBorderStyleDashed:
                [string appendString:@"/D"];
                break;
            case kPDFBorderStyleBeveled:
                [string appendString:@"/B"];
                break;
            case kPDFBorderStyleInset:
                [string appendString:@"/I"];
                break;
            case kPDFBorderStyleUnderline:
                [string appendString:@"/U"];
                break;
        }
        [string appendFormat:@"/D[%@]", [[[border dashPattern] valueForKey:@"stringValue"] componentsJoinedByString:@" "]];
        [string appendString:@">>"];
    } else {
        [string appendString:@"/BS<</W 0.0>>"];
    }
    [string appendString:@"/Contents("];
    [string appendString:contents ? [contents stringByEscapingParenthesis] : @""];
    if ([[self text] length]) {
        [string appendString:@"  "];
        [string appendString:[[[self text] string] stringByEscapingParenthesis]];
    }
    [string appendString:@")"];
    return string;
}

- (PDFDestination *)destination{
    NSRect bounds = [self bounds];
    NSPoint point = SKTopLeftPoint(bounds);
    return [[[PDFDestination alloc] initWithPage:[self page] atPoint:point] autorelease];
}

- (unsigned int)pageIndex {
    PDFPage *page = [self page];
    return page ? [page pageIndex] : NSNotFound;
}

- (int)noteType {
    if ([[self type] isEqualToString:SKFreeTextString])
        return SKFreeTextNote;
    else if ([[self type] isEqualToString:SKNoteString])
        return SKAnchoredNote;
    else if ([[self type] isEqualToString:SKCircleString])
        return SKCircleNote;
    else if ([[self type] isEqualToString:SKSquareString])
        return SKSquareNote;
    else if ([[self type] isEqualToString:SKHighlightString] || [[self type] isEqualToString:SKMarkUpString])
        return SKHighlightNote;
    else if ([[self type] isEqualToString:SKUnderlineString])
        return SKUnderlineNote;
    else if ([[self type] isEqualToString:SKStrikeOutString])
        return SKStrikeOutNote;
    else if ([[self type] isEqualToString:SKLineString])
        return SKLineNote;
    return 0;
}

- (PDFBorderStyle)borderStyle {
    return [[self border] style];
}

- (void)setBorderStyle:(PDFBorderStyle)style {
    PDFBorder *border = [[self border] copyWithZone:[self zone]];
    if (border == nil && style)
        border = [[PDFBorder allocWithZone:[self zone]] init];
    [border setStyle:style];
    [self setBorder:border];
    [border release];
}

- (float)lineWidth {
    return [[self border] lineWidth];
}

- (void)setLineWidth:(float)width {
    PDFBorder *border = nil;
    if (width > 0.0) {
        border = [[self border] copyWithZone:[self zone]];
        if (border == nil)
            border = [[PDFBorder allocWithZone:[self zone]] init];
        [border setLineWidth:width];
    } 
    [self setBorder:border];
    [border release];
}

- (NSArray *)dashPattern {
    return [[self border] dashPattern];
}

- (void)setDashPattern:(NSArray *)pattern {
    PDFBorder *border = [[self border] copyWithZone:[self zone]];
    if (border == nil && [pattern count])
        border = [[PDFBorder allocWithZone:[self zone]] init];
    [border setDashPattern:pattern];
    [self setBorder:border];
    [border release];
}

- (void)replacementSetBounds:(NSRect)bounds {
    if ([self isNoteAnnotation]) {
        [[[self undoManager] prepareWithInvocationTarget:self] setBounds:[self bounds]];
        [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification 
                object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"bounds", @"key", nil]];
    }
    originalSetBounds(self, _cmd, bounds);
    if ([self isNoteAnnotation])
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
                object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"bounds", @"key", nil]];
}

- (void)replacementSetContents:(NSString *)contents {
    if ([self isNoteAnnotation]) {
        [[[self undoManager] prepareWithInvocationTarget:self] setContents:[self contents]];
        [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    }
    originalSetContents(self, _cmd, contents);
    if ([self isNoteAnnotation])
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
                object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"contents", @"key", nil]];
}

- (void)replacementSetColor:(NSColor *)color {
    if ([self isNoteAnnotation]) {
        [[[self undoManager] prepareWithInvocationTarget:self] setColor:[self color]];
        [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    }
    originalSetColor(self, _cmd, color);
    if ([self isNoteAnnotation])
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
                object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"color", @"key", nil]];
}

- (void)replacementSetBorder:(PDFBorder *)border {
    if ([self isNoteAnnotation]) {
        PDFBorder *oldBorder = [[self border] copyWithZone:[self zone]];
        [[[self undoManager] prepareWithInvocationTarget:self] setBorder:oldBorder];
        [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
        [oldBorder release];
    }
    originalSetBorder(self, _cmd, border);
    if ([self isNoteAnnotation])
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
                object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"border", @"key", nil]];
}

- (NSImage *)image { return nil; }

- (NSAttributedString *)text { return nil; }

- (NSArray *)texts { return nil; }

- (NSColor *)interiorColor { return nil; }

- (BOOL)isNoteAnnotation { return NO; }

- (BOOL)isMarkupAnnotation { return NO; }

- (BOOL)isTemporaryAnnotation { return NO; }

- (BOOL)isResizable { return NO; }

- (BOOL)isMovable { return NO; }

- (BOOL)isEditable { return NO; }

- (BOOL)hitTest:(NSPoint)point {
    return [self shouldDisplay] ? NSPointInRect(point, [self bounds]) : NO;
}

- (NSUndoManager *)undoManager {
    return [[[self page] containingDocument] undoManager];
}

#pragma mark Scripting support

// to support the 'make' command
- (id)init {
    [[self initWithBounds:NSZeroRect] release];
    self = nil;
    NSScriptCommand *currentCommand = [NSScriptCommand currentCommand];
    if ([currentCommand isKindOfClass:[NSCreateCommand class]]) {
        unsigned long classCode = [[(NSCreateCommand *)currentCommand createClassDescription] appleEventCode];
        float defaultWidth = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteWidthKey];
        float defaultHeight = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteHeightKey];
       
        if (classCode == 'Note') {
            
            NSDictionary *properties = [(NSCreateCommand *)currentCommand resolvedKeyDictionary];
            int type = [[properties objectForKey:@"asNoteType"] intValue];
            
            if (type == 0) {
                [currentCommand setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
                [currentCommand setScriptErrorString:NSLocalizedString(@"New notes need a type.", @"Error description")];
            } else if (type == SKASHighlightNote || type == SKASStrikeOutNote || type == SKASUnderlineNote) {
                id selSpec = [properties objectForKey:@"selectionSpecifier"];
                PDFSelection *selection;
                int markupType = 0;
                
                if (selSpec == nil) {
                    [currentCommand setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
                    [currentCommand setScriptErrorString:NSLocalizedString(@"New markup notes need a selection.", @"Error description")];
                } else if (selection = [PDFSelection selectionWithSpecifier:selSpec]) {
                    if (type == SKASHighlightNote)
                        markupType = kPDFMarkupTypeHighlight;
                    else if (type == SKASUnderlineNote)
                        markupType = kPDFMarkupTypeUnderline;
                    else if (type == SKASStrikeOutNote)
                        markupType = kPDFMarkupTypeStrikeOut;
                    if (self = [[SKPDFAnnotationMarkup alloc] initWithSelection:selection markupType:markupType]) {
                        PDFPage *page = [[selection pages] objectAtIndex:0];
                        if (page && [self respondsToSelector:@selector(setPage:)])
                            [self performSelector:@selector(setPage:) withObject:page];
                    }
                }
            } else if (type == SKASTextNote) {
                self = [[SKPDFAnnotationFreeText alloc] initWithBounds:NSMakeRect(100.0, 100.0, defaultWidth, defaultHeight)];
            } else if (type == SKASAnchoredNote) {
                self = [[SKPDFAnnotationNote alloc] initWithBounds:NSMakeRect(100.0, 100.0, 16.0, 16.0)];
            } else if (type == SKASCircleNote) {
                self = [[SKPDFAnnotationCircle alloc] initWithBounds:NSMakeRect(100.0, 100.0, defaultWidth, defaultHeight)];
            } else if (type == SKASSquareNote) {
                self = [[SKPDFAnnotationSquare alloc] initWithBounds:NSMakeRect(100.0, 100.0, defaultWidth, defaultHeight)];
            } else if (type == SKASLineNote) {
                self = [[SKPDFAnnotationLine alloc] initWithBounds:NSMakeRect(100.0, 100.0, defaultWidth, defaultHeight)];
            }
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

// to support the 'duplicate' command
- (id)copyWithZone:(NSZone *)zone {
    if ([self isMovable]) // we don't want to duplicate markup
        return [[PDFAnnotation allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
    else
        return nil;
}

- (int)asNoteType {
    if ([[self type] isEqualToString:SKFreeTextString])
        return SKASTextNote;
    else if ([[self type] isEqualToString:SKNoteString])
        return SKASAnchoredNote;
    else if ([[self type] isEqualToString:SKCircleString])
        return SKASCircleNote;
    else if ([[self type] isEqualToString:SKSquareString])
        return SKASSquareNote;
    else if ([[self type] isEqualToString:SKHighlightString] || [[self type] isEqualToString:SKMarkUpString])
        return SKASHighlightNote;
    else if ([[self type] isEqualToString:SKUnderlineString])
        return SKASUnderlineNote;
    else if ([[self type] isEqualToString:SKStrikeOutString])
        return SKASStrikeOutNote;
    else if ([[self type] isEqualToString:SKLineString])
        return SKASLineNote;
    return 0;
}

- (int)asIconType {
    return SKASTextAnnotationIconNote;
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
    if ([inQDBoundsAsData length] == sizeof(Rect) && [self isMovable]) {
        const Rect *qdBounds = (const Rect *)[inQDBoundsAsData bytes];
        NSRect newBounds = NSRectFromRect(*qdBounds);
        if ([self isResizable] == NO) {
            newBounds.size = [self bounds].size;
        } else {
            if (NSWidth(newBounds) < 0.0)
                newBounds.size.width = 0.0;
            if (NSHeight(newBounds) < 0.0)
                newBounds.size.height = 0.0;
        }
        [self setBounds:newBounds];
    }

}

- (NSData *)boundsAsQDRect {
    Rect qdBounds = RectFromNSRect([self bounds]);
    return [NSData dataWithBytes:&qdBounds length:sizeof(Rect)];
}

- (NSString *)fontName {
    return (id)[NSNull null];
}

- (float)fontSize {
    return 0;
}

- (int)asBorderStyle {
    switch ([self borderStyle]) {
        case kPDFBorderStyleSolid: return SKASBorderStyleSolid;
        case kPDFBorderStyleDashed: return SKASBorderStyleDashed;
        case kPDFBorderStyleBeveled: return SKASBorderStyleBeveled;
        case kPDFBorderStyleInset: return SKASBorderStyleInset;
        case kPDFBorderStyleUnderline: return SKASBorderStyleUnderline;
        default: return SKASBorderStyleSolid;
    }
}

- (void)setAsBorderStyle:(int)borderStyle {
    PDFBorderStyle style = kPDFBorderStyleSolid;
    switch (borderStyle) {
        case SKASBorderStyleSolid: style = kPDFBorderStyleSolid; break;
        case SKASBorderStyleDashed: style = kPDFBorderStyleDashed; break;
        case SKASBorderStyleBeveled: style = kPDFBorderStyleBeveled; break;
        case SKASBorderStyleInset: style = kPDFBorderStyleInset; break;
        case SKASBorderStyleUnderline: style = kPDFBorderStyleUnderline; break;
    }
    [self setBorderStyle:style];
}

- (NSData *)startPointAsQDPoint {
    return (id)[NSNull null];
}

- (NSData *)endPointAsQDPoint {
    return (id)[NSNull null];
}

- (int)asStartLineStyle {
    return SKASLineStyleNone;
}

- (int)asEndLineStyle {
    return SKASLineStyleNone;
}

- (id)selectionSpecifier {
    return [NSNull null];
}

- (void)setSelectionSpecifier:(id)specifier {}

@end

#pragma mark -

@implementation SKPDFAnnotationCircle

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        [self setShouldPrint:YES];
        NSColor *color = [[NSUserDefaults standardUserDefaults] colorForKey:SKCircleNoteInteriorColorKey];
        if ([color alphaComponent] > 0.0)
            [super setInteriorColor:color];
        originalSetColor(self, @selector(setColor:), [[NSUserDefaults standardUserDefaults] colorForKey:SKCircleNoteColorKey]);
        [[self border] setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKCircleNoteLineWidthKey]];
        [[self border] setDashPattern:[[NSUserDefaults standardUserDefaults] arrayForKey:SKCircleNoteDashPatternKey]];
        [[self border] setStyle:[[NSUserDefaults standardUserDefaults] floatForKey:SKCircleNoteLineStyleKey]];
        rowHeight = 19.0;
    }
    return self;
}

- (id)initWithBounds:(NSRect)bounds dictionary:(NSDictionary *)dict{
    if (self = [self initWithBounds:bounds]) {
        NSColor *interiorColor = [dict objectForKey:INTERIOR_COLOR_KEY];
        if (interiorColor)
            [super setInteriorColor:interiorColor];
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[self interiorColor] forKey:INTERIOR_COLOR_KEY];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *string = [[[super fdfString] mutableCopy] autorelease];
    float r, g, b, a = 0.0;
    [[self interiorColor] getRed:&r green:&g blue:&b alpha:&a];
    if (a > 0.0)
        [string appendFormat:@"/IC[%f %f %f]", r, g, b];
    return string;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (void)setInteriorColor:(NSColor *)color {
    [[[self undoManager] prepareWithInvocationTarget:self] setInteriorColor:[self interiorColor]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [super setInteriorColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"interiorColor", @"key", nil]];
}

- (float)rowHeight {
    return rowHeight;
}

- (void)setRowHeight:(float)newRowHeight {
    rowHeight = newRowHeight;
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:@"richText", @"fontName", @"fontSize", @"asIconType", @"startPointAsQDPoint", @"endPointAsQDPoint", @"asStartLineStyle", @"asEndLineStyle", @"selectionSpecifier", nil]];
    return properties;
}

@end

#pragma mark -

@implementation SKPDFAnnotationSquare

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        [self setShouldPrint:YES];
        NSColor *color = [[NSUserDefaults standardUserDefaults] colorForKey:SKSquareNoteInteriorColorKey];
        if ([color alphaComponent] > 0.0)
            [super setInteriorColor:color];
        originalSetColor(self, @selector(setColor:), [[NSUserDefaults standardUserDefaults] colorForKey:SKSquareNoteColorKey]);
        [[self border] setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKSquareNoteLineWidthKey]];
        [[self border] setDashPattern:[[NSUserDefaults standardUserDefaults] arrayForKey:SKSquareNoteDashPatternKey]];
        [[self border] setStyle:[[NSUserDefaults standardUserDefaults] floatForKey:SKSquareNoteLineStyleKey]];
        rowHeight = 19.0;
    }
    return self;
}

- (id)initWithBounds:(NSRect)bounds dictionary:(NSDictionary *)dict{
    if (self = [self initWithBounds:bounds]) {
        NSColor *interiorColor = [dict objectForKey:INTERIOR_COLOR_KEY];
        if (interiorColor)
            [super setInteriorColor:interiorColor];
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[self interiorColor] forKey:INTERIOR_COLOR_KEY];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *string = [[[super fdfString] mutableCopy] autorelease];
    float r, g, b, a = 0.0;
    [[self interiorColor] getRed:&r green:&g blue:&b alpha:&a];
    if (a > 0.0)
        [string appendFormat:@"/IC[%f %f %f]", r, g, b];
    return string;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (void)setInteriorColor:(NSColor *)color {
    [[[self undoManager] prepareWithInvocationTarget:self] setInteriorColor:[self interiorColor]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [super setInteriorColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"interiorColor", @"key", nil]];
}

- (float)rowHeight {
    return rowHeight;
}

- (void)setRowHeight:(float)newRowHeight {
    rowHeight = newRowHeight;
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:@"richText", @"fontName", @"fontSize", @"asIconType", @"startPointAsQDPoint", @"endPointAsQDPoint", @"asStartLineStyle", @"asEndLineStyle", @"selectionSpecifier", nil]];
    return properties;
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
    NSRect r = NSOffsetRect(bounds, -origin.x, -origin.y);
    NSPoint p0 = SKTopLeftPoint(r);
    NSPoint p1 = SKTopRightPoint(r);
    NSPoint p2 = SKBottomLeftPoint(r);
    NSPoint p3 = SKBottomRightPoint(r);
    return [[NSArray alloc] initWithObjects:[NSValue valueWithPoint:p0], [NSValue valueWithPoint:p1], [NSValue valueWithPoint:p2], [NSValue valueWithPoint:p3], nil];
}

- (id)initWithBounds:(NSRect)bounds markupType:(int)type quadrilateralPointsAsStrings:(NSArray *)pointStrings {
    if (self = [super initWithBounds:bounds]) {
        [self setShouldPrint:YES];
        [self setMarkupType:type];
        
        NSString *colorKey = nil;
        switch (type) {
            case kPDFMarkupTypeHighlight: colorKey = SKHighlightNoteColorKey; break;
            case kPDFMarkupTypeUnderline: colorKey = SKUnderlineNoteColorKey; break;
            case kPDFMarkupTypeStrikeOut: colorKey = SKStrikeOutNoteColorKey; break;
        }
        if (colorKey)
            originalSetColor(self, @selector(setColor:), [[NSUserDefaults standardUserDefaults] colorForKey:colorKey]);
        
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
        
        rowHeight = 19.0;
    }
    return self;
}

- (id)initWithBounds:(NSRect)bounds {
    self = [self initWithBounds:bounds markupType:kPDFMarkupTypeHighlight quadrilateralPointsAsStrings:nil];
    return self;
}

- (id)initWithBounds:(NSRect)bounds dictionary:(NSDictionary *)dict{
    NSString *type = [dict objectForKey:TYPE_KEY];
    int markupType = kPDFMarkupTypeHighlight;
    if ([type isEqualToString:SKUnderlineString])
        markupType = kPDFMarkupTypeUnderline;
    else if ([type isEqualToString:SKStrikeOutString])
        markupType = kPDFMarkupTypeStrikeOut;
    return [self initWithBounds:bounds markupType:markupType quadrilateralPointsAsStrings:[dict objectForKey:QUADRILATERAL_POINTS_KEY]];
}

- (void)addLineRect:(NSRect)aRect {
    numberOfLines++;
    lineRects = NSZoneRealloc([self zone], lineRects, numberOfLines * sizeof(NSRect));
    lineRects[numberOfLines - 1] = aRect;
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
                            [self addLineRect:lineRect];
                            newBounds = NSUnionRect(lineRect, newBounds);
                        }
                        // ignore whitespace at the beginning of the new line
                        lineRect = nonWS ? charRect : NSZeroRect;
                   }
                }
            }
            if (NSIsEmptyRect(lineRect) == NO) {
                [self addLineRect:lineRect];
                newBounds = NSUnionRect(lineRect, newBounds);
            }
            if (NSIsEmptyRect(newBounds)) {
                [self release];
                self = nil;
            } else {
                [self setBounds:newBounds];
                for (i = 0; i < numberOfLines; i++) {
                    NSArray *quadLine = createQuadPointsWithBounds(lineRects[i], [self bounds].origin);
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
    if (lineRects) NSZoneFree([self zone], lineRects);
    [super dealloc];
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    NSArray *quadPoints = createStringsFromPoints([self quadrilateralPoints]);
    [dict setValue:quadPoints forKey:QUADRILATERAL_POINTS_KEY];
    [quadPoints release];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *string = [[[super fdfString] mutableCopy] autorelease];
    NSEnumerator *pointEnum = [[self quadrilateralPoints] objectEnumerator];
    NSValue *value;
    NSPoint point;
    NSRect bounds = [self bounds];
    [string appendString:@"/QuadPoints["];
    while (value = [pointEnum nextObject]) {
        point = [value pointValue];
        [string appendFormat:@"%f %f ", point.x + NSMinX(bounds), point.y + NSMinY(bounds)];
    }
    [string appendString:@"]"];
    return string;
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
        lineRect.origin = SKAddPoints(points[2], [self bounds].origin);
        [self addLineRect:lineRect];
    }
}

- (PDFSelection *)selection {
    if (0 == numberOfLines)
        [self regenerateLineRects];
    
    PDFSelection *sel, *selection = nil;
    unsigned i;
    
    for (i = 0; i < numberOfLines; i++) {
        // slightly outset the rect to avoid rounding errors, as selectionForRect is pretty strict
        if (sel = [[self page] selectionForRect:NSInsetRect(lineRects[i], -1.0, -1.0)]) {
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
    if (0 == numberOfLines)
        [self regenerateLineRects];
    
    unsigned i = numberOfLines;
    BOOL isContained = NO;
    
    while (i-- && NO == isContained)
        isContained = NSPointInRect(point, lineRects[i]);
    
    return isContained;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isMarkupAnnotation { return YES; }

// fix a bug in PDFKit, the color space sometimes is not correct
- (void)drawWithBox:(CGPDFBox)box inContext:(CGContextRef)context {
    if (floor(NSAppKitVersionNumber) <= 824) {
        CGContextSaveGState(context);
        SKCGContextSetDefaultRGBColorSpace(context);
    }
    [super drawWithBox:box inContext:context];
    if (floor(NSAppKitVersionNumber) <= 824) {
        CGContextRestoreGState(context);
    }
}

- (float)rowHeight {
    return rowHeight;
}

- (void)setRowHeight:(float)newRowHeight {
    rowHeight = newRowHeight;
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:@"richText", @"fontName", @"fontSize", @"asIconType", @"lineWidth", @"asBorderStyle", @"dashPattern", @"startPointAsQDPoint", @"endPointAsQDPoint", @"asStartLineStyle", @"asEndLineStyle", nil]];
    return properties;
}

- (id)selectionSpecifier {
    PDFSelection *sel = [self selection];
    return sel ? [sel objectSpecifier] : [NSArray array];
}

@end

#pragma mark -

@implementation SKPDFAnnotationFreeText

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        [self setShouldPrint:YES];
        NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:SKTextNoteFontNameKey]
                                       size:[[NSUserDefaults standardUserDefaults] floatForKey:SKTextNoteFontSizeKey]];
        [super setFont:font];
        originalSetColor(self, @selector(setColor:), [[NSUserDefaults standardUserDefaults] colorForKey:SKFreeTextNoteColorKey]);
        PDFBorder *border = [[PDFBorder allocWithZone:[self zone]] init];
        [border setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKFreeTextNoteLineWidthKey]];
        [border setDashPattern:[[NSUserDefaults standardUserDefaults] arrayForKey:SKFreeTextNoteDashPatternKey]];
        [border setStyle:[[NSUserDefaults standardUserDefaults] floatForKey:SKFreeTextNoteLineStyleKey]];
        originalSetBorder(self, @selector(setBorder:), [border lineWidth] > 0.0 ? border : nil);
        [border release];
        rowHeight = 19.0;
    }
    return self;
}

- (id)initWithBounds:(NSRect)bounds dictionary:(NSDictionary *)dict{
    if (self = [self initWithBounds:bounds]) {
        NSFont *font = [dict objectForKey:FONT_KEY];
        NSNumber *rotation = [dict objectForKey:@"rotation"];
        if (font)
            [super setFont:font];
        if (rotation && [self respondsToSelector:@selector(setRotation:)])
            [self setRotation:[rotation intValue]];
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[self font] forKey:FONT_KEY];
    if ([self respondsToSelector:@selector(rotation)])
        [dict setValue:[NSNumber numberWithInt:[self rotation]] forKey:@"rotation"];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *string = [[[super fdfString] mutableCopy] autorelease];
    [string appendFormat:@"/DA(/%@ %f Tf)/DS(font: %@ %fpt)", [[self font] fontName], [[self font] pointSize], [[self font] fontName], [[self font] pointSize]];
    return string;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)isEditable { return YES; }

- (void)setFont:(NSFont *)font {
    [[[self undoManager] prepareWithInvocationTarget:self] setFont:[self font]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [super setFont:font];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"font", @"key", nil]];
}

- (float)rowHeight {
    return rowHeight;
}

- (void)setRowHeight:(float)newRowHeight {
    rowHeight = newRowHeight;
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:@"richText", @"asIconType", @"startPointAsQDPoint", @"endPointAsQDPoint", @"asStartLineStyle", @"asEndLineStyle", @"selectionSpecifier", nil]];
    return properties;
}

- (id)textContents {
    NSTextStorage *textContents = [[[NSTextStorage alloc] initWithString:[self contents]] autorelease];
    if ([self font])
        [textContents addAttribute:NSFontAttributeName value:[self font] range:NSMakeRange(0, [textContents length])];
    return [self contents] ? textContents : (id)[NSNull null];
}

- (NSString *)fontName {
    return [[self font] fontName];
}

- (void)setFontName:(NSString *)fontName {
    NSFont *font = [NSFont fontWithName:fontName size:[[self font] pointSize]];
    if (font)
        [self setFont:font];
}

- (float)fontSize {
    return [[self font] pointSize];
}

- (void)setFontSize:(float)pointSize {
    NSFont *font = [NSFont fontWithName:[[self font] fontName] size:pointSize];
    if (font)
        [self setFont:font];
}

@end

#pragma mark -

@implementation SKPDFAnnotationNote

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        [self setShouldPrint:YES];
        originalSetColor(self, @selector(setColor:), [[NSUserDefaults standardUserDefaults] colorForKey:SKAnchoredNoteColorKey]);
        [super setIconType:[[NSUserDefaults standardUserDefaults] integerForKey:SKAnchoredNoteIconTypeKey]];
        texts = [[NSArray alloc] initWithObjects:[[[SKNoteText alloc] initWithAnnotation:self] autorelease], nil];
        textStorage = [[NSTextStorage allocWithZone:[self zone]] init];
        [textStorage setDelegate:self];
        text = [[NSAttributedString alloc] init];
        rowHeight = 19.0;
    }
    return self;
}

- (id)initWithBounds:(NSRect)bounds dictionary:(NSDictionary *)dict{
    if (self = [self initWithBounds:bounds]) {
        NSAttributedString *aText = [dict objectForKey:TEXT_KEY];
        NSImage *anImage = [dict objectForKey:IMAGE_KEY];
        NSNumber *iconType = [dict objectForKey:ICON_TYPE_KEY];
        if (anImage)
            image = [anImage retain];
        if (aText)
            [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withAttributedString:aText];
        if (iconType)
            [super setIconType:[iconType intValue]];
    }
    return self;
}

- (void)dealloc {
    [textStorage release];
    [text release];
    [image release];
    [texts release];
    [super dealloc];
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[NSNumber numberWithInt:[self iconType]] forKey:ICON_TYPE_KEY];
    [dict setValue:[self text] forKey:TEXT_KEY];
    [dict setValue:[self image] forKey:IMAGE_KEY];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *string = [[[super fdfString] mutableCopy] autorelease];
    [string appendString:@"/Name"];
    switch ([self iconType]) {
        case kPDFTextAnnotationIconComment:
            [string appendString:@"/Comment"];
            break;
        case kPDFTextAnnotationIconKey:
            [string appendString:@"/Key"];
            break;
        case kPDFTextAnnotationIconNote:
            [string appendString:@"/Note"];
            break;
        case kPDFTextAnnotationIconNewParagraph:
            [string appendString:@"/NewParagraph"];
            break;
        case kPDFTextAnnotationIconParagraph:
            [string appendString:@"/Paragraph"];
            break;
        case kPDFTextAnnotationIconInsert:
            [string appendString:@"/Insert"];
            break;
    }
    return string;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)isEditable { return YES; }

- (NSString *)type {
    return SKNoteString;
}

- (void)setIconType:(PDFTextAnnotationIconType)type;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIconType:[self iconType]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [super setIconType:type];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"iconType", @"key", nil]];
}

- (NSImage *)image;
{
    return image;
}

- (void)setImage:(NSImage *)newImage;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setImage:[self image]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    if (image != newImage) {
        [image release];
        image = [newImage retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
                object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"image", @"key", nil]];
    }
}

- (NSAttributedString *)text;
{
    return text;
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
    [[[self undoManager] prepareWithInvocationTarget:self] setText:text];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [self willChangeValueForKey:@"text"];
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification;
{
    [self didChangeValueForKey:@"text"];
    [text release];
    text = [[NSAttributedString allocWithZone:[self zone]] initWithAttributedString:textStorage];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"text", @"key", nil]];
}

- (float)rowHeight {
    return rowHeight;
}

- (void)setRowHeight:(float)newRowHeight {
    rowHeight = newRowHeight;
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:@"fontName", @"fontSize", @"lineWidth", @"asBorderStyle", @"dashPattern", @"startPointAsQDPoint", @"endPointAsQDPoint", @"asStartLineStyle", @"asEndLineStyle", @"selectionSpecifier", nil]];
    return properties;
}

- (int)asIconType {
    switch ([self iconType]) {
        case kPDFTextAnnotationIconComment: return SKASTextAnnotationIconComment;
        case kPDFTextAnnotationIconKey: return SKASTextAnnotationIconKey;
        case kPDFTextAnnotationIconNote: return SKASTextAnnotationIconNote;
        case kPDFTextAnnotationIconHelp: return SKASTextAnnotationIconHelp;
        case kPDFTextAnnotationIconNewParagraph: return SKASTextAnnotationIconNewParagraph;
        case kPDFTextAnnotationIconParagraph: return SKASTextAnnotationIconParagraph;
        case kPDFTextAnnotationIconInsert: return SKASTextAnnotationIconInsert;
        default: return kPDFTextAnnotationIconNote;
    }
}

- (void)setAsIconType:(int)type {
    PDFTextAnnotationIconType iconType = SKASTextAnnotationIconNote;
    switch (type) {
        case SKASTextAnnotationIconComment: iconType = kPDFTextAnnotationIconComment; break;
        case SKASTextAnnotationIconKey: iconType = kPDFTextAnnotationIconKey; break;
        case SKASTextAnnotationIconNote: iconType = kPDFTextAnnotationIconNote; break;
        case SKASTextAnnotationIconHelp: iconType = kPDFTextAnnotationIconHelp; break;
        case SKASTextAnnotationIconNewParagraph: iconType = kPDFTextAnnotationIconNewParagraph; break;
        case SKASTextAnnotationIconParagraph: iconType = kPDFTextAnnotationIconParagraph; break;
        case SKASTextAnnotationIconInsert: iconType = kPDFTextAnnotationIconInsert; break;
    }
    [self setIconType:iconType];
}

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

@implementation SKPDFAnnotationLine

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        originalSetColor(self, @selector(setColor:), [[NSUserDefaults standardUserDefaults] colorForKey:SKLineNoteColorKey]);
        [super setStartLineStyle:[[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteStartLineStyleKey]];
        [super setEndLineStyle:[[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteEndLineStyleKey]];
        [super setStartPoint:NSMakePoint(0.0, 0.0)];
        [super setEndPoint:NSMakePoint(NSWidth(bounds), NSHeight(bounds))];
        PDFBorder *border = [[PDFBorder allocWithZone:[self zone]] init];
        [border setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKLineNoteLineWidthKey]];
        [border setDashPattern:[[NSUserDefaults standardUserDefaults] arrayForKey:SKLineNoteDashPatternKey]];
        [border setStyle:[[NSUserDefaults standardUserDefaults] floatForKey:SKLineNoteLineStyleKey]];
        originalSetBorder(self, @selector(setBorder:), [border lineWidth] > 0.0 ? border : nil);
        [border release];
        rowHeight = 19.0;
    }
    return self;
}

- (id)initWithBounds:(NSRect)bounds dictionary:(NSDictionary *)dict{
    if (self = [self initWithBounds:bounds]) {
        NSString *point;
        NSNumber *startLineStyle = [dict objectForKey:START_LINE_STYLE_KEY];
        NSNumber *endLineStyle = [dict objectForKey:END_LINE_STYLE_KEY];
        if (point = [dict objectForKey:START_POINT_KEY])
            [super setStartPoint:NSPointFromString(point)];
        if (point = [dict objectForKey:END_POINT_KEY])
            [super setEndPoint:NSPointFromString(point)];
        if (startLineStyle)
            [super setStartLineStyle:[startLineStyle intValue]];
        if (endLineStyle)
            [super setEndLineStyle:[endLineStyle intValue]];
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[NSNumber numberWithInt:[self startLineStyle]] forKey:START_LINE_STYLE_KEY];
    [dict setValue:[NSNumber numberWithInt:[self endLineStyle]] forKey:END_LINE_STYLE_KEY];
    [dict setValue:NSStringFromPoint([self startPoint]) forKey:START_POINT_KEY];
    [dict setValue:NSStringFromPoint([self endPoint]) forKey:END_POINT_KEY];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *string = [[[super fdfString] mutableCopy] autorelease];
    [string appendString:@"/LE["];
    switch ([self startLineStyle]) {
        case kPDFLineStyleNone:
            [string appendString:@"/None"];
            break;
        case kPDFLineStyleSquare:
            [string appendString:@"/Square"];
            break;
        case kPDFLineStyleCircle:
            [string appendString:@"/Circle"];
            break;
        case kPDFLineStyleDiamond:
            [string appendString:@"/Diamond"];
            break;
        case kPDFLineStyleOpenArrow:
            [string appendString:@"/OpenArrow"];
            break;
        case kPDFLineStyleClosedArrow:
            [string appendString:@"/ClosedArrow"];
            break;
        default:
            [string appendString:@"/None"];
            break;
    }
    switch ([self endLineStyle]) {
        case kPDFLineStyleNone:
            [string appendString:@"/None"];
            break;
        case kPDFLineStyleSquare:
            [string appendString:@"/Square"];
            break;
        case kPDFLineStyleCircle:
            [string appendString:@"/Circle"];
            break;
        case kPDFLineStyleDiamond:
            [string appendString:@"/Diamond"];
            break;
        case kPDFLineStyleOpenArrow:
            [string appendString:@"/OpenArrow"];
            break;
        case kPDFLineStyleClosedArrow:
            [string appendString:@"/ClosedArrow"];
            break;
        default:
            [string appendString:@"/None"];
            break;
    }
    [string appendString:@"]"];
    return string;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (void)setStartPoint:(NSPoint)point {
    [[[self undoManager] prepareWithInvocationTarget:self] setStartPoint:[self startPoint]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [super setStartPoint:point];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"startPoint", @"key", nil]];
}

- (void)setEndPoint:(NSPoint)point {
    [[[self undoManager] prepareWithInvocationTarget:self] setEndPoint:[self endPoint]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [super setEndPoint:point];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"endPoint", @"key", nil]];
}

- (void)setStartLineStyle:(PDFLineStyle)startLineStyle {
    [[[self undoManager] prepareWithInvocationTarget:self] setStartLineStyle:[self startLineStyle]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [super setStartLineStyle:startLineStyle];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"startLineStyle", @"key", nil]];
}

- (void)setEndLineStyle:(PDFLineStyle)endLineStyle {
    [[[self undoManager] prepareWithInvocationTarget:self] setEndLineStyle:[self endLineStyle]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [super setEndLineStyle:endLineStyle];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"endLineStyle", @"key", nil]];
}

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

- (float)rowHeight {
    return rowHeight;
}

- (void)setRowHeight:(float)newRowHeight {
    rowHeight = newRowHeight;
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:@"richText", @"fontName", @"fontSize", @"asIconType", @"lineWidth", @"asBorderStyle", @"dashPattern", @"selectionSpecifier", nil]];
    return properties;
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

- (int)asStartLineStyle {
    switch ([self startLineStyle]) {
        case kPDFLineStyleNone: return SKASLineStyleNone;
        case kPDFLineStyleSquare: return SKASLineStyleSquare;
        case kPDFLineStyleCircle: return SKASLineStyleCircle;
        case kPDFLineStyleDiamond: return SKASLineStyleDiamond;
        case kPDFLineStyleOpenArrow: return SKASLineStyleOpenArrow;
        case kPDFLineStyleClosedArrow: return SKASLineStyleClosedArrow;
        default: return SKASLineStyleNone;
    }
}

- (int)asEndLineStyle {
    switch ([self endLineStyle]) {
        case kPDFLineStyleNone: return SKASLineStyleNone;
        case kPDFLineStyleSquare: return SKASLineStyleSquare;
        case kPDFLineStyleCircle: return SKASLineStyleCircle;
        case kPDFLineStyleDiamond: return SKASLineStyleDiamond;
        case kPDFLineStyleOpenArrow: return SKASLineStyleOpenArrow;
        case kPDFLineStyleClosedArrow: return SKASLineStyleClosedArrow;
        default: return SKASLineStyleNone;
    }
}

- (void)setAsStartLineStyle:(int)style {
    int startLineStyle = 0;
    switch (style) {
        case SKASLineStyleNone: startLineStyle = kPDFLineStyleNone; break;
        case SKASLineStyleSquare: startLineStyle = kPDFLineStyleSquare; break;
        case SKASLineStyleCircle: startLineStyle = kPDFLineStyleCircle; break;
        case SKASLineStyleDiamond: startLineStyle = kPDFLineStyleDiamond; break;
        case SKASLineStyleOpenArrow: startLineStyle = kPDFLineStyleOpenArrow; break;
        case SKASLineStyleClosedArrow: startLineStyle = kPDFLineStyleClosedArrow; break;
    }
    [self setStartLineStyle:startLineStyle];
}

- (void)setAsEndLineStyle:(int)style {
    int endLineStyle = 0;
    switch (style) {
        case SKASLineStyleNone: endLineStyle = kPDFLineStyleNone; break;
        case SKASLineStyleSquare: endLineStyle = kPDFLineStyleSquare; break;
        case SKASLineStyleCircle: endLineStyle = kPDFLineStyleCircle; break;
        case SKASLineStyleDiamond: endLineStyle = kPDFLineStyleDiamond; break;
        case SKASLineStyleOpenArrow: endLineStyle = kPDFLineStyleOpenArrow; break;
        case SKASLineStyleClosedArrow: endLineStyle = kPDFLineStyleClosedArrow; break;
    }
    [self setEndLineStyle:endLineStyle];
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
