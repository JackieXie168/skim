// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineDragPoint.h,v 1.8 2003/01/15 22:51:40 kc Exp $

// OAOutlineView uses instances of this class to track valid drop points for a drag operation.


#import <OmniFoundation/OFObject.h>

@class OAOutlineEntry;

#import <Foundation/NSGeometry.h> // for NSPoint

@interface OAOutlineDragPoint : OFObject <NSCopying>
{
    unsigned int index;
    OAOutlineEntry *entry;
    NSPoint position;
}

- (unsigned int)index;
- (OAOutlineEntry *)entry;
- (float)x;
- (float)y;

- (void)setIndex:(unsigned int)anIndex;
- (void)setEntry:(OAOutlineEntry *)anEntry;
- (void)setPosition:(NSPoint)aPosition;
- (void)addDX:(float)dx;
- (void)addDY:(float)dy;

@end
