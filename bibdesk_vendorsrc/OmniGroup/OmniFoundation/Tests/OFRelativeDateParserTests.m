// Copyright 2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <SenTestingKit/SenTestingKit.h>
#import <OmniFoundation/OFRelativeDateParser.h>
#import "OmniFoundationTestUtils.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/trunk/OmniGroup/Frameworks/OmniFoundation/Tests/OFSetTests.m 76239 2006-06-07 01:12:12Z wiml $");

static NSCalendar *calendar;
@interface OFRelativeDateParserTests : SenTestCase
{
    //NSDate *baseDate;
   // NSDate *expectedDate;
   
}
//+ (NSDate *)_dateFromYear:(int)year month:(int)month day:(int)day hour:(int)hour minute:(int)minute second:(int)second;
@end



static NSDate *_dateFromYear(int year, int month, int day, int hour, int minute, int second, NSCalendar *cal)
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:day];
    [components setHour:hour];
    [components setMinute:minute];
    [components setSecond:second];
    return [cal dateFromComponents:components];
}


@implementation OFRelativeDateParserTests

- (void)setup;
{
}

- (void)teardown;
{
    [calendar release];
}

#define parseDate(string, expectedDate, baseDate) \
do { \
    NSDate *result = [OFRelativeDateParser dateForString:string fromDate:baseDate withTimeZone:[NSTimeZone localTimeZone] withCalendarIdentifier:NSGregorianCalendar error:nil]; \
	NSLog( @"result: %@", result);\
	    NSLog( @"expected: %@", expectedDate);\
		shouldBeEqual(result, expectedDate);  \
} while(0)
- (void)donttestLocaleWeekdays;
{
    NSString *locale = @"en_US";
    
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    
    //NSLocale *loc = (NSLocale *)CFLocaleCreate(kCFAllocatorDefault, (CFStringRef)locale);
    NSLocale *loc = [NSLocale currentLocale];
    [formatter setLocale:loc];
    NSArray *weekdays = [formatter weekdaySymbols];
    NSDate *baseDate = _dateFromYear(2001, 1, 10, 1, 1, 1, calendar);
    unsigned int dayIndex = [weekdays count];
    NSLog( @"locale %@, weekdays: %@", [loc localeIdentifier], weekdays );
    NSDateComponents *components = [calendar components:NSWeekdayCalendarUnit fromDate:baseDate];
    unsigned int weekday = [components weekday];
    while (dayIndex--) {
	NSLog( @"test index: %d", dayIndex );
	parseDate( [weekdays objectAtIndex:dayIndex], 
		   _dateFromYear(2001, 1, 10-(weekday-dayIndex), 1, 1, 1, calendar),
		   _dateFromYear(2001, 1, 10, 1, 1, 1, calendar) );
    }
    
}

- (void)testTimes;
{
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    parseDate( @"1d@5:45:1", 
	       _dateFromYear(2001, 1, 2, 17, 45, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"@17:45", 
	       _dateFromYear(2001, 1, 1, 17, 45, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"@5:45 pm", 
	       _dateFromYear(2001, 1, 1, 17, 45, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"@5:45 am", 
	       _dateFromYear(2001, 1, 1, 5, 45, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    
}

- (void)donttestCodes;
{
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    parseDate( @"0h", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"1h", 
	       _dateFromYear(2001, 1, 1, 2, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+1h1h", 
	       _dateFromYear(2001, 1, 1, 3, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-1h", 
	       _dateFromYear(2001, 1, 1, 0, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
   
    parseDate( @"0d", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"1d", 
	       _dateFromYear(2001, 1, 2, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+1d", 
	       _dateFromYear(2001, 1, 2, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-1d", 
	       _dateFromYear(2000, 12, 31, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );

    parseDate( @"0w", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"1w", 
	       _dateFromYear(2001, 1, 8, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+1w", 
	       _dateFromYear(2001, 1, 8, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-1w", 
	       _dateFromYear(2000, 12, 25, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );

    parseDate( @"0m", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"1m", 
	       _dateFromYear(2001, 2, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+1m", 
	       _dateFromYear(2001, 2, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-1m", 
	       _dateFromYear(2000, 12, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    
    parseDate( @"0y", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"1y", 
	       _dateFromYear(2002, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+1y", 
	       _dateFromYear(2002, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-1y", 
	       _dateFromYear(2000, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    
    
}

- (void)donttestWeekdays;
{
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    parseDate( @"sunday", 
	       _dateFromYear(2001, 1, 7, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+Sunday", 
	       _dateFromYear(2001, 1, 7, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-Sunday", 
	       _dateFromYear(2000, 12, 31, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    
    parseDate( @"Monnday", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+monday", 
	       _dateFromYear(2001, 1, 8, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-Mon", 
	       _dateFromYear(2000, 12, 25, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"mon", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );

    parseDate( @"Tuesday", 
	       _dateFromYear(2001, 1, 2, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+tuesday", 
	       _dateFromYear(2001, 1, 2, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-Tue", 
	       _dateFromYear(2000, 12, 26, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"tue", 
	       _dateFromYear(2001, 1, 2, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );

    parseDate( @"Wednesday", 
	       _dateFromYear(2001, 1, 3, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+wednesday", 
	       _dateFromYear(2001, 1, 3, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-Wed", 
	       _dateFromYear(2000, 12, 27, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"wed", 
	       _dateFromYear(2001, 1, 3, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) ); 

    
    parseDate( @"Thursday", 
	       _dateFromYear(2001, 1, 4, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+thursday", 
	       _dateFromYear(2001, 1, 4, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-Thu", 
	       _dateFromYear(2000, 12, 28, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"thu", 
	       _dateFromYear(2001, 1, 4, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );

    parseDate( @"Friday", 
	       _dateFromYear(2001, 1, 5, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+friday", 
	       _dateFromYear(2001, 1, 5, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-Fri", 
	       _dateFromYear(2000, 12, 29, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"fri", 
	       _dateFromYear(2001, 1, 5, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );

    parseDate( @"Saturday", 
	       _dateFromYear(2001, 1, 6, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+saturday", 
	       _dateFromYear(2001, 1, 6, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-Sat", 
	       _dateFromYear(2000, 12, 30, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"sat", 
	       _dateFromYear(2001, 1, 6, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
}
- (void)donttestMonthRelativety;
{
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    parseDate( @"+january", 
	       _dateFromYear(2002, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-jan", 
	       _dateFromYear(2000, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+februaruy", 
	       _dateFromYear(2001, 2, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-feb", 
	       _dateFromYear(2000, 2, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+march", 
	       _dateFromYear(2001, 3, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-mar", 
	       _dateFromYear(2000, 3, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+april", 
	       _dateFromYear(2001, 4, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-apr", 
	       _dateFromYear(2000, 4, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+may", 
	       _dateFromYear(2001, 5, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-may", 
	       _dateFromYear(2000, 5, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+june", 
	       _dateFromYear(2001, 6, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-jun", 
	       _dateFromYear(2000, 6, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+july", 
	       _dateFromYear(2001, 7, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-jul", 
	       _dateFromYear(2000, 7, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+august", 
	       _dateFromYear(2001, 8, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-aug", 
	       _dateFromYear(2000, 8, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+september", 
	       _dateFromYear(2001, 9, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-sept", 
	       _dateFromYear(2000, 9, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-october", 
	       _dateFromYear(2000, 10, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+oct", 
	       _dateFromYear(2001, 10, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-november", 
	       _dateFromYear(2000, 11, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+nov", 
	       _dateFromYear(2001, 11, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"-december", 
	       _dateFromYear(2000, 12, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"+dec", 
	       _dateFromYear(2001, 12, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
}

- (void)donttestMonth;
{
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    // lc months
    parseDate( @"january", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"jan", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"februaruy", 
	       _dateFromYear(2001, 2, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"feb", 
	       _dateFromYear(2001, 2, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"march", 
	       _dateFromYear(2001, 3, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"mar", 
	       _dateFromYear(2001, 3, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"april", 
	       _dateFromYear(2001, 4, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"apr", 
	       _dateFromYear(2001, 4, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"may", 
	       _dateFromYear(2001, 5, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"may", 
	       _dateFromYear(2001, 5, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"june", 
	       _dateFromYear(2001, 6, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"jun", 
	       _dateFromYear(2001, 6, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"july", 
	       _dateFromYear(2001, 7, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"jul", 
	       _dateFromYear(2001, 7, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"august", 
	       _dateFromYear(2001, 8, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"aug", 
	       _dateFromYear(2001, 8, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"september", 
	       _dateFromYear(2001, 9, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"sept", 
	       _dateFromYear(2001, 9, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"october", 
	       _dateFromYear(2001, 10, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"oct", 
	       _dateFromYear(2001, 10, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"november", 
	       _dateFromYear(2001, 11, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"nov", 
	       _dateFromYear(2001, 11, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"december", 
	       _dateFromYear(2001, 12, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"dec", 
	       _dateFromYear(2001, 12, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    
    // uc months
    parseDate( @"January", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Jan", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Februaruy", 
	       _dateFromYear(2001, 2, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Feb", 
	       _dateFromYear(2001, 2, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"March", 
	       _dateFromYear(2001, 3, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Mar", 
	       _dateFromYear(2001, 3, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"April", 
	       _dateFromYear(2001, 4, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Apr", 
	       _dateFromYear(2001, 4, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"May", 
	       _dateFromYear(2001, 5, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"May", 
	       _dateFromYear(2001, 5, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"June", 
	       _dateFromYear(2001, 6, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Jun", 
	       _dateFromYear(2001, 6, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"July", 
	       _dateFromYear(2001, 7, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Jul", 
	       _dateFromYear(2001, 7, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"August", 
	       _dateFromYear(2001, 8, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Aug", 
	       _dateFromYear(2001, 8, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"September", 
	       _dateFromYear(2001, 9, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Sept", 
	       _dateFromYear(2001, 9, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"October", 
	       _dateFromYear(2001, 10, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Oct", 
	       _dateFromYear(2001, 10, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"November", 
	       _dateFromYear(2001, 11, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Nov", 
	       _dateFromYear(2001, 11, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"December", 
	       _dateFromYear(2001, 12, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"Dec", 
	       _dateFromYear(2001, 12, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    
    // mixed-case months
    parseDate( @"jaNuaRy", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"jAn", 
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"feBruaruy", 
	       _dateFromYear(2001, 2, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"feB", 
	       _dateFromYear(2001, 2, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"MARCH", 
	       _dateFromYear(2001, 3, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"mar", 
	       _dateFromYear(2001, 3, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"apRil", 
	       _dateFromYear(2001, 4, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"aPR", 
	       _dateFromYear(2001, 4, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"mAY", 
	       _dateFromYear(2001, 5, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"May", 
	       _dateFromYear(2001, 5, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"juNe", 
	       _dateFromYear(2001, 6, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"juN", 
	       _dateFromYear(2001, 6, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"juLy", 
	       _dateFromYear(2001, 7, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"juL", 
	       _dateFromYear(2001, 7, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"auGust", 
	       _dateFromYear(2001, 8, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"auG", 
	       _dateFromYear(2001, 8, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"sePTember", 
	       _dateFromYear(2001, 9, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"sEPT", 
	       _dateFromYear(2001, 9, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"ocToBer", 
	       _dateFromYear(2001, 10, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"oCt", 
	       _dateFromYear(2001, 10, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"noVEmber", 
	       _dateFromYear(2001, 11, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"noV", 
	       _dateFromYear(2001, 11, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"decEMber", 
	       _dateFromYear(2001, 12, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    parseDate( @"deC", 
	       _dateFromYear(2001, 12, 1, 1, 1, 1, calendar),
	       _dateFromYear(2001, 1, 1, 1, 1, 1, calendar) );
    
    // TODO: Are there locales where the modifier would come after the base bit?
    // YES: "next july" == "juillet prochain" in fr
}


@end

