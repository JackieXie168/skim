// Copyright 2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

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
