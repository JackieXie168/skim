//
//  SKTextFieldSheetController.m
//  Skim
//
//  Created by Christiaan Hofman on 9/29/08.
/*
 This software is Copyright (c) 2008-2014
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

#import "SKTextFieldSheetController.h"
#import "NSGraphics_SKExtensions.h"


@implementation SKTextFieldSheetController

@synthesize textField, labelFields, controls, buttons;
@dynamic stringValue;

- (void)dealloc {
    SKDESTROY(textField);
    SKDESTROY(labelFields);
    SKDESTROY(controls);
    SKDESTROY(buttons);
    [super dealloc];
}

- (void)windowDidLoad {
    NSButton *cancelButton = [buttons lastObject];
    CGFloat buttonMargin = NSWidth([[cancelButton superview] bounds]) - NSMaxX([[buttons objectAtIndex:0] frame]);
    SKAutoSizeButtons(buttons, YES);
    if (NSMinX([cancelButton frame]) < buttonMargin)
        SKResizeWindow([self window], buttonMargin - NSMinX([cancelButton frame]));
    SKAutoSizeLabelFields(labelFields, controls, YES);
}

- (NSTextField *)textField {
    [self window];
    return textField;
}

- (NSString *)stringValue {
    return [[self textField] stringValue];
}

- (void)setStringValue:(NSString *)string {
    [[self textField] setStringValue:string];
}

@end
