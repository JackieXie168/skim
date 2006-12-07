//
//  BDSKReferenceMinerParser.m
//  BibDesk
//
//  Created by Michael McCracken on Sun Nov 16 2003.
/*
 This software is Copyright (c) 2003,2004,2005,2006
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

#import "BDSKReferenceMinerParser.h"
#import <AGRegex/AGRegex.h>
#import "PubMedparser.h"
#import "BDSKRISParser.h"
#import "BDSKMARCParser.h"


@interface NSString (ReferenceMinerExtensions)
- (BOOL)isRefMinerPubMedString;
- (BOOL)isRefMinerLoCString;
- (BOOL)isRefMinerAmazonString;
- (NSString *)stringByFixingRefMinerPubMedTags;
- (NSString *)stringByFixingRefMinerLoCString;
- (NSString *)stringByFixingRefMinerAmazonString;
@end


@implementation BDSKReferenceMinerParser

+ (BOOL)canParseString:(NSString *)string{
    string = [string stringByNormalizingSpacesAndLineBreaks];
    return [string isRefMinerPubMedString] || [string isRefMinerLoCString] || [string isRefMinerAmazonString];
}

+ (NSArray *)itemsFromString:(NSString *)itemString error:(NSError **)outError{
    
    // get rid of any leading whitespace or newlines, so our range checks at the beginning are more reliable
    // don't trim trailing whitespace/newlines, since that breaks parsing PubMed (possibly the RIS end tag regex?)
    itemString = [itemString stringByTrimmingPrefixCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // make sure that we only have one type of space and line break to deal with, since HTML copy/paste can have odd whitespace characters
    itemString = [itemString stringByNormalizingSpacesAndLineBreaks];
    
    if([itemString isRefMinerPubMedString]){
        // the only problem here is the stuff that Ref Miner prepends to the PMID; other than that, it's just PubMed output
        itemString = [itemString stringByFixingRefMinerPubMedTags];
        return [PubMedParser itemsFromString:itemString error:outError];
    }else if([itemString isRefMinerAmazonString]){
        // run a crude hack for fixing the broken RIS that we get for Amazon entries from Reference Miner
        itemString = [itemString stringByFixingRefMinerAmazonString]; 
        return [BDSKRISParser itemsFromString:itemString error:outError];
    }else if([itemString isRefMinerLoCString]){
        // the only problem here is the stuff that Ref Miner prepends to the LDR; other than that, it's just MARC output
        itemString = [itemString stringByFixingRefMinerLoCString]; 
        return [BDSKMARCParser itemsFromString:itemString error:outError];
    }else{
        if(outError)
            OFErrorWithInfo(outError, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Unknown Reference Miner format.", @"Error description"), nil);
        return [NSArray array];
    }
}

@end


@implementation NSString (ReferenceMinerExtensions)

- (BOOL)isRefMinerPubMedString;
{
    AGRegex *pubmedRegex = [AGRegex regexWithPattern:@"^.+PMID- [0-9]+\n[A-Z]{3} - " options:AGRegexMultiline];
    return nil != [pubmedRegex findInString:self];
}

- (BOOL)isRefMinerLoCString;
{
    AGRegex *locRegex = [AGRegex regexWithPattern:@"^.+LDR [a-z0-9 ]{24})\n{0,2}[0-9]{3} " options:AGRegexMultiline];
    return nil != [locRegex findInString:self];
}

- (BOOL)isRefMinerAmazonString;
{
    AGRegex *amazonRegex = [AGRegex regexWithPattern:@"^Amazon,RM[0-9]{3}," options:AGRegexMultiline];
    return nil != [amazonRegex findInString:self];
}

- (NSString *)stringByFixingRefMinerPubMedTags;
{    
    // Reference Miner puts its own goo at the front of each entry, so we remove it.  From looking at
    // the input string in gdb, we're getting something like "PubMed,RM122,PMID- 15639629," as the first line.
    AGRegex *startTags = [AGRegex regexWithPattern:@"^(.+)(PMID- [0-9]+\n[A-Z]{3} - )" options:AGRegexMultiline];
    return [startTags replaceWithString:@"\2" inString:self];
}

- (NSString *)stringByFixingRefMinerLoCString;
{    
    // Reference Miner puts its own goo at the front of each entry, so we remove it.  From looking at
    // the input string in gdb, we're getting something like "Library of Congress,RM122,LDR 01080pam  2200325 a 4500" as the first line.
    AGRegex *startTags = [AGRegex regexWithPattern:@"^(.+)(LDR [a-z0-9 ]{24}\n{0,2}[0-9]{3} )" options:AGRegexMultiline];
    return [startTags replaceWithString:@"" inString:self];
}

- (NSString *)stringByFixingRefMinerAmazonString;
{
    //
    // For cleaning up reference miner output for Amazon references.  Use an NSLog to see
    // what it's giving us, then compare with <http://www.refman.com/support/risformat_intro.asp>.  We'll
    // fix it up enough to separate the references and save typing the author/title, but the date is just
    // too messed up to bother with.
    //
	NSString *tmpStr;
	
    // this is what Ref Miner uses to mark the beginning; should be TY key instead, so we'll fake it; this means the actual type doesn't get set
    AGRegex *start = [AGRegex regexWithPattern:@"^Amazon,RM[0-9]{3}," options:AGRegexMultiline];
    tmpStr = [start replaceWithString:@"" inString:self];
    
    start = [AGRegex regexWithPattern:@"^ITEM" options:AGRegexMultiline];
    tmpStr = [start replaceWithString:@"TY  - " inString:tmpStr];
    
    // special case for handling the url; others we just won't worry about
    AGRegex *url = [AGRegex regexWithPattern:@"^URL- " options:AGRegexMultiline];
    tmpStr = [url replaceWithString:@"UR  - " inString:tmpStr];
    
    AGRegex *tag2Regex = [AGRegex regexWithPattern:@"^([A-Z]{2})- " options:AGRegexMultiline];
    tmpStr = [tag2Regex replaceWithString:@"$1  - " inString:tmpStr];
    
    AGRegex *tag3Regex = [AGRegex regexWithPattern:@"^([A-Z]{3})- " options:AGRegexMultiline];
    tmpStr = [tag3Regex replaceWithString:@"$1 - " inString:tmpStr];
    
    AGRegex *ends = [AGRegex regexWithPattern:@"(?<!\\A)^TY  - " options:AGRegexMultiline];
    tmpStr = [ends replaceWithString:@"ER  - \r\nTY  - " inString:tmpStr];
	
    return [tmpStr stringByAppendingString:@"\r\nER  - "];	
}

@end
