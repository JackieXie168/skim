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
#import "NSSTring_BDSKExtensions.h"

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

- (id)init{
	self = [self initWithType:BSN_STRING value:@""];
	return self;
}

- (id)initWithType:(bdsk_stringnodetype)aType value:(NSString *)s{
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
    BDSKStringNode *copy = [[BDSKStringNode allocWithZone:zone] initWithType:type value:value];
    return copy;
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

- (bdsk_stringnodetype)type {
    return type;
}

- (NSString *)value {
    return [[value retain] autorelease];
}

- (NSString *)description{
    return [NSString stringWithFormat:@"type: %d, %@", type, value];
}

@end

// accessor for lazy updating of the expanded value
@interface BDSKComplexString (Private)
- (NSString *)expandedValue;
@end

// stores system-defined macros for the months.
// we grab their localized versions for display.
static NSDictionary *globalMacroDefs; 

@implementation BDSKComplexString

+ (void)initialize{
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

- (BOOL)isEqual:(BDSKComplexString *)other{
    return [super isEqual:other]; // do not override super's implementation of isEqual
}

- (id)initWithArray:(NSArray *)a macroResolver:(id)theMacroResolver{
    if (self = [super init]) {
        nodes = [[NSArray alloc] initWithArray:a copyItems:YES];
		if(theMacroResolver) {
			macroResolver = theMacroResolver;
		} else {
			NSLog(@"Warning: complex string being created without macro resolver. Macros in it will not be resolved.");
		}
		complex = YES;
	}		
    return self;
}

- (id)initWithInheritedValue:(NSString *)aValue {
    if (self = [super init]) {
		if (aValue == nil) {
			[self release];
			return nil;
		}
		if ([aValue isComplex]) {
			nodes = [[NSArray alloc] initWithArray:[(BDSKComplexString *)aValue nodes] copyItems:YES];
			macroResolver = [(BDSKComplexString *)aValue macroResolver];
			if (macroResolver == nil) {
				NSLog(@"Warning: complex string being created without macro resolver. Macros in it will not be resolved.");
			}
			complex = YES;
		} else {
			if ([aValue isInherited])
				aValue = [(BDSKComplexString *)aValue expandedValue];
			nodes = [[NSArray alloc] initWithObjects:[BDSKStringNode nodeWithQuotedString:aValue], nil];
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

- (id)copyWithZone:(NSZone *)zone{
    BDSKComplexString *cs;
	
	if ([self isInherited]) {
		cs = [[BDSKComplexString allocWithZone:zone] initWithInheritedValue:self];
	} else {
		NSEnumerator *nodeEnum = [nodes objectEnumerator];
		BDSKStringNode *node;
		NSMutableArray *copiedNodes = [NSMutableArray array];
		
		// deep copy the nodes, to be sure...
		while (node = [nodeEnum nextObject]) {
			[copiedNodes addObject:[[node copyWithZone:zone] autorelease]];
		}
		cs = [[BDSKComplexString allocWithZone:zone] initWithArray:copiedNodes 
																	macroResolver:macroResolver];
    }
	return cs;
}

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

- (unsigned int)length{
    return [[self expandedValue] length];
}

- (unichar)characterAtIndex:(unsigned)index{
    return [[self expandedValue] characterAtIndex:index];
}

- (void)getCharacters:(unichar *)buffer{
    [[self expandedValue] getCharacters:buffer];
}

- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange{
    [[self expandedValue] getCharacters:buffer range:aRange];
}

#pragma mark overridden methods from the ComplexStringExtensions

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
    return [NSString stringWithFormat:@"{%@}", [self expandedValue]];
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

@implementation BDSKComplexString (Private)

- (NSString *)expandedValue{
	if (nodes == nil)
		return nil;
	
    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:10];
    NSString *retStr = nil;
    NSEnumerator *nodeEnum = [nodes objectEnumerator];
	BDSKStringNode *node = nil;
	
    while(node = [nodeEnum nextObject]){
        if([node type] == BSN_MACRODEF){
            NSString *exp = nil;
            if(macroResolver)
                exp = [macroResolver valueOfMacro:[node value]];
            if (exp){
                [s appendString:exp];
            }else{
                // there was no expansion. Check the system global dict first.
                NSString *globalExp = [globalMacroDefs objectForKey:[node value]];
                if(globalExp) 
                    [s appendString:globalExp];
                else 
                    [s appendString:[node value]];
            }
        }else{
            [s appendString:[node value]];
        }
    }
    retStr = [[s copy] autorelease];
    [s release];
    return retStr;
}

@end

@implementation NSString (ComplexStringExtensions)

+ (id)complexStringWithBibTeXString:(NSString *)btstring macroResolver:(id<BDSKMacroResolver>)theMacroResolver{
    NSMutableArray *returnNodes = [NSMutableArray array];
    
    btstring = [btstring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([btstring length] == 0){
        // if the string was whitespace only, it becomes empty.
        // empty strings are a special case, they are not complex.
        return [NSString stringWithString:@""];
    }
    
    NSScanner *sc = [NSScanner scannerWithString:btstring];
	[sc setCharactersToBeSkipped:nil];
    NSString *s = nil;
	int nesting;
	unichar ch;
	NSCharacterSet *bracesCharSet = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
	
	if (!macroCharSet) {
		NSMutableCharacterSet *tmpSet = [[[NSMutableCharacterSet alloc] init] autorelease];
		[tmpSet addCharactersInRange:NSMakeRange(48,10)]; // 0-9
		[tmpSet addCharactersInRange:NSMakeRange(65,26)]; // A-Z
		[tmpSet addCharactersInRange:NSMakeRange(97,26)]; // a-z
		[tmpSet addCharactersInString:@"!$&*+-./:;<>?[]^_`|"]; // see the btparse documentation
		macroCharSet = [tmpSet copy];
	}
	
	while (![sc isAtEnd]) {
		ch = [btstring characterAtIndex:[sc scanLocation]];
		if (ch == '{') {
			// a brace-quoted string, we look for the corresponding closing brace
			NSMutableString *nodeStr = [NSMutableString string];
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
				[NSException raise:BDSKComplexStringException 
							format:@"Unbalanced string: [%@]", nodeStr];
			}
			[returnNodes addObject:[BDSKStringNode nodeWithQuotedString:nodeStr]];
		} 
		else if (ch == '"') {
			// a doublequote-quoted string
			NSMutableString *nodeStr = [NSMutableString string];
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
				[NSException raise:BDSKComplexStringException 
							format:@"Unbalanced string: [%@]", nodeStr];
			}
			[returnNodes addObject:[BDSKStringNode nodeWithQuotedString:nodeStr]];
		} 
		else if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:ch]) {
			// this should be all numbers
			[sc scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&s];
			[returnNodes addObject:[BDSKStringNode nodeWithNumberString:s]];
		} 
		else if ([macroCharSet characterIsMember:ch]) {
			// a macro
			if ([sc scanCharactersFromSet:macroCharSet intoString:&s])
				[returnNodes addObject:[BDSKStringNode nodeWithMacroString:s]];
		}
		else if (ch == '#') {
			// we found 2 # or a # at the beginning
			[NSException raise:BDSKComplexStringException 
						format:@"Missing component"];
		} 
		else {
			[NSException raise:BDSKComplexStringException 
						format:@"Invalid first character in component"];
		}
		
		// look for the next #-character, removing spaces around it
		[sc scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
		if (![sc isAtEnd]) {
			if (![sc scanString:@"#" intoString:NULL]) {
				[NSException raise:BDSKComplexStringException 
							format:@"Missing # character"];
			}
			[sc scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
			if ([sc isAtEnd]) {
				// we found a # at the end
				[NSException raise:BDSKComplexStringException 
							format:@"Empty component"];
			}
		}
	}
	
	// if we have a single string-type node, we return an NSString
	if ([returnNodes count] == 1 && [(BDSKStringNode*)[returnNodes objectAtIndex:0] type] == BSN_STRING) {
		return [[returnNodes objectAtIndex:0] value];
	}
	return [NSString complexStringWithArray:returnNodes macroResolver:theMacroResolver];
}

+ (id)complexStringWithArray:(NSArray *)a macroResolver:(id<BDSKMacroResolver>)theMacroResolver{
    return [[[BDSKComplexString alloc] initWithArray:a macroResolver:theMacroResolver] autorelease];
}

+ (id)stringWithInheritedValue:(NSString *)aValue{
    return [[[BDSKComplexString alloc] initWithInheritedValue:aValue] autorelease];
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

- (NSString *)stringAsBibTeXString{
	return [NSString stringWithFormat:@"{%@}", self];
}

- (NSString *)stringAsExpandedBibTeXString{
    return [self stringAsBibTeXString];
}
        

@end
