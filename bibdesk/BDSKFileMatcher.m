//
//  BDSKFileMatcher.m
//  Bibdesk
//
//  Created by Adam Maxwell on 02/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BDSKFileMatcher.h"
#import "BibItem.h"
#import "BDSKTreeNode.h"
#import "BDSKTextWithIconCell.h"
#import "BDSKDocumentController.h"
#import "NSWorkspace_BDSKExtensions.h"
#import "BibDocument_Actions.h"
#import "NSImage+Toolbox.h"
#import "BibAuthor.h"

static CFIndex MAX_SEARCHKIT_RESULTS = 10;

@interface BDSKFileMatcher (Private)

- (void)doSearch;
- (void)makeNewIndex;
- (void)indexFiles:(NSArray *)absoluteURLs;

@end

@implementation BDSKFileMatcher

+ (id)sharedInstance;
{
    static id sharedInstance = nil;
    if (nil == sharedInstance)
        sharedInstance = [[self alloc] init];
    return sharedInstance;
}

- (id)init
{
    self = [super initWithWindowNibName:[self windowNibName]];
    if (self) {
        matches = [[NSMutableArray alloc] init];
        searchIndex = NULL;
    }
    return self;
}

- (NSString *)windowNibName { return @"FileMatcher"; }

- (void)dealloc
{
    [matches release];
    if (searchIndex)
        SKIndexClose(searchIndex);
    [super dealloc];
}

- (void)awakeFromNib
{
    [outlineView setAutosaveExpandedItems:YES];
    BDSKTextWithIconCell *cell = [[BDSKTextWithIconCell alloc] initTextCell:@""];
    [cell setDrawsHighlight:NO];
    [cell setImagePosition:NSImageLeft];
    [[[outlineView tableColumns] lastObject] setDataCell:cell];
    [cell release];
    
    [outlineView setDoubleAction:@selector(openAction:)];
    [outlineView setTarget:self];
    [outlineView registerForDraggedTypes:[NSArray arrayWithObject:NSURLPboardType]];
    [progressIndicator setUsesThreadedAnimation:YES];
}

// API: try to match these files with the front document
- (void)matchFiles:(NSArray *)absoluteURLs;
{
    [matches removeAllObjects];
    if (nil == [[NSDocumentController sharedDocumentController] mainDocument]) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"No front document", @"") defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"You need to open a document in order to match publications.", @"")];
        [alert runModal];
    } else {        
        // for the progress indicator
        [[self window] makeKeyAndOrderFront:self];
        
        [self makeNewIndex];
        [self indexFiles:absoluteURLs];
        [self doSearch];
    }
}

- (IBAction)openAction:(id)sender;
{
    id clickedItem = [outlineView itemAtRow:[outlineView clickedRow]];
    id obj = [clickedItem valueForKey:@"pub"];
    if (obj && [[NSDocumentController sharedDocumentController] mainDocument])
        [[[NSDocumentController sharedDocumentController] mainDocument] editPub:obj];
    else if ((obj = [clickedItem valueForKey:@"fileURL"]))
        [[NSWorkspace sharedWorkspace] openURL:obj withSearchString:[clickedItem valueForKey:@"searchString"]];
    else NSBeep();
}

#pragma mark Outline view drag-and-drop

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard;
{
    id item = [items lastObject];
    if ([item isLeaf]) {
        [pboard declareTypes:[NSArray arrayWithObject:NSURLPboardType] owner:nil];
        [[item valueForKey:@"fileURL"] writeToPasteboard:pboard];
        return YES;
    }
    return NO;
}

- (NSDragOperation)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index;
{
    if ([[info draggingSource] isEqual:outlineView] && [item isLeaf] == NO) {
        [olv setDropItem:item dropChildIndex:NSOutlineViewDropOnItemIndex];
        return NSDragOperationLink;
    }
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index;
{
    NSURL *fileURL = [NSURL URLFromPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]];
    if (nil == fileURL)
        return NO;
    
    BibItem *pub = [item valueForKey:@"pub"];
    if ([pub localURL]) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:NSLocalizedString(@"Publication already has a file", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"Overwrite", @"")];
        [alert setInformativeText:[NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedString(@"The publication's file is", @""), [[[pub localURL] path] stringByAbbreviatingWithTildeInPath]]];
        int rv = [alert runModal];
        if (NSAlertSecondButtonReturn == rv)
            [pub setField:BDSKLocalUrlString toValue:[fileURL absoluteString]];
    } else {
        [pub setField:BDSKLocalUrlString toValue:[fileURL absoluteString]];
    }
    return YES;
}

// return a larger row height for the items; tried using a spotlight controller image, but row size is too large to be practical
- (float)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return [item isLeaf] ? 17.0f : 48.0f;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
{
    return [item isLeaf];
}

#pragma mark Outline view datasource

- (id)outlineView:(NSOutlineView *)ov child:(int)index ofItem:(id)item;
{
    return nil == item ? [matches objectAtIndex:index] : [[item children] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item;
{
    return item ? (NO == [item isLeaf]) : YES;
}

- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item;
{
    return item ? [item numberOfChildren] : [matches count];
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
{
    return item;
}

- (id)outlineView:(NSOutlineView *)ov itemForPersistentObject:(id)object
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:object];
}

// return archived item
- (id)outlineView:(NSOutlineView *)ov persistentObjectForItem:(id)item
{
    return [NSKeyedArchiver archivedDataWithRootObject:item];
}

@end

@implementation BDSKFileMatcher (Private)

static NSString *searchStringWithPub(BibItem *pub)
{
    // may be better ways to do this, but we'll try a phrase search and then append the first author's last name (if available)
    NSMutableString *searchString = [NSMutableString stringWithFormat:@"\"%@\"", [pub title]];
    NSString *name = [[pub firstAuthor] lastName];
    if (name)
        [searchString appendFormat:@" AND %@", [[pub firstAuthor] lastName]];
    return searchString;
}

// this method iterates available publications, trying to match them up with a file
- (void)doSearch;
{
    BibDocument *doc = [[NSDocumentController sharedDocumentController] mainDocument];
    NSEnumerator *pubE = [[doc publications] objectEnumerator];
    BibItem *pub;
    NSString *searchString;
    
    NSParameterAssert(NULL != searchIndex);
    SKIndexFlush(searchIndex);
    
    [progressIndicator setDoubleValue:0.0];
    [statusField setStringValue:[NSLocalizedString(@"Searching document", @"") stringByAppendingEllipsis]];
    double val = 0;
    double max = [[doc publications] count];
    
    while (pub = [pubE nextObject]) {
        
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        searchString = searchStringWithPub(pub);
        SKSearchRef search = SKSearchCreate(searchIndex, (CFStringRef)searchString, kSKSearchOptionNoRelevanceScores);
        
        // if we get more than 10 matches back per pub, the results will be pretty useless anyway
        SKDocumentID docID[MAX_SEARCHKIT_RESULTS];
        CFIndex numFound;
        
        // could loop here if we need to, or increase search time
        SKSearchFindMatches(search, MAX_SEARCHKIT_RESULTS, docID, NULL, 1, &numFound);
        
        if (numFound) {
            
            CFURLRef urls[MAX_SEARCHKIT_RESULTS];
            SKIndexCopyDocumentURLsForDocumentIDs(searchIndex, numFound, docID, urls);
            
            int i, iMax = numFound;
            BDSKTreeNode *node = [[BDSKTreeNode alloc] init];
            [node setValue:[NSString stringWithFormat:@"%@ (%@)", [pub displayTitle], [pub pubAuthorsForDisplay]]  forKey:OATextWithIconCellStringKey];
            [node setValue:[NSImage imageNamed:@"cacheDoc"] forKey:OATextWithIconCellImageKey];
            [node setValue:pub forKey:@"pub"];
            
            // now we have a matching file; we could remove it from the index, but multiple matches are reasonable
            for (i =  0; i < iMax; i++) {
                BDSKTreeNode *child = [[BDSKTreeNode alloc] init];
                [child setValue:(id)urls[i] forKey:@"fileURL"];
                [child setValue:[[(id)urls[i] path] stringByAbbreviatingWithTildeInPath] forKey:OATextWithIconCellStringKey];
                [child setValue:[NSImage imageForURL:(NSURL *)urls[i]] forKey:OATextWithIconCellImageKey];
                [child setValue:searchString forKey:@"searchString"];
                [node addChild:child];
                [child release];
            }
            [matches addObject:node];
            [node release];
        }
        SKSearchCancel(search);
        CFRelease(search);
        
        val++;
        [outlineView reloadData];
        [progressIndicator setDoubleValue:(val/max)];
        [[self window] display];
        [pool release];
    }
    [progressIndicator setDoubleValue:1.0];
    [statusField setStringValue:NSLocalizedString(@"Search complete!", @"")];
}

- (void)makeNewIndex;
{
    if (searchIndex)
        SKIndexClose(searchIndex);
    CFMutableDataRef indexData = CFDataCreateMutable(CFAllocatorGetDefault(), 0);
    
    CFMutableDictionaryRef opts = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(opts, kSKMaximumTerms, (CFNumberRef)[NSNumber numberWithInt:200]);
    CFDictionaryAddValue(opts, kSKProximityIndexing, kCFBooleanTrue);
    
    // options are unused for now, since they seem to slow things down and caused a crash on one of my files rdar://problem/4988691
    searchIndex = SKIndexCreateWithMutableData(indexData, NULL, kSKIndexInverted, NULL);
    CFRelease(opts);
    CFRelease(indexData);
}    

- (void)indexFiles:(NSArray *)absoluteURLs;
{    
    double val = 0;
    double max = [absoluteURLs count];
    NSEnumerator *e = [absoluteURLs objectEnumerator];
    NSURL *url;
    [statusField setStringValue:[NSLocalizedString(@"Indexing files", @"") stringByAppendingEllipsis]];
    [progressIndicator setDoubleValue:0.0];
    [[self window] display];
    
    // some HTML files cause a deadlock or crash in -[NSHTMLReader _loadUsingLibXML2] rdar://problem/4988303
    BOOL shouldLog = [[NSUserDefaults standardUserDefaults] boolForKey:@"BDSKShouldLogFilesAddedToMatchingSearchIndex"];
    
    while (url = [e nextObject]) {
        SKDocumentRef doc = SKDocumentCreateWithURL((CFURLRef)url);
        
        if (shouldLog)
            NSLog(@"%@", url);
        
        if (doc) {
            SKIndexAddDocument(searchIndex, doc, NULL, TRUE);
            CFRelease(doc);
        }
        // forcing a redisplay at every step is ok since adding documents to the index is pretty slow
        val++;        
        [progressIndicator setDoubleValue:(val/max)];
        [[self window] display];
    }
    [progressIndicator setDoubleValue:1.0];
    [statusField setStringValue:NSLocalizedString(@"Indexing complete!", @"")];
    [[self window] display];    
}

@end

