//
//  BDSKComparisonPredicateController.h
//  bd2
//
//  Created by Christiaan Hofman on 2/15/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BDSKSmartGroupEditor;


@interface BDSKComparisonPredicateController : NSObject {
    IBOutlet NSView *view;
    IBOutlet NSObjectController *ownerController;
    BDSKSmartGroupEditor *smartGroupEditor;
    NSString *propertyName;
    NSString *operatorName;
    NSString *searchValue;
}

- (id)initWithEditor:(BDSKSmartGroupEditor *)anEditor;

- (void)cleanup;

- (NSView *)view;

- (void)remove:(id)sender;

- (BDSKSmartGroupEditor *)smartGroupEditor;
- (void)setSmartGroupEditor:(BDSKSmartGroupEditor *)newEditor;

- (NSPredicate *)predicate;
- (void)setPredicate:(NSPredicate *)newPredicate;

- (NSString *)propertyName;
- (void)setPropertyName:(NSString *)value;

- (NSString *)operatorName;
- (void)setOperatorName:(NSString *)value;

- (NSString *)searchValue;
- (void)setSearchValue:(NSString *)value;

- (BOOL)prependAnyString;

- (NSAttributeDescription *)attribute;
- (int)attributeType;
- (NSString *)attributeTypeName;

- (NSPredicateOperatorType)operatorType;
- (void)setOperatorType:(NSPredicateOperatorType)type;

- (NSArray *)operatorNames;
- (NSArray *)propertyNames;

@end


@interface NSString (BDSKBoolExtensions) 
- (BOOL)boolValue;
@end

