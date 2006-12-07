//
//  BDSKFilter.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKCondition.h"
#import "BDSKFilterItem.h"

typedef enum {
	BDSKAnd = 0,
	BDSKOr = 1
} BDSKConjunction;

@interface BDSKFilter : NSObject <NSCopying, NSCoding> {
	NSMutableArray *conditions;
	BDSKConjunction conjunction;
	BOOL enabled;
}

- (id)initWithConditions:(NSArray *)newConditions;

- (NSArray *)filterItems:(NSArray *)items;
- (BOOL)testItem:(id<BDSKFilterItem>)item;

- (NSArray *)conditions;
- (void)setConditions:(NSArray *)newConditions;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)newEnabled;
- (BDSKConjunction)conjunction;
- (void)setConjunction:(BDSKConjunction)newConjunction;

@end
