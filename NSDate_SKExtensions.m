//
//  NSDate_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 14/06/2018.
/*
 This software is Copyright (c) 2018
 Christiaan Hofman. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Christiaan Hofman nor the names of any
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

#import "NSDate_SKExtensions.h"

@interface SKFormattedDate : NSDate {
    NSDate *date;
    NSDateFormatter *formatter;
}

- (id)initWithDate:(NSDate *)aDate;

@end

#pragma mark

@implementation NSDate (SKExtensions)

@dynamic fullDateFormat, longDateFormat, mediumDateFormat, shortDateFormat, fullTimeFormat, longTimeFormat, mediumTimeFormat, shortTimeFormat, standardDescription;

- (NSDate *)fullDateFormat {
    return [[[[SKFormattedDate alloc] initWithDate:self] autorelease] fullDateFormat];
}

- (NSDate *)longDateFormat {
    return [[[[SKFormattedDate alloc] initWithDate:self] autorelease] longDateFormat];
}

- (NSDate *)mediumDateFormat {
    return [[[[SKFormattedDate alloc] initWithDate:self] autorelease] mediumDateFormat];
}

- (NSDate *)shortDateFormat {
    return [[[[SKFormattedDate alloc] initWithDate:self] autorelease] shortDateFormat];
}

- (NSDate *)fullTimeFormat {
    return [[[[SKFormattedDate alloc] initWithDate:self] autorelease] fullTimeFormat];
}

- (NSDate *)longTimeFormat {
    return [[[[SKFormattedDate alloc] initWithDate:self] autorelease] longTimeFormat];
}

- (NSDate *)mediumTimeFormat {
    return [[[[SKFormattedDate alloc] initWithDate:self] autorelease] mediumTimeFormat];
}

- (NSDate *)shortTimeFormat {
    return [[[[SKFormattedDate alloc] initWithDate:self] autorelease] shortTimeFormat];
}

- (NSString *)standardDescription {
    // %Y-%m-%d %H:%M:%S %z
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
    }
    return [formatter stringFromDate:self];
}

@end

#pragma mark

@implementation SKFormattedDate

- (id)init {
    return [self initWithDate:[NSDate date]];
}

- (id)initWithDate:(NSDate *)aDate {
    if (date == nil) {
        [self release];
        return nil;
    }
    self = [super init];
    if (self) {
        date = [aDate retain];
        formatter = [[NSDateFormatter alloc] init];
        [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [formatter setDateStyle:NSDateFormatterNoStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
    }
    return self;
}

- (id)initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeInterval {
    return [self initWithDate:[[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:timeInterval
                ] autorelease]];
}

- (void)dealloc {
    SKDESTROY(date);
    SKDESTROY(formatter);
    [super dealloc];
}

- (NSString *)description {
    return [formatter stringFromDate:date];
}

- (NSTimeInterval)timeIntervalSinceReferenceDate {
    return [date timeIntervalSinceReferenceDate];
}

- (NSDate *)fullDateFormat {
    [formatter setDateStyle:NSDateFormatterFullStyle];
    return self;
}

- (NSDate *)longDateFormat {
    [formatter setDateStyle:NSDateFormatterLongStyle];
    return self;
}

- (NSDate *)mediumDateFormat {
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    return self;
}

- (NSDate *)shortDateFormat {
    [formatter setDateStyle:NSDateFormatterShortStyle];
    return self;
}

- (NSDate *)fullTimeFormat {
    [formatter setTimeStyle:NSDateFormatterFullStyle];
    return self;
}

- (NSDate *)longTimeFormat {
    [formatter setTimeStyle:NSDateFormatterLongStyle];
    return self;
}

- (NSDate *)mediumTimeFormat {
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    return self;
}

- (NSDate *)shortTimeFormat {
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    return self;
}

@end

