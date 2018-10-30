//
//  SKSelectionCommand.m
//  Skim
//
//  Created by Christiaan on 30/10/2018.
/*
 This software is Copyright (c) 2018
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

#import "SKSelectionCommand.h"
#import <Quartz/Quartz.h>
#import "PDFSelection_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKMainDocument.h"
#import "SKPDFView.h"

@implementation SKSelectionCommand

- (id)performDefaultImplementation {
    NSData *rectOrPoint = [self directParameter];
    NSDictionary *args = [self evaluatedArguments];
    NSData *point = [args objectForKey:@"To"];
    PDFPage *page = [args objectForKey:@"Page"];
    id doc = [page containingDocument];
    
    if (doc == nil)
        doc = [[NSScriptObjectSpecifier objectSpecifierWithDescriptor:[[self appleEvent] attributeDescriptorForKeyword:'subj']] objectsByEvaluatingSpecifier];
    
    if ([doc isKindOfClass:[SKMainDocument class]] == NO) {
        [self setScriptErrorNumber:NSArgumentsWrongScriptError];
        [self setScriptErrorString:@"Invalid or missing document."];
        return nil;
    }
    
    if (page == nil)
        page = [[doc pdfView] currentPage];
    
    if (point)
        return [[page selectionFromPoint:[rectOrPoint pointValueAsQDPoint] toPoint:[point pointValueAsQDPoint]] objectSpecifier];
    else
        return [[page selectionForRect:[rectOrPoint rectValueAsQDRect]] objectSpecifier];
}

@end
