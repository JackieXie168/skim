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
#import "PDFPage_SKExtensions.h"
#import "SKPDFView.h"

enum {
    SKASTextNote = 'NTxt',
    SKASAnchoredNote = 'NAnc',
    SKASCircleNote = 'NCir',
    SKASSquareNote = 'NSqu',
    SKASHighlightNote = 'NHil',
};

NSString *SKAnnotationWillChangeNotification = @"SKAnnotationWillChangeNotification";
NSString *SKAnnotationDidChangeNotification = @"SKAnnotationDidChangeNotification";

@interface PDFAnnotation (PDFAnnotationPrivateDeclarations)
- (void)drawWithBox:(CGPDFBox)box inContext:(CGContextRef)context;
@end

@implementation PDFAnnotation (SKExtensions)

- (id)initWithDictionary:(NSDictionary *)dict{
    [[self initWithBounds:NSZeroRect] release];
    
    NSString *type = [dict objectForKey:@"type"];
    NSRect bounds = NSRectFromString([dict objectForKey:@"bounds"]);
    NSString *contents = [dict objectForKey:@"contents"];
    NSColor *color = [dict objectForKey:@"color"];
    
    if ([type isEqualToString:@"Note"]) {
        self = [[SKPDFAnnotationNote alloc] initWithBounds:bounds];
        NSAttributedString *text = [dict objectForKey:@"text"];
        NSImage *image = [dict objectForKey:@"image"];
        if (image)
            [(SKPDFAnnotationNote *)self setImage:image];
        if (text)
            [(SKPDFAnnotationNote *)self setText:text];
    } else if ([type isEqualToString:@"FreeText"]) {
        self = [[SKPDFAnnotationFreeText alloc] initWithBounds:bounds];
    } else if ([type isEqualToString:@"Circle"]) {
        self = [[SKPDFAnnotationCircle alloc] initWithBounds:bounds];
    } else if ([type isEqualToString:@"Square"]) {
        self = [[SKPDFAnnotationSquare alloc] initWithBounds:bounds];
    } else if ([type isEqualToString:@"MarkUp"]) {
        self = [[SKPDFAnnotationMarkup alloc] initWithBounds:bounds];
        [(SKPDFAnnotationMarkup *)self setQuadrilateralPointsFromStrings:[dict objectForKey:@"quadrilateralPoints"]];
        [(SKPDFAnnotationMarkup *)self setMarkupType:[[dict objectForKey:@"markupType"] intValue]];
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

- (NSImage *)image { return nil; }

- (NSAttributedString *)text { return nil; }

- (void)setDefaultColor:(NSColor *)newColor {
    [self setColor:newColor];
}

- (NSArray *)texts { return nil; }

- (BOOL)isNoteAnnotation { return NO; }

- (BOOL)isTemporaryAnnotation { return NO; }

- (BOOL)isResizable { return NO; }

#pragma mark Scripting support

- (id)init {
    self = nil;
    NSScriptCommand *currentCommand = [NSScriptCommand currentCommand];
    if ([currentCommand isKindOfClass:[NSCreateCommand class]]) {
        unsigned long classCode = [[(NSCreateCommand *)currentCommand createClassDescription] appleEventCode];
       
        if (classCode == 'Note') {
            
            NSMutableDictionary *properties = [[[(NSCreateCommand *)currentCommand resolvedKeyDictionary] mutableCopy] autorelease];
            int type = [[properties objectForKey:@"noteType"] intValue];
            
            if (type == 0) {
                [currentCommand setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
                [currentCommand setScriptErrorString:NSLocalizedString(@"New notes need a type.", @"Error description")];
                return nil;
            }
            
            PDFAnnotation *annotation = nil;
            
            if (type == SKASTextNote)
                annotation = [[SKPDFAnnotationFreeText alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0)];
            else if (type == SKASAnchoredNote)
                annotation = [[SKPDFAnnotationNote alloc] initWithBounds:NSMakeRect(100.0, 100.0, 16.0, 16.0)];
            else if (type == SKASCircleNote)
                annotation = [[PDFAnnotationCircle alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0)];
            else if (type == SKASSquareNote)
                annotation = [[PDFAnnotationSquare alloc] initWithBounds:NSMakeRect(100.0, 100.0, 64.0, 64.0)];
            
            self = annotation;
        }
    }
    return self;
}

- (NSScriptObjectSpecifier *)objectSpecifier {
	unsigned index = [[[self page] notes] indexOfObjectIdenticalTo:self];
    if (index != NSNotFound) {
        NSScriptObjectSpecifier *containerRef = [[self page] objectSpecifier];
        return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"notes" index:index] autorelease];
    } else {
        return nil;
    }
}

- (int)noteType {
    if ([[self type] isEqualToString:@"FreeText"])
        return SKASTextNote;
    else if ([[self type] isEqualToString:@"Note"])
        return SKASAnchoredNote;
    else if ([[self type] isEqualToString:@"Circle"])
        return SKASCircleNote;
    else if ([[self type] isEqualToString:@"Square"])
        return SKASSquareNote;
    return 0;
}

- (id)richText {
    return [self text] ? [[[NSTextStorage alloc] initWithAttributedString:[self text]] autorelease] : [NSNull null];
}

- (void)setBoundsAsQDRect:(NSData *)inQDBoundsAsData {
    if ([inQDBoundsAsData length] == sizeof(Rect)) {
        const Rect *qdBounds = (const Rect *)[inQDBoundsAsData bytes];
        SKPDFView *pdfView = [[[self page] containingDocument] pdfView];
        NSRect newBounds = NSRectFromRect(*qdBounds);
        if ([self isResizable] == NO)
            newBounds.size = [self bounds].size;
        [pdfView setNeedsDisplayForAnnotation:self];
        [self setBounds:newBounds];
        [pdfView setNeedsDisplayForAnnotation:self];
    }

}

- (NSData *)boundsAsQDRect {
    Rect qdBounds = RectFromNSRect([self bounds]);
    return [NSData dataWithBytes:&qdBounds length:sizeof(Rect)];
}

- (id)handleGoToScriptCommand:(NSScriptCommand *)command {
    [[[[self page] containingDocument] pdfView] scrollAnnotationToVisible:self];
    return nil;
}

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

- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setContents:(NSString *)contents {
    [super setContents:contents];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setColor:(NSColor *)color {
    [super setColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

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

- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setContents:(NSString *)contents {
    [super setContents:contents];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setColor:(NSColor *)color {
    [super setColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

@end

#pragma mark -

@implementation SKPDFAnnotationMarkup

static NSColor *markupColor = nil;

- (id)initWithBounds:(NSRect)bounds {
    if (self = [super initWithBounds:bounds]) {
        if (markupColor == nil)
            markupColor = [[NSColor yellowColor] retain];
        [self setColor:markupColor];
        /*
         http://www.cocoabuilder.com/archive/message/cocoa/2007/2/16/178891
          The docs are wrong (as is Adobe's spec).  The ordering is:
          --------
          | 0  1 |
          | 2  3 |
          --------
         */         
        [self setQuadrilateralPoints: [NSArray arrayWithObjects:
            [NSValue valueWithPoint: NSMakePoint(0.0, NSHeight(bounds))],
            [NSValue valueWithPoint: NSMakePoint(NSWidth(bounds), NSHeight (bounds))],
            [NSValue valueWithPoint: NSMakePoint(0.0, 0.0)],
            [NSValue valueWithPoint: NSMakePoint(NSWidth(bounds), 0.0)], nil]];        
    }
    return self;
}

- (NSDictionary *)dictionaryValue{
    NSMutableDictionary *dict = (NSMutableDictionary *)[super dictionaryValue];
    [dict setValue:[NSNumber numberWithInt:[self markupType]] forKey:@"markupType"];
    // NSValue conforms to NSCoding, but NSKeyedArchiver throws an exception when encoding points
    [dict setValue:[self quadrilateralPointsAsStrings] forKey:@"quadrilateralPoints"];
    return dict;
}

- (void)setQuadrilateralPointsFromStrings:(NSArray *)pointStrings {
    NSMutableArray *points = [pointStrings mutableCopy];
    unsigned i, iMax = [points count];
    for (i = 0; i < iMax; i++ )
        [points replaceObjectAtIndex:i withObject:[NSValue valueWithPoint:NSPointFromString([points objectAtIndex:i])]];
    [self setQuadrilateralPoints:points];
    [points release];
}

- (NSArray *)quadrilateralPointsAsStrings {
    NSMutableArray *points = [[self quadrilateralPoints] mutableCopy];
    unsigned i, iMax = [points count];
    for (i = 0; i < iMax; i++ )
        [points replaceObjectAtIndex:i withObject:NSStringFromPoint([[points objectAtIndex:i] pointValue])];
    return [points autorelease];
}

- (void)setDefaultColor:(NSColor *)newColor {
    [self setColor:newColor];
    if (markupColor != newColor) {
        [markupColor release];
        markupColor = [newColor retain];
    }
}

- (BOOL)isNoteAnnotation { return YES; }

- (BOOL)isResizable { return YES; }

- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [self setQuadrilateralPoints: [NSArray arrayWithObjects:
        [NSValue valueWithPoint: NSMakePoint(0.0, NSHeight(bounds))],
        [NSValue valueWithPoint: NSMakePoint(NSWidth(bounds), NSHeight (bounds))],
        [NSValue valueWithPoint: NSMakePoint(0.0, 0.0)],
        [NSValue valueWithPoint: NSMakePoint(NSWidth(bounds), 0.0)], nil]];   
}

- (void)setContents:(NSString *)contents {
    [super setContents:contents];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setColor:(NSColor *)color {
    [super setColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setMarkupType:(int)type {
    [super setMarkupType:type];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setQuadrilateralPoints:(NSArray *)points {
    [super setQuadrilateralPoints:points];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

// fix a bug in PDFKit, the color space sometimes is not correct
- (void)drawWithBox:(CGPDFBox)box inContext:(CGContextRef)context {
    CMProfileRef profile;
    CMGetDefaultProfileBySpace(cmRGBData, &profile);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithPlatformColorSpace(profile);
    
    CMCloseProfile(profile);
    CGContextSetStrokeColorSpace(context, colorSpace);
    CGContextSetFillColorSpace(context, colorSpace);
    CGColorSpaceRelease(colorSpace);
    
    [super drawWithBox:box inContext:context];
}

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

- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setContents:(NSString *)contents {
    [super setContents:contents];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

- (void)setColor:(NSColor *)color {
    [super setColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification object:self];
}

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

- (void)setBounds:(NSRect)bounds {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"bounds", @"key", nil]];
    [super setBounds:bounds];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"bounds", @"key", nil]];
}

- (void)setContents:(NSString *)contents {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"contents", @"key", nil]];
    [super setContents:contents];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"contents", @"key", nil]];
}

- (void)setColor:(NSColor *)color {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"color", @"key", nil]];
    [super setColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"color", @"key", nil]];
}

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

- (void)setBounds:(NSRect)bounds {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"bounds", @"key", nil]];
    [super setBounds:bounds];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"bounds", @"key", nil]];
}

- (void)setContents:(NSString *)contents {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"contents", @"key", nil]];
    [super setContents:contents];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"contents", @"key", nil]];
}

- (void)setColor:(NSColor *)color {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"color", @"key", nil]];
    [super setColor:color];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
            object:self
          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"color", @"key", nil]];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
                object:self
              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"image", @"key", nil]];
        [image release];
        image = [newImage retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
                object:self
              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"image", @"key", nil]];
    }
}

- (NSAttributedString *)text;
{
    return text;
}

- (void)setText:(NSAttributedString *)newText;
{
    if (text != newText) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationWillChangeNotification
                object:self
              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"text", @"key", nil]];
        [text release];
        text = [newText retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKAnnotationDidChangeNotification
                object:self
              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"text", @"key", nil]];
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
        rowHeight = 85.0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAnnotationDidChangeNotification:) 
                                                     name:SKAnnotationDidChangeNotification object:annotation];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (PDFAnnotation *)annotation {
    return annotation;
}

- (NSArray *)texts { return nil; }

- (NSString *)type { return nil; }

- (PDFPage *)page { return nil; }

- (unsigned int)pageIndex { return [annotation pageIndex]; }

- (NSAttributedString *)contents { return [annotation text]; }

- (float)rowHeight {
    return rowHeight;
}

- (void)setRowHeight:(float)newRowHeight {
    rowHeight = newRowHeight;
}

- (void)handleAnnotationDidChangeNotification:(NSNotification *)notification {
    if ([[[notification userInfo] objectForKey:@"key"] isEqualToString:@"text"]) {
        [self willChangeValueForKey:@"contents"];
        [self didChangeValueForKey:@"contents"];
    }
}

@end
