//
//  BDSKScriptMenu.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 30/10/05.
/*
 This software is Copyright (c) 2005,2006,2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "BDSKScriptMenu.h"
#import <OmniFoundation/OmniFoundation.h>
#import <OmniAppKit/NSMenu-OAExtensions.h>
#import <OmniBase/OmniBase.h>
#import <OmniAppKit/OAApplication.h>

@interface BDSKScriptMenuController : NSObject
+ (id)sharedInstance;
@end

@interface BDSKScriptMenu (Private)
- (NSArray *)scriptPaths;
- (NSArray *)directoryContentsAtPath:(NSString *)path lastModified:(NSDate **)lastModifiedDate;
- (void)updateSubmenu:(NSMenu *)menu withScripts:(NSArray *)scripts;
- (void)executeScript:(id)sender;
- (void)openScript:(id)sender;
- (void)reloadScriptMenu;
@end

@implementation BDSKScriptMenu

static NSArray *sortDescriptors = nil;
static int recursionDepth = 0;

+ (void)initialize
{
    OBINITIALIZE;
    sortDescriptors = [[NSArray alloc] initWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"filename" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease], nil];
}

+ (void)addScriptsToMainMenu;
{
    // title is currently unused
    NSString *scriptMenuTitle = @"Scripts";
    NSMenu *newMenu = [[BDSKScriptMenu allocWithZone:[NSMenu menuZone]] initWithTitle:scriptMenuTitle];
    NSMenuItem *scriptItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:scriptMenuTitle action:NULL keyEquivalent:@""];
    [scriptItem setImage:[NSImage imageNamed:@"OAScriptMenu"]];
    [scriptItem setSubmenu:newMenu];
    [newMenu setDelegate:[BDSKScriptMenuController sharedInstance]];
    [newMenu release];
    [[NSApp mainMenu] insertItem:scriptItem atIndex:[[NSApp mainMenu] indexOfItemWithTitle:@"Help"]];
    [scriptItem release];
}    

- (void)dealloc
{
    [cachedDate release];
    [super dealloc];
}

+ (BOOL)disabled;
{
    // Omni disables their script menu on 10.4, saying the system one is better...
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"OAScriptMenuDisabled"];
}

@end

@implementation BDSKScriptMenu (Private)

static NSDate *earliestDateFromBaseScriptsFolders(NSArray *folders)
{
    unsigned i, count = [folders count];
    NSDate *date = [NSDate distantPast];
    for(i = 0; i < count; i++){
        NSDate *modDate = [[[NSFileManager defaultManager] fileAttributesAtPath:[folders objectAtIndex:i] traverseLink:YES] objectForKey:NSFileModificationDate];
        
        // typically these don't even exist for the other domains
        if(modDate)
            date = [modDate laterDate:date];
    }
    return date;
}
        
- (void)reloadScriptMenu;
{
    NSMutableArray *scripts;
    NSArray *scriptFolders;
    unsigned int scriptFolderIndex, scriptFolderCount;
    
    scripts = [[NSMutableArray alloc] init];
    scriptFolders = [self scriptPaths];
    scriptFolderCount = [scriptFolders count];
    
    // must initialize this date before passing it by reference
    NSDate *modDate = earliestDateFromBaseScriptsFolders(scriptFolders);
    
    // walk the subdirectories for each domain
    for (scriptFolderIndex = 0; scriptFolderIndex < scriptFolderCount; scriptFolderIndex++) {
        NSString *scriptFolder = [scriptFolders objectAtIndex:scriptFolderIndex];
        recursionDepth = 0;
		[scripts addObjectsFromArray:[self directoryContentsAtPath:scriptFolder lastModified:&modDate]];
    }
    
    // don't recreate the menu unless the content on disk has actually changed
    if(nil == cachedDate || [modDate compare:cachedDate] == NSOrderedDescending){
        [cachedDate release];
        cachedDate = [modDate retain];
        
        [scripts sortUsingDescriptors:sortDescriptors];
        [self updateSubmenu:self withScripts:scripts];        
    }   
    [scripts release];
}

- (NSArray *)directoryContentsAtPath:(NSString *)path lastModified:(NSDate **)lastModifiedDate
{
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
	NSString *file, *fileType, *filePath;
	NSNumber *fileCode;
	NSArray *content;
	NSDictionary *dict;
	NSMutableArray *fileArray = [NSMutableArray array];
	
    recursionDepth++;
    
    NSDate *modDate;
    NSDictionary *fileAttributes;
    
    // avoid recursing too many times (and creating an excessive number of submenus)
	while (recursionDepth <= 3 && (file = [dirEnum nextObject])) {
        fileAttributes = [dirEnum fileAttributes];
		fileType = [fileAttributes valueForKey:NSFileType];
		fileCode = [fileAttributes valueForKey:NSFileHFSTypeCode];
		filePath = [path stringByAppendingPathComponent:file];
		
        // get the latest modification date
        modDate = [fileAttributes valueForKey:NSFileModificationDate];
        *lastModifiedDate = [*lastModifiedDate laterDate:modDate];
        
		if ([file hasPrefix:@"."]) {
            if ([fileType isEqualToString:NSFileTypeDirectory]) 
                [dirEnum skipDescendents];
		} else if ([fileType isEqualToString:NSFileTypeDirectory]) {
			[dirEnum skipDescendents];
			content = [self directoryContentsAtPath:filePath lastModified:lastModifiedDate];
			if ([content count] > 0) {
				dict = [[NSDictionary alloc] initWithObjectsAndKeys:filePath, @"filename", content, @"content", nil];
				[fileArray addObject:dict];
				[dict release];
			}
		} else if ([file hasSuffix:@".scpt"] || [file hasSuffix:@".scptd"] || [fileCode longValue] == 'osas') {
			dict = [[NSDictionary alloc] initWithObjectsAndKeys:filePath, @"filename", nil];
			[fileArray addObject:dict];
			[dict release];
		}
	}
    [fileArray sortUsingDescriptors:sortDescriptors];
	recursionDepth--;
	return fileArray;
}

- (void)updateSubmenu:(NSMenu *)menu withScripts:(NSArray *)scripts;
{        
    // we call this method recursively; if the menu is nil, the stuff we add won't be retained
    NSParameterAssert(menu != nil);
    
    NSEnumerator *scriptEnum = [scripts objectEnumerator];
	NSDictionary *scriptInfo;
    
    [menu setAutoenablesItems:NO];
    [menu removeAllItems];
    
    while (scriptInfo = [scriptEnum nextObject]) {
        NSString *scriptFilename = [scriptInfo objectForKey:@"filename"];
		NSArray *folderContent = [scriptInfo objectForKey:@"content"];
        NSString *scriptName = [scriptFilename lastPathComponent];
		NSMenuItem *item;
		
		if (folderContent) {
			NSMenu *submenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:scriptName];
			
			item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:scriptName action:NULL keyEquivalent:@""];
			[item setSubmenu:submenu];
			[submenu release];
			[menu addItem:item];
			[item release];
			
			[self updateSubmenu:submenu withScripts:folderContent];
		} else {
			// why not use displayNameAtPath: or stringByDeletingPathExtension?
			// we want to remove the standard script filetype extension even if they're displayed in Finder
			// but we don't want to truncate a non-extension from a script without a filetype extension.
			// e.g. "Foo.scpt" -> "Foo" but not "Foo 2.5" -> "Foo 2"
			scriptName = [scriptName stringByRemovingSuffix:@".scpt"];
			scriptName = [scriptName stringByRemovingSuffix:@".scptd"];
			scriptName = [scriptName stringByRemovingSuffix:@".applescript"];
			
			item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:scriptName action:@selector(executeScript:) keyEquivalent:@""];
			[item setTarget:self];
			[item setEnabled:YES];
			[item setRepresentedObject:scriptFilename];
			[menu addItem:item];
			[item release];
			item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:scriptName action:@selector(openScript:) keyEquivalent:@""];
			[item setKeyEquivalentModifierMask:NSAlternateKeyMask];
			[item setTarget:self];
			[item setEnabled:YES];
			[item setRepresentedObject:scriptFilename];
			[item setAlternate:YES];
			[menu addItem:item];
			[item release];
		}
    }
}

- (NSArray *)scriptPaths;
{
    static NSArray *scriptPaths = nil;
    
    if(nil == scriptPaths){
        NSString *appSupportDirectory = nil;
        
        id appDelegate = [NSApp delegate];
        if (appDelegate != nil && [appDelegate respondsToSelector:@selector(applicationSupportDirectoryName)])
            appSupportDirectory = [appDelegate applicationSupportDirectoryName];
        
        if (appSupportDirectory == nil)
            appSupportDirectory = [[NSProcessInfo processInfo] processName];
        
        NSArray *libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
        unsigned int libraryIndex, libraryCount;
        libraryCount = [libraries count];
        NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:libraryCount + 1];
        for (libraryIndex = 0; libraryIndex < libraryCount; libraryIndex++) {
            NSString *library = [libraries objectAtIndex:libraryIndex];        
            
            [result addObject:[[[library stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:appSupportDirectory] stringByAppendingPathComponent:@"Scripts"]];
        }
        
        [result addObject:[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Scripts"]];
        scriptPaths = [result copy];
        [result release];
    }
    
    return scriptPaths;
}

- (void)executeScript:(id)sender;
{
    NSString *scriptFilename, *scriptName;
    NSAppleScript *script;
    NSDictionary *errorDictionary;
    NSAppleEventDescriptor *result;
    
    scriptFilename = [sender representedObject];
    scriptName = [[NSFileManager defaultManager] displayNameAtPath:scriptFilename];
    script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptFilename] error:&errorDictionary] autorelease];
    if (script == nil) {
        NSString *errorText, *messageText, *okButton;
        
        errorText = [NSString stringWithFormat:NSLocalizedString(@"The script file '%@' could not be opened.", @"Message in alert dialog when failing to load script"), scriptName];
        messageText = [NSString stringWithFormat:NSLocalizedString(@"AppleScript reported the following error:\n%@", @"Informative text in alert dialog"), [errorDictionary objectForKey:NSAppleScriptErrorMessage]];
        okButton = NSLocalizedString(@"OK", @"Button title");
        NSRunAlertPanel(errorText, messageText, okButton, nil, nil);
        return;
    }
    result = [script executeAndReturnError:&errorDictionary];
    if (result == nil) {
        NSString *errorText, *messageText, *okButton, *editButton;
        
        errorText = [NSString stringWithFormat:NSLocalizedString(@"The script '%@' could not complete.", @"Message in alert dialog when failing to execute script"), scriptName];
        messageText = [NSString stringWithFormat:NSLocalizedString(@"AppleScript reported the following error:\n%@", @"Informative text in alert dialog"), [errorDictionary objectForKey:NSAppleScriptErrorMessage]];
        okButton = NSLocalizedString(@"OK", "Button title");
        editButton = NSLocalizedString(@"Edit Script", @"Button title");
        if (NSRunAlertPanel(errorText, messageText, okButton, editButton, nil) == NSAlertAlternateReturn) {
            [[NSWorkspace sharedWorkspace] openFile:scriptFilename];
        }
        return;
    }
}

- (void)openScript:(id)sender;
{
    NSString *scriptFilename = [sender representedObject];
	
	[[NSWorkspace sharedWorkspace] openFile:scriptFilename];
}

@end

@implementation BDSKScriptMenuController

static id sharedScriptMenuController = nil;

+ (id)sharedInstance;
{
    if(nil == sharedScriptMenuController)
        sharedScriptMenuController = [[self alloc] init];
    return sharedScriptMenuController;
}

- (void)menuNeedsUpdate:(BDSKScriptMenu *)menu
{
    [menu reloadScriptMenu];
}

- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action
{
    // implemented so the menu isn't populated on every key event
    return NO;
}

@end
