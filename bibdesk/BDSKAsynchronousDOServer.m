//
//  BDSKAsynchronousDOServer.m
//  Bibdesk
//
//  Created by Adam Maxwell on 04/24/06.
/*
 This software is Copyright (c) 2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKAsynchronousDOServer.h"

// protocols for the server thread proxies, must be included in protocols used by subclasses
@protocol BDSKAsyncDOServerThread
// override for custom cleanup on the server thread; call super afterwards
- (oneway void)cleanup; 
@end

@protocol BDSKAsyncDOServerMainThread
- (oneway void)setLocalServer:(byref id)anObject;
@end


@interface BDSKAsynchronousDOServer (Private)
// avoid categories in the implementation, since categories and formal protocols don't mix
- (void)runDOServerForPorts:(NSArray *)ports;
@end

@implementation BDSKAsynchronousDOServer

- (id)init;
{
    if (self = [super init]) {
        // set up a connection to communicate with the local background thread
        NSPort *port1 = [NSPort port];
        NSPort *port2 = [NSPort port];
        
        mainThreadConnection = [[NSConnection alloc] initWithReceivePort:port1 sendPort:port2];
        [mainThreadConnection setRootObject:self];
        [mainThreadConnection enableMultipleThreads];
       
        // set up flags
        memset(&serverFlags, 0, sizeof(serverFlags));
        serverFlags.shouldKeepRunning = 1;
        
        // these will be set when the background thread sets up
        localThreadConnection = nil;
        serverOnMainThread = nil;
        serverOnServerThread = nil;
        
        // run a background thread to connect to the remote server
        // this will connect back to the connection we just set up
        [NSThread detachNewThreadSelector:@selector(runDOServerForPorts:) toTarget:self withObject:[NSArray arrayWithObjects:port2, port1, nil]];
    }
    return self;
}

#pragma mark Proxies

- (Protocol *)protocolForServerThread;
{ 
    return @protocol(BDSKAsyncDOServerThread); 
}

- (Protocol *)protocolForMainThread;
{ 
    return @protocol(BDSKAsyncDOServerMainThread); 
}

- (oneway void)setLocalServer:(byref id)anObject;
{
    [anObject setProtocolForProxy:[self protocolForServerThread]];
    serverOnServerThread = [anObject retain];
}

#pragma mark ServerThread

- (oneway void)cleanup;
{   
    // clean up the connection in the server thread
    [localThreadConnection setRootObject:nil];
    
    // this frees up the CFMachPorts created in -init
    [[localThreadConnection receivePort] invalidate];
    [[localThreadConnection sendPort] invalidate];
    [localThreadConnection invalidate];
    [localThreadConnection release];
    localThreadConnection = nil;
    
    [serverOnMainThread release];
    serverOnMainThread = nil;    
}

- (void)runDOServerForPorts:(NSArray *)ports;
{
    // detach a new thread to run this
    NSAssert([NSThread inMainThread] == NO, @"do not run the server in the main thread");
    NSAssert(localThreadConnection == nil, @"server is already running");
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&serverFlags.shouldKeepRunning);
    
    @try {
        // we'll use this to communicate between threads on the localhost
        localThreadConnection = [[NSConnection alloc] initWithReceivePort:[ports objectAtIndex:0] sendPort:[ports objectAtIndex:1]];
        if(localThreadConnection == nil)
            @throw @"Unable to get default connection";
        [localThreadConnection setRootObject:self];
        
        serverOnMainThread = [[localThreadConnection rootProxy] retain];
        [serverOnMainThread setProtocolForProxy:[self protocolForMainThread]];
        // handshake, this sets the proxy at the other side
        [serverOnMainThread setLocalServer:self];
        
        // allow subclasses to do some custom setup
        [self serverDidSetup];
        
        NSRunLoop *rl = [NSRunLoop currentRunLoop];
        BOOL didRun;
        
        // see http://lists.apple.com/archives/cocoa-dev/2006/Jun/msg01054.html for a helpful explanation of NSRunLoop
        do {
            [pool release];
            pool = [NSAutoreleasePool new];
            didRun = [rl runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (serverFlags.shouldKeepRunning == 1 && didRun);
    }
    @catch(id exception) {
        NSLog(@"Discarding exception \"%@\" raised in object %@", exception, self);
        // reset the flag so we can start over; shouldn't be necessary
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&serverFlags.shouldKeepRunning);
    }
    
    @finally {
        [pool release];
    }
}

- (void)serverDidSetup{}

#pragma mark -
#pragma mark API

- (void)stopDOServer;
{
    // this cleans up the connections, ports and proxies on both sides
    [serverOnServerThread cleanup];
    // we're in the main thread, so set the stop flag
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&serverFlags.shouldKeepRunning);
    
    // clean up the connection in the main thread; don't invalidate the ports, since they're still in use
    [mainThreadConnection setRootObject:nil];
    [mainThreadConnection invalidate];
    [mainThreadConnection release];
    mainThreadConnection = nil;
    
    [serverOnServerThread release];
    serverOnServerThread = nil;    
}

- (BOOL)shouldKeepRunning { return serverFlags.shouldKeepRunning == 1; }
- (id)serverOnMainThread { return serverOnMainThread; }
- (id)serverOnServerThread { return serverOnServerThread; }

@end
