// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <Foundation/NSGeometry.h>

@class OAShelfView;

@protocol OAShelfViewFormatter <NSObject>

- (void)drawBackground:(NSRect)rect ofShelf:(OAShelfView *)shelf;
- (void)drawEntry:(id)shelfEntry inRect:(NSRect)spot ofShelf:(OAShelfView *)shelf selected:(BOOL)isSelected dragging:(BOOL)isMoving;

@end
