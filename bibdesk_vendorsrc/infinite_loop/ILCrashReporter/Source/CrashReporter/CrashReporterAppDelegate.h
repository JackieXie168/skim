//
//  CrashReporterAppDelegate.h
//  ILCrashReporter
//
//  Created by Claus Broch on Wed Jun 02 2004.
//  Copyright (c) 2004 Infinite Loop. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "CrashReporterController.h"


@interface CrashReporterAppDelegate : NSObject
{
	int						_processToWatch;
	NSString				*_processName;
	NSString				*_companyName;
	NSString				*_reportEmail;
	NSString				*_fromEmail;
	NSString				*_smtpServer;
	int						_smtpPort;
	id						_alertPanel;
	NSModalSession			_alertSession;
	BOOL					_shouldQuit;
	
	IBOutlet CrashReporterController *reportController;
}

@end

@interface CrashReporterAppDelegate(NSApplicationDelegate)

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;
- (void)applicationWillFinishLaunching:(NSNotification *)notification;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

@end