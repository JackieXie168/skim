//
//  BDSKPerson.h
//  bd2xtest
//
//  Created by Michael McCracken on 7/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKContributor.h"
#import "BDSKPersonInstitutionRelationship.h"

@interface BDSKPerson : BDSKContributor {

}
+ (NSMutableSet *)findOrCreatePeopleWithNames:(NSArray *)names managedObjectContext:(NSManagedObjectContext *)moc;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (BDSKPersonInstitutionRelationship *)currentInstitutionRelationship;
- (NSString *)currentInstitutionRelationshipDisplayString;



@end
