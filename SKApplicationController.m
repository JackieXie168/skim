//
//  SKApplicationController.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2008
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
#import "SKLineInspector.h"
#import "SKNotesPanelController.h"
#import "SKPreferenceController.h"
#import "SKReleaseNotesController.h"
#import "SKStringConstants.h"
#import "SKPDFDocument.h"
#import "SKMainWindowController.h"
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
#import "Files_SKExtensions.h"
#import "NSTask_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "SKUtilities.h"
#import <SkimNotes/PDFAnnotation_SKNExtensions.h>
#import "PDFAnnotation_SKExtensions.h"
#import "PDFAnnotationLine_SKExtensions.h"
#import "PDFAnnotationText_SKExtensions.h"
#import "SKRemoteStateWindow.h"
#import "NSMenu_SKExtensions.h"

#define WEBSITE_URL @"http://skim-app.sourceforge.net/"
#define WIKI_URL    @"http://skim-app.sourceforge.net/wiki/"

#define INITIAL_USER_DEFAULTS_FILENAME  @"InitialUserDefaults"
#define REGISTERED_DEFAULTS_KEY         @"RegisteredDefaults"
#define RESETTABLE_KEYS_KEY             @"ResettableKeys"

#define FILE_MENU_INDEX 1
#define VIEW_MENU_INDEX 4
#define BOOKMARKS_MENU_INDEX 8

NSString *SKDocumentSetupAliasKey = @"_BDAlias";
NSString *SKDocumentSetupFileNameKey = @"fileName";

static NSString *SKSpotlightVersionInfoKey = @"SKSpotlightVersionInfo";

@implementation SKApplicationController

+ (void)initialize{
    OBINITIALIZE;
    
    [self setupDefaults];
}
   
+ (void)setupDefaults{
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
    NSMenu *viewMenu = [[[NSApp mainMenu] itemAtIndex:VIEW_MENU_INDEX] submenu];
    int i, count = [viewMenu numberOfItems];
    
    for (i = 0; i < count; i++) {
        NSMenuItem *menuItem = [viewMenu itemAtIndex:i];
        if ([menuItem action] == @selector(changeLeftSidePaneState:) || [menuItem action] == @selector(changeRightSidePaneState:)) 
            [menuItem setIndentationLevel:1];
    }
    
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4) {
        NSMenu *fileMenu = [[[NSApp mainMenu] itemAtIndex:FILE_MENU_INDEX] submenu];
        unsigned int idx = [fileMenu indexOfItemWithTarget:nil andAction:@selector(runPageLayout:)];
        if (idx != NSNotFound)
            [fileMenu removeItemAtIndex:idx];
    }
    
    [[[NSApp mainMenu] itemAtIndex:BOOKMARKS_MENU_INDEX] setRepresentedObject:[[SKBookmarkController sharedBookmarkController] bookmarkRoot]];
    
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
}

#pragma mark NSApplication delegate

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKReopenLastOpenFilesKey]) {
        NSArray *files = [[NSUserDefaults standardUserDefaults] objectForKey:SKLastOpenFileNamesKey];
        NSEnumerator *fileEnum = [files objectEnumerator];
        NSDictionary *dict;
        NSURL *fileURL = nil;
        SKPDFDocument *document;
        NSError *error;
        
        while (dict = [fileEnum nextObject]){ 
            fileURL = [[BDAlias aliasWithData:[dict objectForKey:SKDocumentSetupAliasKey]] fileURL];
            if(fileURL == nil && [dict objectForKey:SKDocumentSetupFileNameKey])
                fileURL = [NSURL fileURLWithPath:[dict objectForKey:SKDocumentSetupFileNameKey]];
            if(fileURL && NO == SKFileIsInTrash(fileURL)) {
                if (document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:NO error:&error]) {
                    [document makeWindowControllers];
                    if ([document respondsToSelector:@selector(mainWindowController)])
                        [[document mainWindowController] setInitialSetup:dict];
                    [document showWindows];
                } else {
                    [NSApp presentError:error];
                }
            }
        }
    }
    
    return NO;
}    

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    [NSImage makeAdornImages];
    [NSImage makeToolbarImages];
    [NSImage makeCursorImages];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    [NSApp setServicesProvider:self];
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    SKVersionNumber *versionNumber = versionString ? [[[SKVersionNumber alloc] initWithVersionString:versionString] autorelease] : nil;
    NSString *lastVersionString = [[NSUserDefaults standardUserDefaults] stringForKey:SKLastVersionLaunchedKey];
    SKVersionNumber *lastVersionNumber = lastVersionString ? [[[SKVersionNumber alloc] initWithVersionString:lastVersionString] autorelease] : nil;
    if(lastVersionNumber == nil || [lastVersionNumber compareToVersionNumber:versionNumber] == NSOrderedAscending) {
        [self showReleaseNotes:nil];
        [[NSUserDefaults standardUserDefaults] setObject:versionString forKey:SKLastVersionLaunchedKey];
    }
	
    [self doSpotlightImportIfNeeded];
    
    currentDocumentsTimer = [[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(saveCurrentOpenDocuments:) userInfo:nil repeats:YES] retain];
    
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    RemoteControlContainer *container = [[RemoteControlContainer alloc] initWithDelegate:self];
    if ([sud boolForKey:SKEnableAppleRemoteKey])
        [container instantiateAndAddRemoteControlDeviceWithClass:[AppleRemote class]];	
    if ([sud boolForKey:SKEnableKeyspanFrontRowControlKey])
        [container instantiateAndAddRemoteControlDeviceWithClass:[KeyspanFrontRowControl class]];
    if ([sud boolForKey:SKEnableKeyboardRemoteSimulationKey])
        [container instantiateAndAddRemoteControlDeviceWithClass:[GlobalKeyboardDevice class]];	
    remoteControl = container;
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
    [remoteControl startListening:self];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
	[remoteControl stopListening:self];
}

- (void)applicationStartsTerminating:(NSNotification *)aNotification {
    [currentDocumentsTimer invalidate];
    [currentDocumentsTimer release];
    currentDocumentsTimer = nil;
    [self saveCurrentOpenDocuments:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:SKEnableAppleRemoteKey]) {
        [remoteControl setListeningToRemote:NO];
        [remoteControl release];
        remoteControl = nil;
    }
}

#pragma mark Services Support

- (void)openDocumentFromURLOnPboard:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
    NSError *outError;
    id document = [[NSDocumentController sharedDocumentController] openDocumentWithURLFromPasteboard:pboard error:&outError];
    
    if (document == nil && outError && error)
        *error = [outError localizedDescription];
}

- (void)openDocumentFromDataOnPboard:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
    NSError *outError;
    id document = [[NSDocumentController sharedDocumentController] openDocumentWithImageFromPasteboard:pboard error:&outError];
    
    if (document == nil && outError && error)
        *error = [outError localizedDescription];
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

- (IBAction)openBookmark:(id)sender {
    SKBookmark *bookmark = [sender representedObject];
    [[SKBookmarkController sharedBookmarkController] openBookmarks:[NSArray arrayWithObjects:bookmark, nil]];
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
    NSMenuItem *item = [menu supermenuItem];
    SKBookmark *bm = [item representedObject];
    
    if ([bm isKindOfClass:[SKBookmark class]]) {
        NSArray *bookmarks = [bm children];
        int i = [menu numberOfItems], numBookmarks = [bookmarks count];
        while (i-- > 0 && ([[menu itemAtIndex:i] isSeparatorItem] || [[menu itemAtIndex:i] representedObject]))
            [menu removeItemAtIndex:i];
        if ([menu numberOfItems] > 0 && numBookmarks > 0)
            [menu addItem:[NSMenuItem separatorItem]];
        for (i = 0; i < numBookmarks; i++) {
            bm = [bookmarks objectAtIndex:i];
            switch ([bm bookmarkType]) {
                case SKBookmarkTypeFolder:
                    item = [menu addItemWithTitle:[bm label] submenu:[[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:[bm label]] autorelease]];
                    [item setRepresentedObject:bm];
                    [item setImage:[bm icon]];
                    [[item submenu] setDelegate:self];
                    break;
                case SKBookmarkTypeSeparator:
                    [menu addItem:[NSMenuItem separatorItem]];
                    break;
                default:
                    item = [menu addItemWithTitle:[bm label] action:@selector(openBookmark:) target:self];
                    [item setRepresentedObject:bm];
                    [item setImage:[bm icon]];
                    break;
            }
        }
    }
}

- (void)sendRemoteButtonEvent:(RemoteControlEventIdentifier)event pressedDown:(BOOL)pressedDown remoteControl:(RemoteControl *)remoteControl {
    NSArray *docs = [NSApp orderedDocuments];
    id document = [docs count] ? [docs objectAtIndex:0] : nil;
    SKMainWindowController *controller = [document respondsToSelector:@selector(mainWindowController)]? [document mainWindowController] : nil;
    
    if (controller == nil || pressedDown == NO)
        return;
    
    switch (event) {
        case kRemoteButtonPlus:
            if (remoteScrolling)
                [[[controller pdfView] documentView] scrollLineUp];
            else if ([controller isPresentation])
                [controller doAutoScale:nil];
            else
                [controller doZoomIn:nil];
            break;
        case kRemoteButtonMinus:
            if (remoteScrolling)
                [[[controller pdfView] documentView] scrollLineDown];
            else if ([controller isPresentation])
                [controller doZoomToActualSize:nil];
            else
                [controller doZoomOut:nil];
            break;
        case kRemoteButtonRight_Hold:
        case kRemoteButtonRight:
            if (remoteScrolling)
                [[[controller pdfView] documentView] scrollLineRight];
            else 
                [controller doGoToNextPage:nil];
            break;
        case kRemoteButtonLeft_Hold:
        case kRemoteButtonLeft:
            if (remoteScrolling)
                [[[controller pdfView] documentView] scrollLineLeft];
            else 
                [controller doGoToPreviousPage:nil];
            break;
        case kRemoteButtonPlay:
            [controller togglePresentation:nil];
            break;
		case kRemoteButtonMenu:
            remoteScrolling = !remoteScrolling;
            if ([[NSUserDefaults standardUserDefaults] floatForKey:SKAppleRemoteSwitchIndicationTimeoutKey] > 0.0) {
                NSRect rect = [[controller window] frame];
                NSPoint point = NSMakePoint(NSMidX(rect), NSMidY(rect));
                int type = remoteScrolling ? SKRemoteStateScroll : SKRemoteStateResize;
                [SKRemoteStateWindow showWithType:type atPoint:point];
            }
            break;
        default:
            break;
    }
}

- (void)doSpotlightImportIfNeeded {
    
    // This code finds the spotlight importer and re-runs it if the importer or app version has changed since the last time we launched.
    NSArray *pathComponents = [NSArray arrayWithObjects:[[NSBundle mainBundle] bundlePath], @"Contents", @"Library", @"Spotlight", @"SkimImporter", nil];
    NSString *importerPath = [[NSString pathWithComponents:pathComponents] stringByAppendingPathExtension:@"mdimporter"];
    
    NSBundle *importerBundle = [NSBundle bundleWithPath:importerPath];
    NSString *importerVersion = [importerBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    if (importerVersion) {
        SKVersionNumber *importerVersionNumber = [[[SKVersionNumber alloc] initWithVersionString:importerVersion] autorelease];
        NSDictionary *versionInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SKSpotlightVersionInfoKey];
        
        long sysVersion;
        OSStatus err = Gestalt(gestaltSystemVersion, &sysVersion);
        
        BOOL runImporter = NO;
        if ([versionInfo count] == 0) {
            runImporter = YES;
        } else {
            NSString *lastImporterVersion = [versionInfo objectForKey:@"lastImporterVersion"];
            SKVersionNumber *lastImporterVersionNumber = [[[SKVersionNumber alloc] initWithVersionString:lastImporterVersion] autorelease];
            
            long lastSysVersion = [[versionInfo objectForKey:@"lastSysVersion"] longValue];
            
            runImporter = noErr == err ? ([lastImporterVersionNumber compareToVersionNumber:importerVersionNumber] == NSOrderedAscending || sysVersion > lastSysVersion) : YES;
        }
        if (runImporter) {
            NSString *mdimportPath = @"/usr/bin/mdimport";
            if ([[NSFileManager defaultManager] isExecutableFileAtPath:mdimportPath]) {
                [NSTask launchedTaskWithLaunchPath:mdimportPath arguments:[NSArray arrayWithObjects:@"-r", importerPath, nil]];
                
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:sysVersion], @"lastSysVersion", importerVersion, @"lastImporterVersion", nil];
                [[NSUserDefaults standardUserDefaults] setObject:info forKey:@"SKSpotlightVersionInfo"];
                
            } else NSLog(@"%@ not found!", mdimportPath);
        }
    }
}

- (void)saveCurrentOpenDocuments:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[[[NSDocumentController sharedDocumentController] documents] valueForKey:@"currentDocumentSetup"] forKey:SKLastOpenFileNamesKey];
    [[[NSDocumentController sharedDocumentController] documents] makeObjectsPerformSelector:@selector(saveRecentDocumentInfo)];
}

- (NSArray *)applicationSupportDirectories {
    static NSArray *applicationSupportDirectories = nil;
    if (applicationSupportDirectories == nil) {
        NSMutableArray *pathArray = [NSMutableArray array];
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        NSEnumerator *pathEnum = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSAllDomainsMask, YES) objectEnumerator];
        NSString *path;
        while (path = [pathEnum nextObject])
            [pathArray addObject:[path stringByAppendingPathComponent:appName]];
        applicationSupportDirectories = [pathArray copy];
    }
    return applicationSupportDirectories;
}

- (NSString *)pathForApplicationSupportFile:(NSString *)file ofType:(NSString *)extension {
    return [self pathForApplicationSupportFile:file ofType:extension inDirectory:nil];
}

- (NSString *)pathForApplicationSupportFile:(NSString *)file ofType:(NSString *)extension inDirectory:(NSString *)subpath {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *filename = [file stringByAppendingPathExtension:extension];
    NSString *fullPath = nil;
    NSEnumerator *pathEnum = [[[self applicationSupportDirectories] arrayByAddingObject:[[NSBundle mainBundle] sharedSupportPath]] objectEnumerator];
    NSString *appSupportPath = nil;
    
    while (appSupportPath = [pathEnum nextObject]) {
        fullPath = subpath ? [appSupportPath stringByAppendingPathComponent:subpath] : appSupportPath;
        fullPath = [fullPath stringByAppendingPathComponent:filename];
        if ([fm fileExistsAtPath:fullPath] == NO)
            fullPath = nil;
        else break;
    }
    
    return fullPath;
}

#pragma mark Scripting support

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
    static NSSet *applicationScriptingKeys = nil;
    if (applicationScriptingKeys == nil)
        applicationScriptingKeys = [[NSSet alloc] initWithObjects:@"defaultPdfViewSettings", @"defaultFullScreenPdfViewSettings", @"backgroundColor", @"fullScreenBackgroundColor", 
            @"defaultNoteColors", @"defaultLineWidths", @"defaultLineStyles", @"defaultDashPatterns", @"defaultStartLineStyle", @"defaultEndLineStyle", @"defaultIconType", @"lines", nil];
	return [applicationScriptingKeys containsObject:key];
}

- (NSDictionary *)defaultPdfViewSettings {
    return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey] AppleScriptPDFViewSettingsFromPDFViewSettings];
}

- (void)setDefaultPdfViewSettings:(NSDictionary *)settings {
    if (settings == nil)
        return;
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    [setup addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey]];
    [setup addEntriesFromDictionary:[settings PDFViewSettingsFromAppleScriptPDFViewSettings]];
    [[NSUserDefaults standardUserDefaults] setObject:setup forKey:SKDefaultPDFDisplaySettingsKey];
}

- (NSDictionary *)defaultFullScreenPdfViewSettings {
    return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey] AppleScriptPDFViewSettingsFromPDFViewSettings];
}

- (void)setDefaultFullScreenPdfViewSettings:(NSDictionary *)settings {
    if (settings == nil)
        return;
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    if ([settings count]) {
        [setup addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultPDFDisplaySettingsKey]];
        [setup addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:SKDefaultFullScreenPDFDisplaySettingsKey]];
        [setup addEntriesFromDictionary:[settings PDFViewSettingsFromAppleScriptPDFViewSettings]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:setup forKey:SKDefaultFullScreenPDFDisplaySettingsKey];
}

- (NSColor *)backgroundColor {
    return [[NSUserDefaults standardUserDefaults] colorForKey:SKBackgroundColorKey];
}

- (void)setBackgroundColor:(NSColor *)color {
    return [[NSUserDefaults standardUserDefaults] setColor:color forKey:SKBackgroundColorKey];
}

- (NSColor *)fullScreenBackgroundColor {
    return [[NSUserDefaults standardUserDefaults] colorForKey:SKFullScreenBackgroundColorKey];
}

- (void)setFullScreenBackgroundColor:(NSColor *)color {
    return [[NSUserDefaults standardUserDefaults] setColor:color forKey:SKFullScreenBackgroundColorKey];
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
        [sud colorForKey:SKCircleNoteInteriorColorKey], @"CircleInterior", 
        [sud colorForKey:SKSquareNoteInteriorColorKey], @"SquareInterior", 
        [sud colorForKey:SKFreeTextNoteFontColorKey], @"FreeTextFont", 
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
    if (color = [colorDict objectForKey:@"CircleInterior"])
        [sud setColor:color forKey:SKCircleNoteInteriorColorKey];
    if (color = [colorDict objectForKey:@"SquareInterior"])
        [sud setColor:color forKey:SKSquareNoteInteriorColorKey];
    if (color = [colorDict objectForKey:@"FreeTextFont"])
        [sud setColor:color forKey:SKFreeTextNoteFontColorKey];
}

- (NSDictionary *)defaultLineWidths {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    return [NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithFloat:[sud floatForKey:SKFreeTextNoteLineWidthKey]], SKNFreeTextString, 
        [NSNumber numberWithFloat:[sud floatForKey:SKCircleNoteLineWidthKey]], SKNCircleString, 
        [NSNumber numberWithFloat:[sud floatForKey:SKSquareNoteLineWidthKey]], SKNSquareString, 
        [NSNumber numberWithFloat:[sud floatForKey:SKLineNoteLineWidthKey]], SKNLineString, nil];
}

- (void)setDefaultLineWidth:(NSDictionary *)dict {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSNumber *number;
    if (number = [dict objectForKey:SKNFreeTextString])
        [sud setFloat:[number floatValue] forKey:SKFreeTextNoteLineWidthKey];
    if (number = [dict objectForKey:SKNCircleString])
        [sud setFloat:[number floatValue] forKey:SKCircleNoteLineWidthKey];
    if (number = [dict objectForKey:SKNSquareString])
        [sud setFloat:[number floatValue] forKey:SKSquareNoteLineWidthKey];
    if (number = [dict objectForKey:SKNLineString])
        [sud setFloat:[number floatValue] forKey:SKLineNoteLineWidthKey];
}

- (NSDictionary *)defaultLineStyles {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    return [NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithUnsignedLong:SKScriptingBorderStyleFromBorderStyle([sud integerForKey:SKFreeTextNoteLineStyleKey])], SKNFreeTextString, 
        [NSNumber numberWithUnsignedLong:SKScriptingBorderStyleFromBorderStyle([sud integerForKey:SKCircleNoteLineStyleKey])], SKNCircleString, 
        [NSNumber numberWithUnsignedLong:SKScriptingBorderStyleFromBorderStyle([sud integerForKey:SKSquareNoteLineStyleKey])], SKNSquareString, 
        [NSNumber numberWithUnsignedLong:SKScriptingBorderStyleFromBorderStyle([sud integerForKey:SKLineNoteLineStyleKey])], SKNLineString, nil];
}

- (void)setDefaultLineStyles:(NSDictionary *)dict {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSNumber *number;
    if (number = [dict objectForKey:SKNFreeTextString])
        [sud setInteger:SKBorderStyleFromScriptingBorderStyle([number unsignedLongValue]) forKey:SKFreeTextNoteLineStyleKey];
    if (number = [dict objectForKey:SKNCircleString])
        [sud setInteger:SKBorderStyleFromScriptingBorderStyle([number unsignedLongValue]) forKey:SKCircleNoteLineStyleKey];
    if (number = [dict objectForKey:SKNSquareString])
        [sud setInteger:SKBorderStyleFromScriptingBorderStyle([number unsignedLongValue]) forKey:SKSquareNoteLineStyleKey];
    if (number = [dict objectForKey:SKNLineString])
        [sud setInteger:SKBorderStyleFromScriptingBorderStyle([number unsignedLongValue]) forKey:SKLineNoteLineStyleKey];
}

- (NSDictionary *)defaultDashPatterns {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    return [NSDictionary dictionaryWithObjectsAndKeys: 
        [sud arrayForKey:SKFreeTextNoteDashPatternKey], SKNFreeTextString, 
        [sud arrayForKey:SKCircleNoteDashPatternKey], SKNCircleString, 
        [sud arrayForKey:SKSquareNoteDashPatternKey], SKNSquareString, 
        [sud arrayForKey:SKLineNoteDashPatternKey], SKNLineString, nil];
}

- (void)setDefaultDashPattern:(NSDictionary *)dict {
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
}

- (FourCharCode)defaultStartLineStyle {
    return SKScriptingLineStyleFromLineStyle([[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteStartLineStyleKey]);
}

- (void)setDefaultStartLineStyle:(FourCharCode)style {
    return [[NSUserDefaults standardUserDefaults] setInteger:SKLineStyleFromScriptingLineStyle(style) forKey:SKLineNoteStartLineStyleKey];
}

- (FourCharCode)defaultEndLineStyle {
    return SKScriptingLineStyleFromLineStyle([[NSUserDefaults standardUserDefaults] integerForKey:SKLineNoteEndLineStyleKey]);
}

- (void)setDefaultEndLineStyle:(FourCharCode)style {
    return [[NSUserDefaults standardUserDefaults] setInteger:SKLineStyleFromScriptingLineStyle(style) forKey:SKLineNoteEndLineStyleKey];
}

- (FourCharCode)defaultIconType {
    return SKScriptingIconTypeFromIconType([[NSUserDefaults standardUserDefaults] integerForKey:SKAnchoredNoteIconTypeKey]);
}

- (void)setDefaultIconType:(FourCharCode)type {
    return [[NSUserDefaults standardUserDefaults] setInteger:SKIconTypeFromScriptingIconType(type) forKey:SKAnchoredNoteIconTypeKey];
}

- (unsigned int)countOfLines {
    return UINT_MAX;
}

- (SKLine *)objectInLinesAtIndex:(unsigned int)anIndex {
    return [[[SKLine alloc] initWithLine:anIndex] autorelease];
}

@end
