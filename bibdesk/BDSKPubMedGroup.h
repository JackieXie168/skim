//
//  BDSKPubMedGroup.h
//  Bibdesk
//
//  Created by Adam Maxwell on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKURLGroup.h"

@interface BDSKPubMedGroup : BDSKURLGroup {
    int maxResults;
    int availableResults;
    NSString *searchTerm;
    NSString *searchKey;
}

- (void)setMaxResults:(int)count;
- (int)maxResults;
- (void)setSearchTerm:(NSString *)aTerm;
- (NSString *)searchTerm;
- (void)setSearchKey:(NSString *)aKey;
- (NSString *)searchKey;

@end
