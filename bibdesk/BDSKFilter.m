//
//  BDSKFilter.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
/*
 This software is Copyright (c) 2005,2006,2007
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

#import "BDSKFilter.h"
#import <OmniFoundation/NSArray-OFExtensions.h>


@implementation BDSKFilter

- (id)init {
	BDSKCondition *condition = [[BDSKCondition alloc] init];
	NSArray *newConditions = [[NSArray alloc] initWithObjects:condition, nil];
	self = [self initWithConditions:newConditions];
	[condition release];
	[newConditions release];
	return self;
}

- (id)initWithConditions:(NSArray *)newConditions {
	if (self = [super init]) {
		conditions = [newConditions mutableCopy];
		conjunction = BDSKAnd;
		undoManager = nil;
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
	NSMutableArray *newConditions = [NSMutableArray arrayWithCapacity:1];
	NSEnumerator *cEnum = [[dictionary objectForKey:@"conditions"] objectEnumerator];
	NSDictionary *dict;
	BDSKCondition *condition;
	
	while (dict = [cEnum nextObject]) {
		condition = [[BDSKCondition alloc] initWithDictionary:dict];
		[newConditions addObject:condition];
		[condition release];
	}
	
	if ([newConditions count] > 0)
		self = [self initWithConditions:newConditions];
	else
		self = [self init];
	if (self) {
		conjunction = [[dictionary objectForKey:@"conjunction"] intValue];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		conditions = [[decoder decodeObjectForKey:@"conditions"] retain];
		conjunction = [decoder decodeIntForKey:@"conjunction"];
		undoManager = nil;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:conditions forKey:@"conditions"];
	[coder encodeInt:conjunction forKey:@"conjunction"];
}

- (void)dealloc {
	[[self undoManager] removeAllActionsWithTarget:self];
    [undoManager release];
	[conditions release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)aZone {
	BDSKFilter *copy = [[BDSKFilter allocWithZone:aZone] initWithConditions:[self conditions]];
	[copy setConjunction:[self conjunction]];
	return copy;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ conditions=\"%@\" conjunction=\"%@\"", [super description], conditions, (conjunction == BDSKAnd ? @"AND" : @"OR")];
}

- (NSDictionary *)dictionaryValue {
	NSArray *conditionArray = [conditions arrayByPerformingSelector:@selector(dictionaryValue)];
	NSNumber *conjunctionNumber = [NSNumber numberWithInt:conjunction];
	return [NSDictionary dictionaryWithObjectsAndKeys:conjunctionNumber, @"conjunction", conditionArray, @"conditions", nil];
}

- (BOOL)isEqual:(id)other {
	if (self == other)
		return YES;
	if (![other isKindOfClass:[BDSKFilter class]]) 
		return NO;
	return [[self conditions] isEqualToArray:[(BDSKFilter *)other conditions]] &&
		   [self conjunction] == [(BDSKFilter *)other conjunction];
}

- (NSArray *)filterItems:(NSArray *)items {
	NSMutableArray *filteredItems = [NSMutableArray array];
	NSEnumerator *itemE = [items objectEnumerator];
	id item;
	
	while (item = [itemE nextObject]) {
		if ([self testItem:item]) {
			[filteredItems addObject:item];
		}
	}
	return filteredItems;
}

- (BOOL)testItem:(BibItem *)item {
	if ([conditions count] == 0)
		return YES;
	
	NSEnumerator *condE = [conditions objectEnumerator];
	BDSKCondition *condition;
	BOOL isOr = (conjunction == BDSKOr);
	
	while (condition = [condE nextObject]) {
		if ([condition isSatisfiedByItem:item] == isOr) {
			return isOr;
		}
	}
	return !isOr;
}

- (NSArray *)conditions {
    return [[conditions retain] autorelease];
}

- (void)setConditions:(NSArray *)newConditions {
    if (![conditions isEqualToArray:newConditions]) {
		[[[self undoManager] prepareWithInvocationTarget:self] setConditions:conditions];
        
		[conditions release];
        conditions = [newConditions mutableCopy];
		
		if ([self undoManager]) { // only notify when we are attched to a group
			[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFilterChangedNotification
																object:self
															  userInfo:[NSDictionary dictionary]];
		}
	}
}

- (BDSKConjunction)conjunction {
    return conjunction;
}

- (void)setConjunction:(BDSKConjunction)newConjunction {
	[[[self undoManager] prepareWithInvocationTarget:self] setConjunction:conjunction];
	
	conjunction = newConjunction;
	
	if ([self undoManager]) { // only notify when we are attched to a group
		[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFilterChangedNotification
															object:self
														  userInfo:[NSDictionary dictionary]];
	}
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
