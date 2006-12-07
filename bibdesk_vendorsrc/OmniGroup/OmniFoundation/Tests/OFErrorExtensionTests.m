// Copyright 2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#import <SenTestingKit/SenTestingKit.h>
#import <OmniFoundation/NSError-OFExtensions.h>

RCS_ID("$Header$");

@interface OFErrorExtensionTests : SenTestCase
@end

@implementation OFErrorExtensionTests

- (void)testSimpleError;
{
    NSError *error = nil;
    
    OFError(&error, foo, nil);
    should(error != nil);
    shouldBeEqual([error domain], @"com.omnigroup.framework.OmniFoundation.UnitTests.ErrorDomain.foo");
    should([error code] == 0);
}

- (void)testUnderlyingError;
{
    NSError *error = nil;
    
    OFError(&error, foo, nil);
    OFError(&error, bar, nil);
    
    should(error != nil);
    shouldBeEqual([error domain], @"com.omnigroup.framework.OmniFoundation.UnitTests.ErrorDomain.bar");
    should([error code] == 0);

    should([error userInfo] != nil);
    should([[error userInfo] count] == 1);
    
    NSError *underlyingError = [[error userInfo] valueForKey:NSUnderlyingErrorKey];
    should(underlyingError != nil);
    shouldBeEqual([underlyingError domain], @"com.omnigroup.framework.OmniFoundation.UnitTests.ErrorDomain.foo");
    should([underlyingError code] == 0);
}

// First key is special in how it is handled
- (void)testSingleKeyValue;
{
    NSError *error = nil;
    OFError(&error, foo, @"MyKey", @"MyValue", nil);
    should([[error userInfo] count] == 1);
    should([[[error userInfo] valueForKey:@"MyKey"] isEqual:@"MyValue"]);
}

- (void)testMultipleKeyValue;
{
    NSError *error = nil;
    OFError(&error, foo, @"MyKey1", @"MyValue1", @"MyKey2", @"MyValue2", nil);
    should([[error userInfo] count] == 2);
    should([[[error userInfo] valueForKey:@"MyKey1"] isEqual:@"MyValue1"]);
    should([[[error userInfo] valueForKey:@"MyKey2"] isEqual:@"MyValue2"]);
}

- (void)testCausedByUserCancelling_Not;
{
    NSError *error = nil;
    OFError(&error, foo, nil);
    shouldnt([error causedByUserCancelling]);
}

- (void)testCausedByUserCancelling_Direct;
{
    NSError *error = nil;
    OFError(&error, foo, OFUserCancelledActionErrorKey, [NSNumber numberWithBool:YES], nil);
    should([error causedByUserCancelling]);
}

- (void)testCausedByUserCancelling_Indirect;
{
    NSError *error = nil;
    OFError(&error, foo, OFUserCancelledActionErrorKey, [NSNumber numberWithBool:YES], nil);
    OFError(&error, bar, nil);
    should([error causedByUserCancelling]);
}

@end
