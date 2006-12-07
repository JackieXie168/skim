//
//  BDSKAutoGroupEditor.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/16/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKAutoGroupEditor : NSWindowController {
    NSManagedObjectContext *managedObjectContext;
    NSString *entityName;
    NSString *propertyName;
    NSDictionary *predicateRules;
    CFArrayRef editors;
}

- (NSManagedObjectContext *)managedObjectContext;
- (void)setManagedObjectContext:(NSManagedObjectContext *)context;

- (NSString *)entityName;
- (void)setEntityName:(NSString *)newEntityName;

- (NSString *)propertyName;
- (void)setPropertyName:(NSString *)newPropertyName;

- (NSArray *)entityNames;
- (NSArray *)propertyNames;

- (void)reset;

- (IBAction)closeEditor:(id)sender;

@end
