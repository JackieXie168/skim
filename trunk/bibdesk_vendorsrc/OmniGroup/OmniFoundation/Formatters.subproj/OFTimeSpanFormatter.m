// Copyright 2000-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFTimeSpanFormatter.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import "OFTimeSpan.h"
#import "NSObject-OFExtensions.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Formatters.subproj/OFTimeSpanFormatter.m 79079 2006-09-07 22:35:32Z kc $")

typedef float (*FLOAT_IMP)(id, SEL); 
typedef unsigned int (*UINT_IMP)(id, SEL);
typedef void (*SETFLOAT_IMP)(id, SEL, float);

typedef struct {
    NSString *singularString, *pluralString, *abbreviatedString;
    FLOAT_IMP spanGetImplementation;
    SETFLOAT_IMP spanSetImplementation;
    UINT_IMP formatterMultiplierImplementation;
    float fixedDivider;
} OFTimeSpanUnit;

@implementation OFTimeSpanFormatter

#define TIME_SPAN_UNITS 7

static OFTimeSpanUnit timeSpanUnits[TIME_SPAN_UNITS];
static NSNumberFormatter *numberFormatter;

+ (void)initialize;
{
    OBINITIALIZE;
    
    NSBundle *bundle = [self bundle];
    
    timeSpanUnits[0].pluralString = NSLocalizedStringFromTableInBundle(@"years", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[0].singularString = NSLocalizedStringFromTableInBundle(@"year", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[0].abbreviatedString = NSLocalizedStringFromTableInBundle(@"y", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[0].spanGetImplementation = (FLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(years)];
    timeSpanUnits[0].spanSetImplementation = (SETFLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(setYears:)];
    timeSpanUnits[0].formatterMultiplierImplementation = (UINT_IMP)[self instanceMethodForSelector:@selector(hoursPerYear)];
    
    timeSpanUnits[1].pluralString = NSLocalizedStringFromTableInBundle(@"months", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[1].singularString = NSLocalizedStringFromTableInBundle(@"month", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[1].abbreviatedString = NSLocalizedStringFromTableInBundle(@"mo", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[1].spanGetImplementation = (FLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(months)];
    timeSpanUnits[1].spanSetImplementation = (SETFLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(setMonths:)];
    timeSpanUnits[1].formatterMultiplierImplementation = (UINT_IMP)[self instanceMethodForSelector:@selector(hoursPerMonth)];    
    
    timeSpanUnits[2].pluralString = NSLocalizedStringFromTableInBundle(@"weeks", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[2].singularString = NSLocalizedStringFromTableInBundle(@"week", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[2].abbreviatedString = NSLocalizedStringFromTableInBundle(@"w", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[2].spanGetImplementation = (FLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(weeks)];
    timeSpanUnits[2].spanSetImplementation = (SETFLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(setWeeks:)];
    timeSpanUnits[2].formatterMultiplierImplementation = (UINT_IMP)[self instanceMethodForSelector:@selector(hoursPerWeek)];       
     
    timeSpanUnits[3].pluralString = NSLocalizedStringFromTableInBundle(@"days", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[3].singularString = NSLocalizedStringFromTableInBundle(@"day", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[3].abbreviatedString = NSLocalizedStringFromTableInBundle(@"d", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[3].spanGetImplementation = (FLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(days)];
    timeSpanUnits[3].spanSetImplementation = (SETFLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(setDays:)];
    timeSpanUnits[3].formatterMultiplierImplementation = (UINT_IMP)[self instanceMethodForSelector:@selector(hoursPerDay)];  
              
    timeSpanUnits[4].pluralString = NSLocalizedStringFromTableInBundle(@"hours", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[4].singularString = NSLocalizedStringFromTableInBundle(@"hour", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[4].abbreviatedString = NSLocalizedStringFromTableInBundle(@"h", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[4].spanGetImplementation = (FLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(hours)];
    timeSpanUnits[4].spanSetImplementation = (SETFLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(setHours:)];
    timeSpanUnits[4].formatterMultiplierImplementation = NULL;    
    timeSpanUnits[4].fixedDivider = 1.0f;    
    
    timeSpanUnits[5].pluralString = NSLocalizedStringFromTableInBundle(@"minutes", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[5].singularString = NSLocalizedStringFromTableInBundle(@"minute", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[5].abbreviatedString = NSLocalizedStringFromTableInBundle(@"m", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[5].spanGetImplementation = (FLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(minutes)];
    timeSpanUnits[5].spanSetImplementation = (SETFLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(setMinutes:)];
    timeSpanUnits[5].formatterMultiplierImplementation = NULL;
    timeSpanUnits[5].fixedDivider = 60.0f;    
                        
    timeSpanUnits[6].pluralString = NSLocalizedStringFromTableInBundle(@"seconds", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[6].singularString = NSLocalizedStringFromTableInBundle(@"second", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[6].abbreviatedString = NSLocalizedStringFromTableInBundle(@"s", @"OmniFoundation", bundle, @"time span formatter span");
    timeSpanUnits[6].spanGetImplementation = (FLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(seconds)];
    timeSpanUnits[6].spanSetImplementation = (SETFLOAT_IMP)[OFTimeSpan instanceMethodForSelector:@selector(setSeconds:)];    
    timeSpanUnits[6].formatterMultiplierImplementation = NULL;    
    timeSpanUnits[6].fixedDivider = 3600.0f;    
    
    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
}

- init;
{
    [super init];
    [self setStandardWorkTime];
    [self setUseVerboseFormat:NO];
    _flags.returnNumber = YES;
    
    _flags.displayUnits = 0;
    [self setDisplayHours:YES];
    [self setDisplayDays:YES];
    [self setDisplayWeeks:YES];

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

- (void)setShouldReturnNumber:(BOOL)shouldReturnNumber;
{
    _flags.returnNumber = shouldReturnNumber;
}

- (BOOL)shouldReturnNumber;
{
    return _flags.returnNumber;
}

- (void)setRoundingInterval:(float)interval;
{
    roundingInterval = interval;
}

- (float)roundingInterval;
{
    return roundingInterval;
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

- (BOOL)displaySeconds;
{
    return (_flags.displayUnits >> 6) & 1;
}

- (BOOL)displayMinutes;
{
    return (_flags.displayUnits >> 5) & 1;
}

- (BOOL)displayHours;
{
    return (_flags.displayUnits >> 4) & 1;
}

- (BOOL)displayDays;
{
    return (_flags.displayUnits >> 3) & 1;
}

- (BOOL)displayWeeks;
{
    return (_flags.displayUnits >> 2) & 1;
}

- (BOOL)displayMonths;
{
    return (_flags.displayUnits >> 1) & 1;
}

- (BOOL)displayYears;
{
    return (_flags.displayUnits >> 0) & 1;
}

- (void)setDisplaySeconds:(BOOL)aBool;
{
    if (aBool)
        _flags.displayUnits |= (1 << 6);
    else
        _flags.displayUnits &= ~(1 << 6);
}

- (void)setDisplayMinutes:(BOOL)aBool;
{
    if (aBool)
        _flags.displayUnits |= (1 << 5);
    else
        _flags.displayUnits &= ~(1 << 5);
}

- (void)setDisplayHours:(BOOL)aBool;
{
    if (aBool)
        _flags.displayUnits |= (1 << 4);
    else
        _flags.displayUnits &= ~(1 << 4);
}

- (void)setDisplayDays:(BOOL)aBool;
{
    if (aBool)
        _flags.displayUnits |= (1 << 3);
    else
        _flags.displayUnits &= ~(1 << 3);
}

- (void)setDisplayWeeks:(BOOL)aBool;
{
    if (aBool)
        _flags.displayUnits |= (1 << 2);
    else
        _flags.displayUnits &= ~(1 << 2);
}

- (void)setDisplayMonths:(BOOL)aBool;
{
    if (aBool)
        _flags.displayUnits |= (1 << 1);
    else
        _flags.displayUnits &= ~(1 << 1);
}

- (void)setDisplayYears:(BOOL)aBool;
{
    if (aBool)
        _flags.displayUnits |= (1 << 0);
    else
        _flags.displayUnits &= ~(1 << 0);
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

// bug://bugs/25124 We need to make sure that we display true and accurate information. This means that, if we hav an 
// input of 2h but are not displaying hours, then we must roll the fraction up into the next displayed value. If we
// don't do this then we'll get 0 as our return value.

- (float)_useRoundingOnValue:(float)value;
{
    if (!roundingInterval)
        return value;
        
    float remainder = fmod(value, roundingInterval);
            
    if (remainder > (roundingInterval / 2))
        value += (roundingInterval - remainder);
    else
        value -= remainder;
    return value;
}

- (NSString *)stringForObjectValue:(id)object;
{
    if (![object isKindOfClass:[NSNumber class]] && ![object isKindOfClass:[OFTimeSpan class]]) 
	return @"";

    NSMutableString *result = [NSMutableString string];
    float hoursLeft = [object floatValue];
    int unitIndex;
    for (unitIndex = 0; unitIndex < TIME_SPAN_UNITS && hoursLeft != 0.0; unitIndex++) {
        if (_flags.displayUnits & (1 << unitIndex)) {
            BOOL willDisplaySmallerUnits = (_flags.displayUnits & ~((1 << (unitIndex+1))-1));
            float value = hoursLeft;
            
            if (timeSpanUnits[unitIndex].formatterMultiplierImplementation) {
                float hoursPerUnit = timeSpanUnits[unitIndex].formatterMultiplierImplementation(self, NULL);
		value /= hoursPerUnit;
		hoursLeft -= ((int)value) * hoursPerUnit;
            } else {
		value *= timeSpanUnits[unitIndex].fixedDivider;
                hoursLeft -= ((int)value) / timeSpanUnits[unitIndex].fixedDivider;                
	    }
	    
            NSString *numberString;
            if (willDisplaySmallerUnits) {
		value = (int)value;
                numberString = [numberFormatter stringFromNumber:[NSNumber numberWithInt:(int)value]];
            } else {
                numberString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat:[self _useRoundingOnValue:value]]];
                hoursLeft = 0.0;
            }
            
            if (value != 0.0) {
                if ([result length])
                    [result appendString:@" "];            
                if (shouldUseVerboseFormat) {
                    NSString *unitString = ABS(value) > 1.0 ? timeSpanUnits[unitIndex].pluralString : timeSpanUnits[unitIndex].singularString;
                    [result appendFormat:@"%@ %@", numberString, unitString];
                } else
                    [result appendFormat:@"%@%@", numberString, timeSpanUnits[unitIndex].abbreviatedString];
            }
        }
    }
    return result;
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error;
{
    BOOL gotAnythingValid = NO;
    float number;
    NSScanner *scanner;
    NSCharacterSet *whitespaceCharacterSet;
    NSCharacterSet *letterCharacterSet;
    OFTimeSpan *timeSpan;
    BOOL negativLand = NO;
    
    if (![string length]) {
        *obj = nil;
        return YES;
    }
    
    timeSpan = [[OFTimeSpan alloc] initWithTimeSpanFormatter:self];

    whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    letterCharacterSet = [NSCharacterSet letterCharacterSet];
    scanner = [NSScanner localizedScannerWithString:string];
    [scanner setCaseSensitive:NO];
    while(1) {
        // Eat whitespace
        [scanner scanCharactersFromSet:whitespaceCharacterSet intoString:NULL];
        
        // Look for a sign.  Ace of Base would be proud.  Not supporting infix operator followed by unary sign: "1d - +1h".
        if ([scanner scanString:@"-" intoString:NULL])
            negativLand = YES;
        else if ([scanner scanString:@"+" intoString:NULL])
            negativLand = NO;

        // Eat more whitespace
        [scanner scanCharactersFromSet:whitespaceCharacterSet intoString:NULL];

        if (![scanner scanFloat:&number]) {
            if (gotAnythingValid)
                break;
            if (error)
                *error = NSLocalizedStringFromTableInBundle(@"Invalid time span format", @"OmniFoundation", [OFTimeSpanFormatter bundle], @"formatter input error");
            return NO;
        }
        
        if (negativLand)
            number *= -1.0f;
        
        int unitIndex;
        for (unitIndex = 0; unitIndex < TIME_SPAN_UNITS; unitIndex++) {
            if ([scanner scanString:timeSpanUnits[unitIndex].abbreviatedString intoString:NULL]) {
                float existingValue = timeSpanUnits[unitIndex].spanGetImplementation(timeSpan, NULL);
                timeSpanUnits[unitIndex].spanSetImplementation(timeSpan, NULL, number + existingValue);
                break;
            }
        }
        if (unitIndex == TIME_SPAN_UNITS) {
            // didn't match any abbreviation, so assume the lowest unit we display
            for (unitIndex = TIME_SPAN_UNITS; unitIndex >= 0; unitIndex--) {
                if (_flags.displayUnits & (1 << unitIndex)) {
                    float existingValue = timeSpanUnits[unitIndex].spanGetImplementation(timeSpan, NULL);
                    timeSpanUnits[unitIndex].spanSetImplementation(timeSpan, NULL, number + existingValue);
                    break;
                }
            }
	}
        gotAnythingValid = YES;

        // eat anything remaining since we might be parsing long forms... Yes... this sucks. (ryan)
        [scanner scanCharactersFromSet:letterCharacterSet intoString:NULL];
    }

    if (_flags.returnNumber) {
        *obj = [NSDecimalNumber numberWithFloat:[timeSpan floatValue]];
        [timeSpan release];
    } else 
        *obj = [timeSpan autorelease];
    return YES;
}

@end
