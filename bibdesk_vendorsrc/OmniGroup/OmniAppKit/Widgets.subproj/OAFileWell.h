// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAFileWell.h,v 1.4 2003/01/15 22:51:43 kc Exp $

#import <AppKit/NSView.h>

@interface OAFileWell : NSView
{
    BOOL acceptIncomingDrags;
    NSArray *files;
}

- (BOOL)acceptsIncomingDrags;
- (NSArray *)files;

- (void)setAcceptIncomingDrags:(BOOL)acceptIncoming;
- (void)setFiles:(NSArray *)someFiles;


@end
