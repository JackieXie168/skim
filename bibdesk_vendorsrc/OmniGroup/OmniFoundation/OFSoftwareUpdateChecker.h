// Copyright 2001-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFSoftwareUpdateChecker.h,v 1.15 2004/02/10 04:07:41 kc Exp $

#import <OmniFoundation/OFObject.h>
#import <OmniFoundation/FrameworkDefines.h>

@class OFScheduledEvent;
@class NSTask, NSFileHandle, NSData;

extern NSString *OFSoftwareUpdateExceptionName;
extern NSString *OSUPreferencesChangedNotificationName;

@interface OFSoftwareUpdateChecker : OFObject
{
    OFScheduledEvent *automaticUpdateEvent;
    
    id checkTarget;
    SEL checkAction;
    
    struct {
        unsigned int updateInProgress: 2;  // may be 0, 1, or 2
        unsigned int shouldCheckAutomatically: 1;
    } flags;

    struct _softwareUpdatePostponementState *postpone;

    NSTask *fetchSubprocessTask;
    NSFileHandle *fetchSubprocessPipe;
    NSData *subprocessOutput;
    int subprocessTerminationStatus;
}

+ (OFSoftwareUpdateChecker *)sharedUpdateChecker;

+ (NSString *)userVisibleSystemVersion;

- (void)setTarget:(id)anObject;
- (void)setAction:(SEL)aSelector;
- (BOOL)checkSynchronously;

@end


@interface OFSoftwareUpdateChecker (SubclassOpportunity)

// Subclasses can provide implementations of this in order to prevent OFSoftwareUpdateChecker from checking when it shouldn't. -hostAppearsToBeReachable: is called in the main thread; OFSoftwareUpdateChecker's implementation uses the SystemConfiguration framework to check whether the machine has any routes to the outside world. (We can't explicitly check for a route to omnigroup.com or the user's proxy server, because that would require doing a name lookup; we can't do multithreaded name lookups without the stuff in OmniNetworking, so doing a name lookup might hang the app for a while (up to a few minutes) --- bad!)

- (BOOL)hostAppearsToBeReachable:(NSString *)aHostname;

@end

@interface NSObject (OFSoftwareUpdateTarget)
- (void)newVersionAvailable:(NSDictionary *)versionInfo;
/* Callback for when we determine there's a new version to update to -- presumably you want to notify the user of this. Information about the update is provided in versionInfo, which under Omni's system can have the following keys:
               displayName : name of the app
            displayVersion : human-readable version string for the new update
              downloadPage : URL to page with detailed info about the update
            directDownload : URL to downloadable form of the new version
        incompatibleUpdate : if present, indicates the update 
    infoBaseURL (optional) : Base URL (to which version is appended) for fetching short release notes
*/
@end

