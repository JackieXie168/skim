//
//  BDSKContainerView.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/12/06.
/*
 This software is Copyright (c) 2006
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

#import "BDSKContainerView.h"


@implementation BDSKContainerView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		contentView = [[NSView alloc] initWithFrame:[self contentRect]];
		[super addSubview:contentView];
		[contentView release];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		if ([[super subviews] count]) { // not sure if this works OK, but we're not using it now as IB calls initWithFrame
			[self setContentView:[[super subviews] objectAtIndex:0]];
		} else {
			contentView = [[NSView alloc] initWithFrame:[self contentRect]];
			[super addSubview:contentView];
			[contentView release];
		}
	}
	return self;
}

- (id)contentView {
	return contentView;
}

- (void)setContentView:(NSView *)aView {
	if (aView != contentView) {
		[contentView removeFromSuperview];
		[super addSubview:aView]; // replaceSubview:with: does not work, as it calls [self addSubview:]
		contentView = aView;
		[contentView setFrame:[self contentRect]];
		[self setNeedsDisplay:YES];
	}
}

- (NSRect)contentRect {
	return [self bounds];
}

- (void)resizeSubviewsWithOldSize:(NSSize)size {
	[contentView setFrame:[self contentRect]];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
	[super resizeWithOldSuperviewSize:oldSize];
	[contentView setFrame:[self contentRect]];
}

- (void)addSubview:(NSView *)aView {
	[contentView addSubview:aView];
}

- (void)addSubview:(NSView *)aView positioned:(NSWindowOrderingMode)place relativeTo:(NSView *)otherView {
	[contentView addSubview:aView positioned:place relativeTo:otherView];
}

- (void)replaceSubview:(NSView *)aView with:(NSView *)newView {
	[contentView replaceSubview:aView with:newView];
}

@end
