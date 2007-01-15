//
//  BDSKFormatParser.m
//  BibDesk
//
//  Created by Christiaan Hofman on 17/4/05.
/*
 This software is Copyright (c) 2005,2006,2007
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
#import <OmniFoundation/NSAttributedString-OFExtensions.h>
#import "BibPrefController.h"
#import "BibAuthor.h"
#import "BDSKConverter.h"
#import "BibTypeManager.h"
#import "NSString_BDSKExtensions.h"
#import "NSDate_BDSKExtensions.h"
#import "NSScanner_BDSKExtensions.h"

@implementation BDSKFormatParser

+ (NSString *)parseFormat:(NSString *)format forField:(NSString *)fieldName ofItem:(id <BDSKParseableItem>)pub
{
    return [self parseFormat:format forField:fieldName ofItem:pub suggestion:nil];
}

+ (NSString *)parseFormat:(NSString *)format forField:(NSString *)fieldName ofItem:(id <BDSKParseableItem>)pub suggestion:(NSString *)suggestion
{
	static NSCharacterSet *nonLowercaseLetterCharSet = nil;
	static NSCharacterSet *nonUppercaseLetterCharSet = nil;
	static NSCharacterSet *nonDecimalDigitCharSet = nil;
	
    if (nonLowercaseLetterCharSet == nil) {
        nonLowercaseLetterCharSet = [[[NSCharacterSet characterSetWithRange:NSMakeRange('a',26)] invertedSet] copy];
        nonUppercaseLetterCharSet = [[[NSCharacterSet characterSetWithRange:NSMakeRange('A',26)] invertedSet] copy];
        nonDecimalDigitCharSet = [[[NSCharacterSet characterSetWithRange:NSMakeRange('0',10)] invertedSet] copy];
    }
    
    NSMutableString *parsedStr = [NSMutableString string];
	NSString *prefixStr = nil;
	NSScanner *scanner = [NSScanner scannerWithString:format];
	NSString *string, *authSep, *nameSep, *etal, *slash;
	unsigned int number, numAuth, i, uniqueNumber;
    int intValue;
	unichar specifier, nextChar, uniqueSpecifier = 0;
	NSArray *authArray;
	NSMutableArray *arr;
	NSScanner *wordScanner;
	NSCharacterSet *slashCharSet = [NSCharacterSet characterSetWithCharactersInString:@"/"];
	NSArray *localFileFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey];
	BOOL isLocalFile = [localFileFields containsObject:fieldName];
	
	[scanner setCharactersToBeSkipped:nil];
	
	while (![scanner isAtEnd]) {
		// scan non-specifier parts
		if ([scanner scanUpToString:@"%" intoString:&string]) {
			// if we are not sure about a valid format, we should sanitize string
			[parsedStr appendString:string];
		}
		// does nothing at the end; allows but ignores % at end
		[scanner scanString:@"%" intoString:NULL];
        // found %, so now there should be a specifier char
		if ([scanner scanCharacter:&specifier]) {
			switch (specifier) {
				case 'a':
				case 'p':
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
						if ([scanner peekCharacter:&nextChar]) {
							// look for #names
							if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:nextChar]) {
								[scanner setScanLocation:[scanner scanLocation]+1];
								numAuth = (unsigned)(nextChar - '0');
								// scan for #chars per name
								if (![scanner scanUnsignedInt:&number]) number = 0;
							}
						}
					}
					authArray = [pub peopleArrayForField:BDSKAuthorString];
					if ([authArray count] == 0 && specifier == 'p') {
						authArray = [pub peopleArrayForField:BDSKEditorString];
					}
					if ([authArray count] == 0) {
						break;
					}
					if (numAuth == 0 || numAuth > [authArray count]) {
						numAuth = [authArray count];
					}
					for (i = 0; i < numAuth; i++) {
						if (i > 0) {
							[parsedStr appendString:authSep];
						}
						string = [self stringByStrictlySanitizingString:[[authArray objectAtIndex:i] lastName] forField:fieldName inFileType:[pub fileType]];
						if (isLocalFile) {
							string = [string stringByReplacingCharactersInSet:slashCharSet withString:@"-"];
						}
						if ([string length] > number && number > 0) {
							string = [string substringToIndex:number];
						}
						[parsedStr appendString:string];
					}
					if (numAuth < [authArray count]) {
						[parsedStr appendString:etal];
					}
					break;
				case 'A':
				case 'P':
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
						if ([scanner peekCharacter:&nextChar]) {
							// look for #names
							if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:nextChar]) {
								[scanner setScanLocation:[scanner scanLocation]+1];
								numAuth = (unsigned)(nextChar - '0');
							}
						}
					}
					authArray = [pub peopleArrayForField:BDSKAuthorString];
					if ([authArray count] == 0 && specifier == 'P') {
						authArray = [pub peopleArrayForField:BDSKEditorString];
					}
					if ([authArray count] == 0) {
						break;
					}
					if (numAuth == 0 || numAuth > [authArray count]) {
						numAuth = [authArray count];
					}
					for (i = 0; i < numAuth; i++) {
						if (i > 0) {
							[parsedStr appendString:authSep];
						}
						BibAuthor *auth = [authArray objectAtIndex:i];
						NSString *firstName = [self stringByStrictlySanitizingString:[auth firstName] forField:fieldName inFileType:[pub fileType]];
						NSString *lastName = [self stringByStrictlySanitizingString:[auth lastName] forField:fieldName inFileType:[pub fileType]];
						if ([firstName length] > 0) {
							string = [NSString stringWithFormat:@"%@%@%C", 
											lastName, nameSep, [firstName characterAtIndex:0]];
						} else {
							string = lastName;
						}
						if (isLocalFile) {
							string = [string stringByReplacingCharactersInSet:slashCharSet withString:@"-"];
						}
						[parsedStr appendString:string];
					}
					if (numAuth < [authArray count]) {
						[parsedStr appendString:etal];
					}
					break;
				case 't':
					// title, optional #chars
                    string = [pub title];
					string = [self stringByStrictlySanitizingString:string forField:fieldName inFileType:[pub fileType]];
					if (isLocalFile) {
						string = [string stringByReplacingCharactersInSet:slashCharSet withString:@"-"];
					}
					if (![scanner scanUnsignedInt:&number]) number = 0;
					if (number > 0 && [string length] > number) {
						[parsedStr appendString:[string substringToIndex:number]];
					} else {
						[parsedStr appendString:string];
					}
					break;
				case 'T':
					// title, optional #words
                    string = [pub title];
					if (![scanner scanUnsignedInt:&number]) number = 0;
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
							if (isLocalFile) {
								string = [string stringByReplacingCharactersInSet:slashCharSet withString:@"-"];
							}
							[parsedStr appendString:string]; 
							if ([string length] > 3) --number;
						}
					}
					break;
				case 'y':
					// year without century
                    string = [pub stringValueOfField:BDSKYearString];
                    if ([NSString isEmptyString:string] == NO) {
                        NSDate *date = [[NSDate alloc] initWithMonthDayYearString:[NSString stringWithFormat:@"6-15-%@", string]];
						string = [date descriptionWithCalendarFormat:@"%y" timeZone:nil locale:nil];
						[parsedStr appendString:string];
                        [date release];
					}
					break;
				case 'Y':
					// year with century
                    string = [pub stringValueOfField:BDSKYearString];
                    if ([NSString isEmptyString:string] == NO) {
                        NSDate *date = [[NSDate alloc] initWithMonthDayYearString:[NSString stringWithFormat:@"6-15-%@", string]];
						string = [date descriptionWithCalendarFormat:@"%Y" timeZone:nil locale:nil];
						[parsedStr appendString:string];
                        [date release];
					}
					break;
				case 'm':
					// month
                    string = [pub stringValueOfField:BDSKMonthString];
                    if ([NSString isEmptyString:string] == NO) {
                        NSDate *date = [[NSDate alloc] initWithMonthDayYearString:[NSString stringWithFormat:@"%@-15-2000", string]];
						string = [date descriptionWithCalendarFormat:@"%m" timeZone:nil locale:nil];
						[parsedStr appendString:string];
                        [date release];
					}
					break;
				case 'k':
					// keywords
					// look for [slash]
					slash = (isLocalFile) ? @"-" : @"/";
					if ([scanner scanString:@"[" intoString:NULL]) {
						if (![scanner scanUpToString:@"]" intoString:&slash]) slash = @"";
						[scanner scanString:@"]" intoString:NULL];
					}
					string = [pub stringValueOfField:BDSKKeywordsString];
					if (![scanner scanUnsignedInt:&number]) number = 0;
					if (string != nil) {
						arr = [NSMutableArray array];
						// split the keyword string using the same methodology as addString:forCompletionEntry:, treating ,:; as possible dividers
                        NSCharacterSet *sepCharSet = [[BibTypeManager sharedManager] separatorCharacterSetForField:BDSKKeywordsString];
                        NSRange keywordPunctuationRange = [string rangeOfCharacterFromSet:sepCharSet];
						if (keywordPunctuationRange.location != NSNotFound) {
							wordScanner = [NSScanner scannerWithString:string];
							[wordScanner setCharactersToBeSkipped:nil];
							
							while (![wordScanner isAtEnd]) {
								if ([wordScanner scanUpToCharactersFromSet:sepCharSet intoString:&string])
									[arr addObject:string];
								[wordScanner scanCharactersFromSet:sepCharSet intoString:nil];
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
					if ([fieldName isLocalFileField])
						string = [pub localFilePathForField:fieldName];
					else
						string = [pub localFilePathForField:BDSKLocalUrlString];
					if (string != nil) {
						string = [[string lastPathComponent] stringByDeletingPathExtension];
						string = [self stringBySanitizingString:string forField:fieldName inFileType:[pub fileType]]; 
						[parsedStr appendString:string];
					}
					break;
				case 'L':
					// old filename with extension
					if ([fieldName isLocalFileField])
						string = [pub localFilePathForField:fieldName];
					else
						string = [pub localFilePathForField:BDSKLocalUrlString];
					if (string != nil) {
						string = [string lastPathComponent];
						string = [self stringBySanitizingString:string forField:fieldName inFileType:[pub fileType]]; 
						[parsedStr appendString:string];
					}
					break;
				case 'e':
					// old file extension
					if ([fieldName isLocalFileField])
						string = [pub localFilePathForField:fieldName];
					else
						string = [pub localFilePathForField:BDSKLocalUrlString];
					if (string != nil) {
						string = [string pathExtension];
						if (![string isEqualToString:@""]) {
							string = [self stringBySanitizingString:string forField:fieldName inFileType:[pub fileType]]; 
							[parsedStr appendFormat:@".%@", string];
						}
					}
					break;
				case 'b':
					// document filename
					string = [pub documentFileName];
					if (string != nil) {
						string = [[string lastPathComponent] stringByDeletingPathExtension];
						string = [self stringBySanitizingString:string forField:fieldName inFileType:[pub fileType]]; 
						[parsedStr appendString:string];
					}
					break;
				case 'f':
					// arbitrary field
					if ([scanner scanString:@"{" intoString:NULL] &&
						[scanner scanUpToString:@"}" intoString:&string] &&
						[scanner scanString:@"}" intoString:NULL]) {
						// look for [slash]
						slash = (isLocalFile) ? @"-" : @"/";
						if ([scanner scanString:@"[" intoString:NULL]) {
							if (![scanner scanUpToString:@"]" intoString:&slash]) slash = @"";
							[scanner scanString:@"]" intoString:NULL];
						}
					
						if (![scanner scanUnsignedInt:&number]) number = 0;
						if (![fieldName isEqualToString:BDSKCiteKeyString] &&
							[string isEqualToString:BDSKCiteKeyString]) {
							string = [pub citeKey];
						} else if ([string isEqualToString:BDSKContainerString]) {
							string = [pub container];
						} else {
							string = [pub stringValueOfField:string];
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
						if (![scanner scanUnsignedInt:&number]) number = 3;
				
						string = [[pub stringValueOfField:string] acronymValueIgnoringWordLength:number];
						string = [self stringByStrictlySanitizingString:string forField:fieldName inFileType:[pub fileType]];
						[parsedStr appendString:string];
					}
					else {
						NSLog(@"Missing {'field'} after format specifier %%c in format.");
					}
					break;
				case 's':
					// arbitrary boolean or tri-value field
					if ([scanner scanString:@"{" intoString:NULL] &&
						[scanner scanUpToString:@"}" intoString:&string] &&
						[scanner scanString:@"}" intoString:NULL]) {
						NSString *yesValue = @"";
						NSString *noValue = @"";
						NSString *mixedValue = @"";
						// look for [yes value]
						if ([scanner scanString:@"[" intoString:NULL]) {
							if (![scanner scanUpToString:@"]" intoString:&yesValue]) yesValue = @"";
							[scanner scanString:@"]" intoString:NULL];
                            // look for [no value]
                            if ([scanner scanString:@"[" intoString:NULL]) {
                                if (![scanner scanUpToString:@"]" intoString:&noValue]) noValue = @"";
                                [scanner scanString:@"]" intoString:NULL];
                                // look for [mixed value]
                                if ([scanner scanString:@"[" intoString:NULL]) {
                                    if (![scanner scanUpToString:@"]" intoString:&mixedValue]) mixedValue = @"";
                                    [scanner scanString:@"]" intoString:NULL];
                                }
                            }
                        }
						if (![scanner scanUnsignedInt:&number]) number = 0;
                        intValue = [pub intValueOfField:string];
                        string = (intValue == 0 ? noValue : (intValue == 1 ? yesValue : mixedValue));
                        if (number > 0 && [string length] > number) {
                            [parsedStr appendString:[string substringToIndex:number]];
                        } else {
                            [parsedStr appendString:string];
                        }
					}
					else {
						NSLog(@"Missing {'field'} after format specifier %%s in format.");
					}
					break;
				case 'i':
					// arbitrary document info
					if ([scanner scanString:@"{" intoString:NULL] &&
						[scanner scanUpToString:@"}" intoString:&string] &&
						[scanner scanString:@"}" intoString:NULL]) {
					
						if (![scanner scanUnsignedInt:&number]) number = 0;
                        string = [pub documentInfoForKey:string];
						if (string != nil) {
							string = [self stringByStrictlySanitizingString:string forField:fieldName inFileType:[pub fileType]];
							if (number > 0 && [string length] > number) {
								[parsedStr appendString:[string substringToIndex:number]];
							} else {
								[parsedStr appendString:string];
							}
						}
					}
					else {
						NSLog(@"Missing {'key'} after format specifier %%i in format.");
					}
					break;
				case 'r':
					// random lowercase letters
					if (![scanner scanUnsignedInt:&number]) number = 1;
					while (number-- > 0) {
						[parsedStr appendFormat:@"%c",'a' + (char)(rand() % 26)];
					}
					break;
				case 'R':
					// random uppercase letters
					if (![scanner scanUnsignedInt:&number]) number = 1;
					while (number-- > 0) {
						[parsedStr appendFormat:@"%c",'A' + (char)(rand() % 26)];
					}
					break;
				case 'd':
					// random digits
					if (![scanner scanUnsignedInt:&number]) number = 1;
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
						prefixStr = parsedStr;
						parsedStr = [NSMutableString string];
						if (![scanner scanUnsignedInt:&uniqueNumber]) uniqueNumber = 1;
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
        NSString *suggestedUnique = nil;
        unsigned prefixLength = [prefixStr length];
        unsigned suffixLength = [parsedStr length];
        unsigned suggestionLength = [suggestion length] - prefixLength - suffixLength;
        if (suggestion && ((uniqueNumber == 0 && suggestionLength >= 0) || suggestionLength == uniqueNumber) &&
            (prefixLength == 0 || [suggestion hasPrefix:prefixStr]) && (suffixLength == 0 || [suggestion hasSuffix:parsedStr])) {
            suggestedUnique = [suggestion substringWithRange:NSMakeRange(prefixLength, suggestionLength)];
        }
		switch (uniqueSpecifier) {
			case 'u':
				// unique lowercase letters
                if (suggestedUnique && [suggestedUnique rangeOfCharacterFromSet:nonLowercaseLetterCharSet].location == NSNotFound) {
                    [parsedStr setString:suggestion];
                } else {
                    [parsedStr setString:[self uniqueString:prefixStr 
                                                     suffix:parsedStr
                                                   forField:fieldName
                                                     ofItem:pub
                                              numberOfChars:uniqueNumber 
                                                       from:'a' to:'z' 
                                                      force:(uniqueNumber == 0)]];
                }
				break;
			case 'U':
				// unique uppercase letters
                if (suggestedUnique && [suggestedUnique rangeOfCharacterFromSet:nonUppercaseLetterCharSet].location == NSNotFound) {
                    [parsedStr setString:suggestion];
                } else {
                    [parsedStr setString:[self uniqueString:prefixStr 
                                                     suffix:parsedStr
                                                   forField:fieldName
                                                     ofItem:pub
                                              numberOfChars:uniqueNumber 
                                                       from:'A' to:'Z' 
                                                      force:(uniqueNumber == 0)]];
				}
                break;
			case 'n':
				// unique number
                if (suggestedUnique && [suggestedUnique rangeOfCharacterFromSet:nonDecimalDigitCharSet].location == NSNotFound) {
                    [parsedStr setString:suggestion];
                } else {
                    [parsedStr setString:[self uniqueString:prefixStr 
                                                     suffix:parsedStr
                                                   forField:fieldName
                                                     ofItem:pub
                                              numberOfChars:uniqueNumber 
                                                       from:'0' to:'9' 
                                                      force:(uniqueNumber == 0)]];
				}
                break;
		}
	}
	
	if([NSString isEmptyString:parsedStr]) {
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
+ (NSString *)uniqueString:(NSString *)baseStr
					suffix:(NSString *)suffix
				  forField:(NSString *)fieldName 
					ofItem:(id <BDSKParseableItem>)pub
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
		// not unique yet, so try with 1 more char
		return [self uniqueString:baseStr suffix:suffix forField:fieldName ofItem:pub numberOfChars:number + 1 from:fromChar to:toChar force:YES];
	}
	
	return uniqueStr;
}

// this might be changed when more fields are available
// do we want to add character checks as in CiteKeyFormatter?
+ (BOOL)stringIsValid:(NSString *)proposedStr forField:(NSString *)fieldName ofItem:(id <BDSKParseableItem>)pub
{
	if ([fieldName isEqualToString:BDSKCiteKeyString]) {
		return [pub isValidCiteKey:proposedStr];
	}
	else if ([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey] containsObject:fieldName]) {
		return [pub isValidLocalUrlPath:proposedStr];
	}
	else if ([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRemoteURLFieldsKey] containsObject:fieldName]) {
		if ([NSString isEmptyString:proposedStr])
			return NO;
		return YES;
	}
	else {
		return YES;
	}
}

+ (NSString *)stringBySanitizingString:(NSString *)string forField:(NSString *)fieldName inFileType:(NSString *)type
{
	NSCharacterSet *invalidCharSet = [[BibTypeManager sharedManager] invalidCharactersForField:fieldName inFileType:type];
    NSString *newString = nil;

	if ([fieldName isEqualToString:BDSKCiteKeyString]) {
		
		if ([NSString isEmptyString:string]) {
			return @"";
		}
		newString = [string stringByDeTeXifyingString];
		newString = [newString stringByReplacingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
													 withString:@"-"];
		newString = [newString stringByReplacingCharactersInSet:invalidCharSet withString:@""];
		
		return newString;
	}
	else if ([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey] containsObject:fieldName]) {
		
		if ([NSString isEmptyString:string]) {
			return @"";
		}
		newString = [string stringByDeTeXifyingString];
		newString = [newString stringByReplacingCharactersInSet:invalidCharSet withString:@""];
		
		return newString;
	}
	else if ([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRemoteURLFieldsKey] containsObject:fieldName]) {
		
		if ([NSString isEmptyString:string]) {
			return @"";
		}
		newString = [string stringByDeTeXifyingString];
		newString = [newString stringByReplacingCharactersInSet:invalidCharSet withString:@""];
		
		return newString;
	}
	else {
		newString = [string stringByReplacingCharactersInSet:invalidCharSet withString:@""];
		return newString;
	}
}

+ (NSString *)stringByStrictlySanitizingString:(NSString *)string forField:(NSString *)fieldName inFileType:(NSString *)type
{
	NSCharacterSet *invalidCharSet = [[BibTypeManager sharedManager] strictInvalidCharactersForField:fieldName inFileType:type];
    NSString *newString = nil;
	int cleanOption = 0;

	if ([fieldName isEqualToString:BDSKCiteKeyString]) {
		cleanOption = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKCiteKeyCleanOptionKey];
		
		if ([NSString isEmptyString:string]) {
			return @"";
		}
		newString = [string stringByDeTeXifyingString];
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
	else if ([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey] containsObject:fieldName]) {
		cleanOption = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKLocalUrlCleanOptionKey];
		
		if (cleanOption >= 3)
			invalidCharSet = [[BibTypeManager sharedManager] veryStrictInvalidCharactersForField:fieldName inFileType:type];
		
		if ([NSString isEmptyString:string]) {
			return @"";
		}
		newString = [string stringByDeTeXifyingString];
		if (cleanOption == 1) {
			newString = [newString stringByRemovingCurlyBraces];
		} else if (cleanOption >= 2) {
			newString = [newString stringByRemovingTeX];
            if (cleanOption == 4)
                newString = [NSString lossyASCIIStringWithString:newString];
		}
		newString = [newString stringByReplacingCharactersInSet:invalidCharSet withString:@""];
		
		return newString;
	}
	else if ([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRemoteURLFieldsKey] containsObject:fieldName]) {
		if ([NSString isEmptyString:string]) {
			return @"";
		}
		newString = [string stringByDeTeXifyingString];
		newString = [NSString lossyASCIIStringWithString:newString];
		newString = [newString stringByRemovingTeX];
		newString = [newString stringByReplacingCharactersInSet:invalidCharSet withString:@""];
		
		return newString;
	}
	else {
		newString = [newString stringByReplacingCharactersInSet:invalidCharSet withString:@""];
		return string;
	}
}

+ (BOOL)validateFormat:(NSString **)formatString forField:(NSString *)fieldName inFileType:(NSString *)type error:(NSString **)error
{
	return [self validateFormat:formatString attributedFormat:NULL forField:fieldName inFileType:type error:error];
}

#define AppendStringToFormatStrings(s, attr) \
	[sanitizedFormatString appendString:s]; \
	[attrString appendString:s attributes:attr]; \
	location = [scanner scanLocation];

+ (BOOL)validateFormat:(NSString **)formatString attributedFormat:(NSAttributedString **)attrFormatString forField:(NSString *)fieldName inFileType:(NSString *)type error:(NSString **)error
{
	static NSCharacterSet *validSpecifierChars = nil;
	static NSCharacterSet *validParamSpecifierChars = nil;
	static NSCharacterSet *validUniqueSpecifierChars = nil;
	static NSCharacterSet *validEscapeSpecifierChars = nil;
	static NSCharacterSet *validArgSpecifierChars = nil;
	static NSCharacterSet *validOptArgSpecifierChars = nil;
	static NSDictionary *specAttr = nil;
	static NSDictionary *paramAttr = nil;
	static NSDictionary *argAttr = nil;
	static NSDictionary *textAttr = nil;
	static NSDictionary *errorAttr = nil;
	
	if (validSpecifierChars == nil) {
		validSpecifierChars = [[NSCharacterSet characterSetWithCharactersInString:@"aApPtTmyYlLebkfcsirRduUn0123456789%[]"] retain];
		validParamSpecifierChars = [[NSCharacterSet characterSetWithCharactersInString:@"aApPtTkfcirRduUn"] retain];
		validUniqueSpecifierChars = [[NSCharacterSet characterSetWithCharactersInString:@"uUn"] retain];
		validEscapeSpecifierChars = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789%[]"] retain];
		validArgSpecifierChars = [[NSCharacterSet characterSetWithCharactersInString:@"fcsi"] retain];
		validOptArgSpecifierChars = [[NSCharacterSet characterSetWithCharactersInString:@"aApPkfs"] retain];
		
		NSFont *font = [NSFont systemFontOfSize:0];
		NSFont *boldFont = [NSFont boldSystemFontOfSize:0];
		specAttr = [[NSDictionary alloc] initWithObjectsAndKeys:boldFont, NSFontAttributeName, [NSColor blueColor], NSForegroundColorAttributeName, nil];
		paramAttr = [[NSDictionary alloc] initWithObjectsAndKeys:boldFont, NSFontAttributeName, [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.0 alpha:1.0], NSForegroundColorAttributeName, nil];
		argAttr = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, [NSColor controlTextColor], NSForegroundColorAttributeName, nil];
		textAttr = [[NSDictionary alloc] initWithObjectsAndKeys:boldFont, NSFontAttributeName, [NSColor controlTextColor], NSForegroundColorAttributeName, nil];
		errorAttr = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, [NSColor redColor], NSForegroundColorAttributeName, nil];
	}
	
	NSCharacterSet *invalidCharSet = [[BibTypeManager sharedManager] invalidCharactersForField:fieldName inFileType:type];
	NSCharacterSet *digitCharSet = [NSCharacterSet decimalDigitCharacterSet];
	NSScanner *scanner = [NSScanner scannerWithString:*formatString];
	NSMutableString *sanitizedFormatString = [[NSMutableString alloc] init];
	NSString *string = nil;
	unichar specifier;
	BOOL foundUnique = NO;
	NSMutableAttributedString *attrString = nil;
	NSString *errorMsg = nil;
	unsigned int location = 0;
	
	if (attrFormatString != NULL)
		attrString = [[NSMutableAttributedString alloc] init];
	
	[scanner setCharactersToBeSkipped:nil];
	
	while (![scanner isAtEnd]) {
		
		// scan non-specifier parts
		if ([scanner scanUpToString:@"%" intoString:&string]) {
			string = [self stringBySanitizingString:string forField:fieldName inFileType:type];
			AppendStringToFormatStrings(string, textAttr);
		}
		if (![scanner scanString:@"%" intoString: NULL]) { // we're at the end, so done
			break;
		}
		
		// found %, so now there should be a specifier char
		if (![scanner scanCharacter:&specifier]) {
			errorMsg = NSLocalizedString(@"Empty specifier % at end of format.", @"Error description");
			break;
		}
		
		// see if it is a valid specifier
		if (![validSpecifierChars characterIsMember:specifier]) {
			errorMsg = [NSString stringWithFormat:NSLocalizedString(@"Invalid specifier %%%C in format.", @"Error description"), specifier];
			break;
		}
		else if ([validEscapeSpecifierChars characterIsMember:specifier] && [invalidCharSet characterIsMember:specifier]) {
			errorMsg = [NSString stringWithFormat: NSLocalizedString(@"Invalid escape specifier %%%C in format.", @"Error description"), specifier];
			break;
		}
		else if ([validUniqueSpecifierChars characterIsMember:specifier]) {
			if (foundUnique) { // a second 'unique' specifier was found
				errorMsg = [NSString stringWithFormat: NSLocalizedString(@"Unique specifier %%%C can appear only once in format.", @"Error description"), specifier];
				break;
			}
			foundUnique = YES;
		}
		string = [NSString stringWithFormat:@"%%%C", specifier];
		AppendStringToFormatStrings(string, specAttr);
		
		// check compulsory argument
		if ([validArgSpecifierChars characterIsMember:specifier]) {
			if ( [scanner isAtEnd] || 
				 ![scanner scanString:@"{" intoString: NULL] ||
				 ![scanner scanUpToString:@"}" intoString:&string] ||
				 ![scanner scanString:@"}" intoString:NULL]) {
				errorMsg = [NSString stringWithFormat: NSLocalizedString(@"Specifier %%%C must be followed by a {'field'} name.", @"Error description"), specifier];
				break;
			}
			string = [self stringBySanitizingString:string forField:BDSKCiteKeyString inFileType:type]; // cite-key sanitization is strict, so we use that for fieldnames
			string = [string fieldName]; // we need to have BibTeX field names capitalized
			if ([string isEqualToString:@"Cite-Key"] || [string isEqualToString:@"Citekey"])
				string = BDSKCiteKeyString;
			AppendStringToFormatStrings(@"{", specAttr);
			AppendStringToFormatStrings(string, argAttr);
			AppendStringToFormatStrings(@"}", specAttr);
		}
		
		// check optional arguments
		if ([validOptArgSpecifierChars characterIsMember:specifier]) {
			if (![scanner isAtEnd]) {
				int numOpts = ((specifier == 'A' || specifier == 'P' || specifier == 's')? 3 : ((specifier == 'a' || specifier == 'p')? 2 : 1));
				while (numOpts-- && [scanner scanString:@"[" intoString: NULL]) {
					if (![scanner scanUpToString:@"]" intoString:&string]) 
						string = @"";
					if (![scanner scanString:@"]" intoString:NULL]) {
						errorMsg = [NSString stringWithFormat: NSLocalizedString(@"Missing \"]\" after specifier %%%C.", @"Error description"), specifier];
						break;
					}
					string = [self stringBySanitizingString:string forField:fieldName inFileType:type];
					AppendStringToFormatStrings(@"[", paramAttr);
					AppendStringToFormatStrings(string, paramAttr);
					AppendStringToFormatStrings(@"]", paramAttr);
				}
				if (errorMsg != nil)
					break;
			}
		}
		
		// check numeric optional parameters
		if ([validParamSpecifierChars characterIsMember:specifier]) {
			if ([scanner scanCharactersFromSet:digitCharSet intoString:&string]) {
				AppendStringToFormatStrings(string, paramAttr);
			}
		}
	}
	
	if (errorMsg == nil) {
		// change formatString
		*formatString = [[sanitizedFormatString copy] autorelease];
	} else {
		// there were errors. Don't change formatString, but append the rest to the attributed format
		if (attrString != nil && location < [*formatString length]) {
			string = [*formatString substringFromIndex:location];
			AppendStringToFormatStrings(string, errorAttr);
		}
		if (error != NULL)
			*error = errorMsg;
	}
	if (attrString != nil) 
		*attrFormatString = [attrString autorelease];
	
	[sanitizedFormatString release];
	
	return (errorMsg == nil);
}

+ (NSArray *)requiredFieldsForFormat:(NSString *)formatString
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
			case 'p':
			case 'P':
				[arr addObject:BDSKAuthorEditorString];
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
			case 'b':
				[arr addObject:@"Document Filename"];
				break;
            case 'k':
                [arr addObject:BDSKKeywordsString];
                break;
			case 'f':
			case 'c':
			case 's':
				[arr addObject:[[[string componentsSeparatedByString:@"}"] objectAtIndex:0] substringFromIndex:2]];
                break;
			case 'i':
				[arr addObject:[NSString stringWithFormat:@"Document: ", [[[string componentsSeparatedByString:@"}"] objectAtIndex:0] substringFromIndex:2]]];
				break;
		}
	}
	return arr;
}

@end

#pragma mark -

@implementation BDSKFormatStringFieldEditor

- (id)initWithFrame:(NSRect)frameRect parseField:(NSString *)field fileType:(NSString *)fileType;
{
    // initWithFrame sets up the entire text system for us
    if(self = [super initWithFrame:frameRect]){
        OBASSERT(field != nil);
        parseField = [field copy];
        
        OBASSERT(fileType != nil);
        parseFileType = [fileType copy];
    }
    return self;
}

- (void)dealloc
{
    [parseFileType release];
    [parseField release];
    [super dealloc];
}

- (BOOL)isFieldEditor { return YES; }

- (void)recolorText
{
    NSTextStorage *textStorage = [self textStorage];
    unsigned length = [textStorage length];
    
    NSRange range;
    NSDictionary *attributes;
    
    range.length = 0;
    range.location = 0;
	
    // get the attributed string from the format parser
    NSAttributedString *attrString = nil;
    NSString *format = [[[self string] copy] autorelease]; // pass a copy so we don't change the backing store of our text storage
    [BDSKFormatParser validateFormat:&format attributedFormat:&attrString forField:parseField inFileType:parseFileType error:NULL];   
    
	if ([[self string] isEqualToString:[attrString string]] == NO) 
		return;
    
    // get the attributes of the parsed string and apply them to our NSTextStorage; it may not be safe to set it directly at this point
    unsigned start = 0;
    while(start < length){
        
        attributes = [attrString attributesAtIndex:start effectiveRange:&range];        
        [textStorage setAttributes:attributes range:range];
        
        start += range.length;
    }
}    

// this is a convenient override point that gets called often enough to recolor everything
- (void)setSelectedRange:(NSRange)charRange
{
    [super setSelectedRange:charRange];
    [self recolorText];
}

- (void)didChangeText
{
    [super didChangeText];
    [self recolorText];
}

@end

@implementation BDSKFormatStringFormatter

- (id)initWithField:(NSString *)field fileType:(NSString *)fileType; {
    // initWithFrame sets up the entire text system for us
    if(self = [super init]){
        OBASSERT(field != nil);
        parseField = [field copy];
        
        OBASSERT(fileType != nil);
        parseFileType = [fileType copy];
    }
    return self;
}

- (void)dealloc
{
    [parseFileType release];
    [parseField release];
    [super dealloc];
}

- (NSString *)stringForObjectValue:(id)obj{
    return obj;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs{
    NSAttributedString *attrString = nil;
    NSString *format = [[obj copy] autorelease];
    
	[BDSKFormatParser validateFormat:&format attributedFormat:&attrString forField:parseField inFileType:parseFileType error:NULL];
    
    return attrString;
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error{
    NSAttributedString *attrString = nil;
    NSString *format = [[*partialStringPtr copy] autorelease];
    
	[BDSKFormatParser validateFormat:&format attributedFormat:&attrString forField:parseField inFileType:parseFileType error:NULL];
    format = [attrString string];
	
	if (![format isEqualToString:*partialStringPtr]) {
		unsigned length = [format length];
		*partialStringPtr = format;
		if ([format isEqualToString:origString]) 
			*proposedSelRangePtr = origSelRange;
		else if (NSMaxRange(*proposedSelRangePtr) > length){
			if ((*proposedSelRangePtr).location <= length)
				*proposedSelRangePtr = NSIntersectionRange(*proposedSelRangePtr, NSMakeRange(0, length));
			else
				*proposedSelRangePtr = NSMakeRange(length, 0);
		}
		return NO;
	} else return YES;
}


@end

