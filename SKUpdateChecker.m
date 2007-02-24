//
//  SKUpdateChecker.m
//  Skim
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

#import "SKUpdateChecker.h"
#import "SKVersionNumber.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKStringConstants.h"

#define PROPERTY_LIST_URL @"http://bibdesk.sourceforge.net/skim-versions-xml.txt"
#define DOWNLOAD_URL @"http://bibdesk.sourceforge.net/"
#define SKIM_VERSION_KEY @"Skim"

static NSString *SKErrorDomain = @"net.sourceforge.bibdesk.skim.errors";

enum {
    kSKNetworkConnectionFailed,
    kSKPropertyListDeserializationFailed
};

@interface SKUpdateChecker (Private)

- (NSURL *)propertyListURL;
- (NSURL *)releaseNotesURLForVersion:(NSString *)versionString;
- (NSString *)keyForVersion:(NSString *)versionString;
- (SKVersionNumber *)latestReleasedVersionNumber;
- (SKVersionNumber *)latestReleasedVersionNumberForCurrentMajor;
- (SKVersionNumber *)latestNotifiedVersionNumber;
- (SKVersionNumber *)localVersionNumber;
- (BOOL)downloadPropertyListFromServer:(NSError **)error;

- (void)setUpdateTimer:(NSTimer *)aTimer;
- (CFGregorianUnits)updateCheckGregorianUnits;
- (NSTimeInterval)updateCheckTimeInterval;
- (NSDate *)nextUpdateCheckDate;
- (BOOL)checkForNetworkAvailability:(NSError **)error;
- (void)checkForUpdatesInBackground:(NSTimer *)timer;
- (void)checkForUpdatesInBackground;

- (void)displayUpdateAvailableWindow:(NSArray *)latestVersions;
- (void)downloadAndDisplayReleaseNotesForVersion:(NSString *)versionString;

@end

#pragma mark -

@implementation SKUpdateChecker

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
        localVersionNumber = [[SKVersionNumber alloc] initWithVersionString:versionString];
        keyForCurrentMajorVersion = [[self keyForVersion:versionString] retain];
        
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKUpdateCheckIntervalKey];
    }
    return self;
}

- (void)dealloc
{
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKUpdateCheckIntervalKey];
    
    // these objects are only accessed from the main thread
    //[releaseNotesWindowController release];
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
    [[NSUserDefaults standardUserDefaults] setObject:[[NSDate date] description] forKey:SKUpdateCheckLastDateKey];
    [self scheduleUpdateCheckIfNeeded];

    // check for network availability and display a warning if it's down
    NSError *error = nil;
    if([self checkForNetworkAvailability:&error] == NO || [self downloadPropertyListFromServer:&error] == NO) {
        
        // display a warning based on the error and bail out now
        [NSApp presentError:error];
        return;
    }
    
    SKVersionNumber *remoteVersion = [self latestReleasedVersionNumber];
    SKVersionNumber *remoteVersionForCurrentMajor = [self latestReleasedVersionNumberForCurrentMajor];
    SKVersionNumber *localVersion = [self localVersionNumber];
    SKVersionNumber *notifiedVersion = [self latestNotifiedVersionNumber];
    
    // simplification if we already have the latest major
    if(remoteVersionForCurrentMajor && [remoteVersionForCurrentMajor compareToVersionNumber:remoteVersion] != NSOrderedAscending){
        remoteVersion = nil;
    }
    
    if(remoteVersion && (notifiedVersion == nil || [notifiedVersion compareToVersionNumber:remoteVersion] == NSOrderedAscending)){
        [[NSUserDefaults standardUserDefaults] setObject:[remoteVersion cleanVersionString] forKey:SKUpdateLatestNotifiedVersionKey];
    } else if(remoteVersionForCurrentMajor && (notifiedVersion == nil || [notifiedVersion compareToVersionNumber:remoteVersionForCurrentMajor] == NSOrderedAscending)){
        [[NSUserDefaults standardUserDefaults] setObject:[remoteVersionForCurrentMajor cleanVersionString] forKey:SKUpdateLatestNotifiedVersionKey];
    }
    
    if(remoteVersionForCurrentMajor && [remoteVersionForCurrentMajor compareToVersionNumber:localVersion] == NSOrderedDescending){
        [self displayUpdateAvailableWindow:[NSArray arrayWithObjects:[remoteVersionForCurrentMajor cleanVersionString], [remoteVersion cleanVersionString], nil]];
    } else if(remoteVersion && [remoteVersion compareToVersionNumber:localVersion] == NSOrderedDescending){
        [self displayUpdateAvailableWindow:[NSArray arrayWithObjects:[remoteVersion cleanVersionString], nil]];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [NSUserDefaultsController sharedUserDefaultsController]) {
        if (NO == [keyPath hasPrefix:@"values."])
            return;
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKUpdateCheckIntervalKey]) {
            [self scheduleUpdateCheckIfNeeded];
        }
    }
}

@end

#pragma mark -

@implementation SKUpdateChecker (Private)

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
    
    return URLString ? [NSURL URLWithString:URLString] : nil;
}

// string of the form BibDesk1.3 for BibDesk 1.3.x; update check info is keyed to a specific branch of development
- (NSString *)keyForVersion:(NSString *)versionString;
{
    SKVersionNumber *versionNumber = [[[SKVersionNumber alloc] initWithVersionString:versionString] autorelease];
    NSAssert([versionNumber componentCount] > 1, @"expect at least 2 version components");
    return [NSString stringWithFormat:@"%@%d.%d", SKIM_VERSION_KEY, [versionNumber componentAtIndex:0], [versionNumber componentAtIndex:1]];
}

- (SKVersionNumber *)latestReleasedVersionNumber;
{
    [plistLock lock];
    NSString *versionString = [[[propertyListFromServer objectForKey:SKIM_VERSION_KEY] copy] autorelease];
    [plistLock unlock];
    SKVersionNumber *versionNumber = versionString ? [[[SKVersionNumber alloc] initWithVersionString:versionString] autorelease] : nil;
    return versionNumber;
}

- (SKVersionNumber *)latestReleasedVersionNumberForCurrentMajor;
{
    [plistLock lock];
    NSDictionary *thisBranchDictionary = [[propertyListFromServer objectForKey:keyForCurrentMajorVersion] copy];
    [plistLock unlock];
    SKVersionNumber *versionNumber = thisBranchDictionary ? [[[SKVersionNumber alloc] initWithVersionString:[thisBranchDictionary valueForKey:@"LatestVersion"]] autorelease] : nil;
    [thisBranchDictionary release];
    return versionNumber;
}

- (SKVersionNumber *)latestNotifiedVersionNumber;
{
    NSString *versionString = [[NSUserDefaults standardUserDefaults] stringForKey:SKUpdateLatestNotifiedVersionKey];
    SKVersionNumber *versionNumber = [[[SKVersionNumber alloc] initWithVersionString:versionString] autorelease];
    return versionNumber;
}

- (SKVersionNumber *)localVersionNumber;
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
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to read the version number from the server", @"Error description"), NSLocalizedDescriptionKey, err, NSLocalizedRecoverySuggestionErrorKey, downloadError, NSUnderlyingErrorKey, nil];
                *error = [[[NSError alloc] initWithDomain:SKErrorDomain code:kSKPropertyListDeserializationFailed userInfo:userInfo] autorelease];
            }
            [err release];
            
            // see if we have a web server error page and log it to the console; NSUnderlyingErrorKey has \n literals when logged
            NSAttributedString *attrString = [[NSAttributedString alloc] initWithHTML:theData documentAttributes:NULL];
            if ([attrString length] != 0)
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
    SKUpdateCheckInterval intervalType = [[NSUserDefaults standardUserDefaults] integerForKey:SKUpdateCheckIntervalKey];
    
    CFGregorianUnits dateUnits = { 0, 0, 0, 0, 0, 0 };
    
    if (SKCheckForUpdatesHourly == intervalType)
        dateUnits.hours = 1;
    else if (SKCheckForUpdatesDaily == intervalType)
        dateUnits.days = 1;
    else if (SKCheckForUpdatesWeekly == intervalType)
        dateUnits.days = 7;
    else if (SKCheckForUpdatesMonthly == intervalType)
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
    NSDate *lastCheck = [NSDate dateWithString:[[NSUserDefaults standardUserDefaults] objectForKey:SKUpdateCheckLastDateKey]];    
    
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
    [[NSUserDefaults standardUserDefaults] setObject:[[NSDate date] description] forKey:SKUpdateCheckLastDateKey];
    [self scheduleUpdateCheckIfNeeded];
}

// @@ is this used anywhere?
- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(unsigned int)recoveryOptionIndex;
{
    BOOL didRecover = NO;
    
    // we only receive this for a single error at present
    if ([[error domain] isEqualToString:SKErrorDomain] && [error code] == kSKNetworkConnectionFailed) {
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
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:details, NSLocalizedDescriptionKey, NSLocalizedString(@"Would you like to ignore this problem or attempt to diagnose it?  You may also open the Console log to check for errors.", @"Error informative text"), NSLocalizedRecoverySuggestionErrorKey, self, NSRecoveryAttempterErrorKey, [NSArray arrayWithObjects:NSLocalizedString(@"Ignore", @"Button title"), NSLocalizedString(@"Diagnose", @"Button title"), NSLocalizedString(@"Open Console", @"Button title"), nil], NSLocalizedRecoveryOptionsErrorKey, nil];
            *error = [[[NSError alloc] initWithDomain:SKErrorDomain code:kSKNetworkConnectionFailed userInfo:userInfo] autorelease];
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
    
    SKVersionNumber *remoteVersion = [self latestReleasedVersionNumber];
    SKVersionNumber *remoteVersionForCurrentMajor = [self latestReleasedVersionNumberForCurrentMajor];
    SKVersionNumber *localVersion = [self localVersionNumber];
    SKVersionNumber *notifiedVersion = [self latestNotifiedVersionNumber];
    
    // simplification if we're already have the latest major
    if(remoteVersionForCurrentMajor && [remoteVersionForCurrentMajor compareToVersionNumber:remoteVersion] != NSOrderedAscending){
        remoteVersion = nil;
    }
    
    // we only automatically notify for new releases of next major versions once
    // @@ we might also notify only once per major instead of per version
    if(notifiedVersion && [notifiedVersion compareToVersionNumber:remoteVersion] != NSOrderedAscending){
        remoteVersion = nil;
    } else if(remoteVersion){
        [[NSUserDefaults standardUserDefaults] setObject:[remoteVersion cleanVersionString] forKey:SKUpdateLatestNotifiedVersionKey];
    } else if(remoteVersionForCurrentMajor && (notifiedVersion == nil || [notifiedVersion compareToVersionNumber:remoteVersionForCurrentMajor] == NSOrderedAscending)){
        [[NSUserDefaults standardUserDefaults] setObject:[remoteVersionForCurrentMajor cleanVersionString] forKey:SKUpdateLatestNotifiedVersionKey];
    }
    
    if(remoteVersionForCurrentMajor && [remoteVersionForCurrentMajor compareToVersionNumber:localVersion] == NSOrderedDescending){
        [self performSelectorOnMainThread:@selector(displayUpdateAvailableWindow:) withObject:[NSArray arrayWithObjects:[remoteVersionForCurrentMajor cleanVersionString], [remoteVersion cleanVersionString]] waitUntilDone:NO];
    } else if(remoteVersion && [remoteVersion compareToVersionNumber:localVersion] == NSOrderedDescending){
        [self performSelectorOnMainThread:@selector(displayUpdateAvailableWindow:) withObject:[NSArray arrayWithObjects:[remoteVersion cleanVersionString], nil] waitUntilDone:NO];
        
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
    NSData *theData = nil;
    
    if(theURL){
        // load it synchronously; user requested this on the main thread
        NSURLRequest *request = [NSURLRequest requestWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
        NSURLResponse *response = nil;
        NSError *downloadError = nil;
        theData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&downloadError];
    }
    
    // @@ use error description for message or display alert?
    NSAttributedString *attrString;
    if (theData)
        attrString = [[[NSAttributedString alloc] initWithRTF:theData documentAttributes:NULL] autorelease];
    else
        attrString = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Download Failed", @"Message when download failed") attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor redColor], NSForegroundColorAttributeName, nil]] autorelease];
    
    /*
    if (nil == releaseNotesWindowController)
        releaseNotesWindowController = [[SKRelNotesController alloc] init];
    
    [releaseNotesWindowController displayAttributedString:attrString];
    [releaseNotesWindowController showWindow:nil];
    */
}

- (void)displayUpdateAvailableWindow:(NSArray *)latestVersions;
{
    NSString *latestVersion = [latestVersions objectAtIndex:0];
    NSString *altLatestVersion = [latestVersions count] > 1 ? [latestVersions objectAtIndex:1] : nil;
    int button;
    NSString *message = nil;
    NSString *alternateButton = nil;
    NSString *altAlternateButton = nil;
    
    const int SKAlertAltAlternateReturn = 1003;
    
    if(altLatestVersion != nil){
        message = NSLocalizedString(@"A new version of BibDesk is available (versions %@ and %@). Would you like to download the new version now?", @"Informative text in alert dialog");
        alternateButton = [NSString stringWithFormat:NSLocalizedString(@"Release Notes for %@", @"Buttton title"), altLatestVersion];
        altAlternateButton = [NSString stringWithFormat:NSLocalizedString(@"Release Notes for %@", @"Buttton title"), latestVersion];
    }else{
        message = NSLocalizedString(@"A new version of BibDesk is available (version %@). Would you like to download the new version now?", @"Informative text in alert dialog");
        alternateButton = NSLocalizedString(@"View Release Notes", @"Button title");
    }
    
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"A New Version is Available", @"Message in alert dialog when new version is available")
                                     defaultButton:NSLocalizedString(@"Download", @"Button title")
                                   alternateButton:alternateButton
                                       otherButton:NSLocalizedString(@"Ignore",@"Button title")
                         informativeTextWithFormat:message, latestVersion, altLatestVersion];
    
    if(altAlternateButton){
        [alert addButtonWithTitle:altAlternateButton];
    }
    
    button = [alert runModal];
    
    if (button == NSAlertDefaultReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:DOWNLOAD_URL]];
    } else if (button == NSAlertAlternateReturn) {
        [self downloadAndDisplayReleaseNotesForVersion:altLatestVersion ? altLatestVersion : latestVersion];
    } else if (button == SKAlertAltAlternateReturn) {
        [self downloadAndDisplayReleaseNotesForVersion:latestVersion];
    }
}

@end
