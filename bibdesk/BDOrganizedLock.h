//
//  BDOrganizedLock.h
//  BibDesk
//  This is a self-contained class designed for easy use in any application.
//
//  Created (including algorithm design) by Matthew Cook on Sun Sep 28 2003.
//  Copyright (c) 2003 Matthew Cook. All rights reserved.
//  You may use this as part of BibDesk under "the new BSD license".
//  You may use this for other purposes under the latest version of "the Gnu Public License".

#import <Foundation/Foundation.h>


/*! @header BDOrganizedLock.h
    @discussion A more elaborate lock than NSLock.
    @class BDOrganizedLock
    @abstract A more elaborate lock than NSLock, supplying a bit of useful info about what happened while the thread was waiting.
    @discussion When you lock this lock, you tell it your identity and what you plan to do.  If another request is received for the same identity while you are waiting for the lock, then the locking method, lockFor:job:, returns BDOtherWorkRequested.  If the previous holder of the lock (who received BDDoTheWork) did exactly what you plan to do (i.e. their jobs match according to isEqual:), then lockFor:job: returns BDWorkJustDone.  If neither of these cases apply, then BDDoTheWork is returned. <p>
    If a thread is given BDOtherWorkRequested, the expectation is that they will drop this request (so as to process only the later request, in the other thread).  The BDOrganizedLock assumes that the previous work is still valid -- the BDOrganizedLock may give another thread BDWorkJustDone based on the previous thread that was given BDDoTheWork.  A return value of BDOtherWorkRequested can be avoided by giving an anonymous request (identity is nil). <p>
    A request may indicate a nebulous job (job plan is nil) if it does not wish to receive BDWorkJustDone. <p>
    Threads for the same identity are guaranteed to receive the lock in the order the requests arrive in.  Threads for different identities may be shuffled to allow threads to receive BDWorkJustDone.  If all requests are for nil identities and nil jobs, then this is the same as an NSLock, except that requests are guaranteed to be processed in order. <p>
    Suggested use:
    <pre>
    switch([myBDOrganizedLock lockFor:self job:input]) {
    case BDDoTheWork:
        // do a lot of work
    case BDWorkJustDone:
        // use the result of the work
    case BDOtherWorkRequested:
        [myBDOrganizedLock unlock];
    } // fall-throughs are intentional
    </pre>

*/



// return values of lockFor:job:
enum{
    BDDoTheWork = 1,
    BDWorkJustDone = 2,
    BDOtherWorkRequested = 3
};


@interface BDOrganizedLock : NSObject {

    NSLock *internalLock; // don't touch the remaining vars without this!
    NSMutableArray *lockList, *forList, *jobList; // list of waiters, indices match across lists
    NSLock *currentLockHolder; // nil if not locked
    id previousJob; // the work that was just done (nil means nothing was just done)
    volatile int returnValue; // figured out by unlock, given out by lock
    BOOL debugging; // provides information about how lock is being used
}

- (BDOrganizedLock*)init;
/*! @method - (BDOrganizedLock*)init
    @abstract Designated initializer for a BDOrganizedLock.
    @discussion  Creates a new BDOrganizedLock that can be used by multiple threads.
*/

- (int)lockFor:(id)who job:(id)why;
/*! @method - (int)lockFor:(id)who job:(id)why
    @abstract Blocks until the lock can be obtained, or another lock request comes from who.
    @discussion  If this request for the lock should never be eliminated, use nil for who (then BDOtherWorkRequested will never be returned).  If the caller cannot make use of knowledge about what work was done by the previous holder of the lock, nil may be used for why (then BDWorkJustDone will never be returned).  If both are nil, then this is the same as a regular NSLock, except that threads are guaranteed to get the lock in the order they request it in.
    Regardless of the return value, the caller has the lock and must call unlock when done, or else all other users of the lock will hang forever.
*/

- (void)unlock;
/*! @method - (void)unlock
    @abstract Unlocks the lock, allowing other threads to use it.
    @discussion  This passes the lock to the earliest thread which can be given BDOtherWorkRequested.  If there is none, the lock is passed to the earliest thread which can be given BDWorkJustDone.  If there is none of this type either, the lock is passed to the earliest waiting thread, which is given BDDoTheWork.  If there are no waiting threads, then the lock becomes available for the next requestor in the future.
*/

- (void)dealloc;
/*! @method - (void)dealloc
    @abstract Frees the data structures used by the lock.
    @discussion  This method should not be called directly.  Instead, release the lock once everybody is done using it.
*/


@end
