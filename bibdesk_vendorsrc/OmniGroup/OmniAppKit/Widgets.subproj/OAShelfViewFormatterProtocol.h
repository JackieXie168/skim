// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAShelfViewFormatterProtocol.h,v 1.6 2003/01/15 22:51:45 kc Exp $

#import <Foundation/NSGeometry.h>

@class OAShelfView;

@protocol OAShelfViewFormatter <NSObject>

- (void)drawBackground:(NSRect)rect ofShelf:(OAShelfView *)shelf;
- (void)drawEntry:(id)shelfEntry inRect:(NSRect)spot ofShelf:(OAShelfView *)shelf selected:(BOOL)isSelected dragging:(BOOL)isMoving;

@end
