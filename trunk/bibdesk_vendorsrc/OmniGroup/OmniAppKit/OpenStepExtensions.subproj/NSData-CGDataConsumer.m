// Copyright 2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSData-CGDataConsumer.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <ApplicationServices/ApplicationServices.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSData-CGDataConsumer.m 77393 2006-07-12 18:15:18Z wiml $");

@implementation NSMutableData (CGDataConsumer)

typedef struct  {
    NSData *data;
} OFDataCGDataConsumer;

size_t OFDataCGDataConsumerPutBytes(void *opaqueConsumer, const void *buffer, size_t count)
{
    NSMutableData *data = opaqueConsumer;
    [data appendBytes:buffer length:count];
    return count;
}

void OFDataCGDataConsumerReleaseConsumer(void *opaqueConsumer)
{
    NSMutableData *data = opaqueConsumer;
    [data release];
}

- (void *)coreGraphicsDataConsumer;
{
    static CGDataConsumerCallbacks callbacks;
    
    // This is probably reentrant, but it's ugly
    callbacks.putBytes = OFDataCGDataConsumerPutBytes;
    callbacks.releaseConsumer = OFDataCGDataConsumerReleaseConsumer;
    
    return CGDataConsumerCreate([self retain], &callbacks);
}


@end

