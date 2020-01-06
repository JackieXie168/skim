//
//  PDFOutline_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 9/4/09.
/*
 This software is Copyright (c) 2009-2020
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

#import "PDFOutline_SKExtensions.h"
#import "PDFPage_SKExtensions.h"


@interface PDFOutline (SKPrivateDeclarations)
- (void)setDocument:(PDFDocument *)document;
@end

@implementation PDFOutline (SKExtensions)

- (PDFPage *)page {
    PDFDestination *dest = [self destination];
    if (dest == nil && [[self action] respondsToSelector:@selector(destination)])
        dest = [(PDFActionGoTo *)[self action] destination];
    return [dest page];
}

- (NSString *)pageLabel {
    PDFPage *page = [self page];
    if (page)
        return [page displayLabel];
    else if ([[self action] respondsToSelector:@selector(pageIndex)])
        return [NSString stringWithFormat:@"%lu", (unsigned long)([(PDFActionRemoteGoTo *)[self action] pageIndex] + 1)];
    else
        return nil;
}

// on 10.12 the document is not weakly linked, so we need to clear it to avoid a retain cycle
- (void)clearDocument {
    if ([self respondsToSelector:@selector(setDocument:)] == NO || RUNNING(10_12))
        return;
    NSUInteger i, iMax = [self numberOfChildren];
    for (i = 0; i < iMax; i++)
         [[self childAtIndex:i] clearDocument];
    [self setDocument:nil];
}

@end
