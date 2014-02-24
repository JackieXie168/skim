//
//  PDFAnnotation_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 4/1/08.
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "NSGeometry_SKExtensions.h"


extern NSString *SKPDFAnnotationScriptingBorderStyleKey;
extern NSString *SKPDFAnnotationScriptingColorKey;
extern NSString *SKPDFAnnotationScriptingModificationDateKey;
extern NSString *SKPDFAnnotationScriptingUserNameKey;

extern NSString *SKPasteboardTypeSkimNote;

@class SKPDFView;

@interface PDFAnnotation (SKExtensions) <NSPasteboardReading, NSPasteboardWriting>

+ (PDFAnnotation *)currentActiveAnnotation;
+ (void)setCurrentActiveAnnotation:(PDFAnnotation *)annotation;

- (NSString *)fdfString;

- (PDFDestination *)destination;
- (NSUInteger)pageIndex;

- (PDFBorderStyle)borderStyle;
- (void)setBorderStyle:(PDFBorderStyle)style;
- (CGFloat)lineWidth;
- (void)setLineWidth:(CGFloat)width;
- (NSArray *)dashPattern;
- (void)setDashPattern:(NSArray *)pattern;

- (PDFTextAnnotationIconType)iconType;
- (NSImage *)image;
- (NSAttributedString *)text;

- (NSArray *)texts;

- (BOOL)isMarkup;
- (BOOL)isNote;
- (BOOL)isLine;
- (BOOL)isLink;
- (BOOL)isResizable;
- (BOOL)isMovable;
- (BOOL)isEditable;
- (BOOL)hasBorder;

- (BOOL)isConvertibleAnnotation;

- (BOOL)hitTest:(NSPoint)point;

- (NSRect)displayRectForBounds:(NSRect)bounds lineWidth:(CGFloat)lineWidth;
- (NSRect)displayRect;

- (SKRectEdges)resizeHandleForPoint:(NSPoint)point scaleFactor:(CGFloat)scaleFactor;

- (void)drawSelectionHighlightForView:(PDFView *)pdfView;

- (void)registerUserName;

- (void)autoUpdateString;

- (NSSet *)keysForValuesToObserveForUndo;

+ (NSSet *)customScriptingKeys;
- (NSScriptObjectSpecifier *)objectSpecifier;
- (NSColor *)scriptingColor;
- (void)setScriptingColor:(NSColor *)newColor;
- (PDFPage *)scriptingPage;
- (NSDate *)scriptingModificationDate;
- (void)setScriptingModificationDate:(NSDate *)date;
- (NSString *)scriptingUserName;
- (void)setScriptingUserName:(NSString *)name;
- (PDFTextAnnotationIconType)scriptingIconType;
- (id)textContents;
- (void)setTextContents:(id)text;
- (id)richText;
- (void)setBoundsAsQDRect:(NSData *)inQDBoundsAsData;
- (NSData *)boundsAsQDRect;
- (NSTextAlignment)scriptingAlignment;
- (NSString *)fontName;
- (CGFloat)fontSize;
- (NSColor *)scriptingFontColor;
- (NSColor *)scriptingInteriorColor;
- (PDFBorderStyle)scriptingBorderStyle;
- (void)setScriptingBorderStyle:(PDFBorderStyle)style;
- (NSData *)startPointAsQDPoint;
- (NSData *)endPointAsQDPoint;
- (PDFLineStyle)scriptingStartLineStyle;
- (PDFLineStyle)scriptingEndLineStyle;
- (id)selectionSpecifier;
- (NSArray *)scriptingPointLists;

- (NSArray *)accessibilityAttributeNames;
- (id)accessibilityRoleAttribute;
- (id)accessibilityRoleDescriptionAttribute;
- (id)accessibilityDescriptionAttribute;
- (id)accessibilityTitleAttribute;

@end
