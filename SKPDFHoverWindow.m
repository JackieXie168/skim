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
        
        NSScrollView *scrollView = [[NSScrollView alloc] init];
        imageView = [[NSImageView alloc] init];
        [imageView setImageFrameStyle:NSImageFrameNone];
        [scrollView setDocumentView:imageView];
        [self setContentView:scrollView];
        [scrollView release];
        [imageView release];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActiveNotification:) 
                                                     name:NSApplicationWillResignActiveNotification object:NSApp];
    }
    return self;
}

- (void)handleApplicationWillResignActiveNotification:(NSNotification *)notification {
    [self orderOut:self];
}

- (BOOL)canBecomeKeyWindow { return NO; }

- (BOOL)canBecomeMainWindow { return NO; }

- (void)orderFront:(id)sender {
    [animation stopAnimation];
    [self setAlphaValue:1.0];
    [super orderFront:sender];
}

- (void)orderOut:(id)sender {
    [animation stopAnimation];
    [self setAlphaValue:1.0];
    [annotation release];
    annotation = nil;
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
    
    return rect;
}

- (void)showForAnnotation:(PDFAnnotation *)note atPoint:(NSPoint)point fromView:(PDFView *)srcView{
    
    if ([note isEqual:annotation])
        return;
    
    BOOL wasHidden = annotation == nil;
    
    [annotation release];
    annotation = [note retain];
    
    NSRect rect, contentRect = [self hoverWindowRectFittingScreenFromRect:NSMakeRect(point.x, point.y + fmin(NSHeight([annotation bounds]) + 3.0, 16.0), 400.0, 80.0)];
    NSImage *image = nil;
    NSAttributedString *text = nil;
    NSColor *color = [NSColor controlBackgroundColor];
    
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
            
        } else {
            
            NSString *urlString = [[(PDFAnnotationLink *)annotation URL] absoluteString];
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:11.0], NSFontAttributeName, nil];
            
            text = [[[NSAttributedString alloc] initWithString:urlString attributes:attrs] autorelease];
            
        }
        
    } else {
        
        text = [annotation text];
        
    }
    
    if (text) {
        
        rect = NSInsetRect([text boundingRectWithSize:contentRect.size options:NSStringDrawingUsesLineFragmentOrigin], -2.0, 0.0);
        if (NSWidth(rect) < NSWidth(contentRect))
            contentRect.size.width = NSWidth(rect);
        if (NSHeight(rect) < NSHeight(contentRect))
            contentRect.size.height = NSHeight(rect);
        rect.size = contentRect.size;
        rect.origin = NSZeroPoint;
        
        image = [[NSImage alloc] initWithSize:rect.size];
        color = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.6 alpha:1.0];
        
        [image lockFocus];
        [text drawWithRect:NSInsetRect(rect, 2.0, 0.0) options:NSStringDrawingUsesLineFragmentOrigin];
        [image unlockFocus];
        
    }
    
    if (image) {
        
        [imageView setFrameSize:[image size]];
        [imageView setImage:image];
        [image release];
        
        // Convert to window and expand for the border
        [self setFrame:[self frameRectForContentRect:contentRect] display:NO];
        [imageView scrollRectToVisible:rect];
        
        [[imageView enclosingScrollView] setBackgroundColor:color];
        
        if ([self isVisible] == NO)
            [self setAlphaValue:0.0];
        [animation stopAnimation];
        [super orderFront:self];
        
        if (wasHidden) {
            NSDictionary *fadeInDict = [[NSDictionary alloc] initWithObjectsAndKeys:self, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
            
            animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:fadeInDict, nil]];
            [fadeInDict release];
            
            [animation setAnimationBlockingMode:NSAnimationNonblocking];
            [animation setDuration:0.5];
            [animation setDelegate:self];
            [animation startAnimation];
        }
        
    }
}

- (void)hide {
    if (annotation == nil)
        return;
    
    [animation stopAnimation];
    
    [annotation release];
    annotation = nil;
    
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
    [self setAlphaValue:1.0];
}

- (void)animationDidStop:(NSAnimation*)anAnimation {
    [animation release];
    animation = nil;
}

@end
