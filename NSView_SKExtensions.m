//
//  NSView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 9/17/07.
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

#import "NSView_SKExtensions.h"
#import "SKLineWell.h"
#import "SKFontWell.h"


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

- (void)deactivateColorWellSubcontrols {
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
    return [[self window] convertRectToScreen:[self convertRect:rect toView:nil]];
}

- (NSRect)convertRectFromScreen:(NSRect)rect {
    return [self convertRect:[[self window] convertRectFromScreen:rect] fromView:nil];
}

- (NSPoint)convertPointToScreen:(NSPoint)point {
    NSRect rect = NSZeroRect;
    rect.origin = [self convertPoint:point toView:nil];
    return [[self window] convertRectToScreen:rect].origin;
}

- (NSPoint)convertPointFromScreen:(NSPoint)point {
    NSRect rect = NSZeroRect;
    rect.origin = point;
    return [self convertPoint:[[self window] convertRectFromScreen:rect].origin fromView:nil];
}

- (NSBitmapImageRep *)bitmapImageRepCachingDisplayInRect:(NSRect)rect {
    NSBitmapImageRep *imageRep = [self bitmapImageRepForCachingDisplayInRect:rect];
    [self cacheDisplayInRect:rect toBitmapImageRep:imageRep];
    return imageRep;
}

@end


@interface NSColorWell (SKNSViewExtensions)
@end

@implementation NSColorWell (SKNSViewExtensions)

- (void)deactivateWellSubcontrols {
    [self deactivate];
    [super deactivateWellSubcontrols];
}

- (void)deactivateColorWellSubcontrols {
    [self deactivate];
    [super deactivateColorWellSubcontrols];
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
