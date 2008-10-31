//
//  SKDocumentController.m
//  Skim
//
//  Created by Christiaan Hofman on 5/21/07.
/*
 This software is Copyright (c) 2007-2008
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
#import "SKPDFDocument.h"
#import "SKDownloadController.h"
#import "NSString_SKExtensions.h"
#import "NSURL_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKRuntime.h"
#import "SKApplicationController.h"
#import "Files_SKExtensions.h"
#import "BDAlias.h"
#import "SKMainWindowController.h"

static NSString *SKAutosaveIntervalKey = @"SKAutosaveInterval";


// See CFBundleTypeName in Info.plist
static NSString *SKPDFDocumentTypeName = nil; /* set to NSPDFPboardType, not @"NSPDFPboardType" */
static NSString *SKPDFBundleDocumentTypeName = @"PDF Bundle";
static NSString *SKEmbeddedPDFDocumentTypeName = @"PDF With Embedded Notes";
static NSString *SKBarePDFDocumentTypeName = @"PDF Without Notes";
static NSString *SKNotesDocumentTypeName = @"Skim Notes";
static NSString *SKNotesTextDocumentTypeName = @"Notes as Text";
static NSString *SKNotesRTFDocumentTypeName = @"Notes as RTF";
static NSString *SKNotesRTFDDocumentTypeName = @"Notes as RTFD";
static NSString *SKNotesFDFDocumentTypeName = @"Notes as FDF";
static NSString *SKPostScriptDocumentTypeName = @"PostScript document";
static NSString *SKDVIDocumentTypeName = @"DVI document";

static NSString *SKPDFDocumentTypeUTI = @"com.adobe.pdf";
static NSString *SKPDFBundleDocumentTypeUTI = @"net.sourceforge.skim-app.pdfd";
static NSString *SKEmbeddedPDFDocumentTypeUTI = @"net.sourceforge.skim-app.embedded.pdf";
static NSString *SKBarePDFDocumentTypeUTI = @"net.sourceforge.skim-app.bare.pdf";
static NSString *SKNotesDocumentTypeUTI = @"net.sourceforge.skim-app.skimnotes";
static NSString *SKNotesTextDocumentTypeUTI = @"public.plain-text";
static NSString *SKNotesRTFDocumentTypeUTI = @"public.rtf";
static NSString *SKNotesRTFDDocumentTypeUTI = @"com.apple.rtfd";
static NSString *SKNotesFDFDocumentTypeUTI = @"com.adobe.fdf"; // I don't know the UTI for fdf, is there one?
static NSString *SKPostScriptDocumentTypeUTI = @"com.adobe.postscript";
static NSString *SKDVIDocumentTypeUTI = @"net.sourceforge.skim-app.dvi"; // I don't know the UTI for dvi, is there one?

NSString *SKPDFDocumentType = nil;
NSString *SKPDFBundleDocumentType = nil;
NSString *SKEmbeddedPDFDocumentType = nil;
NSString *SKBarePDFDocumentType = nil;
NSString *SKNotesDocumentType = nil;
NSString *SKNotesTextDocumentType = nil;
NSString *SKNotesRTFDocumentType = nil;
NSString *SKNotesRTFDDocumentType = nil;
NSString *SKNotesFDFDocumentType = nil;
NSString *SKPostScriptDocumentType = nil;
NSString *SKDVIDocumentType = nil;

static BOOL SKIsEqualToDocumentType(NSString *docType, NSString *docTypeName, NSString *docUTI) {
    return ([[NSWorkspace sharedWorkspace] respondsToSelector:@selector(type:conformsToType:)] && [[NSWorkspace sharedWorkspace] type:docType conformsToType:docUTI]) || [docType isEqualToString:docTypeName];
}

#define DEFINE_IS_DOCUMENT_TYPE(name) BOOL SKIs##name##DocumentType(NSString *docType) { return SKIsEqualToDocumentType(docType, SK##name##DocumentTypeName, SK##name##DocumentTypeUTI); }

DEFINE_IS_DOCUMENT_TYPE(PDF)
DEFINE_IS_DOCUMENT_TYPE(PDFBundle)
DEFINE_IS_DOCUMENT_TYPE(EmbeddedPDF)
DEFINE_IS_DOCUMENT_TYPE(BarePDF)
DEFINE_IS_DOCUMENT_TYPE(Notes)
DEFINE_IS_DOCUMENT_TYPE(NotesText)
DEFINE_IS_DOCUMENT_TYPE(NotesRTF)
DEFINE_IS_DOCUMENT_TYPE(NotesRTFD)
DEFINE_IS_DOCUMENT_TYPE(NotesFDF)
DEFINE_IS_DOCUMENT_TYPE(PostScript)
DEFINE_IS_DOCUMENT_TYPE(DVI)

#define CHECK_DOCUMENT_TYPE(name) if (SKIs##name##DocumentType(docType)) return SK##name##DocumentType

NSString *SKNormalizedDocumentType(NSString *docType) {
    CHECK_DOCUMENT_TYPE(PDF);
    CHECK_DOCUMENT_TYPE(PDFBundle);
    CHECK_DOCUMENT_TYPE(EmbeddedPDF);
    CHECK_DOCUMENT_TYPE(BarePDF);
    CHECK_DOCUMENT_TYPE(Notes);
    CHECK_DOCUMENT_TYPE(NotesText);
    CHECK_DOCUMENT_TYPE(NotesRTF);
    CHECK_DOCUMENT_TYPE(NotesRTFD);
    CHECK_DOCUMENT_TYPE(NotesFDF);
    CHECK_DOCUMENT_TYPE(PostScript);
    CHECK_DOCUMENT_TYPE(DVI);
    return docType;
}


NSString *SKDocumentSetupAliasKey = @"_BDAlias";
NSString *SKDocumentSetupFileNameKey = @"fileName";

NSString *SKDocumentControllerDidAddDocumentNotification = @"SKDocumentControllerDidAddDocumentNotification";
NSString *SKDocumentControllerDidRemoveDocumentNotification = @"SKDocumentControllerDidRemoveDocumentNotification";
NSString *SKDocumentDidShowNotification = @"SKDocumentDidShowNotification";

@implementation SKDocumentController

#define DEFINE_DOCUMENT_TYPE(name) SK##name##DocumentType = floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SK##name##DocumentTypeName : SK##name##DocumentTypeUTI

+ (void)initialize {
    OBINITIALIZE;
    
    SKPDFDocumentTypeName = NSPDFPboardType;
    DEFINE_DOCUMENT_TYPE(PDF);
    DEFINE_DOCUMENT_TYPE(PDFBundle);
    DEFINE_DOCUMENT_TYPE(EmbeddedPDF);
    DEFINE_DOCUMENT_TYPE(BarePDF);
    DEFINE_DOCUMENT_TYPE(Notes);
    DEFINE_DOCUMENT_TYPE(NotesText);
    DEFINE_DOCUMENT_TYPE(NotesRTF);
    DEFINE_DOCUMENT_TYPE(NotesRTFD);
    DEFINE_DOCUMENT_TYPE(NotesFDF);
    DEFINE_DOCUMENT_TYPE(PostScript);
    DEFINE_DOCUMENT_TYPE(DVI);
}

- (id)init {
    if (self = [super init]) {
        [self setAutosavingDelay:[[NSUserDefaults standardUserDefaults] integerForKey:SKAutosaveIntervalKey]];
    }
    return self;
}

- (void)dealloc {
    [customExportTemplateFiles release];
    [super dealloc];
}

- (NSString *)typeFromFileExtension:(NSString *)fileExtensionOrHFSFileType {
	NSString *type = [super typeFromFileExtension:fileExtensionOrHFSFileType];
    if (SKIsEmbeddedPDFDocumentType(type) || SKIsBarePDFDocumentType(type)) {
        // fix of bug when reading a PDF file on 10.4
        // this is interpreted as SKEmbeddedPDFDocumentType, even though we don't declare that as a readable type
        type = SKPDFDocumentType;
    }
	return type;
}

- (void)addDocument:(NSDocument *)document {
    [super addDocument:document];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentControllerDidAddDocumentNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:document, @"document", nil]];
}

- (void)removeDocument:(NSDocument *)document {
    [super removeDocument:[[document retain] autorelease]];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentControllerDidRemoveDocumentNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:document, @"document", nil]];
}

- (NSString *)typeForContentsOfURL:(NSURL *)inAbsoluteURL error:(NSError **)outError {
    unsigned int headerLength = 5;
    
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
    
    if ([self documentClassForType:type] == NULL) {
        // "open -f" creates a temporary file with a .txt extension, we want to be able to open these file as it can be very handy to e.g. display man pages and pretty printed text file from the command line
        if ([inAbsoluteURL isFileURL]) {
            NSString *fileName = [inAbsoluteURL path];
            NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:fileName];
            NSData *leadingData = [fh readDataOfLength:headerLength];
            if ([leadingData length] >= [pdfHeaderData length] && [pdfHeaderData isEqual:[leadingData subdataWithRange:NSMakeRange(0, [pdfHeaderData length])]]) {
                type = SKPDFDocumentType;
            } else if ([leadingData length] >= [psHeaderData length] && [psHeaderData isEqual:[leadingData subdataWithRange:NSMakeRange(0, [psHeaderData length])]]) {
                type = SKPostScriptDocumentType;
            }
        }
        if (type == nil && outError)
            *outError = error;
    } else if (SKIsNotesFDFDocumentType(type)) {
        // Springer sometimes sends PDF files with an .fdf extension for review, huh?
        NSString *fileName = [inAbsoluteURL path];
        NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:fileName];
        NSData *leadingData = [fh readDataOfLength:headerLength];
        if ([leadingData length] >= [pdfHeaderData length] && [pdfHeaderData isEqual:[leadingData subdataWithRange:NSMakeRange(0, [pdfHeaderData length])]])
            type = SKPDFDocumentType;
    }
    
    return type;
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
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load data from clipboard", @"Error description"), NSLocalizedDescriptionKey, nil]];
    }
    
    return document;
}

- (id)openDocumentWithURLFromPasteboard:(NSPasteboard *)pboard error:(NSError **)outError {
    NSURL *theURL = [NSURL URLFromPasteboardAnyType:pboard];
    id document = nil;
    
    if ([theURL isFileURL]) {
        document = [self openDocumentWithContentsOfURL:theURL display:YES error:outError];
    } else if (theURL) {
        [[SKDownloadController sharedDownloadController] addDownloadForURL:theURL];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoOpenDownloadsWindowKey])
            [[SKDownloadController sharedDownloadController] showWindow:self];
        if (outError)
            *outError = nil;
    } else if (outError) {
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load data from clipboard", @"Error description"), NSLocalizedDescriptionKey, nil]];
    }
    
    return document;
}

- (id)openDocumentWithContentsOfPasteboard:(NSPasteboard *)pboard error:(NSError **)outError {
    id document = [self openDocumentWithImageFromPasteboard:pboard error:outError];
    if (document == nil)
        document = [self openDocumentWithURLFromPasteboard:pboard error:outError];
    return document;
}

- (void)newDocumentFromClipboard:(id)sender {
    NSError *error = nil;
    id document = [self openDocumentWithContentsOfPasteboard:[NSPasteboard generalPasteboard] error:&error];
    
    if (document == nil && error)
        [NSApp presentError:error];
}

- (id)openDocumentWithSetup:(NSDictionary *)setup error:(NSError **)outError {
    id document = nil;
    NSError *error = nil;
    NSURL *fileURL = [[BDAlias aliasWithData:[setup objectForKey:SKDocumentSetupAliasKey]] fileURL];
    if(fileURL == nil && [setup objectForKey:SKDocumentSetupFileNameKey])
        fileURL = [NSURL fileURLWithPath:[setup objectForKey:SKDocumentSetupFileNameKey]];
    if(fileURL && NO == SKFileIsInTrash(fileURL)) {
        if (document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:NO error:&error]) {
            [document makeWindowControllers];
            [document setInitialSetup:setup];
            [document showWindows];
        } else if (outError) {
            *outError = error;
        }
    }
    return document;
}

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError {
    NSString *type = [self typeForContentsOfURL:absoluteURL error:NULL];
    if (SKIsNotesDocumentType(type)) {
        NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
        if ([event eventID] == kAEOpenDocuments && [event descriptorForKeyword:keyAESearchText]) {
            NSString *pdfFile = [[absoluteURL path] stringByReplacingPathExtension:@"pdf"];
            BOOL isDir;
            if ([[NSFileManager defaultManager] fileExistsAtPath:pdfFile isDirectory:&isDir] && isDir == NO)
                absoluteURL = [NSURL fileURLWithPath:pdfFile];
        }
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
        NSEnumerator *pathEnum = [[[SKApplicationController sharedApplicationController] applicationSupportDirectories] objectEnumerator];
        NSString *appSupportPath;
        
        while (appSupportPath = [pathEnum nextObject]) {
            NSString *templatesPath = [appSupportPath stringByAppendingPathComponent:@"Templates"];
            BOOL isDir;
            if ([fm fileExistsAtPath:templatesPath isDirectory:&isDir] && isDir) {
                NSEnumerator *fileEnum = [[fm subpathsAtPath:templatesPath] objectEnumerator];
                NSString *file;
                while (file = [fileEnum nextObject]) {
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

- (void)resetCustomExportTemplateFiles {
    [customExportTemplateFiles release];
    customExportTemplateFiles = nil;
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
