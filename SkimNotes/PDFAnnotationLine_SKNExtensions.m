//
//  PDFAnnotationLine_SKNExtensions.m
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

#import <SkimNotes/PDFAnnotationLine_SKNExtensions.h>
#import <SkimNotes/PDFAnnotation_SKNExtensions.h>

NSString *SKNPDFAnnotationStartLineStyleKey = @"startLineStyle";
NSString *SKNPDFAnnotationEndLineStyleKey = @"endLineStyle";
NSString *SKNPDFAnnotationStartPointKey = @"startPoint";
NSString *SKNPDFAnnotationEndPointKey = @"endPoint";


@implementation PDFAnnotationLine (SKNExtensions)

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    if (self = [super initSkimNoteWithProperties:dict]) {
        Class stringClass = [NSString class];
        NSString *startPoint = [dict objectForKey:SKNPDFAnnotationStartPointKey];
        NSString *endPoint = [dict objectForKey:SKNPDFAnnotationEndPointKey];
        NSNumber *startLineStyle = [dict objectForKey:SKNPDFAnnotationStartLineStyleKey];
        NSNumber *endLineStyle = [dict objectForKey:SKNPDFAnnotationEndLineStyleKey];
        if ([startPoint isKindOfClass:stringClass])
            [self setStartPoint:NSPointFromString(startPoint)];
        if ([endPoint isKindOfClass:stringClass])
            [self setEndPoint:NSPointFromString(endPoint)];
        if ([startLineStyle respondsToSelector:@selector(intValue)])
            [self setStartLineStyle:[startLineStyle intValue]];
        if ([endLineStyle respondsToSelector:@selector(intValue)])
            [self setEndLineStyle:[endLineStyle intValue]];
    }
    return self;
}

- (NSDictionary *)properties {
    NSMutableDictionary *dict = [[[super properties] mutableCopy] autorelease];
    [dict setValue:[NSNumber numberWithInt:[self startLineStyle]] forKey:SKNPDFAnnotationStartLineStyleKey];
    [dict setValue:[NSNumber numberWithInt:[self endLineStyle]] forKey:SKNPDFAnnotationEndLineStyleKey];
    [dict setValue:NSStringFromPoint([self startPoint]) forKey:SKNPDFAnnotationStartPointKey];
    [dict setValue:NSStringFromPoint([self endPoint]) forKey:SKNPDFAnnotationEndPointKey];
    return dict;
}

@end
