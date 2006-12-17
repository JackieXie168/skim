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
#import "NSFileManager_ExtendedAttributes.h"
#import "SKNote.h"


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
    if (success && [typeName isEqualToString:SKPDFDocumentType] && saveOperation != NSAutosaveOperation) {
       [self saveNotesToExtendedAttributesAtURL:absoluteURL];
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

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)docType error:(NSError **)outError{
    if ([docType isEqualToString:SKPDFDocumentType]) {
        pdfDoc = [[PDFDocument alloc] initWithURL:absoluteURL];    
       [self readNotesFromExtendedAttributesAtURL:absoluteURL];
    } else if ([docType isEqualToString:SKNotesDocumentType]) {
        // should we be able to load just notes?
        [self setNotes:[NSKeyedUnarchiver unarchiveObjectWithFile:[absoluteURL path]]];
    }
    return YES;
}

- (BOOL)saveNotesToExtendedAttributesAtURL:(NSURL *)aURL {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = YES;
    
    if ([aURL isFileURL]) {
        NSString *path = [aURL path];
        int i, numberOfNotes = [notes count];
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:numberOfNotes], @"numberOfNotes", nil];
        NSString *name = nil;
        NSData *data = nil;
        NSError *error = nil;
        
        if ([fm setExtendedAttributeNamed:@"SKNotesInfo" toPropertyListValue:dictionary atPath:path options:nil error:&error] == NO) {
            success = NO;
            NSLog(@"%@: %@", self, error);
        }
        
        for (i = 0; i < numberOfNotes; i++) {
            name = [NSString stringWithFormat:@"SKNote-%i", i];
            data = [NSKeyedArchiver archivedDataWithRootObject:[notes objectAtIndex:i]];
            if ([fm setExtendedAttributeNamed:name toValue:data atPath:path options:nil error:&error] == NO) {
                success = NO;
                NSLog(@"%@: %@", self, error);
            }
        }
    }
    return success;
}

- (BOOL)readNotesFromExtendedAttributesAtURL:(NSURL *)aURL {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *dict = nil;
    BOOL success = YES;
    NSError *error = nil;
    
    if ([aURL isFileURL]) {
        dict = [fm propertyListFromExtendedAttributeNamed:@"SKNotesInfo" atPath:[aURL path] traverseLink:YES error:&error];
        if (dict == nil) {
            success = NO;
            NSLog(@"%@: %@", self, error);
        }
    }
    if (dict != nil) {
        int i, numberOfNotes = [[dict objectForKey:@"numberOfNotes"] intValue];
        NSString *name = nil;
        NSData *data = nil;
        SKNote *note = nil;
        
        [notes removeAllObjects];
        
        for (i = 0; i < numberOfNotes; i++) {
            name = [NSString stringWithFormat:@"SKNote-%i", i];
            if ((data = [fm extendedAttributeNamed:name atPath:[aURL path] traverseLink:YES error:&error]) &&
                (note = [NSKeyedUnarchiver unarchiveObjectWithData:data])) {
                [notes addObject:note];
            } else {
                success = NO;
                NSLog(@"%@: %@", self, error);
            }
        }
    } else {
        success = NO;
    }
    return success;
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
