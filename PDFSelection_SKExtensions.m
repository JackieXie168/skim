//
//  PDFSelection_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/24/07.
/*
 This software is Copyright (c) 2007
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


@interface PDFSelection (PDFSelectionPrivateDeclarations)

- (int)numberOfRangesOnPage:(PDFPage *)page;
- (NSRange)rangeAtIndex:(int)index onPage:(PDFPage *)page;

@end


@implementation PDFSelection (SKExtensions)

// returns the label of the first page (if the selection spans multiple pages)
- (NSString *)firstPageLabel { 
    NSArray *pages = [self pages];
    return [pages count] ? [[pages objectAtIndex:0] label] : nil;
}

- (NSAttributedString *)contextString {
    PDFSelection *extendedSelection = [self copy]; // see remark in -tableViewSelectionDidChange:
	NSMutableAttributedString *attributedSample;
	NSString *searchString = [[self string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
	NSString *sample;
    NSMutableString *attributedString;
	NSString *ellipse = [NSString stringWithFormat:@"%C", 0x2026];
	NSRange foundRange;
    NSDictionary *attributes;
	
	// Extend selection.
	[extendedSelection extendSelectionAtStart:10];
	[extendedSelection extendSelectionAtEnd:30];
	
    // get the cleaned string
    sample = [[extendedSelection string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
    
	// Finally, create attributed string.
 	attributedSample = [[NSMutableAttributedString alloc] initWithString:sample];
    attributedString = [attributedSample mutableString];
    [attributedString insertString:ellipse atIndex:0];
    [attributedString appendString:ellipse];
	
	// Find instances of search string and "bold" them.
	foundRange = [sample rangeOfString:searchString options:NSCaseInsensitiveSearch];
    if (foundRange.location != NSNotFound) {
        // Bold the text range where the search term was found.
        attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, nil];
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

- (int)safeNumberOfRangesOnPage:(PDFPage *)page {
    if ([self respondsToSelector:@selector(numberOfRangesOnPage:)])
        return [self numberOfRangesOnPage:page];
    else
        return 0;
}

- (NSRange)safeRangeAtIndex:(int)index onPage:(PDFPage *)page {
    if ([self respondsToSelector:@selector(rangeAtIndex:onPage:)])
        return [self rangeAtIndex:index onPage:page];
    else
        return NSMakeRange(NSNotFound, 0);
}

+ (id)selectionWithSpecifier:(id)specifier {
    if ([specifier isEqual:[NSNull null]])
        return nil;
    if ([specifier isKindOfClass:[NSArray class]] == NO)
        specifier = [NSArray arrayWithObject:specifier];
    else if ([specifier count] == 1 && [[specifier objectAtIndex:0] isKindOfClass:[NSPropertySpecifier class]])
        specifier = [[specifier objectAtIndex:0] objectsByEvaluatingSpecifier];
    
    PDFSelection *selection = nil;
    NSEnumerator *specEnum = [specifier objectEnumerator];
    NSScriptObjectSpecifier *spec;
    
    while (spec = [specEnum nextObject]) {
        if ([spec isKindOfClass:[NSScriptObjectSpecifier class]] == NO)
            continue;
        
        NSScriptObjectSpecifier *pageSpec = nil;
        NSScriptObjectSpecifier *textSpec = nil;
        NSString *key = [spec key];
        PDFPage *page = nil;
        int startIndex, endIndex;
        PDFSelection *sel = nil;
        
        textSpec = [spec containerSpecifier];
        if ([[textSpec key] isEqualToString:@"richText"] == NO)
            continue;
        
        pageSpec = [textSpec containerSpecifier];
        page = [pageSpec objectsByEvaluatingSpecifier];
        if ([page isKindOfClass:[NSArray class]])
            page = [(NSArray *)page count] ? [(NSArray *)page objectAtIndex:0] : nil;
        if (page == nil)
            continue;
        
        if ([spec isKindOfClass:[NSRangeSpecifier class]]) {
            
            NSScriptObjectSpecifier *startSpec = [(NSRangeSpecifier *)spec startSpecifier];
            NSScriptObjectSpecifier *endSpec = [(NSRangeSpecifier *)spec endSpecifier];
            if (startSpec == nil && endSpec == nil)
                continue;
            
            if ([key isEqualToString:@"characters"]) {
                
                startIndex = (startSpec && [startSpec isKindOfClass:[NSIndexSpecifier class]]) ? [(NSIndexSpecifier *)startSpec index] : 0;
                endIndex = (endSpec && [endSpec isKindOfClass:[NSIndexSpecifier class]]) ? [(NSIndexSpecifier *)endSpec index] : -1;
                if (startIndex < 0)
                    startIndex += [[page string] length];
                if (endIndex < 0)
                    endIndex += [[page string] length];
                
            } else if ([key isEqualToString:@"words"]) {
                
                NSRange startRange, endRange;
                NSTextStorage *textStorage = [textSpec objectsByEvaluatingSpecifier];
                if ([textStorage isKindOfClass:[NSArray class]])
                    textStorage = [(NSArray *)textStorage count] ? [(NSArray *)textStorage objectAtIndex:0] : nil;
                
                startIndex = (startSpec && [startSpec isKindOfClass:[NSIndexSpecifier class]]) ? [(NSIndexSpecifier *)startSpec index] : 0;
                endIndex = (endSpec && [endSpec isKindOfClass:[NSIndexSpecifier class]]) ? [(NSIndexSpecifier *)endSpec index] : -1;
                if (startIndex < 0)
                    startIndex += [[textStorage words] count];
                if (endIndex < 0)
                    endIndex += [[textStorage words] count];
                startRange = [textStorage characterRangeForWordAtIndex:startIndex];
                endRange = [textStorage characterRangeForWordAtIndex:endIndex];
                if (startRange.location == NSNotFound || endRange.location == NSNotFound)
                    continue;
                
                startIndex = startRange.location;
                endIndex = NSMaxRange(endRange);
                
            } else if ([key isEqualToString:@"paragraphs"]) {
                
                NSRange startRange, endRange;
                NSTextStorage *textStorage = [textSpec objectsByEvaluatingSpecifier];
                if ([textStorage isKindOfClass:[NSArray class]])
                    textStorage = [(NSArray *)textStorage count] ? [(NSArray *)textStorage objectAtIndex:0] : nil;
                
                startIndex = (startSpec && [startSpec isKindOfClass:[NSIndexSpecifier class]]) ? [(NSIndexSpecifier *)startSpec index] : 0;
                endIndex = (endSpec && [endSpec isKindOfClass:[NSIndexSpecifier class]]) ? [(NSIndexSpecifier *)endSpec index] : -1;
                if (startIndex < 0)
                    startIndex += [[textStorage paragraphs] count];
                if (endIndex < 0)
                    endIndex += [[textStorage paragraphs] count];
                startRange = [textStorage characterRangeForParagraphAtIndex:startIndex];
                endRange = [textStorage characterRangeForParagraphAtIndex:endIndex];
                if (startRange.location == NSNotFound || endRange.location == NSNotFound)
                    continue;
                
                startIndex = startRange.location;
                endIndex = NSMaxRange(endRange) - 1;
                
            } else continue;
            
        } else if ([spec isKindOfClass:[NSIndexSpecifier class]]) {
            
            if ([key isEqualToString:@"characters"]) {
                
                startIndex = [(NSIndexSpecifier *)spec index];
                if (startIndex < 0)
                    startIndex += [[page string] length];
                endIndex = startIndex;
                
            } else if ([key isEqualToString:@"words"]) {
                
                NSRange range;
                NSTextStorage *textStorage = [textSpec objectsByEvaluatingSpecifier];
                if ([textStorage isKindOfClass:[NSArray class]])
                    textStorage = [(NSArray *)textStorage count] ? [(NSArray *)textStorage objectAtIndex:0] : nil;
                
                startIndex = [(NSIndexSpecifier *)spec index];
                if (startIndex < 0)
                    startIndex += [[textStorage words] count];
                range = [textStorage characterRangeForWordAtIndex:startIndex];
                if (range.location == NSNotFound)
                    continue;
                
                startIndex = range.location;
                endIndex = NSMaxRange(range) - 1;
                
            } else if ([key isEqualToString:@"paragraphs"]) {
                
                NSRange range;
                NSTextStorage *textStorage = [textSpec objectsByEvaluatingSpecifier];
                if ([textStorage isKindOfClass:[NSArray class]])
                    textStorage = [(NSArray *)textStorage count] ? [(NSArray *)textStorage objectAtIndex:0] : nil;
                
                startIndex = [(NSIndexSpecifier *)spec index];
                if (startIndex < 0)
                    startIndex += [[textStorage paragraphs] count];
                range = [textStorage characterRangeForParagraphAtIndex:startIndex];
                if (range.location == NSNotFound)
                    continue;
                
                startIndex = range.location;
                endIndex = NSMaxRange(range) - 1;
                
            } else continue;
            
        } else continue;
        
        if ((endIndex >= startIndex) && (sel = [page selectionForRange:NSMakeRange(startIndex, endIndex + 1 - startIndex)])) {
            if (selection == nil)
                selection = sel;
            else
                [selection addSelection:sel];
        }
    }
    return selection;
}

- (id)objectSpecifier {
    NSArray *pages = [self pages];
    if ([pages count] == 0)
        return [NSArray array];
    NSMutableArray *ranges = [NSMutableArray array];
    NSEnumerator *pageEnum = [pages objectEnumerator];
    PDFPage *page;
    while (page = [pageEnum nextObject]) {
        int i, iMax = [self safeNumberOfRangesOnPage:page];
        for (i = 0; i < iMax; i++) {
            NSRange range = [self safeRangeAtIndex:i onPage:page];
            if (range.length == 0)
                continue;
            
            NSScriptObjectSpecifier *textSpec = [[NSPropertySpecifier alloc] initWithContainerSpecifier:[page objectSpecifier] key:@"richText"];
            if (textSpec == nil)
                continue;
            
            NSIndexSpecifier *startSpec = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" index:range.location];
            NSIndexSpecifier *endSpec = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" index:NSMaxRange(range) - 1];
            if (startSpec == nil || endSpec == nil) {
                [startSpec release];
                [endSpec release];
                continue;
            }
            
            NSRangeSpecifier *rangeSpec = [[NSRangeSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" startSpecifier:startSpec endSpecifier:endSpec];
            if (rangeSpec == nil)
                continue;
            
            [ranges addObject:rangeSpec];
            [rangeSpec release];
            [startSpec release];
            [endSpec release];
            [textSpec release];
        }
    }
    return ranges;
}

@end


@implementation NSTextStorage (SKExtensions) 

- (NSRange)characterRangeForWordAtIndex:(unsigned int)index {
    NSString *string = [self string];
    NSArray *words = [self words];
    unsigned int length = [string length];
    NSRange range = NSMakeRange(0, 0);
    unsigned int i, iMax = [words count];
    
    if (index >= iMax)
        return NSMakeRange(NSNotFound, 0);
    for (i = 0; i < index; i++) {
        NSString *word = [[words objectAtIndex:i] string];
        NSRange searchRange = NSMakeRange(NSMaxRange(range), length - NSMaxRange(range));
        if ([word length] == 0)
            continue;
        range = [string rangeOfString:word options:NSLiteralSearch range:searchRange];
        if (range.location == NSNotFound)
            return NSMakeRange(NSNotFound, 0);
    }
    return range;
}

- (NSRange)characterRangeForParagraphAtIndex:(unsigned int)index {
    NSString *string = [self string];
    NSArray *paragraphs = [self paragraphs];
    unsigned int length = [string length];
    NSRange range = NSMakeRange(0, 0);
    unsigned int i, iMax = [paragraphs count];
    
    if (index >= iMax)
        return NSMakeRange(NSNotFound, 0);
    for (i = 0; i < index; i++) {
        NSString *paragraph = [[paragraphs objectAtIndex:i] string];
        NSRange searchRange = NSMakeRange(NSMaxRange(range), length - NSMaxRange(range));
        if ([paragraph length] == 0)
            continue;
        range = [string rangeOfString:paragraph options:NSLiteralSearch range:searchRange];
        if (range.location == NSNotFound)
            return NSMakeRange(NSNotFound, 0);
    }
    return range;
}

@end

