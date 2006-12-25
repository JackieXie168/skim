//
//  BDSKSearchGroup.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKSearchGroup.h"

// max number of results from NCBI is 100, except on evenings and weekends
#define MAX_RESULTS 50

/* Based on public domain sample code written by Oleg Khovayko, available at
 http://www.ncbi.nlm.nih.gov/entrez/query/static/eutils_example.pl
 
 - We limit requests to 100 in the editor interface, per NCBI's request.  
 - We also pass tool=bibdesk for their tracking purposes.  
 - We use lower case characters in the URL /except/ for WebEnv
 - See http://www.ncbi.nlm.nih.gov/entrez/query/static/eutils_help.html for details.
 
 */

@implementation BDSKSearchGroup

+ (NSURL *)baseURL { 
    static NSURL *baseURL = nil;
    if (nil == baseURL)
        baseURL = [[NSURL alloc] initWithString:@"http://eutils.ncbi.nlm.nih.gov/entrez/eutils"];
    return baseURL;
}

- (id)initWithName:(NSString *)aName;
{
    self = [super initWithName:aName URL:[[self class] baseURL]];
    if (self) {
    }
    return self;
}

- (void)resetSearch;
{
    // get the initial XML document with our search parameters in it
    NSString *esearch = [[[[self class] baseURL] absoluteString] stringByAppendingFormat:@"/esearch.fcgi?db=pubmed&retmax=1&usehistory=y&term=%@&tool=bibdesk", [self searchTerm]];
    NSURL *initialURL = [NSURL URLWithString:esearch]; 
    NSAssert(initialURL, @"unable to create initial query URL");
    
    NSURLRequest *request = [NSURLRequest requestWithURL:initialURL];
    NSURLResponse *response;
    NSError *error;
    NSData *esearchResult = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSXMLDocument *document = nil;
    if (nil == esearchResult)
        NSLog(@"failed to download %@ with error %@", initialURL, error);
    else
        document = [[NSXMLDocument alloc] initWithData:esearchResult options:NSXMLNodeOptionsNone error:&error];
    
    if (nil != document) {
        NSXMLElement *root = [document rootElement];
        
        // we need to extract WebEnv, Count, and QueryKey to construct our final URL
        webEnv = [[[[root nodesForXPath:@"/eSearchResult[1]/WebEnv[1]" error:NULL] lastObject] stringValue] retain];
        queryKey = [[[[root nodesForXPath:@"/eSearchResult[1]/QueryKey[1]" error:NULL] lastObject] stringValue] retain];
        NSString *countString = [[[root nodesForXPath:@"/eSearchResult[1]/Count[1]" error:NULL] lastObject] stringValue];
        availableResults = countString ? [countString intValue] : 0;
    }
}

- (void)fetch;
{
    if (webEnv == nil || queryKey == nil || availableResults <= fetchedResults)
        return;
    
    int numResults = MIN(availableResults - fetchedResults, MAX_RESULTS);
    NSString *efetch = [[[[self class] baseURL] absoluteString] stringByAppendingFormat:@"/efetch.fcgi?rettype=medline&retmode=text&retstart=%d&retmax=%d&db=pubmed&query_key=%@&WebEnv=%@&tool=bibdesk", fetchedResults, numResults, queryKey, webEnv];
    NSURL *theURL = [NSURL URLWithString:efetch];
    NSAssert(theURL, @"unable to create fetch URL");

    fetchedResults += numResults;
    
    [URL release];
    URL = [theURL copy];
    [self startDownload];
    
    // use this to notify the tableview to start the progress indicators and disable the button
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKURLGroupUpdatedNotification object:self userInfo:userInfo];
}

- (void)search;
{
    if ([self isRetrieving])
        return;
    
    [webEnv release];
    webEnv = nil;
    [queryKey release];
    queryKey = nil;
    fetchedResults = 0;
    availableResults = 0;
    
    
    if ([NSString isEmptyString:searchTerm]) {
        [URL release];
        URL = nil;
        [self setPublications:[NSArray array]];
    } else {
        [self setPublications:nil];
        [self resetSearch];
        [self fetch];
    }
}

- (void)searchNext;
{
    if ([self isRetrieving])
        return;
    if ([NSString isEmptyString:searchTerm]) {
        [URL release];
        URL = nil;
    } else {
        if (searchKey == nil || webEnv == nil)
            [self resetSearch];
        [self fetch];
    }
}

- (void)setSearchTerm:(NSString *)aTerm;
{
    if ([aTerm isEqualToString:searchTerm] == NO) {
        [searchTerm autorelease];
        searchTerm = [aTerm copy];
        
        [self search];
    }
}

- (NSString *)searchTerm { return searchTerm; }

// searchKey is currently unused
- (void)setSearchKey:(NSString *)aKey;
{
    if ([aKey isEqualToString:searchKey] == NO) {
        [searchKey autorelease];
        searchKey = [aKey copy];
        
        [webEnv release];
        webEnv = nil;
        [queryKey release];
        queryKey = nil;
        fetchedResults = 0;
        
        [self search];
    }
}

- (NSString *)searchKey { return searchKey; }

// this returns nil if no searchTerm has been set, to avoid an error message
- (id)publications {
    return [NSString isEmptyString:searchTerm] ? nil : [super publications];
}

- (BOOL)hasMoreResults;
{
    return availableResults > fetchedResults;
}

@end
