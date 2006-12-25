//
//  BDSKGroupsArray.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 11/10/06.
/*
 This software is Copyright (c) 2006
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

#import "BDSKGroupsArray.h"
#import "BDSKGroup.h"
#import "BDSKSharedGroup.h"
#import "BDSKURLGroup.h"
#import "BDSKScriptGroup.h"
#import "BDSKSearchGroup.h"
#import "BDSKSmartGroup.h"
#import "BDSKStaticGroup.h"
#import "BDSKCategoryGroup.h"
#import "BDSKPublicationsArray.h"
#import "BibAuthor.h"
#import "NSObject_BDSKExtensions.h"
#import "BDSKFilter.h"

@interface BDSKGroupsArray (Private)

- (void)updateStaticGroupsIfNeeded;
- (NSUndoManager *)undoManager;

@end


@implementation BDSKGroupsArray 

- (id)init {
    if(self = [super init]) {
        libraryGroup = [[BDSKGroup alloc] initLibraryGroup];
        lastImportGroup = nil;
        sharedGroups = [[NSMutableArray alloc] init];
        urlGroups = [[NSMutableArray alloc] init];
        scriptGroups = [[NSMutableArray alloc] init];
        searchGroups = [[NSMutableArray alloc] init];
        smartGroups = [[NSMutableArray alloc] init];
        staticGroups = [[NSMutableArray alloc] init];
        tmpStaticGroups = nil;
        categoryGroups = nil;
        spinners = nil;
    }
    return self;
}

- (void)dealloc {
    [libraryGroup release];
    [lastImportGroup release];
    [sharedGroups release];
    [urlGroups release];
    [scriptGroups release];
    [searchGroups release];
    [smartGroups release];
    [staticGroups release];
    [tmpStaticGroups release];
    [categoryGroups release];
    [spinners release];
    [super dealloc];
}

#pragma mark NSArray primitive methods

- (unsigned int)count {
    [self updateStaticGroupsIfNeeded];
    return [sharedGroups count] + [urlGroups count] + [scriptGroups count] + [searchGroups count] + [smartGroups count] + [staticGroups count] + [categoryGroups count] + ([lastImportGroup count] ? 2 : 1) /* add 1 for all publications group */ ;
}

- (id)objectAtIndex:(unsigned int)index {
    unsigned int count;
    
    [self updateStaticGroupsIfNeeded];
    
    if (index == 0)
		return libraryGroup;
    index -= 1;
    
    count = [sharedGroups count];
    if (index < count)
        return [sharedGroups objectAtIndex:index];
    index -= count;
    
    count = [urlGroups count];
    if (index < count)
        return [urlGroups objectAtIndex:index];
    index -= count;
    
    count = [scriptGroups count];
    if (index < count)
        return [scriptGroups objectAtIndex:index];
    index -= count;
    
    count = [searchGroups count];
    if (index < count)
        return [searchGroups objectAtIndex:index];
    index -= count;
    
    if ([lastImportGroup count] != 0) {
        if (index == 0)
            return lastImportGroup;
        index -= 1;
    }
    
	count = [smartGroups count];
    if (index < count)
		return [smartGroups objectAtIndex:index];
    index -= count;
    
    count = [staticGroups count];
    if (index < count)
        return [staticGroups objectAtIndex:index];
    index -= count;
    
    return [categoryGroups objectAtIndex:index];
}

#pragma mark Subarray Accessors

- (BDSKGroup *)libraryGroup{
    return libraryGroup;
}

- (BDSKStaticGroup *)lastImportGroup{
    return lastImportGroup;
}

- (NSArray *)sharedGroups{
    return sharedGroups;
}

- (NSArray *)URLGroups{
    return urlGroups;
}

- (NSArray *)scriptGroups{
    return scriptGroups;
}

- (NSArray *)searchGroups{
    return searchGroups;
}

- (NSArray *)smartGroups{
    return smartGroups;
}

- (NSArray *)staticGroups{
    [self updateStaticGroupsIfNeeded];
    return staticGroups;
}

- (NSArray *)categoryGroups{
    return categoryGroups;
}

#pragma mark Index ranges of groups

- (NSRange)rangeOfSharedGroups{
    return NSMakeRange(1, [sharedGroups count]);
}

- (NSRange)rangeOfURLGroups{
    return NSMakeRange(NSMaxRange([self rangeOfSharedGroups]), [urlGroups count]);
}

- (NSRange)rangeOfScriptGroups{
    return NSMakeRange(NSMaxRange([self rangeOfURLGroups]), [scriptGroups count]);
}

- (NSRange)rangeOfSearchGroups{
    return NSMakeRange(NSMaxRange([self rangeOfScriptGroups]), [searchGroups count]);
}

- (NSRange)rangeOfSmartGroups{
    unsigned startIndex = NSMaxRange([self rangeOfSearchGroups]);
    if([lastImportGroup count] > 0) startIndex++;
    return NSMakeRange(startIndex, [smartGroups count]);
}

- (NSRange)rangeOfStaticGroups{
    [self updateStaticGroupsIfNeeded];
    return NSMakeRange(NSMaxRange([self rangeOfSmartGroups]), [staticGroups count]);
}

- (NSRange)rangeOfCategoryGroups{
    return NSMakeRange(NSMaxRange([self rangeOfStaticGroups]), [categoryGroups count]);
}

- (unsigned int)numberOfSharedGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange sharedRange = [self rangeOfSharedGroups];
    unsigned int maxCount = MIN([indexes count], sharedRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&sharedRange];
}

- (unsigned int)numberOfURLGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange urlRange = [self rangeOfURLGroups];
    unsigned int maxCount = MIN([indexes count], urlRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&urlRange];
}

- (unsigned int)numberOfScriptGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange scriptRange = [self rangeOfScriptGroups];
    unsigned int maxCount = MIN([indexes count], scriptRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&scriptRange];
}

- (unsigned int)numberOfSearchGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange searchRange = [self rangeOfSearchGroups];
    unsigned int maxCount = MIN([indexes count], searchRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&searchRange];
}

- (unsigned int)numberOfSmartGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange smartRange = [self rangeOfSmartGroups];
    unsigned int maxCount = MIN([indexes count], smartRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&smartRange];
}

- (unsigned int)numberOfStaticGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange staticRange = [self rangeOfStaticGroups];
    unsigned int maxCount = MIN([indexes count], staticRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&staticRange];
}

- (unsigned int)numberOfCategoryGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange categoryRange = [self rangeOfCategoryGroups];
    unsigned int maxCount = MIN([indexes count], categoryRange.length);
    unsigned int buffer[maxCount];
    return [indexes getIndexes:buffer maxCount:maxCount inIndexRange:&categoryRange];
}

- (BOOL)hasSharedGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange sharedRange = [self rangeOfSharedGroups];
    return [indexes intersectsIndexesInRange:sharedRange];
}

- (BOOL)hasURLGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange urlRange = [self rangeOfURLGroups];
    return [indexes intersectsIndexesInRange:urlRange];
}

- (BOOL)hasScriptGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange scriptRange = [self rangeOfScriptGroups];
    return [indexes intersectsIndexesInRange:scriptRange];
}

- (BOOL)hasSearchGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange searchRange = [self rangeOfSearchGroups];
    return [indexes intersectsIndexesInRange:searchRange];
}

- (BOOL)hasSmartGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange smartRange = [self rangeOfSmartGroups];
    return [indexes intersectsIndexesInRange:smartRange];
}

- (BOOL)hasStaticGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange staticRange = [self rangeOfStaticGroups];
    return [indexes intersectsIndexesInRange:staticRange];
}

- (BOOL)hasCategoryGroupsAtIndexes:(NSIndexSet *)indexes{
    NSRange categoryRange = [self rangeOfCategoryGroups];
    return [indexes intersectsIndexesInRange:categoryRange];
}

- (BOOL)hasExternalGroupsAtIndexes:(NSIndexSet *)indexes{
    return [self hasSharedGroupsAtIndexes:indexes] || [self hasURLGroupsAtIndexes:indexes] || [self hasScriptGroupsAtIndexes:indexes] || [self hasSearchGroupsAtIndexes:indexes];
}

#pragma mark Mutable accessors

- (void)setLastImportedPublications:(NSArray *)pubs{
    if(lastImportGroup == nil)
        lastImportGroup = [[BDSKStaticGroup alloc] initWithLastImport:pubs];
    else 
        [lastImportGroup setPublications:pubs];
}

- (void)setSharedGroups:(NSArray *)array{
    if(sharedGroups != array){
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKWillAddRemoveGroupNotification object:self];
        
        [sharedGroups removeObjectsInArray:array];
        [self performSelector:@selector(removeSpinnerForGroup:) withObjectsFromArray:sharedGroups];
        [sharedGroups setArray:array]; 
    }
}

- (void)addURLGroup:(BDSKURLGroup *)group {
	[[[self undoManager] prepareWithInvocationTarget:self] removeURLGroup:group];
    
	[urlGroups addObject:group];
	[group setUndoManager:[self undoManager]];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDidAddRemoveGroupNotification object:self];
}

- (void)removeURLGroup:(BDSKURLGroup *)group {
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKWillAddRemoveGroupNotification object:self];
    
	[[[self undoManager] prepareWithInvocationTarget:self] addURLGroup:group];
    
    [self removeSpinnerForGroup:group];
    
	[group setUndoManager:nil];
	[urlGroups removeObjectIdenticalTo:group];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDidAddRemoveGroupNotification object:self];
}

- (void)addScriptGroup:(BDSKScriptGroup *)group {
	[[[self undoManager] prepareWithInvocationTarget:self] removeScriptGroup:group];
    
	[scriptGroups addObject:group];
	[group setUndoManager:[self undoManager]];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDidAddRemoveGroupNotification object:self];
}

- (void)removeScriptGroup:(BDSKScriptGroup *)group {
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKWillAddRemoveGroupNotification object:self];
    
	[[[self undoManager] prepareWithInvocationTarget:self] addScriptGroup:group];
    
    [self removeSpinnerForGroup:group];
    
	[group setUndoManager:nil];
	[scriptGroups removeObjectIdenticalTo:group];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDidAddRemoveGroupNotification object:self];
}

- (void)addSearchGroup:(BDSKSearchGroup *)group {
	[[[self undoManager] prepareWithInvocationTarget:self] removeSearchGroup:group];
    
	[searchGroups addObject:group];
	[group setUndoManager:[self undoManager]];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDidAddRemoveGroupNotification object:self];
}

- (void)removeSearchGroup:(BDSKSearchGroup *)group {
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKWillAddRemoveGroupNotification object:self];
    
	[[[self undoManager] prepareWithInvocationTarget:self] addSearchGroup:group];
    
    [self removeSpinnerForGroup:group];
    
	[group setUndoManager:nil];
	[searchGroups removeObjectIdenticalTo:group];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDidAddRemoveGroupNotification object:self];
}

- (void)addSmartGroup:(BDSKSmartGroup *)group {
	[[[self undoManager] prepareWithInvocationTarget:self] removeSmartGroup:group];
    
    // update the count
	[group filterItems:[document publications]];
	
	[smartGroups addObject:group];
	[group setUndoManager:[self undoManager]];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDidAddRemoveGroupNotification object:self];
}

- (void)removeSmartGroup:(BDSKSmartGroup *)group {
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKWillAddRemoveGroupNotification object:self];
    
	[[[self undoManager] prepareWithInvocationTarget:self] addSmartGroup:group];
	
	[group setUndoManager:nil];
	[smartGroups removeObjectIdenticalTo:group];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDidAddRemoveGroupNotification object:self];
}

- (void)addStaticGroup:(BDSKStaticGroup *)group {
	[[[self undoManager] prepareWithInvocationTarget:self] removeStaticGroup:group];
	
	[group setUndoManager:[self undoManager]];
    [self updateStaticGroupsIfNeeded];
    [staticGroups addObject:group];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDidAddRemoveGroupNotification object:self];
}

- (void)removeStaticGroup:(BDSKStaticGroup *)group {
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKWillAddRemoveGroupNotification object:self];
    
	[[[self undoManager] prepareWithInvocationTarget:self] addStaticGroup:group];
	
	[group setUndoManager:nil];
    [self updateStaticGroupsIfNeeded];
    [staticGroups removeObjectIdenticalTo:group];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDidAddRemoveGroupNotification object:self];
}
 
- (void)setCategoryGroups:(NSArray *)array{
    if(categoryGroups != array){
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKWillAddRemoveGroupNotification object:self];
        
        [categoryGroups release];
        categoryGroups = [array mutableCopy]; 
    }
}

// this should only be used just before reading from file, in particular revert, so we shouldn't make this undoable
- (void)removeAllNonSharedGroups {
    [self performSelector:@selector(removeSpinnerForGroup:) withObjectsFromArray:urlGroups];
    [self performSelector:@selector(removeSpinnerForGroup:) withObjectsFromArray:scriptGroups];
    
    [lastImportGroup setPublications:[NSArray array]];
    [urlGroups removeAllObjects];
    [scriptGroups removeAllObjects];
    [searchGroups removeAllObjects];
    [staticGroups removeAllObjects];
    [smartGroups removeAllObjects];
    [staticGroups removeAllObjects];
    [categoryGroups removeAllObjects];
}

#pragma mark Spinners

- (NSProgressIndicator *)spinnerForGroup:(BDSKGroup *)group{
    NSProgressIndicator *spinner = [spinners objectForKey:group];
    
    if(spinner == nil && [group isRetrieving]){
        if(spinners == nil)
            spinners = [[NSMutableDictionary alloc] initWithCapacity:5];
        spinner = [[NSProgressIndicator alloc] init];
        [spinner setControlSize:NSSmallControlSize];
        [spinner setStyle:NSProgressIndicatorSpinningStyle];
        [spinner setDisplayedWhenStopped:NO];
        [spinner sizeToFit];
        [spinner setUsesThreadedAnimation:YES];
        [spinners setObject:spinner forKey:group];
        [spinner release];
    }
    if(spinner){
        if ([group isRetrieving])
            [spinner startAnimation:nil];
        else
            [spinner stopAnimation:nil];
    }
    
    return spinner;
}

- (void)removeSpinnerForGroup:(BDSKGroup *)group{
    NSProgressIndicator *spinner = [spinners objectForKey:group];
    if(spinner){
        [spinner stopAnimation:nil];
        [spinner removeFromSuperview];
        [spinners removeObjectForKey:group];
    }
}

#pragma mark Document

- (BibDocument *)document{
    return document;
}

- (void)setDocument:(BibDocument *)newDocument{
    document = newDocument;
}

#pragma mark Sorting

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors{
    BDSKGroup *emptyGroup = nil;
    
    if ([categoryGroups count] > 0) {
        id firstName = [[categoryGroups objectAtIndex:0] name];
        if ([firstName isEqual:@""] || [firstName isEqual:[BibAuthor emptyAuthor]]) {
            emptyGroup = [[categoryGroups objectAtIndex:0] retain];
            [categoryGroups removeObjectAtIndex:0];
        }
    }
    
    [self updateStaticGroupsIfNeeded];
    
    [sharedGroups sortUsingDescriptors:sortDescriptors];
    [urlGroups sortUsingDescriptors:sortDescriptors];
    [scriptGroups sortUsingDescriptors:sortDescriptors];
    [searchGroups sortUsingDescriptors:sortDescriptors];
    [smartGroups sortUsingDescriptors:sortDescriptors];
    [staticGroups sortUsingDescriptors:sortDescriptors];
    [categoryGroups sortUsingDescriptors:sortDescriptors];
	
    if (emptyGroup != nil) {
        [categoryGroups insertObject:emptyGroup atIndex:0];
        [emptyGroup release];
    }
}

#pragma mark Serializing

- (void)setSmartGroupsFromPlist:(NSArray *)plist {
    NSEnumerator *groupEnum = [plist objectEnumerator];
    NSDictionary *groupDict;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[(NSArray *)plist count]];
    BDSKSmartGroup *group = nil;
    BDSKFilter *filter = nil;
    
    while (groupDict = [groupEnum nextObject]) {
        @try {
            filter = [[BDSKFilter alloc] initWithDictionary:groupDict];
            group = [[BDSKSmartGroup alloc] initWithName:[groupDict objectForKey:@"group name"] count:0 filter:filter];
            [group setUndoManager:[self undoManager]];
            [array addObject:group];
        }
        @catch(id exception) {
            NSLog(@"Ignoring exception \"%@\" while parsing smart groups data.", exception);
        }
        @finally {
            [group release];
            group = nil;
            [filter release];
            filter = nil;
        }
    }
	
	[smartGroups setArray:array];
}

- (void)setStaticGroupsFromPlist:(NSArray *)plist {
    [tmpStaticGroups release]; // just to be sure, for revert
    tmpStaticGroups = [plist retain];
}

- (void)setURLGroupsFromPlist:(NSArray *)plist {
    NSString *name = nil;
    NSURL *url = nil;
    NSEnumerator *groupEnum = [plist objectEnumerator];
    NSDictionary *groupDict;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[(NSArray *)plist count]];
    BDSKURLGroup *group = nil;
    
    while (groupDict = [groupEnum nextObject]) {
        @try {
            name = [[groupDict objectForKey:@"group name"] stringByUnescapingGroupPlistEntities];
            url = [NSURL URLWithString:[groupDict objectForKey:@"URL"]];
            group = [[BDSKURLGroup alloc] initWithName:name URL:url];
            [group setUndoManager:[self undoManager]];
            [array addObject:group];
        }
        @catch(id exception) {
            NSLog(@"Ignoring exception \"%@\" while parsing URL groups data.", exception);
        }
        @finally {
            [group release];
            group = nil;
        }
    }
	
	[urlGroups setArray:array];
}

- (void)setScriptGroupsFromPlist:(NSArray *)plist {
    NSString *name = nil;
    NSString *path = nil;
    NSString *arguments = nil;
    int type;
    NSEnumerator *groupEnum = [plist objectEnumerator];
    NSDictionary *groupDict;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[(NSArray *)plist count]];
    BDSKScriptGroup *group = nil;
    
    while (groupDict = [groupEnum nextObject]) {
        @try {
            name = [[groupDict objectForKey:@"group name"] stringByUnescapingGroupPlistEntities];
            path = [[groupDict objectForKey:@"script path"] stringByUnescapingGroupPlistEntities];
            arguments = [[groupDict objectForKey:@"script arguments"] stringByUnescapingGroupPlistEntities];
            type = [[groupDict objectForKey:@"script type"] intValue];
            group = [[BDSKScriptGroup alloc] initWithName:name scriptPath:path scriptArguments:arguments scriptType:type];
            [group setUndoManager:[self undoManager]];
            [array addObject:group];
        }
        @catch(id exception) {
            NSLog(@"Ignoring exception \"%@\" while parsing script groups data.", exception);
        }
        @finally {
            [group release];
            group = nil;
        }
    }
	
	[scriptGroups setArray:array];
}

#warning Temporary
- (void)setSearchGroupsFromPlist:(NSArray *)plist {
    NSString *name = nil;
    NSString *path = nil;
    NSString *arguments = nil;
    int type;
    NSEnumerator *groupEnum = [plist objectEnumerator];
    NSDictionary *groupDict;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[(NSArray *)plist count]];
    BDSKSearchGroup *group = nil;
    
    while (groupDict = [groupEnum nextObject]) {
        @try {
            name = [[groupDict objectForKey:@"group name"] stringByUnescapingGroupPlistEntities];
            group = [[BDSKSearchGroup alloc] initWithName:name];
            [group setUndoManager:[self undoManager]];
            [array addObject:group];
        }
        @catch(id exception) {
            NSLog(@"Ignoring exception \"%@\" while parsing search groups data.", exception);
        }
        @finally {
            [group release];
            group = nil;
        }
    }
	
	[scriptGroups setArray:array];
}

- (NSArray *)plistFromSmartGroups {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[smartGroups count]];
    NSString *name;
    NSMutableDictionary *groupDict;
	NSEnumerator *groupEnum = [smartGroups objectEnumerator];
	BDSKSmartGroup *group;
	
	while (group = [groupEnum nextObject]) {
        name = [[group stringValue] stringByEscapingGroupPlistEntities];
		groupDict = [[[group filter] dictionaryValue] mutableCopy];
		[groupDict setObject:name forKey:@"group name"];
		[array addObject:groupDict];
		[groupDict release];
	}
	
	return array;
}

- (NSArray *)plistFromStaticGroups {
    [self updateStaticGroupsIfNeeded];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[staticGroups count]];
	NSString *keys;
    NSString *name;
    NSDictionary *groupDict;
	NSEnumerator *groupEnum = [staticGroups objectEnumerator];
	BDSKStaticGroup *group;
	
	while (group = [groupEnum nextObject]) {
        name = [[group stringValue] stringByEscapingGroupPlistEntities];
		keys = [[[group publications] valueForKeyPath:@"@distinctUnionOfObjects.citeKey"] componentsJoinedByString:@","];
        groupDict = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"group name", keys, @"keys", nil];
		[array addObject:groupDict];
		[groupDict release];
	}
	
	return array;
}

- (NSArray *)plistFromURLGroups {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[urlGroups count]];
    NSString *name;
    NSString *url;
    NSDictionary *groupDict;
	NSEnumerator *groupEnum = [urlGroups objectEnumerator];
	BDSKURLGroup *group;
	
	while (group = [groupEnum nextObject]) {
        name = [[group stringValue] stringByEscapingGroupPlistEntities];
        url = [[group URL] absoluteString];
        groupDict = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"group name", url, @"URL", nil];
		[array addObject:groupDict];
		[groupDict release];
	}
	
	return array;
}

- (NSArray *)plistFromScriptGroups {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[scriptGroups count]];
    NSString *name;
    NSString *path;
    NSString *args;
    NSNumber *type;
    NSDictionary *groupDict;
	NSEnumerator *groupEnum = [scriptGroups objectEnumerator];
	BDSKScriptGroup *group;
	
	while (group = [groupEnum nextObject]) {
        name = [[group stringValue] stringByEscapingGroupPlistEntities];
        path = [[group scriptPath] stringByEscapingGroupPlistEntities];
        args = [[group scriptArguments] stringByEscapingGroupPlistEntities];
        type = [NSNumber numberWithInt:[group scriptType]];
        groupDict = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"group name", path, @"script path", args, @"script arguments", type, @"script type", nil];
		[array addObject:groupDict];
		[groupDict release];
	}
	
	return array;
}

#warning Temporary
- (NSArray *)plistFromSearchGroups {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[searchGroups count]];
    NSString *name;
    NSString *path;
    NSString *args;
    NSNumber *type;
    NSDictionary *groupDict;
	NSEnumerator *groupEnum = [searchGroups objectEnumerator];
	BDSKScriptGroup *group;
	
	while (group = [groupEnum nextObject]) {
        name = [[group stringValue] stringByEscapingGroupPlistEntities];
        groupDict = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"group name", nil];
		[array addObject:groupDict];
		[groupDict release];
	}
	
	return array;
}

- (void)setGroupsOfType:(int)groupType fromSerializedData:(NSData *)data {
	NSString *error = nil;
	NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
	id plist = [NSPropertyListSerialization propertyListFromData:data
												mutabilityOption:NSPropertyListImmutable
														  format:&format 
												errorDescription:&error];
	
	if (error) {
		NSLog(@"Error deserializing: %@", error);
        [error release];
		return;
	}
	if ([plist isKindOfClass:[NSArray class]] == NO) {
		NSLog(@"Serialized groups was no array.");
		return;
	}
	
    if (groupType == BDSKSmartGroupType)
        [self setSmartGroupsFromPlist:plist];
	else if (groupType == BDSKStaticGroupType)
        [self setStaticGroupsFromPlist:plist];
	else if (groupType == BDSKURLGroupType)
        [self setURLGroupsFromPlist:plist];
	else if (groupType == BDSKScriptGroupType)
        [self setScriptGroupsFromPlist:plist];
}

- (NSData *)serializedGroupsDataOfType:(int)groupType {
	NSArray *array = nil;
    
    if (groupType == BDSKSmartGroupType)
        array = [self plistFromSmartGroups];
	else if (groupType == BDSKStaticGroupType)
        array = [self plistFromStaticGroups];
	else if (groupType == BDSKURLGroupType)
        array = [self plistFromURLGroups];
	else if (groupType == BDSKScriptGroupType)
        array = [self plistFromScriptGroups];
	else if (groupType == BDSKSearchGroupType)
        array = [self plistFromSearchGroups];
    else return nil;
    
	NSString *error = nil;
	NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:array
															  format:format 
													errorDescription:&error];
    	
	if (error) {
		NSLog(@"Error serializing: %@", error);
        [error release];
		return nil;
	}
	return data;
}

@end


@implementation BDSKGroupsArray (Private)

- (void)updateStaticGroupsIfNeeded{
    if (tmpStaticGroups == nil) 
        return;
    
    NSEnumerator *groupEnum = [tmpStaticGroups objectEnumerator];
    NSDictionary *groupDict;
    BDSKStaticGroup *group = nil;
    NSMutableArray *pubArray = nil;
    NSString *name;
    NSArray *keys;
    NSEnumerator *keyEnum;
    NSString *key;
    
    [staticGroups removeAllObjects];
    
    while (groupDict = [groupEnum nextObject]) {
        @try {
            name = [[groupDict objectForKey:@"group name"] stringByUnescapingGroupPlistEntities];
            keys = [[groupDict objectForKey:@"keys"] componentsSeparatedByString:@","];
            keyEnum = [keys objectEnumerator];
            pubArray = [[NSMutableArray alloc] initWithCapacity:[keys count]];
            while (key = [keyEnum nextObject]) 
                [pubArray addObjectsFromArray:[[document publications] allItemsForCiteKey:key]];
            group = [[BDSKStaticGroup alloc] initWithName:name publications:pubArray];
            [group setUndoManager:[self undoManager]];
            [staticGroups addObject:group];
        }
        @catch(id exception) {
            NSLog(@"Ignoring exception \"%@\" while parsing static groups data.", exception);
        }
        @finally {
            [group release];
            group = nil;
            [pubArray release];
            pubArray = nil;
        }
    }
    
    [tmpStaticGroups release];
    tmpStaticGroups = nil;
}

- (NSUndoManager *)undoManager {
    return [document undoManager];
}

@end
