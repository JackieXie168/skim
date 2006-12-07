//
//  BDSKPersonGroup.m
//  bd2
//
//  Created by Michael McCracken on 7/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKPersonGroup.h"


@implementation BDSKPersonGroup


- (NSImage *)icon{
    NSImage *theIcon = [NSImage imageNamed:@"NSApplicationIcon"];
    [theIcon setSize:NSMakeSize(16, 16)];
    return theIcon;
}

@end
