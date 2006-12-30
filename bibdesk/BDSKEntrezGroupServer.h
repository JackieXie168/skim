//
//  BDSKEntrezGroupServer.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 12/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKSearchGroup.h"

@class BDSKServerInfo;

@interface BDSKEntrezGroupServer : NSObject <BDSKSearchGroupServer>
{
    BDSKSearchGroup *group;
    BDSKServerInfo *serverInfo;
    NSString *searchTerm;
    NSString *webEnv;     // cookie-like data returned by PubMed
    NSString *queryKey;   // searchTerm as returned by PubMed
    NSString *filePath;
    NSURLDownload *URLDownload;
    BOOL failedDownload;
    BOOL isRetrieving;
    BOOL needsReset;
    int availableResults;
    int fetchedResults;
}
+ (NSString *)baseURLString;
+ (BOOL)canConnect;
- (void)setServerInfo:(BDSKServerInfo *)info;
- (BDSKServerInfo *)serverInfo;
- (void)setSearchTerm:(NSString *)string;
- (NSString *)searchTerm;
- (void)setWebEnv:(NSString *)env;
- (NSString *)webEnv;
- (void)setQueryKey:(NSString *)aKey;
- (NSString *)queryKey;
- (void)resetSearch;
- (void)fetch;
- (void)startDownloadFromURL:(NSURL *)theURL;

@end
