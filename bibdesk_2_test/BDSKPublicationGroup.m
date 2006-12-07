//
//  BDSKPublicationGroup.m
//  bd2
//
//  Created by Michael McCracken on 7/12/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKPublicationGroup.h"


@implementation BDSKPublicationGroup

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"publications", @"children", nil]
    triggerChangeNotificationsForDependentKey:@"publicationsInSelfOrChildren"];
}

- (NSSet *)publicationsInSelfOrChildren{
    NSMutableSet *myPubs = [NSMutableSet setWithCapacity:10];
    [myPubs unionSet:[self valueForKey:@"publications"]];
  
    NSSet *myChildren = [self valueForKey:@"children"];
    NSEnumerator *childE = [myChildren objectEnumerator];
    id child = nil;
    while(child = [childE nextObject]){
        [myPubs unionSet:[child valueForKey:@"publicationsInSelfOrChildren"]];
    }
    return [[myPubs retain] autorelease];
}

- (NSImage *)icon{
    NSImage *theIcon = [NSImage imageNamed:@"NSApplicationIcon"];
    [theIcon setSize:NSMakeSize(16, 16)];
    return theIcon;
}

@end
