//
//  SKStatusBar.h
//  Skim
//
//  Created by Christiaan Hofman on 7/8/07.
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

enum {
   SKProgressIndicatorNone = -1,
   SKProgressIndicatorBarStyle = NSProgressIndicatorBarStyle,
   SKProgressIndicatorSpinningStyle = NSProgressIndicatorSpinningStyle
};
typedef NSInteger SKProgressIndicatorStyle;


@interface SKStatusBar : NSView {
	id leftCell;
	id rightCell;
    id iconCell;
	NSProgressIndicator *progressIndicator;
    NSTrackingArea *leftTrackingArea;
    NSTrackingArea *rightTrackingArea;
    BOOL animating;
}

@property (nonatomic, readonly) BOOL isVisible;
@property (nonatomic, readonly, getter=isAnimating) BOOL animating;
@property (nonatomic, copy) NSString *leftStringValue, *rightStringValue;
@property (nonatomic) SEL leftAction, rightAction;
@property (nonatomic, assign) id leftTarget, rightTarget;
@property (nonatomic) NSInteger leftState, rightState;
@property (nonatomic, retain) NSFont *font; 
@property (nonatomic, retain) id iconCell; 
@property (nonatomic, readonly) NSProgressIndicator *progressIndicator;
@property (nonatomic) SKProgressIndicatorStyle progressIndicatorStyle;

- (void)toggleBelowView:(NSView *)view animate:(BOOL)animate;

- (void)startAnimation:(id)sender;
- (void)stopAnimation:(id)sender;

@end
