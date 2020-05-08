//
//  SKTransitionController.m
//  Skim
//
//  Created by Christiaan Hofman on 7/15/07.
/*
 This software is Copyright (c) 2007-2020
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
#import <Quartz/Quartz.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

NSString *SKStyleNameKey = @"styleName";
NSString *SKDurationKey = @"duration";
NSString *SKShouldRestrictKey = @"shouldRestrict";

#define kCIInputBacksideImageKey @"inputBacksideImage"

#define TRANSITIONS_PLUGIN @"SkimTransitions.plugin"

#define SKEnableCoreGraphicsTransitionsKey @"SKEnableCoreGraphicsTransitions"

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

static CGSConnection (*_CGSDefaultConnection_func)(void) = NULL;
static OSStatus (*CGSNewTransition_func)(const CGSConnection cid, const CGSTransitionSpec* spec, int *pTransitionHandle) = NULL;
static OSStatus (*CGSInvokeTransition_func)(const CGSConnection cid, int transitionHandle, float duration);
static OSStatus (*CGSReleaseTransition_func)(const CGSConnection cid, int transitionHandle);

#define LOAD_FUNCTION(name, bundle) ((name ## _func = (typeof(name ## _func))CFBundleGetFunctionPointerForName(bundle, CFSTR(#name))) != NULL)

#pragma mark -

@protocol SKTransitionView <NSObject>
@property (nonatomic, retain) CIImage *image;
@property (nonatomic) CGRect extent;
@property (nonatomic, retain) CIFilter *filter;
@property (nonatomic) CGFloat progress;
@end

#pragma mark -

@interface SKTransitionView : NSView <SKTransitionView> {
    CIImage *image;
    CGRect extent;
    CIFilter *filter;
}
@end

#pragma mark -

@interface SKOpenGLTransitionView : NSOpenGLView <SKTransitionView> {
    CIImage *image;
    CGRect extent;
    CIFilter *filter;
    CIContext *context;
    BOOL needsReshape;
}
@end

#pragma mark -

@interface SKMetalTransitionView : NSView <SKTransitionView, MTKViewDelegate> {
    CIImage *image;
    CGRect extent;
    CIFilter *filter;
    id<MTLCommandQueue> commandQueue;
    CIContext *context;
}
@end

#pragma mark -

// Core Graphics transitions
// this corresponds to the CGSTransitionType enum
enum {
    SKTransitionFade = 1,
    SKTransitionZoom,
    SKTransitionReveal,
    SKTransitionSlide,
    SKTransitionWarpFade,
    SKTransitionSwap,
    SKTransitionCube,
    SKTransitionWarpSwitch,
    SKTransitionFlip
};

static SKTransitionStyle SKCoreImageTransition = 1;

@implementation SKTransitionController

@synthesize view, transitionStyle, duration, shouldRestrict, pageTransitions;
@dynamic hasTransition;

static NSDictionary *oldStyleNames = nil;
static BOOL hasCoreGraphicsTransitions = NO;

+ (void)initialize {
    SKINITIALIZE;
    oldStyleNames = [[NSDictionary alloc] initWithObjectsAndKeys:
                     @"CoreGraphics SKTransitionFade", @"CIDissolveTransition",
                     @"CoreGraphics SKTransitionZoom", @"SKTZoomTransition",
                     @"CoreGraphics SKTransitionReveal", @"SKTRevealTransition",
                     @"CoreGraphics SKTransitionSlide", @"SKTSlideTransition",
                     @"CoreGraphics SKTransitionWarpFade", @"SKTWarpFadeTransition",
                     @"CoreGraphics SKTransitionSwap", @"SKTSwapTransition",
                     @"CoreGraphics SKTransitionCube", @"SKTCubeTransition",
                     @"CoreGraphics SKTransitionWarpSwitch", @"SKTSwitchTransition",
                     @"CoreGraphics SKTransitionWarpFlip", @"SKTFlipTransition",
                     @"SKPTAccelerationTransitionFilter", @"SKTAccelerationTransition",
                     @"SKPTBlindsTransitionFilter", @"SKTBlindsTransition",
                     @"SKPTBlurTransitionFilter", @"SKTBlurTransition",
                     @"SKPTBoxInTransitionFilter", @"SKTBoxInTransition",
                     @"SKPTBoxOutTransitionFilter", @"SKTBoxOutTransition",
                     @"SKPTCoverTransitionFilter", @"SKTCoverTransition",
                     @"SKPTHoleTransitionFilter", @"SKTHoleTransition",
                     @"SKPTMeltdownTransitionFilter", @"SKTMeltdownTransition",
                     @"SKPTPinchTransitionFilter", @"SKTPinchTransition",
                     @"SKPTRadarTransitionFilter", @"SKTRadarTransition",
                     @"SKPTSinkTransitionFilter", @"SKTSinkTransition",
                     @"SKPTSplitInTransitionFilter", @"SKTSplitInTransition",
                     @"SKPTSplitOutTransitionFilter", @"SKSplitOutTransition",
                     @"SKPTStripsTransitionFilter", @"SKTStripsTransition",
                     @"SKPTUncoverTransitionFilter", @"SKTRevealTransition",
                     nil];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKEnableCoreGraphicsTransitionsKey]) {
        CFBundleRef bundle = CFBundleGetBundleWithIdentifier(CFSTR("com.apple.CoreGraphics"));
        if (bundle &&
            LOAD_FUNCTION(_CGSDefaultConnection, bundle) &&
            LOAD_FUNCTION(_CGSDefaultConnection, bundle) &&
            LOAD_FUNCTION(CGSNewTransition, bundle) &&
            LOAD_FUNCTION(CGSInvokeTransition, bundle) &&
            LOAD_FUNCTION(CGSReleaseTransition, bundle)) {
            SKCoreImageTransition = SKTransitionFlip + 1;
            hasCoreGraphicsTransitions = YES;
        }
    }
}

+ (NSArray *)transitionNames {
    static NSArray *transitionNames = nil;
    
    if (transitionNames == nil) {
        NSMutableArray *names = [NSMutableArray arrayWithObjects:
            @"", nil];
        if (hasCoreGraphicsTransitions) {
            [names addObjectsFromArray:[NSArray arrayWithObjects:
               @"CoreGraphics SKTransitionFade",
               @"CoreGraphics SKTransitionZoom",
               @"CoreGraphics SKTransitionReveal",
               @"CoreGraphics SKTransitionSlide",
               @"CoreGraphics SKTransitionWarpFade",
               @"CoreGraphics SKTransitionSwap",
               @"CoreGraphics SKTransitionCube",
               @"CoreGraphics SKTransitionWarpSwitch",
               @"CoreGraphics SKTransitionWarpFlip", nil]];
        }
        // get our transitions
        NSURL *transitionsURL = [[[NSBundle mainBundle] builtInPlugInsURL] URLByAppendingPathComponent:TRANSITIONS_PLUGIN];
        [CIPlugIn loadPlugIn:transitionsURL allowExecutableCode:YES];
        // get all the transition filters
		[CIPlugIn loadAllPlugIns];
        [names addObjectsFromArray:[CIFilter filterNamesInCategory:kCICategoryTransition]];
        transitionNames = [names copy];
    }
    
    return transitionNames;
}

+ (NSString *)nameForStyle:(SKTransitionStyle)style {
    if (style > SKNoTransition && style < [[self transitionNames] count])
        return [[self transitionNames] objectAtIndex:style];
    else
        return nil;
}

+ (SKTransitionStyle)styleForName:(NSString *)name {
    NSUInteger idx = [[self transitionNames] indexOfObject:name];
    if (idx == NSNotFound) {
        NSString *altName = [oldStyleNames objectForKey:name];
        if (altName)
            idx = [[self transitionNames] indexOfObject:altName];
    }
    return idx == NSNotFound ? SKNoTransition : idx;
}

+ (NSString *)localizedNameForStyle:(SKTransitionStyle)style {
    if (style == SKNoTransition) {
        return NSLocalizedString(@"No Transition", @"Transition name");
    } else if ([self isCoreImageTransition:style]) {
        return [CIFilter localizedNameForFilterName:[self nameForStyle:style]];
    } else if ([self isCoreGraphicsTransition:style]) {
        static NSArray *localizedCoreGraphicsNames = nil;
        if (localizedCoreGraphicsNames == nil)
            localizedCoreGraphicsNames = [[NSArray alloc] initWithObjects:@"",
                  NSLocalizedString(@"Fade", @"Transition name"),
                  NSLocalizedString(@"Zoom", @"Transition name"),
                  NSLocalizedString(@"Reveal", @"Transition name"),
                  NSLocalizedString(@"Reveal", @"Transition name"),
                  NSLocalizedString(@"Slide", @"Transition name"),
                  NSLocalizedString(@"Warp Fade", @"Transition name"),
                  NSLocalizedString(@"Swap", @"Transition name"),
                  NSLocalizedString(@"Cube", @"Transition name"),
                  NSLocalizedString(@"Warp Switch", @"Transition name"),
                  NSLocalizedString(@"Flip", @"Transition name"), nil];
        return [[localizedCoreGraphicsNames objectAtIndex:style] stringByAppendingString:@"*"];
    };
    return @"";
}

+ (BOOL)isCoreGraphicsTransition:(SKTransitionStyle)style {
    return hasCoreGraphicsTransitions && style > SKNoTransition && style < SKCoreImageTransition;
}

+ (BOOL)isCoreImageTransition:(SKTransitionStyle)style {
    return style >= SKCoreImageTransition;
}

- (id)initForView:(NSView *)aView {
    self = [super init];
    if (self) {
        view = aView; // don't retain as it may retain us
        
        transitionStyle = SKNoTransition;
        duration = 1.0;
        shouldRestrict = YES;
    }
    return self;
}

- (void)dealloc {
    view = nil;
    SKDESTROY(transitionView);
    SKDESTROY(window);
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
- (CIFilter *)transitionFilterForStyle:(SKTransitionStyle)style rect:(CGRect)rect bounds:(CGRect)bounds restricted:(BOOL)restricted forward:(BOOL)forward initialImage:(CIImage *)initialImage finalImage:(CIImage *)finalImage {
    NSString *filterName = [[self class] nameForStyle:style];
    CIFilter *transitionFilter = [CIFilter filterWithName:filterName];
    
    [transitionFilter setDefaults];
    
    for (NSString *key in [transitionFilter inputKeys]) {
        id value = nil;
        if ([key isEqualToString:kCIInputExtentKey]) {
            CGRect extent = restricted ? rect : bounds;
            value = [CIVector vectorWithX:CGRectGetMinX(extent) Y:CGRectGetMinY(extent) Z:CGRectGetWidth(extent) W:CGRectGetHeight(extent)];
        } else if ([key isEqualToString:kCIInputAngleKey]) {
            CGFloat angle = forward ? 0.0 : M_PI;
            if ([filterName hasPrefix:@"CIPageCurlTransition"] || [filterName isEqualToString:@"CIPageCurlWithShadowTransition"])
                angle = forward ? -M_PI_4 : -3.0 * M_PI_4;
            value = [NSNumber numberWithDouble:angle];
        } else if ([key isEqualToString:kCIInputCenterKey]) {
            value = [CIVector vectorWithX:CGRectGetMidX(rect) Y:CGRectGetMidY(rect)];
        } else if ([key isEqualToString:kCIInputImageKey]) {
            value = initialImage;
        } else if ([key isEqualToString:kCIInputTargetImageKey]) {
            value = finalImage;
        } else if ([key isEqualToString:kCIInputShadingImageKey]) {
            static CIImage *inputShadingImage = nil;
            if (inputShadingImage == nil)
                inputShadingImage = [[CIImage alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TransitionShading" withExtension:@"tiff"]];
            value = inputShadingImage;
        } else if ([key isEqualToString:kCIInputBacksideImageKey]) {
            value = initialImage;
        } else if ([[[[transitionFilter attributes] objectForKey:key] objectForKey:kCIAttributeType] isEqualToString:kCIAttributeTypeBoolean]) {
            if ([[NSSet setWithObjects:@"inputBackward", @"inputRight", @"inputReversed", nil] containsObject:key])
                value = [NSNumber numberWithBool:forward == NO];
            else if ([[NSSet setWithObjects:@"inputForward", @"inputLeft", nil] containsObject:key])
                value = [NSNumber numberWithBool:forward];
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

- (CIImage *)currentImageForRect:(NSRect)rect scale:(CGFloat *)scalePtr {
    NSRect bounds = [view bounds];
    NSBitmapImageRep *contentBitmap = [view bitmapImageRepCachingDisplayInRect:bounds];
    CIImage *tmpImage = [[CIImage alloc] initWithBitmapImageRep:contentBitmap];
    CGFloat scale = CGRectGetWidth([tmpImage extent]) / NSWidth(bounds);
    CIImage *image = [tmpImage imageByCroppingToRect:CGRectIntegral(scaleRect(NSIntersectionRect(rect, bounds), scale))];
    [tmpImage release];
    if (scalePtr) *scalePtr = scale;
    return image;
}

- (void)showTransitionViewForRect:(NSRect)rect image:(CIImage *)image extent:(CGRect)extent {
    if (transitionView == nil) {
        if ([MTKView class])
            transitionView = [[SKMetalTransitionView alloc] init];
        else
            transitionView = [[SKOpenGLTransitionView alloc] init];
        [transitionView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        CAAnimation *animation = [CABasicAnimation animation];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [transitionView setAnimations:[NSDictionary dictionaryWithObjectsAndKeys:animation, @"progress", nil]];
    }
    
    [transitionView setImage:image];
    [transitionView setExtent:extent];
    [transitionView setNeedsDisplay:YES];
    
    [transitionView setFrame:rect];
    [view addSubview:transitionView positioned:NSWindowAbove relativeTo:nil];
}

- (void)removeTransitionView {
    [transitionView removeFromSuperview];
    [transitionView setFilter:nil];
    [transitionView setImage:nil];
}

- (void)showTransitionWindowForRect:(NSRect)rect image:(CIImage *)image extent:(CGRect)extent {
    SKTransitionView *tView = (SKTransitionView *)[window contentView];
    if (window == nil) {
        tView = [[[SKTransitionView alloc] init] autorelease];
        window = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [window setReleasedWhenClosed:NO];
        [window setIgnoresMouseEvents:YES];
        [window setBackgroundColor:[NSColor blackColor]];
        [window setAnimationBehavior:NSWindowAnimationBehaviorNone];
        [window setContentView:tView];
    }
    
    [tView setImage:image];
    [tView setExtent:extent];
    [tView setNeedsDisplay:YES];
    
    [window setFrame:[view convertRectToScreen:rect] display:NO];
    [window orderBack:nil];
    [[view window] addChildWindow:window ordered:NSWindowAbove];
}

- (void)removeTransitionWindow {
    SKTransitionView *tView = (SKTransitionView *)[window contentView];
    [[window parentWindow] removeChildWindow:window];
    [window orderOut:nil];
    [tView setImage:nil];
}

- (void)animateForRect:(NSRect)rect from:(NSUInteger)fromIndex to:(NSUInteger)toIndex change:(NSRect (^)(void))change {
    if (animating) {
        change();
        return;
    }
    
    SKTransitionStyle currentTransitionStyle = transitionStyle;
    CGFloat currentDuration = duration;
    BOOL currentShouldRestrict = shouldRestrict;
    BOOL currentForward = (toIndex >= fromIndex);
    
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
    
    if ([SKTransitionController isCoreImageTransition:currentTransitionStyle]) {
        
        animating = YES;
        
        NSWindow *viewWindow = [view window];
        CIImage *initialImage = [self currentImageForRect:rect scale:NULL];
        
        // We don't want the window to draw the next state before the animation is run
        [viewWindow disableFlushWindow];
        
        NSRect toRect = change();

        NSRect bounds = [view bounds];
        CGFloat imageScale = 1.0;
        CIImage *finalImage = [self currentImageForRect:toRect scale:&imageScale];
        CGRect cgRect = CGRectIntegral(scaleRect(NSIntersectionRect(NSUnionRect(rect, toRect), bounds), imageScale));
        CGRect cgBounds = scaleRect(bounds, imageScale);
        CIFilter *transitionFilter = [self transitionFilterForStyle:currentTransitionStyle
                                                               rect:cgRect
                                                             bounds:cgBounds
                                                         restricted:currentShouldRestrict
                                                            forward:currentForward
                                                       initialImage:initialImage
                                                         finalImage:finalImage];
        [self showTransitionViewForRect:bounds image:initialImage extent:cgBounds];
        
        // Update the view and its window, so it shows the correct state when it is shown.
        [view display];
        // Remember we disabled flushing in the previous method, we need to balance that.
        [viewWindow enableFlushWindow];
        [viewWindow flushWindow];
        
        [transitionView setFilter:transitionFilter];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                [context setDuration:currentDuration];
                [[transitionView animator] setProgress:1.0];
            } completionHandler:^{
                [self removeTransitionView];
                animating = NO;
            }];
        
    } else if ([SKTransitionController isCoreGraphicsTransition:currentTransitionStyle]) {
        
        animating = YES;
        
        NSWindow *viewWindow = [view window];
        CIImage *initialImage = nil;
        if (currentShouldRestrict)
            initialImage = [self currentImageForRect:rect scale:NULL];
        
        // We don't want the window to draw the next state before the animation is run
        [viewWindow disableFlushWindow];
        
        NSRect toRect = change();
        
        CIImage *finalImage = nil;
        
        if (currentShouldRestrict) {
            CGFloat imageScale = 1.0;
            
            finalImage = [self currentImageForRect:toRect scale:&imageScale];
            
            rect = NSIntegralRect(NSIntersectionRect(NSUnionRect(rect, toRect), [view bounds]));
            
            [self showTransitionWindowForRect:rect image:initialImage extent:scaleRect(rect, imageScale)];
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
        CGSConnection cgs = _CGSDefaultConnection_func();
        
        // Create a transition
        CGSNewTransition_func(cgs, &spec, &handle);
        
        if (currentShouldRestrict) {
            [(SKTransitionView *)[window contentView] setImage:finalImage];
            [[window contentView] display];
        }
        
        // Redraw the window
        [viewWindow display];
        // Remember we disabled flushing in the previous method, we need to balance that.
        [viewWindow enableFlushWindow];
        [viewWindow flushWindow];
        
        CGSInvokeTransition_func(cgs, handle, currentDuration);
        
        DISPATCH_MAIN_AFTER_SEC(currentDuration, ^{
            CGSReleaseTransition_func(cgs, handle);
            
            if (currentShouldRestrict)
                [self removeTransitionWindow];
            
            animating = NO;
        });
        
    } else {
        change();
    }
}

@end

#pragma mark -

@implementation SKTransitionView

@synthesize image, extent, filter;
@dynamic progress;

- (void)dealloc {
    SKDESTROY(image);
    SKDESTROY(filter);
    [super dealloc];
}

- (BOOL)isOpaque { return YES; }

- (CGFloat)progress {
    NSNumber *number = [filter valueForKey:kCIInputTimeKey];
    return number ? [number doubleValue] : 0.0;
}

- (void)setProgress:(CGFloat)newProgress {
    if (filter) {
        [filter setValue:[NSNumber numberWithDouble:newProgress] forKey:kCIInputTimeKey];
        [self setImage:[filter valueForKey:kCIOutputImageKey]];
        [self setNeedsDisplay:YES];
    }
}

- (void)drawRect:(NSRect)rect {
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
    [image drawInRect:[self bounds] fromRect:extent operation:NSCompositeSourceOver fraction:1.0];
}

@end

#pragma mark -

@implementation SKOpenGLTransitionView

@synthesize image, extent, filter;
@dynamic progress;

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

- (id)init {
    self = [super init];
    if (self) {
        [self setWantsBestResolutionOpenGLSurface:YES];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(image);
    SKDESTROY(filter);
    SKDESTROY(context);
    [super dealloc];
}

- (CGFloat)progress {
    NSNumber *number = [filter valueForKey:kCIInputTimeKey];
    return number ? [number doubleValue] : 0.0;
}

- (void)setProgress:(CGFloat)newProgress {
    if (filter) {
        [filter setValue:[NSNumber numberWithDouble:newProgress] forKey:kCIInputTimeKey];
        [self setImage:[filter valueForKey:kCIOutputImageKey]];
        [self setNeedsDisplay:YES];
    }
}

- (void)reshape    {
    [super reshape];
    needsReshape = YES;
}

- (void)prepareOpenGL {
    [super prepareOpenGL];
    
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
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glHint(GL_TRANSFORM_HINT_APPLE, GL_FASTEST);
    
    needsReshape = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];
    CGRect rect = NSRectToCGRect([self wantsBestResolutionOpenGLSurface] ? [self convertRectToBacking:bounds] : bounds);
    
    [[self openGLContext] makeCurrentContext];
    
    if (needsReshape) {
        [[self openGLContext] update];
        
        glViewport(0, 0, CGRectGetWidth(rect), CGRectGetHeight(rect));

        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(CGRectGetMinX(rect), CGRectGetMaxX(rect), CGRectGetMinY(rect), CGRectGetMaxY(rect), -1, 1);

        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        
        needsReshape = NO;
    }
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (image) {
        if (context == nil) {
            NSOpenGLPixelFormat *pf = [self pixelFormat] ?: [[self class] defaultPixelFormat];
            context = [[CIContext contextWithCGLContext:[[self openGLContext] CGLContextObj] pixelFormat:[pf CGLPixelFormatObj] colorSpace:nil options:nil] retain];
        }
        [context drawImage:image inRect:rect fromRect:extent];
    }
    
    glFlush();
}

@end

#pragma mark -

@implementation SKMetalTransitionView

@synthesize image, extent, filter;
@dynamic progress;

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self && [MTKView class]) {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        MTKView *view = [[MTKView alloc] initWithFrame:[self bounds] device:device];
        [view setFramebufferOnly:NO];
        [view setEnableSetNeedsDisplay:YES];
        [view setPaused:YES];
        [view setClearColor:MTLClearColorMake(0.0, 0.0, 0.0, 1.0)];
        [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [view setDelegate:self];
        [self addSubview:view];
        [view release];
        commandQueue = [device newCommandQueue];
        context = [[CIContext contextWithMTLDevice:device] retain];
        CFRelease(device);
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(image);
    SKDESTROY(filter);
    SKDESTROY(commandQueue);
    SKDESTROY(context);
    [super dealloc];
}

- (CGFloat)progress {
    NSNumber *number = [filter valueForKey:kCIInputTimeKey];
    return number ? [number doubleValue] : 0.0;
}

- (void)setProgress:(CGFloat)newProgress {
    if (filter) {
        [filter setValue:[NSNumber numberWithDouble:newProgress] forKey:kCIInputTimeKey];
        [self setImage:[filter valueForKey:kCIOutputImageKey]];
        [[[self subviews] firstObject] setNeedsDisplay:YES];
    }
}

- (void)drawInMTKView:(MTKView *)view {
    if (image == nil)
        return;
    
    id<CAMetalDrawable> drawable = [view currentDrawable];
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBufferWithUnretainedReferences];
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:[view currentRenderPassDescriptor]];
    
    [commandEncoder endEncoding];
    
    CGRect bounds = {CGPointZero, [view drawableSize]};
    CIImage *img = image;
    CGColorSpaceRef cs = [image colorSpace] ?: [(CIImage *)[filter valueForKey:kCIInputImageKey] colorSpace] ?: (CGColorSpaceRef)[(id)CGColorSpaceCreateDeviceRGB() autorelease];
    
    if (CGRectEqualToRect(extent, bounds) == NO) {
        CGAffineTransform t = CGAffineTransformMakeScale(CGRectGetWidth(bounds) / CGRectGetWidth(extent), CGRectGetHeight(bounds) / CGRectGetHeight(extent));
        t = CGAffineTransformTranslate(t, -CGRectGetMinX(extent), -CGRectGetMinY(extent));
        img = [image imageByApplyingTransform:t];
    }
    
    [context render:img toMTLTexture:[drawable texture] commandBuffer:commandBuffer bounds:bounds colorSpace:cs];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end
