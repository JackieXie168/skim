//
//  BDSKAutoGroup.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/8/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKSmartGroup.h"


@interface BDSKAutoGroup : BDSKSmartGroup {
    NSMutableSet *children;
    BOOL isToMany;
    BOOL recreatingChildren;
}

- (NSString *)itemPropertyName;
- (void)setItemPropertyName:(NSString *)propertyName;

- (void)reset;

@end


@interface BDSKAutoChildGroup : BDSKGroup {
    NSSet *items;
}

- (NSSet *)items;
- (void)setItems:(NSSet *)newItems;

- (NSSet *)children;

@end
