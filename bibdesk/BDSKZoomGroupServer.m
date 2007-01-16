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

#import "BDSKZoomGroupServer.h"
#import "BDSKSearchGroup.h"
#import "BDSKStringParser.h"
#import "BDSKServerInfo.h"
#import "BibItem.h"

#define MAX_RESULTS 100

static NSString *BDSKUSMARCString = @"US MARC";
static NSString *BDSKMARCXMLString = @"MARC XML";
static NSString *BDSKDCXMLString = @"DC XML";

@implementation BDSKZoomGroupServer

+ (void)initialize
{
    OBINITIALIZE;
    [ZOOMRecord setFallbackEncoding:NSISOLatin1StringEncoding];
}

+ (NSArray *)supportedRecordSyntaxes {
    return [NSArray arrayWithObjects:BDSKUSMARCString, BDSKMARCXMLString, BDSKDCXMLString, nil];
}

+ (ZOOMSyntaxType)zoomRecordSyntaxForRecordSyntaxString:(NSString *)syntax{
    if ([syntax isEqualToString:BDSKUSMARCString]) 
        return USMARC;
    else if ([syntax isEqualToString:BDSKMARCXMLString] || [syntax isEqualToString:BDSKDCXMLString]) 
        return XML;
    else
        return UNKNOWN;
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

- (NSFormatter *)searchStringFormatter { return [[[ZOOMCCLQueryFormatter alloc] initWithConfigString:[[[self serverInfo] options] objectForKey:@"queryConfig"]] autorelease]; }

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
        connection = [[ZOOMConnection alloc] initWithHost:[info host] port:[[info port] intValue] database:[info database]];
        [connection setPassword:[info password]];
        [connection setUsername:[info username]];
        ZOOMSyntaxType syntax = [[self class] zoomRecordSyntaxForRecordSyntaxString:[info recordSyntax]];
        if(syntax != UNKNOWN)
            [connection setPreferredRecordSyntax:syntax];    

        [connection setResultEncodingToIANACharSetName:[info resultEncoding]];
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
    NSString *recordSyntax = [serverInfo recordSyntax];
    int stringType = BDSKUnknownStringType;
    if([recordSyntax isEqualToString:BDSKUSMARCString]) {
        stringType = BDSKMARCStringType;
    } else if([recordSyntax isEqualToString:BDSKMARCXMLString]) {
        stringType = BDSKMARCStringType;
        if ([BDSKStringParser canParseString:string ofType:stringType] == NO)
            stringType = BDSKDublinCoreStringType;
    } else if([recordSyntax isEqualToString:BDSKDCXMLString]) {
        stringType = BDSKDublinCoreStringType;
        if ([BDSKStringParser canParseString:string ofType:stringType] == NO)
            stringType = BDSKMARCStringType;
    }
    if (NO == [BDSKStringParser canParseString:string ofType:stringType])
        stringType = [string contentStringType];
    return stringType;
}

- (oneway void)downloadWithSearchTerm:(NSString *)searchTerm;
{
    // only reset the connection when we're actually going to use it, since a mixed host/database/port won't work
    if (flags.needsReset)
        [self resetConnection];
    
    NSMutableArray *pubs = nil;
    BDSKServerInfo *info = [self serverInfo];
    
    if (searchTerm && [info removeDiacritics]) {
        CFMutableStringRef mutableCopy = (CFMutableStringRef)[[searchTerm mutableCopy] autorelease];
        CFStringNormalize(mutableCopy, kCFStringNormalizationFormD);
        BDDeleteCharactersInCharacterSet(mutableCopy, CFCharacterSetGetPredefined(kCFCharacterSetNonBase));
        searchTerm = (NSString *)mutableCopy;
    }
            
    if (NO == [NSString isEmptyString:searchTerm]){
        // the resultSet is cached for each searchTerm, so we have no overhead calling it for retrieving more results
        ZOOMQuery *query = [ZOOMQuery queryWithCCLString:searchTerm config:[[info options] objectForKey:@"queryConfig"]];
        
        ZOOMResultSet *resultSet = query ? [connection resultsForQuery:query] : nil;
        
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
