// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFController.h,v 1.7 2003/01/15 22:51:49 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSMutableArray, NSNotification;

typedef enum _OFControllerStatus {
    OFControllerNotInitializedStatus,
    OFControllerInitializedStatus,
    OFControllerRunningStatus,
    OFControllerRequestingTerminateStatus,
    OFControllerTerminatingStatus
} OFControllerStatus;

#import <OmniFoundation/OFWeakRetainProtocol.h>

@interface OFController : OFObject
{
    OFControllerStatus status;
    NSMutableArray *observers;
}

+ (id)sharedController;

- (OFControllerStatus)status;

- (void)addObserver:(id <OFWeakRetain>)observer;
- (void)removeObserver:(id <OFWeakRetain>)observer;

- (void)didInitialize;
- (void)startedRunning;
- (BOOL)requestTermination;
- (void)cancelTermination;
- (void)willTerminate;

@end

@interface NSObject (OFControllerObserver)
/*"
The OFControllerObserver informal protocol describes the methods that will be called on an object if it subscribes to OFController notifications by calling -addObserver: on OFController.
*/

- (void)controllerDidInitialize:(OFController *)controller;
/*"
Called when -[OFController didInitialize] is called.  This notification is for setting up a class (reading defaults, etc.).  At this point it shouldn't rely on any other classes (except OFUserDefaults) being set up yet.
"*/

- (void)controllerStartedRunning:(OFController *)controller;
/*"
Called when -[OFController startedRunning] is called.  This notification is for resetting the state of a class to the way it was when the user last left the program:  for instance, popping up a window that was open.
"*/

- (void)controllerRequestsTerminate:(OFController *)controller;
/*"
Called when -[OFController requestTermination] is called.  This notification gives objects an opportunity to save documents, etc., when an application is considering terminating.  If the application does not wish to terminate (maybe the user cancelled the terminate request), it should call -cancelTermination on the OFController.
"*/

- (void)controllerWillTerminate:(OFController *)controller;
/*"
Called when -[OFController willTerminate] is called.  This notification is posted by the OFController just before the application terminates, when there's no chance that the termination will be cancelled).  This may be used to wait for a particular activity (e.g. an asynchronous document save) before the application finally terminates.
"*/

@end
