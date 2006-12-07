//
//  BDSKGradientView.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/26/05.
/*
 This software is Copyright (c) 2005
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
#import <QuartzCore/QuartzCore.h>

@implementation BDSKGradientView

- (void)setDefaultColors
{
    [self setLowerColor:[NSColor headerColor]];
    [self setUpperColor:[NSColor gridColor]];
}

- (id)initWithFrame:(NSRect)frame
{
    if([super initWithFrame:frame] == nil)
        return nil;

    [self setDefaultColors];
    return self;
}

- (void)drawRect:(NSRect)aRect
{
    [[NSBezierPath bezierPathWithRect:aRect] fillPathVerticallyWithStartColor:startColor endColor:endColor];
}

- (void)setLowerColor:(NSColor *)color
{
    if(startColor != color){
        [startColor release];
        startColor = [color retain];
    }
}

- (void)setUpperColor:(NSColor *)color
{
    if(endColor != color){
        [endColor release];
        endColor = [color retain];
    }
}    

// required in order for redisplay to work properly with the controls
- (BOOL)isOpaque{ return YES; }

@end

@implementation NSBezierPath (CoreImage)


//
// Modified after http://www.cocoadev.com/index.pl?GradientFill
//
// TODO: implement angle parameter, adjust vectors

- (void)fillPathVerticallyWithStartColor:(NSColor *)inStartColor endColor:(NSColor *)inEndColor
{
    CIImage *image;    
    inStartColor = [inStartColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    inEndColor = [inEndColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    CIColor *startColor = [CIColor colorWithRed:[inStartColor redComponent] green:[inStartColor greenComponent] blue:[inStartColor blueComponent] alpha:[inStartColor alphaComponent]];
    CIColor *endColor = [CIColor colorWithRed:[inEndColor redComponent] green:[inEndColor greenComponent] blue:[inEndColor blueComponent] alpha:[inEndColor alphaComponent]];
    
    CIFilter *filter;
    
    filter = [CIFilter filterWithName:@"CILinearGradient"];
    [filter setValue:startColor forKey:@"inputColor0"];
    [filter setValue:endColor forKey:@"inputColor1"];
    
    CIVector *startVector;
    CIVector *endVector;
    
    NSRect aRect = [self bounds];
    float height = NSHeight(aRect);
    
    startVector = [CIVector vectorWithX:0.0 Y:0.0];
    endVector = [CIVector vectorWithX:0.0 Y:height];
    
    [filter setValue:startVector forKey:@"inputPoint0"];
    [filter setValue:endVector forKey:@"inputPoint1"];
    
    image = [filter valueForKey:@"outputImage"];
    
    [NSGraphicsContext saveGraphicsState];
    
    CIContext *context = [[NSGraphicsContext currentContext] CIContext];
    [context drawImage:image atPoint:CGPointZero fromRect:CGRectMake( 0.0, 0.0, NSWidth(aRect), height )];
    
    [NSGraphicsContext restoreGraphicsState];
}

@end
