// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
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

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/CoreFoundationExtensions/CFPropertyList-OFExtensions.m 68913 2005-10-03 19:36:19Z kc $")

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

