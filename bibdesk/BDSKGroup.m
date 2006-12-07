//
//  BDSKGroup.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 8/11/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKGroup.h"
#import "BDSKFilter.h"
#import "NSString_BDSKExtensions.h"
#import "NSImage+Toolbox.h"
#import "BibItem.h"
#import "BibAuthor.h"
#import "BibTypeManager.h"
#import <OmniBase/OBUtilities.h>


// a private subclass for the All Publication group
@interface BDSKAllPublicationsGroup : BDSKGroup @end

// a private subclass for the Empty ... group
@interface BDSKEmptyGroup : BDSKCategoryGroup @end

// a private subclass for the Last Import group
@interface BDSKLastImportGroup : BDSKStaticGroup @end


@implementation BDSKGroup

// super's designated initializer
- (id)init {
	self = [self initWithName:NSLocalizedString(@"Group", @"Group") count:0];
    return self;
}

- (id)initWithAllPublications {
	NSZone *zone = [self zone];
	[[super init] release];
	self = [[BDSKAllPublicationsGroup allocWithZone:zone] init];
	return self;
}

// designated initializer
- (id)initWithName:(id)aName count:(int)aCount {
    if (self = [super init]) {
        name = [aName copy];
        count = aCount;
    }
    return self;
}

// NSCoding protocol

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		name = [[decoder decodeObjectForKey:@"name"] retain];
		count = [decoder decodeIntForKey:@"count"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:name forKey:@"name"];
	[coder encodeInt:count forKey:@"count"];
}

// NSCopying protocol

- (id)copyWithZone:(NSZone *)aZone {
	id copy = [[[self class] allocWithZone:aZone] initWithName:name count:count];
	return copy;
}

- (void)dealloc {
    [name release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
	if (self == other)
		return YES;
	if (![other isMemberOfClass:[self class]]) 
		return NO;
	// we don't care about the count for identification
	return [[self name] isEqual:[(BDSKGroup *)other name]];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: name=\"%@\",count=%d", [self class], name, count];
}

// accessors

- (id)name {
    return [[name retain] autorelease];
}

- (int)count {
    return count;
}

- (void)setCount:(int)newCount {
	count = newCount;
}

// "static" accessors

- (NSImage *)icon {
    OBRequestConcreteImplementation(self, _cmd);
	return nil;
}

- (BOOL)isStatic {
	return NO;
}

- (BOOL)isSmart {
	return NO;
}

- (BOOL)isCategory {
	return NO;
}

- (BOOL)isShared {
	return NO;
}

- (BOOL)isScratch {
	return NO;
}

// custom accessors

- (NSString *)stringValue {
    return [[self name] description];
}

- (NSNumber *)numberValue {
	return [NSNumber numberWithInt:count];
}

// comparisons

- (NSComparisonResult)nameCompare:(BDSKGroup *)otherGroup {
    return [[self name] sortCompare:[otherGroup name]];
}

- (NSComparisonResult)countCompare:(BDSKGroup *)otherGroup {
	return [[self numberValue] compare:[otherGroup numberValue]];
}

- (BOOL)containsItem:(BibItem *)item {
    return YES;
}

- (BOOL)hasEditableName {
    return YES;
}

- (BOOL)isEditable {
    return NO;
}

- (BOOL)failedDownload {
    return NO;
}


- (BOOL)isRetrieving {
    return NO;
}

@end

#pragma mark -

@implementation BDSKAllPublicationsGroup

static NSString *BDSKAllPublicationsLocalizedString = nil;

+ (void)initialize{
    OBINITIALIZE;
    BDSKAllPublicationsLocalizedString = [NSLocalizedString(@"All Publications", @"group name for all pubs") copy];
}

- (id)init {
	self = [super initWithName:BDSKAllPublicationsLocalizedString count:0];
    return self;
}

- (NSImage *)icon {
    // this icon looks better than the one we get from +[NSImage imageNamed:@"FolderPenIcon"] or smallImageNamed:
    static NSImage *image = nil;
    if(nil == image)
        image = [[[NSWorkspace sharedWorkspace] iconForFile:[[NSBundle mainBundle] bundlePath]] copy];
    
	return image;
}

- (BOOL)hasEditableName {
    return NO;
}
 
@end

#pragma mark -

@implementation BDSKCategoryGroup

// designated initializer
- (id)initWithName:(id)aName key:(NSString *)aKey count:(int)aCount {
    if (self = [super initWithName:aName count:aCount]) {
        key = [aKey copy];
    }
    return self;
}

// super's designated initializer
- (id)initWithName:(id)aName count:(int)aCount {
    self = [self initWithName:aName key:nil count:aCount];
    return self;
}

- (id)initEmptyGroupWithKey:(NSString *)aKey count:(int)aCount {
    NSZone *zone = [self zone];
	[[super init] release];
    id aName = ([[[BibTypeManager sharedManager] personFieldsSet] containsObject:aKey]) ? [BibAuthor emptyAuthor] : @"";
    return [[BDSKEmptyGroup allocWithZone:zone] initWithName:aName key:aKey count:aCount];
}

// NSCoding protocol

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		key = [[decoder decodeObjectForKey:@"key"] retain];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:key forKey:@"key"];
}

// NSCopying protocol

- (id)copyWithZone:(NSZone *)aZone {
	id copy = [[[self class] allocWithZone:aZone] initWithName:name key:key count:count];
	return copy;
}

- (void)dealloc {
    [key release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
	if ([super isEqual:other] == NO) 
		return NO;
	return [[self key] isEqualToString:[other key]] || ([self key] == nil && [other key] == nil);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, key=\"%@\"", [super description], key];
}

- (BOOL)containsItem:(BibItem *)item {
	if (key == nil)
		return YES;
	return [item isContainedInGroupNamed:name forField:key];
}

// accessors

- (BOOL)isCategory {
	return YES;
}

- (NSString *)key {
    return [[key retain] autorelease];
}

- (NSImage *)icon {
	return [NSImage smallImageNamed:@"genericFolderIcon"];
}

- (BOOL)isEditable {
    return [[[BibTypeManager sharedManager] personFieldsSet] containsObject:key];
}

@end

#pragma mark -

@implementation BDSKEmptyGroup

- (NSImage *)icon {
    static NSImage *image = nil;
    if(image == nil){
        image = [[NSImage alloc] initWithSize:NSMakeSize(16, 16)];
        NSImage *genericImage = [NSImage smallImageNamed:@"genericFolderIcon"];
        NSImage *questionMark = [NSImage iconWithSize:NSMakeSize(12, 12) forToolboxCode:kQuestionMarkIcon];
        unsigned i;
        [image lockFocus];
        [genericImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:1];
        // hack to make the question mark dark enough to be visible
        for(i = 0; i < 3; i++)
            [questionMark compositeToPoint:NSMakePoint(3, 1) operation:NSCompositeSourceOver];
        [image unlockFocus];
    }
    return image;
}

- (NSString *)stringValue {
    return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Empty", @""), key];
}

- (BOOL)containsItem:(BibItem *)item {
	if (key == nil)
		return YES;
	return [[item groupsForField:key] count] == 0;
}

- (BOOL)hasEditableName {
    return NO;
}

- (BOOL)isEditable {
    return NO;
}

@end

#pragma mark -

@implementation BDSKStaticGroup

static NSString *BDSKLastImportLocalizedString = nil;

+ (void)initialize{
    OBINITIALIZE;
    BDSKLastImportLocalizedString = [NSLocalizedString(@"Last Import", @"group name for last import") copy];
}

- (id)initWithLastImport:(NSArray *)array {
	NSZone *zone = [self zone];
	[[super init] release];
	self = [[BDSKLastImportGroup allocWithZone:zone] initWithName:BDSKLastImportLocalizedString publications:array];
	return self;
}

// designated initializer
- (id)initWithName:(id)aName publications:(NSArray *)array {
    if (self = [super initWithName:aName count:[array count]]) {
        publications = [array mutableCopy];
		undoManager = nil;
    }
    return self;
}

// super's designated initializer
- (id)initWithName:(id)aName count:(int)aCount {
    self = [self initWithName:aName publications:[NSArray array]];
    return self;
}

- (void)dealloc {
	[[self undoManager] removeAllActionsWithTarget:self];
    [undoManager release];
    [publications release];
    [super dealloc];
}

- (NSImage *)icon {
	return [NSImage smallImageNamed:@"staticFolderIcon"];
}

- (BOOL)isStatic {
    return YES;
}

- (void)setName:(id)newName {
    if (name != newName) {
		[(BDSKStaticGroup *)[[self undoManager] prepareWithInvocationTarget:self] setName:name];
        [name release];
        name = [newName retain];
    }
}

- (NSArray *)publications {
    return publications;
}

- (void)setPublications:(NSArray *)newPublications {
    if (newPublications != publications) {
		[[[self undoManager] prepareWithInvocationTarget:self] setPublications:publications];
        [publications release];
        publications = [newPublications retain];
        [self setCount:[publications count]];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKStaticGroupChangedNotification object:self];
    }
}

- (void)addPublication:(BibItem *)item {
    if ([publications containsObjectIdenticalTo:item] == YES)
        return;
    [[[self undoManager] prepareWithInvocationTarget:self] removePublication:item];
    [publications addObject:item];
    [self setCount:[publications count]];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKStaticGroupChangedNotification object:self];
}

- (void)addPublicationsFromArray:(NSArray *)items {
    if ([publications firstObjectCommonWithArray:items]) {
        NSMutableArray *mutableItems = [items mutableCopy];
        [mutableItems removeObjectsInArray:publications];
        items = [mutableItems autorelease];
        if ([items count] == 0)
            return;
    }
    [[[self undoManager] prepareWithInvocationTarget:self] removePublicationsInArray:items];
    [publications addObjectsFromArray:items];
    [self setCount:[publications count]];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKStaticGroupChangedNotification object:self];
}

- (void)removePublication:(BibItem *)item {
    if ([publications containsObjectIdenticalTo:item] == NO)
        return;
    [[[self undoManager] prepareWithInvocationTarget:self] addPublication:item];
    [publications removeObject:item];
    [self setCount:[publications count]];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKStaticGroupChangedNotification object:self];
}

- (void)removePublicationsInArray:(NSArray *)items {
    [[[self undoManager] prepareWithInvocationTarget:self] addPublicationsFromArray:items];
    [publications removeObjectsInArray:items];
    [self setCount:[publications count]];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKStaticGroupChangedNotification object:self];
}

- (BOOL)containsItem:(BibItem *)item {
	return [publications containsObject:item];
}

- (NSUndoManager *)undoManager {
    return undoManager;
}

- (void)setUndoManager:(NSUndoManager *)newUndoManager {
    if (undoManager != newUndoManager) {
        [undoManager release];
        undoManager = [newUndoManager retain];
    }
}

@end

#pragma mark -

@implementation BDSKLastImportGroup

- (NSImage *)icon {
	return [NSImage smallImageNamed:@"importFolderIcon"];
}

- (BOOL)hasEditableName {
    return NO;
}

- (BOOL)isEditable {
    return NO;
}

@end

#pragma mark -

@implementation BDSKSmartGroup

// super's designated initializer
- (id)initWithName:(id)aName count:(int)aCount {
    BDSKFilter *aFilter = [[BDSKFilter alloc] init];
	self = [self initWithName:aName count:aCount filter:aFilter];
	[aFilter release];
    return self;
}

// designated initializer
- (id)initWithName:(id)aName count:(int)aCount filter:(BDSKFilter *)aFilter {
    if (self = [super initWithName:aName count:aCount]) {
        filter = [aFilter copy];
		undoManager = nil;
		[filter setUndoManager:nil];
    }
    return self;
}

- (id)initWithFilter:(BDSKFilter *)aFilter {
	NSString *aName = nil;
	if ([[aFilter conditions] count] > 0)
		aName = [[[aFilter conditions] objectAtIndex:0] value];
	if ([NSString isEmptyString:aName])
		aName = NSLocalizedString(@"Smart Group", @"Smart group");
	self = [self initWithName:aName count:0 filter:aFilter];
	return self;
}

// NSCoding protocol

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		filter = [[decoder decodeObjectForKey:@"filter"] retain];
		undoManager = nil;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:filter forKey:@"filter"];
}

// NSCopying protocol

- (id)copyWithZone:(NSZone *)aZone {
	id copy = [[[self class] allocWithZone:aZone] initWithName:name count:count filter:filter];
	return copy;
}

- (void)dealloc {
	[[self undoManager] removeAllActionsWithTarget:self];
    [undoManager release];
    [filter release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
	if ([super isEqual:other])
		return [[self filter] isEqual:[(BDSKSmartGroup *)other filter]];
	else return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, filter={ %@ }", [super description], filter];
}

// "static" properties

- (BOOL)isSmart {
	return YES;
}

- (NSImage *)icon {
	return [NSImage smallImageNamed:@"smartFolderIcon"];
}

// accessors

- (void)setName:(id)newName {
    if (name != newName) {
		[(BDSKSmartGroup *)[[self undoManager] prepareWithInvocationTarget:self] setName:name];
        [name release];
        name = [newName retain];
    }
}

- (BDSKFilter *)filter {
    return [[filter retain] autorelease];
}

- (void)setFilter:(BDSKFilter *)newFilter {
    if (filter != newFilter) {
		[[[self undoManager] prepareWithInvocationTarget:self] setFilter:filter];
        [filter release];
        filter = [newFilter copy];
		[filter setUndoManager:undoManager];
    }
}

- (NSUndoManager *)undoManager {
    return undoManager;
}

- (void)setUndoManager:(NSUndoManager *)newUndoManager {
    if (undoManager != newUndoManager) {
        [undoManager release];
        undoManager = [newUndoManager retain];
		[filter setUndoManager:undoManager];
    }
}

- (BOOL)containsItem:(BibItem *)item {
	return [filter testItem:item];
}

- (NSArray *)filterItems:(NSArray *)items {
	NSArray *filteredItems = [filter filterItems:items];
	[self setCount:[filteredItems count]];
	return filteredItems;
}

- (BOOL)isEditable {
    return YES;
}

@end

#pragma mark NSString category for KVC

@interface NSString (BDSKGroup) @end

// this exists so we can use valueForKey: in the BDSKGroupCell
@implementation NSString (BDSKGroup)
- (NSString *)stringValue { return self; }
// OmniFoundation implements numberValue for us
- (int)count { return [[self numberValue] intValue]; }
@end

