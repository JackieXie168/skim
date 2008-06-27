//
//  PDFAnnotationFreeText_SKNExtensions.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 6/15/08.
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

#import <SkimNotes/PDFAnnotationFreeText_SKNExtensions.h>
#import <SkimNotes/PDFAnnotation_SKNExtensions.h>

NSString *SKNPDFAnnotationFontKey = @"font";
NSString *SKNPDFAnnotationFontColorKey = @"fontColor";
NSString *SKNPDFAnnotationFontNameKey = @"fontName";
NSString *SKNPDFAnnotationFontSizeKey = @"fontSize";
NSString *SKNPDFAnnotationRotationKey = @"rotation";


@interface PDFAnnotationFreeText (SKNPDFAnnotationFreeTextPrivateDeclarations)
- (int)rotation;
- (void)setRotation:(int)rotation;
@end


@implementation PDFAnnotationFreeText (SKNExtensions)

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    if (self = [super initSkimNoteWithProperties:dict]) {
        Class fontClass = [NSFont class];
        Class colorClass = [NSColor class];
        NSFont *font = [dict objectForKey:SKNPDFAnnotationFontKey];
        NSColor *fontColor = [dict objectForKey:SKNPDFAnnotationFontColorKey];
        NSNumber *rotation = [dict objectForKey:SKNPDFAnnotationRotationKey];
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
    [dict setValue:[self font] forKey:SKNPDFAnnotationFontKey];
    if ([self respondsToSelector:@selector(fontColor)] && [[self fontColor] isEqual:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]] == NO)
        [dict setValue:[self fontColor] forKey:SKNPDFAnnotationFontColorKey];
    if ([self respondsToSelector:@selector(rotation)])
        [dict setValue:[NSNumber numberWithInt:[self rotation]] forKey:SKNPDFAnnotationRotationKey];
    return dict;
}

@end
