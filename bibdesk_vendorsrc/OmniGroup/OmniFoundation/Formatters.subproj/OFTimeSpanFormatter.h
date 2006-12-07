// Copyright 2000-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFTimeSpanFormatter.h 79079 2006-09-07 22:35:32Z kc $

#import <Foundation/NSFormatter.h>

#define STANDARD_WORK_HOURS_PER_DAY 8
#define STANDARD_WORK_HOURS_PER_WEEK (5 * STANDARD_WORK_HOURS_PER_DAY)
#define STANDARD_WORK_HOURS_PER_MONTH (4 * STANDARD_WORK_HOURS_PER_WEEK)
#define STANDARD_WORK_HOURS_PER_YEAR (12 * STANDARD_WORK_HOURS_PER_MONTH)

#define STANDARD_WORK_PER_DAY 24
#define STANDARD_WORK_PER_WEEK (7 * STANDARD_WORK_PER_DAY)
#define STANDARD_WORK_PER_MONTH (30 * STANDARD_WORK_PER_DAY)
#define STANDARD_WORK_PER_YEAR (365 * STANDARD_WORK_PER_DAY)

@interface OFTimeSpanFormatter : NSFormatter
{
    BOOL shouldUseVerboseFormat;
    unsigned int hoursPerDay, hoursPerWeek, hoursPerMonth, hoursPerYear;
    float roundingInterval;
    
    struct {
	unsigned int returnNumber : 1;
	unsigned int displayUnits : 7;
    } _flags;
}

- (void)setUseVerboseFormat:(BOOL)shouldUseVerbose;
- (BOOL)shouldUseVerboseFormat;

- (void)setShouldReturnNumber:(BOOL)shouldReturnNumber;
- (BOOL)shouldReturnNumber;

- (void)setRoundingInterval:(float)interval;
- (float)roundingInterval;

- (unsigned int)hoursPerDay;
- (unsigned int)hoursPerWeek;
- (unsigned int)hoursPerMonth;
- (unsigned int)hoursPerYear;

- (void)setHoursPerDay:(unsigned int)hours;
- (void)setHoursPerWeek:(unsigned int)hours;
- (void)setHoursPerMonth:(unsigned int)hours;
- (void)setHoursPerYear:(unsigned int)hours;

- (BOOL)isStandardWorkTime;
- (BOOL)isStandardCalendarTime;

- (BOOL)displaySeconds;
- (BOOL)displayMinutes;
- (BOOL)displayHours;
- (BOOL)displayDays;
- (BOOL)displayWeeks;
- (BOOL)displayMonths;
- (BOOL)displayYears;

- (void)setDisplaySeconds:(BOOL)aBool;
- (void)setDisplayMinutes:(BOOL)aBool;
- (void)setDisplayHours:(BOOL)aBool;
- (void)setDisplayDays:(BOOL)aBool;
- (void)setDisplayWeeks:(BOOL)aBool;
- (void)setDisplayMonths:(BOOL)aBool;
- (void)setDisplayYears:(BOOL)aBool;

- (void)setStandardWorkTime; // 8h = 1d, 40h = 1w, 160h = 1m, 1920h = 1y (12m = 1y)
- (void)setStandardCalendarTime; // 24h = 1d, 168h = 1w, 720h = 1m (30d = 1m), 8760h = 1y (365d = 1y)

@end
