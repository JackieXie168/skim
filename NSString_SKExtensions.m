//
//  NSString_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/12/07.
/*
 This software is Copyright (c) 2007
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

#import "NSString_SKExtensions.h"
#import "NSScanner_SKExtensions.h"
#import "NSCharacterSet_SKExtensions.h"
#import <Carbon/Carbon.h>


#pragma mark CFString extensions

#define STACK_BUFFER_SIZE 256

static inline
CFStringRef __SKStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef aString)
{
    
    CFIndex length = CFStringGetLength(aString);
    
    if(length == 0)
        return CFRetain(CFSTR(""));
    
    // set up the buffer to fetch the characters
    CFIndex cnt = 0;
    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer(aString, &inlineBuffer, CFRangeMake(0, length));
    UniChar ch;
    UniChar *buffer, stackBuffer[STACK_BUFFER_SIZE];
    CFStringRef retStr;

    allocator = (allocator == NULL) ? CFGetAllocator(aString) : allocator;

    if(length >= STACK_BUFFER_SIZE) {
        buffer = (UniChar *)CFAllocatorAllocate(allocator, length * sizeof(UniChar), 0);
    } else {
        buffer = stackBuffer;
    }
    
    NSCAssert1(buffer != NULL, @"failed to allocate memory for string of length %d", length);
    
    BOOL isFirst = NO;
    int bufCnt = 0;
    for(cnt = 0; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(NO == CFCharacterSetIsCharacterMember(CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline), ch)){
            isFirst = YES;
            buffer[bufCnt++] = ch; // not whitespace, so we want to keep it
        } else {
            if(isFirst){
                buffer[bufCnt++] = ' '; // if it's the first whitespace, we add a single space
                isFirst = NO;
            }
        }
    }
    
    if(buffer[(bufCnt-1)] == ' ') // we've collapsed any trailing whitespace, so disregard it
        bufCnt--;
    
    retStr = CFStringCreateWithCharacters(allocator, buffer, bufCnt);
    if(buffer != stackBuffer) CFAllocatorDeallocate(allocator, buffer);
    return retStr;
}

CFStringRef SKStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef string){ return __SKStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(allocator, string); }

#pragma mark NSString category

@implementation NSString (SKExtensions)

- (NSString *)stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines;
{
    return [(id)SKStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorGetDefault(), (CFStringRef)self) autorelease];
}

- (NSString *)stringByAppendingEllipsis;
{
    return [self stringByAppendingFormat:@"%C", 0x2026];
}

// parses a space separated list of shell script argments
// allows quoting parts of an argument and escaped characters outside quotes, according to shell rules
- (NSArray *)shellScriptArgumentsArray;
{
    static NSCharacterSet *specialChars = nil;
    static NSCharacterSet *quoteChars = nil;
    
    if (specialChars == nil) {
        NSMutableCharacterSet *tmpSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
        [tmpSet addCharactersInString:@"\\\"'`"];
        specialChars = [tmpSet copy];
        [tmpSet release];
        quoteChars = [[NSCharacterSet characterSetWithCharactersInString:@"\"'`"] retain];
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:self];
    NSString *s = nil;
    unichar ch = 0;
    NSMutableString *currArg = [scanner isAtEnd] ? nil : [NSMutableString string];
    NSMutableArray *arguments = [NSMutableArray array];
    
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
    
    while ([scanner isAtEnd] == NO) {
        if ([scanner scanUpToCharactersFromSet:specialChars intoString:&s])
            [currArg appendString:s];
        if ([scanner scanCharacter:&ch] == NO)
            break;
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:ch]) {
            // argument separator, add the last one we found and ignore more whitespaces
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
            [arguments addObject:currArg];
            currArg = [scanner isAtEnd] ? nil : [NSMutableString string];
        } else if (ch == '\\') {
            // escaped character
            if ([scanner scanCharacter:&ch] == NO)
                [NSException raise:NSInternalInconsistencyException format:@"Missing character"];
            if ([currArg length] == 0 && [[NSCharacterSet newlineCharacterSet] characterIsMember:ch])
                // ignore escaped newlines between arguments, as they should be considered whitespace
                [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
            else // real escaped character, just add the character, so we can ignore it if it is a special character
                [currArg appendFormat:@"%C", ch];
        } else if ([quoteChars characterIsMember:ch]) {
            // quoted part of an argument, scan up to the matching quote
            if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithRange:NSMakeRange(ch, 1)] intoString:&s])
                [currArg appendString:s];
            if ([scanner scanCharacter:NULL] == NO)
                [NSException raise:NSInternalInconsistencyException format:@"Unmatched %C", ch];
        }
    }
    if (currArg)
        [arguments addObject:currArg];
    return arguments;
}

@end
