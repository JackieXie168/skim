//
//  BDSKPerson.m
//  bd2xtest
//
//  Created by Michael McCracken on 7/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKPerson.h"
#import "BDSKBibTeXParser.h"


@implementation BDSKPerson


+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"firstNamePart", @"vonNamePart", @"lastNamePart", @"jrNamePart", nil]
    triggerChangeNotificationsForDependentKey:@"name"];
}

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
