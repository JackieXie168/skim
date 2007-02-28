//
//  BDSKContributor.m
//  bd2xtest
//
//  Created by Michael McCracken on 7/19/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKContributor.h"


@implementation BDSKContributor

static long instanceID = 0;

- (id)initWithEntity:(NSEntityDescription*)entity insertIntoManagedObjectContext:(NSManagedObjectContext*)context{
    if(self = [super initWithEntity:entity insertIntoManagedObjectContext:context]){
        [self setPrimitiveValue:[NSNumber numberWithLong:instanceID++] forKey:@"contributorID"];
        //NSLog(@"%@ self! ********", self);
    }
    return self;
}



@end
