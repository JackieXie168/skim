//
//  BDSKSmartGroup.m
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

#import "BDSKSmartGroup.h"
#import "BDSKFilter.h"
#import "NSImage+Toolbox.h"
#import "BibItem.h"


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
		[filter setUndoManager:nil];
    }
    return self;
}

- (id)initWithFilter:(BDSKFilter *)aFilter {
	NSString *aName = nil;
	if ([[aFilter conditions] count] > 0)
		aName = [[[aFilter conditions] objectAtIndex:0] value];
	if ([NSString isEmptyString:aName])
		aName = NSLocalizedString(@"Smart Group", @"Default name for smart group");
	self = [self initWithName:aName count:0 filter:aFilter];
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        filter = [[decoder decodeObjectForKey:@"filter"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:filter forKey:@"filter"];
}

- (void)dealloc {
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

- (BOOL)isSmart { return YES; }

- (BOOL)isEditable { return YES; }

- (BOOL)isValidDropTarget { return NO; }

- (NSImage *)icon {
	return [NSImage smallImageNamed:@"smartFolderIcon"];
}

// accessors

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

- (void)setUndoManager:(NSUndoManager *)newUndoManager{
    [super setUndoManager:newUndoManager];
    [filter setUndoManager:newUndoManager];
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
