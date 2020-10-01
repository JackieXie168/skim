//
//  SKSideViewController.m
//  Skim
//
//  Created by Christiaan Hofman on 3/28/10.
/*
 This software is Copyright (c) 2010-2020
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

#import "SKSideViewController.h"
#import "SKImageToolTipWindow.h"
#import "SKTopBarView.h"
#import "SKImageToolTipWindow.h"
#import "NSGeometry_SKExtensions.h"
#import "SKStringConstants.h"

#define TOPBAR_MIN_WIDTH 100.0

#define DURATION 0.7

@implementation SKSideViewController

@synthesize mainController, topBar, button, alternateButton, searchField, currentView;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    mainController = nil;
    SKDESTROY(topBar);
    SKDESTROY(button);
    SKDESTROY(alternateButton);
    SKDESTROY(searchField);
    SKDESTROY(currentView);
    [super dealloc];
}

- (void)loadView {
    [super loadView];
    
    [topBar setHasSeparator:YES];
    [topBar setMinSize:NSMakeSize(TOPBAR_MIN_WIDTH, NSHeight([topBar contentRect]))];
}

- (void)setMainController:(SKMainWindowController *)newMainController {
    if (mainController && newMainController == nil) {
        [[self topBar] reflectView:nil animate:NO];
    }
    mainController = newMainController;
}

#pragma mark View animation

- (BOOL)requiresAlternateButtonForView:(NSView *)aView {
    return NO;
}

- (void)replaceSideView:(NSView *)newView animate:(BOOL)animate {
    if ([newView superview] != nil)
        return;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey] ||
        [currentView window] == nil)
        animate = NO;
    
    NSView *oldView = [[currentView retain] autorelease];
    self.currentView = newView;
    
    BOOL wasAlternate = [self requiresAlternateButtonForView:oldView];
    BOOL isAlternate = [self requiresAlternateButtonForView:newView];
    BOOL changeButton = wasAlternate != isAlternate;
    NSSegmentedControl *oldButton = wasAlternate ? alternateButton : button;
    NSSegmentedControl *newButton = isAlternate ? alternateButton : button;
    NSView *buttonView = [oldButton superview];
    NSView *contentView = [oldView superview];
    id firstResponder = [[oldView window] firstResponder];
    
    if ([firstResponder isDescendantOf:oldView])
        firstResponder = newView;
    else if (wasAlternate != isAlternate && [firstResponder isEqual:oldButton])
        firstResponder = newButton;
    else
        firstResponder = nil;

    [[SKImageToolTipWindow sharedToolTipWindow] orderOut:self];
    
    if (changeButton)
        [newButton setFrame:[oldButton frame]];
    [newView setFrame:[oldView frame]];
    
    if (animate == NO) {
        [contentView replaceSubview:oldView with:newView];
        if (changeButton)
            [[oldButton superview] replaceSubview:oldButton with:newButton];
        [[firstResponder window] makeFirstResponder:firstResponder];
        [[contentView window] recalculateKeyViewLoop];
        [[self topBar] reflectView:newView animate:NO];
    } else {
        isAnimating = YES;
        
        BOOL hasLayer = YES;
        
        if (RUNNING_AFTER(10_13)) {
            hasLayer = [[self view] wantsLayer] || [[self view] layer] != nil;
            if (hasLayer == NO) {
                [[self view] setWantsLayer:YES];
                [[self view] displayIfNeeded];
            }
        } else {
            hasLayer = [contentView wantsLayer] || [contentView layer] != nil;
            if (hasLayer == NO) {
                [contentView setWantsLayer:YES];
                [contentView displayIfNeeded];
                if (changeButton) {
                    [buttonView setWantsLayer:YES];
                    [buttonView displayIfNeeded];
                }
            }
        }
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                [context setDuration:DURATION]; 
                [[contentView animator] replaceSubview:oldView with:newView];
                [[self topBar] reflectView:newView animate:YES];
                if (changeButton)
                    [[buttonView animator] replaceSubview:oldButton with:newButton];
            }
            completionHandler:^{
                if (hasLayer == NO) {
                    if (RUNNING_AFTER(10_13)) {
                        [[self view] setWantsLayer:NO];
                    } else {
                        [contentView setWantsLayer:NO];
                        if (changeButton)
                            [buttonView setWantsLayer:NO];
                    }
                }
                [[firstResponder window] makeFirstResponder:firstResponder];
                [[contentView window] recalculateKeyViewLoop];
                isAnimating = NO;
        }];
    }
}

@end
