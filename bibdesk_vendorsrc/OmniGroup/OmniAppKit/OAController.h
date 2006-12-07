// Copyright 2004-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OAController.h 75186 2006-05-12 21:50:30Z bungi $

#import <OmniFoundation/OFController.h>

@class OAAboutPanelController;

#import <AppKit/NSNibDeclarations.h> // For IBAction and IBOutlet

@interface OAController : OFController
{
    OAAboutPanelController *aboutPanelController;
}

- (OAAboutPanelController *)aboutPanelController;

- (IBAction)showAboutPanel:(id)sender;
- (IBAction)hideAboutPanel:(id)sender;

@end
