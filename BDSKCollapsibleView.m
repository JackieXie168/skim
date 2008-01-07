//
//  BDSKCollapsibleView.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 27/11/05.
/*
 This software is Copyright (c) 2005-2008
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

#import "BDSKCollapsibleView.h"


@implementation BDSKCollapsibleView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		collapseEdges = BDSKMinXEdgeMask | BDSKMinYEdgeMask;
		minSize = NSZeroSize;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		collapseEdges = [decoder decodeIntForKey:@"collapseEdges"];
		minSize.width = [decoder decodeFloatForKey:@"minSize.width"];
		minSize.height = [decoder decodeFloatForKey:@"minSize.height"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:collapseEdges forKey:@"collapseEdges"];
  [coder encodeFloat:minSize.width forKey:@"minSize.width"];
  [coder encodeFloat:minSize.height forKey:@"minSize.height"];
  // NSView should handle encoding of contentView as it is a subview
}

- (NSSize)minSize {
	return minSize;
}

- (void)setMinSize:(NSSize)size {
	minSize = size;
}

- (int)collapseEdges {
	return collapseEdges;
}

- (void)setCollapseEdges:(int)mask {
	if (mask != collapseEdges) {
		collapseEdges = mask;
		[contentView setFrame:[self contentRect]];
		[self setNeedsDisplay:YES];
	}
}

- (NSRect)contentRect {
	NSRect rect = [self bounds];
	if (rect.size.width < minSize.width) {
		if (collapseEdges & BDSKMinXEdgeMask)
			rect.origin.x -= minSize.width - NSWidth(rect);
		rect.size.width = minSize.width;
	}
	if (rect.size.height < minSize.height) {
		if (collapseEdges & BDSKMinYEdgeMask)
			rect.origin.y -= minSize.height - NSHeight(rect);
		rect.size.height = minSize.height;
	}
	return rect;
}

@end
