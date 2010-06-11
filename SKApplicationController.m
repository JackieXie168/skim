//
//  SKApplicationController.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2010
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
#import "BDAlias.h"
#import "SKVersionNumber.h"
#import "NSUserDefaults_SKExtensions.h"
#import <Quartz/Quartz.h>
#import <Sparkle/Sparkle.h>
#import "RemoteControl.h"
#import "AppleRemote.h"
#import "KeyspanFrontRowControl.h"
#import "GlobalKeyboardDevice.h"
#import "RemoteControlContainer.h"
#import "SKLine.h"
#import "NSImage_SKExtensions.h"
#import "SKDownloadController.h"
#import "NSURL_SKExtensions.h"
#import "SKDocumentController.h"
#import "NSDocument_SKExtensions.h"
#import "NSFileManager_SKExtensions.h"
#import "NSTask_SKExtensions.h"
#import "SKRuntime.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "PDFAnnotationLine_SKExtensions.h"
#import "PDFAnnotationText_SKExtensions.h"
#import "SKRemoteStateWindow.h"
#import "NSMenu_SKExtensions.h"
#import "SKFDFParser.h"
#import "SKLocalization.h"
#import "SKScriptMenu.h"

#define WEBSITE_URL @"http://skim-app.sourceforge.net/"
#define WIKI_URL    @"http://sourceforge.net/apps/mediawiki/skim-app/"

#define INITIAL_USER_DEFAULTS_FILENAME  @"InitialUserDefaults"
#define REGISTERED_DEFAULTS_KEY         @"RegisteredDefaults"
#define RESETTABLE_KEYS_KEY             @"ResettableKeys"

#define VIEW_MENU_INDEX      4
#define BOOKMARKS_MENU_INDEX 8

#define CURRENTDOCUMENTSETUP_KEY @"currentDocumentSetup"

#define SKIsRelaunchKey                     @"SKIsRelaunch"
#define SKSpotlightVersionInfoKey           @"SKSpotlightVersionInfo"
#define SKSpotlightLastImporterVersionKey   @"lastImporterVersion"
#define SKSpotlightLastSysVersionKey        @"lastSysVersion"

#define SUScheduledCheckIntervalKey         @"SUScheduledCheckInterval"

#define SKCircleInteriorString  @"CircleInterior"
#define SKSquareInteriorString  @"SquareInterior"
#define SKFreeTextFontString    @"FreeTextFont"

@interface SKApplicationController (SKPrivate)
- (void)doSpotlightImportIfNeeded;
@end


@implementation SKApplicationController

@dynamic defaultPdfViewSettings, defaultFullScreenPdfViewSettings, backgroundColor, fullScreenBackgroundColor, pageBackgroundColor, defaultNoteColors, defaultLineWidths, defaultLineStyles, defaultDashPatterns, defaultStartLineStyle, defaultEndLineStyle, defaultFontNames, defaultFontSizes, defaultTextNoteFontColor, defaultIconType;

+ (void)initialize{
    SKINITIALIZE;
    
    // load the default values for the user defaults
    NSString *initialUserDefaultsPath = [[NSBundle mainBundle] pathForResource:INITIAL_USER_DEFAULTS_FILENAME ofType:@"plist"];
    NSDictionary *initialUserDefaultsDict = [NSDictionary dictionaryWithContentsOfFile:initialUserDefaultsPath];
    NSDictionary *initialValuesDict = [initialUserDefaultsDict objectForKey:REGISTERED_DEFAULTS_KEY];
    NSArray *resettableUserDefaultsKeys;
    
    // set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:initialValuesDict];
    
    // if your application supports resetting a subset of the defaults to 
    // factory values, you should set those values 
    // in the shared user defaults controller
    
    resettableUserDefaultsKeys = [[[initialUserDefaultsDict objectForKey:RESETTABLE_KEYS_KEY] allValues] valueForKeyPath:@"@unionOfArrays.self"];
    initialValuesDict = [initialValuesDict dictionaryWithValuesForKeys:resettableUserDefaultsKeys];
    
    // Set the initial values in the shared user defaults controller 
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
}

- (void)awakeFromNib {
    [[NSApp mainMenu] localizeStringsFromTable:@"MainMenu"];
    
    NSMenu *viewMenu = [[[NSApp mainMenu] itemAtIndex:VIEW_MENU_INDEX] submenu];
    NSInteger i, count = [viewMenu numberOfItems];
    
    for (i = 0; i < count; i++) {
        NSMenuItem *menuItem = [viewMenu itemAtIndex:i];
        if ([menuItem action] == @selector(changeLeftSidePaneState:) || [menuItem action] == @selector(changeRightSidePaneState:)) 
            [menuItem setIndentationLevel:1];
    }
    
    [[[NSApp mainMenu] itemAtIndex:BOOKMARKS_MENU_INDEX] setRepresentedObject:[[SKBookmarkController sharedBookmarkController] bookmarkRoot]];
    
    // this creates the script menu if needed
    (void)[NSApp scriptMenu];
    
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
}

- (void)registerCurrentDocuments:(NSNotification *)aNotification {
    [[NSUserDefaults standardUserDefaults] setObject:[[(SKApplication *)NSApp orderedDocuments] valueForKey:CURRENTDOCUMENTSETUP_KEY] forKey:SKLastOpenFileNamesKey];
    [[[NSDocumentController sharedDocumentController] documents] makeObjectsPerformSelector:@selector(saveRecentDocumentInfo)];
}

#pragma mark NSApplication delegate

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKReopenLastOpenFilesKey] || [[NSUserDefaults standardUserDefaults] boolForKey:SKIsRelaunchKey]) {
        NSArray *files = [[NSUserDefaults standardUserDefaults] objectForKey:SKLastOpenFileNamesKey];
        NSEnumerator *fileEnum = [files reverseObjectEnumerator];
        NSDictionary *dict;
        NSError *error;
        
        while (dict = [fileEnum nextObject]) {
            error = nil;
            if (nil == [[NSDocumentController sharedDocumentController] openDocumentWithSetup:dict error:&error] && error)
                [NSApp presentError:error];
        }
    }
    
    return NO;
}    

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    [NSImage makeImages];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    
    [sud removeObjectForKey:SKIsRelaunchKey];
    
    [NSApp setServicesProvider:self];
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    NSString *lastVersionString = [sud stringForKey:SKLastVersionLaunchedKey];
    if (lastVersionString == nil || [SKVersionNumber compareVersionString:lastVersionString toVersionString:versionString] == NSOrderedAscending) {
        [self showReleaseNotes:nil];
        [sud setObject:versionString forKey:SKLastVersionLaunchedKey];
    }
	
    [self doSpotlightImportIfNeeded];
    
    remoteControl = [[RemoteControlContainer alloc] initWithDelegate:self];
    if ([sud boolForKey:SKEnableAppleRemoteKey])
        [remoteControl instantiateAndAddRemoteControlDeviceWithClass:[AppleRemote class]];	
    if ([sud boolForKey:SKEnableKeyspanFrontRowControlKey])
        [remoteControl instantiateAndAddRemoteControlDeviceWithClass:[KeyspanFrontRowControl class]];
    if ([sud boolForKey:SKEnableKeyboardRemoteSimulationKey])
        [remoteControl instantiateAndAddRemoteControlDeviceWithClass:[GlobalKeyboardDevice class]];	
    if ([remoteControl count] == 0)
        SKDESTROY(remoteControl);
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(registerCurrentDocuments:) 
                             name:SKDocumentDidShowNotification object:nil];
    [nc addObserver:self selector:@selector(registerCurrentDocuments:) 
                             name:SKDocumentControllerDidRemoveDocumentNotification object:nil];
    [self registerCurrentDocuments:nil];
}

// we don't want to reopen last open files when re-activating the app
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    return flag;
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    [remoteControl startListening:self];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
	[remoteControl stopListening:self];
}

- (void)applicationStartsTerminating:(NSNotification *)aNotification {
    [self registerCurrentDocuments:aNotification];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:SKDocumentDidShowNotification object:nil];
    [nc removeObserver:self name:SKDocumentControllerDidRemoveDocumentNotification object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [remoteControl setListeningToRemote:NO];
    SKDESTROY(remoteControl);
}

#pragma mark Updater

- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater *)updater {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:SUScheduledCheckIntervalKey]) {
        // the user already used an older version of Skim and Sparkle
        [updater setAutomaticallyChecksForUpdates:[[NSUserDefaults standardUserDefaults] integerForKey:SUScheduledCheckIntervalKey] > 0];
        return NO;
    }
    return YES;
}

- (void)updaterWillRelaunchApplication:(SUUpdater *)updater {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SKIsRelaunchKey];
}

#pragma mark Services Support

- (void)openDocumentFromURLOnPboard:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)errorString {
    NSError *error;
    id document = [[NSDocumentController sharedDocumentController] openDocumentWithURLFromPasteboard:pboard error:&error];
    
    if (document == nil && errorString)
        *errorString = [error localizedDescription];
}

- (void)openDocumentFromDataOnPboard:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)errorString {
    NSError *error;
    id document = [[NSDocumentController sharedDocumentController] openDocumentWithImageFromPasteboard:pboard error:&error];
    
    if (document == nil && errorString)
        *errorString = [error localizedDescription];
}

#pragma mark Actions

- (IBAction)orderFrontLineInspector:(id)sender {
    if ([SKLineInspector sharedLineInspectorExists] && [[[SKLineInspector sharedLineInspector] window] isVisible])
        [[[SKLineInspector sharedLineInspector] window] orderOut:sender];
    else
        [[[SKLineInspector sharedLineInspector] window] orderFront:sender];
}

- (IBAction)orderFrontNotesPanel:(id)sender {
    if ([SKNotesPanelController sharedControllerExists] && [[[SKNotesPanelController sharedController] window] isVisible])
        [[[SKNotesPanelController sharedController] window] orderOut:sender];
    else
        [[[SKNotesPanelController sharedController] window] orderFront:sender];
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

- (IBAction)editBookmarks:(id)sender {
    [[SKBookmarkController sharedBookmarkController] showWindow:self];
}

- (IBAction)openBookmarkAction:(id)sender {
    [[SKBookmarkController sharedBookmarkController] openBookmark:[sender representedObject]];
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
            [menuItem setTitle:NSLocalizedString(@"Hide Notes", @"Menu item title")];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Notes", @"Menu item title")];
        return YES;
    }
    return YES;
}

#pragma mark Support

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSMenu *supermenu = [menu supermenu];
    NSInteger idx = [supermenu indexOfItemWithSubmenu:menu]; 
    SKBookmark *bm = idx == -1 ? nil : [[supermenu itemAtIndex:idx] representedObject];
    NSMenuItem *item;
    
    if ([bm isKindOfClass:[SKBookmark class]]) {
        NSArray *bookmarks = [bm children];
        NSInteger i = [menu numberOfItems];
        while (i-- > 0 && ([[menu itemAtIndex:i] isSeparatorItem] || [[menu itemAtIndex:i] representedObject]))
            [menu removeItemAtIndex:i];
        if ([menu numberOfItems] > 0 && [bookmarks count] > 0)
            [menu addItem:[NSMenuItem separatorItem]];
        for (bm in bookmarks) {
            switch ([bm bookmarkType]) {
                case SKBookmarkTypeFolder:
                    item = [menu addItemWithTitle:[bm label] submenu:[[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:[bm label]] autorelease]];
                    [item setRepresentedObject:bm];
                    [item setImageAndSize:[bm icon]];
                    [[item submenu] setDelegate:self];
                    break;
                case SKBookmarkTypeSeparator:
                    [menu addItem:[NSMenuItem separatorItem]];
                    break;
                default:
                    item = [menu addItemWithTitle:[bm label] action:@selector(openBookmarkAction:) target:self];
                    [item setRepresentedObject:bm];
                    [item setImageAndSize:[bm icon]];
                    break;
            }
        }
    }
}

- (void)sendRemoteButtonEvent:(RemoteControlEventIdentifier)event pressedDown:(BOOL)pressedDown remoteControl:(RemoteControl *)remoteControl {
    if (pressedDown) {
        if (event == kRemoteButtonMenu) {
            remoteScrolling = !remoteScrolling;
            if ([[NSUserDefaults standardUserDefaults] floatForKey:SKAppleRemoteSwitchIndicationTimeoutKey] > 0.0) {
                NSRect rect = [[NSScreen mainScreen] frame];
                NSPoint point = NSMakePoint(NSMidX(rect), NSMidY(rect));
                NSInteger type = remoteScrolling ? SKRemoteStateScroll : SKRemoteStateResize;
                [SKRemoteStateWindow showWithType:type atPoint:point];
            }
        } else {
            NSEvent *theEvent = [NSEvent otherEventWithType:NSApplicationDefined
                                                   location:NSZeroPoint
                                              modifierFlags:0
                                                  timestamp:GetCurrentEventTime()
                                               windowNumber:0
                                                    context:nil
                                                    subtype:SKRemoteButtonEvent
                                                      data1:event
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
        
        SInt32 sysVersion;
        OSStatus err = Gestalt(gestaltSystemVersion, &sysVersion);
        
        BOOL runImporter = NO;
        if ([versionInfo count] == 0) {
            runImporter = YES;
        } else {
            NSString *lastImporterVersion = [versionInfo objectForKey:SKSpotlightLastImporterVersionKey];
            
            SInt32 lastSysVersion = [[versionInfo objectForKey:SKSpotlightLastSysVersionKey] intValue];
            
            runImporter = noErr == err ? ([SKVersionNumber compareVersionString:lastImporterVersion toVersionString:importerVersion] == NSOrderedAscending || sysVersion > lastSysVersion) : YES;
        }
        if (runImporter) {
            NSString *mdimportPath = @"/usr/bin/mdimport";
            if ([[NSFileManager defaultManager] isExecutableFileAtPath:mdimportPath]) {
                [NSTask launchedTaskWithLaunchPath:mdimportPath arguments:[NSArray arrayWithObjects:@"-r", importerPath, nil]];
                
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:sysVersion], SKSpotlightLastSysVersionKey, importerVersion, SKSpotlightLastImporterVersionKey, nil];
                [[NSUserDefaults standardUserDefaults] setObject:info forKey:SKSpotlightVersionInfoKey];
                
            } else NSLog(@"%@ not found!", mdimportPath);
        }
    }
}

#pragma mark Scripting support

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
    static NSSet *applicationScriptingKeys = nil;
    if (applicationScriptingKeys == nil)
        applicationScriptingKeys = [[NSSet alloc] initWithObjects:@"defaultPdfViewSettings", @"defaultFullScreenPdfViewSettings", @"backgroundColor", @"fullScreenBackgroundColor", @"pageBackgroundColor", 
            @"defaultNoteColors", @"defaultLineWidths", @"defaultLineStyles", @"defaultDashPatterns", @"defaultStartLineStyle", @"defaultEndLineStyle", @"defaultFontNames", @"defaultFontSizes", @"defaultTextNoteFontColor", @"defaultIconType", nil];
	return [applicationScriptingKeys containsObject:key];
}

- (NSDictionary *)defaultPdfViewSettings {
    return SKScriptingPDFViewSettingsFromPDFViewSettings([[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey]);
}

- (void)setDefaultPdfViewSettings:(NSDictionary *)settings {
    if (settings == nil)
        return;
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    [setup addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey]];
    [setup addEntriesFromDictionary:SKPDFViewSettingsFromScriptingPDFViewSettings(settings)];
    [[NSUserDefaults standardUserDefaults] setObject:setup forKey:SKDefaultPDFDisplaySettingsKey];
}

- (NSDictionary *)defaultFullScreenPdfViewSettings {
    return SKScriptingPDFViewSettingsFromPDFViewSettings([[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey]);
}

- (void)setDefaultFullScreenPdfViewSettings:(NSDictionary *)settings {
    if (settings == nil)
        return;
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    if ([settings count]) {
        [setup addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey]];
        [setup addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey]];
        [setup addEntriesFromDictionary:SKPDFViewSettingsFromScriptingPDFViewSettings(settings)];
    }
    [[NSUserDefaults standardUserDefaults] setObject:setup forKey:SKDefaultFullScreenPDFDisplaySettingsKey];
}

- (NSColor *)backgroundColor {
    return [[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey];
}

- (void)setBackgroundColor:(NSColor *)color {
    [[NSUserDefaults standardUserDefaults] setColor:color forKey:SKBackgroundColorKey];
}

- (NSColor *)fullScreenBackgroundColor {
    return [[NSUserDefaults standardUserDefaults] colorForKey:SKFullScreenBackgroundColorKey];
}

- (void)setFullScreenBackgroundColor:(NSColor *)color {
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
        [sud colorForKey:SKFreeTextNoteFontColorKey], SKFreeTextFontString, 
        nil];
}

- (void)setDefaultNoteColors:(NSDictionary *)colorDict {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSColor *color;
    if (color = [colorDict objectForKey:SKNFreeTextString])
        [sud setColor:color forKey:SKFreeTextNoteColorKey];
    if (color = [colorDict objectForKey:SKNNoteString])
        [sud setColor:color forKey:SKAnchoredNoteColorKey];
    if (color = [colorDict objectForKey:SKNCircleString])
        [sud setColor:color forKey:SKCircleNoteColorKey];
    if (color = [colorDict objectForKey:SKNSquareString])
        [sud setColor:color forKey:SKSquareNoteColorKey];
    if (color = [colorDict objectForKey:SKNHighlightString])
        [sud setColor:color forKey:SKHighlightNoteColorKey];
    if (color = [colorDict objectForKey:SKNUnderlineString])
        [sud setColor:color forKey:SKUnderlineNoteColorKey];
    if (color = [colorDict objectForKey:SKNStrikeOutString])
        [sud setColor:color forKey:SKStrikeOutNoteColorKey];
    if (color = [colorDict objectForKey:SKNLineString])
        [sud setColor:color forKey:SKLineNoteColorKey];
    if (color = [colorDict objectForKey:SKNInkString])
        [sud setColor:color forKey:SKInkNoteColorKey];
    if (color = [colorDict objectForKey:SKCircleInteriorString])
        [sud setColor:color forKey:SKCircleNoteInteriorColorKey];
    if (color = [colorDict objectForKey:SKSquareInteriorString])
        [sud setColor:color forKey:SKSquareNoteInteriorColorKey];
    if (color = [colorDict objectForKey:SKFreeTextFontString])
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
    if (number = [dict objectForKey:SKNFreeTextString])
        [sud setDouble:[number doubleValue] forKey:SKFreeTextNoteLineWidthKey];
    if (number = [dict objectForKey:SKNCircleString])
        [sud setDouble:[number doubleValue] forKey:SKCircleNoteLineWidthKey];
    if (number = [dict objectForKey:SKNSquareString])
        [sud setDouble:[number doubleValue] forKey:SKSquareNoteLineWidthKey];
    if (number = [dict objectForKey:SKNLineString])
        [sud setDouble:[number doubleValue] forKey:SKLineNoteLineWidthKey];
    if (number = [dict objectForKey:SKNInkString])
        [sud setDouble:[number doubleValue] forKey:SKInkNoteLineWidthKey];
}

- (NSDictionary *)defaultLineStyles {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    return [NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithUnsignedInt:SKScriptingBorderStyleFromBorderStyle([sud integerForKey:SKFreeTextNoteLineStyleKey])], SKNFreeTextString, 
        [NSNumber numberWithUnsignedInt:SKScriptingBorderStyleFromBorderStyle([sud integerForKey:SKCircleNoteLineStyleKey])], SKNCircleString, 
        [NSNumber numberWithUnsignedInt:SKScriptingBorderStyleFromBorderStyle([sud integerForKey:SKSquareNoteLineStyleKey])], SKNSquareString, 
        [NSNumber numberWithUnsignedInt:SKScriptingBorderStyleFromBorderStyle([sud integerForKey:SKLineNoteLineStyleKey])], SKNLineString,
        [NSNumber numberWithUnsignedInt:SKScriptingBorderStyleFromBorderStyle([sud integerForKey:SKInkNoteLineStyleKey])], SKNInkString,
        nil];
}

- (void)setDefaultLineStyles:(NSDictionary *)dict {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSNumber *number;
    if (number = [dict objectForKey:SKNFreeTextString])
        [sud setInteger:SKBorderStyleFromScriptingBorderStyle([number unsignedIntValue]) forKey:SKFreeTextNoteLineStyleKey];
    if (number = [dict objectForKey:SKNCircleString])
        [sud setInteger:SKBorderStyleFromScriptingBorderStyle([number unsignedIntValue]) forKey:SKCircleNoteLineStyleKey];
    if (number = [dict objectForKey:SKNSquareString])
        [sud setInteger:SKBorderStyleFromScriptingBorderStyle([number unsignedIntValue]) forKey:SKSquareNoteLineStyleKey];
    if (number = [dict objectForKey:SKNLineString])
        [sud setInteger:SKBorderStyleFromScriptingBorderStyle([number unsignedIntValue]) forKey:SKLineNoteLineStyleKey];
    if (number = [dict objectForKey:SKNInkString])
        [sud setInteger:SKBorderStyleFromScriptingBorderStyle([number unsignedIntValue]) forKey:SKInkNoteLineStyleKey];
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
    if (array = [dict objectForKey:SKNFreeTextString])
        [sud setObject:array forKey:SKFreeTextNoteDashPatternKey];
    if (array = [dict objectForKey:SKNCircleString])
        [sud setObject:array forKey:SKCircleNoteDashPatternKey];
    if (array = [dict objectForKey:SKNSquareString])
        [sud setObject:array forKey:SKSquareNoteDashPatternKey];
    if (array = [dict objectForKey:SKNLineString])
        [sud setObject:array forKey:SKLineNoteDashPatternKey];
    if (array = [dict objectForKey:SKNInkString])
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
    if (fontName = [fontNameDict objectForKey:SKNFreeTextString])
        [sud setObject:fontName forKey:SKFreeTextNoteFontNameKey];
    if (fontName = [fontNameDict objectForKey:SKNNoteString])
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
    if (fontSize = [fontSizeDict objectForKey:SKNFreeTextString])
        [sud setObject:fontSize forKey:SKFreeTextNoteFontSizeKey];
    if (fontSize = [fontSizeDict objectForKey:SKNNoteString])
        [sud setObject:fontSize forKey:SKAnchoredNoteFontSizeKey];
}

- (NSColor *)defaultTextNoteFontColor {
    return [[NSUserDefaults standardUserDefaults] colorForKey:SKFreeTextNoteFontColorKey];
}

- (void)setDefaultTextNoteFontColor:(NSColor *)color {
    [[NSUserDefaults standardUserDefaults] setColor:color forKey:SKFreeTextNoteFontColorKey];
}

- (FourCharCode)defaultStartLineStyle {
    return SKScriptingLineStyleFromLineStyle([[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteStartLineStyleKey]);
}

- (void)setDefaultStartLineStyle:(FourCharCode)style {
    [[NSUserDefaults standardUserDefaults] setInteger:SKLineStyleFromScriptingLineStyle(style) forKey:SKLineNoteStartLineStyleKey];
}

- (FourCharCode)defaultEndLineStyle {
    return SKScriptingLineStyleFromLineStyle([[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteEndLineStyleKey]);
}

- (void)setDefaultEndLineStyle:(FourCharCode)style {
    [[NSUserDefaults standardUserDefaults] setInteger:SKLineStyleFromScriptingLineStyle(style) forKey:SKLineNoteEndLineStyleKey];
}

- (FourCharCode)defaultIconType {
    return SKScriptingIconTypeFromIconType([[NSUserDefaults standardUserDefaults] integerForKey:SKAnchoredNoteIconTypeKey]);
}

- (void)setDefaultIconType:(FourCharCode)type {
    [[NSUserDefaults standardUserDefaults] setInteger:SKIconTypeFromScriptingIconType(type) forKey:SKAnchoredNoteIconTypeKey];
}

@end
