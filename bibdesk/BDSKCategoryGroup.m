//
//  BDSKCategoryGroup.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/21/06.
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

#import "BDSKCategoryGroup.h"
#import "NSImage+Toolbox.h"
#import "BibItem.h"
#import "BibAuthor.h"
#import "BibTypeManager.h"


// a private subclass for the Empty ... group
@interface BDSKEmptyGroup : BDSKCategoryGroup @end


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
    id aName = ([aKey isPersonField]) ? [BibAuthor emptyAuthor] : @"";
    return [[BDSKEmptyGroup allocWithZone:zone] initWithName:aName key:aKey count:aCount];
}

- (id)initWithDictionary:(NSDictionary *)groupDict {
    NSString *aName = [[groupDict objectForKey:@"group name"] stringByUnescapingGroupPlistEntities];
    NSString *aKey = [[groupDict objectForKey:@"key"] stringByUnescapingGroupPlistEntities];
    self = [self initWithName:aName key:aKey count:0];
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSString *aName = [[self stringValue] stringByEscapingGroupPlistEntities];
    NSString *aKey = [[self key] stringByEscapingGroupPlistEntities];
    return [NSDictionary dictionaryWithObjectsAndKeys:aName, @"group name", aKey, @"key", nil];
}

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

- (void)dealloc {
    [key release];
    [super dealloc];
}

// name can change, but key doesn't change, and it's also required for equality
- (unsigned int)hash {
    return [key hash];
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

- (NSString *)key {
    return [[key retain] autorelease];
}

- (NSImage *)icon {
	return [NSImage smallImageNamed:@"genericFolderIcon"];
}

- (BOOL)isCategory { return YES; }

- (BOOL)hasEditableName { return YES; }

- (BOOL)isEditable {
    return [key isPersonField];
}

- (BOOL)isValidDropTarget { return YES; }

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

- (BOOL)hasEditableName { return NO; }

- (BOOL)isEditable { return NO; }

- (BOOL)isValidDropTarget { return NO; }

- (BOOL)isEqual:(id)other { return self == other; }

- (unsigned int)hash {
    return( ((unsigned int) self >> 4) | (unsigned int) self << (32 - 4));
}

@end
