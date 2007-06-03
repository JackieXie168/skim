//
//  SUUpdater.m
//  Sparkle
//
//  Created by Andy Matuschak on 1/4/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUUpdater.h"
#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SUUnarchiver.h"
#import "SUUtilities.h"

#import "SUUpdateAlert.h"
#import "SUAutomaticUpdateAlert.h"
#import "SUStatusController.h"

#import "NSFileManager+Authentication.h"
#import "NSFileManager+Verification.h"
#import "NSApplication+AppCopies.h"

#import <stdio.h>
#import <sys/stat.h>
#import <unistd.h>
#import <signal.h>
#import <dirent.h>

#define kNetworkConnectionFailed 10

@interface SUUpdater (Private)
- (NSURL *)appcastURL;
- (void)checkForUpdatesAndNotify:(BOOL)verbosity;
- (BOOL)checkForNetworkAvailability:(NSError **)error;
- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(unsigned int)recoveryOptionIndex;
- (void)showUpdateErrorAlertWithInfo:(NSString *)info;
- (NSTimeInterval)storedCheckInterval;
- (void)abandonUpdate;
- (IBAction)installAndRestart:sender;
@end

@implementation SUUpdater

- init
{
	[super init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:@"NSApplicationDidFinishLaunchingNotification" object:NSApp];	
	return self;
}

- (void)scheduleCheckWithInterval:(NSTimeInterval)interval
{
	if (checkTimer)
	{
		[checkTimer invalidate];
		checkTimer = nil;
	}
	
	checkInterval = interval;
	if (interval > 0)
		checkTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(checkForUpdatesInBackground) userInfo:nil repeats:YES];
}

- (void)scheduleCheckWithIntervalObject:(NSNumber *)interval
{
	[self scheduleCheckWithInterval:[interval doubleValue]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
	// If there's a scheduled interval, we see if it's been longer than that interval since the last
	// check. If so, we perform a startup check; if not, we don't.	
	if ([self storedCheckInterval])
	{
		NSTimeInterval interval = [self storedCheckInterval];
		NSDate *lastCheck = [[NSUserDefaults standardUserDefaults] objectForKey:SULastCheckTimeKey];
		if (!lastCheck) { lastCheck = [NSDate date]; }
		NSTimeInterval intervalSinceCheck = [[NSDate date] timeIntervalSinceDate:lastCheck];
		if (intervalSinceCheck < interval)
		{
			// Hasn't been long enough; schedule a check for the future.
			[self performSelector:@selector(checkForUpdatesInBackground) withObject:nil afterDelay:intervalSinceCheck];
			[self performSelector:@selector(scheduleCheckWithIntervalObject:) withObject:[NSNumber numberWithLong:interval] afterDelay:intervalSinceCheck];
		}
		else
		{
			[self scheduleCheckWithInterval:interval];
			[self checkForUpdatesInBackground];
		}
	}
	else
	{
		// There's no scheduled check, so let's see if we're supposed to check on startup.
		NSNumber *shouldCheckAtStartup = [[NSUserDefaults standardUserDefaults] objectForKey:SUCheckAtStartupKey];
		if (!shouldCheckAtStartup) // hasn't been set yet; ask the user
		{
			// Let's see if there's a key in Info.plist for a default, though. We'll let that override the dialog if it's there.
			NSNumber *infoStartupValue = SUInfoValueForKey(SUCheckAtStartupKey);
			if (infoStartupValue)
			{
				shouldCheckAtStartup = infoStartupValue;
			}
			else
			{
				NSAlert *alert = [NSAlert alertWithMessageText:SULocalizedString(@"Check for updates on startup?", nil)
 												 defaultButton:SULocalizedString(@"Yes", nil) 
   											   alternateButton:SULocalizedString(@"No", nil) 
   												   otherButton:nil
										informativeTextWithFormat:[NSString stringWithFormat:SULocalizedString(@"Would you like %@ to check for updates on startup? If not, you can initiate the check manually from the application menu.", nil), SUHostAppDisplayName()]];
				shouldCheckAtStartup = [NSNumber numberWithBool:([alert runModal] == NSAlertDefaultReturn)];
			}
			[[NSUserDefaults standardUserDefaults] setObject:shouldCheckAtStartup forKey:SUCheckAtStartupKey];
		}
		
		if ([shouldCheckAtStartup boolValue])
			[self checkForUpdatesInBackground];
	}
}

- (void)dealloc
{
	[updateItem release];
    [updateAlert release];
	
	[downloadPath release];
	[statusController release];
	[downloader release];
	
	if (checkTimer)
		[checkTimer invalidate];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if ([anItem action] == @selector(checkForUpdates:))
		return (updateInProgress == NO);
	else 
		return YES;
}

- (NSURL *)appcastURL
{
	// A value in the user defaults overrides one in the Info.plist (so preferences panels can be created wherein users choose between beta / release feeds).
	NSString *appcastString = [[NSUserDefaults standardUserDefaults] objectForKey:SUFeedURLKey];
	if (!appcastString)
		appcastString = SUInfoValueForKey(SUFeedURLKey);
    NSAssert(nil != appcastString, @"No feed URL is specified in the Info.plist or the user defaults!");
    return [NSURL URLWithString:appcastString];
}

- (void)checkForUpdatesInBackground
{
	[self checkForUpdatesAndNotify:NO];
}

- (IBAction)checkForUpdates:sender
{
	[self checkForUpdatesAndNotify:YES]; // if we're coming from IB, then we want to be more verbose.
}

// If the verbosity flag is YES, Sparkle will say when it can't reach the server and when there's no new update.
// This is generally useful for a menu item--when the check is explicitly invoked.
- (void)checkForUpdatesAndNotify:(BOOL)verbosity
{	
	if (NO == updateInProgress) {
		
		verbose = verbosity;
		updateInProgress = YES;

		SUAppcast *appcast = [[SUAppcast alloc] init];
		[appcast setDelegate:self];
		[appcast fetchAppcastFromURL:[self appcastURL]];
	}
}

- (BOOL)automaticallyUpdates
{
	if (![SUInfoValueForKey(SUAllowsAutomaticUpdatesKey) boolValue] && [SUInfoValueForKey(SUAllowsAutomaticUpdatesKey) boolValue]) { return NO; }
	if (![[NSUserDefaults standardUserDefaults] objectForKey:SUAutomaticallyUpdateKey]) { return NO; } // defaults to NO
	return [[[NSUserDefaults standardUserDefaults] objectForKey:SUAutomaticallyUpdateKey] boolValue];
}

- (BOOL)isAutomaticallyUpdating
{
	return [self automaticallyUpdates] && !verbose;
}

- (BOOL)checkForNetworkAvailability:(NSError **)error
{
	CFURLRef theURL = (CFURLRef)[self appcastURL];
	CFNetDiagnosticRef diagnostic = CFNetDiagnosticCreateWithURL(CFGetAllocator(theURL), theURL);
	
	NSString *details;
	CFNetDiagnosticStatus status = CFNetDiagnosticCopyNetworkStatusPassively(diagnostic, (CFStringRef *)&details);
	CFRelease(diagnostic);
	[details autorelease];
	
	BOOL success;
	
	if (kCFNetDiagnosticConnectionUp == status)
	{
		success = YES;
	}
	else
	{
		if (nil == details) details = SULocalizedString(@"Unknown network error", nil);
		
		// This error contains all the information needed for NSErrorRecoveryAttempting.  
		// Note that buttons in the alert will be ordered right-to-left {0, 1, 2} and correspond to objects in the NSLocalizedRecoveryOptionsErrorKey array.
		if (error)
		{
			NSArray *recoveryOptions = [NSArray arrayWithObjects:SULocalizedString(@"Ignore", nil), SULocalizedString(@"Diagnose", nil), SULocalizedString(@"Open Console", nil), nil];
			
			*error = [NSError errorWithDomain:SUInfoValueForKey((id)kCFBundleIdentifierKey) code:kNetworkConnectionFailed userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self, NSRecoveryAttempterErrorKey, details, NSLocalizedDescriptionKey, SULocalizedString(@"Would you like to ignore this problem or attempt to diagnose it?  You may also open the Console log to check for errors.", nil), NSLocalizedRecoverySuggestionErrorKey, recoveryOptions, NSLocalizedRecoveryOptionsErrorKey, nil]];
		}
		success = NO;
	}
	
	return success;
}

// Recovery attempter is called if we're doing an interactive check and the network is not available
- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(unsigned int)recoveryOptionIndex
{
	BOOL didRecover = NO;
	
	// we only receive this for a single error at present
	if ([error code] == kNetworkConnectionFailed)
	{
		if (0 == recoveryOptionIndex)
		{
			// ignore
			didRecover = NO;
			
		}
		else if (1 == recoveryOptionIndex)
		{
			// diagnose
			CFURLRef theURL = (CFURLRef)[self appcastURL];
			CFNetDiagnosticRef diagnostic = CFNetDiagnosticCreateWithURL(CFGetAllocator(theURL), theURL);
			CFNetDiagnosticStatus status = CFNetDiagnosticDiagnoseProblemInteractively(diagnostic);
			CFRelease(diagnostic);
			didRecover = (status == kCFNetDiagnosticNoErr);
			
		}
		else if (2 == recoveryOptionIndex)
		{
			// open console
			didRecover = [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.console" options:0 additionalEventParamDescriptor:nil launchIdentifier:NULL];
		}
	}
	else
	{
		didRecover = NO;
	}
	
	return didRecover;
}

- (void)showUpdateErrorAlertWithInfo:(NSString *)info
{
	if ([self isAutomaticallyUpdating]) { return; }
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:SULocalizedString(@"Update Error!", nil)];
    [alert setInformativeText:info];
    [alert addButtonWithTitle:SULocalizedString(@"Cancel", @"")];
    [alert runModal];
}

- (NSTimeInterval)storedCheckInterval
{
	// Returns the scheduled check interval stored in the user defaults / info.plist. User defaults override Info.plist.
	if ([[NSUserDefaults standardUserDefaults] objectForKey:SUScheduledCheckIntervalKey])
	{
		long interval = [[[NSUserDefaults standardUserDefaults] objectForKey:SUScheduledCheckIntervalKey] longValue];
		if (interval > 0)
			return interval;
	}
	if (SUInfoValueForKey(SUScheduledCheckIntervalKey))
		return [SUInfoValueForKey(SUScheduledCheckIntervalKey) longValue];
	return 0;
}

- (void)beginDownload
{
	if (![self isAutomaticallyUpdating])
	{
		statusController = [[SUStatusController alloc] init];
		[statusController beginActionWithTitle:SUStringByAppendingEllipsis(SULocalizedString(@"Downloading update", nil)) maxProgressValue:0 statusText:nil];
		[statusController setButtonTitle:SULocalizedString(@"Cancel", nil) target:self action:@selector(cancelDownload:) isDefault:NO];
		[statusController showWindow:self];
	}
	
	downloader = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:[updateItem fileURL]] delegate:self];	
}

- (void)remindMeLater
{
	// Clear out the skipped version so the dialog will actually come back if it was already skipped.
	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:SUSkippedVersionKey];
	
	if (checkInterval)
		[self scheduleCheckWithInterval:checkInterval];
	else
	{
		// If the host hasn't provided a check interval, we'll use 30 minutes.
		[self scheduleCheckWithInterval:30 * 60];
	}
}

- (void)updateAlert:(SUUpdateAlert *)alert finishedWithChoice:(SUUpdateAlertChoice)choice
{
	[alert release];
	switch (choice)
	{
		case SUInstallUpdateChoice:
			// Clear out the skipped version so the dialog will come back if the download fails.
			[[NSUserDefaults standardUserDefaults] setObject:nil forKey:SUSkippedVersionKey];
			[self beginDownload];
			break;
			
		case SURemindMeLaterChoice:
			updateInProgress = NO;
			[self remindMeLater];
			break;
			
		case SUSkipThisVersionChoice:
			updateInProgress = NO;
			[[NSUserDefaults standardUserDefaults] setObject:[updateItem fileVersion] forKey:SUSkippedVersionKey];
			break;
	}			
}

- (void)showUpdatePanel
{
	updateAlert = [[SUUpdateAlert alloc] initWithAppcastItem:updateItem];
	[updateAlert setDelegate:self];
	[updateAlert showWindow:self];
}

- (void)appcastDidFailToLoad:(SUAppcast *)ac
{
	[ac autorelease];
	updateInProgress = NO;
	if (verbose)
	{
		NSError *nsError;
		if ([self checkForNetworkAvailability:&nsError] == NO)
			[NSApp presentError:nsError];
		else
			[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred in retrieving update information; are you connected to the internet? Please try again later.", nil)];
	}
}

// Override this to change the new version comparison logic!
- (BOOL)newVersionAvailable
{
	return SUStandardVersionComparison([updateItem fileVersion], SUHostAppVersion()) == NSOrderedAscending;
	// Want straight-up string comparison like Sparkle 1.0b3 and earlier? Uncomment the line below and comment the one above.
	// return ![SUHostAppVersion() isEqualToString:[updateItem fileVersion]];
}

- (void)appcastDidFinishLoading:(SUAppcast *)ac
{
	BOOL failed = NO;
	if (nil == ac)
	{
		failed = YES;
		NSLog(@"Couldn't get a valid appcast from the server.");
	}

	updateItem = [[ac newestItem] retain];
	[ac release];

	if (!failed)
	{
		// Record the time of the check for host app use and for interval checks on startup.
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:SULastCheckTimeKey];
	}
	else if (nil == [updateItem fileVersion])
	{
		NSLog(@"Can't extract a version string from the appcast feed. The filenames should look like YourApp_1.5.tgz, where 1.5 is the version number.");
	}

	if (!verbose && [[[NSUserDefaults standardUserDefaults] objectForKey:SUSkippedVersionKey] isEqualToString:[updateItem fileVersion]]) { 
		updateInProgress = NO;
		return; 
	}

	if (!failed)
	{
		
		if ([self newVersionAvailable])
		{
			
			// There's a new version! Let's disable the automated checking timer unless the user cancels.
			if (checkTimer)
			{
				[checkTimer invalidate];
				checkTimer = nil;
			}
			
			if ([self isAutomaticallyUpdating])
			{
				[self beginDownload];
			}
			else
			{
				[self showUpdatePanel];
			}
		}
		else
		{
			// We only notify on no new version when we're being verbose.
			if (verbose)
			{
				NSAlert *alert = [[NSAlert new] autorelease];
				[alert setMessageText:SULocalizedString(@"You're up to date!", nil)];
				[alert setInformativeText:[NSString stringWithFormat:SULocalizedString(@"%@ %@ is currently the newest version available.", nil), SUHostAppDisplayName(), SUHostAppVersionString()]];
				[alert addButtonWithTitle:SULocalizedString(@"OK", nil)];
				[alert runModal];
			}
			updateInProgress = NO;
		}
	}

	if(failed)
	{
		updateInProgress = NO;
		if (verbose)
			[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred in retrieving update information. Please try again later.", nil)];
	}
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	[statusController setMaxProgressValue:[response expectedContentLength]];
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)name
{
	// We create a temporary directory in /tmp and stick the file there.
	NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	if ([[NSFileManager defaultManager] createDirectoryAtPath:tempDir attributes:nil])
	{
		[downloadPath autorelease];
		downloadPath = [[tempDir stringByAppendingPathComponent:name] retain];
		[download setDestination:downloadPath allowOverwrite:YES];
	}
	else
	{
		NSLog(@"Failed to create temporary directory %@", tempDir);
		[download cancel];
		[download release];
	}
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
	[statusController setProgressValue:[statusController progressValue] + length];
	[statusController setStatusText:[NSString stringWithFormat:SULocalizedString(@"%.0lfk of %.0lfk", nil), [statusController progressValue] / 1024.0, [statusController maxProgressValue] / 1024.0]];
}

- (void)unarchiver:(SUUnarchiver *)ua extractedLength:(long)length
{
	if ([self isAutomaticallyUpdating]) { return; }
	if ([statusController maxProgressValue] == 0)
		[statusController setMaxProgressValue:[[[[NSFileManager defaultManager] fileAttributesAtPath:downloadPath traverseLink:NO] objectForKey:NSFileSize] longValue]];
	[statusController setProgressValue:[statusController progressValue] + length];
}

- (void)unarchiverDidFinish:(SUUnarchiver *)ua
{
	[ua autorelease];
	
	if ([self isAutomaticallyUpdating])
	{
		[self installAndRestart:self];
	}
	else
	{
		[statusController beginActionWithTitle:SULocalizedString(@"Ready to install!", nil) maxProgressValue:1 statusText:nil];
		[statusController setProgressValue:1]; // fill the bar
		[statusController setButtonTitle:SULocalizedString(@"Install and Relaunch", nil) target:self action:@selector(installAndRestart:) isDefault:YES];
		[NSApp requestUserAttention:NSInformationalRequest];
	}
}

- (void)unarchiverDidFail:(SUUnarchiver *)ua
{
	[ua autorelease];
	[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred while extracting the archive. Please try again later.", nil)];
	[self abandonUpdate];
}

- (void)extractUpdate
{
	// Now we have to extract the downloaded archive.
	if (![self isAutomaticallyUpdating])
		[statusController beginActionWithTitle:SUStringByAppendingEllipsis(SULocalizedString(@"Extracting update", nil)) maxProgressValue:0 statusText:nil];
	
	BOOL failed = NO;
	
	// If the developer's provided a sparkle:md5Hash attribute on the enclosure, let's verify that.
	if ([updateItem MD5Sum] && ![[NSFileManager defaultManager] validatePath:downloadPath withMD5Hash:[updateItem MD5Sum]])
	{
		failed = YES;
		NSLog(@"MD5 verification of the update archive failed.");
	}
	
	// DSA verification, if activated by the developer
	if (!failed && [SUInfoValueForKey(SUExpectsDSASignatureKey) boolValue])
	{
		NSString *dsaSignature = [updateItem DSASignature];
		if (![[NSFileManager defaultManager] validatePath:downloadPath withEncodedDSASignature:dsaSignature])
		{
			failed = YES;
			NSLog(@"DSA verification of the update archive failed.");
		}
	}
	
	if (!failed)
	{
		SUUnarchiver *unarchiver = [[SUUnarchiver alloc] init];
		[unarchiver setDelegate:self];
		
		// asynchronous extraction!
		[unarchiver unarchivePath:downloadPath];
	}
	else
	{
		[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred while extracting the archive. Please try again later.", nil)];
		[self abandonUpdate];
	}	
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	[download release];
	downloader = nil;
	[self extractUpdate];
}

- (void)abandonUpdate
{
	[updateItem release];
	[statusController close];
	[statusController release];
	updateInProgress = NO;	
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	[self abandonUpdate];
	
	NSLog(@"Download error: %@", [error localizedDescription]);
	[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred while trying to download the file. Please try again later.", nil)];
}

static BOOL IsAliasFolderAtPath(NSString *path)
{
	FSRef fileRef;
	OSStatus err = noErr;
	Boolean aliasFileFlag, folderFlag;
	NSURL *fileURL = [NSURL fileURLWithPath:path];
	
	if (FALSE == CFURLGetFSRef((CFURLRef)fileURL, &fileRef))
		err = coreFoundationUnknownErr;
	
	if (noErr == err)
		err = FSIsAliasFile(&fileRef, &aliasFileFlag, &folderFlag);
	
	if (noErr == err)
		return (BOOL)(aliasFileFlag && folderFlag);
	else
		return NO;
}

- (IBAction)installAndRestart:sender
{
	NSString *currentAppPath = [[NSBundle mainBundle] bundlePath];
	NSString *newAppDownloadPath = [[downloadPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[SUInfoValueForKey(@"CFBundleName") stringByAppendingPathExtension:@"app"]];
	BOOL failed = NO;
	
	if (![self isAutomaticallyUpdating])
	{
		[statusController beginActionWithTitle:SUStringByAppendingEllipsis(SULocalizedString(@"Installing update", nil)) maxProgressValue:0 statusText:nil];
		[statusController setButtonEnabled:NO];
		
		// We have to wait for the UI to update.
		NSEvent *event;
		while((event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES]))
			[NSApp sendEvent:event];			
	}
	
	// We assume that the archive will contain a file named {CFBundleName}.app
	// (where, obviously, CFBundleName comes from Info.plist)
	if (!SUInfoValueForKey(@"CFBundleName"))
	{
		failed = YES;
		NSLog(@"This application has no CFBundleName! This key must be set to the application's name.");
	}
	
	if (!failed)
	{
		// Search subdirectories for the application
		NSString *file, *appName = [SUInfoValueForKey(@"CFBundleName") stringByAppendingPathExtension:@"app"];
		NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:[downloadPath stringByDeletingLastPathComponent]];
		while ((file = [dirEnum nextObject]))
		{
			// Some DMGs have symlinks into /Applications! But symlinks are not followed by NSDirectoryEnumerator, so that's OK
            // If someone uses an alias to a folder that can lead to problems though, as it could be resolved to the Applications folder on disk or lead to loops
			if (IsAliasFolderAtPath([[downloadPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:file]))
				[dirEnum skipDescendents];
			if ([[file lastPathComponent] isEqualToString:appName])
				newAppDownloadPath = [[downloadPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:file];
		}
		
		if (!newAppDownloadPath || ![[NSFileManager defaultManager] fileExistsAtPath:newAppDownloadPath])
		{
			failed = YES;
			NSLog(@"The update archive didn't contain an application with the proper name: %@. Remember, the updated app's file name must be identical to {CFBundleName}.app", [SUInfoValueForKey(@"CFBundleName") stringByAppendingPathExtension:@"app"]);
		}
	}
	
	if (failed)
	{
		[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred during installation. Please try again later.", nil)];
		[self abandonUpdate];
        return;	
	}
	else if ([self isAutomaticallyUpdating]) // Don't do authentication if we're automatically updating; that'd be surprising.
	{
		int tag = 0;
		BOOL result = [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[currentAppPath stringByDeletingLastPathComponent] destination:@"" files:[NSArray arrayWithObject:[currentAppPath lastPathComponent]] tag:&tag];
		result &= [[NSFileManager defaultManager] movePath:newAppDownloadPath toPath:currentAppPath handler:nil];
		if (!result)
		{
			[self abandonUpdate];
			return;
		}
	}
	else // But if we're updating by the action of the user, do an authenticated move.
	{
		// Outside of the @try block because we want to be a little more informative on this error.
		if (![[NSFileManager defaultManager] movePathWithAuthentication:newAppDownloadPath toPath:currentAppPath])
		{
			[self showUpdateErrorAlertWithInfo:[NSString stringWithFormat:SULocalizedString(@"%@ does not have permission to write to the application's directory! Are you running off a disk image? If not, ask your system administrator for help.", nil), SUHostAppDisplayName()]];
			[self abandonUpdate];
			return;
		}
	}
		
	// Prompt for permission to restart if we're automatically updating.
	if ([self isAutomaticallyUpdating])
	{
		SUAutomaticUpdateAlert *alert = [[SUAutomaticUpdateAlert alloc] initWithAppcastItem:updateItem];
		if ([NSApp runModalForWindow:[alert window]] == NSAlertAlternateReturn)
		{
			[alert release];
			return;
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:SUUpdaterWillRestartNotification object:self];

	// Thanks to Allan Odgaard for this restart code, which is much more clever than mine was.
	setenv("LAUNCH_PATH", [currentAppPath fileSystemRepresentation], 1);
	setenv("TEMP_FOLDER", [[downloadPath stringByDeletingLastPathComponent] fileSystemRepresentation], 1); // delete the temp stuff after it's all over
	system("/bin/bash -c '{ for (( i = 0; i < 3000 && $(echo $(/bin/ps -xp $PPID|/usr/bin/wc -l))-1; i++ )); do\n"
		   "    /bin/sleep .2;\n"
		   "  done\n"
		   "  if [[ $(/bin/ps -xp $PPID|/usr/bin/wc -l) -ne 2 ]]; then\n"
		   "    /usr/bin/open \"${LAUNCH_PATH}\"\n"
		   "  fi\n"
		   "  rm -rf \"${TEMP_FOLDER}\"\n"
		   "} &>/dev/null &'");
	[NSApp terminate:self];	
}

- (IBAction)cancelDownload:sender
{
	if (downloader)
	{
		[downloader cancel];
		[downloader release];
	}
	[self abandonUpdate];
	
	if (checkInterval)
	{
		[self scheduleCheckWithInterval:checkInterval];
	}
}

@end