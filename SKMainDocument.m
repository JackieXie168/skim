//
//  SKMainDocument.m
//  Skim
//
//  Created by Michael McCracken on 12/5/06.
/*
 This software is Copyright (c) 2006-2014
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
#import "SKMainWindowController_Actions.h"
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
#import "PDFDocument_SKExtensions.h"
#import "SKPrintAccessoryController.h"
#import "SKTemporaryData.h"
#import "SKTemplateManager.h"
#import "SKExportAccessoryController.h"
#import "SKAttachmentEmailer.h"

#define BUNDLE_DATA_FILENAME @"data"
#define PRESENTATION_OPTIONS_KEY @"net_sourceforge_skim-app_presentation_options"
#define OPEN_META_TAGS_KEY @"com.apple.metadata:kMDItemOMUserTags"
#define OPEN_META_RATING_KEY @"com.apple.metadata:kMDItemStarRating"

NSString *SKSkimFileDidSaveNotification = @"SKSkimFileDidSaveNotification";

#define SKLastExportedTypeKey @"SKLastExportedType"
#define SKLastExportedOptionKey @"SKLastExportedOption"

#define URL_KEY             @"URL"
#define TYPE_KEY            @"type"
#define SAVEOPERATION_KEY   @"saveOperation"
#define CALLBACK_KEY        @"callback"
#define TMPURL_KEY          @"tmpURL"
#define SKIMNOTES_KEY       @"skimNotes"
#define SKIMTEXTNOTES_KEY   @"skimTextNotes"
#define SKIMRTFNOTES_KEY    @"skimRTFNotes"

#define SOURCEURL_KEY   @"sourceURL"
#define TARGETURL_KEY   @"targetURL"
#define EMAIL_KEY       @"email"

#define SKPresentationOptionsKey    @"PresentationOptions"
#define SKTagsKey                   @"Tags"
#define SKRatingKey                 @"Rating"

static NSString *SKPDFPasswordServiceName = @"Skim PDF password";

enum {
    SKExportOptionDefault,
    SKExportOptionWithoutNotes,
    SKExportOptionWithEmbeddedNotes,
};

enum {
   SKArchiveDiskImageMask = 1,
   SKArchiveEmailMask = 2,
};


@interface PDFAnnotation (SKPrivateDeclarations)
- (void)setPage:(PDFPage *)newPage;
@end


@interface PDFDocument (SKPrivateDeclarations)
- (NSPrintOperation *)getPrintOperationForPrintInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)autoRotate;
@end

@interface PDFDocument (SKLionDeclarations)
- (NSPrintOperation *)printOperationForPrintInfo:(NSPrintInfo *)printInfo scalingMode:(PDFPrintScalingMode)scalingMode autoRotate:(BOOL)autoRotate;
@end


@interface NSDocument (SKPrivateDeclarations)
// private method used as the action for the file format popup in the save panel, decalred so we can override
- (void)changeSaveType:(id)sender;
@end


@interface SKMainDocument (SKPrivate)

- (BOOL)tryToUnlockDocument:(PDFDocument *)document;

- (void)handleWindowWillCloseNotification:(NSNotification *)notification;

@end

#pragma mark -

@implementation SKMainDocument

@synthesize mainWindowController;
@dynamic pdfDocument, pdfView, synchronizer, snapshots, tags, rating, currentPage, activeNote, richText, selectionSpecifier, selectionQDRect,selectionPage, pdfViewSettings;

+ (BOOL)isPDFDocument { return YES; }

- (id)init {
    self = [super init];
    if (self) {
        fileUpdateChecker = [[SKFileUpdateChecker alloc] initForDocument:self];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // shouldn't need this here, but better be safe
    [fileUpdateChecker stopCheckingFileUpdates];
    [fileUpdateChecker setDocument:nil];
    SKDESTROY(fileUpdateChecker);
    SKDESTROY(mainWindowController);
    [synchronizer terminate];
    [synchronizer setDelegate:nil];
    SKDESTROY(synchronizer);
    SKDESTROY(pdfData);
    SKDESTROY(originalData);
    SKDESTROY(tmpData);
    SKDESTROY(pageOffsets);
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
    SKDESTROY(tmpData);
    
    [[self undoManager] enableUndoRegistration];
    
    if ([self fileURL])
        [fileUpdateChecker checkFileUpdatesIfNeeded];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowWillCloseNotification:) 
                                                 name:NSWindowWillCloseNotification object:[[self mainWindowController] window]];
}

- (void)showWindows{
    BOOL wasVisible = [[self mainWindowController] isWindowLoaded] && [[[self mainWindowController] window] isVisible];
    
    [super showWindows];
    
    // Get the search string keyword if available (Spotlight passes this)
    NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    NSString *searchString;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableSearchAfterSpotlighKey] == NO &&
        [event eventID] == kAEOpenDocuments && 
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
    
    if (wasVisible == NO) {
        // currently PDFView on 10.9 initially doesn't display the PDF, messing around like this is a workaround for this bug
        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8) {
            [[self mainWindowController] toggleStatusBar:nil];
            [[self mainWindowController] toggleStatusBar:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentDidShowNotification object:self];
    }
}

- (void)removeWindowController:(NSWindowController *)windowController {
    if ([windowController isEqual:mainWindowController]) {
        // we need to do this on Tiger, because windowWillClose notifications are posted after this
        [self saveRecentDocumentInfo];
        SKDESTROY(mainWindowController);
    }
    [super removeWindowController:windowController];
}

- (void)saveRecentDocumentInfo {
    NSURL *fileURL = [self fileURL];
    NSUInteger pageIndex = [[[self pdfView] currentPage] pageIndex];
    if (fileURL && pageIndex != NSNotFound && [self mainWindowController])
        [[SKBookmarkController sharedBookmarkController] addRecentDocumentForURL:fileURL pageIndex:pageIndex snapshots:[[[self mainWindowController] snapshots] valueForKey:SKSnapshotCurrentSetupKey]];
}

#pragma mark Writing

- (NSString *)fileType {
    gettingFileType = YES;
    NSString *fileType = [super fileType];
    gettingFileType = NO;
    return fileType;
}

- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation {
    if (gettingFileType)
        return [super writableTypesForSaveOperation:saveOperation];
    NSMutableArray *writableTypes = [[[super writableTypesForSaveOperation:saveOperation] mutableCopy] autorelease];
    NSString *type = [self fileType];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    if ([ws type:type conformsToType:SKEncapsulatedPostScriptDocumentType] == NO)
        [writableTypes removeObject:SKEncapsulatedPostScriptDocumentType];
    else
        [writableTypes removeObject:SKPostScriptDocumentType];
    if ([ws type:type conformsToType:SKPostScriptDocumentType] == NO)
        [writableTypes removeObject:SKPostScriptDocumentType];
    if ([ws type:type conformsToType:SKDVIDocumentType] == NO)
        [writableTypes removeObject:SKDVIDocumentType];
    if ([ws type:type conformsToType:SKXDVDocumentType] == NO)
        [writableTypes removeObject:SKXDVDocumentType];
    if (saveOperation == NSSaveToOperation) {
        [[SKTemplateManager sharedManager] resetCustomTemplateTypes];
        [writableTypes addObjectsFromArray:[[SKTemplateManager sharedManager] customTemplateTypes]];
    }
    return writableTypes;
}

- (NSString *)fileNameExtensionForType:(NSString *)typeName saveOperation:(NSSaveOperationType)saveOperation {
    return [super fileNameExtensionForType:typeName saveOperation:saveOperation] ?: [[SKTemplateManager sharedManager] fileNameExtensionForTemplateType:typeName];
}

- (BOOL)canAttachNotesForType:(NSString *)typeName {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    return ([ws type:typeName conformsToType:SKPDFDocumentType] || 
            [ws type:typeName conformsToType:SKPostScriptDocumentType] || 
            [ws type:typeName conformsToType:SKDVIDocumentType] || 
            [ws type:typeName conformsToType:SKXDVDocumentType]);
}

- (void)updateExportAccessoryView {
    NSString *typeName = [self fileTypeFromLastRunSavePanel];
    NSMatrix *matrix = [exportAccessoryController matrix];
    [matrix selectCellWithTag:exportOption];
    if ([self canAttachNotesForType:typeName]) {
        [matrix setHidden:NO];
        if ([[NSWorkspace sharedWorkspace] type:typeName conformsToType:SKPDFDocumentType] && [[self pdfDocument] allowsPrinting]) {
            [[matrix cellWithTag:SKExportOptionWithEmbeddedNotes] setEnabled:YES];
        } else {
            [[matrix cellWithTag:SKExportOptionWithEmbeddedNotes] setEnabled:NO];
            if (exportOption == SKExportOptionWithEmbeddedNotes) {
                exportOption = SKExportOptionDefault;
                [matrix selectCellWithTag:SKExportOptionDefault];
            }
        }
    } else {
        [matrix setHidden:YES];
    }
}

- (void)changeSaveType:(id)sender {
    if ([NSDocument instancesRespondToSelector:_cmd])
        [super changeSaveType:sender];
    if (exportUsingPanel && exportAccessoryController)
        [self updateExportAccessoryView];
}

- (void)changeExportOption:(id)sender {
    exportOption = [[sender selectedCell] tag];
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
    BOOL success = [super prepareSavePanel:savePanel];
    if (success && exportUsingPanel) {
        NSPopUpButton *formatPopup = [[savePanel accessoryView] subviewOfClass:[NSPopUpButton class]];
        if (formatPopup) {
            NSString *lastExportedType = [[NSUserDefaults standardUserDefaults] stringForKey:SKLastExportedTypeKey];
            NSInteger lastExportedOption = [[NSUserDefaults standardUserDefaults] integerForKey:SKLastExportedOptionKey];
            if (lastExportedType) {
                NSInteger idx = [formatPopup indexOfItemWithRepresentedObject:lastExportedType];
                if (idx != -1 && idx != [formatPopup indexOfSelectedItem]) {
                    [formatPopup selectItemAtIndex:idx];
                    [formatPopup sendAction:[formatPopup action] to:[formatPopup target]];
                    [savePanel setAllowedFileTypes:[NSArray arrayWithObjects:[self fileNameExtensionForType:lastExportedType saveOperation:NSSaveToOperation], nil]];
                }
            }
            exportOption = lastExportedOption;
            
            exportAccessoryController = [[SKExportAccessoryController alloc] init];
            [exportAccessoryController addFormatPopUpButton:formatPopup];
            [[exportAccessoryController matrix] setTarget:self];
            [[exportAccessoryController matrix] setAction:@selector(changeExportOption:)];
            [savePanel setAccessoryView:[exportAccessoryController view]];
            [self updateExportAccessoryView];
        }
    }
    return success;
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    // Override so we can determine if this is a save, saveAs or export operation, so we can prepare the correct accessory view
    exportUsingPanel = (saveOperation == NSSaveToOperation);
    // Should already be reset long ago, just to be sure
    exportOption = SKExportOptionDefault;
    [super runModalSavePanelForSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (NSArray *)SkimNoteProperties {
    NSArray *array = [[self notes] valueForKey:@"SkimNoteProperties"];
    if (pageOffsets != nil) {
        NSMutableArray *mutableArray = [NSMutableArray array];
        for (NSDictionary *dict in array) {
            NSUInteger pageIndex = [[dict objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntegerValue];
            NSPointPointer offsetPtr = NSMapGet(pageOffsets, (const void *)pageIndex);
            if (offsetPtr != NULL) {
                NSMutableDictionary *mutableDict = [dict mutableCopy];
                NSRect bounds = NSRectFromString([dict objectForKey:SKNPDFAnnotationBoundsKey]);
                bounds.origin.x -= offsetPtr->x;
                bounds.origin.y -= offsetPtr->y;
                [mutableDict setObject:NSStringFromRect(bounds) forKey:SKNPDFAnnotationBoundsKey];
                [mutableArray addObject:mutableDict];
                [mutableDict release];
            } else {
                [mutableArray addObject:dict];
            }
        }
        array = mutableArray;
    }
    return  array;
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
        NSURL *notesURL = [absoluteURL URLReplacingPathExtension:@"skim"];
        BOOL fileExists = [notesURL checkResourceIsReachableAndReturnError:NULL];
        
        if (fileExists && (saveOperation == NSSaveAsOperation || saveOperation == NSSaveToOperation)) {
            NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" already exists. Do you want to replace it?", @"Message in alert dialog"), [notesURL lastPathComponent]]
                                             defaultButton:NSLocalizedString(@"Save", @"Button title")
                                           alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"A file or folder with the same name already exists in %@. Replacing it will overwrite its current contents.", @"Informative text in alert dialog"), [[notesURL URLByDeletingLastPathComponent] lastPathComponent]];
            
            saveNotesOK = NSAlertDefaultReturn == [alert runModal];
        } else {
            saveNotesOK = YES;
        }
        
        if (saveNotesOK) {
            if ([[self notes] count] > 0)
                saveNotesOK = [self writeSafelyToURL:notesURL ofType:SKNotesDocumentType forSaveOperation:NSSaveToOperation error:NULL];
            else if (fileExists)
                saveNotesOK = [fm removeItemAtURL:notesURL error:NULL];
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
    
    if (NO == [fm writeSkimNotes:[self SkimNoteProperties] textNotes:[self notesString] richTextNotes:[self notesRTFData] toExtendedAttributesAtURL:absoluteURL error:NULL]) {
        NSString *message = saveNotesOK ? NSLocalizedString(@"The notes could not be saved with the PDF at \"%@\". However a companion .skim file was successfully updated.", @"Informative text in alert dialog") :
                                          NSLocalizedString(@"The notes could not be saved with the PDF at \"%@\"", @"Informative text in alert dialog");
        NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Unable to save notes", @"Message in alert dialog"), nil]
                                         defaultButton:NSLocalizedString(@"OK", @"Button title")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:message, [absoluteURL lastPathComponent]];
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
    NSURL *tmpURL = [info objectForKey:TMPURL_KEY];
    
    if (didSave) {
        NSURL *absoluteURL = [info objectForKey:URL_KEY];
        NSString *typeName = [info objectForKey:TYPE_KEY];
        
        if ([self canAttachNotesForType:typeName] && exportOption == SKExportOptionDefault) {
            // we check for notes and may save a .skim as well:
            [self saveNotesToURL:absoluteURL forSaveOperation:saveOperation];
        } else if ([[NSWorkspace sharedWorkspace] type:typeName conformsToType:SKPDFBundleDocumentType] && tmpURL) {
            // move extra package content like version info to the new location
            NSFileManager *fm = [NSFileManager defaultManager];
            for (NSURL *url in [fm contentsOfDirectoryAtURL:tmpURL includingPropertiesForKeys:nil options:0 error:NULL])
                [fm moveItemAtURL:url toURL:[absoluteURL URLByAppendingPathComponent:[url lastPathComponent]] error:NULL];
        }
    
        if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeCleared];
            [fileUpdateChecker didUpdateFromURL:[self fileURL]];
        }
    
        if ([[self class] isNativeType:typeName])
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:SKSkimFileDidSaveNotification object:[absoluteURL path]];
    } else if (saveOperation == NSSaveOperation) {
        NSArray *skimNotes = [info objectForKey:SKIMNOTES_KEY];
        NSString *textNotes = [info objectForKey:SKIMTEXTNOTES_KEY];
        NSData *rtfNotes = [info objectForKey:SKIMRTFNOTES_KEY];
        if (skimNotes)
            [[NSFileManager defaultManager] writeSkimNotes:skimNotes textNotes:textNotes richTextNotes:rtfNotes toExtendedAttributesAtURL:[self fileURL] error:NULL];
    }
    
    if (tmpURL)
        [[NSFileManager defaultManager] removeItemAtURL:tmpURL error:NULL];
    
    if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
        [fileUpdateChecker checkFileUpdatesIfNeeded];
        isSaving = NO;
    }
    
    // in case we saved using the panel we should reset this for the next save
    exportUsingPanel = NO;
    exportOption = SKExportOptionDefault;
    
    SKDESTROY(exportAccessoryController);
    
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
    } else if (saveOperation == NSSaveToOperation && exportUsingPanel) {
        [[NSUserDefaults standardUserDefaults] setObject:typeName forKey:SKLastExportedTypeKey];
        [[NSUserDefaults standardUserDefaults] setInteger:[self canAttachNotesForType:typeName] ? exportOption : SKExportOptionDefault forKey:SKLastExportedOptionKey];
    }
    // just to make sure
    if (saveOperation != NSSaveToOperation)
        exportOption = SKExportOptionDefault;
    
    NSURL *destURL = [absoluteURL filePathURL];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithObjectsAndKeys:destURL, URL_KEY, typeName, TYPE_KEY, [NSNumber numberWithUnsignedInteger:saveOperation], SAVEOPERATION_KEY, nil];
    if (delegate && didSaveSelector) {
        NSInvocation *invocation = [NSInvocation invocationWithTarget:delegate selector:didSaveSelector];
        [invocation setArgument:&contextInfo atIndex:4];
        [info setObject:invocation forKey:CALLBACK_KEY];
    }
    
    if ([ws type:typeName conformsToType:SKPDFBundleDocumentType] && [ws type:[self fileType] conformsToType:SKPDFBundleDocumentType] && [self fileURL] && saveOperation != NSSaveToOperation) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *fileURL = [self fileURL];
        NSURL *tmpURL = nil;
        // we move everything that's not ours out of the way, so we can preserve version control info
        NSSet *ourExtensions = [NSSet setWithObjects:@"pdf", @"skim", @"fdf", @"txt", @"text", @"rtf", @"plist", nil];
        for (NSURL *url in [fm contentsOfDirectoryAtURL:fileURL includingPropertiesForKeys:nil options:0 error:NULL]) {
            if ([ourExtensions containsObject:[[url pathExtension] lowercaseString]] == NO) {
                if (tmpURL == nil)
                    tmpURL = [fm URLForDirectory:NSItemReplacementDirectory inDomain:NSUserDomainMask appropriateForURL:fileURL create:YES error:NULL];
                [fm copyItemAtURL:url toURL:[tmpURL URLByAppendingPathComponent:[url lastPathComponent]] error:NULL];
            }
        }
        if (tmpURL)
            [info setObject:tmpURL forKey:TMPURL_KEY];
    }
    
    // There seems to be a bug on 10.9 when saving to an existing file that has a lot of extended attributes
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8 && [self canAttachNotesForType:typeName] && [self fileURL] && saveOperation == NSSaveOperation) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *fileURL = [self fileURL];
        NSArray *skimNotes = [fm readSkimNotesFromExtendedAttributesAtURL:fileURL error:NULL];
        NSString *textNotes = [fm readSkimTextNotesFromExtendedAttributesAtURL:fileURL error:NULL];
        NSData *rtfNotes = [fm readSkimRTFNotesFromExtendedAttributesAtURL:fileURL error:NULL];
        [fm writeSkimNotes:nil textNotes:nil richTextNotes:nil toExtendedAttributesAtURL:fileURL error:NULL];
        if (skimNotes)
            [info setObject:skimNotes forKey:SKIMNOTES_KEY];
        if (textNotes)
            [info setObject:textNotes forKey:SKIMTEXTNOTES_KEY];
        if (rtfNotes)
            [info setObject:rtfNotes forKey:SKIMRTFNOTES_KEY];
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
    if ((data = [[[self pdfDocument] string] dataUsingEncoding:NSUTF8StringEncoding]))
        [fileWrapper addRegularFileWithContents:data preferredFilename:[BUNDLE_DATA_FILENAME stringByAppendingPathExtension:@"txt"]];
    if ((data = [NSPropertyListSerialization dataWithPropertyList:info format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL]))
        [fileWrapper addRegularFileWithContents:data preferredFilename:[BUNDLE_DATA_FILENAME stringByAppendingPathExtension:@"plist"]];
    if ([[self notes] count] > 0) {
        if ((data = [self notesData]))
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"skim"]];
        if ((data = [[self notesString] dataUsingEncoding:NSUTF8StringEncoding]))
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"txt"]];
        if ((data = [self notesRTFData]))
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"rtf"]];
        if ((data = [self notesFDFDataForFile:[name stringByAppendingPathExtension:@"pdf"] fileIDStrings:[[self pdfDocument] fileIDStrings:pdfData]]))
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"fdf"]];
    }
    return [fileWrapper autorelease];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    BOOL didWrite = NO;
    NSError *error = nil;
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    if ([ws type:SKPDFDocumentType conformsToType:typeName]) {
        if (exportOption == SKExportOptionWithEmbeddedNotes)
            didWrite = [[self pdfDocument] writeToURL:absoluteURL];
        else
            didWrite = [pdfData writeToURL:absoluteURL options:0 error:&error];
    } else if ([ws type:SKEncapsulatedPostScriptDocumentType conformsToType:typeName] || 
               [ws type:SKDVIDocumentType conformsToType:typeName] || 
               [ws type:SKXDVDocumentType conformsToType:typeName]) {
        if ([ws type:[self fileType] conformsToType:typeName])
            didWrite = [originalData writeToURL:absoluteURL options:0 error:&error];
    } else if ([ws type:SKPDFBundleDocumentType conformsToType:typeName]) {
        NSFileWrapper *fileWrapper = [self PDFBundleFileWrapperForName:[[absoluteURL lastPathComponent] stringByDeletingPathExtension]];
        if (fileWrapper)
            didWrite = [fileWrapper writeToURL:absoluteURL options:0 originalContentsURL:nil error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write file", @"Error description")];
    } else if ([ws type:SKNotesDocumentType conformsToType:typeName]) {
        didWrite = [[NSFileManager defaultManager] writeSkimNotes:[self SkimNoteProperties] toSkimFileAtURL:absoluteURL error:&error];
    } else if ([ws type:SKNotesRTFDocumentType conformsToType:typeName]) {
        NSData *data = [self notesRTFData];
        if (data)
            didWrite = [data writeToURL:absoluteURL options:0 error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as RTF", @"Error description")];
    } else if ([ws type:SKNotesRTFDDocumentType conformsToType:typeName]) {
        NSFileWrapper *fileWrapper = [self notesRTFDFileWrapper];
        if (fileWrapper)
            didWrite = [fileWrapper writeToURL:absoluteURL options:0 originalContentsURL:nil error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as RTFD", @"Error description")];
    } else if ([ws type:SKNotesTextDocumentType conformsToType:typeName]) {
        NSString *string = [self notesString];
        if (string)
            didWrite = [string writeToURL:absoluteURL atomically:NO encoding:NSUTF8StringEncoding error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as text", @"Error description")];
    } else if ([ws type:SKNotesFDFDocumentType conformsToType:typeName]) {
        NSURL *fileURL = [self fileURL];
        if (fileURL && [ws type:[self fileType] conformsToType:SKPDFBundleDocumentType])
            fileURL = [[NSFileManager defaultManager] bundledFileURLWithExtension:@"pdf" inPDFBundleAtURL:fileURL error:NULL];
        NSData *data = [self notesFDFDataForFile:[fileURL lastPathComponent] fileIDStrings:[[self pdfDocument] fileIDStrings:pdfData]];
        if (data)
            didWrite = [data writeToURL:absoluteURL options:0 error:&error];
        else 
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as FDF", @"Error description")];
    } else if ([[SKTemplateManager sharedManager] isRichTextBundleTemplateType:typeName]) {
        NSFileWrapper *fileWrapper = [self notesFileWrapperForTemplateType:typeName];
        if (fileWrapper)
            didWrite = [fileWrapper writeToURL:absoluteURL options:0 originalContentsURL:nil error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes using template", @"Error description")];
    } else {
        NSData *data = [self notesDataForTemplateType:typeName];
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
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    // only set the creator code for our native types
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldSetCreatorCodeKey] && 
        ([[self class] isNativeType:typeName] || [typeName isEqualToString:SKNotesDocumentType]))
        [dict setObject:[NSNumber numberWithUnsignedInt:'SKim'] forKey:NSFileHFSCreatorCode];
    
    if ([ws type:typeName conformsToType:SKPDFDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'PDF '] forKey:NSFileHFSTypeCode];
    else if ([ws type:typeName conformsToType:SKPDFBundleDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'PDFD'] forKey:NSFileHFSTypeCode];
    else if ([ws type:typeName conformsToType:SKNotesDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'SKNT'] forKey:NSFileHFSTypeCode];
    else if ([ws type:typeName conformsToType:SKNotesFDFDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'FDF '] forKey:NSFileHFSTypeCode];
    else if ([[absoluteURL pathExtension] isEqualToString:@"rtf"] || [ws type:typeName conformsToType:SKNotesRTFDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'RTF '] forKey:NSFileHFSTypeCode];
    else if ([[absoluteURL pathExtension] isEqualToString:@"txt"] || [ws type:typeName conformsToType:SKNotesTextDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'TEXT'] forKey:NSFileHFSTypeCode];
    
    return dict;
}

#pragma mark Reading

- (void)setPDFData:(NSData *)data {
    if (pdfData != data) {
        [pdfData release];
        pdfData = [data retain];
    }
    SKDESTROY(pageOffsets);
}

- (void)setOriginalData:(NSData *)data {
    if (originalData != data) {
        [originalData release];
        originalData = [data retain];
    }
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)docType error:(NSError **)outError {
    NSData *inData = data;
    PDFDocument *pdfDoc = nil;
    NSError *error = nil;
    
    [tmpData release];
    tmpData = [[SKTemporaryData alloc] init];
    
    if ([[NSWorkspace sharedWorkspace] type:docType conformsToType:SKPostScriptDocumentType])
        data = [[SKConversionProgressController newPDFDataWithPostScriptData:data error:&error] autorelease];
    
    if (data)
        pdfDoc = [[SKPDFDocument alloc] initWithData:data];
    
    if (pdfDoc) {
        [self setPDFData:data];
        [tmpData setPdfDocument:pdfDoc];
        [self setOriginalData:inData];
        [pdfDoc release];
        [self updateChangeCount:NSChangeDone];
        return YES;
    } else {
        SKDESTROY(tmpData);
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
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    [tmpData release];
    tmpData = [[SKTemporaryData alloc] init];
    
    if ([ws type:docType conformsToType:SKPDFBundleDocumentType]) {
        NSURL *pdfURL = [[NSFileManager defaultManager] bundledFileURLWithExtension:@"pdf" inPDFBundleAtURL:absoluteURL error:&error];
        if (pdfURL) {
            if ((data = [[NSData alloc] initWithContentsOfURL:pdfURL options:NSDataReadingUncached error:&error]) &&
                (pdfDoc = [[SKPDFDocument alloc] initWithURL:pdfURL])) {
                NSArray *array = [[NSFileManager defaultManager] readSkimNotesFromPDFBundleAtURL:absoluteURL error:&error];
                if (array == nil) {
                    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to Read Notes", @"Message in alert dialog") 
                                                     defaultButton:NSLocalizedString(@"No", @"Button title")
                                                   alternateButton:NSLocalizedString(@"Yes", @"Button title")
                                                       otherButton:nil
                                         informativeTextWithFormat:NSLocalizedString(@"Skim was not able to read the notes at %@. %@ Do you want to continue to open the PDF document anyway?", @"Informative text in alert dialog"), [[pdfURL path] stringByAbbreviatingWithTildeInPath], [error localizedDescription]];
                    if ([alert runModal] == NSAlertDefaultReturn) {
                        SKDESTROY(data);
                        SKDESTROY(pdfDoc);
                        error = [NSError userCancelledErrorWithUnderlyingError:error];
                    }
                } else if ([array count]) {
                    [tmpData setNoteDicts:array];
                }
            }
        }
    } else  {
        if ((fileData = [[NSData alloc] initWithContentsOfURL:absoluteURL options:NSDataReadingUncached error:&error])) {
            if ([ws type:docType conformsToType:SKPDFDocumentType]) {
                data = [fileData retain];
                pdfDoc = [[SKPDFDocument alloc] initWithURL:absoluteURL];
            } else {
                if ([ws type:docType conformsToType:SKPostScriptDocumentType])
                    data = [SKConversionProgressController newPDFDataWithPostScriptData:fileData error:&error];
                else if ([ws type:docType conformsToType:SKDVIDocumentType])
                    data = [SKConversionProgressController newPDFDataWithDVIAtURL:absoluteURL error:&error];
                else if ([ws type:docType conformsToType:SKXDVDocumentType])
                    data = [SKConversionProgressController newPDFDataWithXDVAtURL:absoluteURL error:&error];
                if (data)
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
                        SKDESTROY(fileData);
                        SKDESTROY(data);
                        SKDESTROY(pdfDoc);
                        error = [NSError userCancelledErrorWithUnderlyingError:error];
                    }
                }
                if (pdfDoc) {
                    NSURL *url = [absoluteURL URLReplacingPathExtension:@"skim"];
                    if ([url checkResourceIsReachableAndReturnError:NULL]) {
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
                            array = [[NSFileManager defaultManager] readSkimNotesFromSkimFileAtURL:url error:NULL];
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
            [self setOriginalData:fileData];
            [pdfDoc release];
            [fileUpdateChecker didUpdateFromURL:absoluteURL];
            
            NSDictionary *dictionary = nil;
            NSArray *array = nil;
            NSNumber *number = nil;
            if ([docType isEqualToString:SKPDFBundleDocumentType]) {
                NSData *infoData = [NSData dataWithContentsOfURL:[[absoluteURL URLByAppendingPathComponent:BUNDLE_DATA_FILENAME] URLByAppendingPathExtension:@"plist"]];
                if (infoData) {
                    NSDictionary *info = [NSPropertyListSerialization propertyListWithData:infoData options:NSPropertyListImmutable format:NULL error:NULL];
                    if ([info isKindOfClass:[NSDictionary class]]) {
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
    
    if (didRead == NO) {
        SKDESTROY(tmpData);
        if (outError)
            *outError = error ?: [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")];
    }
    
    return didRead;
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    NSWindow *mainWindow = [[self mainWindowController] window];
    NSWindow *sheet = nil;
    
    if ([mainWindow attachedSheet] == nil) {
        sheet = [[NSWindow alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [(SKApplication *)NSApp setUserAttentionDisabled:YES];
        [NSApp beginSheet:sheet modalForWindow:mainWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        [(SKApplication *)NSApp setUserAttentionDisabled:NO];
    }
    
    BOOL success = [super revertToContentsOfURL:absoluteURL ofType:typeName error:outError];
    
    if (success) {
        [[self undoManager] disableUndoRegistration];
        [self setDataFromTmpData];
        [[self undoManager] enableUndoRegistration];
        [[self undoManager] removeAllActions];
        [fileUpdateChecker checkFileUpdatesIfNeeded];
    }
    
    SKDESTROY(tmpData);
    
    if (sheet) {
        [NSApp endSheet:sheet];
        [sheet orderOut:nil];
        [sheet release];
    }
    
    return success;
}

#pragma mark Printing

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError {
    NSPrintInfo *printInfo = [[[self printInfo] copy] autorelease];
    [[printInfo dictionary] addEntriesFromDictionary:printSettings];
    
    NSPrintOperation *printOperation = nil;
    PDFDocument *pdfDoc = [self pdfDocument];
    if ([pdfDoc respondsToSelector:@selector(printOperationForPrintInfo:scalingMode:autoRotate:)])
        printOperation = [pdfDoc printOperationForPrintInfo:printInfo scalingMode:kPDFPrintPageScaleNone autoRotate:YES];
    else if ([pdfDoc respondsToSelector:@selector(getPrintOperationForPrintInfo:autoRotate:)])
        printOperation = [pdfDoc getPrintOperationForPrintInfo:printInfo autoRotate:YES];
    
    // NSPrintProtected is a private key that disables the items in the PDF popup of the Print panel, and is set for encrypted documents
    if ([pdfDoc isEncrypted])
        [[[printOperation printInfo] dictionary] setValue:[NSNumber numberWithBool:NO] forKey:@"NSPrintProtected"];
    
    NSPrintPanel *printPanel = [printOperation printPanel];
    [printPanel setOptions:NSPrintPanelShowsCopies | NSPrintPanelShowsPageRange | NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation | NSPrintPanelShowsScaling | NSPrintPanelShowsPreview];
    [printPanel addAccessoryController:[[[SKPrintAccessoryController alloc] init] autorelease]];
    
    if (printOperation == nil && outError)
        *outError = [NSError printDocumentErrorWithLocalizedDescription:nil];
    
    return printOperation;
}

#pragma mark Actions

- (void)readNotesFromURL:(NSURL *)notesURL replace:(BOOL)replace {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSString *type = [ws typeOfFile:[notesURL path] error:NULL];
    NSArray *array = nil;
    
    if ([ws type:type conformsToType:SKNotesDocumentType]) {
        array = [NSKeyedUnarchiver unarchiveObjectWithFile:[notesURL path]];
    } else if ([ws type:type conformsToType:SKNotesFDFDocumentType]) {
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

#define CHECK_BUTTON_OFFSET_X 16.0
#define CHECK_BUTTON_OFFSET_Y 8.0

- (IBAction)readNotes:(id)sender{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    NSURL *fileURL = [self fileURL];
    NSButton *replaceNotesCheckButton = nil;
    NSView *readNotesAccessoryView = nil;
    
    if ([[[self mainWindowController] notes] count]) {
        replaceNotesCheckButton = [[[NSButton alloc] init] autorelease];
        [replaceNotesCheckButton setButtonType:NSSwitchButton];
        [replaceNotesCheckButton setTitle:NSLocalizedString(@"Replace existing notes", @"Check button title")];
        [replaceNotesCheckButton sizeToFit];
        [replaceNotesCheckButton setFrameOrigin:NSMakePoint(CHECK_BUTTON_OFFSET_X, CHECK_BUTTON_OFFSET_Y)];
        readNotesAccessoryView = [[NSView alloc] initWithFrame:NSInsetRect([replaceNotesCheckButton frame], -CHECK_BUTTON_OFFSET_X, -CHECK_BUTTON_OFFSET_Y)];
        [readNotesAccessoryView addSubview:replaceNotesCheckButton];
        [oPanel setAccessoryView:readNotesAccessoryView];
        [replaceNotesCheckButton setState:NSOnState];
    }
    
    [oPanel setDirectoryURL:[fileURL URLByDeletingLastPathComponent]];
    [oPanel setAllowedFileTypes:[NSArray arrayWithObjects:SKNotesDocumentType, nil]];
    [oPanel beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                NSURL *notesURL = [[oPanel URLs] objectAtIndex:0];
                BOOL replace = (replaceNotesCheckButton && [replaceNotesCheckButton state] == NSOnState);
                [self readNotesFromURL:notesURL replace:replace];
            }
        }];
}

- (void)setPDFData:(NSData *)data pageOffsets:(NSMapTable *)newPageOffsets {
    [[[self undoManager] prepareWithInvocationTarget:self] setPDFData:pdfData pageOffsets:pageOffsets];
    [self setPDFData:data];
    if (newPageOffsets != pageOffsets) {
        [pageOffsets release];
        pageOffsets = [newPageOffsets retain];
    }
}

- (void)convertNotesUsingPDFDocument:(PDFDocument *)pdfDocWithoutNotes {
    [[self mainWindowController] beginProgressSheetWithMessage:[NSLocalizedString(@"Converting notes", @"Message for progress sheet") stringByAppendingEllipsis] maxValue:0];
    
    PDFDocument *pdfDoc = [self pdfDocument];
    NSInteger i, count = [pdfDoc pageCount];
    BOOL didConvert = NO;
    NSMapTable *offsets = nil;
    
    for (i = 0; i < count; i++) {
        PDFPage *page = [pdfDoc pageAtIndex:i];
        NSPoint pageOrigin = [page boundsForBox:kPDFDisplayBoxMediaBox].origin;
        
        for (PDFAnnotation *annotation in [[[page annotations] copy] autorelease]) {
            if ([annotation isSkimNote] == NO && [annotation isConvertibleAnnotation]) {
                NSDictionary *properties = [annotation SkimNoteProperties];
                if ([[annotation type] isEqualToString:SKNTextString])
                    properties = [SKNPDFAnnotationNote textToNoteSkimNoteProperties:properties];
                PDFAnnotation *newAnnotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:properties];
                if (newAnnotation) {
                    [[self pdfView] removeAnnotation:annotation];
                    [[self pdfView] addAnnotation:newAnnotation toPage:page];
                    if ([[newAnnotation contents] length] == 0)
                        [newAnnotation autoUpdateString];
                    [newAnnotation release];
                    didConvert = YES;
                }
            }
        }
        
        if (NSEqualPoints(pageOrigin, NSZeroPoint) == NO) {
            if (offsets == nil)
                offsets = NSCreateMapTable(NSIntegerMapKeyCallBacks, NSOwnedPointerMapValueCallBacks, 0);
            NSPointPointer offsetPtr = NSZoneMalloc([self zone], sizeof(NSPoint));
            *offsetPtr = pageOrigin;
            NSMapInsert(offsets, (const void *)[page pageIndex], offsetPtr);
        }
    }
    
    if (didConvert) {
        // if pdfDocWithoutNotes was nil, the document was not encrypted, so no need to try to unlock
        if (pdfDocWithoutNotes == nil)
            pdfDocWithoutNotes = [[[PDFDocument alloc] initWithData:pdfData] autorelease];
        count = [pdfDocWithoutNotes pageCount];
        for (i = 0; i < count; i++) {
            PDFPage *page = [pdfDocWithoutNotes pageAtIndex:i];
            
            for (PDFAnnotation *annotation in [[[page annotations] copy] autorelease]) {
                if ([annotation isSkimNote] == NO && [annotation isConvertibleAnnotation])
                    [page removeAnnotation:annotation];
            }
        }
        
        [self setPDFData:[pdfDocWithoutNotes dataRepresentation] pageOffsets:offsets];
        
        [[self undoManager] setActionName:NSLocalizedString(@"Convert Notes", @"Undo action name")];
        
        [offsets release];
    }
    
    [[self mainWindowController] dismissProgressSheet];
}

- (void)beginConvertNotesPasswordSheetForPDFDocument:(PDFDocument *)pdfDoc {
    SKTextFieldSheetController *passwordSheetController = [[[SKTextFieldSheetController alloc] initWithWindowNibName:@"PasswordSheet"] autorelease];
    
    [passwordSheetController beginSheetModalForWindow:[[self mainWindowController] window] completionHandler:^(NSInteger result) {
            if (result == NSOKButton) {
                [[passwordSheetController window] orderOut:nil];
                
                if (pdfDoc && [pdfDoc allowsPrinting] == NO && 
                    ([pdfDoc unlockWithPassword:[passwordSheetController stringValue]] == NO || [pdfDoc allowsPrinting] == NO)) {
                    [self beginConvertNotesPasswordSheetForPDFDocument:pdfDoc];
                } else {
                    [self convertNotesUsingPDFDocument:[pdfDoc autorelease]];
                }
            }
        }];
}

- (void)convertNotesSheetDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertAlternateReturn)
        return;
    
    PDFDocument *pdfDocWithoutNotes = nil;
    
    // remove the sheet, to make place for either the password or progress sheet
    [[alert window] orderOut:nil];
    
    if ([[self pdfDocument] allowsPrinting] == NO) {
        pdfDocWithoutNotes = [[[PDFDocument alloc] initWithData:pdfData] autorelease];
        if ([self tryToUnlockDocument:pdfDocWithoutNotes] == NO || [pdfDocWithoutNotes allowsPrinting] == NO) {
            [self beginConvertNotesPasswordSheetForPDFDocument:pdfDocWithoutNotes];
            return;
        }
    }
    [self convertNotesUsingPDFDocument:pdfDocWithoutNotes];
}

- (BOOL)hasConvertibleAnnotations {
    PDFDocument *pdfDoc = [self pdfDocument];
    NSInteger i, count = [pdfDoc pageCount];
    for (i = 0; i < count; i++) {
        for (PDFAnnotation *annotation in [[pdfDoc pageAtIndex:i] annotations]) {
            if ([annotation isSkimNote] == NO && [annotation isConvertibleAnnotation])
                return YES;
        }
    }
    return NO;
}

- (IBAction)convertNotes:(id)sender {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    if (([ws type:[self fileType] conformsToType:SKPDFDocumentType] == NO && [ws type:[self fileType] conformsToType:SKPDFBundleDocumentType] == NO) ||
        [self hasConvertibleAnnotations] == NO) {
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

- (void)saveArchiveToURL:(NSURL *)fileURL email:(BOOL)email {
    NSTask *task = [[[NSTask alloc] init] autorelease];
    if ([[fileURL pathExtension] isEqualToString:@"dmg"]) {
        [task setLaunchPath:@"/usr/bin/hdiutil"];
        [task setArguments:[NSArray arrayWithObjects:@"create", @"-srcfolder", [[self fileURL] path], @"-format", @"UDZO", @"-volname", [[fileURL lastPathComponent] stringByDeletingPathExtension], [fileURL path], nil]];
    } else {
        [task setLaunchPath:@"/usr/bin/tar"];
        [task setArguments:[NSArray arrayWithObjects:@"-czf", [fileURL path], [[self fileURL] lastPathComponent], nil]];
    }
    [task setCurrentDirectoryPath:[[[self fileURL] URLByDeletingLastPathComponent] path]];
    [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    
    SKAttachmentEmailer *emailer = nil;
    if (email)
        emailer = [SKAttachmentEmailer attachmentEmailerWithFileURL:fileURL subject:[self displayName] waitingForTask:task];
    
    @try {
        [task launch];
    }
    @catch (id exception) {
        [emailer taskFailed];
    }
}

- (IBAction)saveArchive:(id)sender {
    NSString *ext = ([sender tag] | SKArchiveDiskImageMask) ? @"dmg" : @"tgz";
    NSURL *fileURL = [self fileURL];
    if (fileURL && [fileURL checkResourceIsReachableAndReturnError:NULL] && [self isDocumentEdited] == NO) {
        if (([sender tag] | SKArchiveEmailMask)) {
            NSURL *tmpDirURL = [[NSFileManager defaultManager] uniqueChewableItemsDirectoryURL];
            NSURL *tmpFileURL = [tmpDirURL URLByAppendingPathComponent:[[self fileURL] lastPathComponentReplacingPathExtension:ext]];
            [self saveArchiveToURL:tmpFileURL email:YES];
        } else {
            NSSavePanel *sp = [NSSavePanel savePanel];
            [sp setAllowedFileTypes:[NSArray arrayWithObjects:ext, nil]];
            [sp setCanCreateDirectories:YES];
            [sp setNameFieldStringValue:[fileURL lastPathComponentReplacingPathExtension:ext]];
            [sp beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result){
                    if (NSFileHandlingPanelOKButton == result)
                        [self saveArchiveToURL:[sp URL] email:NO];
                }];
        }
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"You must save this file first", @"Alert text when trying to create archive for unsaved document") defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The document has unsaved changes, or has not previously been saved to disk.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (IBAction)moveToTrash:(id)sender {
    NSURL *fileURL = [self fileURL];
    if ([fileURL checkResourceIsReachableAndReturnError:NULL]) {
        NSURL *folderURL = [fileURL URLByDeletingLastPathComponent];
        NSString *fileName = [fileURL lastPathComponent];
        NSInteger tag = 0;
        if ([[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[folderURL path] destination:nil files:[NSArray arrayWithObjects:fileName, nil] tag:&tag])
            [self close];
        else NSBeep();
    } else NSBeep();
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
         } else if ([fileUpdateChecker fileChangedOnDisk] || 
                    NSOrderedAscending == [[self fileModificationDate] compare:[[[NSFileManager defaultManager] attributesOfItemAtPath:[[self fileURL] path] error:NULL] fileModificationDate]]) {
             NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Do you want to revert to the version of the document \"%@\" on disk?", @"Message in alert dialog"), [[self fileURL] lastPathComponent]] 	 
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
    [[self mainWindowController] performFindPanelAction:sender];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
	if ([anItem action] == @selector(revertDocumentToSaved:)) {
        if ([self fileURL] == nil || [[self fileURL] checkResourceIsReachableAndReturnError:NULL] == NO)
            return NO;
        return [self isDocumentEdited] || [fileUpdateChecker fileChangedOnDisk] ||
               NSOrderedAscending == [[self fileModificationDate] compare:[[[NSFileManager defaultManager] attributesOfItemAtPath:[[self fileURL] path] error:NULL] fileModificationDate]];
    } else if ([anItem action] == @selector(printDocument:)) {
        return [[self pdfDocument] allowsPrinting];
    } else if ([anItem action] == @selector(convertNotes:)) {
        return [[NSWorkspace sharedWorkspace] type:[self fileType] conformsToType:SKPDFDocumentType] && [[self pdfDocument] isLocked] == NO;
    } else if ([anItem action] == @selector(saveArchive:)) {
        return [self fileURL] && [[self fileURL] checkResourceIsReachableAndReturnError:NULL] && [self isDocumentEdited] == NO;
    } else if ([anItem action] == @selector(moveToTrash:)) {
        return [self fileURL] && [[self fileURL] checkResourceIsReachableAndReturnError:NULL];
    }
    return [super validateUserInterfaceItem:anItem];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if ([menuItem action] == @selector(performFindPanelAction:))
        return [[self mainWindowController] validateMenuItem:menuItem];
    else if ([[SKMainDocument superclass] instancesRespondToSelector:_cmd])
        return [super validateMenuItem:menuItem];
    return YES;
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
        [fileUpdateChecker setDocument:nil];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentFileURLDidChangeNotification object:self];
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
        
        if (NO == [SKSyncPreferences getTeXEditorCommand:&editorCmd arguments:&editorArgs forPreset:editorPreset]) {
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
                    [searchPaths insertObject:[[[appBundle bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Helpers"] atIndex:0];
                    if ([editorPreset isEqualToString:@"BBEdit"] == NO)
                        [searchPaths insertObject:[[appBundle executablePath] stringByDeletingLastPathComponent] atIndex:0];
                    [searchPaths insertObject:[appBundle resourcePath] atIndex:0];
                    [searchPaths insertObject:[appBundle sharedSupportPath] atIndex:0];
                }
            } else {
                [searchPaths addObjectsFromArray:[[[NSFileManager defaultManager] applicationSupportDirectoryURLs] valueForKey:@"path"]];
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
        
        NSTask *task = [[[NSTask alloc] init] autorelease];
        [task setLaunchPath:@"/bin/sh"];
        [task setCurrentDirectoryPath:[file stringByDeletingLastPathComponent]];
        [task setArguments:[NSArray arrayWithObjects:@"-c", cmdString, nil]];
        [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
        @try {
            [task launch];
        }
        @catch(id exception) {
            NSLog(@"%@ %@ failed", [task description], [task launchPath]);
        }
    }
}

- (void)synchronizer:(SKPDFSynchronizer *)synchronizer foundLocation:(NSPoint)point atPageIndex:(NSUInteger)pageIndex options:(NSInteger)options {
    PDFDocument *pdfDoc = [self pdfDocument];
    if (pageIndex < [pdfDoc pageCount]) {
        PDFPage *page = [pdfDoc pageAtIndex:pageIndex];
        if (options & SKPDFSynchronizerFlippedMask)
            point.y = NSMaxY([page boundsForBox:kPDFDisplayBoxMediaBox]) - point.y;
        [[self pdfView] displayLineAtPoint:point inPageAtIndex:pageIndex showReadingBar:(options & SKPDFSynchronizerShowReadingBarMask) != 0];
    }
}


#pragma mark Accessors

- (SKInteractionMode)systemInteractionMode {
    // only return the real interaction mode when the fullscreen window is on the primary screen, otherwise no need to block main menu and dock
    if ([[[[self mainWindowController] window] screen] isEqual:[NSScreen primaryScreen]])
        return [[self mainWindowController] interactionMode];
    return SKNormalMode;
}

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
    if ([self mainWindowController] == nil)
        [self makeWindowControllers];
    [[self mainWindowController] applySetup:setup];
}

- (SKPDFView *)pdfView {
    return [[self mainWindowController] pdfView];
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
    
    OSStatus err = SecKeychainFindGenericPassword(NULL, strlen(service), service, strlen(account), account, password ? &passwordLength : NULL, password ? &passwordData : NULL, itemRef);
    
    if (err == errSecItemNotFound) {
        // try to find an item in the old format
        service = [[@"Skim - " stringByAppendingString:fileID] UTF8String];
        account = [NSUserName() UTF8String];
        
        err = SecKeychainFindGenericPassword(NULL, strlen(service), service, strlen(account), account, password ? &passwordLength : NULL, password ? &passwordData : NULL, itemRef);
        
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
    } else if (password) {
        // password not on keychain, so add it
        err = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &attributes, passwordLength, passwordData, NULL, NULL, NULL);
        if (err != noErr)
            NSLog(@"Error %d occurred adding password: %@", err, [(id)SecCopyErrorMessageString(err, NULL) autorelease]);
    }
}

- (NSString *)fileIDStringForDocument:(PDFDocument *)document {
    return [[document fileIDStrings:originalData] lastObject] ?: [originalData md5String];
}

- (void)doSavePasswordInKeychain:(NSString *)password {
    NSString *fileID = [self fileIDStringForDocument:[self pdfDocument]];
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
        NSString *fileID = [self fileIDStringForDocument:document];
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
        if ((attrString = [[doc pageAtIndex:i] attributedString]))
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

- (NSInteger)toolMode {
    NSInteger toolMode = [[self pdfView] toolMode];
    if (toolMode == SKNoteToolMode)
        toolMode += [[self pdfView] annotationMode];
    return toolMode;
}

- (void)setToolMode:(NSInteger)newToolMode {
    if (newToolMode >= SKNoteToolMode) {
        [[self pdfView] setAnnotationMode:newToolMode - SKNoteToolMode];
        newToolMode = SKNoteToolMode;
    }
    [[self pdfView] setToolMode:newToolMode];
}

- (NSInteger)interactionMode {
    return [[self mainWindowController] interactionMode];
}

- (void)setInteractionMode:(NSInteger)interactionMode {
    if ([[self pdfDocument] isLocked] == NO && interactionMode != [[self mainWindowController] interactionMode]) {
        switch (interactionMode) {
            case SKNormalMode:       [[self mainWindowController] exitFullscreen:nil];    break;
            case SKFullScreenMode:   [[self mainWindowController] enterFullscreen:nil];   break;
            case SKPresentationMode: [[self mainWindowController] enterPresentation:nil]; break;
        }
    }
}

- (NSDocument *)presentationNotesDocument {
    return [[self mainWindowController] presentationNotesDocument];
}

- (void)setPresentationNotesDocument:(NSDocument *)document {
    if ([document isPDFDocument] && [document countOfPages] == [self countOfPages] && document != self)
        [[self mainWindowController] setPresentationNotesDocument:document];
}

- (BOOL)isPDFDocument {
    return YES;
}

- (id)newScriptingObjectOfClass:(Class)class forValueForKey:(NSString *)key withContentsValue:(id)contentsValue properties:(NSDictionary *)properties {
    if ([key isEqualToString:@"notes"]) {
        PDFAnnotation *annotation = nil;
        PDFSelection *selection = [PDFSelection selectionWithSpecifier:[properties objectForKey:SKPDFAnnotationSelectionSpecifierKey]];
        PDFPage *page = [selection safeFirstPage];
        if (page == nil || [page document] != [self pdfDocument]) {
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

- (id)copyScriptingValue:(id)value forKey:(NSString *)key withProperties:(NSDictionary *)properties {
    if ([key isEqualToString:@"notes"]) {
        NSMutableArray *copiedValue = [[NSMutableArray alloc] init];
        for (PDFAnnotation *annotation in value) {
            if ([annotation isMovable] && [[annotation page] document] == [self pdfDocument]) {
                PDFAnnotation *copiedAnnotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:[annotation SkimNoteProperties]];
                [copiedAnnotation registerUserName];
                if ([copiedAnnotation respondsToSelector:@selector(setPage:)])
                    [copiedAnnotation performSelector:@selector(setPage:) withObject:[annotation page]];
                if ([properties count])
                    [copiedAnnotation setScriptingProperties:[copiedAnnotation coerceValue:properties forKey:@"scriptingProperties"]];
                [copiedValue addObject:copiedAnnotation];
            } else {
                // we don't want to duplicate markup
                NSScriptCommand *cmd = [NSScriptCommand currentCommand];
                [cmd setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
                [cmd setScriptErrorString:@"Cannot duplicate markup note."];
                SKDESTROY(copiedValue);
            }
        }
        return copiedValue;
    }
    return [super copyScriptingValue:value forKey:key withProperties:properties];
}

- (id)handleSaveScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id fileType = [args objectForKey:@"FileType"];
    id file = [args objectForKey:@"File"];
    // we don't want to expose the UTI types to the user, and we allow template file names without extension
    if (fileType && file) {
        NSString *normalizedType = nil;
        NSInteger option = SKExportOptionDefault;
        NSArray *writableTypes = [self writableTypesForSaveOperation:NSSaveToOperation];
        SKTemplateManager *tm = [SKTemplateManager sharedManager];
        if ([fileType isEqualToString:@"PDF"]) {
            normalizedType = SKPDFDocumentType;
        } else if ([fileType isEqualToString:@"PDF With Embedded Notes"]) {
            normalizedType = SKPDFDocumentType;
            option = SKExportOptionWithEmbeddedNotes;
        } else if ([fileType isEqualToString:@"PDF Without Notes"]) {
            normalizedType = SKPDFDocumentType;
            option = SKExportOptionWithoutNotes;
        } else if ([fileType isEqualToString:@"PostScript"]) {
            normalizedType = [[NSWorkspace sharedWorkspace] type:[self fileType] conformsToType:SKEncapsulatedPostScriptDocumentType] ? SKEncapsulatedPostScriptDocumentType : SKPostScriptDocumentType;
        } else if ([fileType isEqualToString:@"PostScript Without Notes"]) {
            normalizedType = [[NSWorkspace sharedWorkspace] type:[self fileType] conformsToType:SKEncapsulatedPostScriptDocumentType] ? SKEncapsulatedPostScriptDocumentType : SKPostScriptDocumentType;
            option = SKExportOptionWithoutNotes;
        } else if ([fileType isEqualToString:@"Encapsulated PostScript"]) {
            normalizedType = SKEncapsulatedPostScriptDocumentType;
        } else if ([fileType isEqualToString:@"Encapsulated PostScript Without Notes"]) {
            normalizedType = SKEncapsulatedPostScriptDocumentType;
            option = SKExportOptionWithoutNotes;
        } else if ([fileType isEqualToString:@"DVI"]) {
            normalizedType = SKDVIDocumentType;
        } else if ([fileType isEqualToString:@"DVI Without Notes"]) {
            normalizedType = SKDVIDocumentType;
            option = SKExportOptionWithoutNotes;
        } else if ([fileType isEqualToString:@"XDV"]) {
            normalizedType = SKXDVDocumentType;
        } else if ([fileType isEqualToString:@"XDV Without Notes"]) {
            normalizedType = SKXDVDocumentType;
            option = SKExportOptionWithoutNotes;
        } else if ([fileType isEqualToString:@"PDF Bundle"]) {
            normalizedType = SKPDFBundleDocumentType;
        } else if ([fileType isEqualToString:@"Skim Notes"]) {
            normalizedType = SKNotesDocumentType;
        } else if ([fileType isEqualToString:@"Notes as Text"]) {
            normalizedType = SKNotesTextDocumentType;
        } else if ([fileType isEqualToString:@"Notes as RTF"]) {
            normalizedType = SKNotesRTFDocumentType;
        } else if ([fileType isEqualToString:@"Notes as RTFD"]) {
            normalizedType = SKNotesRTFDDocumentType;
        } else if ([fileType isEqualToString:@"Notes as FDF"]) {
            normalizedType = SKNotesFDFDocumentType;
        } else if ([writableTypes containsObject:fileType] == NO) {
            normalizedType = [tm templateTypeForDisplayName:fileType];
        }
        if ([writableTypes containsObject:normalizedType] || [[tm customTemplateTypes] containsObject:fileType]) {
            exportOption = option;
            NSMutableDictionary *arguments = [[command arguments] mutableCopy];
            if (normalizedType) {
                fileType = normalizedType;
                [arguments setObject:fileType forKey:@"FileType"];
            }
            // for some reason the default implementation adds the extension twice for template types
            if ([[file pathExtension] isCaseInsensitiveEqual:[tm fileNameExtensionForTemplateType:fileType]])
                [arguments setObject:[file URLByDeletingPathExtension] forKey:@"File"];
            [command setArguments:arguments];
            [arguments release];
        }
    }
    return [super handleSaveScriptCommand:command];
}

- (void)handleRevertScriptCommand:(NSScriptCommand *)command {
    if ([self fileURL] && [[self fileURL] checkResourceIsReachableAndReturnError:NULL]) {
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
        [[self synchronizer] findPageAndLocationForLine:[location index] inFile:[[source URLReplacingPathExtension:@"tex"] path] options:options];
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
        
        if ((selection = [[self pdfDocument] findString:text fromSelection:selection withOptions:options]))
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
    if ([[NSWorkspace sharedWorkspace] type:[self fileType] conformsToType:SKPDFDocumentType] == NO && [[NSWorkspace sharedWorkspace] type:[self fileType] conformsToType:SKPDFBundleDocumentType] == NO)
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
    else if ([self hasConvertibleAnnotations])
        [self convertNotesSheetDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:NULL];
}

- (void)handleReadNotesScriptCommand:(NSScriptCommand *)command {
    NSDictionary *args = [command evaluatedArguments];
    NSURL *notesURL = [args objectForKey:@"File"];
    if (notesURL == nil) {
        [command setScriptErrorNumber:NSRequiredArgumentsMissingScriptError];
    } else {
        NSNumber *replaceNumber = [args objectForKey:@"Replace"];
        NSString *fileType = [[NSDocumentController sharedDocumentController] typeForContentsOfURL:notesURL error:NULL];
        if ([[NSWorkspace sharedWorkspace] type:fileType conformsToType:SKNotesDocumentType])
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
