//
//  PDFAnnotation_SKExtensions.m
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

#import "PDFAnnotation_SKExtensions.h"
#import "SKPDFAnnotationCircle.h"
#import "SKPDFAnnotationSquare.h"
#import "SKPDFAnnotationLine.h"
#import "SKPDFAnnotationMarkup.h"
#import "SKPDFAnnotationFreeText.h"
#import "SKPDFAnnotationNote.h"
#import "PDFBorder_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "PDFPage_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "SKPDFView.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "OBUtilities.h"


unsigned long SKScriptingBorderStyleFromBorderStyle(int borderStyle) {
    switch (borderStyle) {
        case kPDFBorderStyleSolid: return SKScriptingBorderStyleSolid;
        case kPDFBorderStyleDashed: return SKScriptingBorderStyleDashed;
        case kPDFBorderStyleBeveled: return SKScriptingBorderStyleBeveled;
        case kPDFBorderStyleInset: return SKScriptingBorderStyleInset;
        case kPDFBorderStyleUnderline: return SKScriptingBorderStyleUnderline;
        default: return SKScriptingBorderStyleSolid;
    }
}

int SKBorderStyleFromScriptingBorderStyle(unsigned long borderStyle) {
    switch (borderStyle) {
        case SKScriptingBorderStyleSolid: return kPDFBorderStyleSolid;
        case SKScriptingBorderStyleDashed: return kPDFBorderStyleDashed;
        case SKScriptingBorderStyleBeveled: return kPDFBorderStyleBeveled;
        case SKScriptingBorderStyleInset: return kPDFBorderStyleInset;
        case SKScriptingBorderStyleUnderline: return kPDFBorderStyleUnderline;
        default: return kPDFBorderStyleSolid;
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

NSString *SKPDFAnnotationScriptingNoteTypeKey = @"scriptingNoteType";
NSString *SKPDFAnnotationScriptingBorderStyleKey = @"scriptingBorderStyle";

enum {
    SKPDFAnnotationScriptingNoteClassCode = 'Note'
};

@interface PDFAnnotation (SKPrivateDeclarations)
- (void)setPage:(PDFPage *)newPage;
@end


@implementation PDFAnnotation (SKExtensions)

- (id)initWithProperties:(NSDictionary *)dict{
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
        self = [[annotationClass alloc] initWithProperties:dict];
        
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

- (NSDictionary *)properties{
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
    [fdfString appendFormat:@"/%s/%s/%s/", SKFDFTypeKey, SKFDFAnnotation, SKFDFAnnotationTypeKey];
    [fdfString appendString:[[self type] isEqualToString:SKNoteString] ? SKTextString : [self type]];
    [fdfString appendFormat:@"/%s[%f %f %f %f]", SKFDFAnnotationRectKey, NSMinX(bounds), NSMinY(bounds), NSMaxX(bounds), NSMaxY(bounds)];
    [fdfString appendFormat:@"/%s %i", SKFDFAnnotationPageKey, [self pageIndex]];
    [fdfString appendFormat:@"/%s 4", SKFDFAnnotationFlagsKey];
    if (a > 0.0)
        [fdfString appendFormat:@"/%s[%f %f %f]", SKFDFAnnotationColorKey, r, g, b];
    if (border) {
        [fdfString appendFormat:@"/%s<</%s %f/%s", SKFDFAnnotationBorderStylesKey, SKFDFAnnotationLineWidthKey, [border lineWidth], SKFDFAnnotationBorderStyleKey];
        switch ([border style]) {
            case kPDFBorderStyleSolid:
                [fdfString appendFormat:@"/%s", SKFDFBorderStyleSolid];
                break;
            case kPDFBorderStyleDashed:
                [fdfString appendFormat:@"/%s", SKFDFBorderStyleDashed];
                break;
            case kPDFBorderStyleBeveled:
                [fdfString appendFormat:@"/%s", SKFDFBorderStyleBeveled];
                break;
            case kPDFBorderStyleInset:
                [fdfString appendFormat:@"/%s", SKFDFBorderStyleInset];
                break;
            case kPDFBorderStyleUnderline:
                [fdfString appendFormat:@"/%s", SKFDFBorderStyleUnderline];
                break;
        }
        [fdfString appendFormat:@"/%s[%@]>>", SKFDFAnnotationDashPatternKey, [[[border dashPattern] valueForKey:@"stringValue"] componentsJoinedByString:@" "]];
    } else {
        [fdfString appendFormat:@"/%s<</%s 0.0>>", SKFDFAnnotationBorderStylesKey, SKFDFAnnotationLineWidthKey];
    }
    [fdfString appendFormat:@"/%s(%@)", SKFDFAnnotationContentsKey, (contents ? [contents stringByEscapingParenthesis] : @"")];
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

- (BOOL)isMarkup { return NO; }

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
    static NSSet *keys = nil;
    if (keys == nil)
        keys = [[NSSet alloc] initWithObjects:SKPDFAnnotationBoundsKey, SKPDFAnnotationStringKey, SKPDFAnnotationColorKey, SKPDFAnnotationBorderKey, nil];
    return keys;
}

#pragma mark Scripting support

// to support the 'make' command
- (id)init {
    [[self initWithBounds:NSZeroRect] release];
    self = nil;
    NSScriptCommand *currentCommand = [NSScriptCommand currentCommand];
    if ([currentCommand isKindOfClass:[NSCreateCommand class]]) {
        unsigned long classCode = [[(NSCreateCommand *)currentCommand createClassDescription] appleEventCode];
        NSRect bounds = NSMakeRect(100.0, 100.0, 0.0, 0.0);
        bounds.size.width = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteWidthKey];
        bounds.size.height = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteHeightKey];
       
        if (classCode == SKPDFAnnotationScriptingNoteClassCode) {
            
            NSDictionary *properties = [(NSCreateCommand *)currentCommand resolvedKeyDictionary];
            unsigned long type = [[properties objectForKey:SKPDFAnnotationScriptingNoteTypeKey] unsignedLongValue];
            
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
                self = [[SKPDFAnnotationFreeText alloc] initWithBounds:bounds];
            } else if (type == SKScriptingAnchoredNote) {
                bounds.size = SKPDFAnnotationNoteSize;
                self = [[SKPDFAnnotationNote alloc] initWithBounds:bounds];
            } else if (type == SKScriptingCircleNote) {
                self = [[SKPDFAnnotationCircle alloc] initWithBounds:bounds];
            } else if (type == SKScriptingSquareNote) {
                self = [[SKPDFAnnotationSquare alloc] initWithBounds:bounds];
            } else if (type == SKScriptingLineNote) {
                self = [[SKPDFAnnotationLine alloc] initWithBounds:bounds];
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
        return [[PDFAnnotation allocWithZone:zone] initWithProperties:[self properties]];
    else
        return nil;
}

// overridden by subclasses to add or remove custom scripting keys relevant for the class, subclasses should call super first
+ (NSSet *)customScriptingKeys {
    static NSSet *customScriptingKeys = nil;
    if (customScriptingKeys == nil)
        customScriptingKeys = [[NSSet alloc] initWithObjects:SKPDFAnnotationLineWidthKey, SKPDFAnnotationScriptingBorderStyleKey, SKPDFAnnotationDashPatternKey, nil];
    return customScriptingKeys;
}

- (NSDictionary *)scriptingProperties {
    // remove all custom properties that are not valid for this class
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    NSMutableSet *customKeys = [[NSMutableSet alloc] init];
    [customKeys unionSet:[SKPDFAnnotationCircle customScriptingKeys]];
    [customKeys unionSet:[SKPDFAnnotationSquare customScriptingKeys]];
    [customKeys unionSet:[SKPDFAnnotationFreeText customScriptingKeys]];
    [customKeys unionSet:[SKPDFAnnotationNote customScriptingKeys]];
    [customKeys unionSet:[SKPDFAnnotationLine customScriptingKeys]];
    [customKeys unionSet:[SKPDFAnnotationMarkup customScriptingKeys]];
    [customKeys minusSet:[[self class] customScriptingKeys]];
    [properties removeObjectsForKeys:[customKeys allObjects]];
    [customKeys release];
    return properties;
}

- (unsigned long)scriptingNoteType {
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

- (void)setScriptingNoteType:(unsigned long)type {
    NSScriptCommand *currentCommand = [NSScriptCommand currentCommand];
    if ([currentCommand isKindOfClass:[NSCreateCommand class]] == NO)
        [currentCommand setScriptErrorNumber:NSReceiversCantHandleCommandScriptError]; 
}

- (unsigned long)scriptingIconType {
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

- (unsigned long)scriptingBorderStyle {
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

- (unsigned long)scriptingStartLineStyle {
    return SKScriptingLineStyleNone;
}

- (unsigned long)scriptingEndLineStyle {
    return SKScriptingLineStyleNone;
}

- (id)selectionSpecifier {
    return [NSNull null];
}

@end

#pragma mark -

@interface PDFAnnotationLink (SKExtensions)
@end

@implementation PDFAnnotationLink (SKExtensions)

// override these Leopard methods to avoid showing the standard tool tips over our own

static IMP originalToolTip = NULL;

- (NSString *)replacementToolTip {
    return ([self URL] || [self destination] || originalToolTip == NULL) ? nil : originalToolTip(self, _cmd);
}

+ (void)load {
    if ([self instancesRespondToSelector:@selector(toolTip)])
        originalToolTip = OBReplaceMethodImplementationWithSelector(self, @selector(toolTip), @selector(replacementToolTip));
}

@end
