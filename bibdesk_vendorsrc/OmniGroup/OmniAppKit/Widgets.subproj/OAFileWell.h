// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAFileWell.h,v 1.6 2004/02/10 04:07:37 kc Exp $

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
