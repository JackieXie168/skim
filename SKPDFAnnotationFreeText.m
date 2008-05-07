//
//  SKPDFAnnotationFreeText.m
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

#import "SKPDFAnnotationFreeText.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFBorder_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "NSUserDefaultsController_SKExtensions.h"

NSString *SKPDFAnnotationFontKey = @"font";
NSString *SKPDFAnnotationFontColorKey = @"fontColor";
NSString *SKPDFAnnotationFontNameKey = @"fontName";
NSString *SKPDFAnnotationFontSizeKey = @"fontSize";
NSString *SKPDFAnnotationRotationKey = @"rotation";


@interface PDFAnnotationFreeText (SKPDFAnnotationFreeTextPrivateDeclarations)
- (int)rotation;
- (void)setRotation:(int)rotation;
@end


@implementation SKPDFAnnotationFreeText

- (id)initNoteWithBounds:(NSRect)bounds {
    if (self = [super initNoteWithBounds:bounds]) {
        [self setShouldPrint:YES];
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

- (id)initWithProperties:(NSDictionary *)dict{
    if (self = [super initWithProperties:dict]) {
        Class fontClass = [NSFont class];
        Class colorClass = [NSColor class];
        NSFont *font = [dict objectForKey:SKPDFAnnotationFontKey];
        NSColor *fontColor = [dict objectForKey:SKPDFAnnotationFontColorKey];
        NSNumber *rotation = [dict objectForKey:SKPDFAnnotationRotationKey];
        if ([font isKindOfClass:fontClass])
            [self setFont:font];
        if ([fontColor isKindOfClass:colorClass] && [self respondsToSelector:@selector(setFontColor:)])
            [self setFontColor:fontColor];
        if ([rotation respondsToSelector:@selector(intValue)] && [self respondsToSelector:@selector(setRotation:)])
            [self setRotation:[rotation intValue]];
    }
    return self;
}

- (NSDictionary *)properties{
    NSMutableDictionary *dict = [[[super properties] mutableCopy] autorelease];
    [dict setValue:[self font] forKey:SKPDFAnnotationFontKey];
    if ([self respondsToSelector:@selector(fontColor)] && [[self fontColor] isEqual:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]] == NO)
        [dict setValue:[self fontColor] forKey:SKPDFAnnotationFontColorKey];
    if ([self respondsToSelector:@selector(rotation)])
        [dict setValue:[NSNumber numberWithInt:[self rotation]] forKey:SKPDFAnnotationRotationKey];
    return dict;
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

- (BOOL)isNote { return YES; }

- (BOOL)isResizable { return YES; }

- (BOOL)isMovable { return YES; }

- (BOOL)isEditable { return YES; }

- (NSSet *)keysForValuesToObserveForUndo {
    static NSSet *freeTextKeys = nil;
    if (freeTextKeys == nil) {
        NSMutableSet *mutableKeys = [[super keysForValuesToObserveForUndo] mutableCopy];
        [mutableKeys addObject:SKPDFAnnotationFontKey];
        [mutableKeys addObject:SKPDFAnnotationFontColorKey];
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
        [customKeys addObject:SKPDFAnnotationFontNameKey];
        [customKeys addObject:SKPDFAnnotationFontSizeKey];
        customFreeTextScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customFreeTextScriptingKeys;
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

#pragma mark -

@interface PDFAnnotationFreeText (SKExtensions)
@end

@implementation PDFAnnotationFreeText (SKExtensions)

- (BOOL)isConvertibleAnnotation { return YES; }

- (id)copyNoteAnnotation {
    SKPDFAnnotationFreeText *annotation = [[SKPDFAnnotationFreeText alloc] initNoteWithBounds:[self bounds]];
    [annotation setString:[self string]];
    [annotation setColor:[self color]];
    [annotation setBorder:[[[self border] copy] autorelease]];
    [annotation setFont:[self font]];
    if ([self respondsToSelector:@selector(rotation)] && [annotation respondsToSelector:@selector(setRotation:)])
        [annotation setRotation:[self rotation]];
    return annotation;
}

@end
