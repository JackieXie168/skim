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
- (void)setPage:(id)page;
@end


@interface PDFAnnotation (SKPDFAnnotationPrivate)
- (void)replacementSetBounds:(NSRect)bounds;
- (void)replacementSetContents:(NSString *)contents;
- (void)replacementSetColor:(NSColor *)color;
@end


@implementation PDFAnnotation (SKExtensions)

static IMP originalSetBounds = NULL;
static IMP originalSetContents = NULL;
static IMP originalSetColor = NULL;

+ (void)load {
    originalSetBounds = OBReplaceMethodImplementationWithSelector(self, @selector(setBounds:), @selector(replacementSetBounds:));
    originalSetContents = OBReplaceMethodImplementationWithSelector(self, @selector(setContents:), @selector(replacementSetContents:));
    originalSetColor = OBReplaceMethodImplementationWithSelector(self, @selector(setColor:), @selector(replacementSetColor:));
}

- (id)initWithDictionary:(NSDictionary *)dict{
    [[self initWithBounds:NSZeroRect] release];
    
    NSString *type = [dict objectForKey:@"type"];
    NSRect bounds = NSRectFromString([dict objectForKey:@"bounds"]);
    NSString *contents = [dict objectForKey:@"contents"];
    NSColor *color = [dict objectForKey:@"color"];
    NSNumber *lineWidth = [dict objectForKey:@"lineWidth"];
    NSNumber *borderStyle = [dict objectForKey:@"borderStyle"];
    NSArray *dashPattern = [dict objectForKey:@"dashPattern"];
    
    if ([type isEqualToString:@"Note"]) {
        self = [[SKPDFAnnotationNote alloc] initWithBounds:bounds];
        NSAttributedString *text = [dict objectForKey:@"text"];
        NSImage *image = [dict objectForKey:@"image"];
        NSNumber *iconType = [dict objectForKey:@"iconType"];
        if (image)
            [(SKPDFAnnotationNote *)self setImage:image];
        if (text)
            [(SKPDFAnnotationNote *)self setText:text];
        if (iconType)
            [(SKPDFAnnotationNote *)self setIconType:[iconType intValue]];
    } else if ([type isEqualToString:@"FreeText"]) {
        self = [[SKPDFAnnotationFreeText alloc] initWithBounds:bounds];
        NSFont *font = [dict objectForKey:@"font"];
        if (font)
            [(SKPDFAnnotationFreeText *)self setFont:font];
    } else if ([type isEqualToString:@"Circle"]) {
        self = [[SKPDFAnnotationCircle alloc] initWithBounds:bounds];
        NSColor *interiorColor = [dict objectForKey:@"interiorColor"];
        if (interiorColor)
            [(SKPDFAnnotationCircle *)self setInteriorColor:interiorColor];
    } else if ([type isEqualToString:@"Square"]) {
        self = [[SKPDFAnnotationSquare alloc] initWithBounds:bounds];
        NSColor *interiorColor = [dict objectForKey:@"interiorColor"];
        if (interiorColor)
            [(SKPDFAnnotationSquare *)self setInteriorColor:interiorColor];
    } else if ([type isEqualToString:@"Highlight"] || [type isEqualToString:@"MarkUp"]) {
        self = [[SKPDFAnnotationMarkup alloc] initWithBounds:bounds markupType:kPDFMarkupTypeHighlight quadrilateralPointsAsStrings:[dict objectForKey:@"quadrilateralPoints"]];
    } else if ([type isEqualToString:@"Underline"]) {
        self = [[SKPDFAnnotationMarkup alloc] initWithBounds:bounds markupType:kPDFMarkupTypeUnderline quadrilateralPointsAsStrings:[dict objectForKey:@"quadrilateralPoints"]];
    } else if ([type isEqualToString:@"StrikeOut"]) {
        self = [[SKPDFAnnotationMarkup alloc] initWithBounds:bounds markupType:kPDFMarkupTypeStrikeOut quadrilateralPointsAsStrings:[dict objectForKey:@"quadrilateralPoints"]];
    } else if ([type isEqualToString:@"Line"]) {
        self = [[SKPDFAnnotationLine alloc] initWithBounds:bounds];
        NSString *point;
        NSNumber *startLineStyle = [dict objectForKey:@"startLineStyle"];
        NSNumber *endLineStyle = [dict objectForKey:@"endLineStyle"];
        if (point = [dict objectForKey:@"startPoint"])
            [(SKPDFAnnotationLine *)self setStartPoint:NSPointFromString(point)];
        if (point = [dict objectForKey:@"endPoint"])
            [(SKPDFAnnotationLine *)self setEndPoint:NSPointFromString(point)];
        if (startLineStyle)
            [(SKPDFAnnotationLine *)self setStartLineStyle:[startLineStyle intValue]];
        if (endLineStyle)
            [(SKPDFAnnotationLine *)self setEndLineStyle:[endLineStyle intValue]];
    } else {
        self = nil;
    }
    
    if (contents)
        [self setContents:contents];
    if (color)
        [self setColor:color];
    if ((lineWidth || borderStyle || dashPattern) && [self border] == nil)
        [self setBorder:[[[PDFBorder alloc] init] autorelease]];
    if (lineWidth)
        [[self border] setLineWidth:[lineWidth floatValue]];
    if (borderStyle)
        [[self border] setStyle:[lineWidth intValue]];
    if (dashPattern)
        [[self border] setDashPattern:dashPattern];
    
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    [dict setValue:[self type] forKey:@"type"];
    [dict setValue:[self contents] forKey:@"contents"];
    [dict setValue:[self color] forKey:@"color"];
    [dict setValue:NSStringFromRect([self bounds]) forKey:@"bounds"];
    [dict setValue:[NSNumber numberWithUnsignedInt:[self pageIndex]] forKey:@"pageIndex"];
    if ([self border]) {
        [dict setValue:[NSNumber numberWithFloat:[[self border] lineWidth]] forKey:@"lineWidth"];
        [dict setValue:[NSNumber numberWithInt:[[self border] style]] forKey:@"borderStyle"];
        [dict setValue:[[self border] dashPattern] forKey:@"dashPattern"];
    }
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

- (int)noteType {
    if ([[self type] isEqualToString:@"FreeText"])
        return SKFreeTextNote;
    else if ([[self type] isEqualToString:@"Note"])
        return SKAnchoredNote;
    else if ([[self type] isEqualToString:@"Circle"])
        return SKCircleNote;
    else if ([[self type] isEqualToString:@"Square"])
        return SKSquareNote;
    else if ([[self type] isEqualToString:@"Highlight"] || [[self type] isEqualToString:@"MarkUp"])
        return SKHighlightNote;
    else if ([[self type] isEqualToString:@"Underline"])
        return SKUnderlineNote;
    else if ([[self type] isEqualToString:@"StrikeOut"])
        return SKStrikeOutNote;
    else if ([[self type] isEqualToString:@"Line"])
        return SKLineNote;
    return 0;
}

- (PDFBorderStyle)borderStyle {
    return [[self border] style];
}

- (void)setBorderStyle:(PDFBorderStyle)style {
    [[[self undoManager] prepareWithInvocationTarget:self] setBorderStyle:style];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    if ([self border] == nil)
        [self setBorder:[[[PDFBorder alloc] init] autorelease]];
    [[self border] setStyle:style];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"borderStyle", @"key", nil]];
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
            } else {
                if (type == SKASTextNote)
                    self = [[SKPDFAnnotationFreeText alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0)];
                else if (type == SKASAnchoredNote)
                    self = [[SKPDFAnnotationNote alloc] initWithBounds:NSMakeRect(100.0, 100.0, 16.0, 16.0)];
                else if (type == SKASCircleNote)
                    self = [[SKPDFAnnotationCircle alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0)];
                else if (type == SKASSquareNote)
                    self = [[SKPDFAnnotationSquare alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0)];
                else if (type == SKASLineNote)
                    self = [[SKPDFAnnotationLine alloc] initWithBounds:NSMakeRect(100.0, 100.0, 16.0, 16.0)];
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
    else if ([[self type] isEqualToString:@"Line"])
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
        if ([self isResizable] == NO)
            newBounds.size = [self bounds].size;
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

- (float)lineWidth {
    return [[self border] lineWidth];
}

- (void)setLineWidth:(float)width {
    [[[self undoManager] prepareWithInvocationTarget:self] setLineWidth:[self lineWidth]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    if ([self border] == nil)
        [self setBorder:[[[PDFBorder alloc] init] autorelease]];
    [[self border] setLineWidth:width];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"lineWidth", @"key", nil]];
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

- (NSArray *)dashPattern {
    return [[self border] dashPattern];
}

- (void)setDashPattern:(NSArray *)pattern {
    [[[self undoManager] prepareWithInvocationTarget:self] setDashPattern:[self dashPattern]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    if ([self border] == nil)
        [self setBorder:[[[PDFBorder alloc] init] autorelease]];
    [[self border] setDashPattern:pattern];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"dashPattern", @"key", nil]];
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
        [self setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKCircleNoteColorKey]]];
        [[self border] setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKCircleNoteLineWidthKey]];
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[self interiorColor] forKey:@"interiorColor"];
    return dict;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)shouldPrint { return YES; }

- (void)setInteriorColor:(NSColor *)color {
    [[[self undoManager] prepareWithInvocationTarget:self] setInteriorColor:[self interiorColor]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [super setInteriorColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"interiorColor", @"key", nil]];
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectForKey:@"richText"];
    [properties removeObjectForKey:@"fontName"];
    [properties removeObjectForKey:@"fontSize"];
    [properties removeObjectForKey:@"asIconType"];
    [properties removeObjectForKey:@"startPointAsQDPoint"];
    [properties removeObjectForKey:@"endPointAsQDPoint"];
    [properties removeObjectForKey:@"asStartLineStyle"];
    [properties removeObjectForKey:@"asEndLineStyle"];
    [properties removeObjectForKey:@"selectionSpecifier"];
    return properties;
}

@end

#pragma mark -

@implementation SKPDFAnnotationSquare

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        [self setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKSquareNoteColorKey]]];
        [[self border] setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKSquareNoteLineWidthKey]];
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[self interiorColor] forKey:@"interiorColor"];
    return dict;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)shouldPrint { return YES; }

- (void)setInteriorColor:(NSColor *)color {
    [[[self undoManager] prepareWithInvocationTarget:self] setInteriorColor:[self interiorColor]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [super setInteriorColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"interiorColor", @"key", nil]];
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectForKey:@"richText"];
    [properties removeObjectForKey:@"fontName"];
    [properties removeObjectForKey:@"fontSize"];
    [properties removeObjectForKey:@"asIconType"];
    [properties removeObjectForKey:@"startPointAsQDPoint"];
    [properties removeObjectForKey:@"endPointAsQDPoint"];
    [properties removeObjectForKey:@"asStartLineStyle"];
    [properties removeObjectForKey:@"asEndLineStyle"];
    [properties removeObjectForKey:@"selectionSpecifier"];
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
    NSPoint p0 = NSMakePoint(NSMinX(bounds) - origin.x, NSMaxY(bounds) - origin.y);
    NSPoint p1 = NSMakePoint(NSMaxX(bounds) - origin.x, NSMaxY(bounds) - origin.y);
    NSPoint p2 = NSMakePoint(NSMinX(bounds) - origin.x, NSMinY(bounds) - origin.y);
    NSPoint p3 = NSMakePoint(NSMaxX(bounds) - origin.x, NSMinY(bounds) - origin.y);
    return [[NSArray alloc] initWithObjects:[NSValue valueWithPoint:p0], [NSValue valueWithPoint:p1], [NSValue valueWithPoint:p2], [NSValue valueWithPoint:p3], nil];
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
            [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:0 green:0.5 blue:0 alpha:1.0]] forKey:SKUnderlineNoteColorKey];
        
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

static BOOL adjacentCharacterBounds(NSRect rect1, NSRect rect2) {
    float w = fmax(NSWidth(rect2), NSWidth(rect1));
    float h = fmax(NSHeight(rect2), NSHeight(rect1));
    // first check the vertical position; allow sub/superscripts
    if (fabs(NSMinY(rect1) - NSMinY(rect2)) > 0.2 * h && fabs(NSMaxY(rect1) - NSMaxY(rect2)) > 0.2 * h)
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

- (PDFSelection *)selection {
    if (0 == numberOfLines)
        [self regenerateLineRects];
    
    PDFSelection *sel, *selection = nil;
    unsigned i;
    
    for (i = 0; i < numberOfLines; i++) {
        if (sel = [[self page] selectionForRect:lineRects[i]]) {
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

- (BOOL)shouldPrint { return YES; }

// fix a bug in PDFKit, the color space sometimes is not correct
- (void)drawWithBox:(CGPDFBox)box inContext:(CGContextRef)context {
    CGContextSaveGState(context);
    SKCGContextSetDefaultRGBColorSpace(context);
    
    [super drawWithBox:box inContext:context];
    
    CGContextRestoreGState(context);
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectForKey:@"richText"];
    [properties removeObjectForKey:@"fontName"];
    [properties removeObjectForKey:@"fontSize"];
    [properties removeObjectForKey:@"asIconType"];
    [properties removeObjectForKey:@"lineWidth"];
    [properties removeObjectForKey:@"borderStyle"];
    [properties removeObjectForKey:@"dashPattern"];
    [properties removeObjectForKey:@"startPointAsQDPoint"];
    [properties removeObjectForKey:@"endPointAsQDPoint"];
    [properties removeObjectForKey:@"asStartLineStyle"];
    [properties removeObjectForKey:@"asEndLineStyle"];
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
        NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:SKTextNoteFontNameKey]
                                       size:[[NSUserDefaults standardUserDefaults] floatForKey:SKTextNoteFontSizeKey]];
        [super setFont:font];
        [super setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKFreeTextNoteColorKey]]];
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

- (void)setFont:(NSFont *)font {
    [[[self undoManager] prepareWithInvocationTarget:self] setFont:[self font]];
    [[self undoManager] setActionName:NSLocalizedString(@"Edit Note", @"Undo action name")];
    [super setFont:font];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"font", @"key", nil]];
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectForKey:@"richText"];
    [properties removeObjectForKey:@"asIconType"];
    [properties removeObjectForKey:@"lineWidth"];
    [properties removeObjectForKey:@"borderStyle"];
    [properties removeObjectForKey:@"dashPattern"];
    [properties removeObjectForKey:@"startPointAsQDPoint"];
    [properties removeObjectForKey:@"endPointAsQDPoint"];
    [properties removeObjectForKey:@"asStartLineStyle"];
    [properties removeObjectForKey:@"asEndLineStyle"];
    [properties removeObjectForKey:@"selectionSpecifier"];
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
        [self setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKAnchoredNoteColorKey]]];
        [self setIconType:[[NSUserDefaults standardUserDefaults] integerForKey:SKAnchoredNoteIconTypeKey]];
        texts = [[NSArray alloc] initWithObjects:[[[SKNoteText alloc] initWithAnnotation:self] autorelease], nil];
        textStorage = [[NSTextStorage allocWithZone:[self zone]] init];
        [textStorage setDelegate:self];
        text = [[NSAttributedString alloc] init];
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
    [dict setValue:[NSNumber numberWithInt:[self iconType]] forKey:@"iconType"];
    [dict setValue:[self text] forKey:@"text"];
    [dict setValue:[self image] forKey:@"image"];
    return dict;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)isEditable { return YES; }

- (BOOL)shouldPrint { return YES; }

- (NSString *)type {
    return @"Note";
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

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectForKey:@"fontName"];
    [properties removeObjectForKey:@"fontSize"];
    [properties removeObjectForKey:@"lineWidth"];
    [properties removeObjectForKey:@"borderStyle"];
    [properties removeObjectForKey:@"dashPattern"];
    [properties removeObjectForKey:@"startPointAsQDPoint"];
    [properties removeObjectForKey:@"endPointAsQDPoint"];
    [properties removeObjectForKey:@"asStartLineStyle"];
    [properties removeObjectForKey:@"asEndLineStyle"];
    [properties removeObjectForKey:@"selectionSpecifier"];
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
        [super setColor:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:SKLineNoteColorKey]]];
        [super setStartLineStyle:[[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteStartLineStyleKey]];
        [super setEndLineStyle:[[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteEndLineStyleKey]];
        [super setStartPoint:NSMakePoint(0.5, 0.5)];
        [super setEndPoint:NSMakePoint(NSWidth(bounds) - 0.5, NSHeight(bounds) - 0.5)];
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[NSNumber numberWithInt:[self startLineStyle]] forKey:@"startLineStyle"];
    [dict setValue:[NSNumber numberWithInt:[self endLineStyle]] forKey:@"endLineStyle"];
    [dict setValue:NSStringFromPoint([self startPoint]) forKey:@"startPoint"];
    [dict setValue:NSStringFromPoint([self endPoint]) forKey:@"endPoint"];
    return dict;
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)shouldPrint { return YES; }

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
        NSPoint relPoint = NSMakePoint(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
        float lengthSquared = relPoint.x * relPoint.x + relPoint.y * relPoint.y;
        float extProduct;
        
        if (lengthSquared < 16.0)
            return YES;
        
        extProduct = (point.x - NSMinX(bounds) - startPoint.x) * relPoint.y - (point.y - NSMinY(bounds) - startPoint.y) * relPoint.x;
        
        return extProduct * extProduct < 16.0 * lengthSquared;
    } else {
        point.x -= NSMinX(bounds);
        point.y -= NSMinY(bounds);
        
        return (fabs(point.x - startPoint.x) < 3.5 && fabs(point.y - startPoint.y) < 3.5) ||
               (fabs(point.x - endPoint.x) < 3.5 && fabs(point.y - endPoint.y) < 3.5);
    }
}

#pragma mark Scripting support

- (NSDictionary *)scriptingProperties {
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    [properties removeObjectForKey:@"richText"];
    [properties removeObjectForKey:@"fontName"];
    [properties removeObjectForKey:@"fontSize"];
    [properties removeObjectForKey:@"asIconType"];
    [properties removeObjectForKey:@"lineWidth"];
    [properties removeObjectForKey:@"borderStyle"];
    [properties removeObjectForKey:@"dashPattern"];
    [properties removeObjectForKey:@"selectionSpecifier"];
    return properties;
}

- (void)setStartPointAsQDPoint:(NSData *)inQDPointAsData {
    if ([inQDPointAsData length] == sizeof(Point)) {
        const Point *qdPoint = (const Point *)[inQDPointAsData bytes];
        NSPoint startPoint = NSPointFromPoint(*qdPoint);
        
        NSRect bounds = [self bounds];
        NSPoint endPoint = [self endPoint];
        endPoint.x = roundf(endPoint.x + NSMinX(bounds));
        endPoint.y = roundf(endPoint.y + NSMinY(bounds));
        
        bounds.origin.x = floorf(fmin(startPoint.x, endPoint.x));
        bounds.size.width = ceilf(fmax(endPoint.x, startPoint.x)) - NSMinX(bounds);
        bounds.origin.y = floorf(fmin(startPoint.y, endPoint.y));
        bounds.size.height = ceilf(fmax(endPoint.y, startPoint.y)) - NSMinY(bounds);
        
        if (NSWidth(bounds) < 8.0) {
            bounds.size.width = 8.0;
            bounds.origin.x = floorf(0.5 * (startPoint.x + endPoint.x) - 4.0);
        }
        if (NSHeight(bounds) < 8.0) {
            bounds.size.height = 8.0;
            bounds.origin.y = floorf(0.5 * (startPoint.y + endPoint.y) - 4.0);
        }
        
        startPoint.x -= NSMinX(bounds);
        startPoint.y -= NSMinY(bounds);
        endPoint.x -= NSMinX(bounds);
        endPoint.y -= NSMinY(bounds);
        
        [self setBounds:bounds];
        [self setStartPoint:startPoint];
        [self setEndPoint:endPoint];
    }

}

- (NSData *)startPointAsQDPoint {
    NSRect bounds = [self bounds];
    NSPoint startPoint = [self startPoint];
    startPoint.x = floorf(startPoint.x + NSMinX(bounds));
    startPoint.y = floorf(startPoint.y + NSMinY(bounds));
    Point qdPoint = PointFromNSPoint(startPoint);
    return [NSData dataWithBytes:&qdPoint length:sizeof(Point)];
}

- (void)setEndPointAsQDPoint:(NSData *)inQDPointAsData {
    if ([inQDPointAsData length] == sizeof(Point)) {
        const Point *qdPoint = (const Point *)[inQDPointAsData bytes];
        NSPoint endPoint = NSPointFromPoint(*qdPoint);
        
        NSRect bounds = [self bounds];
        NSPoint startPoint = [self startPoint];
        startPoint.x = roundf(startPoint.x + NSMinX(bounds));
        startPoint.y = roundf(startPoint.y + NSMinY(bounds));
        
        bounds.origin.x = floorf(fmin(startPoint.x, endPoint.x));
        bounds.size.width = ceilf(fmax(endPoint.x, startPoint.x)) - NSMinX(bounds);
        bounds.origin.y = floorf(fmin(startPoint.y, endPoint.y));
        bounds.size.height = ceilf(fmax(endPoint.y, startPoint.y)) - NSMinY(bounds);
        
        if (NSWidth(bounds) < 8.0) {
            bounds.size.width = 8.0;
            bounds.origin.x = floorf(0.5 * (startPoint.x + endPoint.x) - 4.0);
        }
        if (NSHeight(bounds) < 8.0) {
            bounds.size.height = 8.0;
            bounds.origin.y = floorf(0.5 * (startPoint.y + endPoint.y) - 4.0);
        }
        
        startPoint.x -= NSMinX(bounds);
        startPoint.y -= NSMinY(bounds);
        endPoint.x -= NSMinX(bounds);
        endPoint.y -= NSMinY(bounds);
        
        [self setBounds:bounds];
        [self setStartPoint:startPoint];
        [self setEndPoint:endPoint];
    }

}

- (NSData *)endPointAsQDPoint {
    NSRect bounds = [self bounds];
    NSPoint endPoint = [self endPoint];
    endPoint.x = floorf(endPoint.x + NSMinX(bounds));
    endPoint.y = floorf(endPoint.y + NSMinY(bounds));
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
