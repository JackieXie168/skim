//
//  SKHighlightingTableRowView.m
//  Skim
//
//  Created by Christiaan hofman on 22/04/2019.
/*
 This software is Copyright (c) 2019
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

#define MAX_HIGHLIGHTS 5

@implementation SKHighlightingTableRowView

static BOOL supportsHighlights = YES;

+ (void)initialize {
    SKINITIALIZE;
    supportsHighlights = [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableHistoryHighlightsKey] == NO;
}

@synthesize highlightLevel;

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        highlightLevel = NSNotFound;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        highlightLevel = NSNotFound;
    }
    return self;
}

- (void)dealloc {
    if (supportsHighlights && [self window]) {
        @try { [[self window] removeObserver:self forKeyPath:@"firstResponder"]; }
        @catch (id e) {}
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    [super dealloc];
}

- (BOOL)hasHighlights {
    return supportsHighlights && (RUNNING_BEFORE(10_10) || ([[self window] isKeyWindow] && [[[self window] firstResponder] isDescendantOf:[self superview]]));
}

- (void)setHighlightLevel:(NSUInteger)newHighlightLevel {
    if (highlightLevel != newHighlightLevel) {
        highlightLevel = newHighlightLevel;
        [self setNeedsDisplay:YES];
    }
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    if ([self isSelected] == NO && [self highlightLevel] < MAX_HIGHLIGHTS && [self hasHighlights]) {
        NSColor *color = nil;
        if (RUNNING_BEFORE(10_10)) {
            NSWindow *window = [self window];
            if ([window isKeyWindow] && [[window firstResponder] isDescendantOf:[self superview]])
                color = [NSColor keySourceListHighlightColor];
            else if ([window isMainWindow] || [window isKeyWindow])
                color = [NSColor mainSourceListHighlightColor];
            else
                color = [NSColor disabledSourceListHighlightColor];
        } else {
            color = [[NSColor selectedMenuItemColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        }
        if (color && NSIntersectsRect([self bounds], dirtyRect)) {
            NSGradient *gradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[NSColor clearColor], [color  colorWithAlphaComponent:0.1 * (MAX_HIGHLIGHTS - [self highlightLevel])], [NSColor clearColor], nil]];
            [gradient drawInRect:[self bounds] angle:0.0];
            [gradient release];
        }
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
        id new = [change objectForKey:NSKeyValueChangeNewKey];
        id old = [change objectForKey:NSKeyValueChangeOldKey];
        if (new == [NSNull null]) new = nil;
        if (old == [NSNull null]) old = nil;
        if ([new isDescendantOf:[self superview]] != [old isDescendantOf:[self superview]])
            [self setNeedsDisplay:YES];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
