// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OABackgroundImageControl.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSControl.h>

@interface OABackgroundImageControl : NSControl
{
    NSImage *backgroundImage;

    struct {
        unsigned int backgroundIsValid:1;
        unsigned int shouldDrawFocusRing:1;
        unsigned int drawingFocusRing:1;
    } backgroundImageControlFlags;
}

// API
- (void)rebuildBackgroundImage;
    // Call this method to invalidate the control's background image.  It will immediately recreate the background image, lock focus on it, and call -drawBackgroundImageForBounds: on itself (which is expected to be implemented by the subclass)
    
- (BOOL)drawsFocusRing;
    // Returns YES if the control draws a focus ring around the background image.  Defaults to YES.
- (void)setDrawsFocusRing:(BOOL)flag;

// Subclasses only
- (void)drawBackgroundImageForBounds:(NSRect)bounds;
- (void)drawForegroundRect:(NSRect)rect;

@end
