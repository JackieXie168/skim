//
//  BDSKBackgroundView.m
//  BibDesk
//
//  Created by Christiaan Hofman on 26/2/05.
/*
 This software is Copyright (c) 2005
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

#import "BDSKBackgroundView.h"

@implementation BDSKBackgroundView
- (void)drawRect:(NSRect)rect
{
	float blur = 4.0;
	float offset = 2.0;
	NSSize size = [self bounds].size;
	NSRect viewRect = NSMakeRect(blur, blur + offset, size.width - 2 * blur, size.height - blur - offset);
	NSShadow *viewShadow = [[[NSShadow alloc] init] autorelease];
	[viewShadow setShadowOffset:NSMakeSize(0.0, - offset)];
	[viewShadow setShadowBlurRadius:blur];
	[viewShadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.6]];
	
	[NSGraphicsContext saveGraphicsState];
	[viewShadow set];
 	[[[NSColor controlBackgroundColor] colorWithAlphaComponent:0.9] set]; // this is the white control background
	[NSBezierPath fillRect:viewRect];
	[NSGraphicsContext restoreGraphicsState];
	
	[super drawRect:rect];
}
@end
