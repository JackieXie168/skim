// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OASidewaysTabView.h"

#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OASidewaysTabView.m,v 1.6 2003/01/15 22:51:45 kc Exp $")

#define __TAB_VIEW_HEIGHT 36
#define __TAB_VIEW_TRANSLATE_SLOP 16 // 6
#define __TAB_VIEW_CONTENT_LEFT_MARGIN 10
#define __TAB_VIEW_CONTENT_BOTTOM_MARGIN 29

@implementation OASidewaysTabView

- (id)initWithFrame:(NSRect)frame;
{
    if ([super initWithFrame:frame] == nil)
        return nil;

    tabViewArea = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, __TAB_VIEW_HEIGHT, frame.size.height)];
    [tabViewArea setAutoresizingMask:NSViewHeightSizable];
    [self setAutoresizesSubviews:YES];
    [self addSubview:tabViewArea];

    contentArea = [[NSView alloc] initWithFrame:NSMakeRect(__TAB_VIEW_HEIGHT, 0, frame.size.width - __TAB_VIEW_HEIGHT, frame.size.height)];
    
    [contentArea setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [contentArea setAutoresizesSubviews:YES];
    [self addSubview:contentArea];
    
    contentViews = [[NSMutableArray alloc] init];
        
    return self;
}

- (void)dealloc;
{
    [internalTabView release];
    [tabViewArea release];
    [contentArea release];
    [contentView release];
    [contentViews release];
    [delegate release];
    
    [super dealloc];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldFrameSize;
{
    NSRect tabViewFrame;
    int integralY;
    
    [super resizeSubviewsWithOldSize:oldFrameSize];

    // Make sure the y component of our origin is at an even, integral value, otherwise we'll see strange tearing (presumably due to the math inaccuracies in the transformation).
    tabViewFrame = [internalTabView frame];
    integralY = (int)((NSHeight([tabViewArea bounds]) - tabViewFrame.size.width) / 2);
    if ((integralY % 2) != 0)
        integralY -= 1;
        
    [internalTabView setFrameOrigin:NSMakePoint(tabViewFrame.origin.x, (float)integralY)];
}

- (void)setInternalTabView:(NSTabView *)tabView;
{
    if (internalTabView != tabView) {
        NSRect tabViewFrame;
        NSPoint tabViewOrigin;
        
        [internalTabView release];
        internalTabView = [tabView retain];

        // Become the tab view delegate, and make any previous delegate our delegate
        if ([internalTabView delegate] != nil)
            [self setDelegate:[internalTabView delegate]];
        [internalTabView setDelegate:self];
        
        // Swap in the content view associated with the selected tab in the tab view
        [self setContentView:[[internalTabView selectedTabViewItem] view]];
        
        tabViewFrame = [internalTabView frame];

        // Make sure the frame is anchored at 0, 0
        [internalTabView setFrame:NSMakeRect(0, 0, tabViewFrame.size.width, tabViewFrame.size.height)];
        [internalTabView setAutoresizingMask:NSViewWidthSizable];
        [tabViewArea addSubview:internalTabView];

        // 89.99 is a magic number, don't change.  At 90 degress, NSTabView goes insane.  At 89.9 degress you'll see rotation artifacts.  At 89.999 degress you'll experience a different kind of insanity where the tab view appears and disappears as it's resized.
        [internalTabView setFrameRotation:89.99];
        tabViewOrigin = tabViewFrame.origin;

        // Slide the tab view back in place (after being displaced by the rotation) and center it vertically
        [internalTabView setFrameOrigin:NSMakePoint(tabViewOrigin.x + (NSHeight([internalTabView bounds]) - __TAB_VIEW_TRANSLATE_SLOP), (NSHeight([tabViewArea bounds]) - tabViewFrame.size.width) / 2)];
        [self setNeedsDisplay:YES];
    }
}

- (NSTabView *)internalTabView;
{
    return internalTabView;
}

- (void)setContentView:(NSView *)view;
{
    if (contentView != view) {
        NSRect adjustedFrame;
        
        // Cache the selected content view so we can return it easily
        [contentView removeFromSuperview];
        [contentView release];
        contentView = [view retain];
        
        // Since we're removing these views from the tab view items (by virtue of adding them as subviews to the our tabViewArea), add the content views to an array so they're retained until we're done with them (ie., until this object is released).
        if ([contentViews containsObject:contentView] == NO)
            [contentViews addObject:contentView];
            
        adjustedFrame = [contentView frame];
        adjustedFrame.origin.x -= __TAB_VIEW_CONTENT_LEFT_MARGIN;
        adjustedFrame.origin.y -= __TAB_VIEW_CONTENT_BOTTOM_MARGIN;
        adjustedFrame.size = [contentArea frame].size;
        [contentView setFrame:adjustedFrame];
        [contentView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [contentView setAutoresizesSubviews:YES];

        [contentArea addSubview:contentView];
        
        [self setNeedsDisplay:YES];
    }
}

- (NSView *)contentView;
{
    return contentView;
}

- (NSView *)tabViewArea;
{
    return tabViewArea;
}

- (NSView *)contentArea;
{
    return contentArea;
}

- (void)setDelegate:(id)aDelegate;
{
    if (delegate != aDelegate) {
        [delegate release];
        delegate = [aDelegate retain];
    }
}

- (id)delegate;
{
    return delegate;
}

- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem;
{
    // Forward to our delegate
    if (delegate != nil && [delegate respondsToSelector:@selector(tabView:shouldSelectTabViewItem:)])
        return [delegate tabView:tabView shouldSelectTabViewItem:tabViewItem];
    else
        return YES;
}

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem;
{
    // Forward to our delegate
    if (delegate != nil && [delegate respondsToSelector:@selector(tabView:willSelectTabViewItem:)])
        [delegate tabView:tabView willSelectTabViewItem:tabViewItem];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
{
    // Swap in the appropriate content view and then forward to our delegate
    [self setContentView:[tabViewItem view]];
    
    if (delegate != nil && [delegate respondsToSelector:@selector(tabView:didSelectTabViewItem:)])
        [delegate tabView:tabView didSelectTabViewItem:tabViewItem];
}

- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView;
{
    // Forward to our delegate
    if (delegate != nil && [delegate respondsToSelector:@selector(tabViewDidChangeNumberOfTabViewItems:)])
        [delegate tabViewDidChangeNumberOfTabViewItems:tabView];
}

@end
