//
//  SKOutlineView.h
//  Skim
//
//  Created by Christiaan Hofman on 8/22/07.
/*
 This software is Copyright (c) 2007-2020
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
#import "SKImageToolTipContext.h"

@protocol SKOutlineViewDelegate;

@interface SKOutlineView : NSOutlineView <SKTypeSelectDelegate> {
    SKTypeSelectHelper *typeSelectHelper;
    BOOL hasImageToolTips;
    BOOL supportsQuickLook;
    NSFont *font;
}

@property (nonatomic, readonly) NSArray *selectedItems;
@property (nonatomic, readonly) BOOL canDelete, canCopy, canPaste;
@property (nonatomic) BOOL hasImageToolTips, supportsQuickLook;
@property (nonatomic, retain) SKTypeSelectHelper *typeSelectHelper;

- (NSArray *)itemsAtRowIndexes:(NSIndexSet *)indexes;

- (void)delete:(id)sender;
- (void)copy:(id)sender;
- (void)paste:(id)sender;

- (void)scrollToBeginningOfDocument:(id)sender;
- (void)scrollToEndOfDocument:(id)sender;

- (void)reloadTypeSelectStrings;

- (id <SKOutlineViewDelegate>)delegate;
- (void)setDelegate:(id <SKOutlineViewDelegate>)newDelegate;

@end


@protocol SKOutlineViewDelegate <NSOutlineViewDelegate>
@optional

- (void)outlineView:(NSOutlineView *)anOutlineView deleteItems:(NSArray *)items;
- (BOOL)outlineView:(NSOutlineView *)anOutlineView canDeleteItems:(NSArray *)items;

- (void)outlineView:(NSOutlineView *)anOutlineView copyItems:(NSArray *)items;
- (BOOL)outlineView:(NSOutlineView *)anOutlineView canCopyItems:(NSArray *)items;

- (void)outlineView:(NSOutlineView *)anOutlineView pasteFromPasteboard:(NSPasteboard *)pboard;
- (BOOL)outlineView:(NSOutlineView *)anOutlineView canPasteFromPasteboard:(NSPasteboard *)pboard;

- (id <SKImageToolTipContext>)outlineView:(NSOutlineView *)anOutlineView imageContextForItem:(id)item;

- (NSArray *)outlineView:(NSOutlineView *)anOutlineView typeSelectHelperSelectionStrings:(SKTypeSelectHelper *)aTypeSelectHelper;
- (void)outlineView:(NSOutlineView *)anOutlineView typeSelectHelper:(SKTypeSelectHelper *)aTypeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString;
- (void)outlineView:(NSOutlineView *)anOutlineView typeSelectHelper:(SKTypeSelectHelper *)aTypeSelectHelper updateSearchString:(NSString *)searchString;

@end
