//
//  BDSKTypeSelectHelper.m
//  BibDesk
//
//  Created by Christiaan Hofman on 8/11/06.
/*
 This software is Copyright (c) 2005,2006,2007
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

#import "BDSKTypeSelectHelper.h"
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>

@interface BDSKTypeSelectHelper (BDSKPrivate)
- (void)typeSelectSearchTimeout;
- (unsigned int)indexOfItemWithSubstring:(NSString *)substring afterIndex:(unsigned int)selectedIndex;
@end

@implementation BDSKTypeSelectHelper

// Init and dealloc

- init;
{
    if(self = [super init]){
        cycleResults = YES;
        matchPrefix = YES;
    }
    return self;
}

- (void)dealloc;
{
    [self setDataSource:nil];
    [self typeSelectSearchTimeout];
    [searchCache release];
    [super dealloc];
}

// API
- (id)dataSource;
{
    return dataSource;
}

- (void)setDataSource:(id)newDataSource;
{
    if (dataSource == newDataSource)
        return;
    
    dataSource = newDataSource;
    [self rebuildTypeSelectSearchCache];
}

- (BOOL)cyclesSimilarResults;
{
    return cycleResults;
}

- (void)setCyclesSimilarResults:(BOOL)newValue;
{
    cycleResults = newValue;
}

- (BOOL)matchesPrefix;
{
    return matchPrefix;
}

- (void)setMatchesPrefix:(BOOL)newValue;
{
    matchPrefix = newValue;
}

- (void)rebuildTypeSelectSearchCache;
{    
    if (searchCache)
        [searchCache release];
    
    searchCache = [[dataSource typeSelectHelperSelectionItems:self] retain];
}

- (void)processKeyDownCharacter:(unichar)character;
{
    OFScheduler *scheduler;
    NSString *selectedItem = nil;
    unsigned int selectedIndex, foundIndex;
    unsigned int searchStringLength;
    unsigned int selectedItemLength;
    NSRange range;

    OBPRECONDITION(dataSource != nil);

    // Create the search string the first time around
    if (searchString == nil)
        searchString = [[NSMutableString alloc] init];

    // Append the new character to the search string
    [searchString appendCharacter:character];
    
    if([dataSource respondsToSelector:@selector(typeSelectHelper:updateSearchString:)])
        [dataSource typeSelectHelper:self updateSearchString:searchString];

    // Reset the timer if it hasn't expired yet
    scheduler = [OFScheduler mainScheduler];
    if (timeoutEvent != nil) {
        [scheduler abortEvent:timeoutEvent];
        [timeoutEvent release];
        timeoutEvent = nil;
    }
    timeoutEvent = [[scheduler scheduleSelector:@selector(typeSelectSearchTimeout) onObject:self afterTime:0.7] retain];

    selectedIndex = [dataSource typeSelectHelperCurrentlySelectedIndex:self];
    if (selectedIndex < [searchCache count])
       selectedItem = [searchCache objectAtIndex:selectedIndex];
    else
        selectedIndex = NSNotFound;

    searchStringLength = [searchString length];
    selectedItemLength = [selectedItem length];
    
    // The Omni implementation of this looks for a prefix; we might be searching for a substring
    range = NSMakeRange(0, matchPrefix ? searchStringLength : selectedItemLength);
    if (searchStringLength > 1 && selectedItemLength >= searchStringLength && [selectedItem containsString:searchString options:NSCaseInsensitiveSearch range:range])
        return; // Avoid flashing a selection all over the place while you're still typing the thing you have selected

    if (cycleResults == NO)
        selectedIndex = NSNotFound;
    
    foundIndex = [self indexOfItemWithSubstring:searchString afterIndex:selectedIndex];

    if (foundIndex != NSNotFound)
        [dataSource typeSelectHelper:self selectItemAtIndex:foundIndex];
}

- (BOOL)isProcessing;
{
    return timeoutEvent != nil;
}

@end


@implementation BDSKTypeSelectHelper (BDSKPrivate)

- (void)typeSelectSearchTimeout{
    if([dataSource respondsToSelector:@selector(typeSelectHelper:updateSearchString:)])
        [dataSource typeSelectHelper:self updateSearchString:nil];
    [timeoutEvent release];
    timeoutEvent = nil;
    [searchString release];
    searchString = nil;
}

- (unsigned int)indexOfItemWithSubstring:(NSString *)substring afterIndex:(unsigned int)selectedIndex;
{
    unsigned int labelIndex, foundIndex, labelCount;
    unsigned int substringLength;
    BOOL looped;
    int options;

    if (searchCache == nil)
        [self rebuildTypeSelectSearchCache];

    substringLength = [substring length];
    labelCount = [searchCache count];
    if (labelCount == 0)
        return NSNotFound;
    if (selectedIndex == NSNotFound)
        selectedIndex = labelCount - 1;

    labelIndex = selectedIndex + 1;
    if (labelIndex == labelCount)
        labelIndex = 0;
    looped = NO;
    options = NSCaseInsensitiveSearch;
    if (matchPrefix)
        options |= NSAnchoredSearch;
    while (!looped) {
        NSString *label;
        unsigned int labelLength;
        int location;

        foundIndex = labelIndex++;
        if (labelIndex == labelCount)
            labelIndex = 0;
        if (labelIndex == selectedIndex + 1 || (labelIndex == 0 && selectedIndex == labelCount - 1))
            looped = YES;
        label = [searchCache objectAtIndex:foundIndex];
        labelLength = [label length];
        if (labelLength < substringLength)
            continue;
        location = [label rangeOfString:substring options:options].location;
        if (location != NSNotFound) {
            if (location == 0 || [[NSCharacterSet letterCharacterSet] characterIsMember:[label characterAtIndex:location - 1]] == NO)
                return foundIndex;
        }
    }

    return NSNotFound;
}

@end
