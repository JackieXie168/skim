// Copyright 2005-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#define STEnableDeprecatedAssertionMacros
#import <SenTestingKit/SenTestingKit.h>

#import <OmniBase/rcsid.h>
#import <OmniFoundation/NSAttributedString-OFExtensions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Tests/OFAttributedStringExtensionsTest.m 79087 2006-09-07 23:37:02Z kc $");

@interface OFAttributedStringExtensionsTest : SenTestCase
@end

static void _testSeparate(id self, NSString *string, NSString *separator, ...)
{
    NSAttributedString *sourceString = [[[NSAttributedString alloc] initWithString:string attributes:nil] autorelease];
    NSArray *components = [sourceString componentsSeparatedByString:separator];
    NSMutableArray *array = [NSMutableArray array];
    va_list argList;
    va_start(argList, separator);
    id obj;
    while ((obj = va_arg(argList, id))) {
        obj = [[NSAttributedString alloc] initWithString:obj attributes:nil];
        [array addObject:obj];
        [obj release];
    }
    va_end(argList);
    
    shouldBeEqual(components, array);
}

@implementation OFAttributedStringExtensionsTest

- (void)testComponentsSeparatedByString;
{
    _testSeparate(self, @"bab", @"a", @"b", @"b", nil);
    _testSeparate(self, @"ba", @"a", @"b", @"", nil);
    _testSeparate(self, @"aaa", @"a", @"", @"", @"", @"", nil);
}

@end


