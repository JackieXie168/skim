//
//  BDSKRISParser.m
//  BibDesk
//
//  Created by Michael McCracken on Sun Nov 16 2003.
/*
 This software is Copyright (c) 2003,2004,2005,2006,2007
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

#import "BDSKRISParser.h"
#import "BibTypeManager.h"
#import "BibItem.h"
#import "BibAppController.h"
#import <AGRegex/AGRegex.h>
#import "NSString_BDSKExtensions.h"


@interface BDSKRISParser (Private)

/*!
@function   isDuplicateAuthor
 @abstract   Check to see if we have a duplicate author in the list
 @discussion Some online databases (Scopus in particular) give us RIS with multiple instances of the same author.
 BibTeX accepts this, and happily prints out duplicate author names.  This isn't a very robust check.
 @param      oldList Existing author list in the dictionary
 @param      newAuthor The author that we want to add
 @result     Returns YES if it's a duplicate
 */
static BOOL isDuplicateAuthor(NSString *oldList, NSString *newAuthor);

@end


@implementation BDSKRISParser

+ (BOOL)canParseString:(NSString *)string{
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    BOOL isRIS = NO;
    
    // skip leading whitespace
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
    
    if([scanner scanString:@"TY" intoString:nil] &&
       [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil] &&
       [scanner scanString:@"-" intoString:nil]) // for RIS
        isRIS = YES;
    [scanner release];
    return isRIS;
}

+ (NSArray *)itemsFromString:(NSString *)itemString error:(NSError **)outError{
    
    // make sure that we only have one type of space and line break to deal with, since HTML copy/paste can have odd whitespace characters
    itemString = [itemString stringByNormalizingSpacesAndLineBreaks];
    
    itemString = [self stringByFixingInputString:itemString];
        
    BibItem *newBI = nil;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:10];
    
    //dictionary is the publication entry
    NSMutableDictionary *pubDict = [[NSMutableDictionary alloc] init];
    
    NSArray *sourceLines = [itemString sourceLinesBySplittingString];
    
    NSEnumerator *sourceLineE = [sourceLines objectEnumerator];
    NSString *sourceLine = nil;
    
    NSString *tag = nil;
    NSString *value = nil;
    NSMutableString *mutableValue = [NSMutableString string];
    BibTypeManager *typeManager = [BibTypeManager sharedManager];
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    NSSet *tagsNotToConvert = [NSSet setWithObjects:@"UR", @"L1", @"L2", @"L3", @"L4", nil];
    
    // This is used for stripping extraneous characters from BibTeX year fields
    AGRegex *findYearString = [AGRegex regexWithPattern:@"(.*)(\\d{4})(.*)"];
    
    while(sourceLine = [sourceLineE nextObject]){

        if(([sourceLine length] > 5 && [[sourceLine substringWithRange:NSMakeRange(4,2)] isEqualToString:@"- "]) ||
           [sourceLine isEqualToString:@"ER  -"]){
			// this is a "key - value" line
			
			// first save the last key/value pair if necessary
			if(tag && ![tag isEqualToString:@"ER"]){
				[self addString:mutableValue toDictionary:pubDict forTag:tag];
			}
			
			// get the tag...
            tag = [[sourceLine substringWithRange:NSMakeRange(0,4)] 
						stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
			
			if([tag isEqualToString:@"ER"]){
				// we are done with this publication
				
				if([[pubDict allKeys] count] > 0){
                    [self fixPublicationDictionary:pubDict];
                    newBI = [[BibItem alloc] initWithType:[self pubTypeFromDictionary:pubDict]
                                                 fileType:BDSKBibtexString
                                                  citeKey:nil
                                                pubFields:pubDict
                                                    isNew:YES];
					[returnArray addObject:newBI];
					[newBI release];
				}
				
				// reset these for the next pub
				[pubDict removeAllObjects];
				
				// we don't care about the rest, ER has no value
				continue;
			}
			
			// get the value...
			value = [[sourceLine substringWithRange:NSMakeRange(6,[sourceLine length]-6)]
						stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
			
			// don't convert specials in URL/link fields, bug #1244625
			if(![tagsNotToConvert containsObject:tag])
				value = [value stringByConvertingHTMLToTeX];
		
			// Scopus returns a PY with //// after it.  Others may return a full date, where BibTeX wants a year.  
			// Use a regex to find a substring with four consecutive digits and use that instead.  Not sure how robust this is.
			if([[typeManager fieldNameForPubMedTag:tag] isEqualToString:BDSKYearString])
				value = [findYearString replaceWithString:@"$2" inString:value];
			
			[mutableValue setString:value];                
			
		} else {
			// this is a continuation of a multiline value
			[mutableValue appendString:@" "];
			[mutableValue appendString:[sourceLine stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet]];
        }
        
    }
    
    if(outError) *outError = nil;
    
    [pubDict release];
    return returnArray;
}

+ (void)addString:(NSMutableString *)value toDictionary:(NSMutableDictionary *)pubDict forTag:(NSString *)tag;
{
	NSString *key = nil;
	NSString *oldString = nil;
    NSString *newString = nil;
	
	// we handle fieldnames for authors later, as FAU can duplicate AU. All others are treated as AU. 
	if([tag isEqualToString:@"A1"] || [tag isEqualToString:@"A2"] || [tag isEqualToString:@"A3"])
		tag = @"AU";
    // most RIS uses IS for issue number
    if([tag isEqualToString:@"IS"])
        key = BDSKNumberString;
	else
        key = [[BibTypeManager sharedManager] fieldNameForPubMedTag:tag];
	if(key == nil) key = [tag fieldName];
	oldString = [pubDict objectForKey:key];
	
	BOOL isAuthor = [key isPersonField];
    
    // sometimes we have authors as "Feelgood, D.R.", but BibTeX and btparse need "Feelgood, D. R." for parsing
    // this leads to some unnecessary trailing space, though, in some cases (e.g. "Feelgood, D. R. ") so we can
    // either ignore it, be clever and not add it after the last ".", or add it everywhere and collapse it later
    if(isAuthor){
		[value replaceOccurrencesOfString:@"." withString:@". " 
			options:NSLiteralSearch range:NSMakeRange(0, [value length])];
    }
	// concatenate authors and keywords, as they can appear multiple times
	// other duplicates keys should have at least different tags, so we use the tag instead
	if(![NSString isEmptyString:oldString]){
		if(isAuthor){
			if(isDuplicateAuthor(oldString, value)){
				NSLog(@"Not adding duplicate author %@", value);
			}else{
				newString = [[NSString alloc] initWithFormat:@"%@ and %@", oldString, value];
                // This next step isn't strictly necessary for splitting the names, since the name parsing will do it for us, but you still see duplicate whitespace when editing the author field
                NSString *collapsedWhitespaceString = (NSString *)BDStringCreateByCollapsingAndTrimmingWhitespace(NULL, (CFStringRef)newString);
                [newString release];
                newString = collapsedWhitespaceString;
			}
        }else if([key isEqualToString:BDSKKeywordsString]){
            newString = [[NSString alloc] initWithFormat:@"%@, %@", oldString, value];
		}else{
			// we already had a tag mapping to the same fieldname, so use the tag instead
			key = [tag fieldName];
            oldString = [pubDict objectForKey:key];
            if (![NSString isEmptyString:oldString]){
                newString = [[NSString alloc] initWithFormat:@"%@, %@", oldString, value];
            }else{
                newString = [value copy];
            }
		}
    }else{
        // the default, just set the value
        newString = [value copy];
    }
    if(newString != nil){
        [pubDict setObject:newString forKey:key];
        [newString release];
    }
}

+ (NSString *)pubTypeFromDictionary:(NSDictionary *)pubDict;
{
    BibTypeManager *typeManager = [BibTypeManager sharedManager];
    NSString *type = BDSKArticleString;
    if([typeManager bibtexTypeForPubMedType:[pubDict objectForKey:@"Ty"]] != nil)
        type = [typeManager bibtexTypeForPubMedType:[pubDict objectForKey:@"Ty"]];
    return type;
}

static NSString *RISStartPageString = @"Sp";
static NSString *RISEndPageString = @"Ep";

+ (void)fixPublicationDictionary:(NSMutableDictionary *)pubDict;
{
    // fix up the page numbers if necessary
    NSString *start = [pubDict objectForKey:RISStartPageString];
    NSString *end = [pubDict objectForKey:RISEndPageString];
    
    if(start != nil && end != nil){
       NSMutableString *merge = [start mutableCopy];
       [merge appendString:@"--"];
       [merge appendString:end];
       [pubDict setObject:merge forKey:BDSKPagesString];
       [merge release];
       
       [pubDict removeObjectForKey:RISStartPageString];
       [pubDict removeObjectForKey:RISEndPageString];
	}
}

+ (NSString *)stringByFixingInputString:(NSString *)inputString;
{
    // Scopus doesn't put the end tag ER on a separate line.
    AGRegex *endTag = [AGRegex regexWithPattern:@"([^\r\n])ER  - $" options:AGRegexMultiline];
    return [endTag replaceWithString:@"$1\r\nER  - " inString:inputString];
}

@end

@implementation BDSKRISParser (Private)

static BOOL isDuplicateAuthor(NSString *oldList, NSString *newAuthor){ // check to see if it's a duplicate; this relies on the whitespace around the " and ", and is basically a hack for Scopus
    NSArray *oldAuthArray = [oldList componentsSeparatedByString:@" and "];
    return [oldAuthArray containsObject:newAuthor];
}

@end
