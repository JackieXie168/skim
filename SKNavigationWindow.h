//
//  SKNavigationWindow.h
//  Skim
//
//  Created by Christiaan Hofman on 12/19/06.
/*
 This software is Copyright (c) 2006-2009
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
#import "SKAnimatedBorderlessWindow.h"

@class SKPDFView, SKNavigationToolTipView, SKNavigationButton;

@interface SKNavigationWindow : SKAnimatedBorderlessWindow {
    SKNavigationButton *previousButton;
    SKNavigationButton *nextButton;
    SKNavigationButton *zoomButton;
    SKNavigationButton *closeButton;
    NSSlider *zoomSlider;
}
- (id)initWithPDFView:(SKPDFView *)pdfView hasSlider:(BOOL)hasSlider;
- (void)moveToScreen:(NSScreen *)screen;
- (void)handleScaleChangedNotification:(NSNotification *)notification;
@end


@interface SKNavigationContentView : NSView
@end


@interface SKNavigationToolTipWindow : NSWindow {
    SKNavigationToolTipView *toolTipView;
    NSView *view;
}
+ (id)sharedToolTipWindow;
- (void)showToolTip:(NSString *)toolTip forView:(NSView *)aView;
- (NSView *)view;
@end

@interface SKNavigationToolTipView : NSView {
    NSString *stringValue;
}
- (NSString *)stringValue;
- (void)setStringValue:(NSString *)newStringValue;
- (NSAttributedString *)attributedStringValue;
- (void)sizeToFit;
@end


@interface SKNavigationButton : NSButton

- (NSBezierPath *)path;
- (void)setPath:(NSBezierPath *)newPath;

- (NSBezierPath *)alternatePath;
- (void)setAlternatePath:(NSBezierPath *)newAlternatePath;

- (NSString *)alternateToolTip;
- (void)setAlternateToolTip:(NSString *)string;

@end


@interface SKNavigationButtonCell : NSButtonCell {
    NSString *toolTip;
    NSString *alternateToolTip;
    NSBezierPath *path;
    NSBezierPath *alternatePath;
}

- (NSString *)toolTip;
- (void)setToolTip:(NSString *)string;

- (NSString *)alternateToolTip;
- (void)setAlternateToolTip:(NSString *)string;

- (NSBezierPath *)path;
- (void)setPath:(NSBezierPath *)newPath;

- (NSBezierPath *)alternatePath;
- (void)setAlternatePath:(NSBezierPath *)newAlternatePath;

@end


@interface SKNavigationSlider : NSSlider {
    NSTrackingRectTag trackingRectTag;
    NSString *toolTip;
}

- (NSString *)toolTip;
- (void)setToolTip:(NSString *)string;

@end


@interface SKNavigationSliderCell : NSSliderCell
@end


@interface SKNavigationSeparator : NSView
@end
