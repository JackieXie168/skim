//
//  NSTableHeaderView_BDSKExtensions.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 21/11/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "NSTableHeaderView_BDSKExtensions.h"
#import <OmniBase/OBUtilities.h>


@implementation NSTableHeaderView (BDSKExtensions)

static IMP originalMouseDown;

+ (void)didLoad {
    originalMouseDown = OBReplaceMethodImplementationWithSelector(self, @selector(mouseDown:), @selector(replacementMouseDown:));
}

- (void)replacementMouseDown:(NSEvent *)theEvent{
    // mouseDown in the table header has peculiar behavior for a double-click if you use -[NSTableView setDoubleAction:] on the
    // tableview itself.  The header sends a double-click action to the tableview row/cell that's selected.  
    // Since none of Apple's apps does this, we'll follow suit and just resort.
    if([theEvent clickCount] > 1)
        theEvent = [NSEvent mouseEventWithType:[theEvent type]
                                      location:[theEvent locationInWindow]
                                 modifierFlags:[theEvent modifierFlags]
                                     timestamp:[theEvent timestamp]
                                  windowNumber:[theEvent windowNumber]
                                       context:[theEvent context]
                                   eventNumber:[theEvent eventNumber]
                                    clickCount:1
                                      pressure:[theEvent pressure]];
	originalMouseDown(self, _cmd, theEvent);
}

@end
