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
#import "SKUpdateChecker.h"
#import "SKStringConstants.h"
#import "SKDocument.h"
#import "SKMainWindowController.h"
#import "SKBookmarkController.h"
#import "BDAlias.h"
#import "SKVersionNumber.h"
#import <Quartz/Quartz.h>


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
    userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"InitialUserDefaults" 
                                                           ofType:@"plist"];
    userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    
    // set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
    
    // if your application supports resetting a subset of the defaults to 
    // factory values, you should set those values 
    // in the shared user defaults controller
    resettableUserDefaultsKeys = [userDefaultsValuesDict objectForKey:@"SKResettableKeys"];
    
    initialValuesDict = [userDefaultsValuesDict dictionaryWithValuesForKeys:resettableUserDefaultsKeys];
    
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
        //[self showReleaseNotes:nil];
        //[[NSUserDefaults standardUserDefaults] setObject:versionString forKey:SKLastVersionLaunchedKey];
    }
    [[SKUpdateChecker sharedChecker] scheduleUpdateCheckIfNeeded];
}

- (IBAction)checkForUpdates:(id)sender{
    [[SKUpdateChecker sharedChecker] checkForUpdates:sender];  
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
    
    NSString *path = [bm objectForKey:@"path"];
    NSNumber *pageNumber = [bm objectForKey:@"pageIndex"];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    
    id document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES error:NULL];
    
    [[document mainWindowController] goToPageIndexWhenReady:pageNumber];
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

@end
