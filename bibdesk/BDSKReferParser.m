//
//  BDSKReferParser.m
//  Bibdesk
//
//  Created by Adam Maxwell on 01/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BDSKReferParser.h"
#import "BibItem.h"
#import "NSString_BDSKExtensions.h"
#import "BibTypeManager.h"

/*
 For format, see http://www.ecst.csuchico.edu/~jacobsd/bib/formats/endnote.html and the man page for refer(1).  There's apparently an old-style refer format, and one that's bastardized for EndNote.  I'm adding this parser solely because this file format is returned by AGU's search at the moment, so supporting the version described by the man page for refer(1) isn't a high priority.

 %0 Journal Article 
 %A B. Chen
 %A Y. Song
 %A M. Nishio
 %A S. Someya
 %A M. Akai 
 %D 2005-09-27 
 %T Modeling near-field dispersion from direct injection of carbon dioxide into the ocean 
 %J J. Geophys. Res. 
 %V 110 
 %N C9 
 %P 1-13 
 %F 2004JC002567 
 %2 C09S15 
 %3 doi:10.1029/2004JC002567 
 %K 1616 Global Change: Climate variability
 %K 1635 Global Change: Oceans
 %K 4255 Oceanography: General: Numerical modeling
 %K 4524 Oceanography: Physical: Fine structure and microstructure
 %K 4568 Oceanography: Physical: Turbulence, diffusion, and mixing processes 
 %X In this paper we have predicted the dynamics of double plume formation and dispersion from direct injection of liquid CO 2 into middle-depth ocean water. To do so, we used a three-dimensional, two-fluid numerical model. The model consists of a CO 2 droplet submodel and a small-scale turbulent ocean submodel, both of which were calibrated against field observation data. With an injection rate of 100 kg s −1 CO 2, numerical simulations indicated that the injection of 8-mm-diameter CO 2 droplets from fixed ports at 858 m (20 m above the seafloor) into a current flowing at 2.5 cm s −1 could create a plume that reaches the bottom and has at most a 2.6-unit decrease in pH. The strong interaction between the buoyant rise of the liquid CO 2 and the fall of the CO 2 -enriched water produced a vertically wavy plume tip at about 190 m above the seafloor. The maximum pH decrease, however, was kept to 1.7 units when the liquid CO 2 had an initial droplet diameter of 20 mm and it was injected at 1500 m from a towed pipe with a ship speed of 3.0 m s −1. After 70 min the double plume developed into a single-phase passive plume with a vertical scale of 450 m and a horizontal scale larger than 150 m. This development was attributable to the droplets' buoyant rise and dissolution, along with ocean turbulence, which together diluted the plume and reduced the decrease in pH to less than 0.5 units. 
 %U [URL-Abstract] http://www.agu.org/pubs/crossref/2005.../2004JC002567.shtml 
 %U [URL-Abstract] http://dx.doi.org/10.1029/2004JC002567
 
 */ 

@implementation BDSKReferParser

+ (BOOL)canParseString:(NSString *)string{
    // remove leading newlines in case this originates from copy/paste
    return [[string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] hasPrefix:@"%"];
}

+ (void)addString:(NSString *)value toDictionary:(NSMutableDictionary *)pubDict forTag:(NSString *)tag;
{
	NSString *key = nil;
	NSString *oldString = nil;
    NSString *newString = nil;
	
    // returns [tag fieldName] if nothing in the dictionary
    key = [[BibTypeManager sharedManager] fieldNameForReferTag:tag];	
    oldString = [pubDict objectForKey:key];
    
    // this is likely only useful for AGU
	if ([key isURLField] && [value hasPrefix:@"[URL-Abstract] "])
        value = [value stringByRemovingPrefix:@"[URL-Abstract] "];
    
	BOOL isAuthor = [key isPersonField];
    
	// concatenate authors and keywords, as they can appear multiple times
	// other duplicates keys should have at least different tags, so we use the tag instead
	if ([NSString isEmptyString:oldString] == NO) {
		if (isAuthor) {
            newString = [[NSString alloc] initWithFormat:@"%@ and %@", oldString, value];
            // This next step isn't strictly necessary for splitting the names, since the name parsing will do it for us, but you still see duplicate whitespace when editing the author field
            NSString *collapsedWhitespaceString = (NSString *)BDStringCreateByCollapsingAndTrimmingWhitespace(NULL, (CFStringRef)newString);
            [newString release];
            newString = collapsedWhitespaceString;
        } else if([key isSingleValuedField] || [key isURLField]) {
            // for single valued and URL fields, create a new field name
            int i = 1;
            NSString *newKey = [key stringByAppendingFormat:@"%d", i];
            while ([pubDict objectForKey:newKey] != nil) {
                i++;
                newKey = [key stringByAppendingFormat:@"%d", i];
            }
            key = newKey;
            newString = [value copy];
        } else {
			// append to old value, using separator from prefs
            newString = [[NSString alloc] initWithFormat:@"%@%@%@", oldString, [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKDefaultGroupFieldSeparatorKey], value];
		}
    } else {
        // the default, just set the value
        newString = [value copy];
    }
    if (newString != nil) {
        [pubDict setObject:newString forKey:key];
        [newString release];
    }
}

static void fixDateInDictionary(NSMutableDictionary *pubDict)
{
    NSString *dateString = [pubDict objectForKey:BDSKDateString];
    if (dateString) {
        NSScanner *scanner = [[NSScanner alloc] initWithString:dateString];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL];
        int year;
        if ([scanner scanInt:&year])
            [pubDict setObject:[NSString stringWithFormat:@"%d", year] forKey:BDSKYearString];
        [scanner release];
    }
}

static inline BOOL isTagLine(NSString *sourceLine)
{
    NSCParameterAssert(sourceLine && [sourceLine length] >= 3);
    
    static NSCharacterSet *tagSet = nil;
    if(tagSet == nil) {
        NSMutableCharacterSet *set = [[NSCharacterSet characterSetWithRange:NSMakeRange('A', 26)] mutableCopy];
        [set addCharactersInRange:NSMakeRange('a', 26)];
        [set addCharactersInString:@"0123456789"];
        tagSet = [set copy];
        [set release];
    }
    
    unichar chars[3];
    [sourceLine getCharacters:chars range:NSMakeRange(0, 3)];
    return (chars[0] == '%' && [tagSet characterIsMember:chars[1]] && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:chars[2]]);
}

+ (NSArray *)itemsFromString:(NSString *)itemString error:(NSError **)outError{
    
    // !!! need to keep our items separated by whitespace
    // make sure that we only have one type of space and line break to deal with, since HTML copy/paste can have odd whitespace characters
    itemString = [itemString stringByNormalizingSpacesAndLineBreaks];
    
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:10];
    NSError *error = nil;
    
    NSRange startRange = [itemString rangeOfString:@"%" options:NSLiteralSearch];
	if (startRange.location == NSNotFound){
        OFErrorWithInfo(&error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"This is not a Refer string", @"Error description"), nil);
        if(outError) *outError = error;
		return returnArray;
    }
	
    // this basically trims whitespace and newlines
	int startLoc = startRange.location;
	NSRange endRange = NSMakeRange([itemString length], 0);
	itemString = [itemString substringWithRange:NSMakeRange(startLoc, endRange.location - startLoc)];
    
    // make sure we terminate the loop correctly
    itemString = [itemString stringByAppendingString:@"\n\n"];
    
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
    
    // refer records are separated by empty lines
    NSCharacterSet *invertedWhitespaceAndNewlineSet = [whitespaceAndNewlineCharacterSet invertedSet];
    NSString *type = nil;
    
    while (sourceLine = [sourceLineE nextObject]) {
                
        if ([sourceLine length] >= 3 && isTagLine(sourceLine)) {
 			
			// first save the last key/value pair if necessary
			if (tag) {
                [self addString:mutableValue toDictionary:pubDict forTag:tag];
			}
			
			// get the tag...
            tag = [[sourceLine substringWithRange:NSMakeRange(1, 1)] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
			
			// get the value...
            if([sourceLine length] >= 4)
                value = [[sourceLine substringWithRange:NSMakeRange(3, [sourceLine length] - 3)] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
            else
                [NSException raise:NSInternalInconsistencyException format:@"Unexpected short line"];
            
			[mutableValue setString:value];                
			
		} else if ([sourceLine isEqualToString:@""] || [sourceLine containsCharacterInSet:invertedWhitespaceAndNewlineSet] == NO) {
            
            // add the last line, if available; different from other parsers, since we don't have a real end tag
            if (tag && mutableValue) {
                [self addString:mutableValue toDictionary:pubDict forTag:tag];
            }
            
            // we are done with this publication
				
            if ([pubDict count] > 0) {
                
                // numeric keys end up with "Refer" prepended in the type manager
                // !!! maybe we should move type conversion dictionaries into parsers?
                type = [pubDict objectForKey:@"Refer0"];
                if (nil != type) {
                    type = [typeManager bibtexTypeForReferType:type];
                    [pubDict removeObjectForKey:@"Refer0"];
                } else {
                    type = BDSKMiscString;
                }
                
                fixDateInDictionary(pubDict);
                
                newBI = [[BibItem alloc] initWithType:type fileType:BDSKBibtexString citeKey:nil pubFields:pubDict isNew:YES];
                [returnArray addObject:newBI];
                [newBI release];
            }
            
            // reset these for the next pub
            [pubDict removeAllObjects];
            tag = nil;
            [mutableValue setString:@""];
                        
        } else {
        
            [mutableValue appendString:@" "];
            [mutableValue appendString:[sourceLine stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet]];
        }
    }
    
    if(outError) *outError = error;
    
    [pubDict release];
    return returnArray;
}

@end
