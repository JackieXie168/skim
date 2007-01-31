//
//  BibTypeManager.h
//  BibDesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006,2007
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

#import <Foundation/Foundation.h>
#import "BibPrefController.h"

// The filename and keys used in the plist
#define TYPE_INFO_FILENAME                    @"TypeInfo.plist"
#define FIELDS_FOR_TYPES_KEY                  @"FieldsForTypes"
#define REQUIRED_KEY                          @"required"
#define OPTIONAL_KEY                          @"optional"
#define TYPES_FOR_FILE_TYPE_KEY               @"TypesForFileType"
#define REQUIRED_TYPES_FOR_FILE_TYPE_KEY      @"RequiredTypesForFileType"
#define FILE_TYPES_KEY                        @"FileTypes"
#define BIBTEX_FIELDS_FOR_PUBMED_TAGS_KEY     @"BibTeXFieldNamesForPubMedTags"
#define BIBTEX_TYPES_FOR_PUBMED_TYPES_KEY     @"BibTeXTypesForPubMedTypes"
#define BIBTEX_FIELDS_FOR_MARC_TAGS_KEY       @"BibTeXFieldNamesForMARCTags"
#define BIBTEX_FIELDS_FOR_JSTOR_TAGS_KEY      @"BibTeXFieldNamesForJSTORTags"
#define FIELD_DESCRIPTIONS_FOR_JSTOR_TAGS_KEY @"FieldDescriptionsForJSTORTags"
#define BIBTEX_FIELDS_FOR_WOS_TAGS_KEY        @"BibTeXFieldNamesForWebOfScienceTags"
#define FIELD_DESCRIPTIONS_FOR_WOS_TAGS_KEY   @"FieldDescriptionsForWebOfScienceTags"
#define BIBTEX_TYPES_FOR_WOS_TYPES_KEY        @"BibTeXTypesForWebOfScienceTypes"
#define MODS_GENRES_FOR_BIBTEX_TYPES_KEY      @"MODSGenresForBibTeXType"
#define BIBTEX_TYPES_FOR_DC_TYPES_KEY         @"BibTeXTypesForDublinCoreTypes"
#define BIBTEX_FIELDS_FOR_DC_TERMS_KEY        @"BibTeXFieldNamesForDublinCoreTerms"
#define BIBTEX_FIELDS_FOR_REFER_TAGS_KEY     @"BibTeXFieldNamesForReferTags"
#define BIBTEX_TYPES_FOR_REFER_TYPES_KEY     @"BibTeXTypesForReferTypes"
#define BIBTEX_TYPES_FOR_HCITE_TYPES_KEY     @"BibTeXTypesForHCiteTypes"

@class OFCharacterSet;

@interface BibTypeManager : NSObject {
	NSDictionary *fileTypesDict;
	NSDictionary *fieldsForTypesDict;
	NSDictionary *typesForFileTypeDict;
	NSDictionary *fieldNameForPubMedTagDict;
	NSDictionary *bibtexTypeForPubMedTypeDict;
	NSDictionary *fieldNamesForMARCTagDict;
	NSDictionary *fieldNameForJSTORTagDict;
	NSDictionary *fieldDescriptionForJSTORTagDict;
    NSDictionary *fieldNameForWebOfScienceTagDict;
    NSDictionary *fieldDescriptionForWebOfScienceTagDict;
    NSDictionary *bibtexTypeForWebOfScienceTypeDict;
    NSDictionary *bibtexTypeForDublinCoreTypeDict;
    NSDictionary *fieldNameForDublinCoreTermDict;
    NSDictionary *fieldNameForReferTagDict;
    NSDictionary *bibtexTypeForReferTypeDict;
    NSDictionary *bibtexTypeForHCiteTypeDict;
	NSDictionary *MODSGenresForBibTeXTypeDict;
	NSSet *allFieldNames;
	NSCharacterSet *invalidCiteKeyCharSet;
	NSCharacterSet *fragileCiteKeyCharSet;
	NSCharacterSet *strictInvalidCiteKeyCharSet;
	NSCharacterSet *invalidLocalUrlCharSet;
	NSCharacterSet *strictInvalidLocalUrlCharSet;
	NSCharacterSet *veryStrictInvalidLocalUrlCharSet;
	NSCharacterSet *invalidRemoteUrlCharSet;
	NSCharacterSet *strictInvalidRemoteUrlCharSet;
	NSCharacterSet *invalidGeneralCharSet;
	NSCharacterSet *strictInvalidGeneralCharSet;
	NSCharacterSet *separatorCharSet;
	OFCharacterSet *separatorOFCharSet;
    
    NSMutableSet *localFileFieldsSet;
    NSMutableSet *remoteURLFieldsSet;
    NSMutableSet *allURLFieldsSet;
    NSMutableSet *ratingFieldsSet;
    NSMutableSet *triStateFieldsSet;
    NSMutableSet *booleanFieldsSet;
    NSMutableSet *citationFieldsSet;
    NSMutableSet *personFieldsSet;
    NSMutableSet *singleValuedGroupFieldsSet;
    NSMutableSet *invalidGroupFieldsSet;
}
+ (BibTypeManager *)sharedManager;

- (void)reloadTypeInfo;
- (void)reloadAllFieldNames;
- (void)customFieldsDidChange:(NSNotification *)notification;
- (void)reloadURLFields;
- (void)reloadSpecialFields;
- (void)reloadGroupFields;

- (void)setAllFieldNames:(NSSet *)newNames;
- (void)setMODSGenresForBibTeXTypeDict:(NSDictionary *)newNames;
- (void)setBibtexTypeForPubMedTypeDict:(NSDictionary *)newNames;
- (void)setFieldNameForPubMedTagDict:(NSDictionary *)newNames;
- (void)setFieldNamesForMARCTagDict:(NSDictionary *)newNames;
- (void)setFileTypesDict:(NSDictionary *)newTypes;
- (void)setFieldsForTypesDict:(NSDictionary *)newFields;
- (void)setTypesForFileTypeDict:(NSDictionary *)newTypes;
- (void)setFieldNameForJSTORTagDict:(NSDictionary *)dict;
- (void)setFieldDescriptionForJSTORTagDict:(NSDictionary *)dict;
- (void)setFieldNameForWebOfScienceTagDict:(NSDictionary *)dict;
- (void)setFieldDescriptionForWebOfScienceTagDict:(NSDictionary *)dict;
- (void)setBibtexTypeForWebOfScienceTypeDict:(NSDictionary *)dict;
- (void)setBibtexTypeForDublinCoreTypeDict:(NSDictionary *)dict;
- (void)setFieldNameForDublinCoreTermDict:(NSDictionary *)dict;
- (void)setBibtexTypeForReferTypeDict:(NSDictionary *)newNames;
- (void)setFieldNameForReferTagDict:(NSDictionary *)newNames;
- (void)setBibtexTypeForHCiteTypeDict:(NSDictionary *)newBibtexTypeForHCiteTypeDict;


- (NSString *)defaultTypeForFileFormat:(NSString *)fileFormat;
- (NSSet *)allFieldNames;
- (NSArray *)allFieldNamesIncluding:(NSArray *)include excluding:(NSArray *)exclude;
- (NSArray *)requiredFieldsForType:(NSString *)type;
- (NSArray *)optionalFieldsForType:(NSString *)type;
- (NSArray *)userDefaultFieldsForType:(NSString *)type;
- (NSSet *)invalidGroupFieldsSet;
- (NSSet *)singleValuedGroupFieldsSet;
- (NSArray *)bibTypesForFileType:(NSString *)fileType;
- (NSString *)fieldNameForPubMedTag:(NSString *)tag;
- (NSString *)bibtexTypeForPubMedType:(NSString *)type;
- (NSString *)bibtexTypeForWebOfScienceType:(NSString *)type;
- (NSString *)bibtexTypeForReferType:(NSString *)type;

/*!
    @method     bibtexTypeForHCiteType:
    @abstract   translates between common types used in hCite and bibtex types
    @discussion 
    @param      type -- a string representing a type
    @result     a bibtex type
*/
- (NSString *)bibtexTypeForHCiteType:(NSString *)type;


/*!
    @method     fieldNameForDublinCoreTerm:
    @abstract   translates between Dublin Core Terms and bibtex fields.
    @discussion Is probably incomplete, but doesn't ignore qualifiers - DC.Title.Alternate will become Title-Alternate.
    @param      term - a Dublin Core term like "DC.title"
    @result     a string that can be used as a key to a BibItem field like "Title" (note capitalization!)
*/
- (NSString *)fieldNameForDublinCoreTerm:(NSString *)term;

/*!
    @method     bibtexTypeForDublinCoreType:
    @abstract   translates between Dublin Core types and bibtex terms
    @discussion This is likely to be messy since I couldn't find a good reference for DC types.
    @param      type - A DC.Type value
    @result     a bibtex type
*/
- (NSString *)bibtexTypeForDublinCoreType:(NSString *)type;


- (NSSet *)localFileFieldsSet;
- (NSSet *)remoteURLFieldsSet;
- (NSSet *)allURLFieldsSet;
- (NSSet *)noteFieldsSet;
- (NSSet *)personFieldsSet;
- (NSSet *)booleanFieldsSet;
- (NSSet *)triStateFieldsSet;
- (NSSet *)ratingFieldsSet;
- (NSSet *)citationFieldsSet;
- (NSSet *)numericFieldsSet;

/*!
    @method     RISTagForBibTeXFieldName:
    @abstract   Returns an RIS tag for a BibTeX field name.  May not be a recognized tag according to the http://www.refman.com/support/risformat_intro.asp, but
                it should always be a valid RIS tag.
    @discussion (comprehensive description)
    @param      name (description)
    @result     (description)
*/
- (NSString *)RISTagForBibTeXFieldName:(NSString *)name;

/*!
    @method     RISTypeForBibTeXType:
    @abstract   Returns the closest matching RIS type for a given BibTeX type.  If the type does not exist, it is manufactured by uppercasing the first
                four characters of the given type, and padding with ? as necessary.
    @discussion (comprehensive description)
    @param      type (description)
    @result     (description)
*/
- (NSString *)RISTypeForBibTeXType:(NSString *)type;

- (NSDictionary *)fieldNamesForMARCTag:(NSString *)name;

- (NSString *)fieldNameForJSTORTag:(NSString *)tag;

- (NSString *)fieldNameForJSTORDescription:(NSString *)name;

- (NSString *)fieldNameForWebOfScienceTag:(NSString *)tag;

- (NSString *)fieldNameForWebOfScienceDescription:(NSString *)name;
- (NSString *)fieldNameForReferTag:(NSString *)tag;

    /*!
              @method     MODSGenresForBibTeXType:
     @abstract   returns the appropriate MODS genre and level (like "Conference Publication") for known bibtex types (like "inproceedings")
     @discussion 
     @param      type The bibtex type.
     @result     A dictionary that includes genre tags organized by whether they belong in the item or its host. The dictionary has two keys: 'self' and 'host', and when not nil, the values of those keys are arrays. See TypeInfo.plist for the whole story.
     */
- (NSDictionary *)MODSGenresForBibTeXType:(NSString *)type;

/*!
    @method     invalidCharactersForField:inFieldType:
    @abstract   Characters that must not be used in a given key and reference type, currently only for Cite Key in BibTeX.  This is a fairly liberal definition, since it allows
                non-ascii and some math characters.  Used by the formatter subclass for field entry in BibEditor.
    @discussion (comprehensive description)
    @param      fieldName The name of the field (e.g. "Author")
    @param      type The reference type (e.g. BibTeX, RIS)
    @result     A character set of invalid entries.
*/
- (NSCharacterSet *)invalidCharactersForField:(NSString *)fieldName inFileType:(NSString *)type;

/*!
    @method     strictInvalidCharactersForField:inFieldType:
    @abstract   Characters that will not be used in a generated key and reference type, currently only for BibTeX. 
    @discussion (comprehensive description)
    @param      fieldName The name of the field (e.g. "Author")
    @param      type The reference type (e.g. BibTeX, RIS)
    @result     A character set of invalid entries.
*/
- (NSCharacterSet *)strictInvalidCharactersForField:(NSString *)fieldName inFileType:(NSString *)type;

/*!
    @method     veryStrictInvalidCharactersForField:inFieldType:
    @abstract   Characters that will not be used in a generated key and reference type, currently only for BibTeX. 
    @discussion mainly for use of windoze compatible file names
    @param      fieldName The name of the field (e.g. "Author")
    @param      type The reference type (e.g. BibTeX, RIS)
    @result     A character set of invalid entries.
*/
- (NSCharacterSet *)veryStrictInvalidCharactersForField:(NSString *)fieldName inFileType:(NSString *)type;

/*!
    @method     invalidFieldNameCharacterSetForFileType:
    @abstract   Returns invalid characters for field names; currently only for BibTeX.  Same character set as for citekeys.
    @discussion (comprehensive description)
    @param      type (description)
    @result     (description)
*/
- (NSCharacterSet *)invalidFieldNameCharacterSetForFileType:(NSString *)type;

/*!
    @method     fragileCiteKeyCharacterSet
    @abstract   Returns characters that could give problems in LaTeX for use in cite keys.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSCharacterSet *)fragileCiteKeyCharacterSet;

- (NSCharacterSet *)separatorCharacterSetForField:(NSString *)fieldName;
- (OFCharacterSet *)separatorOFCharacterSetForField:(NSString *)fieldName;

@end

@interface NSString (BDSKTypeExtensions)

- (BOOL)isBooleanField;
- (BOOL)isTriStateField;
- (BOOL)isRatingField;
- (BOOL)isLocalFileField;
- (BOOL)isRemoteURLField;
- (BOOL)isPersonField;
- (BOOL)isURLField;
- (BOOL)isCitationField;
- (BOOL)isNoteField;
- (BOOL)isNumericField;
- (BOOL)isSingleValuedField;
- (BOOL)isInvalidGroupField;

@end
