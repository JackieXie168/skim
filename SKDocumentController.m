//
//  SKDocumentController.m
//  Skim
//
//  Created by Christiaan Hofman on 5/21/07.
/*
 This software is Copyright (c) 2007-2014
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
#import "SKAlias.h"
#import "SKMainWindowController.h"
#import "NSError_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "SKNotesDocument.h"
#import "SKTemplateManager.h"

#define SKAutosaveIntervalKey @"SKAutosaveInterval"

#define SKIM_NOTES_KEY @"net_sourceforge_skim-app_notes"

NSString *SKPDFDocumentType = @"com.adobe.pdf";
NSString *SKPDFBundleDocumentType = @"net.sourceforge.skim-app.pdfd";
NSString *SKNotesDocumentType = @"net.sourceforge.skim-app.skimnotes";
NSString *SKNotesTextDocumentType = @"public.plain-text";
NSString *SKNotesRTFDocumentType = @"public.rtf";
NSString *SKNotesRTFDDocumentType = @"com.apple.rtfd";
NSString *SKNotesFDFDocumentType = @"com.adobe.fdf";
NSString *SKPostScriptDocumentType = @"com.adobe.postscript";
NSString *SKEncapsulatedPostScriptDocumentType = @"com.adobe.encapsulated-postscript";
NSString *SKDVIDocumentType = @"org.tug.tex.dvi";
NSString *SKXDVDocumentType = @"org.tug.tex.xdv";
NSString *SKFolderDocumentType = @"public.folder";

NSString *SKDocumentSetupAliasKey = @"_BDAlias";
NSString *SKDocumentSetupFileNameKey = @"fileName";

NSString *SKDocumentControllerWillRemoveDocumentNotification = @"SKDocumentControllerWillRemoveDocumentNotification";
NSString *SKDocumentControllerDidRemoveDocumentNotification = @"SKDocumentControllerDidRemoveDocumentNotification";
NSString *SKDocumentDidShowNotification = @"SKDocumentDidShowNotification";

NSString *SKDocumentControllerDocumentKey = @"document";

#define SKPasteboardTypePostScript @"com.adobe.encapsulated-postscript"

#define WARNING_LIMIT 10

@interface NSDocumentController (SKDeprecated)
// we don't want this to be flagged as deprecated, because Apple's replacement using UTIs is too buggy, and there's no replacement for this method
- (NSArray *)fileExtensionsFromType:(NSString *)documentTypeName;
@end

@implementation SKDocumentController

- (id)init {
    self = [super init];
    if (self) {
        [self setAutosavingDelay:[[NSUserDefaults standardUserDefaults] doubleForKey:SKAutosaveIntervalKey]];
    }
    return self;
}

- (void)removeDocument:(NSDocument *)document {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentControllerWillRemoveDocumentNotification 
            object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:document, SKDocumentControllerDocumentKey, nil]];
    [super removeDocument:document];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentControllerDidRemoveDocumentNotification 
            object:self userInfo:nil];
}


- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions {    
    [openPanel setCanChooseDirectories:YES];
    return [super runModalOpenPanel:openPanel forTypes:extensions];
}

static BOOL isPDFData(NSData *data) {
    static NSData *pdfHeaderData = nil;
    if (nil == pdfHeaderData) {
        char *h = "%PDF-";
        pdfHeaderData = [[NSData alloc] initWithBytes:h length:5];
    }
    return ([data length] >= 5 && NSNotFound != [data rangeOfData:pdfHeaderData options:NSDataSearchAnchored range:NSMakeRange(0, 5)].location);
}

static BOOL isPostScriptData(NSData *data) {
    static NSData *psHeaderData = nil;
    if (nil == psHeaderData) {
        char *h = "%!PS-";
        psHeaderData = [[NSData alloc] initWithBytes:h length:5];
    }
    return ([data length] >= 5 && NSNotFound != [data rangeOfData:psHeaderData options:NSDataSearchAnchored range:NSMakeRange(0, 5)].location);
}

static BOOL isEncapsulatedPostScriptData(NSData *data) {
    static NSData *epsHeaderData = nil;
    if (nil == epsHeaderData) {
        char *h = " EPSF-";
        epsHeaderData = [[NSData alloc] initWithBytes:h length:6];
    }
    return ([data length] >= 20 && NSNotFound != [data rangeOfData:epsHeaderData options:NSDataSearchAnchored range:NSMakeRange(14, 6)].location);
}

- (NSString *)typeForContentsOfURL:(NSURL *)inAbsoluteURL error:(NSError **)outError {
    NSError *error = nil;
    NSString *type = [super typeForContentsOfURL:inAbsoluteURL error:&error];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    if ([ws type:type conformsToType:SKFolderDocumentType] == NO && [self documentClassForType:type] == NULL) {
        // "open -f" creates a temporary file with a .txt extension, we want to be able to open these file as it can be very handy to e.g. display man pages and pretty printed text file from the command line
        if ([inAbsoluteURL isFileURL]) {
            NSData *leadingData = [[NSFileHandle fileHandleForReadingFromURL:inAbsoluteURL error:NULL] readDataOfLength:20];
            if (isPDFData(leadingData))
                type = SKPDFDocumentType;
            else if (isPostScriptData(leadingData))
                type = isEncapsulatedPostScriptData(leadingData) ? SKEncapsulatedPostScriptDocumentType : SKPostScriptDocumentType;
        }
        if (type == nil && outError)
            *outError = error;
    } else if ([ws type:type conformsToType:SKNotesFDFDocumentType]) {
        // Springer sometimes sends PDF files with an .fdf extension for review, huh?
        NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL:inAbsoluteURL error:NULL];
        NSData *leadingData = [fh readDataOfLength:5];
        if (isPDFData(leadingData))
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
    id document = nil;
    NSData *data = nil;
    NSString *type = nil;
    
    if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSPasteboardTypePDF, nil]]) {
        [pboard types];
        data = [pboard dataForType:NSPasteboardTypePDF];
        type = SKPDFDocumentType;
    } else if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:SKPasteboardTypePostScript, nil]]) {
        [pboard types];
        data = [pboard dataForType:SKPasteboardTypePostScript];
        type = isEncapsulatedPostScriptData(data) ? SKEncapsulatedPostScriptDocumentType : SKPostScriptDocumentType;
    } else if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSPasteboardTypeTIFF, nil]]) {
        [pboard types];
        data = convertTIFFDataToPDF([pboard dataForType:NSPasteboardTypeTIFF]);
        type = SKPDFDocumentType;
    } else {
        NSArray *images = [pboard readObjectsForClasses:[NSArray arrayWithObject:[NSImage class]] options:[NSDictionary dictionary]];
        if ([images count] > 0) {
            data = convertTIFFDataToPDF([[images objectAtIndex:0] TIFFRepresentation]);
            type = SKPDFDocumentType;
        }
    }
    
    if (data && type) {
        
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

- (id)openDocumentWithURLFromPasteboard:(NSPasteboard *)pboard showNotes:(BOOL)showNotes error:(NSError **)outError {
    NSArray *theURLs = [NSURL readURLsFromPasteboard:pboard];
    NSURL *theURL = [theURLs count] > 0 ? [theURLs objectAtIndex:0] : nil;
    id document = nil;
    
    if ([theURL isFileURL]) {
        NSError *error = nil;
        NSString *type = [self typeForContentsOfURL:theURL error:&error];
        
        if (showNotes == NO || [[SKNotesDocument readableTypes] containsObject:type]) {
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
                
                if ([[NSWorkspace sharedWorkspace] type:type conformsToType:SKPDFBundleDocumentType]) {
                    NSURL *skimFileURL = [[NSFileManager defaultManager] bundledFileURLWithExtension:@"skim" inPDFBundleAtURL:theURL error:&error];
                    data = skimFileURL ? [NSData dataWithContentsOfURL:skimFileURL options:0 error:&error] : nil;
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
    } else if (showNotes == NO && theURL) {
        document = [[SKDownloadController sharedDownloadController] addDownloadForURL:theURL];
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
        document = [self openDocumentWithURLFromPasteboard:pboard showNotes:NO error:&error];
    if (document == nil && error && [error isUserCancelledError] == NO)
        [self presentError:error];
}

- (id)openDocumentWithSetup:(NSDictionary *)setup error:(NSError **)outError {
    id document = nil;
    NSURL *fileURL = [[SKAlias aliasWithData:[setup objectForKey:SKDocumentSetupAliasKey]] fileURL];
    if (fileURL == nil && [setup objectForKey:SKDocumentSetupFileNameKey])
        fileURL = [NSURL fileURLWithPath:[setup objectForKey:SKDocumentSetupFileNameKey]];
    if (fileURL && [fileURL checkResourceIsReachableAndReturnError:NULL] && NO == [fileURL isTrashedFileURL]) {
        if ((document = [self openDocumentWithContentsOfURL:fileURL display:NO error:outError])) {
            [document applySetup:setup];
            [document showWindows];
        }
    } else if (outError) {
        *outError = [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")];
    }
    return document;
}

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError {
    NSString *fragment = [absoluteURL fragment];
    if ([fragment length] > 0)
        absoluteURL = [NSURL fileURLWithPath:[absoluteURL path]];
    // don't open a file with a file reference URL, because the system messes those up, they become invalid when you save
    if ([absoluteURL isFileURL])
        absoluteURL = [absoluteURL filePathURL];
    
    NSString *type = [self typeForContentsOfURL:absoluteURL error:NULL];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    if ([ws type:type conformsToType:SKNotesDocumentType]) {
        NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
        if ([event eventID] == kAEOpenDocuments && [event descriptorForKeyword:keyAESearchText]) {
            NSURL *pdfURL = [absoluteURL URLReplacingPathExtension:@"pdf"];
            if ([pdfURL checkResourceIsReachableAndReturnError:NULL])
                absoluteURL = pdfURL;
        }
    } else if ([ws type:type conformsToType:SKFolderDocumentType]) {
        NSDocument *doc = nil;
        NSError *error = nil;
        NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager]
                       enumeratorAtURL:absoluteURL
            includingPropertiesForKeys:nil
                               options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants
                          errorHandler:nil];
        NSMutableArray *urls = [NSMutableArray array];
        BOOL failed = NO;
        
        for (NSURL *url in dirEnum) {
            if ([self documentClassForContentsOfURL:url])
                [urls addObject:url];
        }
        
        if ([urls count] > WARNING_LIMIT) {
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
    
    id document = [super openDocumentWithContentsOfURL:absoluteURL display:displayDocument error:outError];
    
    if ([document isPDFDocument] && [fragment length] > 0) {
        for (NSString *fragmentItem in [fragment componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&#"]]) {
            if ([fragmentItem length] > 5 && [fragmentItem compare:@"page=" options:NSAnchoredSearch | NSCaseInsensitiveSearch range:NSMakeRange(0, 5)] == NSOrderedSame) {
                NSInteger page = [[fragmentItem substringFromIndex:5] integerValue];
                if (page > 0)
                    [[document mainWindowController] setPageNumber:page];
            } else if ([fragmentItem length] > 7 && [fragmentItem compare:@"search=" options:NSAnchoredSearch | NSCaseInsensitiveSearch range:NSMakeRange(0, 7)] == NSOrderedSame) {
                NSString *searchString = [[fragmentItem substringFromIndex:7] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
                if ([searchString length] > 0)
                    [[document mainWindowController] displaySearchResultsForString:searchString];
            }
        }
    }
    
    return document;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
    if ([anItem action] == @selector(newDocumentFromClipboard:)) {
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        return [pboard canReadObjectForClasses:[NSArray arrayWithObject:[NSImage class]] options:[NSDictionary dictionary]] ||
               [NSURL canReadURLFromPasteboard:pboard];
    } else if ([[SKDocumentController superclass] instancesRespondToSelector:_cmd]) {
        return [super validateUserInterfaceItem:anItem];
    } else
        return YES;
}

- (NSArray *)fileExtensionsFromType:(NSString *)documentTypeName {
    NSArray *fileExtensions = [super fileExtensionsFromType:documentTypeName];
    if ([fileExtensions count] == 0) {
        NSString *fileExtension = [[SKTemplateManager sharedManager] fileNameExtensionForTemplateType:documentTypeName];
        if (fileExtension)
            fileExtensions = [NSArray arrayWithObject:fileExtension];
	}
    return fileExtensions;
}

- (NSString *)displayNameForType:(NSString *)documentTypeName{
    return [[SKTemplateManager sharedManager] displayNameForTemplateType:documentTypeName] ?: [super displayNameForType:documentTypeName];
}

@end
