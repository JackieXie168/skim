// BibItem.h
// Created by Michael McCracken on Tue Dec 18 2001.
/*
 This software is Copyright (c) 2001,2002, Michael O. McCracken
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 -  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 -  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*!
@header BibItem.h
 @discussion This file defines the BibItem model class.
 */

#import <Cocoa/Cocoa.h>

/*!
@typedef BibType
 @abstract Enumerates the various possible types
 @discussion This could be more flexible, but for now an enum is fine. I'm not going to describe each enum, except that NOTYPE is used as a return value to determine when there is no matching type.
 */
typedef enum BibType {
    ARTICLE = 0, BOOK, BOOKLET, INBOOK, INCOLLECTION, INPROCEEDINGS,
    MANUAL, MASTERSTHESIS, MISC, PHDTHESIS, PROCEEDINGS, TECHREPORT,
  UNPUBLISHED, NOTYPE
} BibType;


@class BibEditor;

/*!
@class BibItem
@abstract The model class for individual citations
@discussion This is the data model class that encapsulates each Bibtex entry. BibItems are created for each entry in a file, and a BibDocument keeps collections of BibItems. They are also created in response to drag-in or paste operations containing BibTeX source. Their textvalue method is used to provide the text that is written to a file on saves.

*/
@interface BibItem : NSObject <NSCopying>{ 

    
    NSString *title;     /*! @var title the title of the bibitem. */
    NSString *citeKey;    /*! @var citeKey the citeKey of the bibItem */
    NSCalendarDate *pubDate;
    BibType pubType;
    NSMutableDictionary *pubFields;
    NSMutableArray *pubAuthors;
    NSMutableArray *requiredFieldNames;     /*! @var  this is for 'bibtex required fields'*/
    NSMutableArray *defaultFieldsArray;    /*! @var this, on the other hand, is set by the user for fields they want to always add.*/
    BibEditor *editorObj; /*! @var if we have an editor, don't create a new one. */
    unsigned _fileOrder;
}

/*!
@method init
 @discussion  Calls initWithType:INPROCEEDINGS authors:"" defaultFields: "Keywords", etc...
 */
- (id)init;

    /*!
    @method initWithType:authors:defaultFields:
     @abstract Initializes an alloc'd BibItem to a type and allows to set the authors.
     @discussion This lets you set the type and the Authors array at initialization time. Call it with an empty array for authArray if you don't want to do that -<em>Don't use nil</em> The authors array is kept up but isn't used much right now. This will change.
     @param type A BibType {INPROCEEDINGS, MISC ...} - used to make the BibItem have the right entries in its dictionary.
     @param authArray A NSMutableArray of NSStrings, one for each author.
     @param defaultFieldsArray An NSArray of NSStrings which are to be added no matter what type the bibitem is.
  result The receiver, initialized to type and containing authors authArray.
*/
- (id)initWithType: (BibType)type authors:(NSMutableArray *)authArray defaultFields:(NSMutableArray *)defaultFieldsArray;

/*!
  @method makeType:
    @abstract Change the type of a BibItem.
    @discussion Changes the type of a BibItem, and rearranges the dictionary. Currently it keeps all the fields that have any text in them, so changing from one type to another with all fields filled in will give you the union of their entries.

 @param type the type (as a BibType) that you want to make the receiver.
    
*/
- (void)makeType:(BibType)type;

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
- (BOOL)isRequired:(NSString *)rString;

/*!
@method itemFromString:
    @abstract Convenience Constructor
    @discussion builds and returns a BibItem that corresponds to the text in entry.

 @param entry A bibtex entry
 @result An autoreleased bibItem (or null if the parsing failed.)
    
*/
+ (BibItem *)itemFromString:(NSString *)itemString;

/*!
     @method itemsFromString:
 @abstract Convenience Constructor
 @discussion builds and returns the BibItems that correspond to the text in entry.

 @param entry A string of bibtex entries
 @result An array where each entry is anautoreleased bibItem (or null if the parsing failed.)

 */
+ (NSArray *)itemsFromString:(NSString *)itemString;

/*!
    @method typeFromString
 @abstract typeFromString is a function typeFromString : string -> BibType
 @discussion This is just a convenience function that maps strings into BibTypes.
 @param typeString the string you wish to convert
 @result the BibType corresponding to that string (or NOTYPE if the string is not recognized.)
    
*/
+ (BibType)typeFromString:(NSString *)typeString;

    /*!
    @method typeFromString
     @abstract typeFromString is a function typeFromString : string -> BibType
     @discussion This is just a convenience function that maps BibTypes into strings.
     @param type the bibtype you wish to get a string for
     @result the string corresponding to that bibtype 

     */
+ (NSString *)stringFromType:(BibType)type;

    
- (BibEditor *)editorObj;
- (void)setEditorObj:(BibEditor *)editor;

- (NSString *)description;

// ----------------------------------------------------------------------------------------
// comparisons
// ----------------------------------------------------------------------------------------

- (BOOL)isEqual:(BibItem *)aBI;
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

- (int)numberOfChildren;

- (int)numberOfAuthors;
- (NSArray *)pubAuthors;
- (void)addAuthor:(NSString *)newAuthor;

/*!
    @method authorAtIndex
    @abstract returns the string of the author at index index.
    @discussion zero-based indexing
    
*/
- (NSString *)authorAtIndex:(int)index;

- (NSString *)authorString;
- (void)setAuthorsFromString:(NSString *)aString;

- (NSString *)title;
- (void)setTitle:(NSString *)aTitle;

- (void)setDate: (NSCalendarDate *)newDate;
- (NSCalendarDate *)date;

- (void)setType: (BibType)newType;
- (BibType)type;

- (void)setCiteKeyFormat: (NSString *)newKeyFormat;
- (void)setCiteKey:(NSString *)newCiteKey;
- (NSString *)citeKey;

- (void)setFields: (NSMutableDictionary *)newFields;
- (void)setRequiredFieldNames: (NSMutableArray *)newRequiredFieldNames;
- (void)setField: (NSString *)key toValue: (NSString *)value;
- (NSString *)valueOfField: (NSString *)key;
- (void)removeField: (NSString *)key;
- (NSMutableDictionary *)dict;

/*!
    @method PDFValue
    @abstract Returns the bibtex formatted pdf image with the user-specified style. 
    @discussion «discussion»
    
*/
- (NSData *)PDFValue;

/*!
    @method textValue
 @abstract  returns the bibtex source for this bib item.
    @discussion «discussion»
    
*/
- (NSString *)textValue;

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

/*!
    @method allFieldsString
    @abstract returns the value of each of the fields concatenated into a single string.
    @discussion «discussion»
    
*/
- (NSString *)allFieldsString; 
@end

