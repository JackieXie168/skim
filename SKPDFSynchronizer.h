//
//  SKPDFSynchronizer.h
//  Skim
//
//  Created by Christiaan Hofman on 4/21/07.
/*
 This software is Copyright (c) 2007
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
#import <libkern/OSAtomic.h>


@interface SKPDFSynchronizer : NSObject {
    NSString *fileName;
    NSDate *lastModDate;
    NSMutableArray *pages;
    NSMutableDictionary *lines;
    
    id delegate;
    
    NSLock *lock;
    
    id serverOnMainThread;
    id serverOnServerThread;
    NSConnection *mainThreadConnection;
    NSConnection *localThreadConnection;
    
    volatile int32_t shouldKeepRunning __attribute__ ((aligned (4)));
    
    BOOL serverReady;
}


- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSString *)fileName;
- (void)setFileName:(NSString *)newFileName;

- (void)findLineForLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex;
- (void)findPageLocationForLine:(int)line inFile:(NSString *)file;

- (void)stopDOServer;

@end


@interface NSObject (SKPDFSynchronizerDelegate)
- (void)synchronizer:(SKPDFSynchronizer *)synchronizer foundLine:(int)line inFile:(NSString *)file;
- (void)synchronizer:(SKPDFSynchronizer *)synchronizer foundLocation:(NSPoint)point atPageIndex:(unsigned int)pageIndex;
@end


@interface NSMutableDictionary (SKExtensions)
- (void)setIntValue:(int)value forKey:(id)key;
- (void)setFloatValue:(float)value forKey:(id)key;
@end
