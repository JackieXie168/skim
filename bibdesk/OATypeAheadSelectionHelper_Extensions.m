//
//  OATypeAheadSelectionHelper_Extensions.m
//  BibDesk
/*
 This software is Copyright (c) 2001,2002, Michael O. McCracken
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 -  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 -  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "OATypeAheadSelectionHelper_Extensions.h"




@implementation OATypeAheadSelectionHelper (BDSKExtensions)
- (void)newProcessKeyDownCharacter:(unichar)character;
{
    OFScheduler *scheduler;
    NSString *selectedItem;
    int selectedIndex, foundIndex;
    unsigned int searchStringLength;

    OBPRECONDITION(_dataSource != nil);

    // Create the search string the first time around
    if (typeAheadSearchString == nil)
        typeAheadSearchString = [[NSMutableString alloc] init];

    // Append the new character to the search string
    [typeAheadSearchString appendString:[NSString stringWithCharacter:character]];

    // Reset the timer if it hasn't expired yet
    scheduler = [OFScheduler mainScheduler];
    if (typeAheadTimeoutEvent != nil) {
        [scheduler abortEvent:typeAheadTimeoutEvent];
        [typeAheadTimeoutEvent release];
        typeAheadTimeoutEvent = nil;
    }
    typeAheadTimeoutEvent = [[scheduler scheduleSelector:@selector(_typeAheadSearchTimeout) onObject:self afterTime:0.5] retain];

    selectedItem = [_dataSource currentlySelectedItem];

    searchStringLength = [typeAheadSearchString length];
    if (searchStringLength > 1 && [selectedItem length] >= searchStringLength && [selectedItem compare:typeAheadSearchString options:NSCaseInsensitiveSearch range:NSMakeRange(0, searchStringLength)] == NSOrderedSame)
        return; // Avoid flashing a selection all over the place while you're still typing the thing you have selected

    if (flags.cycleResults && selectedItem)
        selectedIndex = [typeAheadSearchCache indexOfObject:selectedItem];
    else
        selectedIndex = NSNotFound;
    foundIndex = [self _indexOfItemWithSubstring:typeAheadSearchString afterIndex:selectedIndex];

    if (foundIndex != NSNotFound)
        [_dataSource typeAheadSelectItemAtIndex:foundIndex];
}

- (int)_indexOfItemWithSubstring:(NSString *)substring afterIndex:(int)selectedIndex
{
    unsigned int labelIndex, foundIndex, labelCount;
    unsigned int substringLength;
    BOOL looped;

    if (typeAheadSearchCache == nil)
        [self rebuildTypeAheadSearchCache];

    substringLength = [substring length];
    labelCount = [typeAheadSearchCache count];
    if (labelCount == 0)
        return NSNotFound;
    if (selectedIndex == NSNotFound)
        selectedIndex = labelCount - 1;

    labelIndex = selectedIndex + 1;
    if (labelIndex == labelCount)
        labelIndex = 0;
    looped = NO;
    while (!looped) {
        NSString *label;
        unsigned int labelLength;

        foundIndex = labelIndex++;
        if (labelIndex == labelCount)
            labelIndex = 0;
        if (labelIndex == selectedIndex + 1 || (labelIndex == 0 && selectedIndex == labelCount - 1))
            looped = YES;
        label = [typeAheadSearchCache objectAtIndex:foundIndex];
        labelLength = [label length];
        if (labelLength < substringLength)
            continue;
        if ([label rangeOfString:substring options:NSCaseInsensitiveSearch].location != NSNotFound)
            return foundIndex;
    }

    return NSNotFound;
}

@end
