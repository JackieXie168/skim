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

typedef void(^SKTransitionAnimationProgressHandler)(CGFloat);

@interface SKTransitionAnimation : NSAnimation {
    SKTransitionAnimationProgressHandler progressHandler;
}
@property (nonatomic, copy) SKTransitionAnimationProgressHandler progressHandler;
@end

#pragma mark -

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_6
@interface NSOpenGLView (SKLionDeclarations)
- (BOOL)wantsBestResolutionOpenGLSurface;
- (void)setWantsBestResolutionOpenGLSurface:(BOOL)flag;
@end
#endif

@interface SKTransitionView : NSOpenGLView {
    CIImage *image;
    CGFloat imageScale;
    CIContext *context;
    BOOL needsReshape;
}
@property (nonatomic, retain) CIImage *image;
@property (nonatomic) CGFloat imageScale;
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
        imageRect = NSZeroRect;
        
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

static inline CGRect scaleRect(NSRect rect, CGFloat scale) {
    return CGRectMake(scale * NSMinX(rect), scale * NSMinY(rect), scale * NSWidth(rect), scale * NSHeight(rect));
}

// rect and bounds are in pixels
- (CIFilter *)transitionFilterForRect:(CGRect)rect bounds:(CGRect)bounds forward:(BOOL)forward initialCIImage:(CIImage *)initialCIImage finalCIImage:(CIImage *)finalCIImage {
    NSString *filterName = [[self class] nameForStyle:currentTransitionStyle];
    CIFilter *transitionFilter = [filters objectForKey:filterName];
    if (transitionFilter == nil && (transitionFilter = [CIFilter filterWithName:filterName])) {
        if (filters == nil)
            filters = [[NSMutableDictionary alloc] init];
        [filters setObject:transitionFilter forKey:filterName];
    }
    [transitionFilter setDefaults];
    
    for (NSString *key in [transitionFilter inputKeys]) {
        id value = nil;
        if ([key isEqualToString:kCIInputExtentKey]) {
            CGRect extent = currentShouldRestrict ? rect : bounds;
            value = [CIVector vectorWithX:CGRectGetMinX(extent) Y:CGRectGetMinY(extent) Z:CGRectGetWidth(extent) W:CGRectGetHeight(extent)];
        } else if ([key isEqualToString:kCIInputAngleKey]) {
            CGFloat angle = forward ? 0.0 : M_PI;
            if ([filterName isEqualToString:@"CIPageCurlTransition"])
                angle = forward ? -M_PI_4 : -3.0 * M_PI_4;
            value = [NSNumber numberWithDouble:angle];
        } else if ([key isEqualToString:kCIInputCenterKey]) {
            value = [CIVector vectorWithX:CGRectGetMidX(rect) Y:CGRectGetMidY(rect)];
        } else if ([key isEqualToString:kCIInputImageKey]) {
            value = initialCIImage;
            if (CGRectEqualToRect(rect, bounds) == NO)
                value = [value imageByCroppingToRect:rect];
        } else if ([key isEqualToString:kCIInputTargetImageKey]) {
            value = finalCIImage;
            if (CGRectEqualToRect(rect, bounds) == NO)
                value = [value imageByCroppingToRect:rect];
        } else if ([key isEqualToString:kCIInputShadingImageKey]) {
            static CIImage *inputShadingImage = nil;
            if (inputShadingImage == nil)
                inputShadingImage = [[CIImage alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TransitionShading" withExtension:@"tiff"]];
            value = inputShadingImage;
        } else if ([key isEqualToString:kCIInputBacksideImageKey]) {
            value = initialCIImage;
            if (CGRectEqualToRect(rect, bounds) == NO)
                value = [value imageByCroppingToRect:rect];
        } else if ([[[[transitionFilter attributes] objectForKey:key] objectForKey:kCIAttributeClass] isEqualToString:@"CIImage"]) {
            // Scale and translate our mask image to match the transition area size.
            static CIImage *inputMaskImage = nil;
            if (inputMaskImage == nil)
                inputMaskImage = [[CIImage alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TransitionMask" withExtension:@"jpg"]];
            CGRect extent = [inputMaskImage extent];
            CGAffineTransform transform;
            if ((CGRectGetWidth(extent) < CGRectGetHeight(extent)) != (CGRectGetWidth(rect) < CGRectGetHeight(rect))) {
                transform = CGAffineTransformMake(0.0, 1.0, 1.0, 0.0, 0.0, 0.0);
                transform = CGAffineTransformTranslate(transform, CGRectGetMinY(rect) - CGRectGetMinY(bounds), CGRectGetMinX(rect) - CGRectGetMinX(bounds));
                transform = CGAffineTransformScale(transform, CGRectGetHeight(rect) / CGRectGetWidth(extent), CGRectGetWidth(rect) / CGRectGetHeight(extent));
            } else {
                transform = CGAffineTransformMakeTranslation(CGRectGetMinX(rect) - CGRectGetMinX(bounds), CGRectGetMinY(rect) - CGRectGetMinY(bounds));
                transform = CGAffineTransformScale(transform, CGRectGetWidth(rect) / CGRectGetWidth(extent), CGRectGetHeight(rect) / CGRectGetHeight(extent));
            }
            value = [inputMaskImage imageByApplyingTransform:transform];
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

- (SKTransitionView *)transitionViewForRect:(NSRect)rect image:(CIImage *)image scale:(CGFloat)imageScale {
    SKTransitionView *transitionView = nil;
    
    if (window == nil) {
        transitionView = [[[SKTransitionView alloc] init] autorelease];
        window = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [window setReleasedWhenClosed:NO];
        [window setIgnoresMouseEvents:YES];
        [window setContentView:transitionView];
    } else {
        transitionView = (SKTransitionView *)[window contentView];
    }
    
    [transitionView setImageScale:imageScale];
    [transitionView setImage:image];
    [transitionView setNeedsDisplay:YES];
    
    NSRect frame = [view convertRect:rect toView:nil];
    frame.origin = [[view window] convertBaseToScreen:frame.origin];
    [window setFrame:frame display:NO];
    [window orderBack:nil];
    [[view window] addChildWindow:window ordered:NSWindowAbove];
    
    return transitionView;
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
}

- (void)animateCoreGraphicsForRect:(NSRect)rect {
    CIImage *finalImage = nil;
    NSWindow *viewWindow = [view window];
    SKTransitionView *transitionView = nil;
    
    if (currentShouldRestrict) {
        NSRect bounds = [view bounds];
        CGFloat imageScale = CGRectGetWidth([initialImage extent]) / NSWidth(bounds);
        
        imageRect = NSIntegralRect(NSIntersectionRect(NSUnionRect(imageRect, rect), bounds));
        
        finalImage = [self newCurrentImage];
        
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-imageScale * NSMinX(imageRect), -imageScale * NSMinY(imageRect));
        initialImage = [[initialImage autorelease] imageByApplyingTransform:transform];
        finalImage = [[finalImage autorelease] imageByApplyingTransform:transform];
        
        transitionView = [self transitionViewForRect:imageRect image:initialImage scale:imageScale];
        initialImage = nil;
    }
    
    // declare our variables  
    int handle = -1;
    CGSTransitionSpec spec;
    // specify our specifications
    spec.unknown1 = 0;
    spec.type =  currentTransitionStyle;
    spec.option = currentForward ? CGSLeft : CGSRight;
    spec.backColour = NULL;
    spec.wid = [(currentShouldRestrict ? window : viewWindow) windowNumber];
    
    // Let's get a connection
    CGSConnection cgs = _CGSDefaultConnection();
    
    // Create a transition
    CGSNewTransition(cgs, &spec, &handle);
    
    if (currentShouldRestrict) {
        [transitionView setImage:finalImage];
        [transitionView display];
    }
    
    // Redraw the window
    [viewWindow display];
    // Remember we disabled flushing in the previous method, we need to balance that.
    [viewWindow enableFlushWindow];
    [viewWindow flushWindow];
    
    CGSInvokeTransition(cgs, handle, currentDuration);
    // We need to wait for the transition to finish before we get rid of it, otherwise we'll get all sorts of nasty errors... or maybe not.
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:currentDuration]];
    
    CGSReleaseTransition(cgs, handle);
    handle = 0;
    
    if (currentShouldRestrict) {
        [viewWindow removeChildWindow:window];
        [window orderOut:nil];
        [transitionView setImage:nil];
    }
}

- (void)animateCoreImageForRect:(NSRect)rect  {
    CGFloat imageScale = CGRectGetWidth([initialImage extent]) / NSWidth([view bounds]);
    
    NSRect bounds = [view bounds];
    imageRect = NSIntegralRect(NSIntersectionRect(NSUnionRect(imageRect, rect), bounds));
    
    CIImage *finalImage = [self newCurrentImage];
    
    CIFilter *transitionFilter = [self transitionFilterForRect:scaleRect(imageRect, imageScale) bounds:scaleRect(bounds, imageScale) forward:currentForward initialCIImage:initialImage finalCIImage:finalImage];
    
    [finalImage release];
    
    SKTransitionView *transitionView = [self transitionViewForRect:[view bounds] image:initialImage scale:imageScale];
    
    [initialImage release];
    initialImage = nil;
    
    SKTransitionAnimation *animation = [[SKTransitionAnimation alloc] initWithDuration:currentDuration animationCurve:NSAnimationEaseInOut];
    [animation setProgressHandler:^(CGFloat value){
            [transitionFilter setValue:[NSNumber numberWithDouble:value] forKey:kCIInputTimeKey];
            [transitionView setImage:[transitionFilter valueForKey:kCIOutputImageKey]];
            [transitionView display];
        }];
    [animation startAnimation];
    [animation release];
    
    // Update the view and its window, so it shows the correct state when it is shown.
    [view display];
    // Remember we disabled flushing in the previous method, we need to balance that.
    NSWindow *viewWindow = [view window];
    [viewWindow enableFlushWindow];
    [viewWindow flushWindow];
    
    [viewWindow removeChildWindow:window];
    [window orderOut:nil];
    [transitionView setImage:nil];
}

- (void)animateForRect:(NSRect)rect  {
    if (NSEqualRects(imageRect, NSZeroRect))
        [self prepareAnimationForRect:rect from:NSNotFound to:NSNotFound];
	
    if (currentTransitionStyle >= SKCoreImageTransition)
        [self animateCoreImageForRect:rect];
	else if (currentTransitionStyle > SKNoTransition && CoreGraphicsServicesTransitionsDefined())
        [self animateCoreGraphicsForRect:rect];
    
    currentTransitionStyle = transitionStyle;
    currentDuration = duration;
    currentShouldRestrict = shouldRestrict;
    currentForward = YES;
    
    imageRect = NSZeroRect;
}

@end

#pragma mark -

@implementation SKTransitionAnimation

@synthesize progressHandler;

- (void)dealloc {
    SKDESTROY(progressHandler);
    [super dealloc];
}

- (void)setCurrentProgress:(NSAnimationProgress)progress {
    [super setCurrentProgress:progress];
    if (progressHandler) progressHandler([self currentValue]);
}

@end

#pragma mark -

@implementation SKTransitionView

@synthesize image, imageScale;

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
    SKDESTROY(image);
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

- (void)updateMatrices {
    NSRect bounds = [self bounds];
    CGFloat scale = ([self respondsToSelector:@selector(wantsBestResolutionOpenGLSurface)] && [self wantsBestResolutionOpenGLSurface]) ? [self backingScale] : 1.0;
    
    [[self openGLContext] update];
    
    glViewport(0, 0, scale * NSWidth(bounds), scale * NSHeight(bounds));

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(scale * NSMinX(bounds), scale * NSMaxX(bounds), scale * NSMinY(bounds), scale * NSMaxY(bounds), -1, 1);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    needsReshape = NO;
}

- (void)drawRect:(NSRect)rect {
    [[self openGLContext] makeCurrentContext];
    
    if (needsReshape)
        [self updateMatrices];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    if (image) {
        CGFloat scale = ([self respondsToSelector:@selector(wantsBestResolutionOpenGLSurface)] && [self wantsBestResolutionOpenGLSurface]) ? [self backingScale] : 1.0;
        NSRect bounds = [self bounds];
        if (context == nil) {
            NSOpenGLPixelFormat *pf = [self pixelFormat] ?: [[self class] defaultPixelFormat];
            context = [[CIContext contextWithCGLContext:CGLGetCurrentContext() pixelFormat:[pf CGLPixelFormatObj] colorSpace:nil options:nil] retain];
        }
        [context drawImage:image inRect:scaleRect(bounds, scale) fromRect:scaleRect(bounds, imageScale)];
    }
    
    glFlush();
}

@end
