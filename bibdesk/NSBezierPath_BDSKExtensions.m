//
//  NSBezierPath_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/22/05.
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
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    if( radius >= (rect.size.height/2) )
        radius = truncf(rect.size.height/2) - 1;
    if( radius >= (rect.size.width/2) )
        radius = truncf(rect.size.width/2) - 1;
    
    // Make sure silly values simply lead to un-rounded corners:
    if( radius <= 0 )
        return [self bezierPathWithRect:rect];
    
    // Now draw our rectangle:
    NSRect innerRect = NSInsetRect(rect, radius, radius); // Make rect with corners being centers of the corner circles.
    NSBezierPath *path = [self bezierPath];
    
    [path moveToPoint: NSMakePoint(rect.origin.x,rect.origin.y +radius)];
    
    // Bottom left (origin):
    [path appendBezierPathWithArcWithCenter:innerRect.origin radius:radius startAngle:180.0 endAngle:270.0];
    [path relativeLineToPoint:NSMakePoint(NSWidth(innerRect), 0.0)]; // Bottom edge.
    
    // Bottom right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMinY(innerRect)) radius:radius startAngle:270.0 endAngle:360.0];
    [path relativeLineToPoint:NSMakePoint(0.0, NSHeight(innerRect))]; // Right edge.
    
    // Top right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMaxY(innerRect)) radius:radius startAngle:0.0  endAngle:90.0 ];
    [path relativeLineToPoint:NSMakePoint(-NSWidth(innerRect), 0.0)]; // Top edge.
    
    // Top left:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect),NSMaxY(innerRect)) radius:radius startAngle:90.0  endAngle:180.0];
    
    [path closePath]; // Implicitly causes left edge.
    
    return path;
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
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    float radius = rect.size.height/2;
    
    // Now draw our rectangle:
	NSBezierPath *path = [self bezierPath];
    
    [path moveToPoint: NSMakePoint(NSMinX(rect), NSMaxY(rect))];
    
    // Left half circle:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMidY(rect)) radius:radius startAngle:90.0 endAngle:270.0];
    // Bottom edge.
	[path relativeLineToPoint:NSMakePoint(NSWidth(rect), 0.0)];
    // Right half circle:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMidY(rect)) radius:radius startAngle:-90.0 endAngle:90.0];
    // Top edge.
    [path closePath];
    
    return path;
}

@end

