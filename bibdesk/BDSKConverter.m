//  BDSKConverter.m
//  Created by Michael McCracken on Thu Mar 07 2002.
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005
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

#import "BDSKConverter.h"
#import "NSString_BDSKExtensions.h"
#import "BDSKComplexString.h"
#import "BibAppController.h"
#import <OmniFoundation/OmniFoundation.h>
#import "NSFileManager_BDSKExtensions.h"

@interface BDSKConverter (Private)
- (void)setDetexifyAccents:(NSDictionary *)newAccents;
- (void)setAccentCharacterSet:(NSCharacterSet *)charSet;
- (void)setBaseCharacterSetForTeX:(NSCharacterSet *)charSet;
- (void)setTexifyAccents:(NSDictionary *)newAccents;
- (void)setFinalCharSet:(NSCharacterSet *)charSet;
- (void)setTexifyConversions:(NSDictionary *)newConversions;
- (void)setDeTexifyConversions:(NSDictionary *)newConversions;
@end

@implementation BDSKConverter

+ (BDSKConverter *)sharedConverter{
    static BDSKConverter *theConverter = nil;
    if(!theConverter){
	theConverter = [[BDSKConverter alloc] init];
    }
    return theConverter;
}

- (id)init{
    if(self = [super init]){
	[self loadDict];
    }
    return self;
}

- (void)dealloc{
    [finalCharSet release];
    [accentCharSet release];
    [texifyConversions release];
    [detexifyConversions release];
    [texifyAccents release];
    [detexifyAccents release];
    [baseCharacterSetForTeX release];
    [super dealloc];
}
    

- (void)loadDict{
    
    NSDictionary *wholeDict = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME]];
	NSDictionary *userWholeDict = nil;
    // look for the user file
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *charConvPath = [[fm currentApplicationSupportPathForCurrentUser] stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME];
	
	if ([fm fileExistsAtPath:charConvPath]) {
		userWholeDict = [NSDictionary dictionaryWithContentsOfFile:charConvPath];
    }
    
    // set up the dictionaries
    NSMutableDictionary *tmpDetexifyDict = [NSMutableDictionary dictionary];
    [tmpDetexifyDict addEntriesFromDictionary:[wholeDict objectForKey:TEX_TO_ROMAN_KEY]];
    
    NSMutableDictionary *tmpTexifyDict = [NSMutableDictionary dictionary];
    [tmpTexifyDict addEntriesFromDictionary:[wholeDict objectForKey:ROMAN_TO_TEX_KEY]];
    [tmpTexifyDict addEntriesFromDictionary:[wholeDict objectForKey:ONE_WAY_CONVERSION_KEY]];
    
	if (userWholeDict) {
		[tmpTexifyDict addEntriesFromDictionary:[userWholeDict objectForKey:ROMAN_TO_TEX_KEY]];
		[tmpTexifyDict addEntriesFromDictionary:[userWholeDict objectForKey:ONE_WAY_CONVERSION_KEY]];
		[tmpDetexifyDict addEntriesFromDictionary:[userWholeDict objectForKey:TEX_TO_ROMAN_KEY]];
    }

    [self setTexifyConversions:tmpTexifyDict];
    [self setDeTexifyConversions:tmpDetexifyDict];
	
	// create a characterset from the characters we know how to convert
    NSMutableCharacterSet *workingSet;
    NSRange highCharRange = NSMakeRange('~' + 1, 256); //this should get all the characters in the upper-range. exclude tilde, or we'll get an alert on it
	
    workingSet = [[NSCharacterSet decomposableCharacterSet] mutableCopy];
    [workingSet addCharactersInRange:highCharRange];

    NSEnumerator *e = [tmpTexifyDict keyEnumerator];
    NSString *key;
	while(key = [e nextObject]){
		[workingSet addCharactersInString:key];
	}
	
    [self setFinalCharSet:workingSet];
    [workingSet release];
            
	// build a character set of [a-z][A-Z] representing the base character set that we can decompose and recompose as TeX
    NSRange ucRange = NSMakeRange('A', 26);
    NSRange lcRange = NSMakeRange('a', 26);
    workingSet = [[NSCharacterSet characterSetWithRange:ucRange] mutableCopy];
    [workingSet addCharactersInRange:lcRange];
    [self setBaseCharacterSetForTeX:workingSet];
    [workingSet release];
	
    [self setTexifyAccents:[wholeDict objectForKey:ROMAN_TO_TEX_ACCENTS_KEY]];
    [self setAccentCharacterSet:[NSCharacterSet characterSetWithCharactersInString:[[texifyAccents allKeys] componentsJoinedByString:@""]]];
    [self setDetexifyAccents:[wholeDict objectForKey:TEX_TO_ROMAN_ACCENTS_KEY]];
}

- (NSString *)stringByTeXifyingString:(NSString *)s{
	// TeXify only string nodes of complex strings;
	if([s isComplex]){
		BDSKComplexString *cs = (BDSKComplexString *)s;
		NSEnumerator *nodeEnum = [[cs nodes] objectEnumerator];
		BDSKStringNode *node, *newNode;
		NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:[[cs nodes] count]];
		
		while(node = [nodeEnum nextObject]){
			if([node type] == BSN_STRING)
				newNode = [[BDSKStringNode alloc] initWithQuotedString:[self stringByTeXifyingString:[node value]]];
			else 
				newNode = [node copy];
			[nodes addObject:newNode];
			[newNode release];
		}
		return [NSString complexStringWithArray:nodes macroResolver:[cs macroResolver]];
	}
	
    NSString *tmpConv = nil;
    NSMutableString *convertedSoFar = [s mutableCopy];

    unsigned sLength = [s length];
    
    int offset=0;
    unsigned index = 0;
    NSString *TEXString = nil;
    NSString *logString = nil;
    
    OFStringScanner *scanner = [[OFStringScanner alloc] initWithString:s];
    UniChar ch;
    
    // convertedSoFar has s to begin with.
    // while scanner's not at eof, scan up to characters from that set into tmpOut

    while(scannerHasData(scanner)){
    
        logString = [scanner readTokenFragmentWithDelimiterOFCharacterSet:finalCharSet];
        index = scannerScanLocation(scanner);
		if(index >= sLength) // don't go past the end
			break;
		
        ch = scannerReadCharacter(scanner);
        tmpConv = [[NSString alloc] initWithCharactersNoCopy:&ch length:1 freeWhenDone:NO];

		if(TEXString = [texifyConversions objectForKey:tmpConv]){
			[convertedSoFar replaceCharactersInRange:NSMakeRange((index + offset), 1)
										  withString:TEXString];
			offset += [TEXString length] - 1;    // we're adding length-1 characters, so we have to make sure we insert at the right point in the future.
		} else {
			TEXString = [self convertedStringWithAccentedString:tmpConv];

			// Check to see if the unicode composition conversion worked.  If it fails, it returns the decomposed string, so we precompose it
			// and compare it to tmpConv; if they're the same, we know that the unicode conversion failed.
			if(TEXString && ![tmpConv isEqualToString:[TEXString precomposedStringWithCanonicalMapping]]){
				[convertedSoFar replaceCharactersInRange:NSMakeRange((index + offset), 1)
								  withString:TEXString];
				offset += [TEXString length] - 1;
			} else if(tmpConv != nil){ // if tmpConv is non-nil, we had a character that was accented and not convertable by us
                NSString *hexString = [NSString stringWithFormat:@"%X", ch];
                NSLog(@"unable to convert character 0x%@", [hexString stringByPaddingToLength:4 withString:@"0" startingAtIndex:0]);
				[NSException raise:BDSKTeXifyException format:@"An error occurred converting %@", [tmpConv autorelease]]; // raise exception after moving the scanner past the offending char
			}
        }
        [tmpConv release];
    }
		
    
    //clean up
    [scanner release];
    
    return([convertedSoFar autorelease]);
}

- (NSString *)convertedStringWithAccentedString:(NSString *)s{
    
    // decompose into D form, make mutable
    NSMutableString * t = [[[s decomposedStringWithCanonicalMapping] mutableCopy] autorelease];
    
    BOOL goOn = YES;
    NSRange searchRange = NSMakeRange(0,[t length]);
    NSRange foundRange;
    NSRange composedRange;
    NSString * replacementString;
    
    while (goOn) {
		foundRange = [t rangeOfCharacterFromSet:accentCharSet options:NSLiteralSearch range:searchRange];

		if (foundRange.location == NSNotFound) {
			// no more accents => STOP
			goOn = NO;
		} else {
			// found an accent => process
			composedRange = [t rangeOfComposedCharacterSequenceAtIndex:foundRange.location];
                        if(composedRange.length > 2) // rangeOfComposedCharacterSequence returns base+N accents; if N>1, we can't convert
                            return nil;
			if(replacementString = [self convertBunch:[t substringWithRange:composedRange]])
					[t replaceCharactersInRange:composedRange withString:replacementString];
			else
					return nil;
			// move searchable range
			searchRange.location = composedRange.location;
			searchRange.length = [t length] - composedRange.location;
		}
    }
    
    return t;
    
}


- (NSString*) convertBunch:(NSString*) s {
    // isolate accent
    NSString * unicodeAccent = [s substringFromIndex:[s length] -1];
    NSString * accent = [texifyAccents objectForKey:unicodeAccent];
    
    // isolate character(s)
    NSString * character = [s substringToIndex:[s length] - 1];
    if(![baseCharacterSetForTeX characterIsMember:[character characterAtIndex:0]]){ // length 1 string
        return nil;
    }
    // handle i and j (others as well?)
    if (([character isEqualToString:@"i"] || [character isEqualToString:@"j"]) &&
		![accent isEqualToString:@"c"] && ![accent isEqualToString:@"d"] && ![accent isEqualToString:@"b"]) {
	    character = [@"\\" stringByAppendingString:character];
    }

    NSMutableString *retStr = [NSMutableString stringWithCapacity:6];
    [retStr appendStrings:@"{\\", accent, character, @"}", nil];
    return retStr;
}

- (NSString *)stringByDeTeXifyingString:(NSString *)s{

    if([NSString isEmptyString:s]){
        return @"";
    }
    
	// deTeXify only string nodes of complex strings;
	if([s isComplex]){
		BDSKComplexString *cs = (BDSKComplexString *)s;
		NSEnumerator *nodeEnum = [[cs nodes] objectEnumerator];
		BDSKStringNode *node, *newNode;
		NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:[[cs nodes] count]];
		
		while(node = [nodeEnum nextObject]){
			if([node type] == BSN_STRING)
				newNode = [[BDSKStringNode alloc] initWithQuotedString:[self stringByDeTeXifyingString:[node value]]];
			else 
				newNode = [node copy];
			[nodes addObject:newNode];
			[newNode release];
		}
		return [NSString complexStringWithArray:nodes macroResolver:[cs macroResolver]];
	}
	
    NSString *tmpPass;
    NSString *tmpConv;
    NSString *tmpConvB;
    NSString *TEXString;

    NSMutableString *convertedSoFar = [[NSMutableString alloc] initWithCapacity:[s length]];
    OFStringScanner *scanner = [[OFStringScanner alloc] initWithString:s];
    
    do {
        if(tmpPass = [scanner readFullTokenUpToString:@"{\\"])
            [convertedSoFar appendString:tmpPass];
        
        if(scannerHasData(scanner) && (tmpConv = [scanner readFullTokenUpToString:@"}"])){
			NSRange range = [tmpConv rangeOfString:@"{\\" options:(NSLiteralSearch | NSBackwardsSearch)];
			while(range.location != NSNotFound){
				// we have a {\, now look for the matching closing brace
                if(!scannerReadString(scanner, @"}")) // the closing brace does not follow immediately, don't convert
					break;
				tmpConv = [tmpConv stringByAppendingString:@"}"];
				tmpConvB = [tmpConv substringFromIndex:range.location]; // this holds the possible TeX char at the end of tmpConv
				if((TEXString = [detexifyConversions objectForKey:tmpConvB]) ||
					(TEXString = [self composedStringFromTeXString:tmpConvB])){
					// we could convert the last part, so replace that part
					tmpConv = [[tmpConv substringToIndex:range.location] stringByAppendingString:TEXString];
				} else { // we couldn't convert
					break;
				}
				/* look for another {\ */
				range = [tmpConv rangeOfString:@"{\\" options:(NSLiteralSearch | NSBackwardsSearch)];
			}
			[convertedSoFar appendString:tmpConv];
        }
    } while(scannerHasData(scanner));
    [scanner release];
    return [convertedSoFar autorelease]; 
}

- (NSString *)composedStringFromTeXString:(NSString *)texString{
	NSString *texAccent = nil;
	NSString *accent = nil;
    NSString *character = nil;
     
    OFStringScanner *scanner = [[OFStringScanner alloc] initWithString:texString];
        	
    if(!scannerReadString(scanner, @"{\\")){
        [scanner release];
        return nil;
    }
    
    UniChar accentCh = scannerReadCharacter(scanner);
    
    if(!scannerReadString(scanner, @" ") && [[NSCharacterSet letterCharacterSet] characterIsMember:accentCh]){
        [scanner release];
        return nil;
    }

    texAccent = [[NSString alloc] initWithCharactersNoCopy:&accentCh length:1 freeWhenDone:NO];
    accent = [detexifyAccents objectForKey:texAccent];
    [texAccent release];
    
    character = [scanner readTokenFragmentWithDelimiterCharacter:'}'];
    
    if(accent && character){
		if ([character isEqualToString:@"\\i"])
			character = @"i";
		else if ([character isEqualToString:@"\\j"])
			character = @"j";
		if ([character length] == 1){
            [scanner release];
			return [[character stringByAppendingString:accent] precomposedStringWithCanonicalMapping];
        }
	}
    
    [scanner release];
    return nil;
}

@end

@implementation BDSKConverter (Private)

- (void)setDetexifyAccents:(NSDictionary *)newAccents{
    if(detexifyAccents != newAccents){
        [detexifyAccents release];
        detexifyAccents = [newAccents copy];
    }
}

- (void)setAccentCharacterSet:(NSCharacterSet *)charSet{
    if(accentCharSet != charSet){
        [accentCharSet release];
        accentCharSet = [charSet copy];
    }
}

- (void)setBaseCharacterSetForTeX:(NSCharacterSet *)charSet{
    if(baseCharacterSetForTeX != charSet){
        [baseCharacterSetForTeX release];
        baseCharacterSetForTeX = [charSet copy];
    }
}

- (void)setTexifyAccents:(NSDictionary *)newAccents{
    if(texifyAccents != newAccents){
        [texifyAccents release];
        texifyAccents = [newAccents copy];
    }
}

- (void)setFinalCharSet:(NSCharacterSet *)charSet{
    [finalCharSet release];
    finalCharSet = [[OFCharacterSet alloc] initWithCharacterSet:charSet];
}

- (void)setTexifyConversions:(NSDictionary *)newConversions{
    if(texifyConversions != newConversions){
        [texifyConversions release];
        texifyConversions = [newConversions copy];
    }
}

- (void)setDeTexifyConversions:(NSDictionary *)newConversions{
    if(detexifyConversions != newConversions){
        [detexifyConversions release];
        detexifyConversions = [newConversions copy];
    }
}

@end
