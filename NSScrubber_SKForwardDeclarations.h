//
//  NSScrubber_SKForwardDeclarations.h
//  Skim
//
//  Created by Christiaan Hofman on 14/05/2019.
/*
 This software is Copyright (c) 2019-2020
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

#if SDK_BEFORE(10_12)

@class NSScrubber;
@class NSScrubberItemView;
@class NSScrubberTextItemView;
@class NSScrubberImageItemView;
@class NSScrubberSelectionView;
@class NSScrubberLayout;
@class NSScrubberFlowLayout;
@class NSScrubberProportionalLayout;

@protocol NSScrubberDelegate;
@protocol NSScrubberDataSource;

typedef NS_ENUM(NSInteger, NSScrubberMode) {
    NSScrubberModeFixed = 0,
    NSScrubberModeFree
};

typedef NS_ENUM(NSInteger, NSScrubberAlignment) {
    NSScrubberAlignmentNone = 0,
    NSScrubberAlignmentLeading,
    NSScrubberAlignmentTrailing,
    NSScrubberAlignmentCenter
};

@interface NSScrubberSelectionStyle : NSObject <NSCoding>

@property (class, strong, readonly) NSScrubberSelectionStyle *outlineOverlayStyle;
@property (class, strong, readonly) NSScrubberSelectionStyle *roundedBackgroundStyle;

- (NSScrubberSelectionView *)makeSelectionView;

@end

@interface NSScrubber : NSView

@property (weak) id<NSScrubberDataSource> dataSource;
@property (weak) id<NSScrubberDelegate> delegate;
@property (strong) NSScrubberLayout *scrubberLayout;
@property (readonly) NSInteger numberOfItems;
@property (readonly) NSInteger highlightedIndex;
@property NSInteger selectedIndex;
@property NSScrubberMode mode;
@property NSScrubberAlignment itemAlignment;
@property (getter=isContinuous) BOOL continuous;
@property BOOL floatsSelectionViews;
@property (strong) NSScrubberSelectionStyle *selectionBackgroundStyle;
@property (strong) NSScrubberSelectionStyle *selectionOverlayStyle;
@property BOOL showsArrowButtons;
@property BOOL showsAdditionalContentIndicators;
@property (copy) NSColor *backgroundColor;
@property (strong) NSView *backgroundView;

- (void)reloadData;
- (void)performSequentialBatchUpdates:(void(^)(void))updateBlock;
- (void)insertItemsAtIndexes:(NSIndexSet *)indexes;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void)reloadItemsAtIndexes:(NSIndexSet *)indexes;
- (void)moveItemAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex;
- (void)scrollItemAtIndex:(NSInteger)index toAlignment:(NSScrubberAlignment)alignment;

- (NSScrubberItemView *)itemViewForItemAtIndex:(NSInteger)index;
- (void)registerClass:(Class)itemViewClass forItemIdentifier:(NSUserInterfaceItemIdentifier)itemIdentifier;
- (void)registerNib:(NSNib *)nib forItemIdentifier:(NSUserInterfaceItemIdentifier)itemIdentifier;
- (NSScrubberItemView *)makeItemWithIdentifier:(NSUserInterfaceItemIdentifier)itemIdentifier owner:(id)owner;

@end

@protocol NSScrubberDataSource <NSObject>
@required
- (NSInteger)numberOfItemsForScrubber:(NSScrubber *)scrubber;
- (NSScrubberItemView *)scrubber:(NSScrubber *)scrubber viewForItemAtIndex:(NSInteger)index;
@end

@protocol NSScrubberDelegate <NSObject>
@optional
- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)selectedIndex;
- (void)scrubber:(NSScrubber *)scrubber didHighlightItemAtIndex:(NSInteger)highlightedIndex;
- (void)scrubber:(NSScrubber *)scrubber didChangeVisibleRange:(NSRange)visibleRange;
- (void)didBeginInteractingWithScrubber:(NSScrubber *)scrubber;
- (void)didFinishInteractingWithScrubber:(NSScrubber *)scrubber;
- (void)didCancelInteractingWithScrubber:(NSScrubber *)scrubber;
@end

@interface NSScrubberArrangedView : NSView
@property (getter=isSelected)    BOOL selected;
@property (getter=isHighlighted) BOOL highlighted;

- (void)applyLayoutAttributes:(NSScrubberLayoutAttributes *)layoutAttributes;

@end

@interface NSScrubberItemView : NSScrubberArrangedView
@end

@interface NSScrubberTextItemView : NSScrubberItemView

@property (strong, readonly) NSTextField *textField;
@property (copy) NSString *title;

@end

@interface NSScrubberImageItemView : NSScrubberItemView

@property (strong, readonly) NSImageView *imageView;
@property (copy) NSImage *image;
@property NSImageAlignment imageAlignment;

@end

@interface NSScrubberLayoutAttributes : NSObject

@property NSInteger itemIndex;
@property NSRect frame;
@property CGFloat alpha;

+ (id)layoutAttributesForItemAtIndex:(NSInteger)index;

@end

@interface NSScrubberLayout : NSObject <NSCoding>

@property (class, readonly) Class layoutAttributesClass;
@property (weak, readonly) NSScrubber *scrubber;
@property (readonly) NSRect visibleRect;

- (void)invalidateLayout;

- (void)prepareLayout;

@property (readonly) NSSize scrubberContentSize;

- (NSScrubberLayoutAttributes *)layoutAttributesForItemAtIndex:(NSInteger)index;

- (NSSet *)layoutAttributesForItemsInRect:(NSRect)rect;

@property (readonly) BOOL shouldInvalidateLayoutForSelectionChange;
@property (readonly) BOOL shouldInvalidateLayoutForHighlightChange;

- (BOOL)shouldInvalidateLayoutForChangeFromVisibleRect:(NSRect)fromVisibleRect toVisibleRect:(NSRect)toVisibleRect;

@property (readonly) BOOL automaticallyMirrorsInRightToLeftLayout;

@end

@protocol NSScrubberFlowLayoutDelegate <NSScrubberDelegate>
@optional
- (NSSize)scrubber:(NSScrubber *)scrubber layout:(NSScrubberFlowLayout *)layout sizeForItemAtIndex:(NSInteger)itemIndex;
@end

@interface NSScrubberFlowLayout : NSScrubberLayout

@property CGFloat itemSpacing;
@property NSSize itemSize;

- (void)invalidateLayoutForItemsAtIndexes:(NSIndexSet *)invalidItemIndexes;

@end

@interface NSScrubberProportionalLayout : NSScrubberLayout

@property NSInteger numberOfVisibleItems;

- (id)initWithNumberOfVisibleItems:(NSInteger)numberOfVisibleItems;

@end

#else

// When compiling against the 10.12.1 SDK or later, just provide forward
// declarations to suppress the partial availability warnings.

@class NSScrubber;
@class NSScrubberItemView;
@class NSScrubberTextItemView;
@class NSScrubberImageItemView;
@class NSScrubberSelectionView;
@class NSScrubberLayout;
@class NSScrubberFlowLayout;
@class NSScrubberProportionalLayout;

@protocol NSScrubberDelegate;
@protocol NSScrubberDataSource;

#endif
