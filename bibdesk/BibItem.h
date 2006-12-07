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
#import "BDSKFontManager.h"
#import "BDAlias.h"
#import "BDSKFormatParser.h"

@class BibEditor;
@class BibDocument;

/*!
@class BibItem
@abstract The model class for individual citations
@discussion This is the data model class that encapsulates each Bibtex entry. BibItems are created for each entry in a file, and a BibDocument keeps collections of BibItems. They are also created in response to drag-in or paste operations containing BibTeX source. Their textvalue method is used to provide the text that is written to a file on saves.

*/
@interface BibItem : NSObject <NSCopying, NSCoding>{
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
    int fileOrder;
	BOOL needsToBeFiled;
	BibDocument *document;
	NSLock *bibLock;
    BOOL hasBeenEdited;
}

/*!
     @method init
     @abstract Initializes an alloc'd BibItem to a default type, empty authors array and createdDate the current date. 
     @discussion This initializer should be used for a newly added BibItem only, as it sets the created date. It calls the designated initializer. 
     @result The receiver, initialized to the default type, containing an an empty pubFields fieldsDict, empty authors authArray, and with date created and modified set to the current date.
*/
- (id)init;

/*!
     @method initWithType:fileType:pubFields:authors:createdDate:
     @abstract Initializes an alloc'd BibItem to a type and allows to set the authors. This is the designated intializer.
     @discussion This lets you set the type and the Authors array at initialization time. Call it with an empty array for authArray if you don't want to do that -<em>Don't use nil</em> The authors array is kept up but isn't used much right now. This will change. The createdDate should be nil when the BibItem is not newly added, such as in a parser. 
     @param fileType A string representing which kind of file this item was read from.
     @param type A string representing the type of entry this item is - used to make the BibItem have the right entries in its dictionary.
     @param fieldsDict The dictionary of fields to initialize the item with.
     @param authArray A NSMutableArray of NSStrings, one for each author.
     @param date The created date of the BibItem. Pass nil if this is not a newly added BibItem (i.e. when it is added from a file). 
     @result The receiver, initialized to type and containing authors authArray.
*/
- (id)initWithType:(NSString *)type fileType:(NSString *)inFileType pubFields:(NSDictionary *)fieldsDict authors:(NSMutableArray *)authArray createdDate:(NSCalendarDate *)date;

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
- (NSComparisonResult)containerWithoutTeXCompare:(BibItem *)aBI;
- (NSComparisonResult)titleWithoutTeXCompare:(BibItem *)aBI;
- (NSComparisonResult)dateCompare:(BibItem *)aBI;
- (NSComparisonResult)auth1Compare:(BibItem *)aBI;
- (NSComparisonResult)auth2Compare:(BibItem *)aBI;
- (NSComparisonResult)auth3Compare:(BibItem *)aBI;
- (NSComparisonResult)authorCompare:(BibItem *)aBI;

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

- (NSString *)container;

- (void)setDate: (NSCalendarDate *)newDate;
- (NSCalendarDate *)date;

- (NSCalendarDate *)dateCreated;
- (void)setDateCreated:(NSCalendarDate *)newDateCreated;
- (NSCalendarDate *)dateModified;
- (void)setDateModified:(NSCalendarDate *)newDateModified;


- (void)setType: (NSString *)newType;
- (NSString *)type;

/*!
    @method     setHasBeenEdited:
    @abstract   Must be set to YES if the BibItem has been edited externally.
    @discussion (comprehensive description)
    @param      yn (description)
*/
- (void)setHasBeenEdited:(BOOL)yn;
/*!
    @method     hasBeenEdited
    @abstract   Returns YES if the BibItem has been edited (type or metadata changed) externally.
    @discussion (comprehensive description)
    @result     (description)
*/
- (BOOL)hasBeenEdited;

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
	@method     setCiteKey:
	@abstract   basic setter for the cite key, with notification and undo and current modified date. 
	@discussion -
*/
- (void)setCiteKey:(NSString *)newCiteKey;

/*!
	@method     setCiteKey:withModDate:
	@abstract   basic setter for the cite key, with notification and undo.
	@discussion -
*/
- (void)setCiteKey:(NSString *)newCiteKey withModDate:(NSCalendarDate *)date;

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
	@method    copyComplexStringValues 
	@abstract  Copies all field values which are complex strings. 
	@discussion -
*/
- (void)copyComplexStringValues;

/*!
	@method    updateComplexStringValues 
	@abstract  Updates the macroResolver for all field values which are complex strings. 
	@discussion -
*/
- (void)updateComplexStringValues;

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

- (NSString *)acronymValueOfField:(NSString *)key;

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
 @abstract  returns the bibtex source for this bib item.  Is TeXified based on default preferences for the application.
    @discussion «discussion»
    
*/
- (NSString *)bibTeXString;

/*!
    @method     bibTeXStringDroppingInternal:
    @abstract   Returns the BibTeX value of this bib item.  It is TeXified based on default prefs for the application.
    @param      drop Boolean determines whether internal fields are dropped. 
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSString *)bibTeXStringDroppingInternal:(BOOL)drop;

/*!
    @method     bibTeXStringByExpandingMacros
    @abstract   Returns the BibTeX value of this bib item with macros expanded.  It is TeXified based on default prefs for the application.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSString *)bibTeXStringByExpandingMacros;

/*!
    @method     RISStringValue
    @abstract   Returns the value of the BibItem in Reference Manager (RIS) format.  BibTeX tags are converted to RIS by the type manager.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSString *)RISStringValue;

/*!
    @method RTFValue
    @abstract  returns a pretty RTF display for this bib item.
    @discussion «discussion»
    
*/
- (NSData *)RTFValue;


/*!
    @method     attributedStringValue
    @abstract   Returns an attributed string representation of the receiver, suitable for display purposes
    @discussion Uses the default font family set in the preferences
    @result     (description)
*/
- (NSAttributedString *)attributedStringValue;
/*!
    @method     attributedStringByParsingTeX:inField:defaultStyle:
    @abstract   Parses a TeX style, e.g. \textit{some text} and returns an attributed string equivalent.
    @discussion A hairy regular expression is used to deal with nested braces
    @param      texStr The string to parse, including all braces
    @param      field The name of the field, used to get the font
    @param      defaultStyle The paragraph style to use for this field
    @param      collapse Whether or not to collapse whitespace and remove surrounding whitespace
    @result     (description)
*/
- (NSAttributedString *)attributedStringByParsingTeX:(NSString *)texStr inField:(NSString *)field defaultStyle:(NSParagraphStyle *)defaultStyle collapse:(BOOL)collapse;
    /*!
    @method RSSValue
     @abstract returns an MODS XML string
     @discussion «discussion»
     
     */

- (NSString *)MODSString;


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

/*!
    @method     localURLPath
    @abstract   Calls localURLPathRelativeTo: with the path to the document.
    @discussion -
    @result     a complete path with no tildes, or nil if an error occurred.
*/
- (NSString *)localURLPath; 

/*!
    @method     localURLPathRelativeTo:
    @abstract   attempts to return a path to the local-url file, relative to the base parameter
    @discussion If the local-url field is a relative path, this will prepend base to it and return the path from building a URL with the result. If the value of local-url is a valid file url already, base is ignored. Base is also ignored if the value of local-url is an absolute path or has a tilde.
    @param      base a path to serve as the base for resolving the relative path.
    @result     a complete path with no tildes, or nil if an error occurred.
*/
- (NSString *)localURLPathRelativeTo:(NSString *)base; 

/*!
    @method suggestedLocalUrl
    @abstract Returns a suggested local-url based on the receiver
    @discussion Returns a suggested local-url based on the local-url format and the receivers publication  data. 
    @result The suggested full path for the local file
*/
- (NSString *)suggestedLocalUrl;

/*!
    @method canSetLocalUrl
    @abstract Returns a boolean indicating whether all fields required for the generated local-url are set
    @discussion - 
*/
- (BOOL)canSetLocalUrl;

/*!
    @method needsToBeFiled
    @abstract Returns a boolean indicating whether the linked file should be automatically filed 
    @discussion - 
*/
- (BOOL)needsToBeFiled;

/*!
    @method setNeedsToBeFiled:
    @abstract Sets a boolean indicating whether the linked file should be automatically filed
    @discussion - 
*/
- (void)setNeedsToBeFiled:(BOOL)flag;

/*!
    @method autoFilePaper
    @abstract Automatically file a paper when all necessary fields are set, otherwise flags to be filed. Does nothing when the preference is set to not file automatically.  
    @discussion - 
*/
- (void)autoFilePaper;

- (void)typeInfoDidChange:(NSNotification *)aNotification;
@end


