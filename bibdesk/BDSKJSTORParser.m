//
//  BDSKJSTORParser.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 18/1/06.
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

#import "BDSKJSTORParser.h"
#import "NSString_BDSKExtensions.h"
#import "BibTypeManager.h"
#import "BibItem.h"
#import "BibAppController.h"
#import <OmniBase/assertions.h>

//
// Tag reference:
// http://www.jstor.org/help/tags.html
//

static void splitDateString(NSMutableDictionary *pubDict)
{
    // the date seems always to be of the form Month, Year
    NSString *dateString = [pubDict objectForKey:@"Date"];
    if(dateString != nil){
        NSArray *components = [dateString componentsSeparatedByString:@", "];
        
		if([components count] == 1){
			[pubDict setObject:[components objectAtIndex:0] forKey:BDSKYearString];
		}else{
			[pubDict setObject:[components objectAtIndex:0] forKey:BDSKMonthString];
			[pubDict setObject:[components objectAtIndex:1] forKey:BDSKYearString];
		}
        
        [pubDict removeObjectForKey:@"Date"];
    }

}

@implementation BDSKJSTORParser

+ (BOOL)canParseString:(NSString *)string{
	return [string hasPrefix:@"JSTOR CITATION LIST"];
}

+ (NSArray *)itemsFromString:(NSString *)itemString error:(NSError **)outError{
    
    // make sure that we only have one type of space and line break to deal with, since HTML copy/paste can have odd whitespace characters
    itemString = [itemString stringByNormalizingSpacesAndLineBreaks];
    
	BOOL resolvedFormat = NO;
	BOOL isTabDelimited = NO;
	
    BibItem *newBI = nil;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:10];
	NSArray *keyArray = nil;
    NSError *error = nil;
    
	NSRange startRange = [itemString rangeOfString:@"--------------------------------------------------------------------------------\n" options:NSLiteralSearch];
	if (startRange.location == NSNotFound){
        OFErrorWithInfo(&error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"JSTOR delimiter not found", @"Error description"), nil);
        if(outError) *outError = error;
		return returnArray;
    }
	
	int startLoc = NSMaxRange(startRange);
	NSRange endRange = [itemString rangeOfString:@"--------------------------------------------------------------------------------\n" options:NSLiteralSearch range:NSMakeRange(startLoc, [itemString length] - startLoc)];
	if (endRange.location == NSNotFound)
		endRange = NSMakeRange([itemString length], 0);
	
	itemString = [itemString substringWithRange:NSMakeRange(startLoc, endRange.location - startLoc)];
	
    NSArray *sourceLines = [itemString sourceLinesBySplittingString];
    
    NSEnumerator *sourceLineE = [sourceLines objectEnumerator];
    NSString *sourceLine = nil;
    
    //dictionary is the publication entry
    NSMutableDictionary *pubDict = [[NSMutableDictionary alloc] init];
        
    NSString *tag = nil;
    NSString *key = nil;
    NSString *value = nil;
    BibTypeManager *typeManager = [BibTypeManager sharedManager];
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    NSSet *fieldsNotToConvert = nil;
    NSSet *authorTags = nil;
    
    while(sourceLine = [sourceLineE nextObject]){

        // ignore empty lines
		if([sourceLine length] == 0)
			continue;
		
		if(resolvedFormat == NO){
			// first non-empty item line, see what format we have
			if([sourceLine hasPrefix:@"<"]){
				isTabDelimited = NO;
				fieldsNotToConvert = [NSSet setWithObjects:@"EI", nil];
				authorTags = [NSSet setWithObjects:@"AU", @"RA", nil];
			}else{
				isTabDelimited = YES;
				keyArray = [sourceLine componentsSeparatedByString:@"\t"];
				authorTags = [NSSet setWithObjects:@"Author", @"Reviewed Author", nil];
				fieldsNotToConvert = [NSSet setWithObjects:@"Electronic Identifier", nil];
			}
			resolvedFormat = YES;
			continue;
		}
		
		if(isTabDelimited){
			
			NSArray *valueArray = [sourceLine componentsSeparatedByString:@"\t"];
			
			OBPRECONDITION([valueArray count] == [keyArray count]);
			
			int count = [keyArray count];
			int i;
			
			if(count == 0)
				continue;
			
			for(i = 0; i < count; i++){
				tag = [keyArray objectAtIndex:i];
				key = [typeManager fieldNameForJSTORDescription:tag];
				value = [[valueArray objectAtIndex:i] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
				if(![fieldsNotToConvert containsObject:tag])
					value = [value stringByConvertingHTMLToTeX];
				
				if([authorTags containsObject:tag])
					value = [value stringByReplacingAllOccurrencesOfString:@";" withString:@" and "];
				
				[pubDict setObject:value forKey:key];
			}
			
			// fix the date
			splitDateString(pubDict);
			
			newBI = [[BibItem alloc] initWithType:BDSKArticleString
										 fileType:BDSKBibtexString
										  citeKey:nil
										pubFields:pubDict
                                            isNew:YES];
			[returnArray addObject:newBI];
			[newBI release];
			
			// reset these for the next pub
			[pubDict removeAllObjects];
			
		}else{
			
			if([sourceLine hasPrefix:@"<"]){
				// start of a new item, first safe the last one
				
				if([pubDict count] > 0){
					// fix the date
					splitDateString(pubDict);
					
					newBI = [[BibItem alloc] initWithType:BDSKArticleString
												 fileType:BDSKBibtexString
												  citeKey:nil
												pubFields:pubDict
                                                    isNew:YES];
					[returnArray addObject:newBI];
					[newBI release];
				}
				
				// reset these for the next pub
				[pubDict removeAllObjects];
				
				// we don't care about the rest, this is a simple counter that has no meaning for us
				continue;
			
			}
			
			if([[sourceLine substringWithRange:NSMakeRange(2,3)] isEqualToString:@" : "] == NO){
				// this is not a tag line, something went wrong. Should we report a problem?
				continue;
			}
		
			// get the tag...
			tag = [sourceLine substringWithRange:NSMakeRange(0,2)];
			
			// find the BibTeX key
			key = [typeManager fieldNameForJSTORTag:tag];
			if(key == nil) key = tag;
			
			// get the value...
			value = [[sourceLine substringWithRange:NSMakeRange(5,[sourceLine length]-5)]
						stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
			
			// don't convert specials in URL/link fields, bug #1244625
			if(![fieldsNotToConvert containsObject:tag])
				value = [value stringByConvertingHTMLToTeX];
			
			if([authorTags containsObject:tag])
				value = [value stringByReplacingAllOccurrencesOfString:@";" withString:@" and "];
			
			[pubDict setObject:value forKey:key];
			
		}
		
    }
	
	// add the last item
	if([pubDict count] > 0){
		
		// fix the date
		splitDateString(pubDict);
		
		newBI = [[BibItem alloc] initWithType:BDSKArticleString
									 fileType:BDSKBibtexString
									  citeKey:nil
									pubFields:pubDict
                                        isNew:YES];
		[returnArray addObject:newBI];
		[newBI release];
	}
    
    if(outError) *outError = error;
    
    [pubDict release];
    return returnArray;
}

@end
