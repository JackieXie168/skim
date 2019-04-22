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

#define MAX_HIGHLIGHTS 5

@implementation SKHighlightingTableRowView

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

- (void)setHighlightLevel:(NSUInteger)newHighlightLevel {
    if (highlightLevel != newHighlightLevel) {
        highlightLevel = newHighlightLevel;
        [self setNeedsDisplay:YES];
    }
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    [super drawBackgroundInRect:dirtyRect];
    
    if ([self isSelected] == NO && [self highlightLevel] < MAX_HIGHLIGHTS) {
        NSColor *color = nil;
        if (RUNNING_BEFORE(10_10)) {
            NSWindow *window = [self window];
            if ([window isKeyWindow] && [window firstResponder] == self)
                color = [NSColor keySourceListHighlightColor];
            else if ([window isMainWindow] || [window isKeyWindow])
                color = [NSColor mainSourceListHighlightColor];
            else
                color = [NSColor disabledSourceListHighlightColor];
        } else {
            color = [[NSColor selectedMenuItemColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        }
        if (color == nil)
            return;
        
        NSRect rect = [self bounds];
        if (NSIntersectsRect(rect, dirtyRect)) {
            NSGradient *gradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[NSColor clearColor], [color  colorWithAlphaComponent:0.1 * (MAX_HIGHLIGHTS - [self highlightLevel])], [NSColor clearColor], nil]];
            [gradient drawInRect:rect angle:0.0];
            [gradient release];
        }
    }
}

@end
