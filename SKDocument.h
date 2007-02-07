//

// SKDocument.h

//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/5/06.
//  Copyright Michael O. McCracken 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *SKDocumentErrorDomain;

@class PDFDocument;

@interface SKDocument : NSDocument
{
    IBOutlet NSPanel *saveProgressSheet;
    IBOutlet NSProgressIndicator *saveProgressBar;
    
    // variables to be saved:
    NSMutableArray *notes;
    PDFDocument *pdfDocument;
    
    // temporary variables:
    NSMutableArray *noteDicts;
}

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

- (PDFDocument *)pdfDocument;

- (void)setupDocumentNotifications;
- (void)disableDocumentNotifications;

- (void)handleDidBeginWriteDocument:(NSNotification *)notification;
- (void)handleDidEndWriteDocument:(NSNotification *)notification;
- (void)handleDidEndPageWrite:(NSNotification *)notification;

@end
