//
//  BibTypeManager.h
//  BibDesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BibPrefController.h"

// The filename and keys used in the plist
#define TYPE_INFO_FILENAME                  @"TypeInfo.plist"
#define FIELDS_FOR_TYPES_KEY                @"FieldsForTypes"
#define REQUIRED_KEY                        @"required"
#define OPTIONAL_KEY                        @"optional"
#define TYPES_FOR_FILE_TYPE_KEY             @"TypesForFileType"
#define REQUIRED_TYPES_FOR_FILE_TYPE_KEY    @"RequiredTypesForFileType"
#define FILE_TYPES_KEY                      @"FileTypes"
#define BIBTEX_FIELDS_FOR_PUBMED_TAGS_KEY   @"BibTeXFieldNamesForPubMedTags"
#define BIBTEX_TYPES_FOR_PUBMED_TYPES_KEY   @"BibTeXTypesForPubMedTypes"
#define MODS_GENRES_FOR_BIBTEX_TYPES_KEY    @"MODSGenresForBibTeXType"

@interface BibTypeManager : NSObject {
	NSDictionary *fileTypesDict;
	NSDictionary *fieldsForTypesDict;
	NSDictionary *typesForFileTypeDict;
	NSDictionary *fieldNameForPubMedTagDict;
	NSDictionary *bibtexTypeForPubMedTypeDict;
	NSDictionary *MODSGenresForBibTeXTypeDict;
	NSSet *allFieldNames;
	NSCharacterSet *invalidCiteKeyCharSet;
	NSCharacterSet *fragileCiteKeyCharSet;
	NSCharacterSet *invalidLocalUrlCharSet;
	NSCharacterSet *strictInvalidCiteKeyCharSet;
	NSCharacterSet *strictInvalidLocalUrlCharSet;
}
+ (BibTypeManager *)sharedManager;

- (void)reloadTypeInfo;

- (NSString *)defaultTypeForFileFormat:(NSString *)fileFormat;
- (NSSet *)allFieldNames;
- (NSArray *)requiredFieldsForType:(NSString *)type;
- (NSArray *)optionalFieldsForType:(NSString *)type;
- (NSArray *)userDefaultFieldsForType:(NSString *)type;
- (NSArray *)bibTypesForFileType:(NSString *)fileType;
- (NSString *)fieldNameForPubMedTag:(NSString *)tag;
- (NSString *)bibtexTypeForPubMedType:(NSString *)type;

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
    
    /*!
@method     MODSGenreForBibTeXType:
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
    @abstract   Characters that will not be used in a generated key and reference type, currently only for Cite Key in BibTeX.  This is a very strict definition, since it allows
                only ascii alphanumerioc characters and -./:;. Used by the parseFormat:forField: method in BibItem.
    @discussion (comprehensive description)
    @param      fieldName The name of the field (e.g. "Author")
    @param      type The reference type (e.g. BibTeX, RIS)
    @result     A character set of invalid entries.
*/
- (NSCharacterSet *)strictInvalidCharactersForField:(NSString *)fieldName inFileType:(NSString *)type;

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

@end
