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
#define SEP_WIDTH 20.0
#define MARGIN 7.0
#define OFFSET 20.0

@implementation SKNavigationWindow

- (id)initWithPDFView:(PDFView *)pdfView {
    NSRect mainScreenFrame = [[NSScreen mainScreen] frame];
    float width = 4 * BUTTON_WIDTH + + 2 * SEP_WIDTH + 2 * MARGIN;
    NSRect contentRect = NSMakeRect(NSMidX(mainScreenFrame) - 0.5 * width, OFFSET, width, BUTTON_WIDTH + 2 * MARGIN);
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[NSScreen mainScreen]]) {
        NSWindowController *controller = [[pdfView window] windowController];
        
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setLevel:CGShieldingWindowLevel()];
        
        [self setContentView:[[[SKNavigationContentView alloc] init] autorelease]];
        
        NSRect rect = NSMakeRect(MARGIN, MARGIN, BUTTON_WIDTH, BUTTON_WIDTH);
        SKNavigationButton *button = [[[SKNavigationPreviousButton alloc] initWithFrame:rect] autorelease];
        [button setTarget:controller];
        [button setAction:@selector(doGoToPreviousPage:)];
        [[self contentView] addSubview:button];
        
        rect.origin.x = NSMaxX(rect);
        button = [[[SKNavigationNextButton alloc] initWithFrame:rect] autorelease];
        [button setTarget:controller];
        [button setAction:@selector(doGoToNextPage:)];
        [[self contentView] addSubview:button];
        
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

@end


@implementation SKNavigationContentView

- (void)drawRect:(NSRect *)rect {
    [[NSColor colorWithCalibratedWhite:0.1 alpha:0.6] set];
    [NSBezierPath fillRoundRectInRect:[self bounds] radius:10.0];
}

@end


@implementation SKNavigationButton
+ (Class)cellClass { return [SKNavigationButtonCell class]; }
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
@end

@implementation SKNavigationZoomButtonCell

- (id)initTextCell:(NSString *)aString {
    if (self = [super initTextCell:@""]) {
        [self setButtonType:NSPushOnPushOffButton];
    }
    return self;
}

- (NSBezierPath *)pathWithFrame:(NSRect)cellFrame {
    NSRect rect = NSInsetRect(cellFrame, 15.0, 15.0);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:rect radius:3.0];
    rect = NSInsetRect(rect, 1.0, 5.0);
    [path moveToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
    [path lineToPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
    [path lineToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
    [path setWindingRule:NSEvenOddWindingRule];
    rect = NSInsetRect(cellFrame, 7.0, 7.0);
    NSBezierPath *arrow = [NSBezierPath bezierPath];
    if ([self state] == NSOnState) {
        [arrow moveToPoint:NSMakePoint(NSMidX(rect) - 2.0, NSMaxY(rect) + 10.0)];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) + 2.0, NSMaxY(rect) + 10.0)];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) + 2.0, NSMaxY(rect) + 5.0)];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) + 5.0, NSMaxY(rect) + 5.0)];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect))];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) - 5.0, NSMaxY(rect) + 5.0)];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) - 2.0, NSMaxY(rect) + 5.0)];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) - 2.0, NSMaxY(rect) + 10.0)];
    } else {
        [arrow moveToPoint:NSMakePoint(NSMidX(rect) - 2.0, NSMaxY(rect))];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) + 2.0, NSMaxY(rect))];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) + 2.0, NSMaxY(rect) + 5.0)];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) + 5.0, NSMaxY(rect) + 5.0)];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect) + 10.0)];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) - 5.0, NSMaxY(rect) + 5.0)];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) - 2.0, NSMaxY(rect) + 5.0)];
        [arrow lineToPoint:NSMakePoint(NSMidX(rect) - 2.0, NSMaxY(rect))];
    }
    NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
    [transform translateXBy:NSMidX(rect) yBy:NSMidY(rect)];
    [transform rotateByDegrees:45.0];
    [transform translateXBy:-NSMidX(rect) yBy:-NSMidY(rect)];
    [arrow transformUsingAffineTransform:transform];
    [path appendBezierPath:arrow];
    [transform translateXBy:NSMidX(rect) yBy:NSMidY(rect)];
    [transform rotateByDegrees:45.0];
    [transform translateXBy:-NSMidX(rect) yBy:-NSMidY(rect)];
    [arrow transformUsingAffineTransform:transform];
    [path appendBezierPath:arrow];
    [arrow transformUsingAffineTransform:transform];
    [path appendBezierPath:arrow];
    [arrow transformUsingAffineTransform:transform];
    [path appendBezierPath:arrow];
    return path;
}

@end


@implementation SKNavigationCloseButton
+ (Class)cellClass { return [SKNavigationCloseButtonCell class]; }
@end

@implementation SKNavigationCloseButtonCell

- (NSBezierPath *)pathWithFrame:(NSRect)cellFrame {
    NSRect rect = NSInsetRect(cellFrame, 8.0, 8.0);
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:rect];
    float radius = 2.0;
    rect = NSInsetRect(rect, 5.0, 5.0);
    [path moveToPoint:NSMakePoint(NSMidX(rect) + radius, NSMidY(rect) + radius)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMidX(rect), NSMaxY(rect)) radius:radius startAngle:0.0 endAngle:180.0];
    [path lineToPoint:NSMakePoint(NSMidX(rect) - radius, NSMidY(rect) + radius)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMidY(rect)) radius:radius startAngle:90.0 endAngle:270.0];
    [path lineToPoint:NSMakePoint(NSMidX(rect) - radius, NSMidY(rect) - radius)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMidX(rect), NSMinY(rect)) radius:radius startAngle:-180.0 endAngle:0.0];
    [path lineToPoint:NSMakePoint(NSMidX(rect) + radius, NSMidY(rect) - radius)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMidY(rect)) radius:radius startAngle:-90.0 endAngle:90.0];
    [path lineToPoint:NSMakePoint(NSMidX(rect) + radius, NSMidY(rect) + radius)];
    [path setWindingRule:NSEvenOddWindingRule];
    NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
    [transform translateXBy:NSMidX(rect) yBy:NSMidY(rect)];
    [transform rotateByDegrees:45.0];
    [transform translateXBy:-NSMidX(rect) yBy:-NSMidY(rect)];
    [path transformUsingAffineTransform:transform];
    return path;
}

@end


@implementation SKNavigationSeparatorButton
+ (Class)cellClass { return [SKNavigationSeparatorButtonCell class]; }
@end

@implementation SKNavigationSeparatorButtonCell

- (BOOL)isEnabled { return NO; }

- (NSBezierPath *)pathWithFrame:(NSRect)cellFrame {
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMidX(cellFrame) - 1.0, NSMinY(cellFrame), 2.0, NSHeight(cellFrame))];
    return path;
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

@end
