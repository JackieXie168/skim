//
//  SKWatchedPath.m
//  Skim
//
//  Created by Christiaan Hofmanon 11/18/12.
/*
 This software is Copyright (c) 2010-2013
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SKWatchedPath.h"
#include <sys/types.h>
#include <sys/event.h>
#import <unistd.h>
#import <fcntl.h>

NSString *SKWatchedPathRenameNotification = @"SKWatchedPathRenameNotification";
NSString *SKWatchedPathWriteNotification = @"SKWatchedPathWriteNotification";
NSString *SKWatchedPathDeleteNotification = @"SKWatchedPathDeleteNotification";

#define PATH_KEY @"path"

@implementation SKWatchedPath

// open() is documented to return -1 in case of an error and >=0 for success
static const NSInteger UNOPENED_DESCRIPTOR = -2;

static int kQueue = -1;
static NSCountedSet *watchedPaths = nil;

+ (void)initialize {
    SKINITIALIZE;
    
    watchedPaths = [[NSCountedSet alloc] init];
    kQueue = kqueue();
    
    if (kQueue != -1)
        [NSThread detachNewThreadSelector:@selector(watcherThread:) toTarget:self withObject:nil];
}

- (id)initWithPath:(NSString *)fullPath {
    self = [super init];
    if (self) {
        // copy since the hash mustn't change
        path = [fullPath copy];
        // allows us to open files lazily, since these may be created just for a path comparison when removing from the queue
        fd = UNOPENED_DESCRIPTOR;
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(path);
    // don't bother closing a descriptor that wasn't created; this may have been instantiated for comparison and immediately discarded
	if (fd >= 0 && close(fd) == -1)
        perror(NULL);
    [super dealloc];
}

- (NSUInteger)hash { return [path hash]; }

// implement in terms of -isEqualToString: since that's what NSPathStore2 uses
- (BOOL)isEqual:(id)other { return [other isKindOfClass:[self class]] ? [path isEqualToString:[other path]] : NO; }

- (int)fileDescriptor { 
    if (fd == UNOPENED_DESCRIPTOR)
        fd = open([path fileSystemRepresentation], O_EVTONLY, 0);
    return fd; 
}

- (NSString *)path { return path; }

+ (void)addWatchedPath:(NSString *)path {
    SKWatchedPath *watchedPath = [[self alloc] initWithPath:path];
    
    // see if we're altready watching this path
    SKWatchedPath *observedWatchedPath = [watchedPaths member:watchedPath];
    
    if (observedWatchedPath == nil || [observedWatchedPath fileDescriptor] < 0) {
        // this will be closed when watchedPath is dealloced
        int fd = [watchedPath fileDescriptor];
        if (fd >= 0) {
            // add the instance that we know will be retained by watchedPaths
            struct kevent ev;
            EV_SET(&ev, fd, EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_CLEAR, NOTE_RENAME | NOTE_WRITE | NOTE_DELETE, 0, (void *)watchedPath);
            kevent(kQueue, &ev, 1, NULL, 0, NULL);
            
            if (observedWatchedPath) {
                // replace observedWatchedPath by watchedPath in the NSCountedSet with the same count, the docs give us no guarantee that we can rely on the fact that -addObject: will do this for us
                NSUInteger i, count = [watchedPaths countForObject:observedWatchedPath];
                for (i = 0; i < count; i++)
                    [watchedPaths removeObject:observedWatchedPath];
                for (i = 0; i < count; i++)
                    [watchedPaths addObject:watchedPath];
            }
            observedWatchedPath = watchedPath;
        } else if (observedWatchedPath == nil) {
            observedWatchedPath = watchedPath;
        }
    }
    // don't add watchedPath, because that may replace observedWatchedPath in the NSCountedSet, which is a problem because observedWatchedPath knows the fileDescriptor
    // the docs say -addObject: does not replace an existing object, but my tests say it always does
    [watchedPaths addObject:observedWatchedPath];
    
    [watchedPath release];
}

+ (void)removeWatchedPath:(NSString *)path {
    SKWatchedPath *watchedPath = [[self alloc] initWithPath:path];
    [watchedPaths removeObject:watchedPath];
    [watchedPath release];
}

+ (void)watcherThread:(id)sender {
	int n;
    struct kevent ev;
	int theFD = kQueue;	// So we don't have to risk accessing iVars when the thread is terminated.
    
    while (YES) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        @try{
            n = kevent(kQueue, NULL, 0, &ev, 1, NULL);
            if (n > 0) {
                if (ev.filter == EVFILT_VNODE) {
                    if (ev.fflags) {
                        // retain in case one of the notified folks removes the path.
                        NSString *name = nil;
                        
                        if ((ev.fflags & NOTE_RENAME) == NOTE_RENAME)
                            name = SKWatchedPathRenameNotification;
                        if ((ev.fflags & NOTE_WRITE) == NOTE_WRITE)
                            name = SKWatchedPathWriteNotification;
                        if ((ev.fflags & NOTE_DELETE) == NOTE_DELETE)
                            name = SKWatchedPathDeleteNotification;
                        
                        if (name) {
                            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[(SKWatchedPath *)ev.udata path], PATH_KEY, nil];
                            // this is the notification we'll queue on the main thread
                            NSNotification *note = [NSNotification notificationWithName:name object:nil userInfo:userInfo];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostWhenIdle];
                            });
                        }
                    }
                }
            }
        }
        @catch (id e) {
            NSLog(@"Error in SKWatchedPath watcherThread: %@", e);
        }
        
        [pool release];
    }
    
	if (close(theFD) == -1)
		NSLog(@"release: Couldn't close main kqueue (%d)", errno);
}	

@end
