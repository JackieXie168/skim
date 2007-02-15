//
//  SKPDFAnnotationNote.m
//  Skim
//
//  Created by Christiaan Hofman on 6/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKPDFAnnotationNote.h"
#import "SKStringConstants.h"
#import "OBUtilities.h"


@implementation PDFAnnotation (SKExtensions)

static IMP originalSetColor = NULL;

+ (void)load{
    originalSetColor = OBReplaceMethodImplementationWithSelector(self, @selector(setColor:), @selector(replacementSetColor:));
}

+ (NSColor *)color { return nil; }

+ (void)setColor:(NSColor *)newColor {}

- (void)replacementSetColor:(NSColor *)newColor {
    originalSetColor(self, _cmd, newColor);
    [[self class] setColor:newColor];
}

- (void)setDefaultColor {
    originalSetColor(self, _cmd, [[self class] color]);
}

- (id)initWithDictionary:(NSDictionary *)dict{
    [[self initWithBounds:NSZeroRect] release];
    
    NSString *type = [dict objectForKey:@"type"];
    NSRect bounds = NSRectFromString([dict objectForKey:@"bounds"]);
    NSString *contents = [dict objectForKey:@"contents"];
    NSColor *color = [dict objectForKey:@"color"];
    
    if ([type isEqualToString:@"Text"]) {
        self = [[PDFAnnotationText alloc] initWithBounds:bounds];
    } else if ([type isEqualToString:@"Note"]) {
        self = [[SKPDFAnnotationNote alloc] initWithBounds:bounds];
        NSAttributedString *text = [dict objectForKey:@"text"];
        NSImage *image = [dict objectForKey:@"image"];
        if (image)
            [(SKPDFAnnotationNote *)self setImage:image];
        if (text)
            [( SKPDFAnnotationNote *)self setText:text];
    } else if ([type isEqualToString:@"FreeText"]) {
        self = [[PDFAnnotationFreeText alloc] initWithBounds:bounds];
    } else if ([type isEqualToString:@"Circle"]) {
        self = [[PDFAnnotationText alloc] initWithBounds:bounds];
    } else if ([type isEqualToString:@"Square"]) {
        self = [[PDFAnnotationText alloc] initWithBounds:bounds];
    } else {
        self = nil;
    }
    
    if (contents)
        [self setContents:contents];
    if (color)
        [self setColor:color];
    
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    [dict setValue:[self type] forKey:@"type"];
    [dict setValue:[self contents] forKey:@"contents"];
    [dict setValue:[self color] forKey:@"color"];
    [dict setValue:NSStringFromRect([self bounds]) forKey:@"bounds"];
    [dict setValue:[NSNumber numberWithUnsignedInt:[self pageIndex]] forKey:@"pageIndex"];
    return dict;
}

- (PDFDestination *)destination{
    NSRect bounds = [self bounds];
    NSPoint point = NSMakePoint(NSMinX(bounds), NSMaxY(bounds));
    return [[[PDFDestination alloc] initWithPage:[self page] atPoint:point] autorelease];
}

- (unsigned int)pageIndex {
    PDFPage *page = [self page];
    return page ? [[page document] indexForPage:page] : NSNotFound;
}

- (NSString *)pageLabel {
    return [[self page] label];
}

- (NSImage *)image { return nil; }

- (NSAttributedString *)text { return nil; }

- (BOOL)isTemporaryAnnotation { return NO; }

@end

#pragma mark -

@interface PDFAnnotationCircle (SKExtensions)
@end

@implementation PDFAnnotationCircle (SKExtensions)

static NSColor *circleColor = nil;

+ (NSColor *)color {
    if (circleColor == nil)
        circleColor = [[NSColor redColor] retain];
    return circleColor;
}

+ (void)setColor:(NSColor *)newColor {
    if (circleColor != newColor) {
        [circleColor release];
        circleColor = [newColor retain];
    }
}

@end

#pragma mark -

@interface PDFAnnotationSquare (SKExtensions)
@end

@implementation PDFAnnotationSquare (SKExtensions)

static NSColor *squareColor = nil;

+ (NSColor *)color {
    if (squareColor == nil)
        squareColor = [[NSColor greenColor] retain];
    return squareColor;
}

+ (void)setColor:(NSColor *)newColor {
    if (squareColor != newColor) {
        [squareColor release];
        squareColor = [newColor retain];
    }
}

@end

#pragma mark -

@interface PDFAnnotationText (SKExtensions)
@end

@implementation PDFAnnotationText (SKExtensions)

static NSColor *textColor = nil;

+ (NSColor *)color {
    if (textColor == nil)
        textColor = [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.5 alpha:1.0] retain];
    return textColor;
}

+ (void)setColor:(NSColor *)newColor {
    if (textColor != newColor) {
        [textColor release];
        textColor = [newColor retain];
    }
}

@end

#pragma mark -

@interface PDFAnnotationFreeText (SKExtensions)
@end

@implementation PDFAnnotationFreeText (SKExtensions)

static NSColor *freeTextColor = nil;

+ (NSColor *)color {
    if (freeTextColor == nil)
        freeTextColor = [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.5 alpha:1.0] retain];
    return freeTextColor;
}

+ (void)setColor:(NSColor *)newColor {
    if (freeTextColor != newColor) {
        [freeTextColor release];
        freeTextColor = [newColor retain];
    }
}

@end

#pragma mark -

// useful for highlighting things; isTemporaryAnnotation is so we know to remove it
@implementation SKPDFAnnotationTemporary

+ (NSColor *)color {
    return [NSColor redColor];
}

- (BOOL)isTemporaryAnnotation { return YES; }

- (BOOL)shouldPrint { return NO; }

@end

#pragma mark -

@implementation SKPDFAnnotationNote

static NSColor *noteColor = nil;

+ (NSColor *)color {
    if (noteColor == nil)
        noteColor = [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.5 alpha:1.0] retain];
    return noteColor;
}

+ (void)setColor:(NSColor *)newColor {
    if (noteColor != newColor) {
        [noteColor release];
        noteColor = [newColor retain];
    }
}

- (void)dealloc {
    [text release];
    [image release];
    [super dealloc];
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[self text] forKey:@"text"];
    [dict setValue:[self image] forKey:@"image"];
    return dict;
}

- (NSString *)type {
    return @"Note";
}

- (NSImage *)image;
{
    return image;
}

- (void)setImage:(NSImage *)newImage;
{
    if (image != newImage) {
        [image release];
        image = [newImage retain];
    }
}

- (NSAttributedString *)text;
{
    return text;
}

- (void)setText:(NSAttributedString *)newText;
{
    if (text != newText) { 
        [text release];
        text = [newText retain];
    }
}

@end
