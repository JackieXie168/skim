/*
 *  SKNAgentListener.m
 *
 *  Created by Adam Maxwell on 04/10/07.
 *
 This software is Copyright (c) 2007-2014
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

#import "SKNAgentListener.h"
#import "SKNAgentListenerProtocol.h"
#import "NSFileManager_SKNToolExtensions.h"

@implementation SKNAgentListener

- (id)initWithServerName:(NSString *)serverName;
{
    self = [super init];
    if (self) {
        connection = [[NSConnection alloc] initWithReceivePort:[NSPort port] sendPort:nil];
        NSProtocolChecker *checker = [NSProtocolChecker protocolCheckerWithTarget:self protocol:@protocol(SKNAgentListenerProtocol)];
        [connection setRootObject:checker];
        [connection setDelegate:self];
        
        // user can pass nil, in which case we generate a server name to be read from standard output
        if (nil == serverName)
            serverName = [[NSProcessInfo processInfo] globallyUniqueString];

        if ([connection registerName:serverName] == NO) {
            fprintf(stderr, "skimnotes agent pid %d: unable to register connection name %s; another process must be running\n", getpid(), [serverName UTF8String]);
            [self destroyConnection];
            [self release];
            self = nil;
        }
        NSFileHandle *fh = [NSFileHandle fileHandleWithStandardOutput];
        [fh writeData:[serverName dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self destroyConnection];
    [super dealloc];
}

- (void)destroyConnection;
{
    [connection registerName:nil];
    [[connection receivePort] invalidate];
    [[connection sendPort] invalidate];
    [connection invalidate];
    [connection release];
    connection = nil;
}

- (void)portDied:(NSNotification *)notification
{
    [self destroyConnection];
    fprintf(stderr, "skimnotes agent pid %d dying because port %s is invalid\n", getpid(), [[[notification object] description] UTF8String]);
    exit(0);
}

// first app to connect will be the owner of this instance of the program; when the connection dies, so do we
- (BOOL)makeNewConnection:(NSConnection *)newConnection sender:(NSConnection *)parentConnection
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portDied:) name:NSPortDidBecomeInvalidNotification object:[newConnection sendPort]];
    fprintf(stderr, "skimnotes agent pid %d connection registered\n", getpid());
    return YES;
}

#pragma mark SKNAgentListenerProtocol

- (bycopy NSData *)SkimNotesAtPath:(in bycopy NSString *)aFile;
{
    NSError *error = nil;
    NSData *data = [[NSFileManager defaultManager] SkimNotesAtPath:aFile error:&error];
    if (nil == data)
        fprintf(stderr, "skimnotes agent pid %d: error getting Skim notes (%s)\n", getpid(), [[error description] UTF8String]);
    return data;
}

- (bycopy NSData *)RTFNotesAtPath:(in bycopy NSString *)aFile;
{
    NSError *error = nil;
    NSData *data = [[NSFileManager defaultManager] SkimRTFNotesAtPath:aFile error:&error];
    if (nil == data)
        fprintf(stderr, "skimnotes agent pid %d: error getting RTF notes (%s)\n", getpid(), [[error description] UTF8String]);
    return data;
}

- (bycopy NSData *)textNotesAtPath:(in bycopy NSString *)aFile encoding:(NSStringEncoding)encoding;
{
    NSError *error = nil;
    NSString *string = [[NSFileManager defaultManager] SkimTextNotesAtPath:aFile error:&error];
    if (nil == string)
        fprintf(stderr, "skimnotes agent pid %d: error getting text notes (%s)\n", getpid(), [[error description] UTF8String]);
    // Returning the string directly can fail under some conditions.  For some strings with corrupt copy-paste characters (typical for notes), -[NSString canBeConvertedToEncoding:NSUTF8StringEncoding] returns YES but the actual conversion fails.  A result seems to be that encoding the string also fails, which causes the DO client to get a timeout.  Returning NSUnicodeStringEncoding data seems to work in those cases (and is safe since we're not going over the wire between big/little-endian systems).
    return [string dataUsingEncoding:encoding];
}

@end
