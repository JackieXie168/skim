//
//  BDSKBD2AppDelegate.m
//  bd2xtest
//
//  Created by Michael McCracken on 7/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKBD2AppDelegate.h"
#import "BDSKInspectorWindowController.h"


@implementation BDSKBD2AppDelegate

+ (void)initialize{
    // Register Custom Value Transformers
    BDSKGroupEntityToItemDisplayNameTransformer *groupToItemNameTransformer;
    groupToItemNameTransformer = [[[BDSKGroupEntityToItemDisplayNameTransformer alloc] init]
        autorelease];
    [NSValueTransformer setValueTransformer:groupToItemNameTransformer
                                    forName:@"BDSKGroupEntityToItemDisplayNameTransformer"];
}

- (IBAction)showNoteWindow:(id)sender {
    [[BDSKNoteWindowController sharedController] showWindow:sender];
}

- (IBAction)showTagWindow:(id)sender {
    [[BDSKTagWindowController sharedController] showWindow:sender];
}

@end
