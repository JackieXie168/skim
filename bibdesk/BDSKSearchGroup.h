//
//  BDSKSearchGroup.h
//  Bibdesk
//
//  Created by Adam Maxwell on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKURLGroup.h"

@interface BDSKSearchGroup : BDSKURLGroup {
    int maxResults;
    int availableResults;
    NSString *webEnv;
    NSString *queryKey;
    NSString *searchTerm;
    NSString *searchKey;
}

- (void)setSearchTerm:(NSString *)aTerm;
- (NSString *)searchTerm;
- (void)setSearchKey:(NSString *)aKey;
- (NSString *)searchKey;

- (void)setNumberOfAvailableResults:(int)value;
- (int)numberOfAvailableResults;

- (BOOL)canGetMoreResults;

- (void)search;
- (void)searchNext;

@end
