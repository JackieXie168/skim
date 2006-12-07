// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/CFString-OFExtensions.h>
#import <Foundation/NSObjCRuntime.h> // for BOOL

#import <OmniBase/rcsid.h>
#import <string.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFString-OFExtensions.m,v 1.7 2003/03/24 23:05:05 neo Exp $")


void OFCaseConversionBufferInit(OFCaseConversionBuffer *caseBuffer)
{
    caseBuffer->bufferSize = 128;
    caseBuffer->buffer = CFAllocatorAllocate(kCFAllocatorDefault, caseBuffer->bufferSize * sizeof(*caseBuffer->buffer), 0);
    caseBuffer->string = CFStringCreateMutableWithExternalCharactersNoCopy(kCFAllocatorDefault, caseBuffer->buffer, 0, caseBuffer->bufferSize, kCFAllocatorDefault);
}

void OFCaseConversionBufferDestroy(OFCaseConversionBuffer *caseBuffer)
{
    CFRelease(caseBuffer->string);
    caseBuffer->string = NULL;
    // Don't release the buffer -- the string did that.
    caseBuffer->buffer = NULL;
    caseBuffer->bufferSize = 0;
}


static inline BOOL _OFHasPotentiallyUppercaseCharacter(const UniChar *characters, CFIndex count)
{
    while (count--) {
        UniChar c = *characters++;
        
        if (c > 0x7f)
            return YES;
        if (c >= 'A' && c <= 'Z')
            return YES;
    }
    
    return NO;
}

/*"
Returns a new immutable string that contains the lowercase variant of the given characters.  The buffer of characters provide is left unchanged.
"*/
CFStringRef OFCreateStringByLowercasingCharacters(OFCaseConversionBuffer *caseBuffer, const UniChar *characters, CFIndex count)
{
    // Trivially create a string from the given characters if non of them can possibly be upper case
    if (!_OFHasPotentiallyUppercaseCharacter(characters, count))
        return CFStringCreateWithCharacters(kCFAllocatorDefault, characters, count);

    // Make sure we have enough room to copy the string into our conversion buffer
    if (caseBuffer->bufferSize < count) {
        caseBuffer->bufferSize = count;
        caseBuffer->buffer = CFAllocatorReallocate(kCFAllocatorDefault, caseBuffer->buffer, caseBuffer->bufferSize * sizeof(*caseBuffer->buffer), 0);
    }
    
    // Copy the string into backing store for the conversion string.
    memcpy(caseBuffer->buffer, characters, sizeof(*characters) * count);

    // Reset the external character buffer (and importantly, reset the length of the string in the buffer)
    CFStringSetExternalCharactersNoCopy(caseBuffer->string, caseBuffer->buffer, count, caseBuffer->bufferSize);

    // Lowercase the string, possibly reallocating the external buffer if it needs to grow to accomodate
    // unicode sequences that have different lengths when lowercased.
    CFStringLowercase(caseBuffer->string, NULL);

    // Make sure that if the external buffer had to grow, we don't lose our pointer to it.
    // Sadly, this doesn't let us find the new size, but if it did grow that means that the next time we
    // try to grow it, we'll be less likely to actually get a new pointer from CFAllocatorReallocate().
    caseBuffer->buffer = (UniChar *)CFStringGetCharactersPtr(caseBuffer->string);
    
    // Return a new immutable string.
    return CFStringCreateCopy(kCFAllocatorDefault, caseBuffer->string);
}


/*" Returns a hash code by examining all of the characters in the provided array.  Two strings that differ only in case will return the same hash code. "*/
CFHashCode OFCaseInsensitiveHash(const UniChar *characters, CFIndex length)
{
    CFIndex index;
    CFHashCode hash;
    UniChar c;
    
    // We will optimistically assume that the string is ASCII
    hash = 0;
    for (index = 0; index < length; index++) {
        c = characters[index];
        if (c < ' ' || c > '~')
            goto HandleUnicode;
        if (c >= 'A' && c <= 'Z') {
            c = 'a' + (c - 'A');
        }
        
        // Rotate hash by 7 bits (which is relatively prime to 32) and or in the
        // next character at the top of the hash code.
        hash = (c << 16) | ((hash & ((1<<7) - 1)) << (32-7)) | (hash >> 7);
    }
    
    return hash;
    
HandleUnicode:

    // This version is SLOW.  The problem is that we don't know if performing case conversion will require more characters.
    // Fortunately, this should only get called once per value that is put in a hashing container, but it will still get called once per lookup.
    {
        CFMutableStringRef string;
        
        string = CFStringCreateMutable(kCFAllocatorDefault, length);
        CFStringAppendCharacters(string, characters, length);
        CFStringLowercase(string, NULL);
        hash = CFHash(string);
        CFRelease(string);
        
        return hash;
    }
}
