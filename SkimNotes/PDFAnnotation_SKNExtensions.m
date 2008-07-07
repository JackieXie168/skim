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

NSString *SKNPDFAnnotationInteriorColorKey = @"interiorColor";

NSString *SKNPDFAnnotationStartLineStyleKey = @"startLineStyle";
NSString *SKNPDFAnnotationEndLineStyleKey = @"endLineStyle";
NSString *SKNPDFAnnotationStartPointKey = @"startPoint";
NSString *SKNPDFAnnotationEndPointKey = @"endPoint";

NSString *SKNPDFAnnotationFontKey = @"font";
NSString *SKNPDFAnnotationFontColorKey = @"fontColor";
NSString *SKNPDFAnnotationFontNameKey = @"fontName";
NSString *SKNPDFAnnotationFontSizeKey = @"fontSize";
NSString *SKNPDFAnnotationRotationKey = @"rotation";

NSString *SKNPDFAnnotationQuadrilateralPointsKey = @"quadrilateralPoints";

NSString *SKNPDFAnnotationIconTypeKey = @"iconType";

@implementation PDFAnnotation (SKNExtensions)

static CFMutableSetRef SkimNotes = NULL;

static IMP originalDealloc = NULL;

- (void)skn_replacementDealloc {
    CFSetRemoveValue(SkimNotes, self);
    originalDealloc(self, _cmd);
}

+ (void)load {
    Method aMethod = class_getInstanceMethod(self, @selector(dealloc));
    Method impMethod = class_getInstanceMethod(self, @selector(skn_replacementDealloc));
    IMP anImp = NULL;
    if (method_getImplementation != NULL && method_setImplementation != NULL) {
        originalDealloc = method_setImplementation(aMethod, method_getImplementation(impMethod));
    } else {
        originalDealloc = aMethod->method_imp;
        aMethod->method_imp = impMethod->method_imp;
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

- (NSDictionary *)SkimNoteProperties{
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

#pragma mark -

@implementation PDFAnnotationCircle (SKNExtensions)

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    if (self = [super initSkimNoteWithProperties:dict]) {
        Class colorClass = [NSColor class];
        NSColor *interiorColor = [dict objectForKey:SKNPDFAnnotationInteriorColorKey];
        if ([interiorColor isKindOfClass:colorClass])
            [self setInteriorColor:interiorColor];
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties{
    NSMutableDictionary *dict = [[[super SkimNoteProperties] mutableCopy] autorelease];
    [dict setValue:[self interiorColor] forKey:SKNPDFAnnotationInteriorColorKey];
    return dict;
}

@end

#pragma mark -

@implementation PDFAnnotationSquare (SKNExtensions)

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    if (self = [super initSkimNoteWithProperties:dict]) {
        Class colorClass = [NSColor class];
        NSColor *interiorColor = [dict objectForKey:SKNPDFAnnotationInteriorColorKey];
        if ([interiorColor isKindOfClass:colorClass])
            [self setInteriorColor:interiorColor];
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties{
    NSMutableDictionary *dict = [[[super SkimNoteProperties] mutableCopy] autorelease];
    [dict setValue:[self interiorColor] forKey:SKNPDFAnnotationInteriorColorKey];
    return dict;
}

@end

#pragma mark -

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

- (NSDictionary *)SkimNoteProperties {
    NSMutableDictionary *dict = [[[super SkimNoteProperties] mutableCopy] autorelease];
    [dict setValue:[NSNumber numberWithInt:[self startLineStyle]] forKey:SKNPDFAnnotationStartLineStyleKey];
    [dict setValue:[NSNumber numberWithInt:[self endLineStyle]] forKey:SKNPDFAnnotationEndLineStyleKey];
    [dict setValue:NSStringFromPoint([self startPoint]) forKey:SKNPDFAnnotationStartPointKey];
    [dict setValue:NSStringFromPoint([self endPoint]) forKey:SKNPDFAnnotationEndPointKey];
    return dict;
}

@end

#pragma mark -

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

- (NSDictionary *)SkimNoteProperties{
    NSMutableDictionary *dict = [[[super SkimNoteProperties] mutableCopy] autorelease];
    [dict setValue:[self font] forKey:SKNPDFAnnotationFontKey];
    if ([self respondsToSelector:@selector(fontColor)] && [[self fontColor] isEqual:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]] == NO)
        [dict setValue:[self fontColor] forKey:SKNPDFAnnotationFontColorKey];
    if ([self respondsToSelector:@selector(rotation)])
        [dict setValue:[NSNumber numberWithInt:[self rotation]] forKey:SKNPDFAnnotationRotationKey];
    return dict;
}

@end

#pragma mark -

@implementation PDFAnnotationMarkup (SKNExtensions)

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    if (self = [super initSkimNoteWithProperties:dict]) {
        Class stringClass = [NSString class];
        NSString *type = [dict objectForKey:SKNPDFAnnotationTypeKey];
        if ([type isKindOfClass:stringClass]) {
            PDFMarkupType markupType = kPDFMarkupTypeHighlight;
            if ([type isEqualToString:SKNUnderlineString])
                markupType = kPDFMarkupTypeUnderline;
            else if ([type isKindOfClass:stringClass] && [type isEqualToString:SKNStrikeOutString])
                markupType = kPDFMarkupTypeStrikeOut;
            if (markupType != [self markupType]) {
                [self setMarkupType:markupType];
                if ([dict objectForKey:SKNPDFAnnotationColorKey] == nil && [[self class] respondsToSelector:@selector(defaultSkimNoteColorForMarkupType:)]) {
                    NSColor *color = [[self class] defaultSkimNoteColorForMarkupType:markupType];
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

- (NSDictionary *)SkimNoteProperties {
    NSMutableDictionary *dict = [[[super SkimNoteProperties] mutableCopy] autorelease];
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

#pragma mark -

@implementation PDFAnnotationText (SKNExtensions)

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    if (self = [super initSkimNoteWithProperties:dict]) {
        NSNumber *iconType = [dict objectForKey:SKNPDFAnnotationIconTypeKey];
        if ([iconType respondsToSelector:@selector(intValue)])
            [self setIconType:[iconType intValue]];
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties{
    NSMutableDictionary *dict = [[[super SkimNoteProperties] mutableCopy] autorelease];
    [dict setValue:[NSNumber numberWithInt:[self iconType]] forKey:SKNPDFAnnotationIconTypeKey];
    return dict;
}

@end
