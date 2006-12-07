// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSCalendarDate-OFExtensions.h,v 1.14 2003/01/15 22:51:59 kc Exp $

#import <OmniBase/SystemType.h> // For YELLOW_BOX

#ifdef YELLOW_BOX
#import <Foundation/NSCalendarDate.h>
#else
#import <Foundation/NSDate.h>
#endif

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
