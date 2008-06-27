//
//  NSFileManager_SKNExtensions.h
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


/*!
    @category    NSFileManager (SKNExtensions)
    @abstract    Provides methods to access Skim notes in extended attributes or PDF bundles.
    @discussion  (comprehensive description)
*/
@interface NSFileManager (SKNExtensions)

/*!
    @method     readSkimNotesFromExtendedAttributesAtURL:error:
    @abstract   Reads Skim notes as an array of property dictionaries from the extended attributes of a file.
    @discussion (comprehensive description)
    @param      aURL (description)
    @param      outError (description)
    @result     (description)
*/
- (NSArray *)readSkimNotesFromExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError;

/*!
    @method     readSkimTextNotesFromExtendedAttributesAtURL:error:
    @abstract   Reads text Skim notes as a string from the extended attributes of a file.
    @discussion (comprehensive description)
    @param      aURL (description)
    @param      outError (description)
    @result     (description)
*/
- (NSString *)readSkimTextNotesFromExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError;

/*!
    @method     readSkimRTFNotesFromExtendedAttributesAtURL:error:
    @abstract   Reads rich text Skim notes as RTF data from the extended attributes of a file.
    @discussion (comprehensive description)
    @param      aURL (description)
    @param      outError (description)
    @result     (description)
*/
- (NSData *)readSkimRTFNotesFromExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError;

/*!
    @method     readSkimNotesFromPDFBundleAtURL:error:
    @abstract   Reads Skim notes as an array of property dictionaries from the contents of a PDF bundle.
    @discussion (comprehensive description)
    @param      aURL (description)
    @param      outError (description)
    @result     (description)
*/
- (NSArray *)readSkimNotesFromPDFBundleAtURL:(NSURL *)aURL error:(NSError **)outError;

/*!
    @method     readSkimTextNotesFromPDFBundleAtURL:error:
    @abstract   Reads text Skim notes as a string from the contents of a PDF bundle.
    @discussion (comprehensive description)
    @param      aURL (description)
    @param      outError (description)
    @result     (description)
*/
- (NSString *)readSkimTextNotesFromPDFBundleAtURL:(NSURL *)aURL error:(NSError **)outError;

/*!
    @method     readSkimRTFNotesFromPDFBundleAtURL:error:
    @abstract   Reads rich text Skim notes as RTF data from the contents of a PDF bundle.
    @discussion (comprehensive description)
    @param      aURL (description)
    @param      outError (description)
    @result     (description)
*/
- (NSData *)readSkimRTFNotesFromPDFBundleAtURL:(NSURL *)aURL error:(NSError **)outError;

/*!
    @method     readSkimNotesFromSkimFileAtURL:error:
    @abstract   Reads Skim notes as an array of property dictionaries from the contents of a .skim file.
    @discussion (comprehensive description)
    @param      aURL (description)
    @param      outError (description)
    @result     (description)
*/
- (NSArray *)readSkimNotesFromSkimFileAtURL:(NSURL *)aURL error:(NSError **)outError;

/*!
    @method     writeSkimNotes:toExtendedAttributesAtURL:error:
    @abstract   Calls writeSkimNotes:textNotes:richTextNotes:toExtendedAttributesAtURL:error: with nil notesString and notesRTFData.
    @discussion (comprehensive description)
    @param      notes (description)
    @param      aURL (description)
    @param      outError (description)
    @result     (description)
*/
- (BOOL)writeSkimNotes:(NSArray *)notes toExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError;

/*!
    @method     writeSkimNotes:textNotes:richTextNotes:toExtendedAttributesAtURL:error:
    @abstract   Writes Skim notes passed as an array of property dictionaries to the extended attributes of a file, as well as text Skim notes and RTF Skim notes.  The array is converted to NSData using NSKeyedArchiver.
    @discussion (comprehensive description)
    @param      notes (description)
    @param      notesString (description)
    @param      notesRTFData (description)
    @param      aURL (description)
    @param      outError (description)
    @result     (description)
*/
- (BOOL)writeSkimNotes:(NSArray *)notes textNotes:(NSString *)notesString richTextNotes:(NSData *)notesRTFData toExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError;

/*!
    @method     writeSkimNotes:toSkimFileAtURL:error:
    @abstract   Writes Skim notes passed as an array of property dictionaries to a .skim file.
    @discussion (comprehensive description)
    @param      notes (description)
    @param      aURL (description)
    @param      outError (description)
    @result     (description)
*/
- (BOOL)writeSkimNotes:(NSArray *)notes toSkimFileAtURL:(NSURL *)aURL error:(NSError **)outError;

/*!
    @method     bundledFileWithExtension:inPDFBundleAtPath:error:
    @abstract   Returns the full path for the file of a given type inside a PDF bundle.
    @discussion (comprehensive description)
    @param      extension (description)
    @param      path (description)
    @param      outError (description)
    @result     (description)
*/
- (NSString *)bundledFileWithExtension:(NSString *)extension inPDFBundleAtPath:(NSString *)path error:(NSError **)outError;

@end
