// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OAScriptToolbarHelper.h 71209 2005-12-16 00:31:58Z bungi $

#import <Foundation/NSObject.h>

#import "OAToolbarWindowController.h"

@class OAToolbarItem;

@interface OAScriptToolbarHelper : NSObject <OAToolbarHelper> 
@end

@interface OAToolbarWindowController (OAScriptToolbarHelperExtensions)
- (BOOL)scriptToolbarItemShouldExecute:(OAToolbarItem *)item;
- (void)scriptToolbarItemFinishedExecuting:(OAToolbarItem *)item; // might be success, might be failure.
@end
