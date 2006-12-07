// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAScriptMenuItem.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

#import "OAOSAScript.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAScriptMenuItem.m,v 1.8 2003/01/15 22:51:31 kc Exp $")

@implementation OAScriptMenuItem

static NSImage *scriptImage;

+ (void)initialize;
{
    OBINITIALIZE;
    scriptImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:self] pathForResource:@"ScriptImage" ofType:@"tiff"]];
}

- (void)_setup;
{
/* Completely fails to work 
    ((NSImage **)self)[8] = scriptImage; // _onStateImage
    ((NSImage **)self)[9] = scriptImage; // _offStateImage
    ((NSImage **)self)[10] = scriptImage; // _mixedStateImage
    [self setTitle:@""];
*/    
}

- initWithTitle:(NSString *)aTitle action:(SEL)anAction keyEquivalent:(NSString *)charCode;
{
    [super initWithTitle:aTitle action:anAction keyEquivalent:charCode];
    [self _setup];
    return self;
}

- initWithCoder:(NSCoder *)coder;
{
    [super initWithCoder:coder];
    [self _setup];
    return self;
}

- (void)dealloc;
{
    [cachedScripts release];
    [cachedScriptsDate release];
    [super dealloc];
}

- (NSArray *)scriptPaths;
{
    NSString *processName;
    NSArray *libraries;
    unsigned libraryIndex, libraryCount;
    NSMutableArray *result;
    
    processName = [[NSProcessInfo processInfo] processName];
    libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    libraryCount = [libraries count];
    result = [[NSMutableArray alloc] initWithCapacity:libraryCount + 1];
    for (libraryIndex = 0; libraryIndex < libraryCount; libraryIndex++) {
        NSString *library;

        library = [libraries objectAtIndex:libraryIndex];
        [result addObject:[[[library stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:processName] stringByAppendingPathComponent:@"Scripts"]];
    }
    [result addObject:[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Scripts"]];
    return [result autorelease];
}

- (IBAction)executeScript:(id)sender;
{
    OAOSAScript *script;
    
    script = [[OAOSAScript alloc] initWithPath:[sender representedObject]];
    [script executeWithInterfaceOnWindow:nil];
    [script release];
}

#define SCRIPT_REFRESH_TIMEOUT (5.0)

int scriptSort(id script1, id script2, void *context)
{
    return [[script1 lastPathComponent] compare:[script2 lastPathComponent]];
}

- (NSArray *)scripts;
{
    NSMutableArray *scripts;
    NSFileManager *fileManager;
    NSArray *scriptFolders;
    unsigned int scriptFolderIndex, scriptFolderCount;

    scripts = [[NSMutableArray alloc] init];
    fileManager = [NSFileManager defaultManager];
    scriptFolders = [self scriptPaths];
    scriptFolderCount = [scriptFolders count];
    for (scriptFolderIndex = 0; scriptFolderIndex < scriptFolderCount; scriptFolderIndex++) {
        NSString *scriptFolder;
        NSArray *filenames;
        unsigned int filenameIndex, filenameCount;

        scriptFolder = [scriptFolders objectAtIndex:scriptFolderIndex];
        filenames = [fileManager directoryContentsAtPath:scriptFolder];
        filenameCount = [filenames count];
        for (filenameIndex = 0; filenameIndex < filenameCount; filenameIndex++) {
            NSString *filename;
            NSString *path;

            filename = [filenames objectAtIndex:filenameIndex];
            path = [scriptFolder stringByAppendingPathComponent:filename];
            if ([filename hasSuffix:@".scpt"] || [[[fileManager fileAttributesAtPath:path traverseLink:YES] objectForKey:NSFileHFSTypeCode] longValue] == 'osas')
                [scripts addObject:path];
        }
    }
    cachedScripts = [[scripts sortedArrayUsingFunction:scriptSort context:NULL] retain];
    [scripts release];
    cachedScriptsDate = [[NSDate alloc] init];
    return cachedScripts;
}

- (NSMenu *)submenu;
{
    NSMenu *menu;
    unsigned int oldMenuItemCount;
    NSArray *scripts;
    unsigned int scriptIndex, scriptCount;
    
    if (cachedScriptsDate != nil && [cachedScriptsDate timeIntervalSinceNow] > -SCRIPT_REFRESH_TIMEOUT) {
        return [super submenu];
    }
    menu = [super submenu];
    [menu setAutoenablesItems:NO];
    oldMenuItemCount = [menu numberOfItems];
    while (oldMenuItemCount-- != 0)
        [menu removeItemAtIndex:oldMenuItemCount];

    scripts = [self scripts];
    scriptCount = [scripts count];
    for (scriptIndex = 0; scriptIndex < scriptCount; scriptIndex++) {
        NSString *scriptFilename;
        NSMenuItem *item;

        scriptFilename = [scripts objectAtIndex:scriptIndex];
        item = [[NSMenuItem alloc] initWithTitle:[[scriptFilename lastPathComponent] stringByDeletingPathExtension] action:@selector(executeScript:) keyEquivalent:@""];
        [item setTarget:self];
        [item setEnabled:YES];
        [item setRepresentedObject:scriptFilename];
        [menu addItem:item];
        [item release];
    }
    return menu;
}

@end
