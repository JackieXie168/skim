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
#import "SKDocument.h"
#import "SKDownloadController.h"
#import "NSString_SKExtensions.h"
#import "NSURL_SKExtensions.h"
#import "SKStringConstants.h"
#import "OBUtilities.h"

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

BOOL SKIsPDFDocumentType(NSString *docType) {
    return [docType isEqualToString:SKPDFDocumentTypeName] || [docType isEqualToString:SKPDFDocumentUTI];
}
BOOL SKIsPDFBundleDocumentType(NSString *docType) {
    return [docType isEqualToString:SKPDFBundleDocumentTypeName] || [docType isEqualToString:SKPDFBundleDocumentUTI];
}
BOOL SKIsEmbeddedPDFDocumentType(NSString *docType) {
    return [docType isEqualToString:SKEmbeddedPDFDocumentTypeName] || [docType isEqualToString:SKEmbeddedPDFDocumentUTI];
}
BOOL SKIsBarePDFDocumentType(NSString *docType) {
    return [docType isEqualToString:SKBarePDFDocumentTypeName] || [docType isEqualToString:SKBarePDFDocumentUTI];
}
BOOL SKIsNotesDocumentType(NSString *docType) {
    return [docType isEqualToString:SKNotesDocumentTypeName] || [docType isEqualToString:SKNotesDocumentUTI];
}
BOOL SKIsNotesTextDocumentType(NSString *docType) {
    return [docType isEqualToString:SKNotesTextDocumentTypeName] || [docType isEqualToString:SKTextDocumentUTI];
}
BOOL SKIsNotesRTFDocumentType(NSString *docType) {
    return [docType isEqualToString:SKNotesRTFDocumentTypeName] || [docType isEqualToString:SKRTFDocumentUTI];
}
BOOL SKIsNotesRTFDDocumentType(NSString *docType) {
    return [docType isEqualToString:SKNotesRTFDDocumentTypeName] || [docType isEqualToString:SKRTFDDocumentUTI];
}
BOOL SKIsNotesFDFDocumentType(NSString *docType) {
    return [docType isEqualToString:SKNotesFDFDocumentTypeName] || [docType isEqualToString:SKFDFDocumentUTI];
}
BOOL SKIsPostScriptDocumentType(NSString *docType) {
    return [docType isEqualToString:SKPostScriptDocumentTypeName] || [docType isEqualToString:SKPostScriptDocumentUTI];
}
BOOL SKIsDVIDocumentType(NSString *docType) {
    return [docType isEqualToString:SKDVIDocumentTypeName] || [docType isEqualToString:SKDVIDocumentUTI];
}

NSString *SKGetPDFDocumentType(void) {
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SKPDFDocumentTypeName : SKPDFDocumentUTI;
}
NSString *SKGetPDFBundleDocumentType(void) {
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SKPDFBundleDocumentTypeName : SKPDFBundleDocumentUTI;
}
NSString *SKGetEmbeddedPDFDocumentType(void) {
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SKEmbeddedPDFDocumentTypeName : SKEmbeddedPDFDocumentUTI;
}
NSString *SKGetBarePDFDocumentType(void) {
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SKBarePDFDocumentTypeName : SKBarePDFDocumentUTI;
}
NSString *SKGetNotesDocumentType(void) {
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SKNotesDocumentTypeName : SKNotesDocumentUTI;
}
NSString *SKGetNotesTextDocumentType(void) {
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SKNotesTextDocumentTypeName : SKTextDocumentUTI;
}
NSString *SKGetNotesRTFDocumentType(void) {
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SKNotesRTFDocumentTypeName : SKRTFDocumentUTI;
}
NSString *SKGetNotesRTFDDocumentType(void) {
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SKNotesRTFDDocumentTypeName : SKRTFDDocumentUTI;
}
NSString *SKGetNotesFDFDocumentType(void) {
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SKNotesFDFDocumentTypeName : SKFDFDocumentUTI;
}
NSString *SKGetPostScriptDocumentType(void) {
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SKPostScriptDocumentTypeName : SKPostScriptDocumentUTI;
}
NSString *SKGetDVIDocumentType(void) {
    return floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4 ? SKDVIDocumentTypeName : SKDVIDocumentUTI;
}

@implementation SKDocumentController

+ (void)initialize {
    OBINITIALIZE;
    
    if (nil == SKPDFDocumentTypeName)
        SKPDFDocumentTypeName = [NSPDFPboardType copy];
}

- (NSString *)typeFromFileExtension:(NSString *)fileExtensionOrHFSFileType {
	NSString *type = [super typeFromFileExtension:fileExtensionOrHFSFileType];
    if (SKIsEmbeddedPDFDocumentType(type) || SKIsBarePDFDocumentType(type)) {
        // fix of bug when reading a PDF file on 10.4
        // this is interpreted as SKEmbeddedPDFDocumentType, even though we don't declare that as a readable type
        type = SKGetPDFDocumentType();
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
                type = SKGetPostScriptDocumentType();
            } else if ([leadingData length] >= [psHeaderData length] && [psHeaderData isEqual:[leadingData subdataWithRange:NSMakeRange(0, [psHeaderData length])]]) {
                type = SKGetPostScriptDocumentType();
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

- (id)openDocumentWithContentsOfPasteboard:(NSPasteboard *)pboard typesMask:(int)mask error:(NSError **)outError {
    // allow any filter services to convert to TIFF data if we can't get PDF or PS directly
    pboard = [NSPasteboard pasteboardByFilteringTypesInPasteboard:pboard];
    NSString *pboardType;
    NSURL *theURL = nil;
    id document = nil;
    
    if ((mask & SKImagePboardTypesMask) && (pboardType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSPDFPboardType, NSPostScriptPboardType, NSTIFFPboardType, nil]])) {
        
        NSData *data = [pboard dataForType:pboardType];
        
        // if it's image data, convert to PDF, then explicitly set the pboard type to PDF
        if ([pboardType isEqualToString:NSTIFFPboardType]) {
            data = convertTIFFDataToPDF(data);
            pboardType = NSPDFPboardType;
        }
        
        NSString *type = [pboardType isEqualToString:NSPostScriptPboardType] ? SKGetPostScriptDocumentType() : SKGetPDFDocumentType();
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
        
    } else if ((mask & SKURLPboardTypesMask) && (theURL = [NSURL URLFromPasteboardAnyType:pboard])) {
        
        if ([theURL isFileURL]) {
            document = [self openDocumentWithContentsOfURL:theURL display:YES error:outError];
        } else {
            [[SKDownloadController sharedDownloadController] addDownloadForURL:theURL];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoOpenDownloadsWindowKey])
                [[SKDownloadController sharedDownloadController] showWindow:self];
            if (outError)
                *outError = nil;
        }
        
    } else if (outError) {
        *outError = [NSError errorWithDomain:SKDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to load data from clipboard", @"Error description"), NSLocalizedDescriptionKey, nil]];
    }
    
    return document;
}

- (void)newDocumentFromClipboard:(id)sender {
    NSError *error = nil;
    id document = [self openDocumentWithContentsOfPasteboard:[NSPasteboard generalPasteboard] typesMask:SKImagePboardTypesMask | SKURLPboardTypesMask error:&error];
    
    if (document == nil && error)
        [NSApp presentError:error];
}

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError {
    NSString *type = [self typeForContentsOfURL:absoluteURL error:NULL];
    if (SKIsNotesTextDocumentType(type)) {
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

@end
