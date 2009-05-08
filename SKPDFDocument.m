//
//  SKPDFDocument.m
//  Skim
//
//  Created by Michael McCracken on 12/5/06.
/*
 This software is Copyright (c) 2006-2009
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

#import "SKPDFDocument.h"
#import <Quartz/Quartz.h>
#import <Carbon/Carbon.h>
#import <SkimNotes/SkimNotes.h>
#import "SKMainWindowController.h"
#import "PDFAnnotation_SKExtensions.h"
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKConversionProgressController.h"
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
#import "PDFSelection_SKExtensions.h"
#import "SKInfoWindowController.h"
#import "SKLine.h"
#import "SKApplicationController.h"
#import "Files_SKExtensions.h"
#import "NSTask_SKExtensions.h"
#import "SKFDFParser.h"
#import "NSData_SKExtensions.h"
#import "SKProgressController.h"
#import "NSView_SKExtensions.h"
#import <Security/Security.h>
#import "SKBookmarkController.h"
#import "PDFPage_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "SKSnapshotWindowController.h"
#import "NSDocument_SKExtensions.h"
#import "SKApplication.h"
#import "NSResponder_SKExtensions.h"
#import "SKRuntime.h"
#import "SKTextFieldSheetController.h"

#define BUNDLE_DATA_FILENAME @"data"
#define OPEN_META_TAGS_KEY @"com.apple.metadata:kOMUserTags"
#define OPEN_META_RATING_KEY @"com.apple.metadata:kOMStarRating"

NSString *SKSkimFileDidSaveNotification = @"SKSkimFileDidSaveNotification";

#define SKLastExportedTypeKey @"SKLastExportedType"
#define SKAutoReloadFileUpdateKey @"SKAutoReloadFileUpdate"
#define SKAutoRotatePrintedPagesKey @"SKAutoRotatePrintedPages"
#define SKDisableReloadAlertKey @"SKDisableReloadAlert"

static char SKPDFDocumentDefaultsObservationContext;

@interface SKPDFDocument (SKPrivate)

- (void)setPDFData:(NSData *)data;
- (void)setPSOrDVIData:(NSData *)data;
- (void)setPDFDoc:(PDFDocument *)doc;
- (void)setNoteDicts:(NSArray *)array;
- (void)setOpenMetaTags:(NSArray *)array;
- (void)setOpenMetaRating:(double)rating;

- (BOOL)tryToUnlockDocument:(PDFDocument *)document;

- (void)checkFileUpdatesIfNeeded;
- (void)stopCheckingFileUpdates;
- (void)fileUpdated;
- (void)handleFileUpdateNotification:(NSNotification *)notification;
- (void)handleFileMoveNotification:(NSNotification *)notification;
- (void)handleFileDeleteNotification:(NSNotification *)notification;
- (void)handleWindowDidEndSheetNotification:(NSNotification *)notification;
- (void)handleWindowWillCloseNotification:(NSNotification *)notification;
- (void)handleDidRemoveDocumentNotification:(NSNotification *)notification;

- (SKProgressController *)progressController;

@end

#pragma mark -

@implementation SKPDFDocument

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [mainWindowController release];
    [synchronizer stopDOServer];
    [synchronizer release];
    [presentationNotesDocument release];
    [watchedFile release];
    [pdfData release];
    [psOrDviData release];
    [pdfDocument release];
    [noteDicts release];
    [openMetaTags release];
    [readNotesAccessoryView release];
    [lastModifiedDate release];
    [progressController release];
    [autoRotateButton release];
    [super dealloc];
}

- (void)makeWindowControllers{
    mainWindowController = [[SKMainWindowController alloc] init];
    [mainWindowController setShouldCloseDocument:YES];
    [self addWindowController:mainWindowController];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController{
    SKMainWindowController *mainController = (SKMainWindowController *)aController;
    
    if ([pdfDocument isLocked])
        [self tryToUnlockDocument:pdfDocument];
    
    if ([pdfDocument pageCount]) {
        BOOL autoRotate = (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4) ? [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoRotatePrintedPagesKey] : YES;
        PDFPage *page = [pdfDocument pageAtIndex:0];
        NSPrintInfo *printInfo = [self printInfo];
        NSSize pageSize = [page boundsForBox:kPDFDisplayBoxMediaBox].size;
        BOOL isLandscape = [page rotation] % 180 == 90 ? pageSize.height > pageSize.width : pageSize.width > pageSize.height;
        
        printInfo = [printInfo copy];
        [[printInfo dictionary] setValue:[NSNumber numberWithBool:autoRotate] forKey:@"PDFPrintAutoRotate"];
        if (isLandscape)
            [printInfo setOrientation:NSLandscapeOrientation];
        [self setPrintInfo:printInfo];
        [printInfo release];
    }
    
    [mainController setPdfDocument:pdfDocument];
    [self setPDFDoc:nil];
    
    [mainController setAnnotationsFromDictionaries:noteDicts undoable:NO];
    [self setNoteDicts:nil];
    
    [mainController setOpenMetaTags:openMetaTags];
    [self setOpenMetaTags:nil];
    
    [mainController setOpenMetaRating:openMetaRating];
    [self setOpenMetaRating:0.0];
    
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKey:SKAutoCheckFileUpdateKey context:&SKPDFDocumentDefaultsObservationContext];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowWillCloseNotification:) 
                                                 name:NSWindowWillCloseNotification object:[mainController window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidRemoveDocumentNotification:) 
                                                 name:SKDocumentControllerDidRemoveDocumentNotification object:nil];
}

- (void)showWindows{
    [super showWindows];
    
    // Get the search string keyword if available (Spotlight passes this)
    NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    NSString *searchString;
    
    if ([event eventID] == kAEOpenDocuments && 
        (searchString = [[event descriptorForKeyword:keyAESearchText] stringValue]) && 
        [@"" isEqualToString:searchString] == NO) {
        [[self mainWindowController] displaySearchResultsForString:searchString];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentDidShowNotification object:self];
}

- (void)removeWindowController:(NSWindowController *)windowController {
    if ([windowController isEqual:mainWindowController]) {
        // we need to do this on Tiger, because windowWillClose notifications are posted after this
        [self saveRecentDocumentInfo];
        [mainWindowController release];
        mainWindowController = nil;
    }
    [super removeWindowController:windowController];
}

- (SKProgressController *)progressController {
    if (progressController == nil)
        progressController = [[SKProgressController alloc] init];
    return progressController;
}

- (void)saveRecentDocumentInfo {
    NSString *path = [[self fileURL] path];
    NSUInteger pageIndex = [[[self pdfView] currentPage] pageIndex];
    if (path && pageIndex != NSNotFound && [self mainWindowController])
        [[SKBookmarkController sharedBookmarkController] addRecentDocumentForPath:path pageIndex:pageIndex snapshots:[[[self mainWindowController] snapshots] valueForKey:SKSnapshotCurrentSetupKey]];
}

- (void)undoableActionDoesntDirtyDocumentDeferred:(NSNumber *)anUndoState {
	[self updateChangeCount:[anUndoState boolValue] ? NSChangeDone : NSChangeUndone];
    // this should be automatic, but Leopard does not seem to do this
    if ([[self valueForKey:@"changeCount"] intValue] == 0)
        [self updateChangeCount:NSChangeCleared];
}

- (void)undoableActionDoesntDirtyDocument {
	// This action, while undoable, shouldn't mark the document dirty
	BOOL isUndoing = [[self undoManager] isUndoing];
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4) {
		[self updateChangeCount:isUndoing ? NSChangeDone : NSChangeUndone];
	} else {
		[self performSelector:@selector(undoableActionDoesntDirtyDocumentDeferred:) withObject:[NSNumber numberWithBool:isUndoing] afterDelay:0.0];
	}
}

#pragma mark Document read/write

- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation {
    NSMutableArray *writableTypes = [[[super writableTypesForSaveOperation:saveOperation] mutableCopy] autorelease];
    if (SKIsPostScriptDocumentType([self fileType]) == NO) {
        [writableTypes removeObject:SKPostScriptDocumentType];
        [writableTypes removeObject:SKBarePostScriptDocumentType];
    }
    if (SKIsDVIDocumentType([self fileType]) == NO) {
        [writableTypes removeObject:SKDVIDocumentType];
        [writableTypes removeObject:SKBareDVIDocumentType];
    }
    if (saveOperation == NSSaveToOperation) {
        [[NSDocumentController sharedDocumentController] resetCustomExportTemplateFiles];
        [writableTypes addObjectsFromArray:[[NSDocumentController sharedDocumentController] customExportTemplateFiles]];
    }
    return writableTypes;
}

- (NSString *)fileNameExtensionForType:(NSString *)typeName saveOperation:(NSSaveOperationType)saveOperation {
    NSString *fileExtension = nil;
    if ([[SKPDFDocument superclass] instancesRespondToSelector:_cmd]) {
        fileExtension = [super fileNameExtensionForType:typeName saveOperation:saveOperation];
        if (fileExtension == nil && [[[NSDocumentController sharedDocumentController] customExportTemplateFiles] containsObject:typeName])
            fileExtension = [typeName pathExtension];
    } else {
        NSArray *fileExtensions = [[NSDocumentController sharedDocumentController] fileExtensionsFromType:typeName];
        if ([fileExtensions count])
            fileExtension = [fileExtensions objectAtIndex:0];
    }
    return fileExtension;
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
    BOOL success = [super prepareSavePanel:savePanel];
    if (success && docFlags.exportUsingPanel) {
        NSPopUpButton *formatPopup = [[savePanel accessoryView] subviewOfClass:[NSPopUpButton class]];
        if (formatPopup) {
            NSString *lastExportedType = [[NSUserDefaults standardUserDefaults] stringForKey:SKLastExportedTypeKey];
            if ([[self pdfDocument] allowsPrinting] == NO) {
                NSInteger idx = [formatPopup indexOfItemWithRepresentedObject:SKEmbeddedPDFDocumentType];
                if (idx != -1)
                    [formatPopup removeItemAtIndex:idx];
            }
            if (lastExportedType) {
                NSInteger idx = [formatPopup indexOfItemWithRepresentedObject:lastExportedType];
                if (idx != -1 && idx != [formatPopup indexOfSelectedItem]) {
                    [formatPopup selectItemAtIndex:idx];
                    [formatPopup sendAction:[formatPopup action] to:[formatPopup target]];
                    [savePanel setAllowedFileTypes:[NSArray arrayWithObjects:[self fileNameExtensionForType:lastExportedType saveOperation:NSSaveToOperation], nil]];
                }
            }
        }
    }
    return success;
}

- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo { 
    docFlags.exportUsingPanel = NO;
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    // Override so we can determine if this is a save, saveAs or export operation, so we can prepare the correct accessory view
    docFlags.exportUsingPanel = (saveOperation == NSSaveToOperation);
    [super runModalSavePanelForSaveOperation:saveOperation delegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:NULL];
}

- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError{
    if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
        [self stopCheckingFileUpdates];
        docFlags.isSaving = YES;
    } else if (docFlags.exportUsingPanel) {
        [[NSUserDefaults standardUserDefaults] setObject:typeName forKey:SKLastExportedTypeKey];
    }
    
    BOOL success = NO;
    NSError *error = nil;
    
    // we check for notes and may save a .skim as well:
    if (SKIsPDFDocumentType(typeName) || SKIsPostScriptDocumentType(typeName) || SKIsDVIDocumentType(typeName)) {
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        if (success = [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:&error]) {
            
            BOOL saveNotesOK = NO;
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoSaveSkimNotesKey]) {
                NSString *notesPath = [[absoluteURL path] stringByReplacingPathExtension:@"skim"];
                BOOL fileExists = [fm fileExistsAtPath:notesPath];
                
                if (fileExists && (saveOperation == NSSaveAsOperation || saveOperation == NSSaveToOperation)) {
                    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" already exists. Do you want to replace it?", @"Message in alert dialog"), [notesPath lastPathComponent]]
                                                     defaultButton:NSLocalizedString(@"Save", @"Button title")
                                                   alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                                       otherButton:nil
                                         informativeTextWithFormat:NSLocalizedString(@"A file or folder with the same name already exists in %@. Replacing it will overwrite its current contents.", @"Informative text in alert dialog"), [[notesPath stringByDeletingLastPathComponent] lastPathComponent]];
                    
                    saveNotesOK = NSAlertDefaultReturn == [alert runModal];
                } else {
                    saveNotesOK = YES;
                }
                
                if (saveNotesOK) {
                    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
                    if ([[self notes] count] == 0 || [self writeToURL:[NSURL fileURLWithPath:tmpPath] ofType:SKNotesDocumentType error:NULL]) {
                        if (fileExists)
                            saveNotesOK = [fm removeFileAtPath:notesPath handler:nil];
                        if ([[self notes] count]) {
                            if (saveNotesOK)
                                saveNotesOK = [fm movePath:tmpPath toPath:notesPath handler:nil];
                            else
                                [fm removeFileAtPath:tmpPath handler:nil];
                        }
                    }
                }
                
            }
            
            if (NO == [[NSFileManager defaultManager] writeSkimNotes:[[self notes] valueForKey:@"SkimNoteProperties"] textNotes:[self notesString] richTextNotes:[self notesRTFData] toExtendedAttributesAtURL:absoluteURL error:NULL]) {
                NSString *message = saveNotesOK ? NSLocalizedString(@"The notes could not be saved with the PDF at \"%@\". However a companion .skim file was successfully updated.", @"Informative text in alert dialog") :
                                                  NSLocalizedString(@"The notes could not be saved with the PDF at \"%@\"", @"Informative text in alert dialog");
                NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Unable to save notes", @"Message in alert dialog")]
                                                 defaultButton:NSLocalizedString(@"OK", @"Button title")
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:[NSString stringWithFormat:message, [[absoluteURL path] lastPathComponent]]];
                [alert runModal];
            }
            
            if (success)
                [[NSDistributedNotificationCenter defaultCenter]
                    postNotificationName:SKSkimFileDidSaveNotification object:[absoluteURL path]];
        }
        
    } else if (SKIsPDFBundleDocumentType(typeName)) {
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *path = [absoluteURL path];
        NSString *tmpPath = nil;
        BOOL isDir = NO;
        NSEnumerator *fileEnum;
        NSString *file;
        
        // we move everything that's not ours out of the way, so we can preserve version control info
        if ([fm fileExistsAtPath:path isDirectory:&isDir] && isDir) {
            NSSet *ourExtensions = [NSSet setWithObjects:@"pdf", @"skim", @"fdf", @"txt", @"text", @"rtf", @"plist", nil];
            fileEnum = [[fm directoryContentsAtPath:path] objectEnumerator];
            while (file = [fileEnum nextObject]) {
                if ([ourExtensions containsObject:[[file pathExtension] lowercaseString]] == NO) {
                    if (tmpPath == nil)
                        tmpPath = SKUniqueTemporaryDirectory();
                    [fm movePath:[path stringByAppendingPathComponent:file] toPath:[tmpPath stringByAppendingPathComponent:file] handler:nil];
                }
            }
        }
        
        success = [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:&error];
        
        if (tmpPath) {
            fileEnum = [[fm directoryContentsAtPath:tmpPath] objectEnumerator];
            while (file = [fileEnum nextObject])
                [fm movePath:[tmpPath stringByAppendingPathComponent:file] toPath:[path stringByAppendingPathComponent:file] handler:nil];
            [fm removeFileAtPath:tmpPath handler:nil];
        }
        
        if (success)
            [[NSDistributedNotificationCenter defaultCenter]
                postNotificationName:SKSkimFileDidSaveNotification object:[absoluteURL path]];
        
    } else {
        
        success = [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:&error];
        
    }
    
    if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
        if (success) {
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeCleared];
            docFlags.fileChangedOnDisk = NO;
            [lastModifiedDate release];
            lastModifiedDate = [[[[NSFileManager defaultManager] fileAttributesAtPath:[self fileName] traverseLink:YES] fileModificationDate] retain];
        }
        [self checkFileUpdatesIfNeeded];
        docFlags.isSaving = NO;
    }
    
    if (success == NO && outError != NULL)
        *outError = error ? : [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write file", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
    return success;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    BOOL didWrite = NO;
    NSError *error = nil;
    if (SKIsEmbeddedPDFDocumentType(typeName)) {
        // this must be checked before PDF, as we check for comformance to the UTI
        [[self mainWindowController] removeTemporaryAnnotations];
        didWrite = [[self pdfDocument] writeToURL:absoluteURL];
    } else if (SKIsPDFDocumentType(typeName) || SKIsBarePDFDocumentType(typeName)) {
        didWrite = [pdfData writeToURL:absoluteURL options:0 error:&error];
    } else if (SKIsPostScriptDocumentType(typeName) || SKIsBarePostScriptDocumentType(typeName)) {
        if (SKIsPostScriptDocumentType([self fileType]))
            didWrite = [psOrDviData writeToURL:absoluteURL options:0 error:&error];
    } else if (SKIsDVIDocumentType(typeName) || SKIsBareDVIDocumentType(typeName)) {
        if (SKIsDVIDocumentType([self fileType]))
            didWrite = [psOrDviData writeToURL:absoluteURL options:0 error:&error];
    } else if (SKIsPDFBundleDocumentType(typeName)) {
        NSString *name = [[[absoluteURL path] lastPathComponent] stringByDeletingPathExtension];
        if ([name caseInsensitiveCompare:BUNDLE_DATA_FILENAME] == NSOrderedSame)
            name = [name stringByAppendingString:@"1"];
        NSData *data;
        NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:[NSDictionary dictionary]];
        [fileWrapper addRegularFileWithContents:pdfData preferredFilename:[name stringByAppendingPathExtension:@"pdf"]];
        if (data = [[[self pdfDocument] string] dataUsingEncoding:NSUTF8StringEncoding])
            [fileWrapper addRegularFileWithContents:data preferredFilename:[BUNDLE_DATA_FILENAME stringByAppendingPathExtension:@"txt"]];
        if (data = [NSPropertyListSerialization dataFromPropertyList:[[SKInfoWindowController sharedInstance] infoForDocument:self] format:NSPropertyListXMLFormat_v1_0 errorDescription:NULL])
            [fileWrapper addRegularFileWithContents:data preferredFilename:[BUNDLE_DATA_FILENAME stringByAppendingPathExtension:@"plist"]];
        if ([[self notes] count] > 0) {
            if (data = [self notesData])
                [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"skim"]];
            if (data = [[self notesString] dataUsingEncoding:NSUTF8StringEncoding])
                [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"txt"]];
            if (data = [self notesRTFData])
                [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"rtf"]];
            if (data = [[self notesFDFStringForFile:[name stringByAppendingPathExtension:@"pdf"]] dataUsingEncoding:NSISOLatin1StringEncoding])
                [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"fdf"]];
        }
        didWrite = [fileWrapper writeToFile:[absoluteURL path] atomically:NO updateFilenames:NO];
        [fileWrapper release];
    } else if (SKIsNotesDocumentType(typeName)) {
        didWrite = [[NSFileManager defaultManager] writeSkimNotes:[[self notes] valueForKey:@"SkimNoteProperties"] toSkimFileAtURL:absoluteURL error:&error];
    } else if (SKIsNotesRTFDocumentType(typeName)) {
        NSData *data = [self notesRTFData];
        if (data)
            didWrite = [data writeToURL:absoluteURL options:0 error:&error];
        else
            error = [NSError errorWithDomain:SKDocumentErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes as RTF", @"Error description"), NSLocalizedDescriptionKey, nil]];
    } else if (SKIsNotesRTFDDocumentType(typeName)) {
        NSFileWrapper *fileWrapper = [self notesRTFDFileWrapper];
        if (fileWrapper)
            didWrite = [fileWrapper writeToFile:[absoluteURL path] atomically:NO updateFilenames:NO];
        else
            error = [NSError errorWithDomain:SKDocumentErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes as RTFD", @"Error description"), NSLocalizedDescriptionKey, nil]];
    } else if (SKIsNotesTextDocumentType(typeName)) {
        NSString *string = [self notesString];
        if (string)
            didWrite = [string writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
        else
            error = [NSError errorWithDomain:SKDocumentErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes as text", @"Error description"), NSLocalizedDescriptionKey, nil]];
    } else if (SKIsNotesFDFDocumentType(typeName)) {
        NSString *filePath = [[self fileURL] path];
        NSString *filename = [filePath lastPathComponent];
        if (filename && SKIsPDFBundleDocumentType([self fileType]))
            filename = [[NSFileManager defaultManager] bundledFileWithExtension:@"pdf" inPDFBundleAtPath:filePath error:NULL];
        NSString *string = [self notesFDFStringForFile:filename];
        if (string)
            didWrite = [string writeToURL:absoluteURL atomically:YES encoding:NSISOLatin1StringEncoding error:&error];
        else 
            error = [NSError errorWithDomain:SKDocumentErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes as FDF", @"Error description"), NSLocalizedDescriptionKey, nil]];
    } else if ([[typeName pathExtension] caseInsensitiveCompare:@"rtfd"] == NSOrderedSame) {
        NSFileWrapper *fileWrapper = [self notesFileWrapperUsingTemplateFile:typeName];
        if (fileWrapper)
            didWrite = [fileWrapper writeToFile:[absoluteURL path] atomically:NO updateFilenames:NO];
        else
            error = [NSError errorWithDomain:SKDocumentErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes using template", @"Error description"), NSLocalizedDescriptionKey, nil]];
    } else {
        NSData *data = [self notesDataUsingTemplateFile:typeName];
        if (data)
            didWrite = [data writeToURL:absoluteURL options:0 error:&error];
        else
            error = [NSError errorWithDomain:SKDocumentErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write notes using template", @"Error description"), NSLocalizedDescriptionKey, nil]];
    }
    
    if (didWrite == NO && outError != NULL)
        *outError = error ?: [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to write file", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
    return didWrite;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    BOOL disableAlert = [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableReloadAlertKey];
    
    if (disableAlert == NO) {
        [[[self windowForSheet] attachedSheet] orderOut:self];
        
        [[self progressController] setMessage:[NSLocalizedString(@"Reloading document", @"Message for progress sheet") stringByAppendingEllipsis]];
        [[self progressController] setIndeterminate:YES];
        [[self progressController] beginSheetModalForWindow:[self windowForSheet]];
    }
    
    BOOL success = [super revertToContentsOfURL:absoluteURL ofType:typeName error:outError];
    
    if (success) {
        if ([pdfDocument isLocked])
            [self tryToUnlockDocument:pdfDocument];
        [[self mainWindowController] setPdfDocument:pdfDocument];
        [self setPDFDoc:nil];
        
        [[self mainWindowController] setAnnotationsFromDictionaries:noteDicts undoable:NO];
        [self setNoteDicts:nil];
        
        [[self mainWindowController] setOpenMetaTags:openMetaTags];
        [self setOpenMetaTags:nil];
        
        [[self mainWindowController] setOpenMetaRating:openMetaRating];
        [self setOpenMetaRating:0.0];
        
        [[self undoManager] removeAllActions];
        // file watching could have been disabled if the file was deleted
        if (watchedFile == nil && fileUpdateTimer == nil)
            [self checkFileUpdatesIfNeeded];
    }

    if (disableAlert == NO)
        [[self progressController] endSheet];
    
    return success;
}

- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError {
    NSMutableDictionary *dict = [[[super fileAttributesToWriteToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:outError] mutableCopy] autorelease];
    
    // only set the creator code for our native types
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldSetCreatorCodeKey] && (SKIsPDFDocumentType(typeName) || SKIsPDFBundleDocumentType(typeName) || SKIsPostScriptDocumentType(typeName) || SKIsDVIDocumentType(typeName) || SKIsNotesDocumentType(typeName)))
        [dict setObject:[NSNumber numberWithUnsignedLong:'SKim'] forKey:NSFileHFSCreatorCode];
    
    if ([[[absoluteURL path] pathExtension] isEqualToString:@"pdf"] || 
        SKIsPDFDocumentType(typeName) || SKIsEmbeddedPDFDocumentType(typeName) || SKIsBarePDFDocumentType(typeName))
        [dict setObject:[NSNumber numberWithUnsignedLong:'PDF '] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"pdfd"] || SKIsPDFBundleDocumentType(typeName))
        [dict setObject:[NSNumber numberWithUnsignedLong:'PDFD'] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"skim"] || SKIsNotesDocumentType(typeName))
        [dict setObject:[NSNumber numberWithUnsignedLong:'SKNT'] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"fdf"] || SKIsNotesFDFDocumentType(typeName))
        [dict setObject:[NSNumber numberWithUnsignedLong:'FDF '] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"rtf"] || SKIsNotesRTFDocumentType(typeName))
        [dict setObject:[NSNumber numberWithUnsignedLong:'RTF '] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"txt"] || SKIsNotesTextDocumentType(typeName))
        [dict setObject:[NSNumber numberWithUnsignedLong:'TEXT'] forKey:NSFileHFSTypeCode];
    
    return dict;
}

- (void)setPDFDataUndoable:(NSData *)data {
    [[[self undoManager] prepareWithInvocationTarget:self] setPDFDataUndoable:pdfData];
    [self setPDFData:data];
}

- (void)setPDFData:(NSData *)data {
    if (pdfData != data) {
        [pdfData release];
        pdfData = [data retain];
    }
}

- (void)setPSOrDVIData:(NSData *)data {
    if (psOrDviData != data) {
        [psOrDviData release];
        psOrDviData = [data retain];
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

- (void)setOpenMetaTags:(NSArray *)array {
    if (openMetaTags != array) {
        [openMetaTags autorelease];
        openMetaTags = [array retain];
    }
}

- (void)setOpenMetaRating:(double)rating {
    openMetaRating = rating;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)docType error:(NSError **)outError;
{
    BOOL didRead = NO;
    PDFDocument *pdfDoc = nil;
    NSError *error = nil;
    
    [self setPDFData:nil];
    [self setPDFDoc:nil];
    [self setNoteDicts:nil];
    
    if (SKIsPostScriptDocumentType(docType))
        data = [SKConversionProgressController PDFDataWithPostScriptData:data];
    
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
        *outError = error ?: [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
    return didRead;
}

static BOOL isIgnorablePOSIXError(NSError *error) {
    if ([[error domain] isEqualToString:NSPOSIXErrorDomain])
        return [error code] == ENOATTR || [error code] == ENOTSUP || [error code] == EINVAL || [error code] == EPERM || [error code] == EACCES;
    else
        return NO;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)docType error:(NSError **)outError{
    BOOL didRead = NO;
    NSData *fileData = nil;
    NSData *data = nil;
    PDFDocument *pdfDoc = nil;
    NSError *error = nil;
    
    [self setPDFData:nil];
    [self setPSOrDVIData:nil];
    [self setPDFDoc:nil];
    [self setNoteDicts:nil];
    [self setOpenMetaTags:nil];
    [self setOpenMetaRating:0.0];
    
    if (SKIsPDFBundleDocumentType(docType)) {
        NSString *path = [absoluteURL path];
        NSString *pdfFile = [[NSFileManager defaultManager] bundledFileWithExtension:@"pdf" inPDFBundleAtPath:path error:&error];
        if (pdfFile) {
            NSURL *pdfURL = [NSURL fileURLWithPath:pdfFile];
            if ((data = [[NSData alloc] initWithContentsOfURL:pdfURL options:NSUncachedRead error:&error]) &&
                (pdfDoc = [[PDFDocument alloc] initWithURL:pdfURL])) {
                NSArray *array = [[NSFileManager defaultManager] readSkimNotesFromPDFBundleAtURL:absoluteURL error:&error];
                if (array == nil) {
                    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to Read Notes", @"Message in alert dialog") 
                                                     defaultButton:NSLocalizedString(@"No", @"Button title")
                                                   alternateButton:NSLocalizedString(@"Yes", @"Button title")
                                                       otherButton:nil
                                         informativeTextWithFormat:NSLocalizedString(@"Skim was not able to read the notes at %@. %@ Do you want to continue to open the PDF document anyway?", @"Informative text in alert dialog"), [path stringByAbbreviatingWithTildeInPath], [[error userInfo] objectForKey:NSLocalizedDescriptionKey]];
                    if ([alert runModal] == NSAlertDefaultReturn) {
                        [data release];
                        data = nil;
                        [pdfDoc release];
                        pdfDoc = nil;
                    }
                } else if ([array count]) {
                    [self setNoteDicts:array];
                }
            }
        }
    } else  {
        if (fileData = [[NSData alloc] initWithContentsOfURL:absoluteURL options:NSUncachedRead error:&error]) {
            if (SKIsPDFDocumentType(docType)) {
                if (data = [fileData retain])
                    pdfDoc = [[PDFDocument alloc] initWithURL:absoluteURL];
            } else if (SKIsPostScriptDocumentType(docType)) {
                if (data = [[SKConversionProgressController PDFDataWithPostScriptData:fileData] retain])
                    pdfDoc = [[PDFDocument alloc] initWithData:data];
            } else if (SKIsDVIDocumentType(docType)) {
                if (data = [[SKConversionProgressController PDFDataWithDVIFile:[absoluteURL path]] retain])
                    pdfDoc = [[PDFDocument alloc] initWithData:data];
            }
        }
        if (pdfDoc) {
            NSArray *array = [[NSFileManager defaultManager] readSkimNotesFromExtendedAttributesAtURL:absoluteURL error:&error];
            if ([array count]) {
                [self setNoteDicts:array];
            } else {
                // we found no notes, see if we had an error finding notes. if EAs were not supported we ignore the error, as we may assume there won't be any notes
                if (array == nil && isIgnorablePOSIXError(error) == NO) {
                    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to Read Notes", @"Message in alert dialog") 
                                                     defaultButton:NSLocalizedString(@"No", @"Button title")
                                                   alternateButton:NSLocalizedString(@"Yes", @"Button title")
                                                       otherButton:nil
                                         informativeTextWithFormat:NSLocalizedString(@"Skim was not able to read the notes at %@. %@ Do you want to continue to open the PDF document anyway?", @"Informative text in alert dialog"), [[absoluteURL path] stringByAbbreviatingWithTildeInPath], [[error userInfo] objectForKey:NSLocalizedDescriptionKey]];
                    if ([alert runModal] == NSAlertDefaultReturn) {
                        [fileData release];
                        fileData = nil;
                        [data release];
                        data = nil;
                        [pdfDoc release];
                        pdfDoc = nil;
                    }
                }
                if (pdfDoc) {
                    NSString *path = [[absoluteURL path] stringByReplacingPathExtension:@"skim"];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                        NSInteger readOption = [[NSUserDefaults standardUserDefaults] integerForKey:SKReadMissingNotesFromSkimFileOptionKey];
                        if (readOption == NSAlertOtherReturn) {
                            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Found Separate Notes", @"Message in alert dialog") 
                                                             defaultButton:NSLocalizedString(@"Yes", @"Button title")
                                                           alternateButton:NSLocalizedString(@"No", @"Button title")
                                                               otherButton:nil
                                                 informativeTextWithFormat:NSLocalizedString(@"Unable to read notes for %@, but a Skim notes file with the same name was found.  Do you want Skim to read the notes from this file?", @"Informative text in alert dialog"), [[absoluteURL path] stringByAbbreviatingWithTildeInPath]];
                            readOption = [alert runModal];
                        }
                        if (readOption == NSAlertDefaultReturn) {
                            array = [[NSFileManager defaultManager] readSkimNotesFromSkimFileAtURL:[NSURL fileURLWithPath:path] error:NULL];
                            if ([array count]) {
                                [self setNoteDicts:array];
                                [self updateChangeCount:NSChangeDone];
                            }
                        }
                    }
                }
            }
        }
    }
    
    if (data) {
        if (pdfDoc) {
            didRead = YES;
            [self setPDFData:data];
            [self setPDFDoc:pdfDoc];
            if (SKIsPostScriptDocumentType(docType) || SKIsDVIDocumentType(docType))
                [self setPSOrDVIData:fileData];
            [pdfDoc release];
            docFlags.fileChangedOnDisk = NO;
            [lastModifiedDate release];
            lastModifiedDate = [[[[NSFileManager defaultManager] fileAttributesAtPath:[absoluteURL path] traverseLink:YES] fileModificationDate] retain];
            
            NSArray *array = nil;
            NSNumber *number = nil;
            if (SKIsPDFBundleDocumentType(docType)) {
                NSData *infoData = [NSData dataWithContentsOfFile:[[[absoluteURL path] stringByAppendingPathComponent:BUNDLE_DATA_FILENAME] stringByAppendingPathExtension:@"plist"]];
                if (infoData) {
                    NSString *errorString = nil;
                    NSDictionary *info = [NSPropertyListSerialization propertyListFromData:infoData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
                    if (info == nil) {
                        [errorString release];
                    } else if ([info isKindOfClass:[NSDictionary class]]) {
                        array =[info objectForKey:@"Tags"];
                        number = [info objectForKey:@"Rating"];
                    }
                }
            } else {
                array = [[SKNExtendedAttributeManager sharedNoSplitManager] propertyListFromExtendedAttributeNamed:OPEN_META_TAGS_KEY atPath:[absoluteURL path] traverseLink:YES error:NULL];
                number = [[SKNExtendedAttributeManager sharedNoSplitManager] propertyListFromExtendedAttributeNamed:OPEN_META_RATING_KEY atPath:[absoluteURL path] traverseLink:YES error:NULL];
            }
            if ([array isKindOfClass:[NSArray class]] && [array count])
                [self setOpenMetaTags:array];
            if ([number respondsToSelector:@selector(doubleValue)] && [number doubleValue] > 0.0)
                [self setOpenMetaRating:[number doubleValue]];
        } else {
            [self setPDFData:nil];
        }
        [data release];
    }
    [fileData release];
    
    if (didRead == NO && outError != NULL)
        *outError = error ?: [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load file", @"Error description"), NSLocalizedDescriptionKey, nil]];
    
    return didRead;
}

#pragma mark Notes

- (NSData *)notesData {
    NSArray *array = [[self notes] valueForKey:@"SkimNoteProperties"];
    return array ? [NSKeyedArchiver archivedDataWithRootObject:array] : nil;
}

- (NSString *)notesFDFString {
    NSString *filePath = [[self fileURL] path];
    NSString *filename = [filePath lastPathComponent];
    if (filename && SKIsPDFBundleDocumentType([self fileType]))
        filename = [[NSFileManager defaultManager] bundledFileWithExtension:@"pdf" inPDFBundleAtPath:filePath error:NULL];
    return [self notesFDFStringForFile:filename];
}

- (NSString *)notesFDFStringForFile:(NSString *)filename {
    NSArray *fileIDStrings = [self fileIDStrings];
    NSInteger i, count = [[self notes] count];
    NSMutableString *string = [NSMutableString stringWithFormat:@"%%FDF-1.2\n%%%C%C%C%C\n", 0xe2, 0xe3, 0xcf, 0xd3];
    NSMutableString *annots = [NSMutableString string];
    for (i = 0; i < count; i++) {
        [string appendFormat:@"%ld 0 obj<<%@>>\nendobj\n", (long)(i + 1), [[[self notes] objectAtIndex:i] fdfString]];
        [annots appendFormat:@"%ld 0 R ", (long)(i + 1)];
    }
    [string appendFormat:@"%ld 0 obj<<", (long)(i + 1)];
    [string appendFDFName:SKFDFFDFKey];
    [string appendString:@"<<"];
    [string appendFDFName:SKFDFAnnotationsKey];
    [string appendFormat:@"[%@]", annots];
    [string appendFDFName:SKFDFFileKey];
    [string appendString:@"("];
    if (filename)
        [string appendString:[[filename lossyISOLatin1String] stringByEscapingParenthesis]];
    [string appendString:@")"];
    if ([fileIDStrings count] == 2) {
        [string appendFDFName:SKFDFFileIDKey];
        [string appendFormat:@"[<%@><%@>]", [fileIDStrings objectAtIndex:0], [fileIDStrings objectAtIndex:1]];
    }
    [string appendString:@">>"];
    [string appendString:@">>\nendobj\n"];
    [string appendString:@"trailer\n<<"];
    [string appendFDFName:SKFDFRootKey];
    [string appendFormat:@" %ld 0 R", (long)(i + 1)];
    [string appendString:@">>\n"];
    [string appendString:@"%%EOF\n"];
    return string;
}

#pragma mark Actions

- (IBAction)printDocument:(id)sender{
    BOOL autoRotate = [[[self printInfo] valueForKeyPath:@"dictionary.PDFPrintAutoRotate"] boolValue];
    [[self pdfView] printWithInfo:[self printInfo] autoRotate:autoRotate];
}

- (void)openPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(NSInteger)returnCode  contextInfo:(void  *)contextInfo{
    if (returnCode == NSOKButton) {
        NSURL *notesURL = [[oPanel URLs] objectAtIndex:0];
        NSString *extension = [[notesURL path] pathExtension];
        NSArray *array = nil;
        
        if ([extension caseInsensitiveCompare:@"skim"] == NSOrderedSame) {
            array = [NSKeyedUnarchiver unarchiveObjectWithFile:[notesURL path]];
        } else {
            NSData *fdfData = [NSData dataWithContentsOfURL:notesURL];
            if (fdfData)
                array = [SKFDFParser noteDictionariesFromFDFData:fdfData];
        }
        
        if (array) {
            if ([[oPanel accessoryView] isEqual:readNotesAccessoryView] && [replaceNotesCheckButton state] == NSOnState) {
                [[self mainWindowController] setAnnotationsFromDictionaries:array undoable:YES];
                [[self undoManager] setActionName:NSLocalizedString(@"Replace Notes", @"Undo action name")];
            } else {
                [[self mainWindowController] addAnnotationsFromDictionaries:array undoable:YES];
                [[self undoManager] setActionName:NSLocalizedString(@"Add Notes", @"Undo action name")];
            }
        } else
            NSBeep();
        
    }
}

- (IBAction)readNotes:(id)sender{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    NSString *path = [[self fileURL] path];
    
    if ([[[self mainWindowController] notes] count]) {
        if (readNotesAccessoryView == nil) {
            if (NO == [NSBundle loadNibNamed:@"ReadNotesAccessoryView" owner:self])
                NSLog(@"Failed to load ReadNotesAccessoryView.nib");
        }
        [oPanel setAccessoryView:readNotesAccessoryView];
        [replaceNotesCheckButton setState:NSOnState];
    }
    
    [oPanel beginSheetForDirectory:[path stringByDeletingLastPathComponent]
                              file:[[path lastPathComponent] stringByReplacingPathExtension:@"skim"]
                             types:[NSArray arrayWithObjects:@"skim", @"fdf", nil]
                    modalForWindow:[self windowForSheet]
                     modalDelegate:self
                    didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo:NULL];		
}

- (void)convertNotesPasswordSheetDidEnd:(SKPasswordSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    PDFDocument *pdfDocWithoutNotes = (PDFDocument *)contextInfo;
    
    if (returnCode == NSCancelButton) {
        [pdfDocWithoutNotes release];
        return;
    }
    
    if (pdfDocWithoutNotes && [pdfDocWithoutNotes unlockWithPassword:[controller stringValue]] == NO) {
        [[controller window] orderOut:self];
        
        SKPasswordSheetController *passwordSheetController = [[[SKPasswordSheetController alloc] init] autorelease];
        
        [passwordSheetController beginSheetModalForWindow:[[self mainWindowController] window]
            modalDelegate:self 
           didEndSelector:@selector(convertNotesPasswordSheetDidEnd:returnCode:contextInfo:)
              contextInfo:pdfDocWithoutNotes];
        
        return;
    }
    
    [[[self windowForSheet] attachedSheet] orderOut:self];
        
    [[self progressController] setMessage:[NSLocalizedString(@"Converting notes", @"Message for progress sheet") stringByAppendingEllipsis]];
    [[self progressController] setIndeterminate:YES];
    [[self progressController] beginSheetModalForWindow:[self windowForSheet]];
    
    PDFDocument *pdfDoc = [self pdfDocument];
    NSInteger i, count = [pdfDoc pageCount];
    BOOL didConvert = NO;
    
    for (i = 0; i < count; i++) {
        PDFPage *page = [pdfDoc pageAtIndex:i];
        NSEnumerator *annEnum = [[[[page annotations] copy] autorelease] objectEnumerator];
        PDFAnnotation *annotation;
        
        while (annotation = [annEnum nextObject]) {
            if ([annotation isSkimNote] == NO && [annotation isConvertibleAnnotation]) {
                NSDictionary *properties = [annotation SkimNoteProperties];
                if ([[annotation type] isEqualToString:SKNTextString])
                    properties = [SKNPDFAnnotationNote textToNoteSkimNoteProperties:properties];
                PDFAnnotation *newAnnotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:properties];
                if (newAnnotation) {
                    [[self pdfView] removeAnnotation:annotation];
                    [[self pdfView] addAnnotation:newAnnotation toPage:page];
                    [newAnnotation release];
                    didConvert = YES;
                }
            }
        }
    }
    
    if (didConvert) {
        if (pdfDocWithoutNotes == nil)
            pdfDocWithoutNotes = [[PDFDocument alloc] initWithData:pdfData];
        if ([pdfDocWithoutNotes isLocked])
            [self tryToUnlockDocument:pdfDocWithoutNotes];
        count = [pdfDocWithoutNotes pageCount];
        for (i = 0; i < count; i++) {
            PDFPage *page = [pdfDocWithoutNotes pageAtIndex:i];
            NSEnumerator *annEnum = [[[[page annotations] copy] autorelease] objectEnumerator];
            PDFAnnotation *annotation;
            
            while (annotation = [annEnum nextObject]) {
                if ([annotation isSkimNote] == NO && [annotation isConvertibleAnnotation])
                    [page removeAnnotation:annotation];
            }
        }
        
        [self setPDFDataUndoable:[pdfDocWithoutNotes dataRepresentation]];
        
        [[self undoManager] setActionName:NSLocalizedString(@"Convert Notes", @"Undo action name")];
    }
    
    [pdfDocWithoutNotes release];
    
    [[self progressController] endSheet];
}

- (void)convertNotesSheetDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertAlternateReturn)
        return;
    
    PDFDocument *pdfDocWithoutNotes = nil;
    
    if ([[self pdfDocument] isEncrypted]) {
        pdfDocWithoutNotes = [[PDFDocument alloc] initWithData:pdfData];
        if ([pdfDocWithoutNotes isLocked] && [self tryToUnlockDocument:pdfDocWithoutNotes] == NO) {
            [[[self windowForSheet] attachedSheet] orderOut:self];
            
            SKPasswordSheetController *passwordSheetController = [[[SKPasswordSheetController alloc] init] autorelease];
            
            [passwordSheetController beginSheetModalForWindow:[[self mainWindowController] window]
                modalDelegate:self 
               didEndSelector:@selector(convertNotesPasswordSheetDidEnd:returnCode:contextInfo:)
                  contextInfo:pdfDocWithoutNotes];
            
            return;
        }
    }
    [self convertNotesPasswordSheetDidEnd:nil returnCode:NSOKButton contextInfo:pdfDocWithoutNotes];
}

- (IBAction)convertNotes:(id)sender {
    if (SKIsPDFDocumentType([self fileType]) == NO || SKIsPDFBundleDocumentType([self fileType]) == NO) {
        NSBeep();
        return;
    }
    NSString *message = NSLocalizedString(@"This will convert PDF annotations to Skim notes. Do you want to proceed?", @"Informative text in alert dialog");
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4)
        message = NSLocalizedString(@"This will convert PDF annotations to Skim notes. This will loose the Table of Contents. Do you want to proceed?", @"Informative text in alert dialog");
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Convert Notes", @"Alert text when trying to convert notes")
                                     defaultButton:NSLocalizedString(@"OK", @"Button title")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                       otherButton:nil
                         informativeTextWithFormat:message];
    [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(convertNotesSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (BOOL)saveArchiveToFile:(NSString *)fileName {
    return [NSTask runTaskWithLaunchPath:@"/usr/bin/tar"
                               arguments:[NSArray arrayWithObjects:@"-czf", fileName, [[[self fileURL] path] lastPathComponent], nil]
                    currentDirectoryPath:[[[self fileURL] path] stringByDeletingLastPathComponent]];
}

- (void)archiveSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode  contextInfo:(void  *)contextInfo {
    if (NSOKButton == returnCode && [self fileURL])
        [self saveArchiveToFile:[sheet filename]];
}

- (IBAction)saveArchive:(id)sender {
    NSString *path = [[self fileURL] path];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path] && [self isDocumentEdited] == NO) {
        NSSavePanel *sp = [NSSavePanel savePanel];
        [sp setRequiredFileType:@"tgz"];
        [sp setCanCreateDirectories:YES];
        [sp beginSheetForDirectory:nil
                              file:[[path lastPathComponent] stringByReplacingPathExtension:@"tgz"]
                    modalForWindow:[self windowForSheet]
                     modalDelegate:self
                    didEndSelector:@selector(archiveSavePanelDidEnd:returnCode:contextInfo:)
                       contextInfo:NULL];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"You must save this file first", @"Alert text when trying to create archive for unsaved document") defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The document has unsaved changes, or has not previously been saved to disk.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (BOOL)emailAttachmentFile:(NSString *)fileName {
    NSMutableString *scriptString = nil;
    
    NSString *mailAppName = nil;
    CFURLRef mailAppURL = NULL;
    OSStatus status = LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"mailto:"], kLSRolesAll, NULL, &mailAppURL);
    if (status == noErr)
        mailAppName = [[[(NSURL *)mailAppURL path] lastPathComponent] stringByDeletingPathExtension];
    
    NSString *subject = [self displayName];
    
    if ([mailAppName rangeOfString:@"Entourage" options:NSCaseInsensitiveSearch].length) {
        scriptString = [NSMutableString stringWithString:@"tell application \"Microsoft Entourage\"\n"];
        [scriptString appendString:@"activate\n"];
        [scriptString appendFormat:@"set m to make new draft window with properties {subject:\"%@\"}\n", subject];
        [scriptString appendString:@"tell m\n"];
        //[scriptString appendFormat:@"set content to \"%@\"\n", body];
        [scriptString appendFormat:@"make new attachment with properties {file:POSIX file \"%@\"}\n", fileName];
        [scriptString appendString:@"end tell\n"];
        [scriptString appendString:@"end tell\n"];
    } else if ([mailAppName rangeOfString:@"Mailsmith" options:NSCaseInsensitiveSearch].length) {
        scriptString = [NSMutableString stringWithString:@"tell application \"Mailsmith\"\n"];
        [scriptString appendString:@"activate\n"];
        [scriptString appendFormat:@"set m to make new message window with properties {subject:\"%@\"}\n", subject];
        [scriptString appendString:@"tell m\n"];
        //[scriptString appendFormat:@"set contents to \"%@\"\n", body];
        [scriptString appendFormat:@"make new enclosure with properties {file:POSIX file \"%@\"}\n", fileName];
        [scriptString appendString:@"end tell\n"];
        [scriptString appendString:@"end tell\n"];
    } else {
        scriptString = [NSMutableString stringWithString:@"tell application \"Mail\"\n"];
        [scriptString appendString:@"activate\n"];
        [scriptString appendFormat:@"set m to make new outgoing message with properties {subject:\"%@\", visible:true}\n", subject];
        //[scriptString appendFormat:@"set content of m to \"%@\"\n", body];
        [scriptString appendString:@"tell content of m\n"];
        [scriptString appendFormat:@"make new attachment at after last character with properties {file name:\"%@\"}\n", fileName];
        [scriptString appendString:@"end tell\n"];
        [scriptString appendString:@"end tell\n"];
    }
    
    if (scriptString) {
        NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:scriptString] autorelease];
        NSDictionary *errorDict = nil;
        if ([script compileAndReturnError:&errorDict] == NO) {
            NSLog(@"Error compiling mail to script: %@", errorDict);
            return NO;
        }
        if ([script executeAndReturnError:&errorDict] == NO) {
            NSLog(@"Error running mail to script: %@", errorDict);
            return NO;
        }
        return YES;
    }
    return NO;
}

- (IBAction)emailArchive:(id)sender {
    NSString *path = [[self fileURL] path];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path] && [self isDocumentEdited] == NO) {
        NSString *tmpDir = SKUniqueChewableItemsDirectory();
        NSString *tmpFile = [tmpDir stringByAppendingPathComponent:[[[[self fileURL] path] lastPathComponent] stringByReplacingPathExtension:@"tgz"]];
        if ([self saveArchiveToFile:tmpFile] == NO || [self emailAttachmentFile:tmpFile] == NO)
            NSBeep();
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"You must save this file first", @"Alert text when trying to create archive for unsaved document") defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The document has unsaved changes, or has not previously been saved to disk.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (void)saveDiskImageWithInfo:(NSDictionary *)info {
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSString *sourcePath = [[[info objectForKey:@"sourcePath"] copy] autorelease];
    NSString *targetPath = [[[info objectForKey:@"targetPath"] copy] autorelease];
    NSString *scriptPath = nil;
    NSArray *arguments = nil;
    
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4) {
        // hdiutil on Tiger looses EAs, so we use a more complicated path
        scriptPath = [[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:@"archivedmg.sh"];
        arguments = [NSArray arrayWithObjects:sourcePath, targetPath, nil];
    } else {
        scriptPath = @"/usr/bin/hdiutil";
        arguments = [NSArray arrayWithObjects:@"create", @"-srcfolder", sourcePath, @"-format", @"UDZO", @"-volname", [[targetPath lastPathComponent] stringByDeletingPathExtension], targetPath, nil];
    }
    
    if ([NSTask runTaskWithLaunchPath:scriptPath arguments:arguments currentDirectoryPath:[sourcePath stringByDeletingLastPathComponent]] == NO)
        NSBeep();
    
    [[self progressController] performSelectorOnMainThread:@selector(hide) withObject:nil waitUntilDone:NO];
    
    if ([[info objectForKey:@"email"] boolValue])
        [self performSelectorOnMainThread:@selector(emailAttachmentFile:) withObject:targetPath waitUntilDone:NO];
    
    [pool release];
}

- (void)saveDiskImageToFile:(NSString *)fileName email:(BOOL)email {
    [[self progressController] setMessage:[NSLocalizedString(@"Saving Disk Image", @"Message for progress sheet") stringByAppendingEllipsis]];
    [[self progressController] setIndeterminate:YES];
    [[self progressController] show];
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[[self fileURL] path], @"sourcePath", fileName, @"targetPath", [NSNumber numberWithBool:email], @"email", nil];
    [NSThread detachNewThreadSelector:@selector(saveDiskImageWithInfo:) toTarget:self withObject:info];
}

- (void)diskImageSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode  contextInfo:(void  *)contextInfo {
    if (NSOKButton == returnCode && [self fileURL])
        [self saveDiskImageToFile:[sheet filename] email:NO];
}

- (IBAction)saveDiskImage:(id)sender {
    NSString *path = [[self fileURL] path];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path] && [self isDocumentEdited] == NO) {
        NSSavePanel *sp = [NSSavePanel savePanel];
        [sp setRequiredFileType:@"dmg"];
        [sp setCanCreateDirectories:YES];
        [sp beginSheetForDirectory:nil
                              file:[[path lastPathComponent] stringByReplacingPathExtension:@"dmg"]
                    modalForWindow:[self windowForSheet]
                     modalDelegate:self
                    didEndSelector:@selector(diskImageSavePanelDidEnd:returnCode:contextInfo:)
                       contextInfo:NULL];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"You must save this file first", @"Alert text when trying to create archive for unsaved document") defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The document has unsaved changes, or has not previously been saved to disk.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (IBAction)emailDiskImage:(id)sender {
    NSString *path = [[self fileURL] path];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path] && [self isDocumentEdited] == NO) {
        NSString *tmpDir = SKUniqueChewableItemsDirectory();
        NSString *tmpFile = [tmpDir stringByAppendingPathComponent:[[[[self fileURL] path] lastPathComponent] stringByReplacingPathExtension:@"dmg"]];
        [self saveDiskImageToFile:tmpFile email:YES];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"You must save this file first", @"Alert text when trying to create archive for unsaved document") defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The document has unsaved changes, or has not previously been saved to disk.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (void)revertAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
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
         } else if (docFlags.fileChangedOnDisk) { 	 
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
        NSString *fileName = [self fileName];
        if (fileName == nil || [[NSFileManager defaultManager] fileExistsAtPath:fileName] == NO)
            return NO;
        return [self isDocumentEdited] || docFlags.fileChangedOnDisk;
    } else if ([anItem action] == @selector(printDocument:)) {
        return [[self pdfDocument] allowsPrinting];
    } else if ([anItem action] == @selector(convertNotes:)) {
        return SKIsPDFDocumentType([self fileType]) && [[self pdfDocument] isLocked] == NO;
    } else if ([anItem action] == @selector(saveArchive:) || [anItem action] == @selector(saveDiskImage:) || [anItem action] == @selector(emailArchive:) || [anItem action] == @selector(emailDiskImage:)) {
        NSString *path = [[self fileURL] path];
        return path && [[NSFileManager defaultManager] fileExistsAtPath:path] && [self isDocumentEdited] == NO;
    }
    return [super validateUserInterfaceItem:anItem];
}

- (void)remoteButtonPressed:(NSEvent *)theEvent {
    [[self mainWindowController] remoteButtonPressed:theEvent];
}


#pragma mark File update checking

- (void)stopCheckingFileUpdates {
    if (watchedFile) {
        // remove from kqueue and invalidate timer; maybe we've changed filesystems
        UKKQueue *kQueue = [UKKQueue sharedFileWatcher];
        [kQueue removePath:watchedFile];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:UKFileWatcherWriteNotification object:kQueue];
        [nc removeObserver:self name:UKFileWatcherRenameNotification object:kQueue];
        [nc removeObserver:self name:UKFileWatcherDeleteNotification object:kQueue];
        [watchedFile release];
        watchedFile = nil;
    }
    if (fileUpdateTimer) {
        [fileUpdateTimer invalidate];
        fileUpdateTimer = nil;
    }
}

static BOOL isFileOnHFSVolume(NSString *fileName)
{
    FSRef fileRef;
    OSStatus err;
    err = FSPathMakeRef((const UInt8 *)[fileName fileSystemRepresentation], &fileRef, NULL);
    
    FSCatalogInfo fileInfo;
    if (noErr == err)
        err = FSGetCatalogInfo(&fileRef, kFSCatInfoVolume, &fileInfo, NULL, NULL, NULL);
    
    FSVolumeInfo volInfo;
    if (noErr == err)
        err = FSGetVolumeInfo(fileInfo.volume, 0, NULL, kFSVolInfoFSInfo, &volInfo, NULL, NULL);
    
    // HFS and HFS+ are documented to have zero for filesystemID; AFP at least is non-zero
    BOOL isHFSVolume = (noErr == err) ? (0 == volInfo.filesystemID) : NO;
    
    return isHFSVolume;
}

- (void)checkForFileModification:(NSTimer *)timer {
    NSDate *currentFileModifiedDate = [[[NSFileManager defaultManager] fileAttributesAtPath:[self fileName] traverseLink:YES] fileModificationDate];
    if (nil == lastModifiedDate) {
        lastModifiedDate = [currentFileModifiedDate copy];
    } else if ([lastModifiedDate compare:currentFileModifiedDate] == NSOrderedAscending) {
        // Always reset mod date to prevent repeating messages; note that the kqueue also notifies only once
        [lastModifiedDate release];
        lastModifiedDate = [currentFileModifiedDate copy];
        [self handleFileUpdateNotification:nil];
    }
        
}

- (void)checkFileUpdatesIfNeeded {
    if ([self fileName]) {
        [self stopCheckingFileUpdates];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey]) {
            
            // AFP, NFS, SMB etc. don't support kqueues, so we have to manually poll and compare mod dates
            if (isFileOnHFSVolume([self fileName])) {
                watchedFile = [[self fileName] retain];
                
                UKKQueue *kQueue = [UKKQueue sharedFileWatcher];
                [kQueue addPath:watchedFile];
                NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
                [nc addObserver:self selector:@selector(handleFileUpdateNotification:) name:UKFileWatcherWriteNotification object:kQueue];
                [nc addObserver:self selector:@selector(handleFileMoveNotification:) name:UKFileWatcherRenameNotification object:kQueue];
                [nc addObserver:self selector:@selector(handleFileDeleteNotification:) name:UKFileWatcherDeleteNotification object:kQueue];
            } else if (nil == fileUpdateTimer) {
                // Let the runloop retain the timer; timer retains us.  Use a fairly long delay since this is likely a network volume.
                fileUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:(double)2.0 target:self selector:@selector(checkForFileModification:) userInfo:nil repeats:YES];
            }
        }
    }
}

- (void)fileUpdateAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    
    if (returnCode == NSAlertOtherReturn) {
        docFlags.autoUpdate = NO;
        docFlags.disableAutoReload = YES;
    } else {
        NSError *error = nil;
        
        [[alert window] orderOut:nil];
        
        if ([self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:&error])
            docFlags.receivedFileUpdateNotification = NO;
        else if (error)
            [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
        if (returnCode == NSAlertAlternateReturn)
            docFlags.autoUpdate = YES;
        docFlags.disableAutoReload = NO;
        if (docFlags.receivedFileUpdateNotification)
            [self performSelector:@selector(fileUpdated) withObject:nil afterDelay:0.0];
    }
    docFlags.isUpdatingFile = NO;
    docFlags.receivedFileUpdateNotification = NO;
}

- (BOOL)canUpdateFromFile:(NSString *)fileName {
    NSString *extension = [fileName pathExtension];
    BOOL isDVI = NO;
    if (extension) {
        NSString *theUTI = [(id)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL) autorelease];
        if ([extension caseInsensitiveCompare:@"pdfd"] == NSOrderedSame || (theUTI && UTTypeConformsTo((CFStringRef)theUTI, CFSTR("net.sourceforge.skim-app.pdfd")))) {
            fileName = [[NSFileManager defaultManager] bundledFileWithExtension:@"pdf" inPDFBundleAtPath:fileName error:NULL];
            if (fileName == nil)
                return NO;
        } else if ([extension caseInsensitiveCompare:@"dvi"] == NSOrderedSame) {
            isDVI = YES;
        }
    }
    
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:fileName];
    
    // read the last 1024 bytes of the file (or entire file); Adobe's spec says they allow %%EOF anywhere in that range
    unsigned long long fileEnd = [fh seekToEndOfFile];
    unsigned long long startPos = fileEnd < 1024 ? 0 : fileEnd - 1024;
    [fh seekToFileOffset:startPos];
    NSData *trailerData = [fh readDataToEndOfFile];
    NSRange range = NSMakeRange(0, [trailerData length]);
    const char *pattern = "%%EOF";
    
    if (isDVI) {
        pattern = [[NSString stringWithFormat:@"%C%C%C%C", 0xFB02, 0xFB02, 0xFB02, 0xFB02] cStringUsingEncoding:NSMacOSRomanStringEncoding];
        range = NSMakeRange(strlen(pattern), [trailerData length] - strlen(pattern));
    }
    return NSNotFound != [trailerData indexOfBytes:pattern length:strlen(pattern) options:NSBackwardsSearch range:range];
}

- (void)fileUpdated {
    NSString *fileName = [self fileName];
    
    // should never happen
    if (docFlags.isUpdatingFile)
        NSLog(@"*** already busy updating file %@", fileName);
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCheckFileUpdateKey] &&
        [[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        
        docFlags.fileChangedOnDisk = YES;
        
        docFlags.isUpdatingFile = YES;
        docFlags.receivedFileUpdateNotification = NO;
        
        // check for attached sheet, since reloading the document while an alert is up looks a bit strange
        if ([[self windowForSheet] attachedSheet]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowDidEndSheetNotification:) 
                                                         name:NSWindowDidEndSheetNotification object:[self windowForSheet]];
        } else if ([self canUpdateFromFile:fileName]) {
            BOOL shouldAutoUpdate = docFlags.autoUpdate || [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoReloadFileUpdateKey];
            if (docFlags.disableAutoReload == NO && shouldAutoUpdate && [self isDocumentEdited] == NO && [[self notes] count] == 0) {
                // tried queuing this with a delayed perform/cancel previous, but revert takes long enough that the cancel was never used
                [self fileUpdateAlertDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:NULL];
            } else {
                NSString *message;
                if ([self isDocumentEdited] || [[self notes] count] > 0)
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
        } else {
            docFlags.isUpdatingFile = NO;
            docFlags.receivedFileUpdateNotification = NO;
        }
    } else {
        docFlags.isUpdatingFile = NO;
        docFlags.receivedFileUpdateNotification = NO;
    }
}

- (void)handleFileUpdateNotification:(NSNotification *)notification {
    NSString *path = [[notification userInfo] objectForKey:@"path"];
    
    if ([watchedFile isEqualToString:path] || notification == nil) {
        // should never happen
        if (notification && [path isEqualToString:[self fileName]] == NO)
            NSLog(@"*** received change notice for %@", path);
        
        if (docFlags.isUpdatingFile)
            docFlags.receivedFileUpdateNotification = YES;
        else
            [self fileUpdated];
    }
}

- (void)handleFileMoveNotification:(NSNotification *)notification {
    if ([watchedFile isEqualToString:[[notification userInfo] objectForKey:@"path"]])
        [self stopCheckingFileUpdates];
    // If the file is moved, NSDocument will notice and will call setFileURL, where we start watching again
}

- (void)handleFileDeleteNotification:(NSNotification *)notification {
    if ([watchedFile isEqualToString:[[notification userInfo] objectForKey:@"path"]])
        [self stopCheckingFileUpdates];
    docFlags.fileChangedOnDisk = YES;
}

- (void)handleWindowDidEndSheetNotification:(NSNotification *)notification {
    // This is only called to delay a file update handling
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidEndSheetNotification object:[notification object]];
    // Make sure we finish the sheet event first. E.g. the documentEdited status may need to be updated.
    [self performSelector:@selector(fileUpdated) withObject:nil afterDelay:0.0];
}

#pragma mark Notification handlers

- (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    NSWindow *window = [notification object];
    // ignore when we're switching fullscreen/main windows
    if ([window isEqual:[[window windowController] window]]) {
        [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKey:SKAutoCheckFileUpdateKey];
        [self stopCheckingFileUpdates];
        [self saveRecentDocumentInfo];
    }
}

- (void)handleDidRemoveDocumentNotification:(NSNotification *)notification {
    if ([[notification userInfo] objectForKey:@"document"] == presentationNotesDocument)
        [self setPresentationNotesDocument:nil];
}

#pragma mark Notification observation

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKPDFDocumentDefaultsObservationContext) {
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKAutoCheckFileUpdateKey]) {
            [self checkFileUpdatesIfNeeded];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Pdfsync support

- (void)setFileURL:(NSURL *)absoluteURL {
    // this shouldn't be necessary, but better be sure
    if ([self fileName] && [[self fileURL] isEqual:absoluteURL] == NO)
        [self stopCheckingFileUpdates];
    [super setFileURL:absoluteURL];
    if ([absoluteURL isFileURL])
        [synchronizer setFileName:[absoluteURL path]];
    else
        [synchronizer setFileName:nil];
    // if we're saving this will be called when saving has finished
    if (docFlags.isSaving == NO)
        [self checkFileUpdatesIfNeeded];
}

- (SKPDFSynchronizer *)synchronizer {
    if (synchronizer == nil) {
        synchronizer = [[SKPDFSynchronizer alloc] init];
        [synchronizer setDelegate:self];
        [synchronizer setFileName:[self fileName]];
    }
    return synchronizer;
}

- (void)synchronizer:(SKPDFSynchronizer *)synchronizer foundLine:(NSInteger)line inFile:(NSString *)file {
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        
        NSString *editorPreset = [[NSUserDefaults standardUserDefaults] objectForKey:SKTeXEditorPresetKey];
        NSString *editorCmd = [[NSUserDefaults standardUserDefaults] objectForKey:SKTeXEditorCommandKey];
        NSMutableString *cmdString = [[[[NSUserDefaults standardUserDefaults] objectForKey:SKTeXEditorArgumentsKey] mutableCopy] autorelease];
        
        if ([editorCmd isAbsolutePath] == NO) {
            NSMutableArray *searchPaths = [NSMutableArray arrayWithObjects:@"/usr/bin", @"/usr/local/bin", nil];
            NSEnumerator *pathEnum;
            NSString *path;
            NSString *toolPath;
            NSBundle *appBundle;
            NSFileManager *fm = [NSFileManager defaultManager];
            
            if ([editorPreset isEqualToString:@""] == NO) {
                if ((path = [[NSWorkspace sharedWorkspace] fullPathForApplication:editorPreset]) &&
                    (appBundle = [NSBundle bundleWithPath:path])) {
                    [searchPaths addObject:[appBundle sharedSupportPath]];
                    [searchPaths addObject:[appBundle resourcePath]];
                    if ([editorPreset isEqualToString:@"BBEdit"] == NO)
                        [searchPaths addObject:[[appBundle executablePath] stringByDeletingLastPathComponent]];
                }
            } else {
                pathEnum = [[[SKApplicationController sharedApplicationController] applicationSupportDirectories] objectEnumerator];
                while (path = [pathEnum nextObject]) {
                    [searchPaths addObject:path];
                    [searchPaths addObject:[path stringByAppendingPathComponent:@"Scripts"]];
                }
            }
            
            pathEnum = [searchPaths objectEnumerator];
            while (path = [pathEnum nextObject]) {
                toolPath = [path stringByAppendingPathComponent:editorCmd];
                if ([fm isExecutableFileAtPath:toolPath]) {
                    editorCmd = toolPath;
                    break;
                }
                toolPath = [[path stringByAppendingPathComponent:@"bin"] stringByAppendingPathComponent:editorCmd];
                if ([fm isExecutableFileAtPath:toolPath]) {
                    editorCmd = toolPath;
                    break;
                }
            }
        }
        
        NSRange range = NSMakeRange(0, 0);
        unichar prevChar, nextChar;
        while (NSMaxRange(range) < [cmdString length]) {
            range = [cmdString rangeOfString:@"%line" options:NSLiteralSearch range:NSMakeRange(NSMaxRange(range), [cmdString length] - NSMaxRange(range))];
            if (range.location == NSNotFound)
                break;
            nextChar = NSMaxRange(range) < [cmdString length] ? [cmdString characterAtIndex:NSMaxRange(range)] : 0;
            if ([[NSCharacterSet letterCharacterSet] characterIsMember:nextChar] == NO) {
                NSString *lineString = [NSString stringWithFormat:@"%ld", (long)(line + 1)];
                [cmdString replaceCharactersInRange:range withString:lineString];
                range.length = [lineString length];
            }
        }
        
        range = NSMakeRange(0, 0);
        while (NSMaxRange(range) < [cmdString length]) {
            range = [cmdString rangeOfString:@"%file" options:NSLiteralSearch range:NSMakeRange(NSMaxRange(range), [cmdString length] - NSMaxRange(range))];
            if (range.location == NSNotFound)
                break;
            prevChar = range.location > 0 ? [cmdString characterAtIndex:range.location - 1] : 0;
            nextChar = NSMaxRange(range) < [cmdString length] ? [cmdString characterAtIndex:NSMaxRange(range)] : 0;
            if ([[NSCharacterSet letterCharacterSet] characterIsMember:nextChar] == NO) {
                NSString *escapedFile = (prevChar == '\'' && nextChar == '\'') ? file : [file stringByEscapingShellChars];
                [cmdString replaceCharactersInRange:range withString:escapedFile];
                range.length = [escapedFile length];
            }
        }
        
        [cmdString insertString:@"\" " atIndex:0];
        [cmdString insertString:editorCmd atIndex:0];
        [cmdString insertString:@"\"" atIndex:0];
        
        NSString *extension = [editorCmd pathExtension];
        if (extension) {
            NSString *theUTI = [(id)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL) autorelease];
            if (theUTI && UTTypeConformsTo((CFStringRef)theUTI, CFSTR("com.apple.applescript.script")) || UTTypeConformsTo((CFStringRef)theUTI, CFSTR("com.apple.applescript.text")))
                [cmdString insertString:@"/usr/bin/osascript " atIndex:0];
        }
        
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmdString, nil] currentDirectoryPath:[file stringByDeletingLastPathComponent]];
    }
}

- (void)synchronizer:(SKPDFSynchronizer *)synchronizer foundLocation:(NSPoint)point atPageIndex:(NSUInteger)pageIndex isFlipped:(BOOL)isFlipped {
    PDFPage *page = [[self pdfDocument] pageAtIndex:pageIndex];
    if (isFlipped)
        point.y = NSMaxY([page boundsForBox:kPDFDisplayBoxMediaBox]) - point.y;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldHighlightSearchResultsKey])
        [[self mainWindowController] addTemporaryAnnotationForPoint:point onPage:page];
    [[self pdfView] displayLineAtPoint:point inPageAtIndex:pageIndex];
}


#pragma mark Accessors

- (SKMainWindowController *)mainWindowController {
    return mainWindowController;
}

- (PDFDocument *)pdfDocument{
    return [[self mainWindowController] pdfDocument];
}

- (NSDictionary *)currentDocumentSetup {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    NSString *fileName = [self fileName];
    if (fileName) {
        NSData *data = [[BDAlias aliasWithPath:fileName] aliasData];
        
        [setup setObject:fileName forKey:SKDocumentSetupFileNameKey];
        if(data)
            [setup setObject:data forKey:SKDocumentSetupAliasKey];
        
        [setup addEntriesFromDictionary:[[self mainWindowController] currentSetup]];
    }
    
    return setup;
}

- (void)setInitialSetup:(NSDictionary *)setup {
    [[self mainWindowController] setInitialSetup:setup];
}

- (void)findString:(NSString *)string options:(NSInteger)options{
    [[self mainWindowController] findString:string options:options];
}

- (NSString *)findString {
    return [[[self pdfView] currentSelection] string];
}

- (SKPDFView *)pdfView {
    return [[self mainWindowController] pdfView];
}

- (SKPDFDocument *)presentationNotesDocument {
    return presentationNotesDocument;
}

- (void)setPresentationNotesDocument:(SKPDFDocument *)aDocument {
    if (presentationNotesDocument != aDocument) {
        [presentationNotesDocument release];
        presentationNotesDocument = [aDocument retain];
    }
}

- (NSArray *)fileIDStrings {
    if (pdfData == nil)
        return nil;
    const char *EOFPattern = "%%EOF";
    const char *trailerPattern = "trailer";
    const char *IDPattern = "/ID";
    const char *startArrayPattern = "[";
    const char *endArrayPattern = "]";
    const char *startStringPattern = "<";
    const char *endStringPattern = ">";
    NSUInteger patternLength = strlen(EOFPattern);
    NSRange range = NSMakeRange([pdfData length] - 1024, 1024);
    if (range.location < 0)
        range = NSMakeRange(0, [pdfData length]);
    NSUInteger EOFIndex = [pdfData indexOfBytes:EOFPattern length:patternLength options:NSBackwardsSearch range:range];
    NSUInteger trailerIndex, IDIndex, startArrayIndex, endArrayIndex, startStringIndex, endStringIndex;
    NSData *firstIDData = nil;
    NSData *secondIDData = nil;
    
    if (EOFIndex != NSNotFound) {
        range = NSMakeRange(EOFIndex - 2048, 2048);
        if (range.location < 0)
            range = NSMakeRange(0, EOFIndex);
        patternLength = strlen(trailerPattern);
        trailerIndex = [pdfData indexOfBytes:trailerPattern length:patternLength options:NSBackwardsSearch range:range];
        if (trailerIndex != NSNotFound) {
            range = NSMakeRange(trailerIndex + patternLength, EOFIndex - trailerIndex - patternLength);
            patternLength = strlen(IDPattern);
            IDIndex = [pdfData indexOfBytes:IDPattern length:patternLength options:0 range:range];
            if (IDIndex != NSNotFound) {
                range = NSMakeRange(IDIndex + patternLength, EOFIndex - IDIndex - patternLength);
                patternLength = strlen(startArrayPattern);
                startArrayIndex = [pdfData indexOfBytes:startArrayPattern length:patternLength options:0 range:range];
                if (startArrayIndex != NSNotFound) {
                    range = NSMakeRange(startArrayIndex + patternLength, EOFIndex - startArrayIndex - patternLength);
                    patternLength = strlen(endArrayPattern);
                    endArrayIndex = [pdfData indexOfBytes:endArrayPattern length:patternLength options:0 range:range];
                    if (endArrayIndex != NSNotFound) {
                        range = NSMakeRange(startArrayIndex + 1, endArrayIndex - startArrayIndex - 1);
                        patternLength = strlen(startStringPattern);
                        startStringIndex = [pdfData indexOfBytes:startStringPattern length:patternLength options:0 range:range];
                        if (startStringIndex != NSNotFound) {
                            range = NSMakeRange(startStringIndex + patternLength, endArrayIndex - startStringIndex - patternLength);
                            patternLength = strlen(endStringPattern);
                            endStringIndex = [pdfData indexOfBytes:endStringPattern length:patternLength options:0 range:range];
                            if (endStringIndex != NSNotFound) {
                                if (firstIDData = [pdfData subdataWithRange:NSMakeRange(startStringIndex + 1, endStringIndex - startStringIndex - 1)]) {
                                    range = NSMakeRange(endStringIndex + patternLength, endArrayIndex - endStringIndex - patternLength);
                                    patternLength = strlen(startStringPattern);
                                    startStringIndex = [pdfData indexOfBytes:startStringPattern length:patternLength options:0 range:range];
                                    if (startStringIndex != NSNotFound) {
                                        range = NSMakeRange(startStringIndex + patternLength, endArrayIndex - startStringIndex - patternLength);
                                        patternLength = strlen(endStringPattern);
                                        endStringIndex = [pdfData indexOfBytes:endStringPattern length:patternLength options:0 range:range];
                                        if (endStringIndex != NSNotFound) {
                                            secondIDData = [pdfData subdataWithRange:NSMakeRange(startStringIndex + 1, endStringIndex - startStringIndex - 1)];
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if (secondIDData)
        return [NSArray arrayWithObjects:
                    [[[NSString alloc] initWithData:firstIDData encoding:NSISOLatin1StringEncoding] autorelease],
                    [[[NSString alloc] initWithData:secondIDData encoding:NSISOLatin1StringEncoding] autorelease], nil];
    return nil;
}

- (void)setPrintInfo:(NSPrintInfo *)printInfo {
    if (autoRotateButton) {
        BOOL autoRotate = [autoRotateButton state] == NSOnState;
        if (autoRotate != [[printInfo valueForKeyPath:@"dictionary.PDFPrintAutoRotate"] boolValue]) {
            [printInfo setValue:[NSNumber numberWithBool:autoRotate] forKeyPath:@"dictionary.PDFPrintAutoRotate"];
            [[NSUserDefaults standardUserDefaults] setBool:autoRotate forKey:SKAutoRotatePrintedPagesKey];
        }
    }
    [[self undoManager] disableUndoRegistration];
    [super setPrintInfo:printInfo];
    [[self undoManager] enableUndoRegistration];
}

- (BOOL)preparePageLayout:(NSPageLayout *)pageLayout {
    if (autoRotateButton == nil) {
        autoRotateButton = [[NSButton alloc] init];
        [autoRotateButton setBezelStyle:NSRoundedBezelStyle];
        [autoRotateButton setButtonType:NSSwitchButton];
        [autoRotateButton setTitle:NSLocalizedString(@"Auto Rotate Pages", @"Print layout sheet button title")];
        [autoRotateButton sizeToFit];
    }
    BOOL autoRotate = [[[self printInfo] valueForKeyPath:@"dictionary.PDFPrintAutoRotate"] boolValue];
    [autoRotateButton setState:autoRotate ? NSOnState : NSOffState];
    [pageLayout setAccessoryView:autoRotateButton];
    return YES;
}

- (NSArray *)snapshots {
    return [[self mainWindowController] snapshots];
}

- (NSArray *)tags {
    return [[self mainWindowController] tags];
}

- (double)rating {
    return [[self mainWindowController] rating];
}

#pragma mark Passwords

- (const char *)keychainServiceName {
    NSArray *fileIDStrings = [self fileIDStrings];
    if ([fileIDStrings count])
        return [[@"Skim - " stringByAppendingString:[fileIDStrings objectAtIndex:0]] UTF8String];
    NSString *md5HexString = [[pdfData md5Signature] hexString];
    if (md5HexString)
        return [[@"Skim - " stringByAppendingString:md5HexString] UTF8String];
    return NULL;
}

- (void)savePasswordInKeychain:(NSString *)aPassword {
    if ([[self pdfDocument] isLocked])
        return;
    
    NSInteger saveOption = [[NSUserDefaults standardUserDefaults] integerForKey:SKSavePasswordOptionKey];
    if (saveOption != NSAlertAlternateReturn) {
        const char *serviceName = [self keychainServiceName];
        if (serviceName != NULL) {
            if (saveOption == NSAlertOtherReturn) {
                NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Remember Password?", @"Message in alert dialog")]
                                                 defaultButton:NSLocalizedString(@"Yes", @"Button title")
                                               alternateButton:NSLocalizedString(@"No", @"Button title")
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"Do you want to save this password in your Keychain?", @"Informative text in alert dialog")];
                saveOption = [alert runModal];
            }
            if (saveOption == NSAlertDefaultReturn) {
                const char *userName = [NSUserName() UTF8String];
                const char *comment = [[self fileName] UTF8String];
                
                OSStatus err;
                SecKeychainItemRef itemRef = NULL;    
                const void *passwordData = NULL;
                UInt32 passwordLength = 0;
                
                // first see if the password exists in the keychain
                err = SecKeychainFindGenericPassword(NULL, strlen(serviceName), serviceName, strlen(userName), userName, &passwordLength, (void **)&passwordData, &itemRef);
                
                if(err == noErr){
                    // password was on keychain, so flush the buffer and then modify the keychain
                    SecKeychainItemFreeContent(NULL, (void *)passwordData);
                    passwordData = NULL;
                    
                    passwordData = [aPassword UTF8String];
                    SecKeychainAttribute attrs[] = {
                        { kSecAccountItemAttr, strlen(userName), (char *)userName },
                        { kSecServiceItemAttr, strlen(serviceName), (char *)serviceName },
                        { kSecCommentItemAttr, comment == NULL ? 0 : strlen(comment), (char *)comment } };
                    const SecKeychainAttributeList attributes = { comment == NULL ? 2 : 3, attrs };
                    
                    err = SecKeychainItemModifyAttributesAndData(itemRef, &attributes, strlen(passwordData), passwordData);
                } else if(err == errSecItemNotFound){
                    // password not on keychain, so add it
                    passwordData = [aPassword UTF8String];
                    err = SecKeychainAddGenericPassword(NULL, strlen(serviceName), serviceName, strlen(userName), userName, strlen(passwordData), passwordData, &itemRef);    
                    if (err == noErr && comment != NULL) {
                        SecKeychainAttribute attrs[] = { { kSecCommentItemAttr, strlen(comment), (char *)comment } };
                        const SecKeychainAttributeList attributes = { 1, attrs };
                        
                        err = SecKeychainItemModifyAttributesAndData(itemRef, &attributes, strlen(passwordData), passwordData);
                    }
                } else 
                    NSLog(@"Error %d occurred setting password", err);
            }
        }
    }
}

- (BOOL)tryToUnlockDocument:(PDFDocument *)document {
    if (NSAlertAlternateReturn != [[NSUserDefaults standardUserDefaults] integerForKey:SKSavePasswordOptionKey]) {
        const char *serviceName = [self keychainServiceName];
        if (serviceName != NULL) {
            const char *userName = [NSUserName() UTF8String];
            void *passwordData = NULL;
            UInt32 passwordLength = 0;
            NSData *data = nil;
            NSString *aPassword = nil;
            OSErr err = SecKeychainFindGenericPassword(NULL, strlen(serviceName), serviceName, strlen(userName), userName, &passwordLength, &passwordData, NULL);
            if (err == noErr) {
                data = [NSData dataWithBytes:passwordData length:passwordLength];
                SecKeychainItemFreeContent(NULL, passwordData);
                aPassword = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                return [document unlockWithPassword:aPassword];
            }
        }
    }
    return NO;
}

#pragma mark Scripting support

- (NSArray *)pages {
    NSMutableArray *pages = [NSMutableArray array];
    PDFDocument *pdfDoc = [self pdfDocument];
    NSInteger i, count = [pdfDoc pageCount];
    for (i = 0; i < count; i++)
        [pages addObject:[pdfDoc pageAtIndex:i]];
    return pages;
}

- (NSUInteger)countOfPages {
    return [[self pdfDocument] pageCount];
}

- (PDFPage *)objectInPagesAtIndex:(NSUInteger)anIndex {
    return [[self pdfDocument] pageAtIndex:anIndex];
}

- (NSArray *)notes {
    return [[self mainWindowController] notes];
}

- (void)insertInNotes:(PDFAnnotation *)newNote {
    PDFPage *page = [newNote page];
    if (page && [[page annotations] containsObject:newNote] == NO) {
        SKPDFView *pdfView = [self pdfView];
        
        [pdfView addAnnotation:newNote toPage:page];
        [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];
    } else {
        [[NSScriptCommand currentCommand] setScriptErrorNumber:NSReceiversCantHandleCommandScriptError]; 
    }
}

- (void)insertObject:(PDFAnnotation *)newNote inNotesAtIndex:(NSUInteger)anIndex {
    [self insertInNotes:newNote];
}

- (void)removeObjectFromNotesAtIndex:(NSUInteger)anIndex {
    PDFAnnotation *note = [[self notes] objectAtIndex:anIndex];
    
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
    return [note isSkimNote] ? note : [NSNull null];
}

- (void)setActiveNote:(id)note {
    if ([note isEqual:[NSNull null]] == NO && [note isSkimNote])
        [[self pdfView] setActiveAnnotation:note];
}

- (NSTextStorage *)richText {
    PDFDocument *doc = [self pdfDocument];
    NSUInteger i, count = [doc pageCount];
    NSTextStorage *textStorage = [[[NSTextStorage alloc] init] autorelease];
    NSAttributedString *attrString;
    [textStorage beginEditing];
    for (i = 0; i < count; i++) {
        if (i > 0)
            [[textStorage mutableString] appendString:@"\n"];
        if (attrString = [[doc pageAtIndex:i] attributedString])
            [textStorage appendAttributedString:attrString];
    }
    [textStorage endEditing];
    return textStorage;
}

- (id)selectionSpecifier {
    PDFSelection *sel = [[self pdfView] currentSelection];
    return sel ? [sel objectSpecifier] : [NSArray array];
}

- (void)setSelectionSpecifier:(id)specifier {
    PDFSelection *selection = [PDFSelection selectionWithSpecifier:specifier];
    [[self pdfView] setCurrentSelection:selection];
}

- (NSData *)selectionQDRect {
    Rect qdRect = SKQDRectFromNSRect([[self pdfView] currentSelectionRect]);
    return [NSData dataWithBytes:&qdRect length:sizeof(Rect)];
}

- (void)setSelectionQDRect:(NSData *)inQDRectAsData {
    if ([inQDRectAsData length] == sizeof(Rect)) {
        const Rect *qdBounds = (const Rect *)[inQDRectAsData bytes];
        NSRect newBounds = SKNSRectFromQDRect(*qdBounds);
        [[self pdfView] setCurrentSelectionRect:newBounds];
        if ([[self pdfView] currentSelectionPage] == nil)
            [[self pdfView] setCurrentSelectionPage:[[self pdfView] currentPage]];
    }
}

- (id)selectionPage {
    PDFPage *page = [[self pdfView] currentSelectionPage];
    return (id)page ?: (id)[NSNull null];
}

- (void)setSelectionPage:(PDFPage *)page {
    [[self pdfView] setCurrentSelectionPage:[page isKindOfClass:[PDFPage class]] ? page : nil];
}

- (NSDictionary *)pdfViewSettings {
    return SKScriptingPDFViewSettingsFromPDFViewSettings([[self mainWindowController] currentPDFSettings]);
}

- (void)setPdfViewSettings:(NSDictionary *)pdfViewSettings {
    [[self mainWindowController] applyPDFSettings:SKPDFViewSettingsFromScriptingPDFViewSettings(pdfViewSettings)];
}

- (NSDictionary *)documentAttributes {
    NSMutableDictionary *info = [[[[SKInfoWindowController sharedInstance] infoForDocument:self] mutableCopy] autorelease];
    [info removeObjectForKey:@"KeywordsString"];
    return info;
}

// fix a bug in Apple's implementation, which ignores the file type (for export), also make some more sensible choice of save operation
- (id)handleSaveScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id fileURL = [args objectForKey:@"File"];
    id fileType = [args objectForKey:@"FileType"];
    // we don't want to expose the pboard types or UTIs to the user
    if (fileType) {
        NSString *normalizedType = SKNormalizedDocumentType(fileType);
        if ([fileType isEqualToString:normalizedType] == NO) {
            fileType = SKPDFDocumentType;
            NSMutableDictionary *arguments = [[command arguments] mutableCopy];
            [arguments setObject:fileType forKey:@"FileType"];
            [command setArguments:arguments];
            [arguments release];
        }
    }
    if (fileURL) {
        if ([fileURL isKindOfClass:[NSURL class]] == NO) {
            [command setScriptErrorNumber:NSArgumentsWrongScriptError];
            [command setScriptErrorString:@"The file is not a file or alias."];
        } else {
            NSSaveOperationType saveOperation = NSSaveToOperation;
            NSString *extension = [[fileURL path] pathExtension];
            
            if (fileType == nil) {
                if ([extension caseInsensitiveCompare:@"pdf"] == NSOrderedSame)
                    fileType = SKPDFDocumentType;
                else if ([extension caseInsensitiveCompare:@"ps"] == NSOrderedSame && SKIsPostScriptDocumentType([self fileType]))
                    fileType = SKPostScriptDocumentType;
                else if ([extension caseInsensitiveCompare:@"dvi"] == NSOrderedSame && SKIsDVIDocumentType([self fileType]))
                    fileType = SKDVIDocumentType;
                else
                    fileType = [self fileType];
                saveOperation = NSSaveAsOperation;
            }
            
            NSString *requiredExtension = [self fileNameExtensionForType:fileType saveOperation:saveOperation];
            
            if (extension == nil && requiredExtension) {
                extension = requiredExtension;
                fileURL = [NSURL fileURLWithPath:[[fileURL path] stringByAppendingPathExtension:extension]];
            }
            if (requiredExtension && [requiredExtension caseInsensitiveCompare:extension] != NSOrderedSame) {
                [command setScriptErrorNumber:NSArgumentsWrongScriptError];
                [command setScriptErrorString:[NSString stringWithFormat:@"Invalid file extension for this file type."]];
            } else if ([self saveToURL:fileURL ofType:fileType forSaveOperation:saveOperation error:NULL] == NO) {
                [command setScriptErrorNumber:NSInternalScriptError];
                [command setScriptErrorString:saveOperation == NSSaveToOperation ? @"Unable to export." : @"Unable to save."];
            }
        }
    } else if (fileType) {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"Missing file argument."];
    } else {
        return [super handleSaveScriptCommand:command];
    }
    return nil;
}

- (id)handlePrintScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id settings = [args objectForKey:@"PrintSettings"];
    id showPanel = [args objectForKey:@"ShowPrintDialog"];
    
    NSPrintInfo *printInfo = [[[self printInfo] copy] autorelease];
    
    if ([settings isKindOfClass:[NSDictionary class]]) {
        settings = [[settings mutableCopy] autorelease];
        id value;
        if (value = [settings objectForKey:NSPrintDetailedErrorReporting])
            [settings setObject:[NSNumber numberWithBool:[value intValue] == 'lwdt'] forKey:NSPrintDetailedErrorReporting];
        if ((value = [settings objectForKey:NSPrintPrinterName]) && (value = [NSPrinter printerWithName:value]))
            [settings setObject:value forKey:NSPrintPrinter];
        if ([settings objectForKey:NSPrintFirstPage] || [settings objectForKey:NSPrintLastPage]) {
            [settings setObject:[NSNumber numberWithBool:NO] forKey:NSPrintAllPages];
            if ([settings objectForKey:NSPrintFirstPage] == nil)
                [settings setObject:[NSNumber numberWithInt:1] forKey:NSPrintLastPage];
            if ([settings objectForKey:NSPrintLastPage] == nil)
                [settings setObject:[NSNumber numberWithInt:[[self pdfDocument] pageCount]] forKey:NSPrintLastPage];
        }
        [[printInfo dictionary] addEntriesFromDictionary:settings];
    }
    
    if (showPanel && [showPanel boolValue] == NO)
        [[printInfo dictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"SKSuppressPrintPanel"];
    
    [[self pdfView] printWithInfo:printInfo autoRotate:YES];
    
    return nil;
}

- (void)handleRevertScriptCommand:(NSScriptCommand *)command {
    if ([self fileURL] && [[NSFileManager defaultManager] fileExistsAtPath:[self fileName]]) {
        if ([self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:NULL] == NO) {
            [command setScriptErrorNumber:NSInternalScriptError];
            [command setScriptErrorString:@"Revert failed."];
        }
    } else {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"File does not exist."];
    }
}

- (void)handleGoToScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id location = [args objectForKey:@"To"];
    
    if ([location isKindOfClass:[PDFPage class]]) {
        [[self pdfView] goToPage:(PDFPage *)location];
    } else if ([location isKindOfClass:[PDFAnnotation class]]) {
        [[self pdfView] scrollAnnotationToVisible:(PDFAnnotation *)location];
    } else if ([location isKindOfClass:[SKLine class]]) {
        id source = [args objectForKey:@"Source"];
        if ([source isKindOfClass:[NSString class]])
            source = [NSURL fileURLWithPath:source];
        if ([source isKindOfClass:[NSURL class]] == NO)
            source = [self fileURL];
        [[self synchronizer] findPageAndLocationForLine:[location index] inFile:[[source path] stringByReplacingPathExtension:@"tex"]];
    } else {
        PDFSelection *selection = [PDFSelection selectionWithSpecifier:[[command arguments] objectForKey:@"To"]];
        if ([[selection pages] count]) {
            PDFPage *page = [[selection pages] objectAtIndex:0];
            NSRect bounds = [selection boundsForPage:page];
            [[self pdfView] scrollRect:bounds inPageToVisible:page];
        }
    }
}

- (id)handleFindScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id text = [args objectForKey:@"Text"];
    id specifier = nil;
    
    if ([text isKindOfClass:[NSString class]] == NO) {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"The text to find is missing or is not a string."];
        return nil;
    } else {
        id from = [args objectForKey:@"From"];
        id backward = [args objectForKey:@"Backward"];
        id caseSensitive = [args objectForKey:@"CaseSensitive"];
        PDFSelection *selection = nil;
        NSInteger options = 0;
        
        if (from)
            selection = [PDFSelection selectionWithSpecifier:from];
        
        if ([backward isKindOfClass:[NSNumber class]] && [backward boolValue])
            options |= NSBackwardsSearch;
        if ([caseSensitive isKindOfClass:[NSNumber class]] == NO || [caseSensitive boolValue] == NO)
            options |= NSCaseInsensitiveSearch;
        
        if (selection = [[self mainWindowController] findString:text fromSelection:selection withOptions:options])
            specifier = [selection objectSpecifier];
    }
    
    return specifier ?: [NSArray array];
}

- (void)handleShowTeXScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id page = [args objectForKey:@"Page"];
    id pointData = [args objectForKey:@"Point"];
    NSPoint point = NSZeroPoint;
    
    if ([page isKindOfClass:[PDFPage class]] == NO)
        page = [[self pdfView] currentPage];
    if ([pointData isKindOfClass:[NSDate class]] && [pointData length] != sizeof(Point)) {
        const Point *qdPoint = (const Point *)[pointData bytes];
        point = SKNSPointFromQDPoint(*qdPoint);
    } else {
        NSRect bounds = [page boundsForBox:[[self pdfView] displayBox]];
        point = NSMakePoint(NSMidX(bounds), NSMidY(bounds));
    }
    if (page) {
        NSUInteger pageIndex = [page pageIndex];
        PDFSelection *sel = [page selectionForLineAtPoint:point];
        NSRect rect = sel ? [sel boundsForPage:page] : NSMakeRect(point.x - 20.0, point.y - 5.0, 40.0, 10.0);
        
        [[self synchronizer] findFileAndLineForLocation:point inRect:rect pageBounds:[page boundsForBox:kPDFDisplayBoxMediaBox] atPageIndex:pageIndex];
    }
}

- (void)handleConvertNotesScriptCommand:(NSScriptCommand *)command {
    if (SKIsPDFDocumentType([self fileType]) || SKIsPDFBundleDocumentType([self fileType]))
        [self convertNotesSheetDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:NULL];
}

@end


@implementation NSWindow (SKScriptingExtensions)

static id (*original_document)(id, SEL) = NULL;

- (id)replacement_document {
    id document = original_document(self, _cmd);
    return [[NSApp orderedDocuments] containsObject:document] ? document : [NSNull null];
}

+ (void)load {
    original_document = (id (*)(id, SEL))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(document), @selector(replacement_document));
}

- (void)handleRevertScriptCommand:(NSScriptCommand *)command {
    id document = [[self windowController] document];
    if (document == nil) {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"Window does not have a document."];
    } else
        [document handleRevertScriptCommand:command];
}

@end


NSDictionary *SKScriptingPDFViewSettingsFromPDFViewSettings(NSDictionary *settings) {
    NSMutableDictionary *setup = [[settings mutableCopy] autorelease];
    
    FourCharCode displayMode = 0;
    switch ([[setup objectForKey:@"displayMode"] intValue]) {
        case kPDFDisplaySinglePage: displayMode = SKScriptingDisplaySinglePage; break;
        case kPDFDisplaySinglePageContinuous: displayMode = SKScriptingDisplaySinglePageContinuous; break;
        case kPDFDisplayTwoUp: displayMode = SKScriptingDisplayTwoUp; break;
        case kPDFDisplayTwoUpContinuous: displayMode = SKScriptingDisplayTwoUpContinuous; break;
    }
    [setup setObject:[NSNumber numberWithUnsignedLong:displayMode] forKey:@"displayMode"];
    
    FourCharCode displayBox = 0;
    switch ([[setup objectForKey:@"displayBox"] intValue]) {
        case kPDFDisplayBoxMediaBox: displayBox = SKScriptingMediaBox; break;
        case kPDFDisplayBoxCropBox: displayBox = SKScriptingCropBox; break;
    }
    [setup setObject:[NSNumber numberWithUnsignedLong:displayBox] forKey:@"displayBox"];
    
    return setup;
}

NSDictionary *SKPDFViewSettingsFromScriptingPDFViewSettings(NSDictionary *settings) {
    NSMutableDictionary *setup = [[settings mutableCopy] autorelease];
    NSNumber *number;
    
    if (number = [setup objectForKey:@"displayMode"]) {
        NSInteger displayMode = 0;
        switch ([number unsignedLongValue]) {
            case SKScriptingDisplaySinglePage: displayMode = kPDFDisplaySinglePage; break;
            case SKScriptingDisplaySinglePageContinuous: displayMode = kPDFDisplaySinglePageContinuous; break;
            case SKScriptingDisplayTwoUp: displayMode = kPDFDisplayTwoUp; break;
            case SKScriptingDisplayTwoUpContinuous: displayMode = kPDFDisplayTwoUpContinuous; break;
        }
        [setup setObject:[NSNumber numberWithInt:displayMode] forKey:@"displayMode"];
    }
    
    if (number = [setup objectForKey:@"displayBox"]) {
        NSInteger displayBox = 0;
        switch ([number unsignedLongValue]) {
            case SKScriptingMediaBox: displayBox = kPDFDisplayBoxMediaBox; break;
            case SKScriptingCropBox: displayBox = kPDFDisplayBoxCropBox; break;
        }
        [setup setObject:[NSNumber numberWithInt:displayBox] forKey:@"displayBox"];
    }
    
    return setup;
}
