//
//  SKFieldEditor.m
//  Skim
//
//  Created by Christiaan Hofman on 4/6/06.
/*
 This software is Copyright (c) 2005-2014
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

#import "SKFieldEditor.h"


@implementation SKFieldEditor

- (void)dealloc {
    SKDESTROY(ignoredSelectors);
    [super dealloc];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if (ignoredSelectors && NSHashGet(ignoredSelectors, aSelector) != NULL)
        return NO;
    return [super respondsToSelector:aSelector];
}

- (void)ignoreSelectors:(SEL)aSelector, ... {
    if (aSelector) {
        if (ignoredSelectors)
            NSResetHashTable(ignoredSelectors);
        else
            ignoredSelectors = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 0);
        NSHashInsert(ignoredSelectors, aSelector);
        va_list selectorList;
        SEL nextSelector;
        va_start(selectorList, aSelector);
        while ((nextSelector = va_arg(selectorList, SEL)))
            NSHashInsert(ignoredSelectors, nextSelector);
        va_end(selectorList);
    } else {
        SKDESTROY(ignoredSelectors);
    }
}

@end
