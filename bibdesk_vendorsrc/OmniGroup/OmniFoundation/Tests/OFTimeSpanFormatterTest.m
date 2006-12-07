// Copyright 2005 Omni Development, Inc. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFTimeSpanFormatter.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#import <SenTestingKit/SenTestingKit.h>

RCS_ID("$Header$");

@interface OFTimeSpanFormatterTest : SenTestCase
{
}

@end

@implementation OFTimeSpanFormatterTest

- (void)testDefaultFormatter;
{
    OFTimeSpanFormatter *formatter = [[OFTimeSpanFormatter alloc] init];
    NSNumber *timeSpan;
    NSString *timeSpanString = @"1y 1m 1w 1d 1h";
    NSString *expectedTimeSpanString = @"53w 1d 1h";
    
    should ([formatter getObjectValue:&timeSpan forString:timeSpanString errorDescription:nil]);
    should ([expectedTimeSpanString isEqualToString:[formatter stringForObjectValue:timeSpan]]);
    [formatter release];
}

- (void)testAllFormats;
{
    NSNumber *timeSpan;
    NSString *timeSpanString = @"1y 1m 1w 1d 1h";
    NSString *expectedTimeSpanString = @"1y 1m 1w 1d 1h";
    OFTimeSpanFormatter *formatter = [[OFTimeSpanFormatter alloc] init];

    [formatter setDisplayMonths:YES];
    [formatter setDisplayYears:YES];
    
    should ([formatter getObjectValue:&timeSpan forString:timeSpanString errorDescription:nil]);
    should ([expectedTimeSpanString isEqualToString:[formatter stringForObjectValue:timeSpan]]);
    [formatter release];
}

- (void)testNoFormats;
{
    NSNumber *timeSpan;
    NSString *timeSpanString = @"1y 1m 1w 1d 1h";
    NSString *expectedTimeSpanString = @"";
    OFTimeSpanFormatter *formatter = [[OFTimeSpanFormatter alloc] init];
    
    [formatter setDisplayHours:NO];
    [formatter setDisplayDays:NO];
    [formatter setDisplayWeeks:NO];
    [formatter setDisplayMonths:NO];
    [formatter setDisplayYears:NO];
    
    should ([formatter getObjectValue:&timeSpan forString:timeSpanString errorDescription:nil]);
    should ([expectedTimeSpanString isEqualToString:[formatter stringForObjectValue:timeSpan]]);
    [formatter release];
}


- (void)testNoYear;
{
    NSNumber *timeSpan;
    NSString *timeSpanString = @"1y 1m 1w 1d 1h";
    NSString *expectedTimeSpanString = @"13m 1w 1d 1h";
    OFTimeSpanFormatter *formatter = [[OFTimeSpanFormatter alloc] init];
    
    [formatter setDisplayHours:YES];
    [formatter setDisplayDays:YES];
    [formatter setDisplayWeeks:YES];
    [formatter setDisplayMonths:YES];
    [formatter setDisplayYears:NO];
    
    should ([formatter getObjectValue:&timeSpan forString:timeSpanString errorDescription:nil]);
    should ([expectedTimeSpanString isEqualToString:[formatter stringForObjectValue:timeSpan]]);
    [formatter release];
}

- (void)testNoMonth;
{
    NSNumber *timeSpan;
    NSString *timeSpanString = @"1y 1m 1w 1d 1h";
    NSString *expectedTimeSpanString = @"1y 5w 1d 1h";
    OFTimeSpanFormatter *formatter = [[OFTimeSpanFormatter alloc] init];
    
    [formatter setDisplayHours:YES];
    [formatter setDisplayDays:YES];
    [formatter setDisplayWeeks:YES];
    [formatter setDisplayMonths:NO];
    [formatter setDisplayYears:YES];
    
    should ([formatter getObjectValue:&timeSpan forString:timeSpanString errorDescription:nil]);
    should ([expectedTimeSpanString isEqualToString:[formatter stringForObjectValue:timeSpan]]);
    [formatter release];
}

- (void)testNoWeeks;
{
    NSNumber *timeSpan;
    NSString *timeSpanString = @"1y 1m 1w 1d 1h";
    NSString *expectedTimeSpanString = @"1y 1m 6d 1h";
    OFTimeSpanFormatter *formatter = [[OFTimeSpanFormatter alloc] init];
    
    [formatter setDisplayHours:YES];
    [formatter setDisplayDays:YES];
    [formatter setDisplayWeeks:NO];
    [formatter setDisplayMonths:YES];
    [formatter setDisplayYears:YES];
    
    should ([formatter getObjectValue:&timeSpan forString:timeSpanString errorDescription:nil]);
    should ([expectedTimeSpanString isEqualToString:[formatter stringForObjectValue:timeSpan]]);
    [formatter release];
}

- (void)testNoDays;
{
    NSNumber *timeSpan;
    NSString *timeSpanString = @"1y 1m 1w 1d 1h";
    NSString *expectedTimeSpanString = @"1y 1m 1w 9h";
    OFTimeSpanFormatter *formatter = [[OFTimeSpanFormatter alloc] init];
    
    [formatter setDisplayHours:YES];
    [formatter setDisplayDays:NO];
    [formatter setDisplayWeeks:YES];
    [formatter setDisplayMonths:YES];
    [formatter setDisplayYears:YES];
    
    should ([formatter getObjectValue:&timeSpan forString:timeSpanString errorDescription:nil]);
    should ([expectedTimeSpanString isEqualToString:[formatter stringForObjectValue:timeSpan]]);
    [formatter release];
}

- (void)testNoHours;
{
    NSNumber *timeSpan;
    NSString *timeSpanString = @"1y 1m 1w 1d 1h";
    NSString *expectedTimeSpanString = @"1y 1m 1w 1d";
    OFTimeSpanFormatter *formatter = [[OFTimeSpanFormatter alloc] init];
    
    [formatter setDisplayHours:NO];
    [formatter setDisplayDays:YES];
    [formatter setDisplayWeeks:YES];
    [formatter setDisplayMonths:YES];
    [formatter setDisplayYears:YES];
    
    should ([formatter getObjectValue:&timeSpan forString:timeSpanString errorDescription:nil]);
    should ([expectedTimeSpanString isEqualToString:[formatter stringForObjectValue:timeSpan]]);
    [formatter release];
}

@end

