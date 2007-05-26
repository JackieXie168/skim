//
//  SKApplicationController.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006,2007
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
#import "SKPreferenceController.h"
#import "SKReleaseNotesController.h"
#import "SKStringConstants.h"
#import "SKDocument.h"
#import "SKMainWindowController.h"
#import "SKBookmarkController.h"
#import "BDAlias.h"
#import "SKVersionNumber.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import <Quartz/Quartz.h>
#import <Sparkle/Sparkle.h>
#import "AppleRemote.h"


@implementation SKApplicationController

+ (void)initialize{
    [self setupDefaults];
}
   
+ (void)setupDefaults{
    
    NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
    NSDictionary *initialValuesDict;
    NSArray *resettableUserDefaultsKeys;
    
    // load the default values for the user defaults
    userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"InitialUserDefaults" ofType:@"plist"];
    userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    initialValuesDict = [userDefaultsValuesDict objectForKey:@"RegisteredDefaults"];
    
    // set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:initialValuesDict];
    
    // if your application supports resetting a subset of the defaults to 
    // factory values, you should set those values 
    // in the shared user defaults controller
    
    resettableUserDefaultsKeys = [[[userDefaultsValuesDict objectForKey:@"ResettableKeys"] allValues] valueForKeyPath:@"@unionOfArrays.self"];
    initialValuesDict = [initialValuesDict dictionaryWithValuesForKeys:resettableUserDefaultsKeys];
    
    // Set the initial values in the shared user defaults controller 
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
}

static BOOL fileIsInTrash(NSURL *fileURL)
{
    NSCParameterAssert([fileURL isFileURL]);    
    FSRef parentRef;
    CFURLRef parentURL = CFURLCreateCopyDeletingLastPathComponent(CFGetAllocator((CFURLRef)fileURL), (CFURLRef)fileURL);
    [(id)parentURL autorelease];
    if (CFURLGetFSRef(parentURL, &parentRef)) {
        OSStatus err;
        FSRef fsRef;
        err = FSFindFolder(kUserDomain, kTrashFolderType, TRUE, &fsRef);
        if (noErr == err && noErr == FSCompareFSRefs(&fsRef, &parentRef))
            return YES;
        
        err = FSFindFolder(kOnAppropriateDisk, kSystemTrashFolderType, TRUE, &fsRef);
        if (noErr == err && noErr == FSCompareFSRefs(&fsRef, &parentRef))
            return YES;
    }
    return NO;
}

- (void)awakeFromNib {
    NSMenu *viewMenu = [[[NSApp mainMenu] itemAtIndex:4] submenu];
    int i, count = [viewMenu numberOfItems];
    
    for (i = 0; i < count; i++) {
        NSMenuItem *menuItem = [viewMenu itemAtIndex:i];
        if ([menuItem action] == @selector(changeLeftSidePaneState:) || [menuItem action] == @selector(changeRightSidePaneState:)) 
            [menuItem setIndentationLevel:1];
    }
    
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKReopenLastOpenFilesKey]) {
        NSArray *files = [[NSUserDefaults standardUserDefaults] objectForKey:SKLastOpenFileNamesKey];
        NSEnumerator *fileEnum = [files objectEnumerator];
        NSDictionary *dict;
        NSURL *fileURL = nil;
        SKDocument *document;
        
        while (dict = [fileEnum nextObject]){ 
            fileURL = [[BDAlias aliasWithData:[dict objectForKey:@"_BDAlias"]] fileURL];
            if(fileURL == nil && [dict objectForKey:@"fileName"])
                fileURL = [NSURL fileURLWithPath:[dict objectForKey:@"fileName"]];
            if(fileURL && NO == fileIsInTrash(fileURL) && (document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:NO error:NULL])) {
                [document makeWindowControllers];
                if ([document respondsToSelector:@selector(mainWindowController)])
                    [[document mainWindowController] setupWindow:dict];
                [document showWindows];
            }
        }
    }
    
    return NO;
}    

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    SKVersionNumber *versionNumber = versionString ? [[[SKVersionNumber alloc] initWithVersionString:versionString] autorelease] : nil;
    NSString *lastVersionString = [[NSUserDefaults standardUserDefaults] stringForKey:SKLastVersionLaunchedKey];
    SKVersionNumber *lastVersionNumber = lastVersionString ? [[[SKVersionNumber alloc] initWithVersionString:lastVersionString] autorelease] : nil;
    if(lastVersionNumber == nil || [lastVersionNumber compareToVersionNumber:versionNumber] == NSOrderedAscending) {
        [self showReleaseNotes:nil];
        [[NSUserDefaults standardUserDefaults] setObject:versionString forKey:SKLastVersionLaunchedKey];
    }
	if ([[NSUserDefaults standardUserDefaults] boolForKey:SKEnableAppleRemoteKey])
        [[AppleRemote sharedRemote] setDelegate:self];
    [self doSpotlightImportIfNeeded];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:SKEnableAppleRemoteKey])
        [[AppleRemote sharedRemote] setListeningToRemote:YES];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:SKEnableAppleRemoteKey])
        [[AppleRemote sharedRemote] setListeningToRemote:NO];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:SKEnableAppleRemoteKey]) {
        [[AppleRemote sharedRemote] setListeningToRemote:NO];
        [[AppleRemote sharedRemote] setDelegate:nil];
    }
}

- (IBAction)visitWebSite:(id)sender{
    if([[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://skim-app.sourceforge.net/"]] == NO)
        NSBeep();
}

- (IBAction)showPreferencePanel:(id)sender{
    [[SKPreferenceController sharedPrefenceController] showWindow:self];
}

- (IBAction)showReleaseNotes:(id)sender{
    [[SKReleaseNotesController sharedReleaseNotesController] showWindow:self];
}

- (IBAction)editBookmarks:(id)sender {
    [[SKBookmarkController sharedBookmarkController] showWindow:self];
}

- (IBAction)openBookmark:(id)sender {
    int i = [sender tag];
    NSArray *bookmarks = [[SKBookmarkController sharedBookmarkController] bookmarks];
    NSDictionary *bm = [bookmarks objectAtIndex:i];
    id document = nil;
    NSURL *fileURL = [[BDAlias aliasWithData:[bm objectForKey:@"_BDAlias"]] fileURL];
    
    if (fileURL == nil && [bm objectForKey:@"path"])
        fileURL = [NSURL fileURLWithPath:[bm objectForKey:@"path"]];
    if (fileURL && NO == fileIsInTrash(fileURL) && (document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES error:NULL]))
        [[document mainWindowController] setPageNumber:[[bm objectForKey:@"pageIndex"] unsignedIntValue] + 1];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSArray *bookmarks = [[SKBookmarkController sharedBookmarkController] bookmarks];
    int i = [menu numberOfItems], iMax = [bookmarks count];
    while (--i > 1)
        [menu removeItemAtIndex:i];
    if (iMax > 0)
        [menu addItem:[NSMenuItem separatorItem]];
    for (i = 0; i < iMax; i++) {
        NSDictionary *bm = [bookmarks objectAtIndex:i];
        NSMenuItem *item = [menu addItemWithTitle:[bm objectForKey:@"label"] action:@selector(openBookmark:)  keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:i];
    }
}

- (SUUpdater *)updater {
    return updater;
}

- (void)appleRemoteButton:(AppleRemoteEventIdentifier)buttonIdentifier pressedDown:(BOOL)pressedDown {
    NSArray *docs = [NSApp orderedDocuments];
    id document = [docs count] ? [docs objectAtIndex:0] : nil;
    SKMainWindowController *controller = [document respondsToSelector:@selector(mainWindowController)]? [document mainWindowController] : nil;
    
    if (controller == nil)
        return;
    
    switch (buttonIdentifier) {
        case kRemoteButtonVolume_Plus:
            if (pressedDown == NO)
                break;
            if ([controller isPresentation])
                [controller doAutoScale:nil];
            else
                [controller doZoomIn:nil];
            break;
        case kRemoteButtonVolume_Minus:
            if (pressedDown == NO)
                break;
            if ([controller isPresentation])
                [controller doZoomToActualSize:nil];
            else
                [controller doZoomOut:nil];
            break;
        case kRemoteButtonRight_Hold:
            if (pressedDown == NO)
                break;
        case kRemoteButtonRight:
            [controller doGoToNextPage:nil];
            break;
        case kRemoteButtonLeft_Hold:
            if (pressedDown == NO)
                break;
        case kRemoteButtonLeft:
            [controller doGoToPreviousPage:nil];
            break;
        case kRemoteButtonPlay:
            [controller togglePresentation:nil];
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
        NSDictionary *versionInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"SKSpotlightVersionInfo"];
        
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
                NSTask *importerTask = [[[NSTask alloc] init] autorelease];
                [importerTask setLaunchPath:mdimportPath];
                [importerTask setArguments:[NSArray arrayWithObjects:@"-r", importerPath, nil]];
                [importerTask launch];
                
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:sysVersion], @"lastSysVersion", importerVersion, @"lastImporterVersion", nil];
                [[NSUserDefaults standardUserDefaults] setObject:info forKey:@"SKSpotlightVersionInfo"];
                
            } else NSLog(@"%@ not found!", mdimportPath);
        }
    }
}

- (NSString *)applicationSupportPathForDomain:(int)domain create:(BOOL)create {
    static NSString *path = nil;
    
    if (path == nil) {
        FSRef foundRef;
        OSStatus err = noErr;
        
        err = FSFindFolder(domain, kApplicationSupportFolderType, create ? kCreateFolder : kDontCreateFolder, &foundRef);
        if (err != noErr) {
            if (create)
                NSLog(@"Error %d:  the system was unable to find your Application Support folder.", err);
            return nil;
        }
        
        CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &foundRef);
        
        if (url != nil) {
            path = [(NSURL *)url path];
            CFRelease(url);
        }
        
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleExecutableKey];
        
        if(appName == nil)
            [NSException raise:NSObjectNotAvailableException format:NSLocalizedString(@"Unable to find CFBundleIdentifier for %@", @"Exception message"), [NSApp description]];
        
        path = [[path stringByAppendingPathComponent:appName] copy];
        
        // the call to FSFindFolder creates the parent hierarchy, but not the directory we're looking for
        static BOOL dirExists = NO;
        if (dirExists == NO && create) {
            BOOL pathIsDir;
            dirExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&pathIsDir];
            if (dirExists == NO || pathIsDir == NO)
                [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
            // make sure it was created
            dirExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&pathIsDir];
            NSAssert1(dirExists && pathIsDir, @"Unable to create folder %@", path);
        }
    }
    
    return path;
}

- (NSString *)pathForApplicationSupportFile:(NSString *)file ofType:(NSString *)extension {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *filename = [file stringByAppendingPathExtension:extension];
    NSString *fullPath = nil;
    NSString *appSupportPath = nil;
    if (appSupportPath = [self applicationSupportPathForDomain:kUserDomain create:NO]) {
        fullPath = [appSupportPath stringByAppendingPathComponent:filename];
        if ([fm fileExistsAtPath:fullPath] == NO) {
            fullPath = nil;
            if (appSupportPath = [self applicationSupportPathForDomain:kLocalDomain create:NO]) {
                fullPath = [appSupportPath stringByAppendingPathComponent:filename];
                if ([fm fileExistsAtPath:fullPath] == NO) {
                    fullPath = nil;
                    if (appSupportPath = [self applicationSupportPathForDomain:kNetworkDomain create:NO]) {
                        fullPath = [appSupportPath stringByAppendingPathComponent:filename];
                        if ([fm fileExistsAtPath:fullPath] == NO) {
                            fullPath = nil;
                            if (appSupportPath = [[NSBundle mainBundle] sharedSupportPath]) {
                                fullPath = [appSupportPath stringByAppendingPathComponent:filename];
                                if ([fm fileExistsAtPath:fullPath] == NO)
                                    fullPath = nil;
                            }
                        }
                    }
                }
            }
        }
    }
    return fullPath;
}

@end
