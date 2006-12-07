// Copyright 2001-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <AppKit/NSImageView.h>

// Workaround for a bug in NSToolbarItem where custom views that respond to setImage
// end up having that method called twice and their image tus destroyed.

@interface OAToolbarImageView : NSImageView {
}

- (void)reallySetImage:(NSImage *)anImage;

@end
