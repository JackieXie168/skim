//
//  SKPDFSynchronizer.m
//  Skim
//
//  Created by Christiaan Hofman on 4/21/07.
/*
 This software is Copyright (c) 2007-2009
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "SKPDFSynchronizer.h"
#import "SKPDFSynchronizerServer.h"


@implementation SKPDFSynchronizer

- (id)init {
    if (self = [super init]) {
        NSPort *port1 = [NSPort port];
        NSPort *port2 = [NSPort port];
        
        connection = [[NSConnection alloc] initWithReceivePort:port1 sendPort:port2];
        [connection setRootObject:self];
        [connection enableMultipleThreads];
        
        server = [[SKPDFSynchronizerServer alloc] init];
        // this will be set when the background thread sets up
        serverProxy = nil;
        
        // let the server connect back with the ports in opposite order
        [server startDOServerForPorts:[NSArray arrayWithObjects:port2, port1, nil]];
    }
    return self;
}

- (void)dealloc {
    [server release];
    [super dealloc];
}

#pragma mark DO Client

#pragma mark | API

- (void)terminate {
    // tell the server thread to stop running, this is also necessary to tickle the server thread so the runloop can finish
    [serverProxy stopRunning];
    // set the stop flag immediately, so any running task may stop in its tracks
    [server setShouldKeepRunning:NO];
    
    // clean up the connection in the main thread; don't invalidate the ports, since they're still in use
    [connection setRootObject:nil];
    [connection invalidate];
    [connection release];
    connection = nil;
    
    [serverProxy release];
    serverProxy = nil;    
}

#pragma mark | Client protocol

- (void)setServerProxy:(byref id)anObject {
    [anObject setProtocolForProxy:@protocol(SKPDFSynchronizerServer)];
    serverProxy = [anObject retain];
}

#pragma mark Finding

#pragma mark | Accessors

- (id <SKPDFSynchronizerDelegate>)delegate {
    return delegate;
}

- (void)setDelegate:(id <SKPDFSynchronizerDelegate>)newDelegate {
    delegate = newDelegate;
}

- (NSString *)fileName {
    return [server fileName];
}

- (void)setFileName:(NSString *)newFileName {
    [server setFileName:newFileName];
}

#pragma mark | API

- (void)findFileAndLineForLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(NSUInteger)pageIndex {
    [serverProxy findFileAndLineForLocation:point inRect:rect pageBounds:bounds atPageIndex:pageIndex];
}

- (void)findPageAndLocationForLine:(NSInteger)line inFile:(NSString *)file options:(NSInteger)options {
    [serverProxy findPageAndLocationForLine:line inFile:file options:options];
}

#pragma mark | Client protocol

- (oneway void)foundLine:(NSInteger)line inFile:(bycopy NSString *)file {
    if ([server shouldKeepRunning] && [delegate respondsToSelector:@selector(synchronizer:foundLine:inFile:)])
        [delegate synchronizer:self foundLine:line inFile:file];
}

- (oneway void)foundLocation:(NSPoint)point atPageIndex:(NSUInteger)pageIndex options:(NSInteger)options {
    if ([server shouldKeepRunning] && [delegate respondsToSelector:@selector(synchronizer:foundLocation:atPageIndex:options:)])
        [delegate synchronizer:self foundLocation:point atPageIndex:pageIndex options:options];
}

@end
