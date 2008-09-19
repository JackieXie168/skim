//
//  PDFAnnotationFreeText_SKExtensions.m
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

#import "PDFAnnotationFreeText_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "PDFBorder_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "NSUserDefaults_SKExtensions.h"

NSString *SKPDFAnnotationScriptingFontColorKey = @"scriptingFontColor";

@interface PDFAnnotationFreeText (SKNPDFAnnotationFreeTextPrivateDeclarations)
- (int)rotation;
- (void)setRotation:(int)rotation;
@end


@implementation PDFAnnotationFreeText (SKExtensions)

- (id)initSkimNoteWithBounds:(NSRect)bounds {
    if (self = [super initSkimNoteWithBounds:bounds]) {
        NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:SKTextNoteFontNameKey]
                                       size:[[NSUserDefaults standardUserDefaults] floatForKey:SKTextNoteFontSizeKey]];
        if (font)
            [self setFont:font];
        [self setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKFreeTextNoteColorKey]];
        if ([self respondsToSelector:@selector(setFontColor:)])
            [self setFontColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKFreeTextNoteFontColorKey]];
        PDFBorder *border = [[PDFBorder allocWithZone:[self zone]] init];
        [border setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKFreeTextNoteLineWidthKey]];
        [border setDashPattern:[[NSUserDefaults standardUserDefaults] arrayForKey:SKFreeTextNoteDashPatternKey]];
        [border setStyle:[[NSUserDefaults standardUserDefaults] floatForKey:SKFreeTextNoteLineStyleKey]];
        [self setBorder:[border lineWidth] > 0.0 ? border : nil];
        [border release];
    }
    return self;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    [fdfString appendFDFName:SKFDFDefaultAppearanceKey];
    [fdfString appendFormat:@"(/%@ %f Tf", [[self font] fontName], [[self font] pointSize]];
    if ([self respondsToSelector:@selector(fontColor)] && [[self fontColor] isEqual:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]] == NO) {
        float r = 0.0, g = 0.0, b = 0.0, a;
        [[self fontColor] getRed:&r green:&g blue:&b alpha:&a];
        [fdfString appendFormat:@" %f %f %f rg", r, g, b];
    }
    [fdfString appendString:@")"];
    [fdfString appendFDFName:SKFDFDefaultStyleKey];
    [fdfString appendFormat:@"(font: %@ %fpt)", [[self font] fontName], [[self font] pointSize]];
    return fdfString;
}

- (BOOL)isResizable { return [self isSkimNote]; }

- (BOOL)isMovable { return [self isSkimNote]; }

- (BOOL)isEditable { return [self isSkimNote]; }

- (BOOL)isConvertibleAnnotation { return YES; }

- (NSSet *)keysForValuesToObserveForUndo {
    static NSSet *freeTextKeys = nil;
    if (freeTextKeys == nil) {
        NSMutableSet *mutableKeys = [[super keysForValuesToObserveForUndo] mutableCopy];
        [mutableKeys addObject:SKNPDFAnnotationFontKey];
        [mutableKeys addObject:SKNPDFAnnotationFontColorKey];
        freeTextKeys = [mutableKeys copy];
        [mutableKeys release];
    }
    return freeTextKeys;
}

#pragma mark Scripting support

+ (NSSet *)customScriptingKeys {
    static NSSet *customFreeTextScriptingKeys = nil;
    if (customFreeTextScriptingKeys == nil) {
        NSMutableSet *customKeys = [[super customScriptingKeys] mutableCopy];
        [customKeys addObject:SKNPDFAnnotationFontNameKey];
        [customKeys addObject:SKNPDFAnnotationFontSizeKey];
        [customKeys addObject:SKPDFAnnotationScriptingFontColorKey];
        customFreeTextScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customFreeTextScriptingKeys;
}

- (FourCharCode)scriptingNoteType {
    return SKScriptingTextNote;
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

- (NSColor *)scriptingFontColor {
    return [self respondsToSelector:@selector(fontColor)] ? [self fontColor] : [NSColor blackColor];
}

- (void)setScriptingFontColor:(NSColor *)newScriptingFontColor {
    if ([self respondsToSelector:@selector(setFontColor:)])
        [self setFontColor:newScriptingFontColor];
}

#pragma mark Accessibility

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil) {
        attributes = [[[super accessibilityAttributeNames] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:
            NSAccessibilitySelectedTextAttribute,
            NSAccessibilitySelectedTextRangeAttribute,
            NSAccessibilityNumberOfCharactersAttribute,
            NSAccessibilityVisibleCharacterRangeAttribute,
            nil]] retain];
    }
    return attributes;
}

- (id)accessibilityRoleAttribute {
    return NSAccessibilityStaticTextRole;
}

- (id)accessibilitySelectedTextAttribute {
    return @"";
}

- (id)accessibilitySelectedTextRangeAttribute {
    return [NSValue valueWithRange:NSMakeRange(0, 0)];
}

- (id)accessibilityNumberOfCharactersAttribute {
    return [NSNumber numberWithUnsignedInt:[[self accessibilityValueAttribute] length]];
}

- (id)accessibilityVisibleCharacterRangeAttribute {
    return [NSValue valueWithRange:NSMakeRange(0, [[self accessibilityValueAttribute] length])];
}

- (id)accessibilityEnabledAttribute {
    return [NSNumber numberWithBool:YES];
}

- (NSArray *)accessibilityActionNames {
    return [NSArray arrayWithObject:NSAccessibilityPressAction];
}

@end
