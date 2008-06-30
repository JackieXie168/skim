//
//  SKBookmark.m
//  Skim
//
//  Created by Christiaan Hofman on 9/15/07.
/*
 This software is Copyright (c) 2007-2008
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
#import "BDAlias.h"
#import "NSImage_SKExtensions.h"
#import "SKUtilities.h"

NSString *SKBookmarkChangedNotification = @"SKBookmarkChangedNotification";
NSString *SKBookmarkWillBeRemovedNotification = @"SKBookmarkWillBeRemovedNotification";

static NSString *SKBookmarkTypeBookmarkString = @"bookmark";
static NSString *SKBookmarkTypeFolderString = @"folder";
static NSString *SKBookmarkTypeSeparatorString = @"separator";

static NSString *SKBookmarkPropertiesKey = @"properties";

static NSString *SKBookmarkChildrenKey = @"children";
static NSString *SKBookmarkLabelKey = @"label";
static NSString *SKBookmarkPageIndexKey = @"pageIndex";
static NSString *SKBookmarkAliasDataKey = @"_BDAlias";
static NSString *SKBookmarkTypeKey = @"type";

@interface SKFileBookmark : SKBookmark {
    BDAlias *alias;
    NSData *aliasData;
    NSString *label;
    unsigned int pageIndex;
}
@end

@interface SKFolderBookmark : SKBookmark {
    NSString *label;
    NSMutableArray *children;
}
@end

@interface SKSeparatorBookmark : SKBookmark
@end

@implementation SKBookmark

static SKBookmark *defaultPlaceholderBookmark = nil;
static Class SKBookmarkClass = Nil;

+ (void)initialize {
    OBINITIALIZE;
    if (self == [SKBookmark class]) {
        SKBookmarkClass = self;
        defaultPlaceholderBookmark = (SKBookmark *)NSAllocateObject(SKBookmarkClass, 0, NSDefaultMallocZone());
    }
}

+ (id)allocWithZone:(NSZone *)aZone {
    return SKBookmarkClass == self ? defaultPlaceholderBookmark : NSAllocateObject(self, 0, aZone);
}

- (id)init {
    return self != defaultPlaceholderBookmark ? [super init] : nil;
}

- (id)initWithAlias:(BDAlias *)anAlias pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    if (self != defaultPlaceholderBookmark)
        [self release];
    return [[SKFileBookmark alloc] initWithAlias:anAlias pageIndex:aPageIndex label:aLabel];
}

- (id)initWithAliasData:(NSData *)aData pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    return [self initWithAlias:[BDAlias aliasWithData:aData] pageIndex:aPageIndex label:aLabel];
}

- (id)initWithPath:(NSString *)aPath pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    return [self initWithAlias:[BDAlias aliasWithPath:aPath] pageIndex:aPageIndex label:aLabel];
}

- (id)initFolderWithChildren:(NSArray *)aChildren label:(NSString *)aLabel {
    if (self != defaultPlaceholderBookmark)
        [self release];
    return [[SKFolderBookmark alloc] initFolderWithChildren:aChildren label:aLabel];
}

- (id)initFolderWithLabel:(NSString *)aLabel {
    return [self initFolderWithChildren:[NSArray array] label:aLabel];
}

- (id)initSeparator {
    if (self != defaultPlaceholderBookmark)
        [self release];
    return [[SKSeparatorBookmark alloc] init];
}

- (id)initWithProperties:(NSDictionary *)dictionary {
    if ([[dictionary objectForKey:SKBookmarkTypeKey] isEqualToString:SKBookmarkTypeFolderString]) {
        NSEnumerator *dictEnum = [[dictionary objectForKey:SKBookmarkChildrenKey] objectEnumerator];
        NSDictionary *dict;
        NSMutableArray *newChildren = [NSMutableArray array];
        while (dict = [dictEnum nextObject])
            [newChildren addObject:[[[[self class] alloc] initWithProperties:dict] autorelease]];
        return [self initFolderWithChildren:newChildren label:[dictionary objectForKey:SKBookmarkLabelKey]];
    } else if ([[dictionary objectForKey:SKBookmarkTypeKey] isEqualToString:SKBookmarkTypeSeparatorString]) {
        return [self initSeparator];
    } else {
        return [self initWithAliasData:[dictionary objectForKey:SKBookmarkAliasDataKey] pageIndex:[[dictionary objectForKey:SKBookmarkPageIndexKey] unsignedIntValue] label:[dictionary objectForKey:SKBookmarkLabelKey]];
    }
}

- (id)copyWithZone:(NSZone *)aZone {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)dealloc {
    [undoManager release];
    if (self != defaultPlaceholderBookmark)
        [super dealloc];
}

- (NSDictionary *)properties { return nil; }

- (int)bookmarkType { return SKBookmarkTypeSeparator; }

- (NSImage *)icon { return nil; }

- (NSString *)label { return nil; }
- (void)setLabel:(NSString *)newLabel {}

- (NSString *)path { return nil; }
- (BDAlias *)alias { return nil; }
- (NSData *)aliasData { return nil; }
- (unsigned int)pageIndex { return NSNotFound; }
- (NSNumber *)pageNumber { return nil; }

- (NSArray *)children { return nil; }
- (void)insertChild:(SKBookmark *)child atIndex:(unsigned int)anIndex {}
- (void)addChild:(SKBookmark *)child {}
- (void)removeChild:(SKBookmark *)child {}

- (SKBookmark *)parent {
    return parent;
}

- (void)setParent:(SKBookmark *)newParent {
    parent = newParent;
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

- (NSUndoManager *)undoManager {
    return undoManager ? undoManager : [parent undoManager];
}

- (void)setUndoManager:(NSUndoManager *)newUndoManager {
    if (undoManager != newUndoManager) {
        [undoManager release];
        undoManager = [newUndoManager retain];
    }
}

@end

#pragma mark -

@implementation SKFileBookmark

- (id)initWithAlias:(BDAlias *)anAlias pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    if (self = [super init]) {
        if (anAlias) {
            alias = [anAlias retain];
            aliasData = [[alias aliasData] retain];
            pageIndex = aPageIndex;
            label = [aLabel copy];
        } else {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)copyWithZone:(NSZone *)aZone {
    return [[[self class] allocWithZone:aZone] initWithAlias:alias pageIndex:pageIndex label:label];
}

- (void)dealloc {
    [[self undoManager] removeAllActionsWithTarget:self];
    [alias release];
    [aliasData release];
    [label release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: label=%@, path=%@, page=%i>", [self class], label, [self path], pageIndex];
}

- (NSDictionary *)properties {
    return [NSDictionary dictionaryWithObjectsAndKeys:SKBookmarkTypeBookmarkString, SKBookmarkTypeKey, [self aliasData], SKBookmarkAliasDataKey, [NSNumber numberWithUnsignedInt:pageIndex], SKBookmarkPageIndexKey, label, SKBookmarkLabelKey, nil];
}

- (int)bookmarkType {
    return SKBookmarkTypeBookmark;
}

- (NSString *)path {
    return [alias fullPathNoUI];
}

- (BDAlias *)alias {
    return alias;
}

- (NSData *)aliasData {
    return [self path] ? [alias aliasData] : aliasData;
}

- (NSImage *)icon {
    static NSMutableDictionary *tinyIcons = nil;
    
    NSString *filePath = [self path];
    
    if (filePath == nil)
        return [NSImage tinyMissingFileImage];
    
    NSString *extension = [filePath pathExtension];
    NSImage *icon = [tinyIcons objectForKey:extension];
    
    if (icon == nil) {
        if (tinyIcons == nil)
            tinyIcons = [[NSMutableDictionary alloc] init];
        NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
        if (image) {
            NSRect sourceRect = {NSZeroPoint, [image size]};
            NSRect targetRect = NSMakeRect(0.0, 0.0, 16.0, 16.0);
            icon = [[NSImage alloc] initWithSize:targetRect.size];
            [icon lockFocus];
            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
            [image drawInRect:targetRect fromRect:sourceRect operation:NSCompositeCopy fraction:1.0];
            [icon unlockFocus];
            [tinyIcons setObject:icon forKey:extension];
            [icon release];
        }
    }
    return icon;
}

- (unsigned int)pageIndex {
    return pageIndex;
}

- (NSNumber *)pageNumber {
    return pageIndex == NSNotFound ? nil : [NSNumber numberWithUnsignedInt:pageIndex + 1];
}

- (NSString *)label {
    return label ? label : @"";
}

- (void)setLabel:(NSString *)newLabel {
    if (label != newLabel) {
        [(SKBookmark *)[[self undoManager] prepareWithInvocationTarget:self] setLabel:label];
        [label release];
        label = [newLabel retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKBookmarkChangedNotification object:self];
    }
}

@end

#pragma mark -

@implementation SKFolderBookmark

- (id)initFolderWithChildren:(NSArray *)aChildren label:(NSString *)aLabel {
    if (self = [super init]) {
        label = [aLabel copy];
        children = [aChildren mutableCopy];
        [children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)aZone {
    return [[[self class] allocWithZone:aZone] initFolderWithChildren:[[[NSArray alloc] initWithArray:children copyItems:YES] autorelease] label:label];
}

- (void)dealloc {
    [[self undoManager] removeAllActionsWithTarget:self];
    [label release];
    [children release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: label=%@, children=%@>", [self class], label, children];
}

- (NSDictionary *)properties {
    return [NSDictionary dictionaryWithObjectsAndKeys:SKBookmarkTypeFolderString, SKBookmarkTypeKey, [children valueForKey:SKBookmarkPropertiesKey], SKBookmarkChildrenKey, label, SKBookmarkLabelKey, nil];
}

- (int)bookmarkType {
    return SKBookmarkTypeFolder;
}

- (NSImage *)icon {
    return [NSImage tinyFolderImage];
}

- (NSString *)label {
    return label ? label : @"";
}

- (void)setLabel:(NSString *)newLabel {
    if (label != newLabel) {
        [(SKBookmark *)[[self undoManager] prepareWithInvocationTarget:self] setLabel:label];
        [label release];
        label = [newLabel retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKBookmarkChangedNotification object:self];
    }
}

- (NSArray *)children {
    return children;
}

- (void)insertChild:(SKBookmark *)child atIndex:(unsigned int)anIndex {
    [(SKBookmark *)[[self undoManager] prepareWithInvocationTarget:self] removeChild:child];
    [children insertObject:child atIndex:anIndex];
    [child setParent:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKBookmarkChangedNotification object:self];
}

- (void)addChild:(SKBookmark *)child {
    [self insertChild:child atIndex:[children count]];
}

- (void)removeChild:(SKBookmark *)child {
    [(SKBookmark *)[[self undoManager] prepareWithInvocationTarget:self] insertChild:child atIndex:[[self children] indexOfObject:child]];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKBookmarkWillBeRemovedNotification object:self];
    [child setParent:nil];
    [children removeObject:child];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKBookmarkChangedNotification object:self];
}

@end

#pragma mark -

@implementation SKSeparatorBookmark

- (id)copyWithZone:(NSZone *)aZone {
    return [[[self class] allocWithZone:aZone] init];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: separator>", [self class]];
}

- (NSDictionary *)properties {
    return [NSDictionary dictionaryWithObjectsAndKeys:SKBookmarkTypeSeparatorString, SKBookmarkTypeKey, nil];
}

- (int)bookmarkType {
    return SKBookmarkTypeSeparator;
}

@end
