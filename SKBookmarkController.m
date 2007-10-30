//
//  SKBookmarkController.m
//  Skim
//
//  Created by Christiaan Hofman on 3/16/07.
/*
 This software is Copyright (c) 2007
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

#import "SKBookmarkController.h"
#import "SKBookmark.h"
#import "BDAlias.h"
#import "SKDocument.h"
#import "SKMainWindowController.h"
#import "Files_SKExtensions.h"
#import "SKOutlineView.h"
#import "SKTypeSelectHelper.h"
#import "SKStatusBar.h"
#import "SKTextWithIconCell.h"
#import "SKToolbarItem.h"
#import "NSImage_SKExtensions.h"
#import "SKStringConstants.h"
#import "OBUtilities.h"

static NSString *SKBookmarkRowsPboardType = @"SKBookmarkRowsPboardType";

static NSString *SKBookmarksToolbarIdentifier = @"SKBookmarksToolbarIdentifier";
static NSString *SKBookmarksNewFolderToolbarItemIdentifier = @"SKBookmarksNewFolderToolbarItemIdentifier";
static NSString *SKBookmarksNewSeparatorToolbarItemIdentifier = @"SKBookmarksNewSeparatorToolbarItemIdentifier";
static NSString *SKBookmarksDeleteToolbarItemIdentifier = @"SKBookmarksDeleteToolbarItemIdentifier";

static NSString *SKBookmarksWindowFrameAutosaveName = @"SKBookmarksWindow";

static NSString *SKMaximumDocumentPageHistoryCountKey = @"SKMaximumDocumentPageHistoryCount";

#define BOOKMARKS_KEY           @"bookmarks"
#define RECENT_DOCUMENTS_KEY    @"recentDocuments"

#define PAGE_INDEX_KEY          @"pageIndex"
#define PATH_KEY                @"path"
#define ALIAS_KEY               @"alias"
#define ALIAS_DATA_KEY          @"_BDAlias"
#define SNAPSHOTS_KEY           @"snapshots"

@implementation SKBookmarkController

static unsigned int maxRecentDocumentsCount = 0;

+ (void)initialize {
    OBINITIALIZE;
    
    maxRecentDocumentsCount = [[NSUserDefaults standardUserDefaults] integerForKey:SKMaximumDocumentPageHistoryCountKey];
    if (maxRecentDocumentsCount == 0)
        maxRecentDocumentsCount = 50;
}

+ (id)sharedBookmarkController {
    static SKBookmarkController *sharedBookmarkController = nil;
    if (sharedBookmarkController == nil)
        sharedBookmarkController = [[self alloc] init];
    return sharedBookmarkController;
}

- (id)init {
    if (self = [super init]) {
        bookmarks = [[NSMutableArray alloc] init];
        recentDocuments = [[NSMutableArray alloc] init];
        
        NSData *data = [NSData dataWithContentsOfFile:[self bookmarksFilePath]];
        if (data) {
            NSString *error = nil;
            NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
            id plist = [NSPropertyListSerialization propertyListFromData:data
                                                        mutabilityOption:NSPropertyListMutableContainers
                                                                  format:&format 
                                                        errorDescription:&error];
            
            if (error) {
                NSLog(@"Error deserializing: %@", error);
                [error release];
            } else if ([plist isKindOfClass:[NSDictionary class]]) {
                [recentDocuments addObjectsFromArray:[plist objectForKey:RECENT_DOCUMENTS_KEY]];
                NSEnumerator *dictEnum = [[plist objectForKey:BOOKMARKS_KEY] objectEnumerator];
                NSDictionary *dict;
                
                while (dict = [dictEnum nextObject]) {
                    SKBookmark *bookmark = [[SKBookmark alloc] initWithDictionary:dict];
                    if (bookmark)
                        [bookmarks addObject:bookmark];
                    [bookmark release];
                }
            }
        }
        
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationWillTerminateNotification:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:NSApp];
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBookmarkChangedNotification:)
                                                     name:SKBookmarkChangedNotification
                                                   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBookmarkWillBeRemovedNotification:)
                                                     name:SKBookmarkWillBeRemovedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [bookmarks release];
    [recentDocuments release];
    [draggedBookmarks release];
    [toolbarItems release];
    [statusBar release];
    [super dealloc];
}

- (NSString *)windowNibName { return @"BookmarksWindow"; }

- (void)windowDidLoad {
    [self setupToolbar];
    
    [self setWindowFrameAutosaveName:SKBookmarksWindowFrameAutosaveName];
    
    [statusBar retain];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShowBookmarkStatusBarKey] == NO)
        [self toggleStatusBar:nil];
    
    SKTypeSelectHelper *typeSelectHelper = [[[SKTypeSelectHelper alloc] init] autorelease];
    [typeSelectHelper setDataSource:self];
    [outlineView setTypeSelectHelper:typeSelectHelper];
    
    [outlineView registerForDraggedTypes:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil]];
    
    [outlineView setDoubleAction:@selector(doubleClickBookmark:)];
}

- (void)updateStatus {
    int row = [outlineView selectedRow];
    NSString *message = @"";
    if (row != -1) {
        SKBookmark *bookmark = [outlineView itemAtRow:row];
        if ([bookmark bookmarkType] == SKBookmarkTypeBookmark) {
            message = [bookmark path];
        } else if ([bookmark bookmarkType] == SKBookmarkTypeFolder) {
            int count = [[bookmark children] count];
            message = count == 1 ? NSLocalizedString(@"1 item", @"Bookmark folder description") : [NSString stringWithFormat:NSLocalizedString(@"%i items", @"Bookmark folder description"), count];
        }
    }
    [statusBar setLeftStringValue:message ? message : @""];
}

#pragma mark Bookmarks

- (NSArray *)bookmarks {
    return bookmarks;
}

- (void)setBookmarks:(NSArray *)newBookmarks {
    [[[self undoManager] prepareWithInvocationTarget:self] setBookmarks:[[bookmarks copy] autorelease]];
    return [bookmarks setArray:newBookmarks];
}

- (unsigned)countOfBookmarks {
    return [bookmarks count];
}

- (id)objectInBookmarksAtIndex:(unsigned)index {
    return [bookmarks objectAtIndex:index];
}

- (void)insertObject:(id)obj inBookmarksAtIndex:(unsigned)index {
    [[[self undoManager] prepareWithInvocationTarget:self] removeObjectFromBookmarksAtIndex:index];
    [bookmarks insertObject:obj atIndex:index];
    [self handleBookmarkChangedNotification:nil];
}

- (void)removeObjectFromBookmarksAtIndex:(unsigned)index {
    [[[self undoManager] prepareWithInvocationTarget:self] insertObject:[bookmarks objectAtIndex:index] inBookmarksAtIndex:index];
    [self handleBookmarkWillBeRemovedNotification:nil];
    [bookmarks removeObjectAtIndex:index];
    [self handleBookmarkChangedNotification:nil];
}

- (NSArray *)childrenOfBookmark:(SKBookmark *)bookmark {
    return bookmark ? [bookmark children] : bookmarks;
}

- (unsigned int)indexOfChildBookmark:(SKBookmark *)bookmark {
    return [[self childrenOfBookmark:[bookmark parent]] indexOfObject:bookmark];
}

- (void)bookmark:(SKBookmark *)bookmark insertChildBookmark:(SKBookmark *)child atIndex:(unsigned int)index {
    if (bookmark)
        [bookmark insertChild:child atIndex:index];
    else
        [self insertObject:child inBookmarksAtIndex:index];
}

- (void)removeChildBookmark:(SKBookmark *)bookmark {
    SKBookmark *parent = [bookmark parent];
    if (parent)
        [parent removeChild:bookmark];
    else
        [[self mutableArrayValueForKey:@"bookmarks"] removeObject:bookmark];
}

- (NSArray *)minimumCoverForBookmarks:(NSArray *)items {
    NSEnumerator *bmEnum = [items objectEnumerator];
    SKBookmark *bm;
    SKBookmark *lastBm = nil;
    NSMutableArray *minimalCover = [NSMutableArray array];
    
    while (bm = [bmEnum nextObject]) {
        if ([bm isDescendantOf:lastBm] == NO) {
            [minimalCover addObject:bm];
            lastBm = bm;
        }
    }
    return minimalCover;
}

- (void)addBookmarkForPath:(NSString *)path pageIndex:(unsigned)pageIndex label:(NSString *)label toFolder:(SKBookmark *)folder {
    SKBookmark *bookmark = [[SKBookmark alloc] initWithPath:path pageIndex:pageIndex label:label];
    if (bookmark) {
        [self bookmark:folder insertChildBookmark:bookmark atIndex:[[self childrenOfBookmark:folder] count]];
        [bookmark release];
    }
}

- (NSArray *)draggedBookmarks {
    return draggedBookmarks;
}

- (void)setDraggedBookmarks:(NSArray *)items {
    if (draggedBookmarks != items) {
        [draggedBookmarks release];
        draggedBookmarks = [items retain];
    }
}

#pragma mark Recent Documents

- (NSArray *)recentDocuments {
    return recentDocuments;
}

- (unsigned int)indexOfRecentDocumentAtPath:(NSString *)path {
    unsigned int index = NSNotFound, i, iMax = [recentDocuments count];
    for (i = 0; i < iMax; i++) {
        NSMutableDictionary *info = [recentDocuments objectAtIndex:i];
        BDAlias *alias = [info valueForKey:ALIAS_KEY];
        if (alias == nil) {
            alias = [BDAlias aliasWithData:[info valueForKey:ALIAS_DATA_KEY]];
            [info setValue:alias forKey:ALIAS_KEY];
        }
        if ([[alias fullPathNoUI] isEqualToString:path]) {
            index = i;
            break;
        }
    }
    return index;
}

- (void)addRecentDocumentForPath:(NSString *)path pageIndex:(unsigned)pageIndex snapshots:(NSArray *)setups {
    if (path == nil)
        return;
    
    unsigned int index = [self indexOfRecentDocumentAtPath:path];
    if (index != NSNotFound)
        [recentDocuments removeObjectAtIndex:index];
    
    BDAlias *alias = [BDAlias aliasWithPath:path];
    NSMutableDictionary *bm = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:pageIndex], PAGE_INDEX_KEY, [alias aliasData], ALIAS_DATA_KEY, alias, ALIAS_KEY, [setups count] ? setups : nil, SNAPSHOTS_KEY, nil];
    [recentDocuments insertObject:bm atIndex:0];
    if ([recentDocuments count] > maxRecentDocumentsCount)
        [recentDocuments removeLastObject];
}

- (unsigned int)pageIndexForRecentDocumentAtPath:(NSString *)path {
    if (path == nil)
        return NSNotFound;
    unsigned int index = [self indexOfRecentDocumentAtPath:path];
    return index == NSNotFound ? NSNotFound : [[[recentDocuments objectAtIndex:index] objectForKey:PAGE_INDEX_KEY] unsignedIntValue];
}

- (NSArray *)snapshotsAtPath:(NSString *)path {
    if (path == nil)
        return nil;
    unsigned int index = [self indexOfRecentDocumentAtPath:path];
    NSArray *setups = index == NSNotFound ? nil : [[recentDocuments objectAtIndex:index] objectForKey:SNAPSHOTS_KEY];
    return [setups count] ? setups : nil;
}

- (NSString *)bookmarksFilePath {
    static NSString *bookmarksPath = nil;
    
    if (bookmarksPath == nil) {
        NSString *prefsPath = nil;
        FSRef foundRef;
        OSStatus err = noErr;
        
        err = FSFindFolder(kUserDomain,  kPreferencesFolderType, kCreateFolder, &foundRef);
        if (err != noErr) {
            NSLog(@"Error %d:  the system was unable to find your Preferences folder.", err);
            return nil;
        }
        
        CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &foundRef);
        
        if (url != nil) {
            prefsPath = [(NSURL *)url path];
            CFRelease(url);
            
            NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey];
            
            bookmarksPath = [[[prefsPath stringByAppendingPathComponent:[bundleIdentifier stringByAppendingString:@".bookmarks"]] stringByAppendingPathExtension:@"plist"] copy];
        }
        
    }
    
    return bookmarksPath;
}

- (void)openBookmarks:(NSArray *)items {
    NSEnumerator *bmEnum = [items objectEnumerator];
    SKBookmark *bm;
    
    while (bm = [bmEnum nextObject]) {
        id document = nil;
        NSString *path = [bm path];
        NSURL *fileURL = path ? [NSURL fileURLWithPath:path] : nil;
        NSError *error;
        
        if (fileURL && NO == SKFileIsInTrash(fileURL)) {
            if (document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES error:&error]) {
                [[document mainWindowController] setPageNumber:[bm pageIndex] + 1];
            } else {
                [NSApp presentError:error];
            }
        }
    }
}

- (IBAction)doubleClickBookmark:(id)sender {
    int row = [outlineView clickedRow];
    SKBookmark *bm = row == -1 ? nil : [outlineView itemAtRow:row];
    if (bm && [bm bookmarkType] == SKBookmarkTypeBookmark)
        [self openBookmarks:[NSArray arrayWithObject:bm]];
}

- (IBAction)insertBookmarkFolder:(id)sender {
    SKBookmark *folder = [[[SKBookmark alloc] initFolderWithLabel:NSLocalizedString(@"Folder", @"default folder name")] autorelease];
    int rowIndex = [[outlineView selectedRowIndexes] lastIndex];
    SKBookmark *item = nil;
    unsigned int index = [bookmarks count];
    
    if (rowIndex != NSNotFound) {
        SKBookmark *selectedItem = [outlineView itemAtRow:rowIndex];
        if ([outlineView isItemExpanded:selectedItem]) {
            item = selectedItem;
            index = [[item children] count];
        } else {
            item = [selectedItem parent];
            index = [self indexOfChildBookmark:selectedItem] + 1;
        }
    }
    [self bookmark:item insertChildBookmark:folder atIndex:index];
    
    int row = [outlineView rowForItem:folder];
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [outlineView editColumn:0 row:row withEvent:nil select:YES];
}

- (IBAction)insertBookmarkSeparator:(id)sender {
    SKBookmark *separator = [[[SKBookmark alloc] initSeparator] autorelease];
    int rowIndex = [[outlineView selectedRowIndexes] lastIndex];
    SKBookmark *item = nil;
    unsigned int index = [bookmarks count];
    
    if (rowIndex != NSNotFound) {
        SKBookmark *selectedItem = [outlineView itemAtRow:rowIndex];
        if ([outlineView isItemExpanded:selectedItem]) {
            item = selectedItem;
            index = [[item children] count];
        } else {
            item = [selectedItem parent];
            index = [self indexOfChildBookmark:selectedItem] + 1;
        }
    }
    [self bookmark:item insertChildBookmark:separator atIndex:index];
    
    int row = [outlineView rowForItem:separator];
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

- (IBAction)deleteBookmark:(id)sender {
    [outlineView delete:sender];
}

- (IBAction)toggleStatusBar:(id)sender {
    [statusBar toggleBelowView:[outlineView enclosingScrollView] offset:1.0];
    [[NSUserDefaults standardUserDefaults] setBool:[statusBar isVisible] forKey:SKShowBookmarkStatusBarKey];
}

#pragma mark Undo support

- (NSUndoManager *)undoManager {
    if(undoManager == nil)
        undoManager = [[NSUndoManager alloc] init];
    return undoManager;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
    return [self undoManager];
}

#pragma mark Notification handlers

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification  {
    [recentDocuments makeObjectsPerformSelector:@selector(removeObjectForKey:) withObject:ALIAS_KEY];
    NSDictionary *bookmarksDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[bookmarks valueForKey:@"dictionaryValue"], BOOKMARKS_KEY, recentDocuments, RECENT_DOCUMENTS_KEY, nil];
    NSString *error = nil;
    NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:bookmarksDictionary format:format errorDescription:&error];
    
	if (error) {
		NSLog(@"Error serializing: %@", error);
        [error release];
	} else {
        [data writeToFile:[self bookmarksFilePath] atomically:YES];
    }
}

- (void)handleBookmarkWillBeRemovedNotification:(NSNotification *)notification  {
    if ([outlineView editedRow] && [[self window] makeFirstResponder:outlineView] == NO)
        [[self window] endEditingFor:nil];
}

- (void)handleBookmarkChangedNotification:(NSNotification *)notification {
    [outlineView reloadData];
}

#pragma mark NSOutlineView datasource methods

- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item {
    return [[self childrenOfBookmark:item] count];
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item {
    return [item bookmarkType] == SKBookmarkTypeFolder;
}

- (id)outlineView:(NSOutlineView *)ov child:(int)index ofItem:(id)item {
    return [[self childrenOfBookmark:item] objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:@"label"]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:[item label], SKTextWithIconCellStringKey, [item icon], SKTextWithIconCellImageKey, nil];
    } else if ([tcID isEqualToString:@"file"]) {
        if ([item bookmarkType] == SKBookmarkTypeFolder) {
            int count = [[item children] count];
            return count == 1 ? NSLocalizedString(@"1 item", @"Bookmark folder description") : [NSString stringWithFormat:NSLocalizedString(@"%i items", @"Bookmark folder description"), count];
        } else {
            return [item path];
        }
    } else if ([tcID isEqualToString:@"page"]) {
        return [[item pageNumber] stringValue];
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:@"label"]) {
        if (object == nil)
            object = @"";
        if ([object isEqualToString:[item label]] == NO)
            [item setLabel:object];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    [self setDraggedBookmarks:[self minimumCoverForBookmarks:items]];
    [pboard declareTypes:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil] owner:nil];
    [pboard setData:[NSData data] forType:SKBookmarkRowsPboardType];
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil]];
    
    if (type) {
        if (index == NSOutlineViewDropOnItemIndex) {
            if ([item bookmarkType] == SKBookmarkTypeFolder && [outlineView isItemExpanded:item]) {
                [ov setDropItem:item dropChildIndex:0];
            } else if ([item parent]) {
                [ov setDropItem:[item parent] dropChildIndex:[[[item parent] children] indexOfObject:item] + 1];
            } else if (item) {
                [ov setDropItem:nil dropChildIndex:[bookmarks indexOfObject:item] + 1];
            } else {
                [ov setDropItem:nil dropChildIndex:[bookmarks count]];
            }
        }
        return [item isDescendantOfArray:[self draggedBookmarks]] ? NSDragOperationNone : NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil]];
    
    if (type) {
        NSEnumerator *bmEnum = [[self draggedBookmarks] objectEnumerator];
        SKBookmark *bookmark;
				
		while (bookmark = [bmEnum nextObject]) {
            int bookmarkIndex = [self indexOfChildBookmark:bookmark];
            if (item == [bookmark parent]) {
                if (index > bookmarkIndex)
                    index--;
                if (index == bookmarkIndex)
                    continue;
            }
            [self removeChildBookmark:bookmark];
            [self bookmark:item insertChildBookmark:bookmark atIndex:index++];
		}
        return YES;
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)ov dragEndedWithOperation:(NSDragOperation)operation {
    [self setDraggedBookmarks:nil];
}

#pragma mark NSOutlineView delegate methods

- (void)outlineView:(NSOutlineView *)ov willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([[tableColumn identifier] isEqualToString:@"file"]) {
        if ([item bookmarkType] == SKBookmarkTypeFolder)
            [cell setTextColor:[NSColor disabledControlTextColor]];
        else
            [cell setTextColor:[NSColor controlTextColor]];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return [[tableColumn identifier] isEqualToString:@"label"] && [item bookmarkType] != SKBookmarkTypeSeparator;
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
    NSString *tcID = [tc identifier];
    
    if ([tcID isEqualToString:@"label"]) {
        return [item label];
    } else if ([tcID isEqualToString:@"file"]) {
        return [item path];
    } else if ([tcID isEqualToString:@"page"]) {
        return [[item pageNumber] stringValue];
    }
    return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    [self updateStatus];
}

- (void)outlineView:(NSOutlineView *)ov deleteItems:(NSArray *)items {
    NSEnumerator *itemEnum = [[self minimumCoverForBookmarks:items] reverseObjectEnumerator];
    SKBookmark *item;
    while (item = [itemEnum  nextObject])
        [self removeChildBookmark:item];
}

- (BOOL)outlineView:(NSOutlineView *)ov canDeleteItems:(NSArray *)items {
    return [items count] > 0;
}

- (BOOL)outlineView:(NSOutlineView *)ov drawSeparatorRowForItem:(id)item {
    return [item bookmarkType] == SKBookmarkTypeSeparator;
}

#pragma mark SKTypeSelectHelper datasource protocol

- (NSArray *)typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    int i, count = [outlineView numberOfRows];
    NSMutableArray *labels = [NSMutableArray arrayWithCapacity:count];
    for (i = 0; i < count; i++) {
        NSString *label = [[outlineView itemAtRow:i] label];
        [labels addObject:label ? label : @""];
    }
    return labels;
}

- (unsigned int)typeSelectHelperCurrentlySelectedIndex:(SKTypeSelectHelper *)typeSelectHelper {
    return [[outlineView selectedRowIndexes] lastIndex];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper selectItemAtIndex:(unsigned int)itemIndex {
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
    [outlineView scrollRowToVisible:itemIndex];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString {
    [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
}

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString {
    if (searchString)
        [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Finding: \"%@\"", @"Status message"), searchString]];
    else
        [self updateStatus];
}

#pragma mark Toolbar

- (void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:SKBookmarksToolbarIdentifier] autorelease];
    SKToolbarItem *item;
    
    toolbarItems = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Add template toolbar items
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKBookmarksNewFolderToolbarItemIdentifier];
    [item setLabels:NSLocalizedString(@"New Folder", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add a New Folder", @"Tool tip message")];
    [item setImageNamed:@"ToolbarNewFolder"];
    [item setTarget:self];
    [item setAction:@selector(insertBookmarkFolder:)];
    [toolbarItems setObject:item forKey:SKBookmarksNewFolderToolbarItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKBookmarksNewSeparatorToolbarItemIdentifier];
    [item setLabels:NSLocalizedString(@"New Separator", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add a New Separator", @"Tool tip message")];
    [item setImageNamed:@"ToolbarNewSeparator"];
    [item setTarget:self];
    [item setAction:@selector(insertBookmarkSeparator:)];
    [toolbarItems setObject:item forKey:SKBookmarksNewSeparatorToolbarItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKBookmarksDeleteToolbarItemIdentifier];
    [item setLabels:NSLocalizedString(@"Delete", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Delete Selected Items", @"Tool tip message")];
    [item setImage:[NSImage imageWithIconForToolboxCode:kToolbarDeleteIcon]];
    [item setTarget:self];
    [item setAction:@selector(deleteBookmark:)];
    [toolbarItems setObject:item forKey:SKBookmarksDeleteToolbarItemIdentifier];
    [item release];
    
    // Attach the toolbar to the window
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {

    NSToolbarItem *item = [toolbarItems objectForKey:itemIdent];
    NSToolbarItem *newItem = [[item copy] autorelease];
    return newItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
        SKBookmarksNewFolderToolbarItemIdentifier, 
        SKBookmarksNewSeparatorToolbarItemIdentifier, 
        SKBookmarksDeleteToolbarItemIdentifier, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects: 
        SKBookmarksNewFolderToolbarItemIdentifier, 
        SKBookmarksNewSeparatorToolbarItemIdentifier, 
		SKBookmarksDeleteToolbarItemIdentifier, 
        NSToolbarFlexibleSpaceItemIdentifier, 
		NSToolbarSpaceItemIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    NSString *identifier = [toolbarItem itemIdentifier];
    if ([identifier isEqualToString:SKBookmarksDeleteToolbarItemIdentifier]) {
        return [outlineView canDelete];
    } else {
        return YES;
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(toggleStatusBar:)) {
        if ([statusBar isVisible])
            [menuItem setTitle:NSLocalizedString(@"Hide Status Bar", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Status Bar", @"Menu item title")];
        return YES;
    }
    return YES;
}

@end

#pragma mark -

@implementation SKBookmarkOutlineView

#define SEPARATOR_LEFT_INDENT 20.0
#define SEPARATOR_RIGHT_INDENT 2.0

- (void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect {
    if ([[self delegate] respondsToSelector:@selector(outlineView:drawSeparatorRowForItem:)] &&
        [[self delegate] outlineView:self drawSeparatorRowForItem:[self itemAtRow:rowIndex]]) {
        float indent = [self levelForItem:[self itemAtRow:rowIndex]] * [self indentationPerLevel];
        NSRect rect = [self rectOfRow:rowIndex];
        [[NSColor gridColor] setStroke];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rect) + indent + SEPARATOR_LEFT_INDENT, floorf(NSMidY(rect)) + 0.5) toPoint:NSMakePoint(NSMaxX(rect) - SEPARATOR_RIGHT_INDENT, floorf(NSMidY(rect)) + 0.5)];
    } else {
        [super drawRow:rowIndex clipRect:clipRect];
    }
}

@end
