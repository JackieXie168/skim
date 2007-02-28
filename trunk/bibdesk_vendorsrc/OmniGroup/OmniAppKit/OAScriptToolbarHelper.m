// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
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
#import "OAApplication.h"
#import "OAWorkflow.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OAScriptToolbarHelper.m 71208 2005-12-16 00:31:23Z bungi $")

static BOOL OSVersionIs_10_4_Plus = NO;


@implementation OAScriptToolbarHelper

+ (void)initialize;
{
    OBINITIALIZE;
    
    OFVersionNumber *_10_4_version = [[OFVersionNumber alloc] initWithVersionString:@"10.4"];
    OSVersionIs_10_4_Plus = [_10_4_version compareToVersionNumber:[OFVersionNumber userVisibleOperatingSystemVersionNumber]] != NSOrderedDescending;
    [_10_4_version release];
}

- (NSString *)itemIdentifierExtension;
{
    return @"osascript";
}

- (NSString *)templateItemIdentifier;
{
    return @"OSAScriptTemplate";
}

static NSString *scriptPathForRootPath_10_4(NSString *rootPath)
{
    static NSString *appSupportDirectory = nil;

    if (appSupportDirectory == nil)
        appSupportDirectory = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] retain];

    OBASSERT(appSupportDirectory != nil);

    return [[[[rootPath stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Scripts"] stringByAppendingPathComponent:@"Applications"] stringByAppendingPathComponent:appSupportDirectory];
}

static NSString *scriptPathForRootPath_10_3(NSString *rootPath)
{
    static NSString *appSupportDirectory = nil;
    
    if (appSupportDirectory == nil) {
        id appDelegate = [NSApp delegate];
        if (appDelegate != nil && [appDelegate respondsToSelector:@selector(applicationSupportDirectoryName)])
            appSupportDirectory = [appDelegate applicationSupportDirectoryName];
        
        if (appSupportDirectory == nil)
            appSupportDirectory = [[NSProcessInfo processInfo] processName];
        
        [appSupportDirectory retain];
    }

    OBASSERT(appSupportDirectory != nil);

    return [[[[rootPath stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:appSupportDirectory] stringByAppendingPathComponent:@"Scripts"];
}

static NSString *scriptPathForRootPath(NSString *rootPath)
{
    if (OSVersionIs_10_4_Plus) {
        return scriptPathForRootPath_10_4(rootPath);
    } else {
        return scriptPathForRootPath_10_3(rootPath);
    }
}

- (NSArray *)scriptPaths;
{
    NSMutableArray *result = [NSMutableArray array];

    [result addObject:scriptPathForRootPath(NSHomeDirectory())];
    [result addObject:scriptPathForRootPath(@"/")];
    [result addObject:scriptPathForRootPath(@"/Network")];

    if (!OSVersionIs_10_4_Plus) {
        // The only script we currently embed in the app wrapper is About The Scripts Menu, which we only use on 10.3
        [result addObject:[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Scripts"]];
    }

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
            if (([[attributes objectForKey:NSFileHFSTypeCode] longValue] != 'osas') && ![filename hasSuffix:@".scpt"] && ![filename hasSuffix:@".scptd"] && ![filename hasSuffix:@".workflow"])
                continue;
	    
	    path = [path stringByAppendingPathExtension:@"osascript"];
	    path = [path stringByAbbreviatingWithTildeInPath];
            [results addObject:path];
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
    NSString *path = [self pathForItem:item];
    
    [item setTarget:self];
    [item setAction:@selector(executeScriptItem:)];
    [item setLabel:[[item label] stringByRemovingSuffix:@".scpt"]];
    [item setPaletteLabel:[[item paletteLabel] stringByRemovingSuffix:@".scpt"]];

    path = [path stringByExpandingTildeInPath];
    [item setImage:[[NSWorkspace sharedWorkspace] iconForFile:path]];

    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)path, kCFURLPOSIXPathStyle, false);
    
    FSRef myFSRef;
    if (CFURLGetFSRef(url, &myFSRef)) {
        FSCatalogInfo catalogInfo;
        if (FSGetCatalogInfo(&myFSRef, kFSCatInfoFinderInfo, &catalogInfo, NULL, NULL, NULL) == noErr) {
            if ((((FileInfo *)(&catalogInfo.finderInfo))->finderFlags & kHasCustomIcon) == 0)
                [item setImage:[NSImage imageNamed:@"OAScriptIcon" inBundleForClass:[OAScriptToolbarHelper class]]];
        }
    }
    
    CFRelease(url);
}

- (void)executeScriptItem:sender;
{
    OAToolbarWindowController *controller = [[sender toolbar] delegate];
    
    if ([controller respondsToSelector:@selector(scriptToolbarItemShouldExecute:)] &&
	![controller scriptToolbarItemShouldExecute:sender])
	return;
    
    @try {
	NSString *scriptFilename = [[self pathForItem:sender] stringByExpandingTildeInPath];

	if (OSVersionIs_10_4_Plus && [@"workflow" isEqualToString:[scriptFilename pathExtension]]) {
	    OAWorkflow *workflow = [OAWorkflow workflowWithContentsOfFile:scriptFilename];
	    if (!workflow) {
		NSBundle *frameworkBundle = [OAScriptToolbarHelper bundle];
		NSString *errorText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Unable to run workflow.", @"OmniAppKit", frameworkBundle, "workflow execution error")];
		NSString *messageText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"workflow not found at %@", @"OmniAppKit", frameworkBundle, "script loading error message"), scriptFilename];
		NSString *okButton = NSLocalizedStringFromTableInBundle(@"OK", @"OmniAppKit", frameworkBundle, "script error panel button");
		NSBeginAlertSheet(errorText, okButton, nil, nil, [[sender toolbar] window], self, NULL, NULL, NULL, messageText);                                     
		return;
	    }
	    NSException   *raisedException = nil;
	    NS_DURING {
		[workflow executeWithFiles:nil];
	    } NS_HANDLER {
		raisedException = localException;
	    } NS_ENDHANDLER;
	    if (raisedException) {
		NSBundle *frameworkBundle = [OAScriptToolbarHelper bundle];
		NSString *errorText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Unable to run workflow.", @"OmniAppKit", frameworkBundle, "workflow execution error")];
		NSString *messageText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The following error was reported:\n%@", @"OmniAppKit", frameworkBundle, "script loading error message"), [raisedException reason]];
		NSString *okButton = NSLocalizedStringFromTableInBundle(@"OK", @"OmniAppKit", frameworkBundle, "script error panel button");
		NSBeginAlertSheet(errorText, okButton, nil, nil, [[sender toolbar] window], self, NULL, NULL, NULL, messageText);                                     
	    }
	} else {
	    NSDictionary *errorDictionary;
	    NSString *scriptName = [[NSFileManager defaultManager] displayNameAtPath:scriptFilename];
	    NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptFilename] error:&errorDictionary] autorelease];
	    NSAppleEventDescriptor *result;
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
    } @finally {
	if ([controller respondsToSelector:@selector(scriptToolbarItemFinishedExecuting:)])
	    [controller scriptToolbarItemFinishedExecuting:sender];
    }
}

- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertAlternateReturn)
        [[NSWorkspace sharedWorkspace] openFile:[(NSString *)contextInfo autorelease]];
}

@end

