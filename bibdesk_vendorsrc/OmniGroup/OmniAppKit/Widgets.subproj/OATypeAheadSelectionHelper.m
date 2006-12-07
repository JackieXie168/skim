// Copyright 2001-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OATypeAheadSelectionHelper.h"

#import <Foundation/Foundation.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATypeAheadSelectionHelper.m 68913 2005-10-03 19:36:19Z kc $");

@interface OATypeAheadSelectionHelper (Private)
- (void)_typeAheadSearchTimeout;
- (int)_indexOfItemWithPrefix:(NSString *)prefix afterIndex:(unsigned int)selectedIndex;
@end

@implementation OATypeAheadSelectionHelper

// Init and dealloc

- init;
{
    if (![super init])
        return nil;

    return self;
}

- (void)dealloc;
{
    [self _typeAheadSearchTimeout];
    [typeAheadSearchCache release];
    [super dealloc];
}


// API
- (id)dataSource;
{
    return _dataSource;
}

- (void)setDataSource:(id)newDataSource;
{
    if (_dataSource == newDataSource)
        return;
    
    _dataSource = newDataSource;
    [self rebuildTypeAheadSearchCache];
}

- (BOOL)cyclesSimilarResults;
{
    return flags.cycleResults;
}

- (void)setCyclesSimilarResults:(BOOL)newValue;
{
    flags.cycleResults = newValue;
}

- (void)rebuildTypeAheadSearchCache;
{    
    if (typeAheadSearchCache)
        [typeAheadSearchCache release];
    
    typeAheadSearchCache = [[_dataSource typeAheadSelectionItems] retain];
}

- (void)processKeyDownCharacter:(unichar)character;
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
    foundIndex = [self _indexOfItemWithPrefix:typeAheadSearchString afterIndex:selectedIndex];
    
    if (foundIndex != NSNotFound)
        [_dataSource typeAheadSelectItemAtIndex:foundIndex];
}

- (BOOL)isProcessing;
{
    return typeAheadTimeoutEvent != nil;
}

@end

@implementation OATypeAheadSelectionHelper (Private)

- (void)_typeAheadSearchTimeout;
{
    [typeAheadTimeoutEvent release];
    typeAheadTimeoutEvent = nil;
    [typeAheadSearchString release];
    typeAheadSearchString = nil;
}

// TODO: extend this algorithm so it will select the next item alphabetically if there is not an exact match, like Finder does
- (int)_indexOfItemWithPrefix:(NSString *)prefix afterIndex:(unsigned int)selectedIndex;
{
    unsigned int labelIndex, foundIndex, labelCount;
    unsigned int prefixLength;
    BOOL looped;

    if (typeAheadSearchCache == nil)
        [self rebuildTypeAheadSearchCache];

    prefixLength = [prefix length];
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
        if (labelLength < prefixLength)
            continue;
        if ([label compare:prefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, prefixLength)] == NSOrderedSame)
            return foundIndex;
    }
    
    return NSNotFound;
}

@end
