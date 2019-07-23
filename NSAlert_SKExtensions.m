//
//  NSAlert_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 23/07/2019.
/*
 This software is Copyright (c) 2019
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

#import "NSAlert_SKExtensions.h"
#import "SKRuntime.h"

@implementation NSAlert (SKExtensions)

- (void)didEndAlert:(NSAlert *)alert returnCode:(NSInteger)returnCode completionHandler:(void *)contextInfo {
    if (contextInfo != NULL) {
        void (^handler)(NSInteger) = (void(^)(NSInteger))contextInfo;
        handler(returnCode);
        Block_release(handler);
    }
}

- (void)fallback_beginSheetModalForWindow:(NSWindow *)window completionHandler:(void (^)(NSInteger result))handler {
    [self beginSheetModalForWindow:window
                     modalDelegate:handler ? self : nil
                    didEndSelector:handler ? @selector(didEndAlert:returnCode:completionHandler:) : NULL
                       contextInfo:handler ? Block_copy(handler) : NULL];
}

+ (void)load {
    SKAddInstanceMethodImplementationFromSelector(self, @selector(beginSheetModalForWindow:completionHandler:), @selector(fallback_beginSheetModalForWindow:completionHandler:));
}

@end
