//
//  SKPDFToolTipWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
/*
 This software is Copyright (c) 2007-2010
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

#import "SKPDFToolTipWindow.h"
#import "NSGeometry_SKExtensions.h"

#define WINDOW_OFFSET           20.0
#define ALPHA_VALUE             0.95
#define CRITICAL_ALPHA_VALUE    0.9
#define AUTO_HIDE_TIME_INTERVAL 7.0
#define DEFAULT_SHOW_DELAY      1.0
#define ALT_SHOW_DELAY          0.1


@interface NSScreen (SKExtensions)
+ (NSScreen *)screenForPoint:(NSPoint)point;
@end


@implementation SKPDFToolTipWindow

+ (id)sharedToolTipWindow {
    static SKPDFToolTipWindow *sharedToolTipWindow = nil;
    if (sharedToolTipWindow == nil)
        sharedToolTipWindow = [[self alloc] init];
    return sharedToolTipWindow;
}

- (id)init {
    if (self = [super initWithContentRect:NSZeroRect]) {
        [self setHidesOnDeactivate:NO];
        [self setIgnoresMouseEvents:YES];
        [self setOpaque:YES];
        [self setBackgroundColor:[NSColor whiteColor]];
        [self setHasShadow:YES];
        [self setLevel:NSStatusWindowLevel];
    
        
        NSImageView *imageView = [[NSImageView alloc] init];
        [imageView setImageFrameStyle:NSImageFrameNone];
        [[imageView enclosingScrollView] setDrawsBackground:NO];
        [self setContentView:imageView];
        [imageView release];
        
        context = nil;
        point = NSZeroPoint;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orderOut:) 
                                                     name:NSApplicationWillResignActiveNotification object:NSApp];
    }
    return self;
}

- (CGFloat)defaultAlphaValue { return ALPHA_VALUE; }

- (NSTimeInterval)autoHideTimeInterval { return AUTO_HIDE_TIME_INTERVAL; }

- (void)willClose {
    SKDESTROY(context);
    point = NSZeroPoint;
}

- (void)showDelayed {
    NSPoint thePoint = NSEqualPoints(point, NSZeroPoint) ? [NSEvent mouseLocation] : point;
    NSRect contentRect;
    NSImage *image = [context toolTipImage];
    
    [self cancelDelayedAnimations];
    
    if (image) {
        [(NSImageView *)[self contentView] setImage:image];
        
        contentRect.size = [image size];
        contentRect.origin.x = thePoint.x;
        contentRect.origin.y = thePoint.y - WINDOW_OFFSET - NSHeight(contentRect);
        contentRect = SKConstrainRect(contentRect, [[NSScreen screenForPoint:thePoint] visibleFrame]);
        [self setFrame:[self frameRectForContentRect:contentRect] display:NO];
        
        [self stopAnimation];
        if ([self isVisible] && [self alphaValue] > CRITICAL_ALPHA_VALUE)
            [self orderFront:self];
        else
            [self fadeIn];
        
    } else {
        
        [self fadeOut];
        
    }
}

- (void)cancelDelayedAnimations {
    [super cancelDelayedAnimations];
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showDelayed) object:nil];
}

- (void)showForPDFContext:(id<SKPDFToolTipContext>)aContext atPoint:(NSPoint)aPoint {
    point = aPoint;
    
    if ([aContext isEqual:context] == NO) {
        [self stopAnimation];
        
        [context release];
        context = [aContext retain];
        
        [self performSelector:@selector(showDelayed) withObject:nil afterDelay:[self isVisible] ? ALT_SHOW_DELAY : DEFAULT_SHOW_DELAY];
    }
}

- (id<SKPDFToolTipContext>)currentPDFContext {
    return context;
}

@end


static inline CGFloat SKSquaredDistanceFromPointToRect(NSPoint point, NSRect rect) {
    CGFloat dx, dy;

    if (point.x < NSMinX(rect))
        dx = NSMinX(rect) - point.x;
    else if (point.x > NSMaxX(rect))
        dx = point.x - NSMaxX(rect);
    else
        dx = 0.0;

    if (point.y < NSMinY(rect))
        dy = NSMinY(rect) - point.y;
    else if (point.y > NSMaxY(rect))
        dy = point.y - NSMaxY(rect);
    else
        dy = 0.0;
    
    return dx * dx + dy * dy;
}


@implementation NSScreen (SKExtensions)

+ (NSScreen *)screenForPoint:(NSPoint)point {
    NSScreen *screen = nil;
    CGFloat distanceSquared = CGFLOAT_MAX;
    
    for (NSScreen *aScreen in [NSScreen screens]) {
        NSRect frame = [aScreen frame];
        
        if (NSPointInRect(point, frame))
            return aScreen;
        
        CGFloat aDistanceSquared = SKSquaredDistanceFromPointToRect(point, frame);
        if (aDistanceSquared < distanceSquared) {
            distanceSquared = aDistanceSquared;
            screen = aScreen;
        }
    }
    
    return screen;
}

@end
