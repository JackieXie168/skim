//
//  BDSKGroup.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 8/11/05.
/*
 This software is Copyright (c) 2005
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
#import <OmniBase/OBUtilities.h>


// a private subclass for the All Publication group
@interface BDSKAllPublicationsGroup : BDSKGroup {
} 
@end


@implementation BDSKGroup

- (id)init {
	self = [self initWithName:NSLocalizedString(@"Group", @"Group") key:nil count:0];
    return self;
}

- (id)initWithAllPublications {
	NSZone *zone = [self zone];
	[[super init] release];
	self = [[BDSKAllPublicationsGroup allocWithZone:zone] init];
	return self;
}

// designated initializer
- (id)initWithName:(id)aName key:(NSString *)aKey count:(int)aCount {
    if (self = [super init]) {
        key = [aKey copy];
        name = [aName copy];
        count = aCount;
    }
    return self;
}

// NSCoding protocol

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		name = [[decoder decodeObjectForKey:@"name"] retain];
		key = [[decoder decodeObjectForKey:@"key"] retain];
		count = [decoder decodeIntForKey:@"count"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:name forKey:@"name"];
	[coder encodeObject:key forKey:@"key"];
	[coder encodeInt:count forKey:@"count"];
}

// NSCopying protocol

- (id)copyWithZone:(NSZone *)aZone {
	id copy = [[[self class] allocWithZone:aZone] initWithName:name key:key count:count];
	return copy;
}

- (void)dealloc {
    [key release];
    [name release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
	if (self == other)
		return YES;
	if (![other isMemberOfClass:[self class]]) 
		return NO;
	// we don't care about the count for identification
	return (([[self key] isEqualToString:[other key]] || ([self key] == nil && [other key] == nil)) &&
			[[self name] isEqual:[(BDSKGroup *)other name]]);
}

// accessors

- (id)name {
    return [[name retain] autorelease];
}

- (NSString *)key {
    return [[key retain] autorelease];
}

- (int)count {
    return count;
}

- (void)setCount:(int)newCount {
	count = newCount;
}

// "static" accessors

- (NSImage *)icon {
	return [NSImage smallImageNamed:@"genericFolderIcon"];
}

- (BOOL)isSmart {
	return NO;
}

// custom acessors

- (NSString *)stringValue {
	if ([name isKindOfClass:[NSString class]])
		return (NSString *)[self name];
	else if ([name respondsToSelector:@selector(stringValue)])
		return [[self name] stringValue];
	else 
		return [[self name] description];
}

- (NSNumber *)numberValue {
	return [NSNumber numberWithInt:count];
}

// comparisons

- (NSComparisonResult)nameCompare:(BDSKGroup *)otherGroup {
	id myName = [self name];
	id otherName = [otherGroup name];
	
	if ([myName isKindOfClass:[BibAuthor class]] && [otherName isKindOfClass:[BibAuthor class]]) 
		return [(BibAuthor *)myName sortCompare:(BibAuthor *)otherName];
	
	myName = [self stringValue];
	otherName = [otherGroup stringValue];
	if ([NSString isEmptyString:myName]) {
		return ([NSString isEmptyString:otherName])? NSOrderedSame : NSOrderedDescending;
	} else if ([NSString isEmptyString:otherName]) {
		return NSOrderedAscending;
	}
	return [myName localizedCaseInsensitiveNumericCompare:otherName];
}

- (NSComparisonResult)countCompare:(BDSKGroup *)otherGroup {
	return [[self numberValue] compare:[otherGroup numberValue]];
}

- (BOOL)containsItem:(BibItem *)item {
	if (key == nil)
		return YES;
	return [item isContainedInGroupNamed:name forField:key];
}

@end


@implementation BDSKAllPublicationsGroup

static NSString *BDSKAllPublicationsLocalizedString = nil;

+ (void)initialize{
    OBINITIALIZE;
    BDSKAllPublicationsLocalizedString = [NSLocalizedString(@"All Publications", @"group name for all pubs") copy];
}

- (id)init {
	self = [super initWithName:BDSKAllPublicationsLocalizedString key:nil count:0];
    return self;
}

- (NSImage *)icon {
    // this icon looks better than the one we get from +[NSImage imageNamed:@"FolderPenIcon"] or smallImageNamed:
    static NSImage *image = nil;
    if(nil == image)
        image = [[[NSWorkspace sharedWorkspace] iconForFile:[[NSBundle mainBundle] bundlePath]] copy];
    
	return image;
}
 
@end


@implementation BDSKSmartGroup

// old designated initializer
- (id)initWithName:(id)aName count:(int)aCount {
    BDSKFilter *aFilter = [[BDSKFilter alloc] init];
	self = [self initWithName:aName count:aCount filter:aFilter];
	[aFilter release];
    return self;
}

// designated initializer
- (id)initWithName:(id)aName count:(int)aCount filter:(BDSKFilter *)aFilter {
    if (self = [super initWithName:aName key:nil count:aCount]) {
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
    [filter release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
	if ([super isEqual:other])
		return [[self filter] isEqual:[(BDSKSmartGroup *)other filter]];
	else return NO;
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

@end
