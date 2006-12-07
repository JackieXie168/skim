// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAColorInspector.h,v 1.9 2004/02/10 04:07:32 kc Exp $

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <OmniAppKit/OAGroupedInspectorProtocol.h>

@class NSView;

@interface OAColorInspector : NSObject <OAGroupedInspector>
{
    NSView *contentView;
    NSSize minimumContentSize;
    BOOL nestedResize;
}

// API
+ (OAInspectorController *)inspectorController;

@end
