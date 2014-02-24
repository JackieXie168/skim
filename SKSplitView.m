//
//  SKSplitView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
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

#import "SKSplitView.h"
#import "SKStringConstants.h"

#define POSITION_KEY @"position"
#define DIVIDERINDEX_KEY @"dividerIndex"

@implementation SKSplitView

- (BOOL)isAnimating {
    return animating;
}

- (void)endAnimation:(NSDictionary *)info {
    [self setPosition:[[info objectForKey:POSITION_KEY] doubleValue] ofDividerAtIndex:[[info objectForKey:DIVIDERINDEX_KEY] integerValue]];
    animating = NO;
}

- (void)setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex animate:(BOOL)animate {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey])
        animate = NO;
    
    if (animating) {
        return;
    } else if (animate == NO) {
        [self setPosition:position ofDividerAtIndex:dividerIndex];
        return;
    }
    
    NSView *view1 = [[self subviews] objectAtIndex:dividerIndex];
    NSView *view2 = [[self subviews] objectAtIndex:dividerIndex + 1];
    NSSize size1 = [view1 frame].size;
    NSSize size2 = [view2 frame].size;
    BOOL collapsed1 = [self isSubviewCollapsed:view1];
    BOOL collapsed2 = [self isSubviewCollapsed:view2];
    CGFloat min = dividerIndex == 0 ? 0.0 : [self minPossiblePositionOfDividerAtIndex:dividerIndex];
    CGFloat thickness = [self dividerThickness];
    BOOL canHide = [[self delegate] respondsToSelector:@selector(splitView:shouldHideDividerAtIndex:)] &&
                   [[self delegate] splitView:self shouldHideDividerAtIndex:dividerIndex];
    
    if (collapsed1 && collapsed2)
        return;
    
    if ([self isVertical]) {
        if (collapsed1) {
            size1.width = 0.0;
            if (canHide && dividerIndex == 0) {
                size2.width -= thickness;
                if (size2.width < 0.0) {
                    size1.width += size2.width;
                    size2.width = 0.0;
                    if (size1.width < 0.0) {
                        [self setPosition:position ofDividerAtIndex:dividerIndex];
                        return;
                    }
                }
            }
            [view1 setFrameSize:size1];
            [view1 setHidden:NO];
            [view2 setFrameSize:size2];
        } else if (collapsed2) {
            size2.width = 0.0;
            if (canHide && dividerIndex == (NSInteger)[[self subviews] count] - 2) {
                size1.width -= thickness;
                if (size1.width < 0.0) {
                    size2.width += size1.width;
                    size1.width = 0.0;
                    if (size2.width < 0.0) {
                        [self setPosition:position ofDividerAtIndex:dividerIndex];
                        return;
                    }
                }
            }
            [view2 setFrameSize:size2];
            [view2 setHidden:NO];
            [view1 setFrameSize:size1];
        }
        size2.width -= position - min - size1.width;
        size1.width = position - min;
        if (size2.width < 0.0) {
            size1.width += size2.width;
            size2.width = 0.0;
        }
        if (size1.width < 0.0) {
            size2.width += size1.width;
            size1.width = 0.0;
        }
    } else {
        if (collapsed1) {
            size1.height = 0.0;
            if (canHide && dividerIndex == 0) {
                size2.height -= thickness;
                if (size2.height < 0.0) {
                    size1.height += size2.height;
                    size2.height = 0.0;
                    if (size1.height < 0.0) {
                        [self setPosition:position ofDividerAtIndex:dividerIndex];
                        return;
                    }
                }
            }
            [view1 setFrameSize:size1];
            [view1 setHidden:NO];
            [view2 setFrameSize:size2];
        } else if (collapsed2) {
            size2.height = 0.0;
            if (canHide && dividerIndex == (NSInteger)[[self subviews] count] - 2) {
                size1.height -= thickness;
                if (size1.height < 0.0) {
                    size2.height += size1.height;
                    size1.height = 0.0;
                    if (size2.height < 0.0) {
                        [self setPosition:position ofDividerAtIndex:dividerIndex];
                        return;
                    }
                }
            }
            [view2 setFrameSize:size2];
            [view2 setHidden:NO];
            [view1 setFrameSize:size1];
        }
        size2.height -= position - min - size1.height;
        size1.height = position - min;
        if (size2.height < 0.0) {
            size1.height += size2.height;
            size2.height = 0.0;
        }
        if (size1.height < 0.0) {
            size2.height += size1.height;
            size1.height = 0.0;
        }
    }
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:position], POSITION_KEY, [NSNumber numberWithInteger:dividerIndex], DIVIDERINDEX_KEY, nil];
    NSTimeInterval duration = [[NSAnimationContext currentContext] duration];
    
    animating = YES;
    [NSAnimationContext beginGrouping];
    [[view1 animator] setFrameSize:size1];
    [[view2 animator] setFrameSize:size2];
    [NSAnimationContext endGrouping];
    
    [self performSelector:@selector(endAnimation:) withObject:info afterDelay:duration]; 
}

@end
