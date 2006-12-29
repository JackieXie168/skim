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
#import "BDSKThreadSafeMutableDictionary.h"

// !!! maximum download of 25 is low, but this is really slow for some reason, at least using my canonical "bob dylan" search
#define MAX_RESULTS 25

@implementation BDSKZoomGroupServer

- (id)initWithGroup:(BDSKSearchGroup *)aGroup serverInfo:(NSDictionary *)info;
{
    [BDSKZoomRecord setFallbackEncoding:NSISOLatin1StringEncoding];
    
    self = [super init];
    if (self) {
        group = aGroup;
        serverInfo = [[BDSKThreadSafeMutableDictionary alloc] initWithCapacity:4];
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
    group = nil;
    [connection release], connection = nil;
    [serverInfo release], serverInfo = nil;
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

- (void)setServerInfo:(NSDictionary *)info;
{
    [serverInfo setDictionary:info];
    [serverInfo setObject:[NSNumber numberWithInt:BDSKSearchGroupZoom] forKey:@"type"];
    [self setNeedsReset:YES];
}

- (NSDictionary *)serverInfo;
{
    return [[serverInfo copy] autorelease];
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
    NSString *host = [serverInfo objectForKey:@"host"];
    int port = [[serverInfo objectForKey:@"port"] intValue];
    NSString *database = [serverInfo objectForKey:@"database"];
    NSString *password = [serverInfo objectForKey:@"password"];
    NSString *user = [serverInfo objectForKey:@"username"];
    
    [connection release];
    connection = [[BDSKZoomConnection alloc] initWithHost:host port:port database:database];
    if ([NSString isEmptyString:password] == NO)
        [connection setOption:password forKey:@"password"];
    if ([NSString isEmptyString:user] == NO)
        [connection setOption:user forKey:@"user"];
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

@end
