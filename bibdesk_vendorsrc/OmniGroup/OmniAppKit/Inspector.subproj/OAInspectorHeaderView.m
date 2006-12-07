// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OAInspectorHeaderView.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>

#import "NSImage-OAExtensions.h"
#import "OAAquaButton.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorHeaderView.m,v 1.22 2003/03/25 08:24:21 wjs Exp $")


@implementation OAInspectorHeaderView

typedef enum {
    OAInspectorHeaderImagePartLeftCap, OAInspectorHeaderImagePartWash, OAInspectorHeaderImagePartRightCap, OAInspectorHeaderImagePartCount,
} OAInspectorHeaderImagePart;
static NSString *OAInspectorHeaderImagePartNames[OAInspectorHeaderImagePartCount] = {@"Cap", @"Wash", @"Cap"};

typedef enum {
    OAInspectorHeaderImageTintBlue, OAInspectorHeaderImageTintGraphite, OAInspectorHeaderImageTintCount,
} OAInspectorHeaderImageTint;
static NSString *OAInspectorHeaderImageTintNames[OAInspectorHeaderImageTintCount] = {@"-Ice", @"-Graphite"};

typedef enum {
    OAInspectorHeaderImageStateNormal, OAInspectorHeaderImageStatePressed, OAInspectorHeaderImageStateCount,
} OAInspectorHeaderImageState;
static NSString *OAInspectorHeaderImageStateNames[OAInspectorHeaderImageStateCount] = {@"", @"-Pressed"};

typedef enum {
    OAInspectorCloseButtonStateNormal, OAInspectorCloseButtonStateRollover, OAInspectorCloseButtonStatePressed, OAInspectorCloseButtonStateCount
} OAInspectorCloseButtonState;
static NSString *OAInspectorCloseButtonStateNames[OAInspectorCloseButtonStateCount] = {@"-Normal", @"-Rollover", @"-Pressed"};

static NSImage *_headerImages[OAInspectorHeaderImagePartCount][OAInspectorHeaderImageTintCount][OAInspectorHeaderImageStateCount];
static NSSize _leftCapImageSize, _rightCapImageSize;

static NSImage *_expandedImage, *_collapsedImage;

static NSImage *_closeButtonImages[OAInspectorHeaderImageTintCount][OAInspectorCloseButtonStateCount];

static NSDictionary *_textAttributes, *_keyEquivalentAttributes;

static BOOL omitTextAndStateWhenCollapsed;

+ (void)initialize;
{
    OBINITIALIZE;

    {
        OAInspectorHeaderImagePart partIndex;
        for (partIndex = 0; partIndex < OAInspectorHeaderImagePartCount; partIndex++) {
            OAInspectorHeaderImageTint tintIndex;
            for (tintIndex = 0; tintIndex < OAInspectorHeaderImageTintCount; tintIndex++) {
                OAInspectorHeaderImageState stateIndex;
                for (stateIndex = 0; stateIndex < OAInspectorHeaderImageStateCount; stateIndex++) {
                    NSString *imageName = [NSString stringWithFormat:@"OAInfoPanelHeader%@%@%@", OAInspectorHeaderImagePartNames[partIndex], OAInspectorHeaderImageTintNames[tintIndex], OAInspectorHeaderImageStateNames[stateIndex]];
                    _headerImages[partIndex][tintIndex][stateIndex] = [[NSImage imageNamed:imageName inBundle:[self bundle]] retain];
                }
            }
        }
    }
    _leftCapImageSize = [_headerImages[OAInspectorHeaderImagePartLeftCap][OAInspectorHeaderImageTintBlue][OAInspectorHeaderImageStateNormal] size];
    _rightCapImageSize = [_headerImages[OAInspectorHeaderImagePartRightCap][OAInspectorHeaderImageTintBlue][OAInspectorHeaderImageStateNormal] size];

    {
        OAInspectorHeaderImageTint tintIndex;
        for (tintIndex = 0; tintIndex < OAInspectorHeaderImageTintCount; tintIndex++) {
            OAInspectorCloseButtonState stateIndex;
            for (stateIndex = 0; stateIndex < OAInspectorCloseButtonStateCount; stateIndex++) {
                NSString *imageName = [NSString stringWithFormat:@"WindowSmallCloseBox%@%@", OAInspectorCloseButtonStateNames[stateIndex], OAInspectorHeaderImageTintNames[tintIndex]];
                _closeButtonImages[tintIndex][stateIndex] = [[NSImage imageNamed:imageName inBundle:[self bundle]] retain];
            }
        }
    }

    _expandedImage = [[NSImage imageNamed:@"OAExpanded" inBundle:[self bundle]] retain];
    _collapsedImage = [[NSImage imageNamed:@"OACollapsed" inBundle:[self bundle]] retain];

    _textAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:[NSFont labelFontSize]], NSFontAttributeName, nil] retain];
    _keyEquivalentAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:[NSFont labelFontSize]], NSFontAttributeName, [NSColor darkGrayColor], NSForegroundColorAttributeName, nil] retain];

    omitTextAndStateWhenCollapsed = [[NSUserDefaults standardUserDefaults] boolForKey:@"OmitTextAndStateWhenCollapsed"];
}

- (void)setTitle:(NSString *)aTitle;
{
    if (title != aTitle) {
        [title release];
        title = [aTitle retain];
        [self setNeedsDisplay:YES];
    }
}

- (void)setImage:(NSImage *)anImage;
{
    if (image != anImage) {
        [image release];
        image = [anImage retain];
        [self setNeedsDisplay:YES];
    }
}

- (void)setKeyEquivalent:(NSString *)anEquivalent;
{
    if (keyEquivalent != anEquivalent) {
        [keyEquivalent release];
        keyEquivalent = [anEquivalent retain];
        [self setNeedsDisplay:YES];
    }
}

- (void)setExpanded:(BOOL)newState;
{
    if (isExpanded != newState) {
        isExpanded = newState;
        [self setNeedsDisplay:YES];
    }
}

- (void)setDelegate:(NSObject <OAInspectorHeaderViewDelegateProtocol> *)aDelegate;
{
    delegate = aDelegate;
}

- (float)minimumWidth;
{
    float result = 35.0;
    float keySize;
    
    if (!omitTextAndStateWhenCollapsed) 
        result += 35.0 + [title sizeWithAttributes:_textAttributes].width + 10.0;
        
    keySize = keyEquivalent ? [keyEquivalent sizeWithAttributes:_keyEquivalentAttributes].width + 10.0 : 0.0;
    result += 10.0 + keySize;
    
    return ceil(result);
}

// NSView subclass

- (BOOL)isFlipped;
{
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
{
    return YES;
}

- (void)resetCursorRects;
{
    if ([delegate headerViewShouldDisplayCloseButton:self]) {
        NSRect closeRect = NSMakeRect(NSMinX(_bounds) + 6.0, NSMaxY(_bounds)-1.0 - 14.0, 14.0, 14.0);    
        [self addTrackingRect:closeRect owner:self userData:NULL assumeInside:NO];
    }
}

- (void)viewDidMoveToWindow;
{
    [self resetCursorRects];
}

- (void)mouseEntered:(NSEvent *)theEvent;
{
    overClose = YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent;
{
    overClose = NO;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)aRect;
{
    BOOL drawAll = isExpanded || !omitTextAndStateWhenCollapsed;
    NSRect leftCapRect, washRect, rightCapRect;
    OAInspectorHeaderImageTint imageTint = (OACurrentControlTint() == OAAquaTint) ? OAInspectorHeaderImageTintBlue : OAInspectorHeaderImageTintGraphite;

    NSDivideRect(_bounds, &leftCapRect, &washRect, _leftCapImageSize.width, NSMinXEdge);
    NSDivideRect(washRect, &rightCapRect, &washRect, _rightCapImageSize.width, NSMaxXEdge);

    [_headerImages[OAInspectorHeaderImagePartLeftCap][imageTint][isClicking ? OAInspectorHeaderImageStatePressed : OAInspectorHeaderImageStateNormal] drawFlippedInRect:leftCapRect operation:NSCompositeCopy fraction:1.0];
    [_headerImages[OAInspectorHeaderImagePartWash][imageTint][isClicking ? OAInspectorHeaderImageStatePressed : OAInspectorHeaderImageStateNormal] drawFlippedInRect:washRect operation:NSCompositeCopy fraction:1.0];
    [_headerImages[OAInspectorHeaderImagePartRightCap][imageTint][isClicking ? OAInspectorHeaderImageStatePressed : OAInspectorHeaderImageStateNormal] drawFlippedInRect:rightCapRect operation:NSCompositeCopy fraction:1.0];
//    [_headerImages[OAInspectorHeaderImagePartWash][imageTint][isClicking ? OAInspectorHeaderImageStatePressed : OAInspectorHeaderImageStateNormal] drawFlippedInRect:_bounds operation:NSCompositeCopy fraction:1.0];
    
    if ([delegate headerViewShouldDisplayCloseButton:self]) {
        NSPoint closeImagePoint = NSMakePoint(NSMinX(_bounds) + 6.0, NSMaxY(_bounds)-1.0);
        NSImage *closeImage = _closeButtonImages[imageTint][clickingClose ? OAInspectorCloseButtonStatePressed : (overClose ? OAInspectorCloseButtonStateRollover : OAInspectorCloseButtonStateNormal)];
        
        [closeImage compositeToPoint:closeImagePoint operation:NSCompositeSourceOver];
    }
    
    if (drawAll) {
        NSImage *disclosureImage = isExpanded ? _expandedImage : _collapsedImage;
        NSPoint disclosureImagePoint = NSMakePoint(NSMinX(_bounds) + 26.0, NSMaxY(_bounds)-2.0);

        [disclosureImage compositeToPoint:disclosureImagePoint operation:NSCompositeSourceOver];

        if (isClicking && !isDragging) // our triangle images are 100% black, but about 50% opaque, so we just draw it again over itself
            [disclosureImage compositeToPoint:disclosureImagePoint operation:NSCompositeSourceOver fraction:0.6666];
    }
    
    {
        NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
        CGContextRef cgContext = [currentContext graphicsPort];
        float indent = drawAll ? 46.0 : 26.0;

        CGContextSaveGState(cgContext);
        CGContextTranslateCTM(cgContext, NSMinX(_bounds) + indent, NSMaxY(_bounds)-2.0);
        CGContextScaleCTM(cgContext, 1.0, -1.0);
        [image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        CGContextRestoreGState(cgContext);
    }
    
    if (drawAll)
        [title drawAtPoint:NSMakePoint(NSMinX(_bounds) + 66.0, NSMinY(_bounds) + 1.0) withAttributes:_textAttributes];

    [keyEquivalent drawAtPoint:NSMakePoint(NSMaxX(_bounds) - [keyEquivalent sizeWithAttributes:_keyEquivalentAttributes].width - 10.0, NSMinY(_bounds) + 1.0) withAttributes:_keyEquivalentAttributes];
}

- (void)mouseDown:(NSEvent *)theEvent;
{
    NSPoint click = [NSEvent mouseLocation];
    NSWindow *window = [self window];
    NSRect windowFrame = [window frame];
    NSSize windowOriginOffset = NSMakeSize(click.x - windowFrame.origin.x, click.y - windowFrame.origin.y);
    NSRect hysterisisRect = NSMakeRect(click.x - 3.0, click.y - 3.0, 6.0, 6.0);
    NSRect closeRect = NSMakeRect(NSMinX(_bounds) + 6.0, NSMaxY(_bounds)-1.0 - 14.0, 14.0, 14.0);
    NSPoint newTopLeft = NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
    float dragWindowHeight = 0.0;
    
    click = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    isDragging = NO;
    isClicking = YES;
    clickingClose = [delegate headerViewShouldDisplayCloseButton:self] && NSMouseInRect(click, closeRect, NO);
    [self display];
    
    do {
        theEvent = [window nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        click = [NSEvent mouseLocation];
        
        if (!isDragging) {
            if (!NSMouseInRect(click, hysterisisRect, NO)) {
                if ([theEvent clickCount] > 1) // don't drag on double-clicks
                    break; 
                dragWindowHeight = [delegate headerViewDraggingHeight:self];
                isDragging = YES;
                clickingClose = NO;
                [delegate headerViewDidBeginDragging:self];     
                windowFrame.size.width = [window frame].size.width; // because width may change due to disconnection
                [self display];
            } else if ([delegate headerViewShouldDisplayCloseButton:self]) {
                BOOL newCloseState;
                
                click = [self convertPoint:[theEvent locationInWindow] fromView:nil];
                newCloseState = NSMouseInRect(click, closeRect, NO);
                if (newCloseState != clickingClose) {
                    clickingClose = newCloseState;
                    [self display];
                }
            }
        }
        
        if (isDragging) {
            NSPoint newPoint = NSMakePoint(click.x - windowOriginOffset.width, click.y - windowOriginOffset.height);
            NSArray *screens = [NSScreen screens];
            int screenIndex = [screens count];
            NSScreen *screen = nil;
            NSRect resultRect;
            
            newTopLeft = NSMakePoint(newPoint.x, newPoint.y + [window frame].size.height);
            
            while (screenIndex--) {
                NSScreen *testScreen = [screens objectAtIndex:screenIndex];
                if (NSPointInRect(click, [testScreen visibleFrame]))
                    screen = testScreen;
            }
            if (!screen)
                screen = [window screen];

            resultRect = [delegate headerView:self willDragWindowToFrame:NSMakeRect(newTopLeft.x, newTopLeft.y - dragWindowHeight, windowFrame.size.width, dragWindowHeight) onScreen:screen];
            
            // convert result group rect to result window rect
            resultRect.origin.y = NSMaxY(resultRect) - windowFrame.size.height;
            resultRect.size.height = windowFrame.size.height;
            
            [window setFrame:resultRect display:YES];
            newTopLeft = NSMakePoint(NSMinX(resultRect), NSMaxY(resultRect));
        }
    } while ([theEvent type] != NSLeftMouseUp);

    if (isDragging)
        [delegate headerViewDidEndDragging:self toFrame:NSMakeRect(newTopLeft.x, newTopLeft.y - dragWindowHeight, windowFrame.size.width, dragWindowHeight)];
    else if (clickingClose)
        [delegate headerViewDidClose:self];
    else
        [delegate headerViewDidToggleExpandedness:self];
    isDragging = NO;
    isClicking = NO;
    clickingClose = NO;
    [self display];
}

@end
