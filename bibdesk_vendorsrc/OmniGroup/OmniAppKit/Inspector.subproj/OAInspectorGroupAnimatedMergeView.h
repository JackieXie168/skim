// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorGroupAnimatedMergeView.h,v 1.4 2004/02/10 04:07:33 kc Exp $

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
