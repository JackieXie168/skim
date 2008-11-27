//
//  SKPDFToolTipWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
/*
 This software is Copyright (c) 2007-2008
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
#import "NSBezierPath_BDSKExtensions.h"
#import "NSParagraphStyle_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSAffineTransform_SKExtensions.h"

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

@interface NSScreen (SKExtensions)
+ (NSScreen *)screenForPoint:(NSPoint)point;
@end


@implementation SKPDFToolTipWindow

static SKPDFToolTipWindow *sharedToolTipWindow = nil;

+ (id)sharedToolTipWindow {
    if (sharedToolTipWindow == nil)
        [[self alloc] init];
    return sharedToolTipWindow;
}

+ (id)allocWithZone:(NSZone *)zone {
    return sharedToolTipWindow ?: [super allocWithZone:zone];
}

- (id)init {
    if (sharedToolTipWindow == nil && (sharedToolTipWindow = self = [super initWithContentRect:NSZeroRect])) {
        [self setHidesOnDeactivate:NO];
        [self setIgnoresMouseEvents:YES];
		[self setOpaque:YES];
        [self setBackgroundColor:[NSColor whiteColor]];
        [self setHasShadow:YES];
        [self setLevel:NSStatusWindowLevel];
    
        
        NSImageView *imageView = [[NSImageView alloc] init];
        [imageView setImageFrameStyle:NSImageFrameNone];
        [self setContentView:imageView];
        [imageView release];
        
        font = [[NSFont toolTipsFontOfSize:11.0] retain];
        backgroundColor = [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.75 alpha:1.0] retain];
        labelFont = [[NSFont boldSystemFontOfSize:11.0] retain];
        labelColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.8] retain];
        
        annotation = nil;
        point = NSZeroPoint;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActiveNotification:) 
                                                     name:NSApplicationWillResignActiveNotification object:NSApp];
    }
    return sharedToolTipWindow;
}

- (void)dealloc {
    [font release];
    [backgroundColor release];
    [labelFont release];
    [labelColor release];
    [super dealloc];
}

- (id)retain { return self; }

- (id)autorelease { return self; }

- (void)release {}

- (unsigned)retainCount { return UINT_MAX; }

- (NSFont *)font {
    return font;
}

- (void)setFont:(NSFont *)newFont {
    if (font != newFont) {
        [font release];
        font = [newFont retain];
    }
}

- (NSColor *)backgroundColor {
    return backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)newColor {
    if (backgroundColor != newColor) {
        [backgroundColor release];
        backgroundColor = [newColor retain];
    }
}

- (NSFont *)labelFont {
    return labelFont;
}

- (void)setLabelFont:(NSFont *)newFont {
    if (labelFont != newFont) {
        [labelFont release];
        labelFont = [newFont retain];
    }
}

- (NSColor *)labelColor {
    return labelColor;
}

- (void)setLabelColor:(NSColor *)newColor {
    if (labelColor != newColor) {
        [labelColor release];
        labelColor = [newColor retain];
    }
}

- (void)handleApplicationWillResignActiveNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self orderOut:self];
}

- (float)defaultAlphaValue { return ALPHA_VALUE; }

- (NSTimeInterval)autoHideTimeInterval { return AUTO_HIDE_TIME_INTERVAL; }

- (void)willClose {
    [annotation release];
    annotation = nil;
    point = NSZeroPoint;
}

- (void)fadeOut {
    [super fadeOut];
}

- (void)showDelayed {
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSPoint thePoint = NSEqualPoints(point, NSZeroPoint) ? [NSEvent mouseLocation] : point;
    NSRect contentRect = NSMakeRect(thePoint.x, thePoint.y - WINDOW_OFFSET, [sud floatForKey:SKToolTipWidthKey], [sud floatForKey:SKToolTipHeightKey]);
    NSImage *image = nil;
    NSAttributedString *text = nil;
    NSString *string = nil;
    NSColor *color = nil;
    
    [self cancelDelayedAnimations];
    
    if ([annotation isLink]) {
        
        PDFDestination *dest = [annotation destination];
        PDFPage *page = [dest page];
        
        if (page) {
            
            NSImage *pageImage = [page thumbnailWithSize:0.0 forBox:kPDFDisplayBoxCropBox shadowBlurRadius:0.0 shadowOffset:NSZeroSize readingBarRect:NSZeroRect];
            NSRect pageImageRect = {NSZeroPoint, [pageImage size]};
            NSRect bounds = [page boundsForBox:kPDFDisplayBoxCropBox];
            NSRect sourceRect = contentRect;
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
            
            sourceRect.origin = [transform transformPoint:[dest point]];
            sourceRect.origin.y -= NSHeight(sourceRect);
            
            if ([selection string]) {
                NSRect selBounds = [transform transformRect:[selection boundsForPage:page]];
                float top = ceilf(fmaxf(NSMaxY(selBounds), NSMinX(selBounds) + NSHeight(sourceRect)));
                float left = floorf(fminf(NSMinX(selBounds), NSMaxX(bounds) - NSWidth(sourceRect)));
                if (top < NSMaxY(sourceRect))
                    sourceRect.origin.y = top - NSHeight(sourceRect);
                if (left > NSMinX(sourceRect))
                    sourceRect.origin.x = left;
            }
            
            color = [NSColor controlBackgroundColor];
            
            sourceRect = SKConstrainRect(sourceRect, pageImageRect);
            
            NSDictionary *attrs = [[NSDictionary alloc] initWithObjectsAndKeys:labelFont, NSFontAttributeName, color, NSForegroundColorAttributeName, [NSParagraphStyle defaultClippingParagraphStyle], NSParagraphStyleAttributeName, nil];
            NSAttributedString *labelString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Page %@", @"Tool tip label format"), [page displayLabel]] attributes:attrs];
            NSRect labelRect = [labelString boundingRectWithSize:NSZeroSize options:NSStringDrawingUsesLineFragmentOrigin];
            
            labelRect.size.width = floorf(NSWidth(labelRect));
            labelRect.size.height = 2.0 * floorf(0.5 * NSHeight(labelRect)); // make sure the cap radius is integral
            labelRect.origin.x = NSWidth(sourceRect) - NSWidth(labelRect) - 0.5 * NSHeight(labelRect) - TEXT_MARGIN_X;
            labelRect.origin.y = TEXT_MARGIN_Y;
            labelRect = NSIntegralRect(labelRect);
            
            NSRect targetRect = sourceRect;
            targetRect.origin = NSZeroPoint;
            
            image = [[NSImage alloc] initWithSize:targetRect.size];
            
            [image lockFocus];
            [pageImage drawInRect:targetRect fromRect:sourceRect operation:NSCompositeCopy fraction:1.0];
            [labelColor setFill];
            [NSBezierPath fillHorizontalOvalAroundRect:labelRect];
            [labelString drawWithRect:labelRect options:NSStringDrawingUsesLineFragmentOrigin];
            [image unlockFocus];
            
            [attrs release];
            [labelString release];
            
        } else {
            
            string = [[(PDFAnnotationLink *)annotation URL] absoluteString];
            
        }
        
    } else {
        
        text = [annotation text];
        string = [text string];
        unsigned int i = 0, l = [string length];
        NSRange r = NSMakeRange(0, l);
        
        while (i != NSNotFound) {
            r = NSMakeRange(i, l - i);
            i = [string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:NSAnchoredSearch range:r].location;
        }
        i = l;
        while (i != NSNotFound) {
            r.length = i - r.location;
            i = [string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:NSBackwardsSearch | NSAnchoredSearch range:r].location;
        }
        if (r.length < l)
            text = [text attributedSubstringFromRange:r];
        
        string = nil;
        
        if ([text length] == 0) {
            text = nil;
            if ([[annotation string] length])
                string = [annotation string];
        }
        // we release text later
        [text retain];
    }
    
    if (string) {
        NSDictionary *attrs = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, [NSParagraphStyle defaultClippingParagraphStyle], NSParagraphStyleAttributeName, nil];
        string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        text = [[NSAttributedString alloc] initWithString:string attributes:attrs];
        [attrs release];
    }
    
    if (text) {
        
        NSRect textRect = [text boundingRectWithSize:NSInsetRect(contentRect, TEXT_MARGIN_X, TEXT_MARGIN_Y).size options:NSStringDrawingUsesLineFragmentOrigin];
        
        textRect.size.height = fminf(NSHeight(textRect), NSHeight(contentRect) - 2.0 * TEXT_MARGIN_Y);
        textRect.origin = NSMakePoint(TEXT_MARGIN_X, TEXT_MARGIN_Y);
        
        image = [[NSImage alloc] initWithSize:NSInsetRect(NSIntegralRect(textRect), -TEXT_MARGIN_X, -TEXT_MARGIN_X).size];
        color = backgroundColor;
        
        [image lockFocus];
        [text drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin];
        [image unlockFocus];
        
        [text release];
        
    }
    
    if (image) {
        
        NSImageView *imageView = (NSImageView *)[self contentView];
        
        [imageView setImage:image];
        [image release];
        
        contentRect.size = [image size];
        contentRect.origin.y -= NSHeight(contentRect);
        contentRect = SKConstrainRect(contentRect, [[NSScreen screenForPoint:thePoint] visibleFrame]);
        [self setFrame:[self frameRectForContentRect:contentRect] display:NO];
        
        [[imageView enclosingScrollView] setBackgroundColor:color];
        
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

- (void)showForAnnotation:(PDFAnnotation *)note atPoint:(NSPoint)aPoint {
    point = aPoint;
    
    if ([note isEqual:annotation] == NO) {
        [self stopAnimation];
        
        [annotation release];
        annotation = [note retain];
        
        [self performSelector:@selector(showDelayed) withObject:nil afterDelay:[self isVisible] ? ALT_SHOW_DELAY : DEFAULT_SHOW_DELAY];
    }
}

@end


static inline float SKSquaredDistanceFromPointToRect(NSPoint point, NSRect rect) {
    float dx, dy;

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
    NSEnumerator *screenEnum = [[NSScreen screens] objectEnumerator];
    NSScreen *aScreen;
    NSScreen *screen = nil;
    float distanceSquared = FLT_MAX;
    
    while (aScreen = [screenEnum nextObject]) {
        NSRect frame = [aScreen frame];
        
        if (NSPointInRect(point, frame))
            return aScreen;
        
        float aDistanceSquared = SKSquaredDistanceFromPointToRect(point, frame);
        if (aDistanceSquared < distanceSquared) {
            distanceSquared = aDistanceSquared;
            screen = aScreen;
        }
    }
    
    return screen;
}

@end
