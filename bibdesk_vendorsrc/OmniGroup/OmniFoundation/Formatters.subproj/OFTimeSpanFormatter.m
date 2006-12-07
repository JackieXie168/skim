// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFTimeSpanFormatter.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "NSObject-OFExtensions.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFTimeSpanFormatter.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFTimeSpanFormatter

- init;
{
    [super init];
    [self setStandardWorkTime];
    [self setUseVerboseFormat:NO];
    _flags.displayHours = YES;
    _flags.displayDays = YES;
    _flags.displayWeeks = YES;
    _flags.displayMonths = NO;
    _flags.displayYears = NO;
    return self;
}

- (void)setUseVerboseFormat:(BOOL)shouldUseVerbose;
{
    shouldUseVerboseFormat = shouldUseVerbose;
}

- (BOOL)shouldUseVerboseFormat;
{
    return shouldUseVerboseFormat;
}

- (unsigned int)hoursPerDay;
{
    return hoursPerDay;
}

- (unsigned int)hoursPerWeek;
{
    return hoursPerWeek;
}

- (unsigned int)hoursPerMonth;
{
    return hoursPerMonth;
}

- (unsigned int)hoursPerYear;
{
    return hoursPerYear;
}

- (void)setHoursPerDay:(unsigned int)hours;
{
    hoursPerDay = hours;
}

- (void)setHoursPerWeek:(unsigned int)hours;
{
    hoursPerWeek = hours;
}

- (void)setHoursPerMonth:(unsigned int)hours;
{
    hoursPerMonth = hours;
}

- (void)setHoursPerYear:(unsigned int)hours;
{
    hoursPerYear = hours;
}

- (BOOL)isStandardWorkTime;
{
    return hoursPerDay == STANDARD_WORK_HOURS_PER_DAY && hoursPerWeek == STANDARD_WORK_HOURS_PER_WEEK && hoursPerMonth == STANDARD_WORK_HOURS_PER_MONTH && hoursPerYear == STANDARD_WORK_HOURS_PER_YEAR;
}

- (BOOL)isStandardCalendarTime;
{
    return hoursPerDay == STANDARD_WORK_PER_DAY && hoursPerWeek == STANDARD_WORK_PER_WEEK && hoursPerMonth == STANDARD_WORK_PER_MONTH && hoursPerYear == STANDARD_WORK_PER_YEAR;
}

- (BOOL)displayHours;
{
    return _flags.displayHours;
}

- (BOOL)displayDays;
{
    return _flags.displayDays;
}

- (BOOL)displayWeeks;
{
    return _flags.displayWeeks;
}

- (BOOL)displayMonths;
{
    return _flags.displayMonths;
}

- (BOOL)displayYears;
{
    return _flags.displayYears;
}

- (void)setDisplayHours:(BOOL)aBool;
{
    _flags.displayHours = (aBool != NO);
}

- (void)setDisplayDays:(BOOL)aBool;
{
    _flags.displayDays = (aBool != NO);
}

- (void)setDisplayWeeks:(BOOL)aBool;
{
    _flags.displayWeeks = (aBool != NO);
}

- (void)setDisplayMonths:(BOOL)aBool;
{
    _flags.displayMonths = (aBool != NO);
}

- (void)setDisplayYears:(BOOL)aBool;
{
    _flags.displayYears = (aBool != NO);
}

- (void)setStandardWorkTime; // 8h = 1d, 40h = 1w, 160h = 1m
{
    hoursPerDay = STANDARD_WORK_HOURS_PER_DAY;
    hoursPerWeek = STANDARD_WORK_HOURS_PER_WEEK;
    hoursPerMonth = STANDARD_WORK_HOURS_PER_MONTH;
    hoursPerYear = STANDARD_WORK_HOURS_PER_YEAR;
}

- (void)setStandardCalendarTime; // 24h = 1d, 168h = 1w, 720h = 1m (30d = 1m), 8760h = 1y (365d = 1y)
{
    hoursPerDay = STANDARD_WORK_PER_DAY;
    hoursPerWeek = STANDARD_WORK_PER_WEEK;
    hoursPerMonth = STANDARD_WORK_PER_MONTH;
    hoursPerYear = STANDARD_WORK_PER_YEAR;
}


- (NSString *)stringForObjectValue:(id)object;
{
    if ([object isKindOfClass:[NSNumber class]]) {
        NSMutableArray *components;
        int intValue;
        float floatValue;
        unsigned int part;
	NSBundle *bundle = [OFTimeSpanFormatter bundle];
	
        components = [NSMutableArray array];
        intValue = [(NSDecimalNumber *)object intValue];
        floatValue = [(NSDecimalNumber *)object floatValue];
        floatValue -= (float)intValue;
	
        if (_flags.displayYears && (part = intValue / hoursPerYear)) {
            if (shouldUseVerboseFormat) {
                if (part > 1)
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d years", @"OmniFoundation", bundle, @"time span formatter span"), part]];
                else
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d year", @"OmniFoundation", bundle, @"time span formatter span singular"), part]];
            } else
                [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%dy", @"OmniFoundation", bundle, @"time span formatter span abbreviated"), part]];
	    
            intValue -= part * hoursPerYear;
        }
        if (_flags.displayMonths && (part = intValue / hoursPerMonth)) {
            if (shouldUseVerboseFormat) {
                if (part > 1)
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d months", @"OmniFoundation", bundle, @"time span formatter span"), part]];
                else
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d month", @"OmniFoundation", bundle, @"time span formatter span singular"), part]];
            } else
                [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%dm", @"OmniFoundation", bundle, @"time span formatter span abbreviated"), part]];
	    
            intValue -= part * hoursPerMonth;
        }
        if (_flags.displayWeeks && (part = intValue / hoursPerWeek)) {
            if (shouldUseVerboseFormat) {
                if (part > 1)
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d weeks", @"OmniFoundation", bundle, @"time span formatter span"), part]];
                else
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d week", @"OmniFoundation", bundle, @"time span formatter span singular"), part]];
            } else
                [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%dw", @"OmniFoundation", bundle, @"time span formatter span abbreviated"), part]];

            intValue -= part * hoursPerWeek;
        }
        if (_flags.displayDays && (part = intValue / hoursPerDay)) {
            if (shouldUseVerboseFormat) {
                if (part > 1)
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d days", @"OmniFoundation", bundle, @"time span formatter span"), part]];
                else
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d day", @"OmniFoundation", bundle, @"time span formatter span singular"), part]];
            } else
                [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%dd", @"OmniFoundation", bundle, @"time span formatter span abbreviated"), part]];

            intValue -= part * hoursPerDay;
        }
        if (_flags.displayHours && floatValue) {
            floatValue += (float)intValue;
            if (shouldUseVerboseFormat) {
                if (floatValue > 1.0)
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1.2f hours", @"OmniFoundation", bundle, @"time span formatter span"), floatValue]];
                else
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1.2f hour", @"OmniFoundation", bundle, @"time span formatter span singular"), floatValue]];
            } else
                [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1.2fh", @"OmniFoundation", bundle, @"time span formatter span abbreviated"), floatValue]];
        } else if (_flags.displayHours && (intValue || ![components count])) {
            if (shouldUseVerboseFormat) {
                if (intValue > 1)
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d hours", @"OmniFoundation", bundle, @"time span formatter span"), intValue]];
                else
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d hour", @"OmniFoundation", bundle, @"time span formatter span singular"), intValue]];
            } else
                [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%dh", @"OmniFoundation", bundle, @"time span formatter span abbreviated"), intValue]];
        }
        return [components componentsJoinedByString:@" "];
    } else
        return nil;
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error;
{
    BOOL gotAnythingValid = NO;
    float number, hours = 0.0;
    NSScanner *scanner;
    NSCharacterSet *whitespaceCharacterSet;
    NSCharacterSet *letterCharacterSet;
    
    if (![string length]) {
        *obj = nil;
        return YES;
    }

    whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    letterCharacterSet = [NSCharacterSet letterCharacterSet];
    scanner = [NSScanner scannerWithString:string];
    while(1) {
        // Eat whitespace
        [scanner scanCharactersFromSet:whitespaceCharacterSet intoString:NULL];
        
        if (![scanner scanFloat:&number]) {
            if (gotAnythingValid)
                break;
            if (error)
                *error = NSLocalizedStringFromTableInBundle(@"Invalid time span format", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"formatter input error");
            return NO;
        }
        if ([scanner scanString:NSLocalizedStringFromTableInBundle(@"y", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"timespan formatter lowercase first character in years") intoString:NULL] || [scanner scanString:NSLocalizedStringFromTableInBundle(@"Y", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"timespan formatter uppercase first character in years") intoString:NULL]) {
            number *= (float)hoursPerYear;
        } else if ([scanner scanString:NSLocalizedStringFromTableInBundle(@"m", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"timespan formatter lowercase first character in months") intoString:NULL] || [scanner scanString:NSLocalizedStringFromTableInBundle(@"M", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"timespan formatter uppercase first character in months") intoString:NULL]) {
            number *= (float)hoursPerMonth;
        } else if ([scanner scanString:NSLocalizedStringFromTableInBundle(@"w", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"timespan formatter lowercase first character in weeks") intoString:NULL] || [scanner scanString:NSLocalizedStringFromTableInBundle(@"W", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"timespan formatter uppercase first character in weeks") intoString:NULL]) {
            number *= (float)hoursPerWeek;
        } else if ([scanner scanString:NSLocalizedStringFromTableInBundle(@"d", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"timespan formatter lowercase first character in days") intoString:NULL] || [scanner scanString:NSLocalizedStringFromTableInBundle(@"D", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"timespan formatter uppercase first character in days") intoString:NULL]) {
            number *= (float)hoursPerDay;
        } else if ([scanner scanString:NSLocalizedStringFromTableInBundle(@"h", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"timespan formatter lowercase first character in hours") intoString:NULL] || [scanner scanString:NSLocalizedStringFromTableInBundle(@"H", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"timespan formatter uppercase first character in hours") intoString:NULL]) {
        }
        hours += number;
        gotAnythingValid = YES;

        // eat anything remaining since we might be parsing long forms... Yes... this sucks. (ryan)
        [scanner scanCharactersFromSet:letterCharacterSet intoString:NULL];
    }

    *obj = [NSDecimalNumber numberWithFloat:hours];
    return YES;
}

@end
