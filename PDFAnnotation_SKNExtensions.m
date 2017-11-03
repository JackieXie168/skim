//
//  PDFAnnotation_SKNExtensions.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 6/15/08.
/*
 This software is Copyright (c) 2008-2017
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

#if !defined(MAC_OS_X_VERSION_10_12) || MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_12
@interface PDFAnnotation (SKNSierraDeclarations)
- (id)valueForAnnotationKey:(NSString *)key;
@end
#endif

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
    self = [self initWithBounds:bounds];
    if (self) {
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
        self = [self initSkimNoteWithBounds:bounds];
        if (self) {
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
            if (lineWidth || borderStyle || dashPattern) {
                if ([self border] == nil)
                    [self setBorder:[[[PDFBorder alloc] init] autorelease]];
                if ([lineWidth respondsToSelector:@selector(floatValue)])
                    [[self border] setLineWidth:[lineWidth floatValue]];
                if ([dashPattern isKindOfClass:arrayClass])
                    [[self border] setDashPattern:dashPattern];
                if ([borderStyle respondsToSelector:@selector(integerValue)])
                    [[self border] setStyle:[borderStyle integerValue]];
            } else if ([self border]) {
                [self setBorder:nil];
                // On 10.12 a border with lineWith 1 is inserted, so set its lineWidth to 0
                [[self border] setLineWidth:0.0];
            }
        }
        
    }
    return self;
}

- (NSMutableDictionary *)genericSkimNoteProperties{
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
    if ([self border] && [[self border] lineWidth] > 0.0) {
        [dict setValue:[NSNumber numberWithFloat:[[self border] lineWidth]] forKey:SKNPDFAnnotationLineWidthKey];
        [dict setValue:[NSNumber numberWithInteger:[[self border] style]] forKey:SKNPDFAnnotationBorderStyleKey];
        [dict setValue:[[self border] dashPattern] forKey:SKNPDFAnnotationDashPatternKey];
    }
    return dict;
}

static inline PDFBorderStyle SKNPDFBorderStyleFromAnnotationValue(id value) {
    if ([value isKindOfClass:[NSString class]] == NO)
        return kPDFBorderStyleSolid;
    if ([value isEqualToString:@"/S"])
        return kPDFBorderStyleSolid;
    else if ([value isEqualToString:@"/D"])
        return kPDFBorderStyleDashed;
    else if ([value isEqualToString:@"/B"])
        return kPDFBorderStyleBeveled;
    else if ([value isEqualToString:@"/I"])
        return kPDFBorderStyleInset;
    else if ([value isEqualToString:@"/U"])
        return kPDFBorderStyleUnderline;
    else
        return kPDFBorderStyleSolid;
}

static inline NSColor *SKNColorFromAnnotationValue(id value) {
    if ([value isKindOfClass:[NSColor class]])
        return value;
    if ([value isKindOfClass:[NSArray class]] == NO || [value count] == 0)
        return nil;
    if ([value count] < 3)
        return [NSColor colorWithDeviceWhite:[[value objectAtIndex:0] floatValue] alpha:[value count] > 1 ? [[value objectAtIndex:1] floatValue] : 1.0];
    return [NSColor colorWithDeviceRed:[[value objectAtIndex:0] floatValue] green:[[value objectAtIndex:1] floatValue] blue:[[value objectAtIndex:2] floatValue] alpha:[value count] > 3 ? [[value objectAtIndex:3] floatValue] : 1.0];
}

static inline PDFTextAnnotationIconType SKNIconTypeFromAnnotationValue(id value) {
    if ([value isKindOfClass:[NSString class]] == NO)
        return kPDFTextAnnotationIconNote;
    if ([value isEqualToString:@"/Comment"])
        return kPDFTextAnnotationIconComment;
    else if ([value isEqualToString:@"/Key"])
        return kPDFTextAnnotationIconKey;
    else if ([value isEqualToString:@"/Note"])
        return kPDFTextAnnotationIconNote;
    else if ([value isEqualToString:@"/NewParagraph"])
        return kPDFTextAnnotationIconNewParagraph;
    else if ([value isEqualToString:@"/Paragraph"])
        return kPDFTextAnnotationIconParagraph;
    else if ([value isEqualToString:@"/Insert"])
        return kPDFTextAnnotationIconInsert;
    else
        return kPDFTextAnnotationIconNote;
}


static inline PDFLineStyle SKNPDFLineStyleFromAnnotationValue(id value) {
    if ([value isKindOfClass:[NSString class]] == NO)
        return kPDFLineStyleNone;
    if ([value isEqualToString:@"/None"])
        return kPDFLineStyleNone;
    else if ([value isEqualToString:@"/Square"])
        return kPDFLineStyleSquare;
    else if ([value isEqualToString:@"/Circle"])
        return kPDFLineStyleCircle;
    else if ([value isEqualToString:@"/Diamond"])
        return kPDFLineStyleDiamond;
    else if ([value isEqualToString:@"/OpenArrow"])
        return kPDFLineStyleOpenArrow;
    else if ([value isEqualToString:@"/ClosedArrow"])
        return kPDFLineStyleClosedArrow;
    else
        return kPDFLineStyleNone;
}

- (NSDictionary *)SkimNoteProperties{
    if ([self respondsToSelector:@selector(valueForAnnotationKey:)] == NO)
        return [self genericSkimNoteProperties];
    
    PDFPage *page = [self page];
    NSUInteger pageIndex = page ? [[page document] indexForPage:page] : NSNotFound;
    NSRect bounds = [self bounds];
    id value = nil;
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    Class arrayClass = [NSArray class];
    Class dictClass = [NSDictionary class];
    Class dateClass = [NSDate class];
    Class stringClass = [NSString class];
    Class borderClass = [PDFBorder class];
    
    [dict setValue:[self type] forKey:SKNPDFAnnotationTypeKey];
    
    [dict setValue:NSStringFromRect(bounds) forKey:SKNPDFAnnotationBoundsKey];
    
    [dict setValue:[NSNumber numberWithUnsignedInteger:pageIndex == NSNotFound ? 0 : pageIndex] forKey:SKNPDFAnnotationPageIndexKey];
    
    if ((value = [self valueForAnnotationKey:@"/BS"])) {
        if ([value isKindOfClass:dictClass]) {
            [dict setValue:[NSNumber numberWithFloat:[[value objectForKey:@"/W"] floatValue]] forKey:SKNPDFAnnotationLineWidthKey];
            [dict setValue:[NSNumber numberWithInteger:SKNPDFBorderStyleFromAnnotationValue([value objectForKey:@"/S"])] forKey:SKNPDFAnnotationBorderStyleKey];
            [dict setValue:[value objectForKey:@"/D"] forKey:SKNPDFAnnotationDashPatternKey];
        }
    } else if ((value = [self valueForAnnotationKey:@"/Border"])) {
        if ([value isKindOfClass:arrayClass] && [value count] >= 3) {
            [dict setValue:[NSNumber numberWithFloat:[[value objectAtIndex:2] floatValue]] forKey:SKNPDFAnnotationLineWidthKey];
            if ([value count] == 3) {
                [dict setValue:[NSNumber numberWithInteger:kPDFBorderStyleSolid] forKey:SKNPDFAnnotationBorderStyleKey];
            } else {
                [dict setValue:[NSNumber numberWithInteger:kPDFBorderStyleDashed] forKey:SKNPDFAnnotationBorderStyleKey];
                [dict setValue:[value objectAtIndex:3] forKey:SKNPDFAnnotationDashPatternKey];
            }
        }
    }
    if ([value isKindOfClass:borderClass]) {
        [dict setValue:[NSNumber numberWithFloat:[(PDFBorder *)value lineWidth]] forKey:SKNPDFAnnotationLineWidthKey];
        [dict setValue:[NSNumber numberWithInteger:[(PDFBorder *)value style]] forKey:SKNPDFAnnotationBorderStyleKey];
        [dict setValue:[(PDFBorder *)value dashPattern] forKey:SKNPDFAnnotationDashPatternKey];
    }
    
    if ((value = [self valueForAnnotationKey:@"/Contents"]))
        [dict setValue:value forKey:SKNPDFAnnotationContentsKey];
    
    if ((value = [self valueForAnnotationKey:@"/M"])) {
        NSDate *date = nil;
        if ([value isKindOfClass:stringClass]) {
            NSMutableString *string = [value mutableCopy];
            if ([string hasPrefix:@"D:"])
                [string deleteCharactersInRange:NSMakeRange(0, 2)];
            [string replaceOccurrencesOfString:@"'" withString:@"" options:0 range:NSMakeRange(0, [string length])];
            if ([string hasSuffix:@"Z0000"])
                [string replaceCharactersInRange:NSMakeRange([string length] - 5, 1) withString:@"+"];
            else if ([string length] == 14)
                [string appendString:@"+0000"];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyyMMddHHmmssZZ"];
            value = [formatter dateFromString:string];
            [formatter release];
            [string release];
        }
        if ([value isKindOfClass:dateClass])
            [dict setValue:date forKey:SKNPDFAnnotationModificationDateKey];
    }
    
    if ((value = [self valueForAnnotationKey:@"/T"]))
        [dict setValue:value forKey:SKNPDFAnnotationUserNameKey];
    
    if ((value = [self valueForAnnotationKey:@"/C"]))
        [dict setValue:SKNColorFromAnnotationValue(value) forKey:SKNPDFAnnotationColorKey];
    
    if ((value = [self valueForAnnotationKey:@"/IC"]))
        [dict setValue:SKNColorFromAnnotationValue(value) forKey:SKNPDFAnnotationInteriorColorKey];
    
    if ((value = [self valueForAnnotationKey:@"/Name"]))
        [dict setValue:SKNIconTypeFromAnnotationValue(value) forKey:SKNPDFAnnotationIconTypeKey];
    
    if ((value = [self valueForAnnotationKey:@"/LE"])) {
        if ([value isKindOfClass:arrayClass] && [value count] == 2) {
            [dict setValue:[NSNumber numberWithInteger:SKNPDFLineStyleFromAnnotationValue([value objectAtIndex:0])] forKey:SKNPDFAnnotationStartLineStyleKey];
            [dict setValue:[NSNumber numberWithInteger:SKNPDFLineStyleFromAnnotationValue([value objectAtIndex:1])] forKey:SKNPDFAnnotationEndLineStyleKey];
        }
    }
    
    if ((value = [self valueForAnnotationKey:@"/L"])) {
        if ([value isKindOfClass:arrayClass] && [value count] == 4) {
            NSPoint p = NSMakePoint([[value objectAtIndex:0] floatValue] - NSMinX(bounds), [[value objectAtIndex:1] floatValue] - NSMinY(bounds));
            [dict setValue:NSStringFromPoint(p) forKey:SKNPDFAnnotationStartPointKey];
            p = NSMakePoint([[value objectAtIndex:2] floatValue] - NSMinX(bounds), [[value objectAtIndex:3] floatValue] - NSMinY(bounds));
            [dict setValue:NSStringFromPoint(p) forKey:SKNPDFAnnotationEndPointKey];
        }
    }
    
    if ((value = [self valueForAnnotationKey:@"/QuadPoints"])) {
        if ([value isKindOfClass:arrayClass] && [value count] % 8 == 0) {
            NSMutableArray *quadPoints = [NSMutableArray array];
            NSUInteger i, iMax = [value count];
            for (i = 0; i < iMax; i += 2) {
                NSPoint p = NSMakePoint([[value objectAtIndex:i] floatValue] - NSMinX(bounds), [[value objectAtIndex:i + 1] floatValue] - NSMinY(bounds));
                [quadPoints addObject:NSStringFromPoint(p)];
            }
            [dict setValue:quadPoints forKey:SKNPDFAnnotationQuadrilateralPointsKey];
        }
    }
    
    if ((value = [self valueForAnnotationKey:@"/InkList"])) {
        if ([value isKindOfClass:arrayClass]) {
            NSMutableArray *pointLists = [NSMutableArray array];
            NSUInteger i, iMax = [value count];
            for (i = 0; i < iMax; i++) {
                NSArray *array = [value objectAtIndex:i];
                if ([array isKindOfClass:arrayClass] && [array count] % 2 == 0) {
                    NSMutableArray *points = [NSMutableArray array];
                    NSUInteger j, jMax = [array count];
                    for (j = 0; j < jMax; j += 2) {
                        NSPoint p = NSMakePoint([[array objectAtIndex:j] floatValue] - NSMinX(bounds), [[array objectAtIndex:j + 1] floatValue] - NSMinY(bounds));
                        [points addObject:NSStringFromPoint(p)];
                    }
                    [pointLists addObject:points];
                }
            }
            [dict setValue:pointLists forKey:SKNPDFAnnotationPointListsKey];
        }
    }
    
    if ((value = [self valueForAnnotationKey:@"/Q"])) {
        NSInteger align = [value integerValue];
        [dict setValue:[NSNumber numberWithInteger:align == 1 ? NSCenterTextAlignment : align == 2 ? NSRightTextAlignment : NSLeftTextAlignment] forKey:SKNPDFAnnotationAlignmentKey];
    }
    
    if ((value = [self valueForAnnotationKey:@"/DA"])) {
        NSScanner *scanner = [[NSScanner alloc] initWithString:value];
        NSString *fontName;
        double fontSize;
        if ([scanner scanUpToString:@"Tf" intoString:NULL] && [scanner isAtEnd] == NO) {
            NSUInteger location = [scanner scanLocation];
            NSRange r = [value rangeOfString:@"/" options:NSBackwardsSearch range:NSMakeRange(0, location)];
            if (r.location != NSNotFound) {
                [scanner setScanLocation:NSMaxRange(r)];
                if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&fontName] &&
                    [scanner scanDouble:&fontSize] &&
                    [scanner scanString:@"Tf" intoString:NULL] &&
                    [scanner scanLocation] == location + 2) {
                    NSFont *font = [NSFont fontWithName:fontName size:fontSize];
                    if (font)
                        [dict setObject:font forKey:SKNPDFAnnotationFontKey];
                }
            }
        }
        [scanner release];
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
    self = [super initSkimNoteWithProperties:dict];
    if (self) {
        Class colorClass = [NSColor class];
        NSColor *interiorColor = [dict objectForKey:SKNPDFAnnotationInteriorColorKey];
        if ([interiorColor isKindOfClass:colorClass])
            [self setInteriorColor:interiorColor];
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties{
    NSMutableDictionary *dict = [super genericSkimNoteProperties];
    [dict setValue:[self interiorColor] forKey:SKNPDFAnnotationInteriorColorKey];
    return dict;
}

@end

#pragma mark -

@implementation PDFAnnotationSquare (SKNExtensions)

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    self = [super initSkimNoteWithProperties:dict];
    if (self) {
        Class colorClass = [NSColor class];
        NSColor *interiorColor = [dict objectForKey:SKNPDFAnnotationInteriorColorKey];
        if ([interiorColor isKindOfClass:colorClass])
            [self setInteriorColor:interiorColor];
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties{
    NSMutableDictionary *dict = [super genericSkimNoteProperties];
    [dict setValue:[self interiorColor] forKey:SKNPDFAnnotationInteriorColorKey];
    return dict;
}

@end

#pragma mark -

@implementation PDFAnnotationLine (SKNExtensions)

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    self = [super initSkimNoteWithProperties:dict];
    if (self) {
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
    NSMutableDictionary *dict = [super genericSkimNoteProperties];
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
    self = [super initSkimNoteWithProperties:dict];
    if (self) {
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
    NSMutableDictionary *dict = [super genericSkimNoteProperties];
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
/*
 http://www.cocoabuilder.com/archive/message/cocoa/2007/2/16/178891
 The docs are wrong (as is Adobe's spec).  The ordering on the rotated page is:
 --------
 | 0  1 |
 | 2  3 |
 --------
 */

static inline void swapPoints(NSPoint p[4], NSUInteger i, NSUInteger j) {
    NSPoint tmp = p[i];
    p[i] = p[j];
    p[j] = tmp;
}

- (id)initSkimNoteWithProperties:(NSDictionary *)dict{
    self = [super initSkimNoteWithProperties:dict];
    if (self) {
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
            // fix the order, as we have done it wrong for a long time
            NSUInteger i, iMax = [pointStrings count] / 4;
            NSMutableArray *quadPoints = [[NSMutableArray alloc] initWithCapacity:4 * iMax];
            for (i = 0; i < iMax; i++) {
                NSPoint p[4];
                NSUInteger j;
                for (j = 0; j < 4; j++)
                    p[j] = NSPointFromString([pointStrings objectAtIndex:4 * i + j]);
                // p[0]-p[1] should be in the same direction as p[2]-p[3]
                if ((p[1].x - p[0].x) * (p[3].x - p[2].x) + (p[1].y - p[0].y) * (p[3].y - p[2].y) < 0.0) {
                    swapPoints(p, 2, 3);
                }
                // p[0], p[1], p[2] should be ordered clockwise
                if ((p[1].y - p[0].y) * (p[2].x - p[0].x) - (p[1].x - p[0].x) * (p[2].y - p[0].y) < 0.0) {
                    swapPoints(p, 0, 2);
                    swapPoints(p, 1, 3);
                }
                for (j = 0; j < 4; j++) {
                    NSValue *value = [[NSValue alloc] initWithBytes:&p[j] objCType:@encode(NSPoint)];
                    [quadPoints addObject:value];
                    [value release];
                }
            }
            [self setQuadrilateralPoints:quadPoints];
            [quadPoints release];
        }
        
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties {
    NSMutableDictionary *dict = [super genericSkimNoteProperties];
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
    self = [super initSkimNoteWithProperties:dict];
    if (self) {
        NSNumber *iconType = [dict objectForKey:SKNPDFAnnotationIconTypeKey];
        if ([iconType respondsToSelector:@selector(integerValue)])
            [self setIconType:[iconType integerValue]];
    }
    return self;
}

- (NSDictionary *)SkimNoteProperties{
    NSMutableDictionary *dict = [super genericSkimNoteProperties];
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
    self = [super initSkimNoteWithProperties:dict];
    if (self) {
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
    NSMutableDictionary *dict = [super genericSkimNoteProperties];
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

// the implementation of -[PDFBorder dashPattern] is badly broken on 10.4 and 10.5 in the 64-bit binary, probably due to the wrong type for _pdfPriv.dashCount or _pdfPriv.dashPattern

@implementation PDFBorder (SKNExtensions)

static NSArray *replacement_dashPattern(id self, SEL _cmd) {
    NSMutableArray *pattern = [NSMutableArray array];
    @try {
        id vars = nil;
        if (NULL != object_getInstanceVariable(vars, "_pdfPriv", (void **)&vars)) {
            Ivar countIvar = object_getInstanceVariable(vars, "dashCount", NULL);
            if (countIvar != NULL) {
                NSUInteger i, count = *(unsigned int *)((void *)vars + ivar_getOffset(countIvar));
                Ivar patternIvar = object_getInstanceVariable(vars, "dashPattern", NULL);
                if (patternIvar != NULL) {
                    float *dashPattern = *(float **)((void *)vars + ivar_getOffset(patternIvar));
                    for (i = 0; i < count; i++)
                        [pattern addObject:[NSNumber numberWithFloat:dashPattern[i]]];
                }
            }
        }
    }
    @catch (id e) {}
    return pattern;
}

+ (void)load {
    if (class_getInstanceVariable(self, "_pdfPriv")) {
        Class cls = NSClassFromString(@"PDFBorderPrivateVars");
        if (cls) {
            Ivar dashCountIvar = class_getInstanceVariable(cls, "dashCount");
            Ivar dashPatternIvar = class_getInstanceVariable(cls, "dashPattern");
            if (dashCountIvar && 0 == strcmp(ivar_getTypeEncoding(dashCountIvar), @encode(unsigned int)) && dashPatternIvar && 0 == strcmp(ivar_getTypeEncoding(dashPatternIvar), @encode(float *)))
                class_replaceMethod(self, @selector(dashPattern), (IMP)replacement_dashPattern, "@@:");
        }
    }
}

@end

#endif
