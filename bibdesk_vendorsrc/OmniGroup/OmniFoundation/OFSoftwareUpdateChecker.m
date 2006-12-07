// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OFSoftwareUpdateChecker.h"

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <OmniBase/OmniBase.h>

#import "OFInvocation.h"
#import "OFScheduledEvent.h"
#import "OFScheduler.h"
#import "OFSoftwareUpdateCheckTool.h"
#import "NSArray-OFExtensions.h"
#import "NSObject-OFExtensions.h"
#import "NSString-OFExtensions.h"
#import "NSUserDefaults-OFExtensions.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFSoftwareUpdateChecker.m,v 1.31 2003/05/02 00:35:43 wjs Exp $");

// Strings of interest
static NSString *OSUCurrentVersionsURL = @"http://www.omnigroup.com/CurrentSoftwareVersions2.plist";
static NSString *OSUBundleTrackInfoKey = @"OFSoftwareUpdateTrack";
static NSString *OSUBundleCheckAtLaunchKey = @"OFSoftwareUpdateAtLaunch";

// Preferences keys
static NSString *OSUCheckEnabled = @"AutomaticSoftwareUpdateCheckEnabled";
static NSString *OSUCheckFrequencyKey = @"OSUCheckInterval";
static NSString *OSUNextCheckKey = @"OSUNextScheduledCheck";
static NSString *OSUCurrentVersionsURLKey = @"OSUCurrentVersionsURL";

static NSString *OSUVisibleTracksKey = @"OSUVisibleTracks";
static NSString *OSULastLaunchKey = @"OSUNewestVersionLaunched";

#define MINIMUM_CHECK_INTERVAL (60.0 * 15.0) // Cannot automatically check more frequently than every fifteen minutes

#define ImpossibleTerminationStatus 0xEFFACED

#define SCKey_GlobalIPv4State CFSTR("State:/Network/Global/IPv4")
#define SCKey_GlobalIPv4State_hasUsefulRoute CFSTR("Router")

NSString *OFSoftwareUpdateExceptionName = @"OFSoftwareUpdateException";
NSString *OSUPreferencesChangedNotificationName = @"OSUPreferencesChangedNotification";

@interface OFSoftwareUpdateChecker (Private)

- (BOOL)_shouldCheckAtLaunch;
- (void)_scheduleNextCheck;
- (void)_initiateCheck;
- (void)_beginLoadingURL:(NSURL *)aURL;
- (void)_discardSubprocess;
- (void)_fetchSubprocessNote:(NSNotification *)note;
- (NSURL *)_currentVersions;
- (BOOL)_interpretSoftwareStatus:(NSDictionary *)status;
- (BOOL)hostAppearsToBeReachable:(NSString *)hostname;
- (BOOL)_postponeCheckForURL:(NSURL *)aURL;

- (void)_scDynamicStoreDisconnect;
- (BOOL)_scDynamicStoreConnect;

static NSArray *OSUWinnowTracks(NSSet *visibleTracks, NSArray *downloadables);
static NSArray *OSUWinnowVersions(NSDictionary *appInfo, NSArray *downloadables);
static NSArray *OSUWinnowCompatibleLicenses(NSDictionary *appInfo, NSArray *downloadables);
static NSArray *OSUWinnowCompatibleOperatingSystems(NSArray *downloadables);
static NSArray *extractOSUVersionFromBundle(NSDictionary *bundleInfo);
static NSString *formatOSUVersion(NSArray *osuVersion);
static NSArray *parseOSUVersionString(NSString *str);
static NSSet *computeVisibleTracks(NSDictionary *trackInfo);
static NSComparisonResult compareOSUVersions(NSArray *software, NSArray *spec);
static void networkInterfaceWatcherCallback(SCDynamicStoreRef store, CFArrayRef keys, void *info);

// This is kept separate from our ivars so that people who use this class don't need to pull in all the SystemConfiguration framework headers.
struct _softwareUpdatePostponementState {
    SCDynamicStoreRef store; // our connection to the system configuration daemon
    CFRunLoopSourceRef loopSource; // our run loop's reference to 'store'

    SCDynamicStoreContext callbackContext;
};

@end

static inline NSDictionary *dataToPlist(NSData *input)
{
    CFDataRef cfIn = (CFDataRef)input;
    CFPropertyListRef output;
    CFStringRef errorString;

    errorString = NULL;
    
    // Contrary to the name, this call handles the text-style plist as well.
    output = CFPropertyListCreateFromXMLData(kCFAllocatorDefault, cfIn, kCFPropertyListImmutable, &errorString);

    [(id)output autorelease];
    if (errorString)
        CFRelease(errorString);
    
    return (NSDictionary *)output;
}

@implementation OFSoftwareUpdateChecker

static inline void cancelScheduledEvent(OFSoftwareUpdateChecker *self)
{
    if (self->automaticUpdateEvent != nil) {
        [[self retain] autorelease];
        [[OFScheduler mainScheduler] abortEvent:self->automaticUpdateEvent];
    	[self->automaticUpdateEvent release];
        self->automaticUpdateEvent = nil;
    }
}

static OFSoftwareUpdateChecker *sharedChecker = nil;

+ (OFSoftwareUpdateChecker *)sharedUpdateChecker;
{
    if (sharedChecker == nil) {
        sharedChecker = [[self alloc] init];
        [sharedChecker setAction:@selector(newVersionAvailable:)];
    }
    return sharedChecker;
}

+ (NSString *)userVisibleSystemVersion;
{
    static NSString *userVisibleSystemVersion = nil;
    
    if (userVisibleSystemVersion == nil) {
        NSDictionary *versionDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];

        userVisibleSystemVersion = [versionDictionary objectForKey:@"ProductUserVisibleVersion"];
        if (userVisibleSystemVersion == nil)
            userVisibleSystemVersion = [versionDictionary objectForKey:@"ProductVersion"];
        [userVisibleSystemVersion retain];
    }
    return userVisibleSystemVersion;
}

- (void)setTarget:(id)anObject;
{
    checkTarget = [anObject retain];

    flags.shouldCheckAutomatically = [[NSUserDefaults standardUserDefaults] boolForKey:OSUCheckEnabled];
    flags.updateInProgress = 0; // not currently fetching anything
    automaticUpdateEvent = nil;

    if ([self _shouldCheckAtLaunch])
        [self _initiateCheck];
    else
        [self _scheduleNextCheck];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(softwareUpdatePreferencesChanged:) name:OSUPreferencesChangedNotificationName object:nil];
}

- (void)setAction:(SEL)aSelector;
{
    checkAction = aSelector;
}

- (void)dealloc;
{
    OBASSERT(automaticUpdateEvent == nil);  // if it were non-nil, it would be retaining us and we wouldn't be being deallocated
    [self _scDynamicStoreDisconnect]; 
    [checkTarget release];
    checkTarget = nil;
    [super dealloc];
}


// API

- (BOOL)checkSynchronously;
{
    NSURL *currentVersions;
    NSData *fetchedData;
    BOOL didSomething;

    if (checkTarget == nil || checkAction == NULL)
        return NO;
    
    currentVersions = [self _currentVersions];
    flags.updateInProgress++;
    NS_DURING {
        cancelScheduledEvent(self);
        fetchedData = [currentVersions resourceDataUsingCache:NO];
        didSomething = [self _interpretSoftwareStatus:dataToPlist(fetchedData)];
        flags.updateInProgress--;
        [self _scheduleNextCheck];
    } NS_HANDLER {
        flags.updateInProgress--;
        [self _scheduleNextCheck];
        [localException raise];
        didSomething = NO;
    } NS_ENDHANDLER;
    
    return didSomething;
}

@end

@implementation OFSoftwareUpdateChecker (NotificationsDelegatesDatasources)

- (void)softwareUpdatePreferencesChanged:(NSNotification *)aNotification;
{
    flags.shouldCheckAutomatically = [[NSUserDefaults standardUserDefaults] boolForKey:OSUCheckEnabled];
    [self _scheduleNextCheck];
}

#if 0
- (void)URLResourceDidFinishLoading:(NSURL *)sender;
{
    NSData *resourceData;
    
    flags.updateInProgress--;
    
    resourceData = [sender resourceDataUsingCache:YES];
    
    [self _interpretSoftwareStatus:dataToPlist(resourceData)];
    // NB (TODO): _interpretSoftwareStatus can raise an exception, in which case we won't schedule another check, and will stop checking for updates until the next time the app is launched. Not sure if this is the best behavior or not.
    
    [self _scheduleNextCheck];
}

- (void)URLResourceDidCancelLoading:(NSURL *)sender;
{
    [self URL:sender resourceDidFailLoadingWithReason:NSLocalizedStringFromTableInBundle(@"Canceled", @"OmniFoundation", [OFSoftwareUpdateChecker bundle], reason for failure to check for update if user has canceled the request)];
}

- (void)URL:(NSURL *)sender resourceDidFailLoadingWithReason:(NSString *)reason;
{
    NSLog(@"Background software update failed: %@", reason);
    
    flags.updateInProgress--;
    [self _interpretSoftwareStatus:nil];
    // NB (TODO): _interpretSoftwareStatus can raise an exception, in which case we won't schedule another check, and will stop checking for updates until the next time the app is launched. Not sure if this is the best behavior or not.
    
    [self _scheduleNextCheck];
}
#endif

@end

@implementation OFSoftwareUpdateChecker (Private)

- (BOOL)_shouldCheckAtLaunch;
{
    id checkAtLaunch;
    NSString *lastLaunch;
    NSArray *thisLaunchVersion;
    NSUserDefaults *defaults;
    NSDictionary *myInfo;

#ifdef DEBUG_rick // or anyone else debugging OSU code
    return YES;
#endif

    if (!flags.shouldCheckAutomatically)
        return NO;

    myInfo = [[NSBundle mainBundle] infoDictionary];
    checkAtLaunch = [myInfo objectForKey:OSUBundleCheckAtLaunchKey];
    if (checkAtLaunch == nil || ![checkAtLaunch boolValue])
        return NO;

    thisLaunchVersion = extractOSUVersionFromBundle(myInfo);
    if (thisLaunchVersion == nil) {
#ifdef DEBUG
        NSLog(@"Unable to compute version number of this app");
#endif
        return NO;
    }


    defaults = [NSUserDefaults standardUserDefaults];

    lastLaunch = [defaults stringForKey:OSULastLaunchKey];
    if (lastLaunch) {
        NSArray *lastLaunchVersion;

        lastLaunchVersion = parseOSUVersionString(lastLaunch);
        if (compareOSUVersions(thisLaunchVersion, lastLaunchVersion) != NSOrderedDescending)
            return NO; // This version is the same or older than the version we ran at last launch
    }

    [defaults setObject:formatOSUVersion(thisLaunchVersion) forKey:OSULastLaunchKey];
    [defaults autoSynchronize];

    return YES;
}

- (void)_scheduleNextCheck;
{
    NSTimeInterval checkInterval;
    NSDate *nextCheckDate, *now;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Make sure we haven't been disabled
    if (![defaults boolForKey:OSUCheckEnabled])
        flags.shouldCheckAutomatically = 0;

    if (!flags.shouldCheckAutomatically || flags.updateInProgress) {
        cancelScheduledEvent(self);
        return;
    }
    
    // Determine when we should make the next check
    checkInterval = [defaults floatForKey:OSUCheckFrequencyKey] * 60.0 * 60.0;
    checkInterval = MAX(checkInterval, MINIMUM_CHECK_INTERVAL);
    // NSLog(@"Next OmniSoftwareUpdate check scheduled for %f seconds from now.", checkInterval);
    
    now = [NSDate date];
    nextCheckDate = [defaults objectForKey:OSUNextCheckKey];
    if (nextCheckDate == nil || ![nextCheckDate isKindOfClass:[NSDate class]] ||
        ([nextCheckDate timeIntervalSinceDate:now] > checkInterval)) {
        nextCheckDate = [[NSDate alloc] initWithTimeInterval:checkInterval sinceDate:now];
        [nextCheckDate autorelease];
        [defaults setObject:nextCheckDate forKey:OSUNextCheckKey];
        [defaults autoSynchronize];
    }
    
    if (automaticUpdateEvent) {
        if(fabs([[automaticUpdateEvent date] timeIntervalSinceDate:nextCheckDate]) < 1.0) {
            // We already have a scheduled check at the time we would be scheduling one, so we don't need to do anything.
            return;
        } else {
            // We have a scheduled check at a different time. Cancel the existing event and add a new one.
            cancelScheduledEvent(self);
        }
    }
    OBASSERT(automaticUpdateEvent == nil);
    automaticUpdateEvent = [[OFScheduledEvent alloc] initWithInvocation:[[[OFInvocation alloc] initForObject:self selector:@selector(_initiateCheck)] autorelease] atDate:nextCheckDate];
    [[OFScheduler mainScheduler] scheduleEvent:automaticUpdateEvent];
}

- (void)_initiateCheck;
{
    NSURL *checkURL;
    
    if (flags.updateInProgress)
        return;

    checkURL = [self _currentVersions];
    
    flags.updateInProgress++;

    if ([self _postponeCheckForURL:checkURL]) {
        flags.updateInProgress--;  // um, never mind.
        return;
    }

    [self _beginLoadingURL:checkURL];
}

- (void)_beginLoadingURL:(NSURL *)aURL;
{
    NSPipe *stdoutPipe;
    NSTask *checker;
    NSNotificationCenter *center;
    NSBundle *myBundle;
    NSString *helperPath;

    [self _discardSubprocess];

    myBundle = [OFSoftwareUpdateChecker bundle];
#if 0
    // This doesn't work?
    helperPath = [myBundle pathForAuxiliaryExecutable:@"getosuinfo"];
#else
    helperPath = [myBundle pathForResource:@"getosuinfo" ofType:@""];
#endif
    if (helperPath == nil) {
#ifdef DEBUG
        NSLog(@"Missing resource getosuinfo; can't check for updates");
#endif
        return;
    }

    stdoutPipe = [NSPipe pipe];
    checker = [[NSTask alloc] init];
    [checker setStandardOutput:stdoutPipe];
#ifndef DEBUG
    // Capture stderr from the getosuinfo tool so it doesn't log this error to the user's console:
    //
    //     2002-10-22 12:46:53.861 getosuinfo[2267] CFLog (0): Usage of CFHTTPReadStreamSetRedirectsAutomatically is deprecated; call SetProperty(kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue/False) instead
    //
    // Note that we're not actually calling that API, that message is logged when we call CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault, url, &data, &properties, NULL, &errorCode).
    [checker setStandardError:[NSFileHandle fileHandleWithNullDevice]];
 
#endif
    [checker setLaunchPath:helperPath];
    [checker setArguments:[NSArray arrayWithObjects:[aURL host], [aURL absoluteString], nil]];
    fetchSubprocessTask = checker;
    fetchSubprocessPipe = [[stdoutPipe fileHandleForReading] retain];

    center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(_fetchSubprocessNote:) name:NSFileHandleReadToEndOfFileCompletionNotification object:fetchSubprocessPipe];
    [center addObserver:self selector:@selector(_fetchSubprocessNote:) name:NSTaskDidTerminateNotification object:checker];
    
    [fetchSubprocessPipe readToEndOfFileInBackgroundAndNotify];
    [checker launch];
}

- (void)_discardSubprocess;
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:nil];
    [center removeObserver:self name:NSTaskDidTerminateNotification object:nil];

    if (fetchSubprocessTask) {
        if ([fetchSubprocessTask isRunning])
            [fetchSubprocessTask terminate];
        [fetchSubprocessTask release];
        fetchSubprocessTask = nil;
    }

    if (fetchSubprocessPipe) {
        [fetchSubprocessPipe closeFile];
        [fetchSubprocessPipe release];
        fetchSubprocessPipe = nil;
    }

    [subprocessOutput release];
    subprocessOutput = nil;
    subprocessTerminationStatus = ImpossibleTerminationStatus;
}

- (void)_fetchSubprocessNote:(NSNotification *)note;
{
    BOOL stopUpdating = NO;
    NSDictionary *status;

    if ([[note name] isEqual:NSFileHandleReadToEndOfFileCompletionNotification] &&
        [note object] == fetchSubprocessPipe) {
        [subprocessOutput autorelease];
        subprocessOutput = [[[note userInfo] objectForKey:NSFileHandleNotificationDataItem] retain];
    }

    if ([[note name] isEqual:NSTaskDidTerminateNotification] &&
        [note object] == fetchSubprocessTask) {
        subprocessTerminationStatus = [fetchSubprocessTask terminationStatus];
    }
    
    if (subprocessOutput == nil || subprocessTerminationStatus == ImpossibleTerminationStatus)
        return;
    
    // The fetch subprocess has completed.
    flags.updateInProgress--;
    
    if (subprocessTerminationStatus == 0) {
        NSDictionary *results = dataToPlist(subprocessOutput);
        
        if (results == nil)
            status = nil;
        else
            status = [results objectForKey:@"plist"];
        
        if (results != nil && status == nil && [results objectForKey:@"error"])
            NSLog(@"Background software update failed: %@", [results objectForKey:@"error"]);
    } else {
        // TODO: We could report the error to _interpretSoftwareStatus, but the extra detail is unlikely to be helpful: it all boils down to "I couldn't reach www.omnigroup.com for some reason". So, we'll leave it be.
        NSLog(@"Background software update failed [%d]", subprocessTerminationStatus);

        status = nil;
        
        if (subprocessTerminationStatus == OFOSUSCT_LocalNetworkFailure &&
            (!postpone))
            [self _scDynamicStoreConnect];
        else if (subprocessTerminationStatus == OFOSUSCT_MiscFailure)
            stopUpdating = YES;
    }

    NS_DURING {
        [self _interpretSoftwareStatus:status];
    } NS_HANDLER {
        // TODO: Shouldn't we try to report this to the UI somehow? This is a background check, though, so we don't want to bother the user.
        NSLog(@"%@: %@", NSStringFromClass(self->isa), [localException reason]);
    } NS_ENDHANDLER;
    
    if (!stopUpdating)
        [self _scheduleNextCheck];
}

- (NSURL *)_currentVersions;
{
    NSString *currentVersionsURL;
    NSString *OSUVersion;
    NSURL *url;
    
    currentVersionsURL = [[NSUserDefaults standardUserDefaults] stringForKey:OSUCurrentVersionsURLKey];
    if ([NSString isEmptyString:currentVersionsURL])
        currentVersionsURL = OSUCurrentVersionsURL;
    
    OSUVersion = [[[[NSBundle bundleForClass:isa] infoDictionary] objectForKey:@"CFBundleVersion"] description];
    if (OSUVersion && [OSUVersion length])
        currentVersionsURL = [NSString stringWithStrings:currentVersionsURL, @"?", OSUVersion, nil];
    // The reason for appending OSUVersion is to allow server-side hacks to compensate for bugs or changes in this class after it's in the field. Hopefully no-one will ever look at it, of course, but function favors the prepared mind.
    
    url = [NSURL URLWithString:currentVersionsURL];
    
    return url;
}

static NSComparisonResult compareVersionDictionaries(id leftDictionary, id rightDictionary, void *context)
{
    NSArray *leftVersion, *rightVersion;

    leftVersion = parseOSUVersionString([leftDictionary objectForKey:@"version"]);
    rightVersion = parseOSUVersionString([rightDictionary objectForKey:@"version"]);
    return compareOSUVersions(leftVersion, rightVersion);
}

- (BOOL)_interpretSoftwareStatus:(NSDictionary *)status;
{
    NSBundle *thisApp = [NSBundle mainBundle];
    NSArray *latestVersions, *compatibleVersions;
    NSSet *visibleTracks;
    NSMutableDictionary *latestVersion = [NSMutableDictionary dictionary];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:OSUNextCheckKey];
    // Removing the nextCheckKey will cause _scheduleNextCheck to schedule a check in the future
    
    if (status == nil) {
        [NSException raise:OFSoftwareUpdateExceptionName format:NSLocalizedStringFromTableInBundle(@"Could not contact %@. Your Internet connection might not be active, or there might be a problem somewhere along the network.", @"OmniFoundation", [OFSoftwareUpdateChecker bundle], error text generated when software update is unable to retrieve the list of current software versions), [[self _currentVersions] host]];
        return NO; // happy compiler! happy compiler!
    }

    visibleTracks = computeVisibleTracks([status objectForKey:@"tracks"]);
    
    latestVersions = [status objectForKey:[thisApp bundleIdentifier]];
    latestVersions = OSUWinnowTracks(visibleTracks, latestVersions);
    latestVersions = OSUWinnowVersions([thisApp infoDictionary], latestVersions);
    
    if (latestVersions == nil || [latestVersions count] == 0)
        return NO;   // nothing to do.

    compatibleVersions = OSUWinnowCompatibleOperatingSystems(latestVersions);
    if ([compatibleVersions count] == 0)
        [latestVersion setObject:@"YES" forKey:@"incompatibleOperatingSystem"];
    else
        latestVersions = compatibleVersions;
    
    compatibleVersions = OSUWinnowCompatibleLicenses([thisApp infoDictionary], latestVersions);
    if ([compatibleVersions count] == 0)
        [latestVersion setObject:@"YES" forKey:@"incompatibleLicense"];
    else
        latestVersions = compatibleVersions;

    latestVersions = [latestVersions sortedArrayUsingFunction:compareVersionDictionaries context:NULL];
    [latestVersion addEntriesFromDictionary:[latestVersions lastObject]];
    [checkTarget performSelector:checkAction withObject:latestVersion];
    return YES;
}

// This is split out so that it can be overridden by more sophisticated subclasses/categories.
- (BOOL)hostAppearsToBeReachable:(NSString *)hostname;
{
    const char *asciiHostname;
    CFDictionaryRef ipv4state;

    if ([hostname isEqualToString:@"localhost"])
        return YES;  // ummm, I guess so

    asciiHostname = [hostname cString];
    if (!asciiHostname) {
        // Can't represent the hostname as a C string --- it's probably bogus. (Might fail when/if unicode DNS ever happens, but we'd need to fix this code to handle that, and it won't affect us unless Omni gets a new domain anyway...
        return NO;
    }


    // Okay, talk to configd and see if this machine has any network interfaces at all.
    if (postpone == nil && ![self _scDynamicStoreConnect]) {
        // Um, something is wrong --- we can't talk to configd! Bail out.
        return NO;
    }

    // TODO: This will fail if the machine has non-IPv4 routes to the outside world. Right now that's not a problem, but if Apple starts supporting IPv6 or whatever in a useful way, we should look at this code again.
    
    ipv4state = SCDynamicStoreCopyValue(postpone->store, SCKey_GlobalIPv4State);
    if (!ipv4state) {
        // Dude, we don't have any knowledge of IPv4 at all!
        // (This normally indicates a machine with no network interfaces, eg. a laptop, or a desktop machine that is not plugged in / dialed up / talking to an AirtPort / whatever)
        return NO;
    } else {
        BOOL reachable;
        // TODO: Check whether ipv4state is, in fact, a CFDictionary?
        if (!CFDictionaryContainsKey(ipv4state, SCKey_GlobalIPv4State_hasUsefulRoute))
            reachable = NO;  // We have some ipv4 state, but it doesn't look useful
        else
            reachable = YES;  // Might as well give it a try.
        
        // TODO: Should we furthermore try to call SCNetworkCheckReachabilityByName() if we have a router? (Probably not: even if everything is working, it might take a while for that call to return, and we don't want to hang the app for the duration. The fetcher tool can call that.)
        
        CFRelease(ipv4state);
        return reachable;
    }
    
    // NOTREACHED
}

// Returns YES if we should postpone checking because our check URL requires network access but the system isn't connected to the network. This routine is also responsible for setting up or tearing down the connection to the system config daemon which we use to initiate a check when the machine reconnects to the net.
- (BOOL)_postponeCheckForURL:(NSURL *)aURL;
{
    BOOL canCheckImmediately;
    NSString *urlScheme;

    urlScheme = [aURL scheme];
    if ([urlScheme isEqual:@"file"]) {
        canCheckImmediately = YES;  // filesystem is always available. we hope.
    } else {
        NSString *urlHost = [aURL host];

        if (urlHost == nil) {   // not sure what's up, but might as well give it a try
            canCheckImmediately = YES;
        } else {
            canCheckImmediately = [self hostAppearsToBeReachable:urlHost];
        }
    }

    if (canCheckImmediately && (postpone != nil)) {
        // Tear down the network-watching stuff.
#ifdef DEBUG
        NSLog(@"%@: no longer watching for network changes", NSStringFromClass(self->isa));
#endif
        [self _scDynamicStoreDisconnect];
    }

    // Set up the network-watching stuff if necessary.
    if (!canCheckImmediately) {
        BOOL connected;
        
        if (postpone == nil)
            connected = [self _scDynamicStoreConnect];
        else
            connected = YES;

        if (connected) {
#ifdef DEBUG
            NSLog(@"%@: no network. will watch for changes.", NSStringFromClass(self->isa));
#endif
        } else {
            NSLog(@"Cannot connect to configd. Will not automatically perform software update.");
        }
    }

    return (!canCheckImmediately);
}

static void networkInterfaceWatcherCallback(SCDynamicStoreRef store, CFArrayRef keys, void *info)
{
    OFSoftwareUpdateChecker *self = info;

    NSLog(@"%@: Network configuration has changed", NSStringFromClass(self->isa));

    [self _initiateCheck];
}

- (void)_scDynamicStoreDisconnect;
{
    if (postpone != nil) {

        if (postpone->loopSource) {
            CFRunLoopSourceInvalidate(postpone->loopSource);
            CFRelease(postpone->loopSource);
            postpone->loopSource = NULL;
        }

        CFRelease(postpone->store);
        postpone->store = NULL;

        free(postpone);
        postpone = NULL;

    }
}

- (BOOL)_scDynamicStoreConnect;
{
    SCDynamicStoreRef store;
    NSArray *watchedRegexps;

    // SystemConfig keys to watch. These keys reflect the highest layer of the network stack, after link activity is detected, DHCP or whatever has completed, etc.
    watchedRegexps = [NSArray arrayWithObject:@"State:/Network/Global/.*"];

    postpone = malloc(sizeof(*postpone));
    if (!postpone)
        goto error0;

    postpone->loopSource = NULL;

    // We don't do any retain/release stuff here since we will always deallocate the dynamic store connection before we deallocate ourselves.
    postpone->callbackContext.version = 0;
    postpone->callbackContext.info = self;
    postpone->callbackContext.retain = NULL;
    postpone->callbackContext.release = NULL;
    postpone->callbackContext.copyDescription = NULL;

    store = SCDynamicStoreCreate(NULL, CFSTR("OFSoftwareUpdateChecker"), networkInterfaceWatcherCallback, &(postpone->callbackContext));
    if (!store) goto error1;

    if (!SCDynamicStoreSetNotificationKeys(store, NULL, (CFArrayRef)watchedRegexps))
        goto error2;
    
    if(!(postpone->loopSource = SCDynamicStoreCreateRunLoopSource(NULL, store, 0)))
        goto error2;

    postpone->store = store;

    CFRunLoopAddSource(CFRunLoopGetCurrent(), postpone->loopSource, kCFRunLoopCommonModes);

    return YES;

error2:
        CFRelease(store);
error1:
    {
        int sysconfigError = SCError();
        
        free(postpone);

        NSLog(@"%@: SystemConfiguration error: %s (%d)", NSStringFromClass(self->isa), SCErrorString(sysconfigError), sysconfigError);
    }
error0:
        return NO;
}


// These functions will eventually need to be moved into a separate file to be shared with the standalone software update app

static NSArray *OSUWinnowCompatibleLicenses(NSDictionary *appInfo, NSArray *downloadables)
{
    id appVersion;
    NSMutableArray *winnowed;
    unsigned int downloadableIndex, downloadableCount;
    
    if (downloadables == nil || [downloadables count] == 0)
        return downloadables;
    downloadableCount = [downloadables count];

    appVersion = extractOSUVersionFromBundle(appInfo);
    if (appVersion == nil) {
        // Unparseable application version.  Pass all entries in downloadables, to encourage the user to upgrade to something parseable.
        return downloadables;
    }

    winnowed = [NSMutableArray arrayWithCapacity:downloadableCount];
    for (downloadableIndex = 0; downloadableIndex < downloadableCount; downloadableIndex++) {
        NSDictionary *downloadable = [downloadables objectAtIndex:downloadableIndex];
        id compatibleVersion;
        
        compatibleVersion = parseOSUVersionString([downloadable objectForKey:@"earliestCompatibleLicense"]);
        if (compatibleVersion == nil || compareOSUVersions(appVersion, compatibleVersion) != NSOrderedAscending)
            [winnowed addObject:downloadable];
    }
    return winnowed;
}

static NSArray *OSUWinnowCompatibleOperatingSystems(NSArray *downloadables)
{
    id systemVersion;
    NSMutableArray *winnowed;
    unsigned int downloadableIndex, downloadableCount;
    
    if (downloadables == nil || [downloadables count] == 0)
        return downloadables;
    downloadableCount = [downloadables count];

    systemVersion = parseOSUVersionString([[OFSoftwareUpdateChecker userVisibleSystemVersion] stringByAppendingString:@";0"]);
    if (systemVersion == nil)
        return downloadables;

    winnowed = [NSMutableArray arrayWithCapacity:downloadableCount];
    for (downloadableIndex = 0; downloadableIndex < downloadableCount; downloadableIndex++) {
        NSDictionary *downloadable = [downloadables objectAtIndex:downloadableIndex];
        id neededOSVersion;
        
        neededOSVersion = parseOSUVersionString([[downloadable objectForKey:@"requiredOSVersion"] stringByAppendingString:@";0"]);
        if (neededOSVersion == nil || compareOSUVersions(systemVersion, neededOSVersion) != NSOrderedAscending)
            [winnowed addObject:downloadable];
    }
    return winnowed;
}

static NSArray *OSUWinnowVersions(NSDictionary *appInfo, NSArray *downloadables)
{
    id appVersion;
    NSMutableArray *winnowed;
    unsigned int downloadableIndex, downloadableCount;
    
    if (downloadables == nil || [downloadables count] == 0)
        return downloadables;
    downloadableCount = [downloadables count];
        
    appVersion = extractOSUVersionFromBundle(appInfo);
    if (appVersion == nil) {
        // Unparseable application version.  Pass all entries in downloadables, to encourage the user to upgrade to something parseable.
        return downloadables;
    }
        
#ifdef DEBUG
    NSLog(@"Application version is %@ %@", [appInfo objectForKey:@"CFBundleName"], formatOSUVersion(appVersion));
#endif

    winnowed = [[NSMutableArray alloc] initWithCapacity:downloadableCount];
    [winnowed autorelease];
    
    for (downloadableIndex = 0; downloadableIndex < downloadableCount; downloadableIndex++) {
        NSDictionary *downloadable = [downloadables objectAtIndex:downloadableIndex];
        id downloadableVersion;
        
        downloadableVersion = parseOSUVersionString([downloadable objectForKey:@"version"]);
        if (downloadableVersion == nil)
            continue;

#ifdef DEBUG
        NSLog(@"Comparing to downloadable %@", formatOSUVersion(downloadableVersion));
#endif
        
        if (compareOSUVersions(appVersion, downloadableVersion) == NSOrderedAscending)
            [winnowed addObject:downloadable];
    }
    
    return winnowed;
}

static NSArray *OSUWinnowTracks(NSSet *visibleTracks, NSArray *downloadables)
{
    int dlIndex, dlCount;
    NSMutableArray *winnowed;
    
    if (!downloadables)
        return nil;
        
    dlCount = [downloadables count];
    winnowed = [[NSMutableArray alloc] initWithCapacity:dlCount];
    [winnowed autorelease];
    for (dlIndex = 0; dlIndex < dlCount; dlIndex++) {
        NSDictionary *downloadable = [downloadables objectAtIndex:dlIndex];
        NSString *track = [downloadable objectForKey:@"track"];
        
        // If this downloadable is on a particular track (eg, beta, sneakypeek, anything except general release) then only show it if the user knows about that track.
        if (!track || [visibleTracks containsObject:track])
            [winnowed addObject:downloadable];
    }
    
    return winnowed;
}

static NSSet *computeVisibleTracks(NSDictionary *trackInfo)
{
    NSUserDefaults *defaults;
    NSArray *visibleTracks;
    NSString *currentVersionTrack;
    unsigned int visibleTrackIndex, visibleTrackCount;
    NSMutableDictionary *knownTracks;
    BOOL didSomething;
    NSMutableSet *wantedTracks;
    NSEnumerator *knownTracksEnumerator;
    NSString *knownTrack;

    // Calculate the initial set of visible tracks
    defaults = [NSUserDefaults standardUserDefaults];
    visibleTracks = [defaults arrayForKey:OSUVisibleTracksKey];
    if (visibleTracks == nil)
        visibleTracks = [NSArray array];
    currentVersionTrack = [[[NSBundle mainBundle] infoDictionary] objectForKey:OSUBundleTrackInfoKey];
    if (currentVersionTrack != nil) {
        if (![visibleTracks containsObject:currentVersionTrack]) {
            visibleTracks = [visibleTracks arrayByAddingObject:currentVersionTrack];
            [defaults setObject:visibleTracks forKey:OSUVisibleTracksKey];
            [defaults autoSynchronize];
        }
    } else
        NSLog(@"Warning: unknown release track"); // TODO think about this

    knownTracks = [NSMutableDictionary dictionaryWithCapacity:4];
    visibleTrackCount = [visibleTracks count];
    for (visibleTrackIndex = 0; visibleTrackIndex < visibleTrackCount; visibleTrackIndex++) {
        NSString *visibleTrack;

        visibleTrack = [visibleTracks objectAtIndex:visibleTrackIndex];
        [knownTracks setObject:@"ask" forKey:visibleTrack];
    }

    // Transitively evaluate all of the "this track subsumes that track" directives in the version plist.
    do {
        NSEnumerator *trackInfoEnumerator;
        NSString *track;

        didSomething = NO;
        trackInfoEnumerator = [trackInfo keyEnumerator];
        while (!didSomething && (track = [trackInfoEnumerator nextObject]) != nil) {
            NSArray *subsumes;
            unsigned int subsumeIndex, subsumeCount;

            if ([knownTracks objectForKey:track] != nil)
                continue;
            subsumes = [[trackInfo objectForKey:track] objectForKey:@"subsumes"];
            if (subsumes == nil)
                continue;
            subsumeCount = [subsumes count];
            for (subsumeIndex = 0; subsumeIndex < subsumeCount; subsumeIndex++) {
                NSString *subsume;
                NSString *transitiveValue;
                
                subsume = [subsumes objectAtIndex:subsumeIndex];
                transitiveValue = [knownTracks objectForKey:subsume];
                if (transitiveValue != nil)  {
                    [knownTracks setObject:transitiveValue forKey:track];
                    didSomething = YES;
                    break;
                }
            }
        }
    } while (didSomething);

    wantedTracks = [NSMutableSet set];
    knownTracksEnumerator = [knownTracks keyEnumerator];
    while ((knownTrack = [knownTracksEnumerator nextObject]) != nil) {
        if ([[knownTracks objectForKey:knownTrack] isEqual:@"ask"])
            [wantedTracks addObject:knownTrack];
    }
    return wantedTracks;
}

// Compares 'software' (a version number represented as a sequence of integers) to 'spec' (likewise). If 'software' is earlier than 'spec', returns < 0. If it's later than 'spec', returns > 0. If equal, returns 0.
static int compareSimpleVersions(NSArray *software, NSArray *spec)
{
    int index;
    int lhsCount = [software count];
    int rhsCount = [spec count];
    
    for (index = 0; index < lhsCount && index < rhsCount; index++) {
        int lhs = [[software objectAtIndex:index] intValue];
        int rhs = [[spec objectAtIndex:index] intValue];
        
        if (lhs < rhs)
            return NSOrderedAscending;
        if (lhs > rhs)
            return NSOrderedDescending;
    }
    
    if (index < rhsCount)
        return NSOrderedAscending;
    
    // Asymmetric: the 'spec' version is implicitly padded with wildcards, so that software 4.0.3 is ordered-same-as spec 4.0 (but not spec 4.0.0). However, software 4.0 is ordered-earlier-than spec 4.0.3.
    
    return NSOrderedSame;
}

// Compares 'software' (a compound marketing + build version) to 'spec' (likewise). If 'software' is earlier than 'spec', returns < 0. If it's later than 'spec', returns > 0. If equal, returns 0.
static NSComparisonResult compareOSUVersions(NSArray *software, NSArray *spec)
{
    NSComparisonResult compare;
    int lhsCount, rhsCount, simpleVersionIndex;
    
    compare = NSOrderedSame;
    
    lhsCount = [software count];
    rhsCount = [spec count];
    
    for (simpleVersionIndex = 0; simpleVersionIndex < lhsCount && simpleVersionIndex < rhsCount; simpleVersionIndex++) {
        compare = compareSimpleVersions([software objectAtIndex:simpleVersionIndex], [spec objectAtIndex:simpleVersionIndex]);
        if (compare != NSOrderedSame)
            return compare;
    }
    
    if (lhsCount < rhsCount)
        return NSOrderedAscending;
    
    return compare;
}

static NSString *formatOSUVersion(NSArray *osuVersion)
{
    NSMutableString *buffer;
    unsigned int versionIndex, versionCount;
    
    buffer = [NSMutableString string];    
    versionCount = [osuVersion count];
    for (versionIndex = 0; versionIndex < versionCount; versionIndex++) {
        if ([buffer length] != 0)
            [buffer appendString:@";"];
        [buffer appendString:[[[osuVersion objectAtIndex:versionIndex] arrayByPerformingSelector:@selector(description)] componentsJoinedByString:@","]];
    }
    return buffer;
}

static NSArray *extractOSUVersionFromBundle(NSDictionary *bundleInfo)
{
    NSString *marketingVersion, *bundleVersion;
    NSScanner *scanner;
    NSMutableArray *buffer;
    NSArray *marketingParsed, *bundleParsed;

    marketingVersion = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
    bundleVersion = [bundleInfo objectForKey:@"CFBundleVersion"];
    
    if (marketingVersion == nil || ![marketingVersion isKindOfClass:[NSString class]] ||
        bundleVersion == nil || ![bundleVersion isKindOfClass:[NSString class]])
        return nil;
    
    bundleVersion = [bundleVersion stringByRemovingPrefix:@"v"];
    bundleVersion = [bundleVersion stringByRemovingPrefix:@"V"];
    
    scanner = [NSScanner scannerWithString:marketingVersion];
    buffer = [[NSMutableArray alloc] init];
    for (;;) {
        int anInteger;
        if (![scanner scanInt:&anInteger])
            break;
        [buffer addObject:[NSNumber numberWithInt:anInteger]];
        if (![scanner scanString:@"." intoString:NULL])
            break;
    }
    marketingParsed = [buffer copy];
    
    [buffer removeAllObjects];
    scanner = [NSScanner scannerWithString:bundleVersion];
    for (;;) {
        int anInteger;
        if (![scanner scanInt:&anInteger])
            break;
        [buffer addObject:[NSNumber numberWithInt:anInteger]];
        if (![scanner scanString:@"." intoString:NULL])
            break;
    }
    bundleParsed = [buffer copy];
    [buffer release];
    
    return [NSArray arrayWithObjects:marketingParsed, bundleParsed, nil];
}


static NSArray *parseOSUVersionString(NSString *osuVersionString)
{
    NSArray *parts;
    NSArray *marketingversion, *buildversion;
    NSString *part;
    
    parts = [osuVersionString componentsSeparatedByString:@";"];
    if ([parts count] != 2)
        return nil;
    
    part = [parts objectAtIndex:0];
    marketingversion = [part componentsSeparatedByString:[part containsString:@","] ? @"," : @"."];
    part = [parts objectAtIndex:1];
    buildversion = [part componentsSeparatedByString:[part containsString:@","] ? @"," : @"."];
    
    if (marketingversion == nil || buildversion == nil)
        return nil;
    
    return [NSArray arrayWithObjects:marketingversion, buildversion, nil];
}

@end
