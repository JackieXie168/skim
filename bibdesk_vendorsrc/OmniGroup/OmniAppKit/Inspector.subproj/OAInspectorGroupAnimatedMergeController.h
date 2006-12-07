// Copyright 2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorGroupAnimatedMergeController.h,v 1.3 2003/04/01 01:49:29 toon Exp $

#import <Foundation/NSObject.h>

@class NSTimer;
@class NSWindow;
@class OAInspectorGroupAnimatedMergeView;

#import <Foundation/NSGeometry.h> // For NSRect

@interface OAInspectorGroupAnimatedMergeController : NSObject
{
    NSWindow *shadowWindow;
    OAInspectorGroupAnimatedMergeView *animatedMergeView;
    NSTimer *throbTimer;
}

+ (OAInspectorGroupAnimatedMergeController *)sharedInspectorGroupAnimatedMergeController;

// API
- (void)animateWithFirstGroupRect:(NSRect)newARect andSecondGroupRect:(NSRect)newBRect atLevel:(int)windowLevel;
- (void)closeWindow;

@end
