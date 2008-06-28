//
//  PDFAnnotation_SKNExtensions.m
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

#import <SkimNotes/PDFAnnotation_SKNExtensions.h>
#import <SkimNotes/PDFAnnotationCircle_SKNExtensions.h>
#import <SkimNotes/PDFAnnotationSquare_SKNExtensions.h>
#import <SkimNotes/PDFAnnotationLine_SKNExtensions.h>
#import <SkimNotes/PDFAnnotationMarkup_SKNExtensions.h>
#import <SkimNotes/PDFAnnotationFreeText_SKNExtensions.h>
#import <SkimNotes/SKNPDFAnnotationNote.h>
#import <objc/objc.h>
#import <objc/objc-class.h>
#import <objc/objc-runtime.h>

NSString *SKNFreeTextString = @"FreeText";
NSString *SKNTextString = @"Text";
NSString *SKNNoteString = @"Note";
NSString *SKNCircleString = @"Circle";
NSString *SKNSquareString = @"Square";
NSString *SKNMarkUpString = @"MarkUp";
NSString *SKNHighlightString = @"Highlight";
NSString *SKNUnderlineString = @"Underline";
NSString *SKNStrikeOutString = @"StrikeOut";
NSString *SKNLineString = @"Line";

NSString *SKNPDFAnnotationTypeKey = @"type";
NSString *SKNPDFAnnotationBoundsKey = @"bounds";
NSString *SKNPDFAnnotationPageKey = @"page";
NSString *SKNPDFAnnotationPageIndexKey = @"pageIndex";
NSString *SKNPDFAnnotationContentsKey = @"contents";
NSString *SKNPDFAnnotationStringKey = @"string";
NSString *SKNPDFAnnotationColorKey = @"color";
NSString *SKNPDFAnnotationBorderKey = @"border";
NSString *SKNPDFAnnotationLineWidthKey = @"lineWidth";
NSString *SKNPDFAnnotationBorderStyleKey = @"borderStyle";
NSString *SKNPDFAnnotationDashPatternKey = @"dashPattern";


@implementation PDFAnnotation (SKNExtensions)

static CFMutableSetRef SkimNotes = NULL;

static IMP originalDealloc = NULL;

- (void)replacementDealloc {
    CFSetRemoveValue(SkimNotes, self);
    originalDealloc(self, _cmd);
}

+ (void)load {
    if (method_getImplementation != NULL && method_setImplementation != NULL) {
        originalDealloc = method_setImplementation(class_getInstanceMethod(self, @selector(dealloc)), method_getImplementation(class_getInstanceMethod(self, @selector(replacementDealloc))));
    } else {
        Method impMethod = class_getInstanceMethod(self, @selector(replacementDealloc));
        IMP anImp = impMethod->method_imp;
        Method aMethod = class_getInstanceMethod(self, @selector(dealloc));
        
        originalDealloc = aMethod->method_imp;
        aMethod->method_imp = anImp;
        
        // Flush the method cache
        extern void _objc_flush_caches(Class);
        if (_objc_flush_caches != NULL)
            _objc_flush_caches(self);
    }
    SkimNotes = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
}

- (id)initSkimNoteWithBounds:(NSRect)bounds {
    if (self = [self initWithBounds:bounds]) {
        [self setShouldPrint:YES];
        [self setSkimNote:YES];
    }
    return self;

}

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    Class stringClass = [NSString class];
    
    if ([self isMemberOfClass:[PDFAnnotation class]]) {
        // generic, initalize the class for the type in the dictionary
        NSString *type = [dict objectForKey:SKNPDFAnnotationTypeKey];
        Class annotationClass = NULL;
        NSZone *zone = [self zone];
        
        if ([type isKindOfClass:stringClass] == NO)
            annotationClass = Nil;
        else if ([type isEqualToString:SKNNoteString] || [type isEqualToString:SKNTextString])
            annotationClass = [SKNPDFAnnotationNote class];
        else if ([type isEqualToString:SKNFreeTextString])
            annotationClass = [PDFAnnotationFreeText class];
        else if ([type isEqualToString:SKNCircleString])
            annotationClass = [PDFAnnotationCircle class];
        else if ([type isEqualToString:SKNSquareString])
            annotationClass = [PDFAnnotationSquare class];
        else if ([type isEqualToString:SKNHighlightString] || [type isEqualToString:SKNMarkUpString] || [type isEqualToString:SKNUnderlineString] || [type isEqualToString:SKNStrikeOutString])
            annotationClass = [PDFAnnotationMarkup class];
        else if ([type isEqualToString:SKNLineString])
            annotationClass = [PDFAnnotationLine class];
        
        [[self initWithBounds:NSZeroRect] release];
        self = [[annotationClass allocWithZone:zone] initSkimNoteWithProperties:dict];
        
    } else {
        // called from the initialization of a subclass
        NSString *boundsString = [dict objectForKey:SKNPDFAnnotationBoundsKey];
        NSRect bounds = [boundsString isKindOfClass:stringClass] ? NSRectFromString(boundsString) : NSZeroRect;
        if (self = [self initSkimNoteWithBounds:bounds]) {
            Class colorClass = [NSColor class];
            Class arrayClass = [NSArray class];
            NSString *contents = [dict objectForKey:SKNPDFAnnotationContentsKey];
            NSColor *color = [dict objectForKey:SKNPDFAnnotationColorKey];
            NSNumber *lineWidth = [dict objectForKey:SKNPDFAnnotationLineWidthKey];
            NSNumber *borderStyle = [dict objectForKey:SKNPDFAnnotationBorderStyleKey];
            NSArray *dashPattern = [dict objectForKey:SKNPDFAnnotationDashPatternKey];
            
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
    PDFPage *page = [self page];
    unsigned int pageIndex = page ? [[page document] indexForPage:page] : NSNotFound;
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    [dict setValue:[self type] forKey:SKNPDFAnnotationTypeKey];
    [dict setValue:[self string] forKey:SKNPDFAnnotationContentsKey];
    [dict setValue:[self color] forKey:SKNPDFAnnotationColorKey];
    [dict setValue:NSStringFromRect([self bounds]) forKey:SKNPDFAnnotationBoundsKey];
    [dict setValue:[NSNumber numberWithUnsignedInt:pageIndex] forKey:SKNPDFAnnotationPageIndexKey];
    if ([self border]) {
        [dict setValue:[NSNumber numberWithFloat:[[self border] lineWidth]] forKey:SKNPDFAnnotationLineWidthKey];
        [dict setValue:[NSNumber numberWithInt:[[self border] style]] forKey:SKNPDFAnnotationBorderStyleKey];
        [dict setValue:[[self border] dashPattern] forKey:SKNPDFAnnotationDashPatternKey];
    }
    return dict;
}

- (BOOL)isSkimNote {
    return CFSetContainsValue(SkimNotes, self);
}

- (void)setSkimNote:(BOOL)flag {
    if (flag)
        CFSetAddValue(SkimNotes, self);
    else
        CFSetRemoveValue(SkimNotes, self);
}

- (NSString *)string {
    return [self contents];
}

- (void)setString:(NSString *)newString {
    [self setContents:newString];
}

@end
