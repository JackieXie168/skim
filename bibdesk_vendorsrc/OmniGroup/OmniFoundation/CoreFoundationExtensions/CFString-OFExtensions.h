// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFString-OFExtensions.h,v 1.9 2004/02/10 04:07:42 kc Exp $

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

/* A simple convenience function which calls CFStringGetBytes() for the specified range and appends the bytes to the CFMutableData buffer. Returns the number of characters of "range" converted, which should always be the same as range.length. */
CFIndex OFAppendStringBytesToBuffer(CFMutableDataRef buffer, CFStringRef source, CFRange range, CFStringEncoding encoding, UInt8 lossByte, Boolean isExternalRepresentation);
