//
//  SKAnimatedBorderlessWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 3/13/08.
/*
 This software is Copyright (c) 2008-2015
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

#import "SKAnimatedBorderlessWindow.h"
#import "SKStringConstants.h"
#import "NSAnimationContext_SKExtensions.h"

#define ALPHA_VALUE 1.0
#define FADE_IN_DURATION 0.3
#define FADE_OUT_DURATION 1.0
#define AUTO_HIDE_TIME_INTERVAL 0.0


@implementation SKAnimatedBorderlessWindow

@synthesize defaultAlphaValue, autoHideTimeInterval;
@dynamic fadeInDuration, fadeOutDuration, backgroundImage;

- (id)initWithContentRect:(NSRect)contentRect {
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if (self) {
        defaultAlphaValue = ALPHA_VALUE;
        autoHideTimeInterval = AUTO_HIDE_TIME_INTERVAL;
		
        [self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
        [self setAlphaValue:[self defaultAlphaValue]];
        [self setReleasedWhenClosed:NO];
        [self setHidesOnDeactivate:NO];
        if ([self respondsToSelector:@selector(setAnimationBehavior:)])
            [self setAnimationBehavior:NSWindowAnimationBehaviorNone];
    }
    return self;
}

- (void)dealloc {
    [self stopAnimation];
    [super dealloc];
}

- (BOOL)canBecomeKeyWindow { return NO; }

- (BOOL)canBecomeMainWindow { return NO; }

- (BOOL)accessibilityIsIgnored { return YES; }

- (NSTimeInterval)fadeInDuration { return FADE_IN_DURATION; }

- (NSTimeInterval)fadeOutDuration { return FADE_OUT_DURATION; }

- (void)stopAnimation {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOut) object:nil];
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(remove) object:nil];
}

- (void)fadeOutAfterTimeout {
    if ([self autoHideTimeInterval] > 0.0)
        [self performSelector:@selector(fadeOut) withObject:nil afterDelay:[self autoHideTimeInterval]];
}

- (void)orderFront:(id)sender {
    [self stopAnimation];
    [self setAlphaValue:[self defaultAlphaValue]];
    [super orderFront:sender];
    [self fadeOutAfterTimeout];
}

- (void)orderFrontRegardless {
    [self stopAnimation];
    [self setAlphaValue:[self defaultAlphaValue]];
    [super orderFrontRegardless];
    [self fadeOutAfterTimeout];
}

- (void)orderOut:(id)sender {
    [self stopAnimation];
    [super orderOut:sender];
    [self setAlphaValue:[self defaultAlphaValue]];
}

- (void)remove {
    [self orderOut:nil];
}

- (void)fadeOut {
    [self stopAnimation];
    
    [self setAlphaValue:[self defaultAlphaValue]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey]) {
        [self remove];
    } else {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                [context setDuration:[self fadeOutDuration]];
                [[self animator] setAlphaValue:0.0];
            }
            completionHandler:nil];
        // don't put this in the completionHandler, because we want to be able to stop this using stopAnimation
        [self performSelector:@selector(remove) withObject:nil afterDelay:[self fadeOutDuration]];
    }
}

- (void)fadeIn {
    [self stopAnimation];
    
    if ([self isVisible] == NO)
        [self setAlphaValue:0.0];
    [super orderFront:self];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey]) {
        [self setAlphaValue:[self defaultAlphaValue]];
    } else {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                [context setDuration:[self fadeInDuration]];
                [[self animator] setAlphaValue:[self defaultAlphaValue]];
            }
            completionHandler:nil];
    }
    [self fadeOutAfterTimeout];
}

- (NSImage *)backgroundImage {
    return [[self contentView] respondsToSelector:@selector(image)] ? [(NSImageView *)[self contentView] image] : nil;
}

- (void)setBackgroundImage:(NSImage *)newBackgroundImage {
    NSImageView *imageView = nil;
    if ([[self contentView] respondsToSelector:@selector(setImage:)]) {
        imageView = (NSImageView *)[self contentView];
    } else if (newBackgroundImage) {
        imageView = [[NSImageView alloc] init];
        [imageView setEditable:NO];
        [imageView setImageFrameStyle:NSImageFrameNone];
        [imageView setImageScaling:NSImageScaleProportionallyUpOrDown];
        [self setContentView:imageView];
        [imageView release];
    }
    [imageView setImage:newBackgroundImage];
}

@end
