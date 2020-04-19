//
//  SKApplicationController.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2020
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

#import "SKApplicationController.h"
#import "SKApplication.h"
#import "SKLineInspector.h"
#import "SKNotesPanelController.h"
#import "SKPreferenceController.h"
#import "SKReleaseNotesController.h"
#import "SKStringConstants.h"
#import "SKMainDocument.h"
#import "SKMainWindowController.h"
#import "SKMainWindowController_Actions.h"
#import "SKBookmarkController.h"
#import "SKBookmark.h"
#import "SKAlias.h"
#import "SKVersionNumber.h"
#import "NSUserDefaults_SKExtensions.h"
#import <Quartz/Quartz.h>
#import <Sparkle/Sparkle.h>
#import "NSImage_SKExtensions.h"
#import "SKDownloadController.h"
#import "SKDownload.h"
#import "NSURL_SKExtensions.h"
#import "SKDocumentController.h"
#import "NSDocument_SKExtensions.h"
#import "NSFileManager_SKExtensions.h"
#import "SKRuntime.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "PDFAnnotationLine_SKExtensions.h"
#import "PDFAnnotationFreeText_SKExtensions.h"
#import "PDFAnnotationText_SKExtensions.h"
#import "SKFDFParser.h"
#import "SKLocalization.h"
#import "SKScriptMenu.h"
#import "NSScreen_SKExtensions.h"
#import "NSError_SKExtensions.h"
#import "NSValueTransformer_SKExtensions.h"
#import "SKAnimatedBorderlessWindow.h"
#import "NSGraphics_SKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "NSColor_SKExtensions.h"

#define WEBSITE_URL @"https://skim-app.sourceforge.io/"
#define WIKI_URL    @"https://sourceforge.net/p/skim-app/wiki/"

#define INITIAL_USER_DEFAULTS_FILENAME  @"InitialUserDefaults"
#define REGISTERED_DEFAULTS_KEY         @"RegisteredDefaults"
#define RESETTABLE_KEYS_KEY             @"ResettableKeys"

#define VIEW_MENU_INDEX      4

#define REOPEN_WARNING_LIMIT 50

#define CURRENTDOCUMENTSETUP_INTERVAL 300.0

#define CURRENTDOCUMENTSETUP_KEY @"currentDocumentSetup"

#define SKIsRelaunchKey                     @"SKIsRelaunch"
#define SKLastVersionLaunchedKey            @"SKLastVersionLaunched"
#define SKSpotlightVersionInfoKey           @"SKSpotlightVersionInfo"
#define SKSpotlightLastImporterVersionKey   @"lastImporterVersion"
#define SKSpotlightLastSysVersionKey        @"lastSysVersion"

#define SKCircleInteriorString  @"CircleInterior"
#define SKSquareInteriorString  @"SquareInterior"
#define SKLineInteriorString    @"LineInterior"
#define SKFreeTextFontString    @"FreeTextFont"

#define SKUseLegacyFullScreenKey @"SKUseLegacyFullScreen"

static char SKApplicationObservationContext;

NSString *SKFavoriteColorListName = @"Skim Favorite Colors";

#if SDK_BEFORE(10_12)
@interface NSApplication (SKSierraDeclarations)
@property (getter=isAutomaticCustomizeTouchBarMenuItemEnabled) BOOL automaticCustomizeTouchBarMenuItemEnabled;
@end
#endif

@interface SKApplicationController (SKPrivate)
- (void)doSpotlightImportIfNeeded;
- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;
@end

@implementation SKApplicationController

@dynamic defaultPdfViewSettings, defaultFullScreenPdfViewSettings, backgroundColor, fullScreenBackgroundColor, pageBackgroundColor, defaultNoteColors, defaultLineWidths, defaultLineStyles, defaultDashPatterns, defaultStartLineStyle, defaultEndLineStyle, defaultFontNames, defaultFontSizes, defaultTextNoteFontColor, defaultAlignment, defaultIconType, favoriteColors;

+ (void)initialize{
    SKINITIALIZE;
    
    // load the default values for the user defaults
    NSURL *initialUserDefaultsURL = [[NSBundle mainBundle] URLForResource:INITIAL_USER_DEFAULTS_FILENAME withExtension:@"plist"];
    NSDictionary *initialUserDefaultsDict = [NSDictionary dictionaryWithContentsOfURL:initialUserDefaultsURL];
    NSDictionary *initialValuesDict = [initialUserDefaultsDict objectForKey:REGISTERED_DEFAULTS_KEY];
    NSArray *resettableUserDefaultsKeys;
    
    // set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:initialValuesDict];
    
    NSURL *downloadsURL = [[NSFileManager defaultManager] URLForDirectory:NSDownloadsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
    if (downloadsURL)
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[[downloadsURL path] stringByAbbreviatingWithTildeInPath] forKey:SKDownloadsDirectoryKey]];
    
    // if your application supports resetting a subset of the defaults to 
    // factory values, you should set those values 
    // in the shared user defaults controller
    
    resettableUserDefaultsKeys = [[[initialUserDefaultsDict objectForKey:RESETTABLE_KEYS_KEY] allValues] valueForKeyPath:@"@unionOfArrays.self"];
    initialValuesDict = [initialValuesDict dictionaryWithValuesForKeys:resettableUserDefaultsKeys];
    
    // Set the initial values in the shared user defaults controller 
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
    
    if (RUNNING(10_11)) {
        // Disable ATS on El Capitan, as forwarding is blocked, even if it is an htpps address
        @try{
            [(NSMutableDictionary *)[[NSBundle mainBundle] infoDictionary] setObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"NSAllowsArbitraryLoads"] forKey:@"NSAppTransportSecurity"];
        }
        @catch(id e) {}
    }
}

- (void)awakeFromNib {
    [[NSApp mainMenu] localizeStringsFromTable:@"MainMenu"];
    
    NSMenu *viewMenu = [[[NSApp mainMenu] itemAtIndex:VIEW_MENU_INDEX] submenu];
    for (NSMenuItem *menuItem in [viewMenu itemArray]) {
        if ([menuItem action] == @selector(changeLeftSidePaneState:) || [menuItem action] == @selector(changeRightSidePaneState:))
            [menuItem setIndentationLevel:1];
    }
    
    // this creates the script menu if needed
    (void)[NSApp scriptMenu];
}

- (void)registerCurrentDocuments:(id)timerOrNotification {
    [[NSUserDefaults standardUserDefaults] setObject:[[NSApp orderedDocuments] valueForKey:CURRENTDOCUMENTSETUP_KEY] forKey:SKLastOpenFileNamesKey];
    [[[NSDocumentController sharedDocumentController] documents] makeObjectsPerformSelector:@selector(saveRecentDocumentInfo)];
    if (RUNNING_BEFORE(10_9))
        [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)handleWindowDidBecomeMainNotification:(NSNotification *)aNotification {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKUseLegacyFullScreenKey])
        [NSApp updatePresentationOptionsForWindow:[aNotification object]];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKApplicationObservationContext) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SKDarkModeChangedNotification object:NSApp];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark NSApplication delegate

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
    if (didCheckReopen == NO) {
        NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
        
        didCheckReopen = YES;
        
        if ([sud boolForKey:SKReopenLastOpenFilesKey] || [sud boolForKey:SKIsRelaunchKey]) {
            // just remove this in case opening the last open files crashes the app after a relaunch
            if ([sud objectForKey:SKIsRelaunchKey]) {
                [sud removeObjectForKey:SKIsRelaunchKey];
                [sud synchronize];
            }
            
            SKBookmark *previousSession = [[SKBookmarkController sharedBookmarkController] previousSession];
            NSUInteger numberOfDocs = [[previousSession children] count];
            
            if (numberOfDocs > REOPEN_WARNING_LIMIT) {
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to open %lu documents?", @"Message in alert dialog"), (unsigned long)numberOfDocs]];
                [alert setInformativeText:NSLocalizedString(@"Each document opens in a separate window.", @"Informative text in alert dialog")];
                [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button title")];
                [alert addButtonWithTitle:NSLocalizedString(@"Open", @"Button title")];
                
                if (NSAlertFirstButtonReturn == [alert runModal])
                    previousSession = nil;
            }
            
            if (previousSession)
                [[NSDocumentController sharedDocumentController] openDocumentWithBookmark:previousSession completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){
                    if (document == nil && error && [error isUserCancelledError] == NO)
                        [NSApp presentError:error];
                }];
        }
    }
    return NO;
}    

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    [NSImage makeImages];
    [NSColor makeColors];
    [NSValueTransformer registerCustomTransformers];
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    
    if (didCheckReopen == NO && [[NSApp windows] count] == 0 && [(SKDocumentController *)[NSDocumentController sharedDocumentController] openedFile] == NO)
        [self applicationShouldOpenUntitledFile:NSApp];
    didCheckReopen = YES;
    [sud removeObjectForKey:SKIsRelaunchKey];
    
    [NSApp setServicesProvider:[NSDocumentController sharedDocumentController]];
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    NSString *lastVersionString = [sud stringForKey:SKLastVersionLaunchedKey];
    if (lastVersionString == nil || [SKVersionNumber compareVersionString:lastVersionString toVersionString:versionString] == NSOrderedAscending) {
        [self showReleaseNotes:nil];
        [sud setObject:versionString forKey:SKLastVersionLaunchedKey];
    }
	
    [self doSpotlightImportIfNeeded];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(registerCurrentDocuments:) 
                             name:SKDocumentDidShowNotification object:nil];
    [nc addObserver:self selector:@selector(registerCurrentDocuments:) 
                             name:SKDocumentControllerDidRemoveDocumentNotification object:nil];
    [nc addObserver:self selector:@selector(handleWindowDidBecomeMainNotification:) 
                             name:NSWindowDidBecomeMainNotification object:nil];
    
    currentDocumentsTimer = [[NSTimer scheduledTimerWithTimeInterval:CURRENTDOCUMENTSETUP_INTERVAL target:self selector:@selector(registerCurrentDocuments:) userInfo:nil repeats:YES] retain];
    
    if (RUNNING_AFTER(10_13))
        [NSApp addObserver:self forKeyPath:@"effectiveAppearance" options:0 context:&SKApplicationObservationContext];
    
    // kHIDRemoteModeExclusiveAuto lets the HIDRemote handle activation when the app gets or loses focus
    if ([sud boolForKey:SKEnableAppleRemoteKey]) {
        [[HIDRemote sharedHIDRemote] startRemoteControl:kHIDRemoteModeExclusiveAuto];
        [[HIDRemote sharedHIDRemote] setDelegate:self];
    }
    
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    if ([NSApp respondsToSelector:@selector(setAutomaticCustomizeTouchBarMenuItemEnabled:)])
        [NSApp setAutomaticCustomizeTouchBarMenuItemEnabled:YES];
#pragma clang diagnostic pop
}

// we don't want to reopen last open files when re-activating the app
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    return flag;
}

- (void)applicationStartsTerminating:(NSNotification *)aNotification {
    [currentDocumentsTimer invalidate];
    SKDESTROY(currentDocumentsTimer);
    [self registerCurrentDocuments:aNotification];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:SKDocumentDidShowNotification object:nil];
    [nc removeObserver:self name:SKDocumentControllerDidRemoveDocumentNotification object:nil];
    [nc removeObserver:self name:NSWindowDidBecomeMainNotification object:nil];
}

#pragma mark Updater

- (void)updaterWillRelaunchApplication:(SUUpdater *)updater {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SKIsRelaunchKey];
}

#pragma mark Actions

- (IBAction)orderFrontLineInspector:(id)sender {
    NSWindow *window = [[SKLineInspector sharedLineInspector] window];
    if ([window isVisible])
        [window orderOut:sender];
    else
        [window orderFront:sender];
}

- (IBAction)orderFrontNotesPanel:(id)sender {
    NSWindow *window = [[SKNotesPanelController sharedController] window];
    if ([window isVisible])
        [window orderOut:sender];
    else
        [window orderFront:sender];
}

- (IBAction)visitWebSite:(id)sender{
    if([[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:WEBSITE_URL]] == NO)
        NSBeep();
}

- (IBAction)visitWiki:(id)sender{
    if([[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:WIKI_URL]] == NO)
        NSBeep();
}

- (IBAction)showPreferencePanel:(id)sender{
    [[SKPreferenceController sharedPrefenceController] showWindow:self];
}

- (IBAction)showReleaseNotes:(id)sender{
    [[SKReleaseNotesController sharedReleaseNotesController] showWindow:self];
}

- (IBAction)showDownloads:(id)sender{
    [[SKDownloadController sharedDownloadController] showWindow:self];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(orderFrontLineInspector:)) {
        if ([SKLineInspector sharedLineInspectorExists] && [[[SKLineInspector sharedLineInspector] window] isVisible])
            [menuItem setTitle:NSLocalizedString(@"Hide Lines", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Lines", @"Menu item title")];
        return YES;
    } else if (action == @selector(orderFrontNotesPanel:)) {
        if ([SKNotesPanelController sharedControllerExists] && [[[SKNotesPanelController sharedController] window] isVisible])
            [menuItem setTitle:NSLocalizedString(@"Hide Note Type", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Note Type", @"Menu item title")];
        return YES;
    }
    return YES;
}

- (void)showRemoteSwitchIndication {
    NSTimeInterval timeInterval = [[NSUserDefaults standardUserDefaults] floatForKey:SKAppleRemoteSwitchIndicationTimeoutKey];
    if (timeInterval > 0.0) {
        static SKAnimatedBorderlessWindow *remoteStateWindow = nil;
        if (remoteStateWindow == nil) {
            NSRect contentRect = SKRectFromCenterAndSize(SKCenterPoint([[NSScreen mainScreen] frame]), SKMakeSquareSize(60.0));
            remoteStateWindow = [[SKAnimatedBorderlessWindow alloc] initWithContentRect:contentRect];
            [remoteStateWindow setIgnoresMouseEvents:YES];
            [remoteStateWindow setDisplaysWhenScreenProfileChanges:NO];
            [remoteStateWindow setLevel:NSStatusWindowLevel];
            [remoteStateWindow setDefaultAlphaValue:0.95];
            [remoteStateWindow setAutoHideTimeInterval:timeInterval];
        }
        [remoteStateWindow center];
        [remoteStateWindow setBackgroundImage:[NSImage imageNamed:remoteScrolling ? SKImageNameRemoteStateScroll : SKImageNameRemoteStateResize]];
        [remoteStateWindow orderFrontRegardless];
    }
}

- (void)hidRemote:(HIDRemote *)hidRemote eventWithButton:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed fromHardwareWithAttributes:(NSMutableDictionary *)attributes {
    if (isPressed) {
        if (buttonCode == kHIDRemoteButtonCodeMenu) {
            remoteScrolling = !remoteScrolling;
            [self showRemoteSwitchIndication];
        } else {
            NSEvent *theEvent = [NSEvent otherEventWithType:NSApplicationDefined
                                                   location:NSZeroPoint
                                              modifierFlags:0
                                                  timestamp:[[NSProcessInfo processInfo] systemUptime]
                                               windowNumber:0
                                                    context:nil
                                                    subtype:SKRemoteButtonEvent
                                                      data1:buttonCode
                                                      data2:remoteScrolling];
            [NSApp postEvent:theEvent atStart:YES];
        }
    }
}

- (void)doSpotlightImportIfNeeded {
    
    // This code finds the spotlight importer and re-runs it if the importer or app version has changed since the last time we launched.
    NSArray *pathComponents = [NSArray arrayWithObjects:[[NSBundle mainBundle] bundlePath], @"Contents", @"Library", @"Spotlight", @"SkimImporter", nil];
    NSString *importerPath = [[NSString pathWithComponents:pathComponents] stringByAppendingPathExtension:@"mdimporter"];
    
    NSBundle *importerBundle = [NSBundle bundleWithPath:importerPath];
    NSString *importerVersion = [importerBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    if (importerVersion) {
        NSDictionary *versionInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKSpotlightVersionInfoKey];
        
        // getting gestaltSystemVersion breaks on 10.10, so we simulate it using the minor and bugfix version component
        SInt32 sysVersionMinor, sysVersionBugFix, sysVersion = 0;
        if (noErr == Gestalt(gestaltSystemVersionMinor, &sysVersionMinor) && noErr == Gestalt(gestaltSystemVersionBugFix, &sysVersionBugFix))
            sysVersion = 0x1000 + sysVersionMinor * 0x10 + sysVersionBugFix;
        
        BOOL runImporter = NO;
        if ([versionInfo count] == 0) {
            runImporter = YES;
        } else {
            NSString *lastImporterVersion = [versionInfo objectForKey:SKSpotlightLastImporterVersionKey];
            
            int lastSysVersion = [[versionInfo objectForKey:SKSpotlightLastSysVersionKey] intValue];
            
            runImporter = sysVersion > 0 ? ([SKVersionNumber compareVersionString:lastImporterVersion toVersionString:importerVersion] == NSOrderedAscending || sysVersion > lastSysVersion) : YES;
        }
        if (runImporter) {
            NSString *mdimportPath = @"/usr/bin/mdimport";
            if ([[NSFileManager defaultManager] isExecutableFileAtPath:mdimportPath]) {
                @try { [NSTask launchedTaskWithLaunchPath:mdimportPath arguments:[NSArray arrayWithObjects:@"-r", importerPath, nil]]; }
                @catch(id exception) {}
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:sysVersion], SKSpotlightLastSysVersionKey, importerVersion, SKSpotlightLastImporterVersionKey, nil];
                [[NSUserDefaults standardUserDefaults] setObject:info forKey:SKSpotlightVersionInfoKey];
                
            } else NSLog(@"%@ not found!", mdimportPath);
        }
    }
}

#pragma mark Scripting support

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    didCheckReopen = YES;
    
    NSString *theURLString = [[event descriptorForKeyword:keyDirectObject] stringValue];
    NSAppleEventDescriptor *errr = [event descriptorForKeyword:'errr'];
    BOOL errorReporting = errr ? [errr booleanValue] : YES;
    
    if (theURLString) {
        if ([theURLString hasPrefix:@"<"] && [theURLString hasSuffix:@">"])
            theURLString = [theURLString substringWithRange:NSMakeRange(0, [theURLString length] - 2)];
        if ([theURLString hasPrefix:@"URL:"])
            theURLString = [theURLString substringFromIndex:4];
        
        NSURL *theURL = [NSURL URLWithString:theURLString] ?: [NSURL URLWithString:[(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)theURLString, CFSTR("#%"), NULL, kCFStringEncodingUTF8) autorelease]];
        
        if ([theURL isFileURL]) {
            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:theURL display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                if (document == nil && errorReporting && error && [error isUserCancelledError] == NO)
                    [NSApp presentError:error];
            }];
        } else if ([theURL isSkimURL]) {
            if ([theURL isSkimBookmarkURL]) {
                SKBookmark *bookmark = [[SKBookmarkController sharedBookmarkController] bookmarkForURL:theURL];
                if (bookmark) {
                    [[NSDocumentController sharedDocumentController] openDocumentWithBookmark:bookmark completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                        if (document == nil && errorReporting && error && [error isUserCancelledError] == NO)
                            [NSApp presentError:error];
                    }];
                }
            } else {
                [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[theURL skimFileURL] display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                    if (document == nil && errorReporting && error && [error isUserCancelledError] == NO)
                        [NSApp presentError:error];
                }];
            }
        } else if (theURL) {
            [[SKDownloadController sharedDownloadController] addDownloadForURL:theURL];
        }
    }
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
    static NSSet *applicationScriptingKeys = nil;
    if (applicationScriptingKeys == nil)
        applicationScriptingKeys = [[NSSet alloc] initWithObjects:@"bookmarks", @"downloads", 
            @"defaultPdfViewSettings", @"defaultFullScreenPdfViewSettings", @"backgroundColor", @"fullScreenBackgroundColor", @"pageBackgroundColor", 
            @"defaultNoteColors", @"defaultLineWidths", @"defaultLineStyles", @"defaultDashPatterns", @"defaultStartLineStyle", @"defaultEndLineStyle", @"defaultFontNames", @"defaultFontSizes", @"defaultTextNoteFontColor", @"defaultAlignment", @"defaultIconType", 
            @"favoriteColors", nil];
	return [applicationScriptingKeys containsObject:key];
}

- (id)newScriptingObjectOfClass:(Class)objectClass forValueForKey:(NSString *)key withContentsValue:(id)contentsValue properties:(NSDictionary *)properties {
    if ([key isEqualToString:@"bookmarks"]) {
        return [[[SKBookmarkController sharedBookmarkController] bookmarkRoot] newScriptingObjectOfClass:objectClass forValueForKey:key withContentsValue:contentsValue properties:properties];
    } else if ([key isEqualToString:@"downloads"]) {
        NSString *urlString = [properties objectForKey:@"scriptingURL"] ?: contentsValue;
        if (urlString == nil) {
            [[NSScriptCommand currentCommand] setScriptErrorNumber:NSRequiredArgumentsMissingScriptError];
            [[NSScriptCommand currentCommand] setScriptErrorString:@"New downloads requires a URL."];
            return nil;
        } else if ([urlString isKindOfClass:[NSString class]] == NO) {
            [[NSScriptCommand currentCommand] setScriptErrorNumber:NSArgumentsWrongScriptError];
            [[NSScriptCommand currentCommand] setScriptErrorString:@"URL must be text."];
            return nil;
        } else {
            return [[SKDownload alloc] initWithURL:[NSURL URLWithString:urlString]];
        }
    } else {
        return [super newScriptingObjectOfClass:objectClass forValueForKey:key withContentsValue:contentsValue properties:properties];
    }
}

- (NSArray *)bookmarks {
    return [[[SKBookmarkController sharedBookmarkController] bookmarkRoot] bookmarks];
}

- (void)insertObject:(SKBookmark *)bookmark inBookmarksAtIndex:(NSUInteger)anIndex {
    [[[SKBookmarkController sharedBookmarkController] bookmarkRoot] insertObject:bookmark inBookmarksAtIndex:anIndex];
}

- (void)removeObjectFromBookmarksAtIndex:(NSUInteger)anIndex {
    [[[SKBookmarkController sharedBookmarkController] bookmarkRoot] removeObjectFromBookmarksAtIndex:anIndex];
}

- (NSArray *)downloads {
    return [[SKDownloadController sharedDownloadController] downloads];
}

- (void)insertObject:(SKDownload *)download inDownloadsAtIndex:(NSUInteger)anIndex {
    [[SKDownloadController sharedDownloadController] addObjectToDownloads:download];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoOpenDownloadsWindowKey])
        [[SKDownloadController sharedDownloadController] showWindow:nil];
}

- (void)removeObjectFromDownloadsAtIndex:(NSUInteger)anIndex {
    SKDownload *download = [[[SKDownloadController sharedDownloadController] downloads] objectAtIndex:anIndex];
    if ([download canRemove])
        [[SKDownloadController sharedDownloadController] removeObjectFromDownloads:download];
}

- (NSDictionary *)defaultPdfViewSettings {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey];
}

- (void)setDefaultPdfViewSettings:(NSDictionary *)settings {
    if (settings == nil)
        return;
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    [setup addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey]];
    [setup addEntriesFromDictionary:settings];
    [[NSUserDefaults standardUserDefaults] setObject:setup forKey:SKDefaultPDFDisplaySettingsKey];
}

- (NSDictionary *)defaultFullScreenPdfViewSettings {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey];
}

- (void)setDefaultFullScreenPdfViewSettings:(NSDictionary *)settings {
    if (settings == nil)
        return;
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    if ([settings count]) {
        [setup addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey]];
        [setup addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey]];
        [setup addEntriesFromDictionary:settings];
    }
    [[NSUserDefaults standardUserDefaults] setObject:setup forKey:SKDefaultFullScreenPDFDisplaySettingsKey];
}

- (NSColor *)backgroundColor {
    NSColor *backgroundColor = nil;
    if (SKHasDarkAppearance(NSApp))
        backgroundColor = [[NSUserDefaults standardUserDefaults] colorForKey:SKDarkBackgroundColorKey];
    if (backgroundColor == nil)
        backgroundColor = [[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey];
    return backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)color {
    if (SKHasDarkAppearance(NSApp))
        [[NSUserDefaults standardUserDefaults] setColor:color forKey:SKDarkBackgroundColorKey];
    else
        [[NSUserDefaults standardUserDefaults] setColor:color forKey:SKBackgroundColorKey];
}

- (NSColor *)fullScreenBackgroundColor {
    NSColor *backgroundColor = nil;
    if (SKHasDarkAppearance(NSApp))
        backgroundColor = [[NSUserDefaults standardUserDefaults] colorForKey:SKDarkFullScreenBackgroundColorKey];
    if (backgroundColor == nil)
        backgroundColor = [[NSUserDefaults standardUserDefaults] colorForKey:SKFullScreenBackgroundColorKey];
    return backgroundColor;
}

- (void)setFullScreenBackgroundColor:(NSColor *)color {
    if (SKHasDarkAppearance(NSApp))
        [[NSUserDefaults standardUserDefaults] setColor:color forKey:SKDarkFullScreenBackgroundColorKey];
    else
        [[NSUserDefaults standardUserDefaults] setColor:color forKey:SKFullScreenBackgroundColorKey];
}

- (NSColor *)pageBackgroundColor {
    return [[NSUserDefaults standardUserDefaults] colorForKey:SKPageBackgroundColorKey] ?: [NSColor whiteColor];
}

- (void)setPageBackgroundColor:(NSColor *)color {
    if ([[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace] isEqual:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]])
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:SKPageBackgroundColorKey];
    else
        [[NSUserDefaults standardUserDefaults] setColor:color forKey:SKPageBackgroundColorKey];
}

- (NSDictionary *)defaultNoteColors {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    return [NSDictionary dictionaryWithObjectsAndKeys: 
        [sud colorForKey:SKFreeTextNoteColorKey], SKNFreeTextString, 
        [sud colorForKey:SKAnchoredNoteColorKey], SKNNoteString, 
        [sud colorForKey:SKCircleNoteColorKey], SKNCircleString, 
        [sud colorForKey:SKSquareNoteColorKey], SKNSquareString, 
        [sud colorForKey:SKHighlightNoteColorKey], SKNHighlightString, 
        [sud colorForKey:SKUnderlineNoteColorKey], SKNUnderlineString, 
        [sud colorForKey:SKStrikeOutNoteColorKey], SKNStrikeOutString, 
        [sud colorForKey:SKLineNoteColorKey], SKNLineString, 
        [sud colorForKey:SKInkNoteColorKey], SKNInkString, 
        [sud colorForKey:SKCircleNoteInteriorColorKey], SKCircleInteriorString, 
        [sud colorForKey:SKSquareNoteInteriorColorKey], SKSquareInteriorString, 
        [sud colorForKey:SKLineNoteInteriorColorKey], SKLineInteriorString, 
        [sud colorForKey:SKFreeTextNoteFontColorKey], SKFreeTextFontString, 
        nil];
}

- (void)setDefaultNoteColors:(NSDictionary *)colorDict {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSColor *color;
    if ((color = [colorDict objectForKey:SKNFreeTextString]))
        [sud setColor:color forKey:SKFreeTextNoteColorKey];
    if ((color = [colorDict objectForKey:SKNNoteString]))
        [sud setColor:color forKey:SKAnchoredNoteColorKey];
    if ((color = [colorDict objectForKey:SKNCircleString]))
        [sud setColor:color forKey:SKCircleNoteColorKey];
    if ((color = [colorDict objectForKey:SKNSquareString]))
        [sud setColor:color forKey:SKSquareNoteColorKey];
    if ((color = [colorDict objectForKey:SKNHighlightString]))
        [sud setColor:color forKey:SKHighlightNoteColorKey];
    if ((color = [colorDict objectForKey:SKNUnderlineString]))
        [sud setColor:color forKey:SKUnderlineNoteColorKey];
    if ((color = [colorDict objectForKey:SKNStrikeOutString]))
        [sud setColor:color forKey:SKStrikeOutNoteColorKey];
    if ((color = [colorDict objectForKey:SKNLineString]))
        [sud setColor:color forKey:SKLineNoteColorKey];
    if ((color = [colorDict objectForKey:SKNInkString]))
        [sud setColor:color forKey:SKInkNoteColorKey];
    if ((color = [colorDict objectForKey:SKCircleInteriorString]))
        [sud setColor:color forKey:SKCircleNoteInteriorColorKey];
    if ((color = [colorDict objectForKey:SKSquareInteriorString]))
        [sud setColor:color forKey:SKSquareNoteInteriorColorKey];
    if ((color = [colorDict objectForKey:SKLineInteriorString]))
        [sud setColor:color forKey:SKLineNoteInteriorColorKey];
    if ((color = [colorDict objectForKey:SKFreeTextFontString]))
        [sud setColor:color forKey:SKFreeTextNoteFontColorKey];
}

- (NSDictionary *)defaultLineWidths {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    return [NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithDouble:[sud doubleForKey:SKFreeTextNoteLineWidthKey]], SKNFreeTextString, 
        [NSNumber numberWithDouble:[sud doubleForKey:SKCircleNoteLineWidthKey]], SKNCircleString, 
        [NSNumber numberWithDouble:[sud doubleForKey:SKSquareNoteLineWidthKey]], SKNSquareString, 
        [NSNumber numberWithDouble:[sud doubleForKey:SKLineNoteLineWidthKey]], SKNLineString, 
        [NSNumber numberWithDouble:[sud doubleForKey:SKInkNoteLineWidthKey]], SKNInkString, 
        nil];
}

- (void)setDefaultLineWidths:(NSDictionary *)dict {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSNumber *number;
    if ((number = [dict objectForKey:SKNFreeTextString]))
        [sud setDouble:[number doubleValue] forKey:SKFreeTextNoteLineWidthKey];
    if ((number = [dict objectForKey:SKNCircleString]))
        [sud setDouble:[number doubleValue] forKey:SKCircleNoteLineWidthKey];
    if ((number = [dict objectForKey:SKNSquareString]))
        [sud setDouble:[number doubleValue] forKey:SKSquareNoteLineWidthKey];
    if ((number = [dict objectForKey:SKNLineString]))
        [sud setDouble:[number doubleValue] forKey:SKLineNoteLineWidthKey];
    if ((number = [dict objectForKey:SKNInkString]))
        [sud setDouble:[number doubleValue] forKey:SKInkNoteLineWidthKey];
}

- (NSDictionary *)defaultLineStyles {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    return [NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithInteger:[sud integerForKey:SKFreeTextNoteLineStyleKey]], SKNFreeTextString, 
        [NSNumber numberWithInteger:[sud integerForKey:SKCircleNoteLineStyleKey]], SKNCircleString, 
        [NSNumber numberWithInteger:[sud integerForKey:SKSquareNoteLineStyleKey]], SKNSquareString, 
        [NSNumber numberWithInteger:[sud integerForKey:SKLineNoteLineStyleKey]], SKNLineString,
        [NSNumber numberWithInteger:[sud integerForKey:SKInkNoteLineStyleKey]], SKNInkString,
        nil];
}

- (void)setDefaultLineStyles:(NSDictionary *)dict {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSNumber *number;
    if ((number = [dict objectForKey:SKNFreeTextString]))
        [sud setInteger:[number integerValue] forKey:SKFreeTextNoteLineStyleKey];
    if ((number = [dict objectForKey:SKNCircleString]))
        [sud setInteger:[number integerValue] forKey:SKCircleNoteLineStyleKey];
    if ((number = [dict objectForKey:SKNSquareString]))
        [sud setInteger:[number integerValue] forKey:SKSquareNoteLineStyleKey];
    if ((number = [dict objectForKey:SKNLineString]))
        [sud setInteger:[number integerValue] forKey:SKLineNoteLineStyleKey];
    if ((number = [dict objectForKey:SKNInkString]))
        [sud setInteger:[number integerValue] forKey:SKInkNoteLineStyleKey];
}

- (NSDictionary *)defaultDashPatterns {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    return [NSDictionary dictionaryWithObjectsAndKeys: 
        [sud arrayForKey:SKFreeTextNoteDashPatternKey], SKNFreeTextString, 
        [sud arrayForKey:SKCircleNoteDashPatternKey], SKNCircleString, 
        [sud arrayForKey:SKSquareNoteDashPatternKey], SKNSquareString, 
        [sud arrayForKey:SKLineNoteDashPatternKey], SKNLineString,
        [sud arrayForKey:SKInkNoteDashPatternKey], SKNInkString,
        nil];
}

- (void)setDefaultDashPatterns:(NSDictionary *)dict {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSArray *array;
    if ((array = [dict objectForKey:SKNFreeTextString]))
        [sud setObject:array forKey:SKFreeTextNoteDashPatternKey];
    if ((array = [dict objectForKey:SKNCircleString]))
        [sud setObject:array forKey:SKCircleNoteDashPatternKey];
    if ((array = [dict objectForKey:SKNSquareString]))
        [sud setObject:array forKey:SKSquareNoteDashPatternKey];
    if ((array = [dict objectForKey:SKNLineString]))
        [sud setObject:array forKey:SKLineNoteDashPatternKey];
    if ((array = [dict objectForKey:SKNInkString]))
        [sud setObject:array forKey:SKInkNoteDashPatternKey];
}

- (NSDictionary *)defaultFontNames {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    return [NSDictionary dictionaryWithObjectsAndKeys: 
        [sud stringForKey:SKFreeTextNoteFontNameKey], SKNFreeTextString, 
        [sud stringForKey:SKAnchoredNoteFontNameKey], SKNNoteString, 
        nil];
}

- (void)setDefaultFontNames:(NSDictionary *)fontNameDict {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSString *fontName;
    if ((fontName = [fontNameDict objectForKey:SKNFreeTextString]))
        [sud setObject:fontName forKey:SKFreeTextNoteFontNameKey];
    if ((fontName = [fontNameDict objectForKey:SKNNoteString]))
        [sud setObject:fontName forKey:SKAnchoredNoteFontNameKey];
}

- (NSDictionary *)defaultFontSizes {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    return [NSDictionary dictionaryWithObjectsAndKeys: 
        [sud objectForKey:SKFreeTextNoteFontSizeKey], SKNFreeTextString, 
        [sud objectForKey:SKAnchoredNoteFontSizeKey], SKNNoteString, 
        nil];
}

- (void)setDefaultFontSizes:(NSDictionary *)fontSizeDict {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSNumber *fontSize;
    if ((fontSize = [fontSizeDict objectForKey:SKNFreeTextString]))
        [sud setObject:fontSize forKey:SKFreeTextNoteFontSizeKey];
    if ((fontSize = [fontSizeDict objectForKey:SKNNoteString]))
        [sud setObject:fontSize forKey:SKAnchoredNoteFontSizeKey];
}

- (NSColor *)defaultTextNoteFontColor {
    return [[NSUserDefaults standardUserDefaults] colorForKey:SKFreeTextNoteFontColorKey];
}

- (void)setDefaultTextNoteFontColor:(NSColor *)color {
    [[NSUserDefaults standardUserDefaults] setColor:color forKey:SKFreeTextNoteFontColorKey];
}

- (PDFLineStyle)defaultStartLineStyle {
    return [[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteStartLineStyleKey];
}

- (void)setDefaultStartLineStyle:(PDFLineStyle)style {
    [[NSUserDefaults standardUserDefaults] setInteger:style forKey:SKLineNoteStartLineStyleKey];
}

- (PDFLineStyle)defaultEndLineStyle {
    return [[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteEndLineStyleKey];
}

- (void)setDefaultEndLineStyle:(PDFLineStyle)style {
    [[NSUserDefaults standardUserDefaults] setInteger:style forKey:SKLineNoteEndLineStyleKey];
}

- (NSTextAlignment)defaultAlignment {
    return [[NSUserDefaults standardUserDefaults] integerForKey:SKFreeTextNoteAlignmentKey];
}

- (void)setDefaultAlignment:(NSTextAlignment)alignment {
    [[NSUserDefaults standardUserDefaults] setInteger:alignment forKey:SKFreeTextNoteAlignmentKey];
}

- (PDFTextAnnotationIconType)defaultIconType {
    return [[NSUserDefaults standardUserDefaults] integerForKey:SKAnchoredNoteIconTypeKey];
}

- (void)setDefaultIconType:(PDFTextAnnotationIconType)type {
    [[NSUserDefaults standardUserDefaults] setInteger:type forKey:SKAnchoredNoteIconTypeKey];
}

- (NSArray *)favoriteColors {
    NSValueTransformer *transformer = [NSValueTransformer arrayTransformerWithValueTransformerForName:NSUnarchiveFromDataTransformerName];
    return [transformer transformedValue:[[NSUserDefaults standardUserDefaults] arrayForKey:SKSwatchColorsKey]];
}

- (void)setFavoriteColors:(NSArray *)array {
    NSValueTransformer *transformer = [NSValueTransformer arrayTransformerWithValueTransformerForName:NSUnarchiveFromDataTransformerName];
    [[NSUserDefaults standardUserDefaults] setObject:[transformer reverseTransformedValue:array] forKey:SKSwatchColorsKey];
}

@end
