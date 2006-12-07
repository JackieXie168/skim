// BibItem.h
// Created by Michael McCracken on Tue Dec 18 2001.
/*
 This software is Copyright (c) 2001,2002, Michael O. McCracken
 All rights reserved.

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

/*!
@header BibItem.h
 @discussion This file defines the BibItem model class.
 */

#import <Cocoa/Cocoa.h>
#import "BibEditor.h"
#import "BibTypeManager.h"
#import "BibAuthor.h"
#import "NSString+Templating.h"
#import "BibPrefController.h"
#import "NSString_BDSKExtensions.h"
#import "BDSKConverter.h"

@class BibEditor;
@class BibDocument;

/*!
@class BibItem
@abstract The model class for individual citations
@discussion This is the data model class that encapsulates each Bibtex entry. BibItems are created for each entry in a file, and a BibDocument keeps collections of BibItems. They are also created in response to drag-in or paste operations containing BibTeX source. Their textvalue method is used to provide the text that is written to a file on saves.

*/
@interface BibItem : NSObject <NSCopying>{
    NSString *fileType;
    NSString *citeKey;    /*! @var citeKey the citeKey of the bibItem */
    NSCalendarDate *pubDate;
	NSCalendarDate *dateCreated;
	NSCalendarDate *dateModified;
    NSString *pubType;
    NSMutableDictionary *pubFields;
    NSMutableArray *pubAuthors;
    NSMutableArray *requiredFieldNames;     /*! @var  this is for 'bibtex required fields'*/
    BibEditor *editorObj; /*! @var if we have an editor, don't create a new one. */
    unsigned _fileOrder;
	BibDocument *document;
	NSUndoManager *undoManager;
}

/*!
     @method initWithType:fileType:authors:doc:
     @abstract Initializes an alloc'd BibItem to a type and allows to set the authors.
     @discussion This lets you set the type and the Authors array at initialization time. Call it with an empty array for authArray if you don't want to do that -<em>Don't use nil</em> The authors array is kept up but isn't used much right now. This will change.
 @param fileType A string representing which kind of file this item was read from.
     @param type A string representing the type of entry this item is - used to make the BibItem have the right entries in its dictionary.
     @param authArray A NSMutableArray of NSStrings, one for each author.
  result The receiver, initialized to type and containing authors authArray.
*/
- (id)initWithType:(NSString *)type fileType:(NSString *)inFileType authors:(NSMutableArray *)authArray;

/*!
  @method makeType:
    @abstract Change the type of a BibItem.
    @discussion Changes the type of a BibItem, and rearranges the dictionary. Currently it keeps all the fields that have any text in them, so changing from one type to another with all fields filled in will give you the union of their entries.

 @param type the type (as a NSString *) that you want to make the receiver.
    
*/
- (void)makeType:(NSString *)type;

/*!
    @method dealloc
    @abstract deallocates the receiver and its data objects.
*/
- (void)dealloc;

/*!
@method isRequired:
    @abstract Abstract??
    @discussion This checks for a string that is an entry type identifier (like "Author") and tells you whether or not it is a bibtex-required entry.

 @param rString The string to be checked. (not a great name, no.)
 @result Whether or not rString was required
    
*/
- (BOOL)isRequired:(NSString *)rString; // @@type - move to type class.
- (NSMutableArray*) requiredFieldNames;
- (BibDocument *)document;
- (void)setDocument:(BibDocument *)newDocument;

- (NSUndoManager *)undoManager;
   
- (BibEditor *)editorObj;
- (void)setEditorObj:(BibEditor *)editor;

- (NSString *)description;

// ----------------------------------------------------------------------------------------
// comparisons
// ----------------------------------------------------------------------------------------

- (BOOL)isEqual:(BibItem *)aBI;
- (NSComparisonResult)pubTypeCompare:(BibItem *)aBI;
- (NSComparisonResult)keyCompare:(BibItem *)aBI;
- (NSComparisonResult)titleCompare:(BibItem *)aBI;
- (NSComparisonResult)dateCompare:(BibItem *)aBI;
- (NSComparisonResult)auth1Compare:(BibItem *)aBI;
- (NSComparisonResult)auth2Compare:(BibItem *)aBI;
- (NSComparisonResult)auth3Compare:(BibItem *)aBI;

- (NSComparisonResult)fileOrderCompare:(BibItem *)aBI;

// accessors for fileorder
- (int)fileOrder;
- (void)setFileOrder:(int)ord;
- (NSString *)fileType;
- (void)setFileType:(NSString *)someFileType;


- (int)numberOfAuthors;
- (NSArray *)pubAuthors;
- (void)addAuthorWithName:(NSString *)newAuthorName;

/*!
    @method authorAtIndex
    @abstract returns the author at index index.
    @discussion zero-based indexing
    
*/
- (BibAuthor *)authorAtIndex:(int)index;

- (NSString *)bibtexAuthorString;
- (void)setAuthorsFromBibtexString:(NSString *)aString;

- (NSString *)title;
- (void)setTitle:(NSString *)title;

- (void)setDate: (NSCalendarDate *)newDate;
- (NSCalendarDate *)date;

- (NSCalendarDate *)dateCreated;
- (void)setDateCreated:(NSCalendarDate *)newDateCreated;
- (NSCalendarDate *)dateModified;
- (void)setDateModified:(NSCalendarDate *)newDateModified;


- (void)setType: (NSString *)newType;
- (NSString *)type;

/*!
    @method suggestedCiteKey
    @abstract Returns a suggested cite key based on the receiver
    @discussion Returns a suggested cite key based on the cite key format and the receivers publication  data. 
    @result The suggested cite key string
*/
- (NSString *)suggestedCiteKey;

/*
    @method canSetCiteKey
    @abstract Returns a boolean indicating whether all fields required for the generated cite key are set
    @discussion - 
*/
- (BOOL)canSetCiteKey;

/*!
	@method     setCiteKeyString
	@abstract   basic setter for the cite key, for initialization only.
	@discussion -
*/
- (void)setCiteKeyString:(NSString *)newCiteKey;

/*!
	@method     setCiteKey
	@abstract   basic setter for the cite key, with notification and undo.
	@discussion -
*/
- (void)setCiteKey:(NSString *)newCiteKey;

/*!
	@method     citeKey
	@abstract   returns the cite key, sets a suggested cite key if undefined.
	@discussion -
*/
- (NSString *)citeKey;

/*!
	@method     setPubFields
	@abstract   basic setter for the dictionary of fields, for initialization only.
	@discussion -
*/
- (void)setPubFields: (NSDictionary *)newFields;

/*!
	@method     setFields
	@abstract   setter for the dictionary of fields, with notification and undo.
	@discussion -
*/
- (void)setFields: (NSDictionary *)newFields;

/*!
    @method     updateMetadataForKey
    @abstract   updates derived info from the dictionary
    @discussion -
*/
- (void)updateMetadataForKey:(NSString *)key;

- (void)setRequiredFieldNames: (NSArray *)newRequiredFieldNames;
- (void)setField: (NSString *)key toValue: (NSString *)value;
- (void)setField: (NSString *)key toValue: (NSString *)value withModDate:(NSCalendarDate *)date;

- (NSString *)valueOfField: (NSString *)key;

- (void)removeField: (NSString *)key;
- (void)removeField: (NSString *)key withModDate:(NSCalendarDate *)date;

- (void)addField:(NSString *)key;
- (void)addField:(NSString *)key withModDate:(NSCalendarDate *)date;

- (NSMutableDictionary *)pubFields;

/*!
    @method PDFValue
    @abstract Returns the bibtex formatted pdf image with the user-specified style. 
    @discussion «discussion»
    
*/
- (NSData *)PDFValue;

/*!
    @method bibTeXString
 @abstract  returns the bibtex source for this bib item.
    @discussion «discussion»
    
*/
- (NSString *)bibTeXString;

/*!
    @method RTFValue
    @abstract  returns a pretty RTF display for this bib item.
    @discussion «discussion»
    
*/
- (NSData *)RTFValue;

/*!
    @method RSSValue
    @abstract returns an rss XML entry suitable for embedding in an rss file.
    @discussion «discussion»
    
*/
- (NSString *)RSSValue;

- (NSString *)HTMLValueUsingTemplateString:(NSString *)templateString;

/*!
    @method allFieldsString
    @abstract returns the value of each of the fields concatenated into a single string.
    @discussion «discussion»
    
*/
- (NSString *)allFieldsString; 

- (NSString *)localURLPathRelativeTo:(NSString *)base; 

/*!
    @method suggestedLocalUrl
    @abstract Returns a suggested local-url based on the receiver
    @discussion Returns a suggested local-url based on the local-url format and the receivers publication  data. 
    @result The suggested full path for the local file
*/
- (NSString *)suggestedLocalUrl;

/*!
    @method parseFormat:forField:
    @abstract Generates a value for a field in a type based on the receiver and the format string
    @discussion -
    @param format The format string to use
    @param fieldName The name of the field (e.g. "Author")
	@result The suggested cite key string
*/
- (NSString *)parseFormat:(NSString *)format forField:(NSString *)fieldName;

/*!
    @method uniqueString:suffix:forField:numberOfChars:from:to:force:
    @abstract Tries to return a unique string value for a field in a type, by adding characters from a range
    @discussion -
    @param baseString The string to base the unique string on
    @param suffix The string to add as a suffix to the unique string
    @param fieldName The name of the field (e.g. "Author")
	@param number The number of characters to add, when force is YES the minimal number
	@param fromChar The first character in the range to use
	@param toChar The last character of the range to use
	@param force Determines whether to allow for more characters to force a unique key
	@result A string value for field in type that starts with baseString and is unique when force is YES
*/
- (NSString *)uniqueString:(NSString *)baseString 
					suffix:(NSString *)suffix
				  forField:(NSString *)fieldName 
			 numberOfChars:(unsigned int)number 
					  from:(unichar)fromChar 
						to:(unichar)toChar 
					 force:(BOOL)force;

/*!
    @method stringIsValid:forField:
    @abstract Returns whether a string is a valid as a value for a field in a type
    @discussion -
	@param proposedStr The trial string to check for validity
    @param fieldName The name of the field (e.g. "Author")
*/
- (BOOL)stringIsValid:(NSString *)proposedStr forField:(NSString *)fieldName;
@end


