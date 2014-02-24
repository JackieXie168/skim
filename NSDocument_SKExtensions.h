//
//  NSDocument_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 5/23/08.
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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

extern NSString *SKDocumentFileURLDidChangeNotification;

enum {
    SKNormalMode,
    SKFullScreenMode,
    SKPresentationMode
};
typedef NSInteger SKInteractionMode;

@interface NSDocument (SKExtensions)

+ (BOOL)isPDFDocument;

- (SKInteractionMode)systemInteractionMode;

- (void)undoableActionIsDiscardable;

#pragma mark Document Setup

- (void)saveRecentDocumentInfo;
- (void)applySetup:(NSDictionary *)setup;
- (NSDictionary *)currentDocumentSetup;

#pragma mark PDF Document

- (PDFDocument *)pdfDocument;

#pragma mark Bookmark Actions

- (IBAction)addBookmark:(id)sender;

#pragma mark Notes

- (NSArray *)notes;

- (NSData *)notesData;

- (NSString *)notesStringForTemplateType:(NSString *)typeName;
- (NSData *)notesDataForTemplateType:(NSString *)typeName;
- (NSFileWrapper *)notesFileWrapperForTemplateType:(NSString *)typeName;

- (NSString *)notesString;
- (NSData *)notesRTFData;
- (NSFileWrapper *)notesRTFDFileWrapper;

- (NSData *)notesFDFDataForFile:(NSString *)filename fileIDStrings:(NSArray *)fileIDStrings;

#pragma mark Scripting

- (NSArray *)pages;
- (NSUInteger)countOfPages;
- (PDFPage *)objectInPagesAtIndex:(NSUInteger)theIndex;

- (PDFPage *)currentPage;
- (void)setCurrentPage:(PDFPage *)page;
- (id)activeNote;
- (NSTextStorage *)richText;
- (id)selectionSpecifier;
- (NSData *)selectionQDRect;
- (id)selectionPage;
- (NSDictionary *)pdfViewSettings;
- (NSDictionary *)documentAttributes;
- (BOOL)isPDFDocument;
- (NSInteger)toolMode;
- (NSInteger)interactionMode;
- (NSDocument *)presentationNotesDocument;

- (void)handleRevertScriptCommand:(NSScriptCommand *)command;
- (void)handleGoToScriptCommand:(NSScriptCommand *)command;
- (id)handleFindScriptCommand:(NSScriptCommand *)command;
- (void)handleShowTeXScriptCommand:(NSScriptCommand *)command;
- (void)handleConvertNotesScriptCommand:(NSScriptCommand *)command;
- (void)handleReadNotesScriptCommand:(NSScriptCommand *)command;

@end
