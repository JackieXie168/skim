//
//  BDSKCondition.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKCondition.h"


@implementation BDSKCondition

- (id)init {
    self = [super init];
    if (self) {
        key = [@"" retain];
        value = [@"" retain];
        comparison = BDSKContain;
        itemType = BDSKPublicationType;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		key = [[decoder decodeObjectForKey:@"key"] retain];
		value = [[decoder decodeObjectForKey:@"value"] retain];
		comparison = [decoder decodeIntForKey:@"comparison"];
		itemType = [decoder decodeIntForKey:@"itemType"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:key forKey:@"key"];
	[coder encodeObject:value forKey:@"value"];
	[coder encodeInt:comparison forKey:@"comparison"];
	[coder encodeInt:itemType forKey:@"itemType"];
}

- (void)dealloc {
	//NSLog(@"dealloc condition");
    [key release];
    key  = nil;
    [value release];
    value  = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)aZone {
	BDSKCondition *copy = [[BDSKCondition allocWithZone:aZone] init];
	[copy setKey:[self key]];
	[copy setValue:[self value]];
	[copy setComparison:[self comparison]];
	[copy setItemType:[self itemType]];
	return copy;
}

- (BOOL)isEqual:(id)other {
	if (![other isKindOfClass:[BDSKCondition class]]) 
		return NO;
	return [[self key] isEqualToString:[other key]] &&
		   [[self value] isEqualToString:[other value]] &&
		   [self comparison] == [other comparison] &&
		   [self itemType] == [other itemType];
}

- (BOOL)isSatisfiedByItem:(id<BDSKFilterItem>)item {
	if (![item isKindOfClass:[self itemClass]]) 
		return NO;
	if (key == nil || value == nil) 
		return YES;
	
	NSString *itemValue = [item filterValueForKey:key];
	
	if (itemValue == nil)
		return NO;
	unsigned options = NSCaseInsensitiveSearch;
	if (comparison == BDSKEndWith)
		options = options | NSBackwardsSearch;
	NSRange range = [itemValue rangeOfString:value options:options];
	
	switch (comparison) {
		case BDSKContain:
			return range.location != NSNotFound;
		case BDSKNotContain:
			return range.location == NSNotFound;
		case BDSKEqual:
			return range.length == [itemValue length];
		case BDSKNotEqual:
			return range.length != [itemValue length];
		case BDSKStartWith:
			return range.location != NSNotFound && range.location == 0;
		case BDSKEndWith:
			return range.location != NSNotFound && NSMaxRange(range) == [itemValue length];
	}
}

- (NSString *)key {
    return [[key retain] autorelease];
}

- (void)setKey:(NSString *)newKey {
    if (![key isEqualToString:newKey]) {
        [key release];
        key = [newKey copy];
    }
}

- (NSString *)value {
    return [[value retain] autorelease];
}

- (void)setValue:(NSString *)newValue {
	if (![value isEqualToString:newValue]) {
        [value release];
        value = [newValue copy];
    }
}

- (BDSKComparison)comparison {
    return comparison;
}

- (void)setComparison:(BDSKComparison)newComparison {
    comparison = newComparison;
}

- (BDSKItemType)itemType {
    return itemType;
}

- (void)setItemType:(BDSKItemType)newItemType {
    if (itemType != newItemType) {
        itemType = newItemType;
    }
}

- (NSString *)itemClassName {
	switch (itemType) {
		case BDSKPublicationType:
			return @"BibItem";
		case BDSKAuthorType:
			return @"BibAuthor";
		case BDSKNoteType:
			return @"BibNote";
	}
}

- (Class)itemClass {
	return NSClassFromString([self itemClassName]);
}

@end
