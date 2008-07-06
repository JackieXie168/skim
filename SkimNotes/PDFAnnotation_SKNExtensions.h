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

/*!
    @header      PDFAnnotation_SKNExtensions.h
    @discussion  This file defines an <code>PDFAnnotation</code> categories to manage Skim notes.
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


/*!
    @category    PDFAnnotation (SKNExtensions)
    @abstract    Provides methods to translate between dictionary representations of Skim notes and <code>PDFAnnotation</code> objects.
    @discussion  Methods from this category are used by the <code>PDFDocument (SKNExtensions)</code> category to add new annotations from Skim notes.
*/
@interface PDFAnnotation (SKNExtensions)

/*!
    @method     initSkimNoteWithBounds:
    @abstract   Initializes a new Skim note annotation.  This is the designated initializer for a Skim note.
    @discussion This method can be implemented in subclasses to provide default properties for Skim notes.
    @param      bounds The bounding box of the annotation, in page space.
    @result     An initialized Skim note annotation instance, or <code>NULL</code> if the object could not be initialized.
*/
- (id)initSkimNoteWithBounds:(NSRect)bounds;

/*!
    @method     initSkimNoteWithProperties:
    @abstract   Initializes a new Skim note annotation with the given properties.
    @discussion This method determines the proper subclass from the value for the <code>"type"</code> key in dict, initializes an instance using <code>initSkimNoteWithBounds:</code>, and sets the known properties from dict. Implementations in subclasses should call it on super and set their properties from dict if available.
    @param      dict A dictionary with Skim notes properties, as returned from properties.  This is required to contain values for <code>"type"</code> and <code>"bounds"</code>.
    @result     An initialized Skim note annotation instance, or <code>NULL</code> if the object could not be initialized.
*/
- (id)initSkimNoteWithProperties:(NSDictionary *)dict;

/*!
    @method     SkimNoteProperties
    @abstract   The Skim notes properties.
    @discussion These properties can be used to initialize a new copy, and to save to extended attributes or file.
    @result     A dictionary with properties of the Skim note.  All values are standard Cocoa objects conforming to <code>NSCoding</code> and <code>NSCopying</code>.
*/
- (NSDictionary *)SkimNoteProperties;

/*!
    @method     isSkimNote
    @abstract   Returns whether the annotation is a Skim note.  
    @discussion An annotation initalized with initializers starting with initSkimNote will return <code>YES</code> by default.
    @result     YES if the annotation is a Skim note; otherwise NO.
*/
- (BOOL)isSkimNote;

/*!
    @method     setSkimNote:
    @abstract   Sets whether the receiver is to be interpreted as a Skim note.
    @discussion You normally would not use this yourself, but rely on the initializer to set the <code>isSkimNote</code> flag.
    @param      flag Set this value to <code>YES</code> if you want the annotation to be interpreted as a Skim note.
*/
- (void)setSkimNote:(BOOL)flag;

/*!
    @method     string
    @abstract   The string value of the annotation.
    @discussion By default, this is just the same as the contents.  However for <code>SKNPDFAnnotationNote</code> the contents will contain both string and text.
    @result     A string representing the string value associated with the annotation.
*/
- (NSString *)string;

/*!
    @method     setString:
    @abstract   Sets the string of the annotation.  By default just sets the contents.
    @discussion By default just calls <code>setContent:</code>.
    @param      newString The new string value for the annotation.
*/
- (void)setString:(NSString *)newString;

@end

#pragma mark -

/*!
    @category    PDFAnnotationCircle (SKNExtensions)
    @abstract    Provides methods to translate between dictionary representations of Skim notes and <code>PDFAnnotation</code> objects.
    @discussion  Implements <code>initSkimNotesWithProperties:</code> and properties to take care of the extra properties of a circle annotation.
*/
@interface PDFAnnotationCircle (SKNExtensions)
@end

#pragma mark -

/*!
    @category    PDFAnnotationSquare (SKNExtensions)
    @abstract    Provides methods to translate between dictionary representations of Skim notes and <code>PDFAnnotation</code> objects.
    @discussion  Implements <code>initSkimNotesWithProperties:</code> and properties to take care of the extra properties of a square annotation.
*/
@interface PDFAnnotationSquare (SKNExtensions)
@end

#pragma mark -

/*!
    @category    PDFAnnotationLine (SKNExtensions)
    @abstract    Provides methods to translate between dictionary representations of Skim notes and <code>PDFAnnotation</code> objects.
    @discussion  Implements <code>initSkimNotesWithProperties:</code> and properties to take care of the extra properties of a line annotation.
*/
@interface PDFAnnotationLine (SKNExtensions)
@end

#pragma mark -

/*!
    @category    PDFAnnotationFreeText (SKNExtensions)
    @abstract    Provides methods to translate between dictionary representations of Skim notes and <code>PDFAnnotation</code> objects.
    @discussion  Implements <code>initSkimNotesWithProperties:</code> and properties to take care of the extra properties of a free text annotation.
*/
@interface PDFAnnotationFreeText (SKNExtensions)
@end

#pragma mark -

/*!
    @category    PDFAnnotationMarkup (SKNExtensions)
    @abstract    Provides methods to translate between dictionary representations of Skim notes and <code>PDFAnnotation</code> objects.
    @discussion  Implements <code>initSkimNotesWithProperties:</code> and properties to take care of the extra properties of a markup annotation.
*/
@interface PDFAnnotationMarkup (SKNExtensions)
@end

/*!
    @category    PDFAnnotationMarkup (SKNOptional)
    @abstract    An informal protocol providing a method name for an optional method that may be implemented in a category.
    @discussion  This defines an optional method that another <code>PDFAnnotationMarkup</code> category may implement to provide a default color.
*/
@interface PDFAnnotationMarkup (SKNOptional)
/*!
    @method     defaultSkimNoteColorForMarkupType:
    @abstract   Optional method to implement to return the default color to use for markup initialized with properties that do not contain a color.
    @param      markupType The markup style for which to return the default color.
    @discussion This optional method can be implemented in another category to provide a default color for Skim notes that have no color set in the properties dictionary.  This method is not implemented by default.
    @result     The default color for an annotation with the passed in markup style.
*/
+ (NSColor *)defaultSkimNoteColorForMarkupType:(PDFMarkupType)markupType;
@end

#pragma mark -

/*!
    @category    PDFAnnotationText (SKNExtensions)
    @abstract    Provides methods to translate between dictionary representations of Skim notes and <code>PDFAnnotation</code> objects.
    @discussion  Implements <code>initSkimNotesWithProperties:</code> and properties to take care of the extra properties of a text annotation.
*/
@interface PDFAnnotationText (SKNExtensions)
@end
