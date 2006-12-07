// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFController.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFController.m,v 1.13 2004/02/10 04:07:40 kc Exp $")


// The following exception can be raised during an OFControllerRequestsTerminateNotification.

static NSString *OFControllerRequestsCancelTerminateException = @"OFControllerRequestsCancelTerminateException";


static OFController *sharedController = nil;

@interface OFController (PrivateAPI)
- (id)_init;
- (void)_makeObserversPerformSelector:(SEL)aSelector abortOnException:(BOOL)shouldAbortOnException;
@end

/*" OFController is used to represent the current state of the application and to receive notifications about changes in that state. "*/
@implementation OFController

+ (id)sharedController;
{
    if (sharedController == nil)
        sharedController = [[self alloc] _init];
    return sharedController;
}

// We currently don't support subclassing OFController and making that subclass the main controller (application delegate, for example) for your process.  We'd have to have some way to make sure the right class got allocated.
- (id)init;
{
    [self release];
    [NSException raise:NSInternalInconsistencyException format:@"Call +sharedController to get an OFController"];
    return nil;
}

- (void)dealloc;
{
    [observers release];
    [super dealloc];
}

- (OFControllerStatus)status;
{
    return status;
}

/*" Subscribes the observer to a set of notifications based on the methods that it implements in the OFControllerObserver informal protocol.  Classes can register for these notifications in their +didLoad methods (and those +didLoad methods probably shouldn't do much else, since defaults aren't yet registered during +didLoad). "*/
- (void)addObserver:(id <OFWeakRetain>)observer;
{
    OBPRECONDITION(observer != nil);
    
    [observers addObject:observer];
    [observer incrementWeakRetainCount];
}


/*" Unsubscribes the observer to a set of notifications based on the methods that it implements in the OFControllerObserver informal protocol. "*/
- (void)removeObserver:(id <OFWeakRetain>)observer;
{
    OBPRECONDITION([observers containsObject:observer]);
    
    [observers removeObject:observer];
    [observer decrementWeakRetainCount];
}


/*" The application should call this once after it is initialized.  In AppKit applications, this should be called from -applicationWillFinishLaunching:. "*/
- (void)didInitialize;
{
    OBPRECONDITION(status == OFControllerNotInitializedStatus);
    
    status = OFControllerInitializedStatus;
    [self _makeObserversPerformSelector:@selector(controllerDidInitialize:) abortOnException:NO];
}

/*" The application should call this once after calling -didInitialize.  In AppKit applications, this should be called from -applicationDidFinishLaunching:. "*/
- (void)startedRunning;
{
    OBPRECONDITION(status == OFControllerInitializedStatus);
    
    status = OFControllerRunningStatus;
    [self _makeObserversPerformSelector:@selector(controllerStartedRunning:) abortOnException:NO];
}

/*" The application should call this when a termination request has been received.  If YES is returned, the termination can proceed (i.e., the caller should call -willTerminate) next. "*/
- (BOOL)requestTermination;
{
    BOOL shouldTerminate = YES;
    
    OBPRECONDITION(status == OFControllerRunningStatus);
    
    status = OFControllerRequestingTerminateStatus;
    NS_DURING {
        [self _makeObserversPerformSelector:@selector(controllerRequestsTerminate:) abortOnException:YES];
    } NS_HANDLER {
        // User requested that the terminate be cancelled
        if ([[localException name] isEqualToString:OFControllerRequestsCancelTerminateException])
            shouldTerminate = NO;
        else
            NSLog(@"Ignoring exception raised during -[OFController requestTermination]: %@", localException);
    } NS_ENDHANDLER;
    
    
    if (shouldTerminate)
        status = OFControllerTerminatingStatus;
    else
        status = OFControllerRunningStatus;
    return shouldTerminate;
}


/*" This method can be called during a -controllerRequestsTerminate: method when an object wishes to cancel the termination (typically in response to a user pressing the "Cancel" button on a Save panel). "*/
- (void)cancelTermination;
{
    OBPRECONDITION(status == OFControllerRequestingTerminateStatus);
    
    [NSException raise:OFControllerRequestsCancelTerminateException format:@"User requested cancel of termination."];
}

/*" The application should call this method when it is going to terminate and there is no chance of cancelling it (i.e., after it has called -requestTermination and a YES has been returned). "*/
- (void)willTerminate;
{
    [self _makeObserversPerformSelector:@selector(controllerWillTerminate:) abortOnException:NO];
}

@end


@implementation OFController (PrivateAPI)

- (id)_init;
{
    if ([super init] == nil)
        return nil;

    status = OFControllerNotInitializedStatus;
    observers = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)_makeObserversPerformSelector:(SEL)aSelector abortOnException:(BOOL)shouldAbortOnException;
{
    NSArray *observersSnapshot;
    unsigned int observerIndex, observerCount;
    NSException *abortException = nil;

    observersSnapshot = [[NSArray alloc] initWithArray:observers];
    observerCount = [observersSnapshot count];
    for (observerIndex = 0; abortException == nil && observerIndex < observerCount; observerIndex++) {
        id anObserver;

        anObserver = [observersSnapshot objectAtIndex:observerIndex];
        if ([anObserver respondsToSelector:aSelector]) {
            // NSLog(@"Calling %s[%@ %s]", OBPointerIsClass(anObserver) ? "+" : "-", OBShortObjectDescription(anObserver), aSelector);
            NS_DURING {
                [anObserver performSelector:aSelector withObject:self];
            } NS_HANDLER {
                if (shouldAbortOnException)
                    abortException = localException;
                else
                    NSLog(@"Ignoring exception raised during %s[%@ %@]: %@", OBPointerIsClass(anObserver) ? "+" : "-", OBShortObjectDescription(anObserver), NSStringFromSelector(aSelector), [localException reason]);
            } NS_ENDHANDLER;
        }
    }
    [observersSnapshot release];
    if (abortException != nil)
        [abortException raise];
}

@end

