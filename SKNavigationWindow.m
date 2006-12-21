//
//  SKNavigationWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 19/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SKNavigationWindow.h"
#import <Quartz/Quartz.h>

#define BUTTON_WIDTH 50.0
#define SEP_WIDTH 21.0
#define MARGIN 7.0
#define OFFSET 20.0
#define LABEL_MARGIN_X 10.0
#define LABEL_MARGIN_Y 25.0

@implementation SKNavigationWindow

- (id)initWithPDFView:(PDFView *)pdfView {
    NSScreen *screen = [[pdfView window] screen];
    float width = 4 * BUTTON_WIDTH + 2 * SEP_WIDTH + 2 * MARGIN + 2 * LABEL_MARGIN_X;
    NSRect contentRect = NSMakeRect(NSMidX([screen frame]) - 0.5 * width, OFFSET, width, BUTTON_WIDTH + 2 * MARGIN + LABEL_MARGIN_Y);
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:screen]) {
        NSWindowController *controller = [[pdfView window] windowController];
        
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setLevel:CGShieldingWindowLevel()];
        
        [self setContentView:[[[SKNavigationContentView alloc] init] autorelease]];
        
        NSRect rect = NSMakeRect(MARGIN + LABEL_MARGIN_X, MARGIN, BUTTON_WIDTH, BUTTON_WIDTH);
        SKNavigationButton *button = [[[SKNavigationPreviousButton alloc] initWithFrame:rect] autorelease];
        [button setTarget:controller];
        [button setAction:@selector(doGoToPreviousPage:)];
        [[self contentView] addSubview:button];
        [button addTrackingRect:NSInsetRect([button bounds], 1.0, 0.0) owner:self userData:button assumeInside:NO];
        
        rect.origin.x = NSMaxX(rect);
        button = [[[SKNavigationNextButton alloc] initWithFrame:rect] autorelease];
        [button setTarget:controller];
        [button setAction:@selector(doGoToNextPage:)];
        [[self contentView] addSubview:button];
        [button addTrackingRect:NSInsetRect([button bounds], 1.0, 0.0) owner:self userData:button assumeInside:NO];
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = SEP_WIDTH;
        button = [[[SKNavigationSeparatorButton alloc] initWithFrame:rect] autorelease];
        [[self contentView] addSubview:button];
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = BUTTON_WIDTH;
        button = [[[SKNavigationZoomButton alloc] initWithFrame:rect] autorelease];
        [button setTarget:controller];
        [button setAction:@selector(toggleZoomToFit:)];
        [[self contentView] addSubview:button];
        [button addTrackingRect:NSInsetRect([button bounds], 1.0, 0.0) owner:self userData:button assumeInside:NO];
        zoomButton = [button retain];
        [zoomButton setState:[pdfView autoScales]];
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = SEP_WIDTH;
        button = [[[SKNavigationSeparatorButton alloc] initWithFrame:rect] autorelease];
        [[self contentView] addSubview:button];
        
        rect.origin.x = NSMaxX(rect);
        rect.size.width = BUTTON_WIDTH;
        button = [[[SKNavigationCloseButton alloc] initWithFrame:rect] autorelease];
        [button setTarget:controller];
        [button setAction:@selector(exitFullScreen:)];
        [[self contentView] addSubview:button];
        [button addTrackingRect:NSInsetRect([button bounds], 1.0, 0.0) owner:self userData:button assumeInside:NO];
        
        labelView = [[[SKNavigationLabelView alloc] initWithFrame:NSMakeRect(LABEL_MARGIN_X, BUTTON_WIDTH + 2 * MARGIN + 2.0, 0.0, 0.0)] autorelease];
        [labelView setHidden:YES];
        [[self contentView] addSubview:labelView];
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleScaleChangedNotification:) 
                                                     name: PDFViewScaleChangedNotification object: pdfView];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [animation stopAnimation];
    [zoomButton release];
    [super dealloc];
}

- (BOOL)canBecomeKeyWindow { return NO; }

- (BOOL)canBecomeMainWindow { return NO; }

- (void)handleScaleChangedNotification:(NSNotification *)notification {
    [zoomButton setState:[[notification object] autoScales]];
}

- (void)orderFront:(id)sender {
    [animation stopAnimation];
    [super orderFront:sender];
}

- (void)orderOut:(id)sender {
    [animation stopAnimation];
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
    [super orderOut:self];
    [self setAlphaValue:1.0];
}

- (void)animationDidStop:(NSAnimation*)anAnimation {
    [animation release];
    animation = nil;
    [self setAlphaValue:1.0];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if ([labelView isHidden] == NO) 
        [[self contentView] setNeedsDisplayInRect:[labelView frame]];
    SKNavigationButton *button = (SKNavigationButton *)[theEvent userData];
    [labelView setStringValue:[button label]];
    [labelView sizeToFit];
    NSRect labelRect = [labelView frame];
    NSRect buttonRect = [button frame];
    labelRect.origin.x = NSMidX(buttonRect) - 0.5 * NSWidth(labelRect);
    [labelView setFrameOrigin:labelRect.origin];
    [labelView setHidden:NO];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [labelView setHidden:YES];
}

@end


@implementation SKNavigationContentView

- (void)drawRect:(NSRect)rect {
    rect = [self bounds];
    rect = NSInsetRect([self bounds], 1.0 + LABEL_MARGIN_X, 1.0);
    rect.size.height -= LABEL_MARGIN_Y;
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
    [NSBezierPath fillRoundRectInRect:rect radius:10.0];
    rect = NSInsetRect(rect, -0.5, -0.5);
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.2] set];
    [NSBezierPath strokeRoundRectInRect:rect radius:10.0];
}

@end

@implementation SKNavigationLabelView

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
        stringValue = [newStringValue retain];;
    }
}

- (NSAttributedString *)attributedStringValue {
    if (stringValue == nil)
        return nil;
    NSMutableParagraphStyle *parStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [parStyle setLineBreakMode:NSLineBreakByClipping];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:3.0];
    [shadow setShadowOffset:NSMakeSize(0.0, -2.0)];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:16.0], NSFontAttributeName, 
        [NSColor whiteColor], NSForegroundColorAttributeName, 
        parStyle, NSParagraphStyleAttributeName, 
        shadow, NSShadowAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:stringValue attributes:attrs] autorelease];
}

- (NSAttributedString *)outlineAttributedStringValue {
    if (stringValue == nil)
        return nil;
    NSMutableParagraphStyle *parStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [parStyle setLineBreakMode:NSLineBreakByClipping];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont boldSystemFontOfSize:16.0] , NSFontAttributeName, 
        [NSColor whiteColor], NSForegroundColorAttributeName, 
        parStyle, NSParagraphStyleAttributeName, 
        [NSColor blackColor], NSStrokeColorAttributeName, 
        [NSNumber numberWithInt:1.0], NSStrokeWidthAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:stringValue attributes:attrs] autorelease];
}

#define LABEL_TEXT_MARGIN 2.0

- (void)sizeToFit {
    NSSize size = [[self attributedStringValue] size];
    size.width += 2 * LABEL_TEXT_MARGIN;
    size.height += 2 * LABEL_TEXT_MARGIN;
    [self setFrameSize:size];
}

- (void)drawRect:(NSRect)rect {
    NSRect textRect = NSInsetRect(rect, LABEL_TEXT_MARGIN, LABEL_TEXT_MARGIN);
    [[self attributedStringValue] drawInRect:textRect];
    [[self outlineAttributedStringValue] drawInRect:textRect];
}

@end


@implementation SKNavigationButton
+ (Class)cellClass { return [SKNavigationButtonCell class]; }
- (NSString *)label { return [[self cell] label]; }
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

- (NSString *)label {
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

- (NSString *)label {
    return NSLocalizedString(@"Next", @"");
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

- (NSString *)label {
    return NSLocalizedString(@"Previous", @"");
}

@end


@implementation SKNavigationZoomButton
+ (Class)cellClass { return [SKNavigationZoomButtonCell class]; }
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
    
    [path appendBezierPath:[NSBezierPath bezierPathWithRect:NSInsetRect(cellFrame, 16.0, 20.0)]];
    
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

- (NSString *)label {
    return [[self target] autoScales] ? NSLocalizedString(@"Actual Size", @"") : NSLocalizedString(@"Fit to Screen", @"");
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

- (NSString *)label {
    return NSLocalizedString(@"Close", @"");
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

- (NSString *)label {
    return @"";
}

@end


@implementation NSBezierPath (SKExtensions)

+ (void)fillRoundRectInRect:(NSRect)rect radius:(float)radius
{
    NSBezierPath *p = [self bezierPathWithRoundRectInRect:rect radius:radius];
    [p fill];
}

+ (void)strokeRoundRectInRect:(NSRect)rect radius:(float)radius
{
    NSBezierPath *p = [self bezierPathWithRoundRectInRect:rect radius:radius];
    [p stroke];
}

+ (NSBezierPath*)bezierPathWithRoundRectInRect:(NSRect)rect radius:(float)radius
{
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    radius = MIN(radius, 0.5f * MIN(NSHeight(rect), NSWidth(rect)));
    
    // Make sure silly values simply lead to un-rounded corners:
    if( radius <= 0 )
        return [self bezierPathWithRect:rect];
    
    NSRect innerRect = NSInsetRect(rect, radius, radius); // Make rect with corners being centers of the corner circles.
	static NSBezierPath *path = nil;
    if(path == nil)
        path = [[self bezierPath] retain];
    
    [path removeAllPoints];    
    
    // Now draw our rectangle:
    [path moveToPoint: NSMakePoint(NSMinX(innerRect) - radius, NSMinY(innerRect))];
    
    // Bottom left (origin):
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect), NSMinY(innerRect)) radius:radius startAngle:180.0 endAngle:270.0];
    // Bottom edge and bottom right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMinY(innerRect)) radius:radius startAngle:270.0 endAngle:360.0];
    // Left edge and top right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMaxY(innerRect)) radius:radius startAngle:0.0  endAngle:90.0 ];
    // Top edge and top left:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect), NSMaxY(innerRect)) radius:radius startAngle:90.0  endAngle:180.0];
    // Left edge:
    [path closePath];
    
    return path;
}

- (NSString *)label {
    return NSLocalizedString(@"", @"");
}

@end
