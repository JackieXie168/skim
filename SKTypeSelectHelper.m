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

#define TIMEOUT 0.7
#define REPEAT_CHARACTER '/'

@interface NSString (BDSKTypeAheadHelperExtensions)
- (BOOL)containsStringStartingAtWord:(NSString *)string options:(int)mask range:(NSRange)range;
@end

#pragma mark -

@interface SKTypeSelectHelper (SKPrivate)
- (NSArray *)searchCache;
- (void)searchWithStickyMatch:(BOOL)allowUpdate;
- (void)stopTimer;
- (void)startTimerForSelector:(SEL)selector;
- (void)typeSelectSearchTimeout:(NSTimer *)aTimer;
- (void)typeSelectCleanTimeout:(NSTimer *)aTimer;
- (unsigned int)indexOfMatchedItemAfterIndex:(unsigned int)selectedIndex;
@end

@implementation SKTypeSelectHelper

// Init and dealloc

- (id)init {
    if (self = [super init]){
        searchString = [[NSMutableString alloc] init];
        cycleResults = YES;
        matchesImmediately = YES;
        matchOption = SKPrefixMatch;
    }
    return self;
}

- (void)dealloc {
    [self stopTimer];
    [searchString release];
    [searchCache release];
    [super dealloc];
}

#pragma mark Accessors

- (id)dataSource {
    return dataSource;
}

- (void)setDataSource:(id)newDataSource {
    if (dataSource != newDataSource) {
        dataSource = newDataSource;
        [self rebuildTypeSelectSearchCache];
    }
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

- (BOOL)isProcessing {
    return processing;
}

#pragma mark API

- (void)rebuildTypeSelectSearchCache {    
    if (searchCache)
        [searchCache release];
    
    searchCache = [[dataSource typeSelectHelperSelectionItems:self] retain];
}

- (void)processKeyDownCharacter:(unichar)character {
    if (processing == NO)
        [searchString setString:@""];
    
    // Append the new character to the search string
    [searchString appendFormat:@"%C", character];
    
    if ([dataSource respondsToSelector:@selector(typeSelectHelper:updateSearchString:)])
        [dataSource typeSelectHelper:self updateSearchString:searchString];
    
    // Reset the timer if it hasn't expired yet
    [self startTimerForSelector:@selector(typeSelectSearchTimeout:)];
    
    if (matchesImmediately)
        [self searchWithStickyMatch:processing];
    
    processing = YES;
}

- (void)repeatSearch {
    [self searchWithStickyMatch:NO];
    
    if ([searchString length] && [dataSource respondsToSelector:@selector(typeSelectHelper:updateSearchString:)])
        [dataSource typeSelectHelper:self updateSearchString:searchString];
    
    [self startTimerForSelector:@selector(typeSelectCleanTimeout:)];
    
    processing = NO;
}

- (BOOL)isTypeSelectCharacter:(unichar)character {
    if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:character])
        return YES;
    if ([self isProcessing] && [[NSCharacterSet controlCharacterSet] characterIsMember:character])
        return YES;
    return NO;
}

- (BOOL)isRepeatCharacter:(unichar)character {
    return [self cyclesSimilarResults] && character == REPEAT_CHARACTER;
}

@end 

#pragma mark -

@implementation SKTypeSelectHelper (SKPrivate)

- (NSArray *)searchCache {
    if (searchCache == nil)
        [self rebuildTypeSelectSearchCache];
    return searchCache;
}

- (void)stopTimer {
    [timer invalidate];
    [timer release];
    timer = nil;
}

- (void)startTimerForSelector:(SEL)selector {
    [self stopTimer];
    timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:TIMEOUT] interval:0 target:self selector:selector userInfo:NULL repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)typeSelectSearchTimeout:(NSTimer *)aTimer {
    if (matchesImmediately == NO)
        [self searchWithStickyMatch:NO];
    [self typeSelectCleanTimeout:aTimer];
}

- (void)typeSelectCleanTimeout:(NSTimer *)aTimer {
    if ([dataSource respondsToSelector:@selector(typeSelectHelper:updateSearchString:)])
        [dataSource typeSelectHelper:self updateSearchString:nil];
    [self stopTimer];
    processing = NO;
}

- (void)searchWithStickyMatch:(BOOL)sticky {
    if ([searchString length]) {
        unsigned int selectedIndex, startIndex, foundIndex;
        
        if (cycleResults) {
            selectedIndex = [dataSource typeSelectHelperCurrentlySelectedIndex:self];
            if (selectedIndex >= [[self searchCache] count])
                selectedIndex = NSNotFound;
        } else {
            selectedIndex = NSNotFound;
        }
        
        startIndex = selectedIndex;
        if (sticky && selectedIndex != NSNotFound)
            startIndex = startIndex > 0 ? startIndex - 1 : [[self searchCache] count] - 1;
        
        foundIndex = [self indexOfMatchedItemAfterIndex:startIndex];
        
        // Avoid flashing a selection all over the place while you're still typing the thing you have selected
        if (foundIndex != NSNotFound && foundIndex != selectedIndex)
            [dataSource typeSelectHelper:self selectItemAtIndex:foundIndex];
    }
}

- (unsigned int)indexOfMatchedItemAfterIndex:(unsigned int)selectedIndex {
    unsigned int labelCount = [[self searchCache] count];
    
    if (labelCount == NO)
        return NSNotFound;
    
    if (selectedIndex == NSNotFound)
        selectedIndex = labelCount - 1;

    unsigned int labelIndex = selectedIndex;
    BOOL looped = NO;
    int options = NSCaseInsensitiveSearch;
    
    if (matchOption == SKPrefixMatch)
        options |= NSAnchoredSearch;
    
    while (looped == NO) {
        NSString *label;
        
        if (++labelIndex == labelCount)
            labelIndex = 0;
        if (labelIndex == selectedIndex)
            looped = YES;
        
        label = [[self searchCache] objectAtIndex:labelIndex];
        
        if (matchOption == SKFullStringMatch) {
            if ([label caseInsensitiveCompare:searchString] == NSOrderedSame)
                return labelIndex;
        } else {
            if ([label containsStringStartingAtWord:searchString options:options range:NSMakeRange(0, [label length])]) {
                return labelIndex;
            }
        }
    }
    
    return NSNotFound;
}

@end

#pragma mark -

@implementation NSString (BDSKTypeAheadHelperExtensions)

- (BOOL)containsStringStartingAtWord:(NSString *)string options:(int)mask range:(NSRange)range {
    unsigned int stringLength = [string length];
    if (stringLength == 0 || stringLength > range.length)
        return NO;
    while (range.length >= stringLength) {
        NSRange r = [self rangeOfString:string options:mask range:range];
        if (r.location == NSNotFound)
            return NO;
        // see if we start at a "word boundary"
        if (r.location == 0 || [[NSCharacterSet alphanumericCharacterSet] characterIsMember:[self characterAtIndex:r.location - 1]] == NO)
            return YES;
        // if it's anchored, we only should search once
        if (mask & NSAnchoredSearch)
            return NO;
        // get the new range, shifted by one from the last match
        if (mask & NSBackwardsSearch)
            range = NSMakeRange(range.location, NSMaxRange(r) - range.location - 1);
        else
            range = NSMakeRange(r.location + 1, NSMaxRange(range) - r.location - 1);
    }
    return NO;
}

@end
