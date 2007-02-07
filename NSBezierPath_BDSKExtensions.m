//
//  NSBezierPath_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/22/05.
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

#import "NSBezierPath_BDSKExtensions.h"


@implementation NSBezierPath (BDSKExtensions)

// code from http://www.cocoadev.com/index.pl?NSBezierPathCategory
// removed UK rect function calls, changed spacing/alignment

+ (void)fillRoundRectInRect:(NSRect)rect radius:(float)radius
{
    NSBezierPath *p = [self bezierPathWithRoundRectInRect:rect radius:radius];
    [p fill];
}


+ (void)strokeRoundRectInRect:(NSRect)rect radius:(float)radius
{
    NSBezierPath *p = [self bezierPathWithRoundRectInRect:rect radius:radius];
    [p stroke];
}

+ (NSBezierPath*)bezierPathWithRoundRectInRect:(NSRect)rect radius:(float)radius
{
    OBASSERT([NSThread inMainThread]);
    
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    radius = MIN(radius, 0.5f * MIN(NSHeight(rect), NSWidth(rect)));
    
    // Make sure silly values simply lead to un-rounded corners:
    if( radius <= 0 )
        return [self bezierPathWithRect:rect];
    
    NSRect innerRect = NSInsetRect(rect, radius, radius); // Make rect with corners being centers of the corner circles.
	static NSBezierPath *path = nil;
    if(path == nil)
        path = [[self bezierPath] retain];
    
    [path removeAllPoints];    
    
    // Now draw our rectangle:
    [path moveToPoint: NSMakePoint(NSMinX(innerRect) - radius, NSMinY(innerRect))];
    
    // Bottom left (origin):
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect), NSMinY(innerRect)) radius:radius startAngle:180.0 endAngle:270.0];
    // Bottom edge and bottom right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMinY(innerRect)) radius:radius startAngle:270.0 endAngle:360.0];
    // Left edge and top right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMaxY(innerRect)) radius:radius startAngle:0.0  endAngle:90.0 ];
    // Top edge and top left:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect), NSMaxY(innerRect)) radius:radius startAngle:90.0  endAngle:180.0];
    // Left edge:
    [path closePath];
    
    return path;
}

+ (void)drawHighlightInRect:(NSRect)rect radius:(float)radius lineWidth:(float)lineWidth color:(NSColor *)color
{
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:NSInsetRect(rect, 0.5 * lineWidth, 0.5 * lineWidth) radius:radius];
    [path setLineWidth:lineWidth];
    [[color colorWithAlphaComponent:0.2] setFill];
    [[color colorWithAlphaComponent:0.8] setStroke];
    [path fill];
    [path stroke];
}

+ (void)fillHorizontalOvalAroundRect:(NSRect)rect
{
    NSBezierPath *p = [self bezierPathWithHorizontalOvalAroundRect:rect];
    [p fill];
}


+ (void)strokeHorizontalOvalAroundRect:(NSRect)rect
{
    NSBezierPath *p = [self bezierPathWithHorizontalOvalAroundRect:rect];
    [p stroke];
}

+ (NSBezierPath*)bezierPathWithHorizontalOvalAroundRect:(NSRect)rect
{
    OBASSERT([NSThread inMainThread]);

    float radius = 0.5f * rect.size.height;
    
	static NSBezierPath *path = nil;
    if(path == nil)
        path = [[self bezierPath] retain];
    
    [path removeAllPoints];
    
    // Now draw our rectangle:
    [path moveToPoint: NSMakePoint(NSMinX(rect), NSMaxY(rect))];
    
    // Left half circle:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMidY(rect)) radius:radius startAngle:90.0 endAngle:270.0];
    // Bottom edge and right half circle:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMidY(rect)) radius:radius startAngle:-90.0 endAngle:90.0];
    // Top edge:
    [path closePath];
    
    return path;
}

+ (void)fillStarInRect:(NSRect)rect{
    [[self bezierPathWithStarInRect:rect] fill];
}

+ (void)fillInvertedStarInRect:(NSRect)rect{
    [[self bezierPathWithInvertedStarInRect:rect] fill];
}

+ (NSBezierPath *)bezierPathWithStarInRect:(NSRect)rect{
    float centerX = NSMidX(rect);
    float centerY = NSMidY(rect);
    float radiusX = 0.5 * NSWidth(rect);
    float radiusY = 0.5 * NSHeight(rect);
    int i = 0;
    
	static NSBezierPath *path = nil;
    if(path == nil)
        path = [[self bezierPath] retain];
    
    [path removeAllPoints];
    
    [path moveToPoint: NSMakePoint(NSMidX(rect), NSMaxY(rect))];
    while(++i < 5)
        [path lineToPoint:NSMakePoint(centerX + sin(0.8 * M_PI * i) * radiusX, centerY + cos(0.8 * M_PI * i) * radiusY)];
    [path closePath];
    
    return path;
}

+ (NSBezierPath *)bezierPathWithInvertedStarInRect:(NSRect)rect{
    float centerX = NSMidX(rect);
    float centerY = NSMidY(rect);
    float radiusX = 0.5 * NSWidth(rect);
    float radiusY = 0.5 * NSHeight(rect);
    int i;
    
	static NSBezierPath *path = nil;
    if(path == nil)
        path = [[self bezierPath] retain];
    
    [path removeAllPoints];
    
    [path moveToPoint:NSMakePoint(NSMidX(rect), NSMinY(rect))];
    for(i = 1; i < 5; i++)
        [path lineToPoint:NSMakePoint(centerX + sinf(0.8 * M_PI * i) * radiusX, centerY - cosf(0.8 * M_PI * i) * radiusY)];
    [path closePath];
    
    return path;
}

@end

