// Copyright 2000-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#if defined(MAC_OS_X_VERSION_10_4) && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#define STEnableDeprecatedAssertionMacros
#import <SenTestingKit/SenTestingKit.h>
#import <OmniFoundation/NSComparisonPredicate-OFExtensions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Tests/OFComparisonPredicateExtensions.m 79087 2006-09-07 23:37:02Z kc $")

@interface OFComparisonPredicateExtensions : SenTestCase
@end

@implementation OFComparisonPredicateExtensions

- (void)testIsKindOfClassPredicate;
{
    NSDictionary *dictionary = [[NSDictionary alloc] init];
    
    NSPredicate *isKindOfDictionaryPredicate = [NSComparisonPredicate isKindOfClassPredicate:[NSDictionary class]];
    should([isKindOfDictionaryPredicate evaluateWithObject:dictionary]);
    
    NSPredicate *isKindOfArrayPredicate = [NSComparisonPredicate isKindOfClassPredicate:[NSArray class]];
    should(![isKindOfArrayPredicate evaluateWithObject:dictionary]);
    
    [dictionary release];
}

- (void)testConformsToProtocolPredicate;
{
    NSDictionary *dictionary = [[NSDictionary alloc] init];
    
    NSPredicate *conformsToCodingPredicate = [NSComparisonPredicate conformsToProtocolPredicate:@protocol(NSCoding)];
    should([conformsToCodingPredicate evaluateWithObject:dictionary]);
    
    NSPredicate *conformsToLockingPredicate = [NSComparisonPredicate conformsToProtocolPredicate:@protocol(NSLocking)];
    should(![conformsToLockingPredicate evaluateWithObject:dictionary]);
    
    [dictionary release];
}

@end

#endif
