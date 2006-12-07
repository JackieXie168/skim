//
//  BDSKFileContentSearchController.m
//  BibDesk
//
//  Created by Adam Maxwell on 10/06/05.
/*
 This software is Copyright (c) 2005
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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


#import <Cocoa/Cocoa.h>
#import "BDSKSearchIndex.h"
#import "BDSKEdgeView.h"
#import "BDSKStatusBar.h"

@protocol BDSKSearchContentView <NSObject>
// Single method required by the BDSKSearchContentView protocol; the implementor is responsible for restoring its state by removing the view passed as an argument and resetting search field target/action.  It is sent to the document in response to a search field action with an empty string as search string.

/* Typical setup might go like this, where the searchController is a BDSKFileContentSearchController ivar; the teardown is then performed in restoreDocumentStateByRemovingSearchView:.  Presumably this is just a reversal of the process outlined here, but only the protocol implementor knows how to do it.

    if(fileSearchController == nil){
        fileSearchController = [[BDSKFileContentSearchController alloc] initForDocument:self];
        [NSBundle loadNibNamed:[fileSearchController windowNibName] owner:fileSearchController];
    }

    NSView *contentView = [fileSearchController searchContentView];
    [oldView retain];
    NSRect frame = [oldView frame];
    [contentView setFrame:frame];
    [[oldView superview] replaceSubview:oldView with:contentView];
    [[contentView superview] setNeedsDisplay:YES];

    [searchField setTarget:fileSearchController];
    [searchField setAction:@selector(search:)];
    [searchField setDelegate:fileSearchController];

    // use whatever content is in the searchfield
    [fileSearchController search:searchField];
*/

- (void)restoreDocumentStateByRemovingSearchView:(NSView *)view;
@end

@interface BDSKFileContentSearchController : NSWindowController <BDSKSearchIndexDelegate>
{
    NSMutableArray *results;
    SKSearchRef currentSearch;
    NSNumber *maxValue;
    NSNumber *minValue;
    BDSKSearchIndex *currentSearchIndex;
    NSString *currentSearchKey;
    
    id currentDocument;
        
    IBOutlet NSObjectController *objectController;
    IBOutlet NSArrayController *resultsArrayController;
    IBOutlet NSSearchField *searchField;
    IBOutlet NSTableView *tableView;
    IBOutlet NSProgressIndicator *spinner;
    IBOutlet NSButton *stopButton;
    IBOutlet NSButton *standaloneStopButton;
    NSMutableDictionary *toolbarItems;
    IBOutlet BDSKStatusBar *statusBar;
    
    volatile BOOL searchCanceled;
    CFMutableDictionaryRef indexDictionary;
    NSLock *dictionaryLock;
    
    IBOutlet BDSKEdgeView *topBarView;
    BOOL standalone;
	NSView *searchContentView;
}

// Returns a singleton instance; useful as an inspector of multiple or single documents
+ (BDSKFileContentSearchController *)sharedController;

// Use this method to instantiate a search controller for use within a document window
- (id)initForDocument:(id)aDocument;
// This returns the search content view, suitable for placement inside a document window
- (NSView *)searchContentView;
// This method returns the titles of all selected items (the text content of the rows)
- (NSArray *)titlesOfSelectedItems;

- (void)rebuildResultsWithNewSearch:(NSString *)searchString;
- (void)rebuildResultsWithCurrentString:(NSString *)searchString;
- (void)updateSearchIfNeeded;
- (void)setupToolbar;
- (void)setResults:(NSArray *)newResults;

- (void)saveSortDescriptors;
- (void)cancelCurrentSearch:(id)sender;
- (void)restoreDocumentState:(id)sender;
- (void)setTableFont;
- (void)setMaxValueWithDouble:(double)doubleValue;
- (void)setMinValueWithDouble:(double)doubleValue;

- (IBAction)search:(id)sender;
- (void)tableAction:(id)sender;

- (void)handleDocumentCloseNotification:(NSNotification *)notification;
- (void)handleApplicationWillTerminate:(NSNotification *)notification;
- (void)handleClipViewFrameChangedNotification:(NSNotification *)note;

@end
