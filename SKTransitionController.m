//
//  SKTransitionController.m
//  Skim
//
//  Created by Christiaan Hofman on 7/15/07.
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
 
/*
 This code is based partly on Apple's AnimatingTabView example code
 and Ankur Kothari's AnimatingTabsDemo application <http://dev.lipidity.com>
*/

#import "SKTransitionController.h"
#import "NSBitmapImageRep_SKExtensions.h"
#import <CoreFoundation/CoreFoundation.h>
#import <Quartz/Quartz.h>
#include <unistd.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

#define WEAK_NULL NULL

#pragma mark Private Core Graphics types and functions

typedef int CGSConnection;
typedef int CGSWindow;

typedef enum _CGSTransitionType {
    CGSNone,
    CGSFade,
    CGSZoom,
    CGSReveal,
    CGSSlide,
    CGSWarpFade,
    CGSSwap,
    CGSCube,
    CGSWarpSwitch,
    CGSFlip
} CGSTransitionType;

typedef enum _CGSTransitionOption {
    CGSDown,
    CGSLeft,
    CGSRight,
    CGSInRight,
    CGSBottomLeft = 5,
    CGSBottomRight,
    CGSDownTopRight,
    CGSUp,
    CGSTopLeft,
    CGSTopRight,
    CGSUpBottomRight,
    CGSInBottom,
    CGSLeftBottomRight,
    CGSRightBottomLeft,
    CGSInBottomRight,
    CGSInOut
} CGSTransitionOption;

typedef struct _CGSTransitionSpec {
    uint32_t unknown1;
    CGSTransitionType type;
    CGSTransitionOption option;
    CGSWindow wid; // Can be 0 for full-screen
    float *backColour; // Null for black otherwise pointer to 3 CGFloat array with RGB value
} CGSTransitionSpec;

extern CGSConnection _CGSDefaultConnection(void) __attribute__((weak_import));

extern OSStatus CGSNewTransition(const CGSConnection cid, const CGSTransitionSpec* spec, int *pTransitionHandle) __attribute__((weak_import));
extern OSStatus CGSInvokeTransition(const CGSConnection cid, int transitionHandle, float duration) __attribute__((weak_import));
extern OSStatus CGSReleaseTransition(const CGSConnection cid, int transitionHandle) __attribute__((weak_import));

#pragma mark Check whether the above functions are actually defined at run time

static BOOL CoreGraphicsServicesTransitionsDefined() {
    return _CGSDefaultConnection != WEAK_NULL &&
           CGSNewTransition != WEAK_NULL &&
           CGSInvokeTransition != WEAK_NULL &&
           CGSReleaseTransition != WEAK_NULL;
}

#pragma mark -

@protocol SKTransitionAnimationDelegate <NSAnimationDelegate>
- (void)animationDidUpdate:(NSAnimation *)anAnimation;
@end

@interface SKTransitionAnimation : NSAnimation {
    CIFilter *filter;
}
- (id)initWithFilter:(CIFilter *)aFilter duration:(NSTimeInterval)duration;
- (CIImage *)currentImage;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
- (id <SKTransitionAnimationDelegate>)delegate;
- (void)setDelegate:(id <SKTransitionAnimationDelegate>)newDelegate;
#endif
@end

#pragma mark -

@interface SKTransitionView : NSOpenGLView <SKTransitionAnimationDelegate> {
    SKTransitionAnimation *animation;
    CIImage *image;
    CIContext *context;
    BOOL needsReshape;
}
- (SKTransitionAnimation *)animation;
- (void)setAnimation:(SKTransitionAnimation *)newAnimation;
- (CIImage *)image;
- (void)setImage:(CIImage *)newImage;
- (CIImage *)currentImage;
@end

#pragma mark -

@implementation SKTransitionController

+ (NSArray *)transitionFilterNames {
    static NSArray *transitionFilterNames = nil;
    
    if (transitionFilterNames == nil) {
        // get all the transition filters
		[CIPlugIn loadAllPlugIns];
        transitionFilterNames = [[CIFilter filterNamesInCategories:[NSArray arrayWithObject:kCICategoryTransition]] copy];
    }
    
    return transitionFilterNames;
}

+ (NSArray *)transitionNames {
    static NSArray *transitionNames = nil;
    
    if (transitionNames == nil) {
        transitionNames = [NSArray arrayWithObjects:
            @"CoreGraphics SKFadeTransition", 
            @"CoreGraphics SKZoomTransition", 
            @"CoreGraphics SKRevealTransition", 
            @"CoreGraphics SKSlideTransition", 
            @"CoreGraphics SKWarpFadeTransition", 
            @"CoreGraphics SKSwapTransition", 
            @"CoreGraphics SKCubeTransition", 
            @"CoreGraphics SKWarpSwitchTransition", 
            @"CoreGraphics SKWarpFlipTransition", nil];
        transitionNames = [[transitionNames arrayByAddingObjectsFromArray:[self transitionFilterNames]] copy];
    }
    
    return transitionNames;
}

+ (NSString *)nameForStyle:(SKAnimationTransitionStyle)style {
    if (style > SKNoTransition && style <= [[self transitionNames] count])
        return [[self transitionNames] objectAtIndex:style - 1];
    else
        return nil;
}

+ (SKAnimationTransitionStyle)styleForName:(NSString *)name {
    NSUInteger idx = [[self transitionNames] indexOfObject:name];
    return idx == NSNotFound ? SKNoTransition : idx + 1;
}

- (id)initWithView:(NSView *)aView {
    if (self = [super init]) {
        view = aView; // don't retain as it may retain us
        
        transitionStyle = SKNoTransition;
        duration = 1.0;
        shouldRestrict = YES;
        currentTransitionStyle = SKNoTransition;
        currentDuration = 1.0;
        currentShouldRestrict = YES;
        
        transitionWindow = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [transitionWindow setReleasedWhenClosed:NO];
        [transitionWindow setIgnoresMouseEvents:YES];
        [transitionWindow setContentView:[[[SKTransitionView alloc] init] autorelease]];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(transitionWindow);
    SKDESTROY(initialImage);
    SKDESTROY(filters);
    [super dealloc];
}

- (NSView *)view {
    return view;
}

- (void)setView:(NSView *)newView {
    if (view != newView) {
        view = newView;
    }
}

- (SKAnimationTransitionStyle)transitionStyle {
    return transitionStyle;
}

- (void)setTransitionStyle:(SKAnimationTransitionStyle)style {
    if (transitionStyle != style) {
        transitionStyle = style;
    }
}

- (CGFloat)duration {
    return duration;
}

- (void)setDuration:(CGFloat)newDuration {
    duration = newDuration;
}

- (BOOL)shouldRestrict {
    return shouldRestrict;
}

- (void)setShouldRestrict:(BOOL)flag {
    shouldRestrict = flag;
}

- (NSArray *)pageTransitions {
    return pageTransitions;
}

- (void)setPageTransitions:(NSArray *)newPageTransitions {
    if (pageTransitions != newPageTransitions) {
        [pageTransitions release];
        pageTransitions = [newPageTransitions copy];
    }
}

- (CIFilter *)filterWithName:(NSString *)name {
    if (filters == nil)
        filters = [[NSMutableDictionary alloc] init];
    CIFilter *filter = [filters objectForKey:name];
    if (filter == nil && (filter = [CIFilter filterWithName:name]))
        [filters setObject:filter forKey:name];
    [filter setDefaults];
    return filter;
}

- (CIImage *)inputShadingImage {
    static CIImage *inputShadingImage = nil;
    if (inputShadingImage == nil) {
        NSData *shadingBitmapData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TransitionShading" ofType:@"tiff"]];
        NSBitmapImageRep *shadingBitmap = [[[NSBitmapImageRep alloc] initWithData:shadingBitmapData] autorelease];
        inputShadingImage = [[CIImage alloc] initWithBitmapImageRep:shadingBitmap];
    }
    return inputShadingImage;
}

- (CIImage *)inputMaskImage {
    static CIImage *inputMaskImage = nil;
    if (inputMaskImage == nil) {
        NSData *maskBitmapData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TransitionMask" ofType:@"jpg"]];
        NSBitmapImageRep *maskBitmap = [[[NSBitmapImageRep alloc] initWithData:maskBitmapData] autorelease];
        inputMaskImage = [[CIImage alloc] initWithBitmapImageRep:maskBitmap];
    }
    return inputMaskImage;
}

- (CIImage *)cropImage:(CIImage *)image toRect:(NSRect)rect {
    CIFilter *cropFilter = [self filterWithName:@"CICrop"];
    [cropFilter setValue:[CIVector vectorWithX:NSMinX(rect) Y:NSMinY(rect) Z:NSWidth(rect) W:NSHeight(rect)] forKey:@"inputRectangle"];
    [cropFilter setValue:image forKey:@"inputImage"];
    return [cropFilter valueForKey:@"outputImage"];
}

- (CIImage *)translateImage:(CIImage *)image xBy:(CGFloat)dx yBy:(CGFloat)dy {
    CIFilter *translationFilter = [self filterWithName:@"CIAffineTransform"];
    NSAffineTransform *affineTransform = [NSAffineTransform transform];
    [affineTransform translateXBy:dx yBy:dy];
    [translationFilter setValue:affineTransform forKey:@"inputTransform"];
    [translationFilter setValue:image forKey:@"inputImage"];
    return [translationFilter valueForKey:@"outputImage"];
}

- (CIImage *)scaleImage:(CIImage *)image toSize:(NSSize)size {
    CIFilter *scalingFilter = [self filterWithName:@"CILanczosScaleTransform"];
    CGRect extent = [image extent];
    CGFloat xScale = size.width / CGRectGetWidth(extent);
    CGFloat yScale = size.height / CGRectGetHeight(extent);
    [scalingFilter setValue:[NSNumber numberWithDouble:yScale] forKey:@"inputScale"];
    [scalingFilter setValue:[NSNumber numberWithDouble:xScale / yScale] forKey:@"inputAspectRatio"];
    [scalingFilter setValue:image forKey:@"inputImage"];
    return [scalingFilter valueForKey:@"outputImage"];
}

- (CIFilter *)transitionFilterForRect:(NSRect)rect forward:(BOOL)forward initialCIImage:(CIImage *)initialCIImage finalCIImage:(CIImage *)finalCIImage {
    NSString *filterName = [[[self class] transitionFilterNames] objectAtIndex:currentTransitionStyle - SKCoreImageTransition];
    CIFilter *transitionFilter = [self filterWithName:filterName];
    
    NSRect bounds = [view bounds];
    
    for (NSString *key in [transitionFilter inputKeys]) {
        id value = nil;
        if ([key isEqualToString:@"inputExtent"]) {
            NSRect extent = currentShouldRestrict ? rect : bounds;
            value = [CIVector vectorWithX:NSMinX(extent) Y:NSMinY(extent) Z:NSWidth(extent) W:NSHeight(extent)];
        } else if ([key isEqualToString:@"inputAngle"]) {
            CGFloat angle = forward ? 0.0 : M_PI;
            if ([filterName isEqualToString:@"CIPageCurlTransition"])
                angle = forward ? -M_PI_4 : -3.0 * M_PI_4;
            value = [NSNumber numberWithDouble:angle];
        } else if ([key isEqualToString:@"inputCenter"]) {
            value = [CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)];
        } else if ([key isEqualToString:@"inputImage"]) {
            value = initialCIImage;
            if (NSEqualRects(rect, bounds) == NO)
                value = [self cropImage:value toRect:rect];
        } else if ([key isEqualToString:@"inputTargetImage"]) {
            value = finalCIImage;
            if (NSEqualRects(rect, bounds) == NO)
                value = [self cropImage:value toRect:rect];
        } else if ([key isEqualToString:@"inputShadingImage"]) {
            value = [self inputShadingImage];
        } else if ([key isEqualToString:@"inputBacksideImage"]) {
            value = initialCIImage;
            if (NSEqualRects(rect, bounds) == NO)
                value = [self cropImage:value toRect:rect];
        } else if ([[[[transitionFilter attributes] objectForKey:key] objectForKey:kCIAttributeClass] isEqualToString:@"CIImage"]) {
            // Scale and translate our mask image to match the transition area size.
            value = [self scaleImage:[self inputMaskImage] toSize:rect.size];
            if (NSEqualPoints(rect.origin, bounds.origin) == NO)
                value = [self translateImage:value xBy:NSMinX(rect) - NSMinX(bounds) yBy:NSMinY(rect) - NSMinY(bounds)];
        } else continue;
        [transitionFilter setValue:value forKey:key];
    }
    
    return transitionFilter;
}

- (CIImage *)newCurrentImage {
    NSRect bounds = [view bounds];
    NSBitmapImageRep *contentBitmap = [view bitmapImageRepForCachingDisplayInRect:bounds];
    
    [contentBitmap clear];
    [view cacheDisplayInRect:bounds toBitmapImageRep:contentBitmap];
    
    return [[CIImage alloc] initWithBitmapImageRep:contentBitmap];
}

- (NSWindow *)transitionWindow {
    return transitionWindow;
}

- (SKTransitionView *)transitionView {
    return (SKTransitionView *)[transitionWindow contentView];
}

- (void)prepareAnimationForRect:(NSRect)rect {
    [self prepareAnimationForRect:rect from:NSNotFound to:NSNotFound];
}

- (void)prepareAnimationForRect:(NSRect)rect from:(NSUInteger)fromIndex to:(NSUInteger)toIndex {
    currentTransitionStyle = transitionStyle;
    currentDuration = duration;
    currentShouldRestrict = shouldRestrict;
    
    NSUInteger idx = MIN(fromIndex, toIndex);
    if (fromIndex != NSNotFound && toIndex != NSNotFound && idx < [pageTransitions count]) {
        NSDictionary *info = [pageTransitions objectAtIndex:idx];
        id value;
        if (value = [info objectForKey:@"styleName"])
            currentTransitionStyle = [[self class] styleForName:value];
        if ((value = [info objectForKey:@"duration"]) && [value respondsToSelector:@selector(doubleValue)])
            currentDuration = [value doubleValue];
        if ((value = [info objectForKey:@"shouldRestrict"]) && [value respondsToSelector:@selector(boolValue)])
            currentShouldRestrict = [value boolValue];
    }
    
	if (currentTransitionStyle >= SKCoreImageTransition) {
        [initialImage release];
        initialImage = [self newCurrentImage];
        // We don't want the window to draw the next state before the animation is run
        [[view window] disableFlushWindow];
    } else if (currentTransitionStyle > SKNoTransition && CoreGraphicsServicesTransitionsDefined()) {
        if (currentShouldRestrict) {
            [initialImage release];
            initialImage = [self newCurrentImage];
        }
        // We don't want the window to draw the next state before the animation is run
        [[view window] disableFlushWindow];
    }
    imageRect = rect;
}

- (void)animateCoreGraphicsForRect:(NSRect)rect forward:(BOOL)forward {
    CIImage *finalImage = nil;
    
    if (currentShouldRestrict) {
        if (initialImage == nil)
            [self prepareAnimationForRect:rect];
        
        NSRect bounds = [view bounds];
        imageRect = NSIntegralRect(NSIntersectionRect(NSUnionRect(imageRect, rect), bounds));
        
        finalImage = [self newCurrentImage];
        
        CGFloat dx = NSMinX(bounds) - NSMinX(imageRect);
        CGFloat dy = NSMinY(bounds) - NSMinY(imageRect);
        initialImage = [self translateImage:[self cropImage:[initialImage autorelease] toRect:rect] xBy:dx yBy:dy];
        finalImage = [self translateImage:[self cropImage:[finalImage autorelease] toRect:rect] xBy:dx yBy:dy];
        
        NSRect frame = [view convertRect:imageRect toView:nil];
        frame.origin = [[view window] convertBaseToScreen:frame.origin];
        
        [[self transitionView] setImage:initialImage];
        initialImage = nil;
        
        [[self transitionWindow] setFrame:frame display:YES];
        [[self transitionWindow] orderBack:nil];
        [[view window] addChildWindow:[self transitionWindow] ordered:NSWindowAbove];
    }
    
    // declare our variables  
    int handle = -1;
    CGSTransitionSpec spec;
    // specify our specifications
    spec.unknown1 = 0;
    spec.type =  currentTransitionStyle;
    spec.option = forward ? CGSLeft : CGSRight;
    spec.backColour = NULL;
    spec.wid = [(currentShouldRestrict ? [self transitionWindow] : [view window]) windowNumber];
    
    // Let's get a connection
    CGSConnection cgs = _CGSDefaultConnection();
    
    // Create a transition
    CGSNewTransition(cgs, &spec, &handle);
    
    if (currentShouldRestrict) {
        [[self transitionView] setImage:finalImage];
        [[self transitionView] display];
    }
    
    // Redraw the window
    [[view window] display];
    // Remember we disabled flushing in the previous method, we need to balance that.
    [[view window] enableFlushWindow];
    [[view window] flushWindow];
    
    CGSInvokeTransition(cgs, handle, currentDuration);
    // We need to wait for the transition to finish before we get rid of it, otherwise we'll get all sorts of nasty errors... or maybe not.
    usleep((useconds_t)(currentDuration * 1000000));
    
    CGSReleaseTransition(cgs, handle);
    handle = 0;
    
    if (currentShouldRestrict) {
        [[view window] removeChildWindow:[self transitionWindow]];
        [[self transitionWindow] orderOut:nil];
        [[self transitionView] setImage:nil];
    }
}

- (void)animateCoreImageForRect:(NSRect)rect forward:(BOOL)forward {
    if (initialImage == nil)
        [self prepareAnimationForRect:rect];
    
    NSRect bounds = [view bounds];
    imageRect = NSIntegralRect(NSIntersectionRect(NSUnionRect(imageRect, rect), bounds));
    
    CIImage *finalImage = [self newCurrentImage];
    
    CIFilter *transitionFilter = [self transitionFilterForRect:imageRect forward:forward initialCIImage:initialImage finalCIImage:finalImage];
    
    [finalImage release];
    [initialImage release];
    initialImage = nil;
    
    NSRect frame = [view convertRect:[view frame] toView:nil];
    frame.origin = [[view window] convertBaseToScreen:frame.origin];
    
    SKTransitionAnimation *animation = [[SKTransitionAnimation alloc] initWithFilter:transitionFilter duration:currentDuration];
    [[self transitionView] setAnimation:animation];
    [animation release];
    
    [[self transitionWindow] setFrame:frame display:NO];
    [[self transitionWindow] orderBack:nil];
    [[view window] addChildWindow:[self transitionWindow] ordered:NSWindowAbove];
    
    [animation startAnimation];
    
    // Update the view and its window, so it shows the correct state when it is shown.
    [view display];
    // Remember we disabled flushing in the previous method, we need to balance that.
    [[view window] enableFlushWindow];
    [[view window] flushWindow];
    
    [[view window] removeChildWindow:[self transitionWindow]];
    [[self transitionWindow] orderOut:nil];
    [[self transitionView] setAnimation:nil];
}

- (void)animateForRect:(NSRect)rect forward:(BOOL)forward {
	if (currentTransitionStyle >= SKCoreImageTransition)
        [self animateCoreImageForRect:rect forward:forward];
	else if (currentTransitionStyle > SKNoTransition && CoreGraphicsServicesTransitionsDefined())
        [self animateCoreGraphicsForRect:rect forward:forward];
    
    currentTransitionStyle = transitionStyle;
    currentDuration = duration;
    currentShouldRestrict = shouldRestrict;
}

@end

#pragma mark -

@implementation SKTransitionAnimation

- (id)initWithFilter:(CIFilter *)aFilter duration:(NSTimeInterval)duration {
    if (self = [super initWithDuration:duration animationCurve:NSAnimationEaseInOut]) {
        filter = [aFilter retain];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(filter);
    [super dealloc];
}

- (void)setCurrentProgress:(NSAnimationProgress)progress {
    [super setCurrentProgress:progress];
    [filter setValue:[NSNumber numberWithDouble:[self currentValue]] forKey:@"inputTime"];
    [[self delegate] animationDidUpdate:self];
}

- (CIImage *)currentImage {
    return [filter valueForKey:@"outputImage"];
}

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
- (id <SKTransitionAnimationDelegate>)delegate {
    return (id <SKTransitionAnimationDelegate>)[super delegate];
}

- (void)setDelegate:(id <SKTransitionAnimationDelegate>)newDelegate {
    [super setDelegate:newDelegate];
}
#endif

@end

#pragma mark -

@implementation SKTransitionView

+ (NSOpenGLPixelFormat *)defaultPixelFormat {
    static NSOpenGLPixelFormat *pf;

    if (pf == nil) {
        NSOpenGLPixelFormatAttribute attr[] = {
            NSOpenGLPFAAccelerated,
            NSOpenGLPFANoRecovery,
            NSOpenGLPFAColorSize, 32,
            0
        };
        
        pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
    }

    return pf;
}

- (void)dealloc {
    SKDESTROY(animation);
    SKDESTROY(context);
    [super dealloc];
}

- (void)reshape	{
    needsReshape = YES;
}

- (void)prepareOpenGL {
    // Enable beam-synced updates.
    GLint parm = 1;
    [[self openGLContext] setValues:&parm forParameter:NSOpenGLCPSwapInterval];
    
    // Make sure that everything we don't need is disabled.
    // Some of these are enabled by default and can slow down rendering.
    
    glDisable(GL_ALPHA_TEST);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_SCISSOR_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_DITHER);
    glDisable(GL_CULL_FACE);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glDepthMask(GL_FALSE);
    glStencilMask(0);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glHint(GL_TRANSFORM_HINT_APPLE, GL_FASTEST);
    
    needsReshape = YES;
}

- (void)animationDidUpdate:(NSAnimation *)anAnimation {
    [self display];
}

- (SKTransitionAnimation *)animation {
    return animation;
}

- (void)setAnimation:(SKTransitionAnimation *)newAnimation {
    if (animation != newAnimation) {
        [animation release];
        animation = [newAnimation retain];
        [animation setDelegate:self];
        [self setNeedsDisplay:YES];
    }
}

- (CIImage *)image {
    return image;
}

- (void)setImage:(CIImage *)newImage {
    if (image != newImage) {
        [image release];
        image = [newImage retain];
        [self setNeedsDisplay:YES];
    }
}

- (CIImage *)currentImage {
    return image ?: [animation currentImage];
}

- (CIContext *)ciContext {
    if (context == nil) {
        [[self openGLContext] makeCurrentContext];
        
        NSOpenGLPixelFormat *pf = [self pixelFormat] ?: [[self class] defaultPixelFormat];
        
        context = [[CIContext contextWithCGLContext:CGLGetCurrentContext() pixelFormat:[pf CGLPixelFormatObj] options:nil] retain];
    }
    return context;
}

- (void)updateMatrices {
    NSRect bounds = [self bounds];
    
    [[self openGLContext] update];
    
    glViewport(0, 0, NSWidth(bounds), NSHeight(bounds));

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(NSMinX(bounds), NSMaxX(bounds), NSMinY(bounds), NSMaxY(bounds), -1, 1);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    needsReshape = NO;
}

- (void)drawRect:(NSRect)rect {
    
    [[self openGLContext] makeCurrentContext];
    
    if (needsReshape)
        [self updateMatrices];
    
    glColor4f(0.0f, 0.0f, 0.0f, 0.0f);
    glBegin(GL_POLYGON);
        glVertex2f(NSMinX(rect), NSMinY(rect));
        glVertex2f(NSMaxX(rect), NSMinY(rect));
        glVertex2f(NSMaxX(rect), NSMaxY(rect));
        glVertex2f(NSMinX(rect), NSMaxY(rect));
    glEnd();
    
    CIImage *currentImage = [self currentImage];
    if (currentImage) {
        NSRect bounds = [self bounds];
        [[self ciContext] drawImage:currentImage inRect:NSRectToCGRect(bounds) fromRect:NSRectToCGRect(bounds)];
    }
    
    glFlush();
}

@end
