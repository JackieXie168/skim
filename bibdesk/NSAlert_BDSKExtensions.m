//
//  NSAlert_BDSKExtensions.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 11/16/05.
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

#import "NSAlert_BDSKExtensions.h"
#import <OmniBase/assertions.h>

@interface NSAlert (PrivateBDSKExtensions)
- (void)didEndAlertSheet:(id)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
// from private NSAlert API
- (void)prepare;
@end

@implementation NSAlert (BDSKExtensions)

- (int)runSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector didDismissSelector:(SEL)didDismissSelector contextInfo:(void *)contextInfo
{
	if([self respondsToSelector:@selector(prepare)])
        [self prepare];
    else
        NSLog(@"NSAlert no longer responds to -prepare.");
	
    _modalDelegate = delegate;
	_didEndSelector = didEndSelector;
	_didDismissSelector = didDismissSelector;
    
    NSPanel *panel = [self valueForKey:@"panel"];
    OBASSERT(panel);
	
	[NSApp beginSheet:panel
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:@selector(didEndAlertSheet:returnCode:contextInfo:)
		  contextInfo:contextInfo];
	int returnCode = [NSApp runModalForWindow:panel];
	
	if(_modalDelegate != nil && _didEndSelector != NULL){
		NSMethodSignature *signature = [_modalDelegate methodSignatureForSelector:_didEndSelector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:_didEndSelector];
		[invocation setArgument:&panel atIndex:2];
		[invocation setArgument:&returnCode atIndex:3];
		[invocation setArgument:&contextInfo atIndex:4];
		[invocation invokeWithTarget:_modalDelegate];
	}
	
	[NSApp endSheet:panel];
	[panel orderOut:self];
	
	if(_modalDelegate != nil && _didDismissSelector != NULL){
		NSMethodSignature *signature = [_modalDelegate methodSignatureForSelector:_didDismissSelector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:_didDismissSelector];
		[invocation setArgument:&panel atIndex:2];
		[invocation setArgument:&returnCode atIndex:3];
		[invocation setArgument:&contextInfo atIndex:4];
		[invocation invokeWithTarget:_modalDelegate];
	}
	
    _modalDelegate = nil;
	_didEndSelector = NULL;
	_didDismissSelector = NULL;
	
	return returnCode;
}

- (void)didEndAlertSheet:(id)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp stopModalWithCode:returnCode];
}

@end
