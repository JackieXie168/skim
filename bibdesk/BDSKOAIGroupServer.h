//
//  BDSKOAIGroupServer.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 1/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKSearchGroup.h"

@class BDSKServerInfo;

@interface BDSKOAIGroupServer : NSObject <BDSKSearchGroupServer>
{
    BDSKSearchGroup *group;
    BDSKServerInfo *serverInfo;
    NSString *searchTerm;
    NSString *resumptionToken;
    NSArray *sets;
    NSString *filePath;
    NSURLDownload *URLDownload;
    BOOL failedDownload;
    BOOL isRetrieving;
    BOOL needsReset;
    int availableResults;
    int fetchedResults;
}
- (void)setServerInfo:(BDSKServerInfo *)info;
- (BDSKServerInfo *)serverInfo;
- (void)setSearchTerm:(NSString *)string;
- (NSString *)searchTerm;
- (void)setSets:(NSArray *)newSets;
- (NSArray *)sets;
- (void)setResumptionToken:(NSString *)newResumptionToken;
- (NSString *)resumptionToken;
- (void)resetSearch;
- (void)fetchSets;
- (void)fetch;
- (void)startDownloadFromURL:(NSURL *)theURL;

@end
