//
//  SKTransitionController.m
//  Skim
//
//  Created by Christiaan Hofman on 7/15/07.
/*
 This software is Copyright (c) 2007-2014
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

@interface SKTransitionView : NSOpenGLView <SKTransitionAnimationDelegate> {
    SKTransitionAnimation *animation;
    CIImage *image;
    CIContext *context;
    BOOL needsReshape;
}
@property (nonatomic, retain) SKTransitionAnimation *animation;
@property (nonatomic, retain) CIImage *image;
@property (nonatomic, readonly) CIImage *currentImage;
@end

#pragma mark -

@implementation SKTransitionController

@synthesize view, transitionStyle, duration, shouldRestrict, pageTransitions;
@dynamic hasTransition;

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
    NSWindow *window = [[[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
    [window setReleasedWhenClosed:NO];
    [window setIgnoresMouseEvents:YES];
    [window setContentView:[[[SKTransitionView alloc] init] autorelease]];
    
    if ((self = [self initWithWindow:window])) {
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
    SKDESTROY(initialImage);
    SKDESTROY(filters);
    SKDESTROY(pageTransitions);
    [super dealloc];
}

- (BOOL)hasTransition {
    return transitionStyle != SKNoTransition && pageTransitions != nil;
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
        NSData *shadingBitmapData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TransitionShading" withExtension:@"tiff"]];
        NSBitmapImageRep *shadingBitmap = [[[NSBitmapImageRep alloc] initWithData:shadingBitmapData] autorelease];
        inputShadingImage = [[CIImage alloc] initWithBitmapImageRep:shadingBitmap];
    }
    return inputShadingImage;
}

- (CIImage *)inputMaskImage {
    static CIImage *inputMaskImage = nil;
    if (inputMaskImage == nil) {
        NSData *maskBitmapData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TransitionMask" withExtension:@"jpg"]];
        NSBitmapImageRep *maskBitmap = [[[NSBitmapImageRep alloc] initWithData:maskBitmapData] autorelease];
        inputMaskImage = [[CIImage alloc] initWithBitmapImageRep:maskBitmap];
    }
    return inputMaskImage;
}

- (CIImage *)cropImage:(CIImage *)image toRect:(NSRect)rect {
    CIFilter *cropFilter = [self filterWithName:@"CICrop"];
    [cropFilter setValue:[CIVector vectorWithX:NSMinX(rect) Y:NSMinY(rect) Z:NSWidth(rect) W:NSHeight(rect)] forKey:kCIInputRectangleKey];
    [cropFilter setValue:image forKey:kCIInputImageKey];
    return [cropFilter valueForKey:kCIOutputImageKey];
}

- (CIImage *)translateImage:(CIImage *)image xBy:(CGFloat)dx yBy:(CGFloat)dy {
    CIFilter *translationFilter = [self filterWithName:@"CIAffineTransform"];
    NSAffineTransform *affineTransform = [NSAffineTransform transform];
    [affineTransform translateXBy:dx yBy:dy];
    [translationFilter setValue:affineTransform forKey:kCIInputTransformKey];
    [translationFilter setValue:image forKey:kCIInputImageKey];
    return [translationFilter valueForKey:kCIOutputImageKey];
}

- (CIImage *)scaleImage:(CIImage *)image toSize:(NSSize)size {
    CIFilter *scalingFilter = [self filterWithName:@"CILanczosScaleTransform"];
    CGRect extent = [image extent];
    CGFloat xScale = size.width / CGRectGetWidth(extent);
    CGFloat yScale = size.height / CGRectGetHeight(extent);
    [scalingFilter setValue:[NSNumber numberWithDouble:yScale] forKey:kCIInputScaleKey];
    [scalingFilter setValue:[NSNumber numberWithDouble:xScale / yScale] forKey:kCIInputAspectRatioKey];
    [scalingFilter setValue:image forKey:kCIInputImageKey];
    return [scalingFilter valueForKey:kCIOutputImageKey];
}

- (CIFilter *)transitionFilterForRect:(NSRect)rect forward:(BOOL)forward initialCIImage:(CIImage *)initialCIImage finalCIImage:(CIImage *)finalCIImage {
    NSString *filterName = [[[self class] transitionFilterNames] objectAtIndex:currentTransitionStyle - SKCoreImageTransition];
    CIFilter *transitionFilter = [self filterWithName:filterName];
    
    NSRect bounds = [view bounds];
    
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
            value = [self inputShadingImage];
        } else if ([key isEqualToString:kCIInputBacksideImageKey]) {
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
}

- (void)animateCoreGraphicsForRect:(NSRect)rect {
    CIImage *finalImage = nil;
    
    if (currentShouldRestrict) {
        if (initialImage == nil)
            [self prepareAnimationForRect:rect from:NSNotFound to:NSNotFound];
        
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
    usleep((useconds_t)(currentDuration * 1000000));
    
    CGSReleaseTransition(cgs, handle);
    handle = 0;
    
    if (currentShouldRestrict) {
        [[view window] removeChildWindow:[self window]];
        [[self window] orderOut:nil];
        [[self transitionView] setImage:nil];
    }
}

- (void)animateCoreImageForRect:(NSRect)rect  {
    if (initialImage == nil)
        [self prepareAnimationForRect:rect from:NSNotFound to:NSNotFound];
    
    NSRect bounds = [view bounds];
    imageRect = NSIntegralRect(NSIntersectionRect(NSUnionRect(imageRect, rect), bounds));
    
    CIImage *finalImage = [self newCurrentImage];
    
    CIFilter *transitionFilter = [self transitionFilterForRect:imageRect forward:currentForward initialCIImage:initialImage finalCIImage:finalImage];
    
    [finalImage release];
    [initialImage release];
    initialImage = nil;
    
    NSRect frame = [view convertRect:[view frame] toView:nil];
    frame.origin = [[view window] convertBaseToScreen:frame.origin];
    
    SKTransitionAnimation *animation = [[SKTransitionAnimation alloc] initWithFilter:transitionFilter duration:currentDuration];
    [[self transitionView] setAnimation:animation];
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
	if (currentTransitionStyle >= SKCoreImageTransition)
        [self animateCoreImageForRect:rect];
	else if (currentTransitionStyle > SKNoTransition && CoreGraphicsServicesTransitionsDefined())
        [self animateCoreGraphicsForRect:rect];
    
    currentTransitionStyle = transitionStyle;
    currentDuration = duration;
    currentShouldRestrict = shouldRestrict;
    currentForward = YES;
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

@synthesize animation, image;
@dynamic currentImage;

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
