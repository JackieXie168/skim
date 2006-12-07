// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "CFPropertyList-OFExtensions.h"

#import <CoreFoundation/CFStream.h>
#import <CoreFoundation/CFString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFPropertyList-OFExtensions.m,v 1.3 2004/02/10 05:19:30 kc Exp $")

CFDataRef OFCreateDataFromPropertyList(CFAllocatorRef allocator, CFPropertyListRef plist, CFPropertyListFormat format)
{
    CFWriteStreamRef stream;
    CFStringRef error;
    CFDataRef buf;

    stream = CFWriteStreamCreateWithAllocatedBuffers(kCFAllocatorDefault, allocator);
    CFWriteStreamOpen(stream);

    error = NULL;
    CFPropertyListWriteToStream(plist, stream, format, &error);

    if (error != NULL) {
        CFWriteStreamClose(stream);
        CFRelease(stream);
        [NSException raise:NSGenericException format:@"CFPropertyListWriteToStream: %@", error];
    }
    
    buf = CFWriteStreamCopyProperty(stream, kCFStreamPropertyDataWritten);
    CFWriteStreamClose(stream);
    CFRelease(stream);

    return buf;
}

