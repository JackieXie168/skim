// Copyright 1998-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFController.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import "OFObject-Queue.h"
#import "NSString-OFExtensions.h"
#import "NSThread-OFExtensions.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/OFController.m 68913 2005-10-03 19:36:19Z kc $")


// The following exception can be raised during an OFControllerRequestsTerminateNotification.

@interface OFController (PrivateAPI)
- (id)_init;
- (void)_makeObserversPerformSelector:(SEL)aSelector;
- (NSArray *)_observersSnapshot;
@end

/*" OFController is used to represent the current state of the application and to receive notifications about changes in that state. "*/
@implementation OFController

static OFController *sharedController = nil;

+ (void)initialize;
{
    OBPRECONDITION([NSThread inMainThread]);
    
    OBINITIALIZE;
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSDictionary *infoDictionary = [mainBundle infoDictionary];
    NSString *controllerClassName = [infoDictionary objectForKey:@"OFControllerClass"];
    Class controllerClass;
    if ([NSString isEmptyString:controllerClassName])
        controllerClass = self;
    else {
        controllerClass = NSClassFromString(controllerClassName);
        if (controllerClass == Nil) {
            NSLog(@"OFController: no such class \"%@\"", controllerClassName);
            controllerClass = self;
        }
    }
        
    sharedController = [[controllerClass alloc] _init];
#ifdef DEBUG_neo
    NSLog(@"sharedController=%@", sharedController);
#endif
}
    
+ (id)sharedController;
{
    return sharedController;
}

// We currently don't support subclassing OFController and making that subclass the main controller (application delegate, for example) for your process.  We'd have to have some way to make sure the right class got allocated.
- (id)init;
{
    OBPRECONDITION([NSThread inMainThread]);

    OBRejectUnusedImplementation(self, _cmd);
}

- (void)dealloc;
{
    OBPRECONDITION([NSThread inMainThread]);

    [observers release];
    [postponingObservers release];
    
    [super dealloc];
}

- (OFControllerStatus)status;
{
    OBPRECONDITION([NSThread inMainThread]);

    return status;
}

/*" Subscribes the observer to a set of notifications based on the methods that it implements in the OFControllerObserver informal protocol.  Classes can register for these notifications in their +didLoad methods (and those +didLoad methods probably shouldn't do much else, since defaults aren't yet registered during +didLoad). "*/
- (void)addObserver:(id <OFWeakRetain>)observer;
{
    OBPRECONDITION(observer != nil);
    
    [observerLock lock];
    
    [observers addObject:observer];
    [observer incrementWeakRetainCount];
    
    [observerLock unlock];
}


/*" Unsubscribes the observer to a set of notifications based on the methods that it implements in the OFControllerObserver informal protocol. "*/
- (void)removeObserver:(id <OFWeakRetain>)observer;
{
    [observerLock lock];
    
    [observers removeObject:observer];
    [observer decrementWeakRetainCount];
    
    [observerLock unlock];
}


/*" The application should call this once after it is initialized.  In AppKit applications, this should be called from -applicationWillFinishLaunching:. "*/
- (void)didInitialize;
{
    OBPRECONDITION([NSThread inMainThread]);
    OBPRECONDITION(status == OFControllerNotInitializedStatus);
    
    status = OFControllerInitializedStatus;
    [self _makeObserversPerformSelector:@selector(controllerDidInitialize:)];
}

/*" The application should call this once after calling -didInitialize.  In AppKit applications, this should be called from -applicationDidFinishLaunching:. "*/
- (void)startedRunning;
{
    OBPRECONDITION([NSThread inMainThread]);
    OBPRECONDITION(status == OFControllerInitializedStatus);
    
    status = OFControllerRunningStatus;
    [self _makeObserversPerformSelector:@selector(controllerStartedRunning:)];
}
    
/*" The application should call this when a termination request has been received.  If YES is returned, the termination can proceed (i.e., the caller should call -willTerminate) next. "*/
- (OFControllerTerminateReply)requestTermination;
{
    OBPRECONDITION([NSThread inMainThread]);
    OBPRECONDITION(status == OFControllerRunningStatus);
    
    status = OFControllerRequestingTerminateStatus;

    NSArray *observersSnapshot = [self _observersSnapshot];    
    unsigned int observerCount = [observersSnapshot count];
    unsigned int observerIndex;
    
    for (observerIndex = 0; observerIndex < observerCount; observerIndex++) {
        id anObserver = [observersSnapshot objectAtIndex:observerIndex];
        if ([anObserver respondsToSelector:@selector(controllerRequestsTerminate:)]) {
            NS_DURING {
                [anObserver controllerRequestsTerminate:self];
            } NS_HANDLER {
                NSLog(@"Ignoring exception raised during %s[%@ controllerRequestsTerminate:]: %@", OBPointerIsClass(anObserver) ? "+" : "-", OBShortObjectDescription(anObserver), [localException reason]);
            } NS_ENDHANDLER;
        }
        
        // Break if the termination was cancelled
        if (status == OFControllerRunningStatus)
            break;
    }

    if (status != OFControllerRunningStatus && [postponingObservers count] > 0)
        status = OFControllerPostponingTerminateStatus;

    switch (status) {
        case OFControllerRunningStatus:
            return OFControllerTerminateCancel;
        case OFControllerRequestingTerminateStatus:
            status = OFControllerTerminatingStatus;
            return OFControllerTerminateNow;
        case OFControllerPostponingTerminateStatus:
            return OFControllerTerminateLater;
        default:
            OBASSERT_NOT_REACHED("Can't return from OFControllerRunningStatus to an earlier state");
            return OFControllerTerminateNow;
    }
}

/*" This method can be called during a -controllerRequestsTerminate: method when an object wishes to cancel the termination (typically in response to a user pressing the "Cancel" button on a Save panel). "*/
- (void)cancelTermination;
{
    OBPRECONDITION([NSThread inMainThread]);
    
    switch (status) {
        case OFControllerRequestingTerminateStatus:
            status = OFControllerRunningStatus;
            break;
        case OFControllerPostponingTerminateStatus:
            [self gotPostponedTerminateResult:NO];
            status = OFControllerRunningStatus;
            break;
        default:
            break;
    }
}

- (void)postponeTermination:(id)observer;
{
    OBPRECONDITION([NSThread inMainThread]);

    [postponingObservers addObject:observer];
}

- (void)continuePostponedTermination:(id)observer;
{
    OBPRECONDITION([NSThread inMainThread]);
    OBPRECONDITION([postponingObservers containsObject:observer]);
    
    [postponingObservers removeObject:observer];
    if ([postponingObservers count] == 0) {
        [self gotPostponedTerminateResult:(status != OFControllerRunningStatus)];
    } else if ((status == OFControllerRequestingTerminateStatus || status == OFControllerPostponingTerminateStatus || status == OFControllerTerminatingStatus)) {
        [self _makeObserversPerformSelector:@selector(controllerRequestsTerminate:)];
    }
}

/*" The application should call this method when it is going to terminate and there is no chance of cancelling it (i.e., after it has called -requestTermination and a YES has been returned). "*/
- (void)willTerminate;
{
    OBPRECONDITION([NSThread inMainThread]);

    [self _makeObserversPerformSelector:@selector(controllerWillTerminate:)];
}

- (void)gotPostponedTerminateResult:(BOOL)isReadyToTerminate;
{
    OBRequestConcreteImplementation(self, _cmd);
}

@end


@implementation OFController (PrivateAPI)

- (id)_init;
{
    OBPRECONDITION([NSThread inMainThread]);

    if ([super init] == nil)
        return nil;

    observerLock = [[NSLock alloc] init];
    status = OFControllerNotInitializedStatus;
    observers = [[NSMutableArray alloc] init];
    postponingObservers = [[NSMutableSet alloc] init];
    
    return self;
}

- (void)_makeObserversPerformSelector:(SEL)aSelector;
{
    OBPRECONDITION([NSThread inMainThread]);
    
    NSArray *observersSnapshot = [self _observersSnapshot];
    unsigned int observerCount = [observersSnapshot count];
    unsigned int observerIndex;
    
    for (observerIndex = 0; observerIndex < observerCount; observerIndex++) {
        id anObserver = [observersSnapshot objectAtIndex:observerIndex];
        if ([anObserver respondsToSelector:aSelector]) {
            // NSLog(@"Calling %s[%@ %s]", OBPointerIsClass(anObserver) ? "+" : "-", OBShortObjectDescription(anObserver), aSelector);
            NS_DURING {
                [anObserver performSelector:aSelector withObject:self];
            } NS_HANDLER {
                NSLog(@"Ignoring exception raised during %s[%@ %@]: %@", OBPointerIsClass(anObserver) ? "+" : "-", OBShortObjectDescription(anObserver), NSStringFromSelector(aSelector), [localException reason]);
            } NS_ENDHANDLER;
        }
    }
}

- (NSArray *)_observersSnapshot;
{
    OBPRECONDITION([NSThread inMainThread]);

    [observerLock lock];
    NSMutableArray *observersSnapshot = [[NSMutableArray alloc] initWithArray:observers];
    [observerLock unlock];

    return [observersSnapshot autorelease];
}

@end

