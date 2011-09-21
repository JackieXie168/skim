//
//  SUDiskImageUnarchiver.m
//  Sparkle
//
//  Created by Andy Matuschak on 6/16/08.
//  Copyright 2008 Andy Matuschak. All rights reserved.
//

#import "SUDiskImageUnarchiver.h"
#import "SUUnarchiver_Private.h"
#import "NTSynchronousTask.h"

@implementation SUDiskImageUnarchiver

+ (BOOL)_canUnarchivePath:(NSString *)path
{
	return [[path pathExtension] isEqualToString:@"dmg"];
}

- (void)_extractDMGContentFromPath:(NSString *)mountPoint
{		
    // get a local copy of NSFileManager because this is running from a secondary thread
    NSFileManager *fm;
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4)
        fm = [[[NSFileManager alloc] init] autorelease];
    else
        fm = [NSFileManager defaultManager];
	
	// Now that we've mounted it, we need to copy out its contents.
    NSString *targetPath = [[archivePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[mountPoint lastPathComponent]];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
    if (![fm createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:NULL])
#else
    if (![fm createDirectoryAtPath:targetPath attributes:nil])
#endif
        goto reportError; 	 
    
    // We can't just copyPath: from the volume root because that always fails. Seems to be a bug.
    
    id subpathEnumerator, currentSubpath;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
    subpathEnumerator = [[fm contentsOfDirectoryAtPath:mountPoint error:NULL] objectEnumerator];
#else
    subpathEnumerator = [[fm directoryContentsAtPath:mountPoint] objectEnumerator];
#endif
    while ((currentSubpath = [subpathEnumerator nextObject])) 	 
    { 	 
        NSString *currentFullPath = [mountPoint stringByAppendingPathComponent:currentSubpath]; 	 
        // Don't bother trying (and failing) to copy out files we can't read. That's not going to be the app anyway. 	 
        if (![fm isReadableFileAtPath:currentFullPath]) continue; 	 
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
        if (![fm copyItemAtPath:currentFullPath toPath:[targetPath stringByAppendingPathComponent:currentSubpath] error:NULL]) 	 
#else
        if (![fm copyPath:currentFullPath toPath:[targetPath stringByAppendingPathComponent:currentSubpath] handler:nil]) 	 
#endif
            goto reportError; 	 
    }
	
	[self performSelectorOnMainThread:@selector(_notifyDelegateOfSuccess) withObject:nil waitUntilDone:NO];
	goto finally;
	
reportError:
	[self performSelectorOnMainThread:@selector(_notifyDelegateOfFailure) withObject:nil waitUntilDone:NO];

finally:
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/hdiutil" arguments:[NSArray arrayWithObjects:@"detach", mountPoint, @"-force", nil]];
}

- (void)_extractDMGFromPath:(NSString *)mountPoint
{		
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray* arguments = [NSArray arrayWithObjects:@"attach", archivePath, @"-mountpoint", mountPoint, @"-noverify", @"-nobrowse", @"-noautoopen", nil];
	// set up a pipe and push "yes" (y works too), this will accept any license agreement crap
	// not every .dmg needs this, but this will make sure it works with everyone
	NSData* yesData = [[[NSData alloc] initWithBytes:"yes\n" length:4] autorelease];
	
	NSData *result = [NTSynchronousTask task:@"/usr/bin/hdiutil" directory:@"/" withArgs:arguments input:yesData];
	if (!result)
        [self performSelectorOnMainThread:@selector(_notifyDelegateOfFailure) withObject:nil waitUntilDone:NO];
    else if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4)
        [self _extractDMGContentFromPath:mountPoint];
    else
        [self performSelectorOnMainThread:@selector(_extractDMGContentFromPath:) withObject:mountPoint waitUntilDone:NO];
    
    [pool drain];
}

- (void)start
{
	NSString *mountPoint = nil;
	do
	{
		CFUUIDRef uuid = CFUUIDCreate(NULL);
		NSString *mountPointName = (NSString *)CFUUIDCreateString(NULL, uuid);
		CFRelease(uuid);
		mountPoint = [@"/Volumes" stringByAppendingPathComponent:mountPointName];
        [mountPointName release];
	}
	while ([[NSFileManager defaultManager] fileExistsAtPath:mountPoint]);
    
    [NSThread detachNewThreadSelector:@selector(_extractDMGFromPath:) toTarget:self withObject:mountPoint];
}

+ (void)load
{
	[self _registerImplementation:self];
}

@end
