// Copyright 2000-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <AppKit/NSView.h>
#import <AppKit/NSNibDeclarations.h>

@class NSMutableArray; // Foundation
@class NSTabView, NSTabViewItem; // AppKit

// When laying out the tab view in nib, you'll want to make it 16 pixels thinner and 42 pixels taller than the OASidewaysTabView.  At this size, a tab view content item which completely fills the content area of the tab view will also completely fill the content area of the OASidewaysTableView

@interface OASidewaysTabView : NSView
{
    IBOutlet NSTabView *internalTabView;
    NSView *tabViewArea;
    NSView *contentArea;
    NSView *contentView;
    
    NSMutableArray *contentViews;
    
    id delegate;
}

- (id)initWithFrame:(NSRect)frame;
- (void)dealloc;

- (void)setInternalTabView:(NSTabView *)tabView;
- (NSTabView *)internalTabView;

- (void)setContentView:(NSView *)view;
- (NSView *)contentView;
- (NSView *)tabViewArea;
- (NSView *)contentArea;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;

@end

