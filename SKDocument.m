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
#import "SKPDFAnnotationNote.h"
#import "SKNote.h"
#import "PDFDocument_BDSKExtensions.h"

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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [pdfDocument release];
    [notes release];
    [super dealloc];
}

- (void)makeWindowControllers{
    SKMainWindowController *mainWindowController = [[[SKMainWindowController alloc] initWithWindowNibName:@"MainWindow"] autorelease];
    [self addWindowController:mainWindowController];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController{
    
    SKMainWindowController *mainController =  (SKMainWindowController *)aController;
    
    [mainController setShouldCloseDocument:YES];
    
    [mainController setPdfDocument:pdfDocument];
    
    // we keep a pristine copy for save, as we shouldn't save the annotations
    [pdfDocument autorelease];
    pdfDocument = [[PDFDocument alloc] initWithData:[pdfDocument dataRepresentation]];
    
    [self setupDocumentNotifications];
    
    [mainController setAnnotationsFromDictionaries:noteDicts];
}


- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError{
    BOOL success = [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:outError];
    
    // we check for notes and save a .skim as well:
    if (success && [typeName isEqualToString:SKPDFDocumentType] && saveOperation != NSAutosaveOperation) {
       [self saveNotesToExtendedAttributesAtURL:absoluteURL];
       [[[[self windowControllers] objectAtIndex:0] window] setDocumentEdited:NO];
    }
    
    return success;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    BOOL didWrite = NO;
    if ([typeName isEqualToString:SKPDFDocumentType]) {
        didWrite = [pdfDocument writeToURL:absoluteURL];
    } else if ([typeName isEqualToString:SKNotesDocumentType]) {
        NSData *data = [self notesData];
        if (data != nil)
            didWrite = [data writeToURL:absoluteURL options:NSAtomicWrite error:outError];
    }
    return didWrite;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    if ([super revertToContentsOfURL:absoluteURL ofType:typeName error:outError]) {
        if ([typeName isEqualToString:SKNotesDocumentType] == NO) {
            [(SKMainWindowController *)[[self windowControllers] objectAtIndex:0] setPdfDocument:pdfDocument];
            [pdfDocument autorelease];
            pdfDocument = [[PDFDocument alloc] initWithData:[pdfDocument dataRepresentation]];
            [self setupDocumentNotifications];
        } else {
            [[[[self windowControllers] objectAtIndex:0] window] setDocumentEdited:NO];
        }
        if (noteDicts)
            [[[self windowControllers] objectAtIndex:0] setAnnotationsFromDictionaries:noteDicts];
        return YES;
    } else return NO;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)docType error:(NSError **)outError{
    BOOL didRead = NO;
    if ([docType isEqualToString:SKPDFDocumentType]) {
        if (pdfDocument)
            [self disableDocumentNotifications];
        [pdfDocument release];
        pdfDocument = [[PDFDocument alloc] initWithURL:absoluteURL];    
        didRead = pdfDocument != nil;
        [self readNotesFromExtendedAttributesAtURL:absoluteURL];
    } else if ([docType isEqualToString:SKNotesDocumentType]) {
        // should we be able to load just notes?
        didRead = [self readNotesFromData:[NSKeyedUnarchiver unarchiveObjectWithFile:[absoluteURL path]]];
    } else if ([docType isEqualToString:SKPostScriptDocumentType]) {
        if (pdfDocument)
            [self disableDocumentNotifications];
        [pdfDocument release];
        pdfDocument = [[PDFDocument alloc] initWithPostScriptURL:absoluteURL];    
        didRead = pdfDocument != nil;
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
            data = [NSKeyedArchiver archivedDataWithRootObject:[[notes objectAtIndex:i] dictionaryValue]];
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
        
        if (noteDicts)
            [noteDicts release];
        noteDicts = [[NSMutableDictionary alloc] initWithCapacity:numberOfNotes];
        
        for (i = 0; i < numberOfNotes; i++) {
            name = [NSString stringWithFormat:@"SKNote-%i", i];
            if ((data = [fm extendedAttributeNamed:name atPath:[aURL path] traverseLink:YES error:&error]) &&
                (dict = [NSKeyedUnarchiver unarchiveObjectWithData:data])) {
                [noteDicts addObject:dict];
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

- (NSData *)notesData {
    int i, numberOfNotes = [notes count];
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:numberOfNotes];
    NSData *data;
    
    for (i = 0; i < numberOfNotes; i++)
        [array addObject:[[notes objectAtIndex:i] dictionaryValue]];
    data = [NSKeyedArchiver archivedDataWithRootObject:array];
    
    return data;
}

- (BOOL)readNotesFromData:(NSData *)data {
    NSDictionary *dict = nil;
    BOOL success = YES;
    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if (array != nil) {
        int i, numberOfNotes = [array count];
        
        if (noteDicts)
            [noteDicts release];
        noteDicts = [[NSMutableDictionary alloc] initWithCapacity:numberOfNotes];
        
        for (i = 0; i < numberOfNotes; i++) {
            dict = [array objectAtIndex:i];
            [noteDicts addObject:dict];
        }
    } else {
        success = NO;
    }
    return success;
}

- (void)setupDocumentNotifications{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidBeginWriteDocument:) 
                                                 name:@"PDFDidBeginDocumentWrite" object:pdfDocument];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidEndWriteDocument:) 
                                                 name:@"PDFDidEndDocumentWrite" object:pdfDocument];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidEndPageWrite:) 
                                                 name:@"PDFDidEndPageWrite" object:pdfDocument];
}

- (void)disableDocumentNotifications{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFDidBeginDocumentWrite" object:pdfDocument];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFDidEndDocumentWrite" object:pdfDocument];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFDidEndPageWrite" object:pdfDocument];
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
    return pdfDocument;
}

#pragma mark Notification handlers

- (void)saveProgressSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[sheet close];
}

- (void)handleDidBeginWriteDocument:(NSNotification *)notification {
    if (saveProgressSheet == nil) {
        if (NO == [NSBundle loadNibNamed:@"SaveProgressSheet" owner:self])  {
            NSLog(@"Failed to load SaveProgressSheet.nib");
            return;
        }
    }
    
	// Establish maximum and current value for progress bar.
	[saveProgressBar setMaxValue:(double)[[notification object] pageCount]];
	[saveProgressBar setDoubleValue: 0.0];
	
	// Bring up the save panel as a sheet.
	[NSApp beginSheet:saveProgressSheet
       modalForWindow:[self windowForSheet]
        modalDelegate:self
       didEndSelector:@selector(saveProgressSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (void)handleDidEndWriteDocument:(NSNotification *)notification {
	[NSApp endSheet:saveProgressSheet];
}

- (void)handleDidEndPageWrite:(NSNotification *)notification {
	[saveProgressBar setDoubleValue:[[[notification userInfo] objectForKey:@"PDFDocumentPageIndex"] floatValue]];
	[saveProgressBar displayIfNeeded];
}

@end
