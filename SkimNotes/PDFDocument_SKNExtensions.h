//
//  PDFDocument_SKNExtensions.h
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
    @header      PDFDocument_SKNExtensions.h
    @discussion  This file defines an PDFDocument category to add Skim note annotations to a PDFDocument.
*/
#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


/*!
    @category    PDFDocument (SKNExtensions)
    @abstract    Provides methods to add Skim notes to a PDFDocument.
    @discussion  This category can be used to add Skim notes from their properties to a PDFDocument or easily load a PDFDocument including attached Skim notes.
*/
@interface PDFDocument (SKNExtensions)

/*!
    @method     initWithURL:readSkimNotes:
    @abstract   Initializes a new PDFDocument from a file or PDF bundle, adding Skim notes from the extended attributes of the file or the contents of the PDF bundle.  The added Skim notes are returned by reference as an array of PDFAnnotations.
    @discussion Initializes a new PDFDocument using initWithURL:, reads Skim notes from theextended attributes or the bundle, and adds new PDFAnnotation objects to the document initialized by the found Skim note properties.
    @param      url The URL of the PDF file or PDF bundle.
    @param      notes An array of PDFAnnotation objects initialized using the Skim note properties read from the extended attributes or bundled Skim file.
    @result     The initialized PDFDocument.
*/
- (id)initWithURL:(NSURL *)url readSkimNotes:(NSArray **)notes;

/*!
    @method     addSkimNotesWithProperties:
    @abstract   Adds new Skim notes from an array of property dictionaries to the receiver, and returns the added Skim notes as an array of PDFAnnotations.
    @discussion This method initializes new PDFAnnotation objects from the passed in properties and adds them to the appropriate pages of the PDFDocument.
    @param      noteDicts An array of dictionaries containing Skim note properties as returned by the properties of PDFAnnotation objects.
    @result     An array of PDFAnnotation objects initialized using the Skim note properties read from the extended attributes or bundled Skim file.
*/
- (NSArray *)addSkimNotesWithProperties:(NSArray *)noteDicts;

@end
