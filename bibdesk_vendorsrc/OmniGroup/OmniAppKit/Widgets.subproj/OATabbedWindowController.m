// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OATabbedWindowController.h>

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniAppKit/OATabViewController.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATabbedWindowController.m,v 1.13 2003/01/15 22:51:45 kc Exp $")

@interface OATabbedWindowController (Private)
@end

@implementation OATabbedWindowController

//
// API
//

- (void)refreshUserInterface;
{
    [[self currentTabViewController] refreshUserInterface];
}

- (OATabViewController *)currentTabViewController;
{
    return [nonretainedCurrentTabViewItem identifier];
}


//
// NSObject subclass
//

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation invokeWithTarget:[self currentTabViewController]];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature;

    signature = [super methodSignatureForSelector:aSelector];
    if (signature)
        return signature;
    return [[self currentTabViewController] methodSignatureForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [super respondsToSelector:aSelector] || [[self currentTabViewController] respondsToSelector:aSelector];
}


//
// NSWindowController subclass
//

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
    OATabViewController *currentTabViewController;
    
    currentTabViewController = [self currentTabViewController];
    if (currentTabViewController && ![currentTabViewController validateMenuItem:anItem])
        return NO;

    return [super validateMenuItem:anItem];
}    


//
// NSTabView delegate
//

- (void)tabView:(NSTabView *)aTabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem;
{
    nonretainedCurrentTabViewItem = tabViewItem;

    if ([[nonretainedCurrentTabViewItem identifier] respondsToSelector:@selector(willSelectInTabView:)])
        [[nonretainedCurrentTabViewItem identifier] willSelectInTabView:aTabView];
}

@end


@implementation OATabbedWindowController (Private)
@end

