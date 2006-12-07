// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/OFCFCallbacks.h 68913 2005-10-03 19:36:19Z kc $

#import <CoreFoundation/CFString.h>


// Callbacks for NSObjects
extern const void *OFNSObjectRetain(CFAllocatorRef allocator, const void *value);
extern const void *OFNSObjectRetainCopy(CFAllocatorRef allocator, const void *value);
extern void        OFNSObjectRelease(CFAllocatorRef allocator, const void *value);
CFStringRef        OFNSObjectCopyDescription(const void *value);
CFStringRef        OFNSObjectCopyShortDescription(const void *value);
extern Boolean     OFNSObjectIsEqual(const void *value1, const void *value2);
extern CFHashCode  OFNSObjectHash(const void *value1);

// Callbacks for CFTypeRefs (should usually be interoperable with NSObject, but not always)
extern const void *OFCFTypeRetain(CFAllocatorRef allocator, const void *value);
extern void        OFCFTypeRelease(CFAllocatorRef allocator, const void *value);
extern CFStringRef OFCFTypeCopyDescription(const void *value);
extern Boolean     OFCFTypeIsEqual(const void *value1, const void *value2);
extern CFHashCode  OFCFTypeHash(const void *value);

// Callbacks for NSObjects responding to the OFWeakRetain protocol
extern const void *OFNSObjectWeakRetain(CFAllocatorRef allocator, const void *value);
extern void        OFNSObjectWeakRelease(CFAllocatorRef allocator, const void *value);

// Special purpose callbacks
extern CFStringRef OFPointerCopyDescription(const void *ptr);
extern CFStringRef OFIntegerCopyDescription(const void *ptr);

extern Boolean    OFCaseInsensitiveStringIsEqual(const void *value1, const void *value2);
extern CFHashCode OFCaseInsensitiveStringHash(const void *value);
