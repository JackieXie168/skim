//
//  BDSKScriptMenuItem.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 30/10/05.
/*
 This software is Copyright (c) 2005
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
#import <OmniFoundation/NSString-OFExtensions.h>

@interface OAScriptMenuItem (Private)
// copy OAScriptMenuItem private API
- (NSArray *)_scripts;
- (NSArray *)_scriptPaths;
@end

@interface BDSKScriptMenuItem (Private)
- (NSArray *)directoryContentsAtPath:(NSString *)path;
- (void)updateSubmenu:(NSMenu *)menu withScripts:(NSArray *)scripts;
@end

@implementation BDSKScriptMenuItem

- (IBAction)openScript:(id)sender;
{
    NSString *scriptFilename = [sender representedObject];
	
	[[NSWorkspace sharedWorkspace] openFile:scriptFilename];
}

- (void)updateScripts;
{
	[self updateSubmenu:[super submenu] withScripts:[self _scripts]];
}

@end

@implementation BDSKScriptMenuItem (Private)
/*
Copied and modified from OmniAppKit/OAScriptMenuItem.h
*/

static NSComparisonResult
scriptSort(id script1, id script2, void *context)
{
	NSString *key = (NSString *)context;
    return [[[script1 objectForKey:key] lastPathComponent] caseInsensitiveCompare:[[script2 objectForKey:key] lastPathComponent]];
}

- (NSArray *)_scripts;
{
    NSMutableArray *scripts;
    NSArray *scriptFolders;
    unsigned int scriptFolderIndex, scriptFolderCount;

    scripts = [[NSMutableArray alloc] init];
    scriptFolders = [self _scriptPaths];
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
    NSEnumerator *scriptEnum = [scripts objectEnumerator];
	NSDictionary *scriptInfo;
	unsigned int oldMenuItemCount;
    
    [menu setAutoenablesItems:NO];
    oldMenuItemCount = [menu numberOfItems];
    while (oldMenuItemCount-- != 0)
        [menu removeItemAtIndex:oldMenuItemCount];

    while (scriptInfo = [scriptEnum nextObject]) {
        NSString *scriptFilename = [scriptInfo objectForKey:@"filename"];
		NSArray *folderContent = [scriptInfo objectForKey:@"content"];
        NSString *scriptName = [scriptFilename lastPathComponent];
		NSMenuItem *item;
		
		if (folderContent) {
			NSMenu *submenu = [[NSMenu alloc] initWithTitle:scriptName];
			
			item = [[NSMenuItem alloc] initWithTitle:scriptName action:NULL keyEquivalent:@""];
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
			
			item = [[NSMenuItem alloc] initWithTitle:scriptName action:@selector(executeScript:) keyEquivalent:@""];
			[item setTarget:self];
			[item setEnabled:YES];
			[item setRepresentedObject:scriptFilename];
			[menu addItem:item];
			[item release];
			item = [[NSMenuItem alloc] initWithTitle:scriptName action:@selector(openScript:) keyEquivalent:@""];
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

@end
