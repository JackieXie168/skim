//
//  NSUserDefaults_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 5/19/08.
/*
 This software is Copyright (c) 2007-2014
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

#import "NSUserDefaults_SKExtensions.h"


@implementation NSUserDefaults (SKExtensions)

- (NSColor *)colorForKey:(NSString *)key {
    NSColor *color = nil;
    NSData *data = [self dataForKey:key];
    if (data) {
        color = [NSUnarchiver unarchiveObjectWithData:data];
    } else {
        NSArray *array = [self arrayForKey:key];
        if ([array count]) {
            CGFloat red, green, blue, alpha = 1.0;
            red = green = blue = [[array objectAtIndex:0] doubleValue];
            if ([array count] > 2) {
                green = [[array objectAtIndex:1] doubleValue];
                blue = [[array objectAtIndex:2] doubleValue];
            }
            if ([array count] == 2)
                alpha = [[array objectAtIndex:1] doubleValue];
            else if ([array count] > 3)
                alpha = [[array objectAtIndex:3] doubleValue];
            color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
        }
    }
    return color;
}

- (void)setColor:(NSColor *)color forKey:(NSString *)key {
    NSData *data = color ? [NSArchiver archivedDataWithRootObject:color] : nil;
    [self setObject:data forKey:key];
}

@end
