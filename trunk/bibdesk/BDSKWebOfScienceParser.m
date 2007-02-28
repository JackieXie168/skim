//
//  BDSKWebOfScienceParser.m
//  Bibdesk
//
//  Created by Adam Maxwell on 01/20/06.
/*
 This software is Copyright (c) 2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "BDSKWebOfScienceParser.h"
#import "BibItem.h"
#import "NSString_BDSKExtensions.h"
#import "BibTypeManager.h"

static void mergePageNumbers(NSMutableDictionary *dict)
{
    NSArray *keys = [dict allKeys];
    NSString *merge;
    
    // need translated key names
    static NSString *bpName = nil;
    static NSString *epName = nil;
    if(bpName == nil){
        bpName = [[[BibTypeManager sharedManager] fieldNameForWebOfScienceTag:@"BP"] copy];
        epName = [[[BibTypeManager sharedManager] fieldNameForWebOfScienceTag:@"EP"] copy];
    }
    
    if([keys containsObject:bpName] && [keys containsObject:epName]){
        merge = [[[dict objectForKey:bpName] stringByAppendingString:@"--"] stringByAppendingString:[dict objectForKey:epName]];
        [dict setObject:merge forKey:BDSKPagesString];
        [dict removeObjectForKey:bpName];
        [dict removeObjectForKey:epName];
    }
}

/* sample from WoS
 Petersen, JK
 Karlsson, O
 Loo, LO
 Nilsson, SF
 */

static NSString *fixedAuthorName(NSString *name)
{
    NSCParameterAssert(name);
    
    NSRange range = [name rangeOfString:@", "];
    if(range.length == 0)
        return name;
    
    NSString *lastName = [name substringToIndex:NSMaxRange(range)];
    NSString *firstNames = [name substringFromIndex:NSMaxRange(range)];
    
    // if there are lower case letters, don't mess with it
    if([firstNames rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]].length)
        return name;
    
    NSMutableString *newName = [[lastName mutableCopy] autorelease];    
    
    unsigned idx, maxIdx = [firstNames length];
    for(idx = 0; idx < maxIdx; idx++){
        [newName appendCharacter:[firstNames characterAtIndex:idx]];
        [newName appendString:(idx == maxIdx - 1 ? @"." : @". ")];
    }
    
    return newName;
}

static inline BOOL 
isTagLine(NSString *sourceLine)
{
    NSCParameterAssert(sourceLine && [sourceLine length] >= 2);
    
    static NSCharacterSet *uppercaseASCIICharacterSet = nil;
    if(uppercaseASCIICharacterSet == nil)
        uppercaseASCIICharacterSet = [[NSCharacterSet characterSetWithRange:NSMakeRange('A', 26)] retain];        

    unichar ch1 = [sourceLine characterAtIndex:0];
    unichar ch2 = [sourceLine characterAtIndex:1];
    return ([uppercaseASCIICharacterSet characterIsMember:ch1] && ([uppercaseASCIICharacterSet characterIsMember:ch2] || [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:ch2]));
}

static void fixDateBySplittingString(NSMutableDictionary *pubDict)
{
    static NSMutableCharacterSet *removeSet = nil;
    if(removeSet == nil){
        removeSet = [[NSCharacterSet decimalDigitCharacterSet] mutableCopy];
        [removeSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    }
        
    // sometimes the date is just the month, sometimes it's Month + numeric day
    NSString *dateString = [pubDict objectForKey:@"Date"];
    if(dateString != nil){
        NSMutableString *mutableDateStr = [dateString mutableCopy];
        [mutableDateStr deleteCharactersInCharacterSet:removeSet];
        
        // use CF so we can transform it in place
        CFLocaleRef locale = CFLocaleCopyCurrent();
        CFStringCapitalize((CFMutableStringRef)mutableDateStr, locale);
        CFRelease(locale);
        
        [pubDict setObject:mutableDateStr forKey:BDSKMonthString];
        [mutableDateStr release];
    }
}

//
// For format, see http://portal.isiknowledge.com/ISI/help/h_markwosa.htm
//
// Very few of the types seem to match up with BibTeX types
//

@implementation BDSKWebOfScienceParser

+ (BOOL)canParseString:(NSString *)string{
    // remove leading newlines in case this originates from copy/paste
    return [[string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] hasPrefix:@"FN ISI Export Format"];
}

+ (NSArray *)itemsFromString:(NSString *)itemString error:(NSError **)outError{
    // make sure that we only have one type of space and line break to deal with, since HTML copy/paste can have odd whitespace characters
    itemString = [itemString stringByNormalizingSpacesAndLineBreaks];
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:10];
    NSError *error = nil;
    
    // for now, we'll only support version 1.0
    NSRange startRange = [itemString rangeOfString:@"VR 1.0\n" options:NSLiteralSearch];
	if (startRange.location == NSNotFound){
        OFErrorWithInfo(&error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"This Web of Science version is not supported", @"Error description"), nil);
        if(outError) *outError = error;
		return returnArray;
    }
	
	int startLoc = NSMaxRange(startRange);
	NSRange endRange = [itemString rangeOfString:@"\nEF" options:NSLiteralSearch|NSBackwardsSearch range:NSMakeRange(startLoc, [itemString length] - startLoc)];
	if (endRange.location == NSNotFound)
		endRange = NSMakeRange([itemString length], 0);
	
	itemString = [itemString substringWithRange:NSMakeRange(startLoc, endRange.location - startLoc)];
    
    BibItem *newBI = nil;
    
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
    NSString *type = nil;
    
    while(sourceLine = [sourceLineE nextObject]){
        
        OBPRECONDITION([sourceLine hasPrefix:@"FN"] == NO && [sourceLine hasPrefix:@"VR"] == NO && [sourceLine hasPrefix:@"EF"] == NO);
        
        if([sourceLine length] >= 2 && isTagLine(sourceLine)){
 			
			// first save the last key/value pair if necessary
			if(tag && ![tag isEqualToString:@"ER"]){
                value = [mutableValue copy];
                [pubDict setObject:value forKey:[typeManager fieldNameForWebOfScienceTag:tag]];
                [value release];
			}
			
			// get the tag...
            tag = [[sourceLine substringWithRange:NSMakeRange(0, 2)] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
			
			if([tag isEqualToString:@"ER"]){
				// we are done with this publication
				
				if([pubDict count] > 0){
                    
                    // fix the page numbers
                    mergePageNumbers(pubDict);
                    
                    // fix the date
                    fixDateBySplittingString(pubDict);
                    
                    // types are a bit weird; DT is apparently optional, and it's not clear what the PT tags stand for
                    // however, bibutils treats PT J as an article, so we'll do the same
                    type = [pubDict objectForKey:@"Publication-Type"];
                    if([type isEqualToString:@"J"]){
                        type = BDSKArticleString;
                    } else {
                        type = [pubDict objectForKey:@"Document-Type"];
                        type = type ? [typeManager bibtexTypeForWebOfScienceType:type] : BDSKMiscString;
                    }
                    
                    newBI = [[BibItem alloc] initWithType:type fileType:BDSKBibtexString citeKey:nil pubFields:pubDict isNew:YES];
					[returnArray addObject:newBI];
					[newBI release];
				}
				
				// reset these for the next pub
				[pubDict removeAllObjects];
				
				// we don't care about the rest, ER has no value
				continue;
			}
			
			// get the value...
            if([sourceLine length] >= 4)
                value = [[sourceLine substringWithRange:NSMakeRange(3,[sourceLine length] - 3)] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
            else
                [NSException raise:NSInternalInconsistencyException format:@"Unexpected short line"];
			            
            if([tag isEqualToString:@"AU"])
                value = fixedAuthorName(value);
            
			[mutableValue setString:value];                
			
		} else {
        
            if([tag isEqualToString:@"AU"]){
                [mutableValue appendString:@" and "];
                [mutableValue appendString:fixedAuthorName([sourceLine stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet])];
            } else if([tag isEqualToString:@"CR"]){
                [mutableValue appendString:@";"];
                [mutableValue appendString:[sourceLine stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet]];
            } else {
                [mutableValue appendString:@" "];
                [mutableValue appendString:[sourceLine stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet]];
            }
        }
        
    }
    
    if(outError) *outError = error;
    
    [pubDict release];
    return returnArray;
}

@end
