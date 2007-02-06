//
//  SKPDFAnnotationNote.h
//  Skim
//
//  Created by Christiaan Hofman on 6/2/07.
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

- (BOOL)isTemporaryAnnotation;

@end

@interface SKPDFAnnotationTemporary : PDFAnnotationCircle
@end

@interface SKPDFAnnotationNote : PDFAnnotationText {
    NSImage *image;
    NSAttributedString *text;
}

- (void)setImage:(NSImage *)newImage;
- (void)setText:(NSAttributedString *)newText;

@end
