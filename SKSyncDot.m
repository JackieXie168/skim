//
//  SKSyncDot.m
//  Skim
//
//  Created by Christiaan Hofman on 2/14/13.
/*
 This software is Copyright (c) 2013
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

#import "SKSyncDot.h"
#import "NSGeometry_SKExtensions.h"


@interface SKSyncDot (SKPrivate)
- (void)finish:(NSTimer *)aTimer;
- (void)animate:(NSTimer *)aTimer;
@end


@implementation SKSyncDot

@synthesize point, page;
@dynamic bounds;

- (id)initWithPoint:(NSPoint)aPoint page:(PDFPage *)aPage delegate:(id)aDelegate {
    self = [super init];
    if (self) {
        point = aPoint;
        page = [aPage retain];
        phase = 0.0;
        timer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(animate:) userInfo:NULL repeats:YES] retain];
        delegate = aDelegate;
        [delegate syncDotDidUpdate:self finished:NO];
    }
    return self;
}

- (void)dealloc {
    delegate = nil;
    [timer invalidate];
    SKDESTROY(timer);
    SKDESTROY(page);
    [super dealloc];
}

- (void)finish:(NSTimer *)aTimer {
    [timer invalidate];
    SKDESTROY(timer);
    [delegate syncDotDidUpdate:self finished:YES];
}

- (void)animate:(NSTimer *)aTimer {
    phase += 0.1;
    if (phase >= 1.0) {
        [timer invalidate];
        [timer release];
        timer = [[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(finish:) userInfo:NULL repeats:NO] retain];
    }
    [delegate syncDotDidUpdate:self finished:NO];
}

- (void)invalidate {
    [timer invalidate];
    SKDESTROY(timer);
    delegate = nil;
}

- (NSRect)bounds {
    return SKRectFromCenterAndSquareSize(point, 22.0);
}

- (void)draw {
    [NSGraphicsContext saveGraphicsState];
    
    CGFloat s = 6.0;
    if (phase < 1.0) {
        s += 8.0 * sin(phase * M_PI);
        NSShadow *shade = [[[NSShadow alloc] init] autorelease];
        [shade setShadowBlurRadius:2.0];
        [shade setShadowOffset:NSMakeSize(0.0, -2.0)];
        [shade set];
    } else {
        CGContextSetBlendMode([[NSGraphicsContext currentContext] graphicsPort], kCGBlendModeMultiply);        
    }
    
    [[NSColor redColor] setFill];
    [[NSBezierPath bezierPathWithOvalInRect:SKRectFromCenterAndSquareSize(point, s)] fill];
    
    [NSGraphicsContext restoreGraphicsState];
}

@end
