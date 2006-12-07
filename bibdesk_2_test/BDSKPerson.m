//
//  BDSKPerson.m
//  bd2xtest
//
//  Created by Michael McCracken on 7/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKPerson.h"
#import "BDSKBibTeXParser.h"
#import "BDSKDataModelNames.h"

@implementation BDSKPerson


+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"firstNamePart", @"vonNamePart", @"lastNamePart", @"jrNamePart", nil]
    triggerChangeNotificationsForDependentKey:@"name"];
}

// This function efficiently finds-or-creates a list of People by their name,
//  not duplicating people with the same name.
// It's designed as one part of the 'efficient find or create' pattern seen in http://developer.apple.com/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html#//apple_ref/doc/uid/TP40003174 

+ (NSMutableSet *)findOrCreatePeopleWithNames:(NSArray *)names managedObjectContext:(NSManagedObjectContext *)moc{

    NSMutableSet *foundPeople = [[NSMutableSet alloc] initWithCapacity:[names count]];
    NSArray *sortedNames = [names sortedArrayUsingSelector:@selector(compare:)];
    
    NSEntityDescription *personEntityDescription = [NSEntityDescription
    entityForName:PersonEntityName inManagedObjectContext:moc];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:personEntityDescription];

    [request setPredicate:[NSPredicate predicateWithFormat:@"(name IN %@)", sortedNames]];
    
    [request setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc]
    initWithKey:@"name" ascending:YES] autorelease]]];
    
    NSError *error = nil;
    NSArray *sortedPeopleMatchingNames = [moc executeFetchRequest:request error:&error];

    int sortedNameIdx = 0;
    int matchingPeopleIdx = 0;
    NSString *curName = 0;
    id curPerson = nil;
    id newPerson = nil;
    
    for( ; sortedNameIdx != [sortedNames count]; matchingPeopleIdx++){
        
        curName = [sortedNames objectAtIndex:sortedNameIdx];
        if(matchingPeopleIdx < [sortedPeopleMatchingNames count]){
            curPerson = [sortedPeopleMatchingNames objectAtIndex:matchingPeopleIdx];
        }else{
            curPerson = nil;
        }
        
        if (curPerson == nil || ![curName isEqualToString:[curPerson valueForKey:@"name"]]){
            // no person for this name - create one 
            newPerson = [NSEntityDescription insertNewObjectForEntityForName:PersonEntityName inManagedObjectContext:moc];
            [newPerson setValue:curName forKey:@"name"];
            [foundPeople addObject:newPerson];
            sortedNameIdx++;
        }else{
            [foundPeople addObject:curPerson];
            matchingPeopleIdx++;
            sortedNameIdx++;
        }
    }
         
    assert([names count] == [foundPeople count]);
    return [[foundPeople retain] autorelease];
}

// FIXME: this is copied and pasted into BDSKBibTeXParser.m.
// it's important that the strings generated here and there match.
// this is a code smell and should be refactored.
- (NSString *)name{
    NSString *firstName = [self valueForKey:@"firstNamePart"];
    NSString *vonPart = [self valueForKey:@"vonNamePart"];
    NSString *lastName = [self valueForKey:@"lastNamePart"];
    NSString *jrPart = [self valueForKey:@"jrNamePart"];
    
    BOOL FIRST = (firstName != nil && ![@"" isEqualToString:firstName]);
    BOOL VON = (vonPart != nil && ![@"" isEqualToString:vonPart]);
    BOOL LAST = (lastName != nil && ![@"" isEqualToString:lastName]);
    BOOL JR = (jrPart != nil && ![@"" isEqualToString:jrPart]);
    
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@", (VON ? vonPart : @""),
        (VON ? @" " : @""),
        (LAST ? lastName : @""),
        (JR ? @", " : @""),
        (JR ? jrPart : @""),
        (FIRST ? @", " : @""),
        (FIRST ? firstName : @"")];
}

- (void)setName:(NSString *)newName{
    NSDictionary *dict = [BDSKBibTeXParser splitPersonName:newName];
	[self setValue:[dict objectForKey:@"firstNamePart"] forKey:@"firstNamePart"];
	[self setValue:[dict objectForKey:@"lastNamePart"] forKey:@"lastNamePart"];
	[self setValue:[dict objectForKey:@"vonNamePart"] forKey:@"vonNamePart"];
	[self setValue:[dict objectForKey:@"jrNamePart"] forKey:@"jrNamePart"];
}

- (BDSKPersonInstitutionRelationship *)currentInstitutionRelationship{
    NSMutableSet *institutionRelationships = [self valueForKey:@"institutionRelationships"];
    NSEnumerator *instRelEnumerator = [institutionRelationships objectEnumerator];
    id instRel = nil;
    NSDate *mostRecentDate = [NSDate distantPast];
    id mostRecentInstRel = nil;
    
    // find the relationship with the most recent start date:
    while (instRel = [instRelEnumerator nextObject]) {
        NSDate *startDate = [instRel valueForKey:@"startDate"];
        if([startDate timeIntervalSinceDate:mostRecentDate] > 0){
            mostRecentDate = startDate;
            mostRecentInstRel = instRel;
        }
    }
    return mostRecentInstRel;
}

- (NSString *)currentInstitutionRelationshipDisplayString{
    BDSKPersonInstitutionRelationship *instRel = [self currentInstitutionRelationship];
    
    NSString *instName = [instRel valueForKeyPath:@"institution.name"];
    NSString *relType = [instRel valueForKey:@"relationshipType"];
    NSDate *startDate = [instRel valueForKey:@"startDate"];
    NSString *startDateString = [startDate descriptionWithCalendarFormat:@"%m/%y" 
                                                                timeZone:nil 
                                                                  locale:nil];

    return [NSString stringWithFormat:@"%@, %@ (since %@)", relType, instName, startDateString];
}

@end
