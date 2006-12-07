// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFTimeSpanFormatter.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSFormatter.h>

#define STANDARD_WORK_HOURS_PER_DAY 8
#define STANDARD_WORK_HOURS_PER_WEEK (5 * STANDARD_WORK_HOURS_PER_DAY)
#define STANDARD_WORK_HOURS_PER_MONTH (4 * STANDARD_WORK_HOURS_PER_WEEK)
#define STANDARD_WORK_HOURS_PER_YEAR (12 * STANDARD_WORK_HOURS_PER_MONTH)

#define STANDARD_WORK_PER_DAY 24
#define STANDARD_WORK_PER_WEEK (7 * STANDARD_WORK_HOURS_PER_DAY)
#define STANDARD_WORK_PER_MONTH (30 * STANDARD_WORK_HOURS_PER_DAY)
#define STANDARD_WORK_PER_YEAR (365 * STANDARD_WORK_HOURS_PER_DAY)

@interface OFTimeSpanFormatter : NSFormatter
{
    BOOL shouldUseVerboseFormat;
    unsigned int hoursPerDay, hoursPerWeek, hoursPerMonth, hoursPerYear;
    
    struct {
	unsigned int displayHours : 1;
	unsigned int displayDays : 1;
	unsigned int displayWeeks : 1;
	unsigned int displayMonths : 1;
	unsigned int displayYears : 1;
    } _flags;
}

- (void)setUseVerboseFormat:(BOOL)shouldUseVerbose;
- (BOOL)shouldUseVerboseFormat;

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

- (BOOL)displayHours;
- (BOOL)displayDays;
- (BOOL)displayWeeks;
- (BOOL)displayMonths;
- (BOOL)displayYears;

- (void)setDisplayHours:(BOOL)aBool;
- (void)setDisplayDays:(BOOL)aBool;
- (void)setDisplayWeeks:(BOOL)aBool;
- (void)setDisplayMonths:(BOOL)aBool;
- (void)setDisplayYears:(BOOL)aBool;

- (void)setStandardWorkTime; // 8h = 1d, 40h = 1w, 160h = 1m, 1920h = 1y (12m = 1y)
- (void)setStandardCalendarTime; // 24h = 1d, 168h = 1w, 720h = 1m (30d = 1m), 8760h = 1y (365d = 1y)

@end
