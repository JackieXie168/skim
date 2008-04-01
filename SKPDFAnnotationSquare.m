//
//  SKPDFAnnotationSquare.m
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

#import "SKPDFAnnotationSquare.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFBorder_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"


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
        NSColor *interiorColor = [dict objectForKey:SKPDFAnnotationInteriorColorKey];
        if ([interiorColor isKindOfClass:colorClass])
            [self setInteriorColor:interiorColor];
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = [[[super dictionaryValue] mutableCopy] autorelease];
    [dict setValue:[self interiorColor] forKey:SKPDFAnnotationInteriorColorKey];
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
