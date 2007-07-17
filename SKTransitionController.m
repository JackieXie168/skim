//
//  SKTransitionController.m
//  Skim
//
//  Created by Christiaan Hofman on 7/15/07.
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
 
/*
 This code is based partly on Apple's AnimatingTabView example code
 and Ankur Kothari's AnimatingTabsDemo application <http://dev.lipidity.com>
*/

#import "SKTransitionController.h"
#import <Quartz/Quartz.h>
#import "NSBitmapImageRep_SKExtensions.h"
#include <unistd.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import "SKFullScreenWindow.h"


@interface SKTransitionAnimation : NSAnimation {
    CIFilter *filter;
}

- (id)initWithFilter:(CIFilter *)aFilter duration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve;
- (CIImage *)currentImage;

@end

#pragma mark -

@interface SKTransitionView : NSOpenGLView {
    SKTransitionAnimation *animation;
    CIContext *context;
    BOOL needsReshape;
}
- (SKTransitionAnimation *)animation;
- (void)setAnimation:(SKTransitionAnimation *)newAnimation;
@end

#pragma mark -

@implementation SKTransitionController

- (id)initWithView:(NSView *)aView {
    if (self = [super init]) {
        view = aView;
    }
    return self;
}

- (void)dealloc {
    [transitionWindow release];
    [initialImage release];
    [super dealloc];
}

- (NSView *)view {
    return view;
}

- (void)setView:(NSView *)newView {
    view = newView;
}

- (CIFilter *)filterWithName:(NSString *)name {
    static NSMutableDictionary *filters = nil;
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

- (CIFilter *)transitionFilter:(SKAnimationTransitionStyle)transitionStyle forRect:(NSRect)rect inBounds:(NSRect)bounds initialCIImage:(CIImage *)initialCIImage finalCIImage:(CIImage *)finalCIImage {
    CIFilter *transitionFilter = nil;
    
    switch (transitionStyle) {
        case SKCopyMachineTransition:
            transitionFilter = [self filterWithName:@"CICopyMachineTransition"];
            [transitionFilter setValue:[CIVector vectorWithX:NSMinX(rect) Y:NSMinY(rect) Z:NSWidth(rect) W:NSHeight(rect)] forKey:@"inputExtent"];
            break;
            
        case SKDisintegrateTransition:
        {
            transitionFilter = [self filterWithName:@"CIDisintegrateWithMaskTransition"];
            
            // Scale and translate our mask image to match the transition area size.
            CIFilter *maskScalingFilter = [self filterWithName:@"CILanczosScaleTransform"];
            CGRect maskExtent = [[self inputMaskImage] extent];
            float xScale = NSWidth(rect) / CGRectGetWidth(maskExtent);
            float yScale = NSHeight(rect) / CGRectGetHeight(maskExtent);
            [maskScalingFilter setValue:[NSNumber numberWithFloat:yScale] forKey:@"inputScale"];
            [maskScalingFilter setValue:[NSNumber numberWithFloat:xScale / yScale] forKey:@"inputAspectRatio"];
            [maskScalingFilter setValue:[self inputMaskImage] forKey:@"inputImage"];
            CIFilter *maskTranslationFilter = [self filterWithName:@"CIAffineTransform"];
            NSAffineTransform *affineTransform = [NSAffineTransform transform];
            [affineTransform translateXBy:NSMinX(rect) - NSMinX(bounds) yBy:NSMinY(rect) - NSMinY(bounds)];
            [maskTranslationFilter setValue:affineTransform forKey:@"inputTransform"];
            [maskTranslationFilter setValue:[maskScalingFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
            
            [transitionFilter setValue:[maskTranslationFilter valueForKey:@"outputImage"] forKey:@"inputMaskImage"];
            break;
        }
        case SKDissolveTransition:
            transitionFilter = [self filterWithName:@"CIDissolveTransition"];
            break;
            
        case SKFlashTransition:
            transitionFilter = [self filterWithName:@"CIFlashTransition"];
            [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
            [transitionFilter setValue:[CIVector vectorWithX:NSMinX(bounds) Y:NSMinY(bounds) Z:NSWidth(bounds) W:NSHeight(bounds)] forKey:@"inputExtent"];
            break;
            
        case SKModTransition:
            transitionFilter = [self filterWithName:@"CIModTransition"];
            [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
            break;
            
        case SKPageCurlTransition:
            transitionFilter = [self filterWithName:@"CIPageCurlTransition"];
            [transitionFilter setValue:[NSNumber numberWithFloat:-M_PI_4] forKey:@"inputAngle"];
            [transitionFilter setValue:initialCIImage forKey:@"inputBacksideImage"];
            [transitionFilter setValue:[self inputShadingImage] forKey:@"inputShadingImage"];
            [transitionFilter setValue:[CIVector vectorWithX:NSMinX(rect) Y:NSMinY(rect) Z:NSWidth(rect) W:NSHeight(rect)] forKey:@"inputExtent"];
            break;
            
        case SKSwipeTransition:
            transitionFilter = [self filterWithName:@"CISwipeTransition"];
            [transitionFilter setValue:[CIVector vectorWithX:NSMinX(rect) Y:NSMinY(rect) Z:NSWidth(rect) W:NSHeight(rect)] forKey:@"inputExtent"];
            break;
            
        case SKRippleTransition:
        default:
            transitionFilter = [self filterWithName:@"CIRippleTransition"];
            [transitionFilter setValue:[CIVector vectorWithX:NSMidX(rect) Y:NSMidY(rect)] forKey:@"inputCenter"];
            [transitionFilter setValue:[CIVector vectorWithX:NSMinX(bounds) Y:NSMinY(bounds) Z:NSWidth(bounds) W:NSHeight(bounds)] forKey:@"inputExtent"];
            [transitionFilter setValue:[self inputShadingImage] forKey:@"inputShadingImage"];
            break;
    }
    
    if (NSEqualRects(rect, bounds) == NO) {
        CIFilter *cropFilter = [self filterWithName:@"CICrop"];
        [cropFilter setValue:[CIVector vectorWithX:NSMinX(rect) Y:NSMinY(rect) Z:NSWidth(rect) W:NSHeight(rect)] forKey:@"inputRectangle"];
        [cropFilter setValue:initialCIImage forKey:@"inputImage"];
        initialCIImage = [cropFilter valueForKey:@"outputImage"];
        [cropFilter setValue:finalCIImage forKey:@"inputImage"];
        finalCIImage = [cropFilter valueForKey:@"outputImage"];
    }
    
    [transitionFilter setValue:initialCIImage forKey:@"inputImage"];
    [transitionFilter setValue:finalCIImage forKey:@"inputTargetImage"];
    
    return transitionFilter;
}

- (void)prepareForAnimationWithTransitionStyle:(SKAnimationTransitionStyle)transitionStyle fromRect:(NSRect)rect {
	if (transitionStyle >= SKCopyMachineTransition) {
        NSRect bounds = [view bounds];
        [initialImage release];
        NSBitmapImageRep *initialContentBitmap = [view bitmapImageRepForCachingDisplayInRect:bounds];
        [initialContentBitmap clear];
        [view cacheDisplayInRect:bounds toBitmapImageRep:initialContentBitmap];
        initialImage = [[CIImage alloc] initWithBitmapImageRep:initialContentBitmap];
        imageRect = rect;
        
        // We don't want the window to draw the next state before the animation is run
        [[view window] disableFlushWindow];
    }
}

- (void)animateWithTransitionStyle:(SKAnimationTransitionStyle)transitionStyle direction:(CGSTransitionOption)direction duration:(float)duration fromRect:(NSRect)rect {
	if (transitionStyle == SKNoTransition) {

	} else if (transitionStyle < SKCopyMachineTransition) {
        
        // declare our variables  
        int handle = -1;
        CGSTransitionSpec spec;
        
        // specify our specifications
        spec.unknown1 = 0;
        spec.type =  transitionStyle;
        spec.option = direction;
        spec.backColour = NULL;
        spec.wid = [[view window] windowNumber];
        
        // Let’s get a connection
        CGSConnection cgs = _CGSDefaultConnection();
        
        // Create a transition
        CGSNewTransition(cgs, &spec, &handle);
        
        // Redraw the window
        [[view window] display];
        
        CGSInvokeTransition(cgs, handle, duration);
        // We need to wait for the transition to finish before we get rid of it, otherwise we’ll get all sorts of nasty errors... or maybe not.
        usleep((useconds_t)(duration * 1000000));
        
        CGSReleaseTransition(cgs, handle);
        handle = 0;
		
	} else {
        
        if (initialImage == nil)
            [self prepareForAnimationWithTransitionStyle:transitionStyle fromRect:rect];
        NSRect bounds = [view bounds];
        imageRect = NSIntersectionRect(NSUnionRect(imageRect, rect), bounds);
        
        NSBitmapImageRep *finalContentBitmap = [view bitmapImageRepForCachingDisplayInRect:bounds];
        [finalContentBitmap clear];
        [view cacheDisplayInRect:bounds toBitmapImageRep:finalContentBitmap];
        CIImage *finalImage = [[CIImage alloc] initWithBitmapImageRep:finalContentBitmap];
        
        CIFilter *transitionFilter = [self transitionFilter:transitionStyle forRect:imageRect inBounds:[view bounds] initialCIImage:initialImage finalCIImage:finalImage];
        
        [finalImage release];
        [initialImage release];
        initialImage = nil;
        
        NSWindow *window = [view window];
        NSRect frame = [view convertRect:[view frame] toView:nil];
        frame.origin = [window convertBaseToScreen:frame.origin];
        
        if (transitionWindow == nil) {
            transitionWindow = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[window screen]];
            [transitionWindow setReleasedWhenClosed:NO];
            [transitionWindow setDisplaysWhenScreenProfileChanges:YES];
            [transitionWindow setIgnoresMouseEvents:YES];
            
            transitionView = [[SKTransitionView alloc] init];
            [transitionWindow setContentView:transitionView];
            [transitionView release];
        }
        
        SKTransitionAnimation *animation = [[SKTransitionAnimation alloc] initWithFilter:transitionFilter duration:duration animationCurve:NSAnimationEaseInOut];
        
        [transitionView setAnimation:animation];
        [animation release];
        
        [transitionWindow setFrame:frame display:NO];
        [transitionWindow orderBack:nil];
        [window addChildWindow:transitionWindow ordered:NSWindowAbove];
        
        [animation startAnimation];
        
        // Update the view and its window, so it shows the correct state when it is shown.
        [view display];
        // Remember we disabled flushing in the previous method, we need to balance that.
        [[view window] enableFlushWindow];
        [[view window] flushWindow];
        
        [window removeChildWindow:transitionWindow];
        [transitionWindow orderOut:nil];
        [transitionView setAnimation:nil];
        
    }
}

@end

#pragma mark -

@implementation SKTransitionAnimation

- (id)initWithFilter:(CIFilter *)aFilter duration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve {
    if (self = [super initWithDuration:duration animationCurve:animationCurve]) {
        filter = [aFilter retain];
    }
    return self;
}

- (void)dealloc {
    [filter release];
    [super dealloc];
}

- (void)setCurrentProgress:(NSAnimationProgress)progress {
    [filter setValue:[NSNumber numberWithFloat:[self currentValue]] forKey:@"inputTime"];
    [super setCurrentProgress:progress];
    [[self delegate] display];
}

- (CIImage *)currentImage {
    return [filter valueForKey:@"outputImage"];
}

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
    [animation release];
    [context release];
    [super dealloc];
}

- (void)reshape	{
    needsReshape = YES;
}

- (void)prepareOpenGL {
    // Enable beam-synced updates.
    long parm = 1;
    [[self openGLContext] setValues:&parm forParameter:NSOpenGLCPSwapInterval];
    
    // Make sure that everything we don't need is disabled. Some of these
    //are enabled by default and can slow down rendering.
    
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

- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bounds];
    
    [[self openGLContext] makeCurrentContext];
    
    if (needsReshape) {
        // reset the views coordinate system when the view has been resized or scrolled
        
        glViewport (0, 0, NSWidth(bounds), NSHeight(bounds));

        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(NSMinX(bounds), NSMaxX(bounds), NSMinY(bounds), NSMaxY(bounds), -1, 1);

        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        needsReshape = NO;
    }
    
    glColor4f(0.0f, 0.0f, 0.0f, 0.0f);
    glBegin(GL_POLYGON);
        glVertex2f(NSMinX(rect), NSMinY(rect));
        glVertex2f(NSMaxX(rect), NSMinY(rect));
        glVertex2f(NSMaxX(rect), NSMaxY(rect));
        glVertex2f(NSMinX(rect), NSMaxY(rect));
    glEnd();
    
    if (animation) {
        
        if (context == nil) {
            NSOpenGLPixelFormat *pf = [self pixelFormat];
            if (pf == nil)
                pf = [[self class] defaultPixelFormat];
            context = [[CIContext contextWithCGLContext:CGLGetCurrentContext() pixelFormat:[pf CGLPixelFormatObj] options:nil] retain];
        }
        
        [context drawImage:[animation currentImage] inRect:*(CGRect*)&bounds fromRect:*(CGRect*)&bounds];
        
    }
    
    glFlush();
}

@end
