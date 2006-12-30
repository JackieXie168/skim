//
//  BDSKEntrezGroupServer.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 12/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

// max number of results from NCBI is 100, except on evenings and weekends
#define MAX_RESULTS 50

/* Based on public domain sample code written by Oleg Khovayko, available at
 http://www.ncbi.nlm.nih.gov/entrez/query/static/eutils_example.pl
 
 - We limit requests to 100 in the editor interface, per NCBI's request.  
 - We also pass tool=bibdesk for their tracking purposes.  
 - We use lower case characters in the URL /except/ for WebEnv
 - See http://www.ncbi.nlm.nih.gov/entrez/query/static/eutils_help.html for details.
 
 */

#import "BDSKEntrezGroupServer.h"
#import "BDSKSearchGroup.h"
#import "BibTeXParser.h"
#import "BDSKStringParser.h"
#import "BibAppController.h"
#import <WebKit/WebKit.h>
#import "BDSKServerInfo.h"


@implementation BDSKEntrezGroupServer

+ (NSString *)baseURLString { return @"http://eutils.ncbi.nlm.nih.gov/entrez/eutils"; }

// may be useful for UI validation
+ (BOOL)canConnect;
{
    CFURLRef theURL = (CFURLRef)[NSURL URLWithString:[self baseURLString]];
    CFNetDiagnosticRef diagnostic = CFNetDiagnosticCreateWithURL(CFGetAllocator(theURL), theURL);
    
    NSString *details;
    CFNetDiagnosticStatus status = CFNetDiagnosticCopyNetworkStatusPassively(diagnostic, (CFStringRef *)&details);
    CFRelease(diagnostic);
    [details autorelease];
    
    BOOL canConnect = kCFNetDiagnosticConnectionUp == status;
    if (NO == canConnect)
        NSLog(@"%@", details);
    
    return canConnect;
}

- (id)initWithGroup:(BDSKSearchGroup *)aGroup serverInfo:(BDSKServerInfo *)info;
{
    self = [super init];
    if (self) {
        group = aGroup;
        serverInfo = [info copy];
        searchTerm = nil;
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

#pragma mark Other accessors

- (void)setSearchTerm:(NSString *)string;
{
    if(searchTerm != string){
        [searchTerm release];
        searchTerm = [string copy];
    }
}

- (NSString *)searchTerm { return searchTerm; }

- (void)setWebEnv:(NSString *)env;
{
    if(webEnv != env){
        [webEnv release];
        webEnv = [env copy];
    }
}

- (NSString *)webEnv { return webEnv; }

- (void)setQueryKey:(NSString *)aKey;
{
    if(queryKey != aKey){
        [queryKey release];
        queryKey = [aKey copy];
    }
}

- (NSString *)queryKey { return queryKey; }

#pragma mark Search methods

- (void)resetSearch;
{
    [self setSearchTerm:[group searchTerm]];
    [self setWebEnv:nil];
    [self setQueryKey:nil];
    [self setNumberOfAvailableResults:0];
    [self setNumberOfFetchedResults:0];
    
    NSXMLDocument *document = nil;
    
    if(NO != [NSString isEmptyString:[self searchTerm]]){
        // get the initial XML document with our search parameters in it
        NSString *esearch = [[[self class] baseURLString] stringByAppendingFormat:@"/esearch.fcgi?db=%@&retmax=1&usehistory=y&term=%@&tool=bibdesk", [[self serverInfo] database], [[self searchTerm] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURL *initialURL = [NSURL URLWithString:esearch]; 
        OBPRECONDITION(initialURL);
        
        NSURLRequest *request = [NSURLRequest requestWithURL:initialURL];
        NSURLResponse *response;
        NSError *error;
        NSData *esearchResult = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (nil == esearchResult)
            NSLog(@"failed to download %@ with error %@", initialURL, error);
        else
            document = [[NSXMLDocument alloc] initWithData:esearchResult options:NSXMLNodeOptionsNone error:&error];
        
        if (nil != document) {
            NSXMLElement *root = [document rootElement];
            
            // we need to extract WebEnv, Count, and QueryKey to construct our final URL
            [self setWebEnv:[[[root nodesForXPath:@"/eSearchResult[1]/WebEnv[1]" error:NULL] lastObject] stringValue]];
            [self setQueryKey:[[[root nodesForXPath:@"/eSearchResult[1]/QueryKey[1]" error:NULL] lastObject] stringValue]];
            NSString *countString = [[[root nodesForXPath:@"/eSearchResult[1]/Count[1]" error:NULL] lastObject] stringValue];
            [self setNumberOfAvailableResults:[countString intValue]];
            
            [document release];
            
        } else if (nil != esearchResult) {
            // make sure error was actually initialized by NSXMLDocument
            NSLog(@"unable to create an XML document: %@", error);
        }
        
        needsReset = NO;
    }
}

- (void)fetch;
{
    if ([self webEnv] == nil || [self queryKey] == nil || [self numberOfAvailableResults] <= [self numberOfFetchedResults])
        return;
    
    int numResults = MIN([self numberOfAvailableResults] - [self numberOfFetchedResults], MAX_RESULTS);
    
    // need to escape queryKey, but the rest should be valid for a URL
    NSString *efetch = [[[self class] baseURLString] stringByAppendingFormat:@"/efetch.fcgi?rettype=medline&retmode=text&retstart=%d&retmax=%d&db=%@&query_key=%@&WebEnv=%@&tool=bibdesk", [self numberOfFetchedResults], numResults, [[self serverInfo] database], [[self queryKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [self webEnv]];
    NSURL *theURL = [NSURL URLWithString:efetch];
    OBPOSTCONDITION(theURL);
    
    [self setNumberOfFetchedResults:[self numberOfFetchedResults] + numResults];
    
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
    NSArray *pubs = nil;
    if (nil == contentString) {
        failedDownload = YES;
    } else {
        int type = [contentString contentStringType];
        if (type == BDSKBibTeXStringType) {
            NSMutableString *frontMatter = [NSMutableString string];
            pubs = [BibTeXParser itemsFromData:[contentString dataUsingEncoding:NSUTF8StringEncoding] frontMatter:frontMatter filePath:filePath document:group encoding:NSUTF8StringEncoding error:&error];
        } else if (type != BDSKUnknownStringType && type != BDSKNoKeyBibTeXStringType){
            pubs = [BDSKStringParser itemsFromString:contentString ofType:type error:&error];
        }
        if (pubs == nil || error) {
            failedDownload = YES;
            [NSApp presentError:error];
        }
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
