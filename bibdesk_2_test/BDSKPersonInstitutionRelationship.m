//
//  BDSKPersonInstitutionRelationship.m
//  bd2xtest
//
//  Created by Michael McCracken on 11/16/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKPersonInstitutionRelationship.h"


@implementation BDSKPersonInstitutionRelationship

- (NSString *)displayString{

    NSString *instName = [self valueForKeyPath:@"institution.name"];
    NSString *relType = [self valueForKey:@"relationshipType"];
    NSDate *startDate = [self valueForKey:@"startDate"];
    NSString *startDateString = [startDate descriptionWithCalendarFormat:@"%m/%y" 
                                                                timeZone:nil 
                                                                  locale:nil];
    NSDate *endDate = [self valueForKey:@"endDate"];
    NSString *endDateString = nil;
    if(endDate != nil){
        [endDate descriptionWithCalendarFormat:@"%M %Y" 
                                      timeZone:nil 
                                        locale:nil];
    }else{
        endDateString = NSLocalizedString(@"present", @"present as in 'the current day'.");
    }
    return [NSString stringWithFormat:@"%@, %@ (%@ - %@)", relType, instName, startDateString, endDateString];
}

@end
