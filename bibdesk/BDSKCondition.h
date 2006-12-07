//
//  BDSKCondition.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKFilterItem.h"

typedef enum {
	BDSKContain = 0,
	BDSKNotContain = 1,
	BDSKEqual = 2,
	BDSKNotEqual = 3,
	BDSKStartWith = 4,
	BDSKEndWith = 5
} BDSKComparison;

typedef enum {
	BDSKPublicationType = 0,
	BDSKAuthorType = 1,
	BDSKNoteType = 2
} BDSKItemType;

@interface BDSKCondition : NSObject <NSCopying, NSCoding> {
	NSString *key;
	NSString *value;
	BDSKComparison comparison;
	BDSKItemType itemType;
}

- (BOOL)isSatisfiedByItem:(id<BDSKFilterItem>)item;
- (NSString *)key;
- (void)setKey:(NSString *)newKey;
- (NSString *)value;
- (void)setValue:(NSString *)newValue;
- (BDSKComparison)comparison;
- (void)setComparison:(BDSKComparison)newComparison;
- (BDSKItemType)itemType;
- (void)setItemType:(BDSKItemType)newItemType;
- (NSString *)itemClassName;
- (Class)itemClass;

@end
