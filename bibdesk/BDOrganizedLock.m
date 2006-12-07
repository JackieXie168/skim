//
//  BDOrganizedLock.m
//  BibDesk
//  This is a self-contained class designed for easy use in any application.
//
//  Created (including algorithm design) by Matthew Cook on Sun Sep 28 2003.
//  Copyright (c) 2003 Matthew Cook. All rights reserved.
//  You may use this as part of BibDesk under "the new BSD license".
//  You may use this for other purposes under the latest version of "the Gnu Public License".

/* Discussion:

    We have a mob of people who want to do jobs that cannot be done in parallel.
    When someone comes in they have to state their purpose and take a number.
        That is, they are given an NSLock and they lock it.
        Then the number can be called asynchronously by unlocking it.
        The thread waits for its number to be called by locking it (again).
    When your number is called, you have a virtual lock.  This is exactly the BDOrganizedLock.
    You return the lock by calling the next number.
    
*/

#import "BDOrganizedLock.h"


@implementation BDOrganizedLock

#define jobSuperceded internalLock // a secret code -- any hidden persistent object could be used here


- (BDOrganizedLock*)init
{
    [super init];
    internalLock = [[NSLock alloc] init];
    lockList = [[NSMutableArray alloc] initWithCapacity:10];
    forList = [[NSMutableArray alloc] initWithCapacity:10];
    jobList = [[NSMutableArray alloc] initWithCapacity:10];
    debugging = NO; // just change to YES for any lock you want to monitor the use of
    return self;
} // [BDOrganizedLock init]


- (int)lockFor:(id)who job:(id)why
{
    NSLock *number = [[NSLock alloc] init];
    BOOL virtualLockIsOurs;
    int i;
    
    [internalLock lock];
        if (debugging) {
            fprintf(stderr, "Thread %d requesting lock.  Taking number %d.\n",
                    (int)[NSThread currentThread], (int)number);
            if (currentLockHolder != nil)
                fprintf(stderr, "  Must wait: Lock in use by number %d.\n",
                    (int)currentLockHolder);
        }
        // for efficiency, tag the request (if any) that this supercedes
        if (who != nil)
            for (i = [forList count] - 1; i >= 0; i--)
                if ([forList objectAtIndex:i] == who) {
                    // we found what we supercede.  remember, it might be happening!
                    if ([lockList objectAtIndex:i] != currentLockHolder) // don't trash job info if job is getting done
                        [jobList replaceObjectAtIndex:i withObject:jobSuperceded];
                    break;
                }
        // add ourself to list
        [lockList addObject:number];
        [forList addObject: who != nil ? who : [NSThread currentThread]]; // currentThread is just something
        [jobList addObject: why != nil ? why : [NSThread currentThread]]; // that is unique for every thread
        
        // get ready to go
        virtualLockIsOurs = (currentLockHolder == nil);
        if (virtualLockIsOurs) {
            currentLockHolder = number; // no need to retain, since currentLockHolder is always in lockList
            // imagine locking number and having it released by the ghost
            // what return value would the ghost have set?
            returnValue = [why isEqual:previousJob] ? BDWorkJustDone : BDDoTheWork; // works for nil too
            if (debugging)
                fprintf(stderr, "  Lock is not in use.  Can take it immediately with %s.\n",
                        returnValue == BDWorkJustDone ? "BDWorkJustDone" : "BDDoTheWork");
        } else {
            [number lock];
        }
    [internalLock unlock];

    if (virtualLockIsOurs) {
        // [number lock]; // this will immediately succeed; it's a waste of time
    } else {
        [number lock]; // wait for our number to be called
        // we are already the currentLockHolder now that we have been called (unlock did it)
        // note that somebody else is using the internalLock to release us here
    }
    // number will never be used again <em>as a lock</em>.  It will be used for pointer comparison (currentLockHolder vs. lockList).
    if (debugging)
        fprintf(stderr, "Number %d now has lock.\n", (int)number);
    
	[number release];
    return returnValue; // this was set by the previous unlocker
} // [BDOrganizedLock lockFor:job:]


- (void)unlock
{
    int i;
    
    [internalLock lock];
    if (debugging)
        fprintf(stderr, "Number %d relinquishing lock.\n", (int)currentLockHolder);
    // take ourself out of the list
    for (i = 0; i < [lockList count]; i++)
        if ([lockList objectAtIndex:i] == currentLockHolder) {
            if (returnValue == BDDoTheWork) { // did this thread do more work?
                [previousJob release];
                previousJob = [jobList objectAtIndex:i]; // make a note of what that work was
                [previousJob retain];
            }
            [lockList removeObjectAtIndex:i];
            [forList removeObjectAtIndex:i];
            [jobList removeObjectAtIndex:i];
            break;
        }
    // figure out who's next up:  (1) anybody superceded (2) anybody doing repeat work (3) anybody (4) nobody
    for (i = 0; i < [lockList count]; i++)
        if ([jobList objectAtIndex:i] == jobSuperceded) {
            currentLockHolder = [lockList objectAtIndex:i];
            returnValue = BDOtherWorkRequested;
            if (debugging)
                fprintf(stderr, "  Calling number %d (with BDOtherWorkRequested).\n",
                        (int)currentLockHolder);
            [currentLockHolder unlock];
            [internalLock unlock];
            return;
        }
    for (i = 0; i < [lockList count]; i++)
        if ([previousJob isEqual:[jobList objectAtIndex:i]]) {
            currentLockHolder = [lockList objectAtIndex:i];
            returnValue = BDWorkJustDone;
            if (debugging)
                fprintf(stderr, "  Calling number %d (with BDWorkJustDone).\n",
                        (int)currentLockHolder);
            [currentLockHolder unlock];
            [internalLock unlock];
            return;
        }
    if ([lockList count] > 0) {
        currentLockHolder = [lockList objectAtIndex:0];
        returnValue = BDDoTheWork;
        if (debugging)
            fprintf(stderr, "  Calling number %d (with BDDoTheWork).\n",
                    (int)currentLockHolder);
        [currentLockHolder unlock];
        [internalLock unlock];
        return;
    } else {
        currentLockHolder = nil;
        if (debugging)
            fprintf(stderr, "  No numbers to call.\n");
        [internalLock unlock];
        return;
    }
        
} // [BDOrganizedLock unlock]


- (void)dealloc
{
    [internalLock release];
    [lockList release];
    [forList release];
    [jobList release];
    [super dealloc];
} // [BDOrganizedLock dealloc]

@end
