//
//  SKSplitView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
/*
 This software is Copyright (c) 2007-2016
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
#import "NSAnimationContext_SKExtensions.h"

NSString *SKSplitViewAnimationDidEndNotification = @"SKSplitViewAnimationDidEndNotification";

@implementation SKSplitView

+ (id)defaultAnimationForKey:(NSString *)key {
    if ([key isEqualToString:@"firstSplitPosition"] || [key isEqualToString:@"secondSplitPosition"])
        return [CABasicAnimation animation];
    else
        return [super defaultAnimationForKey:key];
}

- (CGFloat)firstSplitPosition {
    NSView *view = [[self subviews] objectAtIndex:0];
    if ([self isSubviewCollapsed:view])
        return [self minPossiblePositionOfDividerAtIndex:0];
    else if ([self isVertical])
        return NSMaxX([view frame]);
    else
        return NSMaxY([view frame]);
}

- (void)setFirstSplitPosition:(CGFloat)position {
    [self setPosition:position ofDividerAtIndex:0];
}

- (CGFloat)secondSplitPosition {
    NSView *view = [[self subviews] objectAtIndex:1];
    if ([self isSubviewCollapsed:view])
        return [self minPossiblePositionOfDividerAtIndex:1];
    else if ([self isVertical])
        return NSMaxX([view frame]);
    else
        return NSMaxY([view frame]);
}

- (void)setSecondSplitPosition:(CGFloat)position {
    [self setPosition:position ofDividerAtIndex:1];
}

- (BOOL)isAnimating {
    return animating;
}

- (void)setPosition:(CGFloat)position ofDividerAtIndex:(NSInteger)dividerIndex animate:(BOOL)animate {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey] || dividerIndex > 1)
        animate = NO;
    
    if (animating) {
        return;
    } else if (animate == NO) {
        [self setPosition:position ofDividerAtIndex:dividerIndex];
        return;
    }
    
    animating = YES;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            if (dividerIndex == 0)
                [[self animator] setFirstSplitPosition:position];
            else if (dividerIndex == 1)
                [[self animator] setSecondSplitPosition:position];
            else
                [self setPosition:position ofDividerAtIndex:dividerIndex];
        }
        completionHandler:^{
            animating = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:SKSplitViewAnimationDidEndNotification object:self];
    }];
}

@end
