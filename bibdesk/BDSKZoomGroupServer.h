//
//  BDSKZoomGroupServer.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <yaz/BDSKZoom.h>
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
- (void)setHost:(NSString *)aHost;
- (NSString *)host;
- (void)setPort:(int)n;
- (int)port;
- (void)setDatabase:(NSString *)dbase;
- (NSString *)database;
- (void)setUser:(NSString *)aUser;
- (NSString *)user;
- (void)setPassword:(NSString *)aPassword;
- (NSString *)password;
- (oneway void)terminateConnection;
@end

typedef struct _BDSKZoomGroupFlags {
    volatile int32_t isRetrieving   __attribute__ ((aligned (4)));
    volatile int32_t failedDownload __attribute__ ((aligned (4)));
    volatile int32_t needsReset     __attribute__ ((aligned (4)));
} BDSKZoomGroupFlags;    

@interface BDSKZoomGroupServer : BDSKAsynchronousDOServer <BDSKSearchGroupServer, BDSKZoomGroupServerMainThread, BDSKZoomGroupServerLocalThread>
{
    BDSKSearchGroup *group;
    BDSKZoomConnection *connection;
    NSString *host;
    int port;
    NSString *user;
    NSString *password;
    NSString *database;
    int availableResults;
    int fetchedResults;
    BDSKZoomGroupFlags flags;
    pthread_rwlock_t infolock;
}
- (void)resetConnection;
@end
