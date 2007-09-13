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
#import "BDAlias.h"
#import "SKDocument.h"
#import "SKMainWindowController.h"
#import "Files_SKExtensions.h"
#import "SKOutlineView.h"
#import "SKTableView.h"
#import "SKTypeSelectHelper.h"
#import "SKStatusBar.h"
#import "SKTextWithIconCell.h"

static NSString *SKBookmarkRowsPboardType = @"SKBookmarkRowsPboardType";
static NSString *SKBookmarkChangedNotification = @"SKBookmarkChangedNotification";

@implementation SKBookmarkController

static unsigned int maxRecentDocumentsCount = 0;

+ (void)initialize {
    maxRecentDocumentsCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"SKMaximumDocumentPageHistoryCount"];
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
            NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
            id plist = [NSPropertyListSerialization propertyListFromData:data
                                                        mutabilityOption:NSPropertyListImmutable
                                                                  format:&format 
                                                        errorDescription:&error];
            
            if (error) {
                NSLog(@"Error deserializing: %@", error);
                [error release];
            } else if ([plist isKindOfClass:[NSDictionary class]]) {
                [recentDocuments addObjectsFromArray:[plist objectForKey:@"recentDocuments"]];
                NSEnumerator *dictEnum = [[plist objectForKey:@"bookmarks"] objectEnumerator];
                NSDictionary *dict;
                
                while (dict = [dictEnum nextObject]) {
                    SKBookmark *bookmark = [[SKBookmark alloc] initWithDictionary:dict];
                    [bookmarks addObject:bookmark];
                    [bookmark release];
                }
            }
        }
        
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBookmarkChangedNotification:)
                                                     name:SKBookmarkChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [bookmarks release];
    [recentDocuments release];
    [super dealloc];
}

- (NSString *)windowNibName { return @"BookmarksWindow"; }

- (void)windowDidLoad {
    [self setWindowFrameAutosaveName:@"SKBookmarksWindow"];
    
    SKTypeSelectHelper *typeSelectHelper = [[[SKTypeSelectHelper alloc] init] autorelease];
    [typeSelectHelper setDataSource:self];
    [outlineView setTypeSelectHelper:typeSelectHelper];
    
    [outlineView registerForDraggedTypes:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil]];
    
    [outlineView setDoubleAction:@selector(doubleClickBookmark:)];
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
    [bookmarks removeObjectAtIndex:index];
    [self handleBookmarkChangedNotification:nil];
}

- (void)addBookmarkForPath:(NSString *)path pageIndex:(unsigned)pageIndex label:(NSString *)label {
    if (path == nil)
        return;
    SKBookmark *bookmark = [[SKBookmark alloc] initWithPath:path pageIndex:pageIndex label:label];
    [[self mutableArrayValueForKey:@"bookmarks"] addObject:bookmark];
    [bookmark release];
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

#pragma mark Recent Documents

- (NSArray *)recentDocuments {
    return recentDocuments;
}

- (unsigned int)indexOfRecentDocumentAtPath:(NSString *)path {
    unsigned int index = [[recentDocuments valueForKey:@"path"] indexOfObject:path];
    if (index == NSNotFound) {
        unsigned int i, iMax = [recentDocuments count];
        for (i = 0; i < iMax; i++) {
            NSData *aliasData = [[recentDocuments objectAtIndex:i] valueForKey:@"_BDAlias"];
            if ([[[BDAlias aliasWithData:aliasData] fullPathNoUI] isEqualToString:path]) {
                index = i;
                break;
            }
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
    
    NSData *data = [[BDAlias aliasWithPath:path] aliasData];
    NSMutableDictionary *bm = [NSMutableDictionary dictionaryWithObjectsAndKeys:path, @"path", [NSNumber numberWithUnsignedInt:pageIndex], @"pageIndex", data, @"_BDAlias", [setups count] ? setups : nil, @"snapshots", nil];
    [recentDocuments insertObject:bm atIndex:0];
    if ([recentDocuments count] > maxRecentDocumentsCount)
        [recentDocuments removeLastObject];
    
    [self saveBookmarks];
}

- (unsigned int)pageIndexForRecentDocumentAtPath:(NSString *)path {
    if (path == nil)
        return NSNotFound;
    unsigned int index = [self indexOfRecentDocumentAtPath:path];
    return index == NSNotFound ? NSNotFound : [[[recentDocuments objectAtIndex:index] objectForKey:@"pageIndex"] unsignedIntValue];
}

- (NSArray *)snapshotsAtPath:(NSString *)path {
    if (path == nil)
        return nil;
    unsigned int index = [self indexOfRecentDocumentAtPath:path];
    NSArray *setups = index == NSNotFound ? nil : [[recentDocuments objectAtIndex:index] objectForKey:@"snapshots"];
    return [setups count] ? setups : nil;
}

- (void)saveBookmarks {
    NSDictionary *bookmarksDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[bookmarks valueForKey:@"dictionaryValue"], @"bookmarks", recentDocuments, @"recentDocuments", nil];
    NSString *error = nil;
    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:bookmarksDictionary format:format errorDescription:&error];
    
	if (error) {
		NSLog(@"Error deserializing: %@", error);
        [error release];
	} else {
        [data writeToFile:[self bookmarksFilePath] atomically:YES];
    }
}

- (void)handleBookmarkChangedNotification:(NSNotification *)notification {
    [self saveBookmarks];
    [outlineView reloadData];
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
        NSString *path = [bm resolvedPath];
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
        return [item resolvedPath];
    } else if ([tcID isEqualToString:@"page"]) {
        return [[item pageNumber] stringValue];
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)ov setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSString *tcID = [tableColumn identifier];
    if ([tcID isEqualToString:@"label"]) {
        [item setLabel:object];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    SKBookmark *item = [items objectAtIndex:0];
    [pboard declareTypes:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil] owner:nil];
    [pboard setPropertyList:[NSNumber numberWithUnsignedInt:[outlineView rowForItem:item]] forType:SKBookmarkRowsPboardType];
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
        return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil]];
    
    if (type) {
        int draggedRow = [[pboard propertyListForType:SKBookmarkRowsPboardType] intValue];
        SKBookmark *bookmark = [outlineView itemAtRow:draggedRow];
        if ([(SKBookmark *)item isDescendantOf:bookmark])
            return NO;
        if ([bookmark parent] == item) {
            int draggedIndex = [self indexOfChildBookmark:bookmark];
            if (index > draggedIndex)
                index--;
            if (index == draggedIndex)
                return NO;
        }
        [bookmark retain];
        [self removeChildBookmark:bookmark];
        [self bookmark:item insertChildBookmark:bookmark atIndex:index];
        [bookmark release];
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[outlineView rowForItem:bookmark]] byExtendingSelection:NO];
        return YES;
    }
    return NO;
}

#pragma mark NSOutlineView delegate methods

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
    NSString *tcID = [tc identifier];
    
    if ([tcID isEqualToString:@"label"]) {
        return [item label];
    } else if ([tcID isEqualToString:@"file"]) {
        return [item resolvedPath];
    } else if ([tcID isEqualToString:@"page"]) {
        return [[item pageNumber] stringValue];
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)ov deleteItems:(NSArray *)items {
    SKBookmark *item = [items objectAtIndex:0];
    [self removeChildBookmark:item];
}

- (BOOL)outlineView:(NSOutlineView *)ov canDeleteItems:(NSArray *)items {
    return [items count] > 0;
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
    NSString *message = @"";
    if (searchString)
        message = [NSString stringWithFormat:NSLocalizedString(@"Finding: \"%@\"", @"Status message"), searchString];
    [statusBar setLeftStringValue:message];
}

@end

#pragma mark -

@implementation SKBookmark

+ (NSImage *)smallImageForFile:(NSString *)filePath {
    static NSMutableDictionary *smallIcons = nil;
    if (smallIcons == nil)
        smallIcons = [[NSMutableDictionary alloc] init];
    
    NSString *extension = [filePath pathExtension];
    NSImage *icon = [smallIcons objectForKey:extension];
    
    if (icon == nil) {
        NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
        NSRect sourceRect = {NSZeroPoint, [image size]};
        NSRect targetRect = NSMakeRect(0.0, 0.0, 16.0, 16.0);
        icon = [[NSImage alloc] initWithSize:targetRect.size];
        [icon lockFocus];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [image drawInRect:targetRect fromRect:sourceRect operation:NSCompositeCopy fraction:1.0];
        [icon unlockFocus];
        [smallIcons setObject:icon forKey:extension];
        [icon release];
    }
    return icon;
}

- (id)initWithPath:(NSString *)aPath aliasData:(NSData *)aData pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    if (self = [super init]) {
        bookmarkType = SKBookmarkTypeBookmark;
        path = [aPath copy];
        aliasData = [aData copy];
        pageIndex = aPageIndex;
        label = [aLabel copy];
        children = nil;
    }
    return self;
}

- (id)initWithPath:(NSString *)aPath pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    return [self initWithPath:aPath aliasData:[[BDAlias aliasWithPath:aPath] aliasData] pageIndex:aPageIndex label:aLabel];
}

- (id)initFolderWithChildren:(NSArray *)aChildren label:(NSString *)aLabel {
    if (self = [super init]) {
        bookmarkType = SKBookmarkTypeFolder;
        path = nil;
        aliasData = nil;
        pageIndex = NSNotFound;
        label = [aLabel copy];
        children = [aChildren mutableCopy];
        [children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
    }
    return self;
}

- (id)initFolderWithLabel:(NSString *)aLabel {
    return [self initFolderWithChildren:[NSArray array] label:aLabel];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if ([[dictionary objectForKey:@"type"] isEqualToString:@"folder"]) {
        NSEnumerator *dictEnum = [[dictionary objectForKey:@"children"] objectEnumerator];
        NSDictionary *dict;
        NSMutableArray *newChildren = [NSMutableArray array];
        while (dict = [dictEnum nextObject])
            [newChildren addObject:[[[[self class] alloc] initWithDictionary:dict] autorelease]];
        return [self initFolderWithChildren:newChildren label:[dictionary objectForKey:@"label"]];
    } else {
        return [self initWithPath:[dictionary objectForKey:@"path"] aliasData:[dictionary objectForKey:@"_BDAlias"] pageIndex:[[dictionary objectForKey:@"pageIndex"] unsignedIntValue] label:[dictionary objectForKey:@"label"]];
    }
}

- (id)copyWithZone:(NSZone *)aZone {
    if (bookmarkType == SKBookmarkTypeFolder)
        return [[[self class] allocWithZone:aZone] initFolderWithChildren:[[[NSArray alloc] initWithArray:children copyItems:YES] autorelease] label:label];
    else
        return [[[self class] allocWithZone:aZone] initWithPath:path aliasData:aliasData pageIndex:pageIndex label:label];
}

- (void)dealloc {
    [[[SKBookmarkController sharedBookmarkController] undoManager] removeAllActionsWithTarget:self];
    [path release];
    [aliasData release];
    [label release];
    [children release];
    [super dealloc];
}

- (NSString *)description {
    if (bookmarkType == SKBookmarkTypeFolder)
        return [NSString stringWithFormat:@"<%@: label=%@, children=%@>", [self class], label, children];
    else
        return [NSString stringWithFormat:@"<%@: label=%@, path=%@, page=%i>", [self class], label, path, pageIndex];
}

- (NSDictionary *)dictionaryValue {
    if (bookmarkType == SKBookmarkTypeFolder)
        return [NSDictionary dictionaryWithObjectsAndKeys:@"folder", @"type", [children valueForKey:@"dictionaryValue"], @"children", label, @"label", nil];
    else
        return [NSDictionary dictionaryWithObjectsAndKeys:@"bookmark", @"type", path, @"path", aliasData, @"_BDAlias", [NSNumber numberWithUnsignedInt:pageIndex], @"pageIndex", label, @"label", nil];
}

- (int)bookmarkType {
    return bookmarkType;
}

- (NSString *)path {
    return [[path retain] autorelease];
}

- (NSData *)aliasData {
    return aliasData;
}

- (NSString *)resolvedPath {
    NSString *resolvedPath = [[BDAlias aliasWithData:aliasData] fullPathNoUI];
    if (resolvedPath == nil)
        resolvedPath = path;
    return resolvedPath;
}

- (NSImage *)icon {
    if ([self bookmarkType] == SKBookmarkTypeFolder)
        return [NSImage imageNamed:@"SmallFolder"];
    else
        return [[self class] smallImageForFile:[self resolvedPath]];
}

- (unsigned int)pageIndex {
    return pageIndex;
}

- (NSNumber *)pageNumber {
    return pageIndex == NSNotFound ? nil : [NSNumber numberWithUnsignedInt:pageIndex + 1];
}

- (NSString *)label {
    return label;
}

- (void)setLabel:(NSString *)newLabel {
    if (label != newLabel) {
        NSUndoManager *undoManager = [[SKBookmarkController sharedBookmarkController] undoManager];
        [(SKBookmark *)[undoManager prepareWithInvocationTarget:self] setLabel:label];
        [label release];
        label = [newLabel retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKBookmarkChangedNotification object:self];
    }
}

- (SKBookmark *)parent {
    return parent;
}

- (void)setParent:(SKBookmark *)newParent {
    parent = newParent;
}

- (NSArray *)children {
    return children;
}

- (void)insertChild:(SKBookmark *)child atIndex:(unsigned int)index {
    NSUndoManager *undoManager = [[SKBookmarkController sharedBookmarkController] undoManager];
    [(SKBookmark *)[undoManager prepareWithInvocationTarget:self] removeChild:child];
    [children insertObject:child atIndex:index];
    [child setParent:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKBookmarkChangedNotification object:self];
}

- (void)addChild:(SKBookmark *)child {
    [self insertChild:child atIndex:[children count]];
}

- (void)removeChild:(SKBookmark *)child {
    NSUndoManager *undoManager = [[SKBookmarkController sharedBookmarkController] undoManager];
    [(SKBookmark *)[undoManager prepareWithInvocationTarget:self] insertChild:child atIndex:[[self children] indexOfObject:child]];
    [child setParent:nil];
    [children removeObject:child];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKBookmarkChangedNotification object:self];
}

- (BOOL)isDescendantOf:(SKBookmark *)bookmark {
    if (self == bookmark)
        return YES;
    NSEnumerator *childEnum = [[bookmark children] objectEnumerator];
    SKBookmark *child;
    while (child = [childEnum nextObject]) {
        if ([self isDescendantOf:child])
            return YES;
    }
    return NO;
}

@end
