//
//  BDSKZoomGroupServer.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKZoomGroupServer.h"
#import "BDSKSearchGroup.h"
#import "BDSKStringParser.h"

// !!! maximum download of 25 is low, but this is really slow for some reason, at least using my canonical "bob dylan" search
#define MAX_RESULTS 25

@implementation BDSKZoomGroupServer

- (id)initWithGroup:(BDSKSearchGroup *)aGroup serverInfo:(NSDictionary *)info;
{
    [BDSKZoomRecord setFallbackEncoding:NSISOLatin1StringEncoding];
    
    self = [super init];
    if (self) {
        group = aGroup;
        host = [[info objectForKey:@"host"] copy];
        port = [[info objectForKey:@"port"] intValue];
        database = [[info objectForKey:@"database"] copy];
        flags.failedDownload = 0;
        flags.isRetrieving = 0;
        flags.needsReset = 1;
        availableResults = 0;
        fetchedResults = 0;
        pthread_rwlock_init(&infolock, NULL);
    }
    return self;
}

- (void)dealloc
{
    group = nil;
    [connection release], connection = nil;
    pthread_rwlock_wrlock(&infolock);
    [host release], host = nil;
    [database release], database = nil;
    [user release], user = nil;
    [password release], password = nil;
    pthread_rwlock_unlock(&infolock);
    pthread_rwlock_destroy(&infolock);
    [super dealloc];
}

- (Protocol *)protocolForMainThread { return @protocol(BDSKZoomGroupServerMainThread); }
- (Protocol *)protocolForServerThread { return @protocol(BDSKZoomGroupServerLocalThread); }

#pragma mark BDSKSearchGroupServer protocol

// these are called on the main thread

- (void)terminate
{
    [self stopDOServer];
}

- (void)stop
{
    [[self serverOnServerThread] terminateConnection];
}

- (void)retrievePublications
{
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.isRetrieving);
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.failedDownload);
    id server = [self serverOnServerThread];
    if (server)
        [server downloadWithSearchTerm:[group searchTerm]];
    else
        [self performSelector:_cmd withObject:nil afterDelay:0.1];
}

// @@ should the password/username be included in the serverInfo?
- (void)setServerInfo:(NSDictionary *)info;
{
    [self setHost:[info objectForKey:@"host"]];
    [self setPort:[[info objectForKey:@"port"] intValue]];
    [self setDatabase:[info objectForKey:@"database"]];
    [self setPassword:[info objectForKey:@"password"]];
    [self setUser:[info objectForKey:@"username"]];
}

- (NSDictionary *)serverInfo;
{
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:3];
    [info setValue:[NSNumber numberWithInt:BDSKSearchGroupZoom] forKey:@"type"];
    [info setValue:[self host] forKey:@"host"];
    [info setValue:[NSNumber numberWithInt:[(BDSKZoomGroupServer *)self port]] forKey:@"port"];
    [info setValue:[self database] forKey:@"database"];
    [info setValue:[self password] forKey:@"password"];
    [info setValue:[self user] forKey:@"username"];
    return info;
}

- (void)setNumberOfAvailableResults:(int)value;
{
    [[self serverOnServerThread] setAvailableResults:value];
}

- (int)numberOfAvailableResults;
{
    return [[self serverOnServerThread] availableResults];
}

- (void)setNumberOfFetchedResults:(int)value;
{
    [[self serverOnServerThread] setFetchedResults:value];
}

- (int)numberOfFetchedResults;
{
    return [[self serverOnServerThread] fetchedResults];
}

- (BOOL)failedDownload { return 1 == flags.failedDownload; }

- (BOOL)isRetrieving { return 1 == flags.isRetrieving; }

- (void)setNeedsReset:(BOOL)flag {
    int32_t new = flag ? 1 : 0, old = flag ? 0 : 1;
    OSAtomicCompareAndSwap32Barrier(old, new, (int32_t *)&flags.needsReset);
}

- (BOOL)needsReset { return 1 == flags.needsReset; }

#pragma mark Main thread 

- (void)addPublicationsToGroup:(bycopy NSArray *)pubs;
{
    [group addPublications:pubs];
}

#pragma mark Server thread 

- (void)resetConnection;
{
    [connection release];
    connection = [[BDSKZoomConnection alloc] initWithHost:[self host] port:[self port] database:[self database]];
    NSString *value = [self password];
    if ([NSString isEmptyString:value] == NO)
        [connection setOption:value forKey:@"password"];
    value = [self user];
    if ([NSString isEmptyString:value] == NO)
        [connection setOption:value forKey:@"user"];
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.needsReset);
    [self setNumberOfAvailableResults:0];
    [self setNumberOfFetchedResults:0];
} 

- (oneway void)terminateConnection;
{
    [connection release];
    connection = nil;
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.needsReset);
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.isRetrieving);
} 

- (oneway void)downloadWithSearchTerm:(NSString *)searchTerm;
{
    // only reset the connection when we're actually going to use it, since a mixed host/database/port won't work
    if (flags.needsReset)
        [self resetConnection];
    
    BDSKZoomResultSet *resultSet = [connection resultsForCCLQuery:searchTerm];
    
    if (nil == resultSet)
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.failedDownload);
    
    [self setAvailableResults:[resultSet countOfRecords]];
    
    int numResults = MIN([self availableResults] - [self fetchedResults], MAX_RESULTS);
    //NSAssert(numResults >= 0, @"number of results to get must be non-negative");
    
    NSMutableArray *pubs = nil;
    
    if(numResults > 0){
        NSArray *records = [resultSet recordsInRange:NSMakeRange([self fetchedResults], numResults)];
        
        [self setFetchedResults:[self fetchedResults] + numResults];
        
        pubs = [NSMutableArray array];
        BDSKZoomRecord *record;
        int i, iMax = [records count];
        for (i = 0; i < iMax; i++) {
            record = [records objectAtIndex:i];
            BibItem *anItem = [[BDSKStringParser itemsFromString:[record rawString] error:NULL] lastObject];
            if (anItem)
                [pubs addObject:anItem];
        }
    }
    
    // set this flag before adding pubs, or the client will think we're still retrieving (and spinners don't stop)
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.isRetrieving);

    // this will create the array if it doesn't exist
    [[self serverOnMainThread] addPublicationsToGroup:pubs];
}

- (oneway void)cleanup{
    [self terminateConnection];
    [super cleanup];
}

- (void)setAvailableResults:(int)value;
{
    availableResults = value;
}

- (int)availableResults;
{
    return availableResults;
}

- (void)setFetchedResults:(int)value;
{
    fetchedResults = value;
}

- (int)fetchedResults;
{
    return fetchedResults;
}

- (void)setHost:(NSString *)aHost;
{
    pthread_rwlock_wrlock(&infolock);
    [host autorelease];
    host = [aHost copy];
    pthread_rwlock_unlock(&infolock);
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.needsReset);
}

- (NSString *)host {
    pthread_rwlock_rdlock(&infolock);
    NSString *aHost = [[host retain] autorelease];
    pthread_rwlock_unlock(&infolock);
    return aHost;
}

- (void)setPort:(int)n;
{ 
    pthread_rwlock_wrlock(&infolock);
    port = n; 
    pthread_rwlock_unlock(&infolock);
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.needsReset);
}    

- (int)port {
    pthread_rwlock_rdlock(&infolock);
    int n = port;
    pthread_rwlock_unlock(&infolock);
    return n;
}

- (void)setDatabase:(NSString *)dbase;
{
    pthread_rwlock_wrlock(&infolock);
    [database release];
    database = [dbase copy];
    pthread_rwlock_unlock(&infolock);
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.needsReset);
}

- (NSString *)database {
    pthread_rwlock_rdlock(&infolock);
    NSString *dbase = [[database retain] autorelease];
    pthread_rwlock_unlock(&infolock);
    return dbase;
}

- (void)setUser:(NSString *)aUser;
{
    pthread_rwlock_wrlock(&infolock);
    [user autorelease];
    user = [aUser copy];
    pthread_rwlock_unlock(&infolock);
}

- (NSString *)user {
    pthread_rwlock_rdlock(&infolock);
    NSString *aUser = [[user retain] autorelease];
    pthread_rwlock_unlock(&infolock);
    return aUser;
}

- (void)setPassword:(NSString *)aPassword;
{
    pthread_rwlock_wrlock(&infolock);
    [password autorelease];
    password = [aPassword copy];
    pthread_rwlock_unlock(&infolock);
}

- (NSString *)password { 
    pthread_rwlock_rdlock(&infolock);
    NSString *aPassword = [[password retain] autorelease];
    pthread_rwlock_unlock(&infolock);
    return aPassword;
}

@end
