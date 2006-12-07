//
//  BDSKCondition.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
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

#import "BDSKCondition.h"
#import "BibItem.h"
#import "NSString_BDSKExtensions.h"
#import <OmniBase/assertions.h>
#import "BDSKDateStringFormatter.h"

@interface BDSKCondition (Private)
- (NSDate *)cachedDate;
- (void)setCachedDate:(NSDate *)newCachedDate;
- (void)setCachedDateFromString:(NSString *)dateString;
- (void)refreshCachedDate:(NSTimer *)timer;
@end

@implementation BDSKCondition

- (id)init {
    self = [super init];
    if (self) {
        key = [@"" retain];
        value = [@"" retain];
        comparison = BDSKContain;
		cachedDate = nil;
		cacheTimer = nil;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
	if (self = [self init]) {
		NSString *aKey = [dictionary objectForKey:@"key"];
		NSMutableString *escapedValue = [[dictionary objectForKey:@"value"] mutableCopy];
		NSNumber *comparisonNumber = [dictionary objectForKey:@"comparison"];
		
		if (aKey != nil) 
			[self setKey:aKey];
		
		if (escapedValue != nil) {
			// we escape braces as they can give problems with btparse
			[escapedValue replaceAllOccurrencesOfString:@"%7B" withString:@"{"];
			[escapedValue replaceAllOccurrencesOfString:@"%7D" withString:@"}"];
			[escapedValue replaceAllOccurrencesOfString:@"%25" withString:@"%"];
			[self setValue:escapedValue];
			[escapedValue release];
        }
		
		if (comparisonNumber != nil) 
			[self setComparison:[comparisonNumber intValue]];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		key = [[decoder decodeObjectForKey:@"key"] retain];
		value = [[decoder decodeObjectForKey:@"value"] retain];
		comparison = [decoder decodeIntForKey:@"comparison"];
		OBASSERT(key != nil);
		OBASSERT(value != nil);
		cachedDate = nil;
		cacheTimer = nil;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:key forKey:@"key"];
	[coder encodeObject:value forKey:@"value"];
	[coder encodeInt:comparison forKey:@"comparison"];
}

- (void)dealloc {
	//NSLog(@"dealloc condition");
    [key release];
    key  = nil;
    [value release];
    value  = nil;
    [cachedDate release];
    cachedDate  = nil;
    [cacheTimer invalidate];
    cacheTimer  = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)aZone {
	BDSKCondition *copy = [[BDSKCondition allocWithZone:aZone] init];
	[copy setKey:[self key]];
	[copy setValue:[self value]];
	[copy setComparison:[self comparison]];
	return copy;
}

- (NSDictionary *)dictionaryValue {
	NSNumber *comparisonNumber = [NSNumber numberWithInt:comparison];
	NSMutableString *escapedValue = [value mutableCopy];
	// escape braces as they can give problems with btparse
	[escapedValue replaceAllOccurrencesOfString:@"%" withString:@"%25"];
	[escapedValue replaceAllOccurrencesOfString:@"{" withString:@"%7B"];
	[escapedValue replaceAllOccurrencesOfString:@"}" withString:@"%7D"];
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:key, @"key", escapedValue, @"value", comparisonNumber, @"comparison", nil];
	[escapedValue release];
	return [dict autorelease];
}

- (BOOL)isEqual:(id)other {
	if (self == other)
		return YES;
	if (![other isKindOfClass:[BDSKCondition class]]) 
		return NO;
	return [[self key] isEqualToString:[(BDSKCondition *)other key]] &&
		   [[self value] isEqualToString:[(BDSKCondition *)other value]] &&
		   [self comparison] == [(BDSKCondition *)other comparison];
}

- (BOOL)isSatisfiedByItem:(BibItem *)item {
	if ([NSString isEmptyString:key] == YES) 
		return YES; // empty condition matches anything
	
	OBASSERT(value != nil);
	
	if (comparison == BDSKGroupContain) 
		return ([item isContainedInGroupNamed:value forField:key] == YES);
	if (comparison == BDSKGroupNotContain) 
		return ([item isContainedInGroupNamed:value forField:key] == NO);
	
	NSString *itemValue = [item valueOfGenericField:key];
	// unset values are considered empty strings
	if (itemValue == nil)
		itemValue = @"";
	// to speed up comparisons
	if ([itemValue isComplex] || [itemValue isInherited])
		itemValue = [NSString stringWithString:itemValue];
	
	if (comparison == BDSKEqual) 
		return ([value caseInsensitiveCompare:itemValue] == NSOrderedSame);
	if (comparison == BDSKNotEqual) 
		return ([value caseInsensitiveCompare:itemValue] != NSOrderedSame);
	
	unsigned options = NSCaseInsensitiveSearch;
	if (comparison == BDSKEndWith)
		options = options | NSBackwardsSearch;
	NSRange range = [itemValue rangeOfString:value options:options];
	
	switch (comparison) {
		case BDSKContain:
			return range.location != NSNotFound;
		case BDSKNotContain:
			return range.location == NSNotFound;
		case BDSKStartWith:
			return range.location != NSNotFound && range.location == 0;
		case BDSKEndWith:
			return range.location != NSNotFound && NSMaxRange(range) == [itemValue length];
        default:
            break; // other enum types are handled before the switch, but the compiler doesn't know that
	}
	
	NSComparisonResult result;
	if ([key isEqualToString:BDSKDateCreatedString])
		result = [cachedDate compare:[item dateCreated]];
	else if ([key isEqualToString:BDSKDateModifiedString])
		result = [cachedDate compare:[item dateModified]];
	else
		result = [value localizedCaseInsensitiveNumericCompare:itemValue];
	if (comparison == BDSKSmaller) 
		return (result == NSOrderedDescending);
	if (comparison == BDSKLarger) 
		return (result == NSOrderedAscending);
	
	OBASSERT_NOT_REACHED("undefined comparison");
    return NO;
}

- (NSString *)key {
    return [[key retain] autorelease];
}

- (void)setKey:(NSString *)newKey {
	// we never want the key to be nil. It is set to nil sometimes by the binding mechanism
	if (newKey == nil) newKey = @"";
    if (![key isEqualToString:newKey]) {
        [key release];
        key = [newKey copy];
		if ([self isDateCondition] && [NSString isEmptyString:value] == NO)
			[self setCachedDateFromString:value];
    }
}

- (NSString *)value {
    return [[value retain] autorelease];
}

- (void)setValue:(NSString *)newValue {
	// we never want the value to be nil. It is set to nil sometimes by the binding mechanism
	if (newValue == nil) newValue = @"";
	if (![value isEqualToString:newValue]) {
        [value release];
        value = [newValue copy];
		if ([self isDateCondition])
			[self setCachedDateFromString:value];
    }
}

- (BDSKComparison)comparison {
    return comparison;
}

- (void)setComparison:(BDSKComparison)newComparison {
    comparison = newComparison;
}

- (BOOL)isDateCondition {
    return ([key isEqualToString:BDSKDateCreatedString] || [key isEqualToString:BDSKDateModifiedString]);
}

- (BOOL)validateKey:(id *)ioValue error:(NSError **)error {
    if([*ioValue isEqualToString:BDSKDateCreatedString] || [*ioValue isEqualToString:BDSKDateModifiedString]){
        if([self comparison] != BDSKSmaller || [self comparison] != BDSKLarger)
            [self setComparison:BDSKSmaller];
    }
    return YES;
}    
    
- (BOOL)validateComparison:(id *)ioValue error:(NSError **)error {
    if([self isDateCondition]){
        if([*ioValue isEqual:[NSNumber numberWithInt:BDSKSmaller]] || [*ioValue isEqual:[NSNumber numberWithInt:BDSKLarger]]) {
            return YES;
        } else {
            *ioValue = [NSNumber numberWithInt:BDSKSmaller];
            if(error != nil) {
                NSString *description = NSLocalizedString(@"At present, only \"comes before\" and \"comes after\" comparisons are supported for dates.", @"");
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, nil];
                *error = [NSError errorWithDomain:@"BDSKConditionErrorDomain" code:1 userInfo:userInfo];
            }
            return NO;
        }
    }
    return YES;
}

@end

@implementation BDSKCondition (Private)

- (NSDate *)cachedDate {
    return cachedDate;
}

- (void)setCachedDate:(NSDate *)newCachedDate {
    if (cachedDate != newCachedDate) {
        [cachedDate release];
        cachedDate = [newCachedDate retain];
	}
}

- (void)setCachedDateFromString:(NSString *)dateString {
	NSDate *date = nil;
	[cacheTimer invalidate];
	cacheTimer = nil;
	if ([NSString isEmptyString:dateString] == NO) {
		date = [[BDSKDateStringFormatter shortDateNaturalLanguageFormatter] dateFromString:dateString];
		if (date != nil){
			NSTimeInterval timeInterval = ABS([date timeIntervalSinceNow]);
			NSTimeInterval refreshInterval;
			if (timeInterval < 7200) // 2 hours
				refreshInterval = 900; // 1/4 hour
			else if (timeInterval < 43200) // 1/2 day
				refreshInterval = 3600; // 1 hour
			else if (timeInterval < 172800) // 2 days
				refreshInterval = 21600; // 1/4 day
			else 
				refreshInterval = 86400; // 1 day
            // Must pass the string, not the date object, since this may be a colloquial expression.
			cacheTimer = [NSTimer scheduledTimerWithTimeInterval:refreshInterval target:self selector:@selector(refreshCachedDate:) userInfo:dateString repeats:YES];
        }
	}
	[self setCachedDate:date];
}

- (void)refreshCachedDate:(NSTimer *)timer {
	NSDate *date = [[BDSKDateStringFormatter shortDateNaturalLanguageFormatter] dateFromString:[timer userInfo]];
	if ([cachedDate compare:date] != NSOrderedSame) {
        [self setCachedDate:date];
		[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFilterChangedNotification
															object:self
														  userInfo:[NSDictionary dictionary]];
	}
}

@end
