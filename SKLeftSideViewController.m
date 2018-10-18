//
//  SKLeftSideViewController.m
//  Skim
//
//  Created by Christiaan Hofman on 3/28/10.
/*
 This software is Copyright (c) 2010-2018
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

#import "SKLeftSideViewController.h"
#import "SKMainWindowController.h"
#import "SKMainWindowController_Actions.h"
#import "SKMainWindowController_UI.h"
#import "NSMenu_SKExtensions.h"
#import "NSSegmentedControl_SKExtensions.h"
#import "SKTypeSelectHelper.h"
#import "SKThumbnailTableView.h"
#import "SKTocOutlineView.h"
#import "SKSourceListTextFieldCell.h"
#import "SKGroupedSearchResult.h"
#import "PDFSelection_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKImageToolTipContext.h"

#define PAGE_COLUMNID      @"page"
#define LABEL_COLUMNID     @"label"
#define RELEVANCE_COLUMNID @"relevance"
#define RESULTS_COLUMNID   @"results"

#define SKDisableTableToolTipsKey @"SKDisableTableToolTips"

@implementation SKLeftSideViewController

@synthesize tocOutlineView, thumbnailArrayController, thumbnailTableView, findArrayController, findTableView, groupedFindArrayController, groupedFindTableView;

- (void)dealloc {
    [thumbnailTableView setDelegate:nil];
    [thumbnailTableView setDataSource:nil];
    [findTableView setDelegate:nil];
    [groupedFindTableView setDelegate:nil];
    [groupedFindTableView setDataSource:nil];
    [tocOutlineView setDelegate:nil];
    [tocOutlineView setDataSource:nil];
    SKDESTROY(thumbnailArrayController);
    SKDESTROY(findArrayController);
    SKDESTROY(groupedFindArrayController);
    SKDESTROY(tocOutlineView);
    SKDESTROY(thumbnailTableView);
    SKDESTROY(findTableView);
    SKDESTROY(groupedFindTableView);
    [super dealloc];
}

- (NSString *)nibName {
    return @"LeftSideView";
}

- (void)loadView {
    [super loadView];
    
    [button setHelp:NSLocalizedString(@"View Thumbnails", @"Tool tip message") forSegment:SKSidePaneStateThumbnail];
    [button setHelp:NSLocalizedString(@"View Table of Contents", @"Tool tip message") forSegment:SKSidePaneStateOutline];
    [alternateButton setHelp:NSLocalizedString(@"Separate search results", @"Tool tip message") forSegment:SKFindPaneStateSingular];
    [alternateButton setHelp:NSLocalizedString(@"Group search results by page", @"Tool tip message") forSegment:SKFindPaneStateGrouped];
    
    NSMenu *menu = [NSMenu menu];
    [menu addItemWithTitle:NSLocalizedString(@"Whole Words Only", @"Menu item title") action:@selector(toggleWholeWordSearch:) target:mainController];
    [menu addItemWithTitle:NSLocalizedString(@"Ignore Case", @"Menu item title") action:@selector(toggleCaseInsensitiveSearch:) target:mainController];
    [[searchField cell] setSearchMenuTemplate:menu];
    [[searchField cell] setPlaceholderString:NSLocalizedString(@"Search", @"placeholder")];
    
    [searchField setAction:@selector(search:)];
    [searchField setTarget:mainController];
    
    if ([tocOutlineView respondsToSelector:@selector(setStronglyReferencesItems:)])
        [tocOutlineView setStronglyReferencesItems:YES];
    
    [tocOutlineView setAutoresizesOutlineColumn: NO];
    
    [tocOutlineView setDelegate:mainController];
    [tocOutlineView setDataSource:mainController];
    [thumbnailTableView setDelegate:mainController];
    [thumbnailTableView setDataSource:mainController];
    [findTableView setDelegate:self];
    [groupedFindTableView setDelegate:self];
    [groupedFindTableView setDataSource:self];
    [[thumbnailTableView menu] setDelegate:mainController];
    [[findTableView menu] setDelegate:mainController];
    [[groupedFindTableView menu] setDelegate:mainController];
    
    [tocOutlineView setDoubleAction:@selector(goToSelectedOutlineItem:)];
    [tocOutlineView setTarget:mainController];
    [findTableView setDoubleAction:@selector(goToSelectedFindResults:)];
    [findTableView setTarget:mainController];
    [groupedFindTableView setDoubleAction:@selector(goToSelectedFindResults:)];
    [groupedFindTableView setTarget:mainController];
    
    [thumbnailTableView setTypeSelectHelper:[SKTypeSelectHelper typeSelectHelperWithMatchOption:SKFullStringMatch]];
    [tocOutlineView setTypeSelectHelper:[SKTypeSelectHelper typeSelectHelperWithMatchOption:SKSubstringMatch]];
    
    [[[findTableView tableColumnWithIdentifier:PAGE_COLUMNID] headerCell] setTitle:NSLocalizedString(@"Page", @"Table header title")];
    [[[groupedFindTableView tableColumnWithIdentifier:PAGE_COLUMNID] headerCell] setTitle:NSLocalizedString(@"Page", @"Table header title")];
    [[[groupedFindTableView tableColumnWithIdentifier:RELEVANCE_COLUMNID] dataCell] setEnabled:NO];
    
    if (RUNNING_AFTER(10_9)) {
        [thumbnailTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
        [(SKSourceListTextFieldCell *)[[thumbnailTableView tableColumnWithIdentifier:PAGE_COLUMNID] dataCell] setSimulatesSourceList:YES];
    }
    
    NSSortDescriptor *countDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKGroupedSearchResultCountKey ascending:NO] autorelease];
    [groupedFindArrayController setSortDescriptors:[NSArray arrayWithObjects:countDescriptor, nil]];
    
    [thumbnailTableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    
    if (NO == [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableTableToolTipsKey]) {
        [tocOutlineView setHasImageToolTips:YES];
        [findTableView setHasImageToolTips:YES];
        [groupedFindTableView setHasImageToolTips:YES];
    }
}

- (BOOL)requiresAlternateButtonForView:(NSView *)aView {
    return [findTableView isDescendantOf:aView] || [groupedFindTableView isDescendantOf:aView];
}

- (void)applySearchTableHeader:(NSString *)message {
    [[[findTableView tableColumnWithIdentifier:RESULTS_COLUMNID] headerCell] setStringValue:message];
    [[findTableView headerView] setNeedsDisplay:YES];
    [[[groupedFindTableView tableColumnWithIdentifier:RELEVANCE_COLUMNID] headerCell] setStringValue:message];
    [[groupedFindTableView headerView] setNeedsDisplay:YES];
}

#pragma mark NSTableView datasource protocol

// AppKit bug: need a dummy NSTableDataSource implementation, otherwise some NSTableView delegate methods are ignored
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv { return 0; }

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row { return nil; }

- (void)tableView:(NSTableView *)tv sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    if ([tv isEqual:groupedFindTableView]) {
        [groupedFindArrayController setSortDescriptors:[tv sortDescriptors]];
    }
}

#pragma mark NSTableView delegate protocol

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if ([[aNotification object] isEqual:findTableView] || [[aNotification object] isEqual:groupedFindTableView]) {
        [mainController selectFindResultHighlight:NSDirectSelection];
    }
}

- (void)tableView:(NSTableView *)tv copyRowsWithIndexes:(NSIndexSet *)rowIndexes {
    if ([tv isEqual:findTableView]) {
        NSMutableString *string = [NSMutableString string];
        NSArray *results = [findArrayController arrangedObjects];
        [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            PDFSelection *match = [results objectAtIndex:idx];
            [string appendString:@"* "];
            [string appendFormat:NSLocalizedString(@"Page %@", @""), [match firstPageLabel]];
            [string appendFormat:@": %@\n", [[match contextString] string]];
        }];
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        [pboard clearContents];
        [pboard writeObjects:[NSArray arrayWithObjects:string, nil]];
    } else if ([tv isEqual:groupedFindTableView]) {
        NSMutableString *string = [NSMutableString string];
        NSArray *results = [groupedFindArrayController arrangedObjects];
        [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            SKGroupedSearchResult *result = [results objectAtIndex:idx];
            NSArray *matches = [result matches];
            [string appendString:@"* "];
            [string appendFormat:NSLocalizedString(@"Page %@", @""), [[result page] displayLabel]];
            [string appendString:@": "];
            [string appendFormat:NSLocalizedString(@"%ld Results", @""), (long)[matches count]];
            [string appendFormat:@":\n\t%@\n", [[matches valueForKeyPath:@"contextString.string"] componentsJoinedByString:@"\n\t"]];
        }];
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        [pboard clearContents];
        [pboard writeObjects:[NSArray arrayWithObjects:string, nil]];
    }
}

- (void)tableViewMoveLeft:(NSTableView *)tv {
    if (([tv isEqual:findTableView] || [tv isEqual:groupedFindTableView])) {
        [mainController selectFindResultHighlight:NSSelectingPrevious];
    }
}

- (void)tableViewMoveRight:(NSTableView *)tv {
    if (([tv isEqual:findTableView] || [tv isEqual:groupedFindTableView])) {
        [mainController selectFindResultHighlight:NSSelectingNext];
    }
}

- (id <SKImageToolTipContext>)tableView:(NSTableView *)tv imageContextForRow:(NSInteger)row {
    if ([tv isEqual:findTableView])
        return [[[findArrayController arrangedObjects] objectAtIndex:row] destination];
    else if ([tv isEqual:groupedFindTableView])
        return [[[[[groupedFindArrayController arrangedObjects] objectAtIndex:row] matches] objectAtIndex:0] destination];
    return nil;
}

@end
