//
//  BibDocument_Search.m
//  Bibdesk
//
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005,2006,2007
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

#import "BibDocument_Search.h"
#import "BibDocument.h"
#import "BibTypeManager.h"
#import <AGRegex/AGRegex.h>
#import "BibItem.h"
#import "CFString_BDSKExtensions.h"
#import "BDSKFieldSheetController.h"
#import "BDSKSplitView.h"
#import "BDSKFileContentSearchController.h"
#import "BDSKGroupTableView.h"
#import "NSTableView_BDSKExtensions.h"
#import "BDSKPublicationsArray.h"
#import "BDSKZoomablePDFView.h"
#import "BDSKPreviewer.h"
#import "BDSKOverlay.h"
#import "BDSKSearchField.h"
#import "BibDocument_Groups.h"
#import "BDSKMainTableView.h"

NSString *BDSKDocumentFormatForSearchingDates = nil;

@implementation BibDocument (Search)

+ (void)didLoad{
    BDSKDocumentFormatForSearchingDates = [[[NSUserDefaults standardUserDefaults] objectForKey:NSShortDateFormatString] copy];
}

- (IBAction)makeSearchFieldKey:(id)sender{

    NSToolbar *tb = [documentWindow toolbar];
    [tb setVisible:YES];
    if([tb displayMode] == NSToolbarDisplayModeLabelOnly)
        [tb setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    
	[documentWindow makeFirstResponder:searchField];
    [searchField selectText:sender];
}

- (NSString *)searchString {
	return [searchField stringValue];
}

- (void)setSearchString:(NSString *)filterterm {
    NSParameterAssert(filterterm != nil);
    if([[searchField stringValue] isEqualToString:filterterm] == NO){
        [searchField setStringValue:filterterm];
        [searchField sendAction:[searchField action] to:[searchField target]];
    }
}

- (IBAction)search:(id)sender{
    if([[searchField searchKey] isEqualToString:BDSKFileContentLocalizedString])
        [self searchByContent:sender];
    else
        [self filterPublicationsUsingSearchString:[searchField stringValue] inField:[searchField searchKey]];
}

#pragma mark -

- (void)filterPublicationsUsingSearchString:(NSString *)searchString inField:(NSString *)field{
	NSArray *pubsToSelect = [self selectedPublications];

    if([NSString isEmptyString:searchString]){
        [shownPublications setArray:groupedPublications];
    }else{
		[shownPublications setArray:[self publicationsMatchingSearchString:searchString inField:field fromArray:groupedPublications]];
		if([shownPublications count] == 1)
			pubsToSelect = [NSMutableArray arrayWithObject:[shownPublications lastObject]];
	}
	
	[tableView deselectAll:nil];
    // @@ performance: this kills us on large files, since it gets called for every updateCategoryGroupsPreservingSelection (any add/del)
	[self sortPubsByKey:nil]; // resort
	[self updateStatus];
	if([pubsToSelect count])
		[self selectPublications:pubsToSelect];
}
        
- (NSArray *)publicationsMatchingSearchString:(NSString *)searchString inField:(NSString *)field fromArray:(NSArray *)arrayToSearch{
    
    unsigned searchMask = NSCaseInsensitiveSearch;
    if([searchString rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location != NSNotFound)
        searchMask = 0;
    BOOL doLossySearch = YES;
    if(BDStringHasAccentedCharacters((CFStringRef)searchString))
        doLossySearch = NO;
        
    static NSSet *dateFields = nil;
    if(nil == dateFields)
        dateFields = [[NSSet alloc] initWithObjects:BDSKDateString, BDSKDateAddedString, BDSKDateModifiedString, nil];
    
    // if it's a date field, figure out a format string to use based on the given date component(s)
    // this date format string is then made available to the BibItem as a global variable
    // don't convert searchString->date->string, though, or it's no longer a substring and will only match exactly
    if([dateFields containsObject:field]){
        [BDSKDocumentFormatForSearchingDates release];
        BDSKDocumentFormatForSearchingDates = [[[NSUserDefaults standardUserDefaults] objectForKey:NSShortDateFormatString] copy];
        if(nil == [NSCalendarDate dateWithString:searchString calendarFormat:BDSKDocumentFormatForSearchingDates]){
            [BDSKDocumentFormatForSearchingDates release];
            BDSKDocumentFormatForSearchingDates = [[[NSUserDefaults standardUserDefaults] objectForKey:NSDateFormatString] copy];
        }
    }
    
    NSMutableSet *aSet = [NSMutableSet setWithCapacity:10];
    NSArray *searchComponents = [searchString searchComponents], *andSearchComponents;
    
    if([searchComponents count] == 0)
        return arrayToSearch;
    
    int i, j, k, pubCount = [arrayToSearch count], orCount = [searchComponents count], andCount;
    BibItem *pub;
    BOOL match;
    
    // the searchComponents is an array of OR-ed conditions, each one being an array of AND-ed conditions
    // e.g. ((a),(b,c)) is interpreted as (a || ( b && c) )
    
    // cache the IMP for the BibItem search method, since we're potentially calling it several times per item
    typedef BOOL (*searchIMP)(id, SEL, id, unsigned int, id, BOOL);
    SEL matchSelector = @selector(matchesSubstring:withOptions:inField:removeDiacritics:);
    searchIMP itemMatches = (searchIMP)[BibItem instanceMethodForSelector:matchSelector];
    OBASSERT(NULL != itemMatches);
    
    for(i = 0; i < pubCount; i++){
        pub = [arrayToSearch objectAtIndex:i];
        
        for(j = 0; j < orCount; j++){
            andSearchComponents = [searchComponents objectAtIndex:j];
            andCount = [andSearchComponents count];
            match = YES;
            for(k = 0; k < andCount; k++){
                if(itemMatches(pub, matchSelector, [andSearchComponents objectAtIndex:k], searchMask, field, doLossySearch) == NO){
                    // doesn't match, this OR case will be ignored
                    match = NO;
                    break;
                }
            }
            if(match){
                // a full series of AND conditions for an OR condition matched, so we have match
                [aSet addObject:pub];        
                break;
            }
        }
    }
    
    return [aSet allObjects];
}

#pragma mark File Content Search

- (IBAction)searchByContent:(id)sender
{
    // Normal search if the fileSearchController is not present and the searchstring is empty, since the searchfield target has apparently already been reset (I think).  Fixes bug #1341802.
    OBASSERT(searchField != nil && [searchField target] != nil);
    if([searchField target] == self && [NSString isEmptyString:[searchField stringValue]]){
        [self filterPublicationsUsingSearchString:[searchField stringValue] inField:[searchField searchKey]];
        return;
    }
    
    // @@ File content search isn't really compatible with the group concept yet; this allows us to select publications when the content search is done, and also provides some feedback to the user that all pubs will be searched.  This is ridiculously complicated since we need to avoid calling searchByContent: in a loop.
    [tableView deselectAll:nil];
    [groupTableView updateHighlights];
    
    // here we avoid the table selection change notification that will result in an endless loop
    id tableDelegate = [groupTableView delegate];
    [groupTableView setDelegate:nil];
    [groupTableView deselectAll:nil];
    [groupTableView setDelegate:tableDelegate];
    
    // this is what displaySelectedGroup normally ends up doing
    [self handleGroupTableSelectionChangedNotification:nil];
    [self sortPubsByKey:nil];
    
    if(fileSearchController == nil){
        fileSearchController = [[BDSKFileContentSearchController alloc] initForDocument:self];
        NSData *sortDescriptorData = [[self mainWindowSetupDictionaryFromExtendedAttributes] objectForKey:BDSKFileContentSearchSortDescriptorKey defaultObject:[[NSUserDefaults standardUserDefaults] dataForKey:BDSKFileContentSearchSortDescriptorKey]];
        if(sortDescriptorData)
            [fileSearchController setSortDescriptorData:sortDescriptorData];
    }
    
    NSView *contentView = [fileSearchController searchContentView];
    NSRect frame = [splitView frame];
    [contentView setFrame:frame];
    [contentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [mainBox addSubview:contentView];
    
    NSViewAnimation *animation;
    NSDictionary *fadeOutDict = [[NSDictionary alloc] initWithObjectsAndKeys:splitView, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
    NSDictionary *fadeInDict = [[NSDictionary alloc] initWithObjectsAndKeys:contentView, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];

    animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeOutDict, fadeInDict, nil]] autorelease];
    [fadeOutDict release];
    [fadeInDict release];
    
    [animation setAnimationBlockingMode:NSAnimationNonblockingThreaded];
    [animation setDuration:0.75];
    [animation setAnimationCurve:NSAnimationEaseIn];
    [animation setDelegate:self];
    [animation startAnimation];
}

- (void)finishAnimation
{
    if([splitView isHidden]){
        
        [[previewer progressOverlay] remove];
        
        [splitView removeFromSuperview];
        // connect the searchfield to the controller and start the search
        [fileSearchController setSearchField:searchField];
        
    } else {
        
        // reconnect the searchfield
        [searchField setTarget:self];
        [searchField setDelegate:self];
        
        NSArray *titlesToSelect = [fileSearchController titlesOfSelectedItems];
        
        if([titlesToSelect count]){
            
            // clear current selection (just in case)
            [tableView deselectAll:nil];
            
            // we match based on title, since that's all the index knows about the BibItem at present
            NSMutableArray *pubsToSelect = [NSMutableArray array];
            NSEnumerator *pubEnum = [shownPublications objectEnumerator];
            BibItem *item;
            while(item = [pubEnum nextObject])
                if([titlesToSelect containsObject:[item displayTitle]]) 
                    [pubsToSelect addObject:item];
            [self selectPublications:pubsToSelect];
            [tableView scrollRowToCenter:[tableView selectedRow]];
            
            // if searchfield doesn't have focus (user clicked cancel button), switch to the tableview
            if ([[documentWindow firstResponder] isEqual:[searchField currentEditor]] == NO)
                [documentWindow makeFirstResponder:(NSResponder *)tableView];
        }
        
    }
}

// use the delegate method so we don't remove the view too early, but this must be done on the main thread
- (void)animationDidEnd:(NSAnimation*)animation
{
    [self performSelectorOnMainThread:@selector(finishAnimation) withObject:nil waitUntilDone:NO];
}

// Method required by the BDSKSearchContentView protocol; the implementor is responsible for restoring its state by removing the view passed as an argument and resetting search field target/action.
- (void)_restoreDocumentStateByRemovingSearchView:(NSView *)view
{
    
    NSRect frame = [view frame];
    [splitView setFrame:frame];
    [mainBox addSubview:splitView];
    
    if(currentPreviewView != [previewTextView enclosingScrollView])
        [[previewer progressOverlay] overlayView:currentPreviewView];
    
    NSViewAnimation *animation;
    NSDictionary *fadeOutDict = [[NSDictionary alloc] initWithObjectsAndKeys:view, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
    NSDictionary *fadeInDict = [[NSDictionary alloc] initWithObjectsAndKeys:splitView, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
    
    animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeOutDict, fadeInDict, nil]] autorelease];
    [fadeOutDict release];
    [fadeInDict release];
    
    [animation setAnimationBlockingMode:NSAnimationNonblockingThreaded];
    [animation setDuration:0.75];
    [animation setAnimationCurve:NSAnimationEaseIn];
    [animation setDelegate:self];
    [animation startAnimation];
}

#pragma mark Find panel

- (NSString *)selectedStringForFind {
    if([currentPreviewView isKindOfClass:[NSScrollView class]]){
        NSTextView *textView = (NSTextView *)[(NSScrollView *)currentPreviewView documentView];
        NSRange selRange = [textView selectedRange];
        if (selRange.location == NSNotFound)
            return nil;
        return [[textView string] substringWithRange:selRange];
    }else if([currentPreviewView isKindOfClass:[BDSKZoomablePDFView class]]){
        return [[(BDSKZoomablePDFView *)currentPreviewView currentSelection] string];
    }
    return nil;
}

- (IBAction)performFindPanelAction:(id)sender{
    NSString *selString = nil;
    NSPasteboard *findPasteboard;

	switch ([sender tag]) {
		case NSFindPanelActionShowFindPanel:
            [self makeSearchFieldKey:sender];
            break;
		case NSFindPanelActionSetFindString:
            selString = nil;
            findPasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
            if ([findPasteboard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]])
                selString = [findPasteboard stringForType:NSStringPboardType];    
            if ([NSString isEmptyString:selString] == NO)
                [searchField setStringValue:selString];
            [searchField selectText:nil];
            break;
        default:
            NSBeep();
            break;
	}
}

@end
