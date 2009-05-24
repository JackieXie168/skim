//
//  SKPDFSynchronizerServer.h
//  Skim
//
//  Created by Christiaan Hofman on 1/11/09.
/*
 This software is Copyright (c) 2009
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

#import <Cocoa/Cocoa.h>
#import "synctex_parser.h"

// these methods can be sent to the proxy for the server and are implemented by the server
@protocol SKPDFSynchronizerServer
- (oneway void)stopRunning; 
- (oneway void)findFileAndLineForLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(NSUInteger)pageIndex;
- (oneway void)findPageAndLocationForLine:(NSInteger)line inFile:(bycopy NSString *)file;
@end

// these methods can be sent to the proxy for the client and must be implemented by the client
@protocol SKPDFSynchronizerClient
- (void)setServerProxy:(byref id)anObject;
- (oneway void)foundLine:(NSInteger)line inFile:(bycopy NSString *)file;
- (oneway void)foundLocation:(NSPoint)point atPageIndex:(NSUInteger)pageIndex isFlipped:(BOOL)isFlipped;
@end


@interface SKPDFSynchronizerServer : NSObject {
    NSString *fileName;
    NSString *syncFileName;
    NSDate *lastModDate;
    BOOL isPdfsync;
    
    NSMutableArray *pages;
    NSMutableDictionary *lines;
    
    NSMutableDictionary *filenames;
    synctex_scanner_t scanner;
    
    id clientProxy;
    NSConnection *connection;
    BOOL stopRunning;
    struct SKServerFlags *serverFlags;
}

// this sets up the background thread and connects back to the client, blocks until it's fully set up
- (void)startDOServerForPorts:(NSArray *)ports;

// these 4 accessors are thread safe
- (BOOL)shouldKeepRunning;
- (void)setShouldKeepRunning:(BOOL)flag;

- (NSString *)fileName;
- (void)setFileName:(NSString *)newFileName;

@end
