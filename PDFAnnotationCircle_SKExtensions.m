//
//  PDFAnnotationCircle_SKExtensions.m
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

#import "PDFAnnotationCircle_SKExtensions.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFBorder_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "NSUserDefaults_SKExtensions.h"

NSString *SKPDFAnnotationInteriorColorKey = @"interiorColor";

@implementation PDFAnnotationCircle (SKExtensions)

- (id)initNoteWithBounds:(NSRect)bounds {
    if (self = [super initNoteWithBounds:bounds]) {
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

- (id)initWithProperties:(NSDictionary *)dict{
    if (self = [super initWithProperties:dict]) {
        Class colorClass = [NSColor class];
        NSColor *interiorColor = [dict objectForKey:SKPDFAnnotationInteriorColorKey];
        if ([interiorColor isKindOfClass:colorClass])
            [self setInteriorColor:interiorColor];
    }
    return self;
}

- (NSDictionary *)properties{
    NSMutableDictionary *dict = [[[super properties] mutableCopy] autorelease];
    [dict setValue:[self interiorColor] forKey:SKPDFAnnotationInteriorColorKey];
    return dict;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [[[super fdfString] mutableCopy] autorelease];
    float r, g, b, a = 0.0;
    [[self interiorColor] getRed:&r green:&g blue:&b alpha:&a];
    if (a > 0.0) {
        [fdfString appendFDFName:SKFDFAnnotationInteriorColorKey];
        [fdfString appendFormat:@"[%f %f %f]", r, g, b];
    }
    return fdfString;
}

- (BOOL)isResizable { return [self isNote]; }

- (BOOL)isMovable { return [self isNote]; }

- (BOOL)isConvertibleAnnotation { return YES; }

- (NSSet *)keysForValuesToObserveForUndo {
    static NSSet *circleKeys = nil;
    if (circleKeys == nil) {
        NSMutableSet *mutableKeys = [[super keysForValuesToObserveForUndo] mutableCopy];
        [mutableKeys addObject:SKPDFAnnotationInteriorColorKey];
        circleKeys = [mutableKeys copy];
        [mutableKeys release];
    }
    return circleKeys;
}

#pragma mark Scripting support

+ (NSSet *)customScriptingKeys {
    static NSSet *customCircleScriptingKeys = nil;
    if (customCircleScriptingKeys == nil) {
        NSMutableSet *customKeys = [[super customScriptingKeys] mutableCopy];
        [customKeys addObject:SKPDFAnnotationInteriorColorKey];
        customCircleScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customCircleScriptingKeys;
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

@end
