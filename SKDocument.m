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

// maximum length of xattr value recommended by Apple
#define MAX_XATTR_LENGTH 2048

NSString *SKDocumentErrorDomain = @"SKDocumentErrorDomain";

// See CFBundleTypeName in Info.plist
static NSString *SKPDFDocumentType = nil; /* set to NSPDFPboardType, not @"NSPDFPboardType" */
static NSString *SKEmbeddedPDFDocumentType = @"PDF With Embedded Notes";
static NSString *SKBarePDFDocumentType = @"PDF Without Notes";
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
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKAutoCheckFileUpdateKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [pdfData release];
    [notes release];
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


- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError{
    BOOL success = [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:outError];
    // we check for notes and save a .skim as well:
    if (success && [typeName isEqualToString:SKPDFDocumentType]) {
       [self saveNotesToExtendedAttributesAtURL:absoluteURL error:NULL];
       if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
            [self updateChangeCount:NSChangeCleared];
            [lastChangedDate release];
            lastChangedDate = [[NSDate alloc] init];
        }
    }
    
    return success;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
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
        NSData *data = [self notesData];
        if (data != nil)
            didWrite = [data writeToURL:absoluteURL options:NSAtomicWrite error:outError];
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

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)docType error:(NSError **)outError{
    BOOL didRead = NO;
    if ([docType isEqualToString:SKPDFDocumentType]) {
        NSData *data = [[NSData alloc] initWithContentsOfURL:absoluteURL];
        PDFDocument *pdfDoc = [[PDFDocument alloc] initWithURL:absoluteURL];
        if (data && pdfDoc) {
            if (didRead = [self readNotesFromExtendedAttributesAtURL:absoluteURL error:outError]) {
                [pdfData release];
                pdfData = data;    
                [pdfDocument release];
                pdfDocument = pdfDoc;
                [[self mutableArrayValueForKey:@"notes"] removeAllObjects];
                [lastChangedDate release];
                lastChangedDate = [[[[NSFileManager defaultManager] fileAttributesAtPath:[absoluteURL path] traverseLink:YES] fileModificationDate] retain];
            }
        }
    } else if ([docType isEqualToString:SKPostScriptDocumentType]) {
        NSData *data = [[NSData alloc] initWithContentsOfURL:absoluteURL];
        PDFDocument *pdfDoc = nil;
        if (data) {
            SKPSProgressController *progressController = [[SKPSProgressController alloc] init];
            data = [[progressController PDFDataWithPostScriptData:data] retain];
            [progressController autorelease];
            if (data && (pdfDoc = [[PDFDocument alloc] initWithData:data])) {
                [pdfData release];
                pdfData = data;    
                [pdfDocument release];
                pdfDocument = pdfDoc;
            }
        }
    }
    if (NO == didRead && outError && *outError == nil)
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @""), NSLocalizedDescriptionKey, nil]];
    return didRead;
}

- (void)openPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo{
    if (returnCode == NSOKButton) {
        NSURL *notesURL = [[oPanel URLs] objectAtIndex:0];
        
        if ([self readNotesFromData:[NSKeyedUnarchiver unarchiveObjectWithFile:[notesURL path]]] && noteDicts) {
            [[self mainWindowController] setAnnotationsFromDictionaries:noteDicts];
            [noteDicts release];
            noteDicts = nil;
        }
        
        [self updateChangeCount:NSChangeDone];
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
    
    if ([aURL isFileURL]) {
        NSString *path = [aURL path];
        int i, j, n, numberOfNotes = [notes count];
        NSArray *oldNotes = [fm extendedAttributeNamesAtPath:path traverseLink:YES error:NULL];
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:numberOfNotes], @"numberOfNotes", nil];
        NSMutableDictionary *longNotes = [NSMutableDictionary dictionary];
        NSString *name = nil;
        NSData *data = nil;
        NSError *error = nil;
        
        // first remove all old notes
        n = [oldNotes count];
        for (i = 0; i < n; i++) {
            name = [oldNotes objectAtIndex:i];
            if ([name hasPrefix:@"net_sourceforge_bibdesk_skim_note-"]) {
                if ([fm removeExtendedAttribute:name atPath:path traverseLink:YES error:&error] == NO) {
                    // should we set success to NO and return an error?
                    //NSLog(@"%@: %@", self, error);
                }
            }
        }
        
        for (i = 0; success && i < numberOfNotes; i++) {
            name = [NSString stringWithFormat:@"net_sourceforge_bibdesk_skim_note-%i", i];
            data = [NSKeyedArchiver archivedDataWithRootObject:[[notes objectAtIndex:i] dictionaryValue]];
            if ([data length] > MAX_XATTR_LENGTH) {
                n = ceil([data length] / MAX_XATTR_LENGTH);
                NSData *subdata;
                for (j = 0; success && j < n; j++) {
                    name = [NSString stringWithFormat:@"net_sourceforge_bibdesk_skim_note-%i-%i", i, j];
                    subdata = [data subdataWithRange:NSMakeRange(j * MAX_XATTR_LENGTH, j == n - 1 ? [data length] - j * MAX_XATTR_LENGTH : MAX_XATTR_LENGTH)];
                    if ([fm setExtendedAttributeNamed:name toValue:subdata atPath:path options:nil error:&error] == NO) {
                        success = NO;
                        if (outError) *outError = error;
                        //NSLog(@"%@: %@", self, error);
                        while (j--) {
                            name = [NSString stringWithFormat:@"net_sourceforge_bibdesk_skim_note-%i-%i", i, j];
                            [fm removeExtendedAttribute:name atPath:path traverseLink:YES error:NULL];
                        }
                    }                    
                }
                [longNotes setObject:[NSNumber numberWithInt:j] forKey:[NSString stringWithFormat:@"%i", i]];
            } else if ([fm setExtendedAttributeNamed:name toValue:data atPath:path options:nil error:&error] == NO) {
                success = NO;
                if (outError) *outError = error;
                //NSLog(@"%@: %@", self, error);
            }
        }
        
        if (success == NO || [notes count] == 0) {
            if ([fm removeExtendedAttribute:@"net_sourceforge_bibdesk_skim_notesInfo" atPath:path traverseLink:YES error:&error] == NO) {
                success = NO;
                if (outError) *outError = error;
                //NSLog(@"%@: %@", self, error);
            }
        } else {
            dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:numberOfNotes], @"numberOfNotes", [longNotes count] ? longNotes : nil, @"longNotes", nil];
            if ([fm setExtendedAttributeNamed:@"net_sourceforge_bibdesk_skim_notesInfo" toPropertyListValue:dictionary atPath:path options:nil error:&error] == NO) {
                success = NO;
                if (outError) *outError = error;
                //NSLog(@"%@: %@", self, error);
            }
        }
    }
    return success;
}

- (BOOL)readNotesFromExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *dict = nil;
    BOOL success = YES;
    NSError *error = nil;
    
    if ([aURL isFileURL]) {
        dict = [fm propertyListFromExtendedAttributeNamed:@"net_sourceforge_bibdesk_skim_notesInfo" atPath:[aURL path] traverseLink:YES error:&error];
        if (dict != nil) {
            int i, numberOfNotes = [[dict objectForKey:@"numberOfNotes"] intValue];
            NSDictionary *longNotes = [dict objectForKey:@"longNotes"];
            NSString *name = nil;
            int n;
            NSData *data = nil;
            
            if (noteDicts)
                [noteDicts release];
            noteDicts = [[NSMutableArray alloc] initWithCapacity:numberOfNotes];
            
            for (i = 0; success && i < numberOfNotes; i++) {
                n = [[longNotes objectForKey:[NSString stringWithFormat:@"%i", i]] intValue];
                if (n == 0) {
                    name = [NSString stringWithFormat:@"net_sourceforge_bibdesk_skim_note-%i", i];
                    if ((data = [fm extendedAttributeNamed:name atPath:[aURL path] traverseLink:YES error:&error]) &&
                        (dict = [NSKeyedUnarchiver unarchiveObjectWithData:data])) {
                        [noteDicts addObject:dict];
                    } else {
                        success = NO;
                        if (outError) *outError = error;
                        //NSLog(@"%@: %@", self, error);
                    }
                } else {
                    NSMutableData *mutableData = [NSMutableData dataWithCapacity:n * MAX_XATTR_LENGTH];
                    int j;
                    for (j = 0; success && j < n; j++) {
                        name = [NSString stringWithFormat:@"net_sourceforge_bibdesk_skim_note-%i-%i", i, j];
                        if (data = [fm extendedAttributeNamed:name atPath:[aURL path] traverseLink:YES error:&error]) {
                            [mutableData appendData:data];
                        } else {
                            success = NO;
                            if (outError) *outError = error;
                            //NSLog(@"%@: %@", self, error);
                        }
                    }
                    if (dict = [NSKeyedUnarchiver unarchiveObjectWithData:mutableData]) {
                        [noteDicts addObject:dict];
                    } else {
                        success = NO;
                        if (outError) *outError = error;
                        //NSLog(@"%@: %@", self, error);
                    }
                }
            }
        }
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
    NSData *data = [[BDAlias aliasWithPath:fileName] aliasData];

    [setup setObject:fileName forKey:@"fileName"];
    if(data)
         [setup setObject:data forKey:@"_BDAlias"];
    
    [setup addEntriesFromDictionary:[[self mainWindowController] currentSetup]];
    
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

- (PDFView *)pdfView {
    return [[self mainWindowController] pdfView];
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

