//
//  CrashReporterController.m
//  ILCrashReporter
//
//  Created by Claus Broch on Sun Jul 11 2004.
//  Copyright 2004 Infinite Loop. All rights reserved.
//

#import <fcntl.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <sys/sysctl.h>
#import <unistd.h>
#import <AddressBook/AddressBook.h>
#import "CrashReporterController.h"

@interface CrashReporterController(Private)

- (void)setupLocalizedFields;
- (void)fillOutUserCredentials;
- (NSString*)gatherCrashLog:(NSString*)appName;
- (NSString*)gatherCrashLogForApplication:(NSString*)appName fromLocation:(NSString*)crashLogPath;
- (NSString*)gatherConsoleLogForApplication:(NSString*)appName withProcessID:(int)processID;
- (NSString*)currentArchitecture;

@end

@implementation CrashReporterController

- (void)prepareReportForApplication:(NSString*)appName process:(int)processID companyName:(NSString*)companyName
{
	NSWindow	*win;
	NSString	*crashLog;
	NSString	*consoleLog;
	NSString	*buttonText;
	NSString	*windowTitle;
	NSRect		frame;
	float		x;
	
	//Make sure window is loaded from nib
	win = [self window];
	
	[self setupLocalizedFields];
	[self fillOutUserCredentials];
	
	//[crashLogHeader setStringValue:NSLocalizedString(@"Crash Report:", @"Crash log header")];
	[[reportsTabView tabViewItemAtIndex:
		[reportsTabView indexOfTabViewItemWithIdentifier:@"crashreport"]]
		setLabel:NSLocalizedString(@"Crash Report", @"Crash log header")];
	crashLog = [self gatherCrashLog:appName];
	[crashLogTextView setString:(crashLog ? crashLog : @"")];
	
	[[reportsTabView tabViewItemAtIndex:
		[reportsTabView indexOfTabViewItemWithIdentifier:@"consolelog"]]
		setLabel:NSLocalizedString(@"Console Log", @"Console log header")];
	consoleLog = [self gatherConsoleLogForApplication:appName withProcessID:processID];
	[consoleLogTextView setString:(consoleLog ? consoleLog : @"")];
		

	buttonText = [NSString stringWithFormat:
		NSLocalizedString(@"Send to %@", @"Send to #COMPANY# button text"), companyName];
	[submitButton setTitle:buttonText];
	frame = [submitButton frame];
	x = NSMaxX(frame);
	[submitButton sizeToFit];
	frame = [submitButton frame];
	frame.origin.x += x - NSMaxX(frame);
	[submitButton setFrameOrigin:frame.origin];

	windowTitle = [NSString stringWithFormat:NSLocalizedString(@"Crash report for \"%@\"", "Crash report window title"), appName];
	[win setTitle:windowTitle];
	
	[win setLevel:NSNormalWindowLevel];
	[win makeKeyAndOrderFront:self];
	//[win orderFrontRegardless];
}

- (IBAction)submitReport:(id)sender
{
	NSString		*userNotes;
	NSString		*crashLog;
	NSString		*consoleLog;
	NSString		*name;
	NSString		*email;
	NSDictionary	*report;
	
	if([_delegate respondsToSelector:@selector(userDidSubmitCrashReport:)])
	{
		userNotes = [descriptionTextView string];
		crashLog = [crashLogTextView string];
		consoleLog = [consoleLogTextView string];
		name = [nameField stringValue];
		email = [emailField stringValue];
		report = [NSDictionary dictionaryWithObjectsAndKeys:
			userNotes, @"notes",
			crashLog, @"crashlog",
			consoleLog, @"consolelog",
			(name != nil) ? name : @"", @"name",
			(email != nil) ? email : @"", @"email",
			nil ];
		
		[_delegate userDidSubmitCrashReport:report];
		_hasSubmittedReport = YES;
	}
	
	[[self window] performClose:self];
}

- (void)windowWillClose:(NSNotification *)notification
{
	if(!_hasSubmittedReport)
	{
		if([_delegate respondsToSelector:@selector(userDidCancelCrashReport)])
			[_delegate userDidCancelCrashReport];
	}
}

- (void)setDelegate:(id)delegate
{
	if(delegate != _delegate)
	{
		[_delegate release];
		_delegate = [delegate retain];
	}
}

@end

@implementation CrashReporterController(Private)

- (void)setupLocalizedFields
{
	[nameLabelField setStringValue:
		NSLocalizedString(@"Your name:", @"Field header")];
	[nameField setToolTip:
		NSLocalizedString(@"Leave field blank to remain anomymous", @"Field tool tip")];
	[emailLabelField setStringValue:
		NSLocalizedString(@"Your email:", @"Field header")];
	[emailField setToolTip:
		NSLocalizedString(@"Leave field blank to remain anomymous", @"Field tool tip")];
	
	[descriptionHeader setStringValue:
		NSLocalizedString(@"Problem Description:", @"Description header")];
	[descriptionTextView setString:
		NSLocalizedString(@"Please describe the circumstances leading to the crash and any other relevant information:\n\n", @"Description text")];
}

- (void)fillOutUserCredentials
{
	ABAddressBook	*book = [ABAddressBook sharedAddressBook];
	ABPerson	*me = [book me];
	
	// Current User
	if(me)
	{
		NSString	*firstName;
		NSString	*lastName;
		
		firstName = [me valueForProperty:kABFirstNameProperty];
		lastName = [me valueForProperty:kABLastNameProperty];
		if(firstName || lastName)
		{
			[nameField setStringValue:[NSString stringWithFormat:@"%@%@%@",
										  firstName ? firstName : @"",
								   firstName && lastName ? @" " : @"",
											lastName ? lastName : @""]];
		}
	}
	else
	{
		[nameField setStringValue:NSFullUserName()];
	}
	
	// Email
	if(me)
	{
		ABMultiValue *mails = [me valueForProperty:kABEmailProperty];
		if(mails && [mails count])
		{
			NSString	*email = [mails valueAtIndex:[mails indexForIdentifier:[mails primaryIdentifier]]];
			
			if(!email)
				email = [mails valueAtIndex:0];
			if(email)
				[emailField setStringValue:email];
		}
	}
}

- (NSString*)gatherCrashLog:(NSString*)appName
{
	NSString* crashLog = nil;
	
	// First try in NSHomeDirectory()...
	crashLog = [self gatherCrashLogForApplication:appName
									 fromLocation:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/CrashReporter"]];
	
	// ...but if that doesn't work, try /Library/Logs/CrashReporter
	if(!crashLog) {
		crashLog = [self gatherCrashLogForApplication:appName
										 fromLocation:@"/Library/Logs/CrashReporter"];
	}
	
	// If we still can't find it, use placeholders and log a message
	if(!crashLog) {
		NSLog(@"Could not find crashlog for %@", appName);
		crashLog = NSLocalizedString(@"Could not locate crash report.", @"Missing crash report");
	}
	
	return crashLog;
}

- (NSString*)gatherCrashLogForApplication:(NSString*)appName fromLocation:(NSString*)crashLogPath
{
	NSString	*crashLogName;
	NSString	*crashLog = nil;
	
	crashLogName = [NSString stringWithFormat:@"%@.crash.log", appName];
	crashLogPath = [crashLogPath stringByAppendingPathComponent:crashLogName];
	if(crashLogPath && [[NSFileManager defaultManager] fileExistsAtPath:crashLogPath])
	{
		crashLog = [NSString stringWithContentsOfFile:crashLogPath];
		if(crashLog)
		{
			NSRange delimRng;
			
			delimRng = [crashLog rangeOfString:@"**********" options:NSBackwardsSearch];
			if((delimRng.length != 0) && (delimRng.location != NSNotFound))
			{
				NSRange logRange;
				
				// Crash log contains more logs - only need the last one
				logRange.location = delimRng.location + delimRng.length;
				logRange.length = [crashLog length] - logRange.location;
				crashLog = [crashLog substringWithRange:logRange];
				
				// Insert a line to make it easier to match stripped universal binary versions with the unstripped version
				if(crashLog)
				{
					NSRange		logInsertPoint;
					
					logInsertPoint = [crashLog rangeOfString:@"Date/Time:"];
					if((logInsertPoint.length != 0) && (logInsertPoint.location != NSNotFound))
					{
						crashLog = [NSString stringWithFormat:@"%@Architecture:   %@\n%@",
							[crashLog substringToIndex:logInsertPoint.location],
							[self currentArchitecture],
							[crashLog substringFromIndex:logInsertPoint.location]];
					}
				}
			}
		}
		else
			NSLog(@"Could not load crashlog: %@", crashLogPath);
	}
	
	return crashLog;
}

- (NSString*)gatherConsoleLogForApplication:(NSString*)appName withProcessID:(int)processID
{
	NSString	*consoleLog = nil;
	NSString	*path;
	NSFileManager	*mgr = [NSFileManager defaultManager];
	
	path = [NSString stringWithFormat:@"/Library/Logs/Console/%d/console.log", getuid()]; //10.4
	if(!path || ![mgr fileExistsAtPath:path])
		path = [NSString stringWithFormat:@"/Library/Logs/Console/%@/console.log", NSUserName()]; // 10.3
	if(!path || ![mgr fileExistsAtPath:path])
		path = @"/var/tmp/console.log"; // 10.2
	path = [path stringByResolvingSymlinksInPath];
	if([mgr fileExistsAtPath:path])
	{
		consoleLog = [NSString stringWithContentsOfFile:path];
		
		// Limit the console log to 512 KB to prevent over-stuffing the receiving email account
		if([consoleLog length] > 512*1024)
			consoleLog = [consoleLog substringToIndex:512*1024];
	}
	
	return consoleLog;
}

- (NSString*)currentArchitecture
{
	size_t size;
	cpu_type_t	cputype;
	cpu_subtype_t	subtype;
	
	size = sizeof(cputype);
	if(sysctlbyname("hw.cputype", &cputype, &size, NULL, 0) < 0)
		cputype = 0;
	size = sizeof(subtype);
	if(sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0) < 0)
		subtype = 0;
	
	switch(cputype)
	{
		case CPU_TYPE_I386:
			return @"i386";
			
		case CPU_TYPE_POWERPC:
			switch(subtype)
			{
				case CPU_SUBTYPE_POWERPC_970:
					return @"ppc970";
					
				case CPU_SUBTYPE_POWERPC_7400:
				case CPU_SUBTYPE_POWERPC_7450:
					return @"ppc7400";
					
				default:
					return @"ppc";
			}
			
		case CPU_TYPE_POWERPC64:
			return @"ppc64";
	}
	
	return @"unknown";
}

@end

