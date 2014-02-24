//
//  NSMenu_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 6/11/08.
/*
 This software is Copyright (c) 2008-2014
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

#import "NSMenu_SKExtensions.h"


@implementation NSMenu (SKExtensions)

+ (NSMenu *)menu {
    return [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
}

- (NSMenuItem *)insertItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget atIndex:(NSInteger)anIndex {
    NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:aString action:aSelector target:aTarget];
    [self insertItem:item atIndex:anIndex];
    [item release];
    return item;
}

- (NSMenuItem *)addItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget {
    return [self insertItemWithTitle:aString action:aSelector target:aTarget atIndex:[self numberOfItems]];
}

- (NSMenuItem *)insertItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag atIndex:(NSInteger)anIndex {
    NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:aString action:aSelector target:aTarget tag:aTag];
    [self insertItem:item atIndex:anIndex];
    [item release];
    return item;
}

- (NSMenuItem *)addItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag {
    return [self insertItemWithTitle:aString action:aSelector target:aTarget tag:aTag atIndex:[self numberOfItems]];
}

- (NSMenuItem *)insertItemWithTitle:(NSString *)aString imageNamed:(NSString *)anImageName action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag atIndex:(NSInteger)anIndex {
    NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:aString imageNamed:anImageName action:aSelector target:aTarget tag:aTag];
    [self insertItem:item atIndex:anIndex];
    [item release];
    return item;
}

- (NSMenuItem *)addItemWithTitle:(NSString *)aString imageNamed:(NSString *)anImageName action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag {
    return [self insertItemWithTitle:aString imageNamed:anImageName action:aSelector target:aTarget tag:aTag atIndex:[self numberOfItems]];
}

- (NSMenuItem *)insertItemWithSubmenuAndTitle:(NSString *)aString atIndex:(NSInteger)anIndex {
    NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithSubmenuAndTitle:aString];
    [self insertItem:item atIndex:anIndex];
    [item release];
    return item;
}

- (NSMenuItem *)addItemWithSubmenuAndTitle:(NSString *)aString {
    return [self insertItemWithSubmenuAndTitle:aString atIndex:[self numberOfItems]];
}

@end


@implementation NSMenuItem (SKExtensions)

+ (NSMenuItem *)menuItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget {
    return [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:aString action:aSelector target:aTarget] autorelease];
}

+ (NSMenuItem *)menuItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag {
    return [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:aString action:aSelector target:aTarget tag:aTag] autorelease];
}

+ (NSMenuItem *)menuItemWithSubmenuAndTitle:(NSString *)aString {
    return [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithSubmenuAndTitle:aString] autorelease];
}

- (id)initWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget {
    return [self initWithTitle:aString imageNamed:nil action:aSelector target:aTarget tag:0];
}

- (id)initWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag {
    return [self initWithTitle:aString imageNamed:nil action:aSelector target:aTarget tag:aTag];
}

- (id)initWithTitle:(NSString *)aString imageNamed:(NSString *)anImageName action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag {
    self = [self initWithTitle:aString action:aSelector keyEquivalent:@""];
    if (self) {
        if (anImageName)
            [self setImage:[NSImage imageNamed:anImageName]];
        [self setTarget:aTarget];
        [self setTag:aTag];
    }
    return self;
}

- (id)initWithSubmenuAndTitle:(NSString *)aString {
    self = [self initWithTitle:aString action:NULL keyEquivalent:@""];
    if (self) {
        NSMenu *menu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:aString];
        [self setSubmenu:menu];
        [menu release];
    }
    return self;
}

- (void)setImageAndSize:(NSImage *)image {
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager setTypesetterBehavior:NSTypesetterBehavior_10_4];
    CGFloat lineHeight = [layoutManager defaultLineHeightForFont:[NSFont menuFontOfSize:0]];
    [layoutManager release];
    NSSize dstSize = { lineHeight, lineHeight };
    NSSize srcSize = [image size];
    if (NSEqualSizes(srcSize, dstSize)) {
        [self setImage:image];
    } else {
        NSImage *newImage = [[NSImage alloc] initWithSize:dstSize];
        [newImage lockFocus];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [image drawInRect:NSMakeRect(0, 0, dstSize.width, dstSize.height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationDefault];
        [newImage unlockFocus];
        [self setImage:newImage];
        [newImage release];
    }
}
        
@end
