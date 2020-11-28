//
//  SKHighlightingTableRowView.m
//  Skim
//
//  Created by Christiaan hofman on 22/04/2019.
/*
 This software is Copyright (c) 2019-2020
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

#import "SKHighlightingTableRowView.h"
#import "NSColor_SKExtensions.h"
#import "NSResponder_SKExtensions.h"
#import "SKStringConstants.h"

static char SKFirstResponderObservationContext;

@implementation SKHighlightingTableRowView

static BOOL supportsHighlights = YES;

+ (void)initialize {
    SKINITIALIZE;
    supportsHighlights = [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableHistoryHighlightsKey] == NO;
}

@synthesize highlightLevel;

- (void)dealloc {
    if (supportsHighlights && [self window]) {
        @try { [[self window] removeObserver:self forKeyPath:@"firstResponder"]; }
        @catch (id e) {}
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    [super dealloc];
}

- (BOOL)hasHighlights {
    return supportsHighlights && ([[self window] isKeyWindow] && [[[self window] firstResponder] isDescendantOf:[self superview]]);
}

- (void)setHighlightLevel:(NSInteger)newHighlightLevel {
    if (highlightLevel != newHighlightLevel) {
        highlightLevel = newHighlightLevel;
        [self setNeedsDisplay:YES];
    }
}

typedef struct { CGFloat r, g, b, a; } rgba;

static void evaluateHighlight(void *info, const CGFloat *in, CGFloat *out) {
    CGFloat x = fmin(1.0, 4.0 * fmin(in[0], 1.0 - in[0]));
    rgba color = *(rgba*)info;
    out[0] = color.r;
    out[1] = color.g;
    out[2] = color.b;
    out[3] = color.a * x * (2.0 - x);
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    if ([self isSelected] == NO && [self highlightLevel] > 0 && [self hasHighlights]) {
        NSRect rect = [[self viewAtColumn:0] frame];
        rgba color;
        [[[NSColor selectedMenuItemColor] colorUsingColorSpace:[NSColorSpace sRGBColorSpace]] getRed:&color.r green:&color.g blue:&color.b alpha:NULL];
        color.a = fmin(1.0, 0.1 * [self highlightLevel]);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        CGFloat domain[] = {0.0, 1.0};
        CGFloat range[] = {0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0};
        CGFunctionCallbacks callbacks = {0, &evaluateHighlight, NULL};
        CGFunctionRef function = CGFunctionCreate((void *)&color, 1, domain, 4, range, &callbacks);
        CGShadingRef shading = CGShadingCreateAxial(colorSpace, CGPointMake(NSMinX(rect), 0.0), CGPointMake(NSMaxX(rect), 0.0), function, false, false);
        CGColorSpaceRelease(colorSpace);
        CGContextDrawShading([[NSGraphicsContext currentContext] graphicsPort], shading);
        CGShadingRelease(shading);
    }
    
    [super drawBackgroundInRect:dirtyRect];
}

- (void)handleKeyOrMainStateChanged:(NSNotification *)note {
    if (supportsHighlights)
        [self setNeedsDisplay:YES];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    if (supportsHighlights) {
        NSWindow *oldWindow = [self window];
        NSArray *names = [NSArray arrayWithObjects:NSWindowDidBecomeMainNotification, NSWindowDidResignMainNotification, NSWindowDidBecomeKeyNotification, NSWindowDidResignKeyNotification, nil];
        if (oldWindow) {
            @try { [oldWindow removeObserver:self forKeyPath:@"firstResponder"]; }
            @catch (id e) {}
            for (NSString *name in names)
                [[NSNotificationCenter defaultCenter] removeObserver:self name:name object:oldWindow];
        }
        if (newWindow) {
            [newWindow addObserver:self forKeyPath:@"firstResponder" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:&SKFirstResponderObservationContext];
            for (NSString *name in names)
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyOrMainStateChanged:) name:name object:newWindow];
        }
    }
    [super viewWillMoveToWindow:newWindow];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKFirstResponderObservationContext) {
        if ([self highlightLevel] > 0) {
            id new = [change objectForKey:NSKeyValueChangeNewKey];
            id old = [change objectForKey:NSKeyValueChangeOldKey];
            if (new == [NSNull null]) new = nil;
            if (old == [NSNull null]) old = nil;
            if ([new isDescendantOf:[self superview]] != [old isDescendantOf:[self superview]])
                [self setNeedsDisplay:YES];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
