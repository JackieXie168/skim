//
//  PubMedParser.m
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

#import "PubMedParser.h"
#import "BibTypeManager.h"
#import "BibItem.h"
#import "BibAppController.h"
#import <AGRegex/AGRegex.h>
#import "NSString_BDSKExtensions.h"


@implementation PubMedParser

+ (BOOL)canParseString:(NSString *)string{
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    BOOL isPubMed = NO;
    
    // skip leading whitespace
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
    
    if([scanner scanString:@"PMID-" intoString:nil] &&
       [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil]) // for Medline
        isPubMed = YES;
    [scanner release];
    return isPubMed;
}

+ (void)addString:(NSMutableString *)value toDictionary:(NSMutableDictionary *)pubDict forTag:(NSString *)tag;
{
	NSString *key = nil;
	NSString *oldString = nil;
    NSString *newString = nil;
	
	// we handle fieldnames for authors later, as FAU can duplicate AU. All others are treated as AU. 
	if([tag isEqualToString:@"A1"] || [tag isEqualToString:@"A2"] || [tag isEqualToString:@"A3"])
		tag = @"AU";
    // PubMed uses IP for issue number and IS for ISBN
    if([tag isEqualToString:@"IP"])
        key = BDSKNumberString;
    else if([tag isEqualToString:@"IS"])
        key = @"Issn";
	else
        key = [[BibTypeManager sharedManager] fieldNameForPubMedTag:tag];
    if(key == nil || [key isEqualToString:BDSKAuthorString]) key = [tag fieldName];
	oldString = [pubDict objectForKey:key];
	
	BOOL isAuthor = ([key isEqualToString:@"Fau"] ||
					 [key isEqualToString:@"Au"] ||
					 [key isEqualToString:BDSKEditorString]);
    
    // sometimes we have authors as "Feelgood, D.R.", but BibTeX and btparse need "Feelgood, D. R." for parsing
    // this leads to some unnecessary trailing space, though, in some cases (e.g. "Feelgood, D. R. ") so we can
    // either ignore it, be clever and not add it after the last ".", or add it everywhere and collapse it later
    if(isAuthor){
		[value replaceOccurrencesOfString:@"." withString:@". " 
			options:NSLiteralSearch range:NSMakeRange(0, [value length])];
        // see bug #1584054, PubMed now doesn't use a comma between the lastName and the firstName
        // this should be OK for valid RIS, as that should be in the format "last, first"
        int lastSpace = [value rangeOfString:@" " options:NSBackwardsSearch].location;
        if([value rangeOfString:@","].location == NSNotFound && lastSpace != NSNotFound)
            [value insertString:@"," atIndex:lastSpace];
    }
	// concatenate authors and keywords, as they can appear multiple times
	// other duplicates keys should have at least different tags, so we use the tag instead
	if(![NSString isEmptyString:oldString]){
		if(isAuthor){
            newString = [[NSString alloc] initWithFormat:@"%@ and %@", oldString, value];
            // This next step isn't strictly necessary for splitting the names, since the name parsing will do it for us, but you still see duplicate whitespace when editing the author field
            NSString *collapsedWhitespaceString = (NSString *)BDStringCreateByCollapsingAndTrimmingWhitespace(NULL, (CFStringRef)newString);
            [newString release];
            newString = collapsedWhitespaceString;
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
    if([typeManager bibtexTypeForPubMedType:[pubDict objectForKey:@"Pt"]] != nil)
        type = [typeManager bibtexTypeForPubMedType:[pubDict objectForKey:@"Pt"]];
    return type;
}

+ (void)fixPublicationDictionary:(NSMutableDictionary *)pubDict;
{
    // choose the authors from the FAU or AU tag as available
    NSString *authors;
    
    if(authors = [pubDict objectForKey:@"Fau"]){
        [pubDict setObject:authors forKey:BDSKAuthorString];
		[pubDict removeObjectForKey:@"Fau"];
		// should we remove the AU also?
    }else if(authors = [pubDict objectForKey:@"Au"]){
        [pubDict setObject:authors forKey:BDSKAuthorString];
		[pubDict removeObjectForKey:@"Au"];
	}
}

// Adds ER tags to a stream of PubMed records, so it's (more) valid RIS
+ (NSString *)stringByFixingInputString:(NSString *)inputString;
{
    OFStringScanner *scanner = [[OFStringScanner alloc] initWithString:inputString];
    NSMutableString *fixedString = [[NSMutableString alloc] initWithCapacity:[inputString length]];
    
    NSString *scannedString = [scanner readFullTokenUpToString:@"PMID- "];
    unsigned start;
    unichar prevChar;
    BOOL scannedPMID = NO;
    
    // this means we scanned some garbage before the PMID tag, or else this isn't a PubMed string...
    OBPRECONDITION([NSString isEmptyString:scannedString]);
    
    do {
        
        start = scannerScanLocation(scanner);
        
        // scan past the PMID tag
        scannedPMID = scannerReadString(scanner, @"PMID- ");
        OBPRECONDITION(scannedPMID);
        
        // scan to the next PMID tag
        scannedString = [scanner readFullTokenUpToString:@"PMID- "];
        [fixedString appendString:[inputString substringWithRange:NSMakeRange(start, scannerScanLocation(scanner) - start)]];
        
        // see if the previous character is a newline; if not, then some clod put a "PMID- " in the text
        if(scannerScanLocation(scanner)){
            prevChar = *(scanner->scanLocation - 1);
            if(BDIsNewlineCharacter(prevChar))
                [fixedString appendString:@"ER  - \r\n"];
            // if we're operating on a text selection, it may not have a trailing newline
            else if (scannerHasData(scanner) == NO)
                [fixedString appendString:@"\r\nER  - \r\n"];
        }
        
        OBASSERT(scannedString);
        
    } while(scannerHasData(scanner));
    
    OBPOSTCONDITION(!scannerHasData(scanner));
    
    [scanner release];
    OBPOSTCONDITION(![NSString isEmptyString:fixedString]);
    
#if OMNI_FORCE_ASSERTIONS
    // Here's our reference method, which caused swap death on large strings (AGRegex uses a lot of autoreleased NSData objects)
	NSString *tmpStr;
	
    AGRegex *regex = [AGRegex regexWithPattern:@"(?<!\\A)^PMID- " options:AGRegexMultiline];
    tmpStr = [regex replaceWithString:@"ER  - \r\nPMID- " inString:inputString];
	
    tmpStr = [tmpStr stringByAppendingString:@"ER  - \r\n"];
    OBPOSTCONDITION([tmpStr isEqualToString:fixedString]);
#endif
    
    return [fixedString autorelease];
}

@end
