//
//  NSAnimationContext_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 11/15/14.
/*
 This software is Copyright (c)2014-2017
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

#import "NSAnimationContext_SKExtensions.h"
#import "SKRuntime.h"


@implementation NSAnimationContext (SKExtensions)

+ (void)performCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

+ (void)SnowLeopard_runAnimationGroup:(void (^)(NSAnimationContext *context))changes completionHandler:(void (^)(void))completionHandler {
    [self beginGrouping];
    NSAnimationContext *context = [self currentContext];
    changes(context);
    NSTimeInterval duration = [context duration];
    [self endGrouping];
    if (completionHandler)
        [self performSelector:@selector(performCompletionHandler:) withObject:[[completionHandler copy] autorelease] afterDelay:duration];
}

+ (void)load {
    SKAddClassMethodImplementationFromSelector(self, @selector(runAnimationGroup:completionHandler:), @selector(SnowLeopard_runAnimationGroup:completionHandler:));
}

@end
