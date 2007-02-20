//
//  SKApplication.m
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKApplication.h"
#import "SKStringConstants.h"
#import "SKMainWindowController.h"
#import "SKDocument.h"

NSString *SKApplicationWillTerminateNotification = @"SKApplicationWillTerminateNotification";

@interface NSMenu (SKExtensions)
- (int)indexOfItemWithTarget:(id)target;
@end


@implementation NSMenu (SKExtensions)
- (int)indexOfItemWithTarget:(id)target {
    int index = [self numberOfItems];
    while (index--)
        if ([[self itemAtIndex:index] target] == target)
            break;
    return index;
}
@end


@implementation SKApplication

- (IBAction)terminate:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKApplicationWillTerminateNotification object:self];
    [[NSUserDefaults standardUserDefaults] setObject:[[[NSDocumentController sharedDocumentController] documents] valueForKey:@"currentDocumentSetup"] forKey:SKLastOpenFileNamesKey];
    [super terminate:sender];
}

- (void)addWindowsItem:(NSWindow *)aWindow title:(NSString *)aString filename:(BOOL)isFilename {
    [super addWindowsItem:aWindow title:aString filename:isFilename];
    
    NSWindowController *windowController = [aWindow windowController];
    SKMainWindowController *mainWindowController = [[windowController document] mainWindowController];
    NSMenu *windowsMenu = [self windowsMenu];
    int numberOfItems = [windowsMenu numberOfItems];
    int itemIndex = [windowsMenu indexOfItemWithTarget:aWindow];
    
    if ([windowController document] == nil) {
        int index = numberOfItems;
        while (index-- && [[windowsMenu itemAtIndex:index] isSeparatorItem] == NO && [[[[windowsMenu itemAtIndex:index] target] windowController] document] == nil) {}
        if (index >= 0) {
            if (itemIndex < index) {
                NSMenuItem *item = [[windowsMenu itemAtIndex:itemIndex] retain];
                [windowsMenu removeItem:item];
                [windowsMenu insertItem:item atIndex:index];
                [item release];
                index--;
            }
            if ([[windowsMenu itemAtIndex:index] isSeparatorItem] == NO)
                [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:index + 1];
        }
    } else if ([windowController isEqual:mainWindowController]) {
        if (itemIndex + 1 < numberOfItems && [[windowsMenu itemAtIndex:itemIndex + 1] isSeparatorItem] == NO)
            [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex + 1];
        if ([[windowsMenu itemAtIndex:itemIndex - 1] isSeparatorItem] == NO)
            [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex - 1];
    } else {
        NSWindow *mainWindow = [mainWindowController window];
        int index = [windowsMenu indexOfItemWithTarget:mainWindow];
        NSMenuItem *item = [windowsMenu itemAtIndex:itemIndex];
        
        [item setIndentationLevel:1];
        
        if (index >= 0) {
            while (++index < numberOfItems && [[windowsMenu itemAtIndex:index] isSeparatorItem] == NO) {}
            [item retain];
            [windowsMenu removeItem:item];
            [windowsMenu insertItem:item atIndex:itemIndex < index ? --index : index];
            [item release];
        }
    }
}

- (void)removeWindowsItem:(NSWindow *)aWindow {
    int index = [[self windowsMenu] indexOfItemWithTarget:aWindow];
    [super removeWindowsItem:aWindow];
    if ((index > 0) && (index < [[self windowsMenu] numberOfItems]) && [[[self windowsMenu] itemAtIndex:index - 1] isSeparatorItem])
        [[self windowsMenu] removeItemAtIndex:index - 1];
}

@end
