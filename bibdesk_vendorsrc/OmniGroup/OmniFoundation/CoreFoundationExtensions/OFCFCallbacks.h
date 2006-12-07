// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/OFCFCallbacks.h,v 1.6 2004/02/10 04:07:42 kc Exp $

#import <CoreFoundation/CFString.h>


// Callbacks for NSObjects
extern const void *OFNSObjectRetain(CFAllocatorRef allocator, const void *value);
extern const void *OFNSObjectRetainCopy(CFAllocatorRef allocator, const void *value);
extern void        OFNSObjectRelease(CFAllocatorRef allocator, const void *value);
CFStringRef        OFNSObjectCopyDescription(const void *value);
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
