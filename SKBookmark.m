//
//  SKBookmark.m
//  Skim
//
//  Created by Christiaan Hofman on 9/15/07.
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

#import "SKBookmark.h"
#import "BDAlias.h"
#import "NSImage_SKExtensions.h"
#import "SKBookmarkController.h"
#import "NSDocument_SKExtensions.h"
#import "SKDocumentController.h"

#define BOOKMARK_STRING     @"bookmark"
#define SESSION_STRING      @"session"
#define FOLDER_STRING       @"folder"
#define SEPARATOR_STRING    @"separator"

#define PROPERTIES_KEY  @"properties"
#define CHILDREN_KEY    @"children"
#define LABEL_KEY       @"label"
#define PAGEINDEX_KEY   @"pageIndex"
#define ALIASDATA_KEY   @"_BDAlias"
#define TYPE_KEY        @"type"

@interface SKPlaceholderBookmark : SKBookmark
@end

@interface SKFileBookmark : SKBookmark {
    BDAlias *alias;
    NSData *aliasData;
    NSString *label;
    NSUInteger pageIndex;
    NSDictionary *setup;
}
- (id)initWithAliasData:(NSData *)aData pageIndex:(NSUInteger)aPageIndex label:(NSString *)aLabel;
- (BDAlias *)alias;
- (NSData *)aliasData;
@end

@interface SKFolderBookmark : SKBookmark {
    NSString *label;
    NSMutableArray *children;
}
@end

@interface SKRootBookmark : SKFolderBookmark
@end

@interface SKSessionBookmark : SKFolderBookmark
@end

@interface SKSeparatorBookmark : SKBookmark
@end

#pragma mark -

@implementation SKBookmark

@synthesize parent;
@dynamic properties, bookmarkType, label, icon, path, pageIndex, pageNumber, scriptingBookmarkType, scriptingFile, scriptingParent, entireContents;

static SKPlaceholderBookmark *defaultPlaceholderBookmark = nil;
static Class SKBookmarkClass = Nil;

+ (void)initialize {
    SKINITIALIZE;
    SKBookmarkClass = self;
    defaultPlaceholderBookmark = (SKPlaceholderBookmark *)NSAllocateObject([SKPlaceholderBookmark class], 0, NSDefaultMallocZone());
}

+ (id)allocWithZone:(NSZone *)aZone {
    return SKBookmarkClass == self ? defaultPlaceholderBookmark : [super allocWithZone:aZone];
}

+ (id)bookmarkWithPath:(NSString *)aPath pageIndex:(NSUInteger)aPageIndex label:(NSString *)aLabel {
    return [[[self alloc] initWithPath:aPath pageIndex:aPageIndex label:aLabel] autorelease];
}

+ (id)bookmarkWithSetup:(NSDictionary *)aSetupDict label:(NSString *)aLabel {
    return [[[self alloc] initWithSetup:aSetupDict label:aLabel] autorelease];
}

+ (id)bookmarkFolderWithLabel:(NSString *)aLabel {
    return [[[self alloc] initFolderWithLabel:aLabel] autorelease];
}

+ (id)bookmarkSessionWithSetups:(NSArray *)aSetupDicts label:(NSString *)aLabel {
    return [[[self alloc] initSessionWithSetups:aSetupDicts label:aLabel] autorelease];
}

+ (id)bookmarkSeparator {
    return [[[self alloc] initSeparator] autorelease];
}

- (id)initWithPath:(NSString *)aPath pageIndex:(NSUInteger)aPageIndex label:(NSString *)aLabel {
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

- (id)initRootWithChildren:(NSArray *)aChildren {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initSessionWithSetups:(NSArray *)aSetupDicts label:(NSString *)aLabel {
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

- (void)dealloc {
    parent = nil;
    [super dealloc];
}

- (NSDictionary *)properties { return nil; }

- (SKBookmarkType)bookmarkType { return SKBookmarkTypeSeparator; }

- (NSImage *)icon { return nil; }

- (NSString *)label { return nil; }
- (void)setLabel:(NSString *)newLabel {}

- (NSString *)path { return nil; }
- (NSUInteger)pageIndex { return NSNotFound; }
- (void)setPageIndex:(NSUInteger)newPageIndex {}
- (NSNumber *)pageNumber { return nil; }
- (void)setPageNumber:(NSNumber *)newPageNumber {}

- (NSArray *)children { return nil; }
- (NSUInteger)countOfChildren { return 0; }
- (SKBookmark *)objectInChildrenAtIndex:(NSUInteger)anIndex { return nil; }
- (void)insertObject:(SKBookmark *)child inChildrenAtIndex:(NSUInteger)anIndex {}
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)anIndex {}

- (id)objectSpecifier {
    NSUInteger idx = [[parent children] indexOfObjectIdenticalTo:self];
    if (idx != NSNotFound) {
        NSScriptObjectSpecifier *containerRef = nil;
        NSScriptClassDescription *containerClassDescription = nil;
        if ([parent parent]) {
            containerRef = [parent objectSpecifier];
            containerClassDescription = [containerRef keyClassDescription];
        } else {
            containerClassDescription = [NSScriptClassDescription classDescriptionForClass:[NSApp class]];
        }
        return [[[NSIndexSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:containerClassDescription containerSpecifier:containerRef key:@"bookmarks" index:idx] autorelease];
    } else {
        return nil;
    }
}

- (void)insertBookmarksForPaths:(NSArray *)paths relativeToPath:(NSString *)basePath atIndex:(NSUInteger)anIndex {}

- (FourCharCode)scriptingBookmarkType { return 0; }

- (NSURL *)scriptingFile {
    NSString *path = [self path];
    return path ? [NSURL fileURLWithPath:path] : nil;
}

- (SKBookmark *)scriptingParent {
    return [parent parent] == nil ? nil : parent;
};

- (NSArray *)entireContents { return nil; }

- (NSArray *)bookmarks {
    return [self children];
}

- (void)insertObject:(SKBookmark *)bookmark inBookmarksAtIndex:(NSUInteger)anIndex {
    [self insertObject:bookmark inChildrenAtIndex:anIndex];
}

- (void)removeObjectFromBookmarksAtIndex:(NSUInteger)anIndex {
    [self removeObjectFromChildrenAtIndex:anIndex];
}

- (id)newScriptingObjectOfClass:(Class)objectClass forValueForKey:(NSString *)key withContentsValue:(id)contentsValue properties:(NSDictionary *)properties {
    if ([key isEqualToString:@"bookmarks"]) {
        [[NSScriptCommand currentCommand] setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
        [[NSScriptCommand currentCommand] setScriptErrorString:@"Invalid container for new bookmark."];
        return nil;
    }
    return [super newScriptingObjectOfClass:objectClass forValueForKey:key withContentsValue:contentsValue properties:properties];
}

- (BOOL)isDescendantOf:(SKBookmark *)bookmark {
    if (self == bookmark)
        return YES;
    for (SKBookmark *child in [bookmark children]) {
        if ([self isDescendantOf:child])
            return YES;
    }
    return NO;
}

- (BOOL)isDescendantOfArray:(NSArray *)bookmarks {
    for (SKBookmark *bm in bookmarks) {
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

- (id)initWithPath:(NSString *)aPath pageIndex:(NSUInteger)aPageIndex label:(NSString *)aLabel {
    return [[SKFileBookmark alloc] initWithPath:aPath pageIndex:aPageIndex label:aLabel];
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

- (id)initRootWithChildren:(NSArray *)aChildren {
    return [[SKRootBookmark alloc] initFolderWithChildren:aChildren label:NSLocalizedString(@"Bookmarks Menu", @"Menu item title")];
}

- (id)initSessionWithSetups:(NSArray *)aSetupDicts label:(NSString *)aLabel {
    NSMutableArray *aChildren = [NSMutableArray array];
    SKBookmark *child;
    for (NSDictionary *setup in aSetupDicts) {
        if (child = [[SKBookmark alloc] initWithSetup:setup label:@""]) {
            [aChildren addObject:child];
            [child release];
        }
    }
    return [[SKSessionBookmark alloc] initFolderWithChildren:aChildren label:aLabel];
}

- (id)initSeparator {
    return [[SKSeparatorBookmark alloc] init];
}

- (id)initWithProperties:(NSDictionary *)dictionary {
    NSString *type = [dictionary objectForKey:TYPE_KEY];
    if ([type isEqualToString:SEPARATOR_STRING]) {
        return [[SKSeparatorBookmark alloc] init];
    } else if ([type isEqualToString:FOLDER_STRING] || [type isEqualToString:SESSION_STRING]) {
        Class bookmarkClass = [type isEqualToString:FOLDER_STRING] ? [SKFolderBookmark class] : [SKSessionBookmark class];
        NSMutableArray *newChildren = [NSMutableArray array];
        SKBookmark *child;
        for (NSDictionary *dict in [dictionary objectForKey:CHILDREN_KEY]) {
            if (child = [[SKBookmark alloc] initWithProperties:dict]) {
                [newChildren addObject:child];
                [child release];
            } else
                NSLog(@"Failed to read child bookmark: %@", dict);
        }
        return [[bookmarkClass alloc] initFolderWithChildren:newChildren label:[dictionary objectForKey:LABEL_KEY]];
    } else if ([dictionary objectForKey:@"windowFrame"]) {
        return [[SKFileBookmark alloc] initWithSetup:dictionary label:[dictionary objectForKey:LABEL_KEY]];
    } else {
        NSNumber *pageIndex = [dictionary objectForKey:PAGEINDEX_KEY];
        return [[SKFileBookmark alloc] initWithAliasData:[dictionary objectForKey:ALIASDATA_KEY] pageIndex:(pageIndex ? [pageIndex unsignedIntegerValue] : NSNotFound) label:[dictionary objectForKey:LABEL_KEY]];
    }
}

- (id)retain { return self; }

- (id)autorelease { return self; }

- (void)release {}

- (NSUInteger)retainCount { return NSUIntegerMax; }

@end

#pragma mark -

@implementation SKFileBookmark

+ (NSImage *)missingFileImage {
    static NSImage *image = nil;
    if (image == nil) {
        image = [[NSImage alloc] initWithSize:NSMakeSize(32.0, 32.0)];
        NSImage *genericDocImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIcon)];
        NSImage *questionMark = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kQuestionMarkIcon)];
        [image lockFocus];
        [genericDocImage drawInRect:NSMakeRect(0.0, 0.0, 32.0, 32.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:0.7];
        [questionMark drawInRect:NSMakeRect(6.0, 4.0, 20.0, 20.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.7];
        [image unlockFocus];
        NSImage *tinyImage = [[NSImage alloc] initWithSize:NSMakeSize(16.0, 16.0)];
        [tinyImage lockFocus];
        [genericDocImage drawInRect:NSMakeRect(0.0, 0.0, 16.0, 16.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:0.7];
        [questionMark drawInRect:NSMakeRect(3.0, 2.0, 10.0, 10.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.7];
        [tinyImage unlockFocus];
        [image addRepresentation:[[tinyImage representations] lastObject]];
        [tinyImage release];
    }
    return image;
}

- (id)initWithPath:(NSString *)aPath pageIndex:(NSUInteger)aPageIndex label:(NSString *)aLabel {
    if (self = [super init]) {
        alias = [[BDAlias alloc] initWithPath:aPath];
        if (alias) {
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

- (id)initWithAliasData:(NSData *)aData pageIndex:(NSUInteger)aPageIndex label:(NSString *)aLabel {
    if (self = [super init]) {
        alias = [[BDAlias alloc] initWithData:aData];
        if (aData && alias) {
            aliasData = [aData retain];
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
    NSNumber *pageIndexNumber = [aSetupDict objectForKey:PAGEINDEX_KEY];
    if (self = [self initWithAliasData:[aSetupDict objectForKey:ALIASDATA_KEY] pageIndex:(pageIndexNumber ? [pageIndexNumber unsignedIntegerValue] : NSNotFound) label:aLabel]) {
        setup = [aSetupDict copy];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(alias);
    SKDESTROY(aliasData);
    SKDESTROY(label);
    SKDESTROY(setup);
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: label=%@, path=%@, page=%lu>", [self class], label, [self path], (unsigned long)pageIndex];
}

- (NSDictionary *)properties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:setup];
    [properties addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:BOOKMARK_STRING, TYPE_KEY, [self aliasData], ALIASDATA_KEY, [NSNumber numberWithUnsignedInteger:pageIndex], PAGEINDEX_KEY, label, LABEL_KEY, nil]];
    return properties;
}

- (SKBookmarkType)bookmarkType {
    return SKBookmarkTypeBookmark;
}

- (NSString *)path {
    return [alias fullPathNoUI];
}

- (BDAlias *)alias {
    return alias;
}

- (NSData *)aliasData {
    NSData *data = nil;
    if ([self path])
        data = [alias aliasData];
    return data ?: aliasData;
}

- (NSImage *)icon {
    NSString *filePath = [self path];
    return filePath ? [[NSWorkspace sharedWorkspace] iconForFile:filePath] : [[self class] missingFileImage];
}

- (NSUInteger)pageIndex {
    return pageIndex;
}

- (void)setPageIndex:(NSUInteger)newPageIndex { pageIndex = newPageIndex; }

- (NSNumber *)pageNumber {
    return pageIndex == NSNotFound ? nil : [NSNumber numberWithUnsignedInteger:pageIndex + 1];
}

- (void)setPageNumber:(NSNumber *)newPageNumber {
    NSUInteger newNumber = [newPageNumber unsignedIntegerValue];
    if (newNumber > 0)
        [self setPageIndex:newNumber - 1];
}

- (NSString *)label {
    return label ?: @"";
}

- (void)setLabel:(NSString *)newLabel {
    if (label != newLabel) {
        [label release];
        label = [newLabel retain];
    }
}

- (FourCharCode)scriptingBookmarkType {
    return SKScriptingBookmarkTypeBookmark;
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

- (void)dealloc {
    SKDESTROY(label);
    SKDESTROY(children);
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: label=%@, children=%@>", [self class], label, children];
}

- (NSDictionary *)properties {
    return [NSDictionary dictionaryWithObjectsAndKeys:FOLDER_STRING, TYPE_KEY, [children valueForKey:PROPERTIES_KEY], CHILDREN_KEY, label, LABEL_KEY, nil];
}

- (SKBookmarkType)bookmarkType {
    return SKBookmarkTypeFolder;
}

- (NSImage *)icon {
    return [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
}

- (NSString *)label {
    return label ?: @"";
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

- (NSUInteger)countOfChildren {
    return [children count];
}

- (SKBookmark *)objectInChildrenAtIndex:(NSUInteger)anIndex {
    return [children objectAtIndex:anIndex];
}

- (void)insertObject:(SKBookmark *)child inChildrenAtIndex:(NSUInteger)anIndex {
    [children insertObject:child atIndex:anIndex];
    [child setParent:self];
}

- (void)removeObjectFromChildrenAtIndex:(NSUInteger)anIndex {
    [[children objectAtIndex:anIndex] setParent:nil];
    [children removeObjectAtIndex:anIndex];
}

- (FourCharCode)scriptingBookmarkType {
    return SKScriptingBookmarkTypeFolder;
}

- (NSArray *)entireContents {
    NSMutableArray *contents = [NSMutableArray array];
    for (SKBookmark *bookmark in [self children]) {
        [contents addObject:bookmark];
        [contents addObjectsFromArray:[bookmark entireContents]];
    }
    return contents;
}

- (id)newScriptingObjectOfClass:(Class)objectClass forValueForKey:(NSString *)key withContentsValue:(id)contentsValue properties:(NSDictionary *)properties {
    if ([key isEqualToString:@"bookmarks"]) {
        SKBookmark *bookmark = nil;
        NSURL *aURL = [properties objectForKey:@"scriptingFile"] ?: contentsValue;
        NSString *aPath = [aURL respondsToSelector:@selector(path)] ? [aURL path] : nil;
        NSString *aLabel = [properties objectForKey:@"label"];
        FourCharCode type = [[properties objectForKey:@"scriptingBookmarkType"] unsignedIntValue];
        if (type == 0) {
            if (aURL == nil)
                type = SKScriptingBookmarkTypeSession;
            else if ([[NSWorkspace sharedWorkspace] type:[[NSWorkspace sharedWorkspace] typeOfFile:aPath error:NULL] conformsToType:(NSString *)kUTTypeFolder])
                type = SKScriptingBookmarkTypeFolder;
            else
                type = SKScriptingBookmarkTypeBookmark;
        }
        switch (type) {
            case SKScriptingBookmarkTypeBookmark:
            {
                Class docClass;
                if (aPath == nil) {
                    [[NSScriptCommand currentCommand] setScriptErrorNumber:NSRequiredArgumentsMissingScriptError];
                    [[NSScriptCommand currentCommand] setScriptErrorString:@"New file bookmark requires a file."];
                } else if ([[NSFileManager defaultManager] fileExistsAtPath:aPath] == NO) {
                    [[NSScriptCommand currentCommand] setScriptErrorNumber:NSArgumentsWrongScriptError];
                    [[NSScriptCommand currentCommand] setScriptErrorString:@"New file bookmark requires an existing file."];
                } else if (docClass = [[NSDocumentController sharedDocumentController] documentClassForContentsOfURL:aURL]) {
                    NSUInteger aPageNumber = [[properties objectForKey:@"pageNumber"] unsignedIntegerValue];
                    if (aPageNumber > 0)
                        aPageNumber--;
                    else
                        aPageNumber = [docClass isPDFDocument] ? 0 : NSNotFound;
                    if (aLabel == nil && aPath)
                        aLabel = [[NSFileManager defaultManager] displayNameAtPath:aPath];
                    bookmark = [[SKBookmark alloc] initWithPath:aPath pageIndex:aPageNumber label:aLabel ?: @""];
                } else {
                    [[NSScriptCommand currentCommand] setScriptErrorNumber:NSArgumentsWrongScriptError];
                    [[NSScriptCommand currentCommand] setScriptErrorString:@"Unsupported file type for new bookmark."];
                }
                break;
            }
            case SKScriptingBookmarkTypeFolder:
            {
                if (aLabel == nil && aPath)
                    aLabel = [[NSFileManager defaultManager] displayNameAtPath:aPath];
                bookmark = [[SKBookmark alloc] initFolderWithLabel:aLabel ?: @""];
                if (aPath)
                    [bookmark insertBookmarksForPaths:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:aPath error:NULL] relativeToPath:aPath atIndex:0];
                break;
            }
            case SKScriptingBookmarkTypeSession:
            {
                NSArray *setups = [[NSApp orderedDocuments] valueForKey:@"currentDocumentSetup"];
                bookmark = [[SKBookmark alloc] initSessionWithSetups:setups label:aLabel ?: @""];
                break;
            }
            case SKScriptingBookmarkTypeSeparator:
                bookmark = [[SKBookmark alloc] initSeparator];
                break;
            default:
                [[NSScriptCommand currentCommand] setScriptErrorNumber:NSArgumentsWrongScriptError];
                [[NSScriptCommand currentCommand] setScriptErrorString:@"New bookmark requires a supported bookmark type."];
                break;
        }
        return bookmark;
    }
    return [super newScriptingObjectOfClass:objectClass forValueForKey:key withContentsValue:contentsValue properties:properties];
}

- (void)insertBookmarksForPaths:(NSArray *)paths relativeToPath:(NSString *)basePath atIndex:(NSUInteger)anIndex {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    NSUInteger insertIndex = anIndex;
    
    for (NSString *file in paths) {
        if ([[file lastPathComponent] hasPrefix:@"."] == NO) {
            NSString *path = [basePath stringByAppendingPathComponent:file] ?: file;
            NSString *fileType = [dc typeForContentsOfURL:[NSURL fileURLWithPath:path] error:NULL];
            Class docClass;
            SKBookmark *bookmark;
            if ([fileType isEqualToString:SKFolderDocumentType]) {
                if (bookmark = [[SKBookmark alloc] initFolderWithLabel:[fm displayNameAtPath:path]]) {
                    [bookmark insertBookmarksForPaths:[fm contentsOfDirectoryAtPath:path error:NULL] relativeToPath:path atIndex:0];
                    if ([bookmark countOfChildren])
                        [self insertObject:bookmark inChildrenAtIndex:insertIndex++];
                    [bookmark release];
                }
            } else if (docClass = [dc documentClassForType:fileType]) {
                if (bookmark = [[SKBookmark alloc] initWithPath:path pageIndex:([docClass isPDFDocument] ? 0 : NSNotFound) label:[fm displayNameAtPath:path]]) {
                    [self insertObject:bookmark inChildrenAtIndex:insertIndex++];
                    [bookmark release];
                }
            }
        }
    }
}

@end

#pragma mark -

@implementation SKRootBookmark

- (NSImage *)icon {
    static NSImage *menuIcon = nil;
    if (menuIcon == nil) {
        menuIcon = [[NSImage alloc] initWithSize:NSMakeSize(16.0, 16.0)];
        NSShadow *s = [[[NSShadow alloc] init] autorelease];
        [s setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.33333]];
        [s setShadowBlurRadius:2.0];
        [s setShadowOffset:NSMakeSize(0.0, -1.0)];
        [menuIcon lockFocus];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
        [NSBezierPath fillRect:NSMakeRect(1.0, 1.0, 14.0, 13.0)];
        [NSGraphicsContext saveGraphicsState];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(2.0, 2.0)];
        [path lineToPoint:NSMakePoint(2.0, 15.0)];
        [path lineToPoint:NSMakePoint(7.0, 15.0)];
        [path lineToPoint:NSMakePoint(7.0, 13.0)];
        [path lineToPoint:NSMakePoint(14.0, 13.0)];
        [path lineToPoint:NSMakePoint(14.0, 2.0)];
        [path closePath];
        [[NSColor whiteColor] set];
        [s set];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        [[NSColor colorWithCalibratedRed:0.162 green:0.304 blue:0.755 alpha:1.0] set];
        NSRectFill(NSMakeRect(2.0, 13.0, 5.0, 2.0));
        [[NSColor colorWithCalibratedRed:0.894 green:0.396 blue:0.202 alpha:1.0] set];
        NSRectFill(NSMakeRect(3.0, 4.0, 1.0, 1.0));
        NSRectFill(NSMakeRect(3.0, 7.0, 1.0, 1.0));
        NSRectFill(NSMakeRect(3.0, 10.0, 1.0, 1.0));
        [[NSColor colorWithCalibratedWhite:0.6 alpha:1.0] set];
        NSRectFill(NSMakeRect(5.0, 4.0, 1.0, 1.0));
        NSRectFill(NSMakeRect(5.0, 7.0, 1.0, 1.0));
        NSRectFill(NSMakeRect(5.0, 10.0, 1.0, 1.0));
        NSUInteger i, j;
        for (i = 0; i < 7; i++) {
            for (j = 0; j < 3; j++) {
                [[NSColor colorWithCalibratedWhite:0.45 + 0.1 * rand() / RAND_MAX alpha:1.0] set];
                NSRectFill(NSMakeRect(6.0 + i, 4.0 + 3.0 * j, 1.0, 1.0));
            }
        }
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] endingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]] autorelease];
        [gradient drawInRect:NSMakeRect(2.0, 2.0, 12.0,11.0) angle:90.0];
        [menuIcon unlockFocus];
    }
    return menuIcon;
}

@end

#pragma mark -

@implementation SKSessionBookmark

- (NSDictionary *)properties {
    return [NSDictionary dictionaryWithObjectsAndKeys:SESSION_STRING, TYPE_KEY, [children valueForKey:PROPERTIES_KEY], CHILDREN_KEY, label, LABEL_KEY, nil];
}

- (SKBookmarkType)bookmarkType {
    return SKBookmarkTypeSession;
}

- (NSImage *)icon {
    return [NSImage imageNamed:NSImageNameMultipleDocuments];
}
- (FourCharCode)scriptingBookmarkType {
    return SKScriptingBookmarkTypeSession;
}

- (void)insertObject:(SKBookmark *)child inChildrenAtIndex:(NSUInteger)anIndex {}
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)anIndex {}

- (void)insertBookmarksForPaths:(NSArray *)paths relativeToPath:(NSString *)basePath atIndex:(NSUInteger)anIndex {}

- (NSArray *)entireContents { return nil; }

- (id)newScriptingObjectOfClass:(Class)objectClass forValueForKey:(NSString *)key withContentsValue:(id)contentsValue properties:(NSDictionary *)properties {
    if ([key isEqualToString:@"bookmarks"]) {
        [[NSScriptCommand currentCommand] setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
        [[NSScriptCommand currentCommand] setScriptErrorString:@"Invalid container for new bookmark."];
        return nil;
    }
    return [super newScriptingObjectOfClass:objectClass forValueForKey:key withContentsValue:contentsValue properties:properties];
}

@end

#pragma mark -

@implementation SKSeparatorBookmark

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: separator>", [self class]];
}

- (NSDictionary *)properties {
    return [NSDictionary dictionaryWithObjectsAndKeys:SEPARATOR_STRING, TYPE_KEY, nil];
}

- (SKBookmarkType)bookmarkType {
    return SKBookmarkTypeSeparator;
}

- (FourCharCode)scriptingBookmarkType {
    return SKScriptingBookmarkTypeSeparator;
}

@end
