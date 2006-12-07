//  BDSKConverter.m
//  Created by Michael McCracken on Thu Mar 07 2002.
/*
This software is Copyright (c) 2001,2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BDSKConverter.h"
#import "NSString_BDSKExtensions.h"
#import "BDSKComplexString.h"
#import "BibAppController.h"

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
    // first make sure that we release, as this may be called by the character conversion editor
    [finalCharSet release];
    [accentCharSet release];
    [texifyConversions release];
    [detexifyConversions release];
    [texifyAccents release];
    [detexifyAccents release];
    [baseCharacterSetForTeX release];
    
    NSDictionary *wholeDict = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME]];
	NSDictionary *userWholeDict = nil;
    // look for the user file
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *applicationSupportPath = [[fm applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"];
    NSString *charConvPath = [applicationSupportPath stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME];
	
	if ([fm fileExistsAtPath:charConvPath]) {
		userWholeDict = [NSDictionary dictionaryWithContentsOfFile:charConvPath];
    } else {
		userWholeDict = nil;
	}
    
	//create a characterset from the characters we know how to convert
    NSMutableCharacterSet *workingSet;
    NSRange highCharRange;
	
    highCharRange.location = (unsigned int) '~' + 1; //exclude tilde, or we'll get an alert on it
    highCharRange.length = 256; //this should get all the characters in the upper-range.
    workingSet = [[NSCharacterSet decomposableCharacterSet] mutableCopy];
    [workingSet addCharactersInRange:highCharRange];

    // Build a dictionary of one-way conversions that we know how to do, then add these to the character set
    NSDictionary *oneWayCharacters = [wholeDict objectForKey:ONE_WAY_CONVERSION_KEY];
    NSEnumerator *e = [oneWayCharacters keyEnumerator];
    NSString *oneWayKey;
	while(oneWayKey = [e nextObject]){
		[workingSet addCharactersInString:oneWayKey];
	}
    
    // set up the dictionaries
    NSMutableDictionary *tmpDetexifyDict = [NSMutableDictionary dictionaryWithDictionary:[wholeDict objectForKey:TEX_TO_ROMAN_KEY]];
    NSMutableDictionary *tmpTexifyDict = [NSMutableDictionary dictionaryWithDictionary:[wholeDict objectForKey:ROMAN_TO_TEX_KEY]];
    [tmpTexifyDict addEntriesFromDictionary:[wholeDict objectForKey:ONE_WAY_CONVERSION_KEY]];
    
	if (userWholeDict) {
		oneWayCharacters = [userWholeDict objectForKey:ONE_WAY_CONVERSION_KEY];
		e = [oneWayCharacters keyEnumerator];

		while(oneWayKey = [e nextObject]){
			[workingSet addCharactersInString:oneWayKey];
		}
		
		[tmpTexifyDict addEntriesFromDictionary:[userWholeDict objectForKey:ROMAN_TO_TEX_KEY]];
		[tmpTexifyDict addEntriesFromDictionary:[userWholeDict objectForKey:ONE_WAY_CONVERSION_KEY]];
		[tmpDetexifyDict addEntriesFromDictionary:[userWholeDict objectForKey:TEX_TO_ROMAN_KEY]];
    }
	
	// set the ivars
    finalCharSet = [workingSet copy];
	texifyConversions = [tmpTexifyDict copy];
	detexifyConversions = [tmpDetexifyDict copy];
    
    if(!texifyConversions){
        texifyConversions = [[NSDictionary dictionary] retain]; // an empty one won't break the code.
    }
	if(!detexifyConversions){
        detexifyConversions = [[NSDictionary dictionary] retain]; // an empty one won't break the code.
    }
    
	[workingSet release];
    
	// build a character set of [a-z][A-Z] representing the base character set that we can decompose and recompose as TeX
    NSRange ucRange = NSMakeRange('A', 26);
    NSRange lcRange = NSMakeRange('a', 26);
    workingSet = [[NSCharacterSet characterSetWithRange:ucRange] mutableCopy];
    [workingSet addCharactersInRange:lcRange];
    baseCharacterSetForTeX = [workingSet copy];
    [workingSet release];
	
    texifyAccents = [[wholeDict objectForKey:ROMAN_TO_TEX_ACCENTS_KEY] retain];
    accentCharSet = [[NSCharacterSet characterSetWithCharactersInString:[[texifyAccents allKeys] componentsJoinedByString:@""]] retain];
	detexifyAccents = [[wholeDict objectForKey:TEX_TO_ROMAN_ACCENTS_KEY] retain];
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
				newNode = [BDSKStringNode nodeWithQuotedString:[self stringByTeXifyingString:[node value]]];
			else 
				newNode = [[node copy] autorelease];
			[nodes addObject:newNode];
		}
		return [NSString complexStringWithArray:nodes macroResolver:[cs macroResolver]];
	}
	
    // s should be in UTF-8 or UTF-16 (i'm not sure which exactly) format (since that's what the property list editor spat)
    // This direction could be faster, since we're comparing characters to the keys, but that'll be left for later.
    NSScanner *scanner = [[NSScanner alloc] initWithString:s];
    [scanner setCharactersToBeSkipped:nil];
    NSString *tmpConv = nil;
    NSMutableString *convertedSoFar = [s mutableCopy];

    unsigned sLength = [s length];
    
    int offset=0;
    unsigned index = 0;
    NSString *TEXString = nil;
    NSString *logString = nil;
    
    // convertedSoFar has s to begin with.
    // while scanner's not at eof, scan up to characters from that set into tmpOut

    while(![scanner isAtEnd]){

		[scanner scanUpToCharactersFromSet:finalCharSet intoString:&logString];
		index = [scanner scanLocation];

		if(index >= sLength) // don't go past the end
			break;
		
		tmpConv = [s substringWithRange:NSMakeRange(index, 1)];

		if(TEXString = [texifyConversions objectForKey:tmpConv]){
			[convertedSoFar replaceCharactersInRange:NSMakeRange((index + offset), 1)
										  withString:TEXString];
			[scanner setScanLocation:(index + 1)];
			offset += [TEXString length] - 1;    // we're adding length-1 characters, so we have to make sure we insert at the right point in the future.
		} else {
			TEXString = [self convertedStringWithAccentedString:tmpConv];

			// Check to see if the unicode composition conversion worked.  If it fails, it returns the decomposed string, so we precompose it
			// and compare it to tmpConv; if they're the same, we know that the unicode conversion failed.
			if(TEXString && ![tmpConv isEqualToString:[TEXString precomposedStringWithCanonicalMapping]]){
				// NSLog(@"plist didn't work, using unicode magic");
				[convertedSoFar replaceCharactersInRange:NSMakeRange((index + offset), 1)
								  withString:TEXString];
				[scanner setScanLocation:(index + 1)];
				offset += [TEXString length] - 1;
			} else if(tmpConv != nil){ // if tmpConv is non-nil, we had a character that was accented and not convertable by us
				[scanner setScanLocation:(index + 1)]; // increment the scanner to go past the character that we don't have in the dict
                NSString *hexString = [NSString stringWithFormat:@"%X", [tmpConv characterAtIndex:0]];
                NSLog(@"unable to convert character 0x%@", [hexString stringByPaddingToLength:4 withString:@"0" startingAtIndex:0]);
				[NSException raise:BDSKTeXifyException format:@"An error occurred converting %@", tmpConv]; // raise exception after moving the scanner past the offending char
			}
        }
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
    NSString *hexString = [NSString stringWithFormat:@"%X", [character characterAtIndex:0]];
    if(![baseCharacterSetForTeX characterIsMember:[character characterAtIndex:0]]){ // length 1 string
        return nil;
    }
    // handle i and j (others as well?)
    if (([character isEqualToString:@"i"] || [character isEqualToString:@"j"]) &&
		![accent isEqualToString:@"c"] && ![accent isEqualToString:@"d"] && ![accent isEqualToString:@"b"]) {
	    character = [@"\\" stringByAppendingString:character];
    }

    return [NSString stringWithFormat:@"{\\%@%@}", accent, character];
}

- (NSString *)stringByDeTeXifyingString:(NSString *)s{
	// deTeXify only string nodes of complex strings;
	if([s isComplex]){
		BDSKComplexString *cs = (BDSKComplexString *)s;
		NSEnumerator *nodeEnum = [[cs nodes] objectEnumerator];
		BDSKStringNode *node, *newNode;
		NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:[[cs nodes] count]];
		
		while(node = [nodeEnum nextObject]){
			if([node type] == BSN_STRING)
				newNode = [BDSKStringNode nodeWithQuotedString:[self stringByDeTeXifyingString:[node value]]];
			else 
				newNode = [[node copy] autorelease];
			[nodes addObject:newNode];
		}
		return [NSString complexStringWithArray:nodes macroResolver:[cs macroResolver]];
	}
	
    NSScanner *scanner = [NSScanner scannerWithString:s];
    NSString *tmpPass;
    NSString *tmpConv;
    NSString *tmpConvB;
    NSString *TEXString;
    NSMutableString *convertedSoFar = [[NSMutableString alloc] initWithCapacity:10];

    if(!s || [s isEqualToString:@""]){
        [convertedSoFar release];
        return [NSString string];
    }
    
    [scanner setCharactersToBeSkipped:nil];
    //    NSLog(@"scanning string: %@",s);
    while(![scanner isAtEnd]){
        if([scanner scanUpToString:@"{\\" intoString:&tmpPass])
            [convertedSoFar appendString:tmpPass];
        if([scanner scanUpToString:@"}" intoString:&tmpConv]){
			NSRange range = [tmpConv rangeOfString:@"{\\" options:(NSLiteralSearch | NSBackwardsSearch)];
			while(range.location != NSNotFound){
				// we have a {\, now look for the matching closing brace
				if(![scanner scanString:@"}" intoString:nil]) // the closing brace does not follow immediately, don't convert
					break;
				tmpConv = [tmpConv  stringByAppendingString:@"}"];
				tmpConvB = [tmpConv substringFromIndex:range.location]; // thid holds the possible TeX char at the end of tmpConv
				if((TEXString = [detexifyConversions objectForKey:tmpConvB]) ||
					(TEXString = [self composedStringFromTeXString:tmpConvB])){
					// we could convert the last part, so replace that part
					tmpConv = [[tmpConv substringToIndex:range.location] stringByAppendingString:TEXString];
				} else { // we couldn't convert
					break;
				}
				// look for another {\
				range = [tmpConv rangeOfString:@"{\\" options:(NSLiteralSearch | NSBackwardsSearch)];
			}
			[convertedSoFar appendString:tmpConv];
        }
    }
    
  return [convertedSoFar autorelease]; 
}

- (NSString *)composedStringFromTeXString:(NSString *)texString{
    NSScanner *scanner = [[[NSScanner alloc] initWithString:texString] autorelease];
	NSString *texAccent = nil;
	NSString *accent = nil;
    NSString *character = nil;
	
	[scanner setCharactersToBeSkipped:nil];
    if(![scanner scanString:@"{\\" intoString:NULL])
		return nil;
	texAccent = [texString substringWithRange:NSMakeRange([scanner scanLocation],1)];
	[scanner setScanLocation:[scanner scanLocation] + 1]; // go past the accent
	if(![scanner scanString:@" " intoString:NULL] &&
	   [[NSCharacterSet letterCharacterSet] characterIsMember:[texAccent characterAtIndex:0]]) // letters need an extra space
		return nil;
	
	if ((accent = [detexifyAccents objectForKey:texAccent]) && 
		[scanner scanUpToString:@"}" intoString:&character]) {
		if ([character isEqualToString:@"\\i"])
			character = @"i";
		else if ([character isEqualToString:@"\\j"])
			character = @"j";
		if ([character length] == 1)
			return [[character stringByAppendingString:accent] precomposedStringWithCanonicalMapping];
	}
	return nil;
}

@end
