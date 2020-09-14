//
//  SKReflectionView.m
//  Skim
//
//  Created by Christiaan Hofman on 14/09/2020.
/*
This software is Copyright (c) 2020
Adam Maxwell. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

- Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in
the documentation and/or other materials provided with the
distribution.

- Neither the name of Adam Maxwell nor the names of any
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

#import "SKReflectionView.h"
#import "NSView_SKExtensions.h"


@implementation SKReflectionView

@synthesize reflectedScrollView;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SKDESTROY(reflectedScrollView);
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    if ([reflectedScrollView window] == nil || [reflectedScrollView window] != [self window])
        return;
    NSView *view = [[self reflectedScrollView] documentView];
    if (view == nil)
        return;
    NSRect rect = NSIntersectionRect([self convertRect:[self bounds] toView:view], [view bounds]);
    if (NSIsEmptyRect(rect))
        return;
    NSBitmapImageRep *imageRep = [view bitmapImageRepCachingDisplayInRect:rect];
    rect = [self convertRect:rect fromView:view];
    [imageRep drawInRect:rect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0 respectFlipped:YES hints:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:NSImageInterpolationNone], NSImageHintInterpolation, nil]];
}

- (void)reflectedSscrollBoundsChanged:(NSNotification *)notification {
    [self setNeedsDisplay:YES];
}

- (void)setReflectedScrollView:(NSScrollView *)view {
    if (view != reflectedScrollView) {
        if (reflectedScrollView)
             [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:[reflectedScrollView contentView]];
        [reflectedScrollView release];
        reflectedScrollView = [view retain];
        if (reflectedScrollView)
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reflectedSscrollBoundsChanged:) name:NSViewBoundsDidChangeNotification object:[reflectedScrollView contentView]];
        [self setNeedsDisplay:YES];
    }
}

@end
