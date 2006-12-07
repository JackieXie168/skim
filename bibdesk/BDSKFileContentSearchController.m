//
//  BDSKFileContentSearchController.m
//  BibDesk
//
//  Created by Adam Maxwell on 10/06/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKFileContentSearchController.h"
#import "BibItem.h"
#import "BibPrefController.h"
#import "NSImage+Toolbox.h"
#import <Carbon/Carbon.h>
#import "NSWorkspace_BDSKExtensions.h"
#import "BDSKTextWithIconCell.h"
#import "NSAttributedString_BDSKExtensions.h"
#import "BDSKSearch.h"
#import "BDSKSearchField.h"

// Overrides attributedStringValue since we return an attributed string; normally, the cell uses the font of the attributed string, rather than the table's font, so font changes are ignored.  This means that italics and bold in titles will be lost until the search string changes again, but that's not a great loss.
@interface BDSKFileContentTextWithIconCell : BDSKTextWithIconCell
@end

@implementation BDSKFileContentTextWithIconCell

- (NSAttributedString *)attributedStringValue
{
    NSMutableAttributedString *value = [[super attributedStringValue] mutableCopy];
    [value addAttribute:NSFontAttributeName value:[self font] range:NSMakeRange(0, [value length])];
    return [value autorelease];
}

@end

@implementation BDSKFileContentSearchController

- (id)initForDocument:(id)aDocument
{    
    self = [super init];
    if(!self) return nil;
    
    results = [[NSMutableArray alloc] initWithCapacity:10];
    
    canceledSearch = NO;
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    
    NSParameterAssert([aDocument conformsToProtocol:@protocol(BDSKSearchContentView)]);
    [self setDocument:aDocument];
    
    searchIndex = [[BDSKSearchIndex alloc] initWithDocument:aDocument];
    search = [[BDSKSearch alloc] initWithIndex:searchIndex delegate:self];
    searchFieldDidEndEditing = NO;
    
    return self;
}
    

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [searchContentView release];
    [results release];
    [search release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(tableAction:)];
    
    NSLevelIndicatorCell *cell = [[tableView tableColumnWithIdentifier:@"score"] dataCell];
    OBASSERT([cell isKindOfClass:[NSLevelIndicatorCell class]]);
    [cell setLevelIndicatorStyle:NSRelevancyLevelIndicatorStyle]; // the default one makes the tableview unusably slow
    [cell setEnabled:NO]; // this is required to make it non-editable
    
    // set up the image/text cell combination
    BDSKTextWithIconCell *textCell = [[BDSKFileContentTextWithIconCell alloc] init];
    [textCell setControlSize:[cell controlSize]];
    [textCell setDrawsHighlight:NO];
    [[tableView tableColumnWithIdentifier:@"name"] setDataCell:textCell];
    [textCell release];
    
    OBPRECONDITION([[tableView enclosingScrollView] contentView]);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleClipViewFrameChangedNotification:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:[[tableView enclosingScrollView] contentView]];    

    // Do custom view setup 
    [topBarView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
    [topBarView setEdgeColor:[NSColor windowFrameColor]];
    [topBarView adjustSubviews];

    // we might remove this, so keep a retained reference
    searchContentView = [[[self window] contentView] retain];

    // @@ workaround: the font from prefs seems to be overridden by the nib; maybe bindings issue?
    [tableView changeFont:nil];
    
    [indexProgressBar setMaxValue:100.0];
    [indexProgressBar setMinValue:0.0];
    [indexProgressBar setDoubleValue:[searchIndex progressValue]];
}    

- (NSString *)windowNibName
{
    return @"BDSKFileContentSearch";
}

- (NSView *)searchContentView
{
    if(searchContentView == nil)
        [self window]; // this forces a load of the nib
    return searchContentView;
}

- (NSArray *)titlesOfSelectedItems
{
    return [[resultsArrayController selectedObjects] valueForKey:@"string"];
}

- (void)handleClipViewFrameChangedNotification:(NSNotification *)note
{
    // work around for bug where corner view doesn't get redrawn after scrollers hide
    [[tableView cornerView] setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Actions

- (IBAction)tableAction:(id)sender
{
    int row = [tableView clickedRow];
    if(row == -1)
        return;
    
    BOOL isDir;
    NSURL *fileURL = [[[resultsArrayController arrangedObjects] objectAtIndex:row] URL];
    
    OBASSERT(fileURL);
    OBASSERT(searchField);

    if(![[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDir]){
        NSBeginAlertSheet(NSLocalizedString(@"File Does Not Exist", @"Message in alert dialog when file could not be found"),
                          nil /*default button*/,
                          nil /*alternate button*/,
                          nil /*other button*/,
                          [tableView window],nil,NULL,NULL,NULL,NSLocalizedString(@"The file at \"%@\" no longer exists.", @"Informative text in alert dialog "), [fileURL path]);
    } else if(isDir){
        // just open it with the Finder; we shouldn't have folders in our index, though
        [[NSWorkspace sharedWorkspace] openURL:fileURL];
    } else if(![[NSWorkspace sharedWorkspace] openURL:fileURL withSearchString:[searchField stringValue]]){
        NSBeginAlertSheet(NSLocalizedString(@"Unable to Open File", @"Message in alert dialog when unable to open file"),
                          nil /*default button*/,
                          nil /*alternate button*/,
                          nil /*other button*/,
                          [tableView window],nil,NULL,NULL,NULL,NSLocalizedString(@"I was unable to open the file at \"%@.\"  You may wish to check permissions on the file or directory.", @"Informative text in alert dialog "), [fileURL path]);
    }
}

- (void)setSearchField:(BDSKSearchField *)aSearchField
{
    if (nil != searchField) {
        // disconnect the current searchfield
        [searchField setTarget:nil];
        [searchField setDelegate:nil];  
    }
    
    searchField = aSearchField;
    
    if (nil != searchField) {
        [searchField setTarget:self];
        [searchField setDelegate:self];
        [self search:searchField];
    }     
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    // we get this message with an empty string when committing an edit, or with a non-empty string after clearing the searchfield (use it to see if this was a cancel action so we can handle it slightly differently in search:)
    if ([[aNotification object] isEqual:searchField])
        searchFieldDidEndEditing = YES;
}

- (IBAction)search:(id)sender
{
    if ([NSString isEmptyString:[searchField stringValue]] || [[searchField searchKey] isEqualToString:BDSKFileContentLocalizedString] == NO) {
        // iTunes/Mail swap out their search view when clearing the searchfield, so we follow suit.  If the user clicks the cancel button, we want the searchfield to lose first responder status, but this doesn't happen by default (maybe depends on whether it sends immediately?  Xcode seems to work correctly).  Don't clear the array when restoring document state, since we may need the array controller's selected objects.

        // we get a search: action after the cancel/controlTextDidEndEditing: combination, so see if this was a cancel action
        if (searchFieldDidEndEditing)
            [[searchContentView window] makeFirstResponder:nil];

        [self restoreDocumentState];
    } else {
        
        searchFieldDidEndEditing = NO;
        // empty array; this takes care of updating the table for us
        [self setResults:[NSArray array]];        
        [stopButton setEnabled:YES];
        // set before starting the search, or we can end up updating with it == YES
        canceledSearch = NO;
        
        // may be hidden if we called restoreDocumentState while indexing
        if ([searchIndex isIndexing] && [progressView isHiddenOrHasHiddenAncestor]) {
            [progressView setHidden:NO];
            // setHidden:NO doesn't seem to apply to subviews
            [indexProgressBar setHidden:NO];
        }
        
        [search searchForString:[searchField stringValue] withOptions:kSKSearchOptionDefault];
    }
}

- (void)restoreDocumentState
{
    [self saveSortDescriptors];
    [self cancelCurrentSearch:nil];
    
    // disconnect the searchfield
    [self setSearchField:nil];
    
    // hide this so it doesn't flash during the transition
    [progressView setHidden:YES];
    
    [[self document] restoreDocumentStateByRemovingSearchView:[self searchContentView]];
}

#pragma mark -
#pragma mark Accessors

- (void)setResults:(NSArray *)newResults
{
    if(newResults != results){
        [results release];
        results = [newResults mutableCopy];
    }
}

- (NSMutableArray *)results
{
    return results;
}

- (NSData *)sortDescriptorData
{
    [self window];
    return [NSArchiver archivedDataWithRootObject:[resultsArrayController sortDescriptors]];
}

- (void)setSortDescriptorData:(NSData *)data
{
    [self window];
    [resultsArrayController setSortDescriptors:[NSUnarchiver unarchiveObjectWithData:data]];
}

#pragma mark -
#pragma mark SearchKit methods

- (void)search:(BDSKSearch *)aSearch didUpdateWithResults:(NSArray *)anArray;
{
    if ([search isEqual:aSearch]) {
        
        // don't reset the array
        if (NO == canceledSearch)
            [self setResults:anArray];
        [indexProgressBar setDoubleValue:[searchIndex progressValue]];
    }
}

- (void)search:(BDSKSearch *)aSearch didFinishWithResults:(NSArray *)anArray;
{
    if ([search isEqual:aSearch]) {
        [stopButton setEnabled:NO];
        
        // don't reset the array if we canceled updates
        if (NO == canceledSearch)
            [self setResults:anArray];
        [indexProgressBar setDoubleValue:[searchIndex progressValue]];
        
        // hides progress bar and text
        [progressView setHidden:YES];
    }
}

- (IBAction)cancelCurrentSearch:(id)sender
{
    [search cancel];
    [stopButton setEnabled:NO];
    
    // this will cancel updates to the tableview
    canceledSearch = YES;
}    

#pragma mark -
#pragma mark Document interaction

- (void)stopSearching
{
    // cancel the search
    [self cancelCurrentSearch:nil];
    
    // stops the search index runloop so it will release the document
    [searchIndex cancel];
    [searchIndex release];
    searchIndex = nil;
}

- (void)saveSortDescriptors
{
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[self sortDescriptorData] forKey:BDSKFileContentSearchSortDescriptorKey];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self saveSortDescriptors];
}

- (void)handleApplicationWillTerminate:(NSNotification *)notification
{
    [self saveSortDescriptors];
}

#pragma mark TableView delegate

- (NSString *)tableViewFontNamePreferenceKey:(NSTableView *)tv {
    return BDSKFileContentSearchTableViewFontNameKey;
}

- (NSString *)tableViewFontSizePreferenceKey:(NSTableView *)tv {
    return BDSKFileContentSearchTableViewFontSizeKey;
}

@end
