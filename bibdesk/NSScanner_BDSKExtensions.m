//
//  NSScanner_BDSKExtensions.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/23/06.
/*
 This software is Copyright (c) 2006
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

#import "NSScanner_BDSKExtensions.h"


@implementation NSScanner (BDSKExtensions)

- (BOOL)scanUnsignedInt:(unsigned int *)unsignedValue{
    unsigned rewindLocation = [self scanLocation];
    int intValue = 0;
    BOOL returnValue = [self scanInt:&intValue];
    if (returnValue && intValue < 0) {
        [self setScanLocation:rewindLocation];
        returnValue = NO;
    }
    if (returnValue && unsignedValue != NULL)
        *unsignedValue = intValue;
    return returnValue;
}

- (BOOL)scanCharacter:(unichar *)ch {
    if ([self isAtEnd])
        return NO;
    int location = [self scanLocation];
    if (ch != NULL)
        *ch = [[self string] characterAtIndex:location];
    [self setScanLocation:location + 1];
    return YES;
}

- (BOOL)peekCharacter:(unichar *)ch {
    if ([self isAtEnd])
        return NO;
    if (ch != NULL)
        *ch = [[self string] characterAtIndex:[self scanLocation]];
    return YES;
}

// parses an AppleScript type value, including surrounding whitespace. A value can be:
// "-quoted string (with escapes),  explicit number, list of the form {item,...}, record of the form {key:value,...}, boolean constant, unquoted string (no escapes)
- (BOOL)scanAppleScriptValueUpToCharactersInSet:stopSet intoObject:(id *)object {
    static NSCharacterSet *numberChars = nil;
    static NSCharacterSet *specialStringChars = nil;
    static NSCharacterSet *listSeparatorChars = nil;
    
    if (numberChars == nil) {
        numberChars = [[NSCharacterSet characterSetWithCharactersInString:@"-.0123456789"] retain];
        specialStringChars = [[NSCharacterSet characterSetWithCharactersInString:@"\\\""] retain];
        listSeparatorChars = [[NSCharacterSet characterSetWithCharactersInString:@"},:"] retain];
    }
    
    unichar ch = 0;
    id tmpObject = nil;
    
    [self scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
    
    if ([self peekCharacter:&ch] == NO)
        return NO;
    if (ch == '"') {
        // quoted string, look for escaped characters or closing double-quote
        [self setScanLocation:[self scanLocation] + 1];
        NSMutableString *tmpString = [NSMutableString string];
        NSString *s = nil;
        while ([self isAtEnd] == NO) {
            if ([self scanUpToCharactersFromSet:specialStringChars intoString:&s])
                [tmpString appendString:s];
            if ([self scanCharacter:&ch] == NO)
                [NSException raise:NSInternalInconsistencyException format:@"Missing \""];
            if (ch == '\\') {
                if ([self scanCharacter:&ch] == NO)
                    [NSException raise:NSInternalInconsistencyException format:@"Missing character"];
                if (ch == 'n')
                    [tmpString appendString:@"\n"];
                else if (ch == 'r')
                    [tmpString appendString:@"\r"];
                else if (ch == 't')
                    [tmpString appendString:@"\t"];
                else if (ch == '"')
                    [tmpString appendString:@"\""];
                else if (ch == '\\')
                    [tmpString appendString:@"\\"];
                else // or should we raise an exception?
                    [tmpString appendFormat:@"%C", ch];
            } else if (ch == '"') {
                [tmpString removeSurroundingWhitespace];
                tmpObject = tmpString;
                break;
            }
        }
    } else if ([numberChars characterIsMember:ch]) {
        // explicit number, should we check for integers?
        float tmpFloat = 0;
        if ([self scanFloat:&tmpFloat])
            tmpObject = [NSNumber numberWithFloat:tmpFloat];
    } else if (ch == '{') {
        // list or record, comma-separated items, possibly with keys
        // look for item and then a separator or closing brace
        [self setScanLocation:[self scanLocation] + 1];
        NSMutableArray *tmpArray = [NSMutableArray array];
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
        BOOL isDict = NO;
        id tmpValue = nil;
        NSString *tmpKey = nil;
        while ([self isAtEnd] == NO) {
            // look for a key or value
            [self scanAppleScriptValueUpToCharactersInSet:listSeparatorChars intoObject:&tmpValue];
            if ([self scanCharacter:&ch] == NO)
                [NSException raise:NSInternalInconsistencyException format:@"Missing }"];
            if (ch == ':') {
                // we just found a key, so we have a record
                isDict = YES;
                tmpKey = tmpValue;
                tmpValue = nil;
            } else if (ch == ',') {
                // item separator, add it to the array or dictionary
                if (isDict)
                    [tmpDict setObject:tmpValue forKey:tmpKey];
                else
                    [tmpArray addObject:tmpValue];
                tmpValue = nil;
                tmpKey = nil;
            } else if (ch == '}') {
                // matching closing brace of the list or record argument, we can add the array or dictionary
                if (isDict) {
                    if (tmpValue)
                        [tmpDict setObject:tmpValue forKey:tmpKey];
                    tmpObject = tmpDict;
                } else {
                    if (tmpValue)
                        [tmpArray addObject:tmpValue];
                    tmpObject = tmpArray;
                }
                break;
            }
        }
    } else if ([self scanString:@"true" intoString:NULL] || [self scanString:@"yes" intoString:NULL]) {
        // boolean
        tmpObject = [NSNumber numberWithBool:YES];
    } else if ([self scanString:@"false" intoString:NULL] || [self scanString:@"no" intoString:NULL]) {
        // boolean
        tmpObject = [NSNumber numberWithBool:NO];
    } else { // or should we raise an exception?
        // unquoted string, just scan up to the next character in the stopset
        NSString *s = nil;
        if ([self scanUpToCharactersFromSet:stopSet intoString:&s])
            tmpObject = [s stringByRemovingSurroundingWhitespace];
    }
    [self scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
    if (object != NULL)
        *object = tmpObject;
    return nil != tmpObject;
}

@end
