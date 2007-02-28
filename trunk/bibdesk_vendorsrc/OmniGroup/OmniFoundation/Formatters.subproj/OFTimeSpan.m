// Copyright 2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFTimeSpan.h"

#import <OmniBase/rcsid.h>

#import "OFTimeSpanFormatter.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFTimeSpan.m 79081 2006-09-07 22:50:49Z kc $")

@implementation OFTimeSpan

- initWithTimeSpanFormatter:(OFTimeSpanFormatter *)aFormatter;
{
    [super init];
    createdByFormatter = [aFormatter retain];
    years = months = weeks = days = hours = minutes = seconds = 0.0;
    return self;
}

- (void)dealloc;
{
    [createdByFormatter release];
    [super dealloc];
}

- (void)setYears:(float)aValue;
{
    years = aValue;
}

- (void)setMonths:(float)aValue;
{
    months = aValue;
}

- (void)setWeeks:(float)aValue;
{
    weeks = aValue;
}

- (void)setDays:(float)aValue;
{
    days = aValue;
}

- (void)setHours:(float)aValue;
{
    hours = aValue;
}

- (void)setMinutes:(float)aValue;
{
    minutes = aValue;
}

- (void)setSeconds:(float)aValue;
{
    seconds = aValue;
}

- (float)years;
{
    return years;
}

- (float)months;
{
    return months;
}

- (float)weeks;
{
    return weeks;
}

- (float)days;
{
    return days;
}

- (float)hours;
{
    return hours;
}

- (float)minutes;
{
    return minutes;
}

- (float)seconds;
{   
    return seconds;
}

- (float)floatValue;
{
    return years * (float)[createdByFormatter hoursPerYear] + months * (float)[createdByFormatter hoursPerMonth] + weeks * (float)[createdByFormatter hoursPerWeek] + days * (float)[createdByFormatter hoursPerDay] + hours + minutes/60.0 + seconds/3600.0;
}

- (id)copyWithZone:(NSZone *)zone;
{
    OFTimeSpan *result = [[OFTimeSpan allocWithZone:zone] initWithTimeSpanFormatter:createdByFormatter];
    [result setYears:years];
    [result setMonths:months];
    [result setWeeks:weeks];
    [result setDays:days];
    [result setHours:hours];
    [result setMinutes:minutes];
    [result setSeconds:seconds];
    return result;
}

@end
