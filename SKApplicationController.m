//
//  SKApplicationController.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import "SKApplicationController.h"


@implementation SKApplicationController

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
    return NO;
}

@end
