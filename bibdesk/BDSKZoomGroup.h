//
//  BDSKZoomGroup.h
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKSearchGroup.h"
#import  "BDSKOwnerProtocol.h"

@class BDSKZoomGroupServer, BDSKPublicationsArray;

@interface BDSKZoomGroup : BDSKMutableGroup <BDSKOwner>
{
    BDSKPublicationsArray *publications;
    BDSKMacroResolver *macroResolver;
    NSString *searchTerm;
    
    BDSKZoomGroupServer *server;
}

- (id)initWithHost:(NSString *)hostname port:(int)num database:(NSString *)dbase searchTerm:(NSString *)string;
- (void)setHost:(NSString *)aHost;
- (void)setPort:(int)p;
- (NSString *)host;
- (int)port;
- (NSString *)searchTerm;
- (NSString *)database;
- (void)setDatabase:(NSString *)dbase;

- (BDSKPublicationsArray *)publications;
- (void)setPublications:(NSArray *)newPublications;
- (void)addPublications:(NSArray *)newPublications;
- (void)search;


@end
