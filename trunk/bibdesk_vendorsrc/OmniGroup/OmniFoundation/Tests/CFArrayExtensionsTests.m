// Copyright 2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#define STEnableDeprecatedAssertionMacros
#import <SenTestingKit/SenTestingKit.h>
#import <OmniFoundation/CFArray-OFExtensions.h>
#import <OmniFoundation/NSString-OFExtensions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Tests/CFArrayExtensionsTests.m 79087 2006-09-07 23:37:02Z kc $");

@interface CFArrayExtensionsTests :  SenTestCase
@end

@implementation CFArrayExtensionsTests

- (void)testPointerArray;
{
    NSMutableArray *array = OFCreateNonOwnedPointerArray();
    [array addObject:(id)0xdeadbeef];
    should([array count] == 1);
    should([array objectAtIndex:0] == (id)0xdeadbeef);
    should([array indexOfObject:(id)0xdeadbeef] == 0);
    
    // This crashes; -[NSArray description] isn't the same, apparently
    //NSString *description = [array description];
    NSString *description = [(id)CFCopyDescription(array) autorelease];
    
    should([description containsString:@"0xdeadbeef"]);
}

- (void)testIntegerArray;
{
    NSMutableArray *array = OFCreateIntegerArray();
    [array addObject:(id)6060842];
    should([array count] == 1);
    should([array objectAtIndex:0] == (id)6060842);
    should([array indexOfObject:(id)6060842] == 0);

    // This crashes; -[NSArray description] isn't the same, apparently
    //NSString *description = [array description];
    NSString *description = [(id)CFCopyDescription(array) autorelease];
    
    should([description containsString:@"6060842"]);
}

@end
