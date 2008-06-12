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
#import "SKUtilities.h"
#import "SKApplicationController.h"

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

static NSString *SKPDFDocumentUTI = @"com.adobe.pdf";
static NSString *SKPDFBundleDocumentUTI = @"net.sourceforge.skim-app.pdfd";
static NSString *SKEmbeddedPDFDocumentUTI = @"net.sourceforge.skim-app.embedded.pdf";
static NSString *SKBarePDFDocumentUTI = @"net.sourceforge.skim-app.bare.pdf";
static NSString *SKNotesDocumentUTI = @"net.sourceforge.skim-app.skimnotes";
static NSString *SKTextDocumentUTI = @"public.plain-text";
static NSString *SKRTFDocumentUTI = @"com.apple.rtf";
static NSString *SKRTFDDocumentUTI = @"com.apple.rtfd";
static NSString *SKFDFDocumentUTI = @"com.adobe.fdf"; // I don't know the UTI for fdf, is there one?
static NSString *SKPostScriptDocumentUTI = @"com.adobe.postscript";
static NSString *SKDVIDocumentUTI = @"net.sourceforge.skim-app.dvi"; // I don't know the UTI for dvi, is there one?

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

BOOL SKIsPDFDocumentType(NSString *docType) {
    return SKIsEqualToDocumentType(docType, SKPDFDocumentTypeName, SKPDFDocumentUTI) &&
           NO == SKIsEqualToDocumentType(docType, nil, SKEmbeddedPDFDocumentUTI) &&
           NO == SKIsEqualToDocumentType(docType, nil, SKBarePDFDocumentUTI);
}
BOOL SKIsPDFBundleDocumentType(NSString *docType) {
    return SKIsEqualToDocumentType(docType, SKPDFBundleDocumentTypeName, SKPDFBundleDocumentUTI);
}
BOOL SKIsEmbeddedPDFDocumentType(NSString *docType) {
    return SKIsEqualToDocumentType(docType, SKEmbeddedPDFDocumentTypeName, SKEmbeddedPDFDocumentUTI);
}
BOOL SKIsBarePDFDocumentType(NSString *docType) {
    return SKIsEqualToDocumentType(docType, SKBarePDFDocumentTypeName, SKBarePDFDocumentUTI);
}
BOOL SKIsNotesDocumentType(NSString *docType) {
    return SKIsEqualToDocumentType(docType, SKNotesDocumentTypeName, SKNotesDocumentUTI);
}
BOOL SKIsNotesTextDocumentType(NSString *docType) {
    return SKIsEqualToDocumentType(docType, SKNotesTextDocumentTypeName, SKTextDocumentUTI);
}
BOOL SKIsNotesRTFDocumentType(NSString *docType) {
    return SKIsEqualToDocumentType(docType, SKNotesRTFDocumentTypeName, SKRTFDocumentUTI);
}
BOOL SKIsNotesRTFDDocumentType(NSString *docType) {
    return SKIsEqualToDocumentType(docType, SKNotesRTFDDocumentTypeName, SKRTFDDocumentUTI);
}
BOOL SKIsNotesFDFDocumentType(NSString *docType) {
    return SKIsEqualToDocumentType(docType, SKNotesFDFDocumentTypeName, SKFDFDocumentUTI) &&
           NO == SKIsEqualToDocumentType(docType, nil, SKPDFDocumentUTI);
}
BOOL SKIsPostScriptDocumentType(NSString *docType) {
    return SKIsEqualToDocumentType(docType, SKPostScriptDocumentTypeName, SKPostScriptDocumentUTI);
}
BOOL SKIsDVIDocumentType(NSString *docType) {
    return SKIsEqualToDocumentType(docType, SKDVIDocumentTypeName, SKDVIDocumentUTI);
}

NSString *SKNormalizedDocumentType(NSString *docType) {
    if (SKIsPDFDocumentType(docType))
        return SKPDFDocumentType;
    else if (SKIsPDFBundleDocumentType(docType))
        return SKPDFBundleDocumentType;
    else if (SKIsEmbeddedPDFDocumentType(docType))
        return SKEmbeddedPDFDocumentType;
    else if (SKIsBarePDFDocumentType(docType))
        return SKBarePDFDocumentType;
    else if (SKIsNotesDocumentType(docType))
        return SKNotesDocumentType;
    else if (SKIsNotesTextDocumentType(docType))
        return SKNotesTextDocumentType;
    else if (SKIsNotesRTFDocumentType(docType))
        return SKNotesRTFDocumentType;
    else if (SKIsNotesRTFDDocumentType(docType))
        return SKNotesRTFDDocumentType;
    else if (SKIsNotesFDFDocumentType(docType))
        return SKNotesFDFDocumentType;
    else if (SKIsPostScriptDocumentType(docType))
        return SKPostScriptDocumentType;
    else if (SKIsDVIDocumentType(docType))
        return SKDVIDocumentType;
    else
        return SKPDFDocumentType;
}

@implementation SKDocumentController

+ (void)initialize {
    OBINITIALIZE;
    
    SKPDFDocumentTypeName = [NSPDFPboardType copy];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4) {
        SKPDFDocumentType = SKPDFDocumentTypeName;
        SKPDFBundleDocumentType = SKPDFBundleDocumentTypeName;
        SKEmbeddedPDFDocumentType = SKEmbeddedPDFDocumentTypeName;
        SKBarePDFDocumentType = SKBarePDFDocumentTypeName;
        SKNotesDocumentType = SKNotesDocumentTypeName;
        SKNotesTextDocumentType = SKNotesTextDocumentTypeName;
        SKNotesRTFDocumentType = SKNotesRTFDocumentTypeName;
        SKNotesRTFDDocumentType = SKNotesRTFDDocumentTypeName;
        SKNotesFDFDocumentType = SKNotesFDFDocumentTypeName;
        SKPostScriptDocumentType = SKPostScriptDocumentTypeName;
        SKDVIDocumentType = SKDVIDocumentTypeName;
    } else {
        SKPDFDocumentType = SKPDFDocumentUTI;
        SKPDFBundleDocumentType = SKPDFBundleDocumentUTI;
        SKEmbeddedPDFDocumentType = SKEmbeddedPDFDocumentUTI;
        SKBarePDFDocumentType = SKBarePDFDocumentUTI;
        SKNotesDocumentType = SKNotesDocumentUTI;
        SKNotesTextDocumentType = SKTextDocumentUTI;
        SKNotesRTFDocumentType = SKRTFDocumentUTI;
        SKNotesRTFDDocumentType = SKRTFDDocumentUTI;
        SKNotesFDFDocumentType = SKFDFDocumentUTI;
        SKPostScriptDocumentType = SKPostScriptDocumentUTI;
        SKDVIDocumentType = SKDVIDocumentUTI;
    }
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
        NSMutableSet *templateFiles = [NSMutableSet set];
        NSEnumerator *pathEnum = [[[NSApp delegate] applicationSupportDirectories] objectEnumerator];
        NSString *appSupportPath;
        
        while (appSupportPath = [pathEnum nextObject]) {
            NSString *templatesPath = [appSupportPath stringByAppendingPathComponent:@"Templates"];
            BOOL isDir;
            if ([fm fileExistsAtPath:templatesPath isDirectory:&isDir] && isDir) {
                NSEnumerator *fileEnum = [[fm subpathsAtPath:templatesPath] objectEnumerator];
                NSString *file;
                while (file = [fileEnum nextObject]) {
                    if ([file hasPrefix:@"."] == NO)
                        [templateFiles addObject:file];
                }
            }
        }
        [templateFiles minusSet:[NSSet setWithObjects:@"notesTemplate.txt", @"notesTemplate.rtf", @"notesTemplate.rtfd", nil]];
        customExportTemplateFiles = [[[templateFiles allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] copy];
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
