// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFSet-OFExtensions.h,v 1.11 2004/02/10 04:07:41 kc Exp $

#import <CoreFoundation/CFSet.h>

extern const CFSetCallBacks OFCaseInsensitiveStringSetCallbacks;

extern const CFSetCallBacks OFNonOwnedPointerSetCallbacks;
extern const CFSetCallBacks OFIntegerSetCallbacks;
extern const CFSetCallBacks OFPointerEqualObjectSetCallbacks;
extern const CFSetCallBacks OFNSObjectSetCallbacks;
extern const CFSetCallBacks OFWeaklyRetainedObjectSetCallbacks;

@class NSMutableSet;
extern NSMutableSet *OFCreateNonOwnedPointerSet();
extern NSMutableSet *OFCreatePointerEqualObjectSet();
