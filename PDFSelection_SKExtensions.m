//
//  PDFSelection_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/24/07.
/*
 This software is Copyright (c) 2007-2009
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

#import "PDFSelection_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSParagraphStyle_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKPDFDocument.h"
#import "SKCFCallbacks.h"
#import "SKRuntime.h"

#define ELLIPSIS_CHARACTER 0x2026

@interface PDFSelection (PDFSelectionPrivateDeclarations)
- (NSArray *)pageRanges;
- (NSInteger)numberOfRangesOnPage:(PDFPage *)page;
- (NSRange)rangeAtIndex:(NSInteger)index onPage:(PDFPage *)page;
@end

@interface NSObject (PDFPageRangePrivateDeclarations)
- (PDFPage *)page;
- (NSRange)range;
@end


@implementation PDFSelection (SKExtensions)

static usePageRanges = NO;

+ (void)initialize {
    SKINITIALIZE;
    // NSAppKitVersionNumber10_5 = 949, apparently PDFSelection on 10.6 defines but doesn't implement -numberOfPagesOnRange: and -rangeAtIndex:onPage:
    usePageRanges = floor(NSAppKitVersionNumber) > 949 && [self instancesRespondToSelector:@selector(pageRages)] && [NSClassFromString(@"PDFPageRange") instancesRespondToSelector:@selector(page)] && [NSClassFromString(@"PDFPageRange") instancesRespondToSelector:@selector(range)];
}

// returns the label of the first page (if the selection spans multiple pages)
- (NSString *)firstPageLabel { 
    NSArray *pages = [self pages];
    return [pages count] ? [[pages objectAtIndex:0] displayLabel] : nil;
}

- (NSString *)cleanedString {
	return [[[self string] stringByRemovingAliens] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
}

- (NSAttributedString *)contextString {
    PDFSelection *extendedSelection = [self copy];
	NSMutableAttributedString *attributedSample;
	NSString *searchString = [self cleanedString];
	NSString *sample;
    NSMutableString *attributedString;
	NSString *ellipse = [NSString stringWithFormat:@"%C", ELLIPSIS_CHARACTER];
	NSRange foundRange;
    NSDictionary *attributes;
    NSNumber *fontSizeNumber = [[NSUserDefaults standardUserDefaults] objectForKey:SKTableFontSizeKey];
	CGFloat fontSize = fontSizeNumber ? [fontSizeNumber floatValue] : 0.0;
    
	// Extend selection.
	[extendedSelection extendSelectionAtStart:10];
	[extendedSelection extendSelectionAtEnd:50];
	
    // get the cleaned string
    sample = [extendedSelection cleanedString];
    
	// Finally, create attributed string.
 	attributedSample = [[NSMutableAttributedString alloc] initWithString:sample];
    attributedString = [attributedSample mutableString];
    [attributedString insertString:ellipse atIndex:0];
    [attributedString appendString:ellipse];
	
	// Find instances of search string and "bold" them.
	foundRange = [sample rangeOfString:searchString options:NSCaseInsensitiveSearch];
    if (foundRange.location != NSNotFound) {
        // Bold the text range where the search term was found.
        attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont boldSystemFontOfSize:fontSize], NSFontAttributeName, nil];
        [attributedSample setAttributes:attributes range:NSMakeRange(foundRange.location + 1, foundRange.length)];
        [attributes release];
    }
    
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSParagraphStyle defaultTruncatingTailParagraphStyle], NSParagraphStyleAttributeName, nil];
	// Add paragraph style.
    [attributedSample addAttributes:attributes range:NSMakeRange(0, [attributedSample length])];
	// Clean.
	[attributes release];
	[extendedSelection release];
	
	return [attributedSample autorelease];
}

- (PDFDestination *)destination {
    PDFDestination *destination = nil;
    NSArray *pages = [self pages];
    if ([pages count]) {
        PDFPage *page = [pages objectAtIndex:0];
        NSRect bounds = [self boundsForPage:page];
        destination = [[[PDFDestination alloc] initWithPage:page atPoint:NSMakePoint(NSMinX(bounds), NSMaxY(bounds))] autorelease];
    }
    return destination;
}

- (NSInteger)safeNumberOfRangesOnPage:(PDFPage *)page {
    if (usePageRanges) {
        NSEnumerator *prEnum = [[self pageRanges] objectEnumerator];
        id pr;
        NSInteger count = 0;
        while (pr = [prEnum nextObject])
            if ([[pr page] isEqual:page]) count++;
        return count;
    } else if ([self respondsToSelector:@selector(numberOfRangesOnPage:)])
        return [self numberOfRangesOnPage:page];
    return 0;
}

- (NSRange)safeRangeAtIndex:(NSInteger)anIndex onPage:(PDFPage *)page {
    if (usePageRanges) {
        NSEnumerator *prEnum = [[self pageRanges] objectEnumerator];
        id pr;
        while (pr = [prEnum nextObject])
            if ([[pr page] isEqual:page] && (0 == anIndex--)) return [pr range];
    } else if ([self respondsToSelector:@selector(rangeAtIndex:onPage:)])
        return [self rangeAtIndex:anIndex onPage:page];
    return NSMakeRange(NSNotFound, 0);
}

static inline NSRange rangeOfSubstringOfStringAtIndex(NSString *string, NSArray *substrings, NSUInteger anIndex) {
    NSUInteger length = [string length];
    NSRange range = NSMakeRange(0, 0);
    NSUInteger i, iMax = [substrings count];
    
    if (anIndex >= iMax)
        return NSMakeRange(NSNotFound, 0);
    for (i = 0; i <= anIndex; i++) {
        NSString *substring = [substrings objectAtIndex:i];
        NSRange searchRange = NSMakeRange(NSMaxRange(range), length - NSMaxRange(range));
        if ([substring length] == 0)
            continue;
        range = [string rangeOfString:substring options:NSLiteralSearch range:searchRange];
        if (range.location == NSNotFound)
            return NSMakeRange(NSNotFound, 0);
    }
    return range;
}

static NSArray *characterRangesAndContainersForSpecifier(NSScriptObjectSpecifier *specifier, BOOL continuous, BOOL continuousContainers) {
    if ([specifier isKindOfClass:[NSScriptObjectSpecifier class]] == NO)
        return nil;
    
    NSMutableArray *rangeDicts = [NSMutableArray array];
    NSString *key = [specifier key];
    
    if ([key isEqualToString:@"characters"] || [key isEqualToString:@"words"] || [key isEqualToString:@"paragraphs"] || [key isEqualToString:@"attributeRuns"]) {
        
        // get the richText specifier and textStorage
        NSArray *dicts = characterRangesAndContainersForSpecifier([specifier containerSpecifier], continuousContainers, continuousContainers);
        if ([dicts count] == 0)
            return nil;
        
        NSEnumerator *dictEnum = [dicts objectEnumerator];
        NSMutableDictionary *dict;
        
        while (dict = [dictEnum nextObject]) {
            NSTextStorage *containerText = [dict objectForKey:@"text"];
            CFArrayRef textRanges = (CFArrayRef)[dict objectForKey:@"ranges"];
            NSUInteger ri, numRanges = CFArrayGetCount(textRanges);
            CFMutableArrayRef ranges = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kSKNSRangeArrayCallBacks);
            
            for (ri = 0; ri < numRanges; ri++) {
                NSRange textRange = *(NSRange *)CFArrayGetValueAtIndex(textRanges, ri);
                NSTextStorage *textStorage = nil;
                if (NSEqualRanges(textRange, NSMakeRange(0, [containerText length])))
                    textStorage = [containerText retain];
                else
                    textStorage = [[NSTextStorage alloc] initWithAttributedString:[containerText attributedSubstringFromRange:textRange]];
                
                // now get the ranges, which can be any kind of specifier
                NSInteger startIndex, endIndex, i, count, *indices;
                CFMutableArrayRef tmpRanges = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kSKNSRangeArrayCallBacks);
                
                if ([specifier isKindOfClass:[NSPropertySpecifier class]]) {
                    // this should be the full range of characters, words, or paragraphs
                    NSRange range = NSMakeRange(0, [[textStorage valueForKey:key] count]);
                    if (range.length)
                        CFArrayAppendValue(tmpRanges, &range);
                } else if ([specifier isKindOfClass:[NSRangeSpecifier class]]) {
                    // somehow getting the indices as for the general case sometimes leads to an exception for NSRangeSpecifier, so we get the indices of the start/endSpecifiers
                    NSScriptObjectSpecifier *startSpec = [(NSRangeSpecifier *)specifier startSpecifier];
                    NSScriptObjectSpecifier *endSpec = [(NSRangeSpecifier *)specifier endSpecifier];
                    
                    if (startSpec || endSpec) {
                        if (startSpec) {
                            indices = [startSpec indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
                            startIndex = count ? indices[0] : -1;
                        } else {
                            startIndex = 0;
                        }
                        if (endSpec) {
                            indices = [endSpec indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
                            endIndex = count ? indices[count - 1] : -1;
                        } else {
                            endIndex = [[textStorage valueForKey:key] count] - 1;
                        }
                        if (startIndex >= 0 && endIndex >= 0) {
                            NSRange range = NSMakeRange(MIN(startIndex, endIndex), MAX(startIndex, endIndex) + 1 - MIN(startIndex, endIndex));
                            CFArrayAppendValue(tmpRanges, &range);
                        }
                    }
                } else {
                    // this handles other objectSpecifiers (index, middel, random, relative, whose). It can contain several ranges, e.g. for aan NSWhoseSpecifier
                    indices = [specifier indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
                    NSRange range = NSMakeRange(0, 0);
                    for (i = 0; i < count; i++) {
                        NSUInteger idx = indices[i];
                        if (range.length = 0 || idx > NSMaxRange(range)) {
                            if (range.length)
                                CFArrayAppendValue(tmpRanges, &range);
                            range = NSMakeRange(idx, 1);
                        } else {
                            ++(range.length);
                        }
                    }
                    if (range.length)
                        CFArrayAppendValue(tmpRanges, &range);
                }
                
                count = CFArrayGetCount(tmpRanges);
                if (count == 0) {
                } else if ([key isEqualToString:@"characters"]) {
                    for (i = 0; i < count; i++) {
                        NSRange range = *(NSRange *)CFArrayGetValueAtIndex(tmpRanges, i);
                        range.location += textRange.location;
                        range = NSIntersectionRange(range, textRange);
                        if (range.length) {
                            if (continuous) {
                                CFArrayAppendValue(ranges, &range);
                            } else {
                                NSUInteger j;
                                for (j = range.location; j < NSMaxRange(range); j++) {
                                    NSRange r = NSMakeRange(j, 1);
                                    CFArrayAppendValue(ranges, &r);
                                }
                            }
                        }
                    }
                } else {
                    // translate from subtext ranges to character ranges
                    NSString *string = [textStorage string];
                    NSArray *substrings = [[textStorage valueForKey:key] valueForKey:@"string"];
                    if ([substrings count]) {
                        for (i = 0; i < count; i++) {
                            NSRange range = *(NSRange *)CFArrayGetValueAtIndex(tmpRanges, i);
                            startIndex = MIN(range.location, [substrings count] - 1);
                            endIndex = MIN(NSMaxRange(range) - 1, [substrings count] - 1);
                            if (endIndex == startIndex) endIndex = -1;
                            if (continuous) {
                                range = rangeOfSubstringOfStringAtIndex(string, substrings, startIndex);
                                if (range.location == NSNotFound)
                                    continue;
                                startIndex = range.location;
                                if (endIndex >= 0) {
                                    range = rangeOfSubstringOfStringAtIndex(string, substrings, endIndex);
                                    if (range.location == NSNotFound)
                                        continue;
                                }
                                endIndex = NSMaxRange(range) - 1;
                                range = NSMakeRange(textRange.location + startIndex, endIndex + 1 - startIndex);
                                CFArrayAppendValue(ranges, &range);
                            } else {
                                if (endIndex == -1) endIndex = startIndex;
                                NSInteger j;
                                for (j = startIndex; j <= endIndex; j++) {
                                    range = rangeOfSubstringOfStringAtIndex(string, substrings, j);
                                    if (range.location == NSNotFound)
                                        continue;
                                    range.location += textRange.location;
                                    CFArrayAppendValue(ranges, &range);
                                }
                            }
                        }
                    }
                }
                
                CFRelease(tmpRanges);
                [textStorage release];
            }
            
            if (CFArrayGetCount(ranges)) {
                [dict setObject:(id)ranges forKey:@"ranges"];
                [rangeDicts addObject:dict];
            }
            CFRelease(ranges);
        }
        
    } else {
        
        NSScriptClassDescription *classDesc = [specifier keyClassDescription];
        if ([[classDesc className] isEqualToString:@"rich text"]) {
            if ([[[specifier containerClassDescription] toManyRelationshipKeys] containsObject:key])
                return nil;
            specifier = [specifier containerSpecifier];
        } else {
            key = [classDesc defaultSubcontainerAttributeKey];
            if (key == nil || [[[classDesc classDescriptionForKey:key] className] isEqualToString:@"rich text"] == NO)
                return nil;
        }
        
        NSArray *containers = [specifier objectsByEvaluatingSpecifier];
        if (containers && [containers isKindOfClass:[NSArray class]] == NO)
            containers = [NSArray arrayWithObject:containers];
        if ([containers count] == 0)
            return nil;
        
        NSEnumerator *containerEnum = [containers objectEnumerator];
        id container;
        
        while (container = [containerEnum nextObject]) {
            NSTextStorage *containerText = [container valueForKey:key];
            if ([containerText isKindOfClass:[NSTextStorage class]] == NO || [containerText length] == 0)
                continue;
            CFMutableArrayRef ranges = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kSKNSRangeArrayCallBacks);
            NSRange range = NSMakeRange(0, [containerText length]);
            CFArrayAppendValue(ranges, &range);
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:(id)ranges, @"ranges", containerText, @"text", container, @"container", nil];
            [rangeDicts addObject:dict];
            [dict release];
            CFRelease(ranges);
        }
        
    }
    
    return rangeDicts;
}

+ (id)selectionWithSpecifier:(id)specifier {
    return [self selectionWithSpecifier:specifier onPage:nil];
}

+ (id)selectionWithSpecifier:(id)specifier onPage:(PDFPage *)aPage {
    if (specifier == nil || [specifier isEqual:[NSNull null]])
        return nil;
    if ([specifier isKindOfClass:[NSArray class]] == NO)
        specifier = [NSArray arrayWithObject:specifier];
    if ([specifier count] == 1) {
        NSScriptObjectSpecifier *spec = [specifier objectAtIndex:0];
        if ([spec isKindOfClass:[NSPropertySpecifier class]]) {
            NSString *key = [spec key];
            if ([[NSSet setWithObjects:@"characters", @"words", @"paragraphs", @"attributeRuns", @"richText", @"pages", nil] containsObject:key] == NO) {
                // this allows to use selection properties directly
                specifier = [spec objectsByEvaluatingSpecifier];
                if ([specifier isKindOfClass:[NSArray class]] == NO)
                    specifier = [NSArray arrayWithObject:specifier];
            }
        }
    }
    
    NSMutableArray *selections = [NSMutableArray array];
    NSEnumerator *specEnum = [specifier objectEnumerator];
    NSScriptObjectSpecifier *spec;
    
    while (spec = [specEnum nextObject]) {
        if ([spec isKindOfClass:[NSScriptObjectSpecifier class]] == NO)
            continue;
        
        NSArray *dicts = characterRangesAndContainersForSpecifier(spec, YES, NO);
        NSEnumerator *dictEnum = [dicts objectEnumerator];
        NSDictionary *dict;
        PDFDocument *doc = nil;
        
        while (dict = [dictEnum nextObject]) {
            id container = [dict objectForKey:@"container"];
            CFArrayRef ranges = (CFArrayRef)[dict objectForKey:@"ranges"];
            NSUInteger i, numRanges = CFArrayGetCount(ranges);
            
            if ([container isKindOfClass:[SKPDFDocument class]] && (doc == nil || [doc isEqual:[container pdfDocument]])) {
                
                PDFDocument *document = [container pdfDocument];
                NSUInteger aPageIndex = (aPage ? [aPage pageIndex] : NSNotFound), page, numPages = [document pageCount];
                NSUInteger *pageLengths = NSZoneMalloc(NSDefaultMallocZone(), numPages * sizeof(NSUInteger));
                
                for (page = 0; page < numPages; page++)
                    pageLengths[page] = NSNotFound;
                
                for (i = 0; i < numRanges; i++) {
                    NSRange range = *(NSRange *)CFArrayGetValueAtIndex(ranges, i);
                    NSUInteger pageStart = 0, startPage = NSNotFound, endPage = NSNotFound, startIndex = NSNotFound, endIndex = NSNotFound;
                    
                    for (page = 0; (page < numPages) && (pageStart < NSMaxRange(range)); page++) {
                        if (pageLengths[page] == NSNotFound)
                            pageLengths[page] = [[[document pageAtIndex:page] attributedString] length];
                        if ((aPageIndex == NSNotFound || page == aPageIndex) && pageLengths[page] && range.location < pageStart + pageLengths[page]) {
                            if (startPage == NSNotFound && startIndex == NSNotFound) {
                                startPage = page;
                                startIndex = MAX(pageStart, range.location) - pageStart;
                            }
                            if (startPage != NSNotFound && startIndex != NSNotFound) {
                                endPage = page;
                                endIndex = MIN(NSMaxRange(range) - pageStart, pageLengths[page]) - 1;
                            }
                        }
                        pageStart += pageLengths[page] + 1; // text of pages is separated by newlines, see -[SKPDFDocument richText]
                    }
                    
                    if (startPage != NSNotFound && startIndex != NSNotFound && endPage != NSNotFound && endIndex != NSNotFound) {
                        PDFSelection *sel = [document selectionFromPage:[document pageAtIndex:startPage] atCharacterIndex:startIndex toPage:[document pageAtIndex:endPage] atCharacterIndex:endIndex];
                        if (sel) {
                            [selections addObject:sel];
                            doc = document;
                        }
                    }
                }
                
                NSZoneFree(NSDefaultMallocZone(), pageLengths);
                
            } else if ([container isKindOfClass:[PDFPage class]] && (aPage == nil || [aPage isEqual:container]) && (doc == nil || [doc isEqual:[container document]])) {
                
                for (i = 0; i < numRanges; i++) {
                    PDFSelection *sel;
                    NSRange range = *(NSRange *)CFArrayGetValueAtIndex(ranges, i);
                    if (range.length && (sel = [container selectionForRange:range])) {
                        [selections addObject:sel];
                        doc = [container document];
                    }
                }
                
            }
        }
    }
    
    PDFSelection *selection = nil;
    if ([selections count]) {
        selection = [selections objectAtIndex:0];
        if ([selections count] > 1) {
            [selections removeObjectAtIndex:0];
            [selection addSelections:selections];
        }
    }
    return selection;
}

static inline void addSpecifierWithCharacterRangeAndPage(NSMutableArray *ranges, NSRange range, PDFPage *page) {
    NSRangeSpecifier *rangeSpec = nil;
    NSIndexSpecifier *startSpec = nil;
    NSIndexSpecifier *endSpec = nil;
    NSScriptObjectSpecifier *textSpec = [[NSPropertySpecifier alloc] initWithContainerSpecifier:[page objectSpecifier] key:@"richText"];
    
    if (textSpec) {
        if (startSpec = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" index:range.location]) {
            if (range.length == 1) {
                [ranges addObject:startSpec];
            } else if ((endSpec = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" index:NSMaxRange(range) - 1]) &&
                       (rangeSpec = [[NSRangeSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" startSpecifier:startSpec endSpecifier:endSpec])) {
                [ranges addObject:rangeSpec];
                [rangeSpec release];
            }
            [startSpec release];
            [endSpec release];
        }
        [textSpec release];
    }
}

- (id)objectSpecifier {
    NSMutableArray *ranges = [NSMutableArray array];
    NSEnumerator *pageEnum = [[self pages] objectEnumerator];
    PDFPage *page;
    while (page = [pageEnum nextObject]) {
        NSUInteger i, iMax = [self safeNumberOfRangesOnPage:page];
        NSRange lastRange = NSMakeRange(0, 0);
        for (i = 0; i < iMax; i++) {
            NSRange range = [self safeRangeAtIndex:i onPage:page];
            if (range.length == 0) {
            } else if (lastRange.length == 0) {
                lastRange = range;
            } else if (NSMaxRange(lastRange) == range.location) {
                lastRange.length += range.length;
            } else {
                addSpecifierWithCharacterRangeAndPage(ranges, lastRange, page);
                lastRange = range;
            }
        }
        if (lastRange.length)
            addSpecifierWithCharacterRangeAndPage(ranges, lastRange, page);
    }
    return ranges;
}

@end
