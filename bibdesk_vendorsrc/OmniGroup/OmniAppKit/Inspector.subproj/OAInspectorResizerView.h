// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorResizerView.h,v 1.5 2003/01/15 22:51:34 kc Exp $

#import <AppKit/NSSplitView.h>

@class NSButtonCell;

#import <AppKit/NSNibDeclarations.h> // For IBOutlet

@interface OAInspectorResizerView : NSSplitView 
{
    IBOutlet NSView *viewToResize;

    float minimumHeight;
    BOOL isResizing;
    NSButtonCell *buttonCell;
}

- (void)setViewToResize:(NSView *)aView;
- (void)setMinimumHeight:(float)aHeight;

@end
