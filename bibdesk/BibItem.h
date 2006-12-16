// BibItem.h
// Created by Michael McCracken on Tue Dec 18 2001.
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005,2006
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
#import "BDSKFormatParser.h"

enum {
    BDSKNoCrossrefError,
    BDSKSelfCrossrefError,
    BDSKChainCrossrefError,
    BDSKIsCrossreffedCrossrefError
};

@class BibDocument, BDSKGroup, BibAuthor, BDSKFieldCollection, BDSKTemplate, BDSKPublicationsArray, BDSKMacroResolver;
@protocol BDSKParseableItem, BDSKOwner;

/*!
@class BibItem
@abstract The model class for individual citations
@discussion This is the data model class that encapsulates each Bibtex entry. BibItems are created for each entry in a file, and a BibDocument keeps collections of BibItems. They are also created in response to drag-in or paste operations containing BibTeX source. Their textvalue method is used to provide the text that is written to a file on saves.

*/
@interface BibItem : OFObject <NSCopying, NSCoding, BDSKParseableItem>{
    NSString *fileType;
    NSString *citeKey;
	NSString *pubType;
    NSMutableDictionary *pubFields;
    NSMutableDictionary *people;
    NSCalendarDate *pubDate;
	NSCalendarDate *dateAdded;
	NSCalendarDate *dateModified;
	NSMutableDictionary *groups;
    NSNumber * fileOrder;
    BOOL hasBeenEdited;
	BOOL needsToBeFiled;
	id<BDSKOwner> owner;
    BDSKFieldCollection *templateFields;
    int currentIndex;
    BOOL spotlightMetadataChanged;
    NSMutableDictionary *cachedURLs;
}

/*!
     @method init
     @abstract Initializes an alloc'd BibItem to a default type, empty authors array and createdDate the current date. 
     @discussion This initializer should be used for a newly added BibItem only, as it sets the created date. It calls the designated initializer. 
     @result The receiver, initialized to the default type, containing an an empty pubFields fieldsDict, empty authors authArray, and with date created and modified set to the current date.
*/
- (id)init;

/*!
     @method initWithType:fileType:citeKey:pubFields:createdDate:
     @abstract Initializes an alloc'd BibItem to a type and allows to set the authors. This is the designated intializer.
     @discussion This lets you set the type and the Authors array at initialization time. Call it with an empty array for authArray if you don't want to do that -<em>Don't use nil</em> The authors array is kept up but isn't used much right now. This will change. The createdDate should be nil when the BibItem is not newly added, such as in a parser. 
     @param fileType A string representing which kind of file this item was read from.
     @param key The cite key. Pass nil to generate the cite key.
     @param type A string representing the type of entry this item is - used to make the BibItem have the right entries in its dictionary.
     @param fieldsDict The dictionary of fields to initialize the item with.
     @param isNew Boolean determines if the item is new for the BibTeX document. Determines if the date-added should be set. Should be YES unless when reading the BibTeX source file.
     @result The receiver, initialized to type and containing authors authArray.
*/
- (id)initWithType:(NSString *)type fileType:(NSString *)inFileType citeKey:(NSString *)key pubFields:(NSDictionary *)fieldsDict isNew:(BOOL)isNew;

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

- (id<BDSKOwner>)owner;
- (void)setOwner:(id<BDSKOwner>)newOwner;

- (NSUndoManager *)undoManager;

- (NSString *)description;

// ----------------------------------------------------------------------------------------
// comparisons
// ----------------------------------------------------------------------------------------

- (BOOL)isEqual:(BibItem *)aBI;
- (BOOL)isEqualToItem:(BibItem *)aBI;
- (BOOL)isIdenticalToItem:(BibItem *)aBI;

// accessors for fileorder
- (NSNumber *)fileOrder;
- (void)setFileOrder:(NSNumber *)newOrder;

- (NSString *)fileType;
- (void)setFileType:(NSString *)someFileType;


/* Methods for handling people objects (BibAuthors) which may be any people type (Author, Editor, etc.)
*/
- (void)rebuildPeopleIfNeeded;
- (NSSet *)allPeople;
- (int)numberOfPeople;
- (NSArray *)sortedPeople;
- (NSArray *)peopleArrayForField:(NSString *)field;
- (NSArray *)peopleArrayForField:(NSString *)field inherit:(BOOL)inherit;    
- (NSDictionary *)people;
- (NSDictionary *)peopleInheriting:(BOOL)inherit;

/*!
    @method     peopleStringForDisplayFromField:
    @abstract   Returns a string of names according to the user's display prefs (using -[BibAuthor displayName]).
    @discussion (comprehensive description)
    @param      field (description)
    @result     (description)
*/
- (NSString *)peopleStringForDisplayFromField:(NSString *)field;

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
    @method     pubAuthorsForDisplay
    @abstract   Returns authors in a string form, according to the user's display preferences.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSString *)pubAuthorsForDisplay;

/*!
    @method authorAtIndex:
    @abstract Calls authorAtIndex:inherit: with inherit set to YES. 
	@param index The index for the author
    @discussion zero-based indexing
    
*/
- (BibAuthor *)authorAtIndex:(unsigned int)index;

/*!
    @method authorAtIndex:inherit:
    @abstract Returns the author at index index.
	@param index The index for the author
	@param inherit Boolean, if set follows the Crossref to find inherited authors.
    @discussion zero-based indexing
    
*/
- (BibAuthor *)authorAtIndex:(unsigned int)index inherit:(BOOL)inherit;

- (BibAuthor *)firstAuthor;
- (BibAuthor *)secondAuthor;
- (BibAuthor *)thirdAuthor;
- (BibAuthor *)lastAuthor;

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
    @method     bibTeXNameStringForField:normalized:inherit:
    @abstract   Returns a string of BibTeX names, possibly normalized and inherited, for the given field.
    @discussion (comprehensive description)
    @param      field (description)
    @param      normalized (description)
    @param      inherit (description)
    @result     (description)
*/
- (NSString *)bibTeXNameStringForField:(NSString *)field normalized:(BOOL)normalized inherit:(BOOL)inherit;

/*!
    @method numberOfAuthorsOrEditors
    @abstract Calls numberOfAuthorsOrEditorsInheriting: with inherit set to YES. 
    @discussion (discussion)
    
*/
- (int)numberOfAuthorsOrEditors;

/*!
    @method numberOfAuthorsOrEditorsInheriting:
    @abstract Returns the number of authors or editors.
	@param inherit Boolean, if set follows the Crossref to find inherited authors.
    @discussion (discussion)
    
*/
- (int)numberOfAuthorsOrEditorsInheriting:(BOOL)inherit;

/*!
    @method pubAuthorsOrEditors
    @abstract Calls pubAuthorsOrEditorsInheriting: with inherit set to YES. 
    @discussion (discussion)
    
*/
- (NSArray *)pubAuthorsOrEditors;

/*!
    @method pubAuthorsOrEditorsInheriting:
    @abstract Returns the authors or editors array of the publication.
	@param inherit Boolean, if set follows the Crossref to find inherited authors.
    @discussion (discussion)
    
*/
- (NSArray *)pubAuthorsOrEditorsInheriting:(BOOL)inherit;

/*!
    @method     lastAuthorOrEditor
    @abstract   Returns last object of pubAuthorsOrEditors.
    @discussion (comprehensive description)
    @result     (description)
*/
- (BibAuthor *)lastAuthorOrEditor;

/*!
    @method     pubAuthorsOreditorsForDisplay
    @abstract   Returns authors or editors in a string form, according to the user's display preferences.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSString *)pubAuthorsOrEditorsForDisplay;

/*!
    @method authorOrEditorAtIndex:
    @abstract Calls authorOrEditorAtIndex:inherit: with inherit set to YES. 
	@param index The index for the author
    @discussion zero-based indexing
    
*/
- (BibAuthor *)authorOrEditorAtIndex:(unsigned int)index;

/*!
    @method authorOrEditorAtIndex:inherit:
    @abstract Returns the author or editor at index index.
	@param index The index for the author
	@param inherit Boolean, if set follows the Crossref to find inherited authors.
    @discussion zero-based indexing
    
*/
- (BibAuthor *)authorOrEditorAtIndex:(unsigned int)index inherit:(BOOL)inherit;

- (BibAuthor *)firstAuthorOrEditor;
- (BibAuthor *)secondAuthorOrEditor;
- (BibAuthor *)thirdAuthorOrEditor;
- (BibAuthor *)lastAuthorOrEditor;

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

- (NSCalendarDate *)dateAdded;
- (NSCalendarDate *)dateModified;

/*!
	@method     setPubType:
	@abstract   Basic setter for the publication type, calls setType:withModdate: with the current date.
	@discussion -
*/
- (void)setPubType:(NSString *)newType;
/*!
	@method     setPubType:withModDate:
	@abstract   Basic setter for the publication type, with undo. Sets up the fields if necessary.
	@discussion -
*/
- (void)setPubType:(NSString *)newType withModDate:(NSCalendarDate *)date;
/*!
	@method     pubType
	@abstract   Returns the publication type.
	@discussion -
*/
- (NSString *)pubType;

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
    @method     setField:toRatingValue:
    @abstract   Sets an integer-type field value 0--5
    @discussion (comprehensive description)
    @param      field (description)
    @param      rating (description)
*/
- (void)setField:(NSString *)field toRatingValue:(unsigned int)rating;

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
    @method     setField:toBoolValue:
    @abstract   Sets a boolean type field to a string of Yes or No
    @discussion (comprehensive description)
    @param      field (description)
    @param      boolValue (description)
*/
- (void)setField:(NSString *)field toBoolValue:(BOOL)boolValue;


/*!
    @method     triStateValueOfField:
    @abstract   Returns the value of a string stored in the item's pubFields dictionary as an NSCellStateValue
    @discussion (comprehensive description)
    @param      field (description)
    @result     (description)
*/
- (NSCellStateValue)triStateValueOfField:(NSString *)field;

/*!
    @method     setField:toTriStateValue:
    @abstract   Sets a checkbox (aka boolean) type field to a string of Yes or No or "-" for mixed. (or a localized variant)
    @discussion (comprehensive description)
    @param      field (description)
    @param      triStateValue - one of NS{On,Off,Mixed}State
*/

- (void)setField:(NSString *)field toTriStateValue:(NSCellStateValue)triStateValue;
    
/*!
    @method     intValueOfField:
    @abstract   Returns the value of a string stored in the item's pubFields dictionary as an int. Only for boolean, rating or tri-state fields.
    @discussion (comprehensive description)
    @param      field (description)
    @result     (description)
*/
- (int)intValueOfField:(NSString *)field;

/*!
    @method     stringValueOfField:
    @abstract   Calls stringValueOfField:inherit: with inherit set to NO
    @discussion (comprehensive description)
    @param      field (description)
    @result     (description)
*/
- (NSString *)stringValueOfField:(NSString *)field;

/*!
    @method     stringValueOfField:inherit:
    @abstract   Returns the proper string value of a field in the item's pubFields dictionary
    @discussion Returns boolean and rating fields as parsed strings. Note those are never inherited. Also supports Cite Key and Type. 
    @param      field (description)
    @param      inherit (description)
    @result     (description)
*/
- (NSString *)stringValueOfField:(NSString *)field inherit:(BOOL)inherit;

/*!
    @method     setField:toStringValue:
    @abstract   Sets field to the string value, using proper setting depending on the type of field. 
    @discussion (comprehensive description)
    @param      field (description)
    @param      boolValue (description)
*/
- (void)setField:(NSString *)field toStringValue:(NSString *)value;

- (id)displayValueOfField:(NSString *)field;

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

- (BOOL)isValidCiteKey:(NSString *)proposedCiteKey;
- (BOOL)hasEmptyOrDefaultCiteKey;

/*
    @method canGenerateAndSetCiteKey
    @abstract Returns a boolean indicating whether all fields required for the generated cite key are set and whether the item needs a cite key (checks hasEmptyOrDefaultCiteKey).
    @discussion - 
*/
- (BOOL)canGenerateAndSetCiteKey;

/*
    @method canSetCrossref:andCiteKey:
    @abstract Returns an integer error code indicating whether the combination of crossref and citekey would lead to a crossref chain
    @discussion -
    @result 0: no problem, 1: crossref to self, 2: crossref to item with crossref, 3: self is crossreffed
*/
- (int)canSetCrossref:(NSString *)aCrossref andCiteKey:(NSString *)aCiteKey;

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

- (void)setField: (NSString *)key toValue: (NSString *)value;
- (void)setField: (NSString *)key toValue: (NSString *)value withModDate:(NSCalendarDate *)date;

/*!
    @method     setField:toValueWithoutUndo:
    @abstract   Bypasses the undo and change notification mechanisms.  Only for use by BibEditor.
    @discussion (comprehensive description)
    @param      key (description)
    @param      value (description)
*/
- (void)setField:(NSString *)key toValueWithoutUndo:(NSString *)value;

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

- (void)removeField: (NSString *)key;
- (void)removeField: (NSString *)key withModDate:(NSCalendarDate *)date;

- (void)addField:(NSString *)key;
- (void)addField:(NSString *)key withModDate:(NSCalendarDate *)date;

- (NSDictionary *)pubFields;
- (NSArray *)allFieldNames;

/*!
    @method     matchesSubstring:withOptions:inField:removeDiacritics:
    @abstract   Used for searching methods; handles various field types.
    @discussion (comprehensive description)
    @param      substring The string to search for, which may be a string representation of a boolean or date
    @param      searchOptions NSString search option (e.g. NSCaseInsensitiveSearch)
    @param      field The BibItem field
    @param      flag Whether a lossy search is to be performed (by removing diacritic marks)
    @result     (description)
*/
- (BOOL)matchesSubstring:(NSString *)substring withOptions:(unsigned)searchOptions inField:(NSString *)field removeDiacritics:(BOOL)flag;

- (NSDictionary *)searchIndexInfo;
- (NSDictionary *)metadataCacheInfoForUpdate:(BOOL)update;
- (id)completionObject;

/*!
    @method bibTeXStringReturningError:(NSError *)error
    @abstract  returns the bibtex source for this bib item.  Is TeXified based on default preferences for the application.
    @param      error Set to an error when a texification error occurs, can be NULL.
    @discussion «discussion»
    
*/
- (NSString *)bibTeXStringReturningError:(NSError **)error;

/*!
    @method     bibTeXStringDroppingInternal:error:
    @abstract   Returns the BibTeX value of this bib item.  It is TeXified based on default prefs for the application.
    @param      drop Boolean determines whether internal fields are dropped. 
    @param      error Set to an error when a texification error occurs, can be NULL.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSString *)bibTeXStringDroppingInternal:(BOOL)drop error:(NSError **)error;

/*!
    @method     bibTeXStringByExpandingMacros:dropInternal:texify:error:
    @abstract   Returns a BibTeX value with optionally macros expanded, optionally without internal fields, optionally teXified (converted to TeX)
    @discussion (comprehensive description)
    @param      expand Boolean determines whether macros are expanded.
    @param      drop Boolean determines whether internal fields are dropped. 
    @param      shouldTeXify Boolean determines whether accented characters are converted to TeX.
    @param      error Set to an error when a texification error occurs, can be NULL.
    @result     (description)
*/
- (NSString *)bibTeXStringByExpandingMacros:(BOOL)expand dropInternal:(BOOL)drop texify:(BOOL)shouldTeXify error:(NSError **)error;

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

- (NSString *)MODSString;
- (NSString *)endNoteString;


/*!
    @method RSSValue
    @abstract returns an rss XML entry suitable for embedding in an rss file.
    @discussion «discussion»
    
*/
- (NSString *)RSSValue;

/*!
    @method allFieldsString
    @abstract returns the value of each of the fields concatenated into a single string.
    @discussion «discussion»
    
*/
- (NSString *)allFieldsString; 

- (NSString *)stringValueUsingTemplate:(BDSKTemplate *)template;
- (NSAttributedString *)attributedStringValueUsingTemplate:(BDSKTemplate *)template;

- (void)prepareForTemplateParsing;
- (void)cleanupAfterTemplateParsing;
- (id)requiredFields;
- (id)optionalFields;
- (id)defaultFields;
- (id)allFields;
- (BDSKFieldCollection *)fields;
- (BDSKFieldCollection *)urls;
- (BDSKFieldCollection *)persons;
- (id)authors;
- (id)editors;
- (int)itemIndex;
- (void)setItemIndex:(int)index;

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
    @method     localUrlURL
    @abstract   Calls localFileURLForField: with the Local-Url field.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSURL *)localURL;

/*!
    @method     localUrlPath
    @abstract   Calls localUrlPathInheriting: with inherit set to YES. 
    @discussion -
    @result     a complete path with no tildes, or nil if an error occurred.
*/
- (NSString *)localUrlPath; 

/*!
    @method     localUrlPathInheriting:
    @abstract   Calls localFilePathForField:relativeTo:inherit: with the Local-Url field and the path to the document.
	@param      inherit Boolean, if set follows the Crossref to find inherited date.
    @discussion -
    @result     a complete path with no tildes, or nil if an error occurred.
*/
- (NSString *)localUrlPathInheriting:(BOOL)inherit;

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
	@param      inherit Boolean, if set follows the Crossref to find inherited date.
    @result     a complete path with no tildes, or nil if an error occurred.
*/
- (NSString *)localFilePathForField:(NSString *)field inherit:(BOOL)inherit;

/*!
    @method     smallImageForURLField:
    @abstract   Returns a 16x16 image for a URL field (local or remote)
    @discussion (comprehensive description)
    @param      field (description)
    @result     (description)
*/
- (NSImage *)smallImageForURLField:(NSString *)field;

/*!
    @method     imageForURLField:
    @abstract   Returns an icon representation of a URL field.
    @discussion (comprehensive description)
    @param      field Needs to be a local or remote URL field.
    @result     Returns nil if the item has an empty field, and returns a question mark image if a file could not be found.
*/
- (NSImage *)imageForURLField:(NSString *)field;

// NSURL equivalents of the localFilePath... methods
- (NSURL *)localFileURLForField:(NSString *)field;
- (NSURL *)localFileURLForField:(NSString *)field inherit:(BOOL)inherit;

/*!
    @method suggestedLocalUrl
    @abstract Returns a suggested local-url based on the receiver
    @discussion Returns a suggested local-url based on the local-url format and the receivers publication  data. 
    @result The suggested full path for the local file
*/
- (NSString *)suggestedLocalUrl;

- (BOOL)isValidLocalUrlPath:(NSString *)proposedPath;

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
- (BOOL)autoFilePaper;

- (NSString *)documentFileName;
- (NSString *)documentInfoForKey:(NSString *)key;

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

@class PDFMetadata;

@interface BibItem (PDFMetadata)
+ (BibItem *)itemWithPDFMetadata:(PDFMetadata *)metadata;
- (PDFMetadata *)PDFMetadata;
- (void)addPDFMetadataToFileForLocalURLField:(NSString *)field;
@end

extern const CFSetCallBacks BDSKBibItemEqualityCallBacks;
