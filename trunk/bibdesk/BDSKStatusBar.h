//
//  BDSKStatusBar.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 3/11/05.
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

#import <Cocoa/Cocoa.h>
#import "BDSKGradientView.h"

typedef enum {
   BDSKProgressIndicatorNone = -1,
   BDSKProgressIndicatorBarStyle = NSProgressIndicatorBarStyle,
   BDSKProgressIndicatorSpinningStyle = NSProgressIndicatorSpinningStyle
} BDSKProgressIndicatorStyle;


@interface BDSKStatusBar : BDSKGradientView {
	id textCell;
	NSImageCell *iconCell;
	NSProgressIndicator *progressIndicator;
	NSMutableArray *icons;
	id delegate;
    float textOffset;
}

+ (CIColor *)lowerColor;
+ (CIColor *)upperColor;

/*!
	@method toggleBelowView:offset:
	@abstract Toggles the visibility of the status bar in the window, resizes the view to cover or open up the frame occupied by the receiver.
	@discussion This only works properly when the receiver and view are the only subviews of a common superview (when the receiver is attached). 
		This can implicitly release the receiver, therefore the caller is responsible for retaining it when this is used. 
	@param view The view that should be resized.
	@param offset The extra amount by which the view should resize over the receivers height.
*/
- (void)toggleBelowView:(NSView *)view offset:(float)offset;

/*!
	@method toggleInWindow:offset:
	@abstract Toggles the visibility of the status bar in the window, resizes the window to make add or remove space for the receiver.
	@discussion This can implicitly release the receiver, therefore the caller is responsible for retaining it when this is used. 
	@param window The window that should be resized.
	@param offset The extra amount by which the window should resize over the receivers height.
*/
- (void)toggleInWindow:(NSWindow *)window offset:(float)offset;

/*!
	@method isVisible
	@abstract Returns a boolean indicating whether the receiver is shown and attached.
	@discussion -
*/
- (BOOL)isVisible;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)aString;

- (NSAttributedString *)attributedStringValue;
- (void)setAttributedStringValue:(NSAttributedString *)object;

- (NSFont *)font;
- (void)setFont:(NSFont *)fontObject;

- (id)textCell;
- (void)setTextCell:(NSCell *)aCell;

- (float)textOffset;
- (void)setTextOffset:(float)offset;

- (NSProgressIndicator *)progressIndicator;

/*!
	@method progressIndicatorStyle
	@abstract Returns whether the receiver is present and if it is, whether it is a bar indicator or spinning. 
	@discussion -
*/
- (BDSKProgressIndicatorStyle)progressIndicatorStyle;

/*!
	@method isVisible
	@abstract Sets whetherthe receiver has an indicator, and if so whether to use a bar indicator or spinning. 
	@discussion Use this rather than setStyle on the progressIndicator directly.
*/
- (void)setProgressIndicatorStyle:(BDSKProgressIndicatorStyle)style;

- (void)startAnimation:(id)sender;
- (void)stopAnimation:(id)sender;

- (NSArray *)iconIdentifiers;
- (void)addIcon:(NSImage *)icon withIdentifier:(NSString *)identifier;
- (void)addIcon:(NSImage *)icon withIdentifier:(NSString *)identifier toolTip:(NSString *)toolTip;
- (void)removeIconWithIdentifier:(NSString *)identifier;

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData;
- (void)rebuildToolTips;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

@end


@interface NSObject (BDSKStatusBarDelegate)
- (NSString *)statusBar:(BDSKStatusBar *)statusBar toolTipForIdentifier:(NSString *)identifier;
@end
