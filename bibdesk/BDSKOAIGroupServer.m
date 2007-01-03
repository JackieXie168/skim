//
//  BDSKOAIGroupServer.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 1/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BDSKOAIGroupServer.h"
#import "BDSKSearchGroup.h"
#import "BibTeXParser.h"
#import "BDSKStringParser.h"
#import "BibAppController.h"
#import <WebKit/WebKit.h>
#import "BDSKServerInfo.h"


@implementation BDSKOAIGroupServer

- (id)initWithGroup:(BDSKSearchGroup *)aGroup serverInfo:(BDSKServerInfo *)info;
{
    self = [super init];
    if (self) {
        group = aGroup;
        serverInfo = [info copy];
        searchTerm = nil;
        resumptionToken = nil;
        failedDownload = NO;
        isRetrieving = NO;
        needsReset = NO;
        availableResults = 0;
        filePath = nil;
        URLDownload = nil;
    }
    return self;
}

- (void)dealloc
{
    [serverInfo release];
    [filePath release];
    [resumptionToken release];
    [sets release];
    [super dealloc];
}

#pragma mark BDSKSearchGroupServer protocol

- (void)terminate;
{
    [self stop];
}

- (void)stop;
{
    [URLDownload cancel];
    [URLDownload release];
    URLDownload = nil;
    isRetrieving = NO;
}

- (void)retrievePublications {
    isRetrieving = YES;
    if ([[self searchTerm] isEqualToString:[group searchTerm]] == NO || needsReset)
        [self resetSearch];
    [self fetch];
}

- (BDSKServerInfo *)serverInfo { return serverInfo; }

- (void)setServerInfo:(BDSKServerInfo *)info;
{
    if(serverInfo != info){
        [serverInfo release];
        serverInfo = [info copy];
        needsReset = YES;
    }
}

- (void)setNumberOfAvailableResults:(int)value;
{
    availableResults = value;
}

- (int)numberOfFetchedResults { return fetchedResults; }

- (void)setNumberOfFetchedResults:(int)value;
{
    fetchedResults = value;
}

- (int)numberOfAvailableResults { return availableResults; }

- (BOOL)failedDownload { return failedDownload; }

- (BOOL)isRetrieving { return isRetrieving; }

- (NSFormatter *)searchStringFormatter { return nil; }

#pragma mark Other accessors

- (void)setSearchTerm:(NSString *)string;
{
    if(searchTerm != string){
        [searchTerm release];
        searchTerm = [string copy];
    }
}

- (NSString *)searchTerm { return searchTerm; }

- (void)setSets:(NSArray *)newSets;
{
    if(sets != newSets){
        [sets release];
        sets = [newSets copy];
    }
}

- (NSArray *)sets {
    if (sets == nil)
        [self fetchSets];
    return sets;
}

- (void)setResumptionToken:(NSString *)newResumptionToken {
    if (resumptionToken != newResumptionToken) {
        [resumptionToken release];
        resumptionToken = [newResumptionToken retain];
    }
}

- (NSString *)resumptionToken { return resumptionToken; }

#pragma mark Search methods

- (void)fetchSets;
{
    NSString *listSets = [[[self serverInfo] host] stringByAppendingString:@"?verb=ListSets"];
    NSURL *initialURL = [NSURL URLWithString:listSets]; 
    OBPRECONDITION(initialURL);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:initialURL];
    NSURLResponse *response;
    NSError *error;
    NSData *listSetsResult = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSXMLDocument *document = nil;
    
    if (nil == listSetsResult)
        NSLog(@"failed to download %@ with error %@", initialURL, error);
    else
        document = [[NSXMLDocument alloc] initWithData:listSetsResult options:NSXMLNodeOptionsNone error:&error];
    
    if (nil != document) {
        [self setSets:[[[document rootElement] nodesForXPath:@"/OAI-PMH[1]/ListSets/set/setSpec" error:NULL] arrayByPerformingSelector:@selector(stringvalue)]];
        
        [document release];
        
    } else if (nil != listSetsResult) {
        [self setSets:nil];
        // make sure error was actually initialized by NSXMLDocument
        NSLog(@"unable to create an XML document: %@", error);
    }
}

- (void)resetSearch;
{
    [self setSearchTerm:[group searchTerm]];
    [self setNumberOfAvailableResults:0];
    [self setNumberOfFetchedResults:0];
    [self setResumptionToken:nil];
}

- (void)fetch;
{
    NSMutableArray *escapedComponents = [NSMutableArray arrayWithCapacity:3]; 
    NSEnumerator *componentsEnum = [[[self searchTerm] componentsSeparatedByString:@"&"] objectEnumerator];
    NSString *component;
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@?verb=ListRecords&", [[self serverInfo] host]];
    
    while (component = [componentsEnum nextObject]) {
        if (NSMaxRange([component rangeOfString:@"="]) < [component length])
            [urlString appendFormat:@"%@&", [component stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    if ([self resumptionToken])
        [urlString appendFormat:@"resumptionToken=%@&", [self resumptionToken]];
    [urlString appendString:@"metadataPrefix=oai_dc"];
    
    NSURL *theURL = [NSURL URLWithString:urlString];
    OBPOSTCONDITION(theURL);
    
    [self startDownloadFromURL:theURL];
}

#pragma mark URL download

- (void)startDownloadFromURL:(NSURL *)theURL;
{
    NSURLRequest *request = [NSURLRequest requestWithURL:theURL];
    // we use a WebDownload since it's supposed to add authentication dialog capability
    if (URLDownload)
        [URLDownload cancel];
    [URLDownload release];
    URLDownload = [[WebDownload alloc] initWithRequest:request delegate:self];
    [URLDownload setDestination:[[NSApp delegate] temporaryFilePath:nil createDirectory:NO] allowOverwrite:NO];
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path
{
    [filePath autorelease];
    filePath = [path copy];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    isRetrieving = NO;
    failedDownload = NO;
    NSError *error = nil;
    
    if (URLDownload) {
        [URLDownload release];
        URLDownload = nil;
    }

    // tried using -[NSString stringWithContentsOfFile:usedEncoding:error:] but it fails too often
    NSString *contentString = [NSString stringWithContentsOfFile:filePath encoding:NSASCIIStringEncoding guessEncoding:YES];
    
    [self setResumptionToken:nil];
    
    NSArray *pubs = nil;
    if (nil == contentString) {
        failedDownload = YES;
    } else {
        NSXMLDocument *document = [[NSXMLDocument alloc] initWithXMLString:contentString options:NSXMLNodeOptionsNone error:&error];
        
        if (nil != document) {
            [self setResumptionToken:[[[[document rootElement] nodesForXPath:@"/OAI-PMH[1]/ListRecords/resumptionToken" error:NULL] lastObject] stringValue]];
            
            [document release];
            
        } else {
            failedDownload = YES;
        }
        
        pubs = [BDSKStringParser itemsFromString:contentString ofType:BDSKDublinCoreStringType error:&error];
        if (pubs == nil || error) {
            failedDownload = YES;
            [NSApp presentError:error];
        }
        
        [self setNumberOfFetchedResults:[self numberOfFetchedResults] + [pubs count]];
        [self setNumberOfAvailableResults:[self numberOfFetchedResults] + ([self resumptionToken] ? 1 : 0)];
    }
    [group addPublications:pubs];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    isRetrieving = NO;
    failedDownload = YES;
    
    if (URLDownload) {
        [URLDownload release];
        URLDownload = nil;
    }
    
    // redraw 
    [group addPublications:nil];
    [NSApp presentError:error];
}

@end
