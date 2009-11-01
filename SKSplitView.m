//
//  SKSplitView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
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

#import "SKSplitView.h"


@implementation SKSplitView

- (id)initWithCoder:(NSCoder *)coder{
    if (self = [super initWithCoder:coder]) {
        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_5 && [self dividerStyle] == NSSplitViewDividerStyleThick)
            [self setDividerStyle:3]; // NSSplitViewDividerStylePaneSplitter
    }
    return self;
}

- (void)drawDividerInRect:(NSRect)aRect {
	if ([self dividerStyle] == NSSplitViewDividerStyleThick) {
        NSRect topRect, bottomRect, innerRect;
        NSDivideRect(aRect, &topRect, &innerRect, 1.0, NSMaxYEdge);
        NSDivideRect(innerRect, &bottomRect, &innerRect, 1.0, NSMinYEdge);
        
        [NSGraphicsContext saveGraphicsState];
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.98 alpha:1.0] endingColor:[NSColor colorWithDeviceWhite:0.91 alpha:1.0]] autorelease];
        [gradient drawInRect:innerRect angle:90.0];
        [[NSColor colorWithDeviceWhite:0.69 alpha:1.0] setFill];
        NSRectFill(topRect);
        NSRectFill(bottomRect);
        [NSGraphicsContext restoreGraphicsState];
    }
    [super drawDividerInRect:aRect];
}

- (CGFloat)dividerThickness {
	if ([self dividerStyle] == NSSplitViewDividerStyleThick)
        return 10.0;
    return [super dividerThickness];
}

@end
