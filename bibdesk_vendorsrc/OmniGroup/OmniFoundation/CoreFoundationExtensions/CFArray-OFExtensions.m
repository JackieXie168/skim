// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/CFArray-OFExtensions.h>

#import <OmniFoundation/OFCFCallbacks.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFArray-OFExtensions.m,v 1.3 2004/02/10 04:07:41 kc Exp $");

const CFArrayCallBacks OFNonOwnedPointerArrayCallbacks = {
    0,     // version;
    NULL,  // retain;
    NULL,  // release;
    OFPointerCopyDescription,
    NULL,  // equal
};

const CFArrayCallBacks OFIntegerArrayCallbacks = {
    0,     // version;
    NULL,  // retain;
    NULL,  // release;
    OFIntegerCopyDescription,
    NULL,  // equal
};


NSMutableArray *OFCreateNonOwnedPointerArray(void)
{
    return (NSMutableArray *)CFArrayCreateMutable(kCFAllocatorDefault, 0, &OFNonOwnedPointerArrayCallbacks);
}

NSMutableArray *OFCreateIntegerArray(void)
{
    return (NSMutableArray *)CFArrayCreateMutable(kCFAllocatorDefault, 0, &OFIntegerArrayCallbacks);
}

