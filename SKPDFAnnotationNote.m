//
//  SKPDFAnnotationNote.m
//  Skim
//
//  Created by Christiaan Hofman on 2/6/07.
/*
 This software is Copyright (c) 2007
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
        self = [[SKPDFAnnotationText alloc] initWithBounds:bounds];
    } else if ([type isEqualToString:@"Note"]) {
        self = [[SKPDFAnnotationNote alloc] initWithBounds:bounds];
        NSAttributedString *text = [dict objectForKey:@"text"];
        NSImage *image = [dict objectForKey:@"image"];
        if (image)
            [(SKPDFAnnotationNote *)self setImage:image];
        if (text)
            [( SKPDFAnnotationNote *)self setText:text];
    } else if ([type isEqualToString:@"FreeText"]) {
        self = [[SKPDFAnnotationFreeText alloc] initWithBounds:bounds];
    } else if ([type isEqualToString:@"Circle"]) {
        self = [[SKPDFAnnotationText alloc] initWithBounds:bounds];
    } else if ([type isEqualToString:@"Square"]) {
        self = [[SKPDFAnnotationText alloc] initWithBounds:bounds];
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

- (NSArray *)texts { return nil; }

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
        texts = [[NSArray alloc] initWithObjects:[[[SKNoteText alloc] initWithAnnotation:self] autorelease], nil];
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
    [texts release];
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

- (NSArray *)texts {
    return texts;
}

@end

#pragma mark -

// useful for highlighting things; isTemporaryAnnotation is so we know to remove it
@implementation SKPDFAnnotationTemporary

- (BOOL)isTemporaryAnnotation { return YES; }

- (BOOL)shouldPrint { return NO; }

@end

@implementation SKNoteText

- (id)initWithAnnotation:(PDFAnnotation *)anAnnotation {
    if (self = [super init]) {
        annotation = anAnnotation;
        [annotation addObserver:self forKeyPath:@"text" options:0 context:NULL];
        rowHeight = 85.0;
    }
    return self;
}

- (void)dealloc {
    [annotation removeObserver:self forKeyPath:@"text"];
    [super dealloc];
}

- (PDFAnnotation *)annotation {
    return annotation;
}

- (NSArray *)texts { return nil; }

- (NSString *)type { return nil; }

- (unsigned int)pageIndex { return [annotation pageIndex]; }

- (NSString *)pageLabel { return nil; }

- (NSAttributedString *)contents { return [annotation text]; }

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == annotation && [keyPath isEqualToString:@"text"]) {
        [self willChangeValueForKey:@"contents"];
        [self didChangeValueForKey:@"contents"];
    }
}

- (float)rowHeight {
    return rowHeight;
}

- (void)setRowHeight:(float)newRowHeight {
    rowHeight = newRowHeight;
}

@end
