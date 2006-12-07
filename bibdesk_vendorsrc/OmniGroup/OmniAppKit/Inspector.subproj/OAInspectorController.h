// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorController.h,v 1.35 2004/02/10 04:07:32 kc Exp $

#import <Foundation/NSObject.h>

@class NSWindow, NSView, NSMenuItem;
@class OAInspectorWindow, OAInspectorHeaderView, OAInspectorResizer, OAInspectorGroup;

#import <Foundation/NSGeometry.h> // for NSSize, NSPoint
#import <OmniAppKit/OAGroupedInspectorProtocol.h>

#define OAInspectorStartingHeaderButtonWidth (214.0)
#define OAInspectorStartingHeaderButtonHeight (16.0)
#define OAInspectorSpaceBetweenButtons (0.0)

#define OAInspectorColumnSpacing (1.0)

@interface OAInspectorController : NSObject
{
    NSObject <OAGroupedInspector> *inspector;
    OAInspectorGroup *group;
    OAInspectorWindow *window;
    OAInspectorHeaderView *headingButton;
    OAInspectorResizer *resizerView;
    NSMenuItem *menuItem;
    NSView *controlsView;
    BOOL loadedInspectorView, isExpanded, isSettingExpansion, isBottommostInGroup, collapseOnTakeNewPosition, widthSizable, heightSizable, forceResizeWidget, needsToggleBeforeDisplay;
    float _initialInspectorWidth; // Use the -desiredWidth method to make sure you go through the inspector hook
    NSSize minimumSize;
    NSPoint newPosition;
}

// API

- initWithInspector:(NSObject <OAGroupedInspector> *)anInspector;

- (void)setGroup:(OAInspectorGroup *)aGroup;
- (NSObject <OAGroupedInspector> *)inspector;
- (NSWindow *)window;
- (BOOL)isExpanded;
- (NSString *)identifier;
- (NSMenuItem *)menuItem;
- (float)minimumWidth;
- (float)desiredWidth;
- (float)headingHeight;
- (float)desiredHeightWhenExpanded;

- (void)prepareWindowForDisplay;
- (void)displayWindow;
- (void)toggleDisplay;
- (void)showInspector;

- (void)setBottommostInGroup:(BOOL)isBottom;

- (void)toggleExpandednessWithNewTopLeftPoint:(NSPoint)topLeftPoint animate:(BOOL)animate;
- (void)updateExpandedness; // call when the inspector sets its size internally by itself

- (void)setNewPosition:(NSPoint)aPosition;
- (void)setCollapseOnTakeNewPosition:(BOOL)yn;
- (float)heightAfterTakeNewPosition;
- (void)takeNewPositionWithWidth:(float)aWidth;

- (void)loadInterface;
- (void)updateInspector;
- (void)inspectNothing;

@end
