// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSDate-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSDate-OFExtensions.m,v 1.14 2004/02/10 04:07:45 kc Exp $")

@implementation NSDate (OFExtensions)

- (NSString *)descriptionWithHTTPFormat; // rfc1123 format with TZ forced to GMT
{
    // see rfc2616 [3.3.1]
    return [self descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %Z" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
}

- (void)sleepUntilDate;
{
    NSTimeInterval timeIntervalSinceNow;

    timeIntervalSinceNow = [self timeIntervalSinceNow];
    if (timeIntervalSinceNow < 0)
	return;
    [NSThread sleepUntilDate:self];
}

- (BOOL)isAfterDate:(NSDate *)otherDate
{
    return [self compare:otherDate] == NSOrderedDescending;
}

- (BOOL)isBeforeDate:(NSDate *)otherDate
{
    return [self compare:otherDate] == NSOrderedAscending;
}

@end
