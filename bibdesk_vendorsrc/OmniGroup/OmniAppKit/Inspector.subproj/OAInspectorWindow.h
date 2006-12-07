// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorWindow.h,v 1.7 2003/02/21 02:33:56 toon Exp $

#import <AppKit/NSPanel.h>

@interface OAInspectorWindow : NSPanel
{
}

// API

@end

@interface NSObject (AdditionalDelegateMethods)
- (NSRect)windowWillResizeFromFrame:(NSRect)fromRect toFrame:(NSRect)toRect;
@end