// Copyright 2004-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header$

#import <AppKit/NSToolbar.h>

@interface OAToolbar : NSToolbar
{
    BOOL                 _isUpdatingDisplayMode;
    NSToolbarDisplayMode _updatingDisplayMode;
    
    BOOL              _isUpdatingSizeMode;
    NSToolbarSizeMode _updatingSizeMode;
}

- (NSToolbarDisplayMode)updatingDisplayMode;
- (NSToolbarSizeMode)updatingSizeMode;

@end

@interface NSObject (OAToolbarDelegate)
- (void)toolbar:(OAToolbar *)aToolbar willSetDisplayMode:(NSToolbarDisplayMode)displayMode;
- (void)toolbar:(OAToolbar *)aToolbar didSetDisplayMode:(NSToolbarDisplayMode)displayMode;
- (void)toolbar:(OAToolbar *)aToolbar willSetSizeMode:(NSToolbarSizeMode)sizeMode;
- (void)toolbar:(OAToolbar *)aToolbar didSetSizeMode:(NSToolbarSizeMode)sizeMode;
@end
