//
//  SKFDFParser.h
//  Skim
//
//  Created by Christiaan Hofman on 9/6/07.
/*
 This software is Copyright (c) 2007-2008
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

extern const char *SKFDFAnnotationCatalogKey;
extern const char *SKFDFAnnotationAnnotsKey;
extern const char *SKFDFAnnotationTypeKey;
extern const char *SKFDFAnnotationFlagsKey;
extern const char *SKFDFAnnotationSubtypeKey;
extern const char *SKFDFAnnotationRectKey;
extern const char *SKFDFAnnotationContentsKey;
extern const char *SKFDFAnnotationBoundsKey;
extern const char *SKFDFAnnotationPageKey;
extern const char *SKFDFAnnotationColorKey;
extern const char *SKFDFAnnotationInteriorColorKey;
extern const char *SKFDFAnnotationBorderStylesKey;
extern const char *SKFDFAnnotationLineWidthKey;
extern const char *SKFDFAnnotationDashPatternKey;
extern const char *SKFDFAnnotationBorderStyleKey;
extern const char *SKFDFAnnotationBorderKey;
extern const char *SKFDFAnnotationIconTypeKey;
extern const char *SKFDFAnnotationLineStylesKey;
extern const char *SKFDFAnnotationLinePointsKey;
extern const char *SKFDFAnnotationQuadPointsKey;
extern const char *SKFDFDefaultAppearanceKey;
extern const char *SKFDFDefaultStyleKey;

extern const char *SKFDFAnnotation;

extern const char *SKFDFBorderStyleSolid;
extern const char *SKFDFBorderStyleDashed;
extern const char *SKFDFBorderStyleBeveled;
extern const char *SKFDFBorderStyleInset;
extern const char *SKFDFBorderStyleUnderline;

extern const char *SKFDFTextAnnotationIconComment;
extern const char *SKFDFTextAnnotationIconKey;
extern const char *SKFDFTextAnnotationIconNote;
extern const char *SKFDFTextAnnotationIconNewParagraph;
extern const char *SKFDFTextAnnotationIconParagraph;
extern const char *SKFDFTextAnnotationIconInsert;

extern const char *SKFDFLineStyleNone;
extern const char *SKFDFLineStyleSquare;
extern const char *SKFDFLineStyleCircle;
extern const char *SKFDFLineStyleDiamond;
extern const char *SKFDFLineStyleOpenArrow;
extern const char *SKFDFLineStyleClosedArrow;

@interface SKFDFParser : NSObject
+ (NSArray *)noteDictionariesFromFDFData:(NSData *)data;
@end
