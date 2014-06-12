//
//  SKMainDocument.h
//  Skim
//
//  Created by Michael McCracken on 12/5/06.
/*
 This software is Copyright (c) 2006-2014
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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
#import "SKPDFSynchronizer.h"

extern NSString *SKSkimFileDidSaveNotification;

@class PDFDocument, SKMainWindowController, SKPDFView, SKLine, SKProgressController, SKTemporaryData, SKFileUpdateChecker, SKExportAccessoryController;

@interface SKMainDocument : NSDocument <SKPDFSynchronizerDelegate>
{
    SKMainWindowController *mainWindowController;
    
    // variables to be saved:
    NSData *pdfData;
    NSData *originalData;
    
    // temporary variables:
    SKTemporaryData *tmpData;
    
    NSMapTable *pageOffsets;
    
    SKPDFSynchronizer *synchronizer;
    
    SKFileUpdateChecker *fileUpdateChecker;
    
    SKExportAccessoryController *exportAccessoryController;
    
    BOOL isSaving;
    BOOL exportUsingPanel;
    NSInteger exportOption;
    
    BOOL gettingFileType;
}

- (IBAction)readNotes:(id)sender;
- (IBAction)convertNotes:(id)sender;
- (IBAction)saveArchive:(id)sender;
- (IBAction)moveToTrash:(id)sender;

@property (nonatomic, readonly) SKMainWindowController *mainWindowController;
@property (nonatomic, readonly) PDFDocument *pdfDocument;

@property (nonatomic, readonly) SKPDFView *pdfView;

- (void)savePasswordInKeychain:(NSString *)password;

@property (nonatomic, readonly) SKPDFSynchronizer *synchronizer;

@property (nonatomic, readonly) NSArray *snapshots;

@property (nonatomic, readonly) NSArray *tags;
@property (nonatomic, readonly) double rating;

- (NSArray *)notes;
- (void)insertObject:(PDFAnnotation *)newNote inNotesAtIndex:(NSUInteger)anIndex;
- (void)removeObjectFromNotesAtIndex:(NSUInteger)anIndex;

@property (nonatomic, retain) PDFPage *currentPage;
@property (nonatomic, copy) id activeNote;
@property (nonatomic, readonly) NSTextStorage *richText;
@property (nonatomic, copy) id selectionSpecifier;
@property (nonatomic, copy) NSData *selectionQDRect;
@property (nonatomic, retain) PDFPage *selectionPage;
@property (nonatomic, copy) NSDictionary *pdfViewSettings;

- (void)handleRevertScriptCommand:(NSScriptCommand *)command;
- (void)handleGoToScriptCommand:(NSScriptCommand *)command;
- (id)handleFindScriptCommand:(NSScriptCommand *)command;
- (void)handleShowTeXScriptCommand:(NSScriptCommand *)command;
- (void)handleConvertNotesScriptCommand:(NSScriptCommand *)command;
- (void)handleReadNotesScriptCommand:(NSScriptCommand *)command;

@end


@interface NSWindow (SKScriptingExtensions)
- (void)handleRevertScriptCommand:(NSScriptCommand *)command;
@end
