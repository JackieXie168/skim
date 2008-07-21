//
//  SKTransitionController.h
//  Skim
//
//  Created by Christiaan Hofman on 7/15/07.
/*
 This software is Copyright (c) 2007-2008
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

#pragma mark SKTransitionController

// this corresponds to the CGSTransitionType enum
typedef enum _SKAnimationTransitionStyle {
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
} SKAnimationTransitionStyle;

@class CIImage, SKTransitionWindow, SKTransitionView;

@interface SKTransitionController : NSWindowController {
    IBOutlet NSPopUpButton      *transitionStylePopUpButton;
    IBOutlet NSTextField        *transitionDurationField;
    IBOutlet NSSlider           *transitionDurationSlider;
    IBOutlet NSMatrix           *transitionExtentMatrix;
    IBOutlet SKTransitionWindow *transitionWindow;
    IBOutlet SKTransitionView   *transitionView;
    
    NSView *view;
    CIImage *initialImage;
    NSRect imageRect;
    
    NSMutableDictionary *filters;
    
    SKAnimationTransitionStyle transitionStyle;
    float duration;
    BOOL shouldRestrict;
}

+ (NSArray *)transitionFilterNames;

- (id)initWithView:(NSView *)aView;

- (NSView *)view;
- (void)setView:(NSView *)newView;

- (SKAnimationTransitionStyle)transitionStyle;
- (void)setTransitionStyle:(SKAnimationTransitionStyle)style;

- (float)duration;
- (void)setDuration:(float)newDuration;

- (BOOL)shouldRestrict;
- (void)setShouldRestrict:(BOOL)flag;

- (void)prepareAnimationForRect:(NSRect)rect;
- (void)animateForRect:(NSRect)rect forward:(BOOL)forward;

- (void)chooseTransitionModalForWindow:(NSWindow *)window;
- (IBAction)dismissTransitionSheet:(id)sender;

@end

#pragma mark -

@class SKTransitionAnimation, CIImage, CIContext;

@interface SKTransitionView : NSOpenGLView {
    SKTransitionAnimation *animation;
    CIImage *image;
    CIContext *context;
    BOOL needsReshape;
}
- (SKTransitionAnimation *)animation;
- (void)setAnimation:(SKTransitionAnimation *)newAnimation;
- (CIImage *)image;
- (void)setImage:(CIImage *)newImage;
- (CIImage *)currentImage;
@end

#pragma mark -

@interface SKTransitionWindow : NSWindow
@end
