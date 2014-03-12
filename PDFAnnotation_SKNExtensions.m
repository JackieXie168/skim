//
//  PDFAnnotation_SKNExtensions.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 6/15/08.
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

#import "PDFAnnotation_SKNExtensions.h"
#import "SKNPDFAnnotationNote.h"
#import <objc/objc-runtime.h>
#import <tgmath.h>

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
NSString *SKNInkString = @"Ink";

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
NSString *SKNPDFAnnotationModificationDateKey = @"modificationDate";
NSString *SKNPDFAnnotationUserNameKey = @"userName";

NSString *SKNPDFAnnotationInteriorColorKey = @"interiorColor";

NSString *SKNPDFAnnotationStartLineStyleKey = @"startLineStyle";
NSString *SKNPDFAnnotationEndLineStyleKey = @"endLineStyle";
NSString *SKNPDFAnnotationStartPointKey = @"startPoint";
NSString *SKNPDFAnnotationEndPointKey = @"endPoint";

NSString *SKNPDFAnnotationFontKey = @"font";
NSString *SKNPDFAnnotationFontColorKey = @"fontColor";
NSString *SKNPDFAnnotationFontNameKey = @"fontName";
NSString *SKNPDFAnnotationFontSizeKey = @"fontSize";
NSString *SKNPDFAnnotationAlignmentKey = @"alignment";
NSString *SKNPDFAnnotationRotationKey = @"rotation";

NSString *SKNPDFAnnotationQuadrilateralPointsKey = @"quadrilateralPoints";

NSString *SKNPDFAnnotationIconTypeKey = @"iconType";

NSString *SKNPDFAnnotationPointListsKey = @"pointLists";

@implementation PDFAnnotation (SKNExtensions)

static NSHashTable *SkimNotes = nil;

static IMP original_dealloc = NULL;

static void replacement_dealloc(id self, SEL _cmd) {
    [SkimNotes removeObject:self];
    original_dealloc(self, _cmd);
}

+ (void)load {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    SkimNotes = [[NSHashTable alloc] initWithOptions:NSHashTableZeroingWeakMemory | NSHashTableObjectPointerPersonality capacity:0];
    original_dealloc = method_setImplementation(class_getInstanceMethod(self, @selector(dealloc)), (IMP)replacement_dealloc);
    [pool release];
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
        else if ([type isEqualToString:SKNInkString])
            annotationClass = [PDFAnnotationInk class];
        
        [[self initWithBounds:NSZeroRect] release];
        self = [[annotationClass allocWithZone:zone] initSkimNoteWithProperties:dict];
        
    } else {
        // called from the initialization of a subclass
        NSString *boundsString = [dict objectForKey:SKNPDFAnnotationBoundsKey];
        NSRect bounds = [boundsString isKindOfClass:stringClass] ? NSRectFromString(boundsString) : NSZeroRect;
        if (self = [self initSkimNoteWithBounds:bounds]) {
            Class colorClass = [NSColor class];
            Class arrayClass = [NSArray class];
            Class dateClass = [NSDate class];
            NSString *contents = [dict objectForKey:SKNPDFAnnotationContentsKey];
            NSColor *color = [dict objectForKey:SKNPDFAnnotationColorKey];
            NSDate *modificationDate = [dict objectForKey:SKNPDFAnnotationModificationDateKey];
            NSString *userName = [dict objectForKey:SKNPDFAnnotationUserNameKey];
            NSNumber *lineWidth = [dict objectForKey:SKNPDFAnnotationLineWidthKey];
            NSNumber *borderStyle = [dict objectForKey:SKNPDFAnnotationBorderStyleKey];
            NSArray *dashPattern = [dict objectForKey:SKNPDFAnnotationDashPatternKey];
            
            if ([contents isKindOfClass:stringClass])
                [self setString:contents];
            if ([color isKindOfClass:colorClass])
                [self setColor:color];
            if ([modificationDate isKindOfClass:dateClass] && [self respondsToSelector:@selector(setModificationDate:)])
                [self setModificationDate:modificationDate];
            if ([userName isKindOfClass:stringClass] && [self respondsToSelector:@selector(setUserName:)])
                [self setUserName:userName];
            if (lineWidth == nil && borderStyle == nil && dashPattern == nil) {
                if ([self border])
                    [self setBorder:nil];
            } else {
                if ([self border] == nil)
                    [self setBorder:[[[PDFBorder alloc] init] autorelease]];
                if ([lineWidth respondsToSelector:@selector(floatValue)])
                    [[self border] setLineWidth:[lineWidth floatValue]];
                if ([dashPattern isKindOfClass:arrayClass])
                    [[self border] setDashPattern:dashPattern];
                if ([borderStyle respondsToSelector:@selector(integerValue)])
                    [[self border] setStyle:[borderStyle integerValue]];
            }
        }
        
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties{
    PDFPage *page = [self page];
    NSUInteger pageIndex = page ? [[page document] indexForPage:page] : NSNotFound;
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    [dict setValue:[self type] forKey:SKNPDFAnnotationTypeKey];
    [dict setValue:[self string] forKey:SKNPDFAnnotationContentsKey];
    [dict setValue:[self color] forKey:SKNPDFAnnotationColorKey];
    if ([self respondsToSelector:@selector(modificationDate)])
        [dict setValue:[self modificationDate] forKey:SKNPDFAnnotationModificationDateKey];
    if ([self respondsToSelector:@selector(userName)])
        [dict setValue:[self userName] forKey:SKNPDFAnnotationUserNameKey];
    [dict setValue:NSStringFromRect([self bounds]) forKey:SKNPDFAnnotationBoundsKey];
    [dict setValue:[NSNumber numberWithUnsignedInteger:pageIndex == NSNotFound ? 0 : pageIndex] forKey:SKNPDFAnnotationPageIndexKey];
    if ([self border]) {
        [dict setValue:[NSNumber numberWithFloat:[[self border] lineWidth]] forKey:SKNPDFAnnotationLineWidthKey];
        [dict setValue:[NSNumber numberWithInteger:[[self border] style]] forKey:SKNPDFAnnotationBorderStyleKey];
        [dict setValue:[[self border] dashPattern] forKey:SKNPDFAnnotationDashPatternKey];
    }
    return dict;
}

- (BOOL)isSkimNote {
    return [SkimNotes containsObject:self];
}

- (void)setSkimNote:(BOOL)flag {
    if (flag) [SkimNotes addObject:self];
    else [SkimNotes removeObject:self];
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
        Class colorClass = [NSColor class];
        NSString *startPoint = [dict objectForKey:SKNPDFAnnotationStartPointKey];
        NSString *endPoint = [dict objectForKey:SKNPDFAnnotationEndPointKey];
        NSNumber *startLineStyle = [dict objectForKey:SKNPDFAnnotationStartLineStyleKey];
        NSNumber *endLineStyle = [dict objectForKey:SKNPDFAnnotationEndLineStyleKey];
        NSColor *interiorColor = [dict objectForKey:SKNPDFAnnotationInteriorColorKey];
        if ([startPoint isKindOfClass:stringClass])
            [self setStartPoint:NSPointFromString(startPoint)];
        if ([endPoint isKindOfClass:stringClass])
            [self setEndPoint:NSPointFromString(endPoint)];
        if ([startLineStyle respondsToSelector:@selector(integerValue)])
            [self setStartLineStyle:[startLineStyle integerValue]];
        if ([endLineStyle respondsToSelector:@selector(integerValue)])
            [self setEndLineStyle:[endLineStyle integerValue]];
        if ([interiorColor isKindOfClass:colorClass] && [self respondsToSelector:@selector(setInteriorColor:)])
            [self setInteriorColor:interiorColor];
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties {
    NSMutableDictionary *dict = [[[super SkimNoteProperties] mutableCopy] autorelease];
    [dict setValue:[NSNumber numberWithInteger:[self startLineStyle]] forKey:SKNPDFAnnotationStartLineStyleKey];
    [dict setValue:[NSNumber numberWithInteger:[self endLineStyle]] forKey:SKNPDFAnnotationEndLineStyleKey];
    [dict setValue:NSStringFromPoint([self startPoint]) forKey:SKNPDFAnnotationStartPointKey];
    [dict setValue:NSStringFromPoint([self endPoint]) forKey:SKNPDFAnnotationEndPointKey];
    if ([self respondsToSelector:@selector(interiorColor)])
        [dict setValue:[self interiorColor] forKey:SKNPDFAnnotationInteriorColorKey];
    return dict;
}

@end

#pragma mark -

@interface PDFAnnotationFreeText (SKNPDFAnnotationFreeTextPrivateDeclarations)
- (int)rotation;
- (void)setRotation:(int)rotation;
- (NSColor *)fontColor;
- (void)setFontColor:(NSColor *)color;
@end


@implementation PDFAnnotationFreeText (SKNExtensions)

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    if (self = [super initSkimNoteWithProperties:dict]) {
        Class fontClass = [NSFont class];
        Class colorClass = [NSColor class];
        NSFont *font = [dict objectForKey:SKNPDFAnnotationFontKey];
        NSColor *fontColor = [dict objectForKey:SKNPDFAnnotationFontColorKey];
        NSNumber *alignment = [dict objectForKey:SKNPDFAnnotationAlignmentKey];
        NSNumber *rotation = [dict objectForKey:SKNPDFAnnotationRotationKey];
        if ([font isKindOfClass:fontClass])
            [self setFont:font];
        if ([fontColor isKindOfClass:colorClass] && [self respondsToSelector:@selector(setFontColor:)])
            [self setFontColor:fontColor];
        if ([alignment respondsToSelector:@selector(integerValue)])
            [self setAlignment:[alignment integerValue]];
        if ([rotation respondsToSelector:@selector(integerValue)] && [self respondsToSelector:@selector(setRotation:)])
            [self setRotation:[rotation integerValue]];
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties{
    NSMutableDictionary *dict = [[[super SkimNoteProperties] mutableCopy] autorelease];
    [dict setValue:[self font] forKey:SKNPDFAnnotationFontKey];
    if ([self respondsToSelector:@selector(fontColor)] && [[self fontColor] isEqual:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]] == NO)
        [dict setValue:[self fontColor] forKey:SKNPDFAnnotationFontColorKey];
    [dict setValue:[NSNumber numberWithInteger:[self alignment]] forKey:SKNPDFAnnotationAlignmentKey];
    if ([self respondsToSelector:@selector(rotation)])
        [dict setValue:[NSNumber numberWithInteger:[self rotation]] forKey:SKNPDFAnnotationRotationKey];
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
            NSInteger markupType = kPDFMarkupTypeHighlight;
            if ([type isEqualToString:SKNUnderlineString])
                markupType = kPDFMarkupTypeUnderline;
            else if ([type isEqualToString:SKNStrikeOutString])
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
            NSUInteger i, iMax = [pointStrings count];
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
        NSUInteger i, iMax = [quadPoints count];
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
        if ([iconType respondsToSelector:@selector(integerValue)])
            [self setIconType:[iconType integerValue]];
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties{
    NSMutableDictionary *dict = [[[super SkimNoteProperties] mutableCopy] autorelease];
    [dict setValue:[NSNumber numberWithInteger:[self iconType]] forKey:SKNPDFAnnotationIconTypeKey];
    return dict;
}

@end

#pragma mark -

@implementation PDFAnnotationInk (SKNExtensions)

+ (void)addPoint:(NSPoint)point toSkimNotesPath:(NSBezierPath *)path {
    NSUInteger count = [path elementCount];
    
    if (count == 0) {
        
        [path moveToPoint:point];
        
    } else if (count == 1) {
        
        [path lineToPoint:point];
        
    } else {
        
        NSBezierPathElement elt;
        NSPoint points[3];
        NSPoint diff, controlPoint, point0, point1;
        CGFloat t, dInv, d0, d1;
        
        elt = [path elementAtIndex:count - 2 associatedPoints:points];
        point0 = elt == NSCurveToBezierPathElement ? points[2] : points[0];
        
        elt = [path elementAtIndex:count - 1 associatedPoints:points];
        point1 = elt == NSCurveToBezierPathElement ? points[2] : points[0];
        
        diff.x = point.x - point0.x;
        diff.y = point.y - point0.y;
        
        d0 = fabs((point1.x - point0.x) * diff.x + (point1.y - point0.y) * diff.y);
        d1 = fabs((point.x - point1.x) * diff.x + (point.y - point1.y) * diff.y);
        dInv = d0 + d1 > 0.0 ? 1.0 / (3.0 * (d0 + d1)) : 0.0;
        
        t = d0 * dInv;
        controlPoint.x = point1.x - t * diff.x;
        controlPoint.y = point1.y - t * diff.y;
        
        if (elt == NSCurveToBezierPathElement) {
            points[1] = controlPoint;
            [path setAssociatedPoints:points atIndex:count - 1];
        } else if (count == 2) {
            [path removeAllPoints];
            [path moveToPoint:point0];
            [path curveToPoint:point1 controlPoint1:point0 controlPoint2:controlPoint];
        } 
        
        t = d1 * dInv;
        controlPoint.x = point1.x + t * diff.x;
        controlPoint.y = point1.y + t * diff.y;
        
        [path curveToPoint:point controlPoint1:controlPoint controlPoint2:point];
        
    }
}

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    if (self = [super initSkimNoteWithProperties:dict]) {
        Class arrayClass = [NSArray class];
        Class stringClass = [NSString class];
        NSArray *pointLists = [dict objectForKey:SKNPDFAnnotationPointListsKey];
        if ([pointLists isKindOfClass:arrayClass]) {
            Class selfClass = [self class];
            NSUInteger i, iMax = [pointLists count];
            for (i = 0; i < iMax; i++) {
                NSArray *pointStrings = [pointLists objectAtIndex:i];
                if ([pointStrings isKindOfClass:arrayClass]) {
                    NSUInteger j, jMax = [pointStrings count];
                    NSBezierPath *path = [NSBezierPath bezierPath];
                    for (j = 0; j < jMax; j++) {
                        NSString *pointString = [pointStrings objectAtIndex:j];
                        if ([pointString isKindOfClass:stringClass])
                            [selfClass addPoint:NSPointFromString(pointString) toSkimNotesPath:path];
                    }
                    [self addBezierPath:path];
                }
            }
        }
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties{
    NSMutableDictionary *dict = [[[super SkimNoteProperties] mutableCopy] autorelease];
    NSArray *paths = [self paths];
    if (paths) {
        NSUInteger i, iMax = [paths count];
        NSMutableArray *pointLists = [[NSMutableArray alloc] initWithCapacity:iMax];
        for (i = 0; i < iMax; i++) {
            NSBezierPath *path = [paths objectAtIndex:i];
            NSUInteger j, jMax = [path elementCount];
            NSMutableArray *pointStrings = [[NSMutableArray alloc] initWithCapacity:jMax];
            for (j = 0; j < jMax; j++) {
                NSPoint points[3];
                NSBezierPathElement element = [path elementAtIndex:j associatedPoints:points];
                NSPoint point = element == NSCurveToBezierPathElement ? points[2] : points[0];
                [pointStrings addObject:NSStringFromPoint(point)];
            }
            [pointLists addObject:pointStrings];
            [pointStrings release];
        }
        [dict setValue:pointLists forKey:SKNPDFAnnotationPointListsKey];
        [pointLists release];
    }
    return dict;
}

@end

#pragma mark -

#if __LP64__

// the implementation of -[PDFBorder dashPattern] is currently badly broken in the 64-bit binary, probably due to the wrong type for _pdfPriv.dashCount

@implementation PDFBorder (SKNExtensions)

static NSArray *replacement_dashPattern(id self, SEL _cmd) {
    NSMutableArray *pattern = [NSMutableArray array];
    @try {
        id vars = [self valueForKey:@"pdfPriv"];
        NSUInteger i, count = [[vars valueForKey:@"dashCount"] unsignedIntegerValue];
        Ivar ivar = object_getInstanceVariable(vars, "dashPattern", NULL);
        if (ivar != NULL) {
            CGFloat *dashPattern = *(CGFloat **)((void *)vars + ivar_getOffset(ivar));
            for (i = 0; i < count; i++)
                [pattern addObject:[NSNumber numberWithDouble:dashPattern[i]]];
        }
    }
    @catch (id e) {}
    return pattern;
}

+ (void)load {
    Class cls = NSClassFromString(@"PDFBorderPrivateVars");
    if (cls) {
        Ivar dashCountIvar = class_getInstanceVariable(cls, "dashCount");
        if (dashCountIvar && 0 != strcmp(ivar_getTypeEncoding(dashCountIvar), @encode(NSUInteger)))
            class_replaceMethod(self, @selector(dashPattern), (IMP)replacement_dashPattern, "@@:");
    }
}

@end

#endif
