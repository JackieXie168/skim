//
//  BDSKSheetController.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 7/23/06.
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

#import "BDSKSheetController.h"


@implementation BDSKSheetController

#pragma mark Run modal dialog

- (int)runModal {
	[self prepare];
	
	runAppModal = YES;
	
	[[self window] makeKeyAndOrderFront:self];
	int returnCode = [NSApp runModalForWindow:[self window]];
	[[self window] orderOut:self];
	
	return returnCode;
}

#pragma mark Begin/run modal sheet

- (void)beginSheetModalForWindow:(NSWindow *)window {
	[self beginSheetModalForWindow:window modalDelegate:nil didEndSelector:NULL didDismissSelector:NULL contextInfo:NULL];
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo {
	[self beginSheetModalForWindow:window modalDelegate:delegate didEndSelector:didEndSelector didDismissSelector:NULL contextInfo:contextInfo];
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector didDismissSelector:(SEL)didDismissSelector contextInfo:(void *)contextInfo {
	[self prepare];
	
	runAppModal = NO;
    theModalDelegate = delegate;
	theDidEndSelector = didEndSelector;
	theDidDismissSelector = didDismissSelector;
    theContextInfo = contextInfo;
	
	[self retain]; // make sure we stay around long enough
	
	[NSApp beginSheet:[self window]
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:NULL];
}

- (int)runSheetModalForWindow:(NSWindow *)window {
	return [self runSheetModalForWindow:window modalDelegate:nil didEndSelector:NULL didDismissSelector:NULL contextInfo:NULL];
}

- (int)runSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo {
	return [self runSheetModalForWindow:window modalDelegate:delegate didEndSelector:didEndSelector didDismissSelector:NULL contextInfo:contextInfo];
}

- (int)runSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector didDismissSelector:(SEL)didDismissSelector contextInfo:(void *)contextInfo {
	[self prepare];
	
	runAppModal = YES;
    theModalDelegate = delegate;
	theDidEndSelector = didEndSelector;
	theDidDismissSelector = didDismissSelector;
    theContextInfo = contextInfo;
	
	[NSApp beginSheet:[self window]
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:NULL];
	int returnCode = [NSApp runModalForWindow:[self window]];
    [self endSheetWithReturnCode:returnCode];
	return returnCode;
}

#pragma mark Prepare, dismiss and end the sheet

- (void)prepare {}

- (IBAction)dismiss:(id)sender {
	int returnCode = [sender tag];
	if (runAppModal) {
		[NSApp stopModalWithCode:returnCode];
	} else {
        [self endSheetWithReturnCode:returnCode];
        [self release];
	}
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if(theModalDelegate != nil && theDidEndSelector != NULL){
		NSMethodSignature *signature = [theModalDelegate methodSignatureForSelector:theDidEndSelector];
        NSAssert2(nil != signature, @"%@ does not implement %@", theModalDelegate, NSStringFromSelector(theDidEndSelector));
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:theDidEndSelector];
		[invocation setArgument:&self atIndex:2];
		[invocation setArgument:&returnCode atIndex:3];
		[invocation setArgument:&theContextInfo atIndex:4];
		[invocation invokeWithTarget:theModalDelegate];
	}
}

- (void)endSheetWithReturnCode:(int)returnCode {
    [NSApp endSheet:[self window] returnCode:returnCode];
    [[self window] orderOut:self];
    
	if(theModalDelegate != nil && theDidDismissSelector != NULL){
		NSMethodSignature *signature = [theModalDelegate methodSignatureForSelector:theDidDismissSelector];
        NSAssert2(nil != signature, @"%@ does not implement %@", theModalDelegate, NSStringFromSelector(theDidDismissSelector));
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:theDidDismissSelector];
		[invocation setArgument:&self atIndex:2];
		[invocation setArgument:&returnCode atIndex:3];
		[invocation setArgument:&theContextInfo atIndex:4];
		[invocation invokeWithTarget:theModalDelegate];
	}
    
    theModalDelegate = nil;
    theDidEndSelector = NULL;
    theDidDismissSelector = NULL;
    theContextInfo = NULL;
}

@end
