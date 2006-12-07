//
//  ILCrashReporter.m
//  ILCrashReporter
//
//  Created by Claus Broch on Thu Jul 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ILCrashReporter.h"

static ILCrashReporter  *_reporter = nil;
static NSTask			*_reporterTask = nil;

@implementation ILCrashReporter

+ (ILCrashReporter*)defaultReporter
{
	if(!_reporter)
		_reporter = [[ILCrashReporter alloc] init];
	
	return _reporter;
}

- (void)launchReporterForCompany:(NSString*)company reportAddr:(NSString*)reportAddr
{
	[self launchReporterForCompany:company reportAddr:reportAddr fromAddr:reportAddr];
}

- (void)launchReporterForCompany:(NSString*)company reportAddr:(NSString*)reportAddr fromAddr:(NSString*)fromAddr
{
	[self launchReporterForCompany:company reportAddr:reportAddr fromAddr:fromAddr smtpServer:nil smtpPort:25];
}

- (void)launchReporterForCompany:(NSString*)company reportAddr:(NSString*)reportAddr fromAddr:(NSString*)fromAddr smtpServer:(NSString*)smtpServer smtpPort:(int)smtpPort
{
    //NSPipe          *pipe;
    NSBundle        *bundle;
    NSString        *path;
    NSProcessInfo   *procInfo;
    NSMutableArray	*args;
    int             pid;
    
	if(!_reporterTask)
	{
		_reporterTask = [[NSTask alloc] init];
		//pipe = [NSPipe pipe];
		//crashReporterPipe = [pipe fileHandleForWriting];
		//[crashReporterTask setStandardInput:pipe];
		
		bundle = [NSBundle bundleForClass:[self class]];
		path = [bundle pathForResource:@"CrashReporter" ofType:@"app"];
		path = [path stringByResolvingSymlinksInPath];
		bundle = [NSBundle bundleWithPath:path];
		path = [bundle executablePath];
		[_reporterTask setLaunchPath:path];
		
		procInfo = [NSProcessInfo processInfo];
		pid = [procInfo processIdentifier];
		/*
		args = [NSArray arrayWithObjects:
			[NSString stringWithFormat:@"%d", pid],
			company,
			reportAddr,
			fromAddr,
			nil];
		 */
		args = [NSMutableArray arrayWithObjects:
			@"-pidToWatch", [NSString stringWithFormat:@"%d", pid],
			@"-company", company,
			@"-reportAddr", reportAddr,
			@"-fromAddr", fromAddr,
			nil];
		
		if(smtpServer && ![smtpServer isEqualToString:@""])
		{
			[args addObjectsFromArray:[NSArray arrayWithObjects:
				@"-smtpServer", smtpServer,
				@"-smtpPort", [NSString stringWithFormat:@"%d", smtpPort],
				nil]];
		}
		
		[_reporterTask setArguments:args];
		
		[_reporterTask launch];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_appWillTerminate:)
													 name:NSApplicationWillTerminateNotification
												   object:NSApp];
	}
}

- (void)terminate
{
	if(_reporterTask)
	{
		[_reporterTask terminate];
		[_reporterTask release];
		_reporterTask = nil;
	}
}

- (void)_appWillTerminate:(NSNotification*)notification
{
	[self terminate];
}

- (void)test
{
    NSProcessInfo   *procInfo;
    //int             pid;
	
	procInfo = [NSProcessInfo processInfo];
	//pid = [procInfo processIdentifier];
	NSLog(@"Testing crash reporter interface");
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"ILCrashReporterTest" 
																   object:[procInfo processName]];
}

@end
