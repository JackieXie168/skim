// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAScriptToolbarHelper.h"

#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "NSImage-OAExtensions.h"
#import "NSToolbar-OAExtensions.h"
#import "OAOSAScript.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAScriptToolbarHelper.m,v 1.9 2003/01/15 22:51:31 kc Exp $")

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
            if (([[attributes objectForKey:NSFileHFSTypeCode] longValue] != 'osas') && ![filename hasSuffix:@".scpt"])
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
    OAOSAScript *script;
    
    script = [[OAOSAScript alloc] initWithPath:[self pathForItem:sender]];
    [script executeWithInterfaceOnWindow:[[sender toolbar] window]];
    [script release];
}

@end
