//
//  SKSelectCommand.m
//  Skim
//
//  Created by Christiaan Hofman on 4/8/11.
/*
 This software is Copyright (c) 2011-2018
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

#import "SKSelectCommand.h"
#import "PDFSelection_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKMainDocument.h"
#import "NSDocument_SKExtensions.h"
#import <Quartz/Quartz.h>
#import "NSData_SKExtensions.h"
#import "SKPDFView.h"


@implementation SKSelectCommand

- (id)evaulatedSubject {
    return [[NSScriptObjectSpecifier objectSpecifierWithDescriptor:[[self appleEvent] attributeDescriptorForKeyword:'subj']] objectsByEvaluatingSpecifier];
}

- (id)performDefaultImplementation {
    id dP = [self directParameter];
    id selection = nil;
    NSRect rect;
    id doc = nil;
    NSDictionary *args = [self evaluatedArguments];
    PDFPage *page = [args objectForKey:@"Page"];
    BOOL animate = [[args objectForKey:@"Animate"] boolValue];
    id obj = [dP isKindOfClass:[NSArray class]] ? [dP firstObject] : dP;
    BOOL isNote = [obj respondsToSelector:@selector(keyClassDescription)] && [[[obj keyClassDescription] className] isEqualToString:@"note"];
    BOOL isRect = [dP isKindOfClass:[NSData class]];

    if (isNote) {
        selection = [dP valueForKey:@"objectsByEvaluatingSpecifier"];
        if ([selection isKindOfClass:[NSArray class]] == NO)
            selection = [NSArray arrayWithObjects:selection, nil];
        doc = [[[selection firstObject] page] containingDocument];
    } else if (isRect) {
        rect = [dP rectValueAsQDRect];
        doc = [page containingDocument] ?: [self evaulatedSubject];
    } else if ([dP isEqual:[NSArray array]]) {
        doc = [self evaulatedSubject];
    } else {
        selection = [PDFSelection selectionWithSpecifier:dP];
        doc = [[[selection pages] firstObject] containingDocument];
    }
    
    for  (doc in [doc isKindOfClass:[NSArray class]] ? doc : [NSArray arrayWithObjects:doc, nil]) {
        if ([doc isKindOfClass:[NSDocument class]] == NO) continue;
        
        SKPDFView *pdfView = nil;
        if ([doc respondsToSelector:@selector(pdfView)])
            pdfView = [doc pdfView];
        
        [[[[doc windowControllers] firstObject] window] makeKeyAndOrderFront:nil];
        if (isNote) {
            [doc setNoteSelection:selection];
        } else if (isRect) {
            if (pdfView) {
                if ([pdfView toolMode] == SKSelectToolMode) {
                    [pdfView setCurrentSelectionRect:rect];
                    if (page)
                        [pdfView setCurrentSelectionPage:page];
                } else if ([pdfView toolMode] == SKTextToolMode) {
                    selection = [(page ?: [pdfView currentPage]) selectionForRect:rect];
                    if (selection) {
                        [pdfView goToSelection:selection];
                        [pdfView setCurrentSelection:selection animate:animate];
                    } else {
                        [pdfView setCurrentSelection:nil];
                    }
                }
            }
        } else if (selection) {
            if ([pdfView toolMode] == SKTextToolMode) {
                [pdfView goToSelection:selection];
                [pdfView setCurrentSelection:selection animate:animate];
            }
        } else if (pdfView) {
            [pdfView setCurrentSelection:nil];
        } else {
            [doc setNoteSelection:[NSArray array]];
        }
    }
    
    return nil;
}

@end
