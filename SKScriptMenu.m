//
//  SKScriptMenu.m
//  Skim
//
//  Created by Christiaan Hofman on 4/22/10.
/*
 This software is Copyright (c) 2010-2014
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

#import "SKScriptMenu.h"
#import "NSFileManager_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "NSString_SKExtensions.h"

#define SCRIPTS_MENU_TITLE  @"Scripts"
#define SCRIPTS_FOLDER_NAME @"Scripts"
#define FILENAME_KEY        @"filename"
#define TITLE_KEY           @"title"
#define CONTENT_KEY         @"content"

@interface SKScriptMenuController : NSObject <NSMenuDelegate> {
    NSMenu *scriptMenu;
    FSEventStreamRef streamRef;
    NSArray *scriptFolders;
    NSArray *sortDescriptors;
    BOOL menuNeedsUpdate;
}

@property (nonatomic, readonly) NSMenu *scriptMenu;
@property (nonatomic) BOOL menuNeedsUpdate;

+ (id)sharedController;

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
- (NSArray *)directoryContentsAtURL:(NSURL *)url recursionDepth:(NSInteger)depth;
- (void)executeScript:(id)sender;

@end

@implementation SKScriptMenuController

@synthesize scriptMenu, menuNeedsUpdate;

+ (id)sharedController {
    static SKScriptMenuController *sharedController = nil;
    if (sharedController == nil)
        sharedController = [[self alloc] init];
    return sharedController;
}

static void fsevents_callback(FSEventStreamRef streamRef, void *clientCallBackInfo, int numEvents, const char *const eventPaths[], const FSEventStreamEventFlags *eventMasks, const uint64_t *eventIDs) {
    [(id)clientCallBackInfo setMenuNeedsUpdate:YES];
}

- (id)init {
    self = [super init];
    if (self) {
        
        NSInteger itemIndex = [[NSApp mainMenu] numberOfItems] - 1;
        NSFileManager *fm = [NSFileManager defaultManager];
        NSMutableArray *folders = [NSMutableArray array];
        
        for (NSURL *folderURL in [fm applicationSupportDirectoryURLs]) {
            NSNumber *isDir = nil;
            folderURL = [folderURL URLByAppendingPathComponent:SCRIPTS_FOLDER_NAME];
            [folderURL getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:NULL];
            if ([isDir boolValue])
                [folders addObject:folderURL];
        }
        
        if (itemIndex > 0 && [folders count]) {
            
            NSMenuItem *menuItem = [NSMenuItem menuItemWithSubmenuAndTitle:SCRIPTS_MENU_TITLE];
            [menuItem setImage:[NSImage imageNamed:@"ScriptMenu"]];
            [[NSApp mainMenu] insertItem:menuItem atIndex:itemIndex];
            
            FSEventStreamContext context = {0, (void *)self, NULL, NULL, NULL};
            
            scriptMenu = [[menuItem submenu] retain];
            
            sortDescriptors = [[NSArray alloc] initWithObjects:[[[NSSortDescriptor alloc] initWithKey:FILENAME_KEY ascending:YES selector:@selector(localizedCaseInsensitiveNumericCompare:)] autorelease], nil];
            
            scriptFolders = [folders copy];
            
            streamRef = FSEventStreamCreate(kCFAllocatorDefault,
                                            (FSEventStreamCallback)&fsevents_callback, // callback
                                            &context, // context
                                            (CFArrayRef)[scriptFolders valueForKey:@"path"], // pathsToWatch
                                            kFSEventStreamEventIdSinceNow, // sinceWhen
                                            1.0, // latency
                                            kFSEventStreamCreateFlagWatchRoot); // flags
            if (streamRef) {
                FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
                FSEventStreamStart(streamRef);
            }
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillTerminateNotification:) name:NSApplicationWillTerminateNotification object:NSApp];
            [scriptMenu setDelegate:self];
            menuNeedsUpdate = YES;
        }
    }
    return self;
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification {
    if (streamRef) {
        FSEventStreamStop(streamRef);
        FSEventStreamInvalidate(streamRef);
        FSEventStreamRelease(streamRef);
        streamRef = NULL;
    }
    [scriptMenu setDelegate:nil];
}

- (void)updateSubmenu:(NSMenu *)menu withScripts:(NSArray *)scripts {
    [menu removeAllItems];
    
    for (NSDictionary *scriptInfo in scripts) {
        NSString *scriptFilename = [scriptInfo objectForKey:FILENAME_KEY];
		NSArray *folderContent = [scriptInfo objectForKey:CONTENT_KEY];
        NSString *title = [scriptInfo objectForKey:TITLE_KEY];
        
        if (title == nil) {
            [menu addItem:[NSMenuItem separatorItem]];
        } else if (folderContent) {
            NSMenuItem *item = [menu addItemWithSubmenuAndTitle:title];
            [self updateSubmenu:[item submenu] withScripts:folderContent];
        } else {
            NSMenuItem *item = [menu addItemWithTitle:title action:@selector(executeScript:) target:self];
            [item setRepresentedObject:scriptFilename];
        }
    }
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menuNeedsUpdate) {
        NSMutableArray *scripts = [NSMutableArray array];
        for (NSURL *folderURL in scriptFolders)
            [scripts addObjectsFromArray:[self directoryContentsAtURL:folderURL recursionDepth:0]];
        [scripts sortUsingDescriptors:sortDescriptors];
        
        [self updateSubmenu:menu withScripts:scripts];
        
        if ([menu numberOfItems] == 0)
            [menu addItemWithTitle:NSLocalizedString(@"No Script", @"Menu item title") action:NULL keyEquivalent:@""];
        
        menuNeedsUpdate = NO;
    }
}

static BOOL isAppleScriptUTI(NSString *theUTI) {
    if (theUTI == NULL)
        return NO;
    return [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:@"com.apple.applescript.script"] ||
           [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:@"com.apple.applescript.text"] ||
           [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:@"com.apple.applescript.script-bundle"];
}

static BOOL isApplicationUTI(NSString *theUTI) {
    if (theUTI == NULL)
        return NO;
    return [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:(id)kUTTypeApplication];
}

static BOOL isAutomatorWorkflowUTI(NSString *theUTI) {
    if (theUTI == NULL)
        return NO;
    return [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:@"com.apple.automator-workflow"];
}

static BOOL isFolderUTI(NSString *theUTI) {
    if (theUTI == NULL)
        return NO;
    return [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:(id)kUTTypeFolder];
}

- (NSArray *)directoryContentsAtURL:(NSURL *)url recursionDepth:(NSInteger)depth {
    NSMutableArray *files = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSArray *keys = [NSArray arrayWithObjects:NSURLIsDirectoryKey, NSURLLocalizedNameKey, nil];
    
    for (NSURL *fileURL in [fm contentsOfDirectoryAtURL:url includingPropertiesForKeys:keys options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL]) {
        NSNumber *isDirNumber = nil;
        BOOL isDir;
        NSString *theUTI = [ws typeOfFile:[[[fileURL URLByStandardizingPath] URLByResolvingSymlinksInPath] path] error:NULL];
        NSString *filePath = [fileURL path];
        NSString *title = nil;
        NSDictionary *dict = nil;
        
        [fileURL getResourceValue:&title forKey:NSURLLocalizedNameKey error:NULL];
        [fileURL getResourceValue:&isDirNumber forKey:NSURLIsDirectoryKey error:NULL];
        isDir = [isDirNumber boolValue];
        
        NSScanner *scanner = [NSScanner scannerWithString:title];
        [scanner setCharactersToBeSkipped:nil];
        if ([scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL] && [scanner scanString:@"-" intoString:NULL])
            title = [title substringFromIndex:[scanner scanLocation]];
        
        if ([title isEqualToString:@"-"] || [title length] == 0) {
            dict = [[NSDictionary alloc] initWithObjectsAndKeys:filePath, FILENAME_KEY, nil];
        } else if (isAppleScriptUTI(theUTI) || isApplicationUTI(theUTI) || isAutomatorWorkflowUTI(theUTI) || ([fm isExecutableFileAtPath:filePath] && isDir == NO)) {
            static NSSet *scriptExtensions = nil;
            if (scriptExtensions == nil)
                scriptExtensions = [[NSSet alloc] initWithObjects:@"scpt", @"scptd", @"applescript", @"sh", @"csh", @"command", @"py", @"rb", @"pl", @"pm", @"app", @"workflow", nil];
            if ([scriptExtensions containsObject:[[title pathExtension] lowercaseString]])
                title = [title stringByDeletingPathExtension];
            dict = [[NSDictionary alloc] initWithObjectsAndKeys:filePath, FILENAME_KEY, title, TITLE_KEY, nil];
        } else if (isDir && isFolderUTI(theUTI) && depth < 3) {
            NSArray *content = [self directoryContentsAtURL:fileURL recursionDepth:depth + 1];
            if ([content count] > 0)
                dict = [[NSDictionary alloc] initWithObjectsAndKeys:filePath, FILENAME_KEY, title, TITLE_KEY, content, CONTENT_KEY, nil];
        }
        if (dict) {
            [files addObject:dict];
            [dict release];
        }
    }
    [files sortUsingDescriptors:sortDescriptors];
    return files;
}

- (void)executeScript:(id)sender {
    NSString *scriptFilename = [sender representedObject];
    NSString *theUTI = [[NSWorkspace sharedWorkspace] typeOfFile:[[scriptFilename stringByStandardizingPath] stringByResolvingSymlinksInPath] error:NULL];
    NSTask *task = nil;
    
    if (isAppleScriptUTI(theUTI)) {
        task = [[[NSTask alloc] init] autorelease];
        [task setLaunchPath:@"/usr/bin/osascript"];
        [task setArguments:[NSArray arrayWithObjects:scriptFilename, nil]];
    } else if (isAutomatorWorkflowUTI(theUTI)) {
        task = [[[NSTask alloc] init] autorelease];
        [task setLaunchPath:@"/usr/bin/automator"];
        [task setArguments:[NSArray arrayWithObjects:scriptFilename, nil]];
    } else if ([[NSFileManager defaultManager] isExecutableFileAtPath:scriptFilename]) {
        task = [[[NSTask alloc] init] autorelease];
        [task setLaunchPath:scriptFilename];
        [task setArguments:[NSArray array]];
    } else if (isApplicationUTI(theUTI)) {
        [[NSWorkspace sharedWorkspace] launchApplication:scriptFilename];
    }
    if (task) {
        [task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
        [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        @try { [task launch]; }
        @catch (id exception) {}
    }
}

@end


@implementation NSApplication (SKScriptMenu)

- (NSMenu *)scriptMenu {
    return [[SKScriptMenuController sharedController] scriptMenu];
}

@end
