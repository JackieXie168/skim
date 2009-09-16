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
#import "NSGeometry_SKExtensions.h"
#include <unistd.h>
#import <Quartz/Quartz.h>

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
    CGSTransitionOption option; // add 1<<7 for a transparent background
    CGSWindow wid; // Can be 0 for full-screen
    float *backColour; // Null for black otherwise pointer to 3 float array with RGB value
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

@interface SKTransitionWindow : NSWindow {
    CALayer *imageLayer;
    BOOL animating;
}
- (void)setImage:(CGImageRef)newImage;
- (void)setImage:(CGImageRef)newImage inRect:(NSRect)rect;
- (void)animateImage:(CGImageRef)newImage usingFilter:(CIFilter *)newFilter duration:(NSTimeInterval)newDuration;
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
        transitionWindow = [[SKTransitionWindow alloc] init];
        view = aView; // don't retain as it may retain us
        transitionStyle = SKNoTransition;
        duration = 1.0;
        shouldRestrict = YES;
        currentTransitionStyle = SKNoTransition;
        currentDuration = 1.0;
        currentShouldRestrict = YES;
    }
    return self;
}

- (void)dealloc {
    [transitionWindow release];
    [initialBitmap release];
    [filters release];
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
        NSBitmapImageRep *shadingBitmap = [[NSBitmapImageRep alloc] initWithData:shadingBitmapData];
        inputShadingImage = [[CIImage alloc] initWithBitmapImageRep:shadingBitmap];
        [shadingBitmap release];
    }
    return inputShadingImage;
}

- (CIImage *)inputMaskImage {
    static CIImage *inputMaskImage = nil;
    if (inputMaskImage == nil) {
        NSData *maskBitmapData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TransitionMask" ofType:@"jpg"]];
        NSBitmapImageRep *maskBitmap = [[NSBitmapImageRep alloc] initWithData:maskBitmapData];
        inputMaskImage = [[CIImage alloc] initWithBitmapImageRep:maskBitmap];
        [maskBitmap release];
    }
    return inputMaskImage;
}

- (CIImage *)translateImage:(CIImage *)image by:(NSPoint)distance {
    CIFilter *translationFilter = [self filterWithName:@"CIAffineTransform"];
    NSAffineTransform *affineTransform = [NSAffineTransform transform];
    [affineTransform translateXBy:distance.x yBy:distance.y];
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

- (CIImage *)cropImage:(CIImage *)image toRect:(NSRect)rect {
    CIFilter *cropFilter = [self filterWithName:@"CICrop"];
    [cropFilter setValue:[CIVector vectorWithX:NSMinX(rect) Y:NSMinY(rect) Z:NSWidth(rect) W:NSHeight(rect)] forKey:@"inputRectangle"];
    [cropFilter setValue:image forKey:kCIInputImageKey];
    return [cropFilter valueForKey:kCIOutputImageKey];
}

- (CIFilter *)transitionFilterForRect:(NSRect)rect forward:(BOOL)forward {
    NSString *filterName = [[[self class] transitionFilterNames] objectAtIndex:currentTransitionStyle - SKCoreImageTransition];
    CIFilter *transitionFilter = [self filterWithName:filterName];
    
    NSEnumerator *keyEnum = [[transitionFilter inputKeys] objectEnumerator];
    NSString *key;
    
    while (key = [keyEnum nextObject]) {
        id value = nil;
        if ([key isEqualToString:kCIInputCenterKey]) {
            value = [CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)];
        } else if ([key isEqualToString:kCIInputAngleKey]) {
            CGFloat angle = forward ? 0.0 : M_PI;
            if ([filterName isEqualToString:@"CIPageCurlTransition"])
                angle = forward ? -M_PI_4 : -3.0 * M_PI_4;
            value = [NSNumber numberWithDouble:angle];
        } else if ([key isEqualToString:kCIInputShadingImageKey]) {
            value = [self inputShadingImage];
        } else if ([key isEqualToString:@"inputBacksideImage"]) {
            value = [[[CIImage alloc] initWithBitmapImageRep:initialBitmap] autorelease];
            if (currentShouldRestrict == NO)
                value = [self cropImage:value toRect:rect];
            else if (NSEqualPoints(rect.origin, NSZeroPoint) == NO)
                value = [self translateImage:value by:rect.origin];
        } else if ([key isEqualToString:kCIInputImageKey] == NO && [key isEqualToString:kCIInputTargetImageKey] == NO &&
                   [[[[transitionFilter attributes] objectForKey:key] objectForKey:kCIAttributeClass] isEqualToString:@"CIImage"]) {
            // Scale and translate our mask image to match the transition area size.
            value = [self scaleImage:[self inputMaskImage] toSize:rect.size];
            if (NSEqualPoints(rect.origin, NSZeroPoint) == NO)
                value = [self translateImage:value by:rect.origin];
        } else continue;
        [transitionFilter setValue:value forKey:key];
    }
    return transitionFilter;
}

- (NSBitmapImageRep *)newCurrentBitmap {
    NSRect bounds = [view bounds];
    NSBitmapImageRep *contentBitmap = [view bitmapImageRepForCachingDisplayInRect:bounds];
    
    [contentBitmap clear];
    [view cacheDisplayInRect:bounds toBitmapImageRep:contentBitmap];
    
    return [contentBitmap retain];
}

- (NSBitmapImageRep *)copyBitmap:(NSBitmapImageRep *)bitmap croppedToRect:(NSRect)rect {
    CIImage *image = [[CIImage alloc] initWithBitmapImageRep:bitmap];
    NSBitmapImageRep *croppedBitmap = [[NSBitmapImageRep alloc] initWithCIImage:[self cropImage:image toRect:rect]];
    [image release];
    return croppedBitmap;
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
        [initialBitmap release];
        initialBitmap = [self newCurrentBitmap];
        // We don't want the window to draw the next state before the animation is run
        [[view window] disableFlushWindow];
	} else if (currentTransitionStyle > SKNoTransition && CoreGraphicsServicesTransitionsDefined()) {
        if (currentShouldRestrict) {
            [initialBitmap release];
            initialBitmap = [self newCurrentBitmap];
        }
        // We don't want the window to draw the next state before the animation is run
        [[view window] disableFlushWindow];
    }
    imageRect = rect;
}

- (void)animateCoreImageForRect:(NSRect)rect forward:(BOOL)forward {
    if (initialBitmap == nil)
        [self prepareAnimationForRect:rect];
    
    imageRect = NSIntegralRect(NSIntersectionRect(NSUnionRect(imageRect, rect), [view bounds]));
    
    NSBitmapImageRep *finalBitmap = [self newCurrentBitmap];
    
    if (currentShouldRestrict) {
        NSBitmapImageRep *tmpBitmap = initialBitmap;
        initialBitmap = [self copyBitmap:tmpBitmap croppedToRect:imageRect];
        [tmpBitmap release];
        tmpBitmap = finalBitmap;
        finalBitmap = [self copyBitmap:tmpBitmap croppedToRect:imageRect];
        [tmpBitmap release];
    }
    
    CIFilter *transitionFilter = [self transitionFilterForRect:imageRect forward:forward];
    NSRect frame = [view convertRect:[view frame] toView:nil];
    frame.origin = [[view window] convertBaseToScreen:frame.origin];
    
    [transitionWindow setFrame:frame display:NO];
    [transitionWindow setImage:[initialBitmap CGImage] inRect:(currentShouldRestrict ? imageRect : [view bounds])];
    [transitionWindow orderBack:nil];
    [[view window] addChildWindow:transitionWindow ordered:NSWindowAbove];
    
    [transitionWindow animateImage:[finalBitmap CGImage] usingFilter:transitionFilter duration:currentDuration];
    
    // Update the view and its window, so it shows the correct state when it is shown.
    [view display];
    // Remember we disabled flushing in the previous method, we need to balance that.
    [[view window] enableFlushWindow];
    [[view window] flushWindow];
    
    [[view window] removeChildWindow:transitionWindow];
    [transitionWindow orderOut:nil];
    [transitionWindow setImage:nil];
    [finalBitmap release];
}

- (void)animateCoreGraphicsForRect:(NSRect)rect forward:(BOOL)forward {
    NSBitmapImageRep *finalBitmap = nil;
    NSWindow *window = [view window];
    
    if (currentShouldRestrict) {
        if (initialBitmap == nil)
            [self prepareAnimationForRect:rect];
        
        imageRect = NSIntegralRect(NSIntersectionRect(NSUnionRect(imageRect, rect), [view bounds]));
        
        NSBitmapImageRep *tmpBitmap = initialBitmap;
        initialBitmap = [self copyBitmap:tmpBitmap croppedToRect:rect];
        [tmpBitmap release];
        tmpBitmap = [self newCurrentBitmap];
        finalBitmap = [self copyBitmap:tmpBitmap croppedToRect:rect];
        [tmpBitmap release];
        
        NSRect frame = [view convertRect:imageRect toView:nil];
        frame.origin = [[view window] convertBaseToScreen:frame.origin];
        
        [transitionWindow setFrame:frame display:NO];
        imageRect.origin = NSZeroPoint;
        [transitionWindow setImage:[initialBitmap CGImage] inRect:imageRect];
        [transitionWindow orderBack:nil];
        [[view window] addChildWindow:transitionWindow ordered:NSWindowAbove];
        
        window = transitionWindow;
    }
    
    // declare our variables  
    int handle = -1;
    CGSTransitionSpec spec;
    // specify our specifications
    spec.unknown1 = 0;
    spec.type =  currentTransitionStyle;
    spec.option = forward ? CGSLeft : CGSRight;
    spec.backColour = NULL;
    spec.wid = [window windowNumber];
    
    // Let's get a connection
    CGSConnection cgs = _CGSDefaultConnection();
    
    // Create a transition
    CGSNewTransition(cgs, &spec, &handle);
    
    if (currentShouldRestrict) {
        [transitionWindow setImage:[finalBitmap CGImage]];
        [transitionWindow display];
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
        [[view window] removeChildWindow:transitionWindow];
        [transitionWindow orderOut:nil];
        [transitionWindow setImage:nil];
        [finalBitmap release];
    }
}

- (void)animateForRect:(NSRect)rect forward:(BOOL)forward {
	if (currentTransitionStyle >= SKCoreImageTransition)
        [self animateCoreImageForRect:rect forward:forward];
    else if (currentTransitionStyle > SKNoTransition && CoreGraphicsServicesTransitionsDefined())
        [self animateCoreGraphicsForRect:rect forward:forward];
    
    [initialBitmap release];
    initialBitmap = nil;
    
    currentTransitionStyle = transitionStyle;
    currentDuration = duration;
    currentShouldRestrict = shouldRestrict;
}

@end

#pragma mark -

@implementation SKTransitionWindow

- (id)init {
    if (self = [super initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO]) {
        [self setReleasedWhenClosed:NO];
        [self setIgnoresMouseEvents:YES];
        
        CALayer *rootLayer = [CALayer layer];
        CGColorRef color = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
        
        [rootLayer setBackgroundColor:color];
        CGColorRelease(color);
        
        [[self contentView] setLayer:rootLayer];
        [[self contentView] setWantsLayer:YES];
        
        imageLayer = [CALayer layer];
        [imageLayer setBounds:[rootLayer bounds]];
        [imageLayer setPosition:[rootLayer position]];
        [imageLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
        [rootLayer addSublayer:imageLayer];
        
        animating = NO;
    }
    return self;
}

- (BOOL)canBecomeMainWindow { return NO; }
- (BOOL)canBecomeKeyWindow { return NO; }

- (void)setImage:(CGImageRef)newImage {
    [self setImage:newImage inRect:NSZeroRect];
}

- (void)setImage:(CGImageRef)newImage inRect:(NSRect)rect {
    [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
    [imageLayer setContents:(id)newImage];
    if (NSEqualRects(rect, NSZeroRect) == NO)
        [imageLayer setFrame:NSRectToCGRect(rect)];
    [[self contentView] setNeedsDisplay:YES];
    [CATransaction setValue:[NSNumber numberWithBool:NO] forKey:kCATransactionDisableActions];
}

- (void)animateImage:(CGImageRef)newImage usingFilter:(CIFilter *)newFilter duration:(NSTimeInterval)newDuration {
    CATransition *transition = [CATransition animation];
    [transition setFilter:newFilter];
    [transition setDuration:newDuration];
    [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [transition setDelegate:self];
    animating = YES;
    [imageLayer addAnimation:transition forKey:@"imageTransition"];
    NSDate *limitDate = [NSDate dateWithTimeIntervalSinceNow:1.0 + 2.0 * newDuration];
    [imageLayer setContents:(id)newImage];
    while (animating && [limitDate compare:[NSDate date]] != NSOrderedAscending)
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantPast]];
    animating = NO;
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    animating = NO;
}

@end
