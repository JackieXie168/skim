//  BibItem.m
//  Created by Michael McCracken on Tue Dec 18 2001.
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005,2006,2007
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


#import "BibItem.h"
#import "BDSKOwnerProtocol.h"
#import "NSDate_BDSKExtensions.h"
#import "BDSKCountedSet.h"
#import "BDSKGroup.h"
#import "BDSKCategoryGroup.h"
#import "BibEditor.h"
#import "BibTypeManager.h"
#import "BibAuthor.h"
#import "BibPrefController.h"
#import "NSString_BDSKExtensions.h"
#import "BDSKConverter.h"
#import "BDSKFontManager.h"
#import "BDAlias.h"
#import "BDSKFormatParser.h"
#import "BibTeXParser.h"
#import "BibFiler.h"
#import "BibDocument.h"
#import "BibAppController.h"
#import "NSFileManager_BDSKExtensions.h"
#import "NSAttributedString_BDSKExtensions.h"
#import "NSSet_BDSKExtensions.h"
#import "NSURL_BDSKExtensions.h"
#import "NSArray_BDSKExtensions.h"
#import "NSError_BDSKExtensions.h"
#import "NSImage+Toolbox.h"
#import "BDSKStringNode.h"
#import "OFCharacterSet_BDSKExtensions.h"
#import "PDFMetadata.h"
#import "BibField.h"
#import "BDSKTemplate.h"
#import "BDSKTemplateParser.h"
#import "BibDocument_Search.h"
#import "BDSKPublicationsArray.h"
#import "NSData_BDSKExtensions.h"

static NSString *BDSKDefaultCiteKey = @"cite-key";

enum {
    BDSKStringFieldCollection, 
    BDSKPersonFieldCollection,
    BDSKURLFieldCollection
};

@interface BDSKFieldCollection : NSObject {
    BibItem *item;
    NSMutableSet *usedFields;
    int type;
}

- (id)initWithItem:(BibItem *)anItem;
- (void)setType:(int)type;
- (id)fieldForName:(NSString *)name;
- (BOOL)isUsedField:(NSString *)name;
- (BOOL)isEmptyField:(NSString *)name;
- (id)fieldsWithNames:(NSArray *)names;

@end

@interface BDSKFieldArray : NSArray {
    NSMutableArray *fieldNames;
    BDSKFieldCollection *fieldCollection;
}

- (id)initWithFieldCollection:(BDSKFieldCollection *)collection fieldNames:(NSArray *)array;
- (id)nonEmpty;
- (unsigned int)count;
- (id)objectAtIndex:(unsigned int)index;

@end

@interface BibItem (Private)

- (void)setDateAdded:(NSCalendarDate *)newDateAdded;
- (void)setDateModified:(NSCalendarDate *)newDateModified;
- (void)setDate:(NSCalendarDate *)newDate;
- (void)setPubTypeWithoutUndo:(NSString *)newType;

// updates derived info from the dictionary
- (void)updateMetadataForKey:(NSString *)key;

@end


CFHashCode BibItemCaseInsensitiveCiteKeyHash(const void *item)
{
    OBASSERT([(id)item isKindOfClass:[BibItem class]]);
    return OFCaseInsensitiveStringHash([(BibItem *)item citeKey]);
}

CFHashCode BibItemEquivalenceHash(const void *item)
{
    OBASSERT([(id)item isKindOfClass:[BibItem class]]);
    
    NSString *type = [(BibItem *)item pubType];
    CFHashCode hash = OFCaseInsensitiveStringHash(type);
	
	// hash only the standard fields; are these all we should compare?
	BibTypeManager *btm = [BibTypeManager sharedManager];
	NSMutableSet *keys = [[NSMutableSet alloc] initWithCapacity:20];
	[keys addObjectsFromArray:[btm requiredFieldsForType:type]];
	[keys addObjectsFromArray:[btm optionalFieldsForType:type]];
	[keys addObjectsFromArray:[btm userDefaultFieldsForType:type]];
    [keys removeObject:BDSKLocalUrlString];
	NSEnumerator *keyEnum = [keys objectEnumerator];
    [keys release];
    
	NSString *key;
	
	while (key = [keyEnum nextObject])
        hash ^= [[(BibItem *)item stringValueOfField:key inherit:NO] hash];
    
    return hash;
}

Boolean BibItemEqualityTest(const void *value1, const void *value2)
{
    return ([(BibItem *)value1 isEqualToItem:(BibItem *)value2]);
}

Boolean BibItemEquivalenceTest(const void *value1, const void *value2)
{
    return ([(BibItem *)value1 isEquivalentToItem:(BibItem *)value2]);
}

// Values are BibItems; used to determine if pubs are duplicates.  Items must not be edited while contained in a set using these callbacks, so dispose of the set before any editing operations.
const CFSetCallBacks BDSKBibItemEqualityCallBacks = {
    0,    // version
    OFNSObjectRetain,  // retain
    OFNSObjectRelease, // release
    OFNSObjectCopyDescription,
    BibItemEqualityTest,
    BibItemCaseInsensitiveCiteKeyHash,
};

// Values are BibItems; used to determine if pubs are duplicates.  Items must not be edited while contained in a set using these callbacks, so dispose of the set before any editing operations.
const CFSetCallBacks BDSKBibItemEquivalenceCallBacks = {
    0,    // version
    OFNSObjectRetain,  // retain
    OFNSObjectRelease, // release
    OFNSObjectCopyDescription,
    BibItemEquivalenceTest,
    BibItemEquivalenceHash,
};

/* Paragraph styles cached for efficiency. */
static NSParagraphStyle* keyParagraphStyle = nil;
static NSParagraphStyle* bodyParagraphStyle = nil;

static CFDictionaryRef selectorTable = NULL;

#pragma mark -

@implementation BibItem

+ (void)initialize
{
    OBINITIALIZE;
    
    NSMutableParagraphStyle *defaultStyle = [[NSMutableParagraphStyle alloc] init];
    [defaultStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    keyParagraphStyle = [defaultStyle copy];
    [defaultStyle setHeadIndent:50];
    [defaultStyle setFirstLineHeadIndent:50];
    [defaultStyle setTailIndent:-30];
    bodyParagraphStyle = [defaultStyle copy];
    
    // Create a table of field/SEL pairs used for searching
    CFMutableDictionaryRef table = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFCopyStringDictionaryKeyCallBacks, &OFNonOwnedPointerDictionaryValueCallbacks);
    
    CFDictionaryAddValue(table, (CFStringRef)BDSKTitleString, NSSelectorFromString(@"title"));
    CFDictionaryAddValue(table, (CFStringRef)BDSKAuthorString, NSSelectorFromString(@"bibTeXAuthorString"));
    CFDictionaryAddValue(table, (CFStringRef)BDSKPubDateString, NSSelectorFromString(@"calendarDateDescription"));
    CFDictionaryAddValue(table, (CFStringRef)BDSKDateModifiedString, NSSelectorFromString(@"calendarDateModifiedDescription"));
    CFDictionaryAddValue(table, (CFStringRef)BDSKDateAddedString, NSSelectorFromString(@"calendarDateAddedDescription"));
    CFDictionaryAddValue(table, (CFStringRef)BDSKAllFieldsString, NSSelectorFromString(@"allFieldsString"));
    CFDictionaryAddValue(table, (CFStringRef)BDSKPubTypeString, NSSelectorFromString(@"pubType"));
    CFDictionaryAddValue(table, (CFStringRef)BDSKCiteKeyString, NSSelectorFromString(@"citeKey"));
    
    // legacy field name support
    CFDictionaryAddValue(table, CFSTR("Modified"), NSSelectorFromString(@"calendarDateModifiedDescription"));
    CFDictionaryAddValue(table, CFSTR("Added"), NSSelectorFromString(@"calendarDateAddedDescription"));
    CFDictionaryAddValue(table, CFSTR("Created"), NSSelectorFromString(@"calendarDateAddedDescription"));
    CFDictionaryAddValue(table, CFSTR("Pub Type"), NSSelectorFromString(@"pubType"));
    selectorTable = CFDictionaryCreateCopy(CFAllocatorGetDefault(), table);
    CFRelease(table);
}

// for creating an empty item
- (id)init
{
	self = [self initWithType:[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPubTypeStringKey] 
                     fileType:BDSKBibtexString 
                      citeKey:BDSKDefaultCiteKey 
                    pubFields:nil 
                        isNew:YES];
	if (self) {
        // reset this here, since designated init's updateMetadataForKey set it to YES
        [self setHasBeenEdited:NO];
	}
	return self;
}

// this is the designated initializer.
- (id)initWithType:(NSString *)type fileType:(NSString *)inFileType citeKey:(NSString *)key pubFields:(NSDictionary *)fieldsDict isNew:(BOOL)isNew{ 
    if (self = [super init]){
		if(fieldsDict){
			pubFields = [fieldsDict mutableCopy];
		}else{
			pubFields = [[NSMutableDictionary alloc] initWithCapacity:7];
		}
		if (isNew){
			NSString *nowStr = [[NSCalendarDate date] description];
			[pubFields setObject:nowStr forKey:BDSKDateAddedString];
			[pubFields setObject:nowStr forKey:BDSKDateModifiedString];
        }
        
        people = nil;
        
        owner = nil;
        
        fileOrder = nil;
        
        [self setFileType:inFileType];
        [self setPubTypeWithoutUndo:type];
        [self setDate: nil];
        [self setDateAdded: nil];
        [self setDateModified: nil];
        
		[self setNeedsToBeFiled:NO];
		
		groups = [[NSMutableDictionary alloc] initWithCapacity:5];
        cachedURLs = [[NSMutableDictionary alloc] initWithCapacity:5];
		
        templateFields = nil;
        // updateMetadataForKey with a nil argument will set the dates properly if we read them from a file
        [self updateMetadataForKey:nil];
        
        if (key == nil) {
            [self setCiteKeyString: BDSKDefaultCiteKey];
        } else {
            [self setCiteKeyString: key];
        }
        
        // used for determining if we need to re-save Spotlight metadata
        // set to YES initially so the first save after opening a file always writes the metadata, since we don't know beforehand if it's been written
        spotlightMetadataChanged = YES;
    }

    return self;
}

// Never copy between different documents, as this messes up the macroResolver for complex string values
- (id)copyWithZone:(NSZone *)zone{
    // We set isNew to YES as copied items are always added as new items to a document, e.g. for duplicates and text import, so the Date-Added should be reset.  Note that unless someone uses Date-Added or Date-Modified as a default field, a copy is equal according to isEqualToItem:
    BibItem *theCopy = [[[self class] allocWithZone: zone] initWithType:pubType fileType:fileType citeKey:citeKey pubFields:pubFields isNew:YES];
    [theCopy setDate: pubDate];
	
    return theCopy;
}

- (id)initWithCoder:(NSCoder *)coder{
    if([coder allowsKeyedCoding]){
        if(self = [super init]){
            // we need to set the pubFields first because makeType might have to change it
            pubFields = [[coder decodeObjectForKey:@"pubFields"] retain];
            [self setFileType:[coder decodeObjectForKey:@"fileType"]];
            [self setCiteKeyString:[coder decodeObjectForKey:@"citeKey"]];
            [self setDate:[coder decodeObjectForKey:@"pubDate"]];
            [self setDateAdded:[coder decodeObjectForKey:@"dateAdded"]];
            [self setPubTypeWithoutUndo:[coder decodeObjectForKey:@"pubType"]];
            [self setDateModified:[coder decodeObjectForKey:@"dateModified"]];
            groups = [[NSMutableDictionary alloc] initWithCapacity:5];
            cachedURLs = [[NSMutableDictionary alloc] initWithCapacity:5];
            // set by the document, which we don't archive
            owner = nil;
            fileOrder = nil;
            hasBeenEdited = [coder decodeBoolForKey:@"hasBeenEdited"];
            // we don't bother encoding this
            spotlightMetadataChanged = YES;
        }
    } else {       
        [[super init] release];
        self = [[NSKeyedUnarchiver unarchiveObjectWithData:[coder decodeDataObject]] retain];
    }
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
    if([coder allowsKeyedCoding]){
        [coder encodeObject:fileType forKey:@"fileType"];
        [coder encodeObject:citeKey forKey:@"citeKey"];
        [coder encodeObject:pubDate forKey:@"pubDate"];
        [coder encodeObject:dateAdded forKey:@"dateAdded"];
        [coder encodeObject:dateModified forKey:@"dateModified"];
        [coder encodeObject:pubType forKey:@"pubType"];
        [coder encodeObject:pubFields forKey:@"pubFields"];
        [coder encodeBool:hasBeenEdited forKey:@"hasBeenEdited"];
    } else {
        [coder encodeDataObject:[NSKeyedArchiver archivedDataWithRootObject:self]];
    }        
}

- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    return [encoder isByref] ? (id)[NSDistantObject proxyWithLocal:self connection:[encoder connection]] : self;
}

- (void)dealloc{
    [[self undoManager] removeAllActionsWithTarget:self];
    [pubFields release];
    [people release];
	[groups release];
    [cachedURLs release];

    [pubType release];
    [fileType release];
    [citeKey release];
    [pubDate release];
    [dateAdded release];
    [dateModified release];
    [fileOrder release];
    [super dealloc];
}

- (NSString *)description{
    return [NSString stringWithFormat:@"citeKey = \"%@\"\n%@", [self citeKey], [[self pubFields] description]];
}

- (BOOL)isEqual:(BibItem *)aBI{ 
    // use NSObject's isEqual: implementation, since our hash cannot depend on internal state (and equal objects must have the same hash)
    return (aBI == self); 
}

- (BOOL)isEqualToItem:(BibItem *)aBI{ 
    if (aBI == self)
		return YES;
    
    // cite key and type should be compared case-insensitively from BibTeX's perspective
	if ([[self citeKey] caseInsensitiveCompare:[aBI citeKey]] != NSOrderedSame)
		return NO;
	if ([[self pubType] caseInsensitiveCompare:[aBI pubType]] != NSOrderedSame)
		return NO;
	
	// compare only the standard fields; are these all we should compare?
	BibTypeManager *btm = [BibTypeManager sharedManager];
	NSMutableSet *keys = [[NSMutableSet alloc] initWithCapacity:20];
	[keys addObjectsFromArray:[btm requiredFieldsForType:[self pubType]]];
	[keys addObjectsFromArray:[btm optionalFieldsForType:[self pubType]]];
	[keys addObjectsFromArray:[btm userDefaultFieldsForType:[self pubType]]];
	NSEnumerator *keyEnum = [keys objectEnumerator];
    [keys release];
    
	NSString *key;
	
    // @@ remove TeX?  case-sensitive?
	while (key = [keyEnum nextObject]) {
		if ([[self stringValueOfField:key inherit:NO] isEqualToString:[aBI stringValueOfField:key inherit:NO]] == NO)
			return NO;
	}
	
	NSString *crossref1 = [self valueOfField:BDSKCrossrefString inherit:NO];
	NSString *crossref2 = [aBI valueOfField:BDSKCrossrefString inherit:NO];
	if ([NSString isEmptyString:crossref1] == YES)
		return [NSString isEmptyString:crossref2];
	else if ([NSString isEmptyString:crossref2] == YES)
		return NO;
	return ([crossref1 caseInsensitiveCompare:crossref2] == NSOrderedSame);
}

- (BOOL)isEquivalentToItem:(BibItem *)aBI{ 
    if (aBI == self)
		return YES;
    
    // type should be compared case-insensitively from BibTeX's perspective
	if ([[self pubType] caseInsensitiveCompare:[aBI pubType]] != NSOrderedSame)
		return NO;
	
	// compare only the standard fields; are these all we should compare?
	BibTypeManager *btm = [BibTypeManager sharedManager];
	NSMutableSet *keys = [[NSMutableSet alloc] initWithCapacity:20];
	[keys addObjectsFromArray:[btm requiredFieldsForType:[self pubType]]];
	[keys addObjectsFromArray:[btm optionalFieldsForType:[self pubType]]];
	[keys addObjectsFromArray:[btm userDefaultFieldsForType:[self pubType]]];
    [keys removeObject:BDSKLocalUrlString];
	NSEnumerator *keyEnum = [keys objectEnumerator];
    [keys release];
    
	NSString *key;
	
    // @@ remove TeX?  case-sensitive?
	while (key = [keyEnum nextObject]) {
		if ([[self stringValueOfField:key inherit:NO] isEqualToString:[aBI stringValueOfField:key inherit:NO]] == NO)
			return NO;
	}
	
	NSString *crossref1 = [self valueOfField:BDSKCrossrefString inherit:NO];
	NSString *crossref2 = [aBI valueOfField:BDSKCrossrefString inherit:NO];
	if ([NSString isEmptyString:crossref1] == YES)
		return [NSString isEmptyString:crossref2];
	else if ([NSString isEmptyString:crossref2] == YES)
		return NO;
	return ([crossref1 caseInsensitiveCompare:crossref2] == NSOrderedSame);
}

- (BOOL)isIdenticalToItem:(BibItem *)aBI{ 
    if (aBI == self)
		return YES;
	if ([[self citeKey] isEqualToString:[aBI citeKey]] == NO)
		return NO;
	if ([[self pubType] isEqualToString:[aBI pubType]] == NO)
		return NO;
	
	// compare all fields, but compare relevant values as nil might mean 0 for some keys etc.
	NSMutableSet *keys = [[NSMutableSet alloc] initWithArray:[self allFieldNames]];
	[keys addObjectsFromArray:[aBI allFieldNames]];
	NSEnumerator *keyEnum = [keys objectEnumerator];
    [keys release];

	NSString *key, *value1, *value2;
	
	while (key = [keyEnum nextObject]) {
		value1 = [self stringValueOfField:key inherit:NO];
		value2 = [aBI stringValueOfField:key inherit:NO];
		if ([NSString isEmptyString:value1] == YES) {
			if ([NSString isEmptyString:value2] == YES)
				continue;
			else
				return NO;
		} else if ([NSString isEmptyString:value2] == YES) {
			return NO;
		} else if ([value1 isEqualToString:value2] == NO) {
			return NO;
		}
	}
	return YES;
}

- (unsigned int)hash{
    // optimized hash from http://www.mulle-kybernetik.com/artikel/Optimization/opti-7.html
    // note that BibItems are used in hashing collections and so -hash must not depend on mutable state
    return( ((unsigned int) self >> 4) | 
            (unsigned int) self << (32 - 4));
}

#pragma mark -

#pragma mark Type info

// used to be a #define; changed to function for clarity in debugging
static inline void setEmptyStringIfObjectIsNilAndExcludeFromRemoval(NSString *key, NSMutableDictionary *dict, NSMutableSet *removalSet)
{
    if([dict objectForKey:key] == nil)
        [dict setObject:@"" forKey:key];
    [removalSet removeObject:key];
}

// CFSetApplierFunction callback
static void removeItemsInSetFromDictionary(const void *value, void *context)
{
    CFDictionaryRemoveValue((CFMutableDictionaryRef)context, value);
}

// CFSet string equality callback
static Boolean stringIsEqualToString(const void *value1, const void *value2) { return [(id)value1 isEqualToString:(id)value2]; }

- (void)makeType{
    NSString *fieldString;
    NSString *theType = [self pubType];
    
    BibTypeManager *typeManager = [BibTypeManager sharedManager];
    
    // enumerating small arrays by index is generally faster than NSEnumerator, and -makeType is called many times at load
    CFArrayRef requiredFields = (CFArrayRef)[typeManager requiredFieldsForType:theType];
    CFArrayRef optionalFields = (CFArrayRef)[typeManager optionalFieldsForType:theType];
    CFArrayRef userFields = (CFArrayRef)[typeManager userDefaultFieldsForType:theType];
    
    // current state of this item's pubFields
    CFArrayRef allFields = (CFArrayRef)[self allFieldNames];
    
    CFIndex requiredCount = CFArrayGetCount(requiredFields);
    CFIndex optionalCount = CFArrayGetCount(optionalFields);
    CFIndex userCount = CFArrayGetCount(userFields);
    CFIndex allFieldsCount = CFArrayGetCount(allFields);
    
    // have to retain keys removed from the dictionary, but we know they're strings
    CFSetCallBacks callBacks = { 0, OFCFTypeRetain, OFCFTypeRelease, CFCopyDescription, stringIsEqualToString, CFHash };
    
    // fixed-size mutable set; this needn't be larger than allFieldsCount
    NSMutableSet *emptyFieldsToRemove = (NSMutableSet *)CFSetCreateMutable(CFAllocatorGetDefault(), allFieldsCount, &callBacks);
    NSString *key;
    
    CFIndex idx;
    
    // for each field currently in this publication, check if it's value is an empty string; if so, add to the set of fields to be removed
    for (idx = 0; idx < allFieldsCount; idx++) {
        key = (id)CFArrayGetValueAtIndex(allFields, idx);
        if ([[pubFields objectForKey:key] isEqualAsComplexString:@""])
            [emptyFieldsToRemove addObject:key];
    }        
        
    // see if we have a nil value for any required field; if so, give it an empty value and don't remove it at the end
    for (idx = 0; idx < requiredCount; idx++) {
        fieldString = (id)CFArrayGetValueAtIndex(requiredFields, idx);
        setEmptyStringIfObjectIsNilAndExcludeFromRemoval(fieldString, pubFields, emptyFieldsToRemove);
    }

    // now check the BibTeX-defined optional fields
    for (idx = 0; idx < optionalCount; idx++) {
        fieldString = (id)CFArrayGetValueAtIndex(optionalFields, idx);
        setEmptyStringIfObjectIsNilAndExcludeFromRemoval(fieldString, pubFields, emptyFieldsToRemove);
    }

    // now check all user-defined default fields
    for (idx = 0; idx < userCount; idx++) {
        fieldString = (id)CFArrayGetValueAtIndex(userFields, idx);
        setEmptyStringIfObjectIsNilAndExcludeFromRemoval(fieldString, pubFields, emptyFieldsToRemove);
    }
    
    // I don't enforce Keywords, but since there's GUI depending on them, I will enforce these others as being non-nil:
    setEmptyStringIfObjectIsNilAndExcludeFromRemoval(BDSKLocalUrlString, pubFields, emptyFieldsToRemove);
    setEmptyStringIfObjectIsNilAndExcludeFromRemoval(BDSKUrlString, pubFields, emptyFieldsToRemove);
    setEmptyStringIfObjectIsNilAndExcludeFromRemoval(BDSKAnnoteString, pubFields, emptyFieldsToRemove);
    setEmptyStringIfObjectIsNilAndExcludeFromRemoval(BDSKAbstractString, pubFields, emptyFieldsToRemove);
    setEmptyStringIfObjectIsNilAndExcludeFromRemoval(BDSKRssDescriptionString, pubFields, emptyFieldsToRemove);

    // now remove everything that's left in removeKeys from pubFields, since it's non-standard for this type
    CFSetApplyFunction((CFMutableSetRef)emptyFieldsToRemove, removeItemsInSetFromDictionary, pubFields);
    CFRelease(emptyFieldsToRemove);
}

- (void)typeInfoDidChange:(NSNotification *)aNotification{
	[self makeType];
}

- (void)customFieldsDidChange:(NSNotification *)aNotification{
	[self makeType];
	[groups removeAllObjects];
}

#pragma mark Document

- (id<BDSKOwner>)owner {
    return owner;
}

- (void)setOwner:(id<BDSKOwner>)newOwner {
    if (owner != newOwner) {
		owner = newOwner;
	}
}

- (NSUndoManager *)undoManager { // this may be nil
    return [owner undoManager];
}

// accessors for fileorder
- (NSNumber *)fileOrder{
    return fileOrder;
}

- (void)setFileOrder:(NSNumber *)newOrder{
    if(fileOrder != newOrder){
        [fileOrder release];
        fileOrder = [newOrder retain];
    }
}

- (NSString *)fileType { 
    return fileType;
}

- (void)setFileType:(NSString *)someFileType {
    if(someFileType != fileType){
        [fileType release];
        fileType = [someFileType retain];
    }
}

#pragma mark -
#pragma mark Generic person handling code

- (void)rebuildPeopleIfNeeded{
    
    if (people == nil) {
        
        NSEnumerator *pEnum = [[[BibTypeManager sharedManager] personFieldsSet] objectEnumerator];
        NSString *personStr;
        NSString *personType;
        
        people = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        while(personType = [pEnum nextObject]){
            // get the string representation from pubFields
            personStr = [pubFields objectForKey:personType];
            
            // parse into an array of BibAuthor objects
            NSArray *tmpPeople = [BibTeXParser authorsFromBibtexString:personStr withPublication:self];
            if([tmpPeople count])
                [people setObject:tmpPeople forKey:personType];
        }
        
    }    
}

// this returns a set so it's clear that the objects are unordered
- (NSSet *)allPeople{
    NSArray *allArrays = [[self people] allValues];
    NSMutableSet *set = [NSMutableSet set];
    
    unsigned i = [allArrays count];
    while(i--)
        [set addObjectsFromArray:[allArrays objectAtIndex:i]];
    
    return set;
}

- (int)numberOfPeople{
    return [[self allPeople] count];
}

- (NSArray *)sortedPeople{
    return [[[self allPeople] allObjects] sortedArrayUsingSelector:@selector(sortCompare:)];
}

- (NSArray *)peopleArrayForField:(NSString *)field{
    return [self peopleArrayForField:field inherit:YES];
}

- (NSArray *)peopleArrayForField:(NSString *)field inherit:(BOOL)inherit{
    [self rebuildPeopleIfNeeded];
    
    NSArray *peopleArray = [people objectForKey:field];
    if([peopleArray count] == 0 && inherit){
        BibItem *parent = [self crossrefParent];
        peopleArray = [parent peopleArrayForField:field inherit:NO];
    }
    return (peopleArray != nil) ? peopleArray : [NSArray array];
}

- (NSDictionary *)people{
    return [self peopleInheriting:YES];
}

- (NSDictionary *)peopleInheriting:(BOOL)inherit{
    BibItem *parent;
    
    [self rebuildPeopleIfNeeded];
    
    if(inherit && (parent = [self crossrefParent])){
        NSMutableDictionary *parentCopy = [[[parent peopleInheriting:NO] mutableCopy] autorelease];
        [parentCopy addEntriesFromDictionary:people]; // replace keys in parent with our keys, but inherit keys we don't have
        return parentCopy;
    } else {
        NSDictionary *copy = [[people copy] autorelease];
        return copy;
    }
}

// returns a string similar to bibtexAuthorString, but removes the "and" separator and can optionally abbreviate first names
- (NSString *)peopleStringForDisplayFromField:(NSString *)field{
    
    NSArray *peopleArray = [self peopleArrayForField:field];
    
	if([peopleArray count] == 0)
        return @"";
    
    unsigned idx, count = [peopleArray count];
    BibAuthor *person;
    NSMutableString *names = [NSMutableString stringWithCapacity:10 * count];
	
    for(idx = 0; idx < count; idx++){
        person = [peopleArray objectAtIndex:idx];
        [names appendString:[person displayName]];
        if(idx != count - 1)
            [names appendString:@" and "];
    }
    
	return names;
}

#pragma mark Author Handling code

- (int)numberOfAuthors{
	return [self numberOfAuthorsInheriting:YES];
}

- (int)numberOfAuthorsInheriting:(BOOL)inherit{
    return [[self pubAuthorsInheriting:inherit] count];
}

- (BibAuthor *)firstAuthor{ 
	return [self authorAtIndex:0]; 
}

- (BibAuthor *)secondAuthor{ 
	return [self authorAtIndex:1]; 
}

- (BibAuthor *)thirdAuthor{ 
	return [self authorAtIndex:2]; 
}

- (BibAuthor *)lastAuthor{
    BibAuthor *author = [[self pubAuthors] lastObject];
    return author == nil ? [BibAuthor emptyAuthor] : author;
}

- (NSArray *)pubAuthors{
	return [self pubAuthorsInheriting:YES];
}

- (NSArray *)pubAuthorsInheriting:(BOOL)inherit{
    return [self peopleArrayForField:BDSKAuthorString inherit:inherit];
}

- (NSArray *)pubAuthorsAsStrings{
    return [[self pubAuthors] arrayByPerformingSelector:@selector(normalizedName)];
}

- (NSString *)pubAuthorsForDisplay{
    return [self peopleStringForDisplayFromField:BDSKAuthorString];
}

- (BibAuthor *)authorAtIndex:(unsigned int)index{ 
    return [self authorAtIndex:index inherit:YES];
}

- (BibAuthor *)authorAtIndex:(unsigned int)index inherit:(BOOL)inherit{ 
	NSArray *auths = [self pubAuthorsInheriting:inherit];
	if ([auths count] > index)
        return [auths objectAtIndex:index];
    else
        return [BibAuthor emptyAuthor];
}

- (NSString *)bibTeXAuthorString{
    return [self bibTeXAuthorStringNormalized:NO inherit:YES];
}

// used for save operations; returns names as "von Last, Jr., First" if normalized is YES
- (NSString *)bibTeXAuthorStringNormalized:(BOOL)normalized{ 
	return [self bibTeXAuthorStringNormalized:normalized inherit:YES];
}

// used for save operations; returns names as "von Last, Jr., First" if normalized is YES
- (NSString *)bibTeXAuthorStringNormalized:(BOOL)normalized inherit:(BOOL)inherit{
    return [self bibTeXNameStringForField:BDSKAuthorString normalized:normalized inherit:inherit];
}

- (NSString *)bibTeXNameStringForField:(NSString *)field normalized:(BOOL)normalized inherit:(BOOL)inherit{
	NSArray *peopleArray = [self peopleArrayForField:field inherit:inherit];
    
	if([peopleArray count] == 0)
        return @"";
    
    unsigned idx, count = [peopleArray count];
    BibAuthor *person;
    NSMutableString *names = [NSMutableString stringWithCapacity:10 * count];
	
    for(idx = 0; idx < count; idx++){
        person = [peopleArray objectAtIndex:idx];
        [names appendString:(normalized ? [person normalizedName] : [person name])];
        if(idx != count - 1)
            [names appendString:@" and "];
    }

	return names;
}

- (NSArray *)pubEditors{
    return [self peopleArrayForField:BDSKEditorString];
}

#pragma mark Author or Editor Handling code

- (int)numberOfAuthorsOrEditors{
	return [self numberOfAuthorsOrEditorsInheriting:YES];
}

- (int)numberOfAuthorsOrEditorsInheriting:(BOOL)inherit{
    return [[self pubAuthorsInheriting:inherit] count];
}

- (BibAuthor *)firstAuthorOrEditor{ 
	return [self authorOrEditorAtIndex:0]; 
}

- (BibAuthor *)secondAuthorOrEditor{ 
	return [self authorOrEditorAtIndex:1]; 
}

- (BibAuthor *)thirdAuthorOrEditor{ 
	return [self authorOrEditorAtIndex:2]; 
}

- (BibAuthor *)lastAuthorOrEditor{
    BibAuthor *author = [[self pubAuthorsOrEditors] lastObject];
    return author == nil ? [BibAuthor emptyAuthor] : author;
}

- (NSArray *)pubAuthorsOrEditors{
	return [self pubAuthorsOrEditorsInheriting:YES];
}

- (NSArray *)pubAuthorsOrEditorsInheriting:(BOOL)inherit{
    NSArray *auths = [self peopleArrayForField:BDSKAuthorString inherit:inherit];
    if ([auths count] == 0)
        auths = [self peopleArrayForField:BDSKEditorString inherit:inherit];
    return auths;
}

// returns a string similar to bibtexAuthorString, but removes the "and" separator and can optionally abbreviate first names
- (NSString *)pubAuthorsOrEditorsForDisplay{
    return [self peopleStringForDisplayFromField:([[self peopleArrayForField:BDSKAuthorString] count] ? BDSKAuthorString : BDSKEditorString)];
}

- (BibAuthor *)authorOrEditorAtIndex:(unsigned int)index{ 
    return [self authorOrEditorAtIndex:index inherit:YES];
}

- (BibAuthor *)authorOrEditorAtIndex:(unsigned int)index inherit:(BOOL)inherit{ 
	NSArray *auths = [self pubAuthorsOrEditorsInheriting:inherit];
	if ([auths count] > index)
        return [auths objectAtIndex:index];
    else
        return [BibAuthor emptyAuthor];
}

#pragma mark -
#pragma mark Accessors

- (BibItem *)crossrefParent{
	NSString *key = [self valueOfField:BDSKCrossrefString inherit:NO];
	
	if ([NSString isEmptyString:key])
		return nil;
	
	return [[owner publications] itemForCiteKey:key];
}

// Container is an aspect of the BibItem that depends on the type of the item
// It is used only to have one column to show all these containers.
- (NSString *)container{
	NSString *c;
    NSString *type = [self pubType];
	
	if ( [type isEqualToString:BDSKInbookString]) {
	    c = [self valueOfField:BDSKTitleString];
	} else if ( [type isEqualToString:BDSKArticleString] ) {
		c = [self valueOfField:BDSKJournalString];
	} else if ( [type isEqualToString:BDSKIncollectionString] || 
				[type isEqualToString:BDSKInproceedingsString] ||
				[type isEqualToString:BDSKConferenceString] ) {
		c = [self valueOfField:BDSKBooktitleString];
	} else if ( [type isEqualToString:BDSKCommentedString] ){
		c = [self valueOfField:BDSKVolumetitleString];
	} else if ( [type isEqualToString:BDSKBookString] ){
		c = [self valueOfField:BDSKSeriesString];
	} else {
		c = @""; //Container is empty for non-container types
	}
	// Check to see if the field for Container was empty
	// They are optional for some types
	if (c == nil) {
		c = @"";
	}
    OBPOSTCONDITION(c != nil);
	return c;
}

// this is used for the lower pane
- (NSString *)title{
    NSString *title = [self valueOfField:BDSKTitleString];
	if (title == nil) 
		title = @"";
	if ([[self pubType] isEqualToString:BDSKInbookString]) {
		NSString *chapter = [self valueOfField:BDSKChapterString];
		if (![NSString isEmptyString:chapter]) {
			title = [NSString stringWithFormat:NSLocalizedString(@"%@ (chapter %@)", @"Inbook item title format: [Title of inbook] (chapter [Chapter])"), title, chapter];
		} else {
            NSString *pages = [self valueOfField:BDSKPagesString];
            if (![NSString isEmptyString:pages]) {
                title = [NSString stringWithFormat:NSLocalizedString(@"%@ (pp %@)", @"Inbook item title format: [Title of inbook] (pp [Pages])"), title, pages];
            }
        }
	}
    if ([title isComplex] || [title isInherited])
        title = [NSString stringWithFormat:@"%@", title];
    OBPOSTCONDITION(title != nil);
	return title;
}

// used for the main tableview and other places we don't want a TeX string (window titles)
- (NSString *)displayTitle{
    // -title is always non-nil
	NSString *title = [self title];
	static NSString	*emptyTitle = nil;
	
	if ([@"" isEqualToString:title]) {
		if (emptyTitle == nil)
			emptyTitle = [NSLocalizedString(@"Empty Title", @"Publication display title for empty title") retain];
		title = emptyTitle;
	}
    OBPOSTCONDITION([NSString isEmptyString:title] == NO);
	return [title stringByRemovingTeX];
}

- (void)duplicateTitleToBooktitleOverwriting:(BOOL)overwrite{
	NSString *title = [self valueOfField:BDSKTitleString inherit:NO];
	
	if([NSString isEmptyString:title])
		return;
	
	NSString *booktitle = [self valueOfField:BDSKBooktitleString inherit:NO];
	if(![NSString isEmptyString:booktitle] && !overwrite)
		return;
	[self setField:BDSKBooktitleString toValue:title];
}

- (NSCalendarDate *)date{
    return [self dateInheriting:YES];
}

- (NSCalendarDate *)dateInheriting:(BOOL)inherit{
    BibItem *parent;
	
	if(inherit && pubDate == nil && (parent = [self crossrefParent])) {
		return [parent dateInheriting:NO];
	}
	return pubDate;
}

- (NSCalendarDate *)dateAdded {
    return dateAdded;
}

- (NSCalendarDate *)dateModified {
    return dateModified;
}

- (void)setPubType:(NSString *)newType{
    [self setPubType:newType withModDate:[NSCalendarDate date]];
}

- (void)setPubType:(NSString *)newType withModDate:(NSCalendarDate *)date{
    NSString *oldType = [self pubType];
    
    if ([oldType isEqualToString:newType]) {
		return;
    }
	
	if ([self undoManager]) {
		[[[self undoManager] prepareWithInvocationTarget:self] setPubType:oldType 
															  withModDate:[self dateModified]];
    }
	
	[self setPubTypeWithoutUndo:newType];
	
	if (date != nil) {
		[pubFields setObject:[date description] forKey:BDSKDateModifiedString];
	} else {
		[pubFields removeObjectForKey:BDSKDateModifiedString];
	}
	[self updateMetadataForKey:BDSKPubTypeString];
		
    NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:newType, @"value", BDSKPubTypeString, @"key", @"Change", @"type", owner, @"owner", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
														object:self
													  userInfo:notifInfo];
}

- (NSString *)pubType{
    return pubType;
}

- (unsigned int)rating{
	return [self ratingValueOfField:BDSKRatingString];
}

- (void)setRating:(unsigned int)rating{
    [self setField:BDSKRatingString toRatingValue:rating];
}

- (void)setHasBeenEdited:(BOOL)yn{
    hasBeenEdited = yn;
}

- (BOOL)hasBeenEdited{
    return hasBeenEdited;
}

- (void)setCiteKey:(NSString *)newCiteKey{
    [self setCiteKey:newCiteKey withModDate:[NSCalendarDate date]];
}

- (void)setCiteKey:(NSString *)newCiteKey withModDate:(NSCalendarDate *)date{
    NSString *oldCiteKey = [[self citeKey] retain];

    if ([self undoManager]) {
		[[[self undoManager] prepareWithInvocationTarget:self] setCiteKey:oldCiteKey 
															  withModDate:[self dateModified]];
    }
	
    [self setCiteKeyString:newCiteKey];
	if (date != nil) {
		[pubFields setObject:[date description] forKey:BDSKDateModifiedString];
	} else {
		[pubFields removeObjectForKey:BDSKDateModifiedString];
	}
	[self updateMetadataForKey:BDSKCiteKeyString];
		
    NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:newCiteKey, @"value", BDSKCiteKeyString, @"key", @"Change", @"type", oldCiteKey, @"oldCiteKey", owner, @"owner", nil];

    [[NSFileManager defaultManager] removeSpotlightCacheFileForCiteKey:oldCiteKey];
    [oldCiteKey release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
														object:self
													  userInfo:notifInfo];
}

- (void)setCiteKeyString:(NSString *)newCiteKey{
    // parser doesn't allow empty cite keys
    OBPRECONDITION([NSString isEmptyString:newCiteKey] == NO);
    if(newCiteKey != citeKey){
        [citeKey autorelease];
        citeKey = [newCiteKey copy];
        [[NSApp delegate] addString:newCiteKey forCompletionEntry:BDSKCrossrefString];
    }
}

- (NSString *)citeKey{
    return citeKey;
}

- (NSString *)suggestedCiteKey
{
    NSString *suggestion = [self citeKey];
    if ([self hasEmptyOrDefaultCiteKey] || [[owner publications] citeKeyIsUsed:suggestion byItemOtherThan:self])
        suggestion = nil;
    
	NSString *citeKeyFormat = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCiteKeyFormatKey];
    NSString *ck = [BDSKFormatParser parseFormat:citeKeyFormat forField:BDSKCiteKeyString ofItem:self suggestion:suggestion];
	if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKCiteKeyLowercaseKey]) {
		ck = [ck lowercaseString];
	}
	return ck;
}

- (BOOL)hasEmptyOrDefaultCiteKey{
    NSString *key = [self citeKey];
    return [NSString isEmptyString:key] || [key isEqualToString:BDSKDefaultCiteKey];
}

- (BOOL)canGenerateAndSetCiteKey
{
    NSArray *requiredFields = [[NSApp delegate] requiredFieldsForCiteKey];
    
    // see if it needs to be set (hasEmptyOrDefaultCiteKey)
	if (nil == requiredFields || [self hasEmptyOrDefaultCiteKey] == NO)
		return NO;
	
	NSEnumerator *fEnum = [requiredFields objectEnumerator];
	NSString *fieldName;
    
    // see if we have enough fields to generate it
	while (fieldName = [fEnum nextObject]) {
		if ([fieldName isEqualToString:BDSKAuthorEditorString]) {
			if ([NSString isEmptyString:[self valueOfField:BDSKAuthorString]] && 
				[NSString isEmptyString:[self valueOfField:BDSKEditorString]])
				return NO;
		} else if ([fieldName hasPrefix:@"Document: "]) {
			if ([NSString isEmptyString:[owner documentInfoForKey:[fieldName substringFromIndex:10]]])
				return NO;
		} else {
			if ([NSString isEmptyString:[self valueOfField:fieldName]]) {
				return NO;
			}
		}
	}
	return YES;
}

- (BOOL)isValidCiteKey:(NSString *)proposedCiteKey{
	if ([NSString isEmptyString:proposedCiteKey] == YES)
        return NO;
    return ([[owner publications] citeKeyIsUsed:proposedCiteKey byItemOtherThan:self] == NO);
}

- (int)canSetCrossref:(NSString *)aCrossref andCiteKey:(NSString *)aCiteKey{
    int errorCode = BDSKNoCrossrefError;
    if ([NSString isEmptyString:aCrossref] == NO) {
        if ([aCiteKey caseInsensitiveCompare:aCrossref] == NSOrderedSame)
            errorCode = BDSKSelfCrossrefError;
        else if ([NSString isEmptyString:[[[owner publications] itemForCiteKey:aCrossref] valueOfField:BDSKCrossrefString inherit:NO]] == NO)
            errorCode = BDSKChainCrossrefError;
        else if ([[owner publications] citeKeyIsCrossreffed:aCiteKey])
            errorCode = BDSKIsCrossreffedCrossrefError;
    }
    return errorCode;
}

- (NSString *)citation{
       OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    return [NSString stringWithFormat:@"\\%@%@", [pw stringForKey:BDSKCiteStringKey],
            [pw stringForKey:BDSKCiteStartBracketKey], [self citeKey], [pw stringForKey:BDSKCiteEndBracketKey]];
}

#pragma mark Pub Fields

- (NSDictionary *)pubFields{
    return pubFields;
}

- (NSArray *)allFieldNames{
    return [pubFields allKeys];
}

- (void)setPubFields: (NSDictionary *)newFields{
    if(newFields != pubFields){
        [pubFields release];
        pubFields = [newFields mutableCopy];
        [self updateMetadataForKey:BDSKAllFieldsString];
    }
}

- (void)setFields: (NSDictionary *)newFields{
    NSDictionary *oldFields = [self pubFields];
	if(![newFields isEqualToDictionary:oldFields]){
		if ([self undoManager]) {
			[[[self undoManager] prepareWithInvocationTarget:self] setFields:oldFields];
		}
		
		[self setPubFields:newFields];
		
		NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Add/Del Fields", @"type", owner, @"owner", nil]; // cmh: maybe not the best info, but handled correctly
		[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
															object:self
														  userInfo:notifInfo];
    }
}

- (void)setField: (NSString *)key toValue: (NSString *)value{
	[self setField:key toValue:value withModDate:[NSCalendarDate date]];
}

- (void)setField:(NSString *)key toValue:(NSString *)value withModDate:(NSCalendarDate *)date{
    OBPRECONDITION(key != nil);
    // use a copy of the old value, since this may be a mutable value
    NSString *oldValue = [[pubFields objectForKey:key] copy];
	if ([self undoManager]) {
		NSCalendarDate *oldModDate = [self dateModified];
		
		[[[self undoManager] prepareWithInvocationTarget:self] setField:key 
														 toValue:oldValue
													 withModDate:oldModDate];
	}
    	
    if(value != nil){
		[pubFields setObject:value forKey:key];
		// to allow autocomplete:
		[[NSApp delegate] addString:value forCompletionEntry:key];
	}else{
		[pubFields removeObjectForKey:key];
	}
	if (date != nil) {
		[pubFields setObject:[date description] forKey:BDSKDateModifiedString];
	} else {
		[pubFields removeObjectForKey:BDSKDateModifiedString];
	}
	[self updateMetadataForKey:key];
	
	NSDictionary *notifInfo;
	if(oldValue != nil && value != nil)
		notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:value, @"value", key, @"key", @"Change", @"type", oldValue, @"oldValue", owner, @"owner", nil];
	else
		notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:key, @"key", @"Add/Del Field", @"type", owner, @"owner", nil];
    [oldValue release];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
														object:self
													  userInfo:notifInfo];
}

- (void)setField:(NSString *)key toValueWithoutUndo:(NSString *)value{
    NSParameterAssert(nil != key);
    NSParameterAssert(nil != value);
    // this method is intended as a workaround for a BibEditor issue with using -[NSTextStorage mutableString] to track changes
    OBPRECONDITION([value isEqualToString:[pubFields objectForKey:key]]);
    [pubFields setObject:value forKey:key];
}

- (NSString *)valueOfField: (NSString *)key{
	return [self valueOfField:key inherit:YES];
}

- (NSString *)valueOfField: (NSString *)key inherit: (BOOL)inherit{
    NSString* value = [pubFields objectForKey:key];
	
	if (inherit && BDIsEmptyString((CFStringRef)value)) {
		BibItem *parent = [self crossrefParent];
		if (parent) {
			NSString *parentValue = [parent valueOfField:key inherit:NO];
			if (BDIsEmptyString((CFStringRef)parentValue) == FALSE)
				return [NSString stringWithInheritedValue:parentValue];
		}
	}
	
	return value;
}

- (void)addField:(NSString *)key{
	[self addField:key withModDate:[NSCalendarDate date]];
}

- (void)addField:(NSString *)key withModDate:(NSCalendarDate *)date{
	if ([self undoManager]) {
		[[[self undoManager] prepareWithInvocationTarget:self] removeField:key
														withModDate:[self dateModified]];
	}
	
	NSString *defaultValue = nil;
	if ([key isBooleanField] || [key isTriStateField] || [key isRatingField]) {
        defaultValue = @"";
    } else {
        defaultValue = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Add data for field:", @"Default value for new field"), key];
    }
    [self setField:key toValue:defaultValue];
	
	if (date != nil) {
		[pubFields setObject:[date description] forKey:BDSKDateModifiedString];
	} else {
		[pubFields removeObjectForKey:BDSKDateModifiedString];
	}
	[self updateMetadataForKey:key];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:key, @"key", @"Add/Del Field", @"type", owner, @"owner", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
														object:self
													  userInfo:notifInfo];

}

- (void)removeField: (NSString *)key{
	[self removeField:key withModDate:[NSCalendarDate date]];
}

- (void)removeField: (NSString *)key withModDate:(NSCalendarDate *)date{
	
    OBPRECONDITION(key != nil);
    
	if ([self undoManager]) {
        if(![NSString isEmptyString:[pubFields objectForKey:key]])
            // this will ensure that the current value can be restored when the user deletes a non-empty field
            [self setField:key toValue:@""];
        
		[[[self undoManager] prepareWithInvocationTarget:self] addField:key
                                                            withModDate:[self dateModified]];
	}
	
    [pubFields removeObjectForKey:key];
	
	if (date != nil) {
		[pubFields setObject:[date description] forKey:BDSKDateModifiedString];
	} else {
		[pubFields removeObjectForKey:BDSKDateModifiedString];
	}
	[self updateMetadataForKey:key];

	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Add/Del Field", @"type", owner, @"owner", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
														object:self
													  userInfo:notifInfo];
	
}

#pragma mark Derived field values

- (id)valueForUndefinedKey:(NSString *)key{
    return [self stringValueOfField:key];
}

- (NSString *)stringValueOfField:(NSString *)field {
	return [self stringValueOfField:field inherit:YES];
}

- (NSString *)stringValueOfField:(NSString *)field inherit:(BOOL)inherit {
		
	if([field isRatingField]){
		return [NSString stringWithFormat:@"%i", [self ratingValueOfField:field]];
	}else if([field isBooleanField]){
		return [NSString stringWithBool:[self boolValueOfField:field]];
    }else if([field isTriStateField]){
		return [NSString stringWithTriStateValue:[self triStateValueOfField:field]];
    }else if([field isCitationField]){
		return [self valueOfField:field inherit:NO];
	}else if([field isEqualToString:BDSKPubTypeString]){
		return [self pubType];
	}else if([field isEqualToString:BDSKCiteKeyString]){
		return [self citeKey];
	}else if([field isEqualToString:BDSKAllFieldsString]){
        return [self allFieldsString];
    }else{
		return [self valueOfField:field inherit:inherit];
    }
}

- (void)setField:(NSString *)field toStringValue:(NSString *)value{
    OBASSERT([field isEqualToString:BDSKAllFieldsString] == NO);
	
	if([field isBooleanField]){
		[self setField:field toBoolValue:[value booleanValue]];
    }else if([field isTriStateField]){
        [self setField:field toTriStateValue:[value triStateValue]];
	}else if([field isRatingField]){
		[self setField:field toRatingValue:[value intValue]];
	}else if([field isEqualToString:BDSKPubTypeString]){
		[self setPubType:value];
	}else if([field isEqualToString:BDSKCiteKeyString]){
		[self setCiteKey:value];
	}else{
		[self setField:field toValue:value];
	}
}

- (int)intValueOfField:(NSString *)field {
		
	if([field isRatingField]){
		return [self ratingValueOfField:field];
	}else if([field isBooleanField]){
		return (int)[self boolValueOfField:field];
    }else if([field isTriStateField]){
		return (int)[self triStateValueOfField:field];
	}else{
		return [NSString isEmptyString:[self valueOfField:field]] ? 0 : 1;
    }
}

- (int)ratingValueOfField:(NSString *)field{
    return [[self valueOfField:field inherit:NO] intValue];
}

- (void)setField:(NSString *)field toRatingValue:(unsigned int)rating{
	if (rating > 5)
		rating = 5;
	[self setField:field toValue:[NSString stringWithFormat:@"%i", rating]];
}

- (BOOL)boolValueOfField:(NSString *)field{
    // stored as a string
	return [[self valueOfField:field inherit:NO] booleanValue];
}

- (void)setField:(NSString *)field toBoolValue:(BOOL)boolValue{
	[self setField:field toValue:[NSString stringWithBool:boolValue]];
}

- (NSCellStateValue)triStateValueOfField:(NSString *)field{
	return [[self valueOfField:field inherit:NO] triStateValue];
}

- (void)setField:(NSString *)field toTriStateValue:(NSCellStateValue)triStateValue{
	if(![[self allFieldNames] containsObject:field])
		[self addField:field];
	[self setField:field toValue:[NSString stringWithTriStateValue:triStateValue]];
}

- (id)displayValueOfField:(NSString *)field{
    static NSDateFormatter *shortDateFormatter = nil;
    if(shortDateFormatter == nil) {
        shortDateFormatter = [[NSDateFormatter alloc] init];
        [shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [shortDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    
    if([field isEqualToString:BDSKCiteKeyString]){
        return [self citeKey];
    }else if([field isEqualToString:BDSKItemNumberString]){
        return [self fileOrder];
    }else if([field isEqualToString: BDSKTitleString] ){
        return [self displayTitle];
    }else if([field isEqualToString: BDSKContainerString] ){
        return [self container];
    }else if([field isEqualToString: BDSKDateAddedString]){
        return [shortDateFormatter stringFromDate:[self dateAdded]];
    }else if([field isEqualToString: BDSKDateModifiedString]){
        return [shortDateFormatter stringFromDate:[self dateModified]];
    }else if([field isEqualToString: BDSKPubDateString] ){
        NSCalendarDate *date = [self date];
        if(nil == date) 
            return nil;
        NSString *monthStr = [self valueOfField:BDSKMonthString];
        if([NSString isEmptyString:monthStr])
            return [date descriptionWithCalendarFormat:@"%Y"];
        else
            return [date descriptionWithCalendarFormat:@"%b %Y"];
    }else if([field isEqualToString: BDSKFirstAuthorString] ){
        return [[self authorAtIndex:0] displayName];
    }else if([field isEqualToString: BDSKSecondAuthorString] ){
        return [[self authorAtIndex:1] displayName]; 
    }else if([field isEqualToString: BDSKThirdAuthorString] ){
        return [[self authorAtIndex:2] displayName];
    }else if([field isEqualToString:BDSKLastAuthorString] ){
        return [[self lastAuthor] displayName];
    }else if([field isEqualToString: BDSKFirstAuthorEditorString] ){
        return [[self authorOrEditorAtIndex:0] displayName];
    }else if([field isEqualToString: BDSKSecondAuthorEditorString] ){
        return [[self authorOrEditorAtIndex:1] displayName]; 
    }else if([field isEqualToString: BDSKThirdAuthorEditorString] ){
        return [[self authorOrEditorAtIndex:2] displayName];
    }else if([field isEqualToString:BDSKLastAuthorEditorString] ){
        return [[self lastAuthorOrEditor] displayName];
    } else if([field isPersonField]) {
        return [self peopleStringForDisplayFromField:field];
    } else if([field isEqualToString:BDSKAuthorEditorString]){
        return [self pubAuthorsOrEditorsForDisplay];
    }else if([field isURLField]){
        return [self smallImageForURLField:field];
    }else if([field isRatingField]){
        return [NSNumber numberWithInt:[self ratingValueOfField:field]];
    }else if([field isBooleanField]){
        return [NSNumber numberWithBool:[self boolValueOfField:field]];
    }else if([field isTriStateField]){
        return [NSNumber numberWithInt:[self triStateValueOfField:field]];
    }else if([field isCitationField]){
        return [self valueOfField:field inherit:NO];
    }else if([field isEqualToString:BDSKPubTypeString]){
        return [self pubType];
    }else if([field isEqualToString:BDSKImportOrderString]){
        return nil;
    }else{
        // the tableColumn isn't something we handle in a custom way.
        return [self valueOfField:field];
    }
}

#pragma mark Search support

- (NSString *)calendarDateDescription{
	return [[self date] descriptionWithCalendarFormat:BDSKDocumentFormatForSearchingDates];
}

// These accessors are wrappers used for searching.  Getting this right is tricky; the main tableview datasource uses NSShortDateFormatString, but the attributed preview uses NSDateFormatString.  Hence, we need to parse the date string on search input for comparison.
- (NSString *)calendarDateModifiedDescription{
    return [[self dateModified] descriptionWithCalendarFormat:BDSKDocumentFormatForSearchingDates];
}

- (NSString *)calendarDateAddedDescription{
	return [[self dateAdded] descriptionWithCalendarFormat:BDSKDocumentFormatForSearchingDates];
}

static inline 
Boolean stringContainsLossySubstring(NSString *theString, NSString *stringToFind, unsigned options, Boolean lossy)
{    
    if(BDIsEmptyString((CFStringRef)theString))
        return FALSE;
    
    CFMutableStringRef mutableCopy = CFStringCreateMutableCopy(CFAllocatorGetDefault(), 0, (CFStringRef)theString);
    BDDeleteCharactersInCharacterSet(mutableCopy, (CFCharacterSetRef)[NSCharacterSet curlyBraceCharacterSet]);
    
    if(lossy){
        CFStringNormalize(mutableCopy, kCFStringNormalizationFormD);
        BDDeleteCharactersInCharacterSet(mutableCopy, CFCharacterSetGetPredefined(kCFCharacterSetNonBase));
    }
    
    Boolean found = CFStringFindWithOptions(mutableCopy, (CFStringRef)stringToFind, CFRangeMake(0, CFStringGetLength(mutableCopy)), options, NULL);
    
    CFRelease(mutableCopy);
    return found;
}

- (BOOL)matchesSubstring:(NSString *)substring withOptions:(unsigned)searchOptions inField:(NSString *)field removeDiacritics:(BOOL)flag;
{
    SEL selector = (void *)CFDictionaryGetValue(selectorTable, (CFStringRef)field);
    if(NULL == selector){
        
        if([field isBooleanField]){
            return [self boolValueOfField:field] == [substring booleanValue];
        } else if([field isTriStateField]){
            return [self triStateValueOfField:field] == [substring triStateValue];
        } else if([field isRatingField]){
            return [self ratingValueOfField:field] == [substring intValue];
        }
    }

    // must be a string of some kind...
    NSString *value = NULL == selector ? [self stringValueOfField:field] : [self performSelector:selector];
    return stringContainsLossySubstring(value, substring, searchOptions, flag);
}

- (NSDictionary *)searchIndexInfo{
    NSSet *urlFields = [[BibTypeManager sharedManager] localFileFieldsSet];
    NSEnumerator *fieldEnumerator = [urlFields objectEnumerator];
    NSString *urlFieldName = nil;
    
    // create an array of all local-URLs this object could have
    NSMutableArray *urls = [[NSMutableArray alloc] initWithCapacity:5];
    while(urlFieldName = [fieldEnumerator nextObject]){
        NSURL *aURL = [self URLForField:urlFieldName];
        if(aURL) [urls addObject:aURL];
    }
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[self citeKey], @"citeKey", [self displayTitle], @"title", urls, @"urls", nil];
    [urls release];
    return info;
}

- (NSDictionary *)metadataCacheInfoForUpdate:(BOOL)update{
    
    // if we're updating, we only return if something changed
    if (update && NO == spotlightMetadataChanged)
        return nil;
    
    // signify that this item is now current
    spotlightMetadataChanged = NO;
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:11];
    NSString *value;
    NSArray *array;
    NSDate *date;
    unsigned int rating;
    
    if(value = [self citeKey])
        [info setObject:value forKey:@"net_sourceforge_bibdesk_citekey"];
    
    [info setObject:@"BibDesk" forKey:(NSString *)kMDItemCreator];

    // A given item is not guaranteed to have all of these, so make sure they are non-nil
    if(value = [self displayTitle])
        [info setObject:value forKey:(NSString *)kMDItemTitle];
    
    // this is what shows up in search results
    [info setObject:value ? value : @"Unknown" forKey:(NSString *)kMDItemDisplayName];

    [info setObject:[self pubAuthorsAsStrings] forKey:(NSString *)kMDItemAuthors];

    if(value = [[self valueOfField:BDSKAbstractString] stringByRemovingTeX])
        [info setObject:value forKey:(NSString *)kMDItemDescription];
    
    if(value = [[self container] stringByRemovingTeX])
        [info setObject:value forKey:@"net_sourceforge_bibdesk_container"];
    
    if(value = [self pubType])
        [info setObject:value forKey:@"net_sourceforge_bibdesk_pubtype"];
    
    if(date = [self date])
        [info setObject:date forKey:@"net_sourceforge_bibdesk_publicationdate"];

    if(date = [self dateModified])
        [info setObject:date forKey:(NSString *)kMDItemContentModificationDate];

    if(date = [self dateAdded])
        [info setObject:date forKey:(NSString *)kMDItemContentCreationDate];

    // keywords is supposed to be a CFArray type, so we'll use the group splitting code
    if(array = [[self groupsForField:BDSKKeywordsString] allObjects])
        [info setObject:array forKey:(NSString *)kMDItemKeywords];

    if(rating = [self rating])
        [info setObject:[NSNumber numberWithInt:rating] forKey:(NSString *)kMDItemStarRating];

    // properly supporting tri-state fields will need a new key of type CFNumber; it will only show up as a number in get info, though, which is not particularly useful
    if([BDSKReadString isBooleanField])
        [info setObject:(id)([self boolValueOfField:BDSKReadString] ? kCFBooleanTrue : kCFBooleanFalse) forKey:@"net_sourceforge_bibdesk_itemreadstatus"];
    else if([BDSKReadString isTriStateField])
        [info setObject:(id)([self triStateValueOfField:BDSKReadString] == NSOnState ? kCFBooleanTrue : kCFBooleanFalse) forKey:@"net_sourceforge_bibdesk_itemreadstatus"];

    // kMDItemWhereFroms is the closest we get to a URL field, so add our standard fields if available
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:2];

    if(value = [[self URLForField:BDSKUrlString] absoluteString]) 
        [mutableArray addObject:value];
    if(value = [[self localFileURLForField:BDSKLocalUrlString] absoluteString])
        [mutableArray addObject:value];

    [info setObject:mutableArray forKey:(NSString *)kMDItemWhereFroms];
    [mutableArray release];
    
    return info;
}

// return a KVC-compliant object; may not be a dictionary in future
- (id)completionObject{
    
    // !!! when adding more keys, update BDSKCompletionServerProtocol.h
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
    [dict setObject:[self citeKey] forKey:@"citeKey"];
    // displayTitle removes TeX
    [dict setObject:[self displayTitle] forKey:@"title"];
    [dict setObject:[NSNumber numberWithInt:[self numberOfAuthorsOrEditors]] forKey:@"numberOfNames"];
    
    // now some optional keys that may be useful, but aren't guaranteed
    id value = [[[self firstAuthorOrEditor] fullLastName] stringByRemovingTeX];
    if (value)
        [dict setObject:value forKey:@"lastName"];
    
    value = [[self firstAuthorOrEditor] sortableName];
    if (value)
        [dict setObject:value forKey:@"sortableName"];
    
    // passing this as an NSString causes a "more significant bytes than room to hold them" exception in the client
    value = [self valueOfField:BDSKYearString];
    if([NSString isEmptyString:value] == NO &&
        (value = [NSNumber numberWithInt:[value intValue]]))
    [dict setObject:value forKey:@"year"];
    
    return dict;
}    

#pragma mark -
#pragma mark BibTeX strings

- (NSString *)bibTeXStringDroppingInternal:(BOOL)drop texify:(BOOL)shouldTeXify{
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
	NSMutableSet *knownKeys = nil;
	NSSet *urlKeys = nil;
	NSString *field;
    NSString *value;
    NSMutableString *s = [NSMutableString stringWithCapacity:200];
    NSMutableArray *keys = [[self allFieldNames] mutableCopy];
	NSEnumerator *e;
    
    BibTypeManager *btm = [BibTypeManager sharedManager];
    NSString *type = [self pubType];
    NSAssert1(type != nil, @"Tried to use a nil pubtype in %@.  You will need to quit and relaunch BibDesk after fixing the error manually.", self );
	[keys sortUsingSelector:@selector(caseInsensitiveCompare:)];
	if ([pw boolForKey:BDSKSaveAnnoteAndAbstractAtEndOfItemKey]) {
		NSMutableArray *noteKeys = [[[btm noteFieldsSet] allObjects] mutableCopy];
        [noteKeys sortUsingSelector:@selector(caseInsensitiveCompare:)];
        [keys removeObjectsInArray:noteKeys]; // make sure these fields are at the end, as they can be long
		[keys addObjectsFromArray:noteKeys];
        [noteKeys release];
	}
	if (drop) {
        knownKeys = [[NSMutableSet alloc] initWithCapacity:14];
		[knownKeys addObjectsFromArray:[btm requiredFieldsForType:type]];
		[knownKeys addObjectsFromArray:[btm optionalFieldsForType:type]];
		[knownKeys addObject:BDSKCrossrefString];
	}
	if(shouldTeXify)
        urlKeys = [[BibTypeManager sharedManager] allURLFieldsSet];
	
	e = [keys objectEnumerator];
	[keys release];

    //build BibTeX entry:
    [s appendString:@"@"];
    
    [s appendString:type];
    [s appendString:@"{"];
    [s appendString:[self citeKey]];
    
    NSSet *personFields = [btm personFieldsSet];
    
    while(field = [e nextObject]){
        if (drop && ![knownKeys containsObject:field])
            continue;
        
        value = [pubFields objectForKey:field];
        
        if([personFields containsObject:field] && [pw boolForKey:BDSKShouldSaveNormalizedAuthorNamesKey] && ![value isComplex]){ // only if it's not complex, use the normalized author name
            value = [self bibTeXNameStringForField:field normalized:YES inherit:NO];
        }
        
        if(shouldTeXify && ![urlKeys containsObject:field]){
            value = [value stringByTeXifyingString];
        }                
        
        if(![value isEqualToString:@""]){
            [s appendString:@",\n\t"];
            [s appendString:field];
            [s appendString:@" = "];
            [s appendString:[value stringAsBibTeXString]];
        }
    }
    [knownKeys release];
    [s appendString:@"}"];
    
    return s;
}

- (NSData *)bibTeXDataDroppingInternal:(BOOL)drop encoding:(NSStringEncoding)encoding error:(NSError **)outError{
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    BOOL shouldTeXify = [pw boolForKey:BDSKShouldTeXifyWhenSavingAndCopyingKey];
	NSMutableSet *knownKeys = nil;
	NSSet *urlKeys = nil;
	NSString *field;
    NSString *value;
    NSMutableData *data = [NSMutableData dataWithCapacity:200];
    NSMutableArray *keys = [[self allFieldNames] mutableCopy];
	NSEnumerator *e;
    NSError *error= nil;
    BOOL isOK = YES;
    
    BibTypeManager *btm = [BibTypeManager sharedManager];
    NSString *type = [self pubType];
    NSAssert1(type != nil, @"Tried to use a nil pubtype in %@.  You will need to quit and relaunch BibDesk after fixing the error manually.", self );
	[keys sortUsingSelector:@selector(caseInsensitiveCompare:)];
	if ([pw boolForKey:BDSKSaveAnnoteAndAbstractAtEndOfItemKey]) {
		NSMutableArray *noteKeys = [[[btm noteFieldsSet] allObjects] mutableCopy];
        [noteKeys sortUsingSelector:@selector(caseInsensitiveCompare:)];
        [keys removeObjectsInArray:noteKeys]; // make sure these fields are at the end, as they can be long
		[keys addObjectsFromArray:noteKeys];
        [noteKeys release];
	}
	if (drop) {
        knownKeys = [[NSMutableSet alloc] initWithCapacity:14];
		[knownKeys addObjectsFromArray:[btm requiredFieldsForType:type]];
		[knownKeys addObjectsFromArray:[btm optionalFieldsForType:type]];
		[knownKeys addObject:BDSKCrossrefString];
	}
	if(shouldTeXify)
        urlKeys = [[BibTypeManager sharedManager] allURLFieldsSet];
	
	e = [keys objectEnumerator];
	[keys release];

    //build BibTeX entry:
    isOK = [data appendDataFromString:@"@" encoding:encoding error:&error] &&
           [data appendDataFromString:type encoding:encoding error:&error] &&
           [data appendDataFromString:@"{" encoding:encoding error:&error] &&
           [data appendDataFromString:[self citeKey] encoding:encoding error:&error];
    if(isOK == NO)
        [error setValue:[NSString stringWithFormat:NSLocalizedString(@"Unable to convert cite key of item with cite key \"%@\".", @"string encoding error context"), [self citeKey]] forKey:NSLocalizedRecoverySuggestionErrorKey];
    
    NSSet *personFields = [btm personFieldsSet];
    
    while(isOK && (field = [e nextObject])){
        if (drop && ![knownKeys containsObject:field])
            continue;
        
        value = [pubFields objectForKey:field];
        NSString *valString;
        
        if([personFields containsObject:field] && [pw boolForKey:BDSKShouldSaveNormalizedAuthorNamesKey] && ![value isComplex]){ // only if it's not complex, use the normalized author name
            value = [self bibTeXNameStringForField:field normalized:YES inherit:NO];
        }
        
        if(shouldTeXify && ![urlKeys containsObject:field]){
            value = [value stringByTeXifyingString];
        }                
        
        valString = [value stringAsBibTeXString];
        
        if(NO == [value isEqualToString:@""]){
            isOK = [data appendDataFromString:@",\n\t" encoding:encoding error:&error] &&
                   [data appendDataFromString:field encoding:encoding error:&error] &&
                   [data appendDataFromString:@" = " encoding:encoding error:&error] &&
                   [data appendDataFromString:valString encoding:encoding error:&error];
            if(isOK == NO)
                [error setValue:[NSString stringWithFormat:NSLocalizedString(@"Unable to convert field \"%@\" of item with cite key \"%@\".", @"string encoding error context"), [field localizedFieldName], [self citeKey]] forKey:NSLocalizedRecoverySuggestionErrorKey];
        }
    }
    [knownKeys release];
    if(isOK)
        isOK = [data appendDataFromString:@"}" encoding:encoding error:&error];
    
    if(isOK == NO && outError)
        *outError = error;
    
    return isOK ? data : nil;
}

- (NSString *)bibTeXStringDroppingInternal:(BOOL)drop{
    BOOL shouldTeXify = [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldTeXifyWhenSavingAndCopyingKey];
    return [self bibTeXStringDroppingInternal:drop texify:shouldTeXify];
}

- (NSString *)bibTeXString{
	return [self bibTeXStringDroppingInternal:NO];
}

#pragma mark Other text representations

- (NSData *)RTFValue{
    NSAttributedString *aStr = [self attributedStringValue];
    return [aStr RTFFromRange:NSMakeRange(0,[aStr length]) documentAttributes:nil];
}

- (NSAttributedString *)attributedStringValue{
    NSString *key;
        NSEnumerator *e = [[[self allFieldNames] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
    NSDictionary *cachedFonts = [[NSFontManager sharedFontManager] cachedFontsForPreviewPane];

    NSDictionary *titleAttributes =
        [[NSDictionary alloc]  initWithObjectsAndKeys:[cachedFonts objectForKey:@"Title"], NSFontAttributeName, 
												      keyParagraphStyle, NSParagraphStyleAttributeName, nil];

    NSDictionary *typeAttributes =
        [[NSDictionary alloc]  initWithObjectsAndKeys:[cachedFonts objectForKey:@"Type"], NSFontAttributeName, 
		                                              [NSColor colorWithCalibratedWhite:0.4 alpha:1.0], NSForegroundColorAttributeName, nil];

    NSDictionary *keyAttributes =
        [[NSDictionary alloc]  initWithObjectsAndKeys:[cachedFonts objectForKey:@"Key"], NSFontAttributeName, 
												      keyParagraphStyle, NSParagraphStyleAttributeName, nil];

    NSDictionary *bodyAttributes =
        [[NSDictionary alloc]  initWithObjectsAndKeys:[cachedFonts objectForKey:@"Body"], NSFontAttributeName, 
												      bodyParagraphStyle, NSParagraphStyleAttributeName, nil];

    NSMutableAttributedString* reqStr = [[NSMutableAttributedString alloc] init];
    NSMutableAttributedString* nonReqStr = [[NSMutableAttributedString alloc] init];
	NSAttributedString *valueStr;
    
	NSSet *reqKeys = [[NSSet alloc] initWithArray:[[BibTypeManager sharedManager] requiredFieldsForType:[self pubType]]];

    static NSDateFormatter *dateFormatter = nil;
    if(dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterFullStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    
    [reqStr appendString:[self citeKey] attributes:typeAttributes];
    [reqStr appendString:@"\n"];

    // make sure we don't use -displayTitle here
    valueStr = [[NSAttributedString alloc] initWithTeXString:[self title]
                                                  attributes:titleAttributes
                                          collapseWhitespace:YES];
    [reqStr appendAttributedString:valueStr];
    [valueStr release];

    [reqStr appendString:[NSString stringWithFormat:@" (%@)\n",[self pubType]] attributes:typeAttributes];

    NSCalendarDate *date = nil;
    NSString *stringValue = nil;
    BOOL notNote = NO;
    
    while(key = [e nextObject]){
		notNote = ![key isNoteField];
        stringValue = [self valueOfField:key inherit:notNote];
        
        if(![stringValue isEqualToString:@""] &&
           ![key isEqualToString:BDSKTitleString]){
			
			valueStr = nil;
			
			if([key isEqualToString:BDSKDateAddedString]){
                if((date = [self dateAdded]) && (stringValue = [dateFormatter stringForObjectValue:date]))
                    valueStr = [[NSAttributedString alloc] initWithString:stringValue
                                                               attributes:bodyAttributes];
                
            }else if([key isEqualToString:BDSKDateModifiedString]){
                if((date = [self dateModified]) && (stringValue = [dateFormatter stringForObjectValue:date]))
                    valueStr = [[NSAttributedString alloc] initWithString:stringValue
                                                               attributes:bodyAttributes];
                
			}else if([key isPersonField]){
				if((stringValue = [self peopleStringForDisplayFromField:key]))
                    valueStr = [[NSAttributedString alloc] initWithString:stringValue
                                                               attributes:bodyAttributes];
                
			}else if([key isURLField] || [key hasPrefix:@"Url"] /* Url1, Url2...UrlN can come from parsers */){
                // make this a clickable link if possible, showing an abbreviated path for file URLs
                NSURL *theURL = [self URLForField:key];
				if(theURL != nil){
                    valueStr = [[NSMutableAttributedString alloc] initWithString:([theURL isFileURL] ? [[theURL path] stringByAbbreviatingWithTildeInPath] : stringValue) attributes:bodyAttributes];
                    [(NSMutableAttributedString *)valueStr addAttribute:NSLinkAttributeName value:theURL range:NSMakeRange(0, [valueStr length])];
                }
  
			}else if([key isEqualToString:BDSKRatingString]){
				int rating = [self ratingValueOfField:BDSKRatingString];
				valueStr = [[NSAttributedString alloc] initWithString:[NSString ratingStringWithInteger:rating]
														   attributes:bodyAttributes];                
			}else if([key isEqualToString:BDSKPagesString]){
                valueStr = [[NSAttributedString alloc] initWithString:[stringValue stringByConvertingDoubleHyphenToEndash]
                                                           attributes:bodyAttributes];
            }else{
                valueStr = [[NSAttributedString alloc] initWithTeXString:stringValue
                                                              attributes:bodyAttributes
                                                      collapseWhitespace:notNote];
			}
			
                       
            // the valueStr will be an empty NSConcreteAttributedString if created with a nil argument, so we check for nil before creating it
			if(valueStr){
				
                if([reqKeys containsObject:key]){
					
					[reqStr appendString:key attributes:keyAttributes];
					[reqStr appendString:@"\n"];
					[reqStr appendAttributedString:valueStr];
					[reqStr appendString:@"\n"];
					
				}else{
					
					[nonReqStr appendString:key attributes:keyAttributes];
					[nonReqStr appendString:@"\n"];
					[nonReqStr appendAttributedString:valueStr];
					[nonReqStr appendString:@"\n"];
					
				}
                
				[valueStr release];
			}
        }
    }

    // now put them together
	[reqStr appendAttributedString:nonReqStr];
	[reqStr appendString:@" "];
	[nonReqStr release];
    [titleAttributes release];
    [typeAttributes release];
    [keyAttributes release];
    [bodyAttributes release];
    [reqKeys release];
    return 	[reqStr autorelease];
}

- (NSString *)RISStringValue{
    NSString *k;
    NSString *v;
    NSMutableString *s = [[[NSMutableString alloc] init] autorelease];
    NSMutableArray *keys = [[self allFieldNames] mutableCopy];
	BOOL hasAU = [keys containsObject:@"AU"];
    [keys sortUsingSelector:@selector(caseInsensitiveCompare:)];
    [keys removeObject:BDSKDateAddedString];
    [keys removeObject:BDSKDateModifiedString];
    [keys removeObject:BDSKLocalUrlString];

    BibTypeManager *btm = [BibTypeManager sharedManager];
    
    // get the type, which may exist in pubFields if this was originally an RIS import; we must have only _one_ TY field,
    // since they mark the beginning of each entry
    NSString *risType = nil;
    if(risType = [self valueOfField:@"TY" inherit:NO])
        [keys removeObject:@"TY"];
    else if(risType = [self valueOfField:@"PT" inherit:NO]) // Medline RIS
        [keys removeObject:@"PT"];
    else
        risType = [btm RISTypeForBibTeXType:[self pubType]];
    
    // enumerate the remaining keys
    NSEnumerator *e = [keys objectEnumerator];
	NSString *tag;
	NSArray *auths;
	[keys release];
    
	if([keys containsObject:@"PMID"]){
		[s appendFormat:@"PMID- %@\n", risType];
        [keys removeObject:@"PMID"];
	}
	
    [s appendFormat:@"TY  - %@\n", risType];
    
    while(k = [e nextObject]){
		tag = [btm RISTagForBibTeXFieldName:k];
        v = [self valueOfField:k inherit:NO];
        
        if([k isEqualToString:BDSKAuthorString]){
			// if we also have an AU field, we use the FAU tag, otherwise we use AU
			tag = (hasAU ? @"FAU" : @"AU ");
            auths = [v componentsSeparatedByString:@" and "];
			v = [auths componentsJoinedByString:[NSString stringWithFormat:@"\n%@ - ", tag]];
        }else if([k isEqualToString:@"AU"] || [k isEqualToString:BDSKEditorString]){
            auths = [v componentsSeparatedByString:@" and "];
			v = [auths componentsJoinedByString:[NSString stringWithFormat:@"\n%@  - ", tag]];
        }else if([k isEqualToString:BDSKKeywordsString]){
			NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
            NSCharacterSet *sepCharSet = [btm separatorCharacterSetForField:BDSKKeywordsString];
			if([v rangeOfCharacterFromSet:sepCharSet].location != NSNotFound) {
				NSScanner *wordScanner = [NSScanner scannerWithString:v];
				[wordScanner setCharactersToBeSkipped:nil];
				
				while(![wordScanner isAtEnd]) {
					if([wordScanner scanUpToCharactersFromSet:sepCharSet intoString:&v])
						[arr addObject:v];
					[wordScanner scanCharactersFromSet:sepCharSet intoString:nil];
				}
				v = [arr componentsJoinedByString:[NSString stringWithFormat:@"\n%@  - ", tag]];
			}
        }
        
		if(![v isEqualToString:@""]){
			[s appendString:tag];
			if([tag length] == 2)
				[s appendString:@"  - "];
			else if([tag length] == 3)
				[s appendString:@" - "];
			else
				[s appendString:@"- "];
            [s appendString:[v stringByRemovingTeX]]; // this won't help with math, but removing $^_ is probably not a good idea
			[s appendString:@"\n"];
		}
    }
    [s appendString:@"ER  - \n"];
    return s;
}

#define AddXMLField(t,f) value = [self valueOfField:f]; if ([NSString isEmptyString:value] == NO) [s appendFormat:@"<%@>%@</%@>", t, [value stringByEscapingBasicXMLEntitiesUsingUTF8], t]

- (NSString *)MODSString{
    NSDictionary *genreForTypeDict = [[BibTypeManager sharedManager] MODSGenresForBibTeXType:[self pubType]];
    NSMutableString *s = [NSMutableString stringWithString:@"<mods>\n"];
    unsigned i = 0;
    NSString *value;
    
    [s appendString:@"<titleInfo>\n"];
    AddXMLField(@"title",BDSKTitleString);
    [s appendString:@"\n</titleInfo>\n"];
    // note: may in the future want to output subtitles.

    NSArray *pubAuthors = [self pubAuthors];
    
    foreach (author, pubAuthors){
        [s appendString:[author MODSStringWithRole:BDSKAuthorString]];
        [s appendString:@"\n"];
    }

    // NOTE: this isn't always text. what are the special case pubtypes?
    [s appendString:@"<typeOfResource>text</typeOfResource>\n"];
    
    NSArray *genresForSelf = [genreForTypeDict objectForKey:@"self"];
    if(genresForSelf){
        for(i = 0; i < [genresForSelf count]; i++){
            [s appendStrings:@"<genre>", [genresForSelf objectAtIndex:i], @"</genre>\n", nil];
        }
    }

    // HOST INFO
    NSArray *genresForHost = [genreForTypeDict objectForKey:@"host"];
    if(genresForHost){
        [s appendString:@"<relatedItem type=\"host\">\n"];
        
        NSString *hostTitle = nil;
        NSString *type = [self pubType];
        
        if([type isEqualToString:BDSKInproceedingsString] || 
           [type isEqualToString:BDSKIncollectionString]){
            hostTitle = [self valueOfField:BDSKBooktitleString];
        }else if([type isEqualToString:BDSKArticleString]){
            hostTitle = [self valueOfField:BDSKJournalString];
        }
        hostTitle = [hostTitle stringByEscapingBasicXMLEntitiesUsingUTF8];
        [s appendString:@"<titleInfo>\n"];
        AddXMLField(@"title",hostTitle);
        [s appendString:@"\n</titleInfo>\n"];
        
        [s appendString:@"</relatedItem>\n"];
    }

    [s appendStrings:@"<identifier type=\"citekey\">", [[self citeKey] stringByEscapingBasicXMLEntitiesUsingUTF8], @"</identifier>\n", nil];
    
    [s appendString:@"</mods>"];
    return s;
}

- (NSString *)endNoteString{
    NSMutableString *s = [NSMutableString stringWithString:@"<record>"];
    NSString *value;
    
    NSString *fileName = [[[self owner] fileURL] path];
    
    int refTypeID;
    NSString *entryType = [self pubType];
    NSString *publisherField = BDSKPublisherString;
    NSString *organizationField = @"Organization";
    NSString *authorField = BDSKAuthorString;
    NSString *editorField = BDSKEditorString;
    NSString *isbnField = @"Isbn";
    NSString *numberField = BDSKNumberString;
    NSString *booktitleField = BDSKBooktitleString;
    
    // EndNote officially does not allow returns between tags
    
    if([entryType isEqualToString:@"misc"]){
        refTypeID = 13; // generic
        publisherField = @"Howpublished";
    }else if([entryType isEqualToString:BDSKInbookString]){
        refTypeID = 5; // book section
    }else if([entryType isEqualToString:BDSKIncollectionString]){
        refTypeID = 5; // book section
    }else if([entryType isEqualToString:BDSKInproceedingsString]){
        refTypeID = 10; // conference proceedings
    }else if([entryType isEqualToString:BDSKProceedingsString]){
        refTypeID = 10; // conference proceedings
    }else if([entryType isEqualToString:BDSKManualString]){
        refTypeID = 9; // computer program
        publisherField = @"Organization";
        organizationField = @"";
    }else if([entryType isEqualToString:BDSKTechreportString]){
        refTypeID = 27; // report
        isbnField = BDSKNumberString;
        numberField = @"";
        publisherField = @"Institution";
    }else if([entryType isEqualToString:@"mastersthesis"]){
        refTypeID = 32; // thesis
        publisherField = @"School";
    }else if([entryType isEqualToString:@"phdthesis"]){
        refTypeID = 32; // thesis
    }else if([entryType isEqualToString:@"unpublished"]){
        refTypeID = 34;
    }else if([entryType isEqualToString:BDSKArticleString]){
        refTypeID = 17; // journal article
        isbnField = @"Issn";
        booktitleField = BDSKJournalString;
        if ([NSString isEmptyString:[self valueOfField:BDSKVolumeString]] && [NSString isEmptyString:[self valueOfField:BDSKNumberString]])
            refTypeID = 23; // newspaper article
    }else if([entryType isEqualToString:BDSKBookString]){
        refTypeID = 6; // book
        booktitleField = BDSKSeriesString;
        if([self numberOfAuthors] == 0){
            refTypeID = 28; // edited book
            authorField = BDSKEditorString;
            editorField = @"";
        }
    }else{
        refTypeID = 13;
    }
    
    // begin writing record
    
    // see bug # 1594134; some EndNote versions seem to require the source-app tag
    if(fileName)
        [s appendFormat:@"<database name=\"%@\" path=\"%@\">%@</database>", [fileName lastPathComponent], fileName, [fileName lastPathComponent]];
    [s appendFormat:@"<source-app name=\"BibDesk\" version=\"%@\">BibDesk</source-app>", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    
    // record number; or should we use itemIndex?
    [s appendFormat:@"<rec-number>%@</rec-number>", [self fileOrder]];
    
    // ref-type
    [s appendFormat:@"<ref-type>%i</ref-type>", refTypeID];
    
    // contributors
    
    NSEnumerator *authorE;
    BibAuthor *author;
    
    [s appendString:@"<contributors>"];
    
    authorE = [[self peopleArrayForField:authorField] objectEnumerator];
    [s appendString:@"<authors>"];
    while (author = [authorE nextObject]){
        [s appendStrings:@"<author>", [[author normalizedName] stringByEscapingBasicXMLEntitiesUsingUTF8], @"</author>", nil];
    }
    [s appendString:@"</authors>"];
    
    authorE = [[self peopleArrayForField:editorField] objectEnumerator];
    [s appendString:@"<secondary-authors>"];
    while (author = [authorE nextObject]){
        [s appendStrings:@"<author>", [[author normalizedName] stringByEscapingBasicXMLEntitiesUsingUTF8], @"</author>", nil];
    }
    [s appendString:@"</secondary-authors>"];
    
    authorE = [[self peopleArrayForField:organizationField] objectEnumerator];
    [s appendString:@"<tertiary-authors>"];
    while (author = [authorE nextObject]){
        [s appendStrings:@"<author>", [[author normalizedName] stringByEscapingBasicXMLEntitiesUsingUTF8], @"</author>", nil];
    }
    [s appendString:@"</tertiary-authors>"];
    
    [s appendString:@"</contributors>"];
    
    // titles
    
    [s appendString:@"<titles>"];
    AddXMLField(@"title",BDSKTitleString);
    AddXMLField(@"secondary-title",booktitleField);
    AddXMLField(@"tertiary-title",BDSKSeriesString);
    [s appendString:@"</titles>"];
    
    // publication info
    
    AddXMLField(@"volume",BDSKVolumeString);
    AddXMLField(@"number",numberField);
    AddXMLField(@"edition",@"Edition");
    AddXMLField(@"pages",BDSKPagesString);
    AddXMLField(@"section",BDSKChapterString);
    AddXMLField(@"pub-location",BDSKAddressString);
    AddXMLField(@"publisher",publisherField);
    AddXMLField(@"isbn",isbnField);
    AddXMLField(@"work-type",BDSKPubTypeString);
    
    // dates
    
    [s appendString:@"<dates>"];
    AddXMLField(@"year",BDSKYearString);
    [s appendString:@"<pub-dates>"];
    AddXMLField(@"date",BDSKMonthString);
    [s appendString:@"</pub-dates></dates>"];
    
    // meta-data
    
    [s appendStrings:@"<label>", [[self citeKey] stringByEscapingBasicXMLEntitiesUsingUTF8], @"</label>", nil];
    [s appendString:@"<keywords>"];
    AddXMLField(@"keyword",BDSKKeywordsString);
    [s appendString:@"</keywords>"];
    [s appendString:@"<urls>"];
    [s appendString:@"<pdf-urls>"];
    AddXMLField(@"url",BDSKLocalUrlString);
    [s appendString:@"</pdf-urls>"];
    [s appendString:@"<related-urls>"];
    AddXMLField(@"url",BDSKUrlString);
    [s appendString:@"</related-urls>"];
    [s appendString:@"</urls>"];
    AddXMLField(@"abstract",BDSKAbstractString);
    AddXMLField(@"research-notes",BDSKAnnoteString);
    AddXMLField(@"notes",@"Note");
    
    // custom
    
    [s appendStrings:@"<custom3>", entryType, @"</custom3>", nil];
    AddXMLField(@"custom4",BDSKCrossrefString);
    
    [s appendString:@"</record>\n"];
    
    return s;
}

- (NSString *)RSSValue{
    // first look if we have an item template for RSS
    NSString *templateStyle = [BDSKTemplate defaultStyleNameForFileType:@"rss"];
    if (templateStyle) {
        BDSKTemplate *template = [BDSKTemplate templateForStyle:templateStyle];
        NSString *string = [self stringValueUsingTemplate:template];
        if (string)
            return string;
    }
    
    // no item template found, so do some custom  stuff
    
    NSMutableString *s = [[[NSMutableString alloc] init] autorelease];

    [s appendString:@"<item>\n<title>"];
	[s appendString:[[self displayTitle] xmlString]];
    [s appendString:@"</title>\n<description>"];
    [s appendString:[[self valueOfField:BDSKRssDescriptionString] xmlString]];
    [s appendString:@"</description>\n<link>"];
    [s appendString:[self valueOfField:BDSKUrlString]];
    [s appendString:@"</link>\n</item>\n"];
    return s;
}

- (NSString *)stringValueUsingTemplate:(BDSKTemplate *)template{
    NSParameterAssert(nil != template);
    NSString *string = nil;
    [self prepareForTemplateParsing];
    string = [BDSKTemplateParser stringByParsingTemplate:[template stringForType:[self pubType]] usingObject:self];
    [self cleanupAfterTemplateParsing];
    return string;
}

- (NSAttributedString *)attributedStringValueUsingTemplate:(BDSKTemplate *)template{
    NSParameterAssert(nil != template);
    NSAttributedString *string = nil;
    [self prepareForTemplateParsing];
    string = [BDSKTemplateParser attributedStringByParsingTemplate:[template attributedStringForType:[self pubType]] usingObject:self];
    [self cleanupAfterTemplateParsing];
    return string;
}

- (NSString *)allFieldsString{
    NSDictionary *thePubFields = [self pubFields];
    NSMutableString *result = [[[NSMutableString alloc] initWithCapacity:([thePubFields count] * 10)] autorelease];
    
    [result appendString:[self citeKey]];
    [result appendString:@" "];
    
    BibItem *parent = [self crossrefParent];

    // if it has a parent, find all the available keys, and use valueOfField: to get either the
    // child object or parent object value. Inherit only the fields of the parent relevant for the item.
    if(parent){
        NSEnumerator *keyEnum = [thePubFields keyEnumerator];
        NSString *key = nil;
        
        while(key = [keyEnum nextObject]){
            [result appendString:[self valueOfField:key inherit:YES]];
            [result appendString:@" "];
        }
                
    } else {
        NSEnumerator *pubFieldsE = [thePubFields objectEnumerator];
        NSString *value = nil;
        
        while(value = [pubFieldsE nextObject]){
            [result appendString:value];
            [result appendString:@" "];
        }
    }       
    
    return result;
}

#pragma mark Templating

- (void)prepareForTemplateParsing{
    [templateFields release];
    templateFields = [[BDSKFieldCollection alloc] initWithItem:self];
}

- (void)cleanupAfterTemplateParsing{
    [templateFields release];
    templateFields = nil;
}

- (id)requiredFields{
    return [[self fields] fieldsWithNames:[[BibTypeManager sharedManager] requiredFieldsForType:[self pubType]]];
}

- (id)optionalFields{
    return [[self fields] fieldsWithNames:[[BibTypeManager sharedManager] optionalFieldsForType:[self pubType]]];
}

- (id)defaultFields{
    return [[self fields] fieldsWithNames:[[BibTypeManager sharedManager] userDefaultFieldsForType:[self pubType]]];
}

- (id)allFields{
    NSMutableArray *allFields = [NSMutableArray array];
    NSString *type = [self pubType];
    [allFields addObjectsFromArray:[[BibTypeManager sharedManager] requiredFieldsForType:type]];
    [allFields addObjectsFromArray:[[BibTypeManager sharedManager] optionalFieldsForType:type]];
    [allFields addNonDuplicateObjectsFromArray:[[BibTypeManager sharedManager] userDefaultFieldsForType:type]];
    [allFields addNonDuplicateObjectsFromArray:[self allFieldNames]];
    return [[self fields] fieldsWithNames:allFields];
}

- (BDSKFieldCollection *)fields{
    if (templateFields == nil)
        [self prepareForTemplateParsing];
    [templateFields setType:BDSKStringFieldCollection];
    return templateFields;
}

- (BDSKFieldCollection *)urls{
    if (templateFields == nil)
        [self prepareForTemplateParsing];
    [templateFields setType:BDSKURLFieldCollection];
    return templateFields;
}

- (BDSKFieldCollection *)persons{
    if (templateFields == nil)
        [self prepareForTemplateParsing];
    [templateFields setType:BDSKPersonFieldCollection];
    return templateFields;
}

- (id)authors{
    return [[self persons] valueForKey:BDSKAuthorString];
}

- (id)editors{
    return [[self persons] valueForKey:BDSKEditorString];
}

- (void)setItemIndex:(int)index{ currentIndex = index; }

- (int)itemIndex{ return currentIndex; }

- (NSCalendarDate *)currentDate{ return [NSCalendarDate date]; }

#pragma mark -
#pragma mark URL handling

- (NSURL *)remoteURL{
	return [self remoteURLForField:BDSKUrlString];
}

- (NSImage *)imageForURLField:(NSString *)field{
    
    NSURL *url = [self URLForField:field];
    if(nil == url)
        return nil;
    
    if([field isLocalFileField] && (url = [url fileURLByResolvingAliases]) == nil)
        return [NSImage missingFileImage];
    
    return [NSImage imageForURL:url];
}

- (NSImage *)smallImageForURLField:(NSString *)field{

    NSURL *url = [self URLForField:field];
    if(nil == url)
        return nil;
   
    if([field isLocalFileField] && (url = [url fileURLByResolvingAliases]) == nil)
        return [NSImage smallMissingFileImage];
    
    return [NSImage smallImageForURL:url];
}

- (NSURL *)URLForField:(NSString *)field{
    return ([field isLocalFileField] ? [self localFileURLForField:field] : [self remoteURLForField:field]);
}

- (NSURL *)remoteURLForField:(NSString *)field{
    
    // check the cache first
    NSURL *returnURL = [cachedURLs objectForKey:field];
    if (returnURL)
        return returnURL;
    
    NSString *value = [self valueOfField:field inherit:NO];
    NSURL *baseURL = nil;
    
    // resolve DOI fields against a base URL if necessary, so they can be opened directly by NSWorkspace
    if([field isEqualToString:BDSKDoiString] && [value rangeOfString:@"://"].length == 0){
        // DOI manual says this is a safe URL to resolve with for the foreseeable future
        baseURL = [NSURL URLWithString:@"http://dx.doi.org/"];
        // remove any text prefix, which is not required for a valid DOI, but may be present; DOI starts with "10"
        // http://www.doi.org/handbook_2000/enumeration.html#2.2
        NSRange range = [value rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
        if(range.length && range.location > 0)
            value = [value substringFromIndex:range.location];
    } else if([field isEqualToString:BDSKCiteseerUrlString] && [value rangeOfString:@"://"].length == 0){
        // JabRef and CiteSeer use Citeseerurl for CiteSeer links
        // cache this base URL; it's a hidden pref, so you have to quit/relaunch to set it anyway
        baseURL = [NSURL URLWithString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCiteseerHostKey]];
    } else if([value hasPrefix:@"\\url{"] && [value hasSuffix:@"}"]){
        // URLs are often enclosed in a \url tex command in bibtex
        value = [value substringWithRange:NSMakeRange(5, [value length] - 6)];
    } else if([value hasPrefix:@"\\href{"]){
        // may also take the form \href{http://arXiv.org/abs/hep-th/0304033}{arXiv:hep-th/0304033}
        unsigned loc = [value indexOfRightBraceMatchingLeftBraceAtIndex:5];
        if (NSNotFound != loc)
            value = [value substringWithRange:NSMakeRange(6, loc - 6)];
    }

    returnURL = [NSURL URLWithStringByNormalizingPercentEscapes:value baseURL:baseURL];
    if (returnURL)
        [cachedURLs setObject:returnURL forKey:field];
    return returnURL;
}

- (NSURL *)localURL{
	return [self localFileURLForField:BDSKLocalUrlString];
}

- (NSString *)localUrlPath{
	return [self localUrlPathInheriting:YES];
}

- (NSString *)localUrlPathInheriting:(BOOL)inherit{
	return [self localFilePathForField:BDSKLocalUrlString inherit:inherit];
}

- (NSString *)localFilePathForField:(NSString *)field{
	return [self localFilePathForField:field inherit:YES];
}

- (NSString *)localFilePathForField:(NSString *)field inherit:(BOOL)inherit{
    return [[self localFileURLForField:field inherit:inherit] path];
}

- (NSURL *)localFileURLForField:(NSString *)field{
	return [self localFileURLForField:field inherit:YES];
}

- (NSURL *)localFileURLForField:(NSString *)field inherit:(BOOL)inherit{
    
    // check the cache first
    NSURL *localURL = [cachedURLs objectForKey:field];
    if (nil != localURL)
        return localURL;
    
    NSURL *resolvedURL = nil;
    NSString *localURLFieldValue = [self valueOfField:field inherit:inherit];
    
    // only cache absolute URLs
    BOOL shouldCache = YES;
    
    if ([NSString isEmptyString:localURLFieldValue]) return nil;
    
    if([localURLFieldValue hasPrefix:@"file://"]){
        // it's already a file: url and we can just build it 
        localURL = [NSURL URLWithString:localURLFieldValue];
        
    }else{
        // the local-url isn't already a file URL, so we'll turn it into one
        
        // check to see if it's a relative path
        UniChar ch = [localURLFieldValue characterAtIndex:0];
        if(ch != '/' && ch != '~'){
            NSString *docPath = [[owner fileURL] path];
            NSString *basePath = [NSString isEmptyString:docPath] ? NSHomeDirectory() : [docPath stringByDeletingLastPathComponent];
			// It's a relative path from the containing document's path
            localURLFieldValue = [basePath stringByAppendingPathComponent:localURLFieldValue];
            shouldCache = NO;
        }

        localURL = [NSURL fileURLWithPath:[localURLFieldValue stringByStandardizingPath]];
    }
	
    
    // resolve aliases in the containing dir, as most NSFileManager methods do not follow them, and NSWorkspace can't open aliases
	// we don't resolve the last path component if it's an alias, as this is used in auto file, which should move the alias rather than the target file 
    resolvedURL = [localURL fileURLByResolvingAliasesBeforeLastPathComponent];
    
    // if the path to the file does not exist resolvedURL is nil, so we return the unresolved path
    NSURL *returnURL = (resolvedURL == nil) ? localURL : resolvedURL;
    if (returnURL)
        [cachedURLs setObject:returnURL forKey:field];
    
    return returnURL;
}

- (BOOL)isValidLocalUrlPath:(NSString *)proposedPath{
    if ([NSString isEmptyString:proposedPath])
        return NO;
    NSString *papersFolderPath = [[NSApp delegate] folderPathForFilingPapersFromDocument:owner];
    if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKLocalUrlLowercaseKey])
        proposedPath = [proposedPath lowercaseString];
    return ([[NSFileManager defaultManager] fileExistsAtPath:[papersFolderPath stringByAppendingPathComponent:proposedPath]] == NO);
}

- (NSString *)suggestedLocalUrl{
	NSString *localUrlFormat = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLocalUrlFormatKey];
	NSString *papersFolderPath = [[NSApp delegate] folderPathForFilingPapersFromDocument:owner];
    
    NSString *oldPath = [self localUrlPathInheriting:NO];
    if ([oldPath hasPrefix:[papersFolderPath stringByAppendingString:@"/"]]) 
        oldPath = [oldPath substringFromIndex:[papersFolderPath length] + 1];
    else
        oldPath = nil;
      
	NSString *relativeFile = [BDSKFormatParser parseFormat:localUrlFormat forField:BDSKLocalUrlString ofItem:self suggestion:oldPath];
	if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKLocalUrlLowercaseKey]) {
		relativeFile = [relativeFile lowercaseString];
	}
	NSURL *url = [NSURL fileURLWithPath:[papersFolderPath stringByAppendingPathComponent:relativeFile]];
	
	return [url absoluteString];
}

- (BOOL)canSetLocalUrl
{
    NSArray *requiredFields = [[NSApp delegate] requiredFieldsForLocalUrl];
	
	if (nil == requiredFields || 
        ([NSString isEmptyString:[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPapersFolderPathKey]] && 
		[NSString isEmptyString:[[[owner fileURL] path] stringByDeletingLastPathComponent]]))
		return NO;
	
	NSEnumerator *fEnum = [requiredFields objectEnumerator];
	NSString *fieldName;
	
	while (fieldName = [fEnum nextObject]) {
		if ([fieldName isEqualToString:BDSKCiteKeyString]) {
            if([self hasEmptyOrDefaultCiteKey])
				return NO;
		} else if ([fieldName isEqualToString:@"Document Filename"]) {
			if ([NSString isEmptyString:[[owner fileURL] path]])
				return NO;
		} else if ([fieldName hasPrefix:@"Document: "]) {
			if ([NSString isEmptyString:[owner documentInfoForKey:[fieldName substringFromIndex:10]]])
				return NO;
		} else if ([fieldName isEqualToString:BDSKAuthorEditorString]) {
			if ([NSString isEmptyString:[self valueOfField:BDSKAuthorString]] && 
				[NSString isEmptyString:[self valueOfField:BDSKEditorString]])
				return NO;
		} else {
			if ([NSString isEmptyString:[self valueOfField:fieldName]]) 
				return NO;
		}
	}
	return YES;
}

- (BOOL)needsToBeFiled { 
	return needsToBeFiled; 
}

- (void)setNeedsToBeFiled:(BOOL)flag {
	needsToBeFiled = flag;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKNeedsToBeFiledChangedNotification object:self];
}

- (BOOL)autoFilePaper
{
    // we can't autofile if it's disabled or there is nothing to file
	if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKFilePapersAutomaticallyKey] == NO || [self localUrlPath] == nil)
		return NO;
	
	if ([self canSetLocalUrl]) {
        OBASSERT([owner isDocument]);
        if ([owner isDocument]) {
            [[BibFiler sharedFiler] filePapers:[NSArray arrayWithObject:self]
                                  fromDocument:(BibDocument *)owner
                                         check:NO]; 
            return YES;
		} else {
            [self setNeedsToBeFiled:YES];
        }
	} else {
		[self setNeedsToBeFiled:YES];
	}
	return NO;
}

- (NSString *)documentFileName {
    return [[owner fileURL] path];
}

- (NSString *)documentInfoForKey:(NSString *)key {
    return [owner documentInfoForKey:key];
}

#pragma mark -
#pragma mark Groups

- (NSSet *)groupsForField:(NSString *)field{
	// first see if we had it cached
	NSSet *groupSet = [groups objectForKey:field];
	if(groupSet)
		return groupSet;

	// otherwise build it if we have a value
    NSString *value = [self stringValueOfField:field];
	if([value isComplex] || [value isInherited])
		value = [NSString stringWithString:value];
    if([NSString isEmptyString:value])
        return [NSSet set];
	
	NSMutableSet *mutableGroupSet;
	
    if([field isSingleValuedField]){
		// types and journals should be added as a whole
		mutableGroupSet = [[NSMutableSet alloc] initCaseInsensitiveWithCapacity:1];
		[mutableGroupSet addObject:value];
	}else if([field isPersonField]){
		mutableGroupSet = BDSKCreateFuzzyAuthorCompareMutableSet();
        [mutableGroupSet addObjectsFromArray:[self peopleArrayForField:field]];
	}else{
        NSArray *groupArray;   
        NSCharacterSet *acSet = [[BibTypeManager sharedManager] separatorCharacterSetForField:field];
        if([value containsCharacterInSet:acSet])
			groupArray = [value componentsSeparatedByCharactersInSet:acSet trimWhitespace:YES];
        else 
            groupArray = [value componentsSeparatedByStringCaseInsensitive:@" and "];
        
		mutableGroupSet = [[NSMutableSet alloc] initCaseInsensitiveWithCapacity:3];
        [mutableGroupSet addObjectsFromArray:groupArray];
    }
	
	[groups setObject:mutableGroupSet forKey:field];
	[mutableGroupSet release];
	
    return [groups objectForKey:field];
}

- (BOOL)isContainedInGroupNamed:(id)name forField:(NSString *)field {
    OBASSERT([field isPersonField] ? [name isKindOfClass:[BibAuthor class]] : 1);
	return [[self groupsForField:field] containsObject:name];
}

- (int)addToGroup:(BDSKGroup *)aGroup handleInherited:(int)operation{
	OBASSERT([aGroup isCategory] == YES && [owner isDocument]);
    BDSKCategoryGroup *group = (BDSKCategoryGroup *)aGroup;
    // don't add it twice
	id groupName = [group name];
	NSString *field = [group key];
	OBASSERT(field != nil);
    if([[self groupsForField:field] containsObject:groupName])
        return BDSKOperationIgnore;
	
	// otherwise build it if we have a value
	BOOL isInherited = NO;
    NSString *oldString = [self stringValueOfField:field];
	if([oldString isComplex] || [oldString isInherited]){
		isInherited = [oldString isInherited];
		oldString = [NSString stringWithString:oldString];
	}
	
	if(isInherited){
		if(operation ==  BDSKOperationAsk || operation == BDSKOperationIgnore)
			return operation;
	}else{
		if([field isSingleValuedField] || [NSString isEmptyString:oldString])
			operation = BDSKOperationSet;
		else
			operation = BDSKOperationAppend;
	}
	// at this point operation is either Set or Append
	
    // may be an author object, so convert it to a string
    NSString *groupDescription = [group stringValue];
	NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[groupDescription length] + [oldString length] + 1];

    // we set the type and journal field, add to other fields if needed
	if(operation == BDSKOperationAppend){
        [string appendString:oldString];
        
		// Use default separator string, unless this is an author/editor field
        if([field isPersonField])
            [string appendString:@" and "];
        else if ([field isCitationField])
            [string appendString:@", "];
        else
            [string appendString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKDefaultGroupFieldSeparatorKey]];
    }
    
    [string appendString:groupDescription];
	[self setField:field toStringValue:string];
    [string release];
	
	return operation;
}

- (int)removeFromGroup:(BDSKGroup *)aGroup handleInherited:(int)operation{
	OBASSERT([aGroup isCategory] == YES && [owner isDocument]);
    BDSKCategoryGroup *group = (BDSKCategoryGroup *)aGroup;
	id groupName = [group name];
	NSString *field = [group key];
	OBASSERT(field != nil);
	NSSet *groupNames = [groups objectForKey:field];
    if([groupNames containsObject:groupName] == NO)
        return BDSKOperationIgnore;
	
	// otherwise build it if we have a value
	BOOL isInherited = NO;
    NSString *oldString = [self stringValueOfField:field];
	if([oldString isComplex] || [oldString isInherited]){
		isInherited = [oldString isInherited];
		oldString = [NSString stringWithString:oldString];
	}
	
	if(isInherited){
		if(operation ==  BDSKOperationAsk || operation == BDSKOperationIgnore)
			return operation;
	}
	
	if([field isSingleValuedField] || [NSString isEmptyString:oldString] || [groupNames count] < 2)
		operation = BDSKOperationSet;
	else
		operation = BDSKOperationAppend; // Append really means Remove here
	
	// at this point operation is either Set or Append
	
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
	// first handle some special cases where we can simply set the value
	if ([[pw stringArrayForKey:BDSKBooleanFieldsKey] containsObject:field]) {
		// we flip the boolean, effectively removing it from the group
		[self setField:field toBoolValue:![groupName booleanValue]];
		return BDSKOperationSet;
	} else if ([[pw stringArrayForKey:BDSKRatingFieldsKey] containsObject:field]) {
		// this operation doesn't really make sense for ratings, but we need to do something
		[self setField:field toRatingValue:([groupName intValue] == 0) ? 1 : 0];
		return BDSKOperationSet;
	} else if ([[pw stringArrayForKey:BDSKTriStateFieldsKey] containsObject:field]) {
		// this operation also doesn't make much sense for tri-state fields
        // so we do something that seems OK:
        NSCellStateValue newVal = NSOffState;
        NSCellStateValue oldVal = [groupName triStateValue];
        switch(oldVal){
            case NSOffState:
                newVal = NSOnState;
                break;
            case NSOnState:
            case NSMixedState:
                newVal = NSOffState;
        }
		[self setField:field toTriStateValue:newVal];
		return BDSKOperationSet;
	} else if (operation == BDSKOperationSet) {
		// we should have a single value to remove, so we can simply clear the field
		[self setField:field toStringValue:@""];
		return BDSKOperationSet;
	}
	
	// handle authors separately
    if([field isPersonField]){
		OBASSERT([groupName isKindOfClass:[BibAuthor class]]);
		NSEnumerator *authEnum = [[self peopleArrayForField:field] objectEnumerator];
		BibAuthor *auth;
		NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[oldString length] - [[groupName lastName] length] - 5];
		BOOL first = YES;
		while(auth = [authEnum nextObject]){
			if([auth fuzzyEqual:groupName] == NO){
				if(first == YES) 
                    first = NO;
				else 
                    [string appendString:@" and "];
				[string appendString:[auth originalName]];
			}
		}
		[self setField:field toValue:string];
		[string release];
		return operation;
    }
	
	// otherwise we have a multivalued string, we should parse to get the order and delimiters right
    OFCharacterSet *delimiterCharSet = [[BibTypeManager sharedManager] separatorOFCharacterSetForField:field];
    OFCharacterSet *whitespaceCharSet = [OFCharacterSet whitespaceCharacterSet];
	
	BOOL useDelimiters = NO;
	if([oldString containsCharacterInOFCharacterSet:delimiterCharSet])
		useDelimiters = YES;
	
	OFStringScanner *scanner = [[OFStringScanner alloc] initWithString:oldString];
	NSString *token;
	NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[oldString length] - [groupName length] - 1];
	BOOL addedToken = NO;
	NSString *lastDelimiter = @"";
	int startLocation, endLocation;
	
	scannerScanUpToCharacterNotInOFCharacterSet(scanner, whitespaceCharSet);

	do {
		addedToken = NO;
		if(useDelimiters)
			token = [scanner readFullTokenWithDelimiterOFCharacterSet:delimiterCharSet];
		else
			token = [scanner readFullTokenUpToString:@" and "];
		if(token){
			token = [token stringByRemovingSurroundingWhitespace];
			if(![NSString isEmptyString:token] && [token caseInsensitiveCompare:groupName] != NSOrderedSame){
				[string appendString:lastDelimiter];
				[string appendString:token];
				addedToken = YES;
			}
		}
		// skip the delimiter or " and ", and any whitespace following it
		startLocation = [scanner scanLocation];
		if(useDelimiters)
			scannerScanUpToCharacterNotInOFCharacterSet(scanner, delimiterCharSet);
		else if(scannerHasData(scanner))
			[scanner setScanLocation:scannerScanLocation(scanner) + 5];
		scannerScanUpToCharacterNotInOFCharacterSet(scanner, whitespaceCharSet);
		endLocation = [scanner scanLocation];
		if(addedToken == YES)
			lastDelimiter = [oldString substringWithRange:NSMakeRange(startLocation, endLocation - startLocation)];
		
	} while(scannerHasData(scanner));
	
	[self setField:field toValue:string];
	[scanner release];
	[string release];
    
	return operation;
}

- (int)replaceGroup:(BDSKGroup *)aGroup withGroupNamed:(NSString *)newGroupName handleInherited:(int)operation{
	OBASSERT([aGroup isCategory] == YES && [owner isDocument]);
    BDSKCategoryGroup *group = (BDSKCategoryGroup *)aGroup;
	id groupName = [group name];
	NSString *field = [group key];
	OBASSERT(field != nil);
	NSSet *groupNames = [groups objectForKey:field];
    if([groupNames containsObject:groupName] == NO)
        return BDSKOperationIgnore;
	
	// otherwise build it if we have a value
	BOOL isInherited = NO;
    NSString *oldString = [self stringValueOfField:field];
	if([oldString isComplex] || [oldString isInherited]){
		isInherited = [oldString isInherited];
		oldString = [NSString stringWithString:oldString];
	}
	
	if(isInherited){
		if(operation ==  BDSKOperationAsk || operation == BDSKOperationIgnore)
			return operation;
	}
	
	if([field isSingleValuedField] || [NSString isEmptyString:oldString] || [groupNames count] < 2)
		operation = BDSKOperationSet;
	else
		operation = BDSKOperationAppend; // Append really means Replace here
	
	// at this point operation is either Set or Append
	
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
	// first handle some special cases where we can simply set the value
	if ([[pw stringArrayForKey:BDSKBooleanFieldsKey] containsObject:field]) {
		// we flip the boolean, effectively removing it from the group
		[self setField:field toBoolValue:[newGroupName booleanValue]];
		return BDSKOperationSet;
	} else if ([[pw stringArrayForKey:BDSKRatingFieldsKey] containsObject:field]) {
		// this operation doesn't really make sense for ratings, but we need to do something
		[self setField:field toRatingValue:[newGroupName intValue]];
		return BDSKOperationSet;
	} else if (operation == BDSKOperationSet) {
		// we should have a single value to remove, so we can simply clear the field
		[self setField:field toStringValue:newGroupName];
		return BDSKOperationSet;
	}
	
	// handle authors separately
    if([field isPersonField]){
		OBASSERT([groupName isKindOfClass:[BibAuthor class]]);
		NSEnumerator *authEnum = [[self peopleArrayForField:field] objectEnumerator];
		BibAuthor *auth;
		NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[oldString length] - [[groupName lastName] length] - 5];
		BOOL first = YES;
		while(auth = [authEnum nextObject]){
			if(first == YES) first = NO;
			else [string appendString:@" and "];
			if([auth fuzzyEqual:groupName]){
				[string appendString:newGroupName];
			}else{
				[string appendString:[auth originalName]];
			}
		}
		[self setField:field toValue:string];
		[string release];
		return operation;
    }
	
	// otherwise we have a multivalued string, we should parse to get the order and delimiters right
    OFCharacterSet *delimiterCharSet = [[BibTypeManager sharedManager] separatorOFCharacterSetForField:field];
    OFCharacterSet *whitespaceCharSet = [OFCharacterSet whitespaceCharacterSet];
	
	BOOL useDelimiters = NO;
	if([oldString containsCharacterInOFCharacterSet:delimiterCharSet])
		useDelimiters = YES;
	
	OFStringScanner *scanner = [[OFStringScanner alloc] initWithString:oldString];
	NSString *token;
	NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[oldString length] - [groupName length] - 1];
	BOOL addedToken = NO;
	NSString *lastDelimiter = @"";
	int startLocation, endLocation;
	
	scannerScanUpToCharacterNotInOFCharacterSet(scanner, whitespaceCharSet);

	do {
		addedToken = NO;
		if(useDelimiters)
			token = [scanner readFullTokenWithDelimiterOFCharacterSet:delimiterCharSet];
		else
			token = [scanner readFullTokenUpToString:@" and "];
		if(token){
			token = [token stringByRemovingSurroundingWhitespace];
			if(![NSString isEmptyString:token]){
				[string appendString:lastDelimiter];
				if([token caseInsensitiveCompare:groupName] == NSOrderedSame)
					[string appendString:newGroupName];
				else
					[string appendString:token];
				addedToken = YES;
			}
		}
		// skip the delimiter or " and ", and any whitespace following it
		startLocation = [scanner scanLocation];
		if(useDelimiters)
			scannerScanUpToCharacterNotInOFCharacterSet(scanner, delimiterCharSet);
		else if(scannerHasData(scanner))
			[scanner setScanLocation:scannerScanLocation(scanner) + 5];
		scannerScanUpToCharacterNotInOFCharacterSet(scanner, whitespaceCharSet);
		endLocation = [scanner scanLocation];
		if(addedToken == YES)
			lastDelimiter = [oldString substringWithRange:NSMakeRange(startLocation, endLocation - startLocation)];
		
	} while(scannerHasData(scanner));
	
	[self setField:field toValue:string];
	[scanner release];
	[string release];
    
	return operation;
}

- (void)invalidateGroupNames{
	[groups removeAllObjects];
}

- (BOOL)isImported{
    return isImported;
}

- (void)setImported:(BOOL)flag{
    if (isImported != flag) {
        isImported = flag;
    }
}
     
@end

#pragma mark -

@implementation BibItem (PDFMetadata)

+ (BibItem *)itemWithPDFMetadata:(PDFMetadata *)metadata;
{
    BibItem *item = nil;
    if(metadata != nil){
        item = [[[self allocWithZone:[self zone]] init] autorelease];
        
        NSString *value = nil;
        
        // setting to nil can remove some fields (e.g. keywords), so check first
        value = [metadata valueForKey:BDSKPDFDocumentAuthorAttribute];
        if(value)
            [item setField:BDSKAuthorString toValue:value];
        
        value = [metadata valueForKey:BDSKPDFDocumentTitleAttribute];
        if(value)
            [item setField:BDSKTitleString toValue:value];
        
        // @@ this seems to be set by the filesystem, not as metadata?
        value = [[[metadata valueForKey:BDSKPDFDocumentCreationDateAttribute] dateWithCalendarFormat:@"%B %Y" timeZone:[NSTimeZone defaultTimeZone]] description];
        if(value)
            [item setField:BDSKDateString toValue:value];
        
        value = [[metadata valueForKey:BDSKPDFDocumentKeywordsAttribute] componentsJoinedByString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKDefaultGroupFieldSeparatorKey]];
        if(value)
            [item setField:BDSKKeywordsString toValue:value];
    }
    return item;
}


- (PDFMetadata *)PDFMetadata;
{
    return [PDFMetadata metadataWithBibItem:self];
}

- (void)addPDFMetadataToFileForLocalURLField:(NSString *)field;
{
    NSParameterAssert([field isLocalFileField]);
    
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldUsePDFMetadata]){
        NSError *error = nil;
        if([[self PDFMetadata] addToURL:[self URLForField:field] error:&error] == NO && error != nil)
            [NSApp presentError:error];
    }
}

// convenience for metadata methods; the silly name is because the AS category implements -(NSString *)keywords
- (NSArray *)keywordsArray { return [[self groupsForField:BDSKKeywordsString] allObjects]; }

@end

#pragma mark -

@implementation BibItem (Private)

// The date setters should only be used at initialization or from updateMetadata:forKey:.  If you want to change the date, change the value in pubFields, and let updateMetadata handle the ivar.
- (void)setDate: (NSCalendarDate *)newDate{
    if(newDate != pubDate){
        [pubDate release];
        pubDate = [newDate retain];
    }
}

- (void)setDateAdded:(NSCalendarDate *)newDateAdded {
    if(newDateAdded != dateAdded){
        [dateAdded release];
        dateAdded = [newDateAdded retain];
    }
}

- (void)setDateModified:(NSCalendarDate *)newDateModified {
    if(newDateModified != dateModified){
        [dateModified release];
        dateModified = [newDateModified retain];
    }
}

- (void)setPubTypeWithoutUndo:(NSString *)newType{
    newType = [newType entryType];
    OBASSERT(![NSString isEmptyString:newType]);
	if(![[self pubType] isEqualToString:newType]){
		[pubType release];
		pubType = [newType copy];
		
		[self makeType];
	}
}

- (void)updateMetadataForKey:(NSString *)key{
    
	[self setHasBeenEdited:YES];
    spotlightMetadataChanged = YES;   
    
    BOOL allFieldsChanged = [BDSKAllFieldsString isEqualToString:key];
    
    // invalidate people (authors, editors, etc.) if necessary
    if (allFieldsChanged || [key isPersonField]) {
        [people release];
        people = nil;
    }
	
	if([BDSKLocalUrlString isEqualToString:key]){
		[self setNeedsToBeFiled:NO];
        // If the Finder comment from this file has a useful URL and our BibItem has an empty remote URL field, use the Finder comment as remote URL.  Do this before autofiling the paper, since we know the path to the file now (hidden user default).
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"BDSKShouldUseSpotlightCommentForURL"]){
            NSString *possibleURLString = [[NSFileManager defaultManager] commentForURL:[self localURL]];
            if(possibleURLString && [NSURL URLWithString:possibleURLString]!= nil && [self remoteURL] == nil)
                [self setField:BDSKUrlString toValue:possibleURLString];
        }
    }
	
    // see if we need to use the crossref workaround (BibTeX bug)
	if([BDSKTitleString isEqualToString:key] &&
	   [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKDuplicateBooktitleKey] &&
	   [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKTypesForDuplicateBooktitleKey] containsObject:[self pubType]]){
		[self duplicateTitleToBooktitleOverwriting:[[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKForceDuplicateBooktitleKey]];
	}
 	
	// invalidate the cached groups; they are rebuilt when needed
	if(allFieldsChanged){
		[groups removeAllObjects];
        // re-call make type to make sure we still have all the appropriate bibtex defined fields...
        // but only if we have set the full pubFields array, as we should not be able to remove necessary fields.
        [self makeType];
        
        // the URL cache is certainly invalid now
        [cachedURLs removeAllObjects];
	}else if(key != nil){
		[groups removeObjectForKey:key];
	}
    
    if([key isURLField])
        [cachedURLs removeObjectForKey:key];
	
    NSCalendarDate *theDate = nil;
    
    // pubDate is a derived field based on Month and Year fields; we take the 15th day of the month to avoid edge cases
    if (key == nil || allFieldsChanged || [BDSKYearString isEqualToString:key] || [BDSKMonthString isEqualToString:key]) {
		NSString *yearValue = [pubFields objectForKey:BDSKYearString];
        if([yearValue isComplex])
            yearValue = [(BDSKStringNode *)[[yearValue nodes] objectAtIndex:0] value];
		if (![NSString isEmptyString:yearValue]) {
			NSString *monthValue = [pubFields objectForKey:BDSKMonthString];
			if([monthValue isComplex])
				monthValue = [(BDSKStringNode *)[[monthValue nodes] objectAtIndex:0] value];
			if (!monthValue) monthValue = @"";
            // allows month as number, name or abbreviated name
            theDate = [[NSCalendarDate alloc] initWithMonthDayYearString:[NSString stringWithFormat:@"%@-15-%@", monthValue, yearValue]];
			[self setDate:theDate];
            [theDate release];
		}else{
			[self setDate:nil];    // nil means we don't have a good date.
		}
	}
	
    // setDateAdded: is only called here; it is derived based on pubFields value of BDSKDateAddedString
    if (key == nil || allFieldsChanged || [BDSKDateAddedString isEqualToString:key]) {
		NSString *dateAddedValue = [pubFields objectForKey:BDSKDateAddedString];
		if (![NSString isEmptyString:dateAddedValue]) {
            theDate = [[NSCalendarDate alloc] initWithNaturalLanguageString:dateAddedValue];
			[self setDateAdded:theDate];
            [theDate release];
		}else{
			[self setDateAdded:nil];
		}
	}
	
    // we shouldn't check for the key here, as the DateModified can be set with any key
    // setDateModified: is only called here; it is derived based on pubFields value of BDSKDateAddedString
    NSString *dateModValue = [pubFields objectForKey:BDSKDateModifiedString];
    if (![NSString isEmptyString:dateModValue]) {
        theDate = [[NSCalendarDate alloc] initWithNaturalLanguageString:dateModValue];
        [self setDateModified:theDate];
        [theDate release];
    }else{
        [self setDateModified:nil];
    }
    
    if([owner isDocument] && ([key isURLField] || [key isEqualToString:BDSKTitleString] || [key isEqualToString:BDSKAllFieldsString])){
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSearchIndexInfoChangedNotification
                                                            object:(BibDocument *)owner
                                                          userInfo:[self searchIndexInfo]];
    }
}

@end

@implementation BDSKFieldCollection 

- (id)initWithItem:(BibItem *)anItem{
    if (self = [super init]) {
        item = anItem;
        usedFields = [[NSMutableSet alloc] init];
        type = BDSKStringFieldCollection;
    }
    return self;
}

- (void)dealloc{
    [usedFields release];
    [super dealloc];
}

- (id)valueForUndefinedKey:(NSString *)key{
    key = [key fieldName];
    if (key == nil)
        return nil;
    [usedFields addObject:key];
    if (type == BDSKPersonFieldCollection)
        return (id)[item peopleArrayForField:key];
    else if (type == BDSKURLFieldCollection)
        return (id)[item URLForField:key];
    else
        return (id)[item stringValueOfField:key];
}

- (void)setType:(int)aType{
    type = aType;
}

- (BOOL)isUsedField:(NSString *)name{
    BOOL isUsed = [usedFields containsObject:[name fieldName]];
    [usedFields addObject:name];
    return isUsed;
}

- (BOOL)isEmptyField:(NSString *)name{
    return [NSString isEmptyString:[item stringValueOfField:name]];
}

- (id)fieldForName:(NSString *)name{
    return [[[BibField alloc] initWithName:name bibItem:item] autorelease];
}

- (id)fieldsWithNames:(NSArray *)names{
    return [[[BDSKFieldArray alloc] initWithFieldCollection:self fieldNames:names] autorelease];
}

@end

@implementation BDSKFieldArray

- (id)initWithFieldCollection:(BDSKFieldCollection *)collection fieldNames:(NSArray *)array{
    if (self = [super init]) {
        fieldCollection = [collection retain];
        fieldNames = [[NSMutableArray alloc] initWithCapacity:[array count]];
        NSEnumerator *fnEnum = [array objectEnumerator];
        NSString *name;
        while (name = [fnEnum nextObject]) 
            if ([fieldCollection isUsedField:name] == NO)
                [fieldNames addObject:name];
    }
    return self;
}

- (void)dealloc{
    [fieldNames release];
    [fieldCollection release];
    [super dealloc];
}

- (unsigned int)count{
    return [fieldNames count];
}

- (id)objectAtIndex:(unsigned int)index{
    return [fieldCollection fieldForName:[fieldNames objectAtIndex:index]];
}

- (id)nonEmpty{
    unsigned int i = [fieldNames count];
    while (i--) 
        if ([fieldCollection isEmptyField:[fieldNames objectAtIndex:i]])
            [fieldNames removeObjectAtIndex:i];
    return self;
}

@end
