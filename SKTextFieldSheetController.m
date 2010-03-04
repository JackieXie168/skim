//
//  SKTextFieldSheetController.m
//  Skim
//
//  Created by Christiaan Hofman on 9/29/08.
/*
 This software is Copyright (c) 2008-2010
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

#import "SKTextFieldSheetController.h"
#import "SKBookmarkController.h"
#import "SKBookmark.h"
#import "NSWindowController_SKExtensions.h"
#import "NSMenu_SKExtensions.h"

#define MIN_BUTTON_WIDTH  82.0
#define MAX_BUTTON_WIDTH  100.0
#define MIN_BUTTON_ORIGIN 14.0

@implementation SKTextFieldSheetController

- (NSString *)prompt { return @""; }

- (void)autosizeLabels {
    NSRect labelFrame = [labelField frame];
    NSRect textFrame = [textField frame];
    [labelField setStringValue:[self prompt]];
    [labelField sizeToFit];
    CGFloat dw = NSWidth([labelField frame]) - NSWidth(labelFrame);
    textFrame.size.width -= dw;
    textFrame.origin.x += dw;
    [textField setFrame:textFrame];
}

- (void)windowDidLoad {
    CGFloat width, right = NSMaxX([okButton frame]);
    NSRect cancelFrame, okFrame;
    [okButton setTitle:NSLocalizedString(@"OK", @"Button title")];
    [cancelButton setTitle:NSLocalizedString(@"Cancel", @"Button title")];
    [cancelButton sizeToFit];
    [okButton sizeToFit];
    cancelFrame = [cancelButton frame];
    okFrame = [okButton frame];
    width = fmin(MAX_BUTTON_WIDTH, fmax(MIN_BUTTON_WIDTH, fmax(NSWidth(cancelFrame), NSWidth(okFrame))));
    cancelFrame.size.width = fmax(NSWidth(cancelFrame), width);
    okFrame.size.width = fmax(NSWidth(okFrame), width);
    okFrame.origin.x = right - NSWidth(okFrame);
    cancelFrame.origin.x = NSMinX(okFrame) - NSWidth(cancelFrame);
    [cancelButton setFrame:cancelFrame];
    [okButton setFrame:okFrame];
    NSRect frame = [[self window] frame];
    if (NSMinX(cancelFrame) < MIN_BUTTON_ORIGIN) {
        frame.size.width += MIN_BUTTON_ORIGIN - NSMinX(cancelFrame);
        [[self window] setFrame:frame display:NO];
    }
    [self autosizeLabels];
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

@implementation SKPageSheetController

- (NSString *)windowNibName { return @"PageSheet"; }

- (NSString *)prompt { return NSLocalizedString(@"Page:", @"Prompt"); }

- (NSArray *)objectValues {
    return [(NSComboBox *)[self textField] objectValues];
}

- (void)setObjectValues:(NSArray *)objects {
    [(NSComboBox *)[self textField] removeAllItems];
    [(NSComboBox *)[self textField] addItemsWithObjectValues:objects];
}

@end

#pragma mark -

@implementation SKScaleSheetController

- (NSString *)windowNibName { return @"ScaleSheet"; }

- (NSString *)prompt { return NSLocalizedString(@"Scale:", @"Prompt"); }

@end

#pragma mark -

@implementation SKBookmarkSheetController

- (NSString *)windowNibName { return @"BookmarkSheet"; }

- (NSString *)prompt { return NSLocalizedString(@"Bookmark:", @"Prompt"); }

- (NSString *)folderPrompt { return NSLocalizedString(@"Add to:", @"Prompt"); }

- (void)autosizeLabels {
    [labelField setStringValue:[self prompt]];
    [folderLabelField setStringValue:[self folderPrompt]];
    NSRect labelFrame = [labelField frame];
    NSRect folderLabelFrame = [folderLabelField frame];
    NSRect textFrame = [textField frame];
    NSRect folderFrame = [folderPopUp frame];
    [labelField sizeToFit];
    [folderLabelField sizeToFit];
    CGFloat right = fmax(NSMaxX([labelField frame]), NSMaxX([folderLabelField frame]));
    CGFloat dw = right - NSMaxX(labelFrame);
    labelFrame.size.width = right - NSMinX(labelFrame);
    folderLabelFrame.size.width = right - NSMinX(labelFrame);
    textFrame.size.width -= dw;
    textFrame.origin.x += dw;
    folderFrame.size.width -= dw;
    folderFrame.origin.x += dw;
    [labelField setFrame:labelFrame];
    [folderLabelField setFrame:folderLabelFrame];
    [textField setFrame:textFrame];
    [folderPopUp setFrame:folderFrame];
}

- (void)addMenuItemsForBookmarks:(NSArray *)bookmarks level:(NSInteger)level toMenu:(NSMenu *)menu {
    for (SKBookmark *bm in bookmarks) {
        if ([bm bookmarkType] == SKBookmarkTypeFolder) {
            NSString *label = [bm label];
            NSMenuItem *item = [menu addItemWithTitle:label ?: @"" action:NULL keyEquivalent:@""];
            [item setImageAndSize:[bm icon]];
            [item setIndentationLevel:level];
            [item setRepresentedObject:bm];
            [self addMenuItemsForBookmarks:[bm children] level:level+1 toMenu:menu];
        }
    }
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo {
    SKBookmarkController *bookmarkController = [SKBookmarkController sharedBookmarkController];
    SKBookmark *root = [bookmarkController bookmarkRoot];
    [self window];
    [folderPopUp removeAllItems];
    [self addMenuItemsForBookmarks:[NSArray arrayWithObjects:root, nil] level:0 toMenu:[folderPopUp menu]];
    [folderPopUp selectItemAtIndex:0];
    
    [super beginSheetModalForWindow:window modalDelegate:delegate didEndSelector:didEndSelector contextInfo:contextInfo];
}

- (SKBookmark *)selectedFolder {
    return [[folderPopUp selectedItem] representedObject];
}

@end

#pragma mark -

@implementation SKPasswordSheetController

- (NSString *)windowNibName { return @"PasswordSheet"; }

- (NSString *)prompt { return NSLocalizedString(@"Password:", @"Prompt"); }

@end
