//
//  SKNavigationWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 12/19/06.
/*
 This software is Copyright (c) 2006-2014
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
#import "NSBezierPath_SKExtensions.h"
#import "SKPDFView.h"
#import "NSParagraphStyle_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "PDFView_SKExtensions.h"

#define BUTTON_WIDTH 50.0
#define BUTTON_HEIGHT 50.0
#define SLIDER_WIDTH 100.0
#define SEP_WIDTH 21.0
#define BUTTON_MARGIN 7.0
#define WINDOW_OFFSET 20.0
#define LABEL_OFFSET 10.0
#define LABEL_TEXT_MARGIN 2.0

#define CORNER_RADIUS 10.0


static inline NSBezierPath *nextButtonPath(NSSize size);
static inline NSBezierPath *previousButtonPath(NSSize size);
static inline NSBezierPath *zoomButtonPath(NSSize size);
static inline NSBezierPath *alternateZoomButtonPath(NSSize size);
static inline NSBezierPath *closeButtonPath(NSSize size);


@implementation SKNavigationWindow

- (id)initWithPDFView:(SKPDFView *)pdfView {
    NSScreen *screen = [[pdfView window] screen] ?: [NSScreen mainScreen];
    CGFloat width = 4 * BUTTON_WIDTH + 2 * SEP_WIDTH + 2 * BUTTON_MARGIN;
    BOOL hasSlider = [pdfView interactionMode] == SKFullScreenMode; 
    if (hasSlider)
        width += SLIDER_WIDTH;
    NSRect contentRect = NSMakeRect(NSMidX([screen frame]) - 0.5 * width, NSMinY([screen frame]) + WINDOW_OFFSET, width, BUTTON_HEIGHT + 2 * BUTTON_MARGIN);
    self = [super initWithContentRect:contentRect];
    if (self) {
        
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setLevel:[[pdfView window] level]];
        [self setMovableByWindowBackground:YES];
        
        [self setContentView:[[[SKNavigationContentView alloc] init] autorelease]];
        
        NSRect rect = NSMakeRect(BUTTON_MARGIN, BUTTON_MARGIN, BUTTON_WIDTH, BUTTON_HEIGHT);
        previousButton = [[SKNavigationButton alloc] initWithFrame:rect];
        [previousButton setTarget:pdfView];
        [previousButton setAction:@selector(goToPreviousPage:)];
        [previousButton setToolTip:NSLocalizedString(@"Previous", @"Tool tip message")];
        [previousButton setPath:previousButtonPath(rect.size)];
        [previousButton setEnabled:[pdfView canGoToPreviousPage]];
        [[self contentView] addSubview:previousButton];
        
        rect.origin.x = NSMaxX(rect);
        nextButton = [[SKNavigationButton alloc] initWithFrame:rect];
        [nextButton setTarget:pdfView];
        [nextButton setAction:@selector(goToNextPage:)];
        [nextButton setToolTip:NSLocalizedString(@"Next", @"Tool tip message")];
        [nextButton setPath:nextButtonPath(rect.size)];
        [nextButton setEnabled:[pdfView canGoToNextPage]];
        [[self contentView] addSubview:nextButton];
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = SEP_WIDTH;
        [[self contentView] addSubview:[[[SKNavigationSeparator alloc] initWithFrame:rect] autorelease]];
        
        if (hasSlider) {
            rect.origin.x = NSMaxX(rect);
            rect.size.width = SLIDER_WIDTH;
            zoomSlider = [[SKNavigationSlider alloc] initWithFrame:rect];
            [zoomSlider setTarget:pdfView];
            [zoomSlider setAction:@selector(zoomLog:)];
            [zoomSlider setToolTip:NSLocalizedString(@"Zoom", @"Tool tip message")];
            [zoomSlider setMinValue:log([pdfView respondsToSelector:@selector(minScaleFactor)] ? [pdfView minScaleFactor] : 0.1)];
            [zoomSlider setMaxValue:log([pdfView respondsToSelector:@selector(maxScaleFactor)] ? [pdfView maxScaleFactor] : 20.0)];
            [zoomSlider setDoubleValue:log([pdfView scaleFactor])];
            [[self contentView] addSubview:zoomSlider];
        }
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = BUTTON_WIDTH;
        zoomButton = [[SKNavigationButton alloc] initWithFrame:rect];
        [zoomButton setTarget:pdfView];
        [zoomButton setAction:@selector(toggleAutoActualSize:)];
        [zoomButton setToolTip:NSLocalizedString(@"Fit to Screen", @"Tool tip message")];
        [zoomButton setAlternateToolTip:NSLocalizedString(@"Actual Size", @"Tool tip message")];
        [zoomButton setPath:zoomButtonPath(rect.size)];
        [zoomButton setAlternatePath:alternateZoomButtonPath(rect.size)];
        [zoomButton setState:[pdfView autoScales]];
        [zoomButton setButtonType:NSPushOnPushOffButton];
        [[self contentView] addSubview:zoomButton];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScaleChangedNotification:) 
                                                     name:PDFViewScaleChangedNotification object:pdfView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageChangedNotification:) 
                                                     name:PDFViewPageChangedNotification object:pdfView];
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = SEP_WIDTH;
        [[self contentView] addSubview:[[[SKNavigationSeparator alloc] initWithFrame:rect] autorelease]];
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = BUTTON_WIDTH;
        closeButton = [[SKNavigationButton alloc] initWithFrame:rect];
        [closeButton setTarget:pdfView];
        [closeButton setAction:@selector(exitFullscreen:)];
        [closeButton setToolTip:NSLocalizedString(@"Close", @"Tool tip message")];
        [closeButton setPath:closeButtonPath(rect.size)];
        [[self contentView] addSubview:closeButton];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SKDESTROY(previousButton);
    SKDESTROY(nextButton);
    SKDESTROY(zoomButton);
    SKDESTROY(zoomSlider);
    SKDESTROY(closeButton);
    [super dealloc];
}

- (void)remove {
    [[self parentWindow] removeChildWindow:self];
    [super remove];
}

- (void)orderOut:(id)sender {
    [[SKNavigationToolTipWindow sharedToolTipWindow] orderOut:nil];
    [super orderOut:sender];
}

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [zoomButton setState:[[notification object] autoScales] ? NSOnState : NSOffState];
    [zoomSlider setDoubleValue:log([(PDFView *)[notification object] scaleFactor])];
}

- (void)handlePageChangedNotification:(NSNotification *)notification {
    [previousButton setEnabled:[[notification object] canGoToPreviousPage]];
    [nextButton setEnabled:[[notification object] canGoToNextPage]];
}

@end

#pragma mark -

@implementation SKNavigationContentView

- (void)drawRect:(NSRect)rect {
    [[NSGraphicsContext currentContext] saveGraphicsState];
    rect = NSInsetRect([self bounds], 1.0, 1.0);
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.5] set];
    [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:CORNER_RADIUS yRadius:CORNER_RADIUS] fill];
    rect = NSInsetRect([self bounds], 0.5, 0.5);
    [[NSColor colorWithDeviceWhite:1.0 alpha:0.2] set];
    [NSBezierPath setDefaultLineWidth:1.0];
    [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:CORNER_RADIUS yRadius:CORNER_RADIUS] stroke];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end

#pragma mark -

@implementation SKNavigationToolTipWindow

@synthesize view;

+ (id)sharedToolTipWindow {
    static SKNavigationToolTipWindow *sharedToolTipWindow = nil;
    if (sharedToolTipWindow == nil)
        sharedToolTipWindow = [[self alloc] init];
    return sharedToolTipWindow;
}

- (id)init {
    self = [super initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
    if (self) {
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        [self setHidesOnDeactivate:NO];
        
        [self setContentView:[[[SKNavigationToolTipView alloc] init] autorelease]];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow { return NO; }

- (BOOL)canBecomeMainWindow { return NO; }

- (void)showToolTip:(NSString *)toolTip forView:(NSView *)aView {
    [view release];
    view = [aView retain];
    [[self contentView] setStringValue:toolTip];
    NSRect newFrame = NSZeroRect;
    NSRect viewRect = [view convertRect:[view bounds] toView:nil];
    viewRect.origin = [[view window] convertBaseToScreen:viewRect.origin];
    newFrame.size = [[self contentView] fitSize];
    newFrame.origin = NSMakePoint(ceil(NSMidX(viewRect) - 0.5 * NSWidth(newFrame)), NSMaxY(viewRect) + LABEL_OFFSET);
    [self setFrame:newFrame display:YES];
    [self setLevel:[[view window] level]];
    if ([self parentWindow] != [view window])
        [[self parentWindow] removeChildWindow:self];
    if ([self parentWindow] == nil)
        [[view window] addChildWindow:self ordered:NSWindowAbove];
    [self orderFront:self];
}

- (void)orderOut:(id)sender {
    [[self parentWindow] removeChildWindow:self];
    [super orderOut:sender];
    SKDESTROY(view);
}

- (BOOL)accessibilityIsIgnored {
    return YES;
}

@end

#pragma mark -

@implementation SKNavigationToolTipView

@synthesize stringValue;
@dynamic attributedStringValue;

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        stringValue = nil;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        stringValue = [[decoder decodeObjectForKey:@"stringValue"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:stringValue forKey:@"stringValue"];
}

- (void)dealloc {
    SKDESTROY(stringValue);
    [super dealloc];
}

- (NSAttributedString *)attributedStringValue {
    if (stringValue == nil)
        return nil;
    NSShadow *aShadow = [[NSShadow alloc] init];
    [aShadow setShadowColor:[NSColor blackColor]];
    [aShadow setShadowBlurRadius:3.0];
    [aShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:15.0], NSFontAttributeName, 
        [NSColor whiteColor], NSForegroundColorAttributeName, 
        [NSParagraphStyle defaultClippingParagraphStyle], NSParagraphStyleAttributeName, 
        aShadow, NSShadowAttributeName, nil];
    [aShadow release];
    return [[[NSAttributedString alloc] initWithString:stringValue attributes:attrs] autorelease];
}

- (NSSize)fitSize {
    NSSize stringSize = [[self attributedStringValue] size];
    return NSMakeSize(ceil(stringSize.width + 2 * LABEL_TEXT_MARGIN), ceil(stringSize.height + 2 * LABEL_TEXT_MARGIN));
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

#pragma mark -

@implementation SKNavigationButton

@dynamic path, alternatePath, toolTip, alternateToolTip;

+ (Class)cellClass { return [SKNavigationButtonCell class]; }

- (NSBezierPath *)path {
    return [(SKNavigationButtonCell *)[self cell] path];
}

- (void)setPath:(NSBezierPath *)newPath {
    [(SKNavigationButtonCell *)[self cell] setPath:newPath];
}

- (NSBezierPath *)alternatePath {
    return [(SKNavigationButtonCell *)[self cell] alternatePath];
}

- (void)setAlternatePath:(NSBezierPath *)newAlternatePath {
    [(SKNavigationButtonCell *)[self cell] setAlternatePath:newAlternatePath];
}

- (NSString *)toolTip {
    return [(SKNavigationButtonCell *)[self cell] toolTip];
}

// we don't use the superclass's ivar because we don't want the system toolTips
- (void)setToolTip:(NSString *)string {
    [(SKNavigationButtonCell *)[self cell] setToolTip:string];
    [self setShowsBorderOnlyWhileMouseInside:[string length] > 0];
}

- (NSString *)alternateToolTip {
    return [(SKNavigationButtonCell *)[self cell] alternateToolTip];
}

- (void)setAlternateToolTip:(NSString *)string {
    [(SKNavigationButtonCell *)[self cell] setAlternateToolTip:string];
}

@end

#pragma mark -

@implementation SKNavigationButtonCell

@synthesize path, alternatePath, toolTip, alternateToolTip;

- (id)initTextCell:(NSString *)aString {
    self = [super initTextCell:@""];
    if (self) {
		[self setBezelStyle:NSShadowlessSquareBezelStyle]; // this is mainly to make it selectable
        [self setBordered:NO];
        [self setButtonType:NSMomentaryPushInButton];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        toolTip = [[decoder decodeObjectForKey:@"toolTip"] retain];
        alternateToolTip = [[decoder decodeObjectForKey:@"alternateToolTip"] retain];
        path = [[decoder decodeObjectForKey:@"path"] retain];
        alternatePath = [[decoder decodeObjectForKey:@"alternatePath"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:toolTip forKey:@"toolTip"];
    [coder encodeObject:alternateToolTip forKey:@"alternateToolTip"];
    [coder encodeObject:path forKey:@"path"];
    [coder encodeObject:alternatePath forKey:@"alternatePath"];
}

- (void)dealloc {
    SKDESTROY(toolTip);
    SKDESTROY(alternateToolTip);
    SKDESTROY(path);
    SKDESTROY(alternatePath);
    [super dealloc];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [[NSColor colorWithDeviceWhite:1.0 alpha:[self isEnabled] == NO ? 0.3 : [self isHighlighted] ? 0.9 : 0.6] setFill];
    [([self state] == NSOnState && [self alternatePath] ? [self alternatePath] : [self path]) fill];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    NSString *currentToolTip = [self state] == NSOnState && alternateToolTip ? alternateToolTip : toolTip;
    [[SKNavigationToolTipWindow sharedToolTipWindow] showToolTip:currentToolTip forView:[self controlView]];
    [super mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent {
    if ([[[SKNavigationToolTipWindow sharedToolTipWindow] view] isEqual:[self controlView]])
        [[SKNavigationToolTipWindow sharedToolTipWindow] orderOut:nil];
    [super mouseExited:theEvent];
}

- (void)setState:(NSInteger)state {
    NSInteger oldState = [self state];
    NSView *button = [self controlView];
    [super setState:state];
    if (oldState != state && [[button window] isVisible]) {
        if (alternatePath)
            [button setNeedsDisplay:YES];
        if (alternateToolTip && [[[SKNavigationToolTipWindow sharedToolTipWindow] view] isEqual:button]) {
            NSString *currentToolTip = [self state] == NSOnState && alternateToolTip ? alternateToolTip : toolTip;
            [[SKNavigationToolTipWindow sharedToolTipWindow] showToolTip:currentToolTip forView:button];
        }
    }
}

@end

#pragma mark -

@implementation SKNavigationSlider

@synthesize toolTip;

+ (Class)cellClass { return [SKNavigationSliderCell class]; }

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect | NSTrackingActiveAlways owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
        toolTip = nil;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        toolTip = [[decoder decodeObjectForKey:@"toolTip"] retain];
        trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect | NSTrackingActiveAlways owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:toolTip forKey:@"toolTip"];
}

- (void)dealloc {
    SKDESTROY(trackingArea);
    SKDESTROY(toolTip);
    [super dealloc];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if ([[theEvent trackingArea] isEqual:trackingArea])
        [[SKNavigationToolTipWindow sharedToolTipWindow] showToolTip:toolTip forView:self];
    else
        [super mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent {
    if ([[theEvent trackingArea] isEqual:trackingArea]) {
        if ([[[SKNavigationToolTipWindow sharedToolTipWindow] view] isEqual:self])
            [[SKNavigationToolTipWindow sharedToolTipWindow] orderOut:nil];
    } else
        [super mouseExited:theEvent];
}

@end

#pragma mark -

@implementation SKNavigationSliderCell

- (void)drawBarInside:(NSRect)frame flipped:(BOOL)flipped {
    frame = NSInsetRect(frame, 2.5, 0.0);
    frame.origin.y = NSMidY(frame) - (flipped ? 2.0 : 3.0);
    frame.size.height = 5.0;
	
    CGFloat alpha = [self isEnabled] ? 0.6 : 0.3;
    [[NSColor colorWithDeviceWhite:0.3 alpha:alpha] setFill];
    [[NSColor colorWithDeviceWhite:1.0 alpha:alpha] setStroke];
    
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:2.0 yRadius:2.0];
    [path fill];
    [path stroke];
}

- (void)drawKnob:(NSRect)frame {
	if ([self isEnabled]) {
        [[NSColor colorWithDeviceWhite:1.0 alpha:[self isHighlighted] ? 0.9 : 0.7] setFill];
        NSShadow *shade = [[NSShadow alloc] init];
        [shade setShadowColor:[NSColor blackColor]];
        [shade setShadowBlurRadius:2.0];
        [shade set];
        [shade release];
    } else {
        [[NSColor colorWithDeviceWhite:1.0 alpha:0.3] setFill];
    }
    
    [[NSBezierPath bezierPathWithOvalInRect:SKRectFromCenterAndSquareSize(SKCenterPoint(frame), 15.0)] fill];
}

- (BOOL)_usesCustomTrackImage { return YES; }

@end

#pragma mark -

@implementation SKNavigationSeparator

- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bounds];
    [[NSColor colorWithDeviceWhite:1.0 alpha:0.6] setFill];
    [NSBezierPath fillRect:NSMakeRect(NSMidX(bounds) - 0.5, NSMinY(bounds), 1.0, NSHeight(bounds))];
}

@end

#pragma mark Button paths

static inline NSBezierPath *nextButtonPath(NSSize size) {
    NSRect bounds = {NSZeroPoint, size};
    NSRect rect = NSInsetRect(bounds, 10.0, 10.0);
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(NSMaxX(rect), NSMidY(rect))];
    [path lineToPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
    [path lineToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
    [path closePath];
    return path;
}

static inline NSBezierPath *previousButtonPath(NSSize size) {
    NSRect bounds = {NSZeroPoint, size};
    NSRect rect = NSInsetRect(bounds, 10.0, 10.0);
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(NSMinX(rect), NSMidY(rect))];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
    [path closePath];
    return path;
}

static inline NSBezierPath *zoomButtonPath(NSSize size) {
    NSRect bounds = {NSZeroPoint, size};
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 15.0, 15.0) xRadius:3.0 yRadius:3.0];
    CGFloat centerX = NSMidX(bounds), centerY = NSMidY(bounds);
    
    [path appendBezierPath:[NSBezierPath bezierPathWithRect:NSInsetRect(bounds, 19.0, 19.0)]];
    
    NSBezierPath *arrow = [NSBezierPath bezierPath];
    [arrow moveToPoint:NSMakePoint(centerX, NSMaxY(bounds) + 2.0)];
    [arrow relativeLineToPoint:NSMakePoint(-5.0, -5.0)];
    [arrow relativeLineToPoint:NSMakePoint(3.0, 0.0)];
    [arrow relativeLineToPoint:NSMakePoint(0.0, -5.0)];
    [arrow relativeLineToPoint:NSMakePoint(4.0, 0.0)];
    [arrow relativeLineToPoint:NSMakePoint(0.0, 5.0)];
    [arrow relativeLineToPoint:NSMakePoint(3.0, 0.0)];
    [arrow relativeLineToPoint:NSMakePoint(-5.0, 5.0)];
    
    NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
    [transform translateXBy:centerX yBy:centerY];
    [transform rotateByDegrees:45.0];
    [transform translateXBy:-centerX yBy:-centerY];
    [arrow transformUsingAffineTransform:transform];
    [transform translateXBy:centerX yBy:centerY];
    [transform rotateByDegrees:45.0];
    [transform translateXBy:-centerX yBy:-centerY];
    
    NSInteger i;
    for (i = 0; i < 4; i++) {
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
    }
    
    [path setWindingRule:NSEvenOddWindingRule];
    
    return path;
}

static inline NSBezierPath *alternateZoomButtonPath(NSSize size) {
    NSRect bounds = {NSZeroPoint, size};
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 15.0, 15.0) xRadius:3.0 yRadius:3.0];
    CGFloat centerX = NSMidX(bounds), centerY = NSMidY(bounds);
    
    [path appendBezierPath:[NSBezierPath bezierPathWithRect:NSInsetRect(bounds, 19.0, 19.0)]];
    
    NSBezierPath *arrow = [NSBezierPath bezierPath];
    [arrow moveToPoint:NSMakePoint(centerX, NSMaxY(bounds) - 8.0)];
    [arrow relativeLineToPoint:NSMakePoint(-5.0, 5.0)];
    [arrow relativeLineToPoint:NSMakePoint(3.0, 0.0)];
    [arrow relativeLineToPoint:NSMakePoint(0.0, 5.0)];
    [arrow relativeLineToPoint:NSMakePoint(4.0, 0.0)];
    [arrow relativeLineToPoint:NSMakePoint(0.0, -5.0)];
    [arrow relativeLineToPoint:NSMakePoint(3.0, 0.0)];
    [arrow relativeLineToPoint:NSMakePoint(-5.0, -5.0)];
    
    NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
    [transform translateXBy:centerX yBy:centerY];
    [transform rotateByDegrees:45.0];
    [transform translateXBy:-centerX yBy:-centerY];
    [arrow transformUsingAffineTransform:transform];
    [transform translateXBy:centerX yBy:centerY];
    [transform rotateByDegrees:45.0];
    [transform translateXBy:-centerX yBy:-centerY];
    
    NSInteger i;
    for (i = 0; i < 4; i++) {
        [path appendBezierPath:arrow];
        [arrow transformUsingAffineTransform:transform];
    }
    
    [path setWindingRule:NSEvenOddWindingRule];
    
    return path;
}

static inline NSBezierPath *closeButtonPath(NSSize size) {
    NSRect bounds = {NSZeroPoint, size};
    NSBezierPath *path = [NSBezierPath bezierPath];
    CGFloat radius = 2.0, halfWidth = 0.5 * NSWidth(bounds) - 15.0, halfHeight = 0.5 * NSHeight(bounds) - 15.0;
    
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
    [transform translateXBy:NSMidX(bounds) yBy:NSMidY(bounds)];
    [transform rotateByDegrees:45.0];
    [path transformUsingAffineTransform:transform];
    
    [path appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(bounds, 8.0, 8.0)]];
    
    return path;
}
