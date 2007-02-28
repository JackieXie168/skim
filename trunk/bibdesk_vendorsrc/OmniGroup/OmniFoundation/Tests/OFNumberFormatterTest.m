// Copyright 2000-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#define STEnableDeprecatedAssertionMacros
#import <SenTestingKit/SenTestingKit.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Tests/OFNumberFormatterTest.m 79087 2006-09-07 23:37:02Z kc $")

@interface OFNumberFormatterTest : SenTestCase
{
}

@end

@implementation OFNumberFormatterTest

- (void)testNegativeDecimalString;
{
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [numberFormatter setFormat:@"###;$0.00;(0.00000)"];

    NSDecimalNumber *originalValue = [NSDecimalNumber decimalNumberWithString:@"-1.01234"];
    NSString *str = [numberFormatter stringForObjectValue:originalValue];
    shouldBeEqual(str, @"(1.01234)");

    id objectValue;
    NSString *error = (id)0xdeadbeef; // make sure this doesn't get written
    BOOL result = [numberFormatter getObjectValue:&objectValue forString:str errorDescription:&error];
    should(error == (id)0xdeadbeef);
    should(result);
    shouldBeEqual(objectValue, originalValue);
}

@end
