//
//  SKNavigationWindow.h
//  Skim
//
//  Created by Christiaan Hofman on 19/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PDFView;

@interface SKNavigationWindow : NSWindow {
    NSButton *zoomButton;
    NSViewAnimation *animation;
    NSTextField *labelField;
}
- (id)initWithPDFView:(PDFView *)pdfView;
- (void)hide;
@end


@interface SKNavigationContentView : NSView
@end


@interface SKNavigationLabelField : NSTextField
@end

@interface SKNavigationLabelFieldCell : NSTextFieldCell
@end


@interface SKNavigationButton : NSButton
- (NSString *)label;
@end


@interface SKNavigationButtonCell : NSButtonCell
- (NSBezierPath *)pathWithFrame:(NSRect)cellFrame;
- (NSString *)label;
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
