// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFDictionary-OFExtensions.h,v 1.13 2004/02/10 04:07:41 kc Exp $

#import <CoreFoundation/CFDictionary.h>

extern const CFDictionaryKeyCallBacks OFCaseInsensitiveStringKeyDictionaryCallbacks;


extern const CFDictionaryKeyCallBacks    OFNonOwnedPointerDictionaryKeyCallbacks;
extern const CFDictionaryValueCallBacks  OFNonOwnedPointerDictionaryValueCallbacks;

extern const CFDictionaryKeyCallBacks    OFIntegerDictionaryKeyCallbacks;
extern const CFDictionaryValueCallBacks  OFIntegerDictionaryValueCallbacks;

extern const CFDictionaryKeyCallBacks    OFNSObjectDictionaryKeyCallbacks;
extern const CFDictionaryKeyCallBacks    OFNSObjectCopyDictionaryKeyCallbacks;
extern const CFDictionaryValueCallBacks  OFNSObjectDictionaryValueCallbacks;


// Convenience functions
@class NSMutableDictionary;
extern NSMutableDictionary *OFCreateCaseInsensitiveKeyMutableDictionary();
