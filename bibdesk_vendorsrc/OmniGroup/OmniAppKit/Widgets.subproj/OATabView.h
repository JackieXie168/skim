// Copyright 1999-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATabView.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSNibDeclarations.h> // For IBOutlet
#import <AppKit/NSTabView.h>

@class OATabViewController;

@interface OATabView : NSTabView
{
    IBOutlet OATabViewController *controller1; // Outlets to the view controllers
    IBOutlet OATabViewController *controller2;
    IBOutlet OATabViewController *controller3;
    IBOutlet OATabViewController *controller4;
    IBOutlet OATabViewController *controller5;
    IBOutlet OATabViewController *controller6;
    IBOutlet OATabViewController *controller7;
    IBOutlet OATabViewController *controller8;

    struct {
        unsigned int alreadyAwoke:1;
    } flags;
}

@end
