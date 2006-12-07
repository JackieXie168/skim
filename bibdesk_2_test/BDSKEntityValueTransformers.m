//
//  BDSKEntityValueTransformers.m
//  bd2xtest
//
//  Created by Michael McCracken on 7/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKEntityValueTransformers.h"

// Given an entity that is a group (PersonGroup, PublicationGroup, etc)
// This class returns the display name of the item that group contains.
@implementation BDSKGroupEntityToItemDisplayNameTransformer
+ (Class)transformedValueClass { return [NSManagedObject self]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
    if (value == nil) return nil;
    
    NSString *entityName = [value valueForKeyPath:@"name"];
    
    if ([entityName isEqualToString:@"PublicationGroup"]){
        return NSLocalizedString(@"Publication", @"name of publication entity");
    }
    if ([entityName isEqualToString:@"NoteGroup"]){
        return NSLocalizedString(@"Note", @"name of note entity");
    }
    if ([entityName isEqualToString:@"PersonGroup"]){
        return NSLocalizedString(@"Person", @"name of person entity");
    }
    else return @"??";
}
@end
