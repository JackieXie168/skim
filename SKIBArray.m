//
//  SKIBArray.m
//  Skim
//
//  Created by Christiaan on 3/18/10.
/*
 This software is Copyright (c) 2010
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

#import "SKIBArray.h"


@implementation SKIBArray

@dynamic object1, object2, object3, object4, object5, object6, object7, object8, object9;

#define DEFINE_ACCESSORS(i) \
- (id)object##i { return object[i-1]; } \
- (void)setObject##i:(id)obj { \
    if (object[i-1] != obj) { \
        [object[i-1] release]; \
        object[i-1] = [obj retain]; \
    } \
}

DEFINE_ACCESSORS(1)
DEFINE_ACCESSORS(2)
DEFINE_ACCESSORS(3)
DEFINE_ACCESSORS(4)
DEFINE_ACCESSORS(5)
DEFINE_ACCESSORS(6)
DEFINE_ACCESSORS(7)
DEFINE_ACCESSORS(8)
DEFINE_ACCESSORS(9)

- (void)dealloc {
    SKDESTROY(object[0]);
    SKDESTROY(object[1]);
    SKDESTROY(object[2]);
    SKDESTROY(object[3]);
    SKDESTROY(object[4]);
    SKDESTROY(object[5]);
    SKDESTROY(object[6]);
    SKDESTROY(object[7]);
    SKDESTROY(object[8]);
    [super dealloc];
}

- (NSUInteger)count {
    NSUInteger i;
    for (i = 0; i < 9; i++)
        if (object[i] == nil) break;
    return i;
}

- (id)objectAtIndex:(NSUInteger)anIndex {
    return object[anIndex];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
    enum { ATSTART = 0, ATEND = 1 };
    if (state->state == ATSTART) {
        static const unsigned long const_mu = 1;
        state->state = ATEND;
        state->itemsPtr = object;
        state->mutationsPtr = (unsigned long *)&const_mu;
        return [self count];
    }
    return 0;
}

@end
