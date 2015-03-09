//
//  SKTransitionController.m
//  Skim
//
//  Created by Christiaan Hofman on 7/15/07.
/*
 This software is Copyright (c) 2007-2015
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
#import "NSView_SKExtensions.h"
#import <CoreFoundation/CoreFoundation.h>
#import <Quartz/Quartz.h>
#include <unistd.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

NSString *SKStyleNameKey = @"styleName";
NSString *SKDurationKey = @"duration";
NSString *SKShouldRestrictKey = @"shouldRestrict";

#define kCIInputBacksideImageKey @"inputBacksideImage"
#define kCIInputRectangleKey @"inputRectangle"

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

@protocol SKTransitionAnimationDelegate;

@interface SKTransitionAnimation : NSAnimation {
    CIFilter *filter;
}
@property (nonatomic, readonly) CIImage *currentImage;
- (id)initWithFilter:(CIFilter *)aFilter duration:(NSTimeInterval)duration;
- (id <SKTransitionAnimationDelegate>)delegate;
- (void)setDelegate:(id <SKTransitionAnimationDelegate>)newDelegate;
@end

@protocol SKTransitionAnimationDelegate <NSAnimationDelegate>
- (void)animationDidUpdate:(NSAnimation *)anAnimation;
@end

#pragma mark -

@interface NSOpenGLView (SKLionExtensions)
- (BOOL)wantsBestResolutionOpenGLSurface;
- (void)setWantsBestResolutionOpenGLSurface:(BOOL)flag;
@end

@interface SKTransitionView : NSOpenGLView <SKTransitionAnimationDelegate> {
    SKTransitionAnimation *animation;
    CIImage *image;
    CGFloat imageScale;
    CIContext *context;
    BOOL needsReshape;
}
@property (nonatomic, retain) SKTransitionAnimation *animation;
@property (nonatomic, retain) CIImage *image;
@property (nonatomic) CGFloat imageScale;
@property (nonatomic, readonly) CIImage *currentImage;
@end

#pragma mark -

@implementation SKTransitionController

@synthesize view, transitionStyle, duration, shouldRestrict, pageTransitions;
@dynamic hasTransition;

+ (NSArray *)transitionNames {
    static NSArray *transitionNames = nil;
    
    if (transitionNames == nil) {
        transitionNames = [NSArray arrayWithObjects:
            @"", 
            @"CoreGraphics SKFadeTransition", 
            @"CoreGraphics SKZoomTransition", 
            @"CoreGraphics SKRevealTransition", 
            @"CoreGraphics SKSlideTransition", 
            @"CoreGraphics SKWarpFadeTransition", 
            @"CoreGraphics SKSwapTransition", 
            @"CoreGraphics SKCubeTransition", 
            @"CoreGraphics SKWarpSwitchTransition", 
            @"CoreGraphics SKWarpFlipTransition", nil];
        // get all the transition filters
		[CIPlugIn loadAllPlugIns];
        transitionNames = [[transitionNames arrayByAddingObjectsFromArray:[CIFilter filterNamesInCategory:kCICategoryTransition]] copy];
    }
    
    return transitionNames;
}

+ (NSString *)nameForStyle:(SKAnimationTransitionStyle)style {
    if (style > SKNoTransition && style < [[self transitionNames] count])
        return [[self transitionNames] objectAtIndex:style];
    else
        return nil;
}

+ (SKAnimationTransitionStyle)styleForName:(NSString *)name {
    NSUInteger idx = [[self transitionNames] indexOfObject:name];
    return idx == NSNotFound ? SKNoTransition : idx;
}

+ (NSString *)localizedNameForStyle:(SKAnimationTransitionStyle)style {
    switch (style) {
        case SKNoTransition:         return NSLocalizedString(@"No Transition", @"Transition name");
        case SKFadeTransition:       return NSLocalizedString(@"Fade", @"Transition name");
        case SKZoomTransition:       return NSLocalizedString(@"Zoom", @"Transition name");
        case SKRevealTransition:     return NSLocalizedString(@"Reveal", @"Transition name");
        case SKSlideTransition:      return NSLocalizedString(@"Slide", @"Transition name");
        case SKWarpFadeTransition:   return NSLocalizedString(@"Warp Fade", @"Transition name");
        case SKSwapTransition:       return NSLocalizedString(@"Swap", @"Transition name");
        case SKCubeTransition:       return NSLocalizedString(@"Cube", @"Transition name");
        case SKWarpSwitchTransition: return NSLocalizedString(@"Warp Switch", @"Transition name");
        case SKWarpFlipTransition:   return NSLocalizedString(@"Flip", @"Transition name");
        default:                     return [CIFilter localizedNameForFilterName:[self nameForStyle:style]];
    };
}

- (id)initForView:(NSView *)aView {
    self = [super init];
    if (self) {
        view = aView; // don't retain as it may retain us
        
        transitionStyle = SKNoTransition;
        duration = 1.0;
        shouldRestrict = YES;
        currentTransitionStyle = SKNoTransition;
        currentDuration = 1.0;
        currentShouldRestrict = YES;
        currentForward = YES;
        
    }
    return self;
}

- (void)dealloc {
    view = nil;
    SKDESTROY(window);
    SKDESTROY(initialImage);
    SKDESTROY(filters);
    SKDESTROY(pageTransitions);
    [super dealloc];
}

- (BOOL)hasTransition {
    return transitionStyle != SKNoTransition || pageTransitions != nil;
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

// rect is in pixels
- (CIImage *)cropImage:(CIImage *)image toRect:(NSRect)rect {
    CIFilter *cropFilter = [self filterWithName:@"CICrop"];
    [cropFilter setValue:[CIVector vectorWithX:NSMinX(rect) Y:NSMinY(rect) Z:NSWidth(rect) W:NSHeight(rect)] forKey:kCIInputRectangleKey];
    [cropFilter setValue:image forKey:kCIInputImageKey];
    return [cropFilter valueForKey:kCIOutputImageKey];
}

// transform is in pixel dimensions
- (CIImage *)transformImage:(CIImage *)image usingTransform:(NSAffineTransform *)transform {
    CIFilter *transformFilter = [self filterWithName:@"CIAffineTransform"];
    [transformFilter setValue:transform forKey:kCIInputTransformKey];
    [transformFilter setValue:image forKey:kCIInputImageKey];
    return [transformFilter valueForKey:kCIOutputImageKey];
}

static inline NSRect scaleRect(NSRect rect, CGFloat scale) {
    return NSMakeRect(scale * NSMinX(rect), scale * NSMinY(rect), scale * NSWidth(rect), scale * NSHeight(rect));
}

// rect and bounds are in pixels
- (CIFilter *)transitionFilterForRect:(NSRect)rect bounds:(NSRect)bounds forward:(BOOL)forward initialCIImage:(CIImage *)initialCIImage finalCIImage:(CIImage *)finalCIImage {
    NSString *filterName = [[self class] nameForStyle:currentTransitionStyle];
    CIFilter *transitionFilter = [self filterWithName:filterName];
    
    for (NSString *key in [transitionFilter inputKeys]) {
        id value = nil;
        if ([key isEqualToString:kCIInputExtentKey]) {
            NSRect extent = currentShouldRestrict ? rect : bounds;
            value = [CIVector vectorWithX:NSMinX(extent) Y:NSMinY(extent) Z:NSWidth(extent) W:NSHeight(extent)];
        } else if ([key isEqualToString:kCIInputAngleKey]) {
            CGFloat angle = forward ? 0.0 : M_PI;
            if ([filterName isEqualToString:@"CIPageCurlTransition"])
                angle = forward ? -M_PI_4 : -3.0 * M_PI_4;
            value = [NSNumber numberWithDouble:angle];
        } else if ([key isEqualToString:kCIInputCenterKey]) {
            value = [CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)];
        } else if ([key isEqualToString:kCIInputImageKey]) {
            value = initialCIImage;
            if (NSEqualRects(rect, bounds) == NO)
                value = [self cropImage:value toRect:rect];
        } else if ([key isEqualToString:kCIInputTargetImageKey]) {
            value = finalCIImage;
            if (NSEqualRects(rect, bounds) == NO)
                value = [self cropImage:value toRect:rect];
        } else if ([key isEqualToString:kCIInputShadingImageKey]) {
            static CIImage *inputShadingImage = nil;
            if (inputShadingImage == nil)
                inputShadingImage = [[CIImage alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TransitionShading" withExtension:@"tiff"]];
            value = inputShadingImage;
        } else if ([key isEqualToString:kCIInputBacksideImageKey]) {
            value = initialCIImage;
            if (NSEqualRects(rect, bounds) == NO)
                value = [self cropImage:value toRect:rect];
        } else if ([[[[transitionFilter attributes] objectForKey:key] objectForKey:kCIAttributeClass] isEqualToString:@"CIImage"]) {
            // Scale and translate our mask image to match the transition area size.
            static CIImage *inputMaskImage = nil;
            if (inputMaskImage == nil)
                inputMaskImage = [[CIImage alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TransitionMask" withExtension:@"jpg"]];
            CGRect extent = [inputMaskImage extent];
            NSAffineTransform *transform = [NSAffineTransform transform];
            if ((CGRectGetWidth(extent) < CGRectGetHeight(extent)) != (NSWidth(rect) < NSHeight(rect))) {
                [transform setTransformStruct:(NSAffineTransformStruct){0.0, 1.0, 1.0, 0.0, 0.0, 0.0}];
                [transform translateXBy:NSMinY(rect) - NSMinY(bounds) yBy:NSMinX(rect) - NSMinX(bounds)];
                [transform scaleXBy:NSHeight(rect) / CGRectGetWidth(extent) yBy:NSWidth(rect) / CGRectGetHeight(extent)];
            } else {
                [transform translateXBy:NSMinX(rect) - NSMinX(bounds) yBy:NSMinY(rect) - NSMinY(bounds)];
                [transform scaleXBy:NSWidth(rect) / CGRectGetWidth(extent) yBy:NSHeight(rect) / CGRectGetHeight(extent)];
            }
            value = [self transformImage:inputMaskImage usingTransform:transform];
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

- (NSWindow *)window {
    if (window == nil) {
        window = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [window setReleasedWhenClosed:NO];
        [window setIgnoresMouseEvents:YES];
        [window setContentView:[[[SKTransitionView alloc] init] autorelease]];
    }
    return window;
}

- (SKTransitionView *)transitionView {
    return (SKTransitionView *)[[self window] contentView];
}

- (void)prepareAnimationForRect:(NSRect)rect from:(NSUInteger)fromIndex to:(NSUInteger)toIndex {
    currentTransitionStyle = transitionStyle;
    currentDuration = duration;
    currentShouldRestrict = shouldRestrict;
    currentForward = (toIndex >= fromIndex);
    
    NSUInteger idx = MIN(fromIndex, toIndex);
    if (fromIndex != NSNotFound && toIndex != NSNotFound && idx < [pageTransitions count]) {
        NSDictionary *info = [pageTransitions objectAtIndex:idx];
        id value;
        if ((value = [info objectForKey:SKStyleNameKey]))
            currentTransitionStyle = [[self class] styleForName:value];
        if ((value = [info objectForKey:SKDurationKey]) && [value respondsToSelector:@selector(doubleValue)])
            currentDuration = [value doubleValue];
        if ((value = [info objectForKey:SKShouldRestrictKey]) && [value respondsToSelector:@selector(boolValue)])
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
    didPrepare = YES;
}

- (void)animateCoreGraphicsForRect:(NSRect)rect {
    CIImage *finalImage = nil;
    
    if (currentShouldRestrict) {
        CGFloat imageScale = CGRectGetWidth([initialImage extent]) / NSWidth([view bounds]);
        
        NSRect bounds = [view bounds];
        imageRect = NSIntegralRect(NSIntersectionRect(NSUnionRect(imageRect, rect), bounds));
        
        finalImage = [self newCurrentImage];
        
        NSRect r = scaleRect(imageRect, imageScale);
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:imageScale * (NSMinX(bounds) - NSMinX(imageRect)) yBy:imageScale * (NSMinY(bounds) - NSMinY(imageRect))];
        initialImage = [self transformImage:[self cropImage:[initialImage autorelease] toRect:r] usingTransform:transform];
        finalImage = [self transformImage:[self cropImage:[finalImage autorelease] toRect:r] usingTransform:transform];
        
        NSRect frame = [view convertRect:imageRect toView:nil];
        frame.origin = [[view window] convertBaseToScreen:frame.origin];
        
        [[self transitionView] setImage:initialImage];
        [[self transitionView] setImageScale:imageScale];
        initialImage = nil;
        
        [[self window] setFrame:frame display:YES];
        [[self window] orderBack:nil];
        [[view window] addChildWindow:[self window] ordered:NSWindowAbove];
    }
    
    // declare our variables  
    int handle = -1;
    CGSTransitionSpec spec;
    // specify our specifications
    spec.unknown1 = 0;
    spec.type =  currentTransitionStyle;
    spec.option = currentForward ? CGSLeft : CGSRight;
    spec.backColour = NULL;
    spec.wid = [(currentShouldRestrict ? [self window] : [view window]) windowNumber];
    
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
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:currentDuration]];
    
    CGSReleaseTransition(cgs, handle);
    handle = 0;
    
    if (currentShouldRestrict) {
        [[view window] removeChildWindow:[self window]];
        [[self window] orderOut:nil];
        [[self transitionView] setImage:nil];
    }
}

- (void)animateCoreImageForRect:(NSRect)rect  {
    CGFloat imageScale = CGRectGetWidth([initialImage extent]) / NSWidth([view bounds]);
    
    NSRect bounds = [view bounds];
    imageRect = NSIntegralRect(NSIntersectionRect(NSUnionRect(imageRect, rect), bounds));
    
    CIImage *finalImage = [self newCurrentImage];
    
    CIFilter *transitionFilter = [self transitionFilterForRect:scaleRect(imageRect, imageScale) bounds:scaleRect(bounds, imageScale) forward:currentForward initialCIImage:initialImage finalCIImage:finalImage];
    
    [finalImage release];
    [initialImage release];
    initialImage = nil;
    
    NSRect frame = [view convertRect:[view frame] toView:nil];
    frame.origin = [[view window] convertBaseToScreen:frame.origin];
    
    SKTransitionAnimation *animation = [[SKTransitionAnimation alloc] initWithFilter:transitionFilter duration:currentDuration];
    [[self transitionView] setAnimation:animation];
    [[self transitionView] setImageScale:imageScale];
    [animation release];
    
    [[self window] setFrame:frame display:NO];
    [[self window] orderBack:nil];
    [[view window] addChildWindow:[self window] ordered:NSWindowAbove];
    
    [animation startAnimation];
    
    // Update the view and its window, so it shows the correct state when it is shown.
    [view display];
    // Remember we disabled flushing in the previous method, we need to balance that.
    [[view window] enableFlushWindow];
    [[view window] flushWindow];
    
    [[view window] removeChildWindow:[self window]];
    [[self window] orderOut:nil];
    [[self transitionView] setAnimation:nil];
}

- (void)animateForRect:(NSRect)rect  {
    if (didPrepare == NO)
        [self prepareAnimationForRect:rect from:NSNotFound to:NSNotFound];
	
    if (currentTransitionStyle >= SKCoreImageTransition)
        [self animateCoreImageForRect:rect];
	else if (currentTransitionStyle > SKNoTransition && CoreGraphicsServicesTransitionsDefined())
        [self animateCoreGraphicsForRect:rect];
    
    currentTransitionStyle = transitionStyle;
    currentDuration = duration;
    currentShouldRestrict = shouldRestrict;
    currentForward = YES;
    
    didPrepare = NO;
}

@end

#pragma mark -

@implementation SKTransitionAnimation

@dynamic currentImage;

- (id)initWithFilter:(CIFilter *)aFilter duration:(NSTimeInterval)duration {
    self = [super initWithDuration:duration animationCurve:NSAnimationEaseInOut];
    if (self) {
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
    [filter setValue:[NSNumber numberWithDouble:[self currentValue]] forKey:kCIInputTimeKey];
    [[self delegate] animationDidUpdate:self];
}

- (CIImage *)currentImage {
    return [filter valueForKey:kCIOutputImageKey];
}

- (id <SKTransitionAnimationDelegate>)delegate { return (id <SKTransitionAnimationDelegate>)[super delegate]; }
- (void)setDelegate:(id <SKTransitionAnimationDelegate>)newDelegate { [super setDelegate:newDelegate]; }

@end

#pragma mark -

@implementation SKTransitionView

@synthesize animation, image, imageScale;
@dynamic currentImage;

+ (NSOpenGLPixelFormat *)defaultPixelFormat {
    static NSOpenGLPixelFormat *pf;

    if (pf == nil) {
        NSOpenGLPixelFormatAttribute attr[] = {
            NSOpenGLPFAAccelerated,
            NSOpenGLPFANoRecovery,
            NSOpenGLPFAColorSize,
            32,
            0
        };
        
        pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
    }

    return pf;
}

- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format {
    self = [super initWithFrame:frameRect pixelFormat:format];
    if (self) {
        imageScale = 1.0;
        if ([self respondsToSelector:@selector(setWantsBestResolutionOpenGLSurface:)])
            [self setWantsBestResolutionOpenGLSurface:YES];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        imageScale = 1.0;
        if ([self respondsToSelector:@selector(setWantsBestResolutionOpenGLSurface:)])
            [self setWantsBestResolutionOpenGLSurface:YES];
    }
    return self;
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

- (void)setAnimation:(SKTransitionAnimation *)newAnimation {
    if (animation != newAnimation) {
        [animation release];
        animation = [newAnimation retain];
        [animation setDelegate:self];
        [self setNeedsDisplay:YES];
    }
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
        
        context = [[CIContext contextWithCGLContext:CGLGetCurrentContext() pixelFormat:[pf CGLPixelFormatObj] colorSpace:nil options:nil] retain];
    }
    return context;
}

- (void)updateMatrices {
    NSRect bounds = [self bounds];
    CGFloat scale = ([self respondsToSelector:@selector(wantsBestResolutionOpenGLSurface)] && [self wantsBestResolutionOpenGLSurface]) ? [self backingScale] : 1.0;
    
    [[self openGLContext] update];
    
    glViewport(0, 0, scale * NSWidth(bounds), scale * NSHeight(bounds));

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(NSMinX(bounds), scale * NSMaxX(bounds), scale * NSMinY(bounds), scale * NSMaxY(bounds), -1, 1);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    needsReshape = NO;
}

- (void)drawRect:(NSRect)rect {
    CGFloat scale = ([self respondsToSelector:@selector(wantsBestResolutionOpenGLSurface)] && [self wantsBestResolutionOpenGLSurface]) ? [self backingScale] : 1.0;
    
    [[self openGLContext] makeCurrentContext];
    
    if (needsReshape)
        [self updateMatrices];
    
    glColor4f(0.0f, 0.0f, 0.0f, 0.0f);
    glBegin(GL_POLYGON);
        glVertex2f(scale * NSMinX(rect), scale * NSMinY(rect));
        glVertex2f(scale * NSMaxX(rect), scale * NSMinY(rect));
        glVertex2f(scale * NSMaxX(rect), scale * NSMaxY(rect));
        glVertex2f(scale * NSMinX(rect), scale * NSMaxY(rect));
    glEnd();
    
    CIImage *currentImage = [self currentImage];
    if (currentImage) {
        NSRect bounds = [self bounds];
        [[self ciContext] drawImage:currentImage inRect:scaleRect(NSRectToCGRect(bounds), scale) fromRect:scaleRect(NSRectToCGRect(bounds), imageScale)];
    }
    
    glFlush();
}

@end
