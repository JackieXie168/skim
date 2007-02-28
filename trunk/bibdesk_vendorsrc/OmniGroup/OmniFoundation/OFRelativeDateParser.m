// Copyright 2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFRelativeDateParser.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/trunk/OmniGroup/Templates/Developer%20Tools/File%20Templates/%20Omni/OmniFoundation%20public%20class.pbfiletemplate/class.m 70671 2005-11-22 01:01:39Z kc $");

static NSDictionary *relativeDateNames;
static NSArray *weekdays;
static NSArray *shortdays;
static NSArray *months;
static NSArray *shortmonths;
static NSDictionary *codes;
static NSDictionary *modifiers;

static NSCalendar *currentCalendar;   

static const unsigned unitFlags = NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSEraCalendarUnit;
typedef enum {
    DPHour = 0,
    DPDay = 1,
    DPWeek = 2,
    DPMonth = 3,
    DPYear = 4,
} DPCode;

typedef enum {
    OFRelativeDateParserCurrentRelativity = 0,
    OFRelativeDateParserFutureRelativity = -1,
    OFRelativeDateParserPastRelativity = 1,
} OFRelativeDateParserRelativity;

@interface OFRelativeDateParser (Private)
+(int)_multiplierForModifer:(int)modifier;
+ (unsigned int)_monthIndexForString:(NSString *)token;
+ (unsigned int)_weekdayIndexForString:(NSString *)token;
+ (NSDate *)_modifyDate:(NSDate *)date withWeekday:(unsigned int)weekday withModifier:(OFRelativeDateParserRelativity)modifier;
+ (NSDateComponents *)_addToComponents:(NSDateComponents *)components codeString:(DPCode)dpCode codeInt:(int)codeInt withMultiplier:(int)multiplier;
+ (int)_determineYearForMonth:(unsigned int)month withModifier:(OFRelativeDateParserRelativity)modifier fromComponents:(NSDateComponents *)components;
@end

@implementation OFRelativeDateParser

+ (void)initialize;
{
    OBINITIALIZE;
      
    // TODO: Can't do seconds offsets for day math due to daylight savings
    // TODO: Make this a localized .plist where it looks something like:
    /*
     "demain" = {day:1}
     "avant-hier" = {day:-2}
     */
    // set times
    relativeDateNames = [[NSDictionary alloc] initWithObjectsAndKeys:
	[NSArray arrayWithObjects:[NSNumber numberWithInt:DPDay], [NSNumber numberWithInt:0], [NSNumber numberWithInt:OFRelativeDateParserCurrentRelativity], nil], NSLocalizedStringFromTableInBundle(@"today", @"DateProcessing", OMNI_BUNDLE, @"today"), 
	[NSArray arrayWithObjects:[NSNumber numberWithInt:DPDay], [NSNumber numberWithInt:0], [NSNumber numberWithInt:OFRelativeDateParserCurrentRelativity], nil], NSLocalizedStringFromTableInBundle(@"today", @"DateProcessing", OMNI_BUNDLE, @"now"), 
	[NSArray arrayWithObjects:[NSNumber numberWithInt:DPDay], [NSNumber numberWithInt:1], [NSNumber numberWithInt:OFRelativeDateParserFutureRelativity], nil], NSLocalizedStringFromTableInBundle(@"tomorrow", @"DateProcessing", OMNI_BUNDLE, @"tomorrow"), 
	[NSArray arrayWithObjects:[NSNumber numberWithInt:DPDay], [NSNumber numberWithInt:1], [NSNumber numberWithInt:OFRelativeDateParserPastRelativity], nil], NSLocalizedStringFromTableInBundle(@"yesterday", @"DateProcessing", OMNI_BUNDLE, @"yesterday"), 
	[NSArray arrayWithObjects:[NSNumber numberWithInt:DPWeek], [NSNumber numberWithInt:1], [NSNumber numberWithInt:OFRelativeDateParserFutureRelativity], nil], NSLocalizedStringFromTableInBundle(@"today", @"DateProcessing", OMNI_BUNDLE, @"next week"), 
	[NSArray arrayWithObjects:[NSNumber numberWithInt:DPWeek], [NSNumber numberWithInt:1], [NSNumber numberWithInt:OFRelativeDateParserPastRelativity], nil], NSLocalizedStringFromTableInBundle(@"today", @"DateProcessing", OMNI_BUNDLE, @"last week"),
	[NSArray arrayWithObjects:[NSNumber numberWithInt:DPMonth], [NSNumber numberWithInt:1], [NSNumber numberWithInt:OFRelativeDateParserFutureRelativity], nil], NSLocalizedStringFromTableInBundle(@"today", @"DateProcessing", OMNI_BUNDLE, @"next month"), 
	[NSArray arrayWithObjects:[NSNumber numberWithInt:DPMonth], [NSNumber numberWithInt:1], [NSNumber numberWithInt:OFRelativeDateParserPastRelativity], nil], NSLocalizedStringFromTableInBundle(@"today", @"DateProcessing", OMNI_BUNDLE, @"last month"),
	[NSArray arrayWithObjects:[NSNumber numberWithInt:DPYear], [NSNumber numberWithInt:1], [NSNumber numberWithInt:OFRelativeDateParserFutureRelativity], nil], NSLocalizedStringFromTableInBundle(@"today", @"DateProcessing", OMNI_BUNDLE, @"next year"), 
	[NSArray arrayWithObjects:[NSNumber numberWithInt:DPYear], [NSNumber numberWithInt:1], [NSNumber numberWithInt:OFRelativeDateParserPastRelativity], nil], NSLocalizedStringFromTableInBundle(@"today", @"DateProcessing", OMNI_BUNDLE, @"last year"),
	nil];
    
    // weekdays, and abbreviations
    // TODO: Move this state into ivars and add -initWithLocale:
    // TODO: Use NSLocale instead and allow it to be passed into the parser
    weekdays = [[[NSUserDefaults standardUserDefaults] objectForKey:NSWeekDayNameArray] copy];
    shortdays = [[[NSUserDefaults standardUserDefaults] objectForKey:NSShortWeekDayNameArray] copy]; 
    
    // months, and abbreviations
    // TODO: Use NSLocale instead and allow it to be passed into the parser
    months = [[[NSUserDefaults standardUserDefaults] objectForKey:NSMonthNameArray] copy];
    shortmonths = [[[NSUserDefaults standardUserDefaults] objectForKey:NSShortMonthNameArray] copy];
    
    // short hand codes
    codes = [[NSDictionary alloc] initWithObjectsAndKeys:
	[NSNumber numberWithInt:DPHour], NSLocalizedStringFromTableInBundle(@"h", @"DateProcessing", OMNI_BUNDLE, @"hours"), 
	[NSNumber numberWithInt:DPHour], NSLocalizedStringFromTableInBundle(@"hour", @"DateProcessing", OMNI_BUNDLE, @"hours"), 
	[NSNumber numberWithInt:DPHour], NSLocalizedStringFromTableInBundle(@"hours", @"DateProcessing", OMNI_BUNDLE, @"hours"), 
	[NSNumber numberWithInt:DPDay], NSLocalizedStringFromTableInBundle(@"d", @"DateProcessing", OMNI_BUNDLE, @"days"), 
	[NSNumber numberWithInt:DPDay], NSLocalizedStringFromTableInBundle(@"day", @"DateProcessing", OMNI_BUNDLE, @"days"), 
	[NSNumber numberWithInt:DPDay], NSLocalizedStringFromTableInBundle(@"days", @"DateProcessing", OMNI_BUNDLE, @"days"), 
	[NSNumber numberWithInt:DPWeek], NSLocalizedStringFromTableInBundle(@"w", @"DateProcessing", OMNI_BUNDLE, @"weeks"), 
	[NSNumber numberWithInt:DPWeek], NSLocalizedStringFromTableInBundle(@"week", @"DateProcessing", OMNI_BUNDLE, @"weeks"), 
	[NSNumber numberWithInt:DPWeek], NSLocalizedStringFromTableInBundle(@"weeks", @"DateProcessing", OMNI_BUNDLE, @"weeks"), 
	[NSNumber numberWithInt:DPMonth],NSLocalizedStringFromTableInBundle(@"m", @"DateProcessing", OMNI_BUNDLE, @"weeks"), 
	[NSNumber numberWithInt:DPMonth], NSLocalizedStringFromTableInBundle(@"month", @"DateProcessing", OMNI_BUNDLE, @"weeks"), 
	[NSNumber numberWithInt:DPMonth], NSLocalizedStringFromTableInBundle(@"months", @"DateProcessing", OMNI_BUNDLE, @"weeks"), 
	[NSNumber numberWithInt:DPYear], NSLocalizedStringFromTableInBundle(@"y", @"DateProcessing", OMNI_BUNDLE, @"365 day periods"), 
	[NSNumber numberWithInt:DPYear], NSLocalizedStringFromTableInBundle(@"year", @"DateProcessing", OMNI_BUNDLE, @"365 day periods"), 
	[NSNumber numberWithInt:DPYear], NSLocalizedStringFromTableInBundle(@"years", @"DateProcessing", OMNI_BUNDLE, @"365 day periods"),  
	nil];
    
    // time modifiers
    modifiers = [[NSDictionary alloc] initWithObjectsAndKeys:
	[NSNumber numberWithInt:OFRelativeDateParserFutureRelativity], NSLocalizedStringFromTableInBundle(@"+", @"DateProcessing", OMNI_BUNDLE, @"future"), 
	[NSNumber numberWithInt:OFRelativeDateParserFutureRelativity], NSLocalizedStringFromTableInBundle(@"next", @"DateProcessing", OMNI_BUNDLE, @"future"),  
	[NSNumber numberWithInt:OFRelativeDateParserPastRelativity], NSLocalizedStringFromTableInBundle(@"-", @"DateProcessing", OMNI_BUNDLE, @"past"), 
	[NSNumber numberWithInt:OFRelativeDateParserPastRelativity], NSLocalizedStringFromTableInBundle(@"last", @"DateProcessing", OMNI_BUNDLE, @"past"), 
	nil];
}

+ (NSDate *)dateForString:(NSString *)string withFormatter:(NSDateFormatter *)formatter error:(NSError **)error;
{
    // TODO: Parsing of dates in an order that is based on the current format
    //  NSString *dateFormat = [formatter dateFormat];
    // int yearOrder = 0;
    // int monthOrder = 1;
    // int dayOrder = 2;
    
    return [[NSDate alloc] init];
}


+ (NSDate *)dateForString:(NSString *)string error:(NSError **)error;
{
    return [self dateForString:string fromDate:[NSDate date] withTimeZone:[NSTimeZone localTimeZone] withCalendarIdentifier:NSGregorianCalendar error:error];
}

+ (NSDate *)dateForString:(NSString *)string fromDate:(NSDate *)date withTimeZone:(NSTimeZone *)timeZone withCalendarIdentifier:(NSString *)nsLocaleCalendarKey error:(NSError **)error;
{
   
    // set the calendar according to the requested calendar and time zone
    currentCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:nsLocaleCalendarKey];
    if ( timeZone != nil )
	[currentCalendar setTimeZone:timeZone];
    
    // seperate the string into the date and time components, and collapse whitespace and make lowercase
    NSArray *dateAndTime = [[[string lowercaseString] stringByCollapsingWhitespaceAndRemovingSurroundingWhitespace] componentsSeparatedByString:@"@"];
    
    // accepted strings are of the form "DATE @ TIME"
    if ([dateAndTime count] > 2) {
	OBRejectInvalidCall(self, _cmd, @"TODO: Build an error and return nil");
	return nil;
    }

    NSString *dateString = nil;
    NSString *timeString = nil;

    // allow for the string to start with the time, and have no time, an "@" must always precede the time
    if ([string hasPrefix:@"@"]) {
	NSLog( @"starts w/ an @ :: %@", [dateAndTime description] );
	timeString = [dateAndTime objectAtIndex:1];
    } else {
	dateString = [dateAndTime objectAtIndex:0];
	if ([dateAndTime count] == 2) 
	    timeString = [dateAndTime objectAtIndex:1];
    }
    
    NSLog( @"1. Date String: %@; Time String: %@", dateString, timeString );
    
    // parse the date if there is a date component
    if (dateString != nil) {
	BOOL foundRelateiveDateName = NO;
	unsigned unitFlags = NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit |NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSEraCalendarUnit;
	
	// look for a modifier as the first part of the string
	OFRelativeDateParserRelativity modifier = 0;
			
	// test for the common words
	NSArray *dateOffset;
	if ((dateOffset = [relativeDateNames objectForKey:dateString])) {

	    NSDateComponents *currentComponents = [currentCalendar components:unitFlags fromDate:date];
	    currentComponents = [self _addToComponents:currentComponents codeString:[[dateOffset objectAtIndex:0] intValue] codeInt:[[dateOffset objectAtIndex:1] intValue] withMultiplier:[self _multiplierForModifer:[[dateOffset objectAtIndex:2] intValue]]];
	    return [currentCalendar dateFromComponents:currentComponents];
	}
		
	// check for any modifier at the front of the string and trim it
	NSEnumerator *patternEnum = [modifiers keyEnumerator];
	NSString *pattern;
	while ((pattern = [patternEnum nextObject])) {
	    if ( [dateString hasPrefix:pattern] ) {
		modifier = [[modifiers objectForKey:pattern] intValue];
		dateString = [dateString substringFromIndex:[pattern length]]; // strip modifier
		break;
	    }
	} 
	int multiplier = [self _multiplierForModifer:modifier];
	
	// if no common word was found, then interpret the date
	if (!foundRelateiveDateName) {
	
	    int month = -1;
	    int weekday = -1;
	    int day = -1;
	    int year = -1;
	    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
	    
	    // get the array of all the whitespace delimited tokens
	    NSArray *dateTokens = [dateString componentsSeparatedByCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]];
    	    unsigned int dateTokenIndex, dateTokenCount = [dateTokens count];
	    for (dateTokenIndex = 0; dateTokenIndex < dateTokenCount; ++dateTokenIndex) {
		NSString *currentToken = [dateTokens objectAtIndex:dateTokenIndex];
		
		// test for month and weekday names
		if (month == -1)
		    month = [self _monthIndexForString:currentToken];
		if (weekday == -1)
		    weekday = [self _weekdayIndexForString:currentToken];
		
		int number = -1;
		DPCode dpCode = -1;
		NSScanner *scanner = [NSScanner localizedScannerWithString:currentToken]; 
		[scanner setCaseSensitive:NO];
		while (![scanner isAtEnd]) {

		    BOOL isYear = NO;
		    //look for a year '
		    if ([scanner scanString:@"'" intoString:NULL])
			isYear = YES;
		
		    // look for a float
		    if ([scanner scanInt:&number]) {
		       
			// if a float was found, look for the code to go with it.
			BOOL foundCode = NO;
			NSString *codeString;
			NSEnumerator *codeEnum = [codes keyEnumerator];
			while ((codeString = [codeEnum nextObject]) && !foundCode) {
			    if ([scanner scanString:codeString intoString:NULL]) {
				dpCode = [[codes objectForKey:codeString] intValue];
				
				//found a float and a code, add to the components
				componentsToAdd = [self _addToComponents:componentsToAdd codeString:dpCode codeInt:number withMultiplier:multiplier];
				isYear = NO; // '97d gets you 97 days
				foundCode= YES;
			    }
			} // look for code
			
			if (isYear)
			    year = number;
			
			if (!foundCode) {
			    if (number > 31 )
				year = number;
			    else
				day = number;
			}
		    } // found float 
		} // scanner
	    } // parse date tokens

	    NSDateComponents *currentComponents = [currentCalendar components:unitFlags fromDate:date];
	    	    
	    NSLog( @"year: %d, month: %d, day: %d, weekday: %d", year, month, day, weekday );
	    NSLog( @"Code Components--- year: %d, month: %d, day: %d, hour: %d", [componentsToAdd year], [componentsToAdd month], [componentsToAdd day], [componentsToAdd day], [componentsToAdd hour] );
	    NSLog( @"Date before modification: %@", date);
	    
	    // TODO: default year?
	    if (year != -1) 
		[currentComponents setYear:year];
	    	    
	    // TODO: default month?
	    if (month != -1) {
		month+=1;
		[currentComponents setYear:[self _determineYearForMonth:month withModifier:modifier fromComponents:currentComponents]];
		[currentComponents setMonth:month];
	    }
		
	    // TODO: default day?
	    if (day != -1)
		[currentComponents setDay:day];
	    
	    date = [currentCalendar dateFromComponents:currentComponents];
	  
	    NSLog( @"date before weekdays: %@", date) ;

	    // find the next weekday that fits
	    if (weekday != -1) {
		weekday +=1;
		date = [self _modifyDate:date withWeekday:weekday withModifier:modifier];
	    }
	    
	    NSLog( @"date after weekdays: %@", date) ;
	    
	    // add the components to the date from the codes
	    date = [currentCalendar dateByAddingComponents:componentsToAdd toDate:date options:0];
	    
	} // parse date string (not relative date)
    } // parse date

    if (timeString != nil) {

	NSScanner *timeScanner = [NSScanner localizedScannerWithString:timeString];
	// Eat whitespace
        [timeScanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
	NSString *timeToken = nil;
	NSString *meridianToken = nil;
	[timeScanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&timeToken];
	if ( timeToken == nil ) {
	    [timeScanner scanUpToCharactersFromSet:[NSCharacterSet illegalCharacterSet] intoString:&timeToken];
	}else 
	    [timeScanner scanUpToCharactersFromSet:[NSCharacterSet illegalCharacterSet] intoString:&meridianToken];
	
	NSLog( @"timeToken is: %@, meridian token is: %@", timeToken, meridianToken );
	
	NSArray *timeComponents = [timeToken componentsSeparatedByString:@":"];
	
	int hours = -1;
	int minutes = 0;
	int seconds = 0;
	unsigned int timeMarker;
	for (timeMarker = 0; timeMarker < [timeComponents count]; ++timeMarker) {
	    switch (timeMarker) {
		case 0:
		    hours = [[timeComponents objectAtIndex:timeMarker] intValue];
		    break;
		case 1:
		    minutes = [[timeComponents objectAtIndex:timeMarker] intValue];
		    break;
		case 2:
		    seconds = [[timeComponents objectAtIndex:timeMarker] intValue];
		    break;
	    }
	}
	
	NSLog( @"hours: %d, minutes: %d, seconds: %d", hours, minutes, seconds );
	
	NSDateComponents *components = [currentCalendar components:unitFlags fromDate:date];
	if (seconds != -1)
	    [components setSecond:seconds];
	
	if (minutes != -1)
	    [components setMinute:minutes];
	
	if (hours != -1) {
	    BOOL isPM = NO; // TODO: Make a default.
			    //parse meridian first if we have one
	    if (meridianToken != nil) {
		if ( [meridianToken isEqualToString:@"pm"] || [meridianToken isEqualToString:@"PM"] ) {
		    isPM = YES;
		} else { 
		    isPM = NO;
		}
	    } else {
		if ( hours < 7 )
		    isPM = YES; // default to afternoon of a working day
	    }
		
	    if ( isPM ) {
		hours+=12;
		NSLog( @"isPM is true, adding 12 to the hours");
	    }
	    [components setHour:hours];
	}
	date = [currentCalendar dateFromComponents:components];
	
    } // parse time
    
    NSLog( @"returning date: %@", date);
    
    return date;
}

@end

@implementation OFRelativeDateParser (Private)

+(int)_multiplierForModifer:(int)modifier;
{
    if (modifier == OFRelativeDateParserPastRelativity)
	    return -1;
    return 1;
}

+ (unsigned int)_monthIndexForString:(NSString *)token;
{
    // return the the value of the month according to its position on the array, or -1 if nothing matches.
    unsigned int monthIndex = [months count];
    while (monthIndex--) {
	if ([token isEqualToString:[[shortmonths objectAtIndex:monthIndex] lowercaseString]] || [token isEqualToString:[[months objectAtIndex:monthIndex] lowercaseString]]) {
	    return monthIndex;
	}
    }
    return -1;
}

+ (unsigned int)_weekdayIndexForString:(NSString *)token;
{
    // return the the value of the weekday according to its position on the array, or -1 if nothing matches.
    unsigned int dayIndex = [weekdays count];
    while (dayIndex--) {
	if ([token isEqualToString:[[shortdays objectAtIndex:dayIndex] lowercaseString]] || [token isEqualToString:[[weekdays objectAtIndex:dayIndex] lowercaseString]])
	    return dayIndex;
    }
    return -1;
}

+ (int)_determineYearForMonth:(unsigned int)month withModifier:(OFRelativeDateParserRelativity)modifier fromComponents:(NSDateComponents *)components;
{
    // find the proper year given the month.
    int monthComponent = [components month];
    int year = [components year];
    
    // current month equals the requested month
    if (monthComponent == (int)month) {
	switch (modifier) {
	    case OFRelativeDateParserFutureRelativity:
		return (year+1);
	    case OFRelativeDateParserPastRelativity:
		return (year-1);
	    default:
		return year;
	} 
    } else if (monthComponent > (int)month) {
	// current month is greater than the requested month
	if ( modifier != OFRelativeDateParserPastRelativity )
		return (year +1);
    } else {
	// current month is less than the requested month
	if (modifier == OFRelativeDateParserPastRelativity)
		return (year-1);
    }
    return year;
}

+ (NSDate *)_modifyDate:(NSDate *)date withWeekday:(unsigned int)weekday withModifier:(OFRelativeDateParserRelativity)modifier;
{

    NSDateComponents *weekdayComp = [currentCalendar components:NSWeekdayCalendarUnit fromDate:date];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    int weekdayComponent = [weekdayComp weekday];
  
    NSLog( @"the weekday component is: %d, and the given weekday is: %d", weekdayComponent, weekday );
    
    // the current day is the same as the given day
    if (weekdayComponent == (int)weekday) {
	switch (modifier) {
	    case OFRelativeDateParserCurrentRelativity:
		NSLog( @"no mod, current day");
		return date;
	    case OFRelativeDateParserFutureRelativity:
		NSLog( @"add a week");
		[components setDay:7];
		break;
	    case OFRelativeDateParserPastRelativity:
		NSLog( @"lose a week");
		[components setDay:-7];
		break;
	}
    }
    
    // the current day is greater than the requested day
    else if (weekdayComponent > (int)weekday) {
	switch (modifier) {
	    case OFRelativeDateParserFutureRelativity:
	    case OFRelativeDateParserCurrentRelativity:
		// set the weekday and a week
		NSLog( @"set the weekday to the diff %d + 7 days for %d total", (weekdayComponent - weekday), (7-(weekdayComponent - weekday)));
		[components setDay:(7-(weekdayComponent - weekday))];
		break;
	    case OFRelativeDateParserPastRelativity:
		// set the weekday to be earlier in this week
		NSLog( @"set the weekday to be earlier in this week: %d ", (weekday - weekdayComponent) );
		[components setDay:(weekday - weekdayComponent)];
		break;
	}
    }
    
    // the current day is less than the requested day
    else {
	switch (modifier) {
	    case OFRelativeDateParserPastRelativity:
		// set the weekday and lose a week
		NSLog( @"set the weekday to the diff %d - 7 days for %d total", (weekday - weekdayComponent), (-7+(weekday - weekdayComponent)) );
		[components setDay:(-7+(weekday - weekdayComponent))];
		break;
	    case OFRelativeDateParserFutureRelativity:
	    case OFRelativeDateParserCurrentRelativity:
		// set the weekday to the day in this week
		NSLog( @"set the weekday to the day in this week, %d", (weekday- weekdayComponent) );
		[components setDay:(weekday- weekdayComponent)];
		break;
	}
    }
    NSLog( @"adding %d days to date: %@", [components day], date);
    return [currentCalendar dateByAddingComponents:components toDate:date options:0];; //return next week
}
+ (NSDateComponents *)_addToComponents:(NSDateComponents *)components codeString:(DPCode)dpCode codeInt:(int)codeInt withMultiplier:(int)multiplier;
{
    codeInt*=multiplier;
    switch (dpCode) {
	case DPHour:
	    if ( [components hour] == NSUndefinedDateComponent )
		[components setHour:codeInt];
	    else
		[components setHour:[components hour] + codeInt];
	    NSLog( @"Added %d hours to the components, now at: %d hours", codeInt, [components hour] );
	    break;
	case DPDay:
	    if ( [components day] == NSUndefinedDateComponent )
		[components setDay:codeInt];
	    else 
		[components setDay:[components day] + codeInt];
	    NSLog( @"Added %d days to the components, now at: %d days", codeInt, [components day] );
	    break;
	case DPWeek:
	    if ( [components day] == NSUndefinedDateComponent )
		[components setDay:codeInt*7];
	    else
		[components setDay:[components day] + codeInt*7];
	    NSLog( @"Added %d weeks(ie. days) to the components, now at: %d days", codeInt, [components day] );
	    break;
	case DPMonth:
	    if ( [components month] == NSUndefinedDateComponent )
		[components setMonth:codeInt];
	    else
		[components setMonth:[components month] + codeInt];
	    NSLog( @"Added %d months to the components, now at: %d months", codeInt, [components month] );
	    break;
	case DPYear:
	    if ( [components year] == NSUndefinedDateComponent )
		[components setYear:codeInt];
	    else 
		[components setYear:[components year] + multiplier*codeInt];
	     NSLog( @"Added %d years to the components, now at: %d years", codeInt, [components year] );
	    break;
    }
    return components;
}
@end
