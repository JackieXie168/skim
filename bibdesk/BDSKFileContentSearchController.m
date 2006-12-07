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
#import "BDSKSearchResult.h"
#import "NSWorkspace_BDSKExtensions.h"
#import "BDSKTextWithIconCell.h"
#import "NSAttributedString_BDSKExtensions.h"

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
    
    [self setMaxValueWithDouble:0];
    [self setMinValueWithDouble:0];
    
    // this is a pointer to the current index; retained only by the indexDictionary
    currentSearchIndex = nil;
    
    results = [[NSMutableArray alloc] initWithCapacity:10];
    
    currentSearchKey = [[NSString alloc] initWithString:@""];
    
    // to be used for storing references to documents and associated index/mutable data objects
    indexDictionary = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &BDSKNSRetainedPointerDictionaryKeyCallbacks, &BDSKNSRetainedPointerDictionaryValueCallbacks);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentCloseNotification:) name:BDSKDocumentWindowWillCloseNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    
    // this lock is used any time the mutable indexDictionary ivar is accessed
    dictionaryLock = [[NSLock alloc] init];
    
    // flag set from UI or before deallocating the current index
    searchCanceled = NO;
 
    OBPRECONDITION(aDocument);
    [self setDocument:aDocument];

    return self;
}
    

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[statusBar unbind:@"stringValue"];
    [self cancelCurrentSearch:nil]; // before releasing the dictionary
    [searchContentView release];
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
    
    [spinner setUsesThreadedAnimation:NO];
    [spinner setDisplayedWhenStopped:NO];
    
    // set up the image/text cell combination
    BDSKTextWithIconCell *textCell = [[BDSKFileContentTextWithIconCell alloc] init];
    [textCell setControlSize:[cell controlSize]];
    [textCell setDrawsHighlight:NO];
    [[tableView tableColumnWithIdentifier:@"name"] setDataCell:textCell];
    [textCell release];
        
    // preserve sort behavior between launches (set in windowWillClose:)
    NSData *sortDescriptorData = [[NSUserDefaults standardUserDefaults] dataForKey:BDSKFileContentSearchSortDescriptorKey];
    if(sortDescriptorData != nil)
        [resultsArrayController setSortDescriptors:[NSUnarchiver unarchiveObjectWithData:sortDescriptorData]];
    
    OBPRECONDITION([[tableView enclosingScrollView] contentView]);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleClipViewFrameChangedNotification:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:[[tableView enclosingScrollView] contentView]];    

    // Do custom view setup 
    [topBarView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
    [topBarView setEdgeColor:[NSColor windowFrameColor]];
    [topBarView adjustSubviews];
    [statusBar toggleBelowView:[tableView enclosingScrollView] offset:0.0];
    statusBar = nil;
    
    // we might remove this, so keep a retained reference
    searchContentView = [[[self window] contentView] retain];

    // @@ workaround: the font from prefs seems to be overridden by the nib; maybe bindings issue?
    [tableView changeFont:nil];
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
    return [[resultsArrayController selectedObjects] valueForKey:@"title"];
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
    if([searchContentView window] && [self document] && [currentSearchKey isEqualToString:@""] == NO)
        [self rebuildResultsWithNewSearch:currentSearchKey];
}

- (void)restoreDocumentState:(id)sender
{
    [self saveSortDescriptors];
    [self cancelCurrentSearch:nil];
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
    [spinner stopAnimation:nil];
}    

- (void)rebuildResultsWithNewSearch:(NSString *)searchString
{        
    OBASSERT([NSThread inMainThread]);
    
    if([NSString isEmptyString:searchString]){
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [spinner stopAnimation:self];
        // iTunes/Mail swap out their search view when clearing the searchfield. don't clear the array, though, since we may need the array controller's selected objects
        [self restoreDocumentState:self];
    } else {
    
        // empty array; this takes care of updating the table for us
        [self setResults:[NSArray array]];

        [spinner startAnimation:self];
        
        SKIndexRef index = [currentSearchIndex index];
            
        // flushing a null index will cause a crash, so wait until the index is created
        if(index == NULL){
            [self performSelector:_cmd withObject:searchString afterDelay:0.1];
        } else {
            [stopButton setEnabled:YES];
            [self setMaxValueWithDouble:0];
            [self setMinValueWithDouble:0];
            [self rebuildResultsWithCurrentString:searchString];
        }
    }
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
    
    SKSearchFindMatches(currentSearch, maxResults, documentIDs, scores, 10, &actualResults);
    
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
            
            NSDictionary *attrs = [[NSDictionary alloc] initWithObjectsAndKeys:[tableView font], NSFontAttributeName, nil];
            NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithTeXString:title attributes:attrs collapseWhitespace:NO];
            [attrs release];
            [searchResult setValue:attributedTitle forKey:OATextWithIconCellStringKey];
            [searchResult setValue:title forKey:@"title"];
            [attributedTitle release];

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
        [spinner stopAnimation:nil];
        [stopButton setEnabled:NO];
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
    if(document == currentDocument){
        [self setDocument:nil];
        [objectController setContent:nil];
	}
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
    if(document != nil)
        NSParameterAssert([document conformsToProtocol:@protocol(BDSKSearchContentView)]);

    // @@ ok to retain as long as handleDocumentCloseNotification: comes first
    if (document != currentDocument) {
        [currentDocument release];
        currentDocument = [document retain];
    }
}    

- (NSDocument *)document
{
    return currentDocument;
}

#pragma mark TableView delegate

- (NSString *)tableViewFontNamePreferenceKey:(NSTableView *)tv {
    return BDSKFileContentSearchTableViewFontNameKey;
}

- (NSString *)tableViewFontSizePreferenceKey:(NSTableView *)tv {
    return BDSKFileContentSearchTableViewFontSizeKey;
}

@end
