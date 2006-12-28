//
//  BDSKZoomGroup.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKZoomGroup.h"
#import <yaz/BDSKZoom.h>
#import "BDSKStringParser.h"
#import "BDSKAsynchronousDOServer.h"
#import "BDSKPublicationsArray.h"
#import "BDSKMacroResolver.h"
#import "NSImage+Toolbox.h"

// private protocols for inter-thread messaging
@protocol BDSKZoomGroupServerMainThread <BDSKAsyncDOServerMainThread>
- (void)addPublicationsToGroup:(bycopy NSArray *)pubs;
@end

@protocol BDSKZoomGroupServerLocalThread <BDSKAsyncDOServerThread>
- (int)numberOfAvailableResults;
- (oneway void)downloadWithSearchTerm:(NSString *)searchTerm groupCount:(int)groupCount;
- (void)setHost:(NSString *)aHost;
- (void)setPort:(int)n;
@end

typedef struct _BDSKZoomGroupFlags {
    volatile int32_t isRetrieving   __attribute__ ((aligned (4)));
    volatile int32_t failedDownload __attribute__ ((aligned (4)));
    volatile int32_t needsReset     __attribute__ ((aligned (4)));
} BDSKZoomGroupFlags;    

@interface BDSKZoomGroupServer : BDSKAsynchronousDOServer
{
    BDSKZoomGroup *group;
    BDSKZoomConnection *connection;
    NSString *host;
    int port;
    NSString *database;
    int availableResults;
    BDSKZoomGroupFlags flags;
}
- (id)initWithGroup:(BDSKZoomGroup *)aGroup host:(NSString *)hostname port:(int)n database:(NSString *)dbase;
- (void)setNumberOfAvailableResults:(int)value;
- (int)numberOfAvailableResults;
- (void)retrievePublications;
- (void)resetConnection;
- (void)setHost:(NSString *)aHost;
- (void)setPort:(int)n;
- (void)setDatabase:(NSString *)dbase;
- (NSString *)host;
- (int)port;
- (NSString *)database;
- (BOOL)failedDownload;
- (BOOL)isRetrieving;

@end


@implementation BDSKZoomGroup

- (id)initWithName:(NSString *)aName;
{
    return [self initWithHost:aName port:0 database:nil searchTerm:nil];
}

- (id)initWithHost:(NSString *)hostname port:(int)num database:(NSString *)dbase searchTerm:(NSString *)string;
{
    
    [BDSKZoomRecord setFallbackEncoding:NSISOLatin1StringEncoding];
    
    self = [super initWithName:hostname count:0];
    if (self) {
        searchTerm = [string copy];
        macroResolver = [[BDSKMacroResolver alloc] initWithOwner:self];
        server = [[BDSKZoomGroupServer alloc] initWithGroup:self host:hostname port:num database:dbase];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)groupDict {
    NSString *aName = [[groupDict objectForKey:@"group name"] stringByUnescapingGroupPlistEntities];
    NSString *aHostName = [[groupDict objectForKey:@"host name"] stringByUnescapingGroupPlistEntities];
    int aPort = [[groupDict objectForKey:@"port"] intValue];
    NSString *aSearchTerm = [[groupDict objectForKey:@"search term"] stringByUnescapingGroupPlistEntities];
    NSString *dbase = [[groupDict objectForKey:@"database"] stringByUnescapingGroupPlistEntities];
    self = [self initWithHost:aHostName port:aPort database:dbase searchTerm:aSearchTerm];
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSString *aName = [[self stringValue] stringByEscapingGroupPlistEntities];
    NSString *aHostName = [[self host] stringByEscapingGroupPlistEntities];
    NSString *aSearchTerm = [[self searchTerm] stringByEscapingGroupPlistEntities];
    NSNumber *aPort = [NSNumber numberWithInt:[self port]];
    NSString *dbase = [[self database] stringByEscapingGroupPlistEntities];
    return [NSDictionary dictionaryWithObjectsAndKeys:aName, @"group name", aHostName, @"host name", aPort, @"port", aSearchTerm, @"search term", dbase, @"database", nil];
}

- (void)dealloc
{
    [server stopDOServer];
    [server release];
    [publications release];
    [searchTerm release];
    [macroResolver release];
    [super dealloc];
}

// note that pointer equality is used for these groups, so names can overlap, and users can have duplicate searches

- (NSImage *)icon {
    return [NSImage smallImageNamed:@"searchFolderIcon"];
}

- (NSString *)name { return [NSString isEmptyString:[self searchTerm]] ? NSLocalizedString(@"Empty", @"") : [self searchTerm]; }

- (BOOL)isRetrieving { return [server isRetrieving]; }

- (BOOL)failedDownload { return [server failedDownload]; }

- (BOOL)isEditable { return YES; }

- (BOOL)hasEditableName { return NO; }

- (BOOL)isSearch { return YES; }

- (void)setSearchTerm:(NSString *)aTerm;
{
    if ([searchTerm isEqualToString:aTerm] == NO) {
        [searchTerm autorelease];
        searchTerm = [aTerm copy];
        [self search];
    }
}

- (NSString *)searchTerm { return searchTerm; }

- (BDSKPublicationsArray *)publications;
{
    if([self isRetrieving] == NO && publications == nil && [NSString isEmptyString:[self searchTerm]] == NO){
        // get initial batch of publications
        [server retrievePublications];
        
        // use this to notify the tableview to start the progress indicators
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKURLGroupUpdatedNotification object:self userInfo:userInfo];
    }
    // this posts a notification that the publications of the group changed, forcing a redisplay of the table cell
    return publications;
}

- (void)setPublications:(NSArray *)newPublications;
{
    if(newPublications != publications){
        [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
        [publications release];
        publications = newPublications == nil ? nil : [[BDSKPublicationsArray alloc] initWithArray:newPublications];
        [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
        
        if (publications == nil)
            [macroResolver removeAllMacros];
    }
    
    [self setCount:[publications count]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:(publications != nil)] forKey:@"succeeded"];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKURLGroupUpdatedNotification object:self userInfo:userInfo];
}

- (void)addPublications:(NSArray *)newPublications;
{    
    if(newPublications != publications && newPublications != nil){
        
        if (publications == nil)
            publications = [[BDSKPublicationsArray alloc] initWithArray:newPublications];
        else 
            [publications addObjectsFromArray:newPublications];
        [newPublications makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
    }
    
    [self setCount:[publications count]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:(newPublications != nil)] forKey:@"succeeded"];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKURLGroupUpdatedNotification object:self userInfo:userInfo];
}

- (BDSKMacroResolver *)macroResolver;
{
    return macroResolver;
}

- (NSUndoManager *)undoManager { return nil; }

- (NSURL *)fileURL { return nil; }

- (NSString *)documentInfoForKey:(NSString *)key { return nil; }

- (BOOL)isDocument { return NO; }

#warning Need formal protocol for search groups
- (void)search;
{
    [[server serverOnServerThread] setNumberOfAvailableResults:0];
    
    if ([NSString isEmptyString:[self searchTerm]]) {
        [self setPublications:[NSArray array]];
    } else {
        [self setPublications:nil];
        [server retrievePublications];
        
        // use this to notify the tableview to start the progress indicators and disable the button
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKURLGroupUpdatedNotification object:self userInfo:userInfo];
    }
}

- (void)searchNext;
{
    // what should this do in the case of an empty string?
    if ([NSString isEmptyString:[self searchTerm]]) {
        [[server serverOnServerThread] setNumberOfAvailableResults:0];
        [self setPublications:[NSArray array]];
    } else {
        [server retrievePublications];
        
        // use this to notify the tableview to start the progress indicators and disable the button
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKURLGroupUpdatedNotification object:self userInfo:userInfo];
    }
}

- (BOOL)canGetMoreResults;
{
    return ([[server serverOnServerThread] numberOfAvailableResults] > [self count] || ([NSString isEmptyString:[self searchTerm]] == NO && publications == nil));
}

- (int)numberOfAvailableResults { return [[server serverOnServerThread] numberOfAvailableResults]; }

- (void)setHost:(NSString *)aHost;
{
    [[server serverOnServerThread] setHost:aHost];
}

- (void)setPort:(int)n { 
    [[server serverOnServerThread] setPort:n]; 
}   

- (void)setDatabase:(NSString *)dbase;
{
    [[server serverOnServerThread] setDatabase:dbase];
}

- (NSString *)host { return [server host]; }
- (int)port { return [server port]; }
- (NSString *)database { return [server database]; }

@end

@implementation BDSKZoomGroupServer

- (id)initWithGroup:(BDSKZoomGroup *)aGroup host:(NSString *)hostname port:(int)n database:(NSString *)dbase;
{
    self = [super init];
    if (self) {
        group = aGroup;
        host = [hostname copy];
        port = n;
        database = [dbase copy];
        [self resetConnection];
        flags.failedDownload = 0;
        flags.isRetrieving = 0;
        flags.needsReset = 0;
        [self setNumberOfAvailableResults:0];
    }
    return self;
}

- (void)dealloc
{
    [host release];
    [database release];
    [connection release];
    [super dealloc];
}

- (Protocol *)protocolForMainThread { return @protocol(BDSKZoomGroupServerMainThread); }
- (Protocol *)protocolForServerThread { return @protocol(BDSKZoomGroupServerLocalThread); }

- (void)setNumberOfAvailableResults:(int)value;
{
    availableResults = value;
}

- (int)numberOfAvailableResults;
{
    return availableResults;
}

- (void)addPublicationsToGroup:(bycopy NSArray *)pubs;
{
    [group addPublications:pubs];
}

- (oneway void)downloadWithSearchTerm:(NSString *)searchTerm groupCount:(int)groupCount;
{
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.isRetrieving);
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.failedDownload);
    
    // only reset the connection when we're actually going to use it, since a mixed host/database/port won't work
    if (flags.needsReset)
        [self resetConnection];
    
    BDSKZoomResultSet *resultSet = [connection resultsForCCLQuery:searchTerm];
    
    if (nil == resultSet)
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.failedDownload);
    
    [self setNumberOfAvailableResults:[resultSet countOfRecords]];
    
    // !!! maximum download of 25 is low, but this is really slow for some reason, at least using my canonical "bob dylan" search
    int numResults = MIN([self numberOfAvailableResults] - groupCount, 25);
    NSAssert(numResults >= 0, @"number of results to get must be non-negative");
    
    NSArray *records = [resultSet recordsInRange:NSMakeRange(groupCount, numResults)];
    
    NSMutableArray *pubs = [NSMutableArray array];
    BDSKZoomRecord *record;
    int i, iMax = [records count];
    for (i = 0; i < iMax; i++) {
        record = [records objectAtIndex:i];
        BibItem *anItem = [[BDSKStringParser itemsFromString:[record rawString] error:NULL] lastObject];
        if (anItem)
            [pubs addObject:anItem];
    }
    
    // set this flag before adding pubs, or the client will think we're still retrieving (and spinners don't stop)
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.isRetrieving);

    // this will create the array if it doesn't exist
    [[self serverOnMainThread] addPublicationsToGroup:pubs];
}

- (void)retrievePublications
{
    [[self serverOnServerThread] downloadWithSearchTerm:[group searchTerm] groupCount:[group count]];
}

- (void)resetConnection;
{
    [connection release];
    connection = [[BDSKZoomConnection alloc] initWithHost:[self host] port:[self port] database:[self database]];
    flags.needsReset = 0;
} 

- (void)setHost:(NSString *)aHost;
{
    [host autorelease];
    host = [aHost copy];
    flags.needsReset = 1;
}

- (void)setPort:(int)n;
{ 
    port = n; 
    flags.needsReset = 1;
}    

- (void)setDatabase:(NSString *)dbase;
{
    [database release];
    database = [dbase copy];
    flags.needsReset = 1;
}

- (NSString *)host { return [[host retain] autorelease]; }
- (int)port { return port; }
- (NSString *)database { return [[database retain] autorelease]; }

- (BOOL)failedDownload { return 1 == flags.failedDownload; }
- (BOOL)isRetrieving { return 1 == flags.isRetrieving; }

@end
