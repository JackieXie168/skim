//
//  BDSKSmartGroupEditor.h
//  bd2
//
//  Created by Christiaan Hofman on 2/15/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKComparisonPredicateController.h"

extern id BDSKNoCategoriesMarker;
extern id BDSKAddOtherMarker;

@class BDSKPredicateView;


@interface BDSKSmartGroupEditor : NSWindowController {
    IBOutlet BDSKPredicateView *mainView;
    IBOutlet NSWindow *addPropertySheet;
    NSManagedObjectContext *managedObjectContext;
    NSString *entityName;
    NSString *propertyName;
    NSString *addedPropertyName;
    int conjunction;
    BOOL canChangeEntityName;
    NSDictionary *predicateRules;
    NSMutableArray *publicationPropertyNames;
    NSMutableArray *controllers;
    CFArrayRef editors;
}

- (IBAction)add:(id)sender;
- (IBAction)remove:(BDSKComparisonPredicateController *)controller;

- (NSManagedObjectContext *)managedObjectContext;
- (void)setManagedObjectContext:(NSManagedObjectContext *)context;

- (NSString *)entityName;
- (void)setEntityName:(NSString *)newEntityName;

- (NSString *)propertyName;
- (void)setPropertyName:(NSString *)newPropertyName;

- (int)conjunction;
- (void)setConjunction:(int)value;

- (NSPredicate *)predicate;
- (void)setPredicate:(NSPredicate *)newPredicate;

- (NSArray *)entityNames;
- (NSArray *)propertyNames;

- (NSArray *)operatorNamesForTypeName:(NSString *)attributeTypeName;
- (NSPredicateOperatorType)operatorTypeForOperatorName:(NSString *)operatorName;
- (NSString *)operatorNameForOperatorType:(NSPredicateOperatorType)operatorType;

- (NSString *)addedPropertyName;
- (void)setAddedPropertyName:(NSString *)newPropertyName;

- (BOOL)isCompound;

- (BOOL)canChangeEntityName;
- (void)setCanChangeEntityName:(BOOL)flag;

- (void)reset;

- (IBAction)closeEditor:(id)sender;

- (IBAction)addNewProperty:(id)sender;
- (IBAction)closeAddPropertySheet:(id)sender;

- (NSString *)addNewPropertyForPropertyName:(NSString *)newPropertyName;
- (NSString *)addNewPropertyForDisplayName:(NSString *)newDisplayName;
 
@end


@interface BDSKPredicateView : NSView {
}

- (void)addView:(NSView *)view;
- (void)removeView:(NSView *)view;
- (void)removeAllSubviews;
- (void)updateSize;

@end
