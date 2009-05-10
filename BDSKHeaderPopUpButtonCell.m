//
//  BDSKHeaderPopUpButtonCell.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/23/05.
/*
 This software is Copyright (c) 2005-2009-2008
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

#import "BDSKHeaderPopUpButtonCell.h"
#import "NSImage_SKExtensions.h"

@implementation BDSKHeaderPopUpButtonCell

- (id)initTextCell:(NSString *)stringValue pullsDown:(BOOL)pullDown {
	if ([super initTextCell:@"" pullsDown:NO]) {
		[self setBordered:NO];
		[self setEnabled:YES];
		[self setUsesItemFromMenu:YES];
		[self setRefusesFirstResponder:YES];
	}
	return self;
}

- (NSSize)cellSize {
	NSSize size = [super cellSize];
	size.width -= 22.0 + 2 * [self controlSize];
	return size;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect bgRect, divRect, srcRect = NSMakeRect(0.0, 0.0, 1.0, 15.0);
    NSDivideRect(cellFrame, &divRect, &bgRect, 1.0, NSMaxXEdge);
    [[NSImage imageNamed:@"Scroller_Background"] drawFlipped:[controlView isFlipped] inRect:bgRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0];
    [[NSImage imageNamed:@"Scroller_Divider"] drawFlipped:[controlView isFlipped] inRect:divRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0];
    [super drawWithFrame:cellFrame inView:controlView];
}    

@end
