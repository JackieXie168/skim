// Copyright 2004-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#define STEnableDeprecatedAssertionMacros
#import <SenTestingKit/SenTestingKit.h>

#import <OmniBase/rcsid.h>
#import <OmniFoundation/OFVersionNumber.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Tests/OFVersionNumberTests.m 79087 2006-09-07 23:37:02Z kc $");

@interface OFVersionNumberTest : SenTestCase
@end

@implementation OFVersionNumberTest

- (void)testVPrefix;
{
    OFVersionNumber *vn;

    vn = [[[OFVersionNumber alloc] initWithVersionString:@"v1.2"] autorelease];
    should(vn != nil);
    should([vn componentCount] == 2);
    should([vn componentAtIndex:0] == 1);
    should([vn componentAtIndex:1] == 2);

    vn = [[[OFVersionNumber alloc] initWithVersionString:@"V1.2"] autorelease];
    should(vn != nil);
    should([vn componentCount] == 2);
    should([vn componentAtIndex:0] == 1);
    should([vn componentAtIndex:1] == 2);

    vn = [[[OFVersionNumber alloc] initWithVersionString:@"vv1.2"] autorelease];
    should(vn == nil); // Only one 'v' allowed
}

- (void)testIgnoringCruftAtEnd;
{
    OFVersionNumber *vn;

    vn = [[[OFVersionNumber alloc] initWithVersionString:@"v1.2xyz"] autorelease];
    should(vn != nil);
    should([vn componentCount] == 2);
    should([vn componentAtIndex:0] == 1);
    should([vn componentAtIndex:1] == 2);

    vn = [[[OFVersionNumber alloc] initWithVersionString:@"v1.2.xyz"] autorelease];
    should(vn != nil);
    should([vn componentCount] == 2);
    should([vn componentAtIndex:0] == 1);
    should([vn componentAtIndex:1] == 2);

    vn = [[[OFVersionNumber alloc] initWithVersionString:@"v1.2 xyz"] autorelease];
    should(vn != nil);
    should([vn componentCount] == 2);
    should([vn componentAtIndex:0] == 1);
    should([vn componentAtIndex:1] == 2);

    vn = [[[OFVersionNumber alloc] initWithVersionString:@"v1.2."] autorelease];
    should(vn != nil);
    should([vn componentCount] == 2);
    should([vn componentAtIndex:0] == 1);
    should([vn componentAtIndex:1] == 2);
}

- (void)testInvalid;
{
    shouldBeEqual([[[OFVersionNumber alloc] initWithVersionString:@""] autorelease], nil);
    shouldBeEqual([[[OFVersionNumber alloc] initWithVersionString:@"v"] autorelease], nil);
    shouldBeEqual([[[OFVersionNumber alloc] initWithVersionString:@"v."] autorelease], nil);
    shouldBeEqual([[[OFVersionNumber alloc] initWithVersionString:@".1"] autorelease], nil);
    shouldBeEqual([[[OFVersionNumber alloc] initWithVersionString:@"-.1"] autorelease], nil);
    shouldBeEqual([[[OFVersionNumber alloc] initWithVersionString:@" v1"] autorelease], nil); // We don't allow leading whitespace right now; maybe we should
}

- (void)testVersionStrings;
{
    OFVersionNumber *vn;

    vn = [[[OFVersionNumber alloc] initWithVersionString:@"v1.2xyz"] autorelease];
    shouldBeEqual([vn originalVersionString], @"v1.2xyz");
    shouldBeEqual([vn cleanVersionString], @"1.2");
}

- (void)testComparison;
{
    OFVersionNumber *a, *b;

    //
    a = [[[OFVersionNumber alloc] initWithVersionString:@"1"] autorelease];
    b = [[[OFVersionNumber alloc] initWithVersionString:@"1"] autorelease];
    should([a compareToVersionNumber:b] == NSOrderedSame);
    should([b compareToVersionNumber:a] == NSOrderedSame);

    //
    a = [[[OFVersionNumber alloc] initWithVersionString:@"1"] autorelease];
    b = [[[OFVersionNumber alloc] initWithVersionString:@"1.0"] autorelease];
    should([a compareToVersionNumber:b] == NSOrderedSame);
    should([b compareToVersionNumber:a] == NSOrderedSame);

    //
    a = [[[OFVersionNumber alloc] initWithVersionString:@"1"] autorelease];
    b = [[[OFVersionNumber alloc] initWithVersionString:@"1.0.0"] autorelease];
    should([a compareToVersionNumber:b] == NSOrderedSame);
    should([b compareToVersionNumber:a] == NSOrderedSame);

    //
    a = [[[OFVersionNumber alloc] initWithVersionString:@"1.0"] autorelease];
    b = [[[OFVersionNumber alloc] initWithVersionString:@"1.0.0"] autorelease];
    should([a compareToVersionNumber:b] == NSOrderedSame);
    should([b compareToVersionNumber:a] == NSOrderedSame);

    //
    a = [[[OFVersionNumber alloc] initWithVersionString:@"1"] autorelease];
    b = [[[OFVersionNumber alloc] initWithVersionString:@"2"] autorelease];
    should([a compareToVersionNumber:b] == NSOrderedAscending);
    should([b compareToVersionNumber:a] == NSOrderedDescending);

    //
    a = [[[OFVersionNumber alloc] initWithVersionString:@"1"] autorelease];
    b = [[[OFVersionNumber alloc] initWithVersionString:@"1.1"] autorelease];
    should([a compareToVersionNumber:b] == NSOrderedAscending);
    should([b compareToVersionNumber:a] == NSOrderedDescending);
    
    //
    a = [[[OFVersionNumber alloc] initWithVersionString:@"1"] autorelease];
    b = [[[OFVersionNumber alloc] initWithVersionString:@"1.1.0"] autorelease];
    should([a compareToVersionNumber:b] == NSOrderedAscending);
    should([b compareToVersionNumber:a] == NSOrderedDescending);
}

@end
