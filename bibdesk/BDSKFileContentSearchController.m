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

#import "BDSKFileContentSearchController.h"
#import "BibItem.h"
#import "BibPrefController.h"
#import "NSImage+Toolbox.h"
#import <Carbon/Carbon.h>
#import "BDSKSearchResult.h"
#import "NSWorkspace_BDSKExtensions.h"

NSString *FileContentSearchToolbarIdentifier = @"FileContentSearchToolbarIdentifier";
NSString *StopButtonToolbarItemIdentifier = @"StopButtonToolbarItemIdentifier";
NSString *ProgressSpinnerToolbarItemIdentifier = @"ProgressSpinnerToolbarItemIdentifier";
NSString *SearchFieldToolbarItemIdentifier = @"SearchFieldToolbarItemIdentifier";

static BDSKFileContentSearchController *theController = nil;

// keys are NSDocument objects; compare using pointer equality, use NSObject retain/release
const CFDictionaryKeyCallBacks BDSKNSRetainedPointerDictionaryKeyCallbacks = {
    0,    // version
    OFNSObjectRetain,  // retain
    OFNSObjectRelease, // release
    OFNSObjectCopyDescription,
    NULL, // equal (use pointer equality): note that KVO isa-swizzling will cause grief here if we aren't careful
    NULL, // hash  (hash of pointer)
};

// values are NSObject subclass instances
const CFDictionaryValueCallBacks BDSKNSRetainedPointerDictionaryValueCallbacks = {
    0,    // version
    OFNSObjectRetain,  // retain
    OFNSObjectRelease, // release
    OFNSObjectCopyDescription,
    NULL, // equal (use pointer equality)
};

@implementation BDSKFileContentSearchController

+ (BDSKFileContentSearchController *)sharedController
{
    if (!theController) {
        theController = [[BDSKFileContentSearchController alloc] init];
    }
    return theController;
}

- (id)init
{    
    [super init];
    if(!self) return nil;
    
    [self setMaxValueWithDouble:0];
    [self setMinValueWithDouble:0];
    
    // this is a pointer to the current index; retained only by the indexDictionary
    currentSearchIndex = nil;
    
    results = [[NSMutableArray alloc] initWithCapacity:10];
    
    currentSearchKey = [[NSString alloc] initWithString:@""];
    
    // to be used for storing references to documents and associated index/mutable data objects
    indexDictionary = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &BDSKNSRetainedPointerDictionaryKeyCallbacks, &BDSKNSRetainedPointerDictionaryValueCallbacks);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentCloseNotification:) name:BDSKDocumentWindowWillCloseNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setTableFont) name:BDSKTableViewFontChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    
    // this lock is used any time the mutable indexDictionary ivar is accessed
    dictionaryLock = [[NSLock alloc] init];
    
    // flag set from UI or before deallocating the current index
    searchCanceled = NO;
    standalone = YES;
    
    searchContentView = nil;
        
    return self;
}

- (id)initForDocument:(id)aDocument
{
    if([self init] == nil)
        return nil;
 
    OBPRECONDITION(aDocument);
    standalone = NO;
    [self setDocument:aDocument];
    
    // don't observe this, since all we use it for is to change the document
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:nil];
    NSAssert1([NSBundle loadNibNamed:[self windowNibName] owner:self], @"Failed to load nib %@", [self windowNibName]);

    return self;
}
    

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelCurrentSearch:nil]; // before releasing the dictionary
    [searchContentView release];
    [toolbarItems release];
    CFRelease(indexDictionary);
    [dictionaryLock release];
    [results release];
    if(currentSearch) CFRelease(currentSearch);
    [currentSearchKey release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [objectController setContent:self];
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(tableAction:)];
    
    NSLevelIndicatorCell *cell = [[tableView tableColumnWithIdentifier:@"score"] dataCell];
    OBASSERT([cell isKindOfClass:[NSLevelIndicatorCell class]]);
    [cell setLevelIndicatorStyle:NSRelevancyLevelIndicatorStyle]; // the default one makes the tableview unusably slow
    [cell setEnabled:NO]; // this is required to make it non-editable
    
    [(standalone ? standaloneSpinner : spinner) setUsesThreadedAnimation:NO];
    [(standalone ? standaloneSpinner : spinner) setDisplayedWhenStopped:NO];
    
    // Make sure we get a window title and document, even though our window will be front when we open; this causes problems for the non-standalone case, obviously, if the the doc controller returns nil for current document.
    if(standalone)
        [self setDocument:[[NSDocumentController sharedDocumentController] currentDocument]];
    
    // set up the image/text cell combination
    OATextWithIconCell *textCell = [[OATextWithIconCell alloc] init];
    [textCell setControlSize:[cell controlSize]];
    [textCell setDrawsHighlight:NO];
    [[tableView tableColumnWithIdentifier:@"name"] setDataCell:textCell];
    [textCell release];
    
    [self setTableFont];
    [self setupToolbar];
    [[self window] makeFirstResponder:searchField];
    
    // preserve sort behavior between launches (set in windowWillClose:)
    NSData *sortDescriptorData = [[OFPreferenceWrapper sharedPreferenceWrapper] dataForKey:BDSKFileContentSearchSortDescriptorKey];
    if(sortDescriptorData != nil)
        [resultsArrayController setSortDescriptors:[NSUnarchiver unarchiveObjectWithData:sortDescriptorData]];
    
    OBPRECONDITION([[tableView enclosingScrollView] contentView]);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleClipViewFrameChangedNotification:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:[[tableView enclosingScrollView] contentView]];    

    NSRect frame = [[tableView enclosingScrollView] frame];

    if(standalone == YES){
        frame.size.height += NSHeight([gradientView frame]) + 1;
        [[gradientView retain] removeFromSuperview];
        [[tableView enclosingScrollView] setFrame:frame];
    } else {
        // unable to set box properly in code, for some reason; retain/release manually, since the window won't retain it for us
        [searchContentView retain];
        [searchContentView setContentView:[[self window] contentView]];
    }        

}    

- (NSString *)windowNibName
{
    return @"BDSKFileContentSearch";
}

- (NSView *)searchContentView
{
    return searchContentView;
}

- (NSArray *)titlesOfSelectedItems
{
    NSArray *selectedObjects = [resultsArrayController selectedObjects];
    BDSKSearchResult *result;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[selectedObjects count]];
    NSEnumerator *selEnum = [selectedObjects objectEnumerator];
    
    while(result = [selEnum nextObject])
        [array addObject:[result valueForKey:OATextWithIconCellStringKey]];
    
    return array;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
    
    if([aCell isKindOfClass:[OATextWithIconCell class]])
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
}

- (void)handleClipViewFrameChangedNotification:(NSNotification *)note
{
    // work around for bug where corner view doesn't get redrawn after scrollers hide
    [[tableView cornerView] setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Actions

- (void)tableAction:(id)sender
{
    int row = [tableView selectedRow];
    if(row == -1)
        return;
    
    BOOL isDir;
    NSURL *fileURL = [[[resultsArrayController arrangedObjects] objectAtIndex:row] valueForKey:@"url"];
    
    OBASSERT(fileURL);
    OBASSERT(currentSearchKey);

    if(![[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDir]){
        NSBeginAlertSheet(NSLocalizedString(@"File Does Not Exist", @""),
                          nil /*default button*/,
                          nil /*alternate button*/,
                          nil /*other button*/,
                          [tableView window],nil,NULL,NULL,NULL,NSLocalizedString(@"The file at \"%@\" no longer exists.", @""), [fileURL path]);
        return;
    } else if(isDir){
        // just open it with the Finder; we shouldn't have folders in our index, though
        [[NSWorkspace sharedWorkspace] openURL:fileURL];
        return;
    } else if(![[NSWorkspace sharedWorkspace] openURL:fileURL withSearchString:currentSearchKey]){
        NSBeginAlertSheet(NSLocalizedString(@"Unable to Open File", @""),
                          nil /*default button*/,
                          nil /*alternate button*/,
                          nil /*other button*/,
                          [tableView window],nil,NULL,NULL,NULL,NSLocalizedString(@"I was unable to open the file at \"%@.\"  You may wish to check permissions on the file or directory.", @""), [fileURL path]);
        return;
    }
}

- (BOOL)hasIndexForCurrentDocument
{
    id document = [self document];
    OBASSERT(document);
    
    if(!document) return NO;
    
    if(CFDictionaryGetValueIfPresent(indexDictionary, document, (const void **)&currentSearchIndex))
        return YES;
    
    currentSearchIndex = [[BDSKSearchIndex alloc] initWithDocument:document];
    [currentSearchIndex setDelegate:self];
    CFDictionaryAddValue(indexDictionary, document, currentSearchIndex);
    [currentSearchIndex release];
    
    return YES;
}

- (IBAction)search:(id)sender
{
    [currentSearchKey autorelease];
    currentSearchKey = [[sender stringValue] copy];
    
    if(![self hasIndexForCurrentDocument]){
        [self setResults:[NSArray array]];
        return;
    }
    
    searchCanceled = NO;    
    [self rebuildResultsWithNewSearch:currentSearchKey];
}

- (void)updateSearchIfNeeded
{
    if(![[self window] isVisible] || [currentSearchKey isEqualToString:@""] || [self document] == nil)
        return;
    
    [self rebuildResultsWithNewSearch:currentSearchKey];
}

- (void)restoreDocumentState:(id)sender
{
    [self saveSortDescriptors];
    [self cancelCurrentSearch:nil];
    [[self document] restoreDocumentStateByRemovingSearchView:searchContentView];
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

- (void)setMaxValueWithDouble:(double)doubleValue
{
    [maxValue autorelease];
    maxValue = [[NSNumber alloc] initWithDouble:doubleValue];
}

- (void)setMinValueWithDouble:(double)doubleValue
{
    [minValue autorelease];
    minValue = [[NSNumber alloc] initWithDouble:doubleValue];
}

- (NSNumber *)maxValue
{
    return maxValue;
}

- (NSNumber *)minValue
{
    return minValue;
}

#pragma mark -
#pragma mark SearchKit methods

- (void)cancelCurrentSearch:(id)sender
{
    OBASSERT([NSThread inMainThread]);
    
    if(currentSearch != NULL){
        SKSearchCancel(currentSearch);
        CFRelease(currentSearch);
        currentSearch = NULL;
    }
    // @@ hack: this is required since we're using a delayed perform to re-search, which sets searchCanceled to NO
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    searchCanceled = YES;
    [(standalone ? standaloneSpinner : spinner) stopAnimation:nil];
}    

- (void)rebuildResultsWithNewSearch:(NSString *)searchString
{        
    OBASSERT([NSThread inMainThread]);
    
    if([NSString isEmptyString:searchString]){
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [(standalone ? standaloneSpinner : spinner) stopAnimation:self];
        // for use in an external window: iTunes/Mail swap out their search view when clearing the searchfield. don't clear the array, though, since we may need the array controller's selected objects
        if(standalone == NO)
            [self restoreDocumentState:self];
        else
            [self setResults:[NSArray array]];
        return;
    }
    
    // empty array; this takes care of updating the table for us
    [self setResults:[NSArray array]];

    [(standalone ? standaloneSpinner : spinner) startAnimation:self];
    
    SKIndexRef index = [currentSearchIndex index];
        
    // flushing a null index will cause a crash, so wait until the index is created
    if(index == NULL){
        [self performSelector:_cmd withObject:searchString afterDelay:0.1];
        return;
    }
    [(standalone ? standaloneStopButton : stopButton) setEnabled:YES];
    [self setMaxValueWithDouble:0];
    [self setMinValueWithDouble:0];
    [self rebuildResultsWithCurrentString:searchString];
}

- (void)rebuildResultsWithCurrentString:(NSString *)searchString
{
    
    if(currentSearch != NULL){
        SKSearchCancel(currentSearch);
        CFRelease(currentSearch);
        currentSearch = NULL;
    }
    
    SKIndexRef index = [currentSearchIndex index];
    
    NSAssert(index != NULL, @"Attempt to flush a null index");
    SKIndexFlush(index);
    
    // While we're indexing, we need to create a new search object every time we update, or else no new results show up.
    currentSearch = SKSearchCreate(index, (CFStringRef)searchString, kSKSearchOptionDefault);

    // Prepare for all of the documents in the index to match; alternately, we could fetch them incrementally if(incomplete == TRUE)
    CFIndex maxResults = SKIndexGetDocumentCount(index);
    
    NSZone *zone = [self zone];
    
    SKDocumentID *documentIDs = (SKDocumentID *)NSZoneCalloc(zone, maxResults, sizeof(SKDocumentID));
    float *scores = (float *)NSZoneCalloc(zone, maxResults, sizeof(float));
    CFIndex actualResults = 0;
    
    Boolean incomplete = SKSearchFindMatches(currentSearch, maxResults, documentIDs, scores, 10, &actualResults);
    OBASSERT(incomplete == FALSE);
    
    if(actualResults > 0){
    
        SKDocumentRef *skDocuments = (SKDocumentRef *)NSZoneCalloc(zone, actualResults, sizeof(SKDocumentRef));
        SKIndexCopyDocumentRefsForDocumentIDs(index, actualResults, documentIDs, skDocuments);

        NSMutableSet *newResults = [[NSMutableSet alloc] initWithCapacity:actualResults];
        
        BDSKSearchResult *searchResult;
        SKDocumentRef skDocument;
        CFURLRef url;
        
        // level indicator value is supposed to be a float, so we don't have to change the type
        float score;
        
        // level indicator min/max values are supposed to be doubles
        double tmpMax = [maxValue doubleValue];
        double tmpMin = [minValue doubleValue];
        NSString *pathKey;
        
        // get a pointer we can safely increment, since we need to free this memory later, so we need to keep a pointer to the beginning of each array
        float *scoreIdx = scores;
        SKDocumentRef *skDocumentIdx = skDocuments;
        CFDictionaryRef properties;
        NSString *title;
        
        while(searchCanceled == NO && actualResults--){
            
            // get the next URL from the array
            skDocument = *skDocumentIdx++;
            OBASSERT(skDocument);
            
            url = SKDocumentCopyURL(skDocument);
            OBASSERT(url);
            
            // the table column is bound to the dictionary with an empty key path; the OATextIconCell is smart enough to recognize that it has a dictionary object value and ask for its keys
            
            // two files can't have the same path, so this should be a reasonable key for uniqueness testing
            pathKey = [(NSURL *)url path];
            searchResult = [[BDSKSearchResult alloc] initWithKey:pathKey];
            
            [searchResult setValue:(NSURL *)url forKey:@"url"];
            [searchResult setValue:[NSImage imageForURL:(NSURL *)url] forKey:OATextWithIconCellImageKey];
            CFRelease(url);
            
            // get our custom properties so we can display the item's title in the table, if possible
            properties = SKIndexCopyDocumentProperties(index, skDocument);
            if(properties == NULL || CFDictionaryGetValueIfPresent(properties, CFSTR("title"), (const void **)&title) == FALSE)
                title = pathKey;
            OBASSERT(pathKey);
            
            [searchResult setValue:title forKey:OATextWithIconCellStringKey];
            if(properties) CFRelease(properties);
            CFRelease(skDocument);
            
            // get the next score from the array; @@ hopefully the URL and score correspond, although it's not clear from the documentation
            score = *scoreIdx++;
            
            // these scores are arbitrarily scaled, so we'll keep track of the search kit's max/min values
            tmpMax = MAX(score, tmpMax);
            tmpMin = MIN(score, tmpMin);
            
            // the score for this object
            [searchResult setValue:[NSNumber numberWithFloat:score] forKey:@"score"];
            
            [newResults addObject:searchResult];
            [searchResult release];
        }
        
        [self setMaxValueWithDouble:tmpMax];
        [self setMinValueWithDouble:tmpMin];
        
        // If we already have search matches, we need to preserve the entries we've already added in a bindings-compatible manner.  Since the objects in the set test for uniqueness by comparing file paths and work with KVC, we avoid duplicating results in the table, and the details of preserving selection and sorting will be nicely handled by the array controller.
        NSMutableArray *kvResults = [self mutableArrayValueForKey:@"results"];
        NSMutableSet *currentResults = [[NSMutableSet alloc] initWithArray:results];
        [newResults minusSet:currentResults];
        [kvResults addObjectsFromSet:newResults];
        
        [currentResults release];
        [newResults release];
        
        NSZoneFree(zone, skDocuments);

    }
    
    NSZoneFree(zone, documentIDs);
    NSZoneFree(zone, scores);
    
    if(searchCanceled || ![currentSearchIndex isIndexing]){
        [(standalone ? standaloneSpinner : spinner) stopAnimation:nil];
        [(standalone ? standaloneStopButton : stopButton) setEnabled:NO];
    } else if([currentSearchIndex isIndexing])
        [self performSelector:_cmd withObject:searchString afterDelay:1];
    
}

#pragma mark -
#pragma mark Document interaction

- (void)handleDocumentCloseNotification:(NSNotification *)notification
{
    id document = [notification object];
    BDSKSearchIndex *index = nil;
    [dictionaryLock lock];
    if(CFDictionaryGetValueIfPresent(indexDictionary, document, (const void **)&index) && index == currentSearchIndex)
        [self cancelCurrentSearch:nil];
    // cancel is required to terminate the run loop of the asynchronous index object and dispose of it
    [index cancel];
    CFDictionaryRemoveValue(indexDictionary, document);
    [dictionaryLock unlock];
    
    // necessary, otherwise we end up creating a retain cycle
    if(document == currentDocument)
        [self setDocument:nil];
}

// As long as this window is main, [NSDocumentController currentDocument] returns nil, so we have to keep track of the document manually; since this is an inspector (though not a panel yet), it needs to track which document is main
- (void)windowDidBecomeMain:(NSNotification *)notification
{
    NSWindow *window = [notification object];
    NSDocument *document = [[NSDocumentController sharedDocumentController] documentForWindow:window];
    if(document != nil) // BibEditors have no document, so we shouldn't set it from them
        [self setDocument:document];
}

- (void)saveSortDescriptors
{
    NSData *sortDescriptorData = [NSArchiver archivedDataWithRootObject:[resultsArrayController sortDescriptors]];
    OBPRECONDITION(sortDescriptorData);
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:sortDescriptorData forKey:BDSKFileContentSearchSortDescriptorKey];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self saveSortDescriptors];
}

- (void)handleApplicationWillTerminate:(NSNotification *)notification
{
    [self saveSortDescriptors];
}

// We care about the document accessor and KVO because our window's title is bound to its file name
- (void)setDocument:(NSDocument *)document
{
    if(standalone == NO && document != nil)
        NSParameterAssert([document conformsToProtocol:@protocol(BDSKSearchContentView)]);

    // @@ ok to retain as long as handleDocumentCloseNotification: comes first
    if (document != currentDocument) {
        // KVO notifications raise an exception here for some reason; maybe because we don't have a window for non-standalone?
        if(standalone) [self willChangeValueForKey:@"document"];
        [currentDocument release];
        currentDocument = [document retain];
        if(standalone) [self didChangeValueForKey:@"document"];
    }
}    

- (NSDocument *)document
{
    return currentDocument;
}

// Use the same font as the document tableview
- (void)setTableFont
{
    NSFont *font = [NSFont fontWithName:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTableViewFontKey]
                                   size:[[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKTableViewFontSizeKey]];
	
	[tableView setFont:font];
    NSLayoutManager *lm = [[NSLayoutManager alloc] init];
    [tableView setRowHeight:([lm defaultLineHeightForFont:font] + 2)];
    [lm release];
	[tableView tile];
    [tableView reloadData]; // otherwise the change isn't immediately visible
}

#pragma mark -
#pragma mark Toolbar setup

// label, palettelabel, toolTip, action, and menu can all be NULL, depending upon what you want the item to do
static void addToolbarItem(NSMutableDictionary *theDict,NSString *identifier,NSString *label,NSString *paletteLabel,NSString *toolTip,id target,SEL settingSelector, id itemContent,SEL action, NSMenuItem *menuItem)
{
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    // the settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
    // one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
    // (in the itemContent parameter).  Then this next line will do the right thing automatically.
    [item performSelector:settingSelector withObject:itemContent];
    [item setAction:action];
    // The menuItem to be shown in text only mode. Don't reset this when we use the default behavior. 
	if (menuItem)
		[item setMenuFormRepresentation:menuItem];
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
}

// called from WindowControllerDidLoadNib.
- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:FileContentSearchToolbarIdentifier] autorelease];
    BDSKMenuItem *menuItem;

    toolbarItems=[[NSMutableDictionary alloc] initWithCapacity:3];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];

    // We are the delegate
    [toolbar setDelegate: self];

    // add toolbaritems:
    addToolbarItem(toolbarItems, ProgressSpinnerToolbarItemIdentifier,
                   NSLocalizedString(@"",@""), 
				   NSLocalizedString(@"Progress Indicator",@""),
                   NSLocalizedString(@"Search Progress Indicator",@""),
                   nil, @selector(setView:),
				   standaloneSpinner, 
				   NULL,
                   nil);
    
    addToolbarItem(toolbarItems, StopButtonToolbarItemIdentifier,
                   NSLocalizedString(@"Stop",@""), 
				   NSLocalizedString(@"Stop Search",@""),
                   NSLocalizedString(@"Stop the Current Search",@""),
                   self, @selector(setView:),
				   standaloneStopButton, 
				   @selector(cancelCurrentSearch:),
                   nil);
    
    addToolbarItem(toolbarItems, SearchFieldToolbarItemIdentifier,
                   NSLocalizedString(@"Search",@""),
                   NSLocalizedString(@"Search",@""),
                   NSLocalizedString(@"Search Using SearchKit",@""),
                   self, @selector(setView:),
                   searchField,
                   @selector(search:), 
				   nil);
    
    // Attach the toolbar to the document window
    [[self window] setToolbar: toolbar];
}



- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar
      itemForItemIdentifier: (NSString *)itemIdent
  willBeInsertedIntoToolbar:(BOOL) willBeInserted {

    OAToolbarItem *newItem = [[[OAToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
    NSToolbarItem *item=[toolbarItems objectForKey:itemIdent];

    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view]!=nil)
    {
        [newItem setView:[item view]];
		[newItem setDelegate:self];
    }
    else
    {
        [newItem setImage:[item image]];
    }
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
    // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    // view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view]!=nil)
    {
        [newItem setMinSize:[[item view] bounds].size];
        [newItem setMaxSize:[[item view] bounds].size];
    }

    return newItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects:
		ProgressSpinnerToolbarItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        StopButtonToolbarItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		SearchFieldToolbarItemIdentifier, nil];
}


- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: 
		FileContentSearchToolbarIdentifier,
		StopButtonToolbarItemIdentifier,
		ProgressSpinnerToolbarItemIdentifier,
		SearchFieldToolbarItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, 
		NSToolbarSpaceItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem{ return YES; }

@end
