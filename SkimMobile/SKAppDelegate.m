//
//  SkimMobileAppDelegate.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-04-27.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKAppDelegate.h"
#import <DropboxSDK/DropboxSDK.h>

@interface SKAppDelegate () <DBSessionDelegate, DBNetworkRequestDelegate, UINavigationControllerDelegate>
@end

@implementation SKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Set these variables before launching the app
    NSString* appKey = @"3f27aq9p8vhhcpe";
	NSString* appSecret = @"kkkss8rvmw1lpr4";
	NSString *root = kDBRootDropbox; // Should be set to either kDBRootAppFolder or kDBRootDropbox

    NSString* errorMsg = nil;
	if ([appKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
		errorMsg = @"Make sure you set the app key correctly in DBRouletteAppDelegate.m";
	} else if ([appSecret rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
		errorMsg = @"Make sure you set the app secret correctly in DBRouletteAppDelegate.m";
	} else if ([root length] == 0) {
		errorMsg = @"Set your root to use either App Folder of full Dropbox";
	} else {
		NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
		NSData *plistData = [NSData dataWithContentsOfFile:plistPath];
		NSDictionary *loadedPlist =
        [NSPropertyListSerialization
         propertyListFromData:plistData mutabilityOption:0 format:NULL errorDescription:NULL];
		NSString *scheme = [[[[loadedPlist objectForKey:@"CFBundleURLTypes"] objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
		if ([scheme isEqual:@"db-APP_KEY"]) {
			errorMsg = @"Set your URL scheme correctly in DBRoulette-Info.plist";
		}
	}

    DBSession* session = [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
	session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
	[DBSession setSharedSession:session];
	
	[DBRequest setNetworkRequestDelegate:self];
    
    if ([[DBSession sharedSession] isLinked])
    {
        NSLog(@"Dropbox account is linked");
    }
    
    return true;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[DBSession sharedSession] handleOpenURL:url])
    {
        if ([[DBSession sharedSession] isLinked])
        {
            NSLog(@"App linked successfully!");
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId
{
    NSLog(@"Dropbox Session Ended");
}

#pragma mark -
#pragma mark DBNetworkRequestDelegate methods

static int outstandingRequests;

- (void)networkRequestStarted
{
	outstandingRequests++;
	if (outstandingRequests == 1)
    {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
}

- (void)networkRequestStopped
{
	outstandingRequests--;
	if (outstandingRequests == 0)
    {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}

@end