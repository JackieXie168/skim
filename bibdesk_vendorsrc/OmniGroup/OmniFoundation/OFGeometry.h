// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFGeometry.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/FrameworkDefines.h>
#import <Foundation/NSGeometry.h>

@class NSArray, NSMutableArray;


OmniFoundation_EXTERN NSPoint OFCenterOfCircleFromThreePoints(NSPoint point1, NSPoint point2, NSPoint point3);
OmniFoundation_EXTERN NSRect OFRectFromPoints(NSPoint point1, NSPoint point2);

/*" Returns a rect constrained to lie within boundary. This differs from NSIntersectionRect() in that it will adjust the rectangle's origin in order to place it within the boundary rectangle, and will only reduce the rectangle's size if necessary to make it fit. "*/
OmniFoundation_EXTERN NSRect OFConstrainRect(NSRect rect, NSRect boundary);

/*" Returns a rectangle centered on the specified point, and with the specified size. "*/
static inline NSRect OFRectFromCenterAndSize(NSPoint center, NSSize size) {
    return (NSRect){
              origin: { center.x - (size.width/2), center.y - (size.height/2) },
              size: size
    };
}

OmniFoundation_EXTERN float OFSquaredDistanceToFitRectInRect(NSRect sourceRect, NSRect destinationRect);
OmniFoundation_EXTERN NSRect OFClosestRectToRect(NSRect sourceRect, NSArray *candidateRects);
OmniFoundation_EXTERN void OFUpdateRectsToAvoidRectGivenMinimumSize(NSMutableArray *rects, NSRect rectToAvoid, NSSize minimumSize);
/*" Returns YES if sourceSize is at least as tall and as wide as minimumSize, and that neither the height nor the width of minimumSize is 0. "*/
static inline BOOL OFSizeIsOfMinimumSize(NSSize sourceSize, NSSize minimumSize)
{
    return (sourceSize.width >= minimumSize.width) && (sourceSize.height >= minimumSize.height) && (sourceSize.width > 0.0) && (sourceSize.height > 0.0);
}

OmniFoundation_EXTERN NSRect OFLargestRectAvoidingRectAndFitSize(NSRect parentRect, NSRect childRect, NSSize fitSize);
#define OFLargestRectAvoidingRect(parentRect, childRect) \
OFLargestRectAvoidingRectAndFitSize(parentRect, childRect, NSZeroSize)

OmniFoundation_EXTERN NSRect OFRectIncludingPoint(NSRect inRect, NSPoint p);

