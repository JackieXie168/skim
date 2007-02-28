// Copyright 2001-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OADockStatusItem.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSObject.h>

@class NSColor, NSImage;

#import <Foundation/NSGeometry.h>

@interface OADockStatusItem : NSObject 
{
    NSImage *icon;
    unsigned int count;
    BOOL isHidden;
}

- initWithIcon:(NSImage *)newIcon;

// API
- (void)setCount:(unsigned int)aCount;
- (void)setNoCount;

- (void)hide;
- (void)show;
- (BOOL)isHidden;

@end
