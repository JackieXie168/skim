// Copyright 2001-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OADockStatusItem.h,v 1.9 2004/02/10 04:07:37 kc Exp $

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
