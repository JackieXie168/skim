//
//  SKPDFOutline.m
//  Skim
//
//  Created by Christiaan Hofman on 11/9/08.
//  Created by Christiaan Hofman on 9/11/08.
/*
 This software is Copyright (c) 2008
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

#import "SKPDFOutline.h"


@implementation SKPDFOutline


- (id)initWithOutline:(PDFOutline *)anOutline parent:(SKPDFOutline *)aParent {
    if (self = [super init]) {
        if (anOutline) {
            outline = [anOutline retain];
            parent = aParent;
            children = nil;
        } else {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void)dealloc {
    [outline release];
    [children release];
    [super dealloc];
}

- (PDFDocument *)document {
    return [outline document];
}

- (SKPDFOutline *)parent {
    return parent;
}

- (unsigned int)numberOfChildren {
    return [outline numberOfChildren];
}

- (SKPDFOutline *)childAtIndex:(unsigned int)anIndex {
    if (children == nil) {
        int i, count = [outline numberOfChildren];
        children = [[NSMutableArray alloc] initWithCapacity:count];
        for (i = 0; i < count; i++) {
            SKPDFOutline *child = [[SKPDFOutline alloc] initWithOutline:[outline childAtIndex:i] parent:self];
            [children addObject:child];
            [child release];
        }
    }
    return [children objectAtIndex:anIndex];
}

- (NSString *)label {
    return [outline label];
}

- (PDFDestination *)destination {
    return [outline destination];
}

- (PDFAction *)action {
    if ([outline respondsToSelector:_cmd])
        return [outline action];
    else
        return nil;
}

- (PDFPage *)page {
    if ([outline respondsToSelector:@selector(destination)])
        return [[outline destination] page];
    else if ([outline respondsToSelector:@selector(action)] && [[outline action] respondsToSelector:@selector(destination)])
        return [[(PDFActionGoTo *)[outline action] destination] page];
    else
        return nil;
}

- (BOOL)isOpen {
    if ([outline respondsToSelector:_cmd])
        return [outline isOpen];
    else
        return [parent parent] == nil && [parent numberOfChildren] == 1;
}

@end
