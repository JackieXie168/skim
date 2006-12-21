//
//  SKNavigationWindow.h
//  Skim
//
//  Created by Christiaan Hofman on 19/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDFView, SKNavigationToolTipView, SKNavigationButton;

@interface SKNavigationWindow : NSWindow {
    NSMutableArray *buttons;
    NSViewAnimation *animation;
}
- (id)initWithPDFView:(PDFView *)pdfView;
- (void)hide;
@end


@interface SKNavigationContentView : NSView
@end


@interface SKNavigationToolTipWindow : NSWindow {
    SKNavigationToolTipView *toolTipView;
}
+ (id)sharedToolTipWindow;
- (void)showToolTip:(NSString *)toolTip forView:(NSView *)view;
@end

@interface SKNavigationToolTipView : NSView {
    NSString *stringValue;
}
- (NSString *)stringValue;
- (void)setStringValue:(NSString *)newStringValue;
- (NSAttributedString *)attributedStringValue;
- (NSAttributedString *)outlineAttributedStringValue;
- (void)sizeToFit;
@end


@interface SKNavigationButton : NSButton {
    NSString *alternateToolTip;
}
- (NSString *)currentToolTip;
- (NSString *)alternateToolTip;
- (void)setAlternateToolTip:(NSString *)string;
@end


@interface SKNavigationButtonCell : NSButtonCell
- (NSBezierPath *)pathWithFrame:(NSRect)cellFrame;
@end


@interface SKNavigationNextButton : SKNavigationButton
@end

@interface SKNavigationNextButtonCell : SKNavigationButtonCell
@end


@interface SKNavigationPreviousButton : SKNavigationButton
@end

@interface SKNavigationPreviousButtonCell : SKNavigationButtonCell
@end


@interface SKNavigationZoomButton : SKNavigationButton
@end

@interface SKNavigationZoomButtonCell : SKNavigationButtonCell
@end


@interface SKNavigationCloseButton : SKNavigationButton
@end

@interface SKNavigationCloseButtonCell : SKNavigationButtonCell
@end


@interface SKNavigationSeparatorButton : SKNavigationButton
@end

@interface SKNavigationSeparatorButtonCell : SKNavigationButtonCell
@end


@interface NSBezierPath (SKExtensions)

+ (void)fillRoundRectInRect:(NSRect)rect radius:(float)radius;
+ (void)strokeRoundRectInRect:(NSRect)rect radius:(float)radius;
+ (NSBezierPath*)bezierPathWithRoundRectInRect:(NSRect)rect radius:(float)radius;

@end
