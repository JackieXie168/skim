//
//  SKApplication.m
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.
/*
 This software is Copyright (c) 2007
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
    NSMenu *windowsMenu = [self windowsMenu];
    int itemIndex = [windowsMenu indexOfItemWithTarget:aWindow];
    
    [super addWindowsItem:aWindow title:aString filename:isFilename];
    
    if (itemIndex >= 0)
        return;
    
    NSWindowController *windowController = [aWindow windowController];
    SKMainWindowController *mainWindowController = [[windowController document] mainWindowController];
    int numberOfItems = [windowsMenu numberOfItems];
    
    itemIndex = [windowsMenu indexOfItemWithTarget:aWindow];
    
    if ([windowController document] == nil) {
        int index = numberOfItems;
        while (index-- && [[windowsMenu itemAtIndex:index] isSeparatorItem] == NO && 
               [[[[windowsMenu itemAtIndex:index] target] windowController] document] == nil) {}
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
            [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex];
    } else {
        int index = [windowsMenu indexOfItemWithTarget:[mainWindowController window]];
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

- (void)changeWindowsItem:(NSWindow *)aWindow title:(NSString *)aString filename:(BOOL)isFilename {
    [super changeWindowsItem:aWindow title:aString filename:isFilename];
    
    NSWindowController *windowController = [aWindow windowController];
    int itemIndex = [[self windowsMenu] indexOfItemWithTarget:aWindow];
    NSMenuItem *item = itemIndex >= 0 ? [[self windowsMenu] itemAtIndex:itemIndex] : nil;
    
    if ([windowController document] && [windowController isEqual:[[windowController document] mainWindowController]] == NO)
        [item setIndentationLevel:1];
}

- (void)removeWindowsItem:(NSWindow *)aWindow {
    int index = [[self windowsMenu] indexOfItemWithTarget:aWindow];
    [super removeWindowsItem:aWindow];
    if ((index >= 0) && (index < [[self windowsMenu] numberOfItems]) && 
        [[[self windowsMenu] itemAtIndex:index - 1] isSeparatorItem])
        [[self windowsMenu] removeItemAtIndex:index - 1];
}

@end
