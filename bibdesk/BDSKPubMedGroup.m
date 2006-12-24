//
//  BDSKPubMedGroup.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKPubMedGroup.h"

/* Based on public domain sample code written by Oleg Khovayko, available at
 http://www.ncbi.nlm.nih.gov/entrez/query/static/eutils_example.pl
 
 - We limit requests to 100 in the editor interface, per NCBI's request.  
 - We also pass tool=bibdesk for their tracking purposes.  
 - We use lower case characters in the URL /except/ for WebEnv
 - See http://www.ncbi.nlm.nih.gov/entrez/query/static/eutils_help.html for details.
 
 */

@implementation BDSKPubMedGroup

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
        //
        [self setMaxResults:50];
    }
    return self;
}

- (void)createURL;
{
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
    
    NSURL *theURL = nil;
    
    if (nil != document) {
        NSXMLElement *root = [document rootElement];
        
        // we need to extract WebEnv, Count, and QueryKey to construct our final URL
        NSString *webEnv = [[[root nodesForXPath:@"/eSearchResult[1]/WebEnv[1]" error:NULL] lastObject] stringValue];
        NSString *countString = [[[root nodesForXPath:@"/eSearchResult[1]/Count[1]" error:NULL] lastObject] stringValue];
        availableResults = countString ? [countString intValue] : 0;
        NSString *queryKey = [[[root nodesForXPath:@"/eSearchResult[1]/QueryKey[1]" error:NULL] lastObject] stringValue];
        
        NSString *efetch = [[[[self class] baseURL] absoluteString] stringByAppendingFormat:@"/efetch.fcgi?rettype=medline&retmode=text&retstart=0&retmax=%d&db=pubmed&query_key=%@&WebEnv=%@&tool=bibdesk", MIN(availableResults, maxResults), queryKey, webEnv];
        theURL = [NSURL URLWithString:efetch];
        NSAssert(theURL, @"unable to create fetch URL");
    }
    [self setURL:theURL];
}

- (void)search;
{
    [self createURL];
    [self startDownload];
}

- (void)setMaxResults:(int)n;
{
    if (n != maxResults) {
        maxResults = n;
        [self search];
    }
}

- (int)maxResults { return maxResults; }

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
        [self search];
    }
}

- (NSString *)searchKey { return searchKey; }

- (id)publications {
    return [self searchTerm] ? [super publications] : nil;
}

@end
