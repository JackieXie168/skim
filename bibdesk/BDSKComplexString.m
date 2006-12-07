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

- (id)initWithArray:(NSArray *)a macroResolver:(id)theMacroResolver{
    if (self = [super init]) {
        nodes = [[NSArray alloc] initWithArray:a copyItems:YES];
		if(theMacroResolver) {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
			macroResolver = theMacroResolver;
			[nc addObserver:self
				   selector:@selector(handleMacroKeyChangedNotification:)
					   name:BDSKBibDocMacroKeyChangedNotification
					 object:theMacroResolver];
			[nc addObserver:self
				   selector:@selector(handleMacroDefinitionChangedNotification:)
					   name:BDSKBibDocMacroDefinitionChangedNotification
					 object:theMacroResolver];
		} else {
			NSLog(@"Warning: complex string being created without macro resolver. Macros in it will not be resolved.");
		}
		expandedValue = [[self expandedValueFromArray:[self nodes]] retain];
	}		
    return self;
}

- (void)dealloc{
    [expandedValue release];
	[nodes release];
	if (macroResolver)
		[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone{
	NSEnumerator *nodeEnum = [nodes objectEnumerator];
	BDSKStringNode *node;
	NSMutableArray *copiedNodes = [NSMutableArray array];
	
	// deep copy the nodes, to be sure...
	while (node = [nodeEnum nextObject]) {
		[copiedNodes addObject:[[node copyWithZone:zone] autorelease]];
	}
    BDSKComplexString *cs = [[BDSKComplexString allocWithZone:zone] initWithArray:copiedNodes 
																	macroResolver:macroResolver];
    return cs;
}

- (id)initWithCoder:(NSCoder *)coder{
	if (self = [super initWithCoder:coder]) {
		expandedValue = [[coder decodeObjectForKey:@"expandedValue"] retain];
		nodes = [[coder decodeObjectForKey:@"nodes"] retain];
		[self setMacroResolver:[coder decodeObjectForKey:@"macroResolver"]];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
	[super encodeWithCoder:coder];
    [coder encodeObject:nodes forKey:@"nodes"];
    [coder encodeObject:expandedValue forKey:@"expandedValue"];
    [coder encodeConditionalObject:macroResolver forKey:@"macroResolver"];
}

#pragma mark overridden NSString Methods

- (unsigned int)length{
    return [expandedValue length];
}

- (unichar)characterAtIndex:(unsigned)index{
    return [expandedValue characterAtIndex:index];
}

- (void)getCharacters:(unichar *)buffer{
    [expandedValue getCharacters:buffer];
}

- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange{
    [expandedValue getCharacters:buffer range:aRange];
}

#pragma mark overridden methods from the ComplexStringExtensions

- (BOOL)isComplex {
    return YES;
}

- (BOOL)isEqualAsComplexString:(NSString *)other{
	if (![other isComplex])
		return NO;
	return [[self nodes] isEqualToArray:[(BDSKComplexString*)other nodes]];
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
    return [NSString stringWithFormat:@"{%@}", expandedValue];
}

#pragma mark complex string methods

- (NSArray *)nodes{
    return nodes;
}

- (NSString *)expandedValueFromArray:(NSArray *)a{
    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:10];
    NSString *retStr = nil;
    int i =0;
    
    if (a == nil){
        [s release];
        return retStr;
    }
	
    for(i = 0 ; i < [a count]; i++){
        BDSKStringNode *node = [a objectAtIndex:i];
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

- (id <BDSKMacroResolver>)macroResolver{
    return macroResolver;
}

- (void)setMacroResolver:(id <BDSKMacroResolver>)newMacroResolver{
	if (newMacroResolver != macroResolver) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		if (macroResolver) {
			[nc removeObserver:self 
						  name:BDSKBibDocMacroKeyChangedNotification 
						object:macroResolver];
			[nc removeObserver:self
						  name:BDSKBibDocMacroDefinitionChangedNotification 
						object:macroResolver];
		}
		macroResolver = newMacroResolver;
		
		[self updateExpandedValue];
		
		if (newMacroResolver) {
			[nc addObserver:self
				   selector:@selector(handleMacroKeyChangedNotification:)
					   name:BDSKBibDocMacroKeyChangedNotification
					 object:newMacroResolver];
			[nc addObserver:self
				   selector:@selector(handleMacroDefinitionChangedNotification:)
					   name:BDSKBibDocMacroDefinitionChangedNotification
					 object:newMacroResolver];
		}
	}
}

- (void)updateExpandedValue{
    [expandedValue release];
    expandedValue = [[self expandedValueFromArray:nodes] retain];
    NSNotification *aNotif = [NSNotification notificationWithName:BDSKComplexStringChangedNotification object:macroResolver];
    [[NSNotificationQueue defaultQueue] enqueueNotification:aNotif postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
}

- (void)handleMacroKeyChangedNotification:(NSNotification *)notification{
	[self updateExpandedValue];
}

- (void)handleMacroDefinitionChangedNotification:(NSNotification *)notification{	
	[self updateExpandedValue];
}

- (void)handleNodeValueChangedNotification:(NSNotification *)notification{
	[self updateExpandedValue];
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
				[NSException raise:@"BDSKComplexStringException" 
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
				[NSException raise:@"BDSKComplexStringException" 
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
			[NSException raise:@"BDSKComplexStringException" 
						format:@"Missing component"];
		} 
		else {
			[NSException raise:@"BDSKComplexStringException" 
						format:@"Invalid first character in component"];
		}
		
		// look for the next #-character, removing spaces around it
		[sc scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
		if (![sc isAtEnd]) {
			if (![sc scanString:@"#" intoString:NULL]) {
				[NSException raise:@"BDSKComplexStringException" 
							format:@"Missing # character"];
			}
			[sc scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
			if ([sc isAtEnd]) {
				// we found a # at the end
				[NSException raise:@"BDSKComplexStringException" 
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

+ (id)complexStringWithArray:(NSArray *)a macroResolver:(id)theMacroResolver{
    return [[[BDSKComplexString alloc] initWithArray:a macroResolver:theMacroResolver] autorelease];
}

- (BOOL)isComplex{
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
