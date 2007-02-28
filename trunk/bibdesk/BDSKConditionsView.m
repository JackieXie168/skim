//
//  BDSKConditionsView.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 4/29/06.
/*
 This software is Copyright (c) 2005,2006,2007
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

#import "BDSKConditionsView.h"

#define SEPARATION 0.0l
#define MAX_HEIGHT 320.0f

@implementation BDSKConditionsView

// this makes it easier to place the subviews
- (BOOL)isFlipped {
    return YES;
}

- (NSSize)minimumSize { 
    NSArray *subviews = [self subviews];
    float height = ([subviews count] > 0) ? NSMaxY([[subviews lastObject] frame]) : 10.0f;
    return NSMakeSize(NSWidth([self frame]), height);
}

- (void)setFrameSize:(NSSize)newSize {
    if (newSize.height >= [self minimumSize].height) {        
        [super setFrameSize:newSize];
    }
}

- (void)updateSize {
    NSSize newSize = [self minimumSize];
    float oldHeight = NSHeight([self frame]);
    float newHeight = newSize.height;
    float dh = MIN(newHeight, MAX_HEIGHT) - MIN(oldHeight, MAX_HEIGHT);
    
    if (newHeight < oldHeight)
        [self setFrameSize:newSize];
    
    // resize the window up to a maximal size
    NSRect winFrame = [[self window] frame];
    winFrame.size.height += dh;
    winFrame.origin.y -= dh;
    [[self window] setFrame:winFrame display:YES animate:YES];
    
    if (newHeight > oldHeight)
        [self setFrameSize:newSize];
}

- (void)insertView:(NSView *)view atIndex:(unsigned int)index{
    NSArray *subviews = [[self subviews] copy];
    
    float yPosition = (index > 0) ? NSMaxY([[subviews objectAtIndex:index - 1] frame]) + SEPARATION : 0.0f;
    NSSize size = [view frame].size;
    int i, count = [subviews count];
    
    for (i = index; i < count; i++) 
        [[subviews objectAtIndex:i] removeFromSuperview];
    
    [view setFrameOrigin:NSMakePoint(0.0l, yPosition)];
    [view setFrameSize:NSMakeSize(NSWidth([self frame]), size.height)];
    [self addSubview:view];
    
    for (i = index; i < count; i++) {
        yPosition = NSMaxY([view frame]) + SEPARATION;
        view = [subviews objectAtIndex:i];
        [view setFrameOrigin:NSMakePoint(0.0l, yPosition)];
        [self addSubview:view];
    }
    
    [subviews release];
    
    [self updateSize];
    [self setNeedsDisplay:YES];
}

- (void)addView:(NSView *)view {
    [self insertView:view atIndex:[[self subviews] count]];
}

- (void)removeView:(NSView *)view {
    NSArray *subviews = [[[self subviews] copy] autorelease];
    int index = [subviews indexOfObjectIdenticalTo:view];
    
    if (index != NSNotFound) {
        NSView *view = [subviews objectAtIndex:index];
        NSPoint newPoint = [view frame].origin;
        float dy = NSHeight([view frame]) + SEPARATION;
        
        [view removeFromSuperview];
        
        int count = [subviews count];
        
        for (index++; index < count; index++) {
            view = [subviews objectAtIndex:index];
            [view setFrameOrigin:newPoint];
            newPoint.y += dy;
        }
        
        [self updateSize];
    }
    [self setNeedsDisplay:YES];
}

- (void)removeAllSubviews {
    NSArray *subviews = [[self subviews] copy];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperviewWithoutNeedingDisplay)];
    [subviews release];
    [self updateSize];
    [self setNeedsDisplay:YES];
}

@end
