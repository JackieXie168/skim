// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/CFSet-OFExtensions.h>

#import <OmniFoundation/OFCFCallbacks.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFSet-OFExtensions.m,v 1.11 2004/02/10 04:07:41 kc Exp $")


const CFSetCallBacks
OFCaseInsensitiveStringSetCallbacks = {
    0,   // version
    OFCFTypeRetain,
    OFCFTypeRelease,
    OFCFTypeCopyDescription,
    OFCaseInsensitiveStringIsEqual,
    OFCaseInsensitiveStringHash,
};

const CFSetCallBacks OFNonOwnedPointerSetCallbacks  = {
    0,    // version
    NULL, // retain
    NULL, // release
    OFPointerCopyDescription,
    NULL, // isEqual
    NULL, // hash
};

const CFSetCallBacks OFIntegerSetCallbacks = {
    0,    // version
    NULL, // retain
    NULL, // release
    OFIntegerCopyDescription,
    NULL, // isEqual
    NULL, // hash
};

// -retain/-release, but no -hash/-isEqual:
const CFSetCallBacks OFPointerEqualObjectSetCallbacks = {
    0,   // version
    OFNSObjectRetain,
    OFNSObjectRelease,
    OFNSObjectCopyDescription,
    NULL,
    NULL,
};

const CFSetCallBacks OFNSObjectSetCallbacks = {
    0,   // version
    OFNSObjectRetain,
    OFNSObjectRelease,
    OFNSObjectCopyDescription,
    OFNSObjectIsEqual,
    OFNSObjectHash,
};

const CFSetCallBacks OFWeaklyRetainedObjectSetCallbacks = {
    0,   // version
    OFNSObjectWeakRetain,
    OFNSObjectWeakRelease,
    OFNSObjectCopyDescription,
    OFNSObjectIsEqual,
    OFNSObjectHash,
};

NSMutableSet *OFCreateNonOwnedPointerSet()
{
    return (NSMutableSet *)CFSetCreateMutable(kCFAllocatorDefault, 0, &OFNonOwnedPointerSetCallbacks);
}

NSMutableSet *OFCreatePointerEqualObjectSet()
{
    return (NSMutableSet *)CFSetCreateMutable(kCFAllocatorDefault, 0, &OFPointerEqualObjectSetCallbacks);
}
