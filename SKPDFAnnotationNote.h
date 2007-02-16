//
//  SKPDFAnnotationNote.h
//  Skim
//
//  Created by Christiaan Hofman on 2/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@interface PDFAnnotation (SKExtensions)

- (id)initWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)dictionaryValue;

- (PDFDestination *)destination;
- (unsigned int)pageIndex;
- (NSString *)pageLabel;

- (NSImage *)image;
- (NSAttributedString *)text;

- (BOOL)isNoteAnnotation;
- (BOOL)isTemporaryAnnotation;
- (BOOL)isResizable;

@end

@interface SKPDFAnnotationCircle : PDFAnnotationCircle
@end

@interface SKPDFAnnotationSquare : PDFAnnotationSquare
@end

@interface SKPDFAnnotationFreeText : PDFAnnotationFreeText
@end

@interface SKPDFAnnotationText : PDFAnnotationText
@end

@interface SKPDFAnnotationNote : PDFAnnotationText {
    NSImage *image;
    NSAttributedString *text;
}

- (void)setImage:(NSImage *)newImage;
- (void)setText:(NSAttributedString *)newText;

@end

@interface SKPDFAnnotationTemporary : PDFAnnotationCircle
@end
