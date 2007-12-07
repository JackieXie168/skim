//
//  BDSKGradientView.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/26/05.
/*
 This software is Copyright (c) 2005,2006,2007
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

#import "BDSKGradientView.h"
#import "NSBezierPath_CoreImageExtensions.h"
#import "CIImage_BDSKExtensions.h"

@interface BDSKGradientView (Private)

- (void)setDefaultColors;

@end

@implementation BDSKGradientView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    [self setDefaultColors];
    layer = NULL;
    return self;
}

- (void)dealloc
{
    CGLayerRelease(layer);
    [lowerColor release];
    [upperColor release];
    [super dealloc];
}

- (void)setBounds:(NSRect)aRect
{
    // since the gradient is vertical, we only have to reset the layer if the height changes; for most of our gradient views, this isn't likely to happen
    if (ABS(NSHeight(aRect) - NSHeight([self bounds])) > 0.01) {
        CGLayerRelease(layer);
        layer = NULL;
    }
    [super setBounds:aRect];
}


- (void)drawRect:(NSRect)aRect
{        
    // fill entire view, not just the (possibly clipped) aRect
    if ([[self window] styleMask] & NSClosableWindowMask) {
        
        CGContextRef viewContext = [[NSGraphicsContext currentContext] graphicsPort];
        NSRect bounds = [self bounds];

        if (NULL == layer) {
            NSSize layerSize = bounds.size;
            layer = CGLayerCreateWithContext(viewContext, *(CGSize *)&layerSize, NULL);
            
            CGContextRef layerContext = CGLayerGetContext(layer);
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:layerContext flipped:NO]];
            NSRect layerRect = NSZeroRect;
            layerRect.size = layerSize;
            
            [[NSBezierPath bezierPathWithRect:bounds] fillPathVerticallyWithStartColor:[self lowerColor] endColor:[self upperColor]];
            [NSGraphicsContext restoreGraphicsState];
        }
        
        // normal blend mode is copy
        CGContextSetBlendMode(viewContext, kCGBlendModeNormal);
        CGContextDrawLayerInRect(viewContext, *(CGRect *)&bounds, layer);
    }
}

// -[CIColor initWithColor:] fails (returns nil) with +[NSColor gridColor] rdar://problem/4789043
- (void)setLowerColor:(NSColor *)color
{
    [lowerColor autorelease];
    lowerColor = [[CIColor colorWithNSColor:color] retain];
}

- (void)setUpperColor:(NSColor *)color
{
    [upperColor autorelease];
    upperColor = [[CIColor colorWithNSColor:color] retain];
}    

- (CIColor *)lowerColor { return lowerColor; }
- (CIColor *)upperColor { return upperColor; }

// required in order for redisplay to work properly with the controls
- (BOOL)isOpaque{  return ([[self window] styleMask] & NSClosableWindowMask) != 0; }
- (BOOL)isFlipped { return NO; }

@end

@implementation BDSKGradientView (Private)

// provides an example implementation
- (void)setDefaultColors
{
    [self setLowerColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
    [self setUpperColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
}

@end
