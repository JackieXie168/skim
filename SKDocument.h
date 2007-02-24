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

@class PDFDocument, SKMainWindowController;

@interface SKDocument : NSDocument
{
    // variables to be saved:
    NSMutableArray *notes;
    NSData *pdfData;
    
    // temporary variables:
    PDFDocument *pdfDocument;
    NSMutableArray *noteDicts;
    
    NSTimer *fileUpdateTimer;
    NSDate *lastChangedDate;
}

- (IBAction)readNotes:(id)sender;

- (NSArray *)notes;
- (void)setNotes:(NSArray *)newNotes;
- (unsigned)countOfNotes;
- (id)objectInNotesAtIndex:(unsigned)index;
- (void)insertObject:(id)obj inNotesAtIndex:(unsigned)index;
- (void)removeObjectFromNotesAtIndex:(unsigned)index;

- (BOOL)saveNotesToExtendedAttributesAtURL:(NSURL *)aURL;
- (BOOL)readNotesFromExtendedAttributesAtURL:(NSURL *)aURL;
- (NSData *)notesData;
- (BOOL)readNotesFromData:(NSData *)data;

- (SKMainWindowController *)mainWindowController;
- (PDFDocument *)pdfDocument;

- (NSDictionary *)currentDocumentSetup;

- (void)checkFileUpdatesIfNeeded;
- (void)checkFileUpdateStatus:(NSTimer *)timer;

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
- (void)handleWindowWillCloseNotification:(NSNotification *)notification;

@end


@interface SKDocumentController : NSDocumentController
@end
