// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFString-OFExtensions.h,v 1.6 2003/01/15 22:51:52 kc Exp $

#import <CoreFoundation/CFString.h>

typedef struct _OFCaseConversionBuffer {
    CFMutableStringRef   string;
    UniChar             *buffer;
    CFIndex              bufferSize;
} OFCaseConversionBuffer;

extern void OFCaseConversionBufferInit(OFCaseConversionBuffer *caseBuffer);
extern void OFCaseConversionBufferDestroy(OFCaseConversionBuffer *caseBuffer);

extern CFStringRef OFCreateStringByLowercasingCharacters(OFCaseConversionBuffer *caseBuffer, const UniChar *characters, CFIndex count);
extern CFHashCode OFCaseInsensitiveHash(const UniChar *characters, CFIndex length);
