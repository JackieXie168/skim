//
//  SKImageToolTipWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
/*
 This software is Copyright (c) 2007-2020
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

#import "SKImageToolTipWindow.h"
#import "NSGeometry_SKExtensions.h"
#import "NSScreen_SKExtensions.h"
#import "NSView_SKExtensions.h"

#define WINDOW_OFFSET           18.0
#define ALPHA_VALUE             0.95
#define CRITICAL_ALPHA_VALUE    0.9
#define AUTO_HIDE_TIME_INTERVAL 10.0
#define DEFAULT_SHOW_DELAY      1.5
#define ALT_SHOW_DELAY          0.2
#if SDK_BEFORE(10_13)
#define WINDOW_LEVEL            104
#else
#define WINDOW_LEVEL            ((NSWindowLevel)104)
#endif

@implementation SKImageToolTipWindow

@synthesize currentImageContext=context;

static SKImageToolTipWindow *sharedToolTipWindow = nil;

+ (id)sharedToolTipWindow {
    if (sharedToolTipWindow == nil)
        sharedToolTipWindow = [[self alloc] init];
    return sharedToolTipWindow;
}

- (id)init {
    if (sharedToolTipWindow) NSLog(@"Attempt to allocate second instance of %@", self);
    self = [super initWithContentRect:NSZeroRect];
    if (self) {
        [self setHidesOnDeactivate:NO];
        [self setIgnoresMouseEvents:YES];
        [self setOpaque:YES];
        [self setBackgroundColor:[NSColor whiteColor]];
        [self setHasShadow:YES];
        [self setLevel:WINDOW_LEVEL];
        [self setDefaultAlphaValue:ALPHA_VALUE];
        [self setAutoHideTimeInterval:AUTO_HIDE_TIME_INTERVAL];
        context = nil;
        point = NSZeroPoint;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orderOut:) 
                                                     name:NSApplicationWillResignActiveNotification object:NSApp];
    }
    return self;
}

- (void)orderOut:(id)sender {
    SKDESTROY(context);
    point = NSZeroPoint;
    [super orderOut:sender];
}

- (void)fadeOut {
    SKDESTROY(context);
    point = NSZeroPoint;
    [super fadeOut];
}

- (void)showDelayed {
    NSPoint thePoint = NSEqualPoints(point, NSZeroPoint) ? [NSEvent mouseLocation] : point;
    NSRect contentRect = NSZeroRect, screenRect = [[NSScreen screenForPoint:thePoint] frame];
    NSImage *image = [context toolTipImage];
    BOOL isOpaque = [[[image representations] firstObject] isOpaque];
    
    if (image) {
        [self setBackgroundImage:image];
        
        if (RUNNING_AFTER(10_13)) {
            if (isOpaque) {
                if ([backgroundView window])
                    [self setContentView:[[[NSView alloc] init] autorelease]];
            } else if ([backgroundView window] == nil) {
                if (backgroundView == nil) {
                    backgroundView = [[NSView visualEffectViewWithMaterial:SKVisualEffectMaterialToolTip active:YES blendInWindow:NO] retain];
                    [backgroundView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
                    [self setOpaque:NO];
                }
                [self setContentView:backgroundView];
            }
        } else if (isOpaque) {
            [self setBackgroundColor:[NSColor whiteColor]];
        } else {
            static NSColor *backgroundColor = nil;
            if (backgroundColor == nil)
                backgroundColor = RUNNING_AFTER(10_9) ? [[NSColor colorWithCalibratedRed:0.95 green:0.95 blue:0.95 alpha:1.0] retain] : [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.75 alpha:1.0] retain];
            [self setBackgroundColor:backgroundColor];
        }
        
        contentRect.size = [image size];
        contentRect.origin.x = fmin(thePoint.x, NSMaxX(screenRect) - NSWidth(contentRect));
        contentRect.origin.y = thePoint.y - WINDOW_OFFSET - NSHeight(contentRect);
        contentRect = [self frameRectForContentRect:contentRect];
        if (NSMinY(contentRect) < NSMinX(screenRect))
            contentRect.origin.y = thePoint.y + WINDOW_OFFSET;
        [self setFrame:contentRect display:NO];
        
        if ([self isVisible] && [self alphaValue] > CRITICAL_ALPHA_VALUE)
            [self orderFront:self];
        else
            [self fadeIn];
        
    } else {
        
        [self fadeOut];
        
    }
}

- (void)stopAnimation {
    [super stopAnimation];
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showDelayed) object:nil];
}

- (void)showForImageContext:(id <SKImageToolTipContext>)aContext atPoint:(NSPoint)aPoint {
    point = aPoint;
    
    if ([aContext isEqual:context] == NO) {
        [self stopAnimation];
        
        [context release];
        context = [aContext retain];
        
        [self performSelector:@selector(showDelayed) withObject:nil afterDelay:[self isVisible] ? ALT_SHOW_DELAY : DEFAULT_SHOW_DELAY];
    }
}

@end
