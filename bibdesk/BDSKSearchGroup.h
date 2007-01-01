//
//  BDSKSearchGroup.h
//  Bibdesk
//
//  Created by Adam Maxwell on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKGroup.h"
#import "BDSKOwnerProtocol.h"

extern NSString *BDSKSearchGroupEntrez;
extern NSString *BDSKSearchGroupZoom;

@class BDSKSearchGroup, BDSKServerInfo;

@protocol BDSKSearchGroupServer <NSObject>
- (id)initWithGroup:(BDSKSearchGroup *)aGroup serverInfo:(BDSKServerInfo *)info;
- (BDSKServerInfo *)serverInfo;
- (void)setServerInfo:(BDSKServerInfo *)info;
- (void)setNumberOfAvailableResults:(int)value;
- (int)numberOfAvailableResults;
- (void)setNumberOfFetchedResults:(int)value;
- (int)numberOfFetchedResults;
- (BOOL)failedDownload;
- (BOOL)isRetrieving;
- (void)retrievePublications;
- (void)stop;
- (void)terminate;
@end

@interface BDSKSearchGroup : BDSKMutableGroup <BDSKOwner> {
    BDSKPublicationsArray *publications;
    BDSKMacroResolver *macroResolver;
    NSString *type;
    NSString *searchTerm; // passed in by caller
    NSArray *history;
    id<BDSKSearchGroupServer> server;
}

- (id)initWithName:(NSString *)aName;
- (id)initWithType:(NSString *)aType serverInfo:(BDSKServerInfo *)info searchTerm:(NSString *)string;

- (BDSKPublicationsArray *)publications;
- (void)setPublications:(NSArray *)newPublications;
- (void)addPublications:(NSArray *)newPublications;

- (NSString *)type;

- (void)setServerInfo:(BDSKServerInfo *)info;
- (BDSKServerInfo *)serverInfo;

- (void)setSearchTerm:(NSString *)aTerm;
- (NSString *)searchTerm;

- (void)setHistory:(NSArray *)newHistory;
- (NSArray *)history;

- (void)setNumberOfAvailableResults:(int)value;
- (int)numberOfAvailableResults;

- (BOOL)hasMoreResults;

- (void)search;

- (void)resetServerWithInfo:(BDSKServerInfo *)info;

@end
