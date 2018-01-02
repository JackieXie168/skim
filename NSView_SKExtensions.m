//
//  NSView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 9/17/07.
/*
 This software is Copyright (c) 2007-2018
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

#import "NSView_SKExtensions.h"
#import "SKLineWell.h"
#import "SKFontWell.h"


#if SDK_BEFORE(10_6)
typedef NS_OPTIONS(unsigned long long, NSAlignmentOptions) {
    NSAlignMinXInward   = 1ULL << 0,
    NSAlignMinYInward   = 1ULL << 1,
    NSAlignMaxXInward   = 1ULL << 2,
    NSAlignMaxYInward   = 1ULL << 3,
    NSAlignWidthInward  = 1ULL << 4,
    NSAlignHeightInward = 1ULL << 5,
    
    NSAlignMinXOutward   = 1ULL << 8,
    NSAlignMinYOutward   = 1ULL << 9,
    NSAlignMaxXOutward   = 1ULL << 10,
    NSAlignMaxYOutward   = 1ULL << 11,
    NSAlignWidthOutward  = 1ULL << 12,
    NSAlignHeightOutward = 1ULL << 13,
    
    NSAlignMinXNearest   = 1ULL << 16,
    NSAlignMinYNearest   = 1ULL << 17,
    NSAlignMaxXNearest   = 1ULL << 18,
    NSAlignMaxYNearest   = 1ULL << 19,
    NSAlignWidthNearest  = 1ULL << 20,
    NSAlignHeightNearest = 1ULL << 21,
    
    NSAlignRectFlipped = 1ULL << 63,
    
    NSAlignAllEdgesInward = NSAlignMinXInward|NSAlignMaxXInward|NSAlignMinYInward|NSAlignMaxYInward,
    NSAlignAllEdgesOutward = NSAlignMinXOutward|NSAlignMaxXOutward|NSAlignMinYOutward|NSAlignMaxYOutward,
    NSAlignAllEdgesNearest = NSAlignMinXNearest|NSAlignMaxXNearest|NSAlignMinYNearest|NSAlignMaxYNearest,
};
@interface NSView (SKLionDeclarations)
- (NSSize)convertSizeToBacking:(NSSize)size;
@end
#endif

@implementation NSView (SKExtensions)

- (id)subviewOfClass:(Class)aClass {
	if ([self isKindOfClass:aClass])
		return self;
	
	NSView *view;
	
	for (NSView *subview in [self subviews]) {
		if ((view = [subview subviewOfClass:aClass]))
			return view;
	}
	return nil;
}

- (void)deactivateWellSubcontrols {
    [[self subviews] makeObjectsPerformSelector:_cmd];
}

- (SKFontWell *)activeFontWell {
	SKFontWell *fontWell;
    for (NSView *subview in [self subviews]) {
        if ((fontWell = [subview activeFontWell]))
            return fontWell;
    }
    return nil;
}

- (CGFloat)backingScale {
    if ([self respondsToSelector:@selector(convertSizeToBacking:)])
        return [self convertSizeToBacking:NSMakeSize(1.0, 1.0)].width;
    return 1.0;
}

- (NSRect)convertRectToScreen:(NSRect)rect {
    rect = [self convertRect:rect toView:nil];
    rect.origin = [[self window] convertBaseToScreen:rect.origin];
    return rect;
}

@end


@interface NSColorWell (SKNSViewExtensions)
@end

@implementation NSColorWell (SKNSViewExtensions)

- (void)deactivateWellSubcontrols {
    [self deactivate];
    [super deactivateWellSubcontrols];
}

@end


@interface SKLineWell (SKNSViewExtensions)
@end

@implementation SKLineWell (SKNSViewExtensions)

- (void)deactivateWellSubcontrols {
    [self deactivate];
    [super deactivateWellSubcontrols];
}

@end


@interface SKFontWell (SKNSViewExtensions)
@end

@implementation SKFontWell (SKNSViewExtensions)

- (void)deactivateWellSubcontrols {
    [self deactivate];
    [super deactivateWellSubcontrols];
}

- (SKFontWell *)activeFontWell {
    if ([self isActive])
        return self;
    return [super activeFontWell];
}

@end
