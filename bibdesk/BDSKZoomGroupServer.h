//
//  BDSKZoomGroupServer.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
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
#import <yaz/ZOOMObjC.h>
#import "BDSKSearchGroup.h"
#import "BDSKAsynchronousDOServer.h"

// private protocols for inter-thread messaging
@protocol BDSKZoomGroupServerMainThread <BDSKAsyncDOServerMainThread>
- (void)addPublicationsToGroup:(bycopy NSArray *)pubs;
@end

@protocol BDSKZoomGroupServerLocalThread <BDSKAsyncDOServerThread>
- (int)availableResults;
- (void)setAvailableResults:(int)value;
- (int)fetchedResults;
- (void)setFetchedResults:(int)value;
- (oneway void)downloadWithSearchTerm:(NSString *)searchTerm;
- (oneway void)terminateConnection;
@end

typedef struct _BDSKZoomGroupFlags {
    volatile int32_t isRetrieving   __attribute__ ((aligned (4)));
    volatile int32_t failedDownload __attribute__ ((aligned (4)));
    volatile int32_t needsReset     __attribute__ ((aligned (4)));
} BDSKZoomGroupFlags;    


@class BDSKServerInfo;

@interface BDSKZoomGroupServer : BDSKAsynchronousDOServer <BDSKSearchGroupServer, BDSKZoomGroupServerMainThread, BDSKZoomGroupServerLocalThread>
{
    BDSKSearchGroup *group;
    ZOOMConnection *connection;
    BDSKServerInfo *serverInfo;
    int availableResults;
    int fetchedResults;
    BDSKZoomGroupFlags flags;
    pthread_rwlock_t infolock;
}
+ (NSArray *)supportedRecordSyntaxes;
+ (ZOOMSyntaxType)zoomRecordSyntaxForRecordSyntaxString:(NSString *)syntax;
- (void)resetConnection;
@end
