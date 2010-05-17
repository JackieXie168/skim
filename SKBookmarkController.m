//
//  SKBookmarkController.m
//  Skim
//
//  Created by Christiaan Hofman on 3/16/07.
/*
 This software is Copyright (c) 2007-2010
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
#import "SKMainDocument.h"
#import "SKMainWindowController.h"
#import "NSFileManager_SKExtensions.h"
#import "SKTypeSelectHelper.h"
#import "SKStatusBar.h"
#import "SKTextWithIconCell.h"
#import "SKToolbarItem.h"
#import "NSImage_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKDocumentController.h"
#import "SKSeparatorCell.h"

#define SKBookmarkRowsPboardType @"SKBookmarkRowsPboardType"

#define SKBookmarksToolbarIdentifier                 @"SKBookmarksToolbarIdentifier"
#define SKBookmarksNewFolderToolbarItemIdentifier    @"SKBookmarksNewFolderToolbarItemIdentifier"
#define SKBookmarksNewSeparatorToolbarItemIdentifier @"SKBookmarksNewSeparatorToolbarItemIdentifier"
#define SKBookmarksDeleteToolbarItemIdentifier       @"SKBookmarksDeleteToolbarItemIdentifier"

#define SKBookmarksWindowFrameAutosaveName @"SKBookmarksWindow"

#define LABEL_COLUMNID @"label"
#define FILE_COLUMNID  @"file"
#define PAGE_COLUMNID  @"page"

#define SKMaximumDocumentPageHistoryCountKey @"SKMaximumDocumentPageHistoryCount"

#define BOOKMARKS_KEY       @"bookmarks"
#define RECENTDOCUMENTS_KEY @"recentDocuments"

#define PAGEINDEX_KEY @"pageIndex"
#define ALIAS_KEY     @"alias"
#define ALIASDATA_KEY @"_BDAlias"
#define SNAPSHOTS_KEY @"snapshots"

#define CHILDREN_KEY @"children"
#define LABEL_KEY    @"label"

static char SKBookmarkPropertiesObservationContext;


@interface SKBookmarkController (SKPrivate)
- (void)setupToolbar;
- (NSString *)bookmarksFilePath;
- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
- (void)endEditing;
- (void)startObservingBookmarks:(NSArray *)newBookmarks;
- (void)stopObservingBookmarks:(NSArray *)oldBookmarks;
@end

@implementation SKBookmarkController

@synthesize outlineView, statusBar, bookmarkRoot, recentDocuments, undoManager;

static NSUInteger maxRecentDocumentsCount = 0;

+ (void)initialize {
    SKINITIALIZE;
    
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
    if (self = [super initWithWindowNibName:@"BookmarksWindow"]) {
        recentDocuments = [[NSMutableArray alloc] init];
        
        NSMutableArray *bookmarks = [NSMutableArray array];
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
                [recentDocuments addObjectsFromArray:[plist objectForKey:RECENTDOCUMENTS_KEY]];
                for (NSDictionary *dict in [plist objectForKey:BOOKMARKS_KEY]) {
                    SKBookmark *bookmark = [SKBookmark bookmarkWithProperties:dict];
                    if (bookmark)
                        [bookmarks addObject:bookmark];
                }
            }
            
        }
        
        bookmarkRoot = [[SKBookmark alloc] initRootWithChildren:bookmarks];
        [self startObservingBookmarks:[NSArray arrayWithObject:bookmarkRoot]];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationWillTerminateNotification:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:NSApp];
    }
    return self;
}

- (void)dealloc {
    [self stopObservingBookmarks:[NSArray arrayWithObject:bookmarkRoot]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SKDESTROY(bookmarkRoot);
    SKDESTROY(recentDocuments);
    SKDESTROY(draggedBookmarks);
    SKDESTROY(toolbarItems);
    SKDESTROY(outlineView);
    SKDESTROY(statusBar);
    [super dealloc];
}

- (void)windowDidLoad {
    [self setupToolbar];
    
    [self setWindowFrameAutosaveName:SKBookmarksWindowFrameAutosaveName];
    
    [[self window] setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShowBookmarkStatusBarKey] == NO)
        [self toggleStatusBar:nil];
    else
        [[self window] setContentBorderThickness:22.0 forEdge:NSMinYEdge];
    
    [outlineView setTypeSelectHelper:[SKTypeSelectHelper typeSelectHelper]];
    
    [outlineView registerForDraggedTypes:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, NSFilenamesPboardType, nil]];
    
    [outlineView setDoubleAction:@selector(doubleClickBookmark:)];
}

- (void)updateStatus {
    NSInteger row = [outlineView selectedRow];
    NSString *message = @"";
    if (row != -1) {
        SKBookmark *bookmark = [outlineView itemAtRow:row];
        if ([bookmark bookmarkType] == SKBookmarkTypeBookmark) {
            message = [bookmark path];
        } else if ([bookmark bookmarkType] == SKBookmarkTypeFolder) {
            NSInteger count = [bookmark countOfChildren];
            message = count == 1 ? NSLocalizedString(@"1 item", @"Bookmark folder description") : [NSString stringWithFormat:NSLocalizedString(@"%ld items", @"Bookmark folder description"), (long)count];
        }
    }
    [statusBar setLeftStringValue:message ?: @""];
}

#pragma mark Bookmarks

static NSArray *minimumCoverForBookmarks(NSArray *items) {
    SKBookmark *lastBm = nil;
    NSMutableArray *minimalCover = [NSMutableArray array];
    
    for (SKBookmark *bm in items) {
        if ([bm isDescendantOf:lastBm] == NO) {
            [minimalCover addObject:bm];
            lastBm = bm;
        }
    }
    return minimalCover;
}

- (void)addBookmarkForPath:(NSString *)path pageIndex:(NSUInteger)pageIndex label:(NSString *)label toFolder:(SKBookmark *)folder {
    if (folder == nil) folder = bookmarkRoot;
    SKBookmark *bookmark = [SKBookmark bookmarkWithPath:path pageIndex:pageIndex label:label];
    if (bookmark)
        [folder insertObject:bookmark inChildrenAtIndex:[folder countOfChildren]];
}

- (void)addBookmarkForSetup:(NSDictionary *)setupDict label:(NSString *)label toFolder:(SKBookmark *)folder {
    if (folder == nil) folder = bookmarkRoot;
    SKBookmark *bookmark = [SKBookmark bookmarkWithSetup:setupDict label:label];
    if (bookmark)
        [folder insertObject:bookmark inChildrenAtIndex:[folder countOfChildren]];
}

- (void)addBookmarkForPaths:(NSArray *)paths pageIndexes:(NSArray *)pageIndexes label:(NSString *)label toFolder:(SKBookmark *)folder {
    NSEnumerator *pathEnum = [paths objectEnumerator];
    NSEnumerator *pageEnum = [pageIndexes objectEnumerator];
    NSString *path;
    NSNumber *page;
    NSMutableArray *children = [NSMutableArray array];
    SKBookmark *bookmark;
    while ((path = [pathEnum nextObject]) && (page = [pageEnum nextObject])) {
        if (bookmark = [SKBookmark bookmarkWithPath:path pageIndex:[page unsignedIntegerValue] label:[path lastPathComponent]])
            [children addObject:bookmark];
    }
    if (folder == nil) folder = bookmarkRoot;
    if (bookmark = [SKBookmark bookmarkSessionWithChildren:children label:label])
        [folder insertObject:bookmark inChildrenAtIndex:[folder countOfChildren]];
}

- (void)addBookmarkForSetups:(NSArray *)setupDicts label:(NSString *)label toFolder:(SKBookmark *)folder {
    NSMutableArray *children = [NSMutableArray array];
    SKBookmark *bookmark;
    for (NSDictionary *setup in setupDicts) {
        if (bookmark = [SKBookmark bookmarkWithSetup:setup label:@""])
            [children addObject:bookmark];
    }
    if (folder == nil) folder = bookmarkRoot;
    if (bookmark = [SKBookmark bookmarkSessionWithChildren:children label:label])
        [folder insertObject:bookmark inChildrenAtIndex:[folder countOfChildren]];
}

- (BOOL)addBookmarksForPaths:(NSArray *)paths basePath:(NSString *)basePath toFolder:(SKBookmark *)folder atIndex:(NSUInteger)anIndex {
    BOOL rv = NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    
    for (NSString *file in paths) {
        if ([[file lastPathComponent] hasPrefix:@"."] == NO) {
            NSString *path = [basePath stringByAppendingPathComponent:file] ?: file;
            NSString *fileType = [dc typeForContentsOfURL:[NSURL fileURLWithPath:path] error:NULL];
            SKBookmark *bookmark;
            if (SKIsFolderDocumentType(fileType)) {
                if (bookmark = [SKBookmark bookmarkFolderWithLabel:[fm displayNameAtPath:path]]) {
                    [folder insertObject:bookmark inChildrenAtIndex:anIndex++];
                    [self addBookmarksForPaths:[fm contentsOfDirectoryAtPath:path error:NULL] basePath:path toFolder:bookmark atIndex:0];
                    rv = YES;
                }
            } else if ([dc documentClassForType:fileType] == [SKMainDocument class]) {
                if (bookmark = [SKBookmark bookmarkWithPath:path pageIndex:0 label:[fm displayNameAtPath:path]]) {
                    [folder insertObject:bookmark inChildrenAtIndex:anIndex++];
                    rv = YES;
                }
            }
        }
    }
    return rv;
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

- (NSUInteger)indexOfRecentDocumentAtPath:(NSString *)path {
    NSUInteger idx = NSNotFound, i, iMax = [recentDocuments count];
    for (i = 0; i < iMax; i++) {
        NSMutableDictionary *info = [recentDocuments objectAtIndex:i];
        BDAlias *alias = [info valueForKey:ALIAS_KEY];
        if (alias == nil) {
            alias = [BDAlias aliasWithData:[info valueForKey:ALIASDATA_KEY]];
            [info setValue:alias forKey:ALIAS_KEY];
        }
        if ([[alias fullPathNoUI] isEqualToString:path]) {
            idx = i;
            break;
        }
    }
    return idx;
}

- (void)addRecentDocumentForPath:(NSString *)path pageIndex:(NSUInteger)pageIndex snapshots:(NSArray *)setups {
    if (path == nil)
        return;
    
    NSUInteger idx = [self indexOfRecentDocumentAtPath:path];
    if (idx != NSNotFound)
        [recentDocuments removeObjectAtIndex:idx];
    
    BDAlias *alias = [BDAlias aliasWithPath:path];
    if (alias) {
        NSMutableDictionary *bm = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:pageIndex], PAGEINDEX_KEY, [alias aliasData], ALIASDATA_KEY, alias, ALIAS_KEY, [setups count] ? setups : nil, SNAPSHOTS_KEY, nil];
        [recentDocuments insertObject:bm atIndex:0];
        if ([recentDocuments count] > maxRecentDocumentsCount)
            [recentDocuments removeLastObject];
    }
}

- (NSUInteger)pageIndexForRecentDocumentAtPath:(NSString *)path {
    if (path == nil)
        return NSNotFound;
    NSUInteger idx = [self indexOfRecentDocumentAtPath:path];
    return idx == NSNotFound ? NSNotFound : [[[recentDocuments objectAtIndex:idx] objectForKey:PAGEINDEX_KEY] unsignedIntegerValue];
}

- (NSArray *)snapshotsForRecentDocumentAtPath:(NSString *)path {
    if (path == nil)
        return nil;
    NSUInteger idx = [self indexOfRecentDocumentAtPath:path];
    NSArray *setups = idx == NSNotFound ? nil : [[recentDocuments objectAtIndex:idx] objectForKey:SNAPSHOTS_KEY];
    return [setups count] ? setups : nil;
}

#pragma mark Bookmarks support

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

- (void)openFileBookmark:(SKBookmark *)bookmark {
    id document = nil;
    NSError *error = nil;
    NSDictionary *dict = [bookmark properties];
    if ([dict objectForKey:@"windowFrame"]) {
        document = [[NSDocumentController sharedDocumentController] openDocumentWithSetup:dict error:&error];
    } else {
        NSString *path = [bookmark path];
        NSURL *fileURL = path ? [NSURL fileURLWithPath:path] : nil;
        if (fileURL && NO == [[NSFileManager defaultManager] isTrashedFileAtURL:fileURL] && 
            (document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES error:&error]) &&
            [document respondsToSelector:@selector(mainWindowController)])
            [[document mainWindowController] setPageNumber:[bookmark pageIndex] + 1];
    }
    if (document == nil && error)
        [NSApp presentError:error];
}

- (void)openBookmark:(SKBookmark *)bookmark {
    if ([bookmark bookmarkType] == SKBookmarkTypeSession) {
        NSInteger i = [bookmark countOfChildren];
        while (i--)
            [self openFileBookmark:[bookmark objectInChildrenAtIndex:i]];
    } else if ([bookmark bookmarkType] == SKBookmarkTypeBookmark) {
        [self openFileBookmark:bookmark];
    }
}

- (IBAction)doubleClickBookmark:(id)sender {
    NSInteger row = [outlineView clickedRow];
    if (row == -1)
        row = [outlineView selectedRow];
    SKBookmark *bm = row == -1 ? nil : [outlineView itemAtRow:row];
    if (bm && [bm bookmarkType] == SKBookmarkTypeBookmark)
        [self openBookmark:bm];
}

- (IBAction)insertBookmarkFolder:(id)sender {
    SKBookmark *folder = [SKBookmark bookmarkFolderWithLabel:NSLocalizedString(@"Folder", @"default folder name")];
    NSInteger rowIndex = [[outlineView selectedRowIndexes] lastIndex];
    SKBookmark *item = bookmarkRoot;
    NSUInteger idx = [bookmarkRoot countOfChildren];
    
    if (rowIndex != NSNotFound) {
        SKBookmark *selectedItem = [outlineView itemAtRow:rowIndex];
        if ([outlineView isItemExpanded:selectedItem]) {
            item = selectedItem;
            idx = [item countOfChildren];
        } else {
            item = [selectedItem parent];
            idx = [[item children] indexOfObject:selectedItem] + 1;
        }
    }
    [item insertObject:folder inChildrenAtIndex:idx];
    
    NSInteger row = [outlineView rowForItem:folder];
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [outlineView editColumn:0 row:row withEvent:nil select:YES];
}

- (IBAction)insertBookmarkSeparator:(id)sender {
    SKBookmark *separator = [SKBookmark bookmarkSeparator];
    NSInteger rowIndex = [[outlineView selectedRowIndexes] lastIndex];
    SKBookmark *item = bookmarkRoot;
    NSUInteger idx = [bookmarkRoot countOfChildren];
    
    if (rowIndex != NSNotFound) {
        SKBookmark *selectedItem = [outlineView itemAtRow:rowIndex];
        if ([outlineView isItemExpanded:selectedItem]) {
            item = selectedItem;
            idx = [item countOfChildren];
        } else {
            item = [selectedItem parent];
            idx = [[item children] indexOfObject:selectedItem] + 1;
        }
    }
    [item insertObject:separator inChildrenAtIndex:idx];
    
    NSInteger row = [outlineView rowForItem:separator];
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

- (IBAction)deleteBookmark:(id)sender {
    [outlineView delete:sender];
}

- (IBAction)toggleStatusBar:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:(NO == [statusBar isVisible]) forKey:SKShowBookmarkStatusBarKey];
    [statusBar toggleBelowView:[outlineView enclosingScrollView] animate:sender != nil];
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

- (void)startObservingBookmarks:(NSArray *)newBookmarks {
    for (SKBookmark *bm in newBookmarks) {
        if ([bm bookmarkType] != SKBookmarkTypeSeparator) {
            [bm addObserver:self forKeyPath:LABEL_KEY options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:&SKBookmarkPropertiesObservationContext];
            [bm addObserver:self forKeyPath:PAGEINDEX_KEY options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:&SKBookmarkPropertiesObservationContext];
            if ([bm bookmarkType] == SKBookmarkTypeFolder) {
                [bm addObserver:self forKeyPath:CHILDREN_KEY options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:&SKBookmarkPropertiesObservationContext];
                [self startObservingBookmarks:[bm children]];
            }
        }
    }
}

- (void)stopObservingBookmarks:(NSArray *)oldBookmarks {
    for (SKBookmark *bm in oldBookmarks) {
        if ([bm bookmarkType] != SKBookmarkTypeSeparator) {
            [bm removeObserver:self forKeyPath:LABEL_KEY];
            [bm removeObserver:self forKeyPath:PAGEINDEX_KEY];
            if ([bm bookmarkType] == SKBookmarkTypeFolder) {
                [bm removeObserver:self forKeyPath:CHILDREN_KEY];
                [self stopObservingBookmarks:[bm children]];
            }
        }
    }
}

- (void)setChildren:(NSArray *)newChildren ofBookmark:(SKBookmark *)bookmark {
    [self endEditing];
    [[bookmark mutableArrayValueForKey:CHILDREN_KEY] setArray:newChildren];
}

- (void)insertObjects:(NSArray *)newChildren inChildrenOfBookmark:(SKBookmark *)bookmark atIndexes:(NSIndexSet *)indexes {
    [[bookmark mutableArrayValueForKey:CHILDREN_KEY] insertObjects:newChildren atIndexes:indexes];
}

- (void)removeObjectsFromChildrenOfBookmark:(SKBookmark *)bookmark atIndexes:(NSIndexSet *)indexes {
    [self endEditing];
    [[bookmark mutableArrayValueForKey:CHILDREN_KEY] removeObjectsAtIndexes:indexes];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKBookmarkPropertiesObservationContext) {
        SKBookmark *bookmark = (SKBookmark *)object;
        id newValue = [change objectForKey:NSKeyValueChangeNewKey];
        id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
        NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
        
        if ([newValue isEqual:[NSNull null]]) newValue = nil;
        if ([oldValue isEqual:[NSNull null]]) oldValue = nil;
        
        switch ([[change objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue]) {
            case NSKeyValueChangeSetting:
                if ([keyPath isEqualToString:CHILDREN_KEY]) {
                    NSMutableArray *old = [NSMutableArray arrayWithArray:oldValue];
                    NSMutableArray *new = [NSMutableArray arrayWithArray:newValue];
                    [old removeObjectsInArray:newValue];
                    [new removeObjectsInArray:oldValue];
                    [self stopObservingBookmarks:old];
                    [self startObservingBookmarks:new];
                    [[[self undoManager] prepareWithInvocationTarget:self] setChildren:[[oldValue copy] autorelease] ofBookmark:bookmark];
                } else if ([keyPath isEqualToString:LABEL_KEY]) {
                    [[[self undoManager] prepareWithInvocationTarget:bookmark] setLabel:oldValue];
                } else if ([keyPath isEqualToString:PAGEINDEX_KEY]) {
                    [[[self undoManager] prepareWithInvocationTarget:bookmark] setPageIndex:[oldValue unsignedIntegerValue]];
                }
                break;
            case NSKeyValueChangeInsertion:
                if ([keyPath isEqualToString:CHILDREN_KEY]) {
                    [self startObservingBookmarks:newValue];
                    [[[self undoManager] prepareWithInvocationTarget:self] removeObjectsFromChildrenOfBookmark:bookmark atIndexes:indexes];
                }
                break;
            case NSKeyValueChangeRemoval:
                if ([keyPath isEqualToString:CHILDREN_KEY]) {
                    [self stopObservingBookmarks:oldValue];
                    [[[self undoManager] prepareWithInvocationTarget:self] insertObjects:[[oldValue copy] autorelease] inChildrenOfBookmark:bookmark atIndexes:indexes];
                }
                break;
            case NSKeyValueChangeReplacement:
                if ([keyPath isEqualToString:CHILDREN_KEY]) {
                    [self stopObservingBookmarks:oldValue];
                    [self startObservingBookmarks:newValue];
                    [[[self undoManager] prepareWithInvocationTarget:self] removeObjectsFromChildrenOfBookmark:bookmark atIndexes:indexes];
                    [[[self undoManager] prepareWithInvocationTarget:self] insertObjects:[[oldValue copy] autorelease] inChildrenOfBookmark:bookmark atIndexes:indexes];
                }
                break;
        }
        
        [outlineView reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Notification handlers

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification  {
    [recentDocuments makeObjectsPerformSelector:@selector(removeObjectForKey:) withObject:ALIAS_KEY];
    NSDictionary *bookmarksDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[[bookmarkRoot children] valueForKey:@"properties"], BOOKMARKS_KEY, recentDocuments, RECENTDOCUMENTS_KEY, nil];
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

- (void)endEditing {
    if ([outlineView editedRow] && [[self window] makeFirstResponder:outlineView] == NO)
        [[self window] endEditingFor:nil];
}

#pragma mark NSOutlineView datasource methods

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item {
    if (item == nil) item = bookmarkRoot;
    return [item bookmarkType] == SKBookmarkTypeFolder ? [item countOfChildren] : 0;
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item {
    return [item bookmarkType] == SKBookmarkTypeFolder;
}

- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)anIndex ofItem:(id)item {
    return [(item ?: bookmarkRoot) objectInChildrenAtIndex:anIndex];
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:LABEL_COLUMNID]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:[item label], SKTextWithIconCellStringKey, [item icon], SKTextWithIconCellImageKey, nil];
    } else if ([tcID isEqualToString:FILE_COLUMNID]) {
        if ([item bookmarkType] == SKBookmarkTypeFolder || [item bookmarkType] == SKBookmarkTypeSession) {
            NSInteger count = [item countOfChildren];
            return count == 1 ? NSLocalizedString(@"1 item", @"Bookmark folder description") : [NSString stringWithFormat:NSLocalizedString(@"%ld items", @"Bookmark folder description"), (long)count];
        } else {
            return [item path];
        }
    } else if ([tcID isEqualToString:PAGE_COLUMNID]) {
        return [item pageNumber];
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:LABEL_COLUMNID]) {
        NSString *newlabel = [object valueForKey:SKTextWithIconCellStringKey] ?: @"";
        if ([newlabel isEqualToString:[item label]] == NO)
            [item setLabel:newlabel];
    } else if ([tcID isEqualToString:PAGE_COLUMNID]) {
        if ([object isEqual:[item pageNumber]] == NO)
            [item setPageNumber:object];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    [self setDraggedBookmarks:minimumCoverForBookmarks(items)];
    [pboard declareTypes:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil] owner:nil];
    [pboard setData:[NSData data] forType:SKBookmarkRowsPboardType];
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)anIndex {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, NSFilenamesPboardType, nil]];
    NSDragOperation dragOp = NSDragOperationNone;
    
    if (anIndex != NSOutlineViewDropOnItemIndex) {
        if ([type isEqualToString:NSFilenamesPboardType])
            dragOp = NSDragOperationEvery;
        else if ([type isEqualToString:SKBookmarkRowsPboardType] && [item isDescendantOfArray:[self draggedBookmarks]])
            dragOp = NSDragOperationMove;
    }
    return dragOp;
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)anIndex {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, NSFilenamesPboardType, nil]];
    
    if ([type isEqualToString:SKBookmarkRowsPboardType]) {
        if (item == nil) item = bookmarkRoot;
        
        [self endEditing];
		for (SKBookmark *bookmark in [self draggedBookmarks]) {
            SKBookmark *parent = [bookmark parent];
            NSInteger bookmarkIndex = [[parent children] indexOfObject:bookmark];
            if (item == parent) {
                if (anIndex > bookmarkIndex)
                    anIndex--;
                if (anIndex == bookmarkIndex)
                    continue;
            }
            [parent removeObjectFromChildrenAtIndex:bookmarkIndex];
            [(SKBookmark *)item insertObject:bookmark inChildrenAtIndex:anIndex++];
		}
        return YES;
    } else if ([type isEqualToString:NSFilenamesPboardType]) {
        if (item == nil) item = bookmarkRoot;
        
        NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
        [self endEditing];
        return [self addBookmarksForPaths:paths basePath:nil toFolder:item atIndex:anIndex];
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)ov dragEndedWithOperation:(NSDragOperation)operation {
    [self setDraggedBookmarks:nil];
}

#pragma mark NSOutlineView delegate methods

- (NSCell *)outlineView:(NSOutlineView *)ov dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (tableColumn == nil)
        return [item bookmarkType] == SKBookmarkTypeSeparator ? [[[SKSeparatorCell alloc] init] autorelease] : nil;
    return [tableColumn dataCellForRow:[ov rowForItem:item]];
}

- (void)outlineView:(NSOutlineView *)ov willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([[tableColumn identifier] isEqualToString:FILE_COLUMNID]) {
        if ([item bookmarkType] == SKBookmarkTypeFolder || [item bookmarkType] == SKBookmarkTypeSession)
            [cell setTextColor:[NSColor disabledControlTextColor]];
        else
            [cell setTextColor:[NSColor controlTextColor]];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:LABEL_COLUMNID])
        return [item bookmarkType] != SKBookmarkTypeSeparator;
    else if ([tcID isEqualToString:PAGE_COLUMNID])
        return [item bookmarkType] == SKBookmarkTypeBookmark;
    return NO;
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
    NSString *tcID = [tc identifier];
    
    if ([tcID isEqualToString:LABEL_COLUMNID]) {
        return [item label];
    } else if ([tcID isEqualToString:FILE_COLUMNID]) {
        return [item path];
    } else if ([tcID isEqualToString:PAGE_COLUMNID]) {
        return [[item pageNumber] stringValue];
    }
    return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    [self updateStatus];
}

- (void)outlineView:(NSOutlineView *)ov deleteItems:(NSArray *)items {
    NSEnumerator *itemEnum = [minimumCoverForBookmarks(items) reverseObjectEnumerator];
    SKBookmark *item;
    [self endEditing];
    while (item = [itemEnum  nextObject]) {
        SKBookmark *parent = [item parent];
        NSUInteger itemIndex = [[parent children] indexOfObject:item];
        if (itemIndex != NSNotFound)
            [parent removeObjectFromChildrenAtIndex:itemIndex];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov canDeleteItems:(NSArray *)items {
    return [items count] > 0;
}

- (NSArray *)outlineView:(NSOutlineView *)ov typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    NSInteger i, count = [outlineView numberOfRows];
    NSMutableArray *labels = [NSMutableArray arrayWithCapacity:count];
    for (i = 0; i < count; i++) {
        NSString *label = [[outlineView itemAtRow:i] label];
        [labels addObject:label ?: @""];
    }
    return labels;
}

- (void)outlineView:(NSOutlineView *)ov typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString {
    [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"No match: \"%@\"", @"Status message"), searchString]];
}

- (void)outlineView:(NSOutlineView *)ov typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString {
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
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    
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
    [item setImageNamed:SKImageNameToolbarNewFolder];
    [item setTarget:self];
    [item setAction:@selector(insertBookmarkFolder:)];
    [dict setObject:item forKey:SKBookmarksNewFolderToolbarItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKBookmarksNewSeparatorToolbarItemIdentifier];
    [item setLabels:NSLocalizedString(@"New Separator", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Add a New Separator", @"Tool tip message")];
    [item setImageNamed:SKImageNameToolbarNewSeparator];
    [item setTarget:self];
    [item setAction:@selector(insertBookmarkSeparator:)];
    [dict setObject:item forKey:SKBookmarksNewSeparatorToolbarItemIdentifier];
    [item release];
    
    item = [[SKToolbarItem alloc] initWithItemIdentifier:SKBookmarksDeleteToolbarItemIdentifier];
    [item setLabels:NSLocalizedString(@"Delete", @"Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"Delete Selected Items", @"Tool tip message")];
    [item setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarDeleteIcon)]];
    [item setTarget:self];
    [item setAction:@selector(deleteBookmark:)];
    [dict setObject:item forKey:SKBookmarksDeleteToolbarItemIdentifier];
    [item release];
    
    toolbarItems = [dict mutableCopy];
    
    // Attach the toolbar to the window
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
    NSToolbarItem *item = [toolbarItems objectForKey:itemIdent];
    if (willBeInserted == NO)
        item = [[item copy] autorelease];
    return item;
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
    if ([[[self window] toolbar] customizationPaletteIsRunning])
        return NO;
    else if ([[toolbarItem itemIdentifier] isEqualToString:SKBookmarksDeleteToolbarItemIdentifier])
        return [outlineView canDelete];
    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(toggleStatusBar:)) {
        if ([statusBar isVisible])
            [menuItem setTitle:NSLocalizedString(@"Hide Status Bar", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Status Bar", @"Menu item title")];
        return YES;
    }
    return YES;
}

@end
