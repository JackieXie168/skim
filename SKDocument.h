//
//  SKDocument.h
//  Skim
//
//  Created by Michael McCracken on 12/5/06.
/*
 This software is Copyright (c) 2006,2007
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

extern NSString *SKDocumentErrorDomain;

extern NSString *SKDocumentWillSaveNotification;

extern NSString *SKPDFDocumentType;
extern NSString *SKEmbeddedPDFDocumentType;
extern NSString *SKBarePDFDocumentType;
extern NSString *SKNotesDocumentType;
extern NSString *SKNotesRTFDocumentType;
extern NSString *SKPostScriptDocumentType;


@class PDFDocument, SKMainWindowController, SKPDFView, SKPDFSynchronizer;

@interface SKDocument : NSDocument
{
    IBOutlet NSView *readNotesAccessoryView;
    IBOutlet NSButton *replaceNotesCheckButton;
    
    // variables to be saved:
    NSData *pdfData;
    
    // temporary variables:
    PDFDocument *pdfDocument;
    NSMutableArray *noteDicts;
    
    SKPDFSynchronizer *synchronizer;
    
    NSTimer *fileUpdateTimer;
    NSDate *lastChangedDate;
    NSDate *previousCheckedDate;
    BOOL autoUpdate;
}

- (IBAction)readNotes:(id)sender;
- (IBAction)saveArchive:(id)sender;

- (BOOL)saveNotesToExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError;
- (BOOL)readNotesFromExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError;

- (SKMainWindowController *)mainWindowController;
- (PDFDocument *)pdfDocument;

- (SKPDFView *)pdfView;

- (NSData *)notesRTFData;

- (NSDictionary *)currentDocumentSetup;

- (void)checkFileUpdatesIfNeeded;
- (void)checkFileUpdateStatus:(NSTimer *)timer;

- (SKPDFSynchronizer *)synchronizer;

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
- (void)handleWindowWillCloseNotification:(NSNotification *)notification;

- (unsigned int)countOfPages;
- (PDFPage *)objectInPagesAtIndex:(unsigned int)index;
- (NSArray *)notes;
- (void)removeFromNotesAtIndex:(unsigned int)index;
- (PDFPage *)currentPage;
- (void)setCurrentPage:(PDFPage *)page;
- (id)activeNote;
- (void)setActiveNote:(id)note;
- (NSString *)string;

@end


@interface SKDocumentController : NSDocumentController
- (void)newDocumentFromClipboard:(id)sender;
@end
