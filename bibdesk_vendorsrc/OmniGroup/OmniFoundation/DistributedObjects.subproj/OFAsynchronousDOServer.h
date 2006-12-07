// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DistributedObjects.subproj/OFAsynchronousDOServer.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFDOServer.h>

@class NSConnection, NSDistantObjectRequest;
@class OFMessageQueue;

#define OMNI_ASYNCHRONOUS_SERVER_DEFAULT_INITIAL_PROCESSORS 10

@interface OFAsynchronousDOServer : OFDOServer
{
    OFMessageQueue *asyncQueue;
}

//
//  Subclasses may implement the following three methods.
//

+ (Class)messageQueueClass;

- (BOOL)shouldProcessInvocationAsynchronously:(NSInvocation *)invocation;
    // The default is to return NO, and process all invocations synchronously.  Subclasses can test if the invocation is a member of some protocol, or similiar, to determine if it should be processed asynchronously.

- (int)initialProcessorCount;
    // Number of OmniQueueProcessors to start the OFMessageQueue with.  Default is defined by OMNI_ASYNCHRONOUS_SERVER_DEFAULT_INITIAL_PROCESSORS.


//
// OFDOServer subclass methods.
//

- (BOOL)connection:(NSConnection *)connection handleRequest:(NSDistantObjectRequest *)doreq;


//
// Private methods.  Should probably put this in a seperate file, OFAsynchronousServer-private.h, sometime.
//

- (void)_processDistantObjectRequestAsynchronously:(NSDistantObjectRequest *)doreq;


@end

#import <OmniFoundation/FrameworkDefines.h>

//
// OFAsynchronousDOServer exception names.
//

OmniFoundation_EXTERN NSString *OFAsynchonrousDOServerAlreadyStartedException;
OmniFoundation_EXTERN NSString *OFAsynchonrousDOServerCouldNotCreateMessageQueueException;
