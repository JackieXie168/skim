/* =============================================================================
	FILE:		UKKQueue.m
	PROJECT:	Filie
    
    COPYRIGHT:  (c) 2003 M. Uli Kusterer, all rights reserved.
    
	AUTHORS:	M. Uli Kusterer - UK
    
    LICENSES:   MIT License

	REVISIONS:
		2006-03-13	UK	Clarified license, streamlined UKFileWatcher stuff,
						Changed notifications to be useful and turned off by
						default some deprecated stuff.
        2004-12-28  UK  Several threading fixes.
		2003-12-21	UK	Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "UKKQueue.h"
#import <unistd.h>
#import <fcntl.h>

// private class used to wrap path/fd for NSSet containment
@interface UKWatchedPath : NSObject
{
    NSString *path;
    int fd;
}
+ (id)watchedPathWithPath:(NSString *)fullPath;
- (int)fileDescriptor;
- (NSString *)path;
@end


// -----------------------------------------------------------------------------
//  Macros:
// -----------------------------------------------------------------------------

// @synchronized isn't available prior to 10.3, so we use a typedef so
//  this class is thread-safe on Panther but still compiles on older OSs.

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
#define AT_SYNCHRONIZED(n)      @synchronized(n)
#else
#define AT_SYNCHRONIZED(n)
#endif


// -----------------------------------------------------------------------------
//  Globals:
// -----------------------------------------------------------------------------

static UKKQueue * gUKKQueueSharedQueueSingleton = nil;


@implementation UKKQueue

// Deprecated:
#if UKKQUEUE_OLD_SINGLETON_ACCESSOR_NAME
+(UKKQueue*) sharedQueue
{
	return [self sharedFileWatcher];
}
#endif

// -----------------------------------------------------------------------------
//  sharedQueue:
//		Returns a singleton queue object. In many apps (especially those that
//      subscribe to the notifications) there will only be one kqueue instance,
//      and in that case you can use this.
//
//      For all other cases, feel free to create additional instances to use
//      independently.
//
//	REVISIONS:
//		2006-03-13	UK	Renamed from sharedQueue.
//      2005-07-02  UK  Created.
// -----------------------------------------------------------------------------

+(id) sharedFileWatcher
{
    AT_SYNCHRONIZED( self )
    {
        if( !gUKKQueueSharedQueueSingleton )
            gUKKQueueSharedQueueSingleton = [[UKKQueue alloc] init];	// This is a singleton, and thus an intentional "leak".
    }
    
    return gUKKQueueSharedQueueSingleton;
}


// -----------------------------------------------------------------------------
//	* CONSTRUCTOR:
//		Creates a new KQueue and starts that thread we use for our
//		notifications.
//
//	REVISIONS:
//      2004-11-12  UK  Doesn't pass self as parameter to watcherThread anymore,
//                      because detachNewThreadSelector retains target and args,
//                      which would cause us to never be released.
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(id)   init
{
	self = [super init];
	if( self )
	{
		queueFD = kqueue();
		if( queueFD == -1 )
		{
			[self release];
			return nil;
		}
		
		watchedPaths = [[NSMutableSet alloc] init];
		
		// Start new thread that fetches and processes our events:
		keepThreadRunning = YES;
		[NSThread detachNewThreadSelector:@selector(watcherThread:) toTarget:self withObject:nil];
	}
	
	return self;
}


// -----------------------------------------------------------------------------
//	release:
//		Since NSThread retains its target, we need this method to terminate the
//      thread when we reach a retain-count of two. The thread is terminated by
//      setting keepThreadRunning to NO.
//
//	REVISIONS:
//		2004-11-12	UK	Created.
// -----------------------------------------------------------------------------

-(oneway void) release
{
    AT_SYNCHRONIZED(self)
    {
        //NSLog(@"%@ (%d)", self, [self retainCount]);
        if( [self retainCount] == 2 && keepThreadRunning )
            keepThreadRunning = NO;
    }
    
    [super release];
}
    
// -----------------------------------------------------------------------------
//	* DESTRUCTOR:
//		Releases the kqueue again.
//
//	REVISIONS:
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(void) dealloc
{	
	if( keepThreadRunning )
		keepThreadRunning = NO;
	
	[watchedPaths release];
	watchedPaths = nil;
	
	[super dealloc];
    
    //NSLog(@"kqueue released.");
}


// -----------------------------------------------------------------------------
//	queueFD:
//		Returns a Unix file descriptor for the KQueue this uses. The descriptor
//		is owned by this object. Do not close it!
//
//	REVISIONS:
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(int)  queueFD
{
	return queueFD;
}


// -----------------------------------------------------------------------------
//	addPathToQueue:
//		Tell this queue to listen for all interesting notifications sent for
//		the object at the specified path. If you want more control, use the
//		addPathToQueue:notifyingAbout: variant instead.
//
//	REVISIONS:
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(void) addPathToQueue: (NSString*)path
{
	[self addPath: path];
}


-(void) addPath: (NSString*)path
{
	[self addPathToQueue: path notifyingAbout: UKKQueueNotifyAboutRename
												| UKKQueueNotifyAboutWrite
												| UKKQueueNotifyAboutDelete
												| UKKQueueNotifyAboutAttributeChange];
}


// -----------------------------------------------------------------------------
//	addPathToQueue:notfyingAbout:
//		Tell this queue to listen for the specified notifications sent for
//		the object at the specified path.
//
//	REVISIONS:
//      2005-06-29  UK  Files are now opened using O_EVTONLY instead of O_RDONLY
//                      which allows ejecting or deleting watched files/folders.
//                      Thanks to Phil Hargett for finding this flag in the docs.
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(void) addPathToQueue: (NSString*)path notifyingAbout: (u_int)fflags
{
	struct kevent		ev;
    UKWatchedPath       *watchedPath = [UKWatchedPath watchedPathWithPath:path];

    AT_SYNCHRONIZED( self )
    {
        if ([watchedPaths containsObject:watchedPath] == NO) {
            
            // this will be closed when watchedPath is dealloced
            int					fd = [watchedPath fileDescriptor];

            if( fd >= 0 )
            {
                
                [watchedPaths addObject:watchedPath];

                // add the instance that we know is retained by watchedPaths
                EV_SET( &ev, fd, EVFILT_VNODE, 
                    EV_ADD | EV_ENABLE | EV_CLEAR,
                    fflags, 0, (void*)watchedPath );
            
                kevent( queueFD, &ev, 1, NULL, 0, NULL );
            }
        }
    }
}

-(void) removePath: (NSString*)path
{
    [self removePathFromQueue: path];
}


// -----------------------------------------------------------------------------
//	removePathFromQueue:
//		Stop listening for changes to the specified path. This removes all
//		notifications. Use this to balance both addPathToQueue:notfyingAbout:
//		as well as addPathToQueue:.
//
//	REVISIONS:
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(void) removePathFromQueue: (NSString*)path
{
    AT_SYNCHRONIZED( self )
    {
        [watchedPaths removeObject:[UKWatchedPath watchedPathWithPath:path]];
    }
}


// -----------------------------------------------------------------------------
//	removeAllPathsFromQueue:
//		Stop listening for changes to all paths. This removes all
//		notifications.
//
//  REVISIONS:
//      2004-12-28  UK  Added as suggested by bbum.
// -----------------------------------------------------------------------------

-(void) removeAllPathsFromQueue;
{
    AT_SYNCHRONIZED( self )
    {
        [watchedPaths removeAllObjects];
    }
}

// -----------------------------------------------------------------------------
//	watcherThread:
//		This method is called by our NSThread to loop and poll for any file
//		changes that our kqueue wants to tell us about. This sends separate
//		notifications for the different kinds of changes that can happen.
//		All messages are sent via the postNotification:forFile: main bottleneck.
//
//		This also calls sharedWorkspace's noteFileSystemChanged.
//
//      To terminate this method (and its thread), set keepThreadRunning to NO.
//
//	REVISIONS:
//      2007-06-05  ARM Removed NSWorkspace notification posting, as it is not
//                      thread safe.
//		2005-08-27	UK	Changed to use keepThreadRunning instead of kqueueFD
//						being -1 as termination criterion, and to close the
//						queue in this thread so the main thread isn't blocked.
//		2004-11-12	UK	Fixed docs to include termination criterion, added
//                      timeout to make sure the bugger gets disposed.
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

-(void)		watcherThread: (id)sender
{
	int					n;
    struct kevent		ev;
	int					theFD = queueFD;	// So we don't have to risk accessing iVars when the thread is terminated.
    
    while( keepThreadRunning )
    {
		NSAutoreleasePool*  pool = [[NSAutoreleasePool alloc] init];
		
		NS_DURING
			n = kevent( queueFD, NULL, 0, &ev, 1, NULL );
			if( n > 0 )
			{
				if( ev.filter == EVFILT_VNODE )
				{
					if( ev.fflags )
					{
                        // retain in case one of the notified folks removes the path.
						NSString*		fpath = [[(UKWatchedPath *)ev.udata path] retain];
						//NSLog(@"UKKQueue: Detected file change: %@", fpath);
						
						//NSLog(@"ev.flags = %u",ev.fflags);	// DEBUG ONLY!
						
						if( (ev.fflags & NOTE_RENAME) == NOTE_RENAME )
							[self postNotification: UKFileWatcherRenameNotification forFile: fpath];
						if( (ev.fflags & NOTE_WRITE) == NOTE_WRITE )
							[self postNotification: UKFileWatcherWriteNotification forFile: fpath];
						if( (ev.fflags & NOTE_DELETE) == NOTE_DELETE )
							[self postNotification: UKFileWatcherDeleteNotification forFile: fpath];
						if( (ev.fflags & NOTE_ATTRIB) == NOTE_ATTRIB )
							[self postNotification: UKFileWatcherAttributeChangeNotification forFile: fpath];
						if( (ev.fflags & NOTE_EXTEND) == NOTE_EXTEND )
							[self postNotification: UKFileWatcherSizeIncreaseNotification forFile: fpath];
						if( (ev.fflags & NOTE_LINK) == NOTE_LINK )
							[self postNotification: UKFileWatcherLinkCountChangeNotification forFile: fpath];
						if( (ev.fflags & NOTE_REVOKE) == NOTE_REVOKE )
							[self postNotification: UKFileWatcherAccessRevocationNotification forFile: fpath];
                        
                        [fpath release];
					}
				}
			}
		NS_HANDLER
			NSLog(@"Error in UKKQueue watcherThread: %@",localException);
		NS_ENDHANDLER
		
		[pool release];
    }
    
	// Close our kqueue's file descriptor:
	if( close( theFD ) == -1 )
		NSLog(@"release: Couldn't close main kqueue (%d)", errno);
	
    //NSLog(@"exiting kqueue watcher thread.");
}


// -----------------------------------------------------------------------------
//	postNotification:forFile:
//		This is the main bottleneck for posting notifications. If you don't want
//		the notifications to go through NSWorkspace, override this method and
//		send them elsewhere.
//
//	REVISIONS:
//      2007-06-05  ARM Modified to queue notifications on the main thread
//                      rather than posting immediately on the UKKQueue thread.
//                      Removed delegate methods as we only use the singleton.
//      2004-02-27  UK  Changed this to send new notification, and the old one
//                      only to objects that respond to it. The old category on
//                      NSObject could cause problems with the proxy itself.
//		2004-10-31	UK	Helloween fun: Make this use a mainThreadProxy and
//						allow sending the notification even if we have a
//						delegate.
//		2004-03-13	UK	Documented.
// -----------------------------------------------------------------------------

// this is only a wrapper method for enqueueNotification:postingStyle: to avoid using NSInvocation
- (void)mainThreadEnqueueNotification:(NSNotification *)note
{
    [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostWhenIdle];
}

-(void) postNotification: (NSString*)nm forFile: (NSString*)fp
{
    NSString *key = @"path";
    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjects:&fp forKeys:&key count:1];
    
    // this is the notification we'll queue on the main thread
    NSNotification *note = [NSNotification notificationWithName:nm object:self userInfo:userInfo];
    [userInfo release];
    
    [self performSelectorOnMainThread:@selector(mainThreadEnqueueNotification:) withObject:note waitUntilDone:NO];
}

// -----------------------------------------------------------------------------
//	description:
//		This method can be used to help in debugging. It provides the value
//      used by NSLog & co. when you request to print this object using the
//      %@ format specifier.
//
//	REVISIONS:
//		2004-11-12	UK	Created.
// -----------------------------------------------------------------------------

-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ { watchedPaths = %@ }", [super description], watchedPaths ];
}

@end

// -----------------------------------------------------------------------------
//	description:
//		UKWatchedPath wraps a path and file descriptor into a single object,
//      implementing -hash and -isEqual: in terms of the path.  This allows
//      easier management of path/file descriptor pairs from the queue, and
//      enables use of NSMutableSet so duplicate paths are ignored.
//
//	REVISIONS:
//		2007-06-05	ARM	Created.
// -----------------------------------------------------------------------------


@implementation UKWatchedPath

// open() is documented to return -1 in case of an error and >=0 for success
static const int UNOPENED_DESCRIPTOR = -2;

- (id)initWatchedPathWithPath:(NSString *)fullPath;
{
    if (self = [super init]) {
        // copy since the hash mustn't change
        path = [fullPath copy];
        // allows us to open files lazily, since these may be created just for a path comparison when removing from the queue
        fd = UNOPENED_DESCRIPTOR;
    }
    return self;
}

+ (id)watchedPathWithPath:(NSString *)fullPath;
{
    return [[[self alloc] initWatchedPathWithPath:fullPath] autorelease];
}

- (void)dealloc
{
    [path release];
    // don't bother closing a descriptor that wasn't created; this may have been instantiated for comparison and immediately discarded
	if( fd >= 0 && close( fd ) == -1 )
        perror(NULL);
    [super dealloc];
}

- (unsigned int)hash { return [path hash]; }
// implement in terms of -isEqualToString: since that's what NSPathStore2 uses
- (BOOL)isEqual:(id)other { return [other isKindOfClass:[self class]] ? [path isEqualToString:[other path]] : NO; }
- (int)fileDescriptor { 
    if (fd == UNOPENED_DESCRIPTOR)
        fd = open([path fileSystemRepresentation], O_EVTONLY, 0);
    return fd; 
}
- (NSString *)path { return path; }

@end
