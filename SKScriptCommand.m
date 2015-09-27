//
//  SKScriptCommand.m
//  Skim
//
//  Created by Christiaan Hofman on 11/26/10.
/*
 This software is Copyright (c) 2008-2015
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

#import "SKScriptCommand.h"


@implementation SKScriptCommand

// Workaround for Cocoa Scripting and AppleScript bugs.
// Cocoa Scripting does not accept range specifiers whose start/end specifier have an absolute container specifier, but AppleScript does not accept range specifiers with relative container specifiers, so we cannot return those from PDFSelection
- (void)fixRangeSpecifiers:(id)object {
    if ([object isKindOfClass:[NSArray class]]) {
        for (id subobject in (NSArray *)object)
            [self fixRangeSpecifiers:subobject];
    } else if ([object isKindOfClass:[NSScriptObjectSpecifier class]]) {
        [self fixRangeSpecifiers:[(NSScriptObjectSpecifier *)object containerSpecifier]];
        if ([object isKindOfClass:[NSRangeSpecifier class]]) {
            NSScriptObjectSpecifier *childSpec = [(NSRangeSpecifier *)object startSpecifier];
            if ([childSpec containerSpecifier]) {
                [childSpec setContainerSpecifier:nil];
                [childSpec setContainerIsRangeContainerObject:YES];
            }
            childSpec = [(NSRangeSpecifier *)object endSpecifier];
            if ([childSpec containerSpecifier]) {
                [childSpec setContainerSpecifier:nil];
                [childSpec setContainerIsRangeContainerObject:YES];
            }
        }
    }
}

- (void)setReceiversSpecifier:(NSScriptObjectSpecifier *)receiversSpec {
    [self fixRangeSpecifiers:receiversSpec];
    [super setReceiversSpecifier:receiversSpec];
}

- (void)setArguments:(NSDictionary *)args {
    [self fixRangeSpecifiers:[args allValues]];
    [super setArguments:args];
}

- (void)setDirectParameter:(id)directParameter {
    [self fixRangeSpecifiers:directParameter];
    [super setDirectParameter:directParameter];
}

@end
