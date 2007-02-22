//
//  SKPDFHoverWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKPDFHoverWindow.h"
#import "PDFPage_SKExtensions.h"


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
    }
    return self;
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
    [destination release];
    destination = nil;
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

- (void)showWithDestination:(PDFDestination *)dest atPoint:(NSPoint)point fromView:(PDFView *)srcView{
    
    if ([destination isEqual:dest])
        return;
    
    BOOL wasHidden = destination == nil;
    
    [destination release];
    destination = [dest retain];
    
    // FIXME: magic number 15 ought to be calculated from the line height of the current line?
    NSRect contentRect = [self hoverWindowRectFittingScreenFromRect:NSMakeRect(point.x, point.y + 15.0, 400.0, 50.0)];
    PDFPage *page = [destination page];
    NSImage *image = [page image];
    NSRect bounds = [page boundsForBox:kPDFDisplayBoxCropBox];
    NSRect rect = [[imageView superview] bounds];
    
    rect.origin = [destination point];
    rect.origin.x -= NSMinX(bounds);
    rect.origin.y -= NSMinY(bounds) + NSHeight(rect);
    
    [imageView setFrameSize:[image size]];
    [imageView setImage:image];
    
    [self setFrame:[self frameRectForContentRect:contentRect] display:NO];
    [imageView scrollRectToVisible:rect];
    
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

- (void)hide {
    if (destination == nil)
        return;
    
    [animation stopAnimation];
    
    [destination release];
    destination = nil;
    
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
