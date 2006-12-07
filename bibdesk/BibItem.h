// BibItem.h
// Created by Michael McCracken on Tue Dec 18 2001.
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005
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

/*!
@header BibItem.h
 @discussion This file defines the BibItem model class.
 */

#import <Cocoa/Cocoa.h>
#import <OmniFoundation/OFObject.h>

@class BibEditor;
@class BibDocument;
@class BDSKGroup;
@class BibAuthor;

/*!
@class BibItem
@abstract The model class for individual citations
@discussion This is the data model class that encapsulates each Bibtex entry. BibItems are created for each entry in a file, and a BibDocument keeps collections of BibItems. They are also created in response to drag-in or paste operations containing BibTeX source. Their textvalue method is used to provide the text that is written to a file on saves.

*/
@interface BibItem : OFObject <NSCopying, NSCoding>{
    NSString *fileType;
    NSString *citeKey;    /*! @var citeKey the citeKey of the bibItem */
    NSCalendarDate *pubDate;
	NSCalendarDate *dateCreated;
	NSCalendarDate *dateModified;
	NSString *pubType;
    NSMutableDictionary *pubFields;
    NSMutableArray *pubAuthors;
	NSMutableDictionary *groups;
    BibEditor *editorObj; /*! @var if we have an editor, don't create a new one. */
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
    @method makeType
    @abstract Setup the type of a BibItem.
    @discussion Rearranges the dictionary for the current type. Currently it keeps all the fields that have any text in them, so changing from one type to another with all fields filled in will give you the union of their entries.
*/
- (void)makeType;

/*!
    @method dealloc
    @abstract deallocates the receiver and its data objects.
*/
- (void)dealloc;

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

// accessors for fileorder
- (NSNumber *)fileOrder;

- (NSString *)fileType;
- (void)setFileType:(NSString *)someFileType;



/*!
    @method numberOfAuthors
    @abstract Calls numberOfAuthorsInheriting: with inherit set to YES. 
    @discussion (discussion)
    
*/
- (int)numberOfAuthors;

/*!
    @method numberOfAuthorsInheriting:
    @abstract Returns the number of authors.
	@param inherit Boolean, if set follows the Crossref to find inherited authors.
    @discussion (discussion)
    
*/
- (int)numberOfAuthorsInheriting:(BOOL)inherit;

/*!
    @method pubAuthors
    @abstract Calls pubAuthorsInheriting: with inherit set to YES. 
    @discussion (discussion)
    
*/
- (NSArray *)pubAuthors;

/*!
    @method pubAuthorsInheriting:
    @abstract Returns the authors array of the publication.
	@param inherit Boolean, if set follows the Crossref to find inherited authors.
    @discussion (discussion)
    
*/
- (NSArray *)pubAuthorsInheriting:(BOOL)inherit;

/*!
    @method     pubAuthorsAsStrings
    @abstract   Returns an array of normalized names for the publications authors.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSArray *)pubAuthorsAsStrings;

/*!
    @method addAuthorWithName:
    @abstract Add an author to the authors array. 
	@param newAuthorName The name of the new author.
    @discussion (discussion)
    
*/
- (void)addAuthorWithName:(NSString *)newAuthorName;

/*!
    @method authorAtIndex:
    @abstract Calls authorAtIndex:inherit: with inherit set to YES. 
	@param index The index for the author
    @discussion zero-based indexing
    
*/
- (BibAuthor *)authorAtIndex:(int)index;

/*!
    @method authorAtIndex:inherit:
    @abstract Returns the author at index index.
	@param index The index for the author
	@param inherit Boolean, if set follows the Crossref to find inherited authors.
    @discussion zero-based indexing
    
*/
- (BibAuthor *)authorAtIndex:(int)index inherit:(BOOL)inherit;

/*!
    @method bibTeXAuthorString
    @abstract Calls bibTeXAuthorStringNormalized:inherit: with normalized set to NO and inherit set to YES.
    @discussion (discussion)
    
*/
- (NSString *)bibTeXAuthorString;

/*!
    @method bibTeXAuthorStringNormalized:
    @abstract Calls bibTeXAuthorStringNormalized:inherit: with inherit set to YES.
	@param normalized Boolean, if set uses the normalized names of the authors. 
    @discussion (discussion)
    
*/
- (NSString *)bibTeXAuthorStringNormalized:(BOOL)normalized;

/*!
    @method bibTeXAuthorStringNormalized:inherit:
    @abstract Returns the BibTeX string value for the authors. 
	@param normalized Boolean, if set uses the normalized names of the authors. 
	@param inherit Boolean, if set follows the Crossref to find inherited authors.
    @discussion (discussion)
    
*/
- (NSString *)bibTeXAuthorStringNormalized:(BOOL)normalized inherit:(BOOL)inherit;

/*!
    @method setAuthorsFromBibtexString:
    @abstract Sets the authors array by parsing a BibTeX string value for the authors. 
	@param aString The bibTeX string value for the authors. 
    @discussion (discussion)
    
*/
- (void)setAuthorsFromBibtexString:(NSString *)aString;

/*!
    @method crossrefParent
    @abstract Returns the item linked to by the Crossref field, or nil when the Crossref field is not set or the item cannot be found. 
    @discussion (discussion)
    
*/
- (BibItem *)crossrefParent;

/*!
    @method title
    @abstract Returns the title. This can be inherited from the Crossref parent. 
    @discussion (discussion)
    
*/
- (NSString *)title;

/*!
    @method displayTitle
    @abstract Returns the title used for displays and dragged file names. This can be inherited from the Crossref parent. It is never nil or an empty string.
    @discussion (discussion)
    
*/
- (NSString *)displayTitle;

/*!
    @method container
    @abstract Returns the title of the container item, such as the proceedings or journal. 
    @discussion (discussion)
    
*/
- (NSString *)container;

/*!
    @method setDate:
    @abstract Set the date. 
	@param newDate The new date to set.
    @discussion (discussion)
    
*/
- (void)setDate: (NSCalendarDate *)newDate;

/*!
    @method date
    @abstract Calls dateInheriting: with inherit set to YES. 
    @discussion (discussion)
    
*/
- (NSCalendarDate *)date;

/*!
    @method dateInheriting:
    @abstract Returns the date. This was formed from the Year and Month fields. 
	@param inherit Boolean, if set follows the Crossref to find inherited date.
    @discussion (discussion)
    
*/
- (NSCalendarDate *)dateInheriting:(BOOL)inherit;

- (NSCalendarDate *)dateCreated;
- (void)setDateCreated:(NSCalendarDate *)newDateCreated;
- (NSCalendarDate *)dateModified;
- (void)setDateModified:(NSCalendarDate *)newDateModified;

/*!
	@method     setPubType:
	@abstract   Basic setter for the publication type, for initialization. Sets up the fields if necessary.
	@discussion -
*/
- (void)setPubType:(NSString *)newType;
/*!
	@method     setType:
	@abstract   Basic setter for the publication type, calls setType:withModdate: with the current date.
	@discussion -
*/
- (void)setType:(NSString *)newType;
/*!
	@method     setType:withModDate:
	@abstract   Basic setter for the publication type, with undo. Sets up the fields if necessary.
	@discussion -
*/
- (void)setType:(NSString *)newType withModDate:(NSCalendarDate *)date;
/*!
	@method     type
	@abstract   Returns the publication type.
	@discussion -
*/
- (NSString *)type;

/*!
    @method     rating
    @abstract   The value of the rating field as an integer.
    @discussion (comprehensive description)
*/
- (unsigned int)rating;

/*!
    @method     setRating:
    @abstract   Sets the rating field. 
    @discussion (comprehensive description)
    @param      rating The new value for the rating.
*/
- (void)setRating:(unsigned int)rating;

/*!
    @method     read
    @abstract   Boolean value for the Read field. 
    @discussion (comprehensive description)
*/
- (BOOL)read;

/*!
    @method     setRead:
    @abstract   Sets the Read field. 
    @discussion (comprehensive description)
    @param      read The new read flag.
*/
- (void)setRead:(BOOL)read;

/*!
    @method     setRatingField:toValue:
    @abstract   Sets an integer-type field value 0--5
    @discussion (comprehensive description)
    @param      field (description)
    @param      rating (description)
*/
- (void)setRatingField:(NSString *)field toValue:(unsigned int)rating;

/*!
    @method     ratingValueOfField:
    @abstract   Returns the rating value of a field (0--5)
    @discussion (comprehensive description)
    @param      field (description)
    @result     (description)
*/
- (int)ratingValueOfField:(NSString *)field;

/*!
    @method     boolValueOfField:
    @abstract   Returns the boolean value of a string stored in the item's pubFields dictionary
    @discussion (comprehensive description)
    @param      field (description)
    @result     (description)
*/
- (BOOL)boolValueOfField:(NSString *)field;

/*!
    @method     setBooleanField:toValue:
    @abstract   Sets a boolean type field to a string of Yes or No
    @discussion (comprehensive description)
    @param      field (description)
    @param      boolValue (description)
*/
- (void)setBooleanField:(NSString *)field toValue:(BOOL)boolValue;

/*!
    @method     valueOfGenericField:
    @abstract   Calls valueOfGenericField:inherit: with inherit set to NO
    @discussion (comprehensive description)
    @param      field (description)
    @result     (description)
*/
- (NSString *)valueOfGenericField:(NSString *)field;

/*!
    @method     valueOfGenericField:inherit:
    @abstract   Returns the string value of a generic field in the item's pubFields dictionary
    @discussion Returns boolean and rating fields as parsed strings. Note those are never inherited. Also supports Cite Key and Type. 
    @param      field (description)
    @param      inherit (description)
    @result     (description)
*/
- (NSString *)valueOfGenericField:(NSString *)field inherit:(BOOL)inherit;

/*!
    @method     setGenericField:toValue:
    @abstract   Sets generic field to the string value, using proper setting depending on the type of field. 
    @discussion (comprehensive description)
    @param      field (description)
    @param      boolValue (description)
*/
- (void)setGenericField:(NSString *)field toValue:(NSString *)value;

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

- (void)setField: (NSString *)key toValue: (NSString *)value;
- (void)setField: (NSString *)key toValue: (NSString *)value withModDate:(NSCalendarDate *)date;

/*!
    @method valueOfField:
    @abstract Calls valueOfField:inherit: with inherit set to YES. 
	@param key The field name.
    @discussion (discussion)
    
*/
- (NSString *)valueOfField: (NSString *)key;

/*!
    @method valueOfField:inherit:
    @abstract Returns the value of a field. 
	@param key The field name.
	@param inherit Boolean, if set follows the Crossref to find inherited date.
    @discussion (discussion)
    
*/
- (NSString *)valueOfField: (NSString *)key inherit: (BOOL)inherit;

- (NSString *)acronymValueOfField:(NSString *)key ignore:(unsigned int)ignoreLength;

- (void)removeField: (NSString *)key;
- (void)removeField: (NSString *)key withModDate:(NSCalendarDate *)date;

- (void)addField:(NSString *)key;
- (void)addField:(NSString *)key withModDate:(NSCalendarDate *)date;

- (NSMutableDictionary *)pubFields;

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
    @method     bibTeXStringUnexpandedAndDeTeXifiedWithoutInternalFields
    @abstract   Returns a BibTeX value with macros unexpanded, deTeXified (not converted to TeX), without internal fields
                such as Local-Url.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSString *)bibTeXStringUnexpandedAndDeTeXifiedWithoutInternalFields;

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
    @discussion Uses the default font family set in the preferences. It follows the Crossref parent for unset fields. 
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
    @method     URLForField:
    @abstract   Returns a valid URL for the field (either a file URL or internet URL) or nil.
    @discussion Calls remote or local URL methods as appropriate to take care of percent escapes.
    @param      field (description)
    @result     (description)
*/
- (NSURL *)URLForField:(NSString *)field;

/*!
    @method     remoteURL
    @abstract   Calls remoteURLForField: with the Url field.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSURL *)remoteURL;

/*!
    @method     remoteURLForField:
    @abstract   Returns a valid URL or nil for the given field.  Adds percent escapes as necessary, as online databases can return doi (and other?)
                string representations of URLs which are invalid according to the relevant RFC.
    @discussion (comprehensive description)
    @param      field the field name linking the local file.
    @result     (description)
*/
- (NSURL *)remoteURLForField:(NSString *)field;

/*!
    @method     localURLPath
    @abstract   Calls localURLPathInheriting: with inherit set to YES. 
    @discussion -
    @result     a complete path with no tildes, or nil if an error occurred.
*/
- (NSString *)localURLPath; 

/*!
    @method     localURLPathInheriting:
    @abstract   Calls localFilePathForField:relativeTo:inherit: with the Local-Url field and the path to the document.
	@param      inherit Boolean, if set follows the Crossref to find inherited date.
    @discussion -
    @result     a complete path with no tildes, or nil if an error occurred.
*/
- (NSString *)localURLPathInheriting:(BOOL)inherit;

/*!
    @method     localFilePathForField:
    @abstract   Calls localFilePathForField:relativeTo:inherit: with the path to the document and inherit set to YES.
    @discussion -
    @param      field the field name linking the local file.
    @result     a complete path with no tildes, or nil if an error occurred.
*/
- (NSString *)localFilePathForField:(NSString *)field; 

/*!
    @method     localFilePathForField:inherit:
    @abstract   attempts to return a path to the local file linked through the field, relative to the base parameter
    @discussion If the local-url field is a relative path, this will prepend base to it and return the path from building a URL with the result. If the value of local-url is a valid file url already, base is ignored. Base is also ignored if the value of local-url is an absolute path or has a tilde.
    @param      field the field name linking the local file.
    @param      base a path to serve as the base for resolving the relative path.
	@param      inherit Boolean, if set follows the Crossref to find inherited date.
    @result     a complete path with no tildes, or nil if an error occurred.
*/
- (NSString *)localFilePathForField:(NSString *)field relativeTo:(NSString *)base inherit:(BOOL)inherit;

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
- (void)customFieldsDidChange:(NSNotification *)aNotification;

- (void)duplicateTitleToBooktitleOverwriting:(BOOL)overwrite;

- (NSSet *)groupsForField:(NSString *)field;
- (BOOL)isContainedInGroupNamed:(id)group forField:(NSString *)field;
- (int)addToGroup:(BDSKGroup *)group handleInherited:(int)operation;
- (int)removeFromGroup:(BDSKGroup *)group handleInherited:(int)operation;
- (int)replaceGroup:(BDSKGroup *)group withGroupNamed:(NSString *)newGroupName handleInherited:(int)operation;
- (void)invalidateGroupNames;

@end
