//
//  SKOutlineView.h
//  Skim
//
//  Created by Christiaan Hofman on 8/22/07.
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
#import "SKTypeSelectHelper.h"


@protocol SKOutlineViewDelegate <NSOutlineViewDelegate>
@optional

- (void)outlineView:(NSOutlineView *)anOutlineView deleteItems:(NSArray *)items;
- (BOOL)outlineView:(NSOutlineView *)anOutlineView canDeleteItems:(NSArray *)items;

- (void)outlineView:(NSOutlineView *)anOutlineView copyItems:(NSArray *)items;
- (BOOL)outlineView:(NSOutlineView *)anOutlineView canCopyItems:(NSArray *)items;

- (NSMenu *)outlineView:(NSOutlineView *)anOutlineView menuForTableColumn:(NSTableColumn *)tableColumn item:(id)item;

- (NSArray *)outlineView:(NSOutlineView *)anOutlineView typeSelectHelperSelectionItems:(SKTypeSelectHelper *)aTypeSelectHelper;
- (void)outlineView:(NSOutlineView *)anOutlineView typeSelectHelper:(SKTypeSelectHelper *)aTypeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString;
- (void)outlineView:(NSOutlineView *)anOutlineView typeSelectHelper:(SKTypeSelectHelper *)aTypeSelectHelper updateSearchString:(NSString *)searchString;

@end

@protocol SKOutlineViewDataSource <NSOutlineViewDataSource>
@optional

- (void)outlineView:(NSOutlineView *)anOutlineView dragEndedWithOperation:(NSDragOperation)operation;

@end


@interface SKOutlineView : NSOutlineView <SKTypeSelectDataSource> {
    SKTypeSelectHelper *typeSelectHelper;
}

+ (BOOL)usesDefaultFontSize;

- (NSArray *)selectedItems;

- (SKTypeSelectHelper *)typeSelectHelper;
- (void)setTypeSelectHelper:(SKTypeSelectHelper *)newTypeSelectHelper;

- (BOOL)canDelete;
- (void)delete:(id)sender;

- (BOOL)canCopy;
- (void)copy:(id)sender;

- (void)scrollToBeginningOfDocument:(id)sender;
- (void)scrollToEndOfDocument:(id)sender;

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
- (id <SKOutlineViewDelegate>)delegate;
- (void)setDelegate:(id <SKOutlineViewDelegate>)newDelegate;
- (id <SKOutlineViewDataSource>)dataSource;
- (void)setDataSource:(id <SKOutlineViewDataSource>)newDataSource;
#endif

@end
