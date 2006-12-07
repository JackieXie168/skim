// Copyright 2006 Omni Development, Inc.  All rights reserved.
//
//  OFUnitValueTests.m
//  OmniFoundation
//
//  Copyright 2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//


#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <SenTestingKit/SenTestingKit.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniFoundation/OFDimensionedValue.h>
#import <OmniFoundation/OFUnit.h>
#import <OmniFoundation/OFUnits.h>
#import "OmniFoundationTestUtils.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Tests/OFUnitValueTests.m 79079 2006-09-07 22:35:32Z kc $");

@interface OFUnitValueTests : SenTestCase
{
}

@end


@implementation OFUnitValueTests

- (void)testDistanceParsing
{
    OFUnits *u = [OFUnits loadUnitsNamed:@"distance" inBundle:[NSBundle bundleForClass:[OFUnits class]]];
    OFDimensionedValue *a, *b, *c, *d, *e, *f, *g;
    OFUnit *meter, *kilometer, *point, *pica, *inch, *foot;
    
    a = [u parseString:@"1 km" defaultUnit:nil];
    should([[a dimension] hasName:@"kilometer"]);
    kilometer = [a dimension];
    shouldBeEqual([a value], [NSNumber numberWithInt:1]);
    shouldBeEqual([a value], [NSNumber numberWithFloat:1.0]);
    shouldBeEqual([u storageStringForValue:a], @"1 km");
    
    b = [u parseString:@"1 m" defaultUnit:nil];
    should([[b dimension] hasName:@"m"]);
    meter = [b dimension];
    shouldBeEqual([b value], [NSNumber numberWithInt:1]);
    shouldBeEqual([b value], [NSNumber numberWithFloat:1.0]);
    shouldBeEqual([u storageStringForValue:b], @"1 m");
    
    c = [u parseString:@"1 kilometer 1 meter" defaultUnit:nil];
    shouldBeEqual([u getValue:c inUnit:meter], [NSNumber numberWithInt:1001]);
    shouldBeEqual([u storageStringForValue:c], @"1001 m");
    
    d = [u parseString:@"48 pt" defaultUnit:nil];
    point = [u unitFromString:@"point"];
    should(point != nil);
    pica = [u unitFromString:@"pica"];
    should(pica != nil);
    foot = [u unitFromString:@"feet"];
    should(foot != nil);
    inch = [u unitFromString:@"inches"];
    should(inch != nil);
    shouldBeEqual([u getValue:d inUnit:point], [NSNumber numberWithInt:48]);
    shouldBeEqual([u getValue:d inUnit:pica], [NSNumber numberWithInt:4]);
    shouldBeEqual([u getValue:d inUnit:inch], [NSNumber numberWithRatio:OFRationalInverse(OFRationalFromDouble(6./4.))]);
    
    e = [u parseString:@"2/3 foot" defaultUnit:nil];
    should([[e dimension] hasName:@"feet"]);
    shouldBeEqual([u getValue:e inUnit:inch], [NSNumber numberWithInt:8]);
    
    f = [u parseString:@"5' 2\"" defaultUnit:nil];
    shouldBeEqual([u getValue:f inUnit:inch], [NSNumber numberWithInt: 62 ]);  // and eyes of blue
    shouldBeEqual([u getValue:f inUnit:foot], [NSNumber numberWithRatio: 62:12 ]);
    
    g = [u parseString:@"-2/3" defaultUnit:pica];
    should([g dimension] == pica);
    shouldBeEqual([u getValue:g inUnit:inch], [NSNumber numberWithRatio: -2:18 ]);
}

@end
