// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFAsynchronousDOServer.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/OFMessageQueue.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DistributedObjects.subproj/OFAsynchronousDOServer.m 68913 2005-10-03 19:36:19Z kc $")

NSString *OFAsynchonrousDOServerAlreadyStartedException = @"OFAsynchonrousDOServerAlreadyStartedException";
NSString *OFAsynchonrousDOServerCouldNotCreateMessageQueueException = @"OFAsynchonrousDOServerCouldNotCreateMessageQueueException";

@implementation OFAsynchronousDOServer

// Init and dealloc

- (void)dealloc;
{
    [asyncQueue release];
    [super dealloc];
}

// Subclasses may implement the following three methods.

+ (Class)messageQueueClass
{
    return [OFMessageQueue class];
}

- (BOOL)shouldProcessInvocationAsynchronously:(NSInvocation *)invocation
{
    // Handle all invocations synchronously by default.
    return NO; 
}

- (int)initialProcessorCount
{
    return OMNI_ASYNCHRONOUS_SERVER_DEFAULT_INITIAL_PROCESSORS;
}


// OFDOServer subclass methods.

- (BOOL)connection:(NSConnection *)connection handleRequest:(NSDistantObjectRequest *)distantObjectRequest;
{
    NSInvocation *distantObjectRequestInvocation;

    distantObjectRequestInvocation = [distantObjectRequest invocation];

    if ([self shouldProcessInvocationAsynchronously:distantObjectRequestInvocation]) {
        [asyncQueue queueSelector:@selector(_processDistantObjectRequestAsynchronously:) forObject:self withObject:distantObjectRequest];
        return YES;
    } else if (_shouldHandleAllInvocations) {
        NS_DURING {
            [distantObjectRequestInvocation invoke];
            [distantObjectRequest replyWithException:nil];
        } NS_HANDLER {
            if (_delegate) {
                if ([_delegate terminateFromException:localException]) {
                    NSLog(@"%@ instructed by delegate to terminate from exception:\n%@: %@\n", NSStringFromClass([self class]), [localException name], [localException reason]);
                    exit(-1);
                }
            }
            else {
                NSLog(@"Exception occurred during invocation: %@\n%@: %@\n", distantObjectRequestInvocation, [localException name], [localException reason]);
            }

            [distantObjectRequest replyWithException:localException];
        } NS_ENDHANDLER;

        return YES;
    }
    else
        return NO;
}


// Private methods.

- (void)_processDistantObjectRequestAsynchronously:(NSDistantObjectRequest *)distantObjectRequest;
{
    NSInvocation *invocation;

    invocation = [distantObjectRequest invocation];

    NS_DURING {
        [invocation invoke];
        [distantObjectRequest replyWithException:nil];
    } NS_HANDLER {
        if (_shouldHandleAllInvocations) {
            if (_delegate) {
                 if ([_delegate terminateFromException:localException]) {
                     NSLog(@"%@ instructed by delegate to terminate from exception:\n%@: %@\n",
                           NSStringFromClass([self class]), [localException name], [localException reason]);
                     exit(-1);
                 }
             }
             else {
                 NSLog(@"Exception occurred during invocation: %@\n%@: %@\n",
                       invocation, [localException name], [localException reason]);
             }
        }

        [distantObjectRequest replyWithException:localException];
    } NS_ENDHANDLER;
}

@end
