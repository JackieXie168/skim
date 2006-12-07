//
//  BibTypeManager.h
//  Bibdesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BibPrefController.h"

@interface BibTypeManager : NSObject {
    NSDictionary *typeInfoDict;
	NSCharacterSet *invalidCiteKeyCharSet;
	NSCharacterSet *invalidLocalUrlCharSet;
	NSCharacterSet *strictInvalidCiteKeyCharSet;
	NSCharacterSet *strictInvalidLocalUrlCharSet;
}
+ (BibTypeManager *)sharedManager;
- (NSString *)defaultTypeForFileFormat:(NSString *)fileFormat;
- (NSArray *)allRemovableFieldNames;
- (NSArray *)requiredFieldsForType:(NSString *)type;
- (NSArray *)optionalFieldsForType:(NSString *)type;
- (NSArray *)userDefaultFieldsForType:(NSString *)type;
- (NSArray *)bibTypesForFileType:(NSString *)fileType;
- (NSString *)fieldNameForPubMedTag:(NSString *)tag;
- (NSString *)bibtexTypeForPubMedType:(NSString *)type;

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

@end
