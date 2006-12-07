// BDSKComplexString.m
// Created by Michael McCracken, 2004
/*
 This software is Copyright (c) 2004,2005
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

#import "BDSKComplexString.h"
#import "NSString_BDSKExtensions.h"
#import <OmniFoundation/NSMutableString-OFExtensions.h>
#import <OmniBase/OmniBase.h>

static NSCharacterSet *macroCharSet = nil;

@implementation BDSKStringNode

+ (BDSKStringNode *)nodeWithQuotedString:(NSString *)s{
    BDSKStringNode *node = [[BDSKStringNode alloc] initWithType:BSN_STRING value:s];
	return [node autorelease];
}

+ (BDSKStringNode *)nodeWithNumberString:(NSString *)s{
    BDSKStringNode *node = [[BDSKStringNode alloc] initWithType:BSN_NUMBER value:s];
	return [node autorelease];
}

+ (BDSKStringNode *)nodeWithMacroString:(NSString *)s{
    BDSKStringNode *node = [[BDSKStringNode alloc] initWithType:BSN_MACRODEF value:s];
	return [node autorelease];
}

- (BDSKStringNode *)initWithQuotedString:(NSString *)s{
    return [self initWithType:BSN_STRING value:s];
}

- (BDSKStringNode *)initWithNumberString:(NSString *)s{
    return [self initWithType:BSN_NUMBER value:s];
}

- (BDSKStringNode *)initWithMacroString:(NSString *)s{
    return [self initWithType:BSN_MACRODEF value:s];
}

- (id)init{
	self = [self initWithType:BSN_STRING value:@""];
	return self;
}

- (id)initWithType:(BDSKStringNodeType)aType value:(NSString *)s{
	if (self = [super init]) {
		type = aType;
		value = [s copy];
	}
	return self;
}

- (void)dealloc{
    [value release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone{
    return NSShouldRetainWithZone(self, zone) ? [self retain] : [[BDSKStringNode allocWithZone:zone] initWithType:type value:value];
}

- (id)initWithCoder:(NSCoder *)coder{
	if (self = [super init]) {
		type = [coder decodeIntForKey:@"type"];
		value = [[coder decodeObjectForKey:@"value"] retain];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder{
	[encoder encodeInt:type forKey:@"type"];
    [encoder encodeObject:value forKey:@"value"];
}

- (BOOL)isEqual:(BDSKStringNode *)other{
    if(type == [other type] &&
       [value isEqualToString:[other value]])
        return YES;
    return NO;
}

- (NSComparisonResult)compareNode:(BDSKStringNode *)aNode{
	return [self compareNode:aNode options:0];
}

- (NSComparisonResult)compareNode:(BDSKStringNode *)aNode options:(unsigned)mask{
	if (type < [aNode type])
		return NSOrderedAscending;
	if (type > [aNode type])
		return NSOrderedDescending;
	return [value compare:[aNode value] options:mask];
}

- (BDSKStringNodeType)type {
    return type;
}

- (NSString *)value {
    return value;
}

- (NSString *)description{
    return [NSString stringWithFormat:@"type: %d, %@", type, value];
}

@end

#pragma mark -
#pragma mark Private complex string expansion

// stores system-defined macros for the months.
// we grab their localized versions for display.
static NSDictionary *globalMacroDefs; 

// look up a macro definition from the preferences dictionary
static inline
CFStringRef __BDGetValueOfMacroFromPreferences(CFStringRef aMacro)
{
    CFPropertyListRef dict = CFPreferencesCopyAppValue((CFStringRef)BDSKBibStyleMacroDefinitionsKey, kCFPreferencesCurrentApplication);
    if(dict == NULL)
        return NULL;
    
    CFMutableStringRef lcMacro = CFStringCreateMutableCopy(CFAllocatorGetDefault(), 0, aMacro);
    CFStringLowercase(lcMacro, NULL);
    CFStringRef val = CFDictionaryGetValue(dict, lcMacro);
    CFRelease(lcMacro);
    CFRelease(dict);
    
    return val;
}

static inline
CFStringRef __BDResolveMacro(id <BDSKMacroResolver>macroResolver, CFStringRef nodeVal)
{
    CFStringRef expandedValue = nil;
    if(macroResolver && (expandedValue = (CFStringRef)[macroResolver valueOfMacro:(NSString *)nodeVal]))
        return expandedValue;

    // there was no expansion. Check the system global dict first.
    expandedValue = (CFStringRef)[globalMacroDefs objectForKey:(NSString *)nodeVal];

    return expandedValue ? expandedValue : __BDGetValueOfMacroFromPreferences(nodeVal);
}   

/*
 This function is an example of how to subvert object-oriented programming; it depends on implementation details of the objects and accesses fields directly.  This is justified since the complex string expansion is a low-level function that gets called by the NSString primitive methods, and it needs to be as fast as possible.  Alternatively, we could store the nodes in a buffer at creation time, but the performance gain isn't worth losing the features of NSArray at this point.
 
 Assumptions: cxString->nodes is an NSArray containing only BDSKStringNodes
              cxString->macroResolver conforms to <BDSKMacroResolver>
              BDSKStringNode fields are public
*/
static inline
CFStringRef __BDCreateStringByCopyingExpandedValue(BDSKComplexString *cxString)
{
    
    // If this was an instance method instead of a function, we could do this without @defs
    NSArray *nodes = ((struct { @defs(BDSKComplexString) } *)cxString)->nodes;
	if (nodes == nil)
		return nil;
	    
	BDSKStringNode *node = nil;
    BDSKStringNode **stringNodes;
    int iMax = [nodes count];
    
    // This zone will automatically be resized as necessary, but won't free the underlying memory; we could statically allocate memory for stringNodes with NSZoneMalloc and then realloc as needed, but then we run into multithreading problems writing to the same memory location.  Using NSZoneMalloc/NSZoneFree allows us to avoid the overhead of malloc/free doing their own zone lookups.
    static NSZone *zone = NULL;
    if(!zone){
        zone = NSCreateZone(1024, 1024, NO);
        NSSetZoneName(zone, @"BDSKComplexStringExpansionZone");
    }
    
    // Allocate memory on the stack using alloca() if possible, so we don't have malloc/free overhead; since the array of string nodes is typically small, this should almost always work.
    BOOL usedMalloc = NO;
    if(stringNodes = (BDSKStringNode **)alloca(sizeof(BDSKStringNode *) * iMax))
        usedMalloc = NO;
    else if(stringNodes = (BDSKStringNode **)NSZoneMalloc(zone, sizeof(BDSKStringNode *) * iMax))
        usedMalloc = YES;
    else [NSException raise:NSInternalInconsistencyException format:@"Unable to malloc memory in zone %@", NSZoneName(zone)];

    // This avoids the overhead of calling objectAtIndex: or using an enumerator, since we can now just increment a pointer to traverse the contents of the array.
    [nodes getObjects:stringNodes];
    
    id <BDSKMacroResolver>macroResolver = ((struct { @defs(BDSKComplexString) } *)cxString)->macroResolver;
    
    OBASSERT((macroResolver != nil) ? [macroResolver conformsToProtocol:@protocol(BDSKMacroResolver)] : 1);
    
    // Guess at size of (50 * (no. of nodes)); this is likely too high, but resizing is a sizeable performance hit.
    CFMutableStringRef mutStr = CFStringCreateMutable(CFAllocatorGetDefault(), (iMax * 50));
    CFStringRef nodeVal, expandedValue;
    
    // Increment this pointer, in case we need to free it later (if alloca didn't work)
    BDSKStringNode **stringNodeIdx = stringNodes;
    
    while(iMax--){
        node = *stringNodeIdx++;
        nodeVal = (CFStringRef)(node->value);
        if(node->type == BSN_MACRODEF){
            expandedValue = __BDResolveMacro(macroResolver, nodeVal);
            CFStringAppend(mutStr, (expandedValue != nil ? expandedValue : nodeVal));
        } else {
            CFStringAppend(mutStr, nodeVal);
        }
    }
    
    OBPOSTCONDITION(!BDIsEmptyString(mutStr));
    
    if(usedMalloc) NSZoneFree(zone, stringNodes);
    
    return mutStr;
}

@implementation BDSKComplexString

+ (void)initialize{
    
    OBINITIALIZE;
    
    if (globalMacroDefs == nil){
        globalMacroDefs = [[NSMutableDictionary alloc] initWithObjects:[[NSUserDefaults standardUserDefaults] objectForKey:NSMonthNameArray]
                                                               forKeys:[NSArray arrayWithObjects:@"jan", @"feb", @"mar", @"apr", @"may", @"jun", @"jul", @"aug", @"sep", @"oct", @"nov", @"dec", nil]];
    }
}

+ (id)allocWithZone:(NSZone *)aZone{
    return NSAllocateObject(self, 0, aZone);
}

- (id)init{
    self = [self initWithArray:nil macroResolver:nil];
	return self;
}

/* designated initializer */
- (id)initWithArray:(NSArray *)a macroResolver:(id)theMacroResolver{
    if (self = [super init]) {
        nodes = [[NSArray allocWithZone:[self zone]] initWithArray:a copyItems:YES];
		if(theMacroResolver) {
			macroResolver = theMacroResolver;
		} else {
            OBPRECONDITION(macroResolver != nil);
		}
		complex = YES;
	}		
    return self;
}

- (id)initWithInheritedValue:(NSString *)aValue {
    if (self = [super init]) {
		if (aValue == nil) {
			[self release]; // should we do this?
			return nil;
		}
		if ([aValue isComplex]) {
			nodes = [[NSArray allocWithZone:[self zone]] initWithArray:[(BDSKComplexString *)aValue nodes] copyItems:YES];
			macroResolver = [(BDSKComplexString *)aValue macroResolver];
			if (macroResolver == nil) {
                OBPRECONDITION(macroResolver != nil);
			}
			complex = YES;
		} else {
			if ([aValue isInherited]) {
				nodes = [[NSArray allocWithZone:[self zone]] initWithArray:[(BDSKComplexString *)aValue nodes] copyItems:YES];
			} else {
				BDSKStringNode *node = [[BDSKStringNode allocWithZone:[self zone]] initWithQuotedString:aValue];
				nodes = [[NSArray allocWithZone:[self zone]] initWithObjects:node, nil];
				[node release];
			}
			complex = NO;
		}
		inherited = YES;
	}
	return self;
}

- (void)dealloc{
	[nodes release];
    [super dealloc];
}

/* NSCopying protocol */

- (id)copyWithZone:(NSZone *)zone{
    
    if(NSShouldRetainWithZone(self, zone))
        return [self retain];
    
    BDSKComplexString *cs;
	
	if ([self isInherited]) {
		cs = [[BDSKComplexString allocWithZone:zone] initWithInheritedValue:self];
	} else {
		cs = [[BDSKComplexString allocWithZone:zone] initWithArray:nodes 
													 macroResolver:macroResolver];
    }
	return cs;
}

/* NSCoding protocol */

- (id)initWithCoder:(NSCoder *)coder{
	if (self = [super initWithCoder:coder]) {
		nodes = [[coder decodeObjectForKey:@"nodes"] retain];
		[self setMacroResolver:[coder decodeObjectForKey:@"macroResolver"]];
		complex = [coder decodeBoolForKey:@"complex"];
		inherited = [coder decodeBoolForKey:@"inherited"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
	[super encodeWithCoder:coder];
    [coder encodeObject:nodes forKey:@"nodes"];
    [coder encodeConditionalObject:macroResolver forKey:@"macroResolver"];
	[coder encodeBool:complex forKey:@"complex"];
	[coder encodeBool:inherited forKey:@"inherited"];
}

#pragma mark overridden NSString Methods

/* A bunch of methods that have to be overridden in a concrete subclass of NSString */

- (unsigned int)length{
    CFStringRef expVal = __BDCreateStringByCopyingExpandedValue(self);
    unsigned len = CFStringGetLength(expVal);
    if(expVal != NULL) CFRelease(expVal);
    return len;
}

- (unichar)characterAtIndex:(unsigned)index{
    CFStringRef expVal = __BDCreateStringByCopyingExpandedValue(self);
    unichar ch = CFStringGetCharacterAtIndex(expVal, index);
    if(expVal != NULL) CFRelease(expVal);
    return ch;
}

/* Overridden NSString performance methods */

- (void)getCharacters:(unichar *)buffer{
    CFStringRef expVal = __BDCreateStringByCopyingExpandedValue(self);
    CFRange fullRange = CFRangeMake(0, CFStringGetLength(expVal));
    CFStringGetCharacters(expVal, fullRange, buffer);
    if(expVal != NULL) CFRelease(expVal);
}

- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange{
    CFStringRef expVal = __BDCreateStringByCopyingExpandedValue(self);
    CFRange range = CFRangeMake(aRange.location, aRange.length);
    CFStringGetCharacters(expVal, range, buffer);
    if(expVal != NULL) CFRelease(expVal);
}

/* do not override super's implementation of -isEqual:
- (BOOL)isEqual:(NSString *)other { return [super isEqual:other]; }
*/

#pragma mark overridden methods from the ComplexStringExtensions

- (id)copyUninheritedWithZone:(NSZone *)zone{
    NSString *cs;
	
	if ([self isComplex]) {
		cs = [[BDSKComplexString allocWithZone:zone] initWithArray:nodes
													 macroResolver:macroResolver];
    } else { // must be inherited with a single string node
		cs = [[[nodes objectAtIndex:0] value] copyWithZone:zone];
	}
	return cs;
}

- (BOOL)isComplex {
    return complex;
}

- (BOOL)isInherited {
    return inherited;
}

- (BOOL)isEqualAsComplexString:(NSString *)other{
	if ([self isComplex]) {
		if (![other isComplex])
			return NO;
		return [[self nodes] isEqualToArray:[(BDSKComplexString*)other nodes]];
	} else {
		return [self isEqualToString:other];
	}
}

- (NSComparisonResult)compareAsComplexString:(NSString *)other options:(unsigned)mask{
	if ([self isComplex]) {
		if (![other isComplex])
			return NSOrderedDescending;
		
		NSEnumerator *nodeE = [nodes objectEnumerator];
		NSEnumerator *otherNodeE = [[(BDSKComplexString *)other nodes] objectEnumerator];
		BDSKStringNode *node = nil;
		BDSKStringNode *otherNode = nil;
		NSComparisonResult comp;
		
		while((node = [nodeE nextObject]) && (otherNode = [otherNodeE nextObject])){
			comp = [node compareNode:otherNode options:mask];
			if(comp != NSOrderedSame)
				return comp;
		}
		if(otherNode)
			return NSOrderedAscending;
		if(node)
			return NSOrderedDescending;
		return NSOrderedSame;
	}
	return [self compare:other options:mask];
}

// Returns the bibtex value of the string.
- (NSString *)stringAsBibTeXString{
    int i = 0;
    NSMutableString *retStr = [NSMutableString string];
        
    for( i = 0; i < [nodes count]; i++){
        BDSKStringNode *valNode = [nodes objectAtIndex:i];
        if (i != 0){
            [retStr appendString:@" # "];
        }
        if([valNode type] == BSN_STRING){
            [retStr appendString:[[valNode value] stringAsBibTeXString]];
        }else{
            [retStr appendString:[valNode value]];
        }
    }
    
    return retStr; 
}

- (NSString *)stringAsExpandedBibTeXString{
    NSString *expValue = (NSString *)__BDCreateStringByCopyingExpandedValue(self);
    if(expValue == nil)
        return @"";
    
    NSMutableString *expandedString = [NSMutableString stringWithCapacity:([expValue length] + 2)];
    [expandedString appendCharacter:'{'];
    [expandedString appendString:expValue];
    [expValue release];
    [expandedString appendCharacter:'}'];
    
    return expandedString;
}

- (BOOL)hasSubstring:(NSString *)target options:(unsigned)opts{
	if ([self isInherited] && ![self isComplex])
		return [[nodes objectAtIndex:0] hasSubstring:target options:opts];
	
	NSArray *targetNodes;
	
	if ([target isComplex]) {
		targetNodes = [(BDSKComplexString *)target nodes];
	} else {
		BDSKStringNode *node = [[BDSKStringNode alloc] initWithQuotedString:target];
		targetNodes = [NSArray arrayWithObject:node];
		[node release];
	}
	
	int tNum = [targetNodes count];
	int max = [nodes count] - tNum;
	BOOL back = (BOOL)(opts & NSBackwardsSearch);
	int i = (back ? max : 0);
	
	while (i <= max && i >= 0) {
		if ([(BDSKStringNode *)[nodes objectAtIndex:i] compareNode:[targetNodes objectAtIndex:0] options:opts] == NSOrderedSame) {
			int j = 1;
			while (j < tNum && [(BDSKStringNode *)[nodes objectAtIndex:i + j] compareNode:[targetNodes objectAtIndex:j] options:opts] == NSOrderedSame) 
				j++;
			if (j == tNum)
				return YES;
		}
		back ? i-- : i++;
	}
	
	return NO;
}

- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(unsigned)opts replacements:(unsigned int *)number{
	NSMutableArray *newNodes = [nodes mutableCopy];
	NSArray *targetNodes;
	NSArray *replNodes;
	NSString *newString;
	BDSKStringNode *node;
	
	if ([target isComplex]) {
		targetNodes = [(BDSKComplexString *)target nodes];
	} else {
		node = [[BDSKStringNode alloc] initWithQuotedString:target];
		targetNodes = [NSArray arrayWithObject:node];
		[node release];
	}
	if ([replacement isComplex]) {
		replNodes = [(BDSKComplexString *)replacement nodes];
	} else {
		node = [[BDSKStringNode alloc] initWithQuotedString:replacement];
		replNodes = [NSArray arrayWithObject:node];
		[node release];
	}
	
	unsigned int num = 0;
	int tNum = [targetNodes count];
	int rNum = [replNodes count];
	int min = 0;
	int max = [newNodes count] - tNum;
	BOOL back = (BOOL)(opts & NSBackwardsSearch);
	int i;
	
	if ([self isInherited] || max < min) {
		*number = 0;
		return [[self copy] autorelease]; // should copy because of macroResolver
	}
	
	if (opts & NSAnchoredSearch) {
		// replace at the beginning or the end of the string
		if (back) 
			min = max;
		else
			max = min;
	}
	
	i = (back ? max : min);
	while (i <= max && i >= min) {
		if ([(BDSKStringNode *)[newNodes objectAtIndex:i] compareNode:[targetNodes objectAtIndex:0] options:opts] == NSOrderedSame) {
			int j = 1;
			while (j < tNum && [(BDSKStringNode *)[newNodes objectAtIndex:i + j] compareNode:[targetNodes objectAtIndex:j] options:opts] == NSOrderedSame) 
				j++;
			if (j == tNum) {
				[newNodes replaceObjectsInRange:NSMakeRange(i, tNum) withObjectsFromArray:replNodes];
				if (!back) {
					i += rNum - 1;
					max += rNum - tNum;
				}
				num++;
			}
		}
		back ? i-- : i++;
	}
	
	if (num) {
		if ([newNodes count] == 1 && [(BDSKStringNode *)[newNodes objectAtIndex:0] type] == BSN_STRING)
			newString = [[[(BDSKStringNode *)[newNodes objectAtIndex:0] value] retain] autorelease];
		else 
			newString = [BDSKComplexString complexStringWithArray:newNodes macroResolver:[self macroResolver]];
	} else {
		newString = [[self copy] autorelease]; // should copy because of macroResolver
	} 
	[newNodes release];
	
	*number = num;
	return newString;
}

#pragma mark complex string methods

- (NSArray *)nodes{
    return nodes;
}

- (id <BDSKMacroResolver>)macroResolver{
    return macroResolver;
}

- (void)setMacroResolver:(id <BDSKMacroResolver>)newMacroResolver{
	if (newMacroResolver != macroResolver)
		macroResolver = newMacroResolver;
}

@end

@implementation NSString (ComplexStringExtensions)

- (id)initWithBibTeXString:(NSString *)btstring macroResolver:(id<BDSKMacroResolver>)theMacroResolver{
    // needed for correct zoning
	NSZone *theZone = [self zone];
	// we don't need ourselves, as we return a concrete subclass
	[self release];
	
	btstring = [btstring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([btstring length] == 0){
        // if the string was whitespace only, it becomes empty.
        // empty strings are a special case, they are not complex.
        return [[NSString allocWithZone:theZone] initWithString:@""];
    }
    
	NSMutableArray *returnNodes = [[NSMutableArray alloc] initWithCapacity:5];
	BDSKStringNode *node = nil;
    NSScanner *sc = [[NSScanner alloc] initWithString:btstring];
    [sc setCharactersToBeSkipped:nil];
    NSString *s = nil;
    int nesting;
    unichar ch;
    
    static NSCharacterSet *bracesCharSet = nil;
    if(bracesCharSet == nil)
        bracesCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"{}"] retain];
    
    if (!macroCharSet) {
        NSMutableCharacterSet *tmpSet = [[NSMutableCharacterSet alloc] init];
        [tmpSet addCharactersInRange:NSMakeRange(48,10)]; // 0-9
        [tmpSet addCharactersInRange:NSMakeRange(65,26)]; // A-Z
        [tmpSet addCharactersInRange:NSMakeRange(97,26)]; // a-z
        [tmpSet addCharactersInString:@"!$&*+-./:;<>?[]^_`|"]; // see the btparse documentation
        macroCharSet = [tmpSet copy];
		[tmpSet release];
    }
    
    while (![sc isAtEnd]) {
        ch = [btstring characterAtIndex:[sc scanLocation]];
        if (ch == '{') {
            // a brace-quoted string, we look for the corresponding closing brace
            NSMutableString *nodeStr = [[NSMutableString alloc] initWithCapacity:10];
            [sc setScanLocation:[sc scanLocation] + 1];
            nesting = 1;
            while (nesting > 0 && ![sc isAtEnd]) {
                if ([sc scanUpToCharactersFromSet:bracesCharSet intoString:&s])
                    [nodeStr appendString:s];
                if ([sc isAtEnd]) break;
                if ([btstring characterAtIndex:[sc scanLocation] - 1] != '\\') {
                    // we found an unquoted brace
                    ch = [btstring characterAtIndex:[sc scanLocation]];
                    if (ch == '}') {
                        --nesting;
                    } else {
                        ++nesting;
                    }
                    if (nesting > 0) // we don't include the outer braces
                        [nodeStr appendFormat:@"%C",ch];
                }
                [sc setScanLocation:[sc scanLocation] + 1];
            }
            if (nesting > 0) {
                [returnNodes release];
                [sc release];
                [nodeStr autorelease];
                [NSException raise:BDSKComplexStringException
                            format:@"Unbalanced string: [%@]", nodeStr];
            }
			node = [[BDSKStringNode alloc] initWithQuotedString:nodeStr];
            [returnNodes addObject:node];
			[node release];
            [nodeStr release];
        }
        else if (ch == '"') {
            // a doublequote-quoted string
            NSMutableString *nodeStr = [[NSMutableString alloc] initWithCapacity:10];
            [sc setScanLocation:[sc scanLocation] + 1];
            nesting = 1;
            while (nesting > 0 && ![sc isAtEnd]) {
                if ([sc scanUpToString:@"\"" intoString:&s])
                    [nodeStr appendString:s];
                if (![sc isAtEnd]) {
                    if ([btstring characterAtIndex:[sc scanLocation] - 1] == '\\')
                        [nodeStr appendString:@"\""];
                    else
                        nesting = 0;
                    [sc setScanLocation:[sc scanLocation] + 1];
                }
            }
            // we don't accept unbalanced braces, as we always quote with braces
            // do we want to be more permissive and try to use "-quoted fields?
            if (nesting > 0 || ![nodeStr isStringTeXQuotingBalancedWithBraces:YES connected:NO]) {
                [returnNodes release];
                [sc release];
                [nodeStr autorelease];
                [NSException raise:BDSKComplexStringException
                            format:@"Unbalanced string: [%@]", nodeStr];
            }
			node = [[BDSKStringNode alloc] initWithQuotedString:nodeStr];
            [returnNodes addObject:node];
			[node release];
            [nodeStr release];
        }
        else if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:ch]) {
            // this should be all numbers
            [sc scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&s];
            node = [[BDSKStringNode alloc] initWithNumberString:s];
			[returnNodes addObject:node];
			[node release];
        }
        else if ([macroCharSet characterIsMember:ch]) {
            // a macro
            if ([sc scanCharactersFromSet:macroCharSet intoString:&s]) {
				node = [[BDSKStringNode alloc] initWithMacroString:s];
                [returnNodes addObject:node];
				[node release];
			}
        }
        else if (ch == '#') {
            // we found 2 # or a # at the beginning
            [returnNodes release];
            [sc release];
            [NSException raise:BDSKComplexStringException
                        format:@"Missing component"];
        }
        else {
            [returnNodes release];
            [sc release];
            [NSException raise:BDSKComplexStringException
                        format:@"Invalid first character in component"];
        }
        
        // look for the next #-character, removing spaces around it
        [sc scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
        if (![sc isAtEnd]) {
            if (![sc scanString:@"#" intoString:NULL]) {
                [returnNodes release];
                [sc release];
                [NSException raise:BDSKComplexStringException
                            format:@"Missing # character"];
            }
            [sc scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
            if ([sc isAtEnd]) {
                // we found a # at the end
                [returnNodes release];
                [sc release];
                [NSException raise:BDSKComplexStringException
                            format:@"Empty component"];
            }
        }
    }
    
    id retVal;
    // if we have a single string-type node, we return an NSString
    if ([returnNodes count] == 1 && [(BDSKStringNode*)[returnNodes objectAtIndex:0] type] == BSN_STRING) {
        retVal = [[NSString allocWithZone:theZone] initWithString:[[returnNodes objectAtIndex:0] value]];
    } else {
        retVal = [[BDSKComplexString allocWithZone:theZone] initWithArray:returnNodes macroResolver:theMacroResolver];
    }
    [sc release];
    [returnNodes release];
    
    return retVal;
}

+ (id)complexStringWithBibTeXString:(NSString *)btstring macroResolver:(id<BDSKMacroResolver>)theMacroResolver{
    return [[[self alloc] initWithBibTeXString:btstring macroResolver:theMacroResolver] autorelease];
}

+ (id)complexStringWithArray:(NSArray *)a macroResolver:(id<BDSKMacroResolver>)theMacroResolver{
    [self release]; // we could check to see if([self isKindOfClass:[BDSKComplexString class]]) and then use [self initWith..], but it's easier just to release self (self will usually be NSPlaceholderString anyway) and return the desired object
    return [[[BDSKComplexString alloc] initWithArray:a macroResolver:theMacroResolver] autorelease];
}

+ (id)stringWithInheritedValue:(NSString *)aValue{
    [self release];
    return [[[BDSKComplexString alloc] initWithInheritedValue:aValue] autorelease];
}

- (id)copyUninherited{
	return [self copyUninheritedWithZone:nil];
}

- (id)copyUninheritedWithZone:(NSZone *)zone{
	return [self copyWithZone:zone];
}

- (BOOL)isComplex{
	return NO;
}

- (BOOL)isInherited{
	return NO;
}

- (BOOL)isEqualAsComplexString:(NSString *)other{
	// we can assume that we are not complex, as BDSKComplexString overrides this
	if ([other isComplex])
		return NO;
	return [self isEqualToString:other];
}

- (NSComparisonResult)compareAsComplexString:(NSString *)other{
	return [self compareAsComplexString:other options:0];
}

- (NSComparisonResult)compareAsComplexString:(NSString *)other options:(unsigned)mask{
	if ([other isComplex])
		return NSOrderedAscending;
	return [self compare:other options:mask];
}

- (NSString *)stringAsBibTeXString{
    NSMutableString *mutableString = [NSMutableString stringWithCapacity:[self length] + 2];
    [mutableString appendString:@"{"];
    [mutableString appendString:self];
    [mutableString appendString:@"}"];
	return mutableString;
}

- (NSString *)stringAsExpandedBibTeXString{
    return [self stringAsBibTeXString];
}
        
- (BOOL)hasSubstring:(NSString *)target options:(unsigned)opts{
	if ([target isComplex])
		return NO;
	
	NSRange range = [self rangeOfString:target options:opts];
	
	return (range.location != NSNotFound);
}

- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(unsigned)opts replacements:(unsigned int *)number{
	if ([target isComplex] || [self length] < [target length]) {// we need this last check for anchored search
		*number = 0;
		return self;
	}
	if ([replacement isComplex]) {
		// only replace complete strings by a complex string
		if ([self compare:target options:opts] == NSOrderedSame) {
			*number = 1;
			return [[replacement copy] autorelease];
		} else {
			*number = 0;
			return self;
		}
	}
	
	NSRange searchRange;
	
	if (opts & NSAnchoredSearch) {
		// search at beginning or end of the string, force only a single replacement
		if (opts & NSBackwardsSearch) 
			searchRange = NSMakeRange([self length] - [target length], [target length]);
		else
			searchRange = NSMakeRange(0, [target length]);
	} else {
		searchRange = NSMakeRange(0, [self length]);
	}
	
	NSMutableString *newString = [self mutableCopy];
	*number = [newString replaceOccurrencesOfString:target withString:replacement options:opts range:searchRange];
	
	if (*number > 0) {
		return [newString autorelease];
	} else {
		[newString release];
		return self;
	}
}

@end
