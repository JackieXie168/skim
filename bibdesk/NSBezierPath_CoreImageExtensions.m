//
//  NSBezierPath_CoreImageExtensions.m
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

#import "NSBezierPath_CoreImageExtensions.h"
#import "CIImage_BDSKExtensions.h"
#import <QuartzCore/QuartzCore.h>


@implementation NSBezierPath (BDSKGradientExtensions)


//
// Modified after http://www.cocoadev.com/index.pl?GradientFill
//

- (void)fillPathVertically:(BOOL)isVertical withStartColor:(CIColor *)startColor endColor:(CIColor *)endColor;
{
    NSRect bounds = [self bounds];
    CGRect aRect = *(CGRect*)&bounds;
    CGPoint startPoint = aRect.origin;
    CGPoint endPoint = startPoint;
    
    if(isVertical)
        endPoint.y += CGRectGetHeight(aRect);
    else
        endPoint.x += CGRectGetWidth(aRect);
        
    CIImage *image = [CIImage imageInRect:aRect withLinearGradientFromPoint:startPoint toPoint:endPoint fromColor:startColor toColor:endColor];
    
    NSGraphicsContext *nsContext = [NSGraphicsContext currentContext];
    [nsContext saveGraphicsState];
    
	[self addClip];
	
    [[nsContext CIContext] drawImage:image atPoint:aRect.origin fromRect:aRect];
    
    [nsContext restoreGraphicsState];
}

- (void)fillPathVerticallyWithStartColor:(CIColor *)inStartColor endColor:(CIColor *)inEndColor;
{
    [self fillPathVertically:YES withStartColor:inStartColor endColor:inEndColor];
}

- (void)fillPathWithHorizontalGradientFromColor:(CIColor *)fgStartColor toColor:(CIColor *)fgEndColor blendedAtTop:(BOOL)top ofVerticalGradientFromColor:(CIColor *)bgStartColor toColor:(CIColor *)bgEndColor;
{
    NSRect bounds = [self bounds];
    CGRect aRect = *(CGRect*)&bounds;
    
    CIImage *image = [CIImage imageInRect:aRect withHorizontalGradientFromColor:fgStartColor toColor:fgEndColor blendedAtTop:top ofVerticalGradientFromColor:bgStartColor toColor:bgEndColor];
    
    NSGraphicsContext *nsContext = [NSGraphicsContext currentContext];
    [nsContext saveGraphicsState];
    
	[self addClip];
	
    [[nsContext CIContext] drawImage:image atPoint:aRect.origin fromRect:aRect];
    
    [nsContext restoreGraphicsState];
}

- (void)fillPathWithVerticalGradientFromColor:(CIColor *)fgStartColor toColor:(CIColor *)fgEndColor blendedAtRight:(BOOL)right ofHorizontalGradientFromColor:(CIColor *)bgStartColor toColor:(CIColor *)bgEndColor;
{
    NSRect bounds = [self bounds];
    CGRect aRect = *(CGRect*)&bounds;
    
    CIImage *image = [CIImage imageInRect:aRect withVerticalGradientFromColor:fgStartColor toColor:fgEndColor blendedAtRight:right ofHorizontalGradientFromColor:bgStartColor toColor:bgEndColor];
    
    NSGraphicsContext *nsContext = [NSGraphicsContext currentContext];
    [nsContext saveGraphicsState];
    
	[self addClip];
	
    [[nsContext CIContext] drawImage:image atPoint:aRect.origin fromRect:aRect];
    
    [nsContext restoreGraphicsState];
}

- (void)fillPathWithColor:(CIColor *)fgColor blendedAtRight:(BOOL)right ofVerticalGradientFromColor:(CIColor *)bgStartColor toColor:(CIColor *)bgEndColor;
{
    NSRect bounds = [self bounds];
    CGRect aRect = *(CGRect*)&bounds;
    
    CIImage *image = [CIImage imageInRect:aRect withColor:fgColor blendedAtRight:right ofVerticalGradientFromColor:bgStartColor toColor:bgEndColor];
    
    NSGraphicsContext *nsContext = [NSGraphicsContext currentContext];
    [nsContext saveGraphicsState];
    
	[self addClip];
	
    [[nsContext CIContext] drawImage:image atPoint:aRect.origin fromRect:aRect];
    
    [nsContext restoreGraphicsState];
}

@end
