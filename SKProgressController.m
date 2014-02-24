//
//  SKProgressController.m
//  Skim
//
//  Created by Christiaan Hofman on 9/16/07.
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

#import "SKProgressController.h"
#import "SKApplication.h"
#import "NSWindowController_SKExtensions.h"


@implementation SKProgressController

@synthesize progressBar, progressField;
@dynamic message, indeterminate, maxValue, doubleValue;

- (void)dealloc {
    SKDESTROY(progressBar);
    SKDESTROY(progressField);
    [super dealloc];
}

- (NSString *)windowNibName { 
    return @"ProgressSheet";
}

- (void)windowDidLoad {
    [progressBar setUsesThreadedAnimation:YES];
}

- (NSProgressIndicator *)progressBar {
    [self window];
    return progressBar;
}

- (NSString *)message {
    [self window];
    return [progressField stringValue];
}

- (void)setMessage:(NSString *)newMessage {
    [self window];
    [progressField setStringValue:newMessage];
    [[self window] setTitle:newMessage];
}

- (BOOL)isIndeterminate {
    return [[self progressBar] isIndeterminate];
}

- (void)setIndeterminate:(BOOL)flag {
    [[self progressBar] setIndeterminate:flag];
}

- (double)maxValue {
    return [[self progressBar] maxValue];
}

- (void)setMaxValue:(double)newMaximum {
    [[self progressBar] setMaxValue:newMaximum];
    [[self progressBar] setDoubleValue:0.0];
}

- (double)doubleValue {
    return [[self progressBar] doubleValue];
}

- (void)setDoubleValue:(double)doubleValue {
    [[self progressBar] setDoubleValue:doubleValue];
    [[self progressBar] displayIfNeeded];
}

- (void)incrementBy:(double)delta {
    [[self progressBar] incrementBy:delta];
    [[self progressBar] displayIfNeeded];
}

- (void)beginSheetModalForWindow:(NSWindow *)window completionHandler:(void (^)(NSInteger result))handler {
    [[self progressBar] startAnimation:self];
    [(SKApplication *)NSApp setUserAttentionDisabled:YES];
    [super beginSheetModalForWindow:window completionHandler:handler];
    [(SKApplication *)NSApp setUserAttentionDisabled:NO];
}

- (IBAction)dismissSheet:(id)sender {
    [[self progressBar] stopAnimation:self];
    [super dismissSheet:sender];
}

@end
