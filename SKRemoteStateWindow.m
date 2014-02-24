//
//  SKRemoteStateWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 12/3/07.
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

#import "SKRemoteStateWindow.h"
#import "NSGeometry_SKExtensions.h"
#import "NSBezierPath_SKExtensions.h"
#import "SKStringConstants.h"

#define ALPHA_VALUE 0.95
#define WINDOW_SIZE 60.0

@interface SKRemoteStateView : NSView {
    SKRemoteState remoteState;
}
- (SKRemoteState)remoteState;
- (void)setRemoteState:(SKRemoteState)newRemoteState;
@end


@implementation SKRemoteStateWindow

+ (id)sharedRemoteStateWindow {
    static id sharedRemoteStateWindow = nil;
    if (sharedRemoteStateWindow == nil)
        sharedRemoteStateWindow = [[self alloc] init];
    return sharedRemoteStateWindow;
}

+ (NSTimeInterval)timeInterval {
    return [[NSUserDefaults standardUserDefaults] floatForKey:SKAppleRemoteSwitchIndicationTimeoutKey];
}

- (id)init {
    NSRect contentRect = SKRectFromCenterAndSquareSize(NSZeroPoint, WINDOW_SIZE);
    self = [super initWithContentRect:contentRect];
    if (self) {
        [self setIgnoresMouseEvents:YES];
        [self setDisplaysWhenScreenProfileChanges:NO];
        [self setLevel:NSStatusWindowLevel];
        [self setContentView:[[[SKRemoteStateView alloc] init] autorelease]];
    }
    return self;
}

- (CGFloat)defaultAlphaValue { return ALPHA_VALUE; }

- (NSTimeInterval)autoHideTimeInterval {
    return [[self class] timeInterval];
}

- (void)showWithType:(SKRemoteState)remoteState {
    if ([self autoHideTimeInterval] > 0.0) {
        [self stopAnimation];
        
        [self setFrame:SKRectFromCenterAndSize(SKCenterPoint([[NSScreen mainScreen] frame]), SKMakeSquareSize(60.0)) display:NO animate:NO];
        [(SKRemoteStateView *)[self contentView] setRemoteState:remoteState];
        
        [self orderFrontRegardless];
    }
}

+ (void)showWithType:(SKRemoteState)remoteState {
    if ([[self class] timeInterval] > 0.0)
        [[self sharedRemoteStateWindow] showWithType:remoteState];
}

@end

#pragma mark -

@implementation SKRemoteStateView

- (SKRemoteState)remoteState {
    return remoteState;
}

- (void)setRemoteState:(SKRemoteState)newRemoteState {
    remoteState = newRemoteState;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bounds];
    NSPoint center = SKCenterPoint(bounds);
    
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] setFill];
    [[NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:10.0 yRadius:10.0] fill];
    
    NSBezierPath *path = nil;
    
    if (remoteState == SKRemoteStateResize) {
        
        path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 20.0, 20.0) xRadius:3.0 yRadius:3.0];
        [path appendBezierPath:[NSBezierPath bezierPathWithRect:NSInsetRect(bounds, 24.0, 24.0)]];
        
        NSBezierPath *arrow = [NSBezierPath bezierPath];
        [arrow moveToPoint:NSMakePoint(NSMinX(bounds) + 10.0, NSMinY(bounds) + 10.0)];
        [arrow relativeLineToPoint:NSMakePoint(6.0, 0.0)];
        [arrow relativeLineToPoint:NSMakePoint(-2.0, 2.0)];
        [arrow relativeLineToPoint:NSMakePoint(2.0, 2.0)];
        [arrow relativeLineToPoint:NSMakePoint(2.0, -2.0)];
        [arrow relativeLineToPoint:NSMakePoint(0.0, 6.0)];
        [arrow relativeLineToPoint:NSMakePoint(-6.0, 0.0)];
        [arrow relativeLineToPoint:NSMakePoint(2.0, -2.0)];
        [arrow relativeLineToPoint:NSMakePoint(-2.0, -2.0)];
        [arrow relativeLineToPoint:NSMakePoint(-2.0, 2.0)];
        [arrow closePath];
        
        NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
        [transform translateXBy:center.x yBy:center.y];
        [transform rotateByDegrees:90.0];
        [transform translateXBy:-center.x yBy:-center.y];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        
        arrow = [NSBezierPath bezierPath];
        [arrow moveToPoint:NSMakePoint(NSMinX(bounds) + 5.0, NSMidY(bounds))];
        [arrow relativeLineToPoint:NSMakePoint(10.0, 5.0)];
        [arrow relativeLineToPoint:NSMakePoint(0.0, -10.0)];
        [arrow closePath];
        [path appendBezierPath:arrow];
        [transform translateXBy:center.x yBy:center.y];
        [transform rotateByDegrees:90.0];
        [transform translateXBy:-center.x yBy:-center.y];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        
        [path setWindingRule:NSEvenOddWindingRule];
        
    } else if (remoteState == SKRemoteStateScroll) {
        
        path = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(bounds, 8.0, 8.0)];
        [path appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(bounds, 9.0, 9.0)]];
        [path appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(bounds, 25.0, 25.0)]];
        
        NSBezierPath *arrow = [NSBezierPath bezierPath];
        [arrow moveToPoint:NSMakePoint(NSMidX(bounds), NSMinY(bounds) + 12.0)];
        [arrow relativeLineToPoint:NSMakePoint(7.0, 7.0)];
        [arrow relativeLineToPoint:NSMakePoint(-14.0, 0.0)];
        [arrow closePath];
        
        NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
        [transform translateXBy:center.x yBy:center.y];
        [transform rotateByDegrees:90.0];
        [transform translateXBy:-center.x yBy:-center.y];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
        [path appendBezierPath:arrow];
        
        [path setWindingRule:NSEvenOddWindingRule];
        
    }
    
    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setFill];
    [path fill];
}

@end
