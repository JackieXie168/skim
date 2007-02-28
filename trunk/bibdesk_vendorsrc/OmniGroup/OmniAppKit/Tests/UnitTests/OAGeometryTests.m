// Copyright 2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OATestCase.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>
#import <AppKit/AppKit.h>
#import <OmniAppKit/OmniAppKit.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Tests/UnitTests/OAGeometryTests.m 73779 2006-03-29 01:30:47Z wiml $");

@interface OAGeometryTests : OATestCase
@end

extern void testLineLineIntersections(void);
extern void testLineCurveIntersections(void);

@implementation OAGeometryTests

- (void)testLineLineIntersections
{
    testLineLineIntersections();
}

- (void)testLineCurveIntersections
{
    testLineCurveIntersections();
}

@end

