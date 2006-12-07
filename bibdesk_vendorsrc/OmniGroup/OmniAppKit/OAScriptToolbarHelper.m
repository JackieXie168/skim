// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAScriptToolbarHelper.h"

#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "NSImage-OAExtensions.h"
#import "NSToolbar-OAExtensions.h"
#import "OAOSAScript.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAScriptToolbarHelper.m,v 1.14 2004/02/10 04:07:31 kc Exp $")

@implementation OAScriptToolbarHelper

- (NSString *)itemIdentifierExtension;
{
    return @"osascript";
}

- (NSString *)templateItemIdentifier;
{
    return @"OSAScriptTemplate";
}

- (NSArray *)scriptPaths;
{
    NSMutableArray *result;
    
    result = [NSMutableArray array];
    [result addObject:[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]] stringByAppendingPathComponent:@"Scripts"]];
    [result addObject:[[[[@"/" stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]] stringByAppendingPathComponent:@"Scripts"]];
    [result addObject:[[[[@"/Network" stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]] stringByAppendingPathComponent:@"Scripts"]];
    [result addObject:[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Scripts"]];
    return result;
}

- (NSArray *)allowedItems;
{
    NSFileManager *fileManager;
    NSEnumerator *pathsEnumerator;
    NSEnumerator *enumerator;
    NSString *scriptFolder, *filename;
    NSMutableArray *results;
    
    results = [NSMutableArray array];
    fileManager = [NSFileManager defaultManager];
    pathsEnumerator = [[self scriptPaths] objectEnumerator];
    while ((scriptFolder = [pathsEnumerator nextObject])) {
        enumerator = [fileManager enumeratorAtPath:scriptFolder];
        while ((filename = [enumerator nextObject])) {
            NSString *path;
            NSDictionary *attributes;
            
            path = [scriptFolder stringByAppendingPathComponent:filename];
            attributes = [fileManager fileAttributesAtPath:path traverseLink:YES];
            if (([[attributes objectForKey:NSFileHFSTypeCode] longValue] != 'osas') && ![filename hasSuffix:@".scpt"] && ![filename hasSuffix:@".scptd"])
                continue;
            [results addObject:[path stringByAppendingPathExtension:@"osascript"]];
        } 
    }
    return results;
}

- (NSString *)pathForItem:(NSToolbarItem *)anItem;
{
    NSString *identifier;

    identifier = [anItem itemIdentifier];
    // -10 for ".osascript" not using deletingPathExtension in case the file also has some other extension
    return [identifier substringToIndex:([identifier length] - 10)];
}

- (void)finishSetupForItem:(NSToolbarItem *)item;
{
    FSRef myFSRef;
    FSSpec myFSSpec;
    FInfo myFInfo;

    [item setTarget:self];
    [item setAction:@selector(executeScriptItem:)];
    [item setLabel:[[item label] stringByRemovingSuffix:@".scpt"]];
    [item setPaletteLabel:[[item paletteLabel] stringByRemovingSuffix:@".scpt"]];
    
    [item setImage:[[NSWorkspace sharedWorkspace] iconForFile:[self pathForItem:item]]];
    if (FSPathMakeRef([[self pathForItem:item] fileSystemRepresentation], &myFSRef, NULL) == noErr) {
        if (FSGetCatalogInfo(&myFSRef, kFSCatInfoNone, NULL, NULL, &myFSSpec, NULL) == noErr) {
            FSpGetFInfo(&myFSSpec, &myFInfo);
            if ((myFInfo.fdFlags & kHasCustomIcon) == 0)
                [item setImage:[NSImage imageNamed:@"OAScriptIcon" inBundleForClass:[OAScriptToolbarHelper class]]];
        }
    }
}

- (void)executeScriptItem:sender;
{
    NSString *scriptFilename, *scriptName;
    NSAppleScript *script;
    NSDictionary *errorDictionary;
    NSAppleEventDescriptor *result;
    
    scriptFilename = [self pathForItem:sender];
    scriptName = [[NSFileManager defaultManager] displayNameAtPath:scriptFilename];
    script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptFilename] error:&errorDictionary] autorelease];
    if (script == nil) {
        NSString *errorText, *messageText, *okButton;
        
        errorText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The script file '%@' could not be opened.", @"OmniAppKit", [OAScriptToolbarHelper bundle], "script loading error"), scriptName];
        messageText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"AppleScript reported the following error:\n%@", @"OmniAppKit", [OAScriptToolbarHelper bundle], "script loading error message"), [errorDictionary objectForKey:NSAppleScriptErrorMessage]];
        okButton = NSLocalizedStringFromTableInBundle(@"OK", @"OmniAppKit", [OAScriptToolbarHelper bundle], "script error panel button");
        NSBeginAlertSheet(errorText, okButton, nil, nil, [[sender toolbar] window], self, NULL, NULL, NULL, messageText);                                     
        return;
    }
    result = [script executeAndReturnError:&errorDictionary];
    if (result == nil) {
        NSString *errorText, *messageText, *okButton, *editButton;
        
        errorText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The script '%@' could not complete.", @"OmniAppKit", [OAScriptToolbarHelper bundle], "script execute error"), scriptName];
        messageText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"AppleScript reported the following error:\n%@", @"OmniAppKit", [OAScriptToolbarHelper bundle], "script execute error message"), [errorDictionary objectForKey:NSAppleScriptErrorMessage]];
        okButton = NSLocalizedStringFromTableInBundle(@"OK", @"OmniAppKit", [OAScriptToolbarHelper bundle], "script error panel button");
        editButton = NSLocalizedStringFromTableInBundle(@"Edit Script", @"OmniAppKit", [OAScriptToolbarHelper bundle], "script error panel button");
        NSBeginAlertSheet(errorText, okButton, editButton, nil, [[sender toolbar] window], self, @selector(errorSheetDidEnd:returnCode:contextInfo:), NULL, [scriptFilename retain], messageText);                                     
        
        return;
    }
}

- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertAlternateReturn)
        [[NSWorkspace sharedWorkspace] openFile:[(NSString *)contextInfo autorelease]];
}

@end
