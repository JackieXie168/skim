//
//  NSScrollView_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 2/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSScrollView (BDSKZoomablePDFViewExtensions) 

- (void)replacementDealloc;
- (BOOL)replacementHasHorizontalScroller;
- (BOOL)replacementHasVerticalScroller;
- (void)replacementSetHasHorizontalScroller:(BOOL)flag;
- (void)replacementSetHasVerticalScroller:(BOOL)flag;

// new API allows ignoring PDFView's attempts to remove the horizontal scroller
- (void)setAlwaysHasHorizontalScroller:(BOOL)flag;
- (void)setNeverHasHorizontalScroller:(BOOL)flag;
- (void)setAlwaysHasVerticalScroller:(BOOL)flag;
- (void)setNeverHasVerticalScroller:(BOOL)flag;

@end
