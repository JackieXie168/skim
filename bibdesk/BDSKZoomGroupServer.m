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
#import "BDSKServerInfo.h"
#import "BibItem.h"

#define MAX_RESULTS 100


@implementation BDSKZoomGroupServer

+ (void)initialize
{
    OBINITIALIZE;
    [BDSKZoomRecord setFallbackEncoding:NSISOLatin1StringEncoding];
}

- (id)initWithGroup:(BDSKSearchGroup *)aGroup serverInfo:(BDSKServerInfo *)info;
{    
    self = [super init];
    if (self) {
        group = aGroup;
        serverInfo = [info copy];
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
    pthread_rwlock_destroy(&infolock);
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
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.isRetrieving);
}

- (void)stop
{
    [[self serverOnServerThread] terminateConnection];
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.isRetrieving);
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

- (void)setServerInfo:(BDSKServerInfo *)info;
{
    pthread_rwlock_wrlock(&infolock);
    if (serverInfo != info) {
        [serverInfo release];
        serverInfo = [info copy];
    }
    pthread_rwlock_unlock(&infolock);
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.needsReset);
}

- (BDSKServerInfo *)serverInfo;
{
    pthread_rwlock_rdlock(&infolock);
    BDSKServerInfo *info = [[serverInfo copy] autorelease];
    pthread_rwlock_unlock(&infolock);
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

#pragma mark Main thread 

- (void)addPublicationsToGroup:(bycopy NSArray *)pubs;
{
    [group addPublications:pubs];
}

#pragma mark Server thread 

- (void)resetConnection;
{
    BDSKServerInfo *info = [self serverInfo];
    
    OBASSERT([info host] != nil);
    
    [connection release];
    if ([info host] != nil) {
        connection = [[BDSKZoomConnection alloc] initWithHost:[info host] port:[[info port] intValue] database:[info database]];
        if ([NSString isEmptyString:[info password]] == NO)
            [connection setOption:[info password] forKey:@"password"];
        if ([NSString isEmptyString:[info username]] == NO)
            [connection setOption:[info username] forKey:@"user"];
        if ([[info options] objectForKey:@"preferredRecordSyntax"])
            [connection setOption:[[info options] objectForKey:@"preferredRecordSyntax"] forKey:@"preferredRecordSyntax"];    
        NSStringEncoding enc = [NSString encodingForIANACharSetName:[[info options] objectForKey:@"resultEncoding"]];
        if (enc)
            [connection setResultEncoding:enc];
        OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.needsReset);
    }else {
        connection = nil;
    }
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

- (int)stringTypeForRecordString:(NSString *)string
{
    NSString *preferredRecordSyntax = [[serverInfo options] objectForKey:@"preferredRecordSyntax"];
    int stringType = BDSKUnknownStringType;
    if([preferredRecordSyntax isEqualToString:[BDSKZoomRecord stringWithSyntaxType:USMARC]] || [preferredRecordSyntax isEqualToString:[BDSKZoomRecord stringWithSyntaxType:UKMARC]]) {
        stringType = BDSKMARCStringType;
    } else if([preferredRecordSyntax isEqualToString:[BDSKZoomRecord stringWithSyntaxType:XML]]) {
        stringType = [BDSKStringParser canParseString:string ofType:BDSKMARCStringType] ? BDSKMARCStringType : BDSKDublinCoreStringType;
    }
    if (NO == [BDSKStringParser canParseString:string ofType:stringType])
        stringType = BDSKUnknownStringType;
    return stringType;
}

- (oneway void)downloadWithSearchTerm:(NSString *)searchTerm;
{
    // only reset the connection when we're actually going to use it, since a mixed host/database/port won't work
    if (flags.needsReset)
        [self resetConnection];
    
    NSMutableArray *pubs = nil;
    
    if(NO == [NSString isEmptyString:searchTerm]){
        // the resultSet is cached for each searchTerm, so we have no overhead calling it for retrieving more results
        BDSKZoomResultSet *resultSet = [connection resultsForCCLQuery:searchTerm];
        
        if (nil == resultSet)
            OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.failedDownload);
        
        [self setAvailableResults:[resultSet countOfRecords]];
        
        int numResults = MIN([self availableResults] - [self fetchedResults], MAX_RESULTS);
        //NSAssert(numResults >= 0, @"number of results to get must be non-negative");
        
        if(numResults > 0){
            NSArray *records = [resultSet recordsInRange:NSMakeRange([self fetchedResults], numResults)];
            
            [self setFetchedResults:[self fetchedResults] + numResults];
            
            pubs = [NSMutableArray array];
            int i, iMax = [records count];
            NSString *record;
            int stringType;
            BibItem *anItem;
            for (i = 0; i < iMax; i++) {
                record = [[records objectAtIndex:i] rawString];
                stringType = [self stringTypeForRecordString:record];
                if (anItem = [[BDSKStringParser itemsFromString:record ofType:stringType error:NULL] lastObject])
                    [pubs addObject:anItem];
            }
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
