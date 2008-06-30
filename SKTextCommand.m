//
//  SKTextCommand.m
//  Skim
//
//  Created by Christiaan Hofman on 6/4/08.
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

#import "SKTextCommand.h"
#import <Quartz/Quartz.h>
#import "SKPDFDocument.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"


@implementation SKTextCommand

- (id)performDefaultImplementation {
    id dP = [self directParameter];
    id dPO = nil;
    if ([dP isKindOfClass:[NSArray class]] == NO)
        dPO = [dP objectsByEvaluatingSpecifier];
    
    NSDictionary *args = [self evaluatedArguments];
    PDFPage *page = [args objectForKey:@"Page"];
    NSTextStorage *textStorage = nil;
    NSAttributedString *attrString = nil;
    
    if ([dPO isKindOfClass:[SKPDFDocument class]]) {
        attrString = page ? [page attributedString] : [[[dPO pdfDocument] selectionForEntireDocument] attributedString];
    } else if ([dPO isKindOfClass:[PDFPage class]]) {
        if (page == nil || [page isEqual:dPO])
            textStorage = [dPO richText];
    } else if ([dPO isKindOfClass:[PDFAnnotation class]]) {
        if (page == nil || [page isEqual:[dPO page]])
            textStorage = [dPO textContents];
    } else {
        attrString = [[PDFSelection selectionWithSpecifier:dP onPage:page] attributedString];
    }
    
    return textStorage ? textStorage : attrString ? [[[NSTextStorage alloc] initWithAttributedString:attrString] autorelease] : [[[NSTextStorage alloc] init] autorelease];
}

@end
