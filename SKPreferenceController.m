//
//  SKPreferenceController.m
//  Skim
//
//  Created by Christiaan Hofman on 10/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKPreferenceController.h"


@implementation SKPreferenceController

- (NSString *)windowNibName {
    return @"PreferencePanel";
}

+ (id)sharedPrefenceController {
    static SKPreferenceController *sharedPrefenceController = nil;
    if (sharedPrefenceController == nil)
        sharedPrefenceController = [[self alloc] init];
    return sharedPrefenceController;
}

@end
