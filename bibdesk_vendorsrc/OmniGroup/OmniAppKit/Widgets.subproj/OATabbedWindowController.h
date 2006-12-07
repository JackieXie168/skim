// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATabbedWindowController.h,v 1.10 2003/01/15 22:51:45 kc Exp $

#import <AppKit/NSWindowController.h>
#import <AppKit/NSNibDeclarations.h>

@class NSTabView, NSTabViewItem;
@class OATabViewController;

@interface OATabbedWindowController : NSWindowController
{
    IBOutlet NSTabView *tabView;

    NSTabViewItem *nonretainedCurrentTabViewItem;
}

// API
- (void)refreshUserInterface;
- (OATabViewController *)currentTabViewController;

@end


@interface NSObject (OATabViewItemController)
- (void)willSelectInTabView:(NSTabView *)tabView;
@end
