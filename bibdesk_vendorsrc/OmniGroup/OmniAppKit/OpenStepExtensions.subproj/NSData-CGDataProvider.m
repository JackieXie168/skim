// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSData-CGDataProvider.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <ApplicationServices/ApplicationServices.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSData-CGDataProvider.m 68913 2005-10-03 19:36:19Z kc $")

@implementation NSData (CGDataProvider)

typedef struct  {
    NSData *data;
    size_t startPosition;
    size_t currentPosition;
} OFDataCGDataProvider;

size_t OFDataCGDataProviderGetBytes(void *opaqueProvider, void *buffer, size_t count)
{
    OFDataCGDataProvider *provider = opaqueProvider;
    size_t dataLength = [provider->data length];
    
    count = MIN(count, dataLength - provider->currentPosition);
    [provider->data getBytes:buffer range:NSMakeRange(provider->currentPosition, count)];
    provider->currentPosition += count;
//    if (provider->currentPosition >= dataLength)
//        provider->currentPosition = provider->startPosition;
    return count;
}

void OFDataCGDataProviderSkipBytes(void *opaqueProvider, size_t count)
{
    OFDataCGDataProvider *provider = opaqueProvider;

    provider->currentPosition += count;
    if (provider->currentPosition >= [provider->data length])
        provider->currentPosition = provider->startPosition;
}

void OFDataCGDataProviderRewind(void *opaqueProvider)
{
    OFDataCGDataProvider *provider = opaqueProvider;

    provider->currentPosition = provider->startPosition;
}

void OFDataCGDataProviderReleaseProvider(void *opaqueProvider)
{
    OFDataCGDataProvider *provider = opaqueProvider;

    [provider->data release];
    NSZoneFree(NULL, provider);
}

- (void *)coreGraphicsDataProvider;
{
    return [self coreGraphicsDataProviderWithOffset:0];
}

- (void *)coreGraphicsDataProviderWithOffset:(int)offset;
{
    static CGDataProviderCallbacks callbacks;
    OFDataCGDataProvider *provider;
    
    // This is probably reentrant, but it's ugly
    callbacks.getBytes = OFDataCGDataProviderGetBytes;
    callbacks.skipBytes = OFDataCGDataProviderSkipBytes;
    callbacks.rewind = OFDataCGDataProviderRewind;
    callbacks.releaseProvider = OFDataCGDataProviderReleaseProvider;
    
    provider = NSZoneMalloc(NULL, sizeof(OFDataCGDataProvider));
    provider->data = [self retain];
    provider->startPosition = offset;
    provider->currentPosition = offset;
    return CGDataProviderCreate(provider, &callbacks);
}

@end
