// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OABackgroundImageControl.h,v 1.3 2004/02/10 04:07:36 kc Exp $

#import <AppKit/NSControl.h>

@interface OABackgroundImageControl : NSControl
{
    NSImage *backgroundImage;

    struct {
        unsigned int backgroundIsValid:1;
        unsigned int doNotDrawFocusRing:1;
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
