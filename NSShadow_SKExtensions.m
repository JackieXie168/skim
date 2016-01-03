//
//  NSShadow_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 1/12/15.
/*
 This software is Copyright (c) 2015-2016
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

#import "NSShadow_SKExtensions.h"


@implementation NSShadow (SKExtensions)

static CGFloat currentScale = 1.0;

+ (CGFloat)currentScale {
    return currentScale;
}

+ (void)setCurrentScale:(CGFloat)newScale {
    currentScale = newScale;
}

+ (void)setShadowWithColor:(NSColor *)color blurRadius:(CGFloat)blurRadius offset:(NSSize)offset {
    blurRadius *= [self currentScale];
    offset.width *= [self currentScale];
    offset.height *= [self currentScale];
    NSShadow *aShadow = [[self alloc] init];
    [aShadow setShadowColor:color];
    [aShadow setShadowBlurRadius:blurRadius];
    [aShadow setShadowOffset:offset];
    [aShadow set];
    [aShadow release];
}

+ (void)setShadowWithColor:(NSColor *)color blurRadius:(CGFloat)blurRadius yOffset:(CGFloat)yOffset {
    [self setShadowWithColor:color blurRadius:blurRadius offset:NSMakeSize(0.0, yOffset)];
}

@end
