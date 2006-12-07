// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorHeaderView.h,v 1.7 2003/01/31 01:27:35 toon Exp $

#import <AppKit/NSControl.h>

@protocol OAInspectorHeaderViewDelegateProtocol;

@interface OAInspectorHeaderView : NSView
{
    NSString *title;
    NSImage *image;
    NSString *keyEquivalent;
    NSObject <OAInspectorHeaderViewDelegateProtocol> *delegate;
    BOOL isExpanded, isClicking, isDragging, clickingClose, overClose;
}

- (void)setTitle:(NSString *)aTitle;
- (void)setImage:(NSImage *)anImage;
- (void)setKeyEquivalent:(NSString *)anEquivalent;
- (void)setExpanded:(BOOL)newState;
- (void)setDelegate:(NSObject <OAInspectorHeaderViewDelegateProtocol> *)aDelegate;
- (float)minimumWidth;

@end

@class NSScreen;

@protocol OAInspectorHeaderViewDelegateProtocol
- (BOOL)headerViewShouldDisplayCloseButton:(OAInspectorHeaderView *)view;
- (float)headerViewDraggingHeight:(OAInspectorHeaderView *)view;
- (void)headerViewDidBeginDragging:(OAInspectorHeaderView *)view;
- (NSRect)headerView:(OAInspectorHeaderView *)view willDragWindowToFrame:(NSRect)aFrame onScreen:(NSScreen *)aScreen;
- (void)headerViewDidEndDragging:(OAInspectorHeaderView *)view toFrame:(NSRect)aFrame;
- (void)headerViewDidToggleExpandedness:(OAInspectorHeaderView *)view;
- (void)headerViewDidClose:(OAInspectorHeaderView *)view;
@end
