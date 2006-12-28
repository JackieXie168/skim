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


@implementation BDSKZoomGroupServer

- (id)initWithGroup:(BDSKSearchGroup *)aGroup serverInfo:(NSDictionary *)info;
{
    self = [super init];
    if (self) {
        group = aGroup;
        host = [[info objectForKey:@"host name"] copy];
        port = [[info objectForKey:@"port"] intValue];
        database = [[info objectForKey:@"database"] copy];
        flags.failedDownload = 0;
        flags.isRetrieving = 0;
        flags.needsReset = 1;
        availableResults = 0;
        fetchedResults = 0;
    }
    return self;
}

- (void)dealloc
{
    [self terminate];
    [connection release];
    [host release];
    [database release];
    [user release];
    [password release];
    [super dealloc];
}

- (Protocol *)protocolForMainThread { return @protocol(BDSKZoomGroupServerMainThread); }
- (Protocol *)protocolForServerThread { return @protocol(BDSKZoomGroupServerLocalThread); }

- (void)addPublicationsToGroup:(bycopy NSArray *)pubs;
{
    [group addPublications:pubs];
}

- (oneway void)downloadWithSearchTerm:(NSString *)searchTerm;
{
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.isRetrieving);
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.failedDownload);
    
    // only reset the connection when we're actually going to use it, since a mixed host/database/port won't work
    if (flags.needsReset)
        [self resetConnection];
    
    BDSKZoomResultSet *resultSet = [connection resultsForCCLQuery:searchTerm];
    
    if (nil == resultSet)
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.failedDownload);
    
    [self setAvailableResults:[resultSet countOfRecords]];
    
    // !!! maximum download of 25 is low, but this is really slow for some reason, at least using my canonical "bob dylan" search
    int numResults = MIN([self availableResults] - [self fetchedResults], 25);
    NSAssert(numResults >= 0, @"number of results to get must be non-negative");
    
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

- (void)resetConnection;
{
    [connection release];
    connection = [[BDSKZoomConnection alloc] initWithHost:[self host] port:[self port] database:[self database]];
    if (password)
        [connection setOption:password forKey:@"password"];
    if (user)
        [connection setOption:user forKey:@"user"];
    flags.needsReset = 0;
    [self setNumberOfAvailableResults:0];
    [self setNumberOfFetchedResults:0];
} 

#pragma mark BDSKSearchGroupServer protocol

// these are called on the main thread

- (void)terminate
{
    [[self serverOnServerThread] terminateConnection];
}

- (void)retrievePublications
{
    [[self serverOnServerThread] downloadWithSearchTerm:[group searchTerm]];
}

// @@ should the password/username be included in the serverInfo?
- (void)setServerInfo:(NSDictionary *)info;
{
    [[self serverOnServerThread] setHost:[info objectForKey:@"host"]];
    [[self serverOnServerThread] setPort:[[info objectForKey:@"port"] intValue]];
    [[self serverOnServerThread] setDatabase:[info objectForKey:@"database"]];
    [[self serverOnServerThread] setPassword:[info objectForKey:@"password"]];
    [[self serverOnServerThread] setUser:[info objectForKey:@"username"]];
}

- (NSDictionary *)serverInfo;
{
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:3];
    NSString *hostname = [[self serverOnServerThread] host];
    NSString *dbase = [[self serverOnServerThread] database];
    NSString *pass = [[self serverOnServerThread] password];
    NSString *username = [[self serverOnServerThread] user];
    int p = [(BDSKZoomGroupServer *)[self serverOnServerThread] port];
    if (hostname) [info setObject:hostname forKey:@"host"];
    if (dbase) [info setObject:dbase forKey:@"database"];
    if (pass) [info setObject:pass forKey:@"password"];
    if (username) [info setObject:username forKey:@"username"];
    [info setObject:[NSNumber numberWithInt:p] forKey:@"database"];
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
    OSAtomicCompareAndSwap32Barrier(1-flag, flag, (int32_t *)&flags.needsReset);
}

- (BOOL)needsReset { return 1 == flags.needsReset; }

#pragma mark Server thread 

- (oneway void)terminateConnection;
{
    [connection release];
    connection = nil;
    flags.needsReset = 1;
    flags.isRetrieving = 0;
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
    [host autorelease];
    host = [aHost copy];
    flags.needsReset = 1;
}

- (NSString *)host { return [[host retain] autorelease]; }

- (void)setPort:(int)n;
{ 
    port = n; 
    flags.needsReset = 1;
}    

- (int)port { return port; }

- (void)setDatabase:(NSString *)dbase;
{
    [database release];
    database = [dbase copy];
    flags.needsReset = 1;
}

- (NSString *)database { return [[database retain] autorelease]; }

- (void)setUser:(NSString *)aUser;
{
    [user autorelease];
    user = [aUser copy];
}

- (NSString *)user { return [[user retain] autorelease]; }

- (void)setPassword:(NSString *)aPassword;
{
    [password autorelease];
    password = [aPassword copy];
}

- (NSString *)password { return [[password retain] autorelease]; }

@end
