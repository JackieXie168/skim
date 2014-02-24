//
//  SKFindTableView.m
//  Skim
//
//  Created by Christiaan Hofman on 7/28/07.
/*
 This software is Copyright (c) 2007-2014
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

#import "SKFindTableView.h"
#import "NSEvent_SKExtensions.h"

#define PAGE_COLUMNID @"page"

@implementation SKFindTableView

- (void)awakeFromNib {
    [[[self tableColumnWithIdentifier:PAGE_COLUMNID] headerCell] setTitle:NSLocalizedString(@"Page", @"Table header title")];
}

- (void)keyDown:(NSEvent *)theEvent {
    unichar eventChar = [theEvent firstCharacter];
	NSUInteger modifierFlags = [theEvent standardModifierFlags];
    
	if (eventChar == NSLeftArrowFunctionKey && modifierFlags == 0) {
        if ([[self delegate] respondsToSelector:@selector(tableViewMoveLeft:)])
            [[self delegate] tableViewMoveLeft:self];
    } else if (eventChar == NSRightArrowFunctionKey && modifierFlags == 0) {
        if ([[self delegate] respondsToSelector:@selector(tableViewMoveRight:)])
            [[self delegate] tableViewMoveRight:self];
    } else {
        [super keyDown:theEvent];
    }
}

- (id <SKFindTableViewDelegate>)delegate { return (id <SKFindTableViewDelegate>)[super delegate]; }
- (void)setDelegate:(id <SKFindTableViewDelegate>)newDelegate { [super setDelegate:newDelegate]; }

@end
