//
//  SKSheetController.m
//  Skim
//
//  Created by Christiaan Hofman on 9/21/07.
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

#import "SKSheetController.h"
#import "SKBookmarkController.h"
#import "SKBookmark.h"
#import "NSInvocation_SKExtensions.h"


@implementation SKSheetController

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo {
	[self prepare];
	
    theModalDelegate = delegate;
	theDidEndSelector = didEndSelector;
    theContextInfo = contextInfo;
	
	[self retain]; // make sure we stay around long enough
	
	[NSApp beginSheet:[self window]
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:NULL];
}

- (void)prepare {}

- (IBAction)dismiss:(id)sender {
	[self endSheetWithReturnCode:[sender tag]];
    [self release];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if(theModalDelegate != nil && theDidEndSelector != NULL){
		NSInvocation *invocation = [NSInvocation invocationWithTarget:theModalDelegate selector:theDidEndSelector argument:&self];
		[invocation setArgument:&returnCode atIndex:3];
		[invocation setArgument:&theContextInfo atIndex:4];
		[invocation invoke];
	}
}

- (void)endSheetWithReturnCode:(int)returnCode {
    [NSApp endSheet:[self window] returnCode:returnCode];
    [[self window] orderOut:self];
    
    theModalDelegate = nil;
    theDidEndSelector = NULL;
    theContextInfo = NULL;
}

- (NSTextField *)textField {
    [self window];
    return textField;
}

- (NSString *)stringValue {
    return [[self textField] stringValue];
}

- (void)setStringValue:(NSString *)string {
    [[self textField] setStringValue:string];
}

@end

#pragma mark -

@implementation SKPageSheetController : SKSheetController

- (NSString *)windowNibName { return @"PageSheet"; }

- (NSArray *)objectValues {
    return [(NSComboBox *)[self textField] objectValues];
}

- (void)setObjectValues:(NSArray *)objects {
    [(NSComboBox *)[self textField] removeAllItems];
    [(NSComboBox *)[self textField] addItemsWithObjectValues:objects];
}

@end

#pragma mark -

@implementation SKScaleSheetController : SKSheetController
- (NSString *)windowNibName { return @"ScaleSheet"; }
@end

#pragma mark -

@implementation SKBookmarkSheetController : SKSheetController

- (NSString *)windowNibName { return @"BookmarkSheet"; }

- (void)addMenuItemsForBookmarks:(NSArray *)bookmarks level:(int)level toMenu:(NSMenu *)menu {
    int i, iMax = [bookmarks count];
    for (i = 0; i < iMax; i++) {
        SKBookmark *bm = [bookmarks objectAtIndex:i];
        if ([bm bookmarkType] == SKBookmarkTypeFolder) {
            NSString *label = [bm label];
            NSMenuItem *item = [menu addItemWithTitle:label ? label : @"" action:NULL keyEquivalent:@""];
            [item setImage:[bm icon]];
            [item setIndentationLevel:level];
            [item setRepresentedObject:bm];
            [self addMenuItemsForBookmarks:[bm children] level:level+1 toMenu:menu];
        }
    }
}

- (void)prepare {
    SKBookmarkController *bookmarkController = [SKBookmarkController sharedBookmarkController];
    SKBookmark *root = [bookmarkController bookmarkRoot];
    [folderPopUp removeAllItems];
    NSMenuItem *item = [[folderPopUp menu] addItemWithTitle:NSLocalizedString(@"Bookmarks Menu", @"Menu item title") action:NULL keyEquivalent:@""];
    [item setImage:[NSImage imageNamed:@"SmallMenu"]];
    [item setRepresentedObject:root];
    [self addMenuItemsForBookmarks:[root children] level:1 toMenu:[folderPopUp menu]];
    [folderPopUp selectItemAtIndex:0];
}

- (SKBookmark *)selectedFolder {
    return [[folderPopUp selectedItem] representedObject];
}

@end

#pragma mark -

@implementation SKPasswordSheetController : SKSheetController
- (NSString *)windowNibName { return @"PasswordSheet"; }
@end
