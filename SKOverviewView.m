//
//  SKOverviewView.m
//  Skim
//
//  Created by Christiaan Hofman on 20/03/2020.
/*
This software is Copyright (c) 2020
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

#import "SKOverviewView.h"
#import "SKTypeSelectHelper.h"
#import "NSEvent_SKExtensions.h"
#import "SKApplication.h"


@implementation SKOverviewView

@synthesize singleClickAction, doubleClickAction, typeSelectHelper;

- (void)dealloc {
    SKDESTROY(typeSelectHelper);
    [super dealloc];
}

- (void)keyDown:(NSEvent *)theEvent {
    unichar eventChar = [theEvent firstCharacter];
    
    if ((eventChar == NSNewlineCharacter || eventChar == NSEnterCharacter || eventChar == NSCarriageReturnCharacter) && [theEvent deviceIndependentModifierFlags] == 0 && [self doubleClickAction]) {
        [self tryToPerform:[self doubleClickAction] with:self];
    } else if (eventChar == 'p' && [theEvent deviceIndependentModifierFlags] == 0 && [self singleClickAction]) {
        [self tryToPerform:[self singleClickAction] with:self];
    } else if ([typeSelectHelper handleEvent:theEvent] == NO) {
        [super keyDown:theEvent];
    }
}

- (void)mouseDown:(NSEvent *)theEvent {
    SEL action = [theEvent clickCount] == 1 ? [self singleClickAction] : [theEvent clickCount] == 2 ? [self doubleClickAction] : NULL;
    
    if (action && [NSApp willDragMouse])
        action = NULL;
    
    [super mouseDown:theEvent];
    
    if (action)
        [self tryToPerform:action with:self];
}

@end
