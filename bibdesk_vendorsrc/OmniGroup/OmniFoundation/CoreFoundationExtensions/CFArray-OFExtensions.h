// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFArray-OFExtensions.h 66043 2005-07-25 21:17:05Z kc $

#import <CoreFoundation/CFArray.h>

extern const CFArrayCallBacks OFNonOwnedPointerArrayCallbacks;
extern const CFArrayCallBacks OFNSObjectArrayCallbacks;
extern const CFArrayCallBacks OFIntegerArrayCallbacks;

// Convenience functions
@class NSMutableArray;
extern NSMutableArray *OFCreateNonOwnedPointerArray(void);
extern NSMutableArray *OFCreateIntegerArray(void);

