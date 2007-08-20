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
#import "NSTableView_SKExtensions.h"

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
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil]];
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
    [self saveBookmarks];
}

- (void)removeObjectFromBookmarksAtIndex:(unsigned)index {
    [[[self undoManager] prepareWithInvocationTarget:self] insertObject:[bookmarks objectAtIndex:index] inBookmarksAtIndex:index];
    [bookmarks removeObjectAtIndex:index];
    [self saveBookmarks];
}

- (void)addBookmarkForPath:(NSString *)path pageIndex:(unsigned)pageIndex label:(NSString *)label {
    if (path == nil)
        return;
    SKBookmark *bookmark = [[SKBookmark alloc] initWithPath:path pageIndex:pageIndex label:label];
    [[self mutableArrayValueForKey:@"bookmarks"] addObject:bookmark];
    [bookmark release];
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

#pragma mark Undo support

- (NSUndoManager *)undoManager {
    if(undoManager == nil)
        undoManager = [[NSUndoManager alloc] init];
    return undoManager;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
    return [self undoManager];
}

#pragma mark NSTableView datasource methods

- (int)numberOfRowsInTableView:(NSTableView *)tv { return 0; }

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row { return nil; }

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    [pboard declareTypes:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil] owner:nil];
    [pboard setPropertyList:[NSNumber numberWithUnsignedInt:[rowIndexes firstIndex]] forType:SKBookmarkRowsPboardType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil]];
    
    if (type) {
        [tv setDropRow:row == -1 ? [tv numberOfRows] : row dropOperation:NSTableViewDropAbove];
        return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:SKBookmarkRowsPboardType, nil]];
    
    if (type) {
        int draggedRow = [[pboard propertyListForType:SKBookmarkRowsPboardType] intValue];
        SKBookmark *bookmark = [[bookmarks objectAtIndex:draggedRow] retain];
        [self removeObjectFromBookmarksAtIndex:draggedRow];
        [self insertObject:bookmark inBookmarksAtIndex:row < draggedRow ? row : row - 1];
        [bookmark release];
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        return YES;
    }
    return NO;
}

#pragma mark NSTableView delegate methods

- (NSString *)tableView:(NSTableView *)tv toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation {
    NSString *tcID = [tableColumn identifier];
    SKBookmark *bookmark = [self objectInBookmarksAtIndex:row];
    
    if ([tcID isEqualToString:@"label"]) {
        return [bookmark label];
    } else if ([tcID isEqualToString:@"file"]) {
        return [bookmark resolvedPath];
    } else if ([tcID isEqualToString:@"page"]) {
        return [[bookmark pageNumber] stringValue];
    }
    return nil;
}

- (void)tableView:(NSTableView *)aTableView deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    int row = [rowIndexes firstIndex];
    [self removeObjectFromBookmarksAtIndex:row];
}

- (BOOL)tableView:(NSTableView *)aTableView canDeleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    return YES;
}

@end

#pragma mark -

@implementation SKBookmark

- (id)initWithPath:(NSString *)aPath aliasData:(NSData *)aData pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    if (self = [super init]) {
        path = [aPath copy];
        aliasData = [aData copy];
        pageIndex = aPageIndex;
        label = [aLabel copy];
    }
    return self;
}

- (id)initWithPath:(NSString *)aPath pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    return [self initWithPath:aPath aliasData:[[BDAlias aliasWithPath:aPath] aliasData] pageIndex:aPageIndex label:aLabel];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    return [self initWithPath:[dictionary objectForKey:@"path"] aliasData:[dictionary objectForKey:@"_BDAlias"] pageIndex:[[dictionary objectForKey:@"pageIndex"] unsignedIntValue] label:[dictionary objectForKey:@"label"]];
}

- (id)copyWithZone:(NSZone *)aZone {
    return [[[self class] allocWithZone:aZone] initWithPath:path aliasData:aliasData pageIndex:pageIndex label:label];
}

- (void)dealloc {
    [[[SKBookmarkController sharedBookmarkController] undoManager] removeAllActionsWithTarget:self];
    [path release];
    [aliasData release];
    [label release];
    [super dealloc];
}

- (NSDictionary *)dictionaryValue {
    return [NSDictionary dictionaryWithObjectsAndKeys:path, @"path", aliasData, @"_BDAlias", [NSNumber numberWithUnsignedInt:pageIndex], @"pageIndex", label, @"label", nil];
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

- (unsigned int)pageIndex {
    return pageIndex;
}

- (NSNumber *)pageNumber {
    return [NSNumber numberWithUnsignedInt:pageIndex + 1];
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

@end
