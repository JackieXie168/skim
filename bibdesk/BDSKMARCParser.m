//
//  BDSKMARCParser.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 12/4/06.
/*
 This software is Copyright (c) 2006
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

#import "BDSKMARCParser.h"
#import "NSString_BDSKExtensions.h"
#import "BibTypeManager.h"
#import "BibItem.h"
#import "BibAppController.h"
#import <OmniFoundation/NSScanner-OFExtensions.h>
#import <OmniFoundation/NSString-OFExtensions.h>
#import <AGRegex/AGRegex.h>


@interface NSString (BDSKMARCParserExtensions)
- (BOOL)isMARCString;
- (BOOL)isFormattedMARCString;
- (BOOL)isMARCXMLString;
- (NSString *)stringByFixingFormattedMARCStart;
- (NSString *)stringByRemovingPunctuationCharactersAndBracketedText;
@end


@interface BDSKMARCParser (Private)
static void addStringToDictionary(NSString *value, NSMutableDictionary *dict, NSString *tag, NSString *subFieldIndicator);
static void addSubstringToDictionary(NSString *subValue, NSMutableDictionary *pubDict, NSString *tag, NSString *subTag);
@end

@interface BDSKMARCXMLParser : NSXMLParser {
    NSMutableArray *returnArray;
    NSMutableDictionary *pubDict;
    NSMutableString *currentValue;
    NSString *tag;
    NSString *subTag;
}
- (NSArray *)parsedItems;
@end

@implementation BDSKMARCParser

+ (BOOL)canParseString:(NSString *)string{
	return [string isMARCString] || [string isFormattedMARCString] || [string isMARCXMLString];
}

+ (NSArray *)itemsFromFormattedMARCString:(NSString *)itemString error:(NSError **)outError{
    // make sure that we only have one type of space and line break to deal with, since HTML copy/paste can have odd whitespace characters
    itemString = [itemString stringByNormalizingSpacesAndLineBreaks];
	
    itemString = [itemString stringByFixingFormattedMARCStart];
    
    AGRegex *regex = [AGRegex regexWithPattern:@"^([ \t]*)1[01]{2}[ \t]*[0-9]{0,1}[ \t]+[^ \t[:alnum:]]a" options:AGRegexMultiline];
    AGRegexMatch *match = [regex findInString:itemString];
    
    if(match == nil){
        if(outError)
            OFErrorWithInfo(outError, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Unknown MARC format.", @"Error description"), nil);
        return [NSArray array];
    }
    
    unsigned tagStartIndex = [match rangeAtIndex:1].length;
    unsigned fieldStartIndex = [match range].length - 2;
    NSString *subFieldIndicator = [[match group] substringWithRange:NSMakeRange(fieldStartIndex, 1)];
    
    BibItem *newBI = nil;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:10];
	
    NSArray *sourceLines = [itemString sourceLinesBySplittingString];
    
    NSEnumerator *sourceLineE = [sourceLines objectEnumerator];
    NSString *sourceLine = nil;
    
    //dictionary is the publication entry
    NSMutableDictionary *pubDict = [[NSMutableDictionary alloc] init];
    
    NSString *tag = nil;
    NSString *tmpTag = nil;
    NSString *value = nil;
    NSMutableString *mutableValue = [NSMutableString string];
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    while(sourceLine = [sourceLineE nextObject]){
        
        if([sourceLine length] < tagStartIndex + 3)
            continue;
        
        tmpTag = [sourceLine substringWithRange:NSMakeRange(tagStartIndex, 3)];
        
        if([tmpTag hasPrefix:@" "]){
            // continuation of a value
            
			value = [sourceLine stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
            [mutableValue appendString:@" "];
            [mutableValue appendString:value];
            
        }else if([tmpTag isEqualToString:@"LDR"]){
            // start of a new item, first safe the last one
            
            // add the last key/value pair
            if(tag && [mutableValue length])
                addStringToDictionary(mutableValue, pubDict, tag, subFieldIndicator);
            
            if([pubDict count] > 0){
                newBI = [[BibItem alloc] initWithType:BDSKBookString
                                             fileType:BDSKBibtexString
                                              citeKey:nil
                                            pubFields:pubDict
                                                isNew:YES];
                [returnArray addObject:newBI];
                [newBI release];
            }
            
            // reset these for the next pub
            [pubDict removeAllObjects];
            
            // we don't care about the rest of the leader
            continue;
            
        }else if([sourceLine length] > fieldStartIndex){
			// first save the last key/value pair if necessary
            
            if(tag && [mutableValue length])
                addStringToDictionary(mutableValue, pubDict, tag, subFieldIndicator);
            
            tag = tmpTag;
            value = [[sourceLine substringFromIndex:fieldStartIndex] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
            [mutableValue setString:value];
            
        }
        
    }
    
    // add the last key/value pair
    if(tag && [mutableValue length])
        addStringToDictionary(mutableValue, pubDict, tag, subFieldIndicator);
	
	// add the last item
	if([pubDict count] > 0){
		
		newBI = [[BibItem alloc] initWithType:BDSKBookString
									 fileType:BDSKBibtexString
									  citeKey:nil
									pubFields:pubDict
                                        isNew:YES];
		[returnArray addObject:newBI];
		[newBI release];
	}
    
    [pubDict release];
    return returnArray;
}

+ (NSArray *)itemsFromMARCString:(NSString *)itemString error:(NSError **)outError{
    // make sure that we only have one type of space and line break to deal with, since HTML copy/paste can have odd whitespace characters
    itemString = [itemString stringByNormalizingSpacesAndLineBreaks];
	
    BibItem *newBI = nil;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:10];
    
    unsigned recordTerminator = 0x1D, fieldTerminator = 0x1E, subFieldChar = 0x1F;
    NSString *subFieldIndicator = [NSString stringWithFormat:@"%C", subFieldChar];
    
#pragma unused (fieldTerminator)
	
    NSArray *records = [itemString componentsSeparatedByString:[NSString stringWithFormat:@"%C", recordTerminator]];
    
    NSEnumerator *recordEnum = [records objectEnumerator];
    NSString *record = nil;
    
    //dictionary is the publication entry
    NSMutableDictionary *pubDict = [[NSMutableDictionary alloc] init];
    
    NSString *tag = nil, *value = nil, *dir = nil;
    unsigned base, fieldStart, fieldLength, i, dirLength;
    
    while(record = [recordEnum nextObject]){
        
        if([record length] < 25)
            continue;
        
        base = [[record substringWithRange:NSMakeRange(12, 5)] intValue];
        dir = [record substringWithRange:NSMakeRange(24, base - 1)];
        dirLength = [dir length];
        
        for(i = 0; i < dirLength; i += 12){
            
            tag = [dir substringWithRange:NSMakeRange(i, 3)];
            fieldLength = [[dir substringWithRange:NSMakeRange(i + 3, 4)] intValue];
            fieldStart = base + [[dir substringWithRange:NSMakeRange(i + 7, 5)] intValue];
            
            if(fieldLength < 4)
                continue;
            if([record length] <= fieldStart + fieldLength)
                break;
            
            OBASSERT([record characterAtIndex:fieldStart + fieldLength - 1] == fieldTerminator);
            
            // the first 2 characters are indicators, which we ignore, the last character is a field terminator
            value = [record substringWithRange:NSMakeRange(fieldStart + 2, fieldLength - 3)];
            
            addStringToDictionary(value, pubDict, tag, subFieldIndicator);
        }
        
        if([pubDict count] > 0){
            newBI = [[BibItem alloc] initWithType:BDSKBookString
                                         fileType:BDSKBibtexString
                                          citeKey:nil
                                        pubFields:pubDict
                                            isNew:YES];
            [returnArray addObject:newBI];
            [newBI release];
        }
        
    }
    
    [pubDict release];
    return returnArray;
}

+ (NSArray *)itemsFromMARCXMLString:(NSString *)itemString error:(NSError **)outError{
    BDSKMARCXMLParser *xmlParser = [[BDSKMARCXMLParser alloc] initWithXMLString:itemString];
    BOOL success = [xmlParser parse];
    NSArray *returnArray = nil;
    
    if(success){
        returnArray = [xmlParser parsedItems];
    }else{
        returnArray = [NSArray array];
        if(outError) *outError = [xmlParser parserError];
    }
    
    [xmlParser release];
    
    return returnArray;
}

+ (NSArray *)itemsFromString:(NSString *)itemString error:(NSError **)outError{
    if([itemString isMARCString]){
        return [self itemsFromMARCString:itemString error:outError];
    }else if([itemString isFormattedMARCString]){
        return [self itemsFromFormattedMARCString:itemString error:outError];
    }else if([itemString isMARCXMLString]){
        return [self itemsFromMARCXMLString:itemString error:outError];
    }else{
        if(outError)
            OFErrorWithInfo(outError, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Unknown MARC format.", @"Error description"), nil);
        return [NSArray array];
    }
}

@end


@implementation BDSKMARCParser (Private)

static void addStringToDictionary(NSString *value, NSMutableDictionary *pubDict, NSString *tag, NSString *subFieldIndicator){
	NSString *subTag = nil;
    NSString *subValue = nil;
	
    NSScanner *scanner = [[NSScanner alloc] initWithString:value];
    
    [scanner setCharactersToBeSkipped:nil];
    
    while([scanner isAtEnd] == NO){
        if(NO == [scanner scanString:subFieldIndicator intoString:NULL] || NO == [scanner scanStringOfLength:1 intoString:&subTag])
            break;
        
        if([scanner scanUpToString:subFieldIndicator intoString:&subValue]){
            subValue = [subValue stringByRemovingSurroundingWhitespace];
            addSubstringToDictionary(subValue, pubDict, tag, subTag);
        }
    }
    
    [scanner release];
}

static NSString *titleTag = @"245";
static NSString *subtitleSubTag = @"b";
static NSString *personTag = @"700";
static NSString *nameSubTag = @"a";
static NSString *relatorSubTag = @"e";

static void addSubstringToDictionary(NSString *subValue, NSMutableDictionary *pubDict, NSString *tag, NSString *subTag){
    NSString *key = [[[BibTypeManager sharedManager] fieldNamesForMARCTag:tag] objectForKey:subTag];
    NSString *tmpValue = nil;
    
    if(key == nil)
        return;
    
    subValue = [subValue stringByRemovingSurroundingWhitespace];
    
    if([tag isEqualToString:titleTag]){
        if([subTag isEqualToString:subtitleSubTag] && (tmpValue = [pubDict objectForKey:key])){
            // this is the subtitle, append it to the title if present
            
            subValue = [NSString stringWithFormat:@"%@: %@", tmpValue, subValue];
            [pubDict removeObjectForKey:key];
        }
    }else if([tag isEqualToString:personTag]){
        tmpValue = [pubDict objectForKey:BDSKAuthorString];
        if([subTag isEqualToString:nameSubTag] && tmpValue){
            subValue = [NSString stringWithFormat:@"%@ and %@", tmpValue, subValue];
        }else if([subTag isEqualToString:relatorSubTag]){
            // this is the person role, see if it is an editor
            if([subValue caseInsensitiveCompare:@"editor"] != NSOrderedSame || tmpValue == nil)
                return;
            NSRange range = [tmpValue rangeOfString:@" and " options:NSBackwardsSearch];
            if(range.location == NSNotFound){
                [pubDict removeObjectForKey:BDSKAuthorString];
                subValue = tmpValue;
            }else{
                [pubDict setObject:[tmpValue substringToIndex:range.location] forKey:BDSKAuthorString];
                subValue = [tmpValue substringFromIndex:NSMaxRange(range)];
            }
            if(tmpValue = [pubDict objectForKey:BDSKEditorString]){
                subValue = [NSString stringWithFormat:@"%@ and %@", tmpValue, subValue];
            }
        }
    }else if([key isEqualToString:BDSKAnnoteString] && (tmpValue = [pubDict objectForKey:key])){
        subValue = [NSString stringWithFormat:@"%@. %@", tmpValue, subValue];
    }else if([key isEqualToString:BDSKYearString]){
        // This is used for stripping extraneous characters from BibTeX year fields
        static AGRegex *findYearRegex = nil;
        if(findYearRegex == nil)
            findYearRegex = [[AGRegex alloc] initWithPattern:@"(.*)(\\d{4})(.*)"];
        subValue = [findYearRegex replaceWithString:@"$2" inString:subValue];
    }
    
    subValue = [[subValue stringByRemovingPunctuationCharactersAndBracketedText] copy];
    [pubDict setObject:subValue forKey:key];
    [subValue release];
}

@end


@implementation NSString (BDSKMARCParserExtensions)

- (BOOL)isMARCString{
    unsigned fieldTerminator = 0x1E, recordTerminator = 0x1D;
    NSString *pattern = [NSString stringWithFormat:@"^[0-9]{5}[a-z]{3}[ a]{2}22[0-9]{5}[ 1-8uz][ aiur]{2}4500([0-9]{12})+%C", fieldTerminator];
    AGRegex *regex = [AGRegex regexWithPattern:pattern];
    
    if([regex findInString:self] == NO)
        return NO;
    unsigned eor = [[self substringToIndex:5] intValue] - 1;
    return [self length] > eor && [self characterAtIndex:eor] == recordTerminator;
}

- (BOOL)isFormattedMARCString{
    AGRegex *regex = [AGRegex regexWithPattern:@"^[ \t]*LDR[ \t]+[ \\-0-9]{5}[a-z]{3}[ \\-a]{2}22[ \\-0-9]{5}[ \\-1-8uz][ \\-aiur]{2}4500\n{1,2}[ \t]*[0-9]{3}[ \t]+" options:AGRegexMultiline];
    
    return nil != [regex findInString:[self stringByNormalizingSpacesAndLineBreaks]];
}

- (BOOL)isMARCXMLString{
    AGRegex *regex = [AGRegex regexWithPattern:@"^ *<collection[^>]*>\n *<record>\n *<leader>[ \\-0-9]{5}[a-z]{3}[ a]{2}22[ \\-0-9]{5}[ 1-8uz][ aiur]{2}4500</leader>\n<controlfield tag=\"00[0-9]\">"];
    
    return nil != [regex findInString:[self stringByNormalizingSpacesAndLineBreaks]];
}

- (NSString *)stringByFixingFormattedMARCStart{
    AGRegex *regex = [AGRegex regexWithPattern:@"^[ \t]*LDR[ \t]+[0-9]{5}[a-z]{3}[ \\-a]{2}22[0-9]{5}[ \\-1-8uz][ \\-aiur]{2}4500\n{1,2}[ \t]*[0-9]{3}[ \t]+" options:AGRegexMultiline];
    unsigned start = [[regex findInString:self] range].location;
    return start == 0 ? self : [self substringFromIndex:start];
}

- (NSString *)stringByRemovingPunctuationCharactersAndBracketedText{
    static NSCharacterSet *punctuationCharacterSet = nil;
    if(punctuationCharacterSet == nil)
        punctuationCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@".,:;/"] retain];
    static NSCharacterSet *bracketCharacterSet = nil;
    if(bracketCharacterSet == nil)
        bracketCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"[]"] retain];
    
    NSString *string = self;
    unsigned length = [string length];
    NSRange range = [self rangeOfString:@"["];
    unsigned start = range.location;
    if(start != NSNotFound){
        range = [self rangeOfString:@"]" options:0 range:NSMakeRange(start, length - start)];
        if(range.location != NSNotFound){
            NSMutableString *mutString = [string mutableCopy];
            [mutString deleteCharactersInRange:NSMakeRange(start, NSMaxRange(range) - start)];
            [mutString removeSurroundingWhitespace];
            string = [mutString autorelease];
            length = [string length];
        }
    }
    
    if(length == 0)
        return string;
    NSString *cleanedString = [string stringByReplacingCharactersInSet:bracketCharacterSet withString:@""];
    length = [cleanedString length];
    if([punctuationCharacterSet characterIsMember:[cleanedString characterAtIndex:length - 1]])
        cleanedString = [cleanedString substringToIndex:length - 1];
    return cleanedString;
}

@end


@implementation BDSKMARCXMLParser  

- (id)initWithXMLString:(NSString *)aString{
    NSData *data = [aString dataUsingEncoding:NSUTF8StringEncoding];
    if(data == nil){
        [[super init] release];
        self = nil;
    }else if(self = [super initWithData:data]){
        returnArray = [[NSMutableArray alloc] initWithCapacity:10];
        pubDict = [[NSMutableDictionary alloc] init];
        currentValue = [[NSMutableString alloc] initWithCapacity:50];
        tag = nil;
        subTag = nil;
        
        [self setDelegate:self];
        
    }
    return self;
}

- (void)dealloc{
    [returnArray release];
    [pubDict release];
    [tag release];
    [subTag release];
    [currentValue release];
    [super dealloc];
}

- (NSArray *)parsedItems{
    return [[returnArray copy] autorelease];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict{
    if([elementName isEqualToString:@"record"] || [elementName isEqualToString:@"marc:record"]){
        [pubDict removeAllObjects];
    }else if([elementName isEqualToString:@"datafield"] || [elementName isEqualToString:@"marc:datafield"]){
        [tag release];
        tag = [[attributeDict objectForKey:@"tag"] retain];
    }else if([elementName isEqualToString:@"subfield"] || [elementName isEqualToString:@"marc:subfield"]){
        [subTag release];
        subTag = [[attributeDict objectForKey:@"code"] retain];
        [currentValue setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if([elementName isEqualToString:@"record"] || [elementName isEqualToString:@"marc:record"]){
        if([pubDict count] > 0){
            BibItem *newBI = [[BibItem alloc] initWithType:BDSKBookString
                                                  fileType:BDSKBibtexString
                                                   citeKey:nil
                                                 pubFields:pubDict
                                                     isNew:YES];
            [returnArray addObject:newBI];
            [newBI release];
        }
    }else if([elementName isEqualToString:@"subfield"] || [elementName isEqualToString:@"marc:subfield"]){
        if(tag && subTag && [currentValue length])
            addSubstringToDictionary(currentValue, pubDict, tag, subTag);
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    [currentValue appendString:string];
}

@end

