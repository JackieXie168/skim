// Copyright 2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorGroupAnimatedMergeView.h,v 1.2 2003/02/21 19:57:23 kc Exp $

#import <AppKit/NSView.h>

@class NSTimer;
@class NSBitmapImageRep;

#import <Foundation/NSGeometry.h> // For NSRect

@interface OAInspectorGroupAnimatedMergeView : NSView
{
    NSBitmapImageRep *bitmapImageRep;
    NSRect upperRect, lowerRect;
    float throbOffset;
}

// API
- (void)setUpperGroupRect:(NSRect)newUpperRect lowerGroupRect:(NSRect)newLowerRect windowFrame:(NSRect)windowFrame;

- (void)throbOnce:(NSTimer *)timer;

@end
