//
//  SKBookmarkController.m
//  Skim
//
//  Created by Christiaan Hofman on 3/16/07.
/*
 This software is Copyright (c) 2007-2014
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
#import "SKAlias.h"
#import "SKTypeSelectHelper.h"
#import "SKStatusBar.h"
#import "SKTextWithIconCell.h"
#import "SKToolbarItem.h"
#import "NSImage_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKSeparatorCell.h"
#import "NSMenu_SKExtensions.h"
#import "NSURL_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSEvent_SKExtensions.h"

#define SKPasteboardTypeBookmarkRows @"net.sourceforge.skim-app.pasteboard.bookmarkrows"

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

static NSArray *minimumCoverForBookmarks(NSArray *items);

@interface SKBookmarkController (SKPrivate)
- (void)setupToolbar;
- (NSString *)bookmarksFilePath;
- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
- (void)endEditing;
- (void)startObservingBookmarks:(NSArray *)newBookmarks;
- (void)stopObservingBookmarks:(NSArray *)oldBookmarks;
@end

@interface SKBookmarkController ()
@property (nonatomic, retain) NSArray *draggedBookmarks;
@end

@implementation SKBookmarkController

@synthesize outlineView, statusBar, bookmarkRoot, recentDocuments, undoManager, draggedBookmarks;

static SKBookmarkController *sharedBookmarkController = nil;

static NSUInteger maxRecentDocumentsCount = 0;

+ (void)initialize {
    SKINITIALIZE;
    
    maxRecentDocumentsCount = [[NSUserDefaults standardUserDefaults] integerForKey:SKMaximumDocumentPageHistoryCountKey];
    if (maxRecentDocumentsCount == 0)
        maxRecentDocumentsCount = 50;
}

+ (id)sharedBookmarkController {
    if (sharedBookmarkController == nil)
        [[[self alloc] init] release];
    return sharedBookmarkController;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [sharedBookmarkController retain] ?: [super allocWithZone:zone];
}

- (id)init {
    if (sharedBookmarkController == nil) {
        self = [super initWithWindowNibName:@"BookmarksWindow"];
        if (self) {
            recentDocuments = [[NSMutableArray alloc] init];
            
            NSMutableArray *bookmarks = [NSMutableArray array];
            NSData *data = [NSData dataWithContentsOfFile:[self bookmarksFilePath]];
            if (data) {
                NSError *error = nil;
                NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
                id plist = [NSPropertyListSerialization propertyListWithData:data
                                                                     options:NSPropertyListMutableContainers
                                                                      format:&format 
                                                                       error:&error];
                
                if (error) {
                    NSLog(@"Error deserializing: %@", error);
                } else if ([plist isKindOfClass:[NSDictionary class]]) {
                    [recentDocuments addObjectsFromArray:[plist objectForKey:RECENTDOCUMENTS_KEY]];
                    for (NSDictionary *dict in [plist objectForKey:BOOKMARKS_KEY]) {
                        SKBookmark *bookmark = [[SKBookmark alloc] initWithProperties:dict];
                        if (bookmark) {
                            [bookmarks addObject:bookmark];
                            [bookmark release];
                        } else
                            NSLog(@"Failed to read bookmark: %@", dict);
                    }
                }
                
            }
            
            bookmarkRoot = [[SKBookmark alloc] initRootWithChildren:bookmarks];
            [self startObservingBookmarks:[NSArray arrayWithObject:bookmarkRoot]];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleApplicationWillTerminateNotification:)
                                                         name:NSApplicationWillTerminateNotification
                                                       object:NSApp];
            
            NSArray *lastOpenFiles = [[NSUserDefaults standardUserDefaults] arrayForKey:SKLastOpenFileNamesKey];
            if ([lastOpenFiles count] > 0)
                previousSession = [[SKBookmark alloc] initSessionWithSetups:lastOpenFiles label:NSLocalizedString(@"Restore Previous Session", @"Menu item title")];
        }
        sharedBookmarkController = [self retain];
    } else if (self != sharedBookmarkController) {
        NSLog(@"Attempt to allocate second instance of %@", [self class]);
        [self release];
        self = [sharedBookmarkController retain];
    }
    return self;
}

- (void)dealloc {
    [self stopObservingBookmarks:[NSArray arrayWithObject:bookmarkRoot]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SKDESTROY(bookmarkRoot);
    SKDESTROY(previousSession);
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
    
    [outlineView registerForDraggedTypes:[NSArray arrayWithObjects:SKPasteboardTypeBookmarkRows, (NSString *)kUTTypeFileURL, NSFilenamesPboardType, nil]];
    
    [outlineView setDoubleAction:@selector(doubleClickBookmark:)];
    
    [outlineView setSupportsQuickLook:YES];
}

- (void)updateStatus {
    NSInteger row = [outlineView selectedRow];
    NSString *message = @"";
    if (row != -1) {
        SKBookmark *bookmark = [outlineView itemAtRow:row];
        if ([bookmark bookmarkType] == SKBookmarkTypeBookmark) {
            message = [[bookmark fileURL] path];
        } else if ([bookmark bookmarkType] == SKBookmarkTypeFolder) {
            NSInteger count = [bookmark countOfChildren];
            message = count == 1 ? NSLocalizedString(@"1 item", @"Bookmark folder description") : [NSString stringWithFormat:NSLocalizedString(@"%ld items", @"Bookmark folder description"), (long)count];
        }
    }
    [statusBar setLeftStringValue:message ?: @""];
}

#pragma mark Recent Documents

- (NSDictionary *)recentDocumentInfoAtURL:(NSURL *)fileURL {
    NSString *path = [fileURL path];
    for (NSMutableDictionary *info in recentDocuments) {
        SKAlias *alias = [info valueForKey:ALIAS_KEY];
        if (alias == nil) {
            alias = [SKAlias aliasWithData:[info valueForKey:ALIASDATA_KEY]];
            [info setValue:alias forKey:ALIAS_KEY];
        }
        if ([[[alias fileURLNoUI] path] isCaseInsensitiveEqual:path])
            return info;
    }
    return nil;
}

- (void)addRecentDocumentForURL:(NSURL *)fileURL pageIndex:(NSUInteger)pageIndex snapshots:(NSArray *)setups {
    if (fileURL == nil)
        return;
    
    NSDictionary *info = [self recentDocumentInfoAtURL:fileURL];
    if (info)
        [recentDocuments removeObjectIdenticalTo:info];
    
    SKAlias *alias = [SKAlias aliasWithURL:fileURL];
    if (alias) {
        NSMutableDictionary *bm = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:pageIndex], PAGEINDEX_KEY, [alias data], ALIASDATA_KEY, alias, ALIAS_KEY, [setups count] ? setups : nil, SNAPSHOTS_KEY, nil];
        [recentDocuments insertObject:bm atIndex:0];
        if ([recentDocuments count] > maxRecentDocumentsCount)
            [recentDocuments removeLastObject];
    }
}

- (NSUInteger)pageIndexForRecentDocumentAtURL:(NSURL *)fileURL {
    if (fileURL == nil)
        return NSNotFound;
    NSNumber *pageIndex = [[self recentDocumentInfoAtURL:fileURL] objectForKey:PAGEINDEX_KEY];
    return pageIndex == nil ? NSNotFound : [pageIndex unsignedIntegerValue];
}

- (NSArray *)snapshotsForRecentDocumentAtURL:(NSURL *)fileURL {
    if (fileURL == nil)
        return nil;
    NSArray *setups = [[self recentDocumentInfoAtURL:fileURL] objectForKey:SNAPSHOTS_KEY];
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
            
            NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
            
            bookmarksPath = [[[prefsPath stringByAppendingPathComponent:[bundleIdentifier stringByAppendingString:@".bookmarks"]] stringByAppendingPathExtension:@"plist"] copy];
        }
        
    }
    
    return bookmarksPath;
}

- (void)getInsertionFolder:(SKBookmark **)bookmarkPtr childIndex:(NSUInteger *)indexPtr {
    NSInteger rowIndex = [outlineView clickedRow];
    NSIndexSet *indexes = [outlineView selectedRowIndexes];
    if (rowIndex != -1 && [indexes containsIndex:rowIndex] == NO)
        indexes = [NSIndexSet indexSetWithIndex:rowIndex];
    rowIndex = [indexes lastIndex];
    
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
    
    *bookmarkPtr = item;
    *indexPtr = idx;
}

- (IBAction)openBookmark:(id)sender {
    [[sender representedObject] open];
}

- (IBAction)doubleClickBookmark:(id)sender {
    NSInteger row = [outlineView clickedRow];
    if (row == -1)
        row = [outlineView selectedRow];
    SKBookmark *bm = row == -1 ? nil : [outlineView itemAtRow:row];
    if (bm && ([bm bookmarkType] == SKBookmarkTypeBookmark || [bm bookmarkType] == SKBookmarkTypeSession))
        [bm open];
}

- (IBAction)insertBookmarkFolder:(id)sender {
    SKBookmark *folder = [SKBookmark bookmarkFolderWithLabel:NSLocalizedString(@"Folder", @"default folder name")];
    SKBookmark *item = nil;
    NSUInteger idx = 0;
    
    [self getInsertionFolder:&item childIndex:&idx];
    [item insertObject:folder inChildrenAtIndex:idx];
    
    NSInteger row = [outlineView rowForItem:folder];
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [outlineView editColumn:0 row:row withEvent:nil select:YES];
}

- (IBAction)insertBookmarkSeparator:(id)sender {
    SKBookmark *separator = [SKBookmark bookmarkSeparator];
    SKBookmark *item = nil;
    NSUInteger idx = 0;
    
    [self getInsertionFolder:&item childIndex:&idx];
    [item insertObject:separator inChildrenAtIndex:idx];
    
    NSInteger row = [outlineView rowForItem:separator];
    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

- (IBAction)addBookmark:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSMutableArray *types = [NSMutableArray array];
    for (NSString *docClass in [[NSDocumentController sharedDocumentController] documentClassNames])
        [types addObjectsFromArray:[NSClassFromString(docClass) readableTypes]];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowedFileTypes:types];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                NSArray *newBookmarks = [SKBookmark bookmarksForURLs:[openPanel URLs]];
                if ([newBookmarks count] > 0) {
                    SKBookmark *item = nil;
                    NSUInteger anIndex = 0;
                    [self getInsertionFolder:&item childIndex:&anIndex];
                    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(anIndex, [newBookmarks count])];
                    [[item mutableArrayValueForKey:@"children"] insertObjects:newBookmarks atIndexes:indexes];
                    if (item == bookmarkRoot || [outlineView isItemExpanded:item]) {
                        if (item != bookmarkRoot)
                            [indexes shiftIndexesStartingAtIndex:0 by:[outlineView rowForItem:item] + 1];
                        [outlineView selectRowIndexes:indexes byExtendingSelection:NO];
                    }
                }
            }
        }];
}

- (IBAction)deleteBookmark:(id)sender {
    [outlineView delete:sender];
}

- (IBAction)toggleStatusBar:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:(NO == [statusBar isVisible]) forKey:SKShowBookmarkStatusBarKey];
    [statusBar toggleBelowView:[outlineView enclosingScrollView] animate:sender != nil];
}

- (NSArray *)clickedBookmarks {
    NSMutableArray *items = [NSMutableArray array];
    NSInteger row = [outlineView clickedRow];
    if (row != -1) {
        NSIndexSet *indexes = [outlineView selectedRowIndexes];
        if ([indexes containsIndex:row] == NO)
            indexes = [NSIndexSet indexSetWithIndex:row];
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [items addObject:[outlineView itemAtRow:idx]];
        }];
    }
    return items;
}

- (IBAction)deleteBookmarks:(id)sender {
    NSArray *items = minimumCoverForBookmarks([self clickedBookmarks]);
    [self endEditing];
    for (SKBookmark *item in [items reverseObjectEnumerator]) {
        SKBookmark *parent = [item parent];
        NSUInteger itemIndex = [[parent children] indexOfObject:item];
        if (itemIndex != NSNotFound)
            [parent removeObjectFromChildrenAtIndex:itemIndex];
    }
}

- (IBAction)openBookmarks:(id)sender {
    NSArray *items = minimumCoverForBookmarks([self clickedBookmarks]);
    for (SKBookmark *item in [minimumCoverForBookmarks(items) reverseObjectEnumerator])
        [item open];
}

- (IBAction)previewBookmarks:(id)sender {
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    } else {
        NSInteger row = [outlineView clickedRow];
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
    }
}

#pragma mark NSMenu delegate methods

- (void)addItemForBookmark:(SKBookmark *)bookmark toMenu:(NSMenu *)menu isFolder:(BOOL)isFolder isAlternate:(BOOL)isAlternate {
    NSMenuItem *item = nil;
    if (isFolder) {
        item = [menu addItemWithSubmenuAndTitle:[bookmark label]];
        [[item submenu] setDelegate:self];
    } else {
        item = [menu addItemWithTitle:[bookmark label] action:@selector(openBookmark:) target:self];
    }
    [item setRepresentedObject:bookmark];
    if (isAlternate) {
        [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [item setAlternate:YES];
        [item setImageAndSize:[bookmark alternateIcon]];
    } else {
        [item setImageAndSize:[bookmark icon]];
    }
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == [outlineView menu]) {
        NSMenuItem *menuItem;
        NSInteger row = [outlineView clickedRow];
        [menu removeAllItems];
        if (row != -1) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Remove", @"Menu item title") action:@selector(deleteBookmarks:) target:self];
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Open", @"Menu item title") action:@selector(openBookmarks:) target:self];
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Quick Look", @"Menu item title") action:@selector(previewBookmarks:) target:self];
            [menu addItem:[NSMenuItem separatorItem]];
        }
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"New Folder", @"Menu item title") action:@selector(insertBookmarkFolder:) target:self];
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"New Separator", @"Menu item title") action:@selector(insertBookmarkSeparator:) target:self];
    } else {
        NSMenu *supermenu = [menu supermenu];
        NSInteger idx = [supermenu indexOfItemWithSubmenu:menu]; 
        SKBookmark *bm = nil;
        
        if (supermenu == [NSApp mainMenu])
            bm = [self bookmarkRoot];
        else if (idx >= 0)
            bm = [[supermenu itemAtIndex:idx] representedObject];
        
        if ([bm isKindOfClass:[SKBookmark class]]) {
            NSArray *bookmarks = [bm children];
            NSInteger i = [menu numberOfItems];
            while (i-- > 0 && ([[menu itemAtIndex:i] isSeparatorItem] || [[menu itemAtIndex:i] representedObject]))
                [menu removeItemAtIndex:i];
            if (supermenu == [NSApp mainMenu] && previousSession) {
                [menu addItem:[NSMenuItem separatorItem]];
                [self addItemForBookmark:previousSession toMenu:menu isFolder:NO isAlternate:NO];
                [self addItemForBookmark:previousSession toMenu:menu isFolder:YES isAlternate:YES];
            }
            if ([menu numberOfItems] > 0 && [bookmarks count] > 0)
                [menu addItem:[NSMenuItem separatorItem]];
            for (bm in bookmarks) {
                switch ([bm bookmarkType]) {
                    case SKBookmarkTypeFolder:
                        [self addItemForBookmark:bm toMenu:menu isFolder:YES isAlternate:NO];
                        [self addItemForBookmark:bm toMenu:menu isFolder:NO isAlternate:YES];
                        break;
                    case SKBookmarkTypeSession:
                        [self addItemForBookmark:bm toMenu:menu isFolder:NO isAlternate:NO];
                        [self addItemForBookmark:bm toMenu:menu isFolder:YES isAlternate:YES];
                        break;
                    case SKBookmarkTypeSeparator:
                        [menu addItem:[NSMenuItem separatorItem]];
                        break;
                    default:
                        [self addItemForBookmark:bm toMenu:menu isFolder:NO isAlternate:NO];
                        break;
                }
            }
        }
    }
}

// avoid rebuilding the bookmarks menu on every key event
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action { return NO; }

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
    NSError *error = nil;
    NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:bookmarksDictionary format:format options:0 error:&error];
    
	if (error) {
		NSLog(@"Error serializing: %@", error);
	} else {
        [data writeToFile:[self bookmarksFilePath] atomically:YES];
    }
}

- (void)endEditing {
    if ([outlineView editedRow] && [[self window] makeFirstResponder:outlineView] == NO)
        [[self window] endEditingFor:nil];
}

#pragma mark NSOutlineView datasource methods

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
        return [NSDictionary dictionaryWithObjectsAndKeys:[item label], SKTextWithIconStringKey, [item icon], SKTextWithIconImageKey, nil];
    } else if ([tcID isEqualToString:FILE_COLUMNID]) {
        if ([item bookmarkType] == SKBookmarkTypeFolder || [item bookmarkType] == SKBookmarkTypeSession) {
            NSInteger count = [item countOfChildren];
            return count == 1 ? NSLocalizedString(@"1 item", @"Bookmark folder description") : [NSString stringWithFormat:NSLocalizedString(@"%ld items", @"Bookmark folder description"), (long)count];
        } else {
            return [[[item fileURL] path] stringByAbbreviatingWithTildeInPath];
        }
    } else if ([tcID isEqualToString:PAGE_COLUMNID]) {
        return [item pageNumber];
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:LABEL_COLUMNID]) {
        NSString *newlabel = [object valueForKey:SKTextWithIconStringKey] ?: @"";
        if ([newlabel isEqualToString:[item label]] == NO)
            [item setLabel:newlabel];
    } else if ([tcID isEqualToString:PAGE_COLUMNID]) {
        if ([object isEqual:[item pageNumber]] == NO)
            [item setPageNumber:object];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    [self setDraggedBookmarks:minimumCoverForBookmarks(items)];
    [pboard clearContents];
    [pboard setData:[NSData data] forType:SKPasteboardTypeBookmarkRows];
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)anIndex {
    NSDragOperation dragOp = NSDragOperationNone;
    if (anIndex != NSOutlineViewDropOnItemIndex) {
        NSPasteboard *pboard = [info draggingPasteboard];
        if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:SKPasteboardTypeBookmarkRows, nil]] &&
            [info draggingSource] == ov)
            dragOp = NSDragOperationMove;
        else if ([NSURL canReadFileURLFromPasteboard:pboard])
            dragOp = NSDragOperationEvery;
    }
    return dragOp;
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)anIndex {
    NSPasteboard *pboard = [info draggingPasteboard];
    
    if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:SKPasteboardTypeBookmarkRows, nil]] &&
        [info draggingSource] == ov) {
        NSMutableArray *movedBookmarks = [NSMutableArray array];
        NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
        
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
            [movedBookmarks addObject:bookmark];
		}
        for (SKBookmark *bookmark in movedBookmarks) {
            NSInteger row = [outlineView rowForItem:bookmark];
            if (row != -1)
                [indexes addIndex:row];
        }
        if ([indexes count])
            [outlineView selectRowIndexes:indexes byExtendingSelection:NO];
        
        return YES;
    } else {
        NSArray *urls = [NSURL readFileURLsFromPasteboard:pboard];
        NSArray *newBookmarks = [SKBookmark bookmarksForURLs:urls];
        if ([newBookmarks count] > 0) {
            [self endEditing];
            if (item == nil) item = bookmarkRoot;
            NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(anIndex, [newBookmarks count])];
            [[item mutableArrayValueForKey:@"children"] insertObjects:newBookmarks atIndexes:indexes];
            if (item == bookmarkRoot || [outlineView isItemExpanded:item]) {
                if (item != bookmarkRoot)
                    [indexes shiftIndexesStartingAtIndex:0 by:[outlineView rowForItem:item] + 1];
                [outlineView selectRowIndexes:indexes byExtendingSelection:NO];
            }
            return YES;
        }
        return NO;
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
        return [item pageIndex] != NSNotFound;
    return NO;
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
    NSString *tcID = [tc identifier];
    
    if ([tcID isEqualToString:LABEL_COLUMNID]) {
        return [item label];
    } else if ([tcID isEqualToString:FILE_COLUMNID]) {
        if ([item bookmarkType] == SKBookmarkTypeSession) {
            return [[[item children] valueForKey:@"path"] componentsJoinedByString:@"\n"];
        } else if ([item bookmarkType] == SKBookmarkTypeFolder) {
            NSInteger count = [item countOfChildren];
            return count == 1 ? NSLocalizedString(@"1 item", @"Bookmark folder description") : [NSString stringWithFormat:NSLocalizedString(@"%ld items", @"Bookmark folder description"), (long)count];
        } else {
            return [[item fileURL] path];
        }
    } else if ([tcID isEqualToString:PAGE_COLUMNID]) {
        return [[item pageNumber] stringValue];
    }
    return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    [self updateStatus];
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible] && [[QLPreviewPanel sharedPreviewPanel] dataSource] == self)
        [[QLPreviewPanel sharedPreviewPanel] reloadData];
}

- (void)outlineView:(NSOutlineView *)ov deleteItems:(NSArray *)items {
    [self endEditing];
    for (SKBookmark *item in [minimumCoverForBookmarks(items) reverseObjectEnumerator]) {
        SKBookmark *parent = [item parent];
        NSUInteger itemIndex = [[parent children] indexOfObject:item];
        if (itemIndex != NSNotFound)
            [parent removeObjectFromChildrenAtIndex:itemIndex];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov canDeleteItems:(NSArray *)items {
    return [items count] > 0;
}

static void addBookmarkURLsToArray(NSArray *items, NSMutableArray *array) {
    for (SKBookmark *bm in items) {
        if ([bm bookmarkType] == SKBookmarkTypeBookmark) {
            NSURL *url = [bm fileURL];
            if (url)
                [array addObject:url];
        } else if ([bm bookmarkType] != SKBookmarkTypeSeparator) {
            addBookmarkURLsToArray([bm children], array);
        }
    }
}

- (void)outlineView:(NSOutlineView *)ov copyItems:(NSArray *)items {
    NSMutableArray *urls = [NSMutableArray array];
    addBookmarkURLsToArray(minimumCoverForBookmarks(items), urls);
    if ([urls count] > 0) {
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        [pboard clearContents];
        [pboard writeObjects:urls];
    } else {
        NSBeep();
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov canCopyItems:(NSArray *)items {
    return [items count] > 0;
}

- (void)outlineView:(NSOutlineView *)ov pasteFromPasteboard:(NSPasteboard *)pboard {
    NSArray *urls = [NSURL readFileURLsFromPasteboard:pboard];
    if ([urls count] > 0) {
        NSArray *newBookmarks = [SKBookmark bookmarksForURLs:urls];
        if ([newBookmarks count] > 0) {
            SKBookmark *item = nil;
            NSUInteger anIndex = 0;
            [self getInsertionFolder:&item childIndex:&anIndex];
            NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(anIndex, [newBookmarks count])];
            [[item mutableArrayValueForKey:@"children"] insertObjects:newBookmarks atIndexes:indexes];
            if (item == bookmarkRoot || [outlineView isItemExpanded:item]) {
                if (item != bookmarkRoot)
                    [indexes shiftIndexesStartingAtIndex:0 by:[outlineView rowForItem:item] + 1];
                [outlineView selectRowIndexes:indexes byExtendingSelection:NO];
            }
        } else NSBeep();
    } else NSBeep();
}

- (BOOL)outlineView:(NSOutlineView *)ov canPasteFromPasteboard:(NSPasteboard *)pboard {
    return [NSURL canReadFileURLFromPasteboard:pboard];
}

- (NSArray *)outlineView:(NSOutlineView *)ov typeSelectHelperSelectionStrings:(SKTypeSelectHelper *)typeSelectHelper {
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
    } else if ([menuItem action] == @selector(addBookmark:)) {
        return [menuItem tag] == 0;
    }
    return YES;
}

#pragma mark Quick Look Panel Support

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    [panel setDelegate:self];
    [panel setDataSource:self];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
}

- (NSArray *)previewItems {
    NSMutableArray *items = [NSMutableArray array];
    
    [[outlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        SKBookmark *item = [outlineView itemAtRow:idx];
        if ([item bookmarkType] == SKBookmarkTypeBookmark)
            [items addObject:item];
        else if ([item bookmarkType] == SKBookmarkTypeSession)
            [items addObjectsFromArray:[item children]];
    }];
    return items;
}

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    return [[self previewItems] count];
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)anIndex {
    return [[self previewItems] objectAtIndex:anIndex];
}

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item {
    if ([[(SKBookmark *)item parent] bookmarkType] == SKBookmarkTypeSession)
        item = [(SKBookmark *)item parent];
    NSInteger row = [outlineView rowForItem:item];
    NSRect iconRect = NSZeroRect;
    if (item != nil && row != -1) {
        iconRect = [(SKTextWithIconCell *)[outlineView preparedCellAtColumn:0 row:row] iconRectForBounds:[outlineView frameOfCellAtColumn:0 row:row]];
        if (NSIntersectsRect([outlineView visibleRect], iconRect)) {
            iconRect = [outlineView convertRectToBase:iconRect];
            iconRect.origin = [[self window] convertBaseToScreen:iconRect.origin];
        } else {
            iconRect = NSZeroRect;
        }
    }
    return iconRect;
}

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event {
    if ([event type] == NSKeyDown) {
        [outlineView keyDown:event];
        return YES;
    }
    return NO;
}

@end
