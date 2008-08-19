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
#import "SKRuntime.h"

static NSString *SKBookmarkTypeBookmarkString = @"bookmark";
static NSString *SKBookmarkTypeSessionString = @"session";
static NSString *SKBookmarkTypeFolderString = @"folder";
static NSString *SKBookmarkTypeSeparatorString = @"separator";

static NSString *SKBookmarkPropertiesKey = @"properties";

static NSString *SKBookmarkChildrenKey = @"children";
static NSString *SKBookmarkLabelKey = @"label";
static NSString *SKBookmarkPageIndexKey = @"pageIndex";
static NSString *SKBookmarkAliasDataKey = @"_BDAlias";
static NSString *SKBookmarkTypeKey = @"type";

@interface SKPlaceholderBookmark : SKBookmark
@end

@interface SKFileBookmark : SKBookmark {
    BDAlias *alias;
    NSData *aliasData;
    NSString *label;
    unsigned int pageIndex;
    NSDictionary *setup;
}
- (id)initWithAlias:(BDAlias *)anAlias pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel;
- (BDAlias *)alias;
- (NSData *)aliasData;
@end

@interface SKFolderBookmark : SKBookmark {
    NSString *label;
    NSMutableArray *children;
}
@end

@interface SKSessionBookmark : SKFolderBookmark
@end

@interface SKSeparatorBookmark : SKBookmark
@end

#pragma mark -

@implementation SKBookmark

static SKPlaceholderBookmark *defaultPlaceholderBookmark = nil;
static Class SKBookmarkClass = Nil;

+ (void)initialize {
    OBINITIALIZE;
    SKBookmarkClass = self;
    defaultPlaceholderBookmark = (SKPlaceholderBookmark *)NSAllocateObject([SKPlaceholderBookmark class], 0, NSDefaultMallocZone());
}

+ (id)allocWithZone:(NSZone *)aZone {
    return SKBookmarkClass == self ? defaultPlaceholderBookmark : [super allocWithZone:aZone];
}

+ (id)bookmarkWithPath:(NSString *)aPath pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    return [[[self alloc] initWithPath:aPath pageIndex:aPageIndex label:aLabel] autorelease];
}

+ (id)bookmarkWithSetup:(NSDictionary *)aSetupDict label:(NSString *)aLabel {
    return [[[self alloc] initWithSetup:aSetupDict label:aLabel] autorelease];
}

+ (id)bookmarkFolderWithChildren:(NSArray *)aChildren label:(NSString *)aLabel {
    return [[[self alloc] initFolderWithChildren:aChildren label:aLabel] autorelease];
}

+ (id)bookmarkFolderWithLabel:(NSString *)aLabel {
    return [[[self alloc] initFolderWithLabel:aLabel] autorelease];
}

+ (id)bookmarkSessionWithChildren:(NSArray *)aChildren label:(NSString *)aLabel {
    return [[[self alloc] initSessionWithChildren:aChildren label:aLabel] autorelease];
}

+ (id)bookmarkSeparator {
    return [[[self alloc] initSeparator] autorelease];
}

+ (id)bookmarkWithProperties:(NSDictionary *)dictionary {
    return [[[self alloc] initWithProperties:dictionary] autorelease];
}

- (id)initWithPath:(NSString *)aPath pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithSetup:(NSDictionary *)aSetupDict label:(NSString *)aLabel {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initFolderWithChildren:(NSArray *)aChildren label:(NSString *)aLabel {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initFolderWithLabel:(NSString *)aLabel {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initSessionWithChildren:(NSArray *)aChildren label:(NSString *)aLabel {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initSeparator {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithProperties:(NSDictionary *)dictionary {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)copyWithZone:(NSZone *)aZone {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSDictionary *)properties { return nil; }

- (int)bookmarkType { return SKBookmarkTypeSeparator; }

- (NSImage *)icon { return nil; }

- (NSString *)label { return nil; }
- (void)setLabel:(NSString *)newLabel {}

- (NSString *)path { return nil; }
- (unsigned int)pageIndex { return NSNotFound; }
- (NSNumber *)pageNumber { return nil; }

- (NSArray *)session { return nil; }

- (NSArray *)children { return nil; }
- (unsigned int)countOfChildren { return 0; }
- (SKBookmark *)objectInChildrenAtIndex:(unsigned int)anIndex { return nil; }
- (void)insertObject:(SKBookmark *)child inChildrenAtIndex:(unsigned int)anIndex {}
- (void)removeObjectFromChildrenAtIndex:(unsigned int)anIndex {}

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

@end

#pragma mark -

@implementation SKPlaceholderBookmark

- (id)init {
    return nil;
}

- (id)initWithAlias:(BDAlias *)anAlias pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    return [[SKFileBookmark alloc] initWithAlias:anAlias pageIndex:aPageIndex label:aLabel];
}

- (id)initWithPath:(NSString *)aPath pageIndex:(unsigned)aPageIndex label:(NSString *)aLabel {
    return [[SKFileBookmark alloc] initWithAlias:[BDAlias aliasWithPath:aPath] pageIndex:aPageIndex label:aLabel];
}

- (id)initWithSetup:(NSDictionary *)aSetupDict label:(NSString *)aLabel {
    return [[SKFileBookmark alloc] initWithSetup:aSetupDict label:aLabel];
}

- (id)initFolderWithChildren:(NSArray *)aChildren label:(NSString *)aLabel {
    return [[SKFolderBookmark alloc] initFolderWithChildren:aChildren label:aLabel];
}

- (id)initFolderWithLabel:(NSString *)aLabel {
    return [self initFolderWithChildren:nil label:aLabel];
}

- (id)initSessionWithChildren:(NSArray *)aChildren label:(NSString *)aLabel {
    return [[SKSessionBookmark alloc] initFolderWithChildren:aChildren label:aLabel];
}

- (id)initSeparator {
    return [[SKSeparatorBookmark alloc] init];
}

- (id)initWithProperties:(NSDictionary *)dictionary {
    NSString *type = [dictionary objectForKey:SKBookmarkTypeKey];
    if ([type isEqualToString:SKBookmarkTypeSeparatorString]) {
        return [[SKSeparatorBookmark alloc] init];
    } else if ([type isEqualToString:SKBookmarkTypeFolderString] || [type isEqualToString:SKBookmarkTypeSessionString]) {
        Class bookmarkClass = [type isEqualToString:SKBookmarkTypeFolderString] ? [SKFolderBookmark class] : [SKSessionBookmark class];
        NSEnumerator *dictEnum = [[dictionary objectForKey:SKBookmarkChildrenKey] objectEnumerator];
        NSDictionary *dict;
        NSMutableArray *newChildren = [NSMutableArray array];
        while (dict = [dictEnum nextObject])
            [newChildren addObject:[SKBookmark bookmarkWithProperties:dict]];
        return [[bookmarkClass alloc] initFolderWithChildren:newChildren label:[dictionary objectForKey:SKBookmarkLabelKey]];
    } else {
        return [[SKFileBookmark alloc] initWithAlias:[BDAlias aliasWithData:[dictionary objectForKey:SKBookmarkAliasDataKey]] pageIndex:[[dictionary objectForKey:SKBookmarkPageIndexKey] unsignedIntValue] label:[dictionary objectForKey:SKBookmarkLabelKey]];
    }
}

- (id)retain { return self; }

- (id)autorelease { return self; }

- (void)release {}

- (unsigned)retainCount { return UINT_MAX; }

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
            setup = nil;
        } else {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithSetup:(NSDictionary *)aSetupDict label:(NSString *)aLabel {
    if (self = [self initWithAlias:[BDAlias aliasWithData:[aSetupDict objectForKey:SKBookmarkAliasDataKey]] pageIndex:[[aSetupDict objectForKey:SKBookmarkPageIndexKey] unsignedIntValue] label:aLabel]) {
        setup = [aSetupDict copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)aZone {
    return [[[self class] allocWithZone:aZone] initWithAlias:alias pageIndex:pageIndex label:label];
}

- (void)dealloc {
    [alias release];
    [aliasData release];
    [label release];
    [setup release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: label=%@, path=%@, page=%i>", [self class], label, [self path], pageIndex];
}

- (NSDictionary *)properties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:setup];
    [properties addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:SKBookmarkTypeBookmarkString, SKBookmarkTypeKey, [self aliasData], SKBookmarkAliasDataKey, [NSNumber numberWithUnsignedInt:pageIndex], SKBookmarkPageIndexKey, label, SKBookmarkLabelKey, nil]];
    return properties;
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
        [label release];
        label = [newLabel retain];
    }
}

@end

#pragma mark -

@implementation SKFolderBookmark

- (id)initFolderWithChildren:(NSArray *)aChildren label:(NSString *)aLabel {
    if (self = [super init]) {
        label = [aLabel copy];
        children = [[NSMutableArray alloc] initWithArray:aChildren];
        [children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)aZone {
    return [[[self class] allocWithZone:aZone] initFolderWithChildren:[[[NSArray alloc] initWithArray:children copyItems:YES] autorelease] label:label];
}

- (void)dealloc {
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
        [label release];
        label = [newLabel retain];
    }
}

- (NSArray *)children {
    return [[children copy] autorelease];
}

- (unsigned int)countOfChildren {
    return [children count];
}

- (SKBookmark *)objectInChildrenAtIndex:(unsigned int)anIndex {
    return [children objectAtIndex:anIndex];
}

- (void)insertObject:(SKBookmark *)child inChildrenAtIndex:(unsigned int)anIndex {
    [children insertObject:child atIndex:anIndex];
    [child setParent:self];
}

- (void)removeObjectFromChildrenAtIndex:(unsigned int)anIndex {
    [[children objectAtIndex:anIndex] setParent:nil];
    [children removeObjectAtIndex:anIndex];
}

@end

#pragma mark -

@implementation SKSessionBookmark

- (NSDictionary *)properties {
    return [NSDictionary dictionaryWithObjectsAndKeys:SKBookmarkTypeSessionString, SKBookmarkTypeKey, [children valueForKey:SKBookmarkPropertiesKey], SKBookmarkChildrenKey, label, SKBookmarkLabelKey, nil];
}

- (int)bookmarkType {
    return SKBookmarkTypeSession;
}

- (NSImage *)icon {
    return [NSImage tinyMultipleFilesImage];
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
