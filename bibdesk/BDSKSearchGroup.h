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

enum {
    BDSKSearchGroupEntrez,
    BDSKSearchGroupZoom
};

@class BDSKSearchGroup;

@protocol BDSKSearchGroupServer <NSObject>
- (id)initWithGroup:(BDSKSearchGroup *)aGroup serverInfo:(NSDictionary *)info;
- (NSDictionary *)serverInfo;
- (void)setServerInfo:(NSDictionary *)info;
- (void)setNumberOfAvailableResults:(int)value;
- (int)numberOfAvailableResults;
- (void)setNumberOfFetchedResults:(int)value;
- (int)numberOfFetchedResults;
- (BOOL)failedDownload;
- (BOOL)isRetrieving;
- (void)setNeedsReset:(BOOL)flag;
- (BOOL)needsReset;
- (void)retrievePublications;
- (void)terminate;
@end

@interface BDSKSearchGroup : BDSKMutableGroup <BDSKOwner> {
    BDSKPublicationsArray *publications;
    BDSKMacroResolver *macroResolver;
    int type;
    NSString *searchTerm; // passed in by caller
    id<BDSKSearchGroupServer> server;
}

- (id)initWithName:(NSString *)aName;
- (id)initWithType:(int)aType serverInfo:(NSDictionary *)info searchTerm:(NSString *)string;

- (BDSKPublicationsArray *)publications;
- (void)setPublications:(NSArray *)newPublications;
- (void)addPublications:(NSArray *)newPublications;

- (void)setType:(int)newType;
- (int)type;

- (void)setServerInfo:(NSDictionary *)info;
- (NSDictionary *)serverInfo;

- (void)setSearchTerm:(NSString *)aTerm;
- (NSString *)searchTerm;

- (void)setNumberOfAvailableResults:(int)value;
- (int)numberOfAvailableResults;

- (BOOL)hasMoreResults;

- (void)search;
- (void)searchNext;

- (void)resetServer;

@end
