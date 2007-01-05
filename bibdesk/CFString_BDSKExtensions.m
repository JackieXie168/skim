//
//  CFString_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 01/02/06.
/*
 This software is Copyright (c) 2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "CFString_BDSKExtensions.h"
#import <OmniFoundation/OFPreference.h>

// This object is a cache for our stop words, so we don't have to hit user defaults every time __BDDeleteArticlesForSorting() is called (which is fairly often).  Alternately, we could require users to quit/relaunch after changing the stop words in prefs, but that's not too nice.  Anyway, it's private to CFString functions.

@interface BDSKStopWordController : NSObject 
{
    CFArrayRef stopWords;
}

+ (id)sharedController;
- (CFArrayRef)stopWords;
- (void)handleStopWordsChangedNotification:(NSNotification *)note;

static inline CFArrayRef BDSKStopwordsFromController(BDSKStopWordController *controller);

@end

@implementation BDSKStopWordController

static id sharedController = nil;

+ (id)sharedController;
{
    if(sharedController == nil)
        sharedController = [[self alloc] init];
    return sharedController;
}

- (id)init;
{
    if(self = [super init]){
        [OFPreference addObserver:self selector:@selector(handleStopWordsChangedNotification:) forPreference:[OFPreference preferenceForKey:BDSKIgnoredSortTermsKey]];
        stopWords = CFPreferencesCopyAppValue((CFStringRef)BDSKIgnoredSortTermsKey, kCFPreferencesCurrentApplication);
    }
    return self;
}

- (CFArrayRef)stopWords;
{
    return stopWords;
}

- (void)handleStopWordsChangedNotification:(NSNotification *)note;
{
    if(stopWords) CFRelease(stopWords);
    stopWords = CFPreferencesCopyAppValue((CFStringRef)BDSKIgnoredSortTermsKey, kCFPreferencesCurrentApplication);
}

- (void)dealloc;
{
    [OFPreference removeObserver:self forPreference:nil];
    if(stopWords) CFRelease(stopWords);
    [super dealloc];
}

static inline CFArrayRef BDSKStopwordsFromController(BDSKStopWordController *controller)
{
    return controller->stopWords;
}


@end

#pragma mark -

#define STACK_BUFFER_SIZE 256

static inline
BOOL __BDCharacterIsWhitespace(UniChar c)
{
    static CFCharacterSetRef csref = NULL;
    if(csref == NULL)
        csref = CFCharacterSetGetPredefined(kCFCharacterSetWhitespace);
    // minor optimization: check for an ASCII character, since those are most common in TeX
    return ( (c <= 0x007E && c >= 0x0021) ? NO : CFCharacterSetIsCharacterMember(csref, c) );
}

static inline
Boolean __BDStringContainsWhitespace(CFStringRef string, CFIndex length)
{
    const UniChar *ptr = CFStringGetCharactersPtr(string);
    if(ptr != NULL){
        while(length--)
            if(__BDCharacterIsWhitespace(ptr[length]))
                return TRUE;
    } else {
        CFStringInlineBuffer inlineBuffer;
        CFStringInitInlineBuffer(string, &inlineBuffer, CFRangeMake(0, length));
        
        while(length--)
            if(__BDCharacterIsWhitespace(CFStringGetCharacterFromInlineBuffer(&inlineBuffer, length)))
                return TRUE;
    }

    return FALSE;
}

static inline
CFStringRef __BDStringCreateByCollapsingAndTrimmingWhitespace(CFAllocatorRef allocator, CFStringRef aString)
{
    
    CFIndex length = CFStringGetLength(aString);
    
    if(length == 0)
        return CFRetain(CFSTR(""));
    
    // improves efficiency somewhat when adding autocomplete strings, since we can completely avoid allocation
    if(__BDStringContainsWhitespace(aString, length) == FALSE)
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
        buffer = (UniChar *)CFAllocatorAllocate(allocator, (length + 1) * sizeof(UniChar), 0);
    } else {
        buffer = stackBuffer;
    }
    
    NSCAssert1(buffer != NULL, @"failed to allocate memory for string of length %d", length);
    
    BOOL isFirst = NO;
    int bufCnt = 0;
    for(cnt = 0; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(!__BDCharacterIsWhitespace(ch)){
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

static inline
BOOL __BDCharacterIsWhitespaceOrNewline(UniChar c)
{
    static CFCharacterSetRef csref = NULL;
    if(csref == NULL)
        csref = CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline);
    // minor optimization: check for an ASCII character, since those are most common in TeX
    return ( (c <= 0x007E && c >= 0x0021) ? NO : CFCharacterSetIsCharacterMember(csref, c) );
}

static inline
Boolean __BDStringContainsWhitespaceOrNewline(CFStringRef string, CFIndex length)
{
    const UniChar *ptr = CFStringGetCharactersPtr(string);
    if(ptr != NULL){
        while(length--)
            if(__BDCharacterIsWhitespaceOrNewline(ptr[length]))
                return TRUE;
    } else {
        CFStringInlineBuffer inlineBuffer;
        CFStringInitInlineBuffer(string, &inlineBuffer, CFRangeMake(0, length));
        
        while(length--)
            if(__BDCharacterIsWhitespaceOrNewline(CFStringGetCharacterFromInlineBuffer(&inlineBuffer, length)))
                return TRUE;
    }

    return FALSE;
}

static inline
CFStringRef __BDStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef aString)
{
    
    CFIndex length = CFStringGetLength(aString);
    
    if(length == 0)
        return CFRetain(CFSTR(""));
    
    // improves efficiency somewhat when adding autocomplete strings, since we can completely avoid allocation
    if(__BDStringContainsWhitespaceOrNewline(aString, length) == FALSE)
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
        if(!__BDCharacterIsWhitespaceOrNewline(ch)){
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

static inline Boolean
__BDShouldRemoveUniChar(UniChar c){ return (c == '{' || c == '`' || c == '$' || c == '\\' || c == '('); }

// private function for removing some tex special characters from a string
// (only those I consider relevant to sorting)
static inline
void __BDDeleteTeXCharactersForSorting(CFMutableStringRef texString)
{
    if(BDIsEmptyString(texString))
        return;
    
    CFAllocatorRef allocator = CFGetAllocator(texString);

    CFStringInlineBuffer inlineBuffer;
    CFIndex length = CFStringGetLength(texString);
    CFIndex cnt = 0;
    
    // create an immutable copy to use with the inline buffer
    CFStringRef myCopy = CFStringCreateCopy(allocator, texString);
    CFStringInitInlineBuffer(myCopy, &inlineBuffer, CFRangeMake(0, length));
    UniChar ch;
    
    // delete the {`$\\( characters, since they're irrelevant to sorting, and typically
    // appear at the beginning of a word
    CFIndex delCnt = 0;
    while(cnt < length){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(__BDShouldRemoveUniChar(ch)){
            // remove from the mutable string; we have to keep track of our index in the copy and the original
            CFStringDelete(texString, CFRangeMake(delCnt, 1));
        } else {
            delCnt++;
        }
        cnt++;
    }
    CFRelease(myCopy); // dispose of our temporary copy
}

static inline
void __BDDeleteArticlesForSorting(CFMutableStringRef mutableString)
{
    if(mutableString == nil)
        return;
    // remove certain terms for sorting, according to preferences
    // each one is typically an article, and we only look
    // for these at the beginning of a string   
    CFArrayRef articlesToRemove = BDSKStopwordsFromController([BDSKStopWordController sharedController]);
    
    CFIndex count = CFArrayGetCount(articlesToRemove);
    if(!count) return;
    
    // get the max string length of any of the strings in the plist; we don't want to search any farther than necessary
    CFIndex maxRemoveLength = 0; 
    CFIndex index = count;
    while(index--)
        maxRemoveLength = MAX(CFStringGetLength(CFArrayGetValueAtIndex(articlesToRemove, index)), maxRemoveLength);
    
    index = count;
    CFRange articleRange;
    Boolean found;
    CFIndex length;

    while(index--){
        length = CFStringGetLength(mutableString);
        found = CFStringFindWithOptions(mutableString, CFArrayGetValueAtIndex(articlesToRemove, index), CFRangeMake(0, MIN(length, maxRemoveLength)), 0, &articleRange);
        
        // make sure the next character is whitespace before deleting, after checking bounds
        if(found && length > articleRange.length && 
           __BDCharacterIsWhitespace(CFStringGetCharacterAtIndex(mutableString, articleRange.length++)))
            CFStringDelete(mutableString, articleRange);
    }        
}

static inline
void __BDDeleteTeXCommandsForSorting(CFMutableStringRef mutableString)
{
    // this will go into an endless loop if the string is nil, but /only/ if the function is declared inline
    if(mutableString == nil)
        return;
    
    NSRange searchRange = NSMakeRange(0, CFStringGetLength(mutableString));
    NSRange cmdRange;
    unsigned startLoc;
        
    // This will find and remove the commands such as \textit{some word} that can confuse the sort order;
    // unfortunately, we can't remove things like {\textit some word}, since it could also be something
    // like {\LaTeX is great}, so this is a compromise
    while( (cmdRange = [(NSMutableString *)mutableString rangeOfTeXCommandInRange:searchRange]).location != NSNotFound){
        // delete the command
        [(NSMutableString *)mutableString deleteCharactersInRange:cmdRange];
        startLoc = cmdRange.location;
        searchRange.location = startLoc;
        searchRange.length = [(NSMutableString *)mutableString length] - startLoc;
    }
}

static inline
uint32_t __BDFastHash(CFStringRef aString)
{
    
    // Golden ratio - arbitrary start value to avoid mapping all 0's to all 0's
    // or anything like that.
    unsigned PHI = 0x9e3779b9U;
    
    // Paul Hsieh's SuperFastHash
    // http://www.azillionmonkeys.com/qed/hash.html
    // Implementation from Apple's WebCore/khtml/xml/dom_stringimpl.cpp, designed
    // to hash UTF-16 characters.
    
    unsigned l = CFStringGetLength(aString);
    uint32_t fastHash = PHI;
    uint32_t tmp;
    
    const UniChar *s = CFStringGetCharactersPtr(aString);
    UniChar *buf = NULL, stackBuffer[STACK_BUFFER_SIZE];
    CFAllocatorRef allocator = NULL;
    
    if(s == NULL){
        
        if(l > STACK_BUFFER_SIZE){
            allocator = CFGetAllocator(aString);
            buf = (UniChar *)CFAllocatorAllocate(allocator, l * sizeof(UniChar), 0);;
            NSCAssert(buf != NULL, @"unable to allocate memory");
        } else {
            buf = stackBuffer;
        }
        CFStringGetCharacters(aString, CFRangeMake(0, l), buf);
        s = buf;
    }
    
    int rem = l & 1;
    l >>= 1;
    
    // Main loop
    for (; l > 0; l--) {
        fastHash += s[0];
        tmp = (s[1] << 11) ^ fastHash;
        fastHash = (fastHash << 16) ^ tmp;
        s += 2;
        fastHash += fastHash >> 11;
    }
    
    // Handle end case
    if (rem) {
        fastHash += s[0];
        fastHash ^= fastHash << 11;
        fastHash += fastHash >> 17;
    }
    
    if(buf != stackBuffer) CFAllocatorDeallocate(allocator, buf);
    
    // Force "avalanching" of final 127 bits
    fastHash ^= fastHash << 3;
    fastHash += fastHash >> 5;
    fastHash ^= fastHash << 2;
    fastHash += fastHash >> 15;
    fastHash ^= fastHash << 10;
    
    // this avoids ever returning a hash code of 0, since that is used to
    // signal "hash not computed yet", using a value that is likely to be
    // effectively the same as 0 when the low bits are masked
    if (fastHash == 0)
        fastHash = 0x80000000;
    
    return fastHash;
}

static inline
CFStringRef __BDStringCreateByNormalizingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef aString)
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
        
    if(length >= STACK_BUFFER_SIZE) {
        buffer = (UniChar *)CFAllocatorAllocate(allocator, (length + 1) * sizeof(UniChar), 0);
    } else {
        buffer = stackBuffer;
    }
    
    NSCAssert1(buffer != NULL, @"failed to allocate memory for string of length %d", length);
    
    int bufCnt = 0;
    BOOL ignoreNextNewline = NO;
    
    for(cnt = 0; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(__BDCharacterIsWhitespace(ch)){
            ignoreNextNewline = NO;
            buffer[bufCnt++] = ' '; // replace with a single space
        } else if(BDIsNewlineCharacter(ch)){
            if(!ignoreNextNewline){      // we can have \r\n, which should appear as a single \n
                buffer[bufCnt++] = '\n'; // any newline would work here
                ignoreNextNewline = YES;
            }
        } else { 
            ignoreNextNewline = NO;
            buffer[bufCnt++] = ch;
        }
    }
    
    retStr = CFStringCreateWithCharacters(allocator, buffer, bufCnt);
    if(buffer != stackBuffer) CFAllocatorDeallocate(allocator, buffer);
    return retStr;
}

static inline void
__BDDeleteCharactersInCharacterSet(CFMutableStringRef theString, CFCharacterSetRef charSet)
{    
    CFStringInlineBuffer inlineBuffer;
    CFIndex length = CFStringGetLength(theString);
    CFIndex cnt = 0;
    
    // create an immutable copy to use with the inline buffer
    CFStringRef myCopy = CFStringCreateCopy(kCFAllocatorDefault, theString);
    CFStringInitInlineBuffer(myCopy, &inlineBuffer, CFRangeMake(0, length));
    UniChar ch;
    
    CFIndex delCnt = 0;
    while(cnt < length){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(CFCharacterSetIsCharacterMember(charSet, ch)){
            // remove from the mutable string; we have to keep track of our index in the copy and the original
            CFStringDelete(theString, CFRangeMake(delCnt, 1));
        } else {
            delCnt++;
        }
        cnt++;
    }
    CFRelease(myCopy); // dispose of our temporary copy
}

/* This is very similar to CFStringTrimWhitespace from CF-368.1.  It takes a buffer of unichars, and removes the whitespace characters from each end, then returns the contents in the original buffer (the pointer is unchanged).  The length returned is the new length, and the length passed is the buffer length. */
static inline CFIndex __BDCharactersTrimmingWhitespace(UniChar *chars, CFIndex length)
{
    CFIndex newStartIndex = 0;
    CFIndex buffer_idx = 0;
    
    while (buffer_idx < length && __BDCharacterIsWhitespace(chars[buffer_idx]))
        buffer_idx++;
    newStartIndex = buffer_idx;
    
    if (newStartIndex < length) {
        
        buffer_idx = length - 1;
        while (0 <= buffer_idx && __BDCharacterIsWhitespace(chars[buffer_idx]))
            buffer_idx--;
        length = buffer_idx - newStartIndex + 1;
        
        // @@ CFStringTrimWhitespace uses memmove(chars, chars + newStartIndex * sizeof(UniChar), length * sizeof(UniChar)), but that doesn't work in my testing here.
        memmove(chars, chars + newStartIndex, length * sizeof(UniChar));        
    } else {
        // whitespace only
        length = 0;
    }
    
    return length;
}

#pragma mark API

// Copied from CFString.c (CF368.25) with the addition of a single parameter for specifying comparison options (e.g. case-insensitive).
CFArrayRef BDStringCreateArrayBySeparatingStringsWithOptions(CFAllocatorRef allocator, CFStringRef string, CFStringRef separatorString, CFOptionFlags compareOptions)
{
    CFArrayRef separatorRanges;
    CFIndex length = CFStringGetLength(string);

    if (!(separatorRanges = CFStringCreateArrayWithFindResults(allocator, string, separatorString, CFRangeMake(0, length), compareOptions))) {
        return CFArrayCreate(allocator, (const void**)&string, 1, & kCFTypeArrayCallBacks);
    } else {
        CFIndex idx;
        CFIndex count = CFArrayGetCount(separatorRanges);
        CFIndex startIndex = 0;
        CFIndex numChars;
        CFMutableArrayRef array = CFArrayCreateMutable(allocator, count + 2, & kCFTypeArrayCallBacks);
        const CFRange *currentRange;
        CFStringRef substring;
        
        for (idx = 0;idx < count;idx++) {
            currentRange = CFArrayGetValueAtIndex(separatorRanges, idx);
            numChars = currentRange->location - startIndex;
            substring = CFStringCreateWithSubstring(allocator, string, CFRangeMake(startIndex, numChars));
            CFArrayAppendValue(array, substring);
            CFRelease(substring);
            startIndex = currentRange->location + currentRange->length;
        }
        substring = CFStringCreateWithSubstring(allocator, string, CFRangeMake(startIndex, length - startIndex));
        CFArrayAppendValue(array, substring);
        CFRelease(substring);
        
        CFRelease(separatorRanges);
        
        return array;
    }
}

CFArrayRef BDStringCreateComponentsSeparatedByCharacterSetTrimWhitespace(CFAllocatorRef allocator, CFStringRef string, CFCharacterSetRef charSet, Boolean trim)
{
    
    CFIndex length = CFStringGetLength(string);
    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer(string, &inlineBuffer, CFRangeMake(0, length));
    
    if(allocator == NULL) allocator = CFAllocatorGetDefault();
    CFMutableArrayRef array = CFArrayCreateMutable(allocator, 0, &kCFTypeArrayCallBacks);
    CFIndex cnt;
    UniChar ch;
    
    // full length of string has to be large enough for the buffer
    UniChar *buffer, stackBuffer[STACK_BUFFER_SIZE];
    if(length >= STACK_BUFFER_SIZE) {
        buffer = (UniChar *)CFAllocatorAllocate(allocator, length * sizeof(UniChar), 0);
    } else {
        buffer = stackBuffer;
    }
    
    NSCAssert1(buffer != NULL, @"Unable to allocate buffer for %@", string);
    CFIndex bufCnt = 0;
    CFStringRef component;
    
    // scan characters into a buffer; when a character from the charSet is reached, stop and create a string
    for(cnt = 0; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(CFCharacterSetIsCharacterMember(charSet, ch) == FALSE){
            buffer[bufCnt++] = ch;
        } else {
            if(bufCnt){
                if(trim) bufCnt = __BDCharactersTrimmingWhitespace(buffer, bufCnt);
                component = CFStringCreateWithCharacters(allocator, buffer, bufCnt);
                CFArrayAppendValue(array, component);
                CFRelease(component);
                bufCnt = 0;
            }
        }
    }
    
    // get the final component from the buffer and create a string
    if(bufCnt){
        if(trim) bufCnt = __BDCharactersTrimmingWhitespace(buffer, bufCnt);
        component = CFStringCreateWithCharacters(allocator, buffer, (bufCnt));
        CFArrayAppendValue(array, component);
        CFRelease(component);
    }
    
    if(buffer != stackBuffer) CFAllocatorDeallocate(allocator, buffer);
    
    return array;
}

CFHashCode BDCaseInsensitiveStringHash(const void *value)
{
    if(value == NULL) return 0;
    
    CFAllocatorRef allocator = CFGetAllocator(value);
    CFIndex len = CFStringGetLength(value);
    
    // use a generous length, in case the lowercase changes the number of characters
    UniChar *buffer, stackBuffer[STACK_BUFFER_SIZE];
    if(len + 10 >= STACK_BUFFER_SIZE) {
        buffer = (UniChar *)CFAllocatorAllocate(allocator, (len + 10) * sizeof(UniChar), 0);
    } else {
        buffer = stackBuffer;
    }
    CFStringGetCharacters(value, CFRangeMake(0, len), buffer);
    
    // If we create the string with external characters, CFStringGetCharactersPtr is guaranteed to succeed; since we're going to call CFStringGetCharacters anyway in fastHash if CFStringGetCharactsPtr fails, let's do it now when we lowercase the string
    CFMutableStringRef mutableString = CFStringCreateMutableWithExternalCharactersNoCopy(allocator, buffer, len, len + 10, (buffer != stackBuffer ? allocator : kCFAllocatorNull));
    CFStringLowercase(mutableString, NULL);
    uint32_t hash = __BDFastHash(mutableString);
    
    // if we used the allocator, this should free the buffer for us
    CFRelease(mutableString);
    return hash;
}
    

CFStringRef BDStringCreateByCollapsingAndTrimmingWhitespace(CFAllocatorRef allocator, CFStringRef string){ return __BDStringCreateByCollapsingAndTrimmingWhitespace(allocator, string); }
CFStringRef BDStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef string){ return __BDStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(allocator, string); }
CFStringRef BDStringCreateByNormalizingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef string){ return __BDStringCreateByNormalizingWhitespaceAndNewlines(allocator, string); }

// useful when you want the range of a single character without messing with character sets, or just to know if a character exists in a string (pass NULL for resultRange if you don't care where the result is located)
Boolean BDStringFindCharacter(CFStringRef string, UniChar character, CFRange searchRange, CFRange *resultRange)
{
    if(CFStringGetLength(string) == 0) return FALSE;
    CFStringInlineBuffer inlineBuffer;
    
    CFStringInitInlineBuffer(string, &inlineBuffer, searchRange);
    CFIndex cnt = 0;
    
    do {
        if(CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt) == character){
            if(resultRange != NULL){
                resultRange->location = searchRange.location + cnt;
                resultRange->length = 1;
            }
            return TRUE;
        }
    } while(++cnt < searchRange.length);
    
    return FALSE;
}

#pragma mark Mutable Strings

void BDDeleteTeXForSorting(CFMutableStringRef mutableString){ 
    __BDDeleteTeXCommandsForSorting(mutableString); 
    // get rid of braces and such...
    __BDDeleteTeXCharactersForSorting(mutableString);
}
void BDDeleteArticlesForSorting(CFMutableStringRef mutableString){ __BDDeleteArticlesForSorting(mutableString); }
void BDDeleteCharactersInCharacterSet(CFMutableStringRef mutableString, CFCharacterSetRef charSet){
    __BDDeleteCharactersInCharacterSet(mutableString, charSet);
}
