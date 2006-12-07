//
//  OATypeAheadSelectionHelper_Extensions.m
//  BibDesk
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005,2006
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

#import "OATypeAheadSelectionHelper_Extensions.h"
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/NSMutableString-OFExtensions.h>

@interface OATypeAheadSelectionHelper (BDSKPrivate)
- (void)_replacementDealloc;
- (void)_replacementTypeAheadSearchTimeout;
- (int)_indexOfItemWithSubstring:(NSString *)substring afterIndex:(unsigned int)selectedIndex;
@end

@interface OATypeAheadSelectionHelper (OmniPrivate)
// this is in Omni's implementation
- (void)_typeAheadSearchTimeout;
- (int)_indexOfItemWithPrefix:(NSString *)prefix afterIndex:(unsigned int)selectedIndex;
@end

// Use to implement a display like OmniWeb's when you start typing a link title; we should probably just use our own subclass here
@interface NSObject (BDSKTypeAheadProtocolExtensions)
- (void)updateTypeAheadStatus:(NSString *)searchString;
@end

static IMP originalTypeAheadSearchTimeoutIMP;
static IMP originalDeallocIMP;

@implementation OATypeAheadSelectionHelper (BDSKPrivate)

+ (void)performPosing
{
    originalTypeAheadSearchTimeoutIMP = OBReplaceMethodImplementationWithSelector(self, @selector(_typeAheadSearchTimeout), @selector(_replacementTypeAheadSearchTimeout));
    originalDeallocIMP = OBReplaceMethodImplementationWithSelector(self, @selector(dealloc), @selector(_replacementDealloc));
}

- (void)_replacementDealloc{
    // set the datasource to nil, since the original dealloc calls _replacementTypeAheadSearchTimeout (which messages the datasource)
    [self setDataSource:nil];
    originalDeallocIMP(self, _cmd);
}

- (void)_replacementTypeAheadSearchTimeout{
    if([_dataSource respondsToSelector:@selector(updateTypeAheadStatus:)])
        [_dataSource updateTypeAheadStatus:nil];
    originalTypeAheadSearchTimeoutIMP(self, _cmd);
}

- (int)_indexOfItemWithSubstring:(NSString *)substring afterIndex:(unsigned int)selectedIndex
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
        int location;

        foundIndex = labelIndex++;
        if (labelIndex == labelCount)
            labelIndex = 0;
        if (labelIndex == selectedIndex + 1 || (labelIndex == 0 && selectedIndex == labelCount - 1))
            looped = YES;
        label = [typeAheadSearchCache objectAtIndex:foundIndex];
        labelLength = [label length];
        if (labelLength < substringLength)
            continue;
        location = [label rangeOfString:substring options:NSCaseInsensitiveSearch].location;
        if (location != NSNotFound) {
            if (location == 0 || [[NSCharacterSet letterCharacterSet] characterIsMember:[label characterAtIndex:location - 1]] == NO)
                return foundIndex;
        }
    }

    return NSNotFound;
}

@end

@implementation OATypeAheadSelectionHelper (BDSKExtensions)

- (void)prefixProcessKeyDownCharacter:(unichar)character;
{
    [self processKeyDownCharacter:character matchPrefix:YES];
}

- (void)substringProcessKeyDownCharacter:(unichar)character;
{
    [self processKeyDownCharacter:character matchPrefix:NO];
}

- (void)processKeyDownCharacter:(unichar)character matchPrefix:(BOOL)matchPrefix;
{
    OFScheduler *scheduler;
    NSString *selectedItem;
    int selectedIndex, foundIndex;
    unsigned int searchStringLength;
    unsigned int selectedItemLength;
    NSRange range;

    OBPRECONDITION(_dataSource != nil);

    // Create the search string the first time around
    if (typeAheadSearchString == nil)
        typeAheadSearchString = [[NSMutableString alloc] init];

    // Append the new character to the search string
    [typeAheadSearchString appendCharacter:character];
    
    if([_dataSource respondsToSelector:@selector(updateTypeAheadStatus:)])
        [_dataSource updateTypeAheadStatus:typeAheadSearchString];

    // Reset the timer if it hasn't expired yet
    scheduler = [OFScheduler mainScheduler];
    if (typeAheadTimeoutEvent != nil) {
        [scheduler abortEvent:typeAheadTimeoutEvent];
        [typeAheadTimeoutEvent release];
        typeAheadTimeoutEvent = nil;
    }
    typeAheadTimeoutEvent = [[scheduler scheduleSelector:@selector(_typeAheadSearchTimeout) onObject:self afterTime:0.7] retain];

    selectedItem = [_dataSource currentlySelectedItem];

    searchStringLength = [typeAheadSearchString length];
    selectedItemLength = [selectedItem length];
    
    // The Omni implementation of this looks for a prefix; we might be searching for a substring
    range = NSMakeRange(0, matchPrefix ? searchStringLength : selectedItemLength);
    if (searchStringLength > 1 && selectedItemLength >= searchStringLength && [selectedItem containsString:typeAheadSearchString options:NSCaseInsensitiveSearch range:range])
        return; // Avoid flashing a selection all over the place while you're still typing the thing you have selected

    if (flags.cycleResults && selectedItem)
        selectedIndex = [typeAheadSearchCache indexOfObject:selectedItem];
    else
        selectedIndex = NSNotFound;
    if (matchPrefix)
        foundIndex = [self _indexOfItemWithPrefix:typeAheadSearchString afterIndex:selectedIndex];
    else
        foundIndex = [self _indexOfItemWithSubstring:typeAheadSearchString afterIndex:selectedIndex];

    if (foundIndex != NSNotFound)
        [_dataSource typeAheadSelectItemAtIndex:foundIndex];
}

@end
