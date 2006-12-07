// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OFTimeSpanFormatter.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "NSObject-OFExtensions.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFTimeSpanFormatter.m,v 1.12 2003/02/12 22:47:28 ryan Exp $")

@implementation OFTimeSpanFormatter

- init;
{
    [super init];
    [self setStandardWorkTime];
    [self setUseVerboseFormat:NO];
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

- (int)hoursPerDay;
{
    return hoursPerDay;
}

- (int)hoursPerWeek;
{
    return hoursPerWeek;
}

- (int)hoursPerMonth;
{
    return hoursPerMonth;
}

- (void)setHoursPerDay:(int)hours;
{
    hoursPerDay = hours;
}

- (void)setHoursPerWeek:(int)hours;
{
    hoursPerWeek = hours;
}

- (void)setHoursPerMonth:(int)hours;
{
    hoursPerMonth = hours;
}

- (BOOL)isStandardWorkTime;
{
    return hoursPerDay == 8 && hoursPerWeek == 40 && hoursPerMonth == 160;
}

- (BOOL)isStandardCalendarTime;
{
    return hoursPerDay == 24 && hoursPerWeek == 168 && hoursPerMonth == 720;
}

- (void)setStandardWorkTime; // 8h = 1d, 40h = 1w, 160h = 1m
{
    hoursPerDay = 8;
    hoursPerWeek = 40;
    hoursPerMonth = 160;
}

- (void)setStandardCalendarTime; // 24h = 1d, 168h = 1w, 720h = 1m (30d = 1m)
{
    hoursPerDay = 24;
    hoursPerWeek = 168;
    hoursPerMonth = 720;
}


- (NSString *)stringForObjectValue:(id)object;
{
    if ([object isKindOfClass:[NSNumber class]]) {
        NSMutableArray *components;
        int intValue;
        float floatValue;
        unsigned int part;

        components = [NSMutableArray array];
        intValue = [(NSDecimalNumber *)object intValue];
        floatValue = [(NSDecimalNumber *)object floatValue];
        floatValue -= (float)intValue;

        if ((part = intValue / hoursPerWeek)) {
            if (shouldUseVerboseFormat) {
                if (part > 1.0)
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d weeks", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span), part]];
                else
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d week", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span singular), part]];
            } else
                [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%dw", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span abbreviated), part]];

            intValue -= part * hoursPerWeek;
        }
        if ((part = intValue / hoursPerDay)) {
            if (shouldUseVerboseFormat) {
                if (part > 1.0)
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d days", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span), part]];
                else
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d day", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span singular), part]];
            } else
                [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%dd", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span abbreviated), part]];

            intValue -= part * hoursPerDay;
        }
        if (floatValue) {
            floatValue += (float)intValue;
            if (shouldUseVerboseFormat) {
                if (floatValue > 1.0)
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1.2f hours", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span), floatValue]];
                else
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1.2f hour", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span singular), floatValue]];
            } else
                [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1.2fh", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span abbreviated), floatValue]];
        } else if (intValue || ![components count]) {
            if (shouldUseVerboseFormat) {
                if (intValue > 1)
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d hours", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span), intValue]];
                else
                    [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d hour", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span singular), intValue]];
            } else
                [components addObject:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%dh", @"OmniFoundation", [OFTimeSpanFormatter bundle], time span formatter span abbreviated), intValue]];
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
    
    if (![string length]) {
        *obj = nil;
        return YES;
    }

    whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    scanner = [NSScanner scannerWithString:string];
    while(1) {
        // Eat whitespace
        [scanner scanCharactersFromSet:whitespaceCharacterSet intoString:(NSString **)0];
        
        if (![scanner scanFloat:&number]) {
            if (gotAnythingValid)
                break;
            if (error)
                *error = NSLocalizedStringFromTableInBundle(@"Invalid time span format", @"OmniFoundation", [OFTimeSpanFormatter bundle], formatter input error);
            return NO;
        }
        if ([scanner scanString:NSLocalizedStringFromTableInBundle(@"m", @"OmniFoundation", [OFTimeSpanFormatter bundle], timespan formatter lowercase first character in months) intoString:NULL] || [scanner scanString:NSLocalizedStringFromTableInBundle(@"M", @"OmniFoundation", [OFTimeSpanFormatter bundle], timespan formatter uppercase first character in months) intoString:NULL]) {
            number *= (float)hoursPerMonth;
        } else if ([scanner scanString:NSLocalizedStringFromTableInBundle(@"w", @"OmniFoundation", [OFTimeSpanFormatter bundle], timespan formatter lowercase first character in weeks) intoString:NULL] || [scanner scanString:NSLocalizedStringFromTableInBundle(@"W", @"OmniFoundation", [OFTimeSpanFormatter bundle], timespan formatter uppercase first character in weeks) intoString:NULL]) {
            number *= (float)hoursPerWeek;
        } else if ([scanner scanString:NSLocalizedStringFromTableInBundle(@"d", @"OmniFoundation", [OFTimeSpanFormatter bundle], timespan formatter lowercase first character in days) intoString:NULL] || [scanner scanString:NSLocalizedStringFromTableInBundle(@"D", @"OmniFoundation", [OFTimeSpanFormatter bundle], timespan formatter uppercase first character in days) intoString:NULL]) {
            number *= (float)hoursPerDay;
        } else if ([scanner scanString:NSLocalizedStringFromTableInBundle(@"h", @"OmniFoundation", [OFTimeSpanFormatter bundle], timespan formatter lowercase first character in hours) intoString:NULL] || [scanner scanString:NSLocalizedStringFromTableInBundle(@"H", @"OmniFoundation", [OFTimeSpanFormatter bundle], timespan formatter uppercase first character in hours) intoString:NULL]) {
        }
        hours += number;
        gotAnythingValid = YES;
    }

    *obj = [NSDecimalNumber numberWithFloat:hours];
    return YES;
}

@end
