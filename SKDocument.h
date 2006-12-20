//

// SKDocument.h

//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/5/06.
//  Copyright Michael O. McCracken 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *SKDocumentWillSaveNotification;
extern NSString *SKDocumentDidSaveNotification;
extern NSString *SKDocumentErrorDomain;

@class PDFDocument;

@interface SKDocument : NSDocument
{
    PDFDocument *pdfDoc;
    
    // variables to be saved:
    NSMutableArray *notes;
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

- (PDFDocument *)pdfDocument;

@end
