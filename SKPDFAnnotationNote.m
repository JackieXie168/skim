//
//  SKPDFAnnotationNote.m
//  Skim
//
//  Created by Christiaan Hofman on 2/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKPDFAnnotationNote.h"
#import "SKStringConstants.h"


@implementation PDFAnnotation (SKExtensions)

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

- (void)setDefaultColor:(NSColor *)newColor {
    [self setColor:newColor];
}

- (BOOL)isNoteAnnotation { return NO; }

- (BOOL)isTemporaryAnnotation { return NO; }

- (BOOL)isResizable { return NO; }

@end

#pragma mark -

@implementation SKPDFAnnotationCircle

static NSColor *circleColor = nil;

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        if (circleColor == nil)
            circleColor = [[NSColor redColor] retain];
        [self setColor:circleColor];
        [[self border] setLineWidth:2.0];
    }
    return self;
}

- (void)setDefaultColor:(NSColor *)newColor {
    [self setColor:newColor];
    if (circleColor != newColor) {
        [circleColor release];
        circleColor = [newColor retain];
    }
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

@end

#pragma mark -

@implementation SKPDFAnnotationSquare

static NSColor *squareColor = nil;

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        if (squareColor == nil)
            squareColor = [[NSColor greenColor] retain];
        [self setColor:squareColor];
        [[self border] setLineWidth:2.0];
    }
    return self;
}

- (void)setDefaultColor:(NSColor *)newColor {
    [self setColor:newColor];
    if (squareColor != newColor) {
        [squareColor release];
        squareColor = [newColor retain];
    }
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

@end

#pragma mark -

@implementation SKPDFAnnotationFreeText

static NSColor *freeTextColor = nil;

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        if (freeTextColor == nil)
            freeTextColor = [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.5 alpha:1.0] retain];
        [self setColor:freeTextColor];
    }
    return self;
}

- (void)setDefaultColor:(NSColor *)newColor {
    [self setColor:newColor];
    if (freeTextColor != newColor) {
        [freeTextColor release];
        freeTextColor = [newColor retain];
    }
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

@end

#pragma mark -

@implementation SKPDFAnnotationText

static NSColor *textColor = nil;

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        if (textColor == nil)
            textColor = [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.5 alpha:1.0] retain];
        [self setColor:textColor];
    }
    return self;
}

- (void)setDefaultColor:(NSColor *)newColor {
    [self setColor:newColor];
    if (textColor != newColor) {
        [textColor release];
        textColor = [newColor retain];
    }
}

- (BOOL)isNoteAnnotation { return YES; }

@end

#pragma mark -

@implementation SKPDFAnnotationNote

static NSColor *noteColor = nil;

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        if (noteColor == nil)
            noteColor = [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.5 alpha:1.0] retain];
        [self setColor:noteColor];
    }
    return self;
}

- (void)setDefaultColor:(NSColor *)newColor {
    [self setColor:newColor];
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

- (BOOL)isNoteAnnotation { return YES; }

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

#pragma mark -

// useful for highlighting things; isTemporaryAnnotation is so we know to remove it
@implementation SKPDFAnnotationTemporary

- (BOOL)isTemporaryAnnotation { return YES; }

- (BOOL)shouldPrint { return NO; }

@end
