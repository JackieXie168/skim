//
//  BDSKFilter.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKFilter.h"


@implementation BDSKFilter

- (id)init {
	self = [self initWithConditions:[NSArray arrayWithObject:[[[BDSKCondition alloc] init] autorelease]]];
	return self;
}

- (id)initWithConditions:(NSArray *)newConditions {
	if (self = [super init]) {
		conditions = [newConditions mutableCopy];
		conjunction = BDSKAnd;
		enabled = NO;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		conditions = [[decoder decodeObjectForKey:@"conditions"] retain];
		conjunction = [decoder decodeIntForKey:@"conjunction"];
		enabled = [decoder decodeBoolForKey:@"enabled"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:conditions forKey:@"conditions"];
	[coder encodeInt:conjunction forKey:@"conjunction"];
	[coder encodeBool:enabled forKey:@"enabled"];
}

- (void)dealloc {
	[conditions release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)aZone {
	BDSKFilter *copy = [[BDSKFilter allocWithZone:aZone] initWithConditions:[self conditions]];
	[copy setConjunction:[self conjunction]];
	[copy setEnabled:[self enabled]];
	return copy;
}

- (NSArray *)filterItems:(NSArray *)items {
	NSMutableArray *filteredItems = [NSMutableArray array];
	NSEnumerator *itemE = [items objectEnumerator];
	id item;
	
	if (![self enabled]) 
		return items;
	
	while (item = [itemE nextObject]) {
		if ([self testItem:item]) {
			[filteredItems addObject:item];
		}
	}
	return filteredItems;
}

- (BOOL)testItem:(id<BDSKFilterItem>)item {
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
        [conditions release];
        conditions = [newConditions mutableCopy];
    }
}

- (BOOL)enabled {
    return enabled;
}

- (void)setEnabled:(BOOL)newEnabled {
	enabled = newEnabled;
}

- (BDSKConjunction)conjunction {
    return conjunction;
}

- (void)setConjunction:(BDSKConjunction)newConjunction {
	conjunction = newConjunction;
}

@end
