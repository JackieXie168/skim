//
//  SKMainDocument.m
//  Skim
//
//  Created by Michael McCracken on 12/5/06.
/*
 This software is Copyright (c) 2006-2011
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

#import "SKMainDocument.h"
#import <Quartz/Quartz.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SkimNotes/SkimNotes.h>
#import "SKMainWindowController.h"
#import "SKPDFDocument.h"
#import "PDFAnnotation_SKExtensions.h"
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKConversionProgressController.h"
#import "SKFindController.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKPDFView.h"
#import "SKNoteWindowController.h"
#import "SKPDFSynchronizer.h"
#import "NSString_SKExtensions.h"
#import "SKDocumentController.h"
#import "SKTemplateParser.h"
#import "SKApplicationController.h"
#import "PDFSelection_SKExtensions.h"
#import "SKInfoWindowController.h"
#import "SKLine.h"
#import "SKApplicationController.h"
#import "NSFileManager_SKExtensions.h"
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
#import "PDFAnnotationMarkup_SKExtensions.h"
#import "NSWindowController_SKExtensions.h"
#import "NSInvocation_SKExtensions.h"
#import "SKSyncPreferences.h"
#import "NSScreen_SKExtensions.h"
#import "NSURL_SKExtensions.h"
#import "SKFileUpdateChecker.h"
#import "NSError_SKExtensions.h"

#define BUNDLE_DATA_FILENAME @"data"
#define PRESENTATION_OPTIONS_KEY @"net_sourceforge_skim-app_presentation_options"
#define OPEN_META_TAGS_KEY @"com.apple.metadata:kOMUserTags"
#define OPEN_META_RATING_KEY @"com.apple.metadata:kOMStarRating"

NSString *SKSkimFileDidSaveNotification = @"SKSkimFileDidSaveNotification";

#define SKLastExportedTypeKey @"SKLastExportedType"
#define SKDisableReloadAlertKey @"SKDisableReloadAlert"

#define URL_KEY             @"URL"
#define TYPE_KEY            @"type"
#define SAVEOPERATION_KEY   @"saveOperation"
#define CALLBACK_KEY        @"callback"
#define TMPPATH_KEY         @"tmpPath"

#define SOURCEPATH_KEY  @"sourcePath"
#define TARGETPATH_KEY  @"targetPath"
#define EMAIL_KEY       @"email"

#define SKPresentationOptionsKey    @"PresentationOptions"
#define SKTagsKey                   @"Tags"
#define SKRatingKey                 @"Rating"

static NSString *SKPDFPasswordServiceName = @"Skim PDF password";


@interface PDFAnnotation (SKPrivateDeclarations)
- (void)setPage:(PDFPage *)newPage;
@end


@interface SKTemporaryData : NSObject {
    PDFDocument *pdfDocument;
    NSArray *noteDicts;
    NSDictionary *presentationOptions;
    NSArray *openMetaTags;
    double openMetaRating;
}

@property (nonatomic, retain) PDFDocument *pdfDocument;
@property (nonatomic, copy) NSArray *noteDicts;
@property (nonatomic, copy) NSDictionary *presentationOptions;
@property (nonatomic, copy) NSArray *openMetaTags;
@property (nonatomic) double openMetaRating;

@end


@interface SKMainDocument (SKPrivate)

- (BOOL)tryToUnlockDocument:(PDFDocument *)document;

- (void)handleWindowWillCloseNotification:(NSNotification *)notification;

- (SKProgressController *)progressController;

@end

#pragma mark -

@implementation SKMainDocument

@synthesize mainWindowController;
@dynamic pdfDocument, pdfView, fileIDStrings, synchronizer, snapshots, tags, rating, currentPage, activeNote, richText, selectionSpecifier, selectionQDRect,selectionPage, pdfViewSettings;

+ (BOOL)isPDFDocument { return YES; }

- (id)init {
    if (self = [super init]) {
        fileUpdateChecker = [[SKFileUpdateChecker alloc] initForDocument:self];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // shouldn't need this here, but better be safe
    [fileUpdateChecker stopCheckingFileUpdates];
    SKDESTROY(fileUpdateChecker);
    SKDESTROY(mainWindowController);
    [synchronizer terminate];
    [synchronizer setDelegate:nil];
    SKDESTROY(synchronizer);
    SKDESTROY(fileUpdateChecker);
    SKDESTROY(pdfData);
    SKDESTROY(psOrDviData);
    SKDESTROY(readNotesAccessoryView);
    SKDESTROY(progressController);
    SKDESTROY(tmpData);
    SKDESTROY(printCallback);
    [super dealloc];
}

- (void)makeWindowControllers{
    mainWindowController = [[SKMainWindowController alloc] init];
    [mainWindowController setShouldCloseDocument:YES];
    [self addWindowController:mainWindowController];
}

- (void)setDataFromTmpData {
    PDFDocument *pdfDoc = [tmpData pdfDocument];
    [self tryToUnlockDocument:pdfDoc];
    [[self mainWindowController] setPdfDocument:pdfDoc];
    
    [[self mainWindowController] addAnnotationsFromDictionaries:[tmpData noteDicts] replace:YES];
    
    if ([tmpData presentationOptions])
        [[self mainWindowController] setPresentationOptions:[tmpData presentationOptions]];
    
    [[self mainWindowController] setTags:[tmpData openMetaTags]];
    
    [[self mainWindowController] setRating:[tmpData openMetaRating]];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController{
    [[self undoManager] disableUndoRegistration];
    
    // set a copy, because we change the printInfo, and we don't want to change the shared instance
    [self setPrintInfo:[[[self printInfo] copy] autorelease]];
    
    [self setDataFromTmpData];
    [tmpData release];
    tmpData = nil;
    
    [[self undoManager] enableUndoRegistration];
    
    if ([self fileURL])
        [fileUpdateChecker checkFileUpdatesIfNeeded];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowWillCloseNotification:) 
                                                 name:NSWindowWillCloseNotification object:[[self mainWindowController] window]];
}

- (void)showWindows{
    [super showWindows];
    
    // Get the search string keyword if available (Spotlight passes this)
    NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    NSString *searchString;
    
    if ([event eventID] == kAEOpenDocuments && 
        (searchString = [[event descriptorForKeyword:keyAESearchText] stringValue]) && 
        [@"" isEqualToString:searchString] == NO) {
        if ([searchString length] > 2 && [searchString characterAtIndex:0] == '"' && [searchString characterAtIndex:[searchString length] - 1] == '"') {
            //strip quotes
            searchString = [searchString substringWithRange:NSMakeRange(1, [searchString length] - 2)];
        } else {
            // strip extra search criteria
            NSRange range = [searchString rangeOfString:@":"];
            if (range.location != NSNotFound) {
                range = [searchString rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
                if (range.location != NSNotFound && range.location > 0)
                    searchString = [searchString substringWithRange:NSMakeRange(0, range.location)];
            }
        }
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
    if ([[self valueForKey:@"changeCount"] integerValue] == 0)
        [self updateChangeCount:NSChangeCleared];
}

- (void)undoableActionDoesntDirtyDocument {
	// This action, while undoable, shouldn't mark the document dirty
	[self performSelector:@selector(undoableActionDoesntDirtyDocumentDeferred:) withObject:[NSNumber numberWithBool:[[self undoManager] isUndoing]] afterDelay:0.0];
}

- (SKInteractionMode)systemInteractionMode {
    // only return the real interaction mode when the fullscreen window is on the primary screen, otherwise no need to block main menu and dock
    if ([[[[self mainWindowController] window] screen] isEqual:[NSScreen primaryScreen]])
        return [[self mainWindowController] interactionMode];
    return SKNormalMode;
}

#pragma mark Writing

- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation {
    NSMutableArray *writableTypes = [[[super writableTypesForSaveOperation:saveOperation] mutableCopy] autorelease];
    if ([[self fileType] isEqualToString:SKPostScriptDocumentType] == NO) {
        [writableTypes removeObject:SKPostScriptDocumentType];
        [writableTypes removeObject:SKBarePostScriptDocumentType];
    }
    if ([[self fileType] isEqualToString:SKDVIDocumentType] == NO) {
        [writableTypes removeObject:SKDVIDocumentType];
        [writableTypes removeObject:SKBareDVIDocumentType];
    }
    if ([[self fileType] isEqualToString:SKXDVDocumentType] == NO) {
        [writableTypes removeObject:SKXDVDocumentType];
        [writableTypes removeObject:SKBareXDVDocumentType];
    }
    if (saveOperation == NSSaveToOperation) {
        [writableTypes addObjectsFromArray:[[NSDocumentController sharedDocumentController] customExportTemplateFilesResetting]];
    }
    return writableTypes;
}

- (NSString *)fileNameExtensionForType:(NSString *)typeName saveOperation:(NSSaveOperationType)saveOperation {
    NSString *fileExtension = nil;
    fileExtension = [super fileNameExtensionForType:typeName saveOperation:saveOperation];
    if (fileExtension == nil && [[[NSDocumentController sharedDocumentController] customExportTemplateFiles] containsObject:typeName])
        fileExtension = [typeName pathExtension];
    return fileExtension;
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
    BOOL success = [super prepareSavePanel:savePanel];
    if (success && exportUsingPanel) {
        NSPopUpButton *formatPopup = [[savePanel accessoryView] subviewOfClass:[NSPopUpButton class]];
        NSString *lastExportedType = [[NSUserDefaults standardUserDefaults] stringForKey:SKLastExportedTypeKey];
        if (formatPopup && lastExportedType) {
            NSInteger idx = [formatPopup indexOfItemWithRepresentedObject:lastExportedType];
            if (idx != -1 && idx != [formatPopup indexOfSelectedItem]) {
                [formatPopup selectItemAtIndex:idx];
                [formatPopup sendAction:[formatPopup action] to:[formatPopup target]];
                [savePanel setAllowedFileTypes:[NSArray arrayWithObjects:[self fileNameExtensionForType:lastExportedType saveOperation:NSSaveToOperation], nil]];
            }
        }
    }
    return success;
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    // Override so we can determine if this is a save, saveAs or export operation, so we can prepare the correct accessory view
    exportUsingPanel = (saveOperation == NSSaveToOperation);
    [super runModalSavePanelForSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

#ifdef __LP64__
#define PERMISSIONS_MODE(catalogInfo) catalogInfo.permissions.mode
#else
#define PERMISSIONS_MODE(catalogInfo) ((FSPermissionInfo *)catalogInfo.permissions)->mode
#endif

- (void)saveNotesToURL:(NSURL *)absoluteURL forSaveOperation:(NSSaveOperationType)saveOperation {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL saveNotesOK = NO;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoSaveSkimNotesKey]) {
        NSString *notesPath = [absoluteURL pathReplacingPathExtension:@"skim"];
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
            if ([[self notes] count] > 0)
                saveNotesOK = [self writeSafelyToURL:[NSURL fileURLWithPath:notesPath] ofType:SKNotesDocumentType forSaveOperation:NSSaveToOperation error:NULL];
            else if (fileExists)
                saveNotesOK = [fm removeItemAtPath:notesPath error:NULL];
        }
    }
    
    FSRef fileRef;
    FSCatalogInfo catalogInfo;
    FSCatalogInfoBitmap whichInfo = kFSCatInfoNone;
    
    if (CFURLGetFSRef((CFURLRef)absoluteURL, &fileRef) &&
        noErr == FSGetCatalogInfo(&fileRef, kFSCatInfoNodeFlags | kFSCatInfoPermissions, &catalogInfo, NULL, NULL, NULL)) {
        
        FSCatalogInfo tmpCatalogInfo = catalogInfo;
        if ((catalogInfo.nodeFlags & kFSNodeLockedMask) != 0) {
            tmpCatalogInfo.nodeFlags &= ~kFSNodeLockedMask;
            whichInfo |= kFSCatInfoNodeFlags;
        }
        if ((PERMISSIONS_MODE(catalogInfo) & S_IWUSR) == 0) {
            PERMISSIONS_MODE(tmpCatalogInfo) |= S_IWUSR;
            whichInfo |= kFSCatInfoPermissions;
        }
        if (whichInfo != kFSCatInfoNone)
            (void)FSSetCatalogInfo(&fileRef, whichInfo, &tmpCatalogInfo);
    }
    
    if (NO == [[NSFileManager defaultManager] writeSkimNotes:[[self notes] valueForKey:@"SkimNoteProperties"] textNotes:[self notesString] richTextNotes:[self notesRTFData] toExtendedAttributesAtURL:absoluteURL error:NULL]) {
        NSString *message = saveNotesOK ? NSLocalizedString(@"The notes could not be saved with the PDF at \"%@\". However a companion .skim file was successfully updated.", @"Informative text in alert dialog") :
                                          NSLocalizedString(@"The notes could not be saved with the PDF at \"%@\"", @"Informative text in alert dialog");
        NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Unable to save notes", @"Message in alert dialog"), nil]
                                         defaultButton:NSLocalizedString(@"OK", @"Button title")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:[NSString stringWithFormat:message, [[absoluteURL path] lastPathComponent]]];
        [alert runModal];
    }
    
    NSDictionary *options = [[self mainWindowController] presentationOptions];
    [[SKNExtendedAttributeManager sharedManager] removeExtendedAttributeNamed:PRESENTATION_OPTIONS_KEY atPath:[absoluteURL path] traverseLink:YES error:NULL];
    if (options)
        [[SKNExtendedAttributeManager sharedManager] setExtendedAttributeNamed:PRESENTATION_OPTIONS_KEY toPropertyListValue:options atPath:[absoluteURL path] options:kSKNXattrDefault error:NULL];
    
    if (whichInfo != kFSCatInfoNone)
        (void)FSSetCatalogInfo(&fileRef, whichInfo, &catalogInfo);
}

- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo {
    NSDictionary *info = [(id)contextInfo autorelease];
    NSSaveOperationType saveOperation = [[info objectForKey:SAVEOPERATION_KEY] unsignedIntegerValue];
    NSString *tmpPath = [info objectForKey:TMPPATH_KEY];
    
    if (didSave) {
        NSURL *absoluteURL = [info objectForKey:URL_KEY];
        NSString *typeName = [info objectForKey:TYPE_KEY];
        
        if ([typeName isEqualToString:SKPDFDocumentType] || [typeName isEqualToString:SKPostScriptDocumentType] || [typeName isEqualToString:SKDVIDocumentType] || [typeName isEqualToString:SKXDVDocumentType]) {
            // we check for notes and may save a .skim as well:
            [self saveNotesToURL:absoluteURL forSaveOperation:saveOperation];
        } else if ([typeName isEqualToString:SKPDFBundleDocumentType] && tmpPath) {
            // move extra package content like version info to the new location
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *path = [absoluteURL path];
            for (NSString *file in [fm contentsOfDirectoryAtPath:tmpPath error:NULL])
                [fm moveItemAtPath:[tmpPath stringByAppendingPathComponent:file] toPath:[path stringByAppendingPathComponent:file] error:NULL];
        }
    
        if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeCleared];
            [fileUpdateChecker didUpdateFromURL:[self fileURL]];
        }
    
        if ([[self class] isNativeType:typeName])
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:SKSkimFileDidSaveNotification object:[absoluteURL path]];
    }
    
    if (tmpPath)
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:NULL];
    
    if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
        [fileUpdateChecker checkFileUpdatesIfNeeded];
        isSaving = NO;
    }
    
    // in case we saved using the panel we should reset this for the next save
    exportUsingPanel = NO;
    
    NSInvocation *invocation = [info objectForKey:CALLBACK_KEY];
    if (invocation) {
        [invocation setArgument:&doc atIndex:2];
        [invocation setArgument:&didSave atIndex:3];
        [invocation invoke];
    }
}

// Don't use -saveToURL:ofType:forSaveOperation:error:, because that may return before the actual saving when NSDoucment needs to ask the user for permission, for instance to override a file lock
- (void)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
        [fileUpdateChecker stopCheckingFileUpdates];
        isSaving = YES;
    } else if (exportUsingPanel) {
        [[NSUserDefaults standardUserDefaults] setObject:typeName forKey:SKLastExportedTypeKey];
    }
    
    NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithObjectsAndKeys:absoluteURL, URL_KEY, typeName, TYPE_KEY, [NSNumber numberWithUnsignedInteger:saveOperation], SAVEOPERATION_KEY, nil];
    if (delegate && didSaveSelector) {
        NSInvocation *invocation = [NSInvocation invocationWithTarget:delegate selector:didSaveSelector];
        [invocation setArgument:&contextInfo atIndex:4];
        [info setObject:invocation forKey:CALLBACK_KEY];
    }
    
    if ([typeName isEqualToString:SKPDFBundleDocumentType] && [[self fileType] isEqualToString:SKPDFBundleDocumentType] && [self fileURL] && saveOperation != NSSaveToOperation) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *path = [[self fileURL] path];
        NSString *tmpPath = nil;
        // we move everything that's not ours out of the way, so we can preserve version control info
        NSSet *ourExtensions = [NSSet setWithObjects:@"pdf", @"skim", @"fdf", @"txt", @"text", @"rtf", @"plist", nil];
        for (NSString *file in [fm contentsOfDirectoryAtPath:path error:NULL]) {
            if ([ourExtensions containsObject:[[file pathExtension] lowercaseString]] == NO) {
                if (tmpPath == nil)
                    tmpPath = SKUniqueTemporaryDirectory();
                [fm copyItemAtPath:[path stringByAppendingPathComponent:file] toPath:[tmpPath stringByAppendingPathComponent:file] error:NULL];
            }
        }
        if (tmpPath)
            [info setObject:tmpPath forKey:TMPPATH_KEY];
    }
    
    [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation delegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:info];
}

- (NSFileWrapper *)PDFBundleFileWrapperForName:(NSString *)name {
    if ([name isCaseInsensitiveEqual:BUNDLE_DATA_FILENAME])
        name = [name stringByAppendingString:@"1"];
    NSData *data;
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:[NSDictionary dictionary]];
    NSDictionary *info = [[SKInfoWindowController sharedInstance] infoForDocument:self];
    NSDictionary *options = [[self mainWindowController] presentationOptions];
    if (options) {
        info = [[info mutableCopy] autorelease];
        [(NSMutableDictionary *)info setObject:options forKey:SKPresentationOptionsKey];
    }
    [fileWrapper addRegularFileWithContents:pdfData preferredFilename:[name stringByAppendingPathExtension:@"pdf"]];
    if (data = [[[self pdfDocument] string] dataUsingEncoding:NSUTF8StringEncoding])
        [fileWrapper addRegularFileWithContents:data preferredFilename:[BUNDLE_DATA_FILENAME stringByAppendingPathExtension:@"txt"]];
    if (data = [NSPropertyListSerialization dataFromPropertyList:info format:NSPropertyListXMLFormat_v1_0 errorDescription:NULL])
        [fileWrapper addRegularFileWithContents:data preferredFilename:[BUNDLE_DATA_FILENAME stringByAppendingPathExtension:@"plist"]];
    if ([[self notes] count] > 0) {
        if (data = [self notesData])
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"skim"]];
        if (data = [[self notesString] dataUsingEncoding:NSUTF8StringEncoding])
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"txt"]];
        if (data = [self notesRTFData])
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"rtf"]];
        if (data = [self notesFDFDataForFile:[name stringByAppendingPathExtension:@"pdf"] fileIDStrings:[self fileIDStrings]])
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"fdf"]];
    }
    return [fileWrapper autorelease];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    BOOL didWrite = NO;
    NSError *error = nil;
    if ([typeName isEqualToString:SKEmbeddedPDFDocumentType]) {
        // this must be checked before PDF, as we check for comformance to the UTI
        [[self mainWindowController] removeTemporaryAnnotations];
        didWrite = [[self pdfDocument] writeToURL:absoluteURL];
    } else if ([typeName isEqualToString:SKPDFDocumentType] || [typeName isEqualToString:SKBarePDFDocumentType]) {
        didWrite = [pdfData writeToURL:absoluteURL options:0 error:&error];
    } else if ([typeName isEqualToString:SKPostScriptDocumentType] || [typeName isEqualToString:SKBarePostScriptDocumentType]) {
        if ([[self fileType] isEqualToString:SKPostScriptDocumentType])
            didWrite = [psOrDviData writeToURL:absoluteURL options:0 error:&error];
    } else if ([typeName isEqualToString:SKDVIDocumentType] || [typeName isEqualToString:SKBareDVIDocumentType]) {
        if ([[self fileType] isEqualToString:SKDVIDocumentType])
            didWrite = [psOrDviData writeToURL:absoluteURL options:0 error:&error];
    } else if ([typeName isEqualToString:SKXDVDocumentType] || [typeName isEqualToString:SKBareXDVDocumentType]) {
        if ([[self fileType] isEqualToString:SKXDVDocumentType])
            didWrite = [psOrDviData writeToURL:absoluteURL options:0 error:&error];
    } else if ([typeName isEqualToString:SKPDFBundleDocumentType]) {
        NSFileWrapper *fileWrapper = [self PDFBundleFileWrapperForName:[[[absoluteURL path] lastPathComponent] stringByDeletingPathExtension]];
        if (fileWrapper)
            didWrite = [fileWrapper writeToFile:[absoluteURL path] atomically:NO updateFilenames:NO];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write file", @"Error description")];
    } else if ([typeName isEqualToString:SKNotesDocumentType]) {
        didWrite = [[NSFileManager defaultManager] writeSkimNotes:[[self notes] valueForKey:@"SkimNoteProperties"] toSkimFileAtURL:absoluteURL error:&error];
    } else if ([typeName isEqualToString:SKNotesRTFDocumentType]) {
        NSData *data = [self notesRTFData];
        if (data)
            didWrite = [data writeToURL:absoluteURL options:0 error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as RTF", @"Error description")];
    } else if ([typeName isEqualToString:SKNotesRTFDDocumentType]) {
        NSFileWrapper *fileWrapper = [self notesRTFDFileWrapper];
        if (fileWrapper)
            didWrite = [fileWrapper writeToFile:[absoluteURL path] atomically:NO updateFilenames:NO];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as RTFD", @"Error description")];
    } else if ([typeName isEqualToString:SKNotesTextDocumentType]) {
        NSString *string = [self notesString];
        if (string)
            didWrite = [string writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as text", @"Error description")];
    } else if ([typeName isEqualToString:SKNotesFDFDocumentType]) {
        NSString *filePath = [[self fileURL] path];
        NSString *filename = [filePath lastPathComponent];
        if (filename && [[self fileType] isEqualToString:SKPDFBundleDocumentType])
            filename = [[NSFileManager defaultManager] bundledFileWithExtension:@"pdf" inPDFBundleAtPath:filePath error:NULL];
        NSData *data = [self notesFDFDataForFile:filename fileIDStrings:[self fileIDStrings]];
        if (data)
            didWrite = [data writeToURL:absoluteURL options:0 error:&error];
        else 
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as FDF", @"Error description")];
    } else if ([[typeName pathExtension] isCaseInsensitiveEqual:@"rtfd"]) {
        NSFileWrapper *fileWrapper = [self notesFileWrapperUsingTemplateFile:typeName];
        if (fileWrapper)
            didWrite = [fileWrapper writeToFile:[absoluteURL path] atomically:NO updateFilenames:NO];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes using template", @"Error description")];
    } else {
        NSData *data = [self notesDataUsingTemplateFile:typeName];
        if (data)
            didWrite = [data writeToURL:absoluteURL options:0 error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes using template", @"Error description")];
    }
    
    if (didWrite == NO && outError != NULL)
        *outError = error ?: [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write file", @"Error description")];
    
    return didWrite;
}

- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError {
    NSMutableDictionary *dict = [[[super fileAttributesToWriteToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:outError] mutableCopy] autorelease];
    
    // only set the creator code for our native types
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldSetCreatorCodeKey] && ([typeName isEqualToString:SKPDFDocumentType] || [typeName isEqualToString:SKPDFBundleDocumentType] || [typeName isEqualToString:SKPostScriptDocumentType] || [typeName isEqualToString:SKDVIDocumentType] || [typeName isEqualToString:SKXDVDocumentType] || [typeName isEqualToString:SKNotesDocumentType]))
        [dict setObject:[NSNumber numberWithUnsignedInt:'SKim'] forKey:NSFileHFSCreatorCode];
    
    if ([[[absoluteURL path] pathExtension] isEqualToString:@"pdf"] || 
        [typeName isEqualToString:SKPDFDocumentType] || [typeName isEqualToString:SKEmbeddedPDFDocumentType] || [typeName isEqualToString:SKBarePDFDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'PDF '] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"pdfd"] || [typeName isEqualToString:SKPDFBundleDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'PDFD'] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"skim"] || [typeName isEqualToString:SKNotesDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'SKNT'] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"fdf"] || [typeName isEqualToString:SKNotesFDFDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'FDF '] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"rtf"] || [typeName isEqualToString:SKNotesRTFDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'RTF '] forKey:NSFileHFSTypeCode];
    else if ([[[absoluteURL path] pathExtension] isEqualToString:@"txt"] || [typeName isEqualToString:SKNotesTextDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'TEXT'] forKey:NSFileHFSTypeCode];
    
    return dict;
}

#pragma mark Reading

- (void)setPDFData:(NSData *)data {
    if (pdfData != data) {
        [pdfData release];
        pdfData = [data retain];
    }
}

- (void)setPDFDataUndoable:(NSData *)data {
    [[[self undoManager] prepareWithInvocationTarget:self] setPDFDataUndoable:pdfData];
    [self setPDFData:data];
}

- (void)setPSOrDVIData:(NSData *)data {
    if (psOrDviData != data) {
        [psOrDviData release];
        psOrDviData = [data retain];
    }
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)docType error:(NSError **)outError {
    PDFDocument *pdfDoc = nil;
    NSError *error = nil;
    
    [tmpData release];
    tmpData = [[SKTemporaryData alloc] init];
    
    if ([docType isEqualToString:SKPostScriptDocumentType]) {
        [self setPSOrDVIData:data];
        data = [SKConversionProgressController PDFDataWithPostScriptData:data error:&error];
    }
    
    if (data)
        pdfDoc = [[SKPDFDocument alloc] initWithData:data];
    
    [tmpData setPdfDocument:pdfDoc];

    if (pdfDoc) {
        [self setPDFData:data];
        [pdfDoc release];
        [self updateChangeCount:NSChangeDone];
        return YES;
    } else {
        if (outError != NULL)
            *outError = error ?: [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")];
        return NO;
    }
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
    
    [tmpData release];
    tmpData = [[SKTemporaryData alloc] init];
    
    if ([docType isEqualToString:SKPDFBundleDocumentType]) {
        NSString *path = [absoluteURL path];
        NSString *pdfFile = [[NSFileManager defaultManager] bundledFileWithExtension:@"pdf" inPDFBundleAtPath:path error:&error];
        if (pdfFile) {
            NSURL *pdfURL = [NSURL fileURLWithPath:pdfFile];
            if ((data = [[NSData alloc] initWithContentsOfURL:pdfURL options:NSUncachedRead error:&error]) &&
                (pdfDoc = [[SKPDFDocument alloc] initWithURL:pdfURL])) {
                NSArray *array = [[NSFileManager defaultManager] readSkimNotesFromPDFBundleAtURL:absoluteURL error:&error];
                if (array == nil) {
                    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to Read Notes", @"Message in alert dialog") 
                                                     defaultButton:NSLocalizedString(@"No", @"Button title")
                                                   alternateButton:NSLocalizedString(@"Yes", @"Button title")
                                                       otherButton:nil
                                         informativeTextWithFormat:NSLocalizedString(@"Skim was not able to read the notes at %@. %@ Do you want to continue to open the PDF document anyway?", @"Informative text in alert dialog"), [path stringByAbbreviatingWithTildeInPath], [error localizedDescription]];
                    if ([alert runModal] == NSAlertDefaultReturn) {
                        [data release];
                        data = nil;
                        [pdfDoc release];
                        pdfDoc = nil;
                        error = [NSError userCancelledErrorWithUnderlyingError:error];
                    }
                } else if ([array count]) {
                    [tmpData setNoteDicts:array];
                }
            }
        }
    } else  {
        if (fileData = [[NSData alloc] initWithContentsOfURL:absoluteURL options:NSUncachedRead error:&error]) {
            if ([docType isEqualToString:SKPDFDocumentType]) {
                if (data = [fileData retain])
                    pdfDoc = [[SKPDFDocument alloc] initWithURL:absoluteURL];
            } else if ([docType isEqualToString:SKPostScriptDocumentType]) {
                if (data = [[SKConversionProgressController PDFDataWithPostScriptData:fileData error:&error] retain])
                    pdfDoc = [[SKPDFDocument alloc] initWithData:data];
            } else if ([docType isEqualToString:SKDVIDocumentType]) {
                if (data = [[SKConversionProgressController PDFDataWithDVIFile:[absoluteURL path] error:&error] retain])
                    pdfDoc = [[SKPDFDocument alloc] initWithData:data];
            } else if ([docType isEqualToString:SKXDVDocumentType]) {
                if (data = [[SKConversionProgressController PDFDataWithXDVFile:[absoluteURL path] error:&error] retain])
                    pdfDoc = [[SKPDFDocument alloc] initWithData:data];
            }
        }
        if (pdfDoc) {
            NSArray *array = [[NSFileManager defaultManager] readSkimNotesFromExtendedAttributesAtURL:absoluteURL error:&error];
            if ([array count]) {
                [tmpData setNoteDicts:array];
            } else {
                // we found no notes, see if we had an error finding notes. if EAs were not supported we ignore the error, as we may assume there won't be any notes
                if (array == nil && isIgnorablePOSIXError(error) == NO) {
                    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to Read Notes", @"Message in alert dialog") 
                                                     defaultButton:NSLocalizedString(@"No", @"Button title")
                                                   alternateButton:NSLocalizedString(@"Yes", @"Button title")
                                                       otherButton:nil
                                         informativeTextWithFormat:NSLocalizedString(@"Skim was not able to read the notes at %@. %@ Do you want to continue to open the PDF document anyway?", @"Informative text in alert dialog"), [[absoluteURL path] stringByAbbreviatingWithTildeInPath], [error localizedDescription]];
                    if ([alert runModal] == NSAlertDefaultReturn) {
                        [fileData release];
                        fileData = nil;
                        [data release];
                        data = nil;
                        [pdfDoc release];
                        pdfDoc = nil;
                        error = [NSError userCancelledErrorWithUnderlyingError:error];
                    }
                }
                if (pdfDoc) {
                    NSString *path = [absoluteURL pathReplacingPathExtension:@"skim"];
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
                                [tmpData setNoteDicts:array];
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
            [tmpData setPdfDocument:pdfDoc];
            if ([docType isEqualToString:SKPostScriptDocumentType] || [docType isEqualToString:SKDVIDocumentType] || [docType isEqualToString:SKXDVDocumentType])
                [self setPSOrDVIData:fileData];
            [pdfDoc release];
            [fileUpdateChecker didUpdateFromURL:absoluteURL];
            
            NSDictionary *dictionary = nil;
            NSArray *array = nil;
            NSNumber *number = nil;
            if ([docType isEqualToString:SKPDFBundleDocumentType]) {
                NSData *infoData = [NSData dataWithContentsOfFile:[[[absoluteURL path] stringByAppendingPathComponent:BUNDLE_DATA_FILENAME] stringByAppendingPathExtension:@"plist"]];
                if (infoData) {
                    NSString *errorString = nil;
                    NSDictionary *info = [NSPropertyListSerialization propertyListFromData:infoData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
                    if (info == nil) {
                        [errorString release];
                    } else if ([info isKindOfClass:[NSDictionary class]]) {
                        dictionary = [info objectForKey:SKPresentationOptionsKey];
                        array = [info objectForKey:SKTagsKey];
                        number = [info objectForKey:SKRatingKey];
                    }
                }
            } else {
                dictionary = [[SKNExtendedAttributeManager sharedNoSplitManager] propertyListFromExtendedAttributeNamed:PRESENTATION_OPTIONS_KEY atPath:[absoluteURL path] traverseLink:YES error:NULL];
                array = [[SKNExtendedAttributeManager sharedNoSplitManager] propertyListFromExtendedAttributeNamed:OPEN_META_TAGS_KEY atPath:[absoluteURL path] traverseLink:YES error:NULL];
                number = [[SKNExtendedAttributeManager sharedNoSplitManager] propertyListFromExtendedAttributeNamed:OPEN_META_RATING_KEY atPath:[absoluteURL path] traverseLink:YES error:NULL];
            }
            if ([dictionary isKindOfClass:[NSDictionary class]] && [dictionary count])
                [tmpData setPresentationOptions:dictionary];
            if ([array isKindOfClass:[NSArray class]] && [array count])
                [tmpData setOpenMetaTags:array];
            if ([number respondsToSelector:@selector(doubleValue)] && [number doubleValue] > 0.0)
                [tmpData setOpenMetaRating:[number doubleValue]];
        }
        [data release];
    }
    [fileData release];
    
    if (didRead == NO && outError != NULL)
        *outError = error ?: [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")];
    
    return didRead;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    BOOL disableAlert = [[NSUserDefaults standardUserDefaults] boolForKey:SKDisableReloadAlertKey] || [[self windowForSheet] attachedSheet];
    
    if (disableAlert == NO) {
        [[[self windowForSheet] attachedSheet] orderOut:self];
        
        [[self progressController] setMessage:[NSLocalizedString(@"Reloading document", @"Message for progress sheet") stringByAppendingEllipsis]];
        [[self progressController] setIndeterminate:YES];
        [[self progressController] beginSheetModalForWindow:[self windowForSheet]];
    }
    
    BOOL success = [super revertToContentsOfURL:absoluteURL ofType:typeName error:outError];
    
    if (success) {
        [[self undoManager] disableUndoRegistration];
        [self setDataFromTmpData];
        [[self undoManager] enableUndoRegistration];
        [[self undoManager] removeAllActions];
        [fileUpdateChecker checkFileUpdatesIfNeeded];
    }
    
    [tmpData release];
    tmpData = nil;
    
    if (disableAlert == NO)
        [[self progressController] dismissSheet:nil];
    
    return success;
}

#pragma mark Printing

static inline void invokePrintCallback(NSInvocation *callback, BOOL didPrint) {
    [callback setArgument:&didPrint atIndex:3];
    [callback performSelector:@selector(invoke) withObject:nil afterDelay:0.0];
}

- (void)handleWindowDidEndPrintSheetNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidEndSheetNotification object:[notification object]];
    invokePrintCallback(printCallback, YES);
    SKDESTROY(printCallback);
}

- (void)printDocumentWithSettings:(NSDictionary *)printSettings showPrintPanel:(BOOL)showPrintPanel delegate:(id)delegate didPrintSelector:(SEL)didPrintSelector contextInfo:(void *)contextInfo {
    NSWindow *printWindow = [[self pdfView] window];
    NSInvocation *callback = nil;
    if (delegate && didPrintSelector) {
        callback = [NSInvocation invocationWithTarget:delegate selector:didPrintSelector argument:&self];
        [callback setArgument:&contextInfo atIndex:4];
    }
    if ([[self pdfDocument] allowsPrinting] && (showPrintPanel == NO || [printWindow attachedSheet] == nil)) {
        NSPrintInfo *printInfo = [[[self printInfo] copy] autorelease];
        NSMutableDictionary *infoDict = [printInfo dictionary];
        
        [infoDict addEntriesFromDictionary:printSettings];
        if (showPrintPanel == NO)
            [infoDict setObject:[NSNumber numberWithBool:YES] forKey:SKSuppressPrintPanel];
        
        [[self pdfView] printWithInfo:printInfo autoRotate:YES pageScaling:kPDFPrintPageScaleNone];
        
        if (callback) {
            if (showPrintPanel && [printWindow attachedSheet]) {
                printCallback = [callback retain];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowDidEndPrintSheetNotification:) name:NSWindowDidEndSheetNotification object:printWindow];
            } else {
                invokePrintCallback(callback, YES);
            }
        }
    } else if (callback) {
        invokePrintCallback(callback, NO);
    }
}

#pragma mark Actions

- (void)readNotesFromURL:(NSURL *)notesURL replace:(BOOL)replace {
    NSString *extension = [[notesURL path] pathExtension];
    NSArray *array = nil;
    
    if ([extension isCaseInsensitiveEqual:@"skim"]) {
        array = [NSKeyedUnarchiver unarchiveObjectWithFile:[notesURL path]];
    } else {
        NSData *fdfData = [NSData dataWithContentsOfURL:notesURL];
        if (fdfData)
            array = [SKFDFParser noteDictionariesFromFDFData:fdfData];
    }
    
    if (array) {
        [[self mainWindowController] addAnnotationsFromDictionaries:array replace:replace];
        [[self undoManager] setActionName:replace ? NSLocalizedString(@"Replace Notes", @"Undo action name") : NSLocalizedString(@"Add Notes", @"Undo action name")];
    } else
        NSBeep();
}

- (void)readNotesPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSFileHandlingPanelOKButton) {
        NSURL *notesURL = [[oPanel URLs] objectAtIndex:0];
        BOOL replace = ([[oPanel accessoryView] isEqual:readNotesAccessoryView] && [replaceNotesCheckButton state] == NSOnState);
        [self readNotesFromURL:notesURL replace:replace];
    }
}

- (IBAction)readNotes:(id)sender{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    NSString *path = [[self fileURL] path];
    
    if ([[[self mainWindowController] notes] count]) {
        if (readNotesAccessoryView == nil) {
            replaceNotesCheckButton = [[[NSButton alloc] init] autorelease];
            [replaceNotesCheckButton setButtonType:NSSwitchButton];
            [replaceNotesCheckButton setTitle:NSLocalizedString(@"Replace existing notes", @"Check button title")];
            [replaceNotesCheckButton sizeToFit];
            [replaceNotesCheckButton setFrameOrigin:NSMakePoint(16.0, 8.0)];
            readNotesAccessoryView = [[NSView alloc] initWithFrame:NSInsetRect([replaceNotesCheckButton frame], -16.0, -8.0)];
            [readNotesAccessoryView addSubview:replaceNotesCheckButton];
        }
        [oPanel setAccessoryView:readNotesAccessoryView];
        [replaceNotesCheckButton setState:NSOnState];
    }
    
    [oPanel beginSheetForDirectory:[path stringByDeletingLastPathComponent]
                              file:[path lastPathComponentReplacingPathExtension:@"skim"]
                             types:[NSArray arrayWithObjects:@"skim", NSAppKitVersionNumber > NSAppKitVersionNumber10_5 ? nil : @"fdf", nil]
                    modalForWindow:[self windowForSheet]
                     modalDelegate:self
                    didEndSelector:@selector(readNotesPanelDidEnd:returnCode:contextInfo:)
                       contextInfo:NULL];		
}

- (void)convertNotesUsingPDFDocument:(PDFDocument *)pdfDocWithoutNotes {
    [[self progressController] setMessage:[NSLocalizedString(@"Converting notes", @"Message for progress sheet") stringByAppendingEllipsis]];
    [[self progressController] setIndeterminate:YES];
    [[self progressController] beginSheetModalForWindow:[self windowForSheet]];
    
    PDFDocument *pdfDoc = [self pdfDocument];
    NSInteger i, count = [pdfDoc pageCount];
    BOOL didConvert = NO;
    
    for (i = 0; i < count; i++) {
        PDFPage *page = [pdfDoc pageAtIndex:i];
        
        for (PDFAnnotation *annotation in [[[page annotations] copy] autorelease]) {
            if ([annotation isSkimNote] == NO && [annotation isConvertibleAnnotation]) {
                NSDictionary *properties = [annotation SkimNoteProperties];
                if ([[annotation type] isEqualToString:SKNTextString])
                    properties = [SKNPDFAnnotationNote textToNoteSkimNoteProperties:properties];
                PDFAnnotation *newAnnotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:properties];
                if (newAnnotation) {
                    [[self pdfView] removeAnnotation:annotation];
                    [[self pdfView] addAnnotation:newAnnotation toPage:page];
                    if ([[newAnnotation contents] length] == 0) {
                        NSString *text = nil;
                        if ([newAnnotation isMarkup]) {
                            text = [[(PDFAnnotationMarkup *)newAnnotation selection] cleanedString];
                        } else if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableUpdateContentsFromEnclosedTextKey] == NO &&
                                   ([[newAnnotation type] isEqualToString:SKNCircleString] || [[newAnnotation type] isEqualToString:SKNSquareString])) {
                            text = [[page selectionForRect:[newAnnotation bounds]] cleanedString];
                        }
                        if ([text length])
                            [newAnnotation setContents:text];
                    }
                    [newAnnotation release];
                    didConvert = YES;
                }
            }
        }
    }
    
    if (didConvert) {
        // if pdfDocWithoutNotes was nil, the document was not encrypted, so no need to try to unlock
        if (pdfDocWithoutNotes == nil)
            pdfDocWithoutNotes = [[PDFDocument alloc] initWithData:pdfData];
        count = [pdfDocWithoutNotes pageCount];
        for (i = 0; i < count; i++) {
            PDFPage *page = [pdfDocWithoutNotes pageAtIndex:i];
            
            for (PDFAnnotation *annotation in [[[page annotations] copy] autorelease]) {
                if ([annotation isSkimNote] == NO && [annotation isConvertibleAnnotation])
                    [page removeAnnotation:annotation];
            }
        }
        
        [self setPDFDataUndoable:[pdfDocWithoutNotes dataRepresentation]];
        
        [[self undoManager] setActionName:NSLocalizedString(@"Convert Notes", @"Undo action name")];
    }
    
    [[self progressController] dismissSheet:nil];
}

- (void)convertNotesPasswordSheetDidEnd:(SKPasswordSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    PDFDocument *pdfDocWithoutNotes = (PDFDocument *)contextInfo;
    
    if (returnCode == NSCancelButton) {
        [pdfDocWithoutNotes release];
    } else {
        [[controller window] orderOut:nil];
        
        if (pdfDocWithoutNotes && [pdfDocWithoutNotes isLocked] && [pdfDocWithoutNotes unlockWithPassword:[controller stringValue]] == NO) {
            SKPasswordSheetController *passwordSheetController = [[[SKPasswordSheetController alloc] init] autorelease];
            [passwordSheetController beginSheetModalForWindow:[[self mainWindowController] window] modalDelegate:self didEndSelector:_cmd contextInfo:pdfDocWithoutNotes];
        } else {
            [self convertNotesUsingPDFDocument:[pdfDocWithoutNotes autorelease]];
        }
    }
}

- (void)convertNotesSheetDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertAlternateReturn)
        return;
    
    PDFDocument *pdfDocWithoutNotes = nil;
    
    if ([[self pdfDocument] isEncrypted]) {
        pdfDocWithoutNotes = [[PDFDocument alloc] initWithData:pdfData];
        if ([self tryToUnlockDocument:pdfDocWithoutNotes] == NO) {
            [[alert window] orderOut:nil];
            
            SKPasswordSheetController *passwordSheetController = [[[SKPasswordSheetController alloc] init] autorelease];
            
            [passwordSheetController beginSheetModalForWindow:[[self mainWindowController] window]
                modalDelegate:self 
               didEndSelector:@selector(convertNotesPasswordSheetDidEnd:returnCode:contextInfo:)
                  contextInfo:pdfDocWithoutNotes];
            
            return;
        }
    }
    [self convertNotesUsingPDFDocument:[pdfDocWithoutNotes autorelease]];
}

- (IBAction)convertNotes:(id)sender {
    if ([[self fileType] isEqualToString:SKPDFDocumentType] == NO && [[self fileType] isEqualToString:SKPDFBundleDocumentType] == NO) {
        NSBeep();
        return;
    }
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Convert Notes", @"Alert text when trying to convert notes")
                                     defaultButton:NSLocalizedString(@"OK", @"Button title")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"This will convert PDF annotations to Skim notes. Do you want to proceed?", @"Informative text in alert dialog")];
    [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(convertNotesSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (BOOL)saveArchiveToFile:(NSString *)fileName {
    return [NSTask runTaskWithLaunchPath:@"/usr/bin/tar"
                               arguments:[NSArray arrayWithObjects:@"-czf", fileName, [[[self fileURL] path] lastPathComponent], nil]
                    currentDirectoryPath:[[[self fileURL] path] stringByDeletingLastPathComponent]];
}

- (void)archiveSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode  contextInfo:(void  *)contextInfo {
    if (NSFileHandlingPanelOKButton == returnCode && [self fileURL])
        [self saveArchiveToFile:[sheet filename]];
}

- (IBAction)saveArchive:(id)sender {
    NSString *path = [[self fileURL] path];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path] && [self isDocumentEdited] == NO) {
        NSSavePanel *sp = [NSSavePanel savePanel];
        [sp setRequiredFileType:@"tgz"];
        [sp setCanCreateDirectories:YES];
        [sp beginSheetForDirectory:nil
                              file:[path lastPathComponentReplacingPathExtension:@"tgz"]
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
    NSString *scriptFormat = nil;
    NSString *mailAppID = [(NSString *)LSCopyDefaultHandlerForURLScheme(CFSTR("mailto")) autorelease];
    
    if ([@"com.microsoft.entourage" isCaseInsensitiveEqual:mailAppID]) {
        scriptFormat = @"tell application \"Microsoft Entourage\"\n"
                       @"activate\n"
                       @"set m to make new draft window with properties {subject:\"%@\", visible:true}\n"
                       @"tell m\n"
                       @"make new attachment with properties {file:POSIX file \"%@\"}\n"
                       @"end tell\n"
                       @"end tell\n";
    } else if ([@"com.barebones.mailsmith" isCaseInsensitiveEqual:mailAppID]) {
        scriptFormat = @"tell application \"Mailsmith\"\n"
                       @"activate\n"
                       @"set m to make new message window with properties {subject:\"%@\", visible:true}\n"
                       @"tell m\n"
                       @"make new enclosure with properties {file:POSIX file \"%@\"}\n"
                       @"end tell\n"
                       @"end tell\n";
    } else if ([@"com.mailplaneapp.Mailplane" isCaseInsensitiveEqual:mailAppID]) {
        scriptFormat = @"tell application \"Mailplane\"\n"
                       @"activate\n"
                       @"set m to make new outgoing message with properties {subject:\"%@\", visible:true}\n"
                       @"tell m\n"
                       @"make new mail attachment with properties {path:\"%@\"}\n"
                       @"end tell\n"
                       @"end tell\n";
    } else if ([@"com.postbox-inc.postboxexpress" isCaseInsensitiveEqual:mailAppID]) {
        scriptFormat = @"tell application \"PostboxExpress\"\n"
                       @"activate\n"
                       @"send message subject \"%@\" attachment \"%@\"\n"
                       @"end tell\n";
    } else if ([@"com.postbox-inc.postbox" isCaseInsensitiveEqual:mailAppID]) {
        scriptFormat = @"tell application \"Postbox\"\n"
                       @"activate\n"
                       @"send message subject \"%@\" attachment \"%@\"\n"
                       @"end tell\n";
    } else {
        scriptFormat = @"tell application \"Mail\"\n"
                       @"activate\n"
                       @"set m to make new outgoing message with properties {subject:\"%@\", visible:true}\n"
                       @"tell content of m\n"
                       @"make new attachment at after last character with properties {file name:\"%@\"}\n"
                       @"end tell\n"
                       @"end tell\n";
    }
    
    
    NSString *scriptString = [NSString stringWithFormat:scriptFormat, [self displayName], fileName];
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

- (IBAction)emailArchive:(id)sender {
    NSString *path = [[self fileURL] path];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path] && [self isDocumentEdited] == NO) {
        NSString *tmpDir = SKUniqueChewableItemsDirectory();
        NSString *tmpFile = [tmpDir stringByAppendingPathComponent:[[[self fileURL] path] lastPathComponentReplacingPathExtension:@"tgz"]];
        if ([self saveArchiveToFile:tmpFile] == NO || [self emailAttachmentFile:tmpFile] == NO)
            NSBeep();
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"You must save this file first", @"Alert text when trying to create archive for unsaved document") defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The document has unsaved changes, or has not previously been saved to disk.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (void)saveDiskImageWithInfo:(NSDictionary *)info {
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSString *sourcePath = [[[info objectForKey:SOURCEPATH_KEY] copy] autorelease];
    NSString *targetPath = [[[info objectForKey:TARGETPATH_KEY] copy] autorelease];
    NSArray *arguments = [NSArray arrayWithObjects:@"create", @"-srcfolder", sourcePath, @"-format", @"UDZO", @"-volname", [[targetPath lastPathComponent] stringByDeletingPathExtension], targetPath, nil];
    
    if ([NSTask runTaskWithLaunchPath:@"/usr/bin/hdiutil" arguments:arguments currentDirectoryPath:[sourcePath stringByDeletingLastPathComponent]] == NO)
        NSBeep();
    
    [[self progressController] performSelectorOnMainThread:@selector(hide) withObject:nil waitUntilDone:NO];
    
    if ([[info objectForKey:EMAIL_KEY] boolValue])
        [self performSelectorOnMainThread:@selector(emailAttachmentFile:) withObject:targetPath waitUntilDone:NO];
    
    [pool release];
}

- (void)saveDiskImageToFile:(NSString *)fileName email:(BOOL)email {
    [[self progressController] setMessage:[NSLocalizedString(@"Saving Disk Image", @"Message for progress sheet") stringByAppendingEllipsis]];
    [[self progressController] setIndeterminate:YES];
    [[self progressController] show];
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[[self fileURL] path], SOURCEPATH_KEY, fileName, TARGETPATH_KEY, [NSNumber numberWithBool:email], EMAIL_KEY, nil];
    [NSThread detachNewThreadSelector:@selector(saveDiskImageWithInfo:) toTarget:self withObject:info];
}

- (void)diskImageSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode  contextInfo:(void  *)contextInfo {
    if (NSFileHandlingPanelOKButton == returnCode && [self fileURL])
        [self saveDiskImageToFile:[sheet filename] email:NO];
}

- (IBAction)saveDiskImage:(id)sender {
    NSString *path = [[self fileURL] path];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path] && [self isDocumentEdited] == NO) {
        NSSavePanel *sp = [NSSavePanel savePanel];
        [sp setRequiredFileType:@"dmg"];
        [sp setCanCreateDirectories:YES];
        [sp beginSheetForDirectory:nil
                              file:[path lastPathComponentReplacingPathExtension:@"dmg"]
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
        NSString *tmpFile = [tmpDir stringByAppendingPathComponent:[[[self fileURL] path] lastPathComponentReplacingPathExtension:@"dmg"]];
        [self saveDiskImageToFile:tmpFile email:YES];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"You must save this file first", @"Alert text when trying to create archive for unsaved document") defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The document has unsaved changes, or has not previously been saved to disk.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (void)revertAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSError *error = nil;
        if (NO == [self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:&error] && [error isUserCancelledError] == NO) {
            [[alert window] orderOut:nil];
            [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
        }
    }
}

- (void)revertDocumentToSaved:(id)sender { 	 
     if ([self fileURL]) { 	 
         if ([self isDocumentEdited]) { 	 
             [super revertDocumentToSaved:sender]; 	 
         } else if ([fileUpdateChecker fileChangedOnDisk]) { 	 
             NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Do you want to revert to the version of the document \"%@\" on disk?", @"Message in alert dialog"), [[[self fileURL] path] lastPathComponent]] 	 
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
        NSString *fileName = [[self fileURL] path];
        if (fileName == nil || [[NSFileManager defaultManager] fileExistsAtPath:fileName] == NO)
            return NO;
        return [self isDocumentEdited] || [fileUpdateChecker fileChangedOnDisk];
    } else if ([anItem action] == @selector(printDocument:)) {
        return [[self pdfDocument] allowsPrinting];
    } else if ([anItem action] == @selector(convertNotes:)) {
        return [[self fileType] isEqualToString:SKPDFDocumentType] && [[self pdfDocument] isLocked] == NO;
    } else if ([anItem action] == @selector(saveArchive:) || [anItem action] == @selector(saveDiskImage:) || [anItem action] == @selector(emailArchive:) || [anItem action] == @selector(emailDiskImage:)) {
        NSString *path = [[self fileURL] path];
        return path && [[NSFileManager defaultManager] fileExistsAtPath:path] && [self isDocumentEdited] == NO;
    }
    return [super validateUserInterfaceItem:anItem];
}

- (void)remoteButtonPressed:(NSEvent *)theEvent {
    [[self mainWindowController] remoteButtonPressed:theEvent];
}

#pragma mark Notification handlers

- (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    NSWindow *window = [notification object];
    // ignore when we're switching fullscreen/main windows
    if ([window isEqual:[[window windowController] window]]) {
        [fileUpdateChecker stopCheckingFileUpdates];
        SKDESTROY(fileUpdateChecker);
        [self saveRecentDocumentInfo];
    }
}

#pragma mark Pdfsync support

- (void)setFileURL:(NSURL *)absoluteURL {
    // this shouldn't be necessary, but better be sure
    if ([self fileURL] && [[self fileURL] isEqual:absoluteURL] == NO)
        [fileUpdateChecker stopCheckingFileUpdates];
    
    [super setFileURL:absoluteURL];
    
    // if we're saving this will be called when saving has finished
    if (isSaving == NO && [mainWindowController isWindowLoaded])
        [fileUpdateChecker checkFileUpdatesIfNeeded];
    
    if ([absoluteURL isFileURL])
        [synchronizer setFileName:[absoluteURL path]];
    else
        [synchronizer setFileName:nil];
}

- (SKPDFSynchronizer *)synchronizer {
    if (synchronizer == nil) {
        synchronizer = [[SKPDFSynchronizer alloc] init];
        [synchronizer setDelegate:self];
        [synchronizer setFileName:[[self fileURL] path]];
    }
    return synchronizer;
}

- (void)synchronizer:(SKPDFSynchronizer *)synchronizer foundLine:(NSInteger)line inFile:(NSString *)file {
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        
        NSString *editorPreset = [[NSUserDefaults standardUserDefaults] objectForKey:SKTeXEditorPresetKey];
        NSString *editorCmd = nil;
        NSString *editorArgs = nil;
        NSMutableString *cmdString = nil;
        SKTeXEditor editor = [SKSyncPreferences TeXEditorForPreset:editorPreset];
        
        if (editor.name) {
            editorCmd = editor.command;
            editorArgs = editor.arguments;
        } else {
            editorCmd = [[NSUserDefaults standardUserDefaults] objectForKey:SKTeXEditorCommandKey];
            editorArgs = [[NSUserDefaults standardUserDefaults] objectForKey:SKTeXEditorArgumentsKey];
        }
        cmdString = [[editorArgs mutableCopy] autorelease];
        
        if ([editorCmd isAbsolutePath] == NO) {
            NSMutableArray *searchPaths = [NSMutableArray arrayWithObjects:@"/usr/bin", @"/usr/local/bin", nil];
            NSString *path;
            NSString *toolPath;
            NSBundle *appBundle;
            NSFileManager *fm = [NSFileManager defaultManager];
            
            if ([editorPreset isEqualToString:@""] == NO) {
                if ((path = [[NSWorkspace sharedWorkspace] fullPathForApplication:editorPreset]) &&
                    (appBundle = [NSBundle bundleWithPath:path])) {
                    if ([editorPreset isEqualToString:@"BBEdit"] == NO)
                        [searchPaths insertObject:[[appBundle executablePath] stringByDeletingLastPathComponent] atIndex:0];
                    [searchPaths insertObject:[appBundle resourcePath] atIndex:0];
                    [searchPaths insertObject:[appBundle sharedSupportPath] atIndex:0];
                }
            } else {
                [searchPaths addObjectsFromArray:[[NSFileManager defaultManager] applicationSupportDirectories]];
            }
            
            for (path in searchPaths) {
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
        
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        NSString *theUTI = [ws typeOfFile:[[editorCmd stringByStandardizingPath] stringByResolvingSymlinksInPath] error:NULL];
        if ([ws type:theUTI conformsToType:@"com.apple.applescript.script"] || [ws type:theUTI conformsToType:@"com.apple.applescript.text"])
            [cmdString insertString:@"/usr/bin/osascript " atIndex:0];
        
        [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmdString, nil] currentDirectoryPath:[file stringByDeletingLastPathComponent]];
    }
}

- (void)synchronizer:(SKPDFSynchronizer *)synchronizer foundLocation:(NSPoint)point atPageIndex:(NSUInteger)pageIndex options:(NSInteger)options {
    PDFDocument *pdfDoc = [self pdfDocument];
    if (pageIndex < [pdfDoc pageCount]) {
        PDFPage *page = [pdfDoc pageAtIndex:pageIndex];
        if (options & SKPDFSynchronizerFlippedMask)
            point.y = NSMaxY([page boundsForBox:kPDFDisplayBoxMediaBox]) - point.y;
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldHighlightSearchResultsKey])
            [[self mainWindowController] addTemporaryAnnotationForPoint:point onPage:page];
        [[self pdfView] displayLineAtPoint:point inPageAtIndex:pageIndex showReadingBar:(options & SKPDFSynchronizerShowReadingBarMask) != 0];
    }
}


#pragma mark Accessors

- (PDFDocument *)pdfDocument{
    return [[self mainWindowController] pdfDocument];
}

- (NSDictionary *)currentDocumentSetup {
    NSMutableDictionary *setup = [[[super currentDocumentSetup] mutableCopy] autorelease];
    if ([setup count])
        [setup addEntriesFromDictionary:[[self mainWindowController] currentSetup]];
    return setup;
}

- (void)applySetup:(NSDictionary *)setup {
    [[self mainWindowController] applySetup:setup];
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

inline NSRange SKRangeBetweenRanges(NSRange startRange, NSRange endRange) {
    NSRange r;
    r.location = NSMaxRange(startRange);
    r.length = endRange.location - r.location;
    return r;
}

inline NSRange SKMakeRangeFromEnd(NSUInteger end, NSUInteger length) {
    NSRange r;
    if (end > length) {
        r.location = end - length;
        r.length = length;
    } else {
        r.location = 0;
        r.length = end;
    }
    return r;
}

- (NSArray *)fileIDStrings {
    if (pdfData == nil)
        return nil;
    
    NSData *firstIDData = nil;
    NSData *secondIDData = nil;
    NSRange EOFRange = [pdfData rangeOfData:[NSData dataWithBytes:"%%EOF" length:5] options:NSDataSearchBackwards range:SKMakeRangeFromEnd([pdfData length], 1024UL)];
    
    if (EOFRange.location != NSNotFound) {
        NSRange trailerRange = [pdfData rangeOfData:[NSData dataWithBytes:"trailer" length:7] options:NSDataSearchBackwards range:SKMakeRangeFromEnd(EOFRange.location, 2048UL)];
        if (trailerRange.location != NSNotFound) {
            NSRange IDRange = [pdfData rangeOfData:[NSData dataWithBytes:"/ID" length:3] options:0 range:SKRangeBetweenRanges(trailerRange, EOFRange)];
            if (IDRange.location != NSNotFound) {
                NSRange startArrayRange = [pdfData rangeOfData:[NSData dataWithBytes:"[" length:1] options:0 range:SKRangeBetweenRanges(IDRange, EOFRange)];
                if (startArrayRange.location != NSNotFound) {
                    NSRange endArrayRange = [pdfData rangeOfData:[NSData dataWithBytes:"]" length:1] options:0 range:SKRangeBetweenRanges(startArrayRange, EOFRange)];
                    if (endArrayRange.location != NSNotFound) {
                        NSData *startStringPattern = [NSData dataWithBytes:"<" length:1];
                        NSData *endStringPattern = [NSData dataWithBytes:">" length:1];
                        NSRange startStringRange = [pdfData rangeOfData:startStringPattern options:0 range:SKRangeBetweenRanges(startArrayRange, endArrayRange)];
                        if (startStringRange.location != NSNotFound) {
                            NSRange endStringRange = [pdfData rangeOfData:endStringPattern options:0 range:SKRangeBetweenRanges(startStringRange, endArrayRange)];
                            if (endStringRange.location != NSNotFound) {
                                if (firstIDData = [pdfData subdataWithRange:SKRangeBetweenRanges(startStringRange, endStringRange)]) {
                                    startStringRange = [pdfData rangeOfData:startStringPattern options:0 range:SKRangeBetweenRanges(endStringRange, endArrayRange)];
                                    if (startStringRange.location != NSNotFound) {
                                        endStringRange = [pdfData rangeOfData:endStringPattern options:0 range:SKRangeBetweenRanges(startStringRange, endArrayRange)];
                                        if (endStringRange.location != NSNotFound) {
                                            secondIDData = [pdfData subdataWithRange:SKRangeBetweenRanges(startStringRange, endStringRange)];
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

- (NSPrintInfo *)printInfo {
    NSPrintInfo *printInfo = [super printInfo];
    if ([[self pdfDocument] pageCount]) {
        PDFPage *page = [[self pdfDocument] pageAtIndex:0];
        NSSize pageSize = [page boundsForBox:kPDFDisplayBoxMediaBox].size;
        BOOL isLandscape = [page rotation] % 180 == 90 ? pageSize.height > pageSize.width : pageSize.width > pageSize.height;
        [printInfo setOrientation:isLandscape ? NSLandscapeOrientation : NSPortraitOrientation];
    }
    return printInfo;
}

- (NSArray *)snapshots {
    return [[self mainWindowController] snapshots];
}

- (NSArray *)tags {
    return [[self mainWindowController] tags] ?: [NSArray array];
}

- (double)rating {
    return [[self mainWindowController] rating];
}

#pragma mark Passwords

enum {
    SKPDFPasswordStatusFound,
    SKPDFPasswordStatusFoundOldFormat,
    SKPDFPasswordStatusNotFound,
    SKPDFPasswordStatusError,
};

- (NSInteger)getPDFPassword:(NSString **)password item:(SecKeychainItemRef *)itemRef forFileID:(NSString *)fileID {
    void *passwordData = NULL;
    UInt32 passwordLength = 0;
    const char *service = [SKPDFPasswordServiceName UTF8String];
    const char *account = [fileID UTF8String];
    NSInteger status = 0;
    
    OSStatus err = SecKeychainFindGenericPassword(NULL, strlen(service), service, strlen(account), account, password ? &passwordLength : 0, password ? &passwordData : NULL, itemRef);
    
    if (err == errSecItemNotFound) {
        // try to find an item in the old format
        service = [[@"Skim - " stringByAppendingString:fileID] UTF8String];
        account = [NSUserName() UTF8String];
        
        err = SecKeychainFindGenericPassword(NULL, strlen(service), service, strlen(account), account, password ? &passwordLength : 0, password ? &passwordData : NULL, itemRef);
        
        status = (err == noErr ? SKPDFPasswordStatusFoundOldFormat : err == errSecItemNotFound ? SKPDFPasswordStatusNotFound : SKPDFPasswordStatusError);
    } else {
        status = (err == noErr ? SKPDFPasswordStatusFound : SKPDFPasswordStatusError);
    }
    
    if (err == noErr && password) {
        *password = [[[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding] autorelease];
        SecKeychainItemFreeContent(NULL, passwordData);
    }
    
    if (err != noErr && err != errSecItemNotFound)
        NSLog(@"Error %d occurred finding password: %@", err, [(id)SecCopyErrorMessageString(err, NULL) autorelease]);
    
    return status;
}

static inline SecKeychainAttribute makeKeychainAttribute(SecKeychainAttrType tag, NSString *string) {
    const char *data = [string UTF8String];
    SecKeychainAttribute attr;
    attr.tag = tag;
    attr.length = strlen(data);
    attr.data = (void *)data;
    return attr;
}

- (void)setPDFPassword:(NSString *)password item:(SecKeychainItemRef)itemRef forFileID:(NSString *)fileID {
    const void *passwordData = [password UTF8String];
    UInt32 passwordLength = password ? strlen(passwordData) : 0;
    NSString *comment = [[self fileURL] path];
    NSUInteger attrCount = comment ? 4 : 3;
    SecKeychainAttributeList attributes;
    SecKeychainAttribute attrs[attrCount];
    OSStatus err;
    
    attrs[0] = makeKeychainAttribute(kSecServiceItemAttr, SKPDFPasswordServiceName);
    attrs[1] = makeKeychainAttribute(kSecAccountItemAttr, fileID);
    attrs[2] = makeKeychainAttribute(kSecLabelItemAttr, [@"Skim: " stringByAppendingString:[self displayName]]);
    if (comment)
        attrs[3] = makeKeychainAttribute(kSecCommentItemAttr, comment);
    
    attributes.count = attrCount;
    attributes.attr = attrs;
    
    if (itemRef) {
        // password was on keychain, so modify the keychain
        err = SecKeychainItemModifyAttributesAndData(itemRef, &attributes, passwordLength, passwordData);
        if (err != noErr)
            NSLog(@"Error %d occurred modifying password: %@", err, [(id)SecCopyErrorMessageString(err, NULL) autorelease]);
    } else {
        // password not on keychain, so add it
        err = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &attributes, passwordLength, passwordData, NULL, NULL, NULL);
        if (err != noErr)
            NSLog(@"Error %d occurred adding password: %@", err, [(id)SecCopyErrorMessageString(err, NULL) autorelease]);
    }
}

- (void)doSavePasswordInKeychain:(NSString *)password {
    NSString *fileID = [[self fileIDStrings] lastObject] ?: [pdfData md5String];
    if (fileID) {
        // first see if the password exists in the keychain
        SecKeychainItemRef itemRef = NULL;
        NSInteger status = [self getPDFPassword:nil item:&itemRef forFileID:fileID];
        
        if (status != SKPDFPasswordStatusError)
            [self setPDFPassword:password item:itemRef forFileID:fileID];
    }
}

- (void)passwordAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSString *password = [(NSString *)contextInfo autorelease];
    if (returnCode == NSAlertDefaultReturn)
        [self doSavePasswordInKeychain:password];   
}

- (void)savePasswordInKeychain:(NSString *)password {
    if ([[self pdfDocument] isLocked])
        return;
    
    NSInteger saveOption = [[NSUserDefaults standardUserDefaults] integerForKey:SKSavePasswordOptionKey];
    if (saveOption == NSAlertDefaultReturn) {
        [self doSavePasswordInKeychain:password];
    } else if (saveOption == NSAlertOtherReturn) {
        NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Remember Password?", @"Message in alert dialog"), nil]
                                         defaultButton:NSLocalizedString(@"Yes", @"Button title")
                                       alternateButton:NSLocalizedString(@"No", @"Button title")
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"Do you want to save this password in your Keychain?", @"Informative text in alert dialog")];
        NSWindow *window = [[self mainWindowController] window];
        if ([window attachedSheet] == nil)
            [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(passwordAlertDidEnd:returnCode:contextInfo:) contextInfo:[password retain]];
        else if (NSAlertDefaultReturn == [alert runModal])
            [self doSavePasswordInKeychain:password];
    }
}

- (BOOL)tryToUnlockDocument:(PDFDocument *)document {
    BOOL didUnlock = NO;
    if ([document isLocked] == NO) {
        didUnlock = YES;
    } else if (NSAlertAlternateReturn != [[NSUserDefaults standardUserDefaults] integerForKey:SKSavePasswordOptionKey]) {
        NSString *fileID = [[self fileIDStrings] lastObject] ?: [pdfData md5String];
        if (fileID) {
            NSString *password = nil;
            SecKeychainItemRef itemRef = NULL;
            NSInteger status = [self getPDFPassword:&password item:&itemRef forFileID:fileID];
            
            if (password) {
                didUnlock = [document unlockWithPassword:password];
                if (status == SKPDFPasswordStatusFoundOldFormat && didUnlock)
                    [self setPDFPassword:nil item:itemRef forFileID:fileID];
            }
        }
    }
    return didUnlock;
}

#pragma mark Scripting support

- (NSArray *)notes {
    return [[self mainWindowController] notes];
}

- (void)insertObject:(PDFAnnotation *)newNote inNotesAtIndex:(NSUInteger)anIndex {
    PDFPage *page = [newNote page];
    if (page && [[page annotations] containsObject:newNote] == NO) {
        SKPDFView *pdfView = [self pdfView];
        
        [pdfView addAnnotation:newNote toPage:page];
        [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];
    } else {
        [[NSScriptCommand currentCommand] setScriptErrorNumber:NSReceiversCantHandleCommandScriptError]; 
    }
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
    return note;
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
    return [sel hasCharacters] ? [sel objectSpecifier] : [NSArray array];
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
    return [[self pdfView] currentSelectionPage];
}

- (void)setSelectionPage:(PDFPage *)page {
    [[self pdfView] setCurrentSelectionPage:[page isKindOfClass:[PDFPage class]] ? page : nil];
}

- (NSDictionary *)pdfViewSettings {
    return [[self mainWindowController] currentPDFSettings];
}

- (void)setPdfViewSettings:(NSDictionary *)pdfViewSettings {
    [[self mainWindowController] applyPDFSettings:pdfViewSettings];
}

- (BOOL)isPDFDocument {
    return YES;
}

- (id)newScriptingObjectOfClass:(Class)class forValueForKey:(NSString *)key withContentsValue:(id)contentsValue properties:(NSDictionary *)properties {
    if ([key isEqualToString:@"notes"]) {
        PDFAnnotation *annotation = nil;
        PDFSelection *selection = [PDFSelection selectionWithSpecifier:[properties objectForKey:SKPDFAnnotationSelectionSpecifierKey]];
        PDFPage *page = [selection safeFirstPage];
        if (page == nil) {
            [[NSScriptCommand currentCommand] setScriptErrorNumber:NSReceiversCantHandleCommandScriptError]; 
        } else {
            annotation = [page newScriptingObjectOfClass:class forValueForKey:key withContentsValue:contentsValue properties:properties];
            if ([annotation respondsToSelector:@selector(setPage:)])
                [annotation performSelector:@selector(setPage:) withObject:page];
        }
        return annotation;
    }
    return [super newScriptingObjectOfClass:class forValueForKey:key withContentsValue:contentsValue properties:properties];
}

- (id)handleSaveScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id fileType = [args objectForKey:@"FileType"];
    // we don't want to expose the pboard types to the user, and we allow template file names without extension
    if (fileType) {
        NSString *normalizedType = nil;
        if ([fileType isEqualToString:@"PDF"])
            normalizedType = SKPDFDocumentType;
        else if ([fileType isEqualToString:@"PostScript"])
            normalizedType = SKPostScriptDocumentType;
        else if ([fileType isEqualToString:@"DVI"])
            normalizedType = SKDVIDocumentType;
        else if ([fileType isEqualToString:@"XDV"])
            normalizedType = SKXDVDocumentType;
        else if ([[self writableTypesForSaveOperation:NSSaveToOperation] containsObject:fileType] == NO) {
            NSArray *templateTypes = [[NSDocumentController sharedDocumentController] customExportTemplateFiles];
            NSArray *templateTypesWithoutExtension = [templateTypes valueForKey:@"stringByDeletingPathExtension"];
            NSUInteger idx = [templateTypesWithoutExtension indexOfObject:fileType];
            if (idx != NSNotFound)
                normalizedType = [templateTypes objectAtIndex:idx];
        }
        if (normalizedType) {
            fileType = normalizedType;
            NSMutableDictionary *arguments = [[command arguments] mutableCopy];
            [arguments setObject:fileType forKey:@"FileType"];
            [command setArguments:arguments];
            [arguments release];
        }
    }
    return [super handleSaveScriptCommand:command];
}

- (void)handleRevertScriptCommand:(NSScriptCommand *)command {
    if ([self fileURL] && [[NSFileManager defaultManager] fileExistsAtPath:[[self fileURL] path]]) {
        if ([fileUpdateChecker isUpdatingFile] == NO && [self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:NULL] == NO) {
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
        BOOL showBar = [[args objectForKey:@"ShowReadingBar"] boolValue];
        NSInteger options = showBar ? SKPDFSynchronizerShowReadingBarMask : 0;
        if ([source isKindOfClass:[NSString class]])
            source = [NSURL fileURLWithPath:source];
        if ([source isKindOfClass:[NSURL class]] == NO)
            source = [self fileURL];
        [[self synchronizer] findPageAndLocationForLine:[location index] inFile:[source pathReplacingPathExtension:@"tex"] options:options];
    } else {
        PDFSelection *selection = [PDFSelection selectionWithSpecifier:[[command arguments] objectForKey:@"To"]];
        if ([selection hasCharacters]) {
            PDFPage *page = [selection safeFirstPage];
            NSRect bounds = [selection boundsForPage:page];
            [[self pdfView] goToRect:bounds onPage:page];
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
        id from = [[command arguments] objectForKey:@"From"];
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
        NSRect rect = [sel hasCharacters] ? [sel boundsForPage:page] : NSMakeRect(point.x - 20.0, point.y - 5.0, 40.0, 10.0);
        
        [[self synchronizer] findFileAndLineForLocation:point inRect:rect pageBounds:[page boundsForBox:kPDFDisplayBoxMediaBox] atPageIndex:pageIndex];
    }
}

- (void)handleConvertNotesScriptCommand:(NSScriptCommand *)command {
    if ([[self fileType] isEqualToString:SKPDFDocumentType] || [[self fileType] isEqualToString:SKPDFBundleDocumentType])
        [self convertNotesSheetDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:NULL];
    else
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
}

- (void)handleReadNotesScriptCommand:(NSScriptCommand *)command {
    NSDictionary *args = [command evaluatedArguments];
    NSURL *notesURL = [args objectForKey:@"File"];
    if (notesURL == nil) {
        [command setScriptErrorNumber:NSRequiredArgumentsMissingScriptError];
    } else {
        NSNumber *replaceNumber = [args objectForKey:@"Replace"];
        NSString *fileType = [[NSDocumentController sharedDocumentController] typeForContentsOfURL:notesURL error:NULL];
        if ([fileType isEqualToString:SKNotesDocumentType] || [fileType isEqualToString:SKNotesFDFDocumentType])
            [self readNotesFromURL:notesURL replace:(replaceNumber ? [replaceNumber boolValue] : YES)];
        else
            [command setScriptErrorNumber:NSArgumentsWrongScriptError];
    }
}

@end


@implementation NSWindow (SKScriptingExtensions)

- (void)handleRevertScriptCommand:(NSScriptCommand *)command {
    id document = [[self windowController] document];
    if (document == nil) {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"Window does not have a document."];
    } else
        [document handleRevertScriptCommand:command];
}

@end


@implementation SKTemporaryData

@synthesize pdfDocument, noteDicts, presentationOptions, openMetaTags, openMetaRating;

- (id)init {
    if (self = [super init]) {
        pdfDocument = nil;
        noteDicts = nil;
        presentationOptions = nil;
        openMetaTags = nil;
        openMetaRating = 0.0;
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(pdfDocument);
    SKDESTROY(noteDicts);
    SKDESTROY(presentationOptions);
    SKDESTROY(openMetaTags);
    [super dealloc];
}

@end
