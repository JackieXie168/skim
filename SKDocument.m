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
#import "SKPDFSynchronizer.h"
#import "NSString_SKExtensions.h"
#import "SKDocumentController.h"
#import "SKTemplateParser.h"
#import "SKApplicationController.h"
#import "UKKQueue.h"

// maximum length of xattr value recommended by Apple
#define MAX_XATTR_LENGTH 2048

NSString *SKDocumentErrorDomain = @"SKDocumentErrorDomain";

NSString *SKDocumentWillSaveNotification = @"SKDocumentWillSaveNotification";


@interface SKDocument (Private)

- (void)setPDFData:(NSData *)data;
- (void)setPDFDoc:(PDFDocument *)doc;
- (void)setNoteDicts:(NSArray *)array;
- (void)setLastChangedDate:(NSDate *)date;

- (void)checkFileUpdatesIfNeeded;
- (void)stopCheckingFileUpdatesForFile:(NSString *)fileName;
- (void)handleFileUpdateNotification:(NSNotification *)note;

@end


@implementation SKDocument

- (void)dealloc {
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKAutoCheckFileUpdateKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [synchronizer stopDOServer];
    [synchronizer release];
    [pdfData release];
    [noteDicts release];
    [readNotesAccessoryView release];
    [super dealloc];
}

- (void)makeWindowControllers{
    SKMainWindowController *mainWindowController = [[[SKMainWindowController alloc] initWithWindowNibName:@"MainWindow"] autorelease];
    [mainWindowController setShouldCloseDocument:YES];
    [self addWindowController:mainWindowController];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController{
    SKMainWindowController *mainController =  (SKMainWindowController *)aController;
    
    [mainController setPdfDocument:pdfDocument];
    [self setPDFDoc:nil];
    
    [mainController setAnnotationsFromDictionaries:noteDicts];
    [self setNoteDicts:nil];
    
    [self checkFileUpdatesIfNeeded];
    
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKAutoCheckFileUpdateKey];
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

#pragma mark Document read/write

static NSPopUpButton *popUpButtonSubview(NSView *view)
{
	if ([view isKindOfClass:[NSPopUpButton class]])
		return (NSPopUpButton *)view;
	
	NSEnumerator *viewEnum = [[view subviews] objectEnumerator];
	NSView *subview;
	NSPopUpButton *popup;
	
	while (subview = [viewEnum nextObject]) {
		if (popup = popUpButtonSubview(subview))
			return popup;
	}
	return nil;
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
    NSPopUpButton *formatPopup = popUpButtonSubview([savePanel accessoryView]);
    NSString *lastExportedType = [[NSUserDefaults standardUserDefaults] stringForKey:@"SKLastExportedType"];
    if (formatPopup && lastExportedType) {
        NSString *title = [[NSDocumentController sharedDocumentController] displayNameForType:lastExportedType];
        int index = [formatPopup indexOfItemWithTitle:title];
        if (index != -1 && index != [formatPopup indexOfSelectedItem]) {
            [formatPopup selectItemAtIndex:index];
            [formatPopup sendAction:[formatPopup action] to:[formatPopup target]];
        }
    }
    return YES;
}

- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError{
    if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
        [self stopCheckingFileUpdatesForFile:[self fileName]];
        isSaving = YES;
    } else if (saveOperation == NSSaveToOperation) {
        [[NSUserDefaults standardUserDefaults] setObject:typeName forKey:@"SKLastExportedType"];
    }
    
    BOOL success = [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:outError];
    // we check for notes and may save a .skim as well:
    if (success && [typeName isEqualToString:SKPDFDocumentType]) {
        NSFileManager *fm = [NSFileManager defaultManager];
        
        [self saveNotesToExtendedAttributesAtURL:absoluteURL error:NULL];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoSaveSkimNotesKey]) {
            NSString *notesPath = [[[absoluteURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"skim"];
            BOOL canMove = YES;
            BOOL fileExists = [fm fileExistsAtPath:notesPath];
            
            if (fileExists && (saveOperation == NSSaveAsOperation || saveOperation == NSSaveToOperation)) {
                NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" already exists. Do you want to replace it?", @"Message in alert dialog"), [notesPath lastPathComponent]]
                                                 defaultButton:NSLocalizedString(@"Save", @"Button title")
                                               alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"A file or folder with the same name already exists in %@. Replacing it will overwrite its current contents.", @"Informative text in alert dialog"), [[notesPath stringByDeletingLastPathComponent] lastPathComponent]];
                
                canMove = NSAlertDefaultReturn == [alert runModal];
            }
            
            if (canMove) {
                NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
                if ([self writeToURL:[NSURL fileURLWithPath:tmpPath] ofType:SKNotesDocumentType error:NULL]) {
                    if (fileExists)
                        canMove = [fm removeFileAtPath:notesPath handler:nil];
                    if (canMove)
                        [fm movePath:tmpPath toPath:notesPath handler:nil];
                    else
                        [fm removeFileAtPath:tmpPath handler:nil];
                }
            }
        }
        
        if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeCleared];
            fileChangedOnDisk = NO;
        }
        
    }
    
    if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
        [self checkFileUpdatesIfNeeded];
        isSaving = NO;
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
            *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes", @"Error description"), NSLocalizedDescriptionKey, nil]];
            
    } else if ([typeName isEqualToString:SKNotesRTFDocumentType]) {
        NSData *data = [self notesRTFData];
        if (data)
            didWrite = [data writeToURL:absoluteURL options:NSAtomicWrite error:outError];
        else if (outError != NULL)
            *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes as RTF", @"Error description"), NSLocalizedDescriptionKey, nil]];
    } else if ([typeName isEqualToString:SKNotesTextDocumentType]) {
        NSString *string = [self notesString];
        if (string)
            didWrite = [string writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:outError];
        else if (outError != NULL)
            *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes as text", @"Error description"), NSLocalizedDescriptionKey, nil]];
    }
    return didWrite;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    if ([super revertToContentsOfURL:absoluteURL ofType:typeName error:outError]) {
        [[self mainWindowController] setPdfDocument:pdfDocument];
        [pdfDocument autorelease];
        pdfDocument = nil;
        if (noteDicts) {
            [[self mainWindowController] setAnnotationsFromDictionaries:noteDicts];
            [self setNoteDicts:nil];
        }
        [[self undoManager] removeAllActions];
        return YES;
    } else return NO;
}

- (void)setPDFData:(NSData *)data {
    if (pdfData != data) {
        [pdfData release];
        pdfData = [data retain];
    }
}

- (void)setPDFDoc:(PDFDocument *)doc {
    if (pdfDocument != doc) {
        [pdfDocument release];
        pdfDocument = [doc retain];
    }
}

- (void)setNoteDicts:(NSArray *)array {
    if (noteDicts != array) {
        [noteDicts autorelease];
        noteDicts = [array retain];
    }
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)docType error:(NSError **)outError;
{
    BOOL didRead = NO;
    PDFDocument *pdfDoc = nil;
    NSError *error = nil;
    
    if ([docType isEqualToString:SKPostScriptDocumentType]) {
        SKPSProgressController *progressController = [[[SKPSProgressController alloc] init] autorelease];
        data = [progressController PDFDataWithPostScriptData:data];
    }
    
    if (data)
        pdfDoc = [[PDFDocument alloc] initWithData:data];
    
    [self setPDFData:data];
    [self setPDFDoc:pdfDoc];

    if (pdfDoc) {
        [pdfDoc release];
        didRead = YES;
        [self updateChangeCount:NSChangeDone];
    }
    
    if (didRead == NO && outError != NULL)
        *outError = error ? error : [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
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
                                     informativeTextWithFormat:NSLocalizedString(@"Skim was not able to read the notes at %@. %@ Do you want to continue to open the PDF document anyway?", @"Informative text in alert dialog"), [[absoluteURL path] stringByAbbreviatingWithTildeInPath], [[error userInfo] objectForKey:NSLocalizedDescriptionKey]];
                if ([alert runModal] == NSAlertDefaultReturn) {
                    [data release];
                    data = nil;
                    [pdfDoc release];
                    pdfDoc = nil;
                }
            } else if ([noteDicts count] == 0) {
                NSString *path = [[[absoluteURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"skim"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    int readOption = [[NSUserDefaults standardUserDefaults] integerForKey:SKReadMissingNotesFromSkimFileOptionKey];
                    if (readOption == NSAlertOtherReturn) {
                        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Found Separate Notes", @"Message in alert dialog") 
                                                         defaultButton:NSLocalizedString(@"Yes", @"Button title")
                                                       alternateButton:NSLocalizedString(@"No", @"Button title")
                                                           otherButton:nil
                                             informativeTextWithFormat:NSLocalizedString(@"Unable to read notes for %@, but a Skim notes file with the same name was found.  Do you want Skim to read the notes from this file?", @"Informative text in alert dialog"), [[absoluteURL path] stringByAbbreviatingWithTildeInPath]];
                        readOption = [alert runModal];
                    }
                    if (readOption == NSAlertDefaultReturn) {
                        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
                        if (array) {
                            [self setNoteDicts:array];
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
            [self setPDFData:data];
            [self setPDFDoc:pdfDoc];
            [pdfDoc release];
            [data release];
            fileChangedOnDisk = NO;
        } else {
            [self setPDFData:nil];
        }
    }
    
    if (didRead == NO && outError != NULL)
        *outError = error ? error : [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
    return didRead;
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
        if ([fm removeExtendedAttribute:@"net_sourceforge_skim-app_notes" atPath:path traverseLink:YES error:&error] == NO) {
            // should we set success to NO and return an error?
            //NSLog(@"%@: %@", self, error);
        }
        
        NSMutableArray *rootObject = [NSMutableArray array];
        for (i = 0; success && i < numberOfNotes; i++) {
            [rootObject addObject:[[notes objectAtIndex:i] dictionaryValue]];
        }
        data = [NSKeyedArchiver archivedDataWithRootObject:rootObject];
        if ([fm setExtendedAttributeNamed:@"net_sourceforge_skim-app_notes" toValue:data atPath:path options:nil error:&error] == NO) {
            success = NO;
            if (outError) *outError = error;
            NSLog(@"%@: %@", self, error);
        }
        [fm setExtendedAttributeNamed:@"net_sourceforge_skim-app_rtf_notes" toValue:[self notesRTFData] atPath:path options:0 error:NULL];
        [fm setExtendedAttributeNamed:@"net_sourceforge_skim-app_text_notes" toPropertyListValue:[self notesString] atPath:path options:0 error:NULL];
    }
    return success;
}

- (BOOL)readNotesFromExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = YES;
    NSError *error = nil;
    
    if ([aURL isFileURL]) {

        NSData *data = [fm extendedAttributeNamed:@"net_sourceforge_skim-app_notes" atPath:[aURL path] traverseLink:YES error:&error];
        
        if ([data length])
            [self setNoteDicts:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        else
            [self setNoteDicts:nil];
        
    } else {
        success = NO;
        if(error == nil && outError) 
            *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"The file does not exist or is not a file.", @"Error description"), NSLocalizedDescriptionKey, nil]];
    }
    if (success == NO) {
        [self setNoteDicts:nil];
    }
    return success;
}

#pragma mark Actions

- (void)openPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo{
    if (returnCode == NSOKButton) {
        NSURL *notesURL = [[oPanel URLs] objectAtIndex:0];
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile:[notesURL path]];
        
        if (array) {
            if ([[oPanel accessoryView] isEqual:readNotesAccessoryView] && [replaceNotesCheckButton state] == NSOnState)
                [[self mainWindowController] setAnnotationsFromDictionaries:array];
            else
                [[self mainWindowController] addAnnotationsFromDictionaries:array];
            // previous undo actions are not reliable anymore
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeDone];
        }
        
    }
}

- (IBAction)readNotes:(id)sender{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    NSString *path = [[self fileURL] path];
    
    if ([[[self mainWindowController] notes] count]) {
        if (readNotesAccessoryView == nil) {
            if (NO == [NSBundle loadNibNamed:@"ReadNotesAccessoryView" owner:self])
                NSLog(@"Failed to load ReadNotesAccessoryView.nib");
            [readNotesAccessoryView retain];
        }
        [oPanel setAccessoryView:readNotesAccessoryView];
        [replaceNotesCheckButton setState:NSOnState];
    }
    
    [oPanel beginSheetForDirectory:[path stringByDeletingLastPathComponent]
                              file:[[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"skim"]
                             types:[NSArray arrayWithObject:@"skim"]
                    modalForWindow:[self windowForSheet]
                     modalDelegate:self
                    didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo:NULL];		
}

- (void)archiveSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
    
    if (NSOKButton == returnCode && [self fileURL]) {
                            
        @try {            
            // create a tar archive; make sure we use a relative path in the archive
            NSTask *task = [[[NSTask alloc] init] autorelease];
            [task setLaunchPath:@"/usr/bin/tar"];
            [task setCurrentDirectoryPath:[[[self fileURL] path] stringByDeletingLastPathComponent]];
            [task setArguments:[NSArray arrayWithObjects:@"-czf", [sheet filename], [[[self fileURL] path] lastPathComponent], nil]];
            [task launch];
            // just in case this is a really huge file, we don't want the user to move it before tar completes
            if ([task isRunning])
                [task waitUntilExit];
        }
        @catch(id exception) {
            NSLog(@"caught exception %@ while archiving %@ to %@", exception, [[self fileURL] path], [sheet filename]);
        }
    }
}

- (IBAction)saveArchive:(id)sender {
    NSString *path = [[self fileURL] path];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path] && [self isDocumentEdited] == NO) {
        NSSavePanel *sp = [NSSavePanel savePanel];
        [sp setRequiredFileType:@"tgz"];
        [sp setCanCreateDirectories:YES];
        [sp beginSheetForDirectory:nil
                              file:[[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"tgz"]
                    modalForWindow:[self windowForSheet]
                     modalDelegate:self
                    didEndSelector:@selector(archiveSavePanelDidEnd:returnCode:contextInfo:)
                       contextInfo:NULL];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"You must save this file first", @"Alert text when trying to create archive for unsaved document") defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The document has unsaved changes, or has not previously been saved to disk.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (void)revertAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSError *error = nil;
        if (NO == [self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:&error]) {
            [[alert window] orderOut:nil];
            [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
        }
    }
}

- (void)revertDocumentToSaved:(id)sender { 	 
     if ([self fileName]) { 	 
         if ([self isDocumentEdited]) { 	 
             [super revertDocumentToSaved:sender]; 	 
         } else if (fileChangedOnDisk) { 	 
             NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Do you want to revert to the version of the document \"%@\" on disk?", @"Message in alert dialog"), [[self fileName] lastPathComponent]] 	 
                                              defaultButton:NSLocalizedString(@"Revert", @"Button title") 	 
                                            alternateButton:NSLocalizedString(@"Cancel", @"Button title") 	 
                                                otherButton:nil 	 
                                  informativeTextWithFormat:NSLocalizedString(@"Your current changes will be lost.", @"Informative text in alert dialog")]; 	 
             [alert beginSheetModalForWindow:[[self mainWindowController] window] 	 
                               modalDelegate:self 	 
                              didEndSelector:@selector(revertAlertDidEnd:returnCode:contextInfo:) 	 
                                 contextInfo:NULL]; 	 
         } 	 
     } 	 
 }

- (void)performFindPanelAction:(id)sender {
    [[SKFindController sharedFindController] performFindPanelAction:sender];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
	if ([anItem action] == @selector(performFindPanelAction:)) {
        return [[SKFindController sharedFindController] validateUserInterfaceItem:anItem];
	} else if ([anItem action] == @selector(revertDocumentToSaved:)) {
        if (fileChangedOnDisk && [self fileName])
            return YES;
    }
    return [super validateUserInterfaceItem:anItem];
}

#pragma mark File update checking

- (void)handleFileMoveNotification:(NSNotification *)note {
    [self stopCheckingFileUpdatesForFile:[[note userInfo] objectForKey:@"path"]];
    // If the file is moved, NSDocument will notice and will call setFileURL, where we start watching again
}

- (void)stopCheckingFileUpdatesForFile:(NSString *)fileName {
    if (fileName) {
        [[UKKQueue sharedFileWatcher] removePath:fileName];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:UKFileWatcherWriteNotification object:fileName];
        [nc removeObserver:self name:UKFileWatcherRenameNotification object:fileName];
        [nc removeObserver:self name:UKFileWatcherDeleteNotification object:fileName];
    }
}

- (void)checkFileUpdatesIfNeeded {
    BOOL autoUpdatePref = [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey];
    NSString *fileName = [self fileName];
    
    if (fileName) {
        [self stopCheckingFileUpdatesForFile:fileName];
        if (autoUpdatePref) {
            [[UKKQueue sharedFileWatcher] addPath:[self fileName]];
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc addObserver:self selector:@selector(handleFileUpdateNotification:) name:UKFileWatcherWriteNotification object:fileName];
            [nc addObserver:self selector:@selector(handleFileMoveNotification:) name:UKFileWatcherRenameNotification object:fileName];
            [nc addObserver:self selector:@selector(handleFileMoveNotification:) name:UKFileWatcherDeleteNotification object:fileName];
        }
    }
}

- (void)fileUpdateAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    
    if (returnCode == NSAlertOtherReturn) {
        autoUpdate = NO;
    } else {
        NSError *error = nil;
        if (NO == [self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:&error]) {
            if (autoUpdate == NO) {
                [[alert window] orderOut:nil];
                [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
            }
        }
        if (returnCode == NSAlertAlternateReturn)
            autoUpdate = YES;
    }
}

- (void)handleFileUpdateNotification:(NSNotification *)note {
    
    // should never happen
    if ([[[note userInfo] objectForKey:@"path"] isEqual:[self fileName]] == NO)
        NSLog(@"*** received change notice for %@", [note object]);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey] &&
        [fm fileExistsAtPath:[self fileName]]) {
        
        fileChangedOnDisk = YES;
        
        NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:[self fileName]];
        unsigned long long fileEnd = [fh seekToEndOfFile];
        unsigned long long startPos = fileEnd < 1024 ? fileEnd : fileEnd - 1024;
        [fh seekToFileOffset:startPos];
        NSData *trailerData = [fh readDataToEndOfFile];
        const char *pattern = "%%EOF";
        unsigned patternLength = strlen(pattern);
        BOOL foundTrailer = NO;

        // adapted from OmniFoundation
        if ([trailerData length] > patternLength) {
            unsigned const char *bufferStart = [trailerData bytes];
            unsigned const char *ptr = bufferStart;
            unsigned const char *ptrEnd = bufferStart + fileEnd - startPos - patternLength;
            
            for (;;) {
                if (memcmp(ptr, pattern, patternLength) == 0) {
                    foundTrailer = YES;
                    break;
                }
                
                ptr++;
                if (ptr == ptrEnd)
                    break;
                ptr = memchr(ptr, *(const char *)pattern, (ptrEnd - ptr));
                if (!ptr)
                    break;
            }
        }
            
        if (foundTrailer) {
            if (autoUpdate && [self isDocumentEdited] == NO) {
                [self fileUpdateAlertDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:NULL];
            } else {
                NSString *message;
                if ([self isDocumentEdited])
                    message = NSLocalizedString(@"The PDF file has changed on disk. If you reload, your changes will be lost. Do you want to reload this document now?", @"Informative text in alert dialog");
                else 
                    message = NSLocalizedString(@"The PDF file has changed on disk. Do you want to reload this document now? Choosing Auto will reload this file automatically for future changes.", @"Informative text in alert dialog");
                
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"File Updated", @"Message in alert dialog") 
                                                 defaultButton:NSLocalizedString(@"Yes", @"Button title")
                                               alternateButton:NSLocalizedString(@"Auto", @"Button title")
                                                   otherButton:NSLocalizedString(@"No", @"Button title")
                                     informativeTextWithFormat:message];
                [alert beginSheetModalForWindow:[self windowForSheet]
                                  modalDelegate:self
                                 didEndSelector:@selector(fileUpdateAlertDidEnd:returnCode:contextInfo:) 
                                    contextInfo:NULL];
            }
        }
    }    
}

#pragma mark Notification observation

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

- (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    NSWindow *window = [notification object];
    // ignore when we're switching fullscreen/main windows
    if ([window isEqual:[[window windowController] window]]) {
        [[UKKQueue sharedFileWatcher] removePath:[self fileName]];
    }
}

#pragma mark Pdfsync support

- (void)setFileURL:(NSURL *)absoluteURL {
    // this shouldn't be necessary, but better be sure
    if ([self fileName] && [[self fileURL] isEqual:absoluteURL] == NO)
        [self stopCheckingFileUpdatesForFile:[self fileName]];
    [super setFileURL:absoluteURL];
    if ([absoluteURL isFileURL])
        [synchronizer setFileName:[[[absoluteURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdfsync"]];
    else
        [synchronizer setFileName:nil];
    // if we're saving this will be called when saving has finished
    if (isSaving == NO)
        [self checkFileUpdatesIfNeeded];
}

- (SKPDFSynchronizer *)synchronizer {
    if (synchronizer == nil) {
        synchronizer = [[SKPDFSynchronizer alloc] init];
        [synchronizer setDelegate:self];
        [synchronizer setFileName:[[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdfsync"]];
    }
    return synchronizer;
}

- (void)synchronizer:(SKPDFSynchronizer *)synchronizer foundLine:(int)line inFile:(NSString *)file {
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        
        NSString *editorPreset = [[NSUserDefaults standardUserDefaults] objectForKey:SKTeXEditorPresetKey];
        NSString *editorCmd = [[NSUserDefaults standardUserDefaults] objectForKey:SKTeXEditorCommandKey];
        NSMutableString *cmdString = [[[[NSUserDefaults standardUserDefaults] objectForKey:SKTeXEditorArgumentsKey] mutableCopy] autorelease];
        
        if ([editorPreset isEqualToString:@""] == NO) {
            NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:editorPreset];
            NSString *toolPath = appPath ? [NSBundle pathForResource:editorCmd ofType:nil inDirectory:appPath] : nil;
            if (toolPath) {
               editorCmd = toolPath;
            } else {
                // Emacs has its tool in Emacs.app/Contents/MacOS/bin/
                toolPath = [[[[[NSBundle bundleWithPath:appPath] executablePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"bin"] stringByAppendingPathComponent:editorCmd];
                if ([[NSFileManager defaultManager] isExecutableFileAtPath:toolPath])
                    editorCmd = toolPath;
            }
        }
        
        [cmdString replaceOccurrencesOfString:@"%file" withString:file options:NSLiteralSearch range: NSMakeRange(0, [cmdString length] )];
        [cmdString replaceOccurrencesOfString:@"%line" withString:[NSString stringWithFormat:@"%d", line] options:NSLiteralSearch range:NSMakeRange(0, [cmdString length])];
        [cmdString insertString:@"\" " atIndex:0];
        [cmdString insertString:editorCmd atIndex:0];
        [cmdString insertString:@"\"" atIndex:0];
        NSTask *task = [[[NSTask alloc] init] autorelease];
        [task setLaunchPath:@"/bin/sh"];
        [task setArguments:[NSArray arrayWithObjects:@"-c", cmdString, nil]];
        [task setCurrentDirectoryPath:[file stringByDeletingLastPathComponent]];
        [task launch];
    }
}

- (void)synchronizer:(SKPDFSynchronizer *)synchronizer foundLocation:(NSPoint)point atPageIndex:(unsigned int)pageIndex {
   [[self pdfView] displayLineAtPoint:point inPageAtIndex:pageIndex];
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

- (void)findString:(NSString *)string options:(int)options{
    [[self mainWindowController] findString:string options:options];
}

- (SKPDFView *)pdfView {
    return [[self mainWindowController] pdfView];
}

- (NSString *)notesString {
    NSString *templatePath = [[NSApp delegate] pathForApplicationSupportFile:@"notesTemplate" ofType:@"txt"];
    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSError *error = nil;
    NSString *templateString = [[NSString alloc] initWithContentsOfFile:templatePath encoding:encoding error:&error];
    NSString *string = [SKTemplateParser stringByParsingTemplate:templateString usingObject:self];
    [templateString release];
    return string;
}

- (NSData *)notesRTFData {
    NSString *templatePath = [[NSApp delegate] pathForApplicationSupportFile:@"notesTemplate" ofType:@"rtf"];
    NSDictionary *docAttributes = nil;
    NSAttributedString *templateAttrString = [[NSAttributedString alloc] initWithPath:templatePath documentAttributes:&docAttributes];
    NSAttributedString *attrString = [SKTemplateParser attributedStringByParsingTemplate:templateAttrString usingObject:self];
    NSData *data = [attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:docAttributes];
    [templateAttrString release];
    return data;
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
    [[self undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
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

- (id)handleRevertScriptCommand:(NSScriptCommand *)command {
    if ([self fileURL] && [[NSFileManager defaultManager] fileExistsAtPath:[self fileName]]) {
        if ([self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:NULL] == NO) {
            [command setScriptErrorNumber:NSInternalScriptError];
            [command setScriptErrorString:@"Revert failed."];
        }
    } else {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"File does not exist."];
    }
    return nil;
}

@end


@interface NSWindow (SKScriptingExtensions)
- (id)handleRevertScriptCommand:(NSScriptCommand *)command;
@end

@implementation NSWindow (SKScriptingExtensions)

- (id)handleRevertScriptCommand:(NSScriptCommand *)command {
    id document = [[self windowController] document];
    if (document == nil) {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"Window does not have a document."];
        return nil;
    } else
        return [document handleRevertScriptCommand:command];
}

@end
