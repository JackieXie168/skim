//
//  NSScanner_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/22/07.
/*
 This software is Copyright (c) 2007-2020
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

#import "NSScanner_SKExtensions.h"
#import "NSCharacterSet_SKExtensions.h"


@implementation NSScanner (SKExtensions)

- (BOOL)scanCharacter:(unichar *)ch {
    NSInteger location, length = [[self string] length];
    unichar character = 0;
    BOOL success = NO;
    for (location = [self scanLocation]; success == NO && location < length; location++) {
        character = [[self string] characterAtIndex:location];
        success = [[self charactersToBeSkipped] characterIsMember:character] == NO;
    }
    if (success) {
        if (ch != 0)
            *ch = character;
        [self setScanLocation:location];
    }
    return success;
}

- (BOOL)peekCharacter:(unichar *)ch {
    NSInteger location, length = [[self string] length];
    unichar character = 0;
    BOOL success = NO;
    for (location = [self scanLocation]; success == NO && location < length; location++) {
        character = [[self string] characterAtIndex:location];
        success = [[self charactersToBeSkipped] characterIsMember:character] == NO;
    }
    if (success && ch != 0)
        *ch = character;
    return success;
}

@end
