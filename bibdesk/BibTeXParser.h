//
//  BibTeXParser.h
//  BibDesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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
@class BibDocument;
@class BibItem;

@interface BibTeXParser : NSObject {
}

/*!
    @method     itemsFromData:error:document:
    @abstract   Convenience method that returns an array of BibItems from the input NSData; used by the pasteboard.  Uses libbtparse to parse the data.
    @discussion (comprehensive description)
    @param      inData (description)
    @param      hadProblems (description)
    @param      aDocument (description)
    @result     (description)
*/
+ (NSMutableArray *)itemsFromData:(NSData *)inData error:(BOOL *)hadProblems document:(BibDocument *)aDocument;

/*!
    @method     itemsFromData:error:frontMatter:filePath:document:
    @abstract   Parsing method that returns an array of BibItems from data, using libbtparse; needs a document to act as macro resolver.
    @discussion (comprehensive description)
    @param      inData (description)
    @param      hadProblems (description)
    @param      frontMatter (description)
    @param      filePath (description)
    @param      aDocument (description)
    @result     (description)
*/
+ (NSMutableArray *)itemsFromData:(NSData *)inData
                            error:(BOOL *)hadProblems
                      frontMatter:(NSMutableString *)frontMatter
                         filePath:(NSString *)filePath
						 document:(BibDocument *)aDocument;

/*!
    @method     macrosFromBibTeXString:hadProblems:document:
    @abstract   Parses a BibTeX string as @string{} declarations, and returns a dictionary of keys and definitions.
    @discussion 
    @param      aString BibTeX as NSString
    @param      hadProblems (description)
    @param      aDocument (description)
    @result     (description)
*/
+ (NSDictionary *)macrosFromBibTeXString:(NSString *)aString hadProblems:(BOOL *)hadProblems document:(BibDocument *)aDocument;


/*!
    @method     macrosFromBibTeXStyle:document:
    @abstract   Returns a dictionary of macro definitions from a BibTeX style file (.bst extension).
    @discussion The definitions take the form <tt>MACRO {ibmjrd} {"IBM Journal of Research and Development"}</tt>
    @param      styleContents The contents of the bst file as a string
    @param      aDocument (description)
    @result     Returns nil if nothing was found or an error occurred.
*/
+ (NSDictionary *)macrosFromBibTeXStyle:(NSString *)styleContents document:(BibDocument *)aDocument;
    
/*!
    @method     stringFromBibTeXValue:error:frontMatter:document:
    @abstract   Parsing method that returns a complex nor simple string for a value entered as BibTeX string, using libbtparse; needs a document to act as macro resolver.
    @discussion (comprehensive description)
    @param      value (description)
    @param      hadProblems (description)
    @param      aDocument (description)
    @result     (description)
*/
+ (NSString *)stringFromBibTeXValue:(NSString *)value error:(BOOL *)hadProblems document:(BibDocument *)aDocument;

/*!
    @method     authorsFromBibtexString:document:
    @abstract   Parses a BibTeX author string (separates components joined by the string "and")
    @discussion (comprehensive description)
    @param      aString The author string
    @param      errorDocument The document associated with the errors; may be nil.
    @result     An array of BibAuthor objects.
*/
+ (NSArray *)authorsFromBibtexString:(NSString *)aString withPublication:(BibItem *)pub document:(id)errorDocument;

@end
