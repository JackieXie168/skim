//
//  SKBookmarkController.m
//  Skim
//
//  Created by Christiaan Hofman on 3/16/07.
/*
 This software is Copyright (c) 2007-2012
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
#import "SKTypeSelectHelper.h"
#import "SKStatusBar.h"
#import "SKTextWithIconCell.h"
#import "SKToolbarItem.h"
#import "NSImage_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKSeparatorCell.h"
#import "NSMenu_SKExtensions.h"
#import "NSURL_SKExtensions.h"

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
    
    [outlineView registerForDraggedTypes:[NSArray arrayWithObjects:SKPasteboardTypeBookmarkRows, (NSString *)kUTTypeFileURL, nil]];
    
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

#pragma mark Recent Documents

- (NSDictionary *)recentDocumentInfoAtPath:(NSString *)path {
    for (NSMutableDictionary *info in recentDocuments) {
        BDAlias *alias = [info valueForKey:ALIAS_KEY];
        if (alias == nil) {
            alias = [BDAlias aliasWithData:[info valueForKey:ALIASDATA_KEY]];
            [info setValue:alias forKey:ALIAS_KEY];
        }
        if ([[alias fullPathNoUI] isEqualToString:path])
            return info;
    }
    return nil;
}

- (void)addRecentDocumentForPath:(NSString *)path pageIndex:(NSUInteger)pageIndex snapshots:(NSArray *)setups {
    if (path == nil)
        return;
    
    NSDictionary *info = [self recentDocumentInfoAtPath:path];
    if (info)
        [recentDocuments removeObjectIdenticalTo:info];
    
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
    NSDictionary *info = [self recentDocumentInfoAtPath:path];
    return info == nil ? NSNotFound : [[info objectForKey:PAGEINDEX_KEY] unsignedIntegerValue];
}

- (NSArray *)snapshotsForRecentDocumentAtPath:(NSString *)path {
    if (path == nil)
        return nil;
    NSArray *setups = [[self recentDocumentInfoAtPath:path] objectForKey:SNAPSHOTS_KEY];
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

- (IBAction)deleteBookmark:(id)sender {
    [outlineView delete:sender];
}

- (IBAction)toggleStatusBar:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:(NO == [statusBar isVisible]) forKey:SKShowBookmarkStatusBarKey];
    [statusBar toggleBelowView:[outlineView enclosingScrollView] animate:sender != nil];
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
            return [[item path] stringByAbbreviatingWithTildeInPath];
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
        else if ([pboard canReadObjectForClasses:[NSArray arrayWithObject:[NSURL class]] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, nil]])
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
        NSArray *urls = [pboard readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, nil]];
        NSArray *newBookmarks = [SKBookmark bookmarksForPaths:[urls valueForKey:@"path"] relativeToPath:nil];
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
            return [item path];
        }
    } else if ([tcID isEqualToString:PAGE_COLUMNID]) {
        return [[item pageNumber] stringValue];
    }
    return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    [self updateStatus];
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

- (void)outlineView:(NSOutlineView *)ov pasteFromPasteboard:(NSPasteboard *)pboard {
    NSArray *urls = [pboard readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, nil]];
    if ([urls count] > 0) {
        NSArray *newBookmarks = [SKBookmark bookmarksForPaths:[urls valueForKey:@"path"] relativeToPath:nil];
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
    return [pboard canReadObjectForClasses:[NSArray arrayWithObject:[NSURL class]] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, nil]];
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
    }
    return YES;
}

@end
