// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OASplitView.h,v 1.7 2004/02/10 04:07:38 kc Exp $

#import <AppKit/NSSplitView.h>

@interface OASplitView : NSSplitView
{
    NSString *positionAutosaveName;
}

- (void)setPositionAutosaveName:(NSString *)name;
- (NSString *)positionAutosaveName;

@end


@interface NSObject (OASplitViewExtendedDelegate)
- (void)splitViewDoubleClick:(OASplitView *)sender; // Called when the divider is double-clicked.
@end