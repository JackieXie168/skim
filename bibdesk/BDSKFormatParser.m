//
//  BDSKFormatParser.m
//  BibDesk
//
//  Created by Christiaan Hofman on 17/4/05.
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

#import "BDSKFormatParser.h"
#import "BibItem.h"

static BDSKFormatParser *sharedParser;

@implementation BDSKFormatParser

+ (BDSKFormatParser *)sharedParser 
{
	if (!sharedParser) sharedParser = [[BDSKFormatParser alloc] init];
	return sharedParser;
}

- (id)init {
	if (self = [super init]) {
		
		validSpecifierChars = [[NSCharacterSet characterSetWithCharactersInString:@"tTmyYlLerRdc"] retain];
		validUniqueSpecifierChars = [[NSCharacterSet characterSetWithCharactersInString:@"uUn"] retain];
		validEscapeSpecifierChars = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789%[]"] retain];
		validArgSpecifierChars = [[NSCharacterSet characterSetWithCharactersInString:@"fc"] retain];
		validOptArgSpecifierChars = [[NSCharacterSet characterSetWithCharactersInString:@"aAk"] retain];
		
	}
	return self;
}

- (void)dealloc {
	[validSpecifierChars release];
	[validUniqueSpecifierChars release];
	[validEscapeSpecifierChars release];
	[validArgSpecifierChars release];
	[validOptArgSpecifierChars release];
	
	[super dealloc];
}

- (NSString *)parseFormat:(NSString *)format forField:(NSString *)fieldName ofItem:(BibItem *)pub
{
	NSMutableString *parsedStr = [NSMutableString string];
	NSString *savedStr = nil;
	NSScanner *scanner = [NSScanner scannerWithString:format];
	NSString *string, *authSep, *nameSep, *etal, *slash;
	int number, numAuth, i, uniqueNumber;
	unichar specifier, nextChar, uniqueSpecifier = 0;
	NSMutableArray *arr;
	NSScanner *wordScanner;
	NSCharacterSet *slashCharSet = [NSCharacterSet characterSetWithCharactersInString:@"/"];
	
	// seed for random letters or characters
	srand(time(NULL));
	[scanner setCharactersToBeSkipped:nil];
	
	while (![scanner isAtEnd]) {
		// scan non-specifier parts
		if ([scanner scanUpToString:@"%" intoString:&string]) {
			// if we are not sure about a valid format, we should sanitize string
			[parsedStr appendString:string];
		}
		// does nothing at the end; allows but ignores % at end
		[scanner scanString:@"%" intoString:NULL];
		if (![scanner isAtEnd]) {
			// found %, so now there should be a specifier char
			specifier = [format characterAtIndex:[scanner scanLocation]];
			[scanner setScanLocation:[scanner scanLocation]+1];
			switch (specifier) {
				case 'a':
					// author names, optional [separator], [etal], #names and #chars
					number = 0;
					numAuth = 0;
					authSep = @"";
					etal = @"";
					if (![scanner isAtEnd]) {
						// look for [separator]
						if ([scanner scanString:@"[" intoString:NULL]) {
							if (![scanner scanUpToString:@"]" intoString:&authSep]) authSep = @"";
							[scanner scanString:@"]" intoString:NULL];
							// look for [etal]
							if ([scanner scanString:@"[" intoString:NULL]) {
								if (![scanner scanUpToString:@"]" intoString:&etal]) etal = @"";
								[scanner scanString:@"]" intoString:NULL];
							}
						}
						if (![scanner isAtEnd]) {
							// look for #names
							nextChar = [format characterAtIndex:[scanner scanLocation]];
							if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:nextChar]) {
								[scanner setScanLocation:[scanner scanLocation]+1];
								numAuth = (int)(nextChar - '0');
								// scan for #chars per name
								if (![scanner scanInt:&number]) number = 0;
							}
						}
					}
					if (numAuth == 0 || numAuth > [pub numberOfAuthors]) {
						numAuth = [pub numberOfAuthors];
					}
					for (i = 0; i < numAuth; i++) {
						if (i > 0) {
							[parsedStr appendString:authSep];
						}
						string = [self stringByStrictlySanitizingString:[[pub authorAtIndex:i] lastName] forField:fieldName inFileType:[pub fileType]];
						if ([fieldName isEqualToString:BDSKLocalUrlString]) {
							string = [string stringByReplacingCharactersInSet:slashCharSet withString:@"-"];
						}
						if ([string length] > number && number > 0) {
							string = [string substringToIndex:number];
						}
						[parsedStr appendString:string];
					}
					if (numAuth < [pub numberOfAuthors]) {
						[parsedStr appendString:etal];
					}
					break;
				case 'A':
					// author names with initials, optional [author separator], [name separator], [etal], #names
					numAuth = 0;
					authSep = @";";
					nameSep = @".";
					etal = @"";
					if (![scanner isAtEnd]) {
						// look for [author separator]
						if ([scanner scanString:@"[" intoString:NULL]) {
							if (![scanner scanUpToString:@"]" intoString:&authSep]) authSep = @"";
							[scanner scanString:@"]" intoString:NULL];
							// look for [name separator]
							if ([scanner scanString:@"[" intoString:NULL]) {
								if (![scanner scanUpToString:@"]" intoString:&nameSep]) nameSep = @"";
								[scanner scanString:@"]" intoString:NULL];
								// look for [etal]
								if ([scanner scanString:@"[" intoString:NULL]) {
									if (![scanner scanUpToString:@"]" intoString:&etal]) etal = @"";
									[scanner scanString:@"]" intoString:NULL];
								}
							}
						}
						if (![scanner isAtEnd]) {
							// look for #names
							nextChar = [format characterAtIndex:[scanner scanLocation]];
							if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:nextChar]) {
								[scanner setScanLocation:[scanner scanLocation]+1];
								numAuth = (int)(nextChar - '0');
							}
						}
					}
					if (numAuth == 0 || numAuth > [pub numberOfAuthors]) {
						numAuth = [pub numberOfAuthors];
					}
					for (i = 0; i < numAuth; i++) {
						if (i > 0) {
							[parsedStr appendString:authSep];
						}
						BibAuthor *auth = [pub authorAtIndex:i];
						NSString *firstName = [self stringByStrictlySanitizingString:[auth firstName] forField:fieldName inFileType:[pub fileType]];
						NSString *lastName = [self stringByStrictlySanitizingString:[auth lastName] forField:fieldName inFileType:[pub fileType]];
						if ([firstName length] > 0) {
							string = [NSString stringWithFormat:@"%@%@%C", 
											lastName, nameSep, [firstName characterAtIndex:0]];
						} else {
							string = lastName;
						}
						if ([fieldName isEqualToString:BDSKLocalUrlString]) {
							string = [string stringByReplacingCharactersInSet:slashCharSet withString:@"-"];
						}
						[parsedStr appendString:string];
					}
					if (numAuth < [pub numberOfAuthors]) {
						[parsedStr appendString:etal];
					}
					break;
				case 't':
					// title, optional #chars
					if ([[pub type] isEqualToString:@"inbook"]) {
						string = [pub valueOfField:BDSKChapterString];
					} else {
						string = [pub valueOfField:BDSKTitleString];
					}
					string = [self stringByStrictlySanitizingString:string forField:fieldName inFileType:[pub fileType]];
					if ([fieldName isEqualToString:BDSKLocalUrlString]) {
						string = [string stringByReplacingCharactersInSet:slashCharSet withString:@"-"];
					}
					if (![scanner scanInt:&number]) number = 0;
					if (number > 0 && [string length] > number) {
						[parsedStr appendString:[string substringToIndex:number]];
					} else {
						[parsedStr appendString:string];
					}
					break;
				case 'T':
					// title, optional #words
					if ([[pub type] isEqualToString:@"inbook"]) {
						string = [pub valueOfField:BDSKChapterString];
					} else {
						string = [pub valueOfField:BDSKTitleString];
					}
					if (![scanner scanInt:&number]) number = 0;
					if (string != nil) {
						arr = [NSMutableArray array];
						// split the title into words using the same methodology as addString:forCompletionEntry:
						NSRange wordSpacingRange = [string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
						if (wordSpacingRange.location != NSNotFound) {
							wordScanner = [NSScanner scannerWithString:string];
							
							while (![wordScanner isAtEnd]) {
								if ([wordScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&string]){
									[arr addObject:string];
								}
								[wordScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
							}
						} else {
							[arr addObject:string];
						}
						if (number == 0) number = [arr count];
						for (i = 0; i < [arr count] && number > 0; i++) { 
							if (i > 0) [parsedStr appendString:[self stringByStrictlySanitizingString:@" " forField:fieldName inFileType:[pub fileType]]]; 
							string = [self stringByStrictlySanitizingString:[arr objectAtIndex:i] forField:fieldName inFileType:[pub fileType]]; 
							if ([fieldName isEqualToString:BDSKLocalUrlString]) {
								string = [string stringByReplacingCharactersInSet:slashCharSet withString:@"-"];
							}
							[parsedStr appendString:string]; 
							if ([string length] > 3) --number;
						}
					}
					break;
				case 'y':
					// year without century
					if ([pub date]) {
						string = [[pub date] descriptionWithCalendarFormat:@"%y"];
						[parsedStr appendString:string];
					}
					break;
				case 'Y':
					// year with century
					if ([pub date]) {
						string = [[pub date] descriptionWithCalendarFormat:@"%Y"];
						[parsedStr appendString:string];
					}
					break;
				case 'm':
					// month
					if ([pub date] && [pub valueOfField:BDSKMonthString] != nil && ![[pub valueOfField:BDSKMonthString] isEqualToString:@""]) {
						string = [[pub date] descriptionWithCalendarFormat:@"%m"];
						[parsedStr appendString:string];
					}
					break;
				case 'k':
					// keywords
					// look for [slash]
					slash = ([fieldName isEqualToString:BDSKLocalUrlString]) ? @"-" : @"/";
					if ([scanner scanString:@"[" intoString:NULL]) {
						if (![scanner scanUpToString:@"]" intoString:&slash]) slash = @"";
						[scanner scanString:@"]" intoString:NULL];
					}
					string = [pub valueOfField:BDSKKeywordsString];
					if (![scanner scanInt:&number]) number = 0;
					if (string != nil) {
						arr = [NSMutableArray array];
						// split the keyword string using the same methodology as addString:forCompletionEntry:, treating ,:; as possible dividers
						NSRange keywordPunctuationRange = [string rangeOfCharacterFromSet:[[NSApp delegate] autoCompletePunctuationCharacterSet]];
						if (keywordPunctuationRange.location != NSNotFound) {
							wordScanner = [NSScanner scannerWithString:string];
							[wordScanner setCharactersToBeSkipped:nil];
							
							while (![wordScanner isAtEnd]) {
								if ([wordScanner scanUpToCharactersFromSet:[[NSApp delegate] autoCompletePunctuationCharacterSet] intoString:&string])
									[arr addObject:string];
								[wordScanner scanCharactersFromSet:[[NSApp delegate] autoCompletePunctuationCharacterSet] intoString:nil];
							}
						} else {
							[arr addObject:string];
						}
						for (i = 0; i < [arr count] && (number == 0 || i < number); i++) { 
							string = [[arr objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; 
							string = [self stringByStrictlySanitizingString:string forField:fieldName inFileType:[pub fileType]]; 
							if (![slash isEqualToString:@"/"])
								string = [string stringByReplacingCharactersInSet:slashCharSet withString:slash];
							[parsedStr appendString:string]; 
						}
					}
					break;
				case 'l':
					// old filename without extension
					string = [pub localURLPath];
					if (string != nil) {
						string = [[string lastPathComponent] stringByDeletingPathExtension];
						string = [self stringBySanitizingString:string forField:fieldName inFileType:[pub fileType]]; 
						[parsedStr appendString:string];
					}
					break;
				case 'L':
					// old filename with extension
					string = [pub localURLPath];
					if (string != nil) {
						string = [string lastPathComponent];
						string = [self stringBySanitizingString:string forField:fieldName inFileType:[pub fileType]]; 
						[parsedStr appendString:string];
					}
					break;
				case 'e':
					// old file extension
					string = [pub localURLPath];
					if (string != nil) {
						string = [string pathExtension];
						if (![string isEqualToString:@""]) {
							string = [self stringBySanitizingString:string forField:fieldName inFileType:[pub fileType]]; 
							[parsedStr appendFormat:@".%@", string];
						}
					}
					break;
				case 'f':
					// arbitrary field
					if ([scanner scanString:@"{" intoString:NULL] &&
						[scanner scanUpToString:@"}" intoString:&string] &&
						[scanner scanString:@"}" intoString:NULL]) {
						// look for [slash]
						slash = ([fieldName isEqualToString:BDSKLocalUrlString]) ? @"-" : @"/";
						if ([scanner scanString:@"[" intoString:NULL]) {
							if (![scanner scanUpToString:@"]" intoString:&slash]) slash = @"";
							[scanner scanString:@"]" intoString:NULL];
						}
					
						if (![scanner scanInt:&number]) number = 0;
						if (![fieldName isEqualToString:BDSKCiteKeyString] &&
							[string isEqualToString:BDSKCiteKeyString]) {
							string = [pub citeKey];
						} else if ([string isEqualToString:BDSKContainerString]) {
							string = [pub container];
						} else {
							string = [pub valueOfField:string];
						}
						if (string != nil) {
							string = [self stringByStrictlySanitizingString:string forField:fieldName inFileType:[pub fileType]];
							if (![slash isEqualToString:@"/"])
								string = [string stringByReplacingCharactersInSet:slashCharSet withString:slash];
							if (number > 0 && [string length] > number) {
								[parsedStr appendString:[string substringToIndex:number]];
							} else {
								[parsedStr appendString:string];
							}
						}
					}
					else {
						NSLog(@"Missing {'field'} after format specifier %%f in format.");
					}
					break;
				case 'c':
					// This handles acronym specifiers of the form %c{FieldName}
					if ([scanner scanString:@"{" intoString:NULL] &&
						[scanner scanUpToString:@"}" intoString:&string] &&
						[scanner scanString:@"}" intoString:NULL]) {
					
						string = [pub acronymValueOfField:string];
						string = [self stringByStrictlySanitizingString:string forField:fieldName inFileType:[pub fileType]];
						[parsedStr appendString:string];
					}
					else {
						NSLog(@"Missing {'field'} after format specifier %%c in format.");
					}
					break;
				case 'r':
					// random lowercase letters
					if (![scanner scanInt:&number]) number = 1;
					while (number-- > 0) {
						[parsedStr appendFormat:@"%c",'a' + (char)(rand() % 26)];
					}
					break;
				case 'R':
					// random uppercase letters
					if (![scanner scanInt:&number]) number = 1;
					while (number-- > 0) {
						[parsedStr appendFormat:@"%c",'A' + (char)(rand() % 26)];
					}
					break;
				case 'd':
					// random digits
					if (![scanner scanInt:&number]) number = 1;
					while (number-- > 0) {
						[parsedStr appendFormat:@"%i",(int)(rand() % 10)];
					}
					break;
				case '0':
				case '1':
				case '2':
				case '3':
				case '4':
				case '5':
				case '6':
				case '7':
				case '8':
				case '9':
				case '%':
				case '[':
				case ']':
					// escaped character
					[parsedStr appendFormat:@"%C", specifier];
					break;
				case 'u':
				case 'U':
				case 'n':
					// unique characters, these may only occur once
					if (uniqueSpecifier == 0) {
						uniqueSpecifier = specifier;
						savedStr = parsedStr;
						parsedStr = [NSMutableString string];
						if (![scanner scanInt:&uniqueNumber]) uniqueNumber = 1;
					}
					else {
						NSLog(@"Specifier %%%C can only be used once in the format.", specifier);
					}
					break;
				default: 
					NSLog(@"Unknown format specifier %%%C in format.", specifier);
			}
		}
	}
	
	if (uniqueSpecifier != 0) {
		switch (uniqueSpecifier) {
			case 'u':
				// unique lowercase letters
				[parsedStr setString:[self uniqueString:savedStr 
												 suffix:parsedStr
											   forField:fieldName
												 ofItem:pub
										  numberOfChars:uniqueNumber 
												   from:'a' to:'z' 
												  force:(uniqueNumber == 0)]];
				break;
			case 'U':
				// unique uppercase letters
				[parsedStr setString:[self uniqueString:savedStr 
												 suffix:parsedStr
											   forField:fieldName
												 ofItem:pub
										  numberOfChars:uniqueNumber 
												   from:'A' to:'Z' 
												  force:(uniqueNumber == 0)]];
				break;
			case 'n':
				// unique number
				[parsedStr setString:[self uniqueString:savedStr 
												 suffix:parsedStr
											   forField:fieldName
												 ofItem:pub
										  numberOfChars:uniqueNumber 
												   from:'0' to:'9' 
												  force:(uniqueNumber == 0)]];
				break;
		}
	}
	
	if(parsedStr == nil || [parsedStr isEqualToString:@""]) {
		number = 0;
		do {
			string = [@"empty" stringByAppendingFormat:@"%i", number++];
		} while (![self stringIsValid:string forField:fieldName ofItem:pub]);
		return string;
	} else {
	   return parsedStr;
	}
}

// returns a 'valid' string rather than a 'unique' one
- (NSString *)uniqueString:(NSString *)baseStr
					suffix:(NSString *)suffix
				  forField:(NSString *)fieldName 
					ofItem:(BibItem *)pub
			 numberOfChars:(unsigned int)number 
					  from:(unichar)fromChar 
						to:(unichar)toChar 
					 force:(BOOL)force {
	
	NSString *uniqueStr = nil;
	char c;
	
	if (number > 0) {
		for (c = fromChar; c <= toChar; c++) {
			// try with the first added char set to c
			uniqueStr = [baseStr stringByAppendingFormat:@"%C", c];
			uniqueStr = [self uniqueString:uniqueStr suffix:suffix forField:fieldName ofItem:pub numberOfChars:number - 1 from:fromChar to:toChar force:NO];
			if ([self stringIsValid:uniqueStr forField:fieldName ofItem:pub])
				return uniqueStr;
		}
	}
	else {
		uniqueStr = [baseStr stringByAppendingString:suffix];
	}
	
	if (force && ![self stringIsValid:uniqueStr forField:fieldName ofItem:pub]) {
		// not uniqueString yet, so try with 1 more char
		return [self uniqueString:baseStr suffix:suffix forField:fieldName ofItem:pub numberOfChars:number + 1 from:fromChar to:toChar force:YES];
	}
	
	return uniqueStr;
}

// this might be changed when more fields are available
// do we want to add character checks as in CiteKeyFormatter?
- (BOOL)stringIsValid:(NSString *)proposedStr forField:(NSString *)fieldName ofItem:(BibItem *)pub
{
	if ([fieldName isEqualToString:BDSKCiteKeyString]) {
		return !(proposedStr == nil || [proposedStr isEqualToString:@""] ||
				 [[pub document] citeKeyIsUsed:proposedStr byItemOtherThan:pub]);
	}
	else if ([fieldName isEqualToString:BDSKLocalUrlString]) {
		if (proposedStr == nil || [proposedStr isEqualToString:@""])
			return NO;
		OFPreferenceWrapper *prefs = [OFPreferenceWrapper sharedPreferenceWrapper];
		NSString *papersFolderPath = [[prefs stringForKey:BDSKPapersFolderPathKey] stringByExpandingTildeInPath];
		if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKLocalUrlLowercaseKey])
			proposedStr = [proposedStr lowercaseString];
		if ([[NSFileManager defaultManager] fileExistsAtPath:[papersFolderPath stringByAppendingPathComponent:proposedStr]])
			return NO;
		return YES;
	}
	else {
		[NSException raise:BDSKUnimplementedException format:@"stringIsValid:forField:ofItem: is partly implemented"];
		return YES;
	}
}

- (NSString *)stringBySanitizingString:(NSString *)string forField:(NSString *)fieldName inFileType:(NSString *)type
{
	NSCharacterSet *invalidCharSet = [[BibTypeManager sharedManager] invalidCharactersForField:fieldName inFileType:type];
	BDSKConverter *converter = [BDSKConverter sharedConverter];
    NSString *newString = nil;

	if ([fieldName isEqualToString:BDSKCiteKeyString]) {
		
		if (string == nil || [string isEqualToString:@""]) {
			return @"";
		}
		newString = [converter stringByDeTeXifyingString:string];
		newString = [newString stringByReplacingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
													 withString:@"-"];
		newString = [newString stringByReplacingCharactersInSet:invalidCharSet withString:@""];
		
		return newString;
	}
	else if ([fieldName isEqualToString:BDSKLocalUrlString]) {
		
		if (string == nil || [string isEqualToString:@""]) {
			return @"";
		}
		newString = [converter stringByDeTeXifyingString:string];
		newString = [newString stringByReplacingCharactersInSet:invalidCharSet withString:@""];
		
		return newString;
	}
	else {
		[NSException raise:BDSKUnimplementedException format:@"stringBySanitizingString:forField:inFileType: is partly implemented"];
		return string;
	}
}

- (NSString *)stringByStrictlySanitizingString:(NSString *)string forField:(NSString *)fieldName inFileType:(NSString *)type
{
	NSCharacterSet *invalidCharSet = [[BibTypeManager sharedManager] strictInvalidCharactersForField:fieldName inFileType:type];
	BDSKConverter *converter = [BDSKConverter sharedConverter];
    NSString *newString = nil;
	int cleanOption = 0;

	if ([fieldName isEqualToString:BDSKCiteKeyString]) {
		cleanOption = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKCiteKeyCleanOptionKey];
		
		if (string == nil || [string isEqualToString:@""]) {
			return @"";
		}
		newString = [converter stringByDeTeXifyingString:string];
		if (cleanOption == 1) {
			newString = [newString stringByRemovingCurlyBraces];
		} else if (cleanOption == 2) {
			newString = [newString stringByRemovingTeX];
		}
		newString = [newString stringByReplacingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
													 withString:@"-"];
		newString = [NSString lossyASCIIStringWithString:newString];
		newString = [newString stringByReplacingCharactersInSet:invalidCharSet withString:@""];
		
		return newString;
	}
	else if ([fieldName isEqualToString:BDSKLocalUrlString]) {
		cleanOption = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKLocalUrlCleanOptionKey];
		
		if (string == nil || [string isEqualToString:@""]) {
			return @"";
		}
		newString = [converter stringByDeTeXifyingString:string];
		if (cleanOption == 1) {
			newString = [newString stringByRemovingCurlyBraces];
		} else if (cleanOption == 2) {
			newString = [newString stringByRemovingTeX];
		}
		newString = [newString stringByReplacingCharactersInSet:invalidCharSet withString:@""];
		
		return newString;
	}
	else {
		[NSException raise:BDSKUnimplementedException format:@"stringByStrictlySanitizingString:forField:inFileType: is partly implemented"];
		return string;
	}
}

- (BOOL)validateFormat:(NSString **)formatString forField:(NSString *)fieldName inFileType:(NSString *)type error:(NSString **)error
{
	NSCharacterSet *invalidCharSet = [[BibTypeManager sharedManager] invalidCharactersForField:fieldName inFileType:type];
	NSScanner *scanner = [NSScanner scannerWithString:*formatString];
	NSMutableString *sanitizedFormatString = [NSMutableString string];
	NSString *string = nil;
	unichar specifier;
	BOOL foundUnique = NO;
	
	[scanner setCharactersToBeSkipped:nil];
	
	while (![scanner isAtEnd]) {
		// scan non-specifier parts
		if ([scanner scanUpToString:@"%" intoString:&string]) {
			string = [self stringBySanitizingString:string forField:fieldName inFileType:type];
			[sanitizedFormatString appendString:string];
		}
		if (![scanner scanString:@"%" intoString: NULL]) { // we're at the end, so done
			break;
		}
		if ([scanner isAtEnd]) {
			*error = NSLocalizedString(@"Empty specifier % at end of format.", @"");
			return NO;
		}
		// found %, so now there should be a specifier char
		specifier = [*formatString characterAtIndex:[scanner scanLocation]];
		[scanner setScanLocation:[scanner scanLocation]+1];
		[sanitizedFormatString appendFormat:@"%%%C", specifier];
		// now see if it is a valid specifier
		if ([validArgSpecifierChars characterIsMember:specifier]) {
			if ( [scanner isAtEnd] || 
				 ![scanner scanString:@"{" intoString: NULL] ||
				 ![scanner scanUpToString:@"}" intoString:&string] ||
				 ![scanner scanString:@"}" intoString:NULL]) {
				*error = [NSString stringWithFormat: NSLocalizedString(@"Specifier %%%C must be followed by a {'field'} name.", @""), specifier];
				return NO;
			}
			string = [self stringBySanitizingString:string forField:BDSKCiteKeyString inFileType:type]; // cite-key sanitization is strict, so we use that for fieldnames
			string = [string capitalizedString];
			if ([string isEqualToString:@"Cite-Key"] || [string isEqualToString:@"Citekey"])
				string = BDSKCiteKeyString;
			[sanitizedFormatString appendFormat:@"{%@}", string]; // we need to have BibTeX field names capitalized
			if (specifier == 'f' && [scanner scanString:@"[" intoString:NULL]) {
				if (![scanner scanUpToString:@"]" intoString:&string]) 
					string = @"";
				if (![scanner scanString:@"]" intoString:NULL]) {
					*error = [NSString stringWithFormat: NSLocalizedString(@"Missing \"]\" after specifier %%%C.", @""), specifier];
					return NO;
				}
				string = [self stringBySanitizingString:string forField:fieldName inFileType:type];
				[sanitizedFormatString appendFormat:@"[%@]", string];
			}
		}
		else if ([validOptArgSpecifierChars characterIsMember:specifier]) {
			if (![scanner isAtEnd]) {
				int numOpts = ((specifier == 'A')? 3 : ((specifier == 'a')? 2 : 1));
				while ([scanner scanString:@"[" intoString: NULL]) {
					if (numOpts-- == 0) {
						*error = [NSString stringWithFormat: NSLocalizedString(@"Too many optional arguments after specifier %%%C.", @""), specifier];
						return NO;
					}
					if (![scanner scanUpToString:@"]" intoString:&string]) 
						string = @"";
					if (![scanner scanString:@"]" intoString:NULL]) {
						*error = [NSString stringWithFormat: NSLocalizedString(@"Missing \"]\" after specifier %%%C.", @""), specifier];
						return NO;
					}
					string = [self stringBySanitizingString:string forField:fieldName inFileType:type];
					[sanitizedFormatString appendFormat:@"[%@]", string];
				}
			}
		}
		else if ([validUniqueSpecifierChars characterIsMember:specifier]) {
			if (foundUnique) { // a second 'unique' specifier was found
				*error = [NSString stringWithFormat: NSLocalizedString(@"Unique specifier %%%C can appear only once in format.", @""), specifier];
				return NO;
			}
			foundUnique = YES;
		}
		else if ([validEscapeSpecifierChars characterIsMember:specifier]) {
			if ([invalidCharSet characterIsMember:specifier]) {
				*error = [NSString stringWithFormat: NSLocalizedString(@"Invalid escape specifier %%%C in format.", @""), specifier];
				return NO;
			}
		}
		else if (![validSpecifierChars characterIsMember:specifier]) {
			*error = [NSString stringWithFormat:NSLocalizedString(@"Invalid specifier %%%C in format.", @""), specifier];
			return NO;
		}
	}
	
	// change formatString
	*formatString = [[sanitizedFormatString copy] autorelease];
	
	return YES;
}

- (NSArray *)requiredFieldsForFormat:(NSString *)formatString
{
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
	NSEnumerator *cEnum = [[formatString componentsSeparatedByString:@"%"] objectEnumerator];
	NSString *string;
	
	[cEnum nextObject];
	while (string = [cEnum nextObject]) {
		if ([string length] == 0) {
			string = [cEnum nextObject];
			continue;
		}
		switch ([string characterAtIndex:0]) {
			case 'a':
			case 'A':
				[arr addObject:BDSKAuthorString];
				break;
			case 't':
			case 'T':
				[arr addObject:BDSKTitleString];
				break;
			case 'y':
			case 'Y':
				[arr addObject:BDSKYearString];
				break;
			case 'm':
				[arr addObject:BDSKMonthString];
				break;
			case 'l':
			case 'L':
			case 'e':
				[arr addObject:BDSKLocalUrlString];
				break;
            case 'k':
                [arr addObject:BDSKKeywordsString];
                break;
			case 'f':
			case 'c':
				[arr addObject:[[[string componentsSeparatedByString:@"}"] objectAtIndex:0] substringFromIndex:2]];
		}
	}
	return arr;
}

@end
