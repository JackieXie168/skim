//

// SKDocument.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/5/06.
//  Copyright Michael O. McCracken 2006 . All rights reserved.
//

#import "SKDocument.h"
#import <Quartz/Quartz.h>
#import "SKMainWindowController.h"


static NSString *SKPDFDocumentType = @"PDF";
static NSString *SKNotesDocumentType = @"Skim Notes";

@implementation SKDocument

- (id)init{
    
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        notes = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}


- (void)makeWindowControllers{
    SKMainWindowController *mainWindowController = [[SKMainWindowController alloc] initWithWindowNibName:@"MainWindow"];
    [self addWindowController:mainWindowController];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController{
    
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}


- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError{
    BOOL success = [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:outError];
    
    // we check for notes and save a .skim as well:
    if (success && [typeName isEqualToString:SKPDFDocumentType] && [notes count] > 0 && saveOperation != NSAutosaveOperation) {
        // save .skim doc
        NSString *notesPath = [[[absoluteURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"skim"];
        if (notesPath != nil)
            [NSKeyedArchiver archiveRootObject:notes toFile:notesPath];
    }
    
    return success;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError{
    if ([typeName isEqualToString:SKPDFDocumentType]) {
        return [pdfDoc dataRepresentation];
    } else if ([typeName isEqualToString:SKNotesDocumentType]) {
        return [NSKeyedArchiver archivedDataWithRootObject:notes];
    }
    return nil;
}

- (BOOL)readFromURL:(NSURL *)aURL ofType:(NSString *)docType error:(NSError **)outError{
    if ([docType isEqualToString:SKPDFDocumentType]) {
        pdfDoc = [[PDFDocument alloc] initWithURL:aURL];    
        // look for a .skim doc as well and try to load it
        NSString *notesPath = [[[aURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"skim"];
        NSArray *docNotes = [NSKeyedUnarchiver unarchiveObjectWithFile:notesPath];
        if (docNotes != nil) {
            [self setNotes:docNotes];
        }
    } else if ([docType isEqualToString:SKNotesDocumentType]) {
        // should we be able to load just notes?
        [self setNotes:[NSKeyedUnarchiver unarchiveObjectWithFile:[aURL path]]];
    }
    return YES;
}

#pragma mark Accessors

- (NSArray *)notes {
    return notes;
}

- (void)setNotes:(NSArray *)newNotes {
    [notes setArray:notes];
}

- (unsigned)countOfNotes {
    return [notes count];
}

- (id)objectInNotesAtIndex:(unsigned)theIndex {
    return [notes objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inNotesAtIndex:(unsigned)theIndex {
    [notes insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromNotesAtIndex:(unsigned)theIndex {
    [notes removeObjectAtIndex:theIndex];
}

- (PDFDocument *)pdfDocument{
    return pdfDoc;
}

@end
