//
//  PDFAnnotation_SKNExtensions.h
//  SkimNotes
//
//  Created by Christiaan Hofman on 6/15/08.
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

extern NSString *SKNFreeTextString;
extern NSString *SKNTextString;
extern NSString *SKNNoteString;
extern NSString *SKNCircleString;
extern NSString *SKNSquareString;
extern NSString *SKNMarkUpString;
extern NSString *SKNHighlightString;
extern NSString *SKNUnderlineString;
extern NSString *SKNStrikeOutString;
extern NSString *SKNLineString;

extern NSString *SKNPDFAnnotationTypeKey;
extern NSString *SKNPDFAnnotationBoundsKey;
extern NSString *SKNPDFAnnotationPageKey;
extern NSString *SKNPDFAnnotationPageIndexKey;
extern NSString *SKNPDFAnnotationContentsKey;
extern NSString *SKNPDFAnnotationStringKey;
extern NSString *SKNPDFAnnotationColorKey;
extern NSString *SKNPDFAnnotationBorderKey;
extern NSString *SKNPDFAnnotationLineWidthKey;
extern NSString *SKNPDFAnnotationBorderStyleKey;
extern NSString *SKNPDFAnnotationDashPatternKey;

extern NSString *SKNPDFAnnotationInteriorColorKey;

extern NSString *SKNPDFAnnotationStartLineStyleKey;
extern NSString *SKNPDFAnnotationEndLineStyleKey;
extern NSString *SKNPDFAnnotationStartPointKey;
extern NSString *SKNPDFAnnotationEndPointKey;

extern NSString *SKNPDFAnnotationFontKey;
extern NSString *SKNPDFAnnotationFontColorKey;
extern NSString *SKNPDFAnnotationFontNameKey;
extern NSString *SKNPDFAnnotationFontSizeKey;
extern NSString *SKNPDFAnnotationRotationKey;

extern NSString *SKNPDFAnnotationQuadrilateralPointsKey;

extern NSString *SKNPDFAnnotationIconTypeKey;


@interface PDFAnnotation (SKNExtensions)

/*!
    @method     initSkimNoteWithBounds:
    @abstract   Initializes a new Skim note annotation .
    @discussion This is the designated intiializer for a SKim note.
    @param      bounds (description)
    @result     (description)
*/
- (id)initSkimNoteWithBounds:(NSRect)bounds;

/*!
    @method     initSkimNoteWithProperties:
    @abstract   Initializes a new Skim note annotation with the given properties.
    @discussion (comprehensive description)
    @param      bounds (description)
    @result     (description)
*/
- (id)initSkimNoteWithProperties:(NSDictionary *)dict;

/*!
    @method     properties
    @abstract   The Skim notes properties.  These properties can be used to initialize a new copy, and to save to extended attributes or file.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSDictionary *)properties;

/*!
    @method     isSkimNote
    @abstract   Returns whether the annotation is a Skim note.  An annotation initalized with initializers starting with initSkimNote will return YES by default.
    @discussion (comprehensive description)
    @result     (description)
*/
- (BOOL)isSkimNote;

/*!
    @method     setSkimNote:
    @abstract   Sets whether the receiver is to be interpreted as a Skim note.  You normally would not use this yourself.
    @discussion (comprehensive description)
*/
- (void)setSkimNote:(BOOL)flag;

/*!
    @method     string
    @abstract   The string value of the annotation.  By default, this is just the same as the contents.  However for SKNPDFAnnotationNote the contents will contain both string and text.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSString *)string;

/*!
    @method     setString:
    @abstract   Sets the string of the annotation.  By default just sets the contents.
    @discussion (comprehensive description)
*/
- (void)setString:(NSString *)newString;

@end

#pragma mark -

@interface PDFAnnotationCircle (SKNExtensions)
@end

#pragma mark -

@interface PDFAnnotationSquare (SKNExtensions)
@end

#pragma mark -

@interface PDFAnnotationLine (SKNExtensions)
@end

#pragma mark -

@interface PDFAnnotationFreeText (SKNExtensions)
@end

#pragma mark -

@interface PDFAnnotationMarkup (SKNExtensions)
@end

@interface PDFAnnotationMarkup (SKNOptional)
/*!
    @method     defaultColorForMarkupType:
    @abstract   This optional method can be implemented in another category to provide a default color for Skim notes that have no color set in the properties dictionary.
    @param      markupType (description)
    @discussion This method is not implemented by default.
*/
+ (NSColor *)defaultColorForMarkupType:(int)markupType;
@end

#pragma mark -

@interface PDFAnnotationText (SKNExtensions)
@end
