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
#import "PDFDocument_BDSKExtensions.h"

NSString *SKDocumentWillSaveNotification = @"SKDocumentWillSaveNotification";
NSString *SKDocumentDidSaveNotification = @"SKDocumentDidSaveNotification";
NSString *SKDocumentErrorDomain = @"SKDocumentErrorDomain";

// See CFBundleTypeName in Info.plist
static NSString *SKPDFDocumentType = nil; /* set to NSPDFPboardType, not @"NSPDFPboardType" */
static NSString *SKNotesDocumentType = @"Skim Notes";
static NSString *SKPostScriptDocumentType = @"PostScript document";

@implementation SKDocument

+ (void)initialize {
    if (nil == SKPDFDocumentType)
        SKPDFDocumentType = [NSPDFPboardType copy];
}

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
    SKMainWindowController *mainWindowController = [[[SKMainWindowController alloc] initWithWindowNibName:@"MainWindow"] autorelease];
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
    NSData *data = nil;
    if ([typeName isEqualToString:SKPDFDocumentType]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentWillSaveNotification object:self];
        data = [pdfDoc dataRepresentation];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentDidSaveNotification object:self];
    } else if ([typeName isEqualToString:SKNotesDocumentType]) {
        data = [NSKeyedArchiver archivedDataWithRootObject:notes];
    }
    return data;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)docType error:(NSError **)outError{
    BOOL didRead;
    if ([docType isEqualToString:SKPDFDocumentType]) {
        pdfDoc = [[PDFDocument alloc] initWithURL:absoluteURL];    
        didRead = pdfDoc != nil;
       [self readNotesFromExtendedAttributesAtURL:absoluteURL];
    } else if ([docType isEqualToString:SKNotesDocumentType]) {
        // should we be able to load just notes?
        [self setNotes:[NSKeyedUnarchiver unarchiveObjectWithFile:[absoluteURL path]]];
        didRead = YES;
    } else if ([docType isEqualToString:SKPostScriptDocumentType]) {
        pdfDoc = [[PDFDocument alloc] initWithPostScriptURL:absoluteURL];
        didRead = pdfDoc != nil;
    }
    if (NO == didRead && outError)
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @""), NSLocalizedDescriptionKey, nil]];
    return didRead;
}

- (BOOL)saveNotesToExtendedAttributesAtURL:(NSURL *)aURL {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = YES;
    
    if ([aURL isFileURL]) {
        NSString *path = [aURL path];
        int i, numberOfNotes = [notes count];
        NSArray *oldNotes = [fm extendedAttributeNamesAtPath:path traverseLink:YES error:NULL];
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:numberOfNotes], @"numberOfNotes", nil];
        NSString *name = nil;
        NSData *data = nil;
        NSError *error = nil;
        
        // first remove all old notes
        for (i = 0; YES; i++) {
            name = [NSString stringWithFormat:@"SKNote-%i", i];
            if ([oldNotes containsObject:name] == NO)
                break;
            if ([fm removeExtendedAttribute:name atPath:path traverseLink:YES error:&error] == NO) {
                NSLog(@"%@: %@", self, error);
            }
        }
        
        if ([notes count] == 0) {
            if ([fm removeExtendedAttribute:@"SKNotesInfo" atPath:path traverseLink:YES error:&error] == NO) {
                success = NO;
                NSLog(@"%@: %@", self, error);
            }
        } else if ([fm setExtendedAttributeNamed:@"SKNotesInfo" toPropertyListValue:dictionary atPath:path options:nil error:&error] == NO) {
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
            if ([[[error userInfo] objectForKey:NSUnderlyingErrorKey] code] != ENOATTR)
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
