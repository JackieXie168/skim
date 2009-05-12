//
//  NSScrollView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/18/07.
/*
 This software is Copyright (c) 2007-2009
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


@interface BDSKPlacardView : NSView
- (void)tile;
@end


@implementation NSScrollView (SKExtensions)

static void (*original_setHasHorizontalScroller)(id, SEL, BOOL) = NULL;
static void (*original_setAutohidesScrollers)(id, SEL, BOOL) = NULL;
static void (*original_dealloc)(id, SEL) = NULL;
static void (*original_tile)(id, SEL) = NULL;

static CFMutableDictionaryRef scrollViewPlacardViews = NULL;

- (void)replacement_dealloc;
{
    CFDictionaryRemoveValue(scrollViewPlacardViews, self);
    original_dealloc(self, _cmd);
}

- (void)replacement_setHasHorizontalScroller:(BOOL)flag;
{
    if (CFDictionaryContainsKey(scrollViewPlacardViews, self) == FALSE)
        original_setHasHorizontalScroller(self, _cmd, flag);
}

- (void)replacement_setAutohidesScrollers:(BOOL)flag;
{
    if (CFDictionaryContainsKey(scrollViewPlacardViews, self) == FALSE)
        original_setAutohidesScrollers(self, _cmd, flag);
}

- (void)replacement_tile {
    original_tile(self, _cmd);
    
    BDSKPlacardView *placardView = (BDSKPlacardView *)CFDictionaryGetValue(scrollViewPlacardViews, self);
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
    original_dealloc = (void (*)(id, SEL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(dealloc), @selector(replacement_dealloc));
    original_tile = (void (*)(id, SEL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(tile), @selector(replacement_tile));
    
    // dictionary doesn't retain keys, so no retain cycles; pointer equality used to compare views
    scrollViewPlacardViews = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, NULL, &kCFTypeDictionaryValueCallBacks);
}

- (NSArray *)placards {
    return [(NSView *)CFDictionaryGetValue(scrollViewPlacardViews, self) subviews];
}

- (void)setPlacards:(NSArray *)newPlacards {
    BDSKPlacardView *placardView = [(BDSKPlacardView *)CFDictionaryGetValue(scrollViewPlacardViews, self) retain];
    if (placardView == nil && [newPlacards count]) {
        placardView = [[BDSKPlacardView alloc] init];
        CFDictionarySetValue(scrollViewPlacardViews, self, placardView);
    }
    
    NSEnumerator *viewEnum = [newPlacards objectEnumerator];
    NSView *view;
    [placardView removeFromSuperview];
    [[[[placardView subviews] copy] autorelease] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    while (view = [viewEnum nextObject])
        [placardView addSubview:view];
    
    if ([newPlacards count] != 0) {
        original_setHasHorizontalScroller(self, @selector(setHasHorizontalScroller:), YES);
        original_setAutohidesScrollers(self, @selector(setAutohidesScrollers:), NO);
    } else if (placardView) {
        CFDictionaryRemoveValue(scrollViewPlacardViews, self);
    }
    [placardView release];
    
    [self tile];
}

@end


@implementation BDSKPlacardView

- (void)drawRect:(NSRect)aRect {
    NSImage *bgImage = [NSImage imageNamed:@"Scroller_Background"];
    NSImage *divImage = [NSImage imageNamed:@"Scroller_Divider"];
    NSRect bgSrcRect = {NSZeroPoint, [bgImage size]};
    NSRect divSrcRect = {NSZeroPoint, [divImage size]};
    NSRect leftRect, rightRect, leftSrcRect, rightSrcRect, midSrcRect = bgSrcRect;
    NSRect midRect = [self bounds];
    NSRect divRect = midRect;
    CGFloat width = NSHeight(bgSrcRect);
    
    divRect.size.width = 1.0;
    midSrcRect.origin.x = SKFloor(NSWidth(midSrcRect) / 2.0);
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
    NSView *view = [viewEnum nextObject];
    CGFloat f = [[self window] isMainWindow] || [[self window] isKeyWindow] ? 1.0 : 0.33333;
    while (view = [viewEnum nextObject]) {
        divRect.origin.x = NSMinX([view frame]) - 1;
        [divImage drawInRect:divRect fromRect:divSrcRect operation:NSCompositeSourceOver fraction:f];
    }
}

- (void)tile {
    NSSize size = NSMakeSize(1.0, [NSScroller scrollerWidth]);
    NSEnumerator *viewEnum = [[self subviews] objectEnumerator];
    NSView *view;
    while (view = [viewEnum nextObject]) {
        NSRect rect = [view frame];
        rect.origin.x = size.width;
        rect.origin.y = 0.0;
        rect.size.height = size.height;
        [view setFrame:rect];
        size.width += NSWidth(rect) + 1.0;
    }
    [self setFrameSize:size];
}

@end
