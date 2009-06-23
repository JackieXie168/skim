//
//  SKSheetController.m
//  Skim
//
//  Created by Christiaan Hofman on 9/21/07.
/*
 This software is Copyright (c) 2007-2009
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

#import "SKSheetController.h"
#import "NSInvocation_SKExtensions.h"


typedef struct _SKCallbackInfo {
    id delegate;
	SEL selector;
    void *contextInfo;
} SKCallbackInfo;


@implementation SKSheetController

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo {
	[self prepare];
	
    SKCallbackInfo *info = (SKCallbackInfo *)NSZoneMalloc(NSDefaultMallocZone(), sizeof(SKCallbackInfo));
    info->delegate = delegate;
	info->selector = didEndSelector;
    info->contextInfo = contextInfo;
	
	[self retain]; // make sure we stay around long enough
	
	[NSApp beginSheet:[self window]
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:info];
}

- (void)prepare {}

- (IBAction)dismiss:(id)sender {
	[self endSheetWithReturnCode:[sender tag]];
    [self release];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	SKCallbackInfo *info = (SKCallbackInfo *)contextInfo;
    if(info->delegate != nil && info->selector != NULL){
		NSInvocation *invocation = [NSInvocation invocationWithTarget:info->delegate selector:info->selector argument:&self];
		[invocation setArgument:&returnCode atIndex:3];
		[invocation setArgument:&(info->contextInfo) atIndex:4];
		[invocation invoke];
	}
    NSZoneFree(NSDefaultMallocZone(), info);
}

- (void)endSheetWithReturnCode:(NSInteger)returnCode {
    [NSApp endSheet:[self window] returnCode:returnCode];
    [[self window] orderOut:self];
}

@end
