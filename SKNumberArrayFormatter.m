//
//  SKNumberArrayFormatter.m
//  Skim
//
//  Created by Christiaan Hofman on 6/5/08.
/*
 This software is Copyright (c) 2008-2014
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

#import "SKNumberArrayFormatter.h"


@implementation SKNumberArrayFormatter

- (void)commonInit {
    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setFormat:@"0;0;-0"];
    [numberFormatter setMinimum:[NSNumber numberWithDouble:0.0]];
}

 - (id)init {
    self = [super init];
    if (self)
        [self commonInit];
    return self;
 }

 - (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self)
        [self commonInit];
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SKNumberArrayFormatter *copy = [super copyWithZone:zone];
    copy->numberFormatter = [numberFormatter copyWithZone:zone];
    return copy;
}

- (void)dealloc {
    SKDESTROY(numberFormatter);
    [super dealloc];
}
 
- (NSString *)stringForObjectValue:(id)obj {
    if ([obj isKindOfClass:[NSString class]])
        obj = [NSArray array];
    if ([obj isKindOfClass:[NSNumber class]])
        obj = [NSArray arrayWithObjects:obj, nil];
    
    NSMutableString *string = [NSMutableString string];
    
    for (NSNumber *number in obj) {
        NSString *s = [numberFormatter stringForObjectValue:number];
        if ([s length]) {
            if ([string length])
                [string appendString:@" "];
            [string appendString:s];
        }
    }
    return string;
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error {
    NSNumber *number;
    NSMutableArray *array = [NSMutableArray array];
    BOOL success = YES;
    
    for (NSString *s in [string componentsSeparatedByString:@" "]) {
        if ([s length] && (success = [numberFormatter getObjectValue:&number forString:s errorDescription:error]))
            [array addObject:number];
        if (success == NO) break;
    }
    if (success)
        *obj = array;
    return success;
}

@end
