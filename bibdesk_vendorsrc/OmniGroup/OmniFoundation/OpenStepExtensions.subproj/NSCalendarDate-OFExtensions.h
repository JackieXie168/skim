// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSCalendarDate-OFExtensions.h,v 1.17 2004/02/10 04:07:45 kc Exp $

#import <Foundation/NSCalendarDate.h>

@interface NSCalendarDate (OFExtensions)

+ (NSCalendarDate *)unixReferenceDate;
- (void)setToUnixDateFormat;
- initWithTime_t:(int)time;

- (NSCalendarDate *)safeReferenceDate;
- (NSCalendarDate *)firstDayOfMonth;
- (NSCalendarDate *)lastDayOfMonth;
- (int)numberOfDaysInMonth;
- (int)weekOfMonth;
    // Returns 1 through 6. Weeks are Sunday-Saturday.
- (BOOL)isInSameWeekAsDate:(NSCalendarDate *)otherDate;

- (NSCalendarDate *)dateByRoundingToDayOfWeek:(int)desiredDayOfWeek;
- (NSCalendarDate *)dateByRoundingToHourOfDay:(int)desiredHour minute:(int)desiredMinute;
@end
