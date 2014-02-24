//
//  PDFDocument_SKNExtensions.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 6/15/08.
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

#import "PDFDocument_SKNExtensions.h"
#import "PDFAnnotation_SKNExtensions.h"
#import "SKNPDFAnnotationNote.h"
#import "NSFileManager_SKNExtensions.h"


@implementation PDFDocument (SKNExtensions)

- (id)initWithURL:(NSURL *)url readSkimNotes:(NSArray **)notes {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *pdfURL = url;
    BOOL isPDFBundle = [[[url path] pathExtension] caseInsensitiveCompare:@"pdfd"] == NSOrderedSame;
    if (isPDFBundle)
        pdfURL = [fm bundledFileURLWithExtension:@"pdf" inPDFBundleAtURL:url error:NULL];
    if (self = [self initWithURL:pdfURL]) {
        NSArray *noteDicts = nil;
        NSArray *annotations = nil;
        if (isPDFBundle)
            noteDicts = [fm readSkimNotesFromPDFBundleAtURL:url error:NULL];
        else
            noteDicts = [fm readSkimNotesFromExtendedAttributesAtURL:url error:NULL];
        if ([noteDicts count])
            annotations = [self addSkimNotesWithProperties:noteDicts];
        if (notes)
            *notes = annotations;
    }
    return self;
}

- (NSArray *)addSkimNotesWithProperties:(NSArray *)noteDicts {
    NSEnumerator *e = [noteDicts objectEnumerator];
    PDFAnnotation *annotation;
    NSDictionary *dict;
    NSMutableArray *notes = [NSMutableArray array];
    
    if ([self pageCount] == 0) return nil;
    
    // create new annotations from the dictionary and add them to their page and to the document
    while (dict = [e nextObject]) {
        NSUInteger pageIndex = [[dict objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntegerValue];
        if ((annotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:dict])) {
            if (pageIndex == NSNotFound || pageIndex == INT_MAX)
                pageIndex = 0;
            else if (pageIndex >= [self pageCount])
                pageIndex = [self pageCount] - 1;
            PDFPage *page = [self pageAtIndex:pageIndex];
            [page addAnnotation:annotation];
            [notes addObject:annotation];
            [annotation release];
        }
    }
    
    return notes;
}
@end
