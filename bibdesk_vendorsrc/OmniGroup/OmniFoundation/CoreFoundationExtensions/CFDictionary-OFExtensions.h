// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFDictionary-OFExtensions.h 66640 2005-08-10 00:37:09Z kc $

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
extern NSMutableDictionary *OFCreateCaseInsensitiveKeyMutableDictionary(void);

// Applier functions
extern void OFPerformSelectorOnKeyApplierFunction(const void *key, const void *value, void *context);   // context==SEL
extern void OFPerformSelectorOnValueApplierFunction(const void *key, const void *value, void *context); // context==SEL
