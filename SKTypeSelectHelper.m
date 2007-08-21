//
//  SKTypeSelectHelper.m
//  Skim
//
//  Created by Christiaan Hofman on 8/21/07.
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

#import "SKTypeSelectHelper.h"


@interface SKTypeSelectHelper (SKPrivate)
- (void)typeSelectSearchTimeout;
- (unsigned int)indexOfMatchedItemAfterIndex:(unsigned int)selectedIndex;
@end

@implementation SKTypeSelectHelper

// Init and dealloc

- (id)init {
    if (self = [super init]){
        cycleResults = YES;
        matchesImmediately = NO;
        matchOption = SKPrefixMatch;
    }
    return self;
}

- (void)dealloc {
    [timer invalidate];
    [timer release];
    [searchString release];
    [searchCache release];
    [super dealloc];
}

// API
- (id)dataSource {
    return dataSource;
}

- (void)setDataSource:(id)newDataSource {
    if (dataSource == newDataSource)
        return;
    
    dataSource = newDataSource;
    [self rebuildTypeSelectSearchCache];
}

- (BOOL)cyclesSimilarResults {
    return cycleResults;
}

- (void)setCyclesSimilarResults:(BOOL)newValue {
    cycleResults = newValue;
}

- (BOOL)matchesImmediately {
    return matchesImmediately;
}

- (void)setMatchesImmediately:(BOOL)newValue {
    matchesImmediately = newValue;
}

- (int)matchOption {
    return matchOption;
}

- (void)setMatchOption:(int)newValue {
    matchOption = newValue;
}

- (void)rebuildTypeSelectSearchCache {    
    if (searchCache)
        [searchCache release];
    
    searchCache = [[dataSource typeSelectHelperSelectionItems:self] retain];
}

- (void)processKeyDownCharacter:(unichar)character {
    NSString *selectedItem = nil;
    unsigned int selectedIndex, foundIndex;
    
    // Create the search string the first time around
    if (searchString == nil)
        searchString = [[NSMutableString alloc] init];
    
    // Append the new character to the search string
    [searchString appendFormat:@"%C", character];
    
    if ([dataSource respondsToSelector:@selector(typeSelectHelper:updateSearchString:)])
        [dataSource typeSelectHelper:self updateSearchString:searchString];
    
    // Reset the timer if it hasn't expired yet
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0.7];
    [timer invalidate];
    [timer release];
    timer = nil;
    timer = [[NSTimer alloc] initWithFireDate:date interval:0 target:self selector:@selector(typeSelectSearchTimeout:) userInfo:NULL repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
    if (matchesImmediately) {
        if (cycleResults) {
            selectedIndex = [dataSource typeSelectHelperCurrentlySelectedIndex:self];
            if (selectedIndex < [searchCache count])
               selectedItem = [searchCache objectAtIndex:selectedIndex];
            else
                selectedIndex = NSNotFound;
            
            // Avoid flashing a selection all over the place while you're still typing the thing you have selected
            if (matchOption == SKFullStringMatch) {
                if ([selectedItem caseInsensitiveCompare:searchString] == NSOrderedSame)
                    return;
            } else {
                unsigned int searchStringLength = [searchString length];
                unsigned int selectedItemLength = [selectedItem length];
                NSRange range = NSMakeRange(0, matchOption == SKPrefixMatch ? searchStringLength : selectedItemLength);
                if (searchStringLength > 1 && selectedItemLength >= searchStringLength && [selectedItem rangeOfString:searchString options:NSCaseInsensitiveSearch range:range].location != NSNotFound)
                    return;
            }
            
        } else {
            selectedIndex = NSNotFound;
        }
        
        foundIndex = [self indexOfMatchedItemAfterIndex:selectedIndex];
        
        if (foundIndex != NSNotFound)
            [dataSource typeSelectHelper:self selectItemAtIndex:foundIndex];
    }
}

- (BOOL)isProcessing {
    return timer != nil;
}

- (void)typeSelectSearchTimeout:(NSTimer *)aTimer {
    if (matchesImmediately == NO && [searchString length]) {
        unsigned int selectedIndex, foundIndex;
        
        if (cycleResults) {
            selectedIndex = [dataSource typeSelectHelperCurrentlySelectedIndex:self];
            if (selectedIndex >= [searchCache count])
                selectedIndex = NSNotFound;
        } else {
            selectedIndex = NSNotFound;
        }
        foundIndex = [self indexOfMatchedItemAfterIndex:selectedIndex];
        if (foundIndex != NSNotFound)
            [dataSource typeSelectHelper:self selectItemAtIndex:foundIndex];
    }
    
    if ([dataSource respondsToSelector:@selector(typeSelectHelper:updateSearchString:)])
        [dataSource typeSelectHelper:self updateSearchString:nil];
    [timer invalidate];
    [timer release];
    timer = nil;
    [searchString release];
    searchString = nil;
}

- (unsigned int)indexOfMatchedItemAfterIndex:(unsigned int)selectedIndex {
    if (searchCache == nil)
        [self rebuildTypeSelectSearchCache];
    
    unsigned int labelCount = [searchCache count];
    
    if (labelCount == NO)
        return NSNotFound;
    
    if (selectedIndex == NSNotFound)
        selectedIndex = labelCount - 1;

    unsigned int labelIndex = selectedIndex;
    BOOL looped = NO;
    unsigned int searchStringLength = [searchString length];
    int options = NSCaseInsensitiveSearch;
    
    if (matchOption == SKPrefixMatch)
        options |= NSAnchoredSearch;
    
    while (looped == NO) {
        NSString *label;
        
        if (++labelIndex == labelCount)
            labelIndex = 0;
        if (labelIndex == selectedIndex)
            looped = YES;
        
        label = [searchCache objectAtIndex:labelIndex];
        
        if (matchOption == SKFullStringMatch) {
            if ([label caseInsensitiveCompare:searchString] == NSOrderedSame)
                return labelIndex;
        } else {
            int location = [label length] < searchStringLength ? NSNotFound : [label rangeOfString:searchString options:options].location;
            if (location != NSNotFound) {
                if (location == 0 || [[NSCharacterSet letterCharacterSet] characterIsMember:[label characterAtIndex:location - 1]] == NO)
                    return labelIndex;
            }
        }
    }
    
    return NSNotFound;
}

@end
