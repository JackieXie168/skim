//
//  PDFAnnotationMarkup_SKNExtensions.m
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

#import <SkimNotes/PDFAnnotationMarkup_SKNExtensions.h>
#import <SkimNotes/PDFAnnotation_SKNExtensions.h>

NSString *SKNPDFAnnotationQuadrilateralPointsKey = @"quadrilateralPoints";


@implementation PDFAnnotationMarkup (SKNExtensions)

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    if (self = [super initSkimNoteWithProperties:dict]) {
        Class stringClass = [NSString class];
        NSString *type = [dict objectForKey:SKNPDFAnnotationTypeKey];
        if ([type isKindOfClass:stringClass]) {
            int markupType = kPDFMarkupTypeHighlight;
            if ([type isEqualToString:SKNUnderlineString])
                markupType = kPDFMarkupTypeUnderline;
            else if ([type isKindOfClass:stringClass] && [type isEqualToString:SKNStrikeOutString])
                markupType = kPDFMarkupTypeStrikeOut;
            if (markupType != [self markupType]) {
                [self setMarkupType:markupType];
                if ([dict objectForKey:SKNPDFAnnotationColorKey] == nil && [[self class] respondsToSelector:@selector(defaultColorForMarkupType:)]) {
                    NSColor *color = [[self class] defaultColorForMarkupType:markupType];
                    if (color)
                        [self setColor:color];
                }
            }
        }
        
        Class arrayClass = [NSArray class];
        NSArray *pointStrings = [dict objectForKey:SKNPDFAnnotationQuadrilateralPointsKey];
        if ([pointStrings isKindOfClass:arrayClass]) {
            int i, iMax = [pointStrings count];
            NSMutableArray *quadPoints = [[NSMutableArray alloc] initWithCapacity:iMax];
            for (i = 0; i < iMax; i++) {
                NSPoint p = NSPointFromString([pointStrings objectAtIndex:i]);
                NSValue *value = [[NSValue alloc] initWithBytes:&p objCType:@encode(NSPoint)];
                [quadPoints addObject:value];
                [value release];
            }
            [self setQuadrilateralPoints:quadPoints];
            [quadPoints release];
        }
        
    }
    return self;
}

- (NSDictionary *)properties {
    NSMutableDictionary *dict = [[[super properties] mutableCopy] autorelease];
    NSArray *quadPoints = [self quadrilateralPoints];
    if (quadPoints) {
        int i, iMax = [quadPoints count];
        NSMutableArray *quadPointStrings = [[NSMutableArray alloc] initWithCapacity:iMax];
        for (i = 0; i < iMax; i++)
            [quadPointStrings addObject:NSStringFromPoint([[quadPoints objectAtIndex:i] pointValue])];
        [dict setValue:quadPointStrings forKey:SKNPDFAnnotationQuadrilateralPointsKey];
        [quadPointStrings release];
    }
    return dict;
}

@end
