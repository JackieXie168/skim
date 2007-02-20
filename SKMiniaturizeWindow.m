//
//  SKMiniaturizeWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKMiniaturizeWindow.h"


@implementation SKMiniaturizeWindow

- (id)initWithContentRect:(NSRect)contentRect image:(NSImage *)image {
    if (self = [self initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO]) {
        [self setReleasedWhenClosed:NO];
        [self setLevel:NSFloatingWindowLevel];
        
        NSImageView *imageView = [[NSImageView alloc] init];
        [imageView setImage:image];
        [imageView setImageFrameStyle:NSImageFrameNone];
        [self setContentView:imageView];
        [imageView release];
    }
    return self;
}

- (BOOL)canBecomeMainWindow { return NO; }

- (BOOL)canBecomeKeyWindow { return NO; }

- (NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame {
    return 0.6 * [super animationResizeTime:newWindowFrame];
}

@end
