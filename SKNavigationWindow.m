//
//  SKNavigationWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 12/19/06.
/*
 This software is Copyright (c) 2006,2007
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

#import "SKNavigationWindow.h"
#import <Quartz/Quartz.h>
#import "NSBezierPath_BDSKExtensions.h"
#import "SKMainWindowController.h"
#import "NSParagraphStyle_SKExtensions.h"

#define BUTTON_WIDTH 50.0
#define SEP_WIDTH 21.0
#define MARGIN 7.0
#define OFFSET 20.0
#define LABEL_OFFSET 10.0
#define LABEL_TEXT_MARGIN 2.0

@implementation SKNavigationWindow

- (id)initWithPDFView:(PDFView *)pdfView {
    NSScreen *screen = [[pdfView window] screen];
    if (screen == nil)
        screen = [NSScreen mainScreen];
    float width = 4 * BUTTON_WIDTH + 2 * SEP_WIDTH + 2 * MARGIN;
    NSRect contentRect = NSMakeRect(NSMidX([screen frame]) - 0.5 * width, NSMinY([screen frame]) + OFFSET, width, BUTTON_WIDTH + 2 * MARGIN);
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen]) {
        NSWindowController *controller = [[pdfView window] windowController];
        
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        [self setLevel:[[pdfView window] level]];
        [self setHidesOnDeactivate:YES];
        [self setMovableByWindowBackground:YES];
        
        [self setContentView:[[[SKNavigationContentView alloc] init] autorelease]];
        
        NSRect rect = NSMakeRect(MARGIN, MARGIN, BUTTON_WIDTH, BUTTON_WIDTH);
        SKNavigationButton *button = [[[SKNavigationPreviousButton alloc] initWithFrame:rect] autorelease];
        [button setTarget:controller];
        [button setAction:@selector(doGoToPreviousPage:)];
        [button setToolTip:NSLocalizedString(@"Previous", @"Tool tip message")];
        [[self contentView] addSubview:button];
        [button addTrackingRect:NSInsetRect([button bounds], 3.0, 0.0) owner:button userData:nil assumeInside:NO];
        
        rect.origin.x = NSMaxX(rect);
        button = [[[SKNavigationNextButton alloc] initWithFrame:rect] autorelease];
        [button setTarget:controller];
        [button setAction:@selector(doGoToNextPage:)];
        [button setToolTip:NSLocalizedString(@"Next", @"Tool tip message")];
        [[self contentView] addSubview:button];
        [button addTrackingRect:NSInsetRect([button bounds], 3.0, 0.0) owner:button userData:nil assumeInside:NO];
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = SEP_WIDTH;
        button = [[[SKNavigationSeparatorButton alloc] initWithFrame:rect] autorelease];
        [[self contentView] addSubview:button];
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = BUTTON_WIDTH;
        button = [[[SKNavigationZoomButton alloc] initWithFrame:rect] autorelease];
        [button setTarget:controller];
        [button setAction:@selector(toggleAutoActualSize:)];
        [button setToolTip:NSLocalizedString(@"Fit to Screen", @"Tool tip message")];
        [button setAlternateToolTip:NSLocalizedString(@"Actual Size", @"Tool tip message")];
        [button setState:[pdfView autoScales]];
        [[self contentView] addSubview:button];
        [button addTrackingRect:NSInsetRect([button bounds], 3.0, 0.0) owner:button userData:nil assumeInside:NO];
        [[NSNotificationCenter defaultCenter] addObserver: button selector: @selector(handleScaleChangedNotification:) 
                                                     name: PDFViewScaleChangedNotification object: pdfView];
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = SEP_WIDTH;
        button = [[[SKNavigationSeparatorButton alloc] initWithFrame:rect] autorelease];
        [[self contentView] addSubview:button];
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = BUTTON_WIDTH;
        button = [[[SKNavigationCloseButton alloc] initWithFrame:rect] autorelease];
        [button setTarget:controller];
        [button setAction:@selector(exitFullScreen:)];
        [button setToolTip:NSLocalizedString(@"Close", @"Tool tip message")];
        [[self contentView] addSubview:button];
        [button addTrackingRect:NSInsetRect([button bounds], 3.0, 0.0) owner:button userData:nil assumeInside:NO];
    }
    return self;
}

- (void)dealloc {
    [animation stopAnimation];
    [super dealloc];
}

- (BOOL)canBecomeKeyWindow { return NO; }

- (BOOL)canBecomeMainWindow { return NO; }

- (void)moveToScreen:(NSScreen *)screen {
    NSRect winFrame = [self frame];
    winFrame.origin.x = NSMidX([screen frame]) - 0.5 * NSWidth(winFrame);
    winFrame.origin.y = NSMinY([screen frame]) + OFFSET;
    [self setFrame:winFrame display:NO];
}

- (void)orderFront:(id)sender {
    [animation stopAnimation];
    [super orderFront:sender];
}

- (void)orderOut:(id)sender {
    [animation stopAnimation];
    [[SKNavigationToolTipWindow sharedToolTipWindow] orderOut:self];
    [super orderOut:sender];
}

- (void)hide {
    [animation stopAnimation];
    
    NSDictionary *fadeOutDict = [[NSDictionary alloc] initWithObjectsAndKeys:self, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
    
    animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeOutDict, nil]];
    [fadeOutDict release];
    
    [animation setAnimationBlockingMode:NSAnimationNonblocking];
    [animation setDuration:1.0];
    [animation setDelegate:self];
    [animation startAnimation];
}

- (void)animationDidEnd:(NSAnimation*)anAnimation {
    [animation release];
    animation = nil;
    [self orderOut:self];
    [self setAlphaValue:1.0];
}

- (void)animationDidStop:(NSAnimation*)anAnimation {
    [animation release];
    animation = nil;
    [self setAlphaValue:1.0];
}

@end


@implementation SKNavigationContentView

- (void)drawRect:(NSRect)rect {
    [[NSGraphicsContext currentContext] saveGraphicsState];
    rect = NSInsetRect([self bounds], 1.0, 1.0);
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
    [NSBezierPath fillRoundRectInRect:rect radius:10.0];
    rect = NSInsetRect([self bounds], 0.5, 0.5);
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.2] set];
    [NSBezierPath setDefaultLineWidth:1.0];
    [NSBezierPath strokeRoundRectInRect:rect radius:10.0];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end


@implementation SKNavigationToolTipWindow : NSWindow {
    SKNavigationToolTipView *toolTipView;
}

static SKNavigationToolTipWindow *sharedToolTipWindow = nil;

+ (id)sharedToolTipWindow {
    if (sharedToolTipWindow == nil)
        sharedToolTipWindow = [[self alloc] init];
    return sharedToolTipWindow;
}

- (id)init {
    if (self = [super initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES screen:[NSScreen mainScreen]]) {
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        
        toolTipView = [[[SKNavigationToolTipView alloc] init] autorelease];
        [[self contentView] addSubview:toolTipView];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow { return NO; }

- (BOOL)canBecomeMainWindow { return NO; }

- (void)showToolTip:(NSString *)toolTip forView:(NSView *)view {
    [toolTipView setStringValue:toolTip];
    [toolTipView sizeToFit];
    NSRect newFrame = [self frameRectForContentRect:[toolTipView frame]];
    NSRect viewRect = [view convertRect:[view bounds] toView:nil];
    viewRect.origin = [[view window] convertBaseToScreen:viewRect.origin];
    newFrame.origin = NSMakePoint(NSMidX(viewRect) - 0.5 * NSWidth(newFrame), NSMaxY(viewRect) + LABEL_OFFSET);
    [self setFrame:newFrame display:YES];
    [self setLevel:[[view window] level]];
    if ([self parentWindow] != [view window])
        [[self parentWindow] removeChildWindow:self];
    if ([self parentWindow]  == nil)
        [[view window] addChildWindow:self ordered:NSWindowAbove];
    [self orderFront:self];
}

- (void)orderOut:(id)sender {
    [[self parentWindow] removeChildWindow:self];
    [super orderOut:sender];
}

@end

@implementation SKNavigationToolTipView

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        stringValue = nil;
    }
    return self;
}

- (void)dealloc {
    [stringValue release];
    [super dealloc];
}

- (NSString *)stringValue {
    return stringValue;
}

- (void)setStringValue:(NSString *)newStringValue {
    if (stringValue != newStringValue) {
        [stringValue release];
        stringValue = [newStringValue retain];
    }
}

- (NSAttributedString *)attributedStringValue {
    if (stringValue == nil)
        return nil;
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:3.0];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.5)];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:15.0], NSFontAttributeName, 
        [NSColor whiteColor], NSForegroundColorAttributeName, 
        [NSParagraphStyle defaultClippingParagraphStyle], NSParagraphStyleAttributeName, 
        shadow, NSShadowAttributeName, nil];
    [shadow release];
    return [[[NSAttributedString alloc] initWithString:stringValue attributes:attrs] autorelease];
}

- (void)sizeToFit {
    NSSize size = [[self attributedStringValue] size];
    size.width += 2 * LABEL_TEXT_MARGIN;
    size.height += 2 * LABEL_TEXT_MARGIN;
    [self setFrameSize:size];
}

- (void)drawRect:(NSRect)rect {
    NSRect textRect = NSInsetRect(rect, LABEL_TEXT_MARGIN, LABEL_TEXT_MARGIN);
    NSAttributedString *attrString = [self attributedStringValue];
    // draw it 3x to see some shadow
    [attrString drawInRect:textRect];
    [attrString drawInRect:textRect];
    [attrString drawInRect:textRect];
}

@end


@implementation SKNavigationButton

+ (Class)cellClass { return [SKNavigationButtonCell class]; }

- (void)dealloc {
    [toolTip release];
    [alternateToolTip release];
    [super dealloc];
}

- (NSString *)toolTip {
    return toolTip;
}

// we don't use the superclass's ivar because we don't want the system toolTips
- (void)setToolTip:(NSString *)string {
    if (toolTip != string) {
        [toolTip release];
        toolTip = [string retain];
    }
}

- (NSString *)currentToolTip {
    return [self state] == NSOnState && alternateToolTip ? alternateToolTip : toolTip;
}

- (NSString *)alternateToolTip {
    return alternateToolTip;
}

- (void)setAlternateToolTip:(NSString *)string {
    if (alternateToolTip != string) {
        [alternateToolTip release];
        alternateToolTip = [string retain];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
    [[SKNavigationToolTipWindow sharedToolTipWindow] showToolTip:[self currentToolTip] forView:self];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [[SKNavigationToolTipWindow sharedToolTipWindow] orderOut:self];
}

@end

@implementation SKNavigationButtonCell

- (id)initTextCell:(NSString *)aString {
    if (self = [super initTextCell:@""]) {
		[self setBezelStyle:NSShadowlessSquareBezelStyle]; // this is mainly to make it selectable
        [self setBordered:NO];
        [self setButtonType:NSMomentaryPushInButton];
    }
    return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [[NSColor colorWithCalibratedWhite:1.0 alpha:[self isHighlighted] ? 0.9 : 0.6] set];
    [[self pathWithFrame:cellFrame] fill];
}

- (NSBezierPath *)pathWithFrame:(NSRect)cellFrame {
    return nil;
}

@end


@implementation SKNavigationNextButton
+ (Class)cellClass { return [SKNavigationNextButtonCell class]; }
@end

@implementation SKNavigationNextButtonCell

- (NSBezierPath *)pathWithFrame:(NSRect)cellFrame {
    NSRect rect = NSInsetRect(cellFrame, 10.0, 10.0);
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(NSMaxX(rect), NSMidY(rect))];
    [path lineToPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
    [path lineToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
    [path closePath];
    return path;
}

@end


@implementation SKNavigationPreviousButton
+ (Class)cellClass { return [SKNavigationPreviousButtonCell class]; }
@end

@implementation SKNavigationPreviousButtonCell

- (NSBezierPath *)pathWithFrame:(NSRect)cellFrame {
    NSRect rect = NSInsetRect(cellFrame, 10.0, 10.0);
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(NSMinX(rect), NSMidY(rect))];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
    [path closePath];
    return path;
}

@end


@implementation SKNavigationZoomButton

+ (Class)cellClass { return [SKNavigationZoomButtonCell class]; }

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    if ([[self window] isVisible] && NSPointInRect([self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil], [self bounds])) {
        [self setState:[[notification object] autoScales]];
        [[SKNavigationToolTipWindow sharedToolTipWindow] showToolTip:[self currentToolTip] forView:self];
        [self setNeedsDisplay:YES];
    }
}

@end

@implementation SKNavigationZoomButtonCell

- (id)initTextCell:(NSString *)aString {
    if (self = [super initTextCell:@""]) {
        [self setButtonType:NSPushOnPushOffButton];
    }
    return self;
}

- (NSBezierPath *)pathWithFrame:(NSRect)cellFrame {
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:NSInsetRect(cellFrame, 15.0, 15.0) radius:3.0];
    float centerX = NSMidX(cellFrame), centerY = NSMidY(cellFrame);
    
    [path appendBezierPath:[NSBezierPath bezierPathWithRect:NSInsetRect(cellFrame, 19.0, 19.0)]];
    
    float dy = [self state] == NSOnState ? -5.0 : 5.0;
    NSBezierPath *arrow = [NSBezierPath bezierPath];
    [arrow moveToPoint:NSMakePoint(centerX, NSMaxY(cellFrame) - 3.0 + dy)];
    [arrow relativeLineToPoint:NSMakePoint(-5.0, -dy)];
    [arrow relativeLineToPoint:NSMakePoint(3.0, 0.0)];
    [arrow relativeLineToPoint:NSMakePoint(0.0, -dy)];
    [arrow relativeLineToPoint:NSMakePoint(4.0, 0.0)];
    [arrow relativeLineToPoint:NSMakePoint(0.0, dy)];
    [arrow relativeLineToPoint:NSMakePoint(3.0, 0.0)];
    [arrow relativeLineToPoint:NSMakePoint(-5.0, dy)];
    
    NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
    [transform translateXBy:centerX yBy:centerY];
    [transform rotateByDegrees:45.0];
    [transform translateXBy:-centerX yBy:-centerY];
    [arrow transformUsingAffineTransform:transform];
    [path appendBezierPath:arrow];
    [transform translateXBy:centerX yBy:centerY];
    [transform rotateByDegrees:45.0];
    [transform translateXBy:-centerX yBy:-centerY];
    [arrow transformUsingAffineTransform:transform];
    [path appendBezierPath:arrow];
    [arrow transformUsingAffineTransform:transform];
    [path appendBezierPath:arrow];
    [arrow transformUsingAffineTransform:transform];
    [path appendBezierPath:arrow];
    
    [path setWindingRule:NSEvenOddWindingRule];
    
    return path;
}

@end


@implementation SKNavigationCloseButton
+ (Class)cellClass { return [SKNavigationCloseButtonCell class]; }
@end

@implementation SKNavigationCloseButtonCell

- (NSBezierPath *)pathWithFrame:(NSRect)cellFrame {
    NSBezierPath *path = [NSBezierPath bezierPath];
    float radius = 2.0, halfWidth = 0.5 * NSWidth(cellFrame) - 15.0, halfHeight = 0.5 * NSHeight(cellFrame) - 15.0;
    
    [path moveToPoint:NSMakePoint(radius, radius)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(halfWidth, 0.0) radius:radius startAngle:90.0 endAngle:-90.0 clockwise:YES];
    [path lineToPoint:NSMakePoint(radius, -radius)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(0.0, -halfHeight) radius:radius startAngle:360.0 endAngle:180.0 clockwise:YES];
    [path lineToPoint:NSMakePoint(-radius, -radius)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(-halfWidth, 0.0) radius:radius startAngle:270.0 endAngle:90.0 clockwise:YES];
    [path lineToPoint:NSMakePoint(-radius, radius)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(0.0, halfHeight) radius:radius startAngle:180.0 endAngle:0.0 clockwise:YES];
    [path closePath];
    
    NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
    [transform translateXBy:NSMidX(cellFrame) yBy:NSMidY(cellFrame)];
    [transform rotateByDegrees:45.0];
    [path transformUsingAffineTransform:transform];
    
    [path appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(cellFrame, 8.0, 8.0)]];
    
    return path;
}

@end


@implementation SKNavigationSeparatorButton
+ (Class)cellClass { return [SKNavigationSeparatorButtonCell class]; }
@end

@implementation SKNavigationSeparatorButtonCell

- (BOOL)isEnabled { return NO; }

- (NSBezierPath *)pathWithFrame:(NSRect)cellFrame {
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMidX(cellFrame) - 0.5, NSMinY(cellFrame), 1.0, NSHeight(cellFrame))];
    return path;
}

@end
