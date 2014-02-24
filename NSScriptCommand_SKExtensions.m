//
//  NSScriptCommand_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 11/26/10.
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

#import "NSScriptCommand_SKExtensions.h"
#import "SKRuntime.h"


@implementation NSScriptCommand (SKExtensions)

// Workaround for Cocoa Scripting and AppleScript bugs.
// Cocoa Scripting does not accept range specifiers whose start/end specifier have an absolute container specifier, but AppleScript does not accept range specifiers with relative container specifiers, so we cannot return those from PDFSselection
static void fixRangeSpecifier(NSScriptObjectSpecifier *specifier) {
    if ([specifier isKindOfClass:[NSRangeSpecifier class]]) {
        NSScriptObjectSpecifier *childSpec = [(NSRangeSpecifier *)specifier startSpecifier];
        if ([childSpec containerSpecifier]) {
            [childSpec setContainerSpecifier:nil];
            [childSpec setContainerIsRangeContainerObject:YES];
        }
        childSpec = [(NSRangeSpecifier *)specifier endSpecifier];
        if ([childSpec containerSpecifier]) {
            [childSpec setContainerSpecifier:nil];
            [childSpec setContainerIsRangeContainerObject:YES];
        }
    }
}

static void (*original_setReceiversSpecifier)(id, SEL, id) = NULL;
static void (*original_setArguments)(id, SEL, id) = NULL;
static void (*original_setDirectParameter)(id, SEL, id) = NULL;

- (void)replacement_setReceiversSpecifier:(NSScriptObjectSpecifier *)receiversSpec {
    fixRangeSpecifier(receiversSpec);
    original_setReceiversSpecifier(self, _cmd, receiversSpec);
}

- (void)replacement_setArguments:(NSDictionary *)args {
    for (NSString *key in args)
        fixRangeSpecifier([args objectForKey:key]);
    original_setArguments(self, _cmd, args);
}

- (void)replacement_setDirectParameter:(id)directParameter {
    fixRangeSpecifier(directParameter);
    original_setDirectParameter(self, _cmd, directParameter);
}

+ (void)load {
    original_setReceiversSpecifier = (void (*)(id, SEL, id))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(setReceiversSpecifier:), @selector(replacement_setReceiversSpecifier:));
    original_setArguments = (void (*)(id, SEL, id))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(setArguments:), @selector(replacement_setArguments:));
    original_setDirectParameter = (void (*)(id, SEL, id))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(setDirectParameter:), @selector(replacement_setDirectParameter:));
}

@end
