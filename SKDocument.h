//

// SKDocument.h

//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/5/06.
//  Copyright Michael O. McCracken 2006 . All rights reserved.
//

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
}

- (IBAction)readNotes:(id)sender;

- (NSArray *)notes;
- (void)setNotes:(NSArray *)newNotes;
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

@end
