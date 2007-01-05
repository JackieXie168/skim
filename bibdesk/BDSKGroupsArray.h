//
//  BDSKGroupsArray.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 11/10/06.
/*
 This software is Copyright (c) 2006,2007
 Christiaan Hofman. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Christiaan Hofman nor the names of any
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

#import <Cocoa/Cocoa.h>

enum {
    BDSKSharedGroupType,
	BDSKURLGroupType,
	BDSKScriptGroupType,
	BDSKSearchGroupType,
    BDSKSmartGroupType,
	BDSKStaticGroupType,
	BDSKCategoryGroupType
};

@class BDSKGroup, BDSKSmartGroup, BDSKStaticGroup, BDSKURLGroup, BDSKScriptGroup, BDSKSearchGroup, BibDocument;

@interface BDSKGroupsArray : NSArray {
    BDSKGroup *libraryGroup;
    BDSKStaticGroup *lastImportGroup;
    NSMutableArray *sharedGroups;
    NSMutableArray *urlGroups;
    NSMutableArray *scriptGroups;
    NSMutableArray *searchGroups;
    NSMutableArray *smartGroups;
    NSMutableArray *staticGroups;
    NSArray *tmpStaticGroups;
    NSMutableArray *categoryGroups;
    NSMutableDictionary *spinners;
    BibDocument *document;
}

- (NSRange)rangeOfSharedGroups;
- (NSRange)rangeOfURLGroups;
- (NSRange)rangeOfScriptGroups;
- (NSRange)rangeOfSearchGroups;
- (NSRange)rangeOfSmartGroups;
- (NSRange)rangeOfStaticGroups;
- (NSRange)rangeOfCategoryGroups;

- (unsigned int)numberOfSharedGroupsAtIndexes:(NSIndexSet *)indexes;
- (unsigned int)numberOfURLGroupsAtIndexes:(NSIndexSet *)indexes;
- (unsigned int)numberOfScriptGroupsAtIndexes:(NSIndexSet *)indexes;
- (unsigned int)numberOfSearchGroupsAtIndexes:(NSIndexSet *)indexes;
- (unsigned int)numberOfSmartGroupsAtIndexes:(NSIndexSet *)indexes;
- (unsigned int)numberOfStaticGroupsAtIndexes:(NSIndexSet *)indexes;
- (unsigned int)numberOfCategoryGroupsAtIndexes:(NSIndexSet *)indexes;

- (BOOL)hasSharedGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasURLGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasScriptGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasSearchGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasSmartGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasStaticGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasCategoryGroupsAtIndexes:(NSIndexSet *)indexes;
- (BOOL)hasExternalGroupsAtIndexes:(NSIndexSet *)indexes;

- (BDSKGroup *)libraryGroup;
- (BDSKStaticGroup *)lastImportGroup;
- (NSArray *)sharedGroups;
- (NSArray *)URLGroups;
- (NSArray *)scriptGroups;
- (NSArray *)searchGroups;
- (NSArray *)smartGroups;
- (NSArray *)staticGroups;
- (NSArray *)categoryGroups;

- (void)setLastImportedPublications:(NSArray *)pubs;
- (void)setSharedGroups:(NSArray *)array;
- (void)addURLGroup:(BDSKURLGroup *)group;
- (void)removeURLGroup:(BDSKURLGroup *)group;
- (void)addScriptGroup:(BDSKScriptGroup *)group;
- (void)removeScriptGroup:(BDSKScriptGroup *)group;
- (void)addSearchGroup:(BDSKSearchGroup *)group;
- (void)removeSearchGroup:(BDSKSearchGroup *)group;
- (void)addSmartGroup:(BDSKSmartGroup *)group;
- (void)removeSmartGroup:(BDSKSmartGroup *)group;
- (void)addStaticGroup:(BDSKStaticGroup *)group;
- (void)removeStaticGroup:(BDSKStaticGroup *)group;
- (void)setCategoryGroups:(NSArray *)array;
- (void)removeAllNonSharedGroups;

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors;

- (NSProgressIndicator *)spinnerForGroup:(BDSKGroup *)group;
- (void)removeSpinnerForGroup:(BDSKGroup *)group;

- (BibDocument *)document;
- (void)setDocument:(BibDocument *)newDocument;

- (void)setGroupsOfType:(int)groupType fromSerializedData:(NSData *)data;
- (NSData *)serializedGroupsDataOfType:(int)groupType;

@end
