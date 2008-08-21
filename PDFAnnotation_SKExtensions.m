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
#import "PDFAnnotationCircle_SKExtensions.h"
#import "PDFAnnotationSquare_SKExtensions.h"
#import "PDFAnnotationLine_SKExtensions.h"
#import "PDFAnnotationMarkup_SKExtensions.h"
#import "PDFAnnotationFreeText_SKExtensions.h"
#import "PDFAnnotationText_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "PDFBorder_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "PDFPage_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "SKPDFView.h"
#import "NSGeometry_SKExtensions.h"
#import "NSString_SKExtensions.h"


FourCharCode SKScriptingBorderStyleFromBorderStyle(PDFBorderStyle borderStyle) {
    switch (borderStyle) {
        case kPDFBorderStyleSolid: return SKScriptingBorderStyleSolid;
        case kPDFBorderStyleDashed: return SKScriptingBorderStyleDashed;
        case kPDFBorderStyleBeveled: return SKScriptingBorderStyleBeveled;
        case kPDFBorderStyleInset: return SKScriptingBorderStyleInset;
        case kPDFBorderStyleUnderline: return SKScriptingBorderStyleUnderline;
        default: return SKScriptingBorderStyleSolid;
    }
}

PDFBorderStyle SKBorderStyleFromScriptingBorderStyle(FourCharCode borderStyle) {
    switch (borderStyle) {
        case SKScriptingBorderStyleSolid: return kPDFBorderStyleSolid;
        case SKScriptingBorderStyleDashed: return kPDFBorderStyleDashed;
        case SKScriptingBorderStyleBeveled: return kPDFBorderStyleBeveled;
        case SKScriptingBorderStyleInset: return kPDFBorderStyleInset;
        case SKScriptingBorderStyleUnderline: return kPDFBorderStyleUnderline;
        default: return kPDFBorderStyleSolid;
    }
}


NSString *SKPDFAnnotationScriptingNoteTypeKey = @"scriptingNoteType";
NSString *SKPDFAnnotationScriptingBorderStyleKey = @"scriptingBorderStyle";

enum {
    SKPDFAnnotationScriptingNoteClassCode = 'Note'
};

@interface PDFAnnotation (SKPrivateDeclarations)
- (void)setPage:(PDFPage *)newPage;
@end


@implementation PDFAnnotation (SKExtensions)

- (NSString *)fdfString {
    NSMutableString *fdfString = [NSMutableString string];
    NSRect bounds = [self bounds];
    float r, g, b, a = 0.0;
    PDFBorder *border = [self border];
    NSString *contents = [self contents];
    [[self color] getRed:&r green:&g blue:&b alpha:&a];
    [fdfString appendFDFName:SKFDFTypeKey];
    [fdfString appendFDFName:SKFDFAnnotation];
    [fdfString appendFDFName:SKFDFAnnotationTypeKey];
    [fdfString appendFormat:@"/%@", [[self type] isEqualToString:SKNNoteString] ? SKNTextString : [self type]];
    [fdfString appendFDFName:SKFDFAnnotationBoundsKey];
    [fdfString appendFormat:@"[%f %f %f %f]", NSMinX(bounds), NSMinY(bounds), NSMaxX(bounds), NSMaxY(bounds)];
    [fdfString appendFDFName:SKFDFAnnotationPageIndexKey];
    [fdfString appendFormat:@" %i", [self pageIndex]];
    [fdfString appendFDFName:SKFDFAnnotationFlagsKey];
    [fdfString appendString:@" 4"];
    if (a > 0.0) {
        [fdfString appendFDFName:SKFDFAnnotationColorKey];
        [fdfString appendFormat:@"[%f %f %f]", r, g, b];
    }
    [fdfString appendFDFName:SKFDFAnnotationBorderStylesKey];
    [fdfString appendString:@"<<"];
    if (border) {
        [fdfString appendFDFName:SKFDFAnnotationLineWidthKey];
        [fdfString appendFormat:@" %f", [border lineWidth]];
        [fdfString appendFDFName:SKFDFAnnotationBorderStyleKey];
        [fdfString appendFDFName:SKFDFBorderStyleFromPDFBorderStyle([border style])];
        [fdfString appendFDFName:SKFDFAnnotationDashPatternKey];
        [fdfString appendFormat:@"[%@]", [[[border dashPattern] valueForKey:@"stringValue"] componentsJoinedByString:@" "]];
    } else {
        [fdfString appendFDFName:SKFDFAnnotationLineWidthKey];
        [fdfString appendString:@" 0.0"];
    }
    [fdfString appendString:@">>"];
    [fdfString appendFDFName:SKFDFAnnotationContentsKey];
    [fdfString appendString:@"("];
    if (contents)
        [fdfString appendString:[[contents lossyISOLatin1String] stringByEscapingParenthesis]];
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

- (PDFTextAnnotationIconType)iconType { return kPDFTextAnnotationIconNote; }

- (NSImage *)image { return nil; }

- (NSAttributedString *)text { return nil; }

- (NSArray *)texts { return nil; }

- (NSColor *)interiorColor { return nil; }

- (BOOL)isMarkup { return NO; }

- (BOOL)isLink { return NO; }

- (BOOL)isResizable { return NO; }

- (BOOL)isMovable { return NO; }

- (BOOL)isEditable { return [self isSkimNote]; }

- (BOOL)isConvertibleAnnotation { return NO; }

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
        keys = [[NSSet alloc] initWithObjects:SKNPDFAnnotationBoundsKey, SKNPDFAnnotationStringKey, SKNPDFAnnotationColorKey, SKNPDFAnnotationBorderKey, nil];
    return keys;
}

#pragma mark Scripting support

// to support the 'make' command
- (id)init {
    [[self initWithBounds:NSZeroRect] release];
    self = nil;
    NSScriptCommand *currentCommand = [NSScriptCommand currentCommand];
    if ([currentCommand isKindOfClass:[NSCreateCommand class]]) {
        FourCharCode classCode = [[(NSCreateCommand *)currentCommand createClassDescription] appleEventCode];
        NSRect bounds = NSMakeRect(100.0, 100.0, 0.0, 0.0);
        bounds.size.width = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteWidthKey];
        bounds.size.height = [[NSUserDefaults standardUserDefaults] floatForKey:SKDefaultNoteHeightKey];
       
        if (classCode == SKPDFAnnotationScriptingNoteClassCode) {
            
            NSDictionary *properties = [(NSCreateCommand *)currentCommand resolvedKeyDictionary];
            FourCharCode type = [[properties objectForKey:SKPDFAnnotationScriptingNoteTypeKey] unsignedLongValue];
            
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
                    if (self = [[PDFAnnotationMarkup alloc] initNoteWithSelection:selection markupType:markupType]) {
                        PDFPage *page = [[selection pages] objectAtIndex:0];
                        if (page && [self respondsToSelector:@selector(setPage:)])
                            [self performSelector:@selector(setPage:) withObject:page];
                    }
                }
            } else if (type == SKScriptingTextNote) {
                self = [[PDFAnnotationFreeText alloc] initSkimNoteWithBounds:bounds];
            } else if (type == SKScriptingAnchoredNote) {
                bounds.size = SKNPDFAnnotationNoteSize;
                self = [[SKNPDFAnnotationNote alloc] initSkimNoteWithBounds:bounds];
            } else if (type == SKScriptingCircleNote) {
                self = [[PDFAnnotationCircle alloc] initSkimNoteWithBounds:bounds];
            } else if (type == SKScriptingSquareNote) {
                self = [[PDFAnnotationSquare alloc] initSkimNoteWithBounds:bounds];
            } else if (type == SKScriptingLineNote) {
                self = [[PDFAnnotationLine alloc] initSkimNoteWithBounds:bounds];
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
        return [[PDFAnnotation allocWithZone:zone] initSkimNoteWithProperties:[self SkimNoteProperties]];
    else
        return nil;
}

// overridden by subclasses to add or remove custom scripting keys relevant for the class, subclasses should call super first
+ (NSSet *)customScriptingKeys {
    static NSSet *customScriptingKeys = nil;
    if (customScriptingKeys == nil)
        customScriptingKeys = [[NSSet alloc] initWithObjects:SKNPDFAnnotationLineWidthKey, SKPDFAnnotationScriptingBorderStyleKey, SKNPDFAnnotationDashPatternKey, nil];
    return customScriptingKeys;
}

- (NSDictionary *)scriptingProperties {
    // remove all custom properties that are not valid for this class
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    NSMutableSet *customKeys = [[NSMutableSet alloc] init];
    [customKeys unionSet:[PDFAnnotationCircle customScriptingKeys]];
    [customKeys unionSet:[PDFAnnotationSquare customScriptingKeys]];
    [customKeys unionSet:[PDFAnnotationFreeText customScriptingKeys]];
    [customKeys unionSet:[SKNPDFAnnotationNote customScriptingKeys]];
    [customKeys unionSet:[PDFAnnotationLine customScriptingKeys]];
    [customKeys unionSet:[PDFAnnotationMarkup customScriptingKeys]];
    [customKeys minusSet:[[self class] customScriptingKeys]];
    [properties removeObjectsForKeys:[customKeys allObjects]];
    [customKeys release];
    return properties;
}

- (FourCharCode)scriptingNoteType {
    if ([[self type] isEqualToString:SKNFreeTextString])
        return SKScriptingTextNote;
    else if ([[self type] isEqualToString:SKNNoteString])
        return SKScriptingAnchoredNote;
    else if ([[self type] isEqualToString:SKNCircleString])
        return SKScriptingCircleNote;
    else if ([[self type] isEqualToString:SKNSquareString])
        return SKScriptingSquareNote;
    else if ([[self type] isEqualToString:SKNHighlightString] || [[self type] isEqualToString:SKNMarkUpString])
        return SKScriptingHighlightNote;
    else if ([[self type] isEqualToString:SKNUnderlineString])
        return SKScriptingUnderlineNote;
    else if ([[self type] isEqualToString:SKNStrikeOutString])
        return SKScriptingStrikeOutNote;
    else if ([[self type] isEqualToString:SKNLineString])
        return SKScriptingLineNote;
    return 0;
}

- (void)setScriptingNoteType:(FourCharCode)type {
    NSScriptCommand *currentCommand = [NSScriptCommand currentCommand];
    if ([currentCommand isKindOfClass:[NSCreateCommand class]] == NO)
        [currentCommand setScriptErrorNumber:NSReceiversCantHandleCommandScriptError]; 
}

- (FourCharCode)scriptingIconType {
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
        NSRect newBounds = SKNSRectFromQDRect(*qdBounds);
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
    Rect qdBounds = SKQDRectFromNSRect([self bounds]);
    return [NSData dataWithBytes:&qdBounds length:sizeof(Rect)];
}

- (NSString *)fontName {
    return (id)[NSNull null];
}

- (float)fontSize {
    return 0;
}

- (FourCharCode)scriptingBorderStyle {
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

- (FourCharCode)scriptingStartLineStyle {
    return SKScriptingLineStyleNone;
}

- (FourCharCode)scriptingEndLineStyle {
    return SKScriptingLineStyleNone;
}

- (id)selectionSpecifier {
    return [NSNull null];
}

#pragma mark Accessibility

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil) {
        attributes = [[NSArray alloc] initWithObjects:
            NSAccessibilityRoleAttribute,
            NSAccessibilityRoleDescriptionAttribute,
            NSAccessibilityTitleAttribute,
            NSAccessibilityValueAttribute,
            NSAccessibilityParentAttribute,
            NSAccessibilityWindowAttribute,
            NSAccessibilityTopLevelUIElementAttribute,
            NSAccessibilityFocusedAttribute,
            NSAccessibilityEnabledAttribute,
            NSAccessibilityPositionAttribute,
            NSAccessibilitySizeAttribute,
            nil];
    }
    return attributes;
}

- (id)accessibilityRoleAttribute {
    return NSAccessibilityUnknownRole;
}

- (id)accessibilityRoleDescriptionAttribute {
    return NSAccessibilityRoleDescription([self accessibilityRoleAttribute], nil);
}

- (id)accessibilityTitleAttribute {
    return [[self type] typeName];
}

- (id)accessibilityValueAttribute {
    return [self contents];
}

- (id)accessibilityEnabledAttribute {
    return [NSNumber numberWithBool:NO];
}

- (BOOL)accessibilityIsIgnored {
    return [self shouldDisplay] == NO;
}

@end
