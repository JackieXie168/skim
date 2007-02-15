//
//  SKApplication.m
//  Skim
//
//  Created by Christiaan Hofman on 15/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKApplication.h"
#import "SKStringConstants.h"

NSString *SKApplicationWillTerminateNotification = @"SKApplicationWillTerminateNotification";

@implementation SKApplication

- (IBAction)terminate:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKApplicationWillTerminateNotification object:self];
    [[NSUserDefaults standardUserDefaults] setObject:[[[NSDocumentController sharedDocumentController] documents] valueForKey:@"currentDocumentSetup"] forKey:SKLastOpenFileNamesKey];
    [super terminate:sender];
}

@end
