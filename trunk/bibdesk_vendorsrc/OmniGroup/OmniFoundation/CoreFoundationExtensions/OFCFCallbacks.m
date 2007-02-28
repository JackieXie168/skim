// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFCFCallbacks.h>
#import <OmniFoundation/CFString-OFExtensions.h>
#import <OmniFoundation/OFWeakRetainProtocol.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/OFCFCallbacks.m 68913 2005-10-03 19:36:19Z kc $");

//
// NSObject callbacks
//

const void * OFNSObjectRetain(CFAllocatorRef allocator, const void *value)
{
    return [(id)value retain];
}

const void * OFNSObjectRetainCopy(CFAllocatorRef allocator, const void *value)
{
    return [(id)value copyWithZone:NULL];
}

void OFNSObjectRelease(CFAllocatorRef allocator, const void *value)
{
    [(id)value release];
}

CFStringRef OFNSObjectCopyDescription(const void *value)
{
    return (CFStringRef)[[(id)value description] retain];
}

CFStringRef OFNSObjectCopyShortDescription(const void *value)
{
    return (CFStringRef)[[(id)value shortDescription] retain];
}

Boolean OFNSObjectIsEqual(const void *value1, const void *value2)
{
    return [(id)value1 isEqual: (id)value2];
}

CFHashCode OFNSObjectHash(const void *value1)
{
    return [(id)value1 hash];
}

//
// OFWeakRetain callbacks
//

const void *OFNSObjectWeakRetain(CFAllocatorRef allocator, const void *value)
{
    id <OFWeakRetain,NSObject> objectValue = (void *)value;
    [objectValue retain];
    [objectValue incrementWeakRetainCount];
    return objectValue;
}

void OFNSObjectWeakRelease(CFAllocatorRef allocator, const void *value)
{
    id <OFWeakRetain,NSObject> const objectValue = (void *)value;
    [objectValue decrementWeakRetainCount];
    [objectValue release];
}

//
// CFTypeRef callbacks
//

const void *OFCFTypeRetain(CFAllocatorRef allocator, const void *value)
{
    return CFRetain((CFTypeRef)value);
}

void OFCFTypeRelease(CFAllocatorRef allocator, const void *value)
{
    CFRelease((CFTypeRef)value);
}

CFStringRef OFCFTypeCopyDescription(const void *value)
{
    return CFCopyDescription((CFTypeRef)value);
}

Boolean OFCFTypeIsEqual(const void *value1, const void *value2)
{
    return CFEqual((CFTypeRef)value1, (CFTypeRef)value2);
}

CFHashCode OFCFTypeHash(const void *value)
{
    return CFHash((CFTypeRef)value);
}

//
// Special purpose callbacks
//

CFStringRef OFPointerCopyDescription(const void *ptr)
{
    return (CFStringRef)[[NSString alloc] initWithFormat: @"<0x%08x>", ptr];
}

CFStringRef OFIntegerCopyDescription(const void *ptr)
{
    return (CFStringRef)[[NSString alloc] initWithFormat: @"%d", (unsigned int)ptr];
}

Boolean OFCaseInsensitiveStringIsEqual(const void *value1, const void *value2)
{
    OBASSERT([(id)value1 isKindOfClass:[NSString class]] && [(id)value2 isKindOfClass:[NSString class]]);
    return CFStringCompare((CFStringRef)value1, (CFStringRef)value2, kCFCompareCaseInsensitive) == kCFCompareEqualTo;
}

CFHashCode OFCaseInsensitiveStringHash(const void *value)
{
    OBASSERT([(id)value isKindOfClass:[NSString class]]);
    
    // This is the only interesting function in the bunch.  We need to ensure that all
    // case variants of the same string (when 'same' is determine case insensitively)
    // have the same hash code.  We will do this by using CFStringGetCharacters over
    // the first 16 characters of each key.
    // This is obviously not a good hashing algorithm for all strings.
    UniChar characters[16];
    unsigned int length;
    CFStringRef string;
    
    string = (CFStringRef)value;
    
    length = CFStringGetLength(string);
    if (length > 16)
        length = 16;
        
    CFStringGetCharacters(string, CFRangeMake(0, length), characters);
    
    return OFCaseInsensitiveHash(characters, length);
}
