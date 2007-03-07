//
//  SKDocument.m
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

#import "SKDocument.h"
#import <Quartz/Quartz.h>
#import "SKMainWindowController.h"
#import "NSFileManager_ExtendedAttributes.h"
#import "SKPDFAnnotationNote.h"
#import "SKPSProgressController.h"
#import "SKFindController.h"
#import "BDAlias.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKPDFView.h"
#import "SKNoteWindowController.h"

// maximum length of xattr value recommended by Apple
#define MAX_XATTR_LENGTH 2048

NSString *SKDocumentErrorDomain = @"SKDocumentErrorDomain";

// See CFBundleTypeName in Info.plist
static NSString *SKPDFDocumentType = nil; /* set to NSPDFPboardType, not @"NSPDFPboardType" */
static NSString *SKEmbeddedPDFDocumentType = @"PDF With Embedded Notes";
static NSString *SKBarePDFDocumentType = @"PDF Without Notes";
static NSString *SKNotesDocumentType = @"Skim Notes";
static NSString *SKPostScriptDocumentType = @"PostScript document";

NSString *SKDocumentWillSaveNotification = @"SKDocumentWillSaveNotification";

@implementation SKDocument

+ (void)initialize {
    if (nil == SKPDFDocumentType)
        SKPDFDocumentType = [NSPDFPboardType copy];
}

- (void)dealloc {
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKAutoCheckFileUpdateKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [pdfData release];
    [noteDicts release];
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
    pdfDocument = nil;
    
    [mainController setAnnotationsFromDictionaries:noteDicts];
    [noteDicts release];
    noteDicts = nil;
    
    [self checkFileUpdatesIfNeeded];
    
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKAutoCheckFileUpdateKey];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillTerminateNotification:) 
                                                 name:NSApplicationWillTerminateNotification object:NSApp];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowWillCloseNotification:) 
                                                 name:NSWindowWillCloseNotification object:[mainController window]];
}

- (void)showWindows{
    [super showWindows];
    
    // Get the search string keyword if available (Spotlight passes this)
    NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    NSString *searchString = [[event descriptorForKeyword:keyAESearchText] stringValue];
    
    if([event eventID] == kAEOpenDocuments && searchString != nil){
        [[self mainWindowController] displaySearchResultsForString:searchString];
    }
}

- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError{
    BOOL success = [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:outError];
    // we check for notes and save a .skim as well:
    if (success && [typeName isEqualToString:SKPDFDocumentType]) {
       if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
            [self saveNotesToExtendedAttributesAtURL:absoluteURL error:NULL];
            [self updateChangeCount:NSChangeCleared];
            [lastChangedDate release];
            lastChangedDate = [[[[NSFileManager defaultManager] fileAttributesAtPath:[absoluteURL path] traverseLink:YES] fileModificationDate] retain];
        }
    }
    
    return success;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentWillSaveNotification object:self];
    BOOL didWrite = NO;
    if ([typeName isEqualToString:SKPDFDocumentType]) {
        // notes are only saved as a dry-run to test if we can write, they are not copied to the final destination. 
        didWrite = [pdfData writeToURL:absoluteURL options:NSAtomicWrite error:outError] &&
                   [self saveNotesToExtendedAttributesAtURL:absoluteURL error:outError];
    } else if ([typeName isEqualToString:SKEmbeddedPDFDocumentType]) {
        [[self mainWindowController] removeTemporaryAnnotations];
        didWrite = [[[self mainWindowController] pdfDocument] writeToURL:absoluteURL];
    } else if ([typeName isEqualToString:SKBarePDFDocumentType]) {
        [[self mainWindowController] removeTemporaryAnnotations];
        didWrite = [pdfData writeToURL:absoluteURL options:NSAtomicWrite error:outError];
    } else if ([typeName isEqualToString:SKNotesDocumentType]) {
        NSArray *array = [[self notes] valueForKey:@"dictionaryValue"];
        NSData *data;
        if (array && (data = [NSKeyedArchiver archivedDataWithRootObject:array]))
            didWrite = [data writeToURL:absoluteURL options:NSAtomicWrite error:outError];
        else if (outError != NULL)
            *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes", @""), NSLocalizedDescriptionKey, nil]];
            
    }
    return didWrite;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    if ([super revertToContentsOfURL:absoluteURL ofType:typeName error:outError]) {
        if ([typeName isEqualToString:SKNotesDocumentType] == NO) {
            [[self mainWindowController] setPdfDocument:pdfDocument];
            [pdfDocument autorelease];
            pdfDocument = nil;
        } else {
            [self updateChangeCount:NSChangeCleared];
        }
        if (noteDicts) {
            [[self mainWindowController] setAnnotationsFromDictionaries:noteDicts];
            [noteDicts release];
            noteDicts = nil;
        }
        return YES;
    } else return NO;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)docType error:(NSError **)outError;
{
    BOOL didRead = NO;
    PDFDocument *pdfDoc = nil;
    NSError *error = nil;
    
    if ([docType isEqualToString:SKPDFDocumentType]) {
        pdfDoc = [[PDFDocument alloc] initWithData:data];
    } else if ([docType isEqualToString:SKPostScriptDocumentType]) {
        SKPSProgressController *progressController = [[SKPSProgressController alloc] init];
        if (data = [[progressController PDFDataWithPostScriptData:data] retain])
            pdfDoc = [[PDFDocument alloc] initWithData:data];
        [progressController autorelease];
    }
    
    if (pdfDoc) {
        didRead = YES;
        [pdfData release];
        pdfData = data;
        [pdfDocument release];
        pdfDocument = pdfDoc;
        [lastChangedDate release];
        lastChangedDate = nil;
    }
    
    if (didRead == NO && outError != NULL)
        *outError = error ? error : [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @""), NSLocalizedDescriptionKey, nil]];
    
    return didRead;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)docType error:(NSError **)outError{
    BOOL didRead = NO;
    NSData *data = nil;
    PDFDocument *pdfDoc = nil;
    NSError *error = nil;
    
    if ([docType isEqualToString:SKPDFDocumentType]) {
        if ((data = [[NSData alloc] initWithContentsOfURL:absoluteURL options:0 error:&error]) &&
            (pdfDoc = [[PDFDocument alloc] initWithURL:absoluteURL])) {
            if ([self readNotesFromExtendedAttributesAtURL:absoluteURL error:&error] == NO) {
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to Read Notes", @"Message in alert dialog") 
                                                 defaultButton:NSLocalizedString(@"No", @"Button title")
                                               alternateButton:NSLocalizedString(@"Yes", @"Button title")
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"Skim was not able to read the notes at %@. %@ Do you want to continue to open the PDF document anyway?", @"Informative text in alert dialog"), [absoluteURL path], [[error userInfo] objectForKey:NSLocalizedDescriptionKey]];
                if ([alert runModal] == NSAlertDefaultReturn) {
                    [data release];
                    data = nil;
                    [pdfDoc release];
                    pdfDoc = nil;
                }
            } else if ([noteDicts count] == 0) {
                NSString *path = [[[absoluteURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"skim"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Found Separate Notes", @"Message in alert dialog") 
                                                     defaultButton:NSLocalizedString(@"Yes", @"Button title")
                                                   alternateButton:NSLocalizedString(@"No", @"Button title")
                                                       otherButton:nil
                                         informativeTextWithFormat:NSLocalizedString(@"Skim was not able to read the notes at %@, but there a Skim notes file %@ with the same name was found. Do you want Skim the read the from this file?", @"Informative text in alert dialog"), [absoluteURL path], path];
                    if ([alert runModal] == NSAlertDefaultReturn) {
                        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
                        if (array) {
                            [noteDicts release];
                            noteDicts = [array copy];
                            [self updateChangeCount:NSChangeDone];
                        }
                    }
                }
            }
        }
    } else if ([docType isEqualToString:SKPostScriptDocumentType]) {
        if (data = [NSData dataWithContentsOfURL:absoluteURL options:0 error:&error]) {
            SKPSProgressController *progressController = [[SKPSProgressController alloc] init];
            if (data = [[progressController PDFDataWithPostScriptData:data] retain])
                pdfDoc = [[PDFDocument alloc] initWithData:data];
            [progressController autorelease];
        }
    }
    
    if (data) {
        if (pdfDoc) {
            didRead = YES;
            [pdfData release];
            pdfData = data;
            [pdfDocument release];
            pdfDocument = pdfDoc;
            [lastChangedDate release];
            lastChangedDate = [[[[NSFileManager defaultManager] fileAttributesAtPath:[absoluteURL path] traverseLink:YES] fileModificationDate] retain];
        } else {
            [data release];
            data = nil;
        }
    }
    
    if (didRead == NO && outError != NULL)
        *outError = error ? error : [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @""), NSLocalizedDescriptionKey, nil]];
    
    return didRead;
}

- (void)openPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo{
    if (returnCode == NSOKButton) {
        NSURL *notesURL = [[oPanel URLs] objectAtIndex:0];
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile:[notesURL path]];
        
        if (array) {
            [[self mainWindowController] setAnnotationsFromDictionaries:array];
            [self updateChangeCount:NSChangeDone];
        }
        
    }
}

- (IBAction)readNotes:(id)sender{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    NSString *path = [[self fileURL] path];
    [oPanel beginSheetForDirectory:[path stringByDeletingLastPathComponent]
                              file:[[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"skim"]
                             types:[NSArray arrayWithObject:@"skim"]
                    modalForWindow:[[self mainWindowController] window]
                     modalDelegate:self
                    didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo:NULL];		
}

- (BOOL)saveNotesToExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = YES;
    NSArray *notes = [self notes];
    
    if ([aURL isFileURL]) {
        NSString *path = [aURL path];
        int i, numberOfNotes = [notes count];
        NSData *data = nil;
        NSError *error = nil;
        
        // first remove all old notes
        if ([fm removeExtendedAttribute:@"net_sourceforge_skim_notes" atPath:path traverseLink:YES error:&error] == NO) {
            // should we set success to NO and return an error?
            //NSLog(@"%@: %@", self, error);
        }
        
        NSMutableArray *rootObject = [NSMutableArray array];
        for (i = 0; success && i < numberOfNotes; i++) {
            [rootObject addObject:[[notes objectAtIndex:i] dictionaryValue]];
        }
        data = [NSKeyedArchiver archivedDataWithRootObject:rootObject];
        if ([fm setExtendedAttributeNamed:@"net_sourceforge_skim_notes" toValue:data atPath:path options:nil error:&error] == NO) {
            success = NO;
            if (outError) *outError = error;
            NSLog(@"%@: %@", self, error);
        }
    }
    return success;
}

- (BOOL)readNotesFromExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = YES;
    NSError *error = nil;
    
    if ([aURL isFileURL]) {

        NSData *data = [fm extendedAttributeNamed:@"net_sourceforge_skim_notes" atPath:[aURL path] traverseLink:YES error:&error];
        
        if (noteDicts)
            [noteDicts release];
        noteDicts = nil;
        
        if ([data length])
            noteDicts = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];
            
    } else {
        success = NO;
        if(error == nil && outError) 
            *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"The file does not exist or is not a file.", @""), NSLocalizedDescriptionKey, nil]];
    }
    if (success == NO) {
        [noteDicts release];
        noteDicts = nil;
    }
    return success;
}

#pragma mark File update checking

// For now this just uses a timer checking the modification date of the file. We may want to use kqueue (UKKqueue) at some point. 

- (void)checkFileUpdatesIfNeeded {
    BOOL autoUpdate = [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey];
    
    if (autoUpdate == NO && fileUpdateTimer) {
        [fileUpdateTimer invalidate];
        [fileUpdateTimer release];
        fileUpdateTimer = nil;
    } else if (autoUpdate) {
        fileUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(checkFileUpdateStatus:) userInfo:nil repeats:NO] retain];
    }
}

- (void)fileUpdateAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSDate *changeDate = (NSDate *)contextInfo;
    
    if (returnCode == NSAlertDefaultReturn) {
        NSError *error = nil;
        if ([self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:&error]) {
            [changeDate release];
        } else {
            [NSApp presentError:error];
            [lastChangedDate release];
            lastChangedDate = changeDate;
        }
    } else {
        [lastChangedDate release];
        lastChangedDate = changeDate;
    }
    
    [self checkFileUpdatesIfNeeded];
}

- (void)checkFileUpdateStatus:(NSTimer *)timer {
    [fileUpdateTimer release];
    fileUpdateTimer = nil;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:[self fileName]]) {
        NSDate *fileChangedDate = [[fm fileAttributesAtPath:[self fileName] traverseLink:YES] fileModificationDate];
        
        if ([lastChangedDate compare:fileChangedDate] == NSOrderedAscending) {
            BOOL autoUpdate = [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey];
            BOOL askPref = [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateAskKey];
            if (autoUpdate && (askPref == NO && [self isDocumentEdited] == NO)) {
                [self fileUpdateAlertDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:[fileChangedDate retain]];
            } else {
                NSString *message;
                if ([self isDocumentEdited])
                    message = NSLocalizedString(@"The PDF file has changed on disk. If you reload, your chnages will be lost. Do you want to reload this document now?", @"Informative text in alert dialog");
                else 
                    message = NSLocalizedString(@"The PDF file has changed on disk. Do you want to reload this document now?", @"Informative text in alert dialog");
                
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"File Updated", @"Message in alert dialog") 
                                                 defaultButton:NSLocalizedString(@"Yes", @"Button title")
                                               alternateButton:NSLocalizedString(@"No", @"Button title")
                                                   otherButton:nil
                                     informativeTextWithFormat:message];
                [alert beginSheetModalForWindow:[[self mainWindowController] window]
                                  modalDelegate:self
                                 didEndSelector:@selector(fileUpdateAlertDidEnd:returnCode:contextInfo:) 
                                    contextInfo:[fileChangedDate retain]];
            }
        } else {
            [self checkFileUpdatesIfNeeded];
        }
        
    } else {
        [self checkFileUpdatesIfNeeded];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [NSUserDefaultsController sharedUserDefaultsController]) {
        if (NO == [keyPath hasPrefix:@"values."])
            return;
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKAutoCheckFileUpdateKey]) {
            [self checkFileUpdatesIfNeeded];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification {
    [fileUpdateTimer invalidate];
    [fileUpdateTimer release];
    fileUpdateTimer = nil;
}

- (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    [fileUpdateTimer invalidate];
    [fileUpdateTimer release];
    fileUpdateTimer = nil;
}

#pragma mark Accessors

- (SKMainWindowController *)mainWindowController {
    NSArray *windowControllers = [self windowControllers];
    return [windowControllers count] ? [windowControllers objectAtIndex:0] : nil;
}

- (PDFDocument *)pdfDocument{
    return [[self mainWindowController] pdfDocument];
}

- (NSDictionary *)currentDocumentSetup {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    NSString *fileName = [self fileName];
    if (fileName) {
        NSData *data = [[BDAlias aliasWithPath:fileName] aliasData];
        
        [setup setObject:fileName forKey:@"fileName"];
        if(data)
            [setup setObject:data forKey:@"_BDAlias"];
        
        [setup addEntriesFromDictionary:[[self mainWindowController] currentSetup]];
    }
    
    return setup;
}

- (void)performFindPanelAction:(id)sender {
    [[SKFindController sharedFindController] performFindPanelAction:sender];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
	if ([anItem action] == @selector(performFindPanelAction:))
        return [[SKFindController sharedFindController] validateUserInterfaceItem:anItem];
    else
        return [super validateUserInterfaceItem:anItem];
}

- (void)findString:(NSString *)string options:(int)options{
    [[self mainWindowController] findString:string options:options];
}

- (SKPDFView *)pdfView {
    return [[self mainWindowController] pdfView];
}

#pragma mark Scripting support

- (unsigned int)countOfPages {
    return [[self pdfDocument] pageCount];
}

- (PDFPage *)objectInPagesAtIndex:(unsigned int)index {
    return [[self pdfDocument] pageAtIndex:index];
}

- (NSArray *)notes {
    return [[self mainWindowController] notes];
}

- (void)removeFromNotesAtIndex:(unsigned int)index {
    PDFAnnotation *note = [[self notes] objectAtIndex:index];
    
    [[self pdfView] removeAnnotation:note];
}

- (PDFPage *)currentPage {
    return [[self pdfView] currentPage];
}

- (void)setCurrentPage:(PDFPage *)page {
    return [[self pdfView] goToPage:page];
}

- (id)activeNote {
    id note = [[self pdfView] activeAnnotation];
    return [note isNoteAnnotation] ? note : [NSNull null];
}

- (void)setActiveNote:(id)note {
    if ([note isEqual:[NSNull null]] == NO && [note isNoteAnnotation])
        [[self pdfView] setActiveAnnotation:note];
}

- (NSString *)string {
    return [[self pdfDocument] string];
}

@end


@implementation SKDocumentController

- (NSString *)typeFromFileExtension:(NSString *)fileExtensionOrHFSFileType {
	NSString *type = [super typeFromFileExtension:fileExtensionOrHFSFileType];
    if ([type isEqualToString:SKEmbeddedPDFDocumentType] || [type isEqualToString:SKBarePDFDocumentType]) {
        // fix of bug when reading a PDF file
        // this is interpreted as SKEmbeddedPDFDocumentType, even though we don't declare that as a readable type
        type = NSPDFPboardType;
    }
	return type;
}

@end
