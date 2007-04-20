//
//  SKPDFHoverWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
/*
 This software is Copyright (c) 2007
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

#import "SKPDFHoverWindow.h"
#import "PDFPage_SKExtensions.h"
#import "SKPDFAnnotationNote.h"
#import "NSBezierPath_BDSKExtensions.h"

#define WINDOW_WIDTH    400.0
#define WINDOW_HEIGHT   80.0
#define WINDOW_OFFSET   20.0
#define TEXT_MARGIN_X   2.0
#define TEXT_MARGIN_Y   2.0
#define ALPHA_VALUE     0.95

@implementation SKPDFHoverWindow

+ (id)sharedHoverWindow {
    static SKPDFHoverWindow *sharedHoverWindow = nil;
    if (sharedHoverWindow == nil)
        sharedHoverWindow = [[self alloc] init];
    return sharedHoverWindow;
}

- (id)init {
    if (self = [super initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO]) {
        [self setHidesOnDeactivate:NO];
        [self setIgnoresMouseEvents:YES];
        [self setBackgroundColor:[NSColor whiteColor]];
        [self setHasShadow:YES];
        [self setLevel:NSStatusWindowLevel];
        [self setAlphaValue:ALPHA_VALUE];
        
        NSScrollView *scrollView = [[NSScrollView alloc] init];
        imageView = [[NSImageView alloc] init];
        [imageView setImageFrameStyle:NSImageFrameNone];
        [scrollView setDocumentView:imageView];
        [self setContentView:scrollView];
        [scrollView release];
        [imageView release];
        
        font = [[NSFont toolTipsFontOfSize:11.0] retain];
        backgroundColor = [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.75 alpha:1.0] retain];
        labelFont = [[NSFont boldSystemFontOfSize:11.0] retain];
        labelColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.8] retain];
        
        annotation = nil;
        point = NSZeroPoint;
        animation = nil;
        timer = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActiveNotification:) 
                                                     name:NSApplicationWillResignActiveNotification object:NSApp];
    }
    return self;
}

- (void)dealloc {
    [font release];
    [backgroundColor release];
    [labelFont release];
    [labelColor release];
    [super dealloc];
}

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
    [self orderOut:self];
}

- (void)stopTimer {
    [timer invalidate];
    [timer release];
    timer = nil;
}

- (BOOL)canBecomeKeyWindow { return NO; }

- (BOOL)canBecomeMainWindow { return NO; }

- (void)orderFront:(id)sender {
    [self stopTimer];
    [animation stopAnimation];
    [self setAlphaValue:ALPHA_VALUE];
    [super orderFront:sender];
}

- (void)orderOut:(id)sender {
    [self stopTimer];
    [animation stopAnimation];
    [self setAlphaValue:ALPHA_VALUE];
    [annotation release];
    annotation = nil;
    point = NSZeroPoint;
    [super orderOut:sender];
}

- (NSRect)hoverWindowRectFittingScreenFromRect:(NSRect)rect{
    NSRect screenRect = [[NSScreen mainScreen] visibleFrame];
    
    if (NSMaxX(rect) > NSMaxX(screenRect) - 2.0)
        rect.origin.x = NSMaxX(screenRect) - NSWidth(rect) - 2.0;
    if (NSMinX(rect) < NSMinX(screenRect) + 2.0)
        rect.origin.x = NSMinX(screenRect) + 2.0;
    if (NSMaxY(rect) > NSMaxY(screenRect) - 2.0)
        rect.origin.y = NSMaxY(screenRect) - NSHeight(rect) - 2.0;
    if (NSMinY(rect) < NSMinY(screenRect) + 2.0)
        rect.origin.y = NSMinY(screenRect) + 2.0;
    
    return [self frameRectForContentRect:rect];
}

- (void)timerFired:(NSTimer *)aTimer {
    NSPoint thePoint = NSEqualPoints(point, NSZeroPoint) ? [NSEvent mouseLocation] : point;
    NSRect rect = NSZeroRect;
    NSRect contentRect = NSMakeRect(thePoint.x, thePoint.y - WINDOW_OFFSET, WINDOW_WIDTH, WINDOW_HEIGHT);
    NSImage *image = nil;
    NSAttributedString *text = nil;
    NSString *string = nil;
    NSColor *color = nil;
    
    [self stopTimer];
    
    if ([[annotation type] isEqualToString:@"Link"]) {
        
        PDFDestination *dest = [annotation destination];
        PDFPage *page = [dest page];
        
        if (page) {
            
            NSRect bounds = [page boundsForBox:kPDFDisplayBoxCropBox];
            
            rect = contentRect;
            rect.origin = [dest point];
            rect.origin.x -= NSMinX(bounds);
            rect.origin.y -= NSMinY(bounds) + NSHeight(rect);
            
            PDFSelection *selection = [page selectionForRect:bounds];
            if ([selection string]) {
                NSRect selBounds = [selection boundsForPage:page];
                float top = fmax(NSMaxY(selBounds), NSMinX(selBounds) + NSHeight(rect));
                float left = fmin(NSMinX(selBounds), NSMaxX(bounds) - NSWidth(rect));
                if (top < NSMaxY(rect))
                    rect.origin.y = top - NSHeight(rect);
                if (left > NSMinX(rect))
                    rect.origin.x = left;
            }
            
            image = [[page image] retain];
            color = [NSColor controlBackgroundColor];
            
            if (NSMaxX(rect) > [image size].width)
                rect.origin.x = [image size].width - NSWidth(rect);
            if (NSMinX(rect) < 0.0)
                rect.origin.x = 0.0;
            if (NSMaxY(rect) > [image size].height)
                rect.origin.y = [image size].height - NSHeight(rect);
            if (NSMinY(rect) < 0.0)
                rect.origin.y = 0.0;
            
            NSDictionary *attrs = [[NSDictionary alloc] initWithObjectsAndKeys:labelFont, NSFontAttributeName, color, NSForegroundColorAttributeName, nil];
            NSAttributedString *labelString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Page %@", @"Tool tip label format"), [page label]] attributes:attrs];
            NSRect labelRect = [labelString boundingRectWithSize:NSZeroSize options:NSStringDrawingUsesLineFragmentOrigin];
            float labelOffset = (0.5 * NSHeight(labelRect)); // make sure the cap radius is integral
            
            labelRect.size.height = 2.0 * labelOffset;
            labelRect.origin.x = NSMaxX(rect) - NSWidth(labelRect) - labelOffset - TEXT_MARGIN_X;
            labelRect.origin.y = NSMinY(rect) + TEXT_MARGIN_Y;
            
            [image lockFocus];
            [NSGraphicsContext saveGraphicsState];
            [labelColor setFill];
            [NSBezierPath fillHorizontalOvalAroundRect:labelRect];
            [labelString drawWithRect:labelRect options:NSStringDrawingUsesLineFragmentOrigin];
            [NSGraphicsContext restoreGraphicsState];
            [image unlockFocus];
            
            [attrs release];
            [labelString release];
            
        } else {
            
            string = [[(PDFAnnotationLink *)annotation URL] absoluteString];
            
        }
        
    } else {
        
        text = [[annotation text] retain];
        
        if ([text length] == 0) {
            [text release];
            text = nil;
            if ([[annotation contents] length])
                string = [annotation contents];
        }
        
    }
    
    if (string) {
        NSDictionary *attrs = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, nil];
        text = [[NSAttributedString alloc] initWithString:string attributes:attrs];
        [attrs release];
    }
    
    if (text) {
        
        rect = [text boundingRectWithSize:NSInsetRect(contentRect, TEXT_MARGIN_X, TEXT_MARGIN_Y).size options:NSStringDrawingUsesLineFragmentOrigin];
        rect.size.width = contentRect.size.width = NSWidth(rect) + 2.0 * TEXT_MARGIN_X;
        rect.size.height = contentRect.size.height = fmin(NSHeight(rect) + 2.0 * TEXT_MARGIN_Y, NSHeight(contentRect));
        rect.origin = NSZeroPoint;
        
        image = [[NSImage alloc] initWithSize:rect.size];
        color = backgroundColor;
        
        [image lockFocus];
        [text drawWithRect:NSInsetRect(rect, TEXT_MARGIN_X, TEXT_MARGIN_Y) options:NSStringDrawingUsesLineFragmentOrigin];
        [image unlockFocus];
        
        [text release];
    }
    
    if (image) {
        
        [imageView setFrameSize:[image size]];
        [imageView setImage:image];
        [image release];
        
        contentRect.origin.y -= NSHeight(contentRect);
        [self setFrame:[self hoverWindowRectFittingScreenFromRect:contentRect] display:NO];
        [imageView scrollRectToVisible:rect];
        
        [[imageView enclosingScrollView] setBackgroundColor:color];
        
        [animation stopAnimation];
        if ([self isVisible] && [self alphaValue] > 0.9) {
            [self orderFront:self];
        } else {
            NSDictionary *fadeInDict = [[NSDictionary alloc] initWithObjectsAndKeys:self, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
            
            animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeInDict, nil]];
            [fadeInDict release];
            
            [self setAlphaValue:0.0];
            [super orderFront:self];
            
            [animation setAnimationBlockingMode:NSAnimationNonblocking];
            [animation setDuration:0.3];
            [animation setDelegate:self];
            [animation startAnimation];
        }
    } else {
        
        [self hide];
        
    }
}

- (void)showForAnnotation:(PDFAnnotation *)note atPoint:(NSPoint)aPoint {
    point = aPoint;
    
    if ([note isEqual:annotation] == NO) {
        [self stopTimer];
        
        if ([self isVisible] && [self alphaValue] > 0.9)
            [animation stopAnimation];
        
        [annotation release];
        annotation = [note retain];
        
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:[self isVisible] ? 0.1 : 1.5];
        timer = [[NSTimer alloc] initWithFireDate:date interval:0 target:self selector:@selector(timerFired:) userInfo:NULL repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}

- (void)hide {
    if (annotation == nil)
        return;
    
    [self stopTimer];
    [animation stopAnimation];
    
    [annotation release];
    annotation = nil;
    point = NSZeroPoint;
    
    NSDictionary *fadeOutDict = [[NSDictionary alloc] initWithObjectsAndKeys:self, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
    
    animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeOutDict, nil]];
    [fadeOutDict release];
    
    [animation setAnimationBlockingMode:NSAnimationNonblocking];
    [animation setDuration:1.0];
    [animation setDelegate:self];
    [animation startAnimation];
}

- (void)animationDidEnd:(NSAnimation*)anAnimation {
    BOOL isFadeOut = [[[[animation viewAnimations] lastObject] objectForKey:NSViewAnimationEffectKey] isEqual:NSViewAnimationFadeOutEffect];
    [animation release];
    animation = nil;
    if (isFadeOut)
        [self orderOut:self];
    [self setAlphaValue:ALPHA_VALUE];
}

- (void)animationDidStop:(NSAnimation*)anAnimation {
    [animation release];
    animation = nil;
}

@end
