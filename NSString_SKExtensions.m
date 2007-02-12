//
//  NSString_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 12/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSString_SKExtensions.h"
#import <Carbon/Carbon.h>


#pragma mark CFString extensions

#define STACK_BUFFER_SIZE 256

static inline
BOOL __SKCharacterIsWhitespaceOrNewline(UniChar c)
{
    static CFCharacterSetRef csref = NULL;
    if(csref == NULL)
        csref = CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline);
    // minor optimization: check for an ASCII character, since those are most common in TeX
    return ( (c <= 0x007E && c >= 0x0021) ? NO : CFCharacterSetIsCharacterMember(csref, c) );
}

static inline
Boolean __SKStringContainsWhitespaceOrNewline(CFStringRef string, CFIndex length)
{
    const UniChar *ptr = CFStringGetCharactersPtr(string);
    if(ptr != NULL){
        while(length--)
            if(__SKCharacterIsWhitespaceOrNewline(ptr[length]))
                return TRUE;
    } else {
        CFStringInlineBuffer inlineBuffer;
        CFStringInitInlineBuffer(string, &inlineBuffer, CFRangeMake(0, length));
        
        while(length--)
            if(__SKCharacterIsWhitespaceOrNewline(CFStringGetCharacterFromInlineBuffer(&inlineBuffer, length)))
                return TRUE;
    }

    return FALSE;
}

static inline
CFStringRef __SKStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef aString)
{
    
    CFIndex length = CFStringGetLength(aString);
    
    if(length == 0)
        return CFRetain(CFSTR(""));
    
    // improves efficiency somewhat when adding autocomplete strings, since we can completely avoid allocation
    if(__SKStringContainsWhitespaceOrNewline(aString, length) == FALSE)
        return CFRetain(aString);
    
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
        if(!__SKCharacterIsWhitespaceOrNewline(ch)){
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

- (NSString *)fastStringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines;
{
    return [(id)SKStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorGetDefault(), (CFStringRef)self) autorelease];
}

@end
