//
//  SKBookmark.m
//  Skim
//
//  Created by Christiaan Hofman on 9/15/07.
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

#import "SKBookmark.h"
#import "SKBookmarkController.h"
#import "BDAlias.h"
#import "NSImage_SKExtensions.h"

NSString *SKBookmarkChangedNotification = @"SKBookmarkChangedNotification";
NSString *SKBookmarkWillBeRemovedNotification = @"SKBookmarkWillBeRemovedNotification";

static NSString *SKBookmarkTypeBookmarkString = @"bookmark";
static NSString *SKBookmarkTypeFolderString = @"folder";
static NSString *SKBookmarkTypeSeparatorString = @"separator";

#define CHILDREN_KEY    @"children"
#define LABEL_KEY       @"label"
#define PAGE_INDEX_KEY  @"pageIndex"
#define ALIAS_DATA_KEY  @"_BDAlias"
#define TYPE_KEY        @"type"

@implementation SKBookmark

+ (NSImage *)smallImageForFile:(NSString *)filePath {
    static NSMutableDictionary *smallIcons = nil;
    
    if (filePath == nil)
        return [NSImage smallMissingFileImage];
    
    NSString *extension = [filePath pathExtension];
    NSImage *icon = [smallIcons objectForKey:extension];
    
    if (icon == nil) {
        if (smallIcons == nil)
            smallIcons = [[NSMutableDictionary alloc] init];
        NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
        if (image) {
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
    }
    return icon;
}

- (id)initWithAlias:(BDAlias *)anAlias pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    if (self = [super init]) {
        if (anAlias) {
            bookmarkType = SKBookmarkTypeBookmark;
            alias = [anAlias retain];
            pageIndex = aPageIndex;
            label = [aLabel copy];
            children = nil;
        } else {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithAliasData:(NSData *)aData pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    return [self initWithAlias:[BDAlias aliasWithData:aData] pageIndex:aPageIndex label:aLabel];
}

- (id)initWithPath:(NSString *)aPath pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    return [self initWithAlias:[BDAlias aliasWithPath:aPath] pageIndex:aPageIndex label:aLabel];
}

- (id)initFolderWithChildren:(NSArray *)aChildren label:(NSString *)aLabel {
    if (self = [super init]) {
        bookmarkType = SKBookmarkTypeFolder;
        alias = nil;
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

- (id)initSeparator {
    if (self = [super init]) {
        bookmarkType = SKBookmarkTypeSeparator;
        alias = nil;
        pageIndex = NSNotFound;
        label = nil;
        children = nil;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if ([[dictionary objectForKey:TYPE_KEY] isEqualToString:SKBookmarkTypeFolderString]) {
        NSEnumerator *dictEnum = [[dictionary objectForKey:CHILDREN_KEY] objectEnumerator];
        NSDictionary *dict;
        NSMutableArray *newChildren = [NSMutableArray array];
        while (dict = [dictEnum nextObject])
            [newChildren addObject:[[[[self class] alloc] initWithDictionary:dict] autorelease]];
        return [self initFolderWithChildren:newChildren label:[dictionary objectForKey:LABEL_KEY]];
    } else if ([[dictionary objectForKey:TYPE_KEY] isEqualToString:SKBookmarkTypeSeparatorString]) {
        return [self initSeparator];
    } else {
        return [self initWithAliasData:[dictionary objectForKey:ALIAS_DATA_KEY] pageIndex:[[dictionary objectForKey:PAGE_INDEX_KEY] unsignedIntValue] label:[dictionary objectForKey:LABEL_KEY]];
    }
}

- (id)copyWithZone:(NSZone *)aZone {
    if (bookmarkType == SKBookmarkTypeFolder)
        return [[[self class] allocWithZone:aZone] initFolderWithChildren:[[[NSArray alloc] initWithArray:children copyItems:YES] autorelease] label:label];
    else if (bookmarkType == SKBookmarkTypeSeparator)
        return [[[self class] allocWithZone:aZone] initSeparator];
    else
        return [[[self class] allocWithZone:aZone] initWithAlias:alias pageIndex:pageIndex label:label];
}

- (void)dealloc {
    [[[SKBookmarkController sharedBookmarkController] undoManager] removeAllActionsWithTarget:self];
    [alias release];
    [label release];
    [children release];
    [super dealloc];
}

- (NSString *)description {
    if (bookmarkType == SKBookmarkTypeFolder)
        return [NSString stringWithFormat:@"<%@: label=%@, children=%@>", [self class], label, children];
    else if (bookmarkType == SKBookmarkTypeSeparator)
        return [NSString stringWithFormat:@"<%@: separator>", [self class]];
    else
        return [NSString stringWithFormat:@"<%@: label=%@, path=%@, page=%i>", [self class], label, [self path], pageIndex];
}

- (NSDictionary *)dictionaryValue {
    if (bookmarkType == SKBookmarkTypeFolder)
        return [NSDictionary dictionaryWithObjectsAndKeys:SKBookmarkTypeFolderString, TYPE_KEY, [children valueForKey:@"dictionaryValue"], CHILDREN_KEY, label, LABEL_KEY, nil];
    else if (bookmarkType == SKBookmarkTypeSeparator)
        return [NSDictionary dictionaryWithObjectsAndKeys:SKBookmarkTypeSeparatorString, TYPE_KEY, nil];
    else
        return [NSDictionary dictionaryWithObjectsAndKeys:SKBookmarkTypeBookmarkString, TYPE_KEY, [self aliasData], ALIAS_DATA_KEY, [NSNumber numberWithUnsignedInt:pageIndex], PAGE_INDEX_KEY, label, LABEL_KEY, nil];
}

- (int)bookmarkType {
    return bookmarkType;
}

- (NSString *)path {
    return [alias fullPathNoUI];
}

- (BDAlias *)alias {
    return alias;
}

- (NSData *)aliasData {
    return [alias aliasData];
}

- (NSImage *)icon {
    if ([self bookmarkType] == SKBookmarkTypeFolder)
        return [NSImage imageNamed:@"SmallFolder"];
    else if (bookmarkType == SKBookmarkTypeSeparator)
        return nil;
    else
        return [[self class] smallImageForFile:[self path]];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:SKBookmarkWillBeRemovedNotification object:self];
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

- (BOOL)isDescendantOfArray:(NSArray *)bookmarks {
    NSEnumerator *bmEnum = [bookmarks objectEnumerator];
    SKBookmark *bm = nil;
    while (bm = [bmEnum nextObject]) {
        if ([self isDescendantOf:bm]) return YES;
    }
    return NO;
}

@end
