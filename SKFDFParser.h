//
//  SKFDFParser.h
//  Skim
//
//  Created by Christiaan Hofman on 9/6/07.
/*
 This software is Copyright (c) 2007-2014
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

typedef const char *SKFDFString;

extern SKFDFString SKFDFFDFKey;
extern SKFDFString SKFDFAnnotationsKey;
extern SKFDFString SKFDFFileKey;
extern SKFDFString SKFDFFileIDKey;
extern SKFDFString SKFDFRootKey;

extern SKFDFString SKFDFTypeKey;

extern SKFDFString SKFDFAnnotationFlagsKey;
extern SKFDFString SKFDFAnnotationTypeKey;
extern SKFDFString SKFDFAnnotationBoundsKey;
extern SKFDFString SKFDFAnnotationPageIndexKey;
extern SKFDFString SKFDFAnnotationContentsKey;
extern SKFDFString SKFDFAnnotationColorKey;
extern SKFDFString SKFDFAnnotationInteriorColorKey;
extern SKFDFString SKFDFAnnotationBorderStylesKey;
extern SKFDFString SKFDFAnnotationLineWidthKey;
extern SKFDFString SKFDFAnnotationDashPatternKey;
extern SKFDFString SKFDFAnnotationBorderStyleKey;
extern SKFDFString SKFDFAnnotationBorderKey;
extern SKFDFString SKFDFAnnotationModificationDateKey;
extern SKFDFString SKFDFAnnotationUserNameKey;
extern SKFDFString SKFDFAnnotationAlignmentKey;
extern SKFDFString SKFDFAnnotationIconTypeKey;
extern SKFDFString SKFDFAnnotationLineStylesKey;
extern SKFDFString SKFDFAnnotationLinePointsKey;
extern SKFDFString SKFDFAnnotationInkListKey;
extern SKFDFString SKFDFAnnotationQuadrilateralPointsKey;
extern SKFDFString SKFDFDefaultAppearanceKey;
extern SKFDFString SKFDFDefaultStyleKey;

extern SKFDFString SKFDFAnnotation;

extern SKFDFString SKFDFBorderStyleSolid;
extern SKFDFString SKFDFBorderStyleDashed;
extern SKFDFString SKFDFBorderStyleBeveled;
extern SKFDFString SKFDFBorderStyleInset;
extern SKFDFString SKFDFBorderStyleUnderline;

extern SKFDFString SKFDFTextAnnotationIconComment;
extern SKFDFString SKFDFTextAnnotationIconKey;
extern SKFDFString SKFDFTextAnnotationIconNote;
extern SKFDFString SKFDFTextAnnotationIconNewParagraph;
extern SKFDFString SKFDFTextAnnotationIconParagraph;
extern SKFDFString SKFDFTextAnnotationIconInsert;

extern SKFDFString SKFDFLineStyleNone;
extern SKFDFString SKFDFLineStyleSquare;
extern SKFDFString SKFDFLineStyleCircle;
extern SKFDFString SKFDFLineStyleDiamond;
extern SKFDFString SKFDFLineStyleOpenArrow;
extern SKFDFString SKFDFLineStyleClosedArrow;

extern NSString *SKFDFStringFromDate(NSDate *date);

extern PDFBorderStyle SKPDFBorderStyleFromFDFBorderStyle(SKFDFString name);
extern SKFDFString SKFDFBorderStyleFromPDFBorderStyle(PDFBorderStyle borderStyle);

extern NSTextAlignment SKPDFFreeTextAnnotationAlignmentFromFDFFreeTextAnnotationAlignment(NSInteger anInt);
extern NSInteger SKFDFFreeTextAnnotationAlignmentFromPDFFreeTextAnnotationAlignment(NSTextAlignment alignment);

extern PDFTextAnnotationIconType SKPDFTextAnnotationIconTypeFromFDFTextAnnotationIconType(SKFDFString name);
extern SKFDFString SKFDFTextAnnotationIconTypeFromPDFTextAnnotationIconType(PDFTextAnnotationIconType iconType);

extern PDFLineStyle SKPDFLineStyleFromFDFLineStyle(SKFDFString name);
extern SKFDFString SKFDFLineStyleFromPDFLineStyle(PDFLineStyle lineStyle);


@interface SKFDFParser : NSObject
+ (NSArray *)noteDictionariesFromFDFData:(NSData *)data;
@end


@interface NSMutableString (SKFDFExtensions)
- (void)appendFDFName:(SKFDFString)name;
@end
