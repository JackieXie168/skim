//
//  SKDocumentController.m
//  Skim
//
//  Created by Christiaan Hofman on 5/21/07.
/*
 This software is Copyright (c) 2007-2011
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "SKDocumentController.h"
#import "NSDocument_SKExtensions.h"
#import "SKMainDocument.h"
#import "SKDownloadController.h"
#import "NSURL_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKApplicationController.h"
#import "NSFileManager_SKExtensions.h"
#import "BDAlias.h"
#import "SKMainWindowController.h"
#import "NSError_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "SKNotesDocument.h"

#define SKAutosaveIntervalKey @"SKAutosaveInterval"

#define SKIM_NOTES_KEY @"net_sourceforge_skim-app_notes"

// See CFBundleTypeName in Info.plist
NSString *SKPDFDocumentType = nil;
NSString *SKPDFBundleDocumentType = @"PDF Bundle";
NSString *SKEmbeddedPDFDocumentType = @"PDF With Embedded Notes";
NSString *SKBarePDFDocumentType = @"PDF Without Notes";
NSString *SKNotesDocumentType = @"Skim Notes";
NSString *SKNotesTextDocumentType = @"Notes as Text";
NSString *SKNotesRTFDocumentType = @"Notes as RTF";
NSString *SKNotesRTFDDocumentType = @"Notes as RTFD";
NSString *SKNotesFDFDocumentType = @"Notes as FDF";
NSString *SKPostScriptDocumentType = nil;
NSString *SKBarePostScriptDocumentType = @"PostScript Without Notes";
NSString *SKDVIDocumentType = @"DVI document";
NSString *SKBareDVIDocumentType = @"DVI Without Notes";
NSString *SKXDVDocumentType = @"XDV document";
NSString *SKBareXDVDocumentType = @"XDV Without Notes";
NSString *SKFolderDocumentType = @"Folder";

NSString *SKDocumentSetupAliasKey = @"_BDAlias";
NSString *SKDocumentSetupFileNameKey = @"fileName";

NSString *SKDocumentControllerDidAddDocumentNotification = @"SKDocumentControllerDidAddDocumentNotification";
NSString *SKDocumentControllerDidRemoveDocumentNotification = @"SKDocumentControllerDidRemoveDocumentNotification";
NSString *SKDocumentDidShowNotification = @"SKDocumentDidShowNotification";

NSString *SKDocumentControllerDocumentKey = @"document";

@implementation SKDocumentController

+ (void)initialize {
    SKINITIALIZE;
    
    SKPDFDocumentType = NSPDFPboardType;
    SKPostScriptDocumentType = NSPostScriptPboardType;
}

- (id)init {
    if (self = [super init]) {
        [self setAutosavingDelay:[[NSUserDefaults standardUserDefaults] doubleForKey:SKAutosaveIntervalKey]];
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(customExportTemplateFiles);
    [super dealloc];
}

- (void)addDocument:(NSDocument *)document {
    [super addDocument:document];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentControllerDidAddDocumentNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:document, SKDocumentControllerDocumentKey, nil]];
}

- (void)removeDocument:(NSDocument *)document {
    [super removeDocument:[[document retain] autorelease]];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentControllerDidRemoveDocumentNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:document, SKDocumentControllerDocumentKey, nil]];
}


- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions {    
    [openPanel setCanChooseDirectories:YES];
    return [super runModalOpenPanel:openPanel forTypes:extensions];
}

static BOOL isFolderAtPath(NSString *path) {
    return [[NSWorkspace sharedWorkspace] type:[[NSWorkspace sharedWorkspace] typeOfFile:path error:NULL] conformsToType:(NSString *)kUTTypeFolder];
}

- (NSString *)typeForContentsOfURL:(NSURL *)inAbsoluteURL error:(NSError **)outError {
    NSUInteger headerLength = 5;
    
    static NSData *pdfHeaderData = nil;
    if (nil == pdfHeaderData) {
        char *h = "%PDF-";
        pdfHeaderData = [[NSData alloc] initWithBytes:h length:headerLength];
    }
    static NSData *psHeaderData = nil;
    if (nil == psHeaderData) {
        char *h = "%!PS-";
        psHeaderData = [[NSData alloc] initWithBytes:h length:headerLength];
    }
    
    NSError *error = nil;
    NSString *type = [super typeForContentsOfURL:inAbsoluteURL error:&error];
    
    // folders are not recognized, so we have to check for those ourselves, rdar://problem/7056540
    if (isFolderAtPath([inAbsoluteURL path])) {
        type = SKFolderDocumentType;
    } else if ([self documentClassForType:type] == NULL) {
        // "open -f" creates a temporary file with a .txt extension, we want to be able to open these file as it can be very handy to e.g. display man pages and pretty printed text file from the command line
        if ([inAbsoluteURL isFileURL]) {
            NSData *leadingData = [[NSFileHandle fileHandleForReadingAtPath:[inAbsoluteURL path]] readDataOfLength:headerLength];
            if ([pdfHeaderData isEqual:leadingData])
                type = SKPDFDocumentType;
            else if ([psHeaderData isEqual:leadingData])
                type = SKPostScriptDocumentType;
        }
        if (type == nil && outError)
            *outError = error;
    } else if ([type isEqualToString:SKNotesFDFDocumentType]) {
        // Springer sometimes sends PDF files with an .fdf extension for review, huh?
        NSString *fileName = [inAbsoluteURL path];
        NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:fileName];
        NSData *leadingData = [fh readDataOfLength:headerLength];
        if ([leadingData length] >= [pdfHeaderData length] && [pdfHeaderData isEqual:[leadingData subdataWithRange:NSMakeRange(0, [pdfHeaderData length])]])
            type = SKPDFDocumentType;
    }
    
    return type;
}

- (Class)documentClassForContentsOfURL:(NSURL *)inAbsoluteURL {
    return [self documentClassForType:[self typeForContentsOfURL:inAbsoluteURL error:NULL]];
}

static NSData *convertTIFFDataToPDF(NSData *tiffData)
{
    // this should accept any image data types we're likely to run across, but PICT returns a zero size image
    CGImageSourceRef imsrc = CGImageSourceCreateWithData((CFDataRef)tiffData, (CFDictionaryRef)[NSDictionary dictionaryWithObject:(id)kUTTypeTIFF forKey:(id)kCGImageSourceTypeIdentifierHint]);

    NSMutableData *pdfData = nil;
    
    if (imsrc && CGImageSourceGetCount(imsrc)) {
        CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imsrc, 0, NULL);

        pdfData = [NSMutableData dataWithCapacity:[tiffData length]];
        CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)pdfData);
        
        // create full size image, assuming pixel == point
        const CGRect rect = CGRectMake(0, 0, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
        
        CGContextRef ctxt = CGPDFContextCreate(consumer, &rect, NULL);
        CGPDFContextBeginPage(ctxt, NULL);
        CGContextDrawImage(ctxt, rect, cgImage);
        CGPDFContextEndPage(ctxt);
        
        CGContextFlush(ctxt);

        CGDataConsumerRelease(consumer);
        CGContextRelease(ctxt);
        CGImageRelease(cgImage);
    }
    
    if (imsrc) CFRelease(imsrc);

    return pdfData;
}

- (id)openDocumentWithImageFromPasteboard:(NSPasteboard *)pboard error:(NSError **)outError {
    // allow any filter services to convert to TIFF data if we can't get PDF or PS directly
    pboard = [NSPasteboard pasteboardByFilteringTypesInPasteboard:pboard];
    NSString *pboardType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSPDFPboardType, NSPostScriptPboardType, NSTIFFPboardType, nil]];
    id document = nil;
    
    if (pboardType) {
        
        NSData *data = [pboard dataForType:pboardType];
        
        // if it's image data, convert to PDF, then explicitly set the pboard type to PDF
        if ([pboardType isEqualToString:NSTIFFPboardType]) {
            data = convertTIFFDataToPDF(data);
            pboardType = NSPDFPboardType;
        }
        
        NSString *type = [pboardType isEqualToString:NSPostScriptPboardType] ? SKPostScriptDocumentType : SKPDFDocumentType;
        NSError *error = nil;
        
        document = [self makeUntitledDocumentOfType:type error:&error];
        
        if ([document readFromData:data ofType:type error:&error]) {
            [self addDocument:document];
            [document makeWindowControllers];
            [document showWindows];
        } else {
            document = nil;
            if (outError)
                *outError = error;
        }
        
    } else if (outError) {
        *outError = [NSError readPasteboardErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load data from clipboard", @"Error description")];
    }
    
    return document;
}

- (id)openDocumentWithURLFromPasteboard:(NSPasteboard *)pboard error:(NSError **)outError {
    NSURL *theURL = [NSURL URLFromPasteboardAnyType:pboard];
    id document = nil;
    
    if ([theURL isFileURL]) {
        document = [self openDocumentWithContentsOfURL:theURL display:YES error:outError];
    } else if (theURL) {
        document = [[SKDownloadController sharedDownloadController] addDownloadForURL:theURL];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoOpenDownloadsWindowKey])
            [[SKDownloadController sharedDownloadController] showWindow:self];
    } else if (outError) {
        *outError = [NSError readPasteboardErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load data from clipboard", @"Error description")];
    }
    
    return document;
}

- (id)openNotesDocumentWithURLFromPasteboard:(NSPasteboard *)pboard error:(NSError **)outError {
    NSURL *theURL = [NSURL URLFromPasteboardAnyType:pboard];
    id document = nil;
    
    if ([theURL isFileURL]) {
        NSError *error = nil;
        NSString *type = [self typeForContentsOfURL:theURL error:&error];
        
        if ([[SKNotesDocument readableTypes] containsObject:type]) {
            document = [self openDocumentWithContentsOfURL:theURL display:YES error:outError];
        } else if ([[SKMainDocument readableTypes] containsObject:type]) {
            for (document in [self documents]) {
                if ([document respondsToSelector:@selector(sourceFileURL)] && [[document sourceFileURL] isEqual:theURL])
                    break;
            }
            if (document) {
                [document showWindows];
            } else {
                NSData *data = nil;
                
                if ([type isEqualToString:SKPDFBundleDocumentType]) {
                    NSString *skimFile = [[NSFileManager defaultManager] bundledFileWithExtension:@"skim" inPDFBundleAtPath:[theURL path] error:&error];
                    data = skimFile ? [NSData dataWithContentsOfFile:skimFile options:0 error:&error] : nil;
                } else {
                    data = [[SKNExtendedAttributeManager sharedManager] extendedAttributeNamed:SKIM_NOTES_KEY atPath:[theURL path] traverseLink:YES error:&error];
                }
                
                document = [self makeUntitledDocumentOfType:SKNotesDocumentType error:&error];
                [document setSourceFileURL:theURL];
                
                if (data == nil || [document readFromData:data ofType:SKNotesDocumentType error:&error]) {
                    [self addDocument:document];
                    [document makeWindowControllers];
                    [document showWindows];
                } else {
                    document = nil;
                    if (outError)
                        *outError = error;
                }
            }
        }
    } else if (outError) {
        *outError = [NSError readPasteboardErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load data from clipboard", @"Error description")];
    }
    
    return document;
}

- (IBAction)newDocumentFromClipboard:(id)sender {
    NSError *error = nil;
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    id document = [self openDocumentWithImageFromPasteboard:pboard error:&error];
    if (document == nil)
        document = [self openDocumentWithURLFromPasteboard:pboard error:&error];
    if (document == nil && error && [error isUserCancelledError] == NO)
        [NSApp presentError:error];
}

- (id)openDocumentWithSetup:(NSDictionary *)setup error:(NSError **)outError {
    id document = nil;
    NSError *error = nil;
    NSURL *fileURL = [[BDAlias aliasWithData:[setup objectForKey:SKDocumentSetupAliasKey]] fileURL];
    if(fileURL == nil && [setup objectForKey:SKDocumentSetupFileNameKey])
        fileURL = [NSURL fileURLWithPath:[setup objectForKey:SKDocumentSetupFileNameKey]];
    if(fileURL && NO == [[NSFileManager defaultManager] isTrashedFileAtURL:fileURL]) {
        if (document = [self documentForURL:fileURL]) {
            // the document was already open, don't call makeWindowControllers because that adds new empty windows
            [document applySetup:setup];
            [document showWindows];
        } else if (document = [self openDocumentWithContentsOfURL:fileURL display:NO error:&error]) {
            [document makeWindowControllers];
            [document applySetup:setup];
            [document showWindows];
        } else if (outError) {
            *outError = error;
        }
    }
    return document;
}

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError {
    NSString *type = [self typeForContentsOfURL:absoluteURL error:NULL];
    if ([type isEqualToString:SKNotesDocumentType]) {
        NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
        if ([event eventID] == kAEOpenDocuments && [event descriptorForKeyword:keyAESearchText]) {
            NSString *pdfFile = [absoluteURL pathReplacingPathExtension:@"pdf"];
            BOOL isDir;
            if ([[NSFileManager defaultManager] fileExistsAtPath:pdfFile isDirectory:&isDir] && isDir == NO)
                absoluteURL = [NSURL fileURLWithPath:pdfFile];
        }
    } else if ([type isEqualToString:SKFolderDocumentType]) {
        NSDocument *doc = nil;
        NSError *error = nil;
        NSString *basePath = [absoluteURL path];
        NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:basePath];
        NSString *path;
        NSMutableArray *urls = [NSMutableArray array];
        BOOL failed = NO;
        
        while (path = [dirEnum nextObject]) {
            NSString *fullPath = [basePath stringByAppendingPathComponent:path];
            NSURL *url = [NSURL fileURLWithPath:fullPath];
            if ([self documentClassForContentsOfURL:url])
                [urls addObject:url];
            if ([[[dirEnum fileAttributes] valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory] &&
                ([[path lastPathComponent] hasPrefix:@"."] || NO == isFolderAtPath(fullPath)))
                [dirEnum skipDescendents];
        }
        
        if ([urls count] > 10) {
            NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to open %lu documents?", @"Message in alert dialog"), (unsigned long)[urls count]]
                                             defaultButton:NSLocalizedString(@"Cancel", @"Button title")
                                           alternateButton:NSLocalizedString(@"Open", @"Button title")
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"Each document opens in a separate window.", @"Informative text in alert dialog")];
            
            if (NSAlertDefaultReturn == [alert runModal]) {
                urls = nil;
                error = [NSError userCancelledErrorWithUnderlyingError:nil];
            }
        }
        
        for (NSURL *url in urls) {
           doc = [self openDocumentWithContentsOfURL:url display:displayDocument error:&error];
           if (doc == nil)
                failed = YES;
        }
        
        if (failed)
            doc = nil;
        if (doc == nil && outError)
            *outError = error ?: [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")];
        return doc;
    }
    return [super openDocumentWithContentsOfURL:absoluteURL display:displayDocument error:outError];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
    if ([anItem action] == @selector(newDocumentFromClipboard:)) {
        NSPasteboard *pboard = [NSPasteboard pasteboardByFilteringTypesInPasteboard:[NSPasteboard generalPasteboard]];
        return ([pboard availableTypeFromArray:[NSArray arrayWithObjects:NSPDFPboardType, NSPostScriptPboardType, NSTIFFPboardType, NSURLPboardType, SKWeblocFilePboardType, NSStringPboardType, nil]] != nil);
    } else if ([[SKDocumentController superclass] instancesRespondToSelector:_cmd]) {
        return [super validateUserInterfaceItem:anItem];
    } else
        return YES;
}

- (NSArray *)customExportTemplateFiles {
    if (customExportTemplateFiles == nil) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSMutableArray *templateFiles = [NSMutableArray array];
        
        for (NSString *appSupportPath in [[NSFileManager defaultManager] applicationSupportDirectories]) {
            NSString *templatesPath = [appSupportPath stringByAppendingPathComponent:@"Templates"];
            BOOL isDir;
            if ([fm fileExistsAtPath:templatesPath isDirectory:&isDir] && isDir) {
                for (NSString *file in [fm subpathsAtPath:templatesPath]) {
                    if ([file hasPrefix:@"."] == NO && [[file stringByDeletingPathExtension] isEqualToString:@"notesTemplate"] == NO)
                        [templateFiles addObject:file];
                }
            }
        }
        [templateFiles sortUsingSelector:@selector(caseInsensitiveCompare:)];
        customExportTemplateFiles = [templateFiles copy];
    }
    return customExportTemplateFiles;
}

- (NSArray *)customExportTemplateFilesResetting {
    SKDESTROY(customExportTemplateFiles);
    return [self customExportTemplateFiles];
}

- (NSArray *)fileExtensionsFromType:(NSString *)documentTypeName {
    NSArray *fileExtensions = [super fileExtensionsFromType:documentTypeName];
    if ([fileExtensions count] == 0 && [[self customExportTemplateFiles] containsObject:documentTypeName])
        fileExtensions = [NSArray arrayWithObjects:[documentTypeName pathExtension], nil];
	return fileExtensions;
}

- (NSString *)displayNameForType:(NSString *)documentTypeName{
    NSString *displayName = nil;
    if ([[self customExportTemplateFiles] containsObject:documentTypeName])
        displayName = [documentTypeName stringByDeletingPathExtension];
    else
        displayName = [super displayNameForType:documentTypeName];
    return displayName;
}

@end
