// Copyright 2005-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#define STEnableDeprecatedAssertionMacros
#import <SenTestingKit/SenTestingKit.h>
#import <OmniFoundation/NSError-OFExtensions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Tests/OFErrorExtensionTests.m 79087 2006-09-07 23:37:02Z kc $");

@interface OFErrorExtensionTests : SenTestCase
@end

@implementation OFErrorExtensionTests

- (void)testSimpleError;
{
    NSError *error = nil;
    
    OFError(&error, foo, @"some reason");
    should(error != nil);
    shouldBeEqual([error domain], @"com.omnigroup.framework.OmniFoundation.UnitTests.ErrorDomain.foo");
    should([error code] == 0);
    shouldBeEqual([error localizedDescription], @"some reason");
}

- (void)testUnderlyingError;
{
    NSError *error = nil;
    
    OFErrorWithInfo(&error, foo, nil);
    OFErrorWithInfo(&error, bar, nil);
    
    should(error != nil);
    shouldBeEqual([error domain], @"com.omnigroup.framework.OmniFoundation.UnitTests.ErrorDomain.bar");
    should([error code] == 0);

    should([error userInfo] != nil);
    should([[error userInfo] count] == 2);
    should([[error userInfo] valueForKey:OFFileNameAndNumberErrorKey] != nil);
    
    NSError *underlyingError = [[error userInfo] valueForKey:NSUnderlyingErrorKey];
    should(underlyingError != nil);
    shouldBeEqual([underlyingError domain], @"com.omnigroup.framework.OmniFoundation.UnitTests.ErrorDomain.foo");
    should([underlyingError code] == 0);
}

// First key is special in how it is handled
- (void)testSingleKeyValue;
{
    NSError *error = nil;
    OFErrorWithInfo(&error, foo, @"MyKey", @"MyValue", nil);
    should([[error userInfo] count] == 2);
    should([[error userInfo] valueForKey:OFFileNameAndNumberErrorKey] != nil);
    should([[[error userInfo] valueForKey:@"MyKey"] isEqual:@"MyValue"]);
}

- (void)testMultipleKeyValue;
{
    NSError *error = nil;
    OFErrorWithInfo(&error, foo, @"MyKey1", @"MyValue1", @"MyKey2", @"MyValue2", nil);
    should([[error userInfo] count] == 3);
    should([[error userInfo] valueForKey:OFFileNameAndNumberErrorKey] != nil);
    should([[[error userInfo] valueForKey:@"MyKey1"] isEqual:@"MyValue1"]);
    should([[[error userInfo] valueForKey:@"MyKey2"] isEqual:@"MyValue2"]);
}

- (void)testFileAndLineNumber;
{
    NSError *error = nil;
    OFErrorWithInfo(&error, foo, nil);
    NSString *expectedFileAndLineNumber = [NSString stringWithFormat:@"%s:%d", __FILE__, __LINE__-1];
    
    should([[[error userInfo] valueForKey:OFFileNameAndNumberErrorKey] isEqual:expectedFileAndLineNumber]);
}

- (void)testCausedByUserCancelling_Not;
{
    NSError *error = nil;
    OFErrorWithInfo(&error, foo, nil);
    shouldnt([error causedByUserCancelling]);
}

- (void)testCausedByUserCancelling_Direct;
{
    NSError *error = nil;
    OFErrorWithInfo(&error, foo, OFUserCancelledActionErrorKey, [NSNumber numberWithBool:YES], nil);
    should([error causedByUserCancelling]);
}

- (void)testCausedByUserCancelling_Indirect;
{
    NSError *error = nil;
    OFErrorWithInfo(&error, foo, OFUserCancelledActionErrorKey, [NSNumber numberWithBool:YES], nil);
    OFErrorWithInfo(&error, bar, nil);
    should([error causedByUserCancelling]);
}

@end
