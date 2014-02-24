//
//  SKTransitionController.h
//  Skim
//
//  Created by Christiaan Hofman on 7/15/07.
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

#import <Cocoa/Cocoa.h>

extern NSString *SKStyleNameKey;
extern NSString *SKDurationKey;
extern NSString *SKShouldRestrictKey;

// this corresponds to the CGSTransitionType enum
enum {
	SKNoTransition,
    // Core Graphics transitions
	SKFadeTransition,
	SKZoomTransition,
	SKRevealTransition,
	SKSlideTransition,
	SKWarpFadeTransition,
	SKSwapTransition,
	SKCubeTransition,
	SKWarpSwitchTransition,
	SKWarpFlipTransition,
    // Core Image transitions
    SKCoreImageTransition
};
typedef NSUInteger SKAnimationTransitionStyle;

@class CIImage;

@interface SKTransitionController : NSWindowController {
    NSView *view;
    CIImage *initialImage;
    NSRect imageRect;
    
    NSMutableDictionary *filters;
    
    SKAnimationTransitionStyle transitionStyle;
    CGFloat duration;
    BOOL shouldRestrict;
    
    SKAnimationTransitionStyle currentTransitionStyle;
    CGFloat currentDuration;
    BOOL currentShouldRestrict;
    BOOL currentForward;
    
    NSArray *pageTransitions;
}

@property (nonatomic, assign) NSView *view;
@property (nonatomic) SKAnimationTransitionStyle transitionStyle;
@property (nonatomic) CGFloat duration;
@property (nonatomic) BOOL shouldRestrict;
@property (nonatomic, copy) NSArray *pageTransitions;
@property (nonatomic) BOOL hasTransition;

+ (NSArray *)transitionFilterNames;
+ (NSArray *)transitionNames;

+ (NSString *)nameForStyle:(SKAnimationTransitionStyle)style;
+ (SKAnimationTransitionStyle)styleForName:(NSString *)name;

+ (NSString *)localizedNameForStyle:(SKAnimationTransitionStyle)style;

- (id)initForView:(NSView *)aView;

- (void)prepareAnimationForRect:(NSRect)rect from:(NSUInteger)fromIndex to:(NSUInteger)toIndex;
- (void)animateForRect:(NSRect)rect;

@end
