// BDSKComplexString.m
// Created by Michael McCracken, 2004
/*
 This software is Copyright (c) 2004,2005,2006
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
#import "BDSKStringNode.h"
#import "BDSKMacroResolver.h"

#pragma mark -
#pragma mark Private complex string expansion

static NSCharacterSet *macroCharSet = nil;
static NSZone *complexStringExpansionZone = NULL;
static Class BDSKComplexStringClass = Nil;

static BDSKMacroResolver *macroResolverForUnarchiving = nil;

#define STACK_BUFFER_SIZE 256

static inline
CFStringRef __BDStringCreateByCopyingExpandedValue(NSArray *nodes, BDSKMacroResolver *macroResolver)
{
	BDSKStringNode *node = nil;
    BDSKStringNode **stringNodes, *stackBuffer[STACK_BUFFER_SIZE];
    
    int iMax = nil == nodes ? 0 : CFArrayGetCount((CFArrayRef)nodes);
    
    if(0 == iMax) return nil;
        
    if (iMax > STACK_BUFFER_SIZE) {
        stringNodes = (BDSKStringNode **)NSZoneMalloc(complexStringExpansionZone, sizeof(BDSKStringNode *) * iMax);
        if (NULL == stringNodes)
            [NSException raise:NSInternalInconsistencyException format:@"Unable to malloc memory in zone %@", NSZoneName(complexStringExpansionZone)];
    } else {
        stringNodes = stackBuffer;
    }

    // This avoids the overhead of calling objectAtIndex: or using an enumerator, since we can now just increment a pointer to traverse the contents of the array.
    CFArrayGetValues((CFArrayRef)nodes, (CFRange){0, iMax}, (const void **)stringNodes);
    
    // Guess at size of (50 * (no. of nodes)); this is likely too high, but resizing is a sizeable performance hit.
    CFMutableStringRef mutStr = CFStringCreateMutable(CFAllocatorGetDefault(), (iMax * 50));
    CFStringRef nodeVal, expandedValue;
    
    // Increment a different pointer, in case we need to free stringNodes later
    BDSKStringNode **stringNodeIdx = stringNodes;
    
    while(iMax--){
        node = *stringNodeIdx++;
        nodeVal = (CFStringRef)(node->value);
        if(node->type == BSN_MACRODEF){
            expandedValue = (CFStringRef)[macroResolver valueOfMacro:(NSString *)nodeVal];
            if(expandedValue == nil && macroResolver != [BDSKMacroResolver defaultMacroResolver])
                expandedValue = (CFStringRef)[[BDSKMacroResolver defaultMacroResolver] valueOfMacro:(NSString *)nodeVal];
            CFStringAppend(mutStr, (expandedValue != nil ? expandedValue : nodeVal));
        } else {
            CFStringAppend(mutStr, nodeVal);
        }
    }
    
    OBPOSTCONDITION(!BDIsEmptyString(mutStr));
    
    if(stackBuffer != stringNodes) NSZoneFree(complexStringExpansionZone, stringNodes);
    
    return mutStr;
}

@implementation BDSKComplexString

+ (void)initialize{
    
    OBINITIALIZE;
    
    NSMutableCharacterSet *tmpSet = [[NSMutableCharacterSet alloc] init];
    [tmpSet addCharactersInRange:NSMakeRange(48,10)]; // 0-9
    [tmpSet addCharactersInRange:NSMakeRange(65,26)]; // A-Z
    [tmpSet addCharactersInRange:NSMakeRange(97,26)]; // a-z
    [tmpSet addCharactersInString:@"!$&*+-./:;<>?[]^_`|"]; // see the btparse documentation
    macroCharSet = [tmpSet copy];
    [tmpSet release];
    
    // This zone will automatically be resized as necessary, but won't free the underlying memory; we could statically allocate memory for stringNodes with NSZoneMalloc and then realloc as needed, but then we run into multithreading problems writing to the same memory location.  Using NSZoneMalloc/NSZoneFree allows us to avoid the overhead of malloc/free doing their own zone lookups.
    if(complexStringExpansionZone == NULL){
        complexStringExpansionZone = NSCreateZone(1024, 1024, NO);
        NSSetZoneName(complexStringExpansionZone, @"BDSKComplexStringExpansionZone");
    } 
    
    BDSKComplexStringClass = self;

}

+ (BDSKMacroResolver *)macroResolverForUnarchiving{
    return macroResolverForUnarchiving;
}

+ (void)setMacroResolverForUnarchiving:(BDSKMacroResolver *)aMacroResolver{
    if (macroResolverForUnarchiving != aMacroResolver) {
        [macroResolverForUnarchiving release];
        macroResolverForUnarchiving = [aMacroResolver retain];
    }
}

+ (id)allocWithZone:(NSZone *)aZone{
    return NSAllocateObject(self, 0, aZone);
}

- (id)init{
    [[super init] release];
	return self = [@"" retain];
}

/* designated initializer */
- (id)initWithNodes:(NSArray *)nodesArray macroResolver:(BDSKMacroResolver *)theMacroResolver{
    if (self = [super init]) {
        if ([nodesArray count] == 0) {
            [self release];
            self = nil;
        } else if ([nodesArray count] == 1 && [(BDSKStringNode *)[nodesArray objectAtIndex:0] type] == BSN_STRING) {
            [self release];
            self = [[(BDSKStringNode *)[nodesArray objectAtIndex:0] value] retain];
        } else {
            nodes = [nodesArray copyWithZone:[self zone]];
            // we don't retain, as the macroResolver might retain us as a macro value
            macroResolver = (theMacroResolver == [BDSKMacroResolver defaultMacroResolver]) ? nil : theMacroResolver;
            complex = YES;
        }
	}		
    return self;
}

- (id)initWithInheritedValue:(NSString *)aValue {
    if (self = [super init]) {
		if (aValue == nil) {
			[self release];
			return self = nil;
		}
        
        nodes = [[aValue nodes] retain];
        complex = [aValue isComplex];
		inherited = YES;
		if (complex) {
			macroResolver = [(BDSKComplexString *)aValue macroResolver];
            if (macroResolver == [BDSKMacroResolver defaultMacroResolver]) 
                macroResolver = nil;
		}
	}
	return self;
}

- (void)dealloc{
	[nodes release];
    [super dealloc];
}

/* NSCopying protocol */
// NSShouldRetainWithZone returns NO on 10.4.4 for NULL or NSDefaultMallocZone rdar://problem/4409099
- (id)copyWithZone:(NSZone *)zone{
    return [self retain];
}

/* NSCoding protocol */

/* In fixing bug #1460089, experiment shows that we need to override -classForKeyedArchiver, since NSArchiver seems to encode NSString subclasses as NSStrings.  

With that change, our NSCoding methods get called, but calling -[super initWithCoder:] causes an NSInvalidArgumentException since it apparently calls -initWithCharactersNoCopy:length:freeWhenDone: on the abstract NSString class:

#2	0x92a6a208 in -[NSString initWithCharactersNoCopy:length:freeWhenDone:]
#3	0x92a69c8c in -[NSString initWithString:]
#4	0x929840d0 in -[NSString initWithCoder:]
#5	0x0002a16c in -[BDSKComplexString initWithCoder:] at StringCoder.m:35

Rather than relying on the same call sequence to be used, I think we should ignore super's implementation.
*/

- (Class)classForKeyedArchiver { return BDSKComplexStringClass; }

- (id)initWithCoder:(NSCoder *)coder{
    if([coder allowsKeyedCoding]){
        if (self = [super init]) {
            OBASSERT([coder isKindOfClass:[NSKeyedUnarchiver class]]);
            nodes = [[coder decodeObjectForKey:@"nodes"] retain];
            complex = [coder decodeBoolForKey:@"complex"];
            inherited = [coder decodeBoolForKey:@"inherited"];
            macroResolver = [BDSKComplexString macroResolverForUnarchiving];
        }
    } else {
        [[super init] release];
        self = [[NSKeyedUnarchiver unarchiveObjectWithData:[coder decodeDataObject]] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
    if([coder allowsKeyedCoding]){
        OBASSERT([coder isKindOfClass:[NSKeyedArchiver class]]);
        [coder encodeObject:nodes forKey:@"nodes"];
        [coder encodeBool:complex forKey:@"complex"];
        [coder encodeBool:inherited forKey:@"inherited"];
    } else {
        [coder encodeDataObject:[NSKeyedArchiver archivedDataWithRootObject:self]];
    }
}

- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder
{
    return [encoder isByref] ? (id)[NSDistantObject proxyWithLocal:self connection:[encoder connection]] : self;
}

#pragma mark overridden NSString Methods

/* A bunch of methods that have to be overridden in a concrete subclass of NSString */

- (unsigned int)length{
    CFStringRef expVal = __BDStringCreateByCopyingExpandedValue(nodes, macroResolver);
    unsigned len = CFStringGetLength(expVal);
    if(expVal != NULL) CFRelease(expVal);
    return len;
}

- (unichar)characterAtIndex:(unsigned)index{
    CFStringRef expVal = __BDStringCreateByCopyingExpandedValue(nodes, macroResolver);
    unichar ch = CFStringGetCharacterAtIndex(expVal, index);
    if(expVal != NULL) CFRelease(expVal);
    return ch;
}

/* Overridden NSString performance methods */

- (void)getCharacters:(unichar *)buffer{
    CFStringRef expVal = __BDStringCreateByCopyingExpandedValue(nodes, macroResolver);
    CFRange fullRange = CFRangeMake(0, CFStringGetLength(expVal));
    CFStringGetCharacters(expVal, fullRange, buffer);
    if(expVal != NULL) CFRelease(expVal);
}

- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange{
    CFStringRef expVal = __BDStringCreateByCopyingExpandedValue(nodes, macroResolver);
    CFRange range = CFRangeMake(aRange.location, aRange.length);
    CFStringGetCharacters(expVal, range, buffer);
    if(expVal != NULL) CFRelease(expVal);
}

/* do not override super's implementation of -isEqual:
- (BOOL)isEqual:(NSString *)other { return [super isEqual:other]; }
*/

#pragma mark overridden methods from the ComplexStringExtensions

- (id)copyUninheritedWithZone:(NSZone *)zone{
	
	if (inherited == NO) 
        return [self retain];
	else 
        return [[BDSKComplexString allocWithZone:zone] initWithNodes:nodes macroResolver:macroResolver];
}

- (BOOL)isComplex {
    return complex;
}

- (BOOL)isInherited {
    return inherited;
}

- (NSArray *)nodes{
    return nodes;
}

- (BOOL)isEqualAsComplexString:(NSString *)other{
	if ([self isComplex]) {
		if (![other isComplex])
			return NO;
		return [[self nodes] isEqualToArray:[other nodes]];
	} else {
		return [self isEqualToString:other];
	}
}

- (NSComparisonResult)compareAsComplexString:(NSString *)other options:(unsigned)mask{
	if ([self isComplex]) {
		if (![other isComplex])
			return NSOrderedDescending;
		
		NSEnumerator *nodeE = [nodes objectEnumerator];
		NSEnumerator *otherNodeE = [[other nodes] objectEnumerator];
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
    unsigned int i = 0;
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
    NSString *expValue = (NSString *)__BDStringCreateByCopyingExpandedValue(nodes, macroResolver);
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
		return [[[nodes objectAtIndex:0] value] hasSubstring:target options:opts];
	
	NSArray *targetNodes = [target nodes];
	
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
	NSArray *targetNodes = [target nodes];
	NSArray *replNodes = [replacement nodes];
	NSString *newString;
	
	unsigned int num = 0;
	int tNum = [targetNodes count];
	int rNum = [replNodes count];
	int min = 0;
	int max = [newNodes count] - tNum;
	BOOL back = (BOOL)(opts & NSBackwardsSearch);
	int i;
	
	if ([self isInherited] || max < min) {
		*number = 0;
		return [[self retain] autorelease];
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
        newString = [BDSKComplexString stringWithNodes:newNodes macroResolver:macroResolver];
	} else {
		newString = [[self retain] autorelease];
	} 
	[newNodes release];
	
	*number = num;
	return newString;
}

#pragma mark complex string methods

- (BDSKMacroResolver *)macroResolver{
    return (macroResolver == nil && complex == YES) ? [BDSKMacroResolver defaultMacroResolver] : macroResolver;
}

@end

@implementation NSString (ComplexStringExtensions)

- (id)initWithNodes:(NSArray *)nodesArray macroResolver:(BDSKMacroResolver *)theMacroResolver{
    [[self init] release];
    self = [[BDSKComplexString alloc] initWithNodes:nodesArray macroResolver:theMacroResolver];
    return self;
}

- (id)initWithInheritedValue:(NSString *)aValue{
    [[self init] release];
    self = [[BDSKComplexString alloc] initWithInheritedValue:aValue];
    return self;
}

- (id)initWithBibTeXString:(NSString *)btstring macroResolver:(BDSKMacroResolver *)theMacroResolver{
	btstring = [btstring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // used for correct zoning
    NSZone *theZone = [self zone];
    // we will return another object
    [[self init] release];
    
    if([btstring length] == 0){
        // if the string was whitespace only, it becomes empty.
        // empty strings are a special case, they are not complex.
        return self = [@"" retain];
    }
    
	NSMutableArray *returnNodes = [[NSMutableArray alloc] initWithCapacity:5];
	BDSKStringNode *node = nil;
    NSScanner *sc = [[NSScanner alloc] initWithString:btstring];
    [sc setCharactersToBeSkipped:nil];
    NSString *s = nil;
    int nesting;
    unichar ch;
    
    NSCharacterSet *bracesCharSet = [NSCharacterSet curlyBraceCharacterSet];
	[BDSKComplexString class]; // make sure the class is initialized
    
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
    
    self = [[BDSKComplexString allocWithZone:theZone] initWithNodes:returnNodes macroResolver:theMacroResolver];
    [sc release];
    [returnNodes release];
    
    return self;
}

+ (id)stringWithBibTeXString:(NSString *)btstring macroResolver:(BDSKMacroResolver *)theMacroResolver{
    return [[[self alloc] initWithBibTeXString:btstring macroResolver:theMacroResolver] autorelease];
}

+ (id)stringWithNodes:(NSArray *)nodesArray macroResolver:(BDSKMacroResolver *)theMacroResolver{
    return [[[BDSKComplexString alloc] initWithNodes:nodesArray macroResolver:theMacroResolver] autorelease];
}

+ (id)stringWithInheritedValue:(NSString *)aValue{
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

- (NSArray *)nodes{
    BDSKStringNode *node = [[BDSKStringNode alloc] initWithQuotedString:self];
    NSArray *nodes = [NSArray arrayWithObject:node];
    [node release];
    return nodes;
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
