//
//  BibTypeManager.m
//  BibDesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005
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
    
    if(!self)
        return nil;
	
	[self reloadTypeInfo];
	
    // this set is used for warning the user on manual entry of a citekey; allows non-ASCII characters and some math symbols
    invalidCiteKeyCharSet = [[NSCharacterSet characterSetWithCharactersInString:@" '\"@,\\#}{~%"] retain];
    
	fragileCiteKeyCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"&$^"] retain];
    
    NSMutableCharacterSet *validSet = [[NSCharacterSet characterSetWithRange:NSMakeRange( (unsigned int)'a', 26)] mutableCopy];
    [validSet addCharactersInRange:NSMakeRange( (unsigned int)'A', 26)];
    [validSet addCharactersInRange:NSMakeRange( (unsigned int)'-', 15)];  //  -./0123456789:;
    
    // this is used for generated cite keys, very strict!
	strictInvalidCiteKeyCharSet = [[validSet invertedSet] copy];  // don't release this
    [validSet release];

	// this set is used for warning the user on manual entry of a local-url; allows non-ASCII characters and some math symbols
    invalidLocalUrlCharSet = [[NSCharacterSet characterSetWithCharactersInString:@":"] retain];
    
	// this is used for generated local urls
	strictInvalidLocalUrlCharSet = [invalidLocalUrlCharSet copy];  // don't release this
        	
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

- (void)reloadTypeInfo{
	
	// Load the TypeInfo plists
	NSDictionary *typeInfoDict = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:TYPE_INFO_FILENAME]];

	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *userTypeInfoPath = [[fm currentApplicationSupportPathForCurrentUser] stringByAppendingPathComponent:TYPE_INFO_FILENAME];
	NSDictionary *userTypeInfoDict;
	
	if ([fm fileExistsAtPath:userTypeInfoPath]) {
		userTypeInfoDict = [NSDictionary dictionaryWithContentsOfFile:userTypeInfoPath];
		// set all the lists we support in the user file
        [self setFieldsForTypesDict:[userTypeInfoDict objectForKey:FIELDS_FOR_TYPES_KEY]];
        [self setTypesForFileTypeDict:[NSDictionary dictionaryWithObjectsAndKeys: 
            [[userTypeInfoDict objectForKey:TYPES_FOR_FILE_TYPE_KEY] objectForKey:BDSKBibtexString], BDSKBibtexString, 
            [[typeInfoDict objectForKey:TYPES_FOR_FILE_TYPE_KEY] objectForKey:@"PubMed"], @"PubMed", nil]];
	} else {
        [self setFieldsForTypesDict:[typeInfoDict objectForKey:FIELDS_FOR_TYPES_KEY]];
        [self setTypesForFileTypeDict:[typeInfoDict objectForKey:TYPES_FOR_FILE_TYPE_KEY]];
    }

    [self setFileTypesDict:[typeInfoDict objectForKey:FILE_TYPES_KEY]];
    [self setFieldNameForPubMedTagDict:[typeInfoDict objectForKey:BIBTEX_FIELDS_FOR_PUBMED_TAGS_KEY]];
    [self setBibtexTypeForPubMedTypeDict:[typeInfoDict objectForKey:BIBTEX_TYPES_FOR_PUBMED_TYPES_KEY]];
    [self setMODSGenresForBibTeXTypeDict:[typeInfoDict objectForKey:MODS_GENRES_FOR_BIBTEX_TYPES_KEY]];

	NSMutableSet *allFields = [NSMutableSet setWithCapacity:30];
	NSEnumerator *typeEnum = [[[typeInfoDict objectForKey:TYPES_FOR_FILE_TYPE_KEY] objectForKey:BDSKBibtexString] objectEnumerator];
	NSString *type;
	
	while (type = [typeEnum nextObject]) {
		[allFields addObjectsFromArray:[[fieldsForTypesDict objectForKey:type] objectForKey:REQUIRED_KEY]];
		[allFields addObjectsFromArray:[[fieldsForTypesDict objectForKey:type] objectForKey:OPTIONAL_KEY]];
	}
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
	[allFields addObjectsFromArray:[pw stringArrayForKey:BDSKDefaultFieldsKey]];
    [self setAllFieldNames:allFields];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibTypeInfoChangedNotification
														object:self
													  userInfo:[NSDictionary dictionary]];
}

#pragma mark Setters

- (void)setAllFieldNames:(NSSet *)newNames{
    if(allFieldNames != newNames){
        [allFieldNames release];
        allFieldNames = [newNames copy];
    }
}

- (void)setMODSGenresForBibTeXTypeDict:(NSDictionary *)newNames{
    if(MODSGenresForBibTeXTypeDict != newNames){
        [MODSGenresForBibTeXTypeDict release];
        MODSGenresForBibTeXTypeDict = [newNames copy];
    }
}

- (void)setBibtexTypeForPubMedTypeDict:(NSDictionary *)newNames{
    if(bibtexTypeForPubMedTypeDict != newNames){
        [bibtexTypeForPubMedTypeDict release];
        bibtexTypeForPubMedTypeDict = [newNames copy];
    }
}

- (void)setFieldNameForPubMedTagDict:(NSDictionary *)newNames{
    if(fieldNameForPubMedTagDict != newNames){
        [fieldNameForPubMedTagDict release];
        fieldNameForPubMedTagDict = [newNames copy];
    }
}

- (void)setFileTypesDict:(NSDictionary *)newTypes{
    if(fileTypesDict != newTypes){
        [fileTypesDict release];
        fileTypesDict = [newTypes copy];
    }
}

- (void)setFieldsForTypesDict:(NSDictionary *)newFields{
    if(fieldsForTypesDict != newFields){
        [fieldsForTypesDict release];
        fieldsForTypesDict = [newFields copy];
    }
}

- (void)setTypesForFileTypeDict:(NSDictionary *)newTypes{
    if(typesForFileTypeDict != newTypes){
        [typesForFileTypeDict release];
        typesForFileTypeDict = [newTypes copy];
    }
}

#pragma mark Getters

- (NSString *)defaultTypeForFileFormat:(NSString *)fileFormat{
     return [[fileTypesDict objectForKey:fileFormat] objectForKey:@"DefaultType"];
}

- (NSSet *)allFieldNames{
    return allFieldNames;
}

- (NSArray *)requiredFieldsForType:(NSString *)type{
    NSDictionary *fieldsForType = [fieldsForTypesDict objectForKey:type];
	if(fieldsForType){
        return [fieldsForType objectForKey:REQUIRED_KEY];
    }else{
        return [NSArray array];
    }
}

- (NSArray *)optionalFieldsForType:(NSString *)type{
    NSDictionary *fieldsForType = [fieldsForTypesDict objectForKey:type];
	if(fieldsForType){
        return [fieldsForType objectForKey:OPTIONAL_KEY];
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

- (NSString *)RISTagForBibTeXFieldName:(NSString *)name{
    NSArray *types = [fieldNameForPubMedTagDict allKeysForObject:name];
    if([types count])
        return [types objectAtIndex:0];
    else
        return [[name stringByPaddingToLength:2 withString:@"1" startingAtIndex:0] uppercaseString]; // manufacture a guess
}

- (NSString *)RISTypeForBibTeXType:(NSString *)type{
    NSArray *types = [bibtexTypeForPubMedTypeDict allKeysForObject:type];
    if([types count])
        return [types objectAtIndex:0];
    else
        return [[type stringByPaddingToLength:4 withString:@"?" startingAtIndex:0] uppercaseString]; // manufacture a guess
}

#pragma mark Character sets

- (NSCharacterSet *)invalidCharactersForField:(NSString *)fieldName inFileType:(NSString *)type{
	if( [type isEqualToString:BDSKBibtexString] && [fieldName isEqualToString:BDSKCiteKeyString]){
		return invalidCiteKeyCharSet;
	}
	if([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey] containsObject:BDSKLocalUrlString]){
		return invalidLocalUrlCharSet;
	}
	[NSException raise:BDSKUnimplementedException format:@"invalidCharactersForField is partly implemented"];
}

- (NSCharacterSet *)strictInvalidCharactersForField:(NSString *)fieldName inFileType:(NSString *)type{
	if( [type isEqualToString:BDSKBibtexString] && [fieldName isEqualToString:BDSKCiteKeyString]){
		return strictInvalidCiteKeyCharSet;
	}
	if([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey] containsObject:BDSKLocalUrlString]){
		return strictInvalidLocalUrlCharSet;
	}
	[NSException raise:BDSKUnimplementedException format:@"strictInvalidCharactersForField is partly implemented"];
}

- (NSCharacterSet *)invalidFieldNameCharacterSetForFileType:(NSString *)type{
    if([type isEqualToString:BDSKBibtexString])
        return invalidCiteKeyCharSet;
    else
        [NSException raise:BDSKUnimplementedException format:@"invalidFieldNameCharacterSetForFileType is only implemented for BibTeX"];
}

- (NSCharacterSet *)fragileCiteKeyCharacterSet{
	return fragileCiteKeyCharSet;
}

@end
