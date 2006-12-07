// Copyright 2001-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <AppKit/NSToolbarItem.h>

@interface OAToolbarItem : NSToolbarItem
{
    id _delegate;
}

- (id)delegate;
- (void)setDelegate:(id)delegate;
    // Right now, the only thing we're doing with our delegate is 
    // using it as a validator; AppKit's auto-validation scheme can
    // be useful for changing more attributes than just enabled/disabled,
    // but it currently only works for items that have a target and
    // action, which many custom toolbar items don't.    
@end
