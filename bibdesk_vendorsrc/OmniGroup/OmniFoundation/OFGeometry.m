// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OFGeometry.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#import <OmniBase/assertions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFGeometry.m,v 1.4 2003/01/15 22:51:50 kc Exp $");


NSPoint OFCenterOfCircleFromThreePoints(NSPoint point1, NSPoint point2, NSPoint point3)
{
    // from http://www.geocities.com/kiranisingh/center.html
    double x1 = point1.x, y1 = point1.y;
    double x2 = point2.x, y2 = point2.y;
    double x3 = point3.x, y3 = point3.y;
    double N1[2][2] = {
    {x2*x2 + y2*y2 - (x1*x1 + y1*y1), y2 - y1},
    {x3*x3 + y3*y3 - (x1*x1 + y1*y1), y3 - y1}
    };
    double N2[2][2] = {
    {x2 - x1, x2*x2 + y2*y2 - (x1*x1 + y1*y1)},
    {x3 - x1, x3*x3 + y3*y3 - (x1*x1 + y1*y1)}
    };
    double D[2][2] = {
    {x2 - x1, y2 - y1},
    {x3 - x1, y3 - y1}
    };

    double determinantN1 = N1[0][0] * N1[1][1] - N1[1][0] * N1[0][1];
    double determinantN2 = N2[0][0] * N2[1][1] - N2[1][0] * N2[0][1];
    double determinantD = D[0][0] * D[1][1] - D[1][0] * D[0][1];

    return NSMakePoint(determinantN1 / (2.0 * determinantD), determinantN2 / (2.0 * determinantD));
}

NSRect OFRectFromPoints(NSPoint point1, NSPoint point2)
{
    return NSMakeRect(MIN(point1.x, point2.x), MIN(point1.y, point2.y), MAX(point1.x, point2.x) - MIN(point1.x, point2.x), MAX(point1.y, point2.y) - MIN(point1.y, point2.y));
}


NSRect OFConstrainRect(NSRect rect, NSRect boundary)
{
    rect.size.width = MIN(rect.size.width, boundary.size.width);
    rect.size.height = MIN(rect.size.height, boundary.size.height);
    
    if (NSMinX(rect) < NSMinX(boundary))
        rect.origin.x = boundary.origin.x;
    else if (NSMaxX(rect) > NSMaxX(boundary))
        rect.origin.x = NSMaxX(boundary) - rect.size.width;

    if (NSMinY(rect) < NSMinY(boundary))
        rect.origin.y = boundary.origin.y;
    else if (NSMaxY(rect) > NSMaxY(boundary))
        rect.origin.y = NSMaxY(boundary) - rect.size.height;

    OBPOSTCONDITION(NSContainsRect(boundary, rect));

    return rect;
}
