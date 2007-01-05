//
//  BDSKUpdateChecker.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/11/06.
/*
 This software is Copyright (c) 2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "BDSKUpdateChecker.h"
#import "BDSKReadMeController.h"
#import "NSError_BDSKExtensions.h"

#define PROPERTY_LIST_URL @"http://bibdesk.sourceforge.net/bibdesk-versions-xml.txt"
#define DOWNLOAD_URL @"http://bibdesk.sourceforge.net/"
#define BIBDESK_VERSION_KEY @"BibDesk"

@interface BDSKUpdateChecker (Private)

- (NSURL *)propertyListURL;
- (NSURL *)releaseNotesURLForVersion:(NSString *)versionString;
- (NSString *)keyForVersion:(NSString *)versionString;
- (OFVersionNumber *)latestReleasedVersionNumber;
- (OFVersionNumber *)latestReleasedVersionNumberForCurrentMajor;
- (OFVersionNumber *)latestNotifiedVersionNumber;
- (OFVersionNumber *)localVersionNumber;
- (BOOL)downloadPropertyListFromServer:(NSError **)error;

- (void)handleUpdateIntervalChanged:(NSNotification *)note;
- (void)setUpdateTimer:(NSTimer *)aTimer;
- (CFGregorianUnits)updateCheckGregorianUnits;
- (NSTimeInterval)updateCheckTimeInterval;
- (NSDate *)nextUpdateCheckDate;
- (BOOL)checkForNetworkAvailability:(NSError **)error;
- (void)checkForUpdatesInBackground:(NSTimer *)timer;
- (void)checkForUpdatesInBackground;

- (void)displayUpdateAvailableWindow:(NSString *)latestVersion alternativeVersion:(NSString *)altLatestVersion;
- (void)downloadAndDisplayReleaseNotesForVersion:(NSString *)versionString;

@end

#pragma mark -

@implementation BDSKUpdateChecker

+ (id)sharedChecker;
{
    static id sharedInstance = nil;
    if (nil == sharedInstance)
        sharedInstance = [[self alloc] init];
    return sharedInstance;
}

- (id)init
{
    if (self = [super init]) {
        plistLock = [[NSLock alloc] init];
        propertyListFromServer = nil;
        keyForCurrentMajorVersion = nil;
        updateTimer = nil;
        
        NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        localVersionNumber = [[OFVersionNumber alloc] initWithVersionString:versionString];
        keyForCurrentMajorVersion = [[self keyForVersion:versionString] retain];
        
        [OFPreference addObserver:self 
                         selector:@selector(handleUpdateIntervalChanged:) 
                    forPreference:[OFPreference preferenceForKey:BDSKUpdateCheckIntervalKey]];
    }
    return self;
}

- (void)dealloc
{
    [OFPreference removeObserver:self forPreference:nil];
    
    // these objects are only accessed from the main thread
    [releaseNotesWindowController release];
    [self setUpdateTimer:nil];

    // propertyListFromServer is currently the only object shared between threads
    [plistLock lock];
    [propertyListFromServer release];
    propertyListFromServer = nil;
    [plistLock unlock];
    [plistLock release];
    plistLock = nil;
    
    // ...well, also these, but they don't change and dealloc is never called anyway
    [localVersionNumber release];
    localVersionNumber = nil;
    [keyForCurrentMajorVersion release];
    keyForCurrentMajorVersion = nil;
    
    [super dealloc];
}

- (void)scheduleUpdateCheckIfNeeded;
{
    // unschedule any current timers
    [self setUpdateTimer:nil];

    // don't schedule a new timer if updateCheckInterval is zero
    if ([self updateCheckTimeInterval] > 0) {
        
        NSDate *nextCheckDate = [self nextUpdateCheckDate];
        
        // if the date is past, check immediately
        if ([nextCheckDate timeIntervalSinceNow] <= 0) {
            [self checkForUpdatesInBackground:nil];
            
        } else {
            
            // timer will be invalidated after it fires
            NSTimer *timer = [[NSTimer alloc] initWithFireDate:nextCheckDate 
                                                      interval:[self updateCheckTimeInterval] 
                                                        target:self 
                                                      selector:@selector(checkForUpdatesInBackground:) 
                                                      userInfo:nil repeats:NO];
            
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
            [self setUpdateTimer:timer];
            [timer release];
        }
    }
}

- (IBAction)checkForUpdates:(id)sender;
{    
    // reset date of last check and reschedule the timer
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[[NSDate date] description] forKey:BDSKUpdateCheckLastDateKey];
    [self scheduleUpdateCheckIfNeeded];

    // check for network availability and display a warning if it's down
    NSError *error = nil;
    if([self checkForNetworkAvailability:&error] == NO || [self downloadPropertyListFromServer:&error] == NO) {
        
        // display a warning based on the error and bail out now
        [NSApp presentError:error];
        return;
    }
    
    OFVersionNumber *remoteVersion = [self latestReleasedVersionNumber];
    OFVersionNumber *remoteVersionForCurrentMajor = [self latestReleasedVersionNumberForCurrentMajor];
    OFVersionNumber *localVersion = [self localVersionNumber];
    OFVersionNumber *notifiedVersion = [self latestNotifiedVersionNumber];
    
    // @@ special check for the 1.3 release from the 1.3.0 nightlies, remove this for the release!
    if ([[localVersion cleanVersionString] isEqualToString:@"1.3.0"] && [[remoteVersion cleanVersionString] isEqualToString:@"1.3"]){
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[remoteVersion cleanVersionString] forKey:BDSKUpdateLatestNotifiedVersionKey];
        [self displayUpdateAvailableWindow:[remoteVersion cleanVersionString] alternativeVersion:nil];
    }
    
    // simplification if we already have the latest major
    if(remoteVersionForCurrentMajor && [remoteVersionForCurrentMajor compareToVersionNumber:remoteVersion] != NSOrderedAscending){
        remoteVersion = nil;
    }
    
    if(remoteVersion && (notifiedVersion == nil || [notifiedVersion compareToVersionNumber:remoteVersion] == NSOrderedAscending)){
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[remoteVersion cleanVersionString] forKey:BDSKUpdateLatestNotifiedVersionKey];
    } else if(remoteVersionForCurrentMajor && (notifiedVersion == nil || [notifiedVersion compareToVersionNumber:remoteVersionForCurrentMajor] == NSOrderedAscending)){
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[remoteVersionForCurrentMajor cleanVersionString] forKey:BDSKUpdateLatestNotifiedVersionKey];
    }
    
    if(remoteVersionForCurrentMajor && [remoteVersionForCurrentMajor compareToVersionNumber:localVersion] == NSOrderedDescending){
        [self displayUpdateAvailableWindow:[remoteVersionForCurrentMajor cleanVersionString] alternativeVersion:[remoteVersion cleanVersionString]];
    } else if(remoteVersion && [remoteVersion compareToVersionNumber:localVersion] == NSOrderedDescending){
        [self displayUpdateAvailableWindow:[remoteVersion cleanVersionString] alternativeVersion:nil];
    } else if(remoteVersionForCurrentMajor || remoteVersion){
        // tell user software is up to date
        NSRunAlertPanel(NSLocalizedString(@"BibDesk is up to date", @"Title of alert when a the user's software is up to date."),
                        NSLocalizedString(@"You have the most recent version of BibDesk.", @"Alert text when the user's software is up to date."),
                        nil, nil, nil);                
    } else {
        
        // likely an error page or other download failure
        [NSApp presentError:error];
    }
    
}

@end

#pragma mark -

@implementation BDSKUpdateChecker (Private)

#pragma mark Property list

- (NSURL *)propertyListURL;
{
    return [NSURL URLWithString:PROPERTY_LIST_URL];
}

// we assume this is only called /after/ a successful plist download; if not, it returns nil
- (NSURL *)releaseNotesURLForVersion:(NSString *)versionString;
{
    [plistLock lock];
    NSString *URLString = [[[[propertyListFromServer objectForKey:[self keyForVersion:versionString]] objectForKey:@"ReleaseNotesBaseURL"] copy] autorelease];
    [plistLock unlock];
    
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"RelNotes" ofType:@"rtf"];
    
    // should be e.g. English.lproj
    NSString *localizationPath = [[resourcePath stringByDeletingLastPathComponent] lastPathComponent];
    URLString = [URLString stringByAppendingPathComponent:localizationPath];
    URLString = [URLString stringByAppendingPathComponent:@"RelNotes.rtf"];
    
    return [NSURL URLWithString:URLString];
}

// string of the form BibDesk1.3 for BibDesk 1.3.x; update check info is keyed to a specific branch of development
- (NSString *)keyForVersion:(NSString *)versionString;
{
    OFVersionNumber *versionNumber = [[[OFVersionNumber alloc] initWithVersionString:versionString] autorelease];
    NSAssert([versionNumber componentCount] > 1, @"expect at least 2 version components");
    return [NSString stringWithFormat:@"%@%d.%d", BIBDESK_VERSION_KEY, [versionNumber componentAtIndex:0], [versionNumber componentAtIndex:1]];
}

- (OFVersionNumber *)latestReleasedVersionNumber;
{
    [plistLock lock];
    NSString *versionString = [[[propertyListFromServer objectForKey:BIBDESK_VERSION_KEY] copy] autorelease];
    [plistLock unlock];
    OFVersionNumber *versionNumber = versionString ? [[[OFVersionNumber alloc] initWithVersionString:versionString] autorelease] : nil;
    return versionNumber;
}

- (OFVersionNumber *)latestReleasedVersionNumberForCurrentMajor;
{
    [plistLock lock];
    NSDictionary *thisBranchDictionary = [[propertyListFromServer objectForKey:keyForCurrentMajorVersion] copy];
    [plistLock unlock];
    OFVersionNumber *versionNumber = thisBranchDictionary ? [[[OFVersionNumber alloc] initWithVersionString:[thisBranchDictionary valueForKey:@"LatestVersion"]] autorelease] : nil;
    [thisBranchDictionary release];
    return versionNumber;
}

- (OFVersionNumber *)latestNotifiedVersionNumber;
{
    NSString *versionString = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKUpdateLatestNotifiedVersionKey];
    OFVersionNumber *versionNumber = [[[OFVersionNumber alloc] initWithVersionString:versionString] autorelease];
    return versionNumber;
}

- (OFVersionNumber *)localVersionNumber;
{
    return localVersionNumber;
}

- (BOOL)downloadPropertyListFromServer:(NSError **)error;
{
    NSError *downloadError = nil;
    
    // make sure we ignore the cache policy; use default timeout of 60 seconds
    NSURLRequest *request = [NSURLRequest requestWithURL:[self propertyListURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    NSURLResponse *response;
    
    // load it synchronously; either the user requested this on the main thread, or this is the update thread
    NSData *theData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&downloadError];
    NSDictionary *versionDictionary = nil;
    BOOL success;
    
    if(nil != theData){
        NSString *err = nil;
        versionDictionary = [NSPropertyListSerialization propertyListFromData:(NSData *)theData
                                                             mutabilityOption:NSPropertyListImmutable
                                                                       format:NULL
                                                             errorDescription:&err];
        if(nil == versionDictionary){
            if (error) {
                *error = [NSError mutableLocalErrorWithCode:kBDSKPropertyListDeserializationFailed localizedDescription:NSLocalizedString(@"Unable to read the version number from the server", @"Error description")];
                [*error setValue:err forKey:NSLocalizedRecoverySuggestionErrorKey];
                // add the parsing error as underlying error, if the retrieval actually succeeded
                [*error embedError:downloadError];
            }
            [err release];
            
            // see if we have a web server error page and log it to the console; NSUnderlyingErrorKey has \n literals when logged
            NSAttributedString *attrString = [[NSAttributedString alloc] initWithHTML:theData documentAttributes:NULL];
            if ([NSString isEmptyString:[attrString string]] == NO)
                NSLog(@"retrieved HTML data instead of property list: \n\"%@\"", [attrString string]);
            [attrString release];
            success = NO;
        } else {
            success = YES;
        }
    } else {
        if(error) *error = downloadError;
        success = NO;
    }    
    
    // will set to nil if failure
    [plistLock lock];
    [propertyListFromServer release];
    propertyListFromServer = [versionDictionary copy];
    [plistLock unlock];
    
    return success;
}

#pragma mark Automatic update checking

- (void)handleUpdateIntervalChanged:(NSNotification *)note;
{
    [self scheduleUpdateCheckIfNeeded];
}

- (void)setUpdateTimer:(NSTimer *)aTimer;
{
    if (updateTimer != aTimer) {
        [updateTimer invalidate];
        [updateTimer release];
        updateTimer = [aTimer retain];
    }
}

// returns the update check granularity
- (CFGregorianUnits)updateCheckGregorianUnits;
{
    BDSKUpdateCheckInterval intervalType = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKUpdateCheckIntervalKey];
    
    CFGregorianUnits dateUnits = { 0, 0, 0, 0, 0, 0 };
    
    if (BDSKCheckForUpdatesHourly == intervalType)
        dateUnits.hours = 1;
    else if (BDSKCheckForUpdatesDaily == intervalType)
        dateUnits.days = 1;
    else if (BDSKCheckForUpdatesWeekly == intervalType)
        dateUnits.days = 7;
    else if (BDSKCheckForUpdatesMonthly == intervalType)
        dateUnits.months = 1;
    
    return dateUnits;
}

// returns the time in seconds between update checks (converts the CFGregorianUnits to seconds)
// a zero interval indicates that automatic update checking should not be performed
- (NSTimeInterval)updateCheckTimeInterval;
{    
    CFAbsoluteTime time = 0;
    return (NSTimeInterval)CFAbsoluteTimeAddGregorianUnits(time, NULL, [self updateCheckGregorianUnits]);
}

// returns UTC date of next update check
- (NSDate *)nextUpdateCheckDate;
{
    NSDate *lastCheck = [NSDate dateWithString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKUpdateCheckLastDateKey]];    
    
    // if nil, return a date in the past
    if (nil == lastCheck)
        lastCheck = [NSDate distantPast];
    
    CFAbsoluteTime lastCheckTime = CFDateGetAbsoluteTime((CFDateRef)lastCheck);
    
    // use GMT everywhere
    CFAbsoluteTime nextCheckTime = CFAbsoluteTimeAddGregorianUnits(lastCheckTime, NULL, [self updateCheckGregorianUnits]);
    
    return [(id)CFDateCreate(CFAllocatorGetDefault(), nextCheckTime) autorelease];
}

- (void)checkForUpdatesInBackground:(NSTimer *)timer;
{
    [NSThread detachNewThreadSelector:@selector(checkForUpdatesInBackground) toTarget:self withObject:nil];
    
    // set the current date as the date of the last update check
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[[NSDate date] description] forKey:BDSKUpdateCheckLastDateKey];
    [self scheduleUpdateCheckIfNeeded];
}

// @@ is this used anywhere?
- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(unsigned int)recoveryOptionIndex;
{
    BOOL didRecover = NO;
    
    // we only receive this for a single error at present
    if ([error isLocalError] && [error code] == kBDSKNetworkConnectionFailed) {
        if (0 == recoveryOptionIndex) {
            // ignore
            didRecover = NO;
            
        } else if (1 == recoveryOptionIndex) {
            // diagnose
            CFURLRef theURL = (CFURLRef)[self propertyListURL];
            CFNetDiagnosticRef diagnostic = CFNetDiagnosticCreateWithURL(CFGetAllocator(theURL), theURL);
            CFNetDiagnosticStatus status = CFNetDiagnosticDiagnoseProblemInteractively(diagnostic);
            CFRelease(diagnostic);
            didRecover = (status == kCFNetDiagnosticNoErr);
            
        } else if (2 == recoveryOptionIndex) {
            // open console
            didRecover = [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.console" options:0 additionalEventParamDescriptor:nil launchIdentifier:NULL];
        }
    } else {
        didRecover = NO;
    }
    
    return didRecover;
}

- (BOOL)checkForNetworkAvailability:(NSError **)error;
{
    CFURLRef theURL = (CFURLRef)[self propertyListURL];
    CFNetDiagnosticRef diagnostic = CFNetDiagnosticCreateWithURL(CFGetAllocator(theURL), theURL);
    
    NSString *details;
    CFNetDiagnosticStatus status = CFNetDiagnosticCopyNetworkStatusPassively(diagnostic, (CFStringRef *)&details);
    CFRelease(diagnostic);
    [details autorelease];
    
    BOOL success;
    
    if (kCFNetDiagnosticConnectionUp == status) {
        success = YES;
    } else {
        if (nil == details) details = NSLocalizedString(@"Unknown network error", @"Error description");
        
        // This error contains all the information needed for NSErrorRecoveryAttempting.  
        // Note that buttons in the alert will be ordered right-to-left {0, 1, 2} and correspond to objects in the NSLocalizedRecoveryOptionsErrorKey array.
        if (error) {
            *error = [NSError mutableLocalErrorWithCode:kBDSKNetworkConnectionFailed localizedDescription:details];
            [*error setValue:self forKey:NSRecoveryAttempterErrorKey];
            [*error setValue:NSLocalizedString(@"Would you like to ignore this problem or attempt to diagnose it?  You may also open the Console log to check for errors.", @"Error informative text") forKey:NSLocalizedRecoverySuggestionErrorKey];
            [*error setValue:[NSArray arrayWithObjects:NSLocalizedString(@"Ignore", @"Button title"), NSLocalizedString(@"Diagnose", @"Button title"), NSLocalizedString(@"Open Console", @"Button title"), nil] forKey:NSLocalizedRecoveryOptionsErrorKey];
        }
        success = NO;
    }
    
    return success;
}

- (void)checkForUpdatesInBackground;
{
    // sanity check so we don't spawn dozens of threads
    static int numberOfConcurrentChecks = 0;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    numberOfConcurrentChecks++;
    
    // don't bother displaying network availability warnings for an automatic check
    if([self checkForNetworkAvailability:NULL] == NO || numberOfConcurrentChecks > 1){
        numberOfConcurrentChecks--;
        [pool release];
        return;
    }
    
    NSError *error = nil;
    
    // make sure our plist is current
    [self downloadPropertyListFromServer:&error];
    
    OFVersionNumber *remoteVersion = [self latestReleasedVersionNumber];
    OFVersionNumber *remoteVersionForCurrentMajor = [self latestReleasedVersionNumberForCurrentMajor];
    OFVersionNumber *localVersion = [self localVersionNumber];
    OFVersionNumber *notifiedVersion = [self latestNotifiedVersionNumber];
    
    // @@ special check for the 1.3 release from the 1.3.0 nightlies, remove this for the release!
    if ([[localVersion cleanVersionString] isEqualToString:@"1.3.0"] && [[remoteVersion cleanVersionString] isEqualToString:@"1.3"]){
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[remoteVersion cleanVersionString] forKey:BDSKUpdateLatestNotifiedVersionKey];
        [[OFMessageQueue mainQueue] queueSelector:@selector(displayUpdateAvailableWindow:alternativeVersion:) forObject:self withObject:[remoteVersion cleanVersionString] withObject:nil];
    }
    
    // simplification if we're already have the latest major
    if(remoteVersionForCurrentMajor && [remoteVersionForCurrentMajor compareToVersionNumber:remoteVersion] != NSOrderedAscending){
        remoteVersion = nil;
    }
    
    // we only automatically notify for new releases of next major versions once
    // @@ we might also notify only once per major instead of per version
    if(notifiedVersion && [notifiedVersion compareToVersionNumber:remoteVersion] != NSOrderedAscending){
        remoteVersion = nil;
    } else if(remoteVersion){
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[remoteVersion cleanVersionString] forKey:BDSKUpdateLatestNotifiedVersionKey];
    } else if(remoteVersionForCurrentMajor && (notifiedVersion == nil || [notifiedVersion compareToVersionNumber:remoteVersionForCurrentMajor] == NSOrderedAscending)){
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[remoteVersionForCurrentMajor cleanVersionString] forKey:BDSKUpdateLatestNotifiedVersionKey];
    }
    
    if(remoteVersionForCurrentMajor && [remoteVersionForCurrentMajor compareToVersionNumber:localVersion] == NSOrderedDescending){
        [[OFMessageQueue mainQueue] queueSelector:@selector(displayUpdateAvailableWindow:alternativeVersion:) forObject:self withObject:[remoteVersionForCurrentMajor cleanVersionString] withObject:[remoteVersion cleanVersionString]];
    } else if(remoteVersion && [remoteVersion compareToVersionNumber:localVersion] == NSOrderedDescending){
        [[OFMessageQueue mainQueue] queueSelector:@selector(displayUpdateAvailableWindow:alternativeVersion:) forObject:self withObject:[remoteVersion cleanVersionString] withObject:nil];
        
    } else if((nil == remoteVersionForCurrentMajor || nil == remoteVersion) && nil != error){
        // was showing an alert for this, but apparently it's really common for the check to fail
        NSLog(@"%@", [error description]);
    }
    [pool release];
    numberOfConcurrentChecks--;
}

#pragma mark Update notification

- (void)downloadAndDisplayReleaseNotesForVersion:(NSString *)versionString;
{
    NSURL *theURL = [self releaseNotesURLForVersion:versionString];
    NSURLRequest *request = [NSURLRequest requestWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    NSURLResponse *response;
    
    NSError *downloadError;
    
    // load it synchronously; user requested this on the main thread
    NSData *theData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&downloadError];
    
    // @@ use error description for message or display alert?
    // @@ option for user to d/l latest version when displaying this window?
    NSAttributedString *attrString;
    if (theData)
        attrString = [[[NSAttributedString alloc] initWithRTF:theData documentAttributes:NULL] autorelease];
    else
        attrString = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Download Failed", @"Message when download failed") attributeName:NSForegroundColorAttributeName attributeValue:[NSColor redColor]] autorelease];
    
    if (nil == releaseNotesWindowController)
        releaseNotesWindowController = [[BDSKRelNotesController alloc] init];
    
    [releaseNotesWindowController displayAttributedString:attrString];
    [releaseNotesWindowController showWindow:nil];
}

- (void)displayUpdateAvailableWindow:(NSString *)latestVersion alternativeVersion:(NSString *)altLatestVersion;
{
    int button;
    NSString *message = nil;
    
    if(altLatestVersion != nil)
        message = NSLocalizedString(@"A new version of BibDesk is available (versions %@ and %@). Would you like to download the new version now?", @"Informative text in alert dialog");
    else
        message = NSLocalizedString(@"A new version of BibDesk is available (version %@). Would you like to download the new version now?", @"Informative text in alert dialog");
    
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"A New Version is Available", @"Message in alert dialog when new version is available")
                                     defaultButton:NSLocalizedString(@"Download", @"Button title")
                                   alternateButton:NSLocalizedString(@"View Release Notes", @"Button title")
                                       otherButton:NSLocalizedString(@"Ignore",@"Button title")
                         informativeTextWithFormat:message, latestVersion, altLatestVersion];
                                        
    button = [alert runModal];
    
    if (button == NSAlertDefaultReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:DOWNLOAD_URL]];
    } else if (button == NSAlertAlternateReturn) {
        [self downloadAndDisplayReleaseNotesForVersion:altLatestVersion ? altLatestVersion : latestVersion];
    }
}

@end
