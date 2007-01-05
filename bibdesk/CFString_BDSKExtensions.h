//
//  CFString_BDSKExtensions.h
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
#import <Cocoa/Cocoa.h>

extern CFArrayRef BDStringCreateArrayBySeparatingStringsWithOptions(CFAllocatorRef allocator, CFStringRef string, CFStringRef separatorString, CFOptionFlags compareOptions);
extern CFStringRef BDStringCreateByCollapsingAndTrimmingWhitespace(CFAllocatorRef allocator, CFStringRef string);
extern CFStringRef BDStringCreateByCollapsingAndTrimmingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef string);
extern CFStringRef BDStringCreateByNormalizingWhitespaceAndNewlines(CFAllocatorRef allocator, CFStringRef string);
extern CFArrayRef BDStringCreateComponentsSeparatedByCharacterSetTrimWhitespace(CFAllocatorRef allocator, CFStringRef string, CFCharacterSetRef charSet, Boolean trim);
extern Boolean BDStringFindCharacter(CFStringRef string, UniChar character, CFRange searchRange, CFRange *resultRange);

extern void BDDeleteTeXForSorting(CFMutableStringRef mutableString);
extern void BDDeleteArticlesForSorting(CFMutableStringRef mutableString);
extern void BDDeleteCharactersInCharacterSet(CFMutableStringRef mutableString, CFCharacterSetRef charSet);
extern CFHashCode BDCaseInsensitiveStringHash(const void *value);

static inline Boolean BDIsEmptyString(CFStringRef aString)
{ 
    return (aString == NULL || CFStringCompare(aString, CFSTR(""), 0) == kCFCompareEqualTo); 
}

static inline Boolean BDIsNewlineCharacter(UniChar c)
{
    // minor optimization: check for an ASCII character, since those are most common in TeX
    return ( (c <= 0x007E && c >= 0x0021) ? NO : CFCharacterSetIsCharacterMember((CFCharacterSetRef)[NSCharacterSet newlineCharacterSet], c) );
}

static inline Boolean BDStringHasAccentedCharacters(CFStringRef string)
{
    CFMutableStringRef mutableString = CFStringCreateMutableCopy(CFAllocatorGetDefault(), CFStringGetLength(string), string);
    CFStringNormalize(mutableString, kCFStringNormalizationFormD);
    Boolean success = CFStringFindCharacterFromSet(mutableString, CFCharacterSetGetPredefined(kCFCharacterSetNonBase), CFRangeMake(0, CFStringGetLength(mutableString)), 0, NULL);
    CFRelease(mutableString);
    return success;
}
