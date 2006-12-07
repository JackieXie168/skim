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
    NSDictionary *_typeInfoDict;
	NSCharacterSet *_invalidCiteKeyCharSet;
}
+ (BibTypeManager *)sharedManager;
- (NSString *)defaultTypeForFileFormat:(NSString *)fileFormat;
- (NSArray *)allRemovableFieldNames;
- (NSArray *)requiredFieldsForType:(NSString *)type;
- (NSArray *)optionalFieldsForType:(NSString *)type;
- (NSArray *)userDefaultFieldsForType:(NSString *)type;
- (NSArray *)bibTypesForFileType:(NSString *)fileType;
- (NSString *)fieldNameForPubMedTag:(NSString *)tag;
- (NSCharacterSet *)invalidCharactersForField:(NSString *)fieldName inType:(NSString *)type;
@end
