//
//  BDSKScriptMenuItem.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 30/10/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKScriptMenuItem.h"
#import <OmniFoundation/OmniFoundation.h>
#import <OmniAppKit/NSMenu-OAExtensions.h>
#import <OmniBase/OmniBase.h>
#import <OmniAppKit/OAApplication.h>

#define SCRIPT_REFRESH_TIMEOUT (5.0)

@interface BDSKScriptMenuItem (Private)
// copy OAScriptMenuItem private API
- (NSArray *)scripts;
- (NSArray *)scriptPaths;
- (void)updateScripts;
- (void)setup;
- (NSArray *)directoryContentsAtPath:(NSString *)path;
- (void)updateSubmenu:(NSMenu *)menu withScripts:(NSArray *)scripts;
- (void)executeScript:(id)sender;
- (void)openScript:(id)sender;
@end

@implementation BDSKScriptMenuItem

static NSImage *scriptImage;

+ (void)initialize;
{
    OBINITIALIZE;
    scriptImage = [[NSImage imageNamed:@"OAScriptMenu"] retain];
}

+ (BOOL)disabled;
{
    // Omni disables their script menu on 10.4, saying the system one is better...
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"OAScriptMenuDisabled"];
}

- initWithTitle:(NSString *)aTitle action:(SEL)anAction keyEquivalent:(NSString *)charCode;
{
    [super initWithTitle:aTitle action:anAction keyEquivalent:charCode];
    [self setup];
    return self;
}

- initWithCoder:(NSCoder *)coder;
{
    // Init from nib
    [super initWithCoder:coder];
    [self setup];
    return self;
}

- (void)dealloc;
{
    [cachedScripts release];
    [cachedScriptsDate release];
    [super dealloc];
}

- (NSMenu *)submenu;
{        
    if (cachedScriptsDate == nil)
        // We've never been updated, so we are likely launching the application.  Don't delay that.
        [self queueSelectorOnce:@selector(updateScripts)];
    else if ([[NSDate date] timeIntervalSinceDate:cachedScriptsDate] > SCRIPT_REFRESH_TIMEOUT)
        // We haven't been updated in a while and the external filesystem might have changed.  Update right now.  The issue is that we might be asked due to tracking starting on the menu.  We don't want to queue the selector in this case since that can modify the menu out from underneath the Carbon menu tracking code, leaving to a crash.
        [self updateScripts];
    
    return [super submenu];
}

@end

@implementation BDSKScriptMenuItem (Private)
/*
Copied and modified from OmniAppKit/OAScriptMenuItem.h
*/

// this method is the preferred way to call updateSubmenu:withScripts, as it checks for a nil menu
- (void)updateScripts;
{
    NSMenu *menu = [super submenu];
    if(menu != nil)
        [self updateSubmenu:menu withScripts:[self scripts]];
}

- (void)setup;
{
    if ([isa disabled]) {
        // Don't queue anything since OAApplication will remove it.  We have to do it there (instead of here) since we can't modify the menu here while it is loading and if we queue it, the menu item will get displayed briefly and then disappear.
    } else {
        [self setImage:scriptImage]; // does nothing on 10.2 and earlier, replaces title with icon on 10.3+
        [self queueSelectorOnce:@selector(updateScripts)];
    }
}

static NSComparisonResult
scriptSort(id script1, id script2, void *context)
{
	NSString *key = (NSString *)context;
    return [[[script1 objectForKey:key] lastPathComponent] caseInsensitiveCompare:[[script2 objectForKey:key] lastPathComponent]];
}

- (NSArray *)scripts;
{
    NSMutableArray *scripts;
    NSArray *scriptFolders;
    unsigned int scriptFolderIndex, scriptFolderCount;

    scripts = [[NSMutableArray alloc] init];
    scriptFolders = [self scriptPaths];
    scriptFolderCount = [scriptFolders count];
	
    for (scriptFolderIndex = 0; scriptFolderIndex < scriptFolderCount; scriptFolderIndex++) {
        NSString *scriptFolder = [scriptFolders objectAtIndex:scriptFolderIndex];
		[scripts addObjectsFromArray:[self directoryContentsAtPath:scriptFolder]];
    }
	
	[scripts sortUsingFunction:scriptSort context:@"filename"];
    
	[cachedScripts release];
    cachedScripts = scripts;

    [cachedScriptsDate release];
    cachedScriptsDate = [[NSDate alloc] init];
    
	return cachedScripts;
}

- (NSArray *)directoryContentsAtPath:(NSString *)path 
{
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
	NSString *file, *fileType, *filePath;
	NSNumber *fileCode;
	NSArray *content;
	NSDictionary *dict;
	NSMutableArray *fileArray = [NSMutableArray array];
	
	while (file = [dirEnum nextObject]) {
		fileType = [[dirEnum fileAttributes] valueForKey:NSFileType];
		fileCode = [[dirEnum fileAttributes] valueForKey:NSFileHFSTypeCode];
		filePath = [path stringByAppendingPathComponent:file];
		
		if ([file hasPrefix:@"."]) {
			[dirEnum skipDescendents];
		} else if ([fileType isEqualToString:NSFileTypeDirectory]) {
			[dirEnum skipDescendents];
			content = [self directoryContentsAtPath:filePath];
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
	[fileArray sortUsingFunction:scriptSort context:@"filename"];
	
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
    
    return [result autorelease];
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

        errorText = [NSString stringWithFormat:NSLocalizedString(@"The script file '%@' could not be opened.", @"script loading error"), scriptName];
        messageText = [NSString stringWithFormat:NSLocalizedString(@"AppleScript reported the following error:\n%@", @"script loading error message"), [errorDictionary objectForKey:NSAppleScriptErrorMessage]];
        okButton = NSLocalizedString(@"OK", @"OK");
        NSRunAlertPanel(errorText, messageText, okButton, nil, nil);
        return;
    }
    result = [script executeAndReturnError:&errorDictionary];
    if (result == nil) {
        NSString *errorText, *messageText, *okButton, *editButton;

        errorText = [NSString stringWithFormat:NSLocalizedString(@"The script '%@' could not complete.", @"script execute error"), scriptName];
        messageText = [NSString stringWithFormat:NSLocalizedString(@"AppleScript reported the following error:\n%@", @"script execute error message"), [errorDictionary objectForKey:NSAppleScriptErrorMessage]];
        okButton = NSLocalizedString(@"OK", "OK");
        editButton = NSLocalizedString(@"Edit Script", @"Edit Script");
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
