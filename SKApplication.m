//
//  SKApplication.m
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.
/*
 This software is Copyright (c) 2007-2008
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
#import "SKDocument.h"
#import "SKPDFSynchronizer.h"
#import "SKPDFView.h"
#import "NSString_SKExtensions.h"

NSString *SKApplicationStartsTerminatingNotification = @"SKApplicationStartsTerminatingNotification";

@interface NSApplication (NSApplicationPrivateDeclarations)
- (id)handleOpenScriptCommand:(NSScriptCommand *)command;
@end


@implementation SKApplication

- (BOOL)isUserAttentionDisabled {
    return userAttentionDisabled;
}

- (void)setUserAttentionDisabled:(BOOL)flag {
    userAttentionDisabled = flag;
}

- (int)requestUserAttention:(NSRequestUserAttentionType)requestType {
    return userAttentionDisabled ? 0 : [super requestUserAttention:requestType];
}

- (void)sendEvent:(NSEvent *)anEvent {
    if ([anEvent type] == NSScrollWheel && [anEvent modifierFlags] & NSAlternateKeyMask) {
        id target = [self targetForAction:@selector(magnifyWheel:)];
        if (target) {
            [target performSelector:@selector(magnifyWheel:) withObject:anEvent];
            return;
        }
    }
    [super sendEvent:anEvent];
}

- (IBAction)terminate:(id)sender {
    NSNotification *notification = [NSNotification notificationWithName:SKApplicationStartsTerminatingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    if ([[self delegate] respondsToSelector:@selector(applicationStartsTerminating:)])
        [[self delegate] applicationStartsTerminating:notification];
    [super terminate:sender];
}

- (void)handleOpenScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id file = [command directParameter];
	id lineNumber = [args objectForKey:@"line"];
 	id source = [args objectForKey:@"source"];
    
    if (lineNumber == nil || ([file isKindOfClass:[NSArray class]] && [file count] != 1)) {
        if ([[SKApplication superclass] instancesRespondToSelector:_cmd])
            [super handleOpenScriptCommand:command];
        return;
    }
	
    if ([file isKindOfClass:[NSArray class]])
        file = [file lastObject];
    if ([file isKindOfClass:[NSString class]])
        file = [NSURL fileURLWithPath:file];
    
    if (source == nil)
        source = file;
    if ([source isKindOfClass:[NSString class]])
        source = [NSURL fileURLWithPath:source];
    
    if ([file isKindOfClass:[NSURL class]] && [source isKindOfClass:[NSURL class]]) {
        
        source = [[source path] stringByReplacingPathExtension:@"tex"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[file path]]) {
            
            NSError *error = nil;
            SKDocument *document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:file display:YES error:&error];
            if (document == nil)
                [self presentError:error];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:source] && [document respondsToSelector:@selector(synchronizer)])
                [[document synchronizer] findPageLocationForLine:[lineNumber intValue] inFile:source];
            
        } else {
            [command setScriptErrorNumber:NSArgumentsWrongScriptError];
            [command setScriptErrorString:@"File does not exist."];
        }
    } else {
		[command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"File argument is not a file."];
    }
    
    return;
}

- (void)reorganizeWindowsItem:(NSWindow *)aWindow {
    NSMenu *windowsMenu = [self windowsMenu];
    NSWindowController *windowController = [aWindow windowController];
    NSWindowController *mainWindowController = [[[[aWindow windowController] document] windowControllers] objectAtIndex:0];
    int numberOfItems = [windowsMenu numberOfItems];
    int itemIndex = [windowsMenu indexOfItemWithTarget:aWindow andAction:@selector(makeKeyAndOrderFront:)];
    
    if (itemIndex != -1) {
        NSMenuItem *item = [windowsMenu itemAtIndex:itemIndex];
        NSString *title = [item title];
        
        if ([windowController document] == nil) {
            int anIndex = numberOfItems;
            while (anIndex-- && [[windowsMenu itemAtIndex:anIndex] isSeparatorItem] == NO && 
                   [[[[windowsMenu itemAtIndex:anIndex] target] windowController] document] == nil) {
                    if ([[[windowsMenu itemAtIndex:anIndex] title] caseInsensitiveCompare:title] == NSOrderedAscending)
                        break;
            }
            if (itemIndex != anIndex + 1) {
                [item retain];
                [windowsMenu removeItem:item];
                [windowsMenu insertItem:item atIndex:itemIndex <= anIndex ? anIndex : ++anIndex];
                [item release];
                if (anIndex > 0 && [[windowsMenu itemAtIndex:anIndex - 1] isSeparatorItem] == NO)
                    [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:anIndex];
            }
        } else if ([windowController isEqual:mainWindowController]) {
            NSMutableArray *subitems = [NSMutableArray array];
            NSMenuItem *anItem;
            int anIndex = numberOfItems;
            int nextIndex = numberOfItems;
            
            while (anIndex--) {
                anItem = [windowsMenu itemAtIndex:anIndex];
                if (anItem != item && [anItem action] == @selector(makeKeyAndOrderFront:)) {
                    id target = [anItem target];
                    NSWindowController *aMainWindowController = [[[[target windowController] document] windowControllers] objectAtIndex:0];
                    if ([aMainWindowController isEqual:mainWindowController]) {
                        [subitems insertObject:anItem atIndex:0];
                        [windowsMenu removeItemAtIndex:anIndex];
                        nextIndex--;
                        if (itemIndex > anIndex)
                            itemIndex--;
                    } else if ([aMainWindowController isEqual:[target windowController]]) {
                        NSComparisonResult comparison = [[anItem title] caseInsensitiveCompare:title];
                        if (comparison == NSOrderedDescending)
                            nextIndex = anIndex;
                    } else if ([[target windowController] document] == nil) {
                        nextIndex = anIndex;
                    }
                }
            }
            
            if (itemIndex != nextIndex) {
                [item retain];
                [windowsMenu removeItemAtIndex:itemIndex];
                if (nextIndex > itemIndex)
                    nextIndex--;
                if (itemIndex < [windowsMenu numberOfItems] && [[windowsMenu itemAtIndex:itemIndex] isSeparatorItem] && 
                    (itemIndex == [windowsMenu numberOfItems] - 1 || (itemIndex > 0 && [[windowsMenu itemAtIndex:itemIndex - 1] isSeparatorItem]))) {
                    [windowsMenu removeItemAtIndex:itemIndex];
                    if (nextIndex > itemIndex)
                        nextIndex--;
                }
                itemIndex = nextIndex++;
                [windowsMenu insertItem:item atIndex:itemIndex];
                [item release];
            }
            if (itemIndex > 1 && [[windowsMenu itemAtIndex:itemIndex - 1] isSeparatorItem] == NO) {
                [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex];
                nextIndex++;
            }
            
            NSEnumerator *itemEnum = [subitems objectEnumerator];
            while (anItem = [itemEnum nextObject])
                [windowsMenu insertItem:anItem atIndex:nextIndex++];
            
            if (nextIndex < [windowsMenu numberOfItems] && [[windowsMenu itemAtIndex:nextIndex] isSeparatorItem] == NO)
                [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:nextIndex];
            
        } else {
            int mainIndex = [windowsMenu indexOfItemWithTarget:[mainWindowController window] andAction:@selector(makeKeyAndOrderFront:)];
            int anIndex = mainIndex;
            
            [item setIndentationLevel:1];
            
            if (anIndex >= 0) {
                while (++anIndex < numberOfItems && [[windowsMenu itemAtIndex:anIndex] isSeparatorItem] == NO) {
                    if ([[[windowsMenu itemAtIndex:anIndex] title] caseInsensitiveCompare:title] == NSOrderedDescending)
                        break;
                }
                if (itemIndex != anIndex - 1) {
                    [item retain];
                    [windowsMenu removeItem:item];
                    [windowsMenu insertItem:item atIndex:itemIndex < anIndex ? --anIndex : anIndex];
                    [item release];
                }
            }
        }
    }
}

- (void)addWindowsItem:(NSWindow *)aWindow title:(NSString *)aString filename:(BOOL)isFilename {
    int itemIndex = [[self windowsMenu] indexOfItemWithTarget:aWindow andAction:@selector(makeKeyAndOrderFront:)];
    
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
    
    int anIndex = [[self windowsMenu] numberOfItems];
    BOOL wasSeparator = YES;
    
    while (anIndex--) {
        if ([[[self windowsMenu] itemAtIndex:anIndex] isSeparatorItem]) {
            if (wasSeparator)
                [[self windowsMenu] removeItemAtIndex:anIndex];
            else
                wasSeparator = YES;
        } else {
            wasSeparator = NO;
        }
    }
}

#pragma mark Scripting support

- (NSArray *)orderedDocuments {
    NSMutableArray *orderedDocuments = [[[super orderedDocuments] mutableCopy] autorelease];
    int i = [orderedDocuments count];
    
    while (i--)
        if ([[orderedDocuments objectAtIndex:i] isKindOfClass:[SKDocument class]] == NO)
            [orderedDocuments removeObjectAtIndex:i];
    
    return orderedDocuments;
}

@end
