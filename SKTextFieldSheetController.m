//
//  SKTextFieldSheetController.m
//  Skim
//
//  Created by Christiaan Hofman on 9/29/08.
/*
 This software is Copyright (c) 2008-2009
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


@implementation SKTextFieldSheetController

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
@end

#pragma mark -

@implementation SKBookmarkSheetController

+ (NSImage *)menuIcon {
    static NSImage *menuIcon = nil;
    if (menuIcon == nil) {
        menuIcon = [[NSImage alloc] initWithSize:NSMakeSize(16.0, 16.0)];
        NSShadow *s = [[[NSShadow alloc] init] autorelease];
        [s setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.33333]];
        [s setShadowBlurRadius:2.0];
        [s setShadowOffset:NSMakeSize(0.0, -1.0)];
        [menuIcon lockFocus];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
        [NSBezierPath fillRect:NSMakeRect(1.0, 1.0, 14.0, 13.0)];
        [NSGraphicsContext saveGraphicsState];
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(2.0, 2.0)];
        [path lineToPoint:NSMakePoint(2.0, 15.0)];
        [path lineToPoint:NSMakePoint(7.0, 15.0)];
        [path lineToPoint:NSMakePoint(7.0, 13.0)];
        [path lineToPoint:NSMakePoint(14.0, 13.0)];
        [path lineToPoint:NSMakePoint(14.0, 2.0)];
        [path closePath];
        [[NSColor whiteColor] set];
        [s set];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
        [[NSColor colorWithCalibratedRed:0.162 green:0.304 blue:0.755 alpha:1.0] set];
        NSRectFill(NSMakeRect(2.0, 13.0, 5.0, 2.0));
        [[NSColor colorWithCalibratedRed:0.894 green:0.396 blue:0.202 alpha:1.0] set];
        NSRectFill(NSMakeRect(3.0, 4.0, 1.0, 1.0));
        NSRectFill(NSMakeRect(3.0, 7.0, 1.0, 1.0));
        NSRectFill(NSMakeRect(3.0, 10.0, 1.0, 1.0));
        [[NSColor colorWithCalibratedWhite:0.6 alpha:1.0] set];
        NSRectFill(NSMakeRect(5.0, 4.0, 1.0, 1.0));
        NSRectFill(NSMakeRect(5.0, 7.0, 1.0, 1.0));
        NSRectFill(NSMakeRect(5.0, 10.0, 1.0, 1.0));
        NSUInteger i, j;
        for (i = 0; i < 7; i++) {
            for (j = 0; j < 3; j++) {
                [[NSColor colorWithCalibratedWhite:0.45 + 0.1 * rand() / RAND_MAX alpha:1.0] set];
                NSRectFill(NSMakeRect(6.0 + i, 4.0 + 3.0 * j, 1.0, 1.0));
            }
        }
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] endingColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]] autorelease];
        [gradient drawInRect:NSMakeRect(2.0, 2.0, 12.0,11.0) angle:90.0];
        [menuIcon unlockFocus];
    }
    return menuIcon;
}

- (NSString *)windowNibName { return @"BookmarkSheet"; }

- (void)addMenuItemsForBookmarks:(NSArray *)bookmarks level:(NSInteger)level toMenu:(NSMenu *)menu {
    NSInteger i, iMax = [bookmarks count];
    for (i = 0; i < iMax; i++) {
        SKBookmark *bm = [bookmarks objectAtIndex:i];
        if ([bm bookmarkType] == SKBookmarkTypeFolder) {
            NSString *label = [bm label];
            NSMenuItem *item = [menu addItemWithTitle:label ?: @"" action:NULL keyEquivalent:@""];
            [item setImage:[bm icon]];
            [item setIndentationLevel:level];
            [item setRepresentedObject:bm];
            [self addMenuItemsForBookmarks:[bm children] level:level+1 toMenu:menu];
        }
    }
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo {
    SKBookmarkController *bookmarkController = [SKBookmarkController sharedBookmarkController];
    SKBookmark *root = [bookmarkController bookmarkRoot];
    [folderPopUp removeAllItems];
    NSMenuItem *item = [[folderPopUp menu] addItemWithTitle:NSLocalizedString(@"Bookmarks Menu", @"Menu item title") action:NULL keyEquivalent:@""];
    [item setImage:[[self class] menuIcon]];
    [item setRepresentedObject:root];
    [self addMenuItemsForBookmarks:[root children] level:1 toMenu:[folderPopUp menu]];
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
@end
