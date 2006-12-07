//
//  BibTypeManager.m
//  Bibdesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "BibTypeManager.h"
#import "BibAppController.h"

static BibTypeManager *sharedInstance = nil;

@implementation BibTypeManager
+ (BibTypeManager *)sharedManager{
    if(!sharedInstance) sharedInstance = [[BibTypeManager alloc] init];
    return sharedInstance;
}

- (id)init{
    self = [super init];
    NSDictionary *typeInfoDict = [[NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TypeInfo.plist"]] retain];

	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *applicationSupportPath = [[fm applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"];
	NSString *userTypeInfoPath = [applicationSupportPath stringByAppendingPathComponent:@"TypeInfo.plist"];
	NSDictionary *userTypeInfoDict;
	
	if ([fm fileExistsAtPath:userTypeInfoPath]) {
		userTypeInfoDict = [NSDictionary dictionaryWithContentsOfFile:userTypeInfoPath];
		
		// set all the lists we support in the user file
		fieldsForTypesDict = [[userTypeInfoDict objectForKey:@"FieldsForTypes"] retain];
		typesForFileTypeDict = [[NSDictionary dictionaryWithObjectsAndKeys: 
				[[userTypeInfoDict objectForKey:@"TypesForFileType"] objectForKey:BDSKBibtexString], BDSKBibtexString, 
				[[typeInfoDict objectForKey:@"TypesForFileType"] objectForKey:@"PubMed"], @"PubMed", nil] retain];
		allFieldNames = [[userTypeInfoDict objectForKey:@"AllRemovableFieldNames"] retain];
	}
	
	if (fieldsForTypesDict == nil)
		fieldsForTypesDict = [[typeInfoDict objectForKey:@"FieldsForTypes"] retain];
	if (typesForFileTypeDict == nil)
		typesForFileTypeDict = [[typeInfoDict objectForKey:@"TypesForFileType"] retain];
	if (allFieldNames == nil)
		allFieldNames = [[typeInfoDict objectForKey:@"AllRemovableFieldNames"] retain];
	fileTypesDict = [[typeInfoDict objectForKey:@"FileTypes"] retain];
	fieldNameForPubMedTagDict = [[typeInfoDict objectForKey:@"BibTeXFieldNamesForPubMedTags"] retain];
	bibtexTypeForPubMedTypeDict = [[typeInfoDict objectForKey:@"BibTeXTypesForPubMedTypes"] retain];
	MODSGenresForBibTeXTypeDict = [[typeInfoDict objectForKey:@"MODSGenresForBibTeXType"] retain];

    // this set is used for warning the user on manual entry of a citekey; allows non-ASCII characters and some math symbols
    invalidCiteKeyCharSet = [[NSCharacterSet characterSetWithCharactersInString:@" '\"@,\\#}{~&%$^"] retain];
    
    NSMutableCharacterSet *validSet = [[NSCharacterSet characterSetWithRange:NSMakeRange( (unsigned int)'a', 26)] mutableCopy];
    [validSet addCharactersInRange:NSMakeRange( (unsigned int)'A', 26)];
    [validSet addCharactersInRange:NSMakeRange( (unsigned int)'-', 15)];  //  -./0123456789:;
    
    // this is used for generated cite keys, very strict!
	strictInvalidCiteKeyCharSet = [[validSet invertedSet] copy];  // don't release this
    
	// this set is used for warning the user on manual entry of a local-url; allows non-ASCII characters and some math symbols
    invalidLocalUrlCharSet = [[NSCharacterSet characterSetWithCharactersInString:@":"] retain];
    
	// this is used for generated local urls
	strictInvalidLocalUrlCharSet = [invalidLocalUrlCharSet copy];  // don't release this
        
        [validSet release];
	
    return self;
}

- (void)dealloc{
	[fileTypesDict release];
	[fieldsForTypesDict release];
	[typesForFileTypeDict release];
	[fieldNameForPubMedTagDict release];
	[bibtexTypeForPubMedTypeDict release];
	[MODSGenresForBibTeXTypeDict release];
	[allFieldNames release];
	[invalidCiteKeyCharSet release];
	[strictInvalidCiteKeyCharSet release];
	[invalidLocalUrlCharSet release];
	[strictInvalidLocalUrlCharSet release];
	[super dealloc];
}

#pragma mark Getters and Setters

- (void)setAllFieldNames:(NSArray *)newArray{
	[allFieldNames autorelease];
	allFieldNames = [newArray copy];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"allFieldNames", @"list",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibTypeInfoChangedNotification
														object:self
													  userInfo:notifInfo];
}

- (void)setFieldsForTypeDict:(NSDictionary *)newDict{
	[fieldsForTypesDict autorelease];
	fieldsForTypesDict = [newDict copy];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"fieldsForTypes", @"list",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibTypeInfoChangedNotification
														object:self
													  userInfo:notifInfo];
}

- (void)setBibTypesForFileTypeDict:(NSDictionary *)newDict{
	[typesForFileTypeDict release];
	typesForFileTypeDict = [newDict copy];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"typesForFileTypes", @"list",nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibTypeInfoChangedNotification
														object:self
													  userInfo:notifInfo];
}

- (NSString *)defaultTypeForFileFormat:(NSString *)fileFormat{
     return [[fileTypesDict objectForKey:fileFormat] objectForKey:@"DefaultType"];
}

- (NSArray *)allRemovableFieldNames{
    if (allFieldNames == nil) [NSException raise:@"nilNames exception" format:@"allRemovableFieldNames returning nil."];
    return allFieldNames;
}

- (NSArray *)requiredFieldsForType:(NSString *)type{
    if(fieldsForTypesDict){
        return [[fieldsForTypesDict objectForKey:type] objectForKey:@"required"];
    }else{
        return [NSArray array];
    }
}

- (NSArray *)optionalFieldsForType:(NSString *)type{
    if(fieldsForTypesDict){
        return [[fieldsForTypesDict objectForKey:type] objectForKey:@"optional"];
    }else{
        return [NSArray array];
    }
}

- (NSArray *)userDefaultFieldsForType:(NSString *)type{
    return [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKDefaultFieldsKey];
}

- (NSArray *)bibTypesForFileType:(NSString *)fileType{
    return [typesForFileTypeDict objectForKey:fileType];
}

- (NSString *)fieldNameForPubMedTag:(NSString *)tag{
    return [fieldNameForPubMedTagDict objectForKey:tag];
}

- (NSString *)bibtexTypeForPubMedType:(NSString *)type{
    return [bibtexTypeForPubMedTypeDict objectForKey:type];
}

- (NSDictionary *)MODSGenresForBibTeXType:(NSString *)type{
    return [MODSGenresForBibTeXTypeDict objectForKey:type];
}

#pragma mark Character sets

- (NSCharacterSet *)invalidCharactersForField:(NSString *)fieldName inFileType:(NSString *)type{
	if( [type isEqualToString:BDSKBibtexString] && [fieldName isEqualToString:BDSKCiteKeyString]){
		return invalidCiteKeyCharSet;
	}
	if([fieldName isEqualToString:BDSKLocalUrlString]){
		return invalidLocalUrlCharSet;
	}
	[NSException raise:@"unimpl. feat. exc." format:@"invalidCharactersForField is partly implemented"];
}

- (NSCharacterSet *)strictInvalidCharactersForField:(NSString *)fieldName inFileType:(NSString *)type{
	if( [type isEqualToString:BDSKBibtexString] && [fieldName isEqualToString:BDSKCiteKeyString]){
		return strictInvalidCiteKeyCharSet;
	}
	if([fieldName isEqualToString:BDSKLocalUrlString]){
		return strictInvalidLocalUrlCharSet;
	}
	[NSException raise:@"unimpl. feat. exc." format:@"strictInvalidCharactersForField is partly implemented"];
}

- (NSCharacterSet *)invalidFieldNameCharacterSetForFileType:(NSString *)type{
    if([type isEqualToString:BDSKBibtexString])
        return invalidCiteKeyCharSet;
    else
        [NSException raise:@"unimpl. feat. exc." format:@"invalidFieldNameCharacterSetForFileType is only implemented for BibTeX"];
}

@end
