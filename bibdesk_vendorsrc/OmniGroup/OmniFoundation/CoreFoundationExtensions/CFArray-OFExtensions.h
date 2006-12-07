// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFArray-OFExtensions.h,v 1.3 2004/02/10 04:07:41 kc Exp $

#import <CoreFoundation/CFArray.h>

extern const CFArrayCallBacks OFNonOwnedPointerArrayCallbacks;
extern const CFArrayCallBacks OFIntegerArrayCallbacks;

// Convenience functions
@class NSMutableArray;
extern NSMutableArray *OFCreateNonOwnedPointerArray(void);
extern NSMutableArray *OFCreateIntegerArray(void);

