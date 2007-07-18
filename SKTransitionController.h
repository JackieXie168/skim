//
//  SKTransitionController.h
//  Skim
//
//  Created by Christiaan Hofman on 7/15/07.
/*
 This software is Copyright (c) 2007
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
#import <Carbon/Carbon.h>

#pragma mark Private Core Graphics types and functions

typedef int CGSConnection;
typedef int CGSWindow;

typedef enum _CGSTransitionType {
    CGSNone,
    CGSFade,
    CGSZoom,
    CGSReveal,
    CGSSlide,
    CGSWarpFade,
    CGSSwap,
    CGSCube,
    CGSWarpSwitch,
    CGSFlip
} CGSTransitionType;

typedef enum _CGSTransitionOption {
    CGSDown,
    CGSLeft,
    CGSRight,
    CGSInRight,
    CGSBottomLeft = 5,
    CGSBottomRight,
    CGSDownTopRight,
    CGSUp,
    CGSTopLeft,
    CGSTopRight,
    CGSUpBottomRight,
    CGSInBottom,
    CGSLeftBottomRight,
    CGSRightBottomLeft,
    CGSInBottomRight,
    CGSInOut
} CGSTransitionOption;

typedef struct _CGSTransitionSpec {
    uint32_t unknown1;
    CGSTransitionType type;
    CGSTransitionOption option;
    CGSWindow wid; // Can be 0 for full-screen
    float *backColour; // Null for black otherwise pointer to 3 float array with RGB value
} CGSTransitionSpec;

extern CGSConnection _CGSDefaultConnection(void);

extern OSStatus CGSNewTransition(const CGSConnection cid, const CGSTransitionSpec* spec, int *pTransitionHandle);
extern OSStatus CGSInvokeTransition(const CGSConnection cid, int transitionHandle, float duration);
extern OSStatus CGSReleaseTransition(const CGSConnection cid, int transitionHandle);

#pragma mark SKTransitionController

@class CIFilter, CIImage;

typedef enum _SKAnimationTransitionStyle {
	SKNoTransition = CGSNone,
    // Core Graphics transitions
	SKFadeTransition = CGSFade,
	SKZoomTransition = CGSZoom,
	SKRevealTransition = CGSReveal,
	SKSlideTransition = CGSSlide,
	SKWarpFadeTransition = CGSWarpFade,
	SKSwapTransition = CGSSwap,
	SKCubeTransition = CGSCube,
	SKWarpSwitchTransition = CGSWarpSwitch,
	SKWarpFlipTransition = CGSFlip,
    // Core Image transitions
    SKCoreImageTransition
    /*
    SKCopyMachineTransition,
    SKDisintegrateTransition,
    SKDissolveTransition,
    SKFlashTransition,
    SKModTransition,
    SKPageCurlTransition,
    SKRippleTransition,
    SKSwipeTransition*/
} SKAnimationTransitionStyle;

@class SKTransitionView;

@interface SKTransitionController : NSObject {
    NSWindow *transitionWindow;
    SKTransitionView *transitionView;
    NSView *view;
    CIImage *initialImage;
    NSRect imageRect;
}

+ (NSArray *)transitionFilterNames;

- (id)initWithView:(NSView *)aView;

- (NSView *)view;
- (void)setView:(NSView *)newView;

- (void)prepareForAnimationWithTransitionStyle:(SKAnimationTransitionStyle)transitionStyle fromRect:(NSRect)rect;
- (void)animateWithTransitionStyle:(SKAnimationTransitionStyle)transitionStyle direction:(CGSTransitionOption)direction duration:(float)duration fromRect:(NSRect)rect shouldRestrict:(BOOL)shouldRestrict;

@end
