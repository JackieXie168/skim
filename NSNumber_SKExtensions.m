//
//  NSNumber_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 6/12/08.
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

#import "NSNumber_SKExtensions.h"

#define ALPHA_CHARACTER (unichar)0x03b1

@implementation NSNumber (SKExtensions)

#pragma mark Templating support

- (NSNumber *)numberByAddingOne {
    return [NSNumber numberWithInteger:[self integerValue] + 1];
}

- (NSNumber *)numberBySubstractingOne {
    return [NSNumber numberWithInteger:[self integerValue] - 1];
}

inline static NSString *romanNumeralForDigit(NSUInteger digit, NSString *i, NSString *v, NSString *x) {
    switch (digit) {
        case 1: return i;
        case 2: return [NSString stringWithFormat:@"%@%@", i, i];
        case 3: return [NSString stringWithFormat:@"%@%@%@", i, i, i];
        case 4: return [NSString stringWithFormat:@"%@%@", i, v];
        case 5: return v;
        case 6: return [NSString stringWithFormat:@"%@%@", v, i];
        case 7: return [NSString stringWithFormat:@"%@%@%@", v, i, i];
        case 8: return [NSString stringWithFormat:@"%@%@%@%@", v, i, i, i];
        case 9: return [NSString stringWithFormat:@"%@%@", i, x];
        default: return @"";
    }
}

- (NSString *)romanNumeralValue{
    static NSString *symbols[9] = {@"i", @"v", @"x", @"l", @"c", @"d", @"m", @"mmm", @""};
    
    NSMutableString *string = [NSMutableString string];
    NSUInteger digit, offset, number = [self unsignedIntegerValue];
    
    if (number >= 5000)
        [NSException raise:@"Roman Numeral Exception" format:@"The number %lu is too big to represent as a roman numeral.", (unsigned long)number];
    
    for (offset = 0; number > 0 && offset < 7; offset += 2) {
        digit = number % 10;
        number /= 10;
        [string insertString:romanNumeralForDigit(digit, symbols[offset], symbols[offset + 1], symbols[offset + 2]) atIndex:0];
    }
    return string;
}

- (NSString *)alphaCounterValue{
    NSMutableString *string = [NSMutableString string];
    NSUInteger letter, number = [self unsignedIntegerValue];
    
    if (number > 0) {
        letter = (number - 1) % 26;
        number = ((number - 1) / 26) + 1;
        while (number-- > 0)
            [string appendFormat:@"%C", 'a' + letter];
    }
    return string;
}

- (NSString *)greekCounterValue{
    NSMutableString *string = [NSMutableString string];
    NSUInteger letter, number = [self unsignedIntegerValue];
    
    if (number > 0) {
        letter = (number - 1) % 24;
        if (letter > 16)
            letter++;
        number = ((number - 1) / 24) + 1;
        while (number-- > 0)
            [string appendFormat:@"%C", ALPHA_CHARACTER + letter];
    }
    return string;
}

@end
