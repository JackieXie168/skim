// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OATabViewController.h>

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniAppKit/OATabbedWindowController.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATabViewController.m,v 1.21 2003/01/15 22:51:45 kc Exp $")


@interface OATabViewController (Private)
@end

@implementation OATabViewController

//
// API
//

- (NSString *)label;
{
    return NSStringFromClass([self class]);
}

- (NSDocument *)document;
{
    return [windowController document];
}

- (void)refreshUserInterface;
{
}

//
// NSNibAwaking informal protocol
//

- (void)awakeFromNib;
{
    if (flags.alreadyAwoke)
        return;
    flags.alreadyAwoke = YES;
}

//
// NSMenuValidation informal protocol
//

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
    return YES;
}

//
// OATabViewItemController informal protocol
//

- (void)willSelectInTabView:(NSTabView *)tabView;
{
    [self refreshUserInterface];
}

@end

@implementation OATabViewController (FriendClassesOnly)

- (NSWindow *)scratchWindow;
{
    return scratchWindow;
}

@end

@implementation OATabViewController (Private)
@end
