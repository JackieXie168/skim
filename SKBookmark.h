//
//  SKBookmark.h
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

#import <Cocoa/Cocoa.h>

enum {
    SKBookmarkTypeBookmark,
    SKBookmarkTypeFolder,
    SKBookmarkTypeSession,
    SKBookmarkTypeSeparator
};
typedef NSInteger SKBookmarkType;

enum {
    SKScriptingBookmarkTypeBookmark = 'BmFl',
    SKScriptingBookmarkTypeFolder = 'BmFd',
    SKScriptingBookmarkTypeSession = 'BmSs',
    SKScriptingBookmarkTypeSeparator = 'BmSp'
};

@interface SKBookmark : NSObject {
    SKBookmark *parent;
}

+ (id)bookmarkWithPath:(NSString *)aPath pageIndex:(NSUInteger)aPageIndex label:(NSString *)aLabel;
+ (id)bookmarkWithSetup:(NSDictionary *)aSetupDict label:(NSString *)aLabel;
+ (id)bookmarkFolderWithChildren:(NSArray *)aChildren label:(NSString *)aLabel;
+ (id)bookmarkFolderWithLabel:(NSString *)aLabel;
+ (id)bookmarkSessionWithChildren:(NSArray *)aChildren label:(NSString *)aLabel;
+ (id)bookmarkSeparator;
+ (id)bookmarkWithProperties:(NSDictionary *)dictionary;

- (id)initWithPath:(NSString *)aPath pageIndex:(NSUInteger)aPageIndex label:(NSString *)aLabel;
- (id)initWithSetup:(NSDictionary *)aSetupDict label:(NSString *)aLabel;
- (id)initFolderWithChildren:(NSArray *)aChildren label:(NSString *)aLabel;
- (id)initFolderWithLabel:(NSString *)aLabel;
- (id)initRootWithChildren:(NSArray *)aChildren;
- (id)initSessionWithChildren:(NSArray *)aChildren label:(NSString *)aLabel;
- (id)initSeparator;
- (id)initWithProperties:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSDictionary *properties;
@property (nonatomic, readonly) SKBookmarkType bookmarkType;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, readonly) NSImage *icon;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic) NSUInteger pageIndex;
@property (nonatomic, retain) NSNumber *pageNumber;
@property (nonatomic, assign) SKBookmark *parent;

- (NSArray *)children;
- (NSUInteger)countOfChildren;
- (SKBookmark *)objectInChildrenAtIndex:(NSUInteger)anIndex;
- (void)insertObject:(SKBookmark *)child inChildrenAtIndex:(NSUInteger)anIndex;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)anIndex;

@property (nonatomic, readonly) FourCharCode scriptingBookmarkType;
@property (nonatomic, readonly) NSURL *scriptingFile;
@property (nonatomic, readonly) SKBookmark *scriptingParent;
@property (nonatomic, readonly) NSArray *entireContents;

- (NSArray *)bookmarks;
- (void)insertObject:(SKBookmark *)bookmark inBookmarksAtIndex:(NSUInteger)anIndex;
- (void)removeObjectFromBookmarksAtIndex:(NSUInteger)anIndex;

- (BOOL)isDescendantOf:(SKBookmark *)bookmark;
- (BOOL)isDescendantOfArray:(NSArray *)bookmarks;

@end
