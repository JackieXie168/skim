//
//  PDFAnnotationFreeText_SKExtensions.m
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

#import "PDFAnnotationFreeText_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "NSUserDefaults_SKExtensions.h"


NSString *SKPDFAnnotationScriptingFontColorKey = @"scriptingFontColor";
NSString *SKPDFAnnotationScriptingAlignmentKey = @"scriptingAlignment";


@implementation PDFAnnotationFreeText (SKExtensions)

- (id)initSkimNoteWithBounds:(NSRect)bounds {
    self = [super initSkimNoteWithBounds:bounds];
    if (self) {
        NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:SKFreeTextNoteFontNameKey]
                                       size:[[NSUserDefaults standardUserDefaults] floatForKey:SKFreeTextNoteFontSizeKey]];
        if (font)
            [self setFont:font];
        [self setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKFreeTextNoteColorKey]];
        [self setFontColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKFreeTextNoteFontColorKey]];
        [self setAlignment:[[NSUserDefaults standardUserDefaults] integerForKey:SKFreeTextNoteAlignmentKey]];
        PDFBorder *border = [[PDFBorder allocWithZone:[self zone]] init];
        [border setLineWidth:[[NSUserDefaults standardUserDefaults] floatForKey:SKFreeTextNoteLineWidthKey]];
        [border setDashPattern:[[NSUserDefaults standardUserDefaults] arrayForKey:SKFreeTextNoteDashPatternKey]];
        [border setStyle:[[NSUserDefaults standardUserDefaults] floatForKey:SKFreeTextNoteLineStyleKey]];
        [self setBorder:[border lineWidth] > 0.0 ? border : nil];
        [border release];
    }
    return self;
}

static inline NSString *alignmentStyleKeyword(NSTextAlignment alignment) {
    switch (alignment) {
        case NSLeftTextAlignment: return @"left";
        case NSRightTextAlignment: return @"right";
        case NSCenterTextAlignment: return @"center";
        default: return @"left";
    }
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    CGFloat r = 0.0, g = 0.0, b = 0.0, a;
    [[self fontColor] getRed:&r green:&g blue:&b alpha:&a];
    [fdfString appendFDFName:SKFDFDefaultAppearanceKey];
    [fdfString appendFormat:@"(/%@ %f Tf %f %f %f rg)", [self fontName], [self fontSize], r, g, b];
    [fdfString appendFDFName:SKFDFDefaultStyleKey];
    [fdfString appendFormat:@"(font: %@ %fpt; text-align:%@; color:#%.2x%.2x%.2x)", [self fontName], [self fontSize], alignmentStyleKeyword([self alignment]), (unsigned int)(255*r), (unsigned int)(255*g), (unsigned int)(255*b)];
    [fdfString appendFDFName:SKFDFAnnotationAlignmentKey];
    [fdfString appendFormat:@" %ld", (long)SKFDFFreeTextAnnotationAlignmentFromPDFFreeTextAnnotationAlignment([self alignment])];
    return fdfString;
}

- (BOOL)isResizable { return [self isSkimNote]; }

- (BOOL)isMovable { return [self isSkimNote]; }

- (BOOL)isConvertibleAnnotation { return YES; }

- (NSSet *)keysForValuesToObserveForUndo {
    static NSSet *freeTextKeys = nil;
    if (freeTextKeys == nil) {
        NSMutableSet *mutableKeys = [[super keysForValuesToObserveForUndo] mutableCopy];
        [mutableKeys addObject:SKNPDFAnnotationFontKey];
        [mutableKeys addObject:SKNPDFAnnotationFontColorKey];
        [mutableKeys addObject:SKNPDFAnnotationAlignmentKey];
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
        [customKeys addObject:SKPDFAnnotationScriptingAlignmentKey];
        customFreeTextScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customFreeTextScriptingKeys;
}

- (id)textContents {
    NSTextStorage *textContents = [super textContents];
    if ([self font])
        [textContents addAttribute:NSFontAttributeName value:[self font] range:NSMakeRange(0, [textContents length])];
    if ([self fontColor])
        [textContents addAttribute:NSForegroundColorAttributeName value:[self fontColor] range:NSMakeRange(0, [textContents length])];
    return textContents;
}

- (NSString *)fontName {
    return [[self font] fontName];
}

- (void)setFontName:(NSString *)fontName {
    if ([self isEditable]) {
        NSFont *font = [NSFont fontWithName:fontName size:[[self font] pointSize]];
        if (font)
            [self setFont:font];
    }
}

- (CGFloat)fontSize {
    return [[self font] pointSize];
}

- (void)setFontSize:(CGFloat)pointSize {
    if ([self isEditable]) {
        NSFont *font = [NSFont fontWithName:[[self font] fontName] size:pointSize];
        if (font)
            [self setFont:font];
    }
}

- (NSColor *)scriptingFontColor {
    return [self fontColor];
}

- (void)setScriptingFontColor:(NSColor *)newScriptingFontColor {
    if ([self isEditable]) {
        [self setFontColor:newScriptingFontColor];
    }
}

- (NSTextAlignment)scriptingAlignment {
    return [self alignment];
}

- (void)setScriptingAlignment:(NSTextAlignment)alignment {
    if ([self isEditable]) {
        [self setAlignment:alignment];
    }
}

#pragma mark Accessibility

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil) {
        attributes = [[[super accessibilityAttributeNames] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:
            NSAccessibilityValueAttribute,
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

- (id)accessibilityValueAttribute {
    return [self contents];
}

- (id)accessibilitySelectedTextAttribute {
    return @"";
}

- (id)accessibilitySelectedTextRangeAttribute {
    return [NSValue valueWithRange:NSMakeRange(0, 0)];
}

- (id)accessibilityNumberOfCharactersAttribute {
    return [NSNumber numberWithUnsignedInteger:[[self accessibilityValueAttribute] length]];
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
