//
//  SKPDFToolTipWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
/*
 This software is Copyright (c) 2007-2009
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

#import "SKPDFToolTipWindow.h"
#import "PDFPage_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "NSParagraphStyle_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSAffineTransform_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"

#define WINDOW_OFFSET           20.0
#define TEXT_MARGIN_X           2.0
#define TEXT_MARGIN_Y           2.0
#define ALPHA_VALUE             0.95
#define CRITICAL_ALPHA_VALUE    0.9
#define AUTO_HIDE_TIME_INTERVAL 7.0
#define DEFAULT_SHOW_DELAY      1.0
#define ALT_SHOW_DELAY          0.1


NSString *SKToolTipWidthKey = @"SKToolTipWidth";
NSString *SKToolTipHeightKey = @"SKToolTipHeight";


static NSFont *font = nil;
static NSColor *backgroundColor = nil;
static NSFont *labelFont = nil;
static NSColor *labelColor = nil;


@interface NSScreen (SKExtensions)
+ (NSScreen *)screenForPoint:(NSPoint)point;
@end


@implementation SKPDFToolTipWindow

+ (void)initialize {
    SKINITIALIZE;
    
    font = [[NSFont toolTipsFontOfSize:11.0] retain];
    backgroundColor = [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.75 alpha:1.0] retain];
    labelFont = [[NSFont boldSystemFontOfSize:11.0] retain];
    labelColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.8] retain];
}

+ (id)sharedToolTipWindow {
    static SKPDFToolTipWindow *sharedToolTipWindow = nil;
    if (sharedToolTipWindow == nil)
        sharedToolTipWindow = [[self alloc] init];
    return sharedToolTipWindow;
}

- (id)init {
    if (self = [super initWithContentRect:NSZeroRect]) {
        [self setHidesOnDeactivate:NO];
        [self setIgnoresMouseEvents:YES];
        [self setOpaque:YES];
        [self setBackgroundColor:[NSColor whiteColor]];
        [self setHasShadow:YES];
        [self setLevel:NSStatusWindowLevel];
    
        
        NSImageView *imageView = [[NSImageView alloc] init];
        [imageView setImageFrameStyle:NSImageFrameNone];
        [[imageView enclosingScrollView] setDrawsBackground:NO];
        [self setContentView:imageView];
        [imageView release];
        
        context = nil;
        point = NSZeroPoint;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActiveNotification:) 
                                                     name:NSApplicationWillResignActiveNotification object:NSApp];
    }
    return self;
}

- (void)handleApplicationWillResignActiveNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self orderOut:self];
}

- (CGFloat)defaultAlphaValue { return ALPHA_VALUE; }

- (NSTimeInterval)autoHideTimeInterval { return AUTO_HIDE_TIME_INTERVAL; }

- (void)willClose {
    SKDESTROY(context);
    point = NSZeroPoint;
}

- (void)fadeOut {
    [super fadeOut];
}

- (void)showDelayed {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSPoint thePoint = NSEqualPoints(point, NSZeroPoint) ? [NSEvent mouseLocation] : point;
    NSRect contentRect = NSMakeRect(thePoint.x, thePoint.y - WINDOW_OFFSET, [sud floatForKey:SKToolTipWidthKey], [sud floatForKey:SKToolTipHeightKey]);
    NSImage *image = [context toolTipImageForDefaultSize:contentRect.size];
    
    [self cancelDelayedAnimations];
    
    if (image) {
        [(NSImageView *)[self contentView] setImage:image];
        
        contentRect.size = [image size];
        contentRect.origin.y -= NSHeight(contentRect);
        contentRect = SKConstrainRect(contentRect, [[NSScreen screenForPoint:thePoint] visibleFrame]);
        [self setFrame:[self frameRectForContentRect:contentRect] display:NO];
        
        [self stopAnimation];
        if ([self isVisible] && [self alphaValue] > CRITICAL_ALPHA_VALUE)
            [self orderFront:self];
        else
            [self fadeIn];
        
    } else {
        
        [self fadeOut];
        
    }
}

- (void)cancelDelayedAnimations {
    [super cancelDelayedAnimations];
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(showDelayed) object:nil];
}

- (void)showForPDFContext:(id<SKPDFToolTipContext>)aContext atPoint:(NSPoint)aPoint {
    point = aPoint;
    
    if ([aContext isEqual:context] == NO) {
        [self stopAnimation];
        
        [context release];
        context = [aContext retain];
        
        [self performSelector:@selector(showDelayed) withObject:nil afterDelay:[self isVisible] ? ALT_SHOW_DELAY : DEFAULT_SHOW_DELAY];
    }
}

- (id<SKPDFToolTipContext>)currentPDFContext {
    return context;
}

@end


static inline CGFloat SKSquaredDistanceFromPointToRect(NSPoint point, NSRect rect) {
    CGFloat dx, dy;

    if (point.x < NSMinX(rect))
        dx = NSMinX(rect) - point.x;
    else if (point.x > NSMaxX(rect))
        dx = point.x - NSMaxX(rect);
    else
        dx = 0.0;

    if (point.y < NSMinY(rect))
        dy = NSMinY(rect) - point.y;
    else if (point.y > NSMaxY(rect))
        dy = point.y - NSMaxY(rect);
    else
        dy = 0.0;
    
    return dx * dx + dy * dy;
}


@implementation NSScreen (SKExtensions)

+ (NSScreen *)screenForPoint:(NSPoint)point {
    NSScreen *screen = nil;
    CGFloat distanceSquared = CGFLOAT_MAX;
    
    for (NSScreen *aScreen in [NSScreen screens]) {
        NSRect frame = [aScreen frame];
        
        if (NSPointInRect(point, frame))
            return aScreen;
        
        CGFloat aDistanceSquared = SKSquaredDistanceFromPointToRect(point, frame);
        if (aDistanceSquared < distanceSquared) {
            distanceSquared = aDistanceSquared;
            screen = aScreen;
        }
    }
    
    return screen;
}

@end

#pragma mark -

@interface PDFDestination (SKPDFToolTipContextExtension)
- (NSImage *)toolTipImageForDefaultSize:(NSSize)aSize offset:(NSPoint)offset;
@end

@implementation PDFDestination (SKPDFToolTipContext)

- (NSImage *)toolTipImageForDefaultSize:(NSSize)aSize offset:(NSPoint)offset {
    PDFPage *page = [self page];
    
    NSImage *pageImage = [page thumbnailWithSize:0.0 forBox:kPDFDisplayBoxCropBox shadowBlurRadius:0.0 shadowOffset:NSZeroSize readingBarRect:NSZeroRect];
    NSRect pageImageRect = {NSZeroPoint, [pageImage size]};
    NSRect bounds = [page boundsForBox:kPDFDisplayBoxCropBox];
    NSRect sourceRect = {NSZeroPoint, aSize};
    PDFSelection *selection = [page selectionForRect:bounds];
    NSAffineTransform *transform = [NSAffineTransform transform];
    
    switch ([page rotation]) {
        case 0:
            [transform translateXBy:-NSMinX(bounds) yBy:-NSMinY(bounds)];
            break;
        case 90:
            [transform translateXBy:-NSMinY(bounds) yBy:NSMaxX(bounds)];
            break;
        case 180:
            [transform translateXBy:NSMaxX(bounds) yBy:NSMaxY(bounds)];
            break;
        case 270:
            [transform translateXBy:NSMaxY(bounds) yBy:-NSMinX(bounds)];
            break;
    }
    [transform rotateByDegrees:-[page rotation]];
    
    bounds = [transform transformRect:bounds];
    
    sourceRect.origin = SKAddPoints([transform transformPoint:[self point]], offset);
    sourceRect.origin.y -= NSHeight(sourceRect);
    
    
    if ([selection hasCharacters]) {
        NSRect selBounds = [transform transformRect:[selection boundsForPage:page]];
        CGFloat top = ceil(fmax(NSMaxY(selBounds), NSMinX(selBounds) + NSHeight(sourceRect)));
        CGFloat left = floor(fmin(NSMinX(selBounds), NSMaxX(bounds) - NSWidth(sourceRect)));
        if (top < NSMaxY(sourceRect))
            sourceRect.origin.y = top - NSHeight(sourceRect);
        if (left > NSMinX(sourceRect))
            sourceRect.origin.x = left;
    }
    
    sourceRect = SKConstrainRect(sourceRect, pageImageRect);
    
    NSDictionary *attrs = [[NSDictionary alloc] initWithObjectsAndKeys:labelFont, NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, [NSParagraphStyle defaultClippingParagraphStyle], NSParagraphStyleAttributeName, nil];
    NSAttributedString *labelString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Page %@", @"Tool tip label format"), [page displayLabel]] attributes:attrs];
    NSRect labelRect = [labelString boundingRectWithSize:NSZeroSize options:NSStringDrawingUsesLineFragmentOrigin];
    
    labelRect.size.width = floor(NSWidth(labelRect));
    labelRect.size.height = 2.0 * floor(0.5 * NSHeight(labelRect)); // make sure the cap radius is integral
    labelRect.origin.x = NSWidth(sourceRect) - NSWidth(labelRect) - 0.5 * NSHeight(labelRect) - TEXT_MARGIN_X;
    labelRect.origin.y = TEXT_MARGIN_Y;
    labelRect = NSIntegralRect(labelRect);
    
    NSRect targetRect = sourceRect;
    targetRect.origin = NSZeroPoint;
    
    NSImage *image = [[[NSImage alloc] initWithSize:targetRect.size] autorelease];
    
    [image lockFocus];
    
    [pageImage drawInRect:targetRect fromRect:sourceRect operation:NSCompositeCopy fraction:1.0];
    
    CGFloat radius = 0.5 * NSHeight(labelRect);
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    [path moveToPoint:SKTopLeftPoint(labelRect)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(labelRect), NSMidY(labelRect)) radius:radius startAngle:90.0 endAngle:270.0];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(labelRect), NSMidY(labelRect)) radius:radius startAngle:-90.0 endAngle:90.0];
    [path closePath];
    
    [labelColor setFill];
    [path fill];
    
    [labelString drawWithRect:labelRect options:NSStringDrawingUsesLineFragmentOrigin];
    
    [image unlockFocus];
    
    [attrs release];
    [labelString release];
    
    return image;
}

- (NSImage *)toolTipImageForDefaultSize:(NSSize)aSize {
    return [self toolTipImageForDefaultSize:aSize offset:NSMakePoint(-50.0, 20.0)];
}

@end


static NSImage *toolTipImageForAttributedString(NSAttributedString *attrString, NSSize aSize) {
    if ([attrString length] == 0)
        return nil;
    
    NSRect textRect = [attrString boundingRectWithSize:NSMakeSize(aSize.width + 2 * TEXT_MARGIN_X, aSize.height + 2 * TEXT_MARGIN_Y) options:NSStringDrawingUsesLineFragmentOrigin];
    
    textRect.size.height = fmin(NSHeight(textRect), aSize.height);
    textRect.origin = NSMakePoint(TEXT_MARGIN_X, TEXT_MARGIN_Y);
    
    NSRect imageRect = {NSZeroPoint, NSInsetRect(NSIntegralRect(textRect), -TEXT_MARGIN_X, -TEXT_MARGIN_X).size};
    NSImage *image = [[[NSImage alloc] initWithSize:imageRect.size] autorelease];
    
    [image lockFocus];
    [backgroundColor setFill];
    NSRectFill(imageRect);
    [attrString drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin];
    [image unlockFocus];
    
    return image;
}

static NSAttributedString *toolTipAttributedStringForString(NSString *string) {
    NSDictionary *attrs = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, [NSParagraphStyle defaultClippingParagraphStyle], NSParagraphStyleAttributeName, nil];
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:string attributes:attrs] autorelease];
    [attrs release];
    return attrString;
}


@implementation PDFAnnotation (SKPDFToolTipContext)

- (NSImage *)toolTipImageForDefaultSize:(NSSize)aSize {
    NSAttributedString *attrString = [self text];
    NSString *string = [attrString string];
    NSUInteger i, l = [string length];
    NSRange r = NSMakeRange(0, l);
    
    while (NSNotFound != (i = NSMaxRange([string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:NSAnchoredSearch range:r])))
        r = NSMakeRange(i, l - i);
    while (NSNotFound != (i = [string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:NSBackwardsSearch | NSAnchoredSearch range:r].location))
        r.length = i - r.location;
    if (r.length < l)
        attrString = [attrString attributedSubstringFromRange:r];
    
    if ([attrString length] == 0) {
        string = [self string];
        attrString = [string length] ? toolTipAttributedStringForString(string) : nil;
    }
    
    return toolTipImageForAttributedString(attrString, aSize);
}

@end


@implementation PDFAnnotationLink (SKPDFToolTipContext)

- (NSImage *)toolTipImageForDefaultSize:(NSSize)aSize {
    PDFDestination *dest = [self destination];
    if (dest)
        return [dest toolTipImageForDefaultSize:aSize offset:NSZeroPoint];
    else
        return toolTipImageForAttributedString(toolTipAttributedStringForString([[self URL] absoluteString]), aSize);
}

@end


@implementation PDFPage (SKPDFToolTipContext)

- (NSImage *)toolTipImageForDefaultSize:(NSSize)aSize {
    return [self thumbnailWithSize:128.0 forBox:kPDFDisplayBoxCropBox shadowBlurRadius:0.0 shadowOffset:NSZeroSize readingBarRect:NSZeroRect];
}

@end
