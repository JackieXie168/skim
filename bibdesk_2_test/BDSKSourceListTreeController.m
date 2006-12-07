//
//  BDSKSourceListTreeController.m
//  bd2
//
//  Created by Michael McCracken on 6/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKSourceListTreeController.h"


@implementation BDSKSourceListTreeController

- (id)newObject{
    NSLog(@"newObject called with %@", [self selectedObjects]);
    return [super newObject];
}

- (void)insertChild:(id)sender{
    NSLog(@"inserting a child when the selection is %@, and my objectClass is %@", [self valueForKeyPath:@"selection.entity.managedObjectClassName"], [self objectClass]);
    [self setObjectClass:NSClassFromString([self valueForKeyPath:@"selection.entity.managedObjectClassName"])];
    NSLog(@"after setting my object class, it is %@", [self objectClass]);
    [super insertChild:sender];
}

@end
