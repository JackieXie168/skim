//
//  SKTextFieldSheetController.m
//  Skim
//
//  Created by Christiaan Hofman on 9/29/08.
/*
 This software is Copyright (c) 2008-2019
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

#if SDK_BEFORE(10_12)
@interface NSButton (SKSierraDeclarations)
- (NSButton *)buttonWithTitle:(NSString *)title image:(NSImage *)image target:(id)target action:(SEL)action;
@end
#endif

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

- (NSString *)touchBarItemIdentifier {
    return [@"SKTouchBarItemIdentifier" stringByAppendingString:[self windowNibName]];
}

- (NSTouchBar *)touchBar {
    if (touchBar == nil) {
        touchBar = [[NSClassFromString(@"NSTouchBar") alloc] init];
        [touchBar setDelegate:self];
        [touchBar setDefaultItemIdentifiers:[NSArray arrayWithObjects:[self touchBarItemIdentifier], nil]];
    }
    return touchBar;
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)aTouchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier {
    NSCustomTouchBarItem *item = nil;
    if ([identifier isEqualToString:[self touchBarItemIdentifier]]) {
        NSView *buttonGroup = [[[NSView alloc] initWithFrame:NSZeroRect] autorelease];
        NSMutableArray *constraints = [NSMutableArray array];
        NSMutableArray *buttonCopies = [NSMutableArray arrayWithCapacity:[buttons count]];
        NSUInteger i, iMax = [buttons count];
        
        for (i = 0; i < iMax; i++) {
            NSButton *button = [buttons objectAtIndex:iMax - 1 - i];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
            NSButton *buttonCopy = [NSButton buttonWithTitle:[button title] target:[button target] action:[button action]];
#pragma clang diagnostic pop
            [buttonCopy setTag:[button tag]];
            [buttonCopy setEnabled:[button isEnabled]];
            
            [buttonCopy setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            [buttonCopies addObject:buttonCopy];
            [buttonGroup addSubview:buttonCopy];
            
            // Custom layout is used for equal width buttons, to look more keyboard-like and mimic standard alerts
            // https://github.com/sparkle-project/Sparkle/pull/987#issuecomment-272324726
            [constraints addObject:[NSLayoutConstraint constraintWithItem:buttonCopy attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:buttonGroup attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
            [constraints addObject:[NSLayoutConstraint constraintWithItem:buttonCopy attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:buttonGroup attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
            if (i == 0) {
                [constraints addObject:[NSLayoutConstraint constraintWithItem:buttonCopy attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:buttonGroup attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
            } else {
                [constraints addObject:[NSLayoutConstraint constraintWithItem:buttonCopy attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:[buttonCopies objectAtIndex:i - 1] attribute:NSLayoutAttributeLeading multiplier:1.0 constant:(i == 1) ? -8 : -32]];
                [constraints addObject:[NSLayoutConstraint constraintWithItem:buttonCopy attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:[buttonCopies objectAtIndex:i - 1] attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
                [[constraints lastObject] setPriority:250];
            }
            if (i == [buttons count] - 1) {
                [constraints addObject:[NSLayoutConstraint constraintWithItem:buttonCopy attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:buttonGroup attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
            }
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
        [NSLayoutConstraint activateConstraints:constraints];
#pragma clang diagnostic pop
        item = [[[NSClassFromString(@"NSCustomTouchBarItem") alloc] initWithIdentifier:identifier] autorelease];
        [(NSCustomTouchBarItem *)item setView:buttonGroup];
    }
    return item;
}

@end
