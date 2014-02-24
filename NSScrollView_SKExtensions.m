//
//  NSScrollView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/18/07.
/*
 This software is Copyright (c) 2007-2014
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

#import "NSScrollView_SKExtensions.h"
#import "SKRuntime.h"

#if !defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_6

enum {
   NSScrollerStyleLegacy,
   NSScrollerStyleOverlay
};
typedef NSInteger NSScrollerStyle;

@interface NSScroller (SKLionDeclarations)
+ (NSScrollerStyle)preferredScrollerStyle;
- (NSScrollerStyle)scrollerStyle;
- (void)setScrollerStyle:(NSScrollerStyle)newScrollerStyle;
@end

#endif


@interface SKPlacardView : NSView
- (void)tile;
@end


@implementation NSScrollView (SKExtensions)

static void (*original_setHasHorizontalScroller)(id, SEL, BOOL) = NULL;
static void (*original_setAutohidesScrollers)(id, SEL, BOOL) = NULL;
static void (*original_setScrollerStyle)(id, SEL, NSScrollerStyle) = NULL;
static void (*original_dealloc)(id, SEL) = NULL;
static void (*original_tile)(id, SEL) = NULL;

static NSMapTable *scrollViewPlacardViews = nil;

- (void)replacement_dealloc;
{
    [scrollViewPlacardViews removeObjectForKey:self];
    original_dealloc(self, _cmd);
}

- (void)replacement_setHasHorizontalScroller:(BOOL)flag;
{
    if ([scrollViewPlacardViews objectForKey:self] == nil)
        original_setHasHorizontalScroller(self, _cmd, flag);
}

- (void)replacement_setAutohidesScrollers:(BOOL)flag;
{
    if ([scrollViewPlacardViews objectForKey:self] == nil)
        original_setAutohidesScrollers(self, _cmd, flag);
}

- (void)replacement_setScrollerStyle:(NSScrollerStyle)newScrollerStyle;
{
    if ([scrollViewPlacardViews objectForKey:self] == nil)
        original_setScrollerStyle(self, _cmd, newScrollerStyle);
}

- (void)replacement_tile {
    original_tile(self, _cmd);
    
    SKPlacardView *placardView = [scrollViewPlacardViews objectForKey:self];
    if (placardView) {
        NSScroller *scroller = [self horizontalScroller];
        NSRect placardFrame, scrollerFrame = [scroller frame];
        [placardView tile];
        NSDivideRect(scrollerFrame, &placardFrame, &scrollerFrame, NSWidth([placardView frame]), NSMaxXEdge);
        [scroller setFrame:scrollerFrame];
        [placardView setFrame:placardFrame];
        if ([placardView isDescendantOf:self] == NO)
            [self addSubview:placardView];
    }
}

+ (void)load {
    original_setHasHorizontalScroller = (void (*)(id, SEL, BOOL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(setHasHorizontalScroller:), @selector(replacement_setHasHorizontalScroller:));
    original_setAutohidesScrollers = (void (*)(id, SEL, BOOL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(setAutohidesScrollers:), @selector(replacement_setAutohidesScrollers:));
    original_setScrollerStyle = (void (*)(id, SEL, NSScrollerStyle))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(setAutohidesScrollers:), @selector(replacement_setScrollerStyle:));
    original_dealloc = (void (*)(id, SEL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(dealloc), @selector(replacement_dealloc));
    original_tile = (void (*)(id, SEL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(tile), @selector(replacement_tile));
    
    // dictionary doesn't retain keys, so no retain cycles; pointer equality used to compare views
    scrollViewPlacardViews = [[NSMapTable alloc] initWithKeyOptions:NSMapTableZeroingWeakMemory | NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory | NSMapTableObjectPointerPersonality capacity:0];
}

- (NSArray *)placards {
    return [[scrollViewPlacardViews objectForKey:self] subviews];
}

- (void)setPlacards:(NSArray *)newPlacards {
    SKPlacardView *placardView = [[scrollViewPlacardViews objectForKey:self] retain];
    if (placardView == nil && [newPlacards count]) {
        placardView = [[SKPlacardView alloc] init];
        [scrollViewPlacardViews setObject:placardView forKey:self];
    }
    
    [placardView removeFromSuperview];
    [[[[placardView subviews] copy] autorelease] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (NSView *view in newPlacards)
        [placardView addSubview:view];
    
    if ([newPlacards count] != 0) {
        original_setHasHorizontalScroller(self, @selector(setHasHorizontalScroller:), YES);
        original_setAutohidesScrollers(self, @selector(setAutohidesScrollers:), NO);
        if (original_setScrollerStyle != NULL)
            original_setScrollerStyle(self, @selector(setScrollerStyle:), NSScrollerStyleOverlay);
    } else if (placardView) {
        [scrollViewPlacardViews removeObjectForKey:self];
        if (original_setScrollerStyle != NULL && [NSScroller respondsToSelector:@selector(preferredScrollerStyle)])
            original_setScrollerStyle(self, @selector(setScrollerStyle:), [NSScroller preferredScrollerStyle]);
    }
    [placardView release];
    
    [self tile];
}

@end


@implementation SKPlacardView

- (void)drawRect:(NSRect)aRect {
    NSImage *bgImage = [NSImage imageNamed:floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6 ? @"Scroller_Background_Lion" : @"Scroller_Background"];
    NSImage *divImage = [NSImage imageNamed:floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6 ? @"Scroller_Divider_Lion" : @"Scroller_Divider"];
    NSRect bgSrcRect = {NSZeroPoint, [bgImage size]};
    NSRect divSrcRect = {NSZeroPoint, [divImage size]};
    NSRect leftRect, rightRect, leftSrcRect, rightSrcRect, midSrcRect = bgSrcRect;
    NSRect midRect = [self bounds];
    NSRect divRect = midRect;
    CGFloat width = NSHeight(bgSrcRect);
    
    divRect.size.width = 1.0;
    midSrcRect.origin.x = floor(NSWidth(midSrcRect) / 2.0);
    midSrcRect.size.width = 1.0;
    NSDivideRect(bgSrcRect, &rightSrcRect, &bgSrcRect, width, NSMaxXEdge);
    NSDivideRect(bgSrcRect, &leftSrcRect, &bgSrcRect, width, NSMinXEdge);
    NSDivideRect(midRect, &rightRect, &midRect, width, NSMaxXEdge);
    NSDivideRect(midRect, &leftRect, &midRect, width, NSMinXEdge);
    
    [bgImage drawInRect:leftRect fromRect:leftSrcRect operation:NSCompositeSourceOver fraction:1.0];
    [bgImage drawInRect:rightRect fromRect:rightSrcRect operation:NSCompositeSourceOver fraction:1.0];
    if (NSWidth(midRect) > 0)
        [bgImage drawInRect:midRect fromRect:midSrcRect operation:NSCompositeSourceOver fraction:1.0];
    
    NSEnumerator *viewEnum = [[self subviews] objectEnumerator];
    NSView *view;
    CGFloat f = [[self window] isMainWindow] || [[self window] isKeyWindow] ? 1.0 : 0.33333;
    [viewEnum nextObject];
    while ((view = [viewEnum nextObject])) {
        divRect.origin.x = NSMinX([view frame]);
        [divImage drawInRect:divRect fromRect:divSrcRect operation:NSCompositeSourceOver fraction:f];
    }
}

- (void)tile {
    NSSize size = NSMakeSize(0.0, [NSScroller scrollerWidth]);
    for (NSView *view in [self subviews]) {
        NSRect rect = [view frame];
        rect.origin.x = size.width;
        rect.origin.y = 0.0;
        rect.size.height = size.height;
        [view setFrame:rect];
        size.width += NSWidth(rect) - 1.0;
    }
    size.width += 1.0;
    [self setFrameSize:size];
}

@end
