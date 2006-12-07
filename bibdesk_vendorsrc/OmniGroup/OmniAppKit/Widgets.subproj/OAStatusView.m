// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OAStatusView.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import <OmniAppKit/NSString-OAExtensions.h>
#import <OmniAppKit/OAProgressView.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAStatusView.m,v 1.17 2003/01/15 22:51:45 kc Exp $")

@interface OAStatusView (private)
- (void)resetBounds;
@end

// This should really be a public protocol

@implementation OAStatusView

static NSColor *toolTipColor;
static NSColor *darkBorderColor;
static NSColor *mediumBorderColor;
static NSColor *lightBorderColor;

#define X_BORDER 3.0
#define Y_BORDER_ABOVE 2.0
#define Y_BORDER_BELOW 5.0
#define PROGRESS_WIDTH	100.0
#define PROGRESS_BORDER_SPACE 3.0

+ (void)initialize
{
    static BOOL alreadyInitialized = NO;

    [super initialize];
    if (alreadyInitialized)
        return;
    alreadyInitialized = YES;

    toolTipColor = [[NSColor colorWithCalibratedHue:1.0/6.0 saturation:.25 brightness:1 alpha:1] retain];
    darkBorderColor = [[NSColor colorWithCalibratedHue:1.0/6.0 saturation:.25 brightness:.15 alpha:.75] retain];
    mediumBorderColor = [[NSColor colorWithCalibratedHue:1.0/6.0 saturation:.25 brightness:.15 alpha:.5] retain];
    lightBorderColor = [[NSColor colorWithCalibratedHue:1.0/6.0 saturation:.25 brightness:.15 alpha:.25] retain];
}

// Init and dealloc

- init;
{
    if (!(self = [super initWithFrame:NSMakeRect(0,0,100,100)]))
        return nil;
    
    attributes = [[NSMutableDictionary alloc] initWithCapacity:2];
    [self setFont:[NSFont boldSystemFontOfSize:12.0]];
    [self setColor:[NSColor blackColor]];
    
    [self setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];
    progressView = [[OAProgressView alloc] initWithFrame:NSMakeRect(0,0,100,100)];

    return self;
}

- (void)dealloc;
{
    [status release];
    [attributes release];
    [progressView release];
    [super dealloc];
}


// NSView

- (void)drawRect:(NSRect)rect;
{
    [self drawBackground];
    [self drawStatus];

    if (flags.hasProgressView) {
        NSRect progressFrame, progressBounds;
        NSAffineTransform *transform;

        progressFrame = [progressView frame];
        progressBounds = [progressView bounds];
        transform = [NSAffineTransform transform];
        [transform translateXBy:NSMinX(progressFrame) yBy:NSMinY(progressFrame)];
        [transform concat];
        [progressView drawRect:progressBounds]; // Just draw the whole darn thing
        [transform invert];
        [transform concat];
    }
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    if (!newWindow && [self superview])
        [self removeFromSuperview];
}

- (BOOL)needsDisplay;
{
    return YES;
}


// API

- (void)setFont:(NSFont *)font;
{
    if (font == [attributes objectForKey:NSFontAttributeName])
        return;

    [attributes setObject:font forKey:NSFontAttributeName];
    ascenderHackAroundRhapsodyBug = [font ascender];
    if (status)
        [self resetBounds];
}

- (void)setColor:(NSColor *)color;
{
    if (color == [attributes objectForKey:NSForegroundColorAttributeName])
        return;

    [attributes setObject:color forKey:NSForegroundColorAttributeName];
    [self setNeedsDisplay:YES];
}

- (void)setStatus:(NSString *)aStatus;
{
    if (status == aStatus)
        return;

    [status release];
    status = [aStatus retain];
    flags.hasProgressView = NO;
    if (status)
        [self resetBounds];
}

- (void)setStatus:(NSString *)aStatus withProgress:(unsigned int)amount ofTotal:(unsigned int)total;
{
    if (status != aStatus) {
        [status release];
        status = [aStatus retain];
    }

    [progressView processedBytes:amount ofBytes:total];

    flags.hasProgressView = YES;
    if (status)
        [self resetBounds];
}


// For overriding in subclasses

- (void)drawBackground;
{
    NSRect bounds;
    NSRect rects[6];
    NSColor *colors[6];

    bounds = [self bounds];
    
    // First, fill in lower left with transparency
    rects[0] = NSMakeRect(NSMinX(bounds), NSMinY(bounds), 3, 3);
    colors[0] = [NSColor colorWithCalibratedWhite:0 alpha:0];
    NSRectFillListWithColors(rects, colors, 1);

    // Main area
    rects[0] = NSMakeRect(NSMinX(bounds)+1, NSMinY(bounds)+4, NSWidth(bounds)-1, NSHeight(bounds)-4);
    colors[0] = toolTipColor;

    // dark border to left and below
    rects[1] = NSMakeRect(NSMinX(bounds), NSMinY(bounds)+3, 1, NSHeight(bounds)-1);
    colors[1] = [NSColor controlDarkShadowColor];

    rects[2] = NSMakeRect(NSMinX(bounds), NSMinY(bounds)+3, NSWidth(bounds), 1);
    colors[2] = [NSColor controlDarkShadowColor];

    // Shadows
    rects[3] = NSMakeRect(NSMinX(bounds)+1, NSMinY(bounds)+2, NSWidth(bounds)-1, 1);
    colors[3] = darkBorderColor;

    rects[4] = NSMakeRect(NSMinX(bounds)+2, NSMinY(bounds)+1, NSWidth(bounds)-2, 1);
    colors[4] = mediumBorderColor;

    rects[5] = NSMakeRect(NSMinX(bounds)+3, NSMinY(bounds), NSWidth(bounds)-3, 1);
    colors[5] = lightBorderColor;

    NSRectFillListWithColors(rects, colors, 6);
}

- (void)drawStatus;
{
    NSRect bounds;
    NSPoint textPoint;

    bounds = [self bounds];
    textPoint = (NSPoint){bounds.origin.x + X_BORDER, bounds.origin.y + Y_BORDER_BELOW};

    {
        // Since we aren't flipped, we have to hack around bug in Rhapsody for now. When Rhapsody can draw strings in unflipped views, remove this and the ascenderHack... variable.
        textPoint.y -= ascenderHackAroundRhapsodyBug;
    }

    [status drawAtPoint:textPoint withAttributes:attributes];
}

@end


@implementation OAStatusView (Private)

- (void)resetBounds;
{
    NSRect bounds;
    NSSize statusStringSize, neededSize;

    statusStringSize = [status sizeWithAttributes:attributes];
    neededSize = NSMakeSize(ceil(statusStringSize.width + X_BORDER * 2.0), ceil(statusStringSize.height + Y_BORDER_BELOW + Y_BORDER_ABOVE));
    if (flags.hasProgressView)
        neededSize.width += PROGRESS_WIDTH + PROGRESS_BORDER_SPACE * 2.0;

    bounds = NSMakeRect(0, 0, neededSize.width, neededSize.height);

    if (flags.hasProgressView) {
        [progressView setFrame:NSMakeRect(NSMaxX(bounds) - (PROGRESS_WIDTH + PROGRESS_BORDER_SPACE), NSMinY(bounds) + Y_BORDER_BELOW + 1, PROGRESS_WIDTH, NSHeight(bounds) - (Y_BORDER_BELOW + Y_BORDER_ABOVE + 1))];
    }

    [self setFrame:bounds];
}

@end
