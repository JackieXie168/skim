//
//  SKPDFAnnotationNote.m
//  Skim
//
//  Created by Christiaan Hofman on 2/6/07.
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

#import "SKPDFAnnotationNote.h"
#import "SKStringConstants.h"
#import "PDFPage_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "SKPDFView.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSString_SKExtensions.h"

enum {
    SKScriptingTextNote = 'NTxt',
    SKScriptingAnchoredNote = 'NAnc',
    SKScriptingCircleNote = 'NCir',
    SKScriptingSquareNote = 'NSqu',
    SKScriptingHighlightNote = 'NHil',
    SKScriptingUnderlineNote = 'NUnd',
    SKScriptingStrikeOutNote = 'NStr',
    SKScriptingLineNote = 'NLin'
};

enum {
    SKScriptingTextAnnotationIconComment = 'ICmt',
    SKScriptingTextAnnotationIconKey = 'IKey',
    SKScriptingTextAnnotationIconNote = 'INot',
    SKScriptingTextAnnotationIconHelp = 'IHlp',
    SKScriptingTextAnnotationIconNewParagraph = 'INPa',
    SKScriptingTextAnnotationIconParagraph = 'IPar',
    SKScriptingTextAnnotationIconInsert = 'IIns'
};

enum {
    SKScriptingLineStyleNone = 'LSNo',
    SKScriptingLineStyleSquare = 'LSSq',
    SKScriptingLineStyleCircle = 'LSCi',
    SKScriptingLineStyleDiamond = 'LSDi',
    SKScriptingLineStyleOpenArrow = 'LSOA',
    SKScriptingLineStyleClosedArrow = 'LSCA'
};

enum {
    SKScriptingBorderStyleSolid = 'Soli',
    SKScriptingBorderStyleDashed = 'Dash',
    SKScriptingBorderStyleBeveled = 'Bevl',
    SKScriptingBorderStyleInset = 'Inst',
    SKScriptingBorderStyleUnderline = 'Undl'
};

int SKScriptingBorderStyleFromBorderStyle(int borderStyle) {
    switch (borderStyle) {
        case kPDFBorderStyleSolid: return SKScriptingBorderStyleSolid;
        case kPDFBorderStyleDashed: return SKScriptingBorderStyleDashed;
        case kPDFBorderStyleBeveled: return SKScriptingBorderStyleBeveled;
        case kPDFBorderStyleInset: return SKScriptingBorderStyleInset;
        case kPDFBorderStyleUnderline: return SKScriptingBorderStyleUnderline;
        default: return SKScriptingBorderStyleSolid;
    }
}

int SKBorderStyleFromScriptingBorderStyle(int borderStyle) {
    switch (borderStyle) {
        case SKScriptingBorderStyleSolid: return kPDFBorderStyleSolid;
        case SKScriptingBorderStyleDashed: return kPDFBorderStyleDashed;
        case SKScriptingBorderStyleBeveled: return kPDFBorderStyleBeveled;
        case SKScriptingBorderStyleInset: return kPDFBorderStyleInset;
        case SKScriptingBorderStyleUnderline: return kPDFBorderStyleUnderline;
        default: return kPDFBorderStyleSolid;
    }
}

int SKScriptingLineStyleFromLineStyle(int lineStyle) {
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

int SKLineStyleFromScriptingLineStyle(int lineStyle) {
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

int SKScriptingIconTypeFromIconType(int iconType) {
    switch (iconType) {
        case kPDFTextAnnotationIconComment: return SKScriptingTextAnnotationIconComment;
        case kPDFTextAnnotationIconKey: return SKScriptingTextAnnotationIconKey;
        case kPDFTextAnnotationIconNote: return SKScriptingTextAnnotationIconNote;
        case kPDFTextAnnotationIconHelp: return SKScriptingTextAnnotationIconHelp;
        case kPDFTextAnnotationIconNewParagraph: return SKScriptingTextAnnotationIconNewParagraph;
        case kPDFTextAnnotationIconParagraph: return SKScriptingTextAnnotationIconParagraph;
        case kPDFTextAnnotationIconInsert: return SKScriptingTextAnnotationIconInsert;
        default: return kPDFTextAnnotationIconNote;
    }
}

int SKIconTypeFromScriptingIconType(int iconType) {
    switch (iconType) {
        case SKScriptingTextAnnotationIconComment: return kPDFTextAnnotationIconComment;
        case SKScriptingTextAnnotationIconKey: return kPDFTextAnnotationIconKey;
        case SKScriptingTextAnnotationIconNote: return kPDFTextAnnotationIconNote;
        case SKScriptingTextAnnotationIconHelp: return kPDFTextAnnotationIconHelp;
        case SKScriptingTextAnnotationIconNewParagraph: return kPDFTextAnnotationIconNewParagraph;
        case SKScriptingTextAnnotationIconParagraph: return kPDFTextAnnotationIconParagraph;
        case SKScriptingTextAnnotationIconInsert: return kPDFTextAnnotationIconInsert;
        default: return kPDFTextAnnotationIconNote;
    }
}

NSString *SKPDFAnnotationTypeKey = @"type";
NSString *SKPDFAnnotationBoundsKey = @"bounds";
NSString *SKPDFAnnotationPageIndexKey = @"pageIndex";
NSString *SKPDFAnnotationContentsKey = @"contents";
NSString *SKPDFAnnotationStringKey = @"string";
NSString *SKPDFAnnotationColorKey = @"color";
NSString *SKPDFAnnotationBorderKey = @"border";
NSString *SKPDFAnnotationLineWidthKey = @"lineWidth";
NSString *SKPDFAnnotationBorderStyleKey = @"borderStyle";
NSString *SKPDFAnnotationDashPatternKey = @"dashPattern";

NSString *SKPDFAnnotationInteriorColorKey = @"interiorColor";

NSString *SKPDFAnnotationQuadrilateralPointsKey = @"quadrilateralPoints";

NSString *SKPDFAnnotationFontKey = @"font";
NSString *SKPDFAnnotationFontNameKey = @"fontName";
NSString *SKPDFAnnotationFontSizeKey = @"fontSize";
NSString *SKPDFAnnotationRotationKey = @"rotation";

NSString *SKPDFAnnotationIconTypeKey = @"iconType";
NSString *SKPDFAnnotationTextKey = @"text";
NSString *SKPDFAnnotationImageKey = @"image";

NSString *SKPDFAnnotationStartLineStyleKey = @"startLineStyle";
NSString *SKPDFAnnotationEndLineStyleKey = @"endLineStyle";
NSString *SKPDFAnnotationStartPointKey = @"startPoint";
NSString *SKPDFAnnotationEndPointKey = @"endPoint";

static NSString *SKPDFAnnotationScriptingNoteTypeKey = @"scriptingNoteType";
static NSString *SKPDFAnnotationScriptingIconTypeKey = @"scriptingIconType";
static NSString *SKPDFAnnotationRichTextKey = @"richText";
static NSString *SKPDFAnnotationStartPointAsQDPointKey = @"startPointAsQDPoint";
static NSString *SKPDFAnnotationEndPointAsQDPointKey = @"endPointAsQDPoint";
static NSString *SKPDFAnnotationScriptingStartLineStyleKey = @"scriptingStartLineStyle";
static NSString *SKPDFAnnotationScriptingEndLineStyleKey = @"scriptingEndLineStyle";
static NSString *SKPDFAnnotationSelectionSpecifierKey = @"selectionSpecifier";
static NSString *SKPDFAnnotationScriptingBorderStyleKey = @"scriptingBorderStyle";

void SKCGContextSetDefaultRGBColorSpace(CGContextRef context) {
    CMProfileRef profile;
    CMGetDefaultProfileBySpace(cmRGBData, &profile);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithPlatformColorSpace(profile);
    
    CMCloseProfile(profile);
    CGContextSetStrokeColorSpace(context, colorSpace);
    CGContextSetFillColorSpace(context, colorSpace);
    CGColorSpaceRelease(colorSpace);
}


@interface PDFBorder (SKExtensions) <NSCopying>
@end

@implementation PDFBorder (SKExtensions)

- (id)copyWithZone:(NSZone *)aZone {
    PDFBorder *copy = [[PDFBorder allocWithZone:aZone] init];
    [copy setLineWidth:[self lineWidth]];
    [copy setDashPattern:[[[self dashPattern] copyWithZone:aZone] autorelease]];
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


@implementation PDFAnnotation (SKExtensions)

- (id)initWithBounds:(NSRect)bounds dictionary:(NSDictionary *)dict{
    [[self initWithBounds:NSZeroRect] release];
    return nil;
}

- (id)initWithDictionary:(NSDictionary *)dict{
    Class stringClass = [NSString class];
    
    if ([self class] == [PDFAnnotation class]) {
        // generic, initalize the class for the type in the dictionary
        NSString *type = [dict objectForKey:SKPDFAnnotationTypeKey];
        Class annotationClass = NULL;
        
        if ([type isKindOfClass:stringClass] == NO)
            annotationClass = Nil;
        if ([type isEqualToString:SKNoteString] || [type isEqualToString:SKTextString])
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
        
        [[self initWithBounds:NSZeroRect] release];
        self = [[annotationClass alloc] initWithDictionary:dict];
        
    } else {
        // called from the initialization of a subclass
        NSString *boundsString = [dict objectForKey:SKPDFAnnotationBoundsKey];
        NSRect bounds = [boundsString isKindOfClass:stringClass] ? NSRectFromString(boundsString) : NSZeroRect;
        if (self = [self initWithBounds:bounds]) {
            Class colorClass = [NSColor class];
            Class arrayClass = [NSArray class];
            NSString *contents = [dict objectForKey:SKPDFAnnotationContentsKey];
            NSColor *color = [dict objectForKey:SKPDFAnnotationColorKey];
            NSNumber *lineWidth = [dict objectForKey:SKPDFAnnotationLineWidthKey];
            NSNumber *borderStyle = [dict objectForKey:SKPDFAnnotationBorderStyleKey];
            NSArray *dashPattern = [dict objectForKey:SKPDFAnnotationDashPatternKey];
            
            if ([contents isKindOfClass:stringClass])
                [self setString:contents];
            if ([color isKindOfClass:colorClass])
                [self setColor:color];
            if (lineWidth == nil && borderStyle == nil && dashPattern == nil) {
                if ([self border])
                    [self setBorder:nil];
            } else {
                if ([self border] == nil)
                    [self setBorder:[[[PDFBorder alloc] init] autorelease]];
                if ([lineWidth respondsToSelector:@selector(floatValue)])
                    [[self border] setLineWidth:[lineWidth floatValue]];
                if ([borderStyle respondsToSelector:@selector(intValue)])
                    [[self border] setStyle:[lineWidth intValue]];
                if ([dashPattern isKindOfClass:arrayClass])
                    [[self border] setDashPattern:dashPattern];
            }
        }
        
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    [dict setValue:[self type] forKey:SKPDFAnnotationTypeKey];
    [dict setValue:[self string] forKey:SKPDFAnnotationContentsKey];
    [dict setValue:[self color] forKey:SKPDFAnnotationColorKey];
    [dict setValue:NSStringFromRect([self bounds]) forKey:SKPDFAnnotationBoundsKey];
    [dict setValue:[NSNumber numberWithUnsignedInt:[self pageIndex]] forKey:SKPDFAnnotationPageIndexKey];
    if ([self border]) {
        [dict setValue:[NSNumber numberWithFloat:[[self border] lineWidth]] forKey:SKPDFAnnotationLineWidthKey];
        [dict setValue:[NSNumber numberWithInt:[[self border] style]] forKey:SKPDFAnnotationBorderStyleKey];
        [dict setValue:[[self border] dashPattern] forKey:SKPDFAnnotationDashPatternKey];
    }
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [NSMutableString string];
    NSRect bounds = [self bounds];
    float r, g, b, a = 0.0;
    PDFBorder *border = [self border];
    NSString *contents = [self contents];
    [[self color] getRed:&r green:&g blue:&b alpha:&a];
    [fdfString appendString:@"/Type/Annot/Subtype/"];
    [fdfString appendString:[[self type] isEqualToString:SKNoteString] ? SKTextString : [self type]];
    [fdfString appendFormat:@"/Rect[%f %f %f %f]", NSMinX(bounds), NSMinY(bounds), NSMaxX(bounds), NSMaxY(bounds)];
    [fdfString appendFormat:@"/Page %i", [self pageIndex]];
    [fdfString appendString:@"/F 4"];
    if (a > 0.0)
        [fdfString appendFormat:@"/C[%f %f %f]", r, g, b];
    if (border) {
        [fdfString appendFormat:@"/BS<</W %f/S", [border lineWidth]];
        switch ([border style]) {
            case kPDFBorderStyleSolid:
                [fdfString appendString:@"/S"];
                break;
            case kPDFBorderStyleDashed:
                [fdfString appendString:@"/D"];
                break;
            case kPDFBorderStyleBeveled:
                [fdfString appendString:@"/B"];
                break;
            case kPDFBorderStyleInset:
                [fdfString appendString:@"/I"];
                break;
            case kPDFBorderStyleUnderline:
                [fdfString appendString:@"/U"];
                break;
        }
        [fdfString appendFormat:@"/D[%@]", [[[border dashPattern] valueForKey:@"stringValue"] componentsJoinedByString:@" "]];
        [fdfString appendString:@">>"];
    } else {
        [fdfString appendString:@"/BS<</W 0.0>>"];
    }
    [fdfString appendString:@"/Contents("];
    [fdfString appendString:contents ? [contents stringByEscapingParenthesis] : @""];
    [fdfString appendString:@")"];
    return fdfString;
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

- (NSString *)string {
    return [self contents];
}

- (void)setString:(NSString *)newString {
    [self setContents:newString];
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

- (BOOL)isConvertibleAnnotation { return NO; }

- (id)copyNoteAnnotation { return nil; }

- (BOOL)hitTest:(NSPoint)point {
    NSRect bounds = [self bounds];
    if ([self isResizable])
        bounds = NSInsetRect(bounds, -4.0, -4.0);
    return [self shouldDisplay] ? NSPointInRect(point, bounds) : NO;
}

- (NSRect)displayRectForBounds:(NSRect)bounds {
    if ([self isResizable])
        bounds = NSInsetRect(bounds, -4.0, -4.0);
    return bounds;
}

- (NSSet *)keysForValuesToObserveForUndo {
    return [NSSet setWithObjects:SKPDFAnnotationBoundsKey, SKPDFAnnotationStringKey, SKPDFAnnotationColorKey, SKPDFAnnotationBorderKey, nil];
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
            int type = [[properties objectForKey:SKPDFAnnotationScriptingNoteTypeKey] intValue];
            
            if (type == 0) {
                [currentCommand setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
                [currentCommand setScriptErrorString:NSLocalizedString(@"New notes need a type.", @"Error description")];
            } else if (type == SKScriptingHighlightNote || type == SKScriptingStrikeOutNote || type == SKScriptingUnderlineNote) {
                id selSpec = [properties objectForKey:SKPDFAnnotationSelectionSpecifierKey];
                PDFSelection *selection;
                int markupType = 0;
                
                if (selSpec == nil) {
                    [currentCommand setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
                    [currentCommand setScriptErrorString:NSLocalizedString(@"New markup notes need a selection.", @"Error description")];
                } else if (selection = [PDFSelection selectionWithSpecifier:selSpec]) {
                    if (type == SKScriptingHighlightNote)
                        markupType = kPDFMarkupTypeHighlight;
                    else if (type == SKScriptingUnderlineNote)
                        markupType = kPDFMarkupTypeUnderline;
                    else if (type == SKScriptingStrikeOutNote)
                        markupType = kPDFMarkupTypeStrikeOut;
                    if (self = [[SKPDFAnnotationMarkup alloc] initWithSelection:selection markupType:markupType]) {
                        PDFPage *page = [[selection pages] objectAtIndex:0];
                        if (page && [self respondsToSelector:@selector(setPage:)])
                            [self performSelector:@selector(setPage:) withObject:page];
                    }
                }
            } else if (type == SKScriptingTextNote) {
                self = [[SKPDFAnnotationFreeText alloc] initWithBounds:NSMakeRect(100.0, 100.0, defaultWidth, defaultHeight)];
            } else if (type == SKScriptingAnchoredNote) {
                self = [[SKPDFAnnotationNote alloc] initWithBounds:NSMakeRect(100.0, 100.0, 16.0, 16.0)];
            } else if (type == SKScriptingCircleNote) {
                self = [[SKPDFAnnotationCircle alloc] initWithBounds:NSMakeRect(100.0, 100.0, defaultWidth, defaultHeight)];
            } else if (type == SKScriptingSquareNote) {
                self = [[SKPDFAnnotationSquare alloc] initWithBounds:NSMakeRect(100.0, 100.0, defaultWidth, defaultHeight)];
            } else if (type == SKScriptingLineNote) {
                self = [[SKPDFAnnotationLine alloc] initWithBounds:NSMakeRect(100.0, 100.0, defaultWidth, defaultHeight)];
            }
        }
    }
    return self;
}

- (NSScriptObjectSpecifier *)objectSpecifier {
	unsigned idx = [[[self page] notes] indexOfObjectIdenticalTo:self];
    if (idx != NSNotFound) {
        NSScriptObjectSpecifier *containerRef = [[self page] objectSpecifier];
        return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"notes" index:idx] autorelease];
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

- (int)scriptingNoteType {
    if ([[self type] isEqualToString:SKFreeTextString])
        return SKScriptingTextNote;
    else if ([[self type] isEqualToString:SKNoteString])
        return SKScriptingAnchoredNote;
    else if ([[self type] isEqualToString:SKCircleString])
        return SKScriptingCircleNote;
    else if ([[self type] isEqualToString:SKSquareString])
        return SKScriptingSquareNote;
    else if ([[self type] isEqualToString:SKHighlightString] || [[self type] isEqualToString:SKMarkUpString])
        return SKScriptingHighlightNote;
    else if ([[self type] isEqualToString:SKUnderlineString])
        return SKScriptingUnderlineNote;
    else if ([[self type] isEqualToString:SKStrikeOutString])
        return SKScriptingStrikeOutNote;
    else if ([[self type] isEqualToString:SKLineString])
        return SKScriptingLineNote;
    return 0;
}

- (int)scriptingIconType {
    return SKScriptingTextAnnotationIconNote;
}

- (id)textContents;
{
    return [self string] ? [[[NSTextStorage alloc] initWithString:[self string]] autorelease] : [NSNull null];
}

- (void)setTextContents:(id)text;
{
    [self setString:[text string]];
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

- (int)scriptingBorderStyle {
    return SKScriptingBorderStyleFromBorderStyle([self borderStyle]);
}

- (void)setScriptingBorderStyle:(int)borderStyle {
    [self setBorderStyle:SKBorderStyleFromScriptingBorderStyle(borderStyle)];
}

- (NSData *)startPointAsQDPoint {
    return (id)[NSNull null];
}

- (NSData *)endPointAsQDPoint {
    return (id)[NSNull null];
}

- (int)scriptingStartLineStyle {
    return SKScriptingLineStyleNone;
}

- (int)scriptingEndLineStyle {
    return SKScriptingLineStyleNone;
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
            [self setInteriorColor:color];
        [self setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKCircleNoteColorKey]];
        [[self border] setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKCircleNoteLineWidthKey]];
        [[self border] setDashPattern:[[NSUserDefaults standardUserDefaults] arrayForKey:SKCircleNoteDashPatternKey]];
        [[self border] setStyle:[[NSUserDefaults standardUserDefaults] floatForKey:SKCircleNoteLineStyleKey]];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict{
    if (self = [super initWithDictionary:dict]) {
        Class colorClass = [NSColor class];
        NSColor *interiorColor = [dict objectForKey:SKPDFAnnotationColorKey];
        if ([interiorColor isKindOfClass:colorClass])
            [self setInteriorColor:interiorColor];
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = [[[super dictionaryValue] mutableCopy] autorelease];
    [dict setValue:[self interiorColor] forKey:SKPDFAnnotationColorKey];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    float r, g, b, a = 0.0;
    [[self interiorColor] getRed:&r green:&g blue:&b alpha:&a];
    if (a > 0.0)
        [fdfString appendFormat:@"/IC[%f %f %f]", r, g, b];
    return fdfString;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (NSSet *)keysForValuesToObserveForUndo {
    NSMutableSet *keys = [[[super keysForValuesToObserveForUndo] mutableCopy] autorelease];
    [keys addObject:SKPDFAnnotationInteriorColorKey];
    return keys;
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:SKPDFAnnotationRichTextKey, SKPDFAnnotationFontNameKey, SKPDFAnnotationFontSizeKey, SKPDFAnnotationScriptingIconTypeKey, SKPDFAnnotationStartPointAsQDPointKey, SKPDFAnnotationEndPointAsQDPointKey, SKPDFAnnotationScriptingStartLineStyleKey, SKPDFAnnotationScriptingEndLineStyleKey, SKPDFAnnotationSelectionSpecifierKey, nil]];
    return properties;
}

@end

#pragma mark -

@interface PDFAnnotationCircle (SKExtensions)
@end

@implementation PDFAnnotationCircle (SKExtensions)

- (BOOL)isConvertibleAnnotation { return YES; }

- (id)copyNoteAnnotation {
    SKPDFAnnotationCircle *annotation = [[SKPDFAnnotationCircle alloc] initWithBounds:[self bounds]];
    [annotation setString:[self string]];
    [annotation setColor:[self color]];
    [annotation setBorder:[[[self border] copy] autorelease]];
    [annotation setInteriorColor:[self interiorColor]];
    return annotation;
}

@end

#pragma mark -

@implementation SKPDFAnnotationSquare

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        [self setShouldPrint:YES];
        NSColor *color = [[NSUserDefaults standardUserDefaults] colorForKey:SKSquareNoteInteriorColorKey];
        if ([color alphaComponent] > 0.0)
            [self setInteriorColor:color];
        [self setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKSquareNoteColorKey]];
        [[self border] setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKSquareNoteLineWidthKey]];
        [[self border] setDashPattern:[[NSUserDefaults standardUserDefaults] arrayForKey:SKSquareNoteDashPatternKey]];
        [[self border] setStyle:[[NSUserDefaults standardUserDefaults] floatForKey:SKSquareNoteLineStyleKey]];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict{
    if (self = [super initWithDictionary:dict]) {
        Class colorClass = [NSColor class];
        NSColor *interiorColor = [dict objectForKey:SKPDFAnnotationColorKey];
        if ([interiorColor isKindOfClass:colorClass])
            [self setInteriorColor:interiorColor];
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = [[[super dictionaryValue] mutableCopy] autorelease];
    [dict setValue:[self interiorColor] forKey:SKPDFAnnotationColorKey];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    float r, g, b, a = 0.0;
    [[self interiorColor] getRed:&r green:&g blue:&b alpha:&a];
    if (a > 0.0)
        [fdfString appendFormat:@"/IC[%f %f %f]", r, g, b];
    return fdfString;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (NSSet *)keysForValuesToObserveForUndo {
    NSMutableSet *keys = [[[super keysForValuesToObserveForUndo] mutableCopy] autorelease];
    [keys addObject:SKPDFAnnotationInteriorColorKey];
    return keys;
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:SKPDFAnnotationRichTextKey, SKPDFAnnotationFontNameKey, SKPDFAnnotationFontSizeKey, SKPDFAnnotationScriptingIconTypeKey, SKPDFAnnotationStartPointAsQDPointKey, SKPDFAnnotationEndPointAsQDPointKey, SKPDFAnnotationScriptingStartLineStyleKey, SKPDFAnnotationScriptingEndLineStyleKey, SKPDFAnnotationSelectionSpecifierKey, nil]];
    return properties;
}

@end

#pragma mark -

@interface PDFAnnotationSquare (SKExtensions)
@end

@implementation PDFAnnotationSquare (SKExtensions)

- (BOOL)isConvertibleAnnotation { return YES; }

- (id)copyNoteAnnotation {
    SKPDFAnnotationSquare *annotation = [[SKPDFAnnotationSquare alloc] initWithBounds:[self bounds]];
    [annotation setString:[self string]];
    [annotation setColor:[self color]];
    [annotation setBorder:[[[self border] copy] autorelease]];
    [annotation setInteriorColor:[self interiorColor]];
    return annotation;
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
        numberOfLines = 0;
        lineRects = NULL;
    }
    return self;
}

- (id)initWithBounds:(NSRect)bounds {
    self = [self initWithBounds:bounds markupType:kPDFMarkupTypeHighlight quadrilateralPointsAsStrings:nil];
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict{
    if (self = [super initWithDictionary:dict]) {
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
    NSMutableDictionary *dict = [[[super dictionaryValue] mutableCopy] autorelease];
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
    [fdfString appendString:@"/QuadPoints["];
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

- (BOOL)isMarkupAnnotation { return YES; }

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

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:SKPDFAnnotationRichTextKey, SKPDFAnnotationFontNameKey, SKPDFAnnotationFontSizeKey, SKPDFAnnotationScriptingIconTypeKey, SKPDFAnnotationLineWidthKey, SKPDFAnnotationScriptingBorderStyleKey, SKPDFAnnotationDashPatternKey, SKPDFAnnotationStartPointAsQDPointKey, SKPDFAnnotationEndPointAsQDPointKey, SKPDFAnnotationScriptingStartLineStyleKey, SKPDFAnnotationScriptingEndLineStyleKey, nil]];
    return properties;
}

- (id)selectionSpecifier {
    PDFSelection *sel = [self selection];
    return sel ? [sel objectSpecifier] : [NSArray array];
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

#pragma mark -

@implementation SKPDFAnnotationFreeText

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        [self setShouldPrint:YES];
        NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:SKTextNoteFontNameKey]
                                       size:[[NSUserDefaults standardUserDefaults] floatForKey:SKTextNoteFontSizeKey]];
        if (font)
            [self setFont:font];
        [self setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKFreeTextNoteColorKey]];
        PDFBorder *border = [[PDFBorder allocWithZone:[self zone]] init];
        [border setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKFreeTextNoteLineWidthKey]];
        [border setDashPattern:[[NSUserDefaults standardUserDefaults] arrayForKey:SKFreeTextNoteDashPatternKey]];
        [border setStyle:[[NSUserDefaults standardUserDefaults] floatForKey:SKFreeTextNoteLineStyleKey]];
        [self setBorder:[border lineWidth] > 0.0 ? border : nil];
        [border release];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict{
    if (self = [super initWithDictionary:dict]) {
        Class fontClass = [NSFont class];
        NSFont *font = [dict objectForKey:SKPDFAnnotationFontKey];
        NSNumber *rotation = [dict objectForKey:SKPDFAnnotationRotationKey];
        if ([font isKindOfClass:fontClass])
            [self setFont:font];
        if ([rotation respondsToSelector:@selector(intValue)] && [self respondsToSelector:@selector(setRotation:)])
            [self setRotation:[rotation intValue]];
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = [[[super dictionaryValue] mutableCopy] autorelease];
    [dict setValue:[self font] forKey:SKPDFAnnotationFontKey];
    if ([self respondsToSelector:@selector(rotation)])
        [dict setValue:[NSNumber numberWithInt:[self rotation]] forKey:SKPDFAnnotationRotationKey];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    [fdfString appendFormat:@"/DA(/%@ %f Tf)/DS(font: %@ %fpt)", [[self font] fontName], [[self font] pointSize], [[self font] fontName], [[self font] pointSize]];
    return fdfString;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)isEditable { return YES; }

- (NSSet *)keysForValuesToObserveForUndo {
    NSMutableSet *keys = [[[super keysForValuesToObserveForUndo] mutableCopy] autorelease];
    [keys addObject:SKPDFAnnotationFontKey];
    return keys;
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:SKPDFAnnotationRichTextKey, SKPDFAnnotationScriptingIconTypeKey, SKPDFAnnotationStartPointAsQDPointKey, SKPDFAnnotationEndPointAsQDPointKey, SKPDFAnnotationScriptingStartLineStyleKey, SKPDFAnnotationScriptingEndLineStyleKey, SKPDFAnnotationSelectionSpecifierKey, nil]];
    return properties;
}

- (id)textContents {
    NSTextStorage *textContents = [[[NSTextStorage alloc] initWithString:[self string]] autorelease];
    if ([self font])
        [textContents addAttribute:NSFontAttributeName value:[self font] range:NSMakeRange(0, [textContents length])];
    return [self string] ? textContents : (id)[NSNull null];
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

@interface PDFAnnotationFreeText (SKExtensions)
@end

@implementation PDFAnnotationFreeText (SKExtensions)

- (BOOL)isConvertibleAnnotation { return YES; }

- (id)copyNoteAnnotation {
    SKPDFAnnotationFreeText *annotation = [[SKPDFAnnotationFreeText alloc] initWithBounds:[self bounds]];
    [annotation setString:[self string]];
    [annotation setColor:[self color]];
    [annotation setBorder:[[[self border] copy] autorelease]];
    [annotation setFont:[self font]];
    if ([self respondsToSelector:@selector(rotation)] && [annotation respondsToSelector:@selector(setRotation:)])
        [annotation setRotation:[self rotation]];
    return annotation;
}

@end

#pragma mark -

@implementation SKPDFAnnotationNote

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        [self setShouldPrint:YES];
        [self setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKAnchoredNoteColorKey]];
        [self setIconType:[[NSUserDefaults standardUserDefaults] integerForKey:SKAnchoredNoteIconTypeKey]];
        texts = [[NSArray alloc] initWithObjects:[[[SKNoteText alloc] initWithAnnotation:self] autorelease], nil];
        textStorage = [[NSTextStorage allocWithZone:[self zone]] init];
        [textStorage setDelegate:self];
        text = [[NSAttributedString alloc] init];
    }
    return self;
}

- (void)updateContents {
    NSMutableString *contents = [NSMutableString string];
    if ([string length])
        [contents appendString:string];
    if ([text length]) {
        [contents appendString:@"  "];
        [contents appendString:[text string]];
    }
    [self setContents:contents];
}

- (id)initWithDictionary:(NSDictionary *)dict{
    if (self = [super initWithDictionary:dict]) {
        Class attrStringClass = [NSAttributedString class];
        Class stringClass = [NSString class];
        Class imageClass = [NSImage class];
        NSAttributedString *aText = [dict objectForKey:SKPDFAnnotationTextKey];
        NSImage *anImage = [dict objectForKey:SKPDFAnnotationImageKey];
        NSNumber *iconType = [dict objectForKey:SKPDFAnnotationTypeKey];
        if ([anImage isKindOfClass:imageClass])
            image = [anImage retain];
        if ([aText isKindOfClass:attrStringClass])
            [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withAttributedString:aText];
        else if ([aText isKindOfClass:stringClass])
            [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:(NSString *)aText];
        if ([iconType respondsToSelector:@selector(intValue)])
            [super setIconType:[iconType intValue]];
        [self updateContents];
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
    NSMutableDictionary *dict = [[[super dictionaryValue] mutableCopy] autorelease];
    [dict setValue:[NSNumber numberWithInt:[self iconType]] forKey:SKPDFAnnotationTypeKey];
    [dict setValue:[self text] forKey:SKPDFAnnotationTextKey];
    [dict setValue:[self image] forKey:SKPDFAnnotationImageKey];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    [fdfString appendString:@"/Name"];
    switch ([self iconType]) {
        case kPDFTextAnnotationIconComment:
            [fdfString appendString:@"/Comment"];
            break;
        case kPDFTextAnnotationIconKey:
            [fdfString appendString:@"/Key"];
            break;
        case kPDFTextAnnotationIconNote:
            [fdfString appendString:@"/Note"];
            break;
        case kPDFTextAnnotationIconNewParagraph:
            [fdfString appendString:@"/NewParagraph"];
            break;
        case kPDFTextAnnotationIconParagraph:
            [fdfString appendString:@"/Paragraph"];
            break;
        case kPDFTextAnnotationIconInsert:
            [fdfString appendString:@"/Insert"];
            break;
    }
    return fdfString;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)isEditable { return YES; }

- (NSString *)type {
    return SKNoteString;
}

- (NSString *)string {
    return string;
}

- (void)setString:(NSString *)newString {
    if (string != newString) {
        [string release];
        string = [newString retain];
        [self updateContents];
    }
}

- (NSImage *)image;
{
    return image;
}

- (void)setImage:(NSImage *)newImage;
{
    if (image != newImage) {
        [image release];
        image = [newImage retain];
    }
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:SKPDFAnnotationTextKey])
        return NO;
    else
        return [super automaticallyNotifiesObserversForKey:key];
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
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification;
{
    [self willChangeValueForKey:SKPDFAnnotationTextKey];
    [texts makeObjectsPerformSelector:@selector(willChangeValueForKey:) withObject:SKPDFAnnotationStringKey];
    [text release];
    text = [[NSAttributedString allocWithZone:[self zone]] initWithAttributedString:textStorage];
    [self didChangeValueForKey:SKPDFAnnotationTextKey];
    [texts makeObjectsPerformSelector:@selector(didChangeValueForKey:) withObject:SKPDFAnnotationStringKey];
    [self updateContents];
}

// override these Leopard methods to avoid showing the standard tool tips over our own
- (NSString *)toolTip { return nil; }
- (NSString *)toolTipNoLabel { return nil; }

- (NSSet *)keysForValuesToObserveForUndo {
    NSMutableSet *keys = [[[super keysForValuesToObserveForUndo] mutableCopy] autorelease];
    [keys addObject:SKPDFAnnotationIconTypeKey];
    [keys addObject:SKPDFAnnotationTextKey];
    [keys addObject:SKPDFAnnotationImageKey];
    return keys;
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:SKPDFAnnotationFontNameKey, SKPDFAnnotationFontSizeKey, SKPDFAnnotationLineWidthKey, SKPDFAnnotationScriptingBorderStyleKey, SKPDFAnnotationDashPatternKey, SKPDFAnnotationStartPointAsQDPointKey, SKPDFAnnotationEndPointAsQDPointKey, SKPDFAnnotationScriptingStartLineStyleKey, SKPDFAnnotationScriptingEndLineStyleKey, SKPDFAnnotationSelectionSpecifierKey, nil]];
    return properties;
}

- (int)scriptingIconType {
    return SKScriptingIconTypeFromIconType([self iconType]);
}

- (void)setScriptingIconType:(int)type {
    [self setIconType:SKIconTypeFromScriptingIconType(type)];
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

@interface PDFAnnotationText (SKExtensions)
@end

@implementation PDFAnnotationText (SKExtensions)

- (BOOL)isConvertibleAnnotation { return YES; }

- (id)copyNoteAnnotation {
    NSRect bounds = [self bounds];
    bounds.size = SKMakeSquareSize(16.0);
    SKPDFAnnotationNote *annotation = [[SKPDFAnnotationNote alloc] initWithBounds:bounds];
    [annotation setString:[self string]];
    [annotation setColor:[self color]];
    [annotation setBorder:[[[self border] copy] autorelease]];
    [annotation setIconType:[self iconType]];
    return annotation;
}

@end

#pragma mark -

@implementation SKPDFAnnotationLine

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
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

- (id)initWithDictionary:(NSDictionary *)dict{
    if (self = [super initWithDictionary:dict]) {
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

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [[[super dictionaryValue] mutableCopy] autorelease];
    [dict setValue:[NSNumber numberWithInt:[self startLineStyle]] forKey:SKPDFAnnotationStartLineStyleKey];
    [dict setValue:[NSNumber numberWithInt:[self endLineStyle]] forKey:SKPDFAnnotationEndLineStyleKey];
    [dict setValue:NSStringFromPoint([self startPoint]) forKey:SKPDFAnnotationStartPointKey];
    [dict setValue:NSStringFromPoint([self endPoint]) forKey:SKPDFAnnotationEndPointKey];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    [fdfString appendString:@"/LE["];
    switch ([self startLineStyle]) {
        case kPDFLineStyleNone:
            [fdfString appendString:@"/None"];
            break;
        case kPDFLineStyleSquare:
            [fdfString appendString:@"/Square"];
            break;
        case kPDFLineStyleCircle:
            [fdfString appendString:@"/Circle"];
            break;
        case kPDFLineStyleDiamond:
            [fdfString appendString:@"/Diamond"];
            break;
        case kPDFLineStyleOpenArrow:
            [fdfString appendString:@"/OpenArrow"];
            break;
        case kPDFLineStyleClosedArrow:
            [fdfString appendString:@"/ClosedArrow"];
            break;
        default:
            [fdfString appendString:@"/None"];
            break;
    }
    switch ([self endLineStyle]) {
        case kPDFLineStyleNone:
            [fdfString appendString:@"/None"];
            break;
        case kPDFLineStyleSquare:
            [fdfString appendString:@"/Square"];
            break;
        case kPDFLineStyleCircle:
            [fdfString appendString:@"/Circle"];
            break;
        case kPDFLineStyleDiamond:
            [fdfString appendString:@"/Diamond"];
            break;
        case kPDFLineStyleOpenArrow:
            [fdfString appendString:@"/OpenArrow"];
            break;
        case kPDFLineStyleClosedArrow:
            [fdfString appendString:@"/ClosedArrow"];
            break;
        default:
            [fdfString appendString:@"/None"];
            break;
    }
    [fdfString appendString:@"]"];
    NSPoint startPoint = SKAddPoints([self startPoint], [self bounds].origin);
    NSPoint endPoint = SKAddPoints([self endPoint], [self bounds].origin);
    [fdfString appendFormat:@"/L[%f %f %f %f]", startPoint.x, startPoint.y, endPoint.x, endPoint.y];
    return fdfString;
}

- (BOOL)isNoteAnnotation { return YES; }

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
    NSMutableSet *keys = [[[super keysForValuesToObserveForUndo] mutableCopy] autorelease];
    [keys addObject:SKPDFAnnotationStartLineStyleKey];
    [keys addObject:SKPDFAnnotationEndLineStyleKey];
    [keys addObject:SKPDFAnnotationStartPointKey];
    [keys addObject:SKPDFAnnotationEndPointKey];
    return keys;
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectsForKeys:[NSArray arrayWithObjects:SKPDFAnnotationRichTextKey, SKPDFAnnotationFontNameKey, SKPDFAnnotationFontSizeKey, SKPDFAnnotationScriptingIconTypeKey, SKPDFAnnotationLineWidthKey, SKPDFAnnotationScriptingBorderStyleKey, SKPDFAnnotationDashPatternKey, SKPDFAnnotationSelectionSpecifierKey, nil]];
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

- (int)scriptingStartLineStyle {
    return SKScriptingLineStyleFromLineStyle([self startLineStyle]);
}

- (int)scriptingEndLineStyle {
    return SKScriptingLineStyleFromLineStyle([self endLineStyle]);
}

- (void)setScriptingStartLineStyle:(int)style {
    [self setStartLineStyle:SKLineStyleFromScriptingLineStyle(style)];
}

- (void)setScriptingEndLineStyle:(int)style {
    [self setEndLineStyle:SKLineStyleFromScriptingLineStyle(style)];
}

@end

#pragma mark -

@interface PDFAnnotationLine (SKExtensions)
@end

@implementation PDFAnnotationLine (SKExtensions)

- (BOOL)isConvertibleAnnotation { return YES; }

- (id)copyNoteAnnotation {
    SKPDFAnnotationLine *annotation = [[SKPDFAnnotationLine alloc] initWithBounds:[self bounds]];
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
    }
    return self;
}

- (PDFAnnotation *)annotation {
    return annotation;
}

- (NSArray *)texts { return nil; }

- (NSString *)type { return nil; }

- (PDFPage *)page { return nil; }

- (unsigned int)pageIndex { return [annotation pageIndex]; }

- (NSAttributedString *)string { return [annotation text]; }

@end

#pragma mark -

@interface PDFAnnotationLink (SKExtensions)
@end

@implementation PDFAnnotationLink (SKExtensions)

// override these Leopard methods to avoid showing the standard tool tips over our own
- (NSString *)toolTip { return nil; }
- (NSString *)toolTipNoLabel { return nil; }

@end
