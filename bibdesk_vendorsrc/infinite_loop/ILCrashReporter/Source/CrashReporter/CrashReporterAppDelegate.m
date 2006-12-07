//
//  CrashReporterAppDelegate.m
//  ILCrashReporter
//
//  Created by Claus Broch on Wed Jun 02 2004.
//  Copyright 2004 Infinite Loop. All rights reserved.
//

//#import <Message/NSMailDelivery.h>

#import "CrashReporterAppDelegate.h"
#import "GetPID.h"
#import "SMTPMailDelivery.h"

@interface CrashReporterAppDelegate(Private)

- (void)_suppressAppleCrashNotify;
- (void)_appTerminated:(NSNotification *)notification;
- (void)_appLaunched:(NSNotification *)notification;
- (void)_displayCrashNotificationForProcess:(NSString*)processName;
- (void)_serviceCrashAlert;

@end

@implementation CrashReporterAppDelegate

- (void)dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[_processName release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[reportController setDelegate:self];
}

@end

@implementation CrashReporterAppDelegate(CrashReporterControllerDelegate)

- (void)userDidSubmitCrashReport:(NSDictionary*)report
{
	if(report)
	{
		//NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults]; 
		//NSString* smtpFromAddress = [defaults stringForKey:PMXSMTPFromAddress]; 
		NSString	*subject;
		BOOL sent = NO; 
		NSFileWrapper* fw; 
		//NSTextAttachment* ta; 
		//NSAttributedString* msg;
		NSString	*notes;
		NSString	*log;
		NSString	*logName;
		NSString	*name;
		NSString	*email;
		NSString	*mailMessage;
		NSMutableArray	*attachments = [NSMutableArray array];
		
		name = [report objectForKey:@"name"];
		email = [report objectForKey:@"email"];
		notes = [report objectForKey:@"notes"];
		if(name || email)
			mailMessage = [NSString stringWithFormat:NSLocalizedString(@"Reported by: %@ <%@>\n\n%@", @"Report template"), name, email, notes];
		else
			mailMessage = notes;
		
		log = [report objectForKey:@"crashlog"];
		logName = [NSString stringWithFormat:@"%@.crash.log", _processName];
		fw = [[NSFileWrapper alloc] initRegularFileWithContents:[log dataUsingEncoding:NSUTF8StringEncoding]]; 
		[fw setFilename:logName]; 
		[fw setPreferredFilename:logName]; 
		[attachments addObject:fw];

		log = [report objectForKey:@"consolelog"];
		logName = @"console.log";
		fw = [[NSFileWrapper alloc] initRegularFileWithContents:[log dataUsingEncoding:NSUTF8StringEncoding]]; 
		[fw setFilename:logName]; 
		[fw setPreferredFilename:logName]; 
		[attachments addObject:fw];
		
		//ta = [[NSTextAttachment alloc] initWithFileWrapper:fw];
		//msg = [NSAttributedString attributedStringWithAttachment:ta]; 
		subject = [NSString stringWithFormat:NSLocalizedString(@"Crash report for \"%@\"", "Crash report window title"), _processName];
		
		
#if 1
		NSData *rawMail = [SMTPMailDelivery mailMessage:mailMessage 
											 withSubject:subject
													  to:_reportEmail
													from:_fromEmail
											 attachments:attachments];
		if(_smtpServer)
		{
			SMTPMailDelivery	*sender;
			
			sender = [[SMTPMailDelivery alloc] init];
			sent = [sender sendMail:rawMail to:_reportEmail from:_fromEmail usingServer:_smtpServer onPort:_smtpPort];
			[sender release];
		}
		else
		{
			sent = [SMTPMailDelivery sendMail:rawMail
										   to:_reportEmail
										 from:_fromEmail];
		}
		
		if(sent)
			NSLog(@"Successfully sent crash report to %@", _companyName);
		else
			NSLog(@"Could not send crash report to %@", _companyName);
#else
		NSMutableDictionary *headers = [NSMutableDictionary dictionary]; 
		[headers setObject:_fromEmail forKey:@"From"]; 
		[headers setObject:_reportEmail forKey:@"To"]; 
		[headers setObject:subject forKey:@"Subject"]; 
		[headers setObject:@"ILCrashReporter" forKey:@"X-Mailer"]; 
		[headers setObject:@"multipart/mixed" forKey:@"Content-Type"]; 
		[headers setObject:@"1.0" forKey:@"Mime-Version"]; 

		if([NSMailDelivery hasDeliveryClassBeenConfigured])
		{
			sent = [NSMailDelivery deliverMessage:msg 
										  headers:headers 
										   format:NSMIMEMailFormat 
										 protocol:NSSMTPDeliveryProtocol];
		}
#endif

		//[ta release]; 
		[fw release];
		
		_shouldQuit = YES;
	}
}

- (void)userDidCancelCrashReport
{
	_shouldQuit = YES;
}

@end

@implementation CrashReporterAppDelegate(NSApplicationDelegate)


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
#if DEBUG
	NSLog(@"applicationShouldTerminate:");
#endif
	
	return _shouldQuit;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
#if DEBUG
	NSLog(@"applicationShouldTerminateAfterLastWindowClosed:");
#endif
	
	return _shouldQuit;
}


- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	//NSLog(@"applicationWillFinishLaunching:");
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	//NSProcessInfo   *procInfo;
	//NSArray			*args;
	NSUserDefaults	*defaults;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	//NSLog(@"applicationDidFinishLaunching:");
	_processToWatch = [defaults integerForKey:@"pidToWatch"];
	_companyName = [defaults stringForKey:@"company"];
	_reportEmail = [defaults stringForKey:@"reportAddr"];
	_fromEmail = [defaults stringForKey:@"fromAddr"];
	_smtpServer = [defaults stringForKey:@"smtpServer"];
	if([defaults objectForKey:@"smtpPort"])
		_smtpPort = [defaults integerForKey:@"smtpPort"];
	
	if(_smtpPort == 0)
		_smtpPort = 25;

#if DEBUG
	NSLog(@"%@", [[NSProcessInfo processInfo] arguments]);
#endif
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(_appTerminated:)
															   name:NSWorkspaceDidTerminateApplicationNotification
															 object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(_appLaunched:)
															   name:NSWorkspaceDidLaunchApplicationNotification
															 object:nil];
	if([defaults boolForKey:@"EnableInterfaceTest"])
	{
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(_displayCrashNotificationTest:)
																name:@"ILCrashReporterTest"
															  object:nil];
	}
}

@end

@implementation CrashReporterAppDelegate(Private)

- (void)_displayCrashNotificationTest:(NSNotification*)notification
{
	_processName = [[notification object] retain];
	[self _displayCrashNotificationForProcess:_processName];
}

- (void)_displayCrashNotificationForProcess:(NSString*)processName
{
	NSString	*title;
	NSString	*message;
	NSString	*button1;
	NSString	*button2;

	title = [NSString stringWithFormat:NSLocalizedString(@"The application %@ has unexpectedly quit.", @"App crash title"), processName];
	message = [NSString stringWithFormat:NSLocalizedString(@"The system and other applications have not been affected.\n\nWould you like to submit a bug report to %@?", @"App crash message"), _companyName];
	button1 = NSLocalizedString(@"Cancel", @"Button title");
	button2 = NSLocalizedString(@"Submit Report...", @"Button title");
	_alertPanel = NSGetInformationalAlertPanel(title, message, button1, nil, button2);
	if(_alertPanel)
	{
		_alertSession = [NSApp beginModalSessionForWindow:_alertPanel];
		[_alertPanel setLevel:NSStatusWindowLevel];
		//[_alertPanel orderFrontRegardless];
		[_alertPanel makeKeyAndOrderFront:self];
		[self _serviceCrashAlert];
	}
}

- (void)_serviceCrashAlert
{
	int response = [NSApp runModalSession:_alertSession];
	if(response == NSRunContinuesResponse)
	{
		[self performSelector:@selector(_serviceCrashAlert) withObject:nil afterDelay:0.05];
	}
	else
	{
		[NSApp endModalSession:_alertSession];
		NSReleaseAlertPanel(_alertPanel);
		_alertPanel = nil;
		
		if(response == NSAlertOtherReturn)
		{
			[reportController prepareReportForApplication:_processName process:_processToWatch companyName:_companyName];
		}
		else
			_shouldQuit = YES;
	}
	
}

- (void)_suppressAppleCrashNotify
{
	pid_t			pids[50];   // More than enough ???
	unsigned int	noOfPids = 0;
	int				err;
	static int		noOfRuns = 0;
	static BOOL		firstBlood = NO;
	
	// This is a dirty, rotten hack but it seems to work
	err = GetAllPIDsForProcessName("UserNotificationCenter", pids, 50, &noOfPids, nil);
	if(err == 0)
	{
		int i;
		
		for(i = 0; i < noOfPids; i++)
		{
			kill(pids[i], SIGTERM);
#if DEBUG
			NSLog(@"Suppressed Apple Crash Notify (pid: %d)", pids[i]);
#endif
			
			// When the Apple Crash notification is shown the crash data has been gathered
			// (at least that's what my tests show)
			if(!firstBlood)
			{
				firstBlood = YES;
				[self _displayCrashNotificationForProcess:_processName];
			}
		}
	}
	
	if(noOfRuns++ < 100) // Don't run forever
		[self performSelector:@selector(_suppressAppleCrashNotify) withObject:nil afterDelay:0.1+((float)noOfRuns / 50.0)];
	else
	{
#if DEBUG
		NSLog(@"Bye bye");
#endif
        // make sure we allow ourselves to quit
		_shouldQuit = YES;
        [NSApp terminate:self];
	}
}

- (void)_appTerminated:(NSNotification *)notification
{
	NSDictionary	*info;
	NSNumber		*pid;
	
	info = [notification userInfo];
	pid = [info objectForKey:@"NSApplicationProcessIdentifier"];
	if(pid && ([pid intValue] == _processToWatch))
	{
		//_processName = [[info objectForKey:@"NSApplicationName"] retain];
		_processName = [[[[NSBundle bundleWithPath:[info objectForKey:@"NSApplicationPath"]] executablePath] lastPathComponent] retain];
		
		NSLog(@"%@ terminated unexpectedly - preparing report", _processName);
		
		[self _suppressAppleCrashNotify];
		//[NSApp terminate:self];
	}
	//NSLog(@"appTerminated: %@", notification);
}

- (void)_appLaunched:(NSNotification *)notification
{
	NSDictionary	*info;
	//NSNumber		*pid;
	
	info = [notification userInfo];

#if DEBUG
	NSLog(@"_appLaunched: %@", info);
#endif
}

@end
