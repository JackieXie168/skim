//
//  BDSKAsynchronousDOServer.h
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

#import <Cocoa/Cocoa.h>
#import <libkern/OSAtomic.h>

typedef struct _BDSKDOServerFlags {
    volatile int32_t shouldKeepRunning __attribute__ ((aligned (4)));
} BDSKDOServerFlags;

// protocols for the server proxies, should be included in protocols used by subclasses
@protocol BDSKAsyncDOServerThread, BDSKAsyncDOServerMainThread;

@interface BDSKAsynchronousDOServer : NSObject {
    @private
    id serverOnMainThread;               // proxy for the main thread
    id serverOnServerThread;             // proxy for the local server thread
    NSConnection *mainThreadConnection;  // so the local server thread can talk to the main thread
    NSConnection *localThreadConnection; // so the main thread can talk to the local server thread
    
    BDSKDOServerFlags serverFlags;       // state variables
}

// use these proxies to message the server object; do not override
- (id)serverOnMainThread;
- (id)serverOnServerThread;

// override for custom setup after the server has been setup; called on the server thread; default does nothing
- (void)serverDidSetup;

// override for custom cleanup on the main thread; call super afterwards
- (void)stopDOServer;

// override for custom cleanup on the server thread; call super afterwards
- (void)cleanup;

// run loop flag
- (BOOL)shouldKeepRunning;

// override to add additional methods adopted by serverOn...Thread objects; they should always adopt our protocols

- (Protocol *)protocolForServerThread; // protocol must adopt <BDSKAsyncDOServerThread>
- (Protocol *)protocolForMainThread;   // protocol must adopt <BDSKAsyncDOServerMainThread>


@end
