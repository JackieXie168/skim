//
//  SKPDFAnnotationNote.h
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

extern NSString *SKAnnotationWillChangeNotification;
extern NSString *SKAnnotationDidChangeNotification;

extern void SKCGContextSetDefaultRGBColorSpace(CGContextRef context);

@interface PDFAnnotation (SKExtensions)

- (id)initWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)dictionaryValue;

- (PDFDestination *)destination;
- (unsigned int)pageIndex;

- (NSImage *)image;
- (NSAttributedString *)text;

- (NSArray *)texts;

- (BOOL)isNoteAnnotation;
- (BOOL)isTemporaryAnnotation;
- (BOOL)isResizable;
- (BOOL)isMovable;
- (BOOL)isEditable;

- (NSUndoManager *)undoManager;

- (BOOL)hitTest:(NSPoint)point;

- (NSScriptObjectSpecifier *)objectSpecifier;
- (int)noteType;
- (id)textContents;
- (void)setTextContents:(id)text;
- (id)richText;
- (void)setBoundsAsQDRect:(NSData *)inQDBoundsAsData;
- (NSData *)boundsAsQDRect;
- (NSData *)startPointAsQDPoint;
- (NSData *)endPointAsQDPoint;
- (id)handleGoToScriptCommand:(NSScriptCommand *)command;

@end

@interface SKPDFAnnotationCircle : PDFAnnotationCircle
@end

@interface SKPDFAnnotationSquare : PDFAnnotationSquare
@end

@interface SKPDFAnnotationMarkup : PDFAnnotationMarkup
{
    NSRect *lineRects;
    unsigned numberOfLines;
}
- (id)initWithBounds:(NSRect)bounds markupType:(int)type quadrilateralPointsAsStrings:(NSArray *)pointStrings;
- (id)initWithSelection:(PDFSelection *)selection markupType:(int)type;
@end

@interface SKPDFAnnotationFreeText : PDFAnnotationFreeText
@end

@interface SKPDFAnnotationNote : PDFAnnotationText {
    NSImage *image;
    NSTextStorage *textStorage;
    NSAttributedString *text;
    NSArray *texts;
}

- (void)setImage:(NSImage *)newImage;
- (void)setText:(NSAttributedString *)newText;

- (void)setRichText:(id)newText;

@end

@interface SKPDFAnnotationLine : PDFAnnotationLine

- (void)setStartPointAsQDPoint:(NSData *)inQDPointAsData;
- (void)setEndPointAsQDPoint:(NSData *)inQDPointAsData;

@end

@interface SKPDFAnnotationTemporary : PDFAnnotationCircle
@end

@interface SKNoteText : NSObject {
    PDFAnnotation *annotation;
    float rowHeight;
}

- (id)initWithAnnotation:(PDFAnnotation *)anAnnotation;

- (PDFAnnotation *)annotation;

- (NSArray *)texts;

- (NSString *)type;
- (PDFPage *)page;
- (unsigned int)pageIndex;
- (NSAttributedString *)contents;

- (float)rowHeight;
- (void)setRowHeight:(float)newRowHeight;

- (void)handleAnnotationDidChangeNotification:(NSNotification *)notification;

@end


static inline
Rect RectFromNSRect(NSRect rect) {
    Rect qdRect;
    qdRect.left = round(NSMinX(rect));
    qdRect.bottom = round(NSMinY(rect));
    qdRect.right = round(NSMaxX(rect));
    qdRect.top = round(NSMaxY(rect));
    return qdRect;
}

static inline
NSRect NSRectFromRect(Rect qdRect) {
    NSRect rect;
    rect.origin.x = (float)qdRect.left;
    rect.origin.y = (float)qdRect.bottom;
    rect.size.width = (float)(qdRect.right - qdRect.left);
    rect.size.height = (float)(qdRect.top - qdRect.bottom);
    return rect;
}


static inline
Point PointFromNSPoint(NSPoint point) {
    Point qdPoint;
    qdPoint.h = round(point.x);
    qdPoint.v = round(point.y);
    return qdPoint;
}

static inline
NSPoint NSPointFromPoint(Point qdPoint) {
    NSPoint point;
    point.x = (float)qdPoint.h;
    point.y = (float)qdPoint.v;
    return point;
}
