// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFDOServer.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DistributedObjects.subproj/OFDOServer.m 68913 2005-10-03 19:36:19Z kc $")

NSString *OFDOServerFailedToRegisterName = @"OFDOServerFailedToRegisterName";

@implementation OFDOServer

//
// Server creation methods.
//

+ serverWithRegisteredName:(NSString *)name
{
    return [[[[self class] alloc] initWithRegisteredName:name] autorelease];
}

- initWithRegisteredName:(NSString *)name
{
    OBPRECONDITION(name);

    if (![super init]) {
        [self release];
        return nil;
    }

    _delegate = nil;
    _shouldHandleAllInvocations = NO;

    _defaultConnection = [[NSConnection defaultConnection] retain];
    [_defaultConnection setRootObject:self];

    if ([_defaultConnection registerName:name] == NO) {
        [self release];

        [NSException raise:OFDOServerFailedToRegisterName format:@"OFDOServer was unable to register the name: %@, with the current NSConnection", name];
    }

    [_defaultConnection setDelegate:self];

    return self;
}

- (void)dealloc
{
    [_delegate release];
    [_defaultConnection release];

    [super dealloc];
}

//
// Setting and accessing the delegate.
//

- (id <OFDOServerDelegateProtocol>)delegate
{
    return _delegate;
}

- (void)setDelegate:(id <OFDOServerDelegateProtocol>)delegate;
{
    OBPRECONDITION(delegate);

    [_delegate autorelease];
    _delegate = [delegate retain];
}


//
// Using the server.
//

- (void)enableGlobalExceptionHandling
{
    _shouldHandleAllInvocations = YES;
}

- (void)run
{
    [[NSRunLoop currentRunLoop] run];
}

- (NSConnection *)connection
{
    return _defaultConnection;
}


//
// NSConnection delegate methods.
//

- (BOOL)connection:(NSConnection *)connection handleRequest:(NSDistantObjectRequest *)distantObjectRequest;
{
    if (_shouldHandleAllInvocations) {
        NSInvocation *invocation;

        invocation = [distantObjectRequest invocation];

        NS_DURING {
            [invocation invoke];
            [distantObjectRequest replyWithException:nil];
        } NS_HANDLER {
            if (_delegate) {
                if ([_delegate terminateFromException:localException]) {
                    NSLog(@"%@ instructed by delegate to terminate from exception:\n%@: %@", NSStringFromClass([self class]), [localException name], [localException reason]);
                    exit(-1);
                }
            }
            else {
                NSLog(@"Exception occurred during invocation: %@\n%@: %@", invocation, [localException name], [localException reason]);
            }

            [distantObjectRequest replyWithException:localException];
        } NS_ENDHANDLER;

        return YES;
    }

    return NO;
}


@end
