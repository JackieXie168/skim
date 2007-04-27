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
#import "SKPDFSynchronizer.h"
#import "SKPDFView.h"

NSString *SKApplicationWillTerminateNotification = @"SKApplicationWillTerminateNotification";

@interface NSApplication (NSApplicationPrivateDeclarations)
- (id)handleOpenScriptCommand:(NSScriptCommand *)command;
@end


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

- (void)sendEvent:(NSEvent *)anEvent {
    id target = nil;
    if ([anEvent type] == NSScrollWheel && [anEvent modifierFlags] & NSAlternateKeyMask)
        target = [self targetForAction:@selector(magnifyWheel:)];
    if (target)
        [target performSelector:@selector(magnifyWheel:) withObject:anEvent];
    else
        [super sendEvent:anEvent];
}

- (IBAction)terminate:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKApplicationWillTerminateNotification object:self];
    [[NSUserDefaults standardUserDefaults] setObject:[[[NSDocumentController sharedDocumentController] documents] valueForKey:@"currentDocumentSetup"] forKey:SKLastOpenFileNamesKey];
    [super terminate:sender];
}

- (id)handleOpenScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id file = [command directParameter];
	id lineNumber = [args objectForKey:@"line"];
 	id source = [args objectForKey:@"source"];
   
    if (lineNumber == nil)
        return [super handleOpenScriptCommand:command];
	
    if (source == nil)
        source = file;
    
    if ([file isKindOfClass:[NSURL class]] == NO || [source isKindOfClass:[NSURL class]] == NO) {
		[command setScriptErrorNumber:NSArgumentsWrongScriptError];
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:[source path]]) {
        SKDocument *document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:file display:YES error:NULL];
        SKPDFSynchronizer *synchronizer = [document synchronizer];
        unsigned int pageIndex;
        NSPoint point;
        
        if ([synchronizer getPageIndex:&pageIndex location:&point forLine:[lineNumber intValue] inFile:[source path]])
            [[document pdfView] displayLineAtPoint:point inPageAtIndex:pageIndex];
    }
    
    return nil;
}

- (void)reorganizeWindowsItem:(NSWindow *)aWindow {
    NSMenu *windowsMenu = [self windowsMenu];
    NSWindowController *windowController = [aWindow windowController];
    SKMainWindowController *mainWindowController = [[windowController document] mainWindowController];
    int numberOfItems = [windowsMenu numberOfItems];
    int itemIndex = [windowsMenu indexOfItemWithTarget:aWindow];
    
    if (itemIndex != -1) {
        NSMenuItem *item = [windowsMenu itemAtIndex:itemIndex];
        
        if ([windowController document] == nil) {
            int index = numberOfItems;
            while (index-- && [[windowsMenu itemAtIndex:index] isSeparatorItem] == NO && 
                   [[[[windowsMenu itemAtIndex:index] target] windowController] document] == nil) {}
            if (index >= 0) {
                if (itemIndex < index) {
                    [item retain];
                    [windowsMenu removeItem:item];
                    [windowsMenu insertItem:item atIndex:index];
                    [item release];
                    index--;
                }
                if ([[windowsMenu itemAtIndex:index] isSeparatorItem] == NO)
                    [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:index + 1];
            }
        } else if ([windowController isEqual:mainWindowController]) {
            int index = itemIndex;
            if ([[windowsMenu itemAtIndex:itemIndex - 1] isSeparatorItem] == NO) {
                if ([[[[windowsMenu itemAtIndex:itemIndex - 1] target] windowController] document]) {
                    while (++index < numberOfItems && [[windowsMenu itemAtIndex:index] isSeparatorItem] == NO) {}
                    if (index == numberOfItems) {
                        [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:index];
                        numberOfItems++;
                    }
                } else {
                    while (--index >= 0 && [[windowsMenu itemAtIndex:index] isSeparatorItem] == NO) {}
                }
                itemIndex = index < itemIndex ? index + 1 : index;
                [item retain];
                [windowsMenu removeItem:item];
                [windowsMenu insertItem:item atIndex:itemIndex];
                [item release];
            }
            index = itemIndex;
            while (++index < numberOfItems && [[[[[windowsMenu itemAtIndex:index] target] windowController] document] isEqual:[windowController document]]) {}
            if (index < numberOfItems && [[windowsMenu itemAtIndex:index] isSeparatorItem] == NO)
                [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:index];
        } else {
            int mainIndex = [windowsMenu indexOfItemWithTarget:[mainWindowController window]];
            int index = mainIndex;
            
            [item setIndentationLevel:1];
            
            if (index >= 0) {
                while (++index < numberOfItems && [[windowsMenu itemAtIndex:index] isSeparatorItem] == NO) {}
                if (itemIndex < mainIndex || itemIndex > index) {
                    [item retain];
                    [windowsMenu removeItem:item];
                    [windowsMenu insertItem:item atIndex:itemIndex < index ? --index : index];
                    [item release];
                }
            }
        }
    }
}

- (void)addWindowsItem:(NSWindow *)aWindow title:(NSString *)aString filename:(BOOL)isFilename {
    int itemIndex = [[self windowsMenu] indexOfItemWithTarget:aWindow];
    
    [super addWindowsItem:aWindow title:aString filename:isFilename];
    
    if (itemIndex == -1)
        [self reorganizeWindowsItem:aWindow];
}

- (void)changeWindowsItem:(NSWindow *)aWindow title:(NSString *)aString filename:(BOOL)isFilename {
    [super changeWindowsItem:aWindow title:aString filename:isFilename];
    
    [self reorganizeWindowsItem:aWindow];
}

- (void)removeWindowsItem:(NSWindow *)aWindow {
    [super removeWindowsItem:aWindow];
    
    int index = [[self windowsMenu] numberOfItems];
    BOOL wasSeparator = YES;
    
    while (index--) {
        if ([[[self windowsMenu] itemAtIndex:index] isSeparatorItem]) {
            if (wasSeparator)
                [[self windowsMenu] removeItemAtIndex:index];
            else
                wasSeparator = YES;
        } else {
            wasSeparator = NO;
        }
    }
}

@end
