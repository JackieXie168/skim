//
//  NSDate_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 07/29/05.
/*
 This software is Copyright (c) 2005,2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSDate_BDSKExtensions.h"
#import "BibPrefController.h"

static NSDictionary *locale = nil;
static CFDateFormatterRef dateFormatter = NULL;
static CFDateFormatterRef numericDateFormatter = NULL;

@implementation NSDate (BDSKExtensions)

+ (void)didLoad
{
    if(nil == locale){
        NSArray *monthNames = [NSArray arrayWithObjects:@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December", nil];
        NSArray *shortMonthNames = [NSArray arrayWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec", nil];
        
        locale = [[NSDictionary alloc] initWithObjectsAndKeys:@"MDYH", NSDateTimeOrdering, monthNames, NSMonthNameArray, shortMonthNames, NSShortMonthNameArray, nil];
    }
    

    // NB: CFDateFormatters are fairly expensive beasts to create, so we cache them here
    
    CFAllocatorRef alloc = CFAllocatorGetDefault();
    
    // use the en locale, since dates use en short names as keys in BibTeX
    CFLocaleRef enLocale = CFLocaleCreate(alloc, CFSTR("en"));
   
    // Create a date formatter that accepts "text month-numeric day-numeric year", which is arguably the most common format in BibTeX
    if(NULL == dateFormatter){
    
        // the formatter styles aren't used here, since we set an explicit format
        dateFormatter = CFDateFormatterCreate(alloc, enLocale, kCFDateFormatterLongStyle, kCFDateFormatterLongStyle);

        if(NULL != dateFormatter){
            // CFDateFormatter uses ICU formats: http://icu.sourceforge.net/userguide/formatDateTime.html
            CFDateFormatterSetFormat(dateFormatter, CFSTR("MMM-dd-yy"));
            CFDateFormatterSetProperty(dateFormatter, kCFDateFormatterIsLenient, kCFBooleanTrue);    
        }
    }
    
    if(NULL == numericDateFormatter){
        
        // the formatter styles aren't used here, since we set an explicit format
        numericDateFormatter = CFDateFormatterCreate(alloc, enLocale, kCFDateFormatterLongStyle, kCFDateFormatterLongStyle);
        
        // CFDateFormatter uses ICU formats: http://icu.sourceforge.net/userguide/formatDateTime.html
        CFDateFormatterSetFormat(numericDateFormatter, CFSTR("MM-dd-yy"));
        CFDateFormatterSetProperty(dateFormatter, kCFDateFormatterIsLenient, kCFBooleanTrue);            
    }
    if(enLocale) CFRelease(enLocale);
}
    
- (id)initWithMonthDayYearString:(NSString *)dateString;
{    
   [[self init] release];
    self = nil;

    CFAllocatorRef alloc = CFAllocatorGetDefault();
    
    CFDateRef date = CFDateFormatterCreateDateFromString(alloc, dateFormatter, (CFStringRef)dateString, NULL);
    
    if(date != nil)
        return (NSDate *)date;
    
    // If we didn't get a valid date on the first attempt, let's try a purely numeric formatter    
    date = CFDateFormatterCreateDateFromString(alloc, numericDateFormatter, (CFStringRef)dateString, NULL);
    
    if(date != nil)
        return (NSDate *)date;
    
    // Now fall back to natural language parsing, which is fairly memory-intensive.
    // We should be able to use NSDateFormatter with the natural language option, but it doesn't seem to work as well as +dateWithNaturalLanguageString
    return [[NSDate dateWithNaturalLanguageString:dateString locale:locale] retain];
}

/* Colloquial date handling

The parsing logic requires the date to contain three tokens (all strings are compared case-insensitively):

1.  Integer specifier.  May be "a", "an", a sequence of digits, or localized strings "one"..."ten"
2.  A time interval.  May be "day" "week" "month" "year" or "fortnight", or the plural form of any of these (plural forms are not recognized as such).  This will be multiplied by the integer specifier from the first step.
3.  A direction for the interval, either positive or negative time.  The term "from" is taken to imply a positive interval as in "10 days from today."  The term "ago" is taken to imply a negative interval, as in "10 days ago."
4.  A time base.  May be "today" "now" "yesterday" or "tomorrow."  The interval will be adjusted accordingly from this base date.

Date format strings are not recognized anywhere in the string.  If the parsing fails at any step, nil will be returned, except if the integer specifier is zero (this will result in a return value of +[NSDate date].

*/

+ (id)dateWithColloquialString:(NSString *)string;
{
    if([NSString isEmptyString:string])
        return nil;
    NSDate *today = [[self class] date];
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceCharacterSet];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanCharactersFromSet:whitespaceSet intoString:NULL];
    
    // this is a fairly generic exception that we throw when a parse failure occurs
    NSException *parseException = [NSException exceptionWithName:@"BDSKColloquialDateException" reason:@"Parse failure" userInfo:nil];
    NSTimeInterval interval = 0;
    volatile BOOL failed = NO;
    
    static CFMutableDictionaryRef numbers = NULL;
    if(numbers == NULL){
        int index = 1;
        numbers = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 10, &OFCaseInsensitiveStringKeyDictionaryCallbacks, &OFIntegerDictionaryValueCallbacks);
        CFDictionaryAddValue(numbers, (CFStringRef)NSLocalizedString(@"one",@"Number for parsing colloquial date"), (const void *)index++);
        CFDictionaryAddValue(numbers, (CFStringRef)NSLocalizedString(@"two",@"Number for parsing colloquial date"), (const void *)index++);
        CFDictionaryAddValue(numbers, (CFStringRef)NSLocalizedString(@"three",@"Number for parsing colloquial date"), (const void *)index++);
        CFDictionaryAddValue(numbers, (CFStringRef)NSLocalizedString(@"four",@"Number for parsing colloquial date"), (const void *)index++);
        CFDictionaryAddValue(numbers, (CFStringRef)NSLocalizedString(@"five",@"Number for parsing colloquial date"), (const void *)index++);
        CFDictionaryAddValue(numbers, (CFStringRef)NSLocalizedString(@"six",@"Number for parsing colloquial date"), (const void *)index++);
        CFDictionaryAddValue(numbers, (CFStringRef)NSLocalizedString(@"seven",@"Number for parsing colloquial date"), (const void *)index++);
        CFDictionaryAddValue(numbers, (CFStringRef)NSLocalizedString(@"eight",@"Number for parsing colloquial date"), (const void *)index++);
        CFDictionaryAddValue(numbers, (CFStringRef)NSLocalizedString(@"nine",@"Number for parsing colloquial date"), (const void *)index++);
        CFDictionaryAddValue(numbers, (CFStringRef)NSLocalizedString(@"ten",@"Number for parsing colloquial date"), (const void *)index++);
    }
    
    @try{
        NSString *countStr = nil;
        int count;
        [scanner scanUpToCharactersFromSet:whitespaceSet intoString:&countStr];
        
        // we could add an NSString method to look up numbers from a dictionary, say 
        if(CFStringCompare((CFStringRef)countStr, (CFStringRef)NSLocalizedString(@"a", @"Word for parsing colloquial date"), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
            count = 1;
        else if(CFStringCompare((CFStringRef)countStr, (CFStringRef)NSLocalizedString(@"an", @"Word for parsing colloquial date"), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
            count = 1;
        else if(countStr != nil)
            if(CFDictionaryGetValueIfPresent(numbers, countStr, (const void **)&count) == FALSE)
                count = [countStr intValue];

        // this occurs if the first token was unrecognizable
        if(count == 0 || ABS(count) >= HUGE_VAL)
            @throw parseException;
        
        [scanner scanCharactersFromSet:whitespaceSet intoString:NULL];

        NSString *intervalStr = nil;
        [scanner scanUpToCharactersFromSet:whitespaceSet intoString:&intervalStr];
        
        if(intervalStr == nil)
            @throw parseException;

        // these are arranged in what I consider the maximum likelihood of occurrence
        // @@ there is probably a standard somewhere that tells how to compute month/year intervals (or likely in the CFDate source), but we don't really care about leap year or 30 vs. 31 days per month for present purposes
        
        NSArray *yearMonthWeek = [[NSUserDefaults standardUserDefaults] objectForKey:NSYearMonthWeekDesignations];
        OBASSERT([yearMonthWeek count] == 3);
        
        NSString *year = [yearMonthWeek count] ? [yearMonthWeek objectAtIndex:0] : NSLocalizedString(@"year", @"Word for parsing colloquial date");
        NSString *month = [yearMonthWeek count] > 1 ? [yearMonthWeek objectAtIndex:1] : NSLocalizedString(@"month", @"Word for parsing colloquial date");
        NSString *week = [yearMonthWeek count] > 2 ? [yearMonthWeek objectAtIndex:2] : NSLocalizedString(@"week", @"Word for parsing colloquial date");
        
        if([intervalStr hasCaseInsensitivePrefix:NSLocalizedString(@"day", @"Word for parsing colloquial date")])
            interval = 24 * 3600;
        else if([intervalStr hasCaseInsensitivePrefix:week])
            interval = 7 * 24 * 3600;
        else if([intervalStr hasCaseInsensitivePrefix:month])
            interval = 30.5 * 24 * 3600;
        else if([intervalStr hasCaseInsensitivePrefix:year])
            interval = 12 * 30.5 * 24 * 3600;
        else if([intervalStr hasCaseInsensitivePrefix:NSLocalizedString(@"fortnight", @"Word for parsing colloquial date")])
            interval = 2 * 7 * 24 * 3600;
        else if([intervalStr hasCaseInsensitivePrefix:NSLocalizedString(@"hour", @"Word for parsing colloquial date")])
            interval = 3600;
        else if([intervalStr hasCaseInsensitivePrefix:NSLocalizedString(@"minute", @"Word for parsing colloquial date")])
            interval = 3600;
        else
            @throw parseException;
        
        // we need to apply this number of intervals
        interval *= count;
        
        // NSTimeInterval is supposed to give submillisecond precision over a range of 10,000 years.  It's unlikely that we work with publications over that range.
        NSAssert(ABS(interval) < DBL_MAX, @"Time interval overflow.");
                
        [scanner scanCharactersFromSet:whitespaceSet intoString:NULL];
        
        // now see what direction we're going in time
        NSString *signStr = nil;
        [scanner scanUpToCharactersFromSet:whitespaceSet intoString:&signStr];
        
        NSAssert(interval > 0, @"Interval must be greater than zero.");
        BOOL getBase = NO;
        
        // -[self note] passing nil or NULL to a CFString function results in a crash
        // @@ Use a case-insensitive dictionary here also, with NSEarlierTimeDesignations; NSLaterTimeDesignations doesn't make sense in our context of relative dates (and the OS handles those fairly well anyway)
        if(signStr != nil){
            if(CFStringCompare((CFStringRef)signStr, (CFStringRef)NSLocalizedString(@"from", @"Word for parsing colloquial date"), kCFCompareCaseInsensitive) == kCFCompareEqualTo){
                interval *= 1;
                getBase = YES;
            } else if(CFStringCompare((CFStringRef)signStr, (CFStringRef)NSLocalizedString(@"ago", @"Word for parsing colloquial date"), kCFCompareCaseInsensitive) == kCFCompareEqualTo){
                interval *= -1; 
                getBase = NO;
            } else
                @throw parseException;
        }
        
        // get the base date if necessary
        if(getBase == YES){
            
            [scanner scanCharactersFromSet:whitespaceSet intoString:NULL];
            
            NSString *baseStr = nil;
            [scanner scanUpToCharactersFromSet:whitespaceSet intoString:&baseStr];
            
            static CFMutableDictionaryRef days = NULL;
            int delta; // an NSTimeInterval, but we can't store a double in a dictionary, and we don't need the extra precision
            
            if(days == NULL){
                int delta = 0;
                days = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &OFCaseInsensitiveStringKeyDictionaryCallbacks, &OFIntegerDictionaryValueCallbacks);
                
                // strings equivalent to "today"
                NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:NSThisDayDesignations];
                CFIndex count = [array count];
                if(count < 2)
                    array = [NSArray arrayWithObjects:NSLocalizedString(@"today", @"Word for parsing colloquial date"), NSLocalizedString(@"now", @"Word for parsing colloquial date"), nil];
                while(count--)
                    CFDictionaryAddValue(days, CFArrayGetValueAtIndex((CFArrayRef)array, count), (const void *)delta);
                
                // strings equivalent to "tomorrow"
                array = [[NSUserDefaults standardUserDefaults] objectForKey:NSNextDayDesignations];
                count = [array count];
                delta = 1 * 24 * 3600;
                if(count == 0)
                    array = [NSArray arrayWithObject:NSLocalizedString(@"tomorrow", @"Word for parsing colloquial date")];
                while(count--)
                    CFDictionaryAddValue(days, CFArrayGetValueAtIndex((CFArrayRef)array, count), (const void *)delta);

                // strings equivalent to "yesterday"
                array = [[NSUserDefaults standardUserDefaults] objectForKey:NSPriorDayDesignations];
                count = [array count];
                delta = -1 * 24 * 3600;
                if(count == 0)
                    array = [NSArray arrayWithObject:NSLocalizedString(@"yesterday", @"Word for parsing colloquial date")];
                while(count--)
                    CFDictionaryAddValue(days, CFArrayGetValueAtIndex((CFArrayRef)array, count), (const void *)delta);
            }
                
            delta = 0;
            if(baseStr != nil && CFDictionaryGetValueIfPresent(days, (CFStringRef)baseStr, (const void **)&delta) == FALSE)
                @throw parseException;
            
            today = [today addTimeInterval:delta];
        }
        
        // not really necessary; we just ignore stuff after this
        OBASSERT([scanner isAtEnd]);
    }
    @catch(id exception){
        failed = YES;
        if([exception respondsToSelector:@selector(name)] == NO || [[exception name] isEqual:@"BDSKColloquialDateException"] == NO)
            @throw;
    }
    @finally{
        [scanner release];
    }
    
    return (failed == YES ? nil : [today addTimeInterval:interval]);
}

@end

@implementation NSCalendarDate (BDSKExtensions)

- (NSCalendarDate *)initWithNaturalLanguageString:(NSString *)dateString;
{
    // initWithString should release self when it returns nil
    NSCalendarDate *date = [self initWithString:dateString];

    return (date != nil ? date : [[NSCalendarDate dateWithNaturalLanguageString:dateString] retain]);
}

// override this NSDate method so we can return an NSCalendarDate efficiently
- (NSCalendarDate *)initWithMonthDayYearString:(NSString *)dateString;
{        
    NSDate *date = [[NSDate alloc] initWithMonthDayYearString:dateString];
    NSTimeInterval time = [date timeIntervalSinceReferenceDate];
    self = [self initWithTimeIntervalSinceReferenceDate:time];
    [date release];
    
    return self;
}

- (NSString *)dateDescription{
    return [self descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSDateFormatString]];
}

- (NSString *)shortDateDescription{
    return [self descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString]];
}

- (NSString *)rssDescription{
    return [self descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %z"];
}

- (NSString *)standardDescription{
    return [self descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"];
}

- (NSCalendarDate *)startOfHour;
{
    NSCalendarDate *startHour = [[NSCalendarDate alloc] initWithYear:[self yearOfCommonEra] month:[self monthOfYear] day:[self dayOfMonth] hour:[self hourOfDay] minute:0 second:0 timeZone:[self timeZone]];
    return [startHour autorelease];
}

- (NSCalendarDate *)endOfHour;
{
    return [[self startOfHour] dateByAddingYears:0 months:0 days:0 hours:1 minutes:0 seconds:-1];
}

- (NSCalendarDate *)startOfDay;
{
    NSCalendarDate *startDay = [[NSCalendarDate alloc] initWithYear:[self yearOfCommonEra] month:[self monthOfYear] day:[self dayOfMonth] hour:0 minute:0 second:0 timeZone:[self timeZone]];
    return [startDay autorelease];
}

- (NSCalendarDate *)endOfDay;
{
    return [[self startOfDay] dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:-1];
}

- (NSCalendarDate *)startOfWeek;
{
    NSCalendarDate *startDay = [self startOfDay];
    return [startDay dateByAddingYears:0 months:0 days:-[startDay dayOfWeek] hours:0 minutes:0 seconds:0];
}

- (NSCalendarDate *)endOfWeek;
{
    return [[self startOfWeek] dateByAddingYears:0 months:0 days:7 hours:0 minutes:0 seconds:-1];
}

- (NSCalendarDate *)startOfMonth;
{
    NSCalendarDate *startDay = [[NSCalendarDate alloc] initWithYear:[self yearOfCommonEra] month:[self monthOfYear] day:1 hour:0 minute:0 second:0 timeZone:[self timeZone]];
    return [startDay autorelease];
}

- (NSCalendarDate *)endOfMonth;
{
    return [[self startOfMonth] dateByAddingYears:0 months:1 days:0 hours:0 minutes:0 seconds:-1];
}

- (NSCalendarDate *)startOfYear;
{
    NSCalendarDate *startDay = [[NSCalendarDate alloc] initWithYear:[self yearOfCommonEra] month:1 day:1 hour:0 minute:0 second:0 timeZone:[self timeZone]];
    return [startDay autorelease];
}

- (NSCalendarDate *)endOfYear;
{
    return [[self startOfYear] dateByAddingYears:1 months:0 days:0 hours:0 minutes:0 seconds:-1];
}

- (NSCalendarDate *)startOfPeriod:(int)period;
{
    switch (period) {
        case BDSKPeriodHour:
            return [self startOfHour];
        case BDSKPeriodDay:
            return [self startOfDay];
        case BDSKPeriodWeek:
            return [self startOfWeek];
        case BDSKPeriodMonth:
            return [self startOfMonth];
        case BDSKPeriodYear:
            return [self startOfYear];
        default:
            NSLog(@"Unknown period %d",period);
            return self;
    }
}

- (NSCalendarDate *)endOfPeriod:(int)period;
{
    switch (period) {
        case BDSKPeriodHour:
            return [self endOfHour];
        case BDSKPeriodDay:
            return [self endOfDay];
        case BDSKPeriodWeek:
            return [self endOfWeek];
        case BDSKPeriodMonth:
            return [self endOfMonth];
        case BDSKPeriodYear:
            return [self endOfYear];
        default:
            NSLog(@"Unknown period %d",period);
            return self;
    }
}

- (NSCalendarDate *)dateByAddingNumber:(int)number ofPeriod:(int)period {
    switch (period) {
        case BDSKPeriodHour:
            return [self dateByAddingYears:0 months:0 days:0 hours:number minutes:0 seconds:0];
        case BDSKPeriodDay:
            return [self dateByAddingYears:0 months:0 days:number hours:0 minutes:0 seconds:0];
        case BDSKPeriodWeek:
            return [self dateByAddingYears:0 months:0 days:7 * number hours:0 minutes:0 seconds:0];
        case BDSKPeriodMonth:
            return [self dateByAddingYears:0 months:number days:0 hours:0 minutes:0 seconds:0];
        case BDSKPeriodYear:
            return [self dateByAddingYears:number months:0 days:0 hours:0 minutes:0 seconds:0];
        default:
            NSLog(@"Unknown period %d",period);
            return self;
    }
}

@end
