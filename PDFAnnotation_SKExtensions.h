//
//  PDFAnnotation_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 4/1/08.
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


enum {
    SKScriptingTextNote = 'NTxt',
    SKScriptingAnchoredNote = 'NAnc',
    SKScriptingCircleNote = 'NCir',
    SKScriptingSquareNote = 'NSqu',
    SKScriptingHighlightNote = 'NHil',
    SKScriptingUnderlineNote = 'NUnd',
    SKScriptingStrikeOutNote = 'NStr',
    SKScriptingLineNote = 'NLin'
};

enum {
    SKScriptingBorderStyleSolid = 'Soli',
    SKScriptingBorderStyleDashed = 'Dash',
    SKScriptingBorderStyleBeveled = 'Bevl',
    SKScriptingBorderStyleInset = 'Inst',
    SKScriptingBorderStyleUnderline = 'Undl'
};


extern int SKScriptingBorderStyleFromBorderStyle(int borderStyle);
extern int SKBorderStyleFromScriptingBorderStyle(int borderStyle);


extern NSString *SKPDFAnnotationTypeKey;
extern NSString *SKPDFAnnotationBoundsKey;
extern NSString *SKPDFAnnotationPageIndexKey;
extern NSString *SKPDFAnnotationContentsKey;
extern NSString *SKPDFAnnotationStringKey;
extern NSString *SKPDFAnnotationColorKey;
extern NSString *SKPDFAnnotationBorderKey;
extern NSString *SKPDFAnnotationLineWidthKey;
extern NSString *SKPDFAnnotationBorderStyleKey;
extern NSString *SKPDFAnnotationDashPatternKey;

extern NSString *SKPDFAnnotationScriptingNoteTypeKey;
extern NSString *SKPDFAnnotationScriptingBorderStyleKey;


@interface PDFAnnotation (SKExtensions)

- (id)initWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)dictionaryValue;

- (NSString *)fdfString;

- (PDFDestination *)destination;
- (unsigned int)pageIndex;

- (PDFBorderStyle)borderStyle;
- (void)setBorderStyle:(PDFBorderStyle)style;
- (float)lineWidth;
- (void)setLineWidth:(float)width;
- (NSArray *)dashPattern;
- (void)setDashPattern:(NSArray *)pattern;

- (NSString *)string;
- (void)setString:(NSString *)newString;

- (NSImage *)image;
- (NSAttributedString *)text;

- (NSArray *)texts;

- (BOOL)isNoteAnnotation;
- (BOOL)isMarkupAnnotation;
- (BOOL)isTemporaryAnnotation;
- (BOOL)isResizable;
- (BOOL)isMovable;
- (BOOL)isEditable;

- (BOOL)isConvertibleAnnotation;
- (id)copyNoteAnnotation;

- (BOOL)hitTest:(NSPoint)point;

- (NSRect)displayRectForBounds:(NSRect)bounds;

- (NSSet *)keysForValuesToObserveForUndo;

- (NSScriptObjectSpecifier *)objectSpecifier;
- (int)scriptingNoteType;
- (int)scriptingIconType;
- (id)textContents;
- (void)setTextContents:(id)text;
- (id)richText;
- (void)setBoundsAsQDRect:(NSData *)inQDBoundsAsData;
- (NSData *)boundsAsQDRect;
- (NSString *)fontName;
- (float)fontSize;
- (int)scriptingBorderStyle;
- (void)setScriptingBorderStyle:(int)style;
- (NSData *)startPointAsQDPoint;
- (NSData *)endPointAsQDPoint;
- (int)scriptingStartLineStyle;
- (int)scriptingEndLineStyle;
- (id)selectionSpecifier;

@end
