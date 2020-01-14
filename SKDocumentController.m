//
//  SKDocumentController.m
//  Skim
//
//  Created by Christiaan Hofman on 5/21/07.
/*
 This software is Copyright (c) 2007-2020
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
#import "SKNotesDocument.h"
#import "SKDownloadController.h"
#import "SKTemplateManager.h"
#import "SKBookmarkController.h"
#import "SKBookmark.h"
#import <SkimNotes/SkimNotes.h>
#import "SKStringConstants.h"
#import "NSURL_SKExtensions.h"
#import "NSError_SKExtensions.h"
#import "NSWindow_SKExtensions.h"

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
NSString *SKArchiveDocumentType = @"org.gnu.gnu-zip-tar-archive";
NSString *SKFolderDocumentType = @"public.folder";

NSString *SKDocumentSetupAliasKey = @"_BDAlias";
NSString *SKDocumentSetupFileNameKey = @"fileName";
NSString *SKDocumentSetupTabsKey = @"tabs";

NSString *SKDocumentControllerWillRemoveDocumentNotification = @"SKDocumentControllerWillRemoveDocumentNotification";
NSString *SKDocumentControllerDidRemoveDocumentNotification = @"SKDocumentControllerDidRemoveDocumentNotification";
NSString *SKDocumentDidShowNotification = @"SKDocumentDidShowNotification";

NSString *SKDocumentControllerDocumentKey = @"document";

#define SKPasteboardTypePostScript @"com.adobe.encapsulated-postscript"

#define WARNING_LIMIT 10

#if SDK_BEFORE(10_8)
@interface NSDocumentController (SKMountainLionDeclarations)
// this is used in 10.8 and later from the openDocument: action
- (void)beginOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)types completionHandler:(void (^)(NSInteger result))completionHandler;
@end
#endif

#if SDK_BEFORE(10_12)
@interface NSResponder(NSWindowTabbing)
- (IBAction)newWindowForTab:(id)sender;
@end
#endif

@interface NSDocumentController (SKDeprecated)
// we don't want this to be flagged as deprecated, because Apple's replacement using UTIs is too buggy, and there's no replacement for this method
- (NSArray *)fileExtensionsFromType:(NSString *)documentTypeName;
@end

@implementation SKDocumentController

@synthesize openedFile;

- (id)init {
    self = [super init];
    if (self) {
        [self setAutosavingDelay:[[NSUserDefaults standardUserDefaults] doubleForKey:SKAutosaveIntervalKey]];
        openedFile = NO;
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

- (void)beginOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)inTypes completionHandler:(void (^)(NSInteger result))completionHandler {
    [openPanel setCanChooseDirectories:YES];
    [super beginOpenPanel:openPanel forTypes:inTypes completionHandler:completionHandler];
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

- (IBAction)newDocumentFromClipboard:(id)sender {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [self openDocumentWithImageFromPasteboard:pboard completionHandler:^(NSDocument *document1, BOOL documentWasAlreadyOpen1, NSError *error1){
        if (document1 == nil) {
            [self openDocumentWithURLFromPasteboard:pboard showNotes:NO completionHandler:^(NSDocument *document2, BOOL documentWasAlreadyOpen2, NSError *error2){
                if (error2 && [error2 isUserCancelledError] == NO)
                    [self presentError:error2];
            }];
        }
    }];
}

- (void)openDocumentWithImageFromPasteboard:(NSPasteboard *)pboard completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
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
    
    NSDocument *document = nil;
    NSError *error = nil;
    
    if (data && type) {
        document = [self makeUntitledDocumentOfType:type error:&error];
        
        if ([document readFromData:data ofType:type error:&error]) {
            [self addDocument:document];
            [document makeWindowControllers];
            [document showWindows];
        } else {
            document = nil;
        }
    } else {
        error = [NSError readPasteboardErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load data from clipboard", @"Error description")];
    }
    
    if (completionHandler)
        completionHandler(document, NO, error);
}

- (void)openDocumentWithURLFromPasteboard:(NSPasteboard *)pboard showNotes:(BOOL)showNotes completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
    NSArray *theURLs = [NSURL readURLsFromPasteboard:pboard];
    NSURL *theURL = [theURLs count] > 0 ? [theURLs objectAtIndex:0] : nil;
    
    if ([theURL isSkimFileURL])
        theURL = [theURL skimFileURL];
    
    if ([theURL isSkimBookmarkURL]) {
        SKBookmark *bookmark = showNotes ? nil : [[SKBookmarkController sharedBookmarkController] bookmarkForURL:theURL];
        if (bookmark) {
            [self openDocumentWithBookmark:bookmark completionHandler:completionHandler];
        } else if (completionHandler) {
            completionHandler(nil, NO, [NSError readPasteboardErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load data from clipboard", @"Error description")]);
        }
    } else if ([theURL isFileURL]) {
        NSError *error = nil;
        NSString *type = [self typeForContentsOfURL:theURL error:&error];
        Class docClass = [self documentClassForType:type];
        
        if (showNotes == NO || docClass == [SKNotesDocument class]) {
            [self openDocumentWithContentsOfURL:theURL display:YES completionHandler:completionHandler];
        } else if (docClass == [SKMainDocument class]) {
            id document = nil;
            for (document in [self documents]) {
                if ([document respondsToSelector:@selector(sourceFileURL)] && [[document sourceFileURL] isEqual:theURL])
                    break;
            }
            if (document) {
                [document showWindows];
                if (completionHandler)
                    completionHandler(document, YES, nil);
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
                }
                if (completionHandler)
                    completionHandler(document, NO, error);
            }
        }
    } else if (showNotes == NO && theURL) {
        id download = [[SKDownloadController sharedDownloadController] addDownloadForURL:theURL];
        if (completionHandler)
            completionHandler(nil, NO, download ? nil : [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")]);
    } else if (completionHandler) {
        completionHandler(nil, NO, [NSError readPasteboardErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load data from clipboard", @"Error description")]);
    }
}

- (void)openDocumentWithBookmark:(SKBookmark *)bookmark completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
    SKBookmarkType type = [bookmark bookmarkType];
    
    if (type == SKBookmarkTypeSession) {
        
        NSArray *children = [bookmark children];
        NSInteger i = [children count];
        
        __block NSInteger countDown = i;
        __block NSMutableArray *errors = nil;
        __block NSMutableArray *windows = nil;
        __block NSMutableArray *tabInfos = nil;
        
        if (RUNNING_AFTER(10_11)) {
            windows = [[NSMutableArray alloc] init];
            while ([windows count] < (NSUInteger)i)
                [windows addObject:[NSNull null]];
        }
        
        while (i-- > 0) {
            SKBookmark *child = [children objectAtIndex:i];
            
            if (windows) {
                NSString *tabs = [child tabs];
                if (tabs) {
                    if (tabInfos == nil)
                        tabInfos = [[NSMutableArray alloc] init];
                    [tabInfos addObject:[NSArray arrayWithObjects:tabs, [NSNumber numberWithUnsignedInteger:i], nil]];
                }
            }
            
            [self openDocumentWithBookmark:child completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){
                if (windows && [document mainWindow])
                    [windows replaceObjectAtIndex:i withObject:[document mainWindow]];
                if (document == nil && error) {
                    if (errors == nil)
                        errors = [[NSMutableArray alloc] init];
                    [errors addObject:error];
                }
                if (--countDown == 0) {
                    if (tabInfos && [windows count] > 1)
                        [NSWindow addTabs:tabInfos forWindows:windows];
                    SKDESTROY(windows);
                    SKDESTROY(tabInfos);
                    if (completionHandler) {
                        if (errors)
                            completionHandler(nil, NO, [NSError combineErrors:errors maximum:WARNING_LIMIT]);
                        else
                            completionHandler(document, documentWasAlreadyOpen, error);
                    }
                    SKDESTROY(errors);
                }
            }];
        }
        
    } else if (type == SKBookmarkTypeFolder) {
        
        NSArray *bookmarks = [bookmark containingBookmarks];
        if ([bookmarks count] > 0) {
            [self openDocumentWithBookmarks:bookmarks completionHandler:completionHandler];
        } else if (completionHandler) {
            completionHandler(nil, NO, [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")]);
        }
        
    } else {
        
        NSURL *fileURL = [bookmark fileURLToOpen];
        if (fileURL && [fileURL checkResourceIsReachableAndReturnError:NULL] && NO == [fileURL isTrashedFileURL]) {
            BOOL hasSetup = [bookmark hasSetup];
            NSDictionary *setup = nil;
            if (hasSetup)
                setup = [bookmark properties];
            else if ([bookmark pageIndex] != NSNotFound)
                setup = [NSDictionary dictionaryWithObject:[bookmark pageNumber] forKey:@"page"];
            [self openDocumentWithContentsOfURL:fileURL display:hasSetup == NO completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){
                if (document && setup) {
                    if (hasSetup) {
                        if (documentWasAlreadyOpen == NO)
                            [document makeWindowControllers];
                        [document applySetup:setup];
                        [document showWindows];
                    } else {
                        [document applyOptions:setup];
                    }
                }
                if (completionHandler)
                    completionHandler(document, documentWasAlreadyOpen, error);
            }];
        } else if (completionHandler) {
            completionHandler(nil, NO, [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")]);
        }
    }
}

- (BOOL)shouldOpenNumberOfDocuments:(NSUInteger)count {
    if (count > WARNING_LIMIT) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to open %lu documents?", @"Message in alert dialog"), (unsigned long)count]];
        [alert setInformativeText:NSLocalizedString(@"Each document opens in a separate window.", @"Informative text in alert dialog")];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button title")];
        [alert addButtonWithTitle:NSLocalizedString(@"Open", @"Button title")];
        
        return NSAlertFirstButtonReturn == [alert runModal];
    }
    return YES;
}

- (void)openDocumentWithBookmarks:(NSArray *)bookmarks completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
    if ([self shouldOpenNumberOfDocuments:[bookmarks count]]) {
        // bookmarks should not be empty
        __block NSInteger i = [bookmarks count];
        __block NSMutableArray *errors = nil;
        
        for (SKBookmark *bookmark in [bookmarks reverseObjectEnumerator]) {
            [self openDocumentWithBookmark:bookmark completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){
                if (document == nil && error) {
                    if (errors == nil)
                        errors = [[NSMutableArray alloc] init];
                    [errors addObject:error];
                }
                if (--i == 0) {
                    if (completionHandler) {
                        if (errors)
                            completionHandler(nil, NO, [NSError combineErrors:errors maximum:WARNING_LIMIT]);
                        else
                            completionHandler(document, documentWasAlreadyOpen, error);
                    }
                    SKDESTROY(errors);
                }
            }];
        }
    } else if (completionHandler) {
        completionHandler(nil, NO, [NSError userCancelledErrorWithUnderlyingError:nil]);
    }
}

- (NSArray *)fileURLsInFolderAtURL:(NSURL *)folderURL error:(NSError **)outError {
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager]
                                      enumeratorAtURL:folderURL
                                      includingPropertiesForKeys:nil
                                      options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants
                                      errorHandler:nil];
    NSMutableArray *urls = [NSMutableArray array];
    
    for (NSURL *url in dirEnum) {
        if ([self documentClassForContentsOfURL:url])
            [urls addObject:url];
    }
    
    if ([self shouldOpenNumberOfDocuments:[urls count]] == NO) {
        urls = nil;
        if (outError)
            *outError = [NSError userCancelledErrorWithUnderlyingError:nil];
    } else if ([urls count] == 0 && outError) {
        *outError = [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")];
    }
    
    return urls;
}

static inline NSDictionary *optionsFromFragmentAndEvent(NSString *fragment) {
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    for (NSString *fragmentItem in [fragment componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&#"]]) {
        NSUInteger i = [fragmentItem rangeOfString:@"="].location;
        if (i != NSNotFound)
            [options setObject:[[fragmentItem substringFromIndex:i + 1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[[fragmentItem substringToIndex:i] lowercaseString]];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableSearchAfterSpotlighKey] == NO && [options objectForKey:@"search"] == NO) {
        
        NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
        
        if ([event eventID] == kAEOpenDocuments) {
            
            NSString *searchString = [[event descriptorForKeyword:keyAESearchText] stringValue];
            
            if ([searchString length]) {
                
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
                [options setObject:searchString forKey:@"search"];
            }
        }
    }
    return [options count] ? options : nil;
}

- (void)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
    openedFile = YES;
    
    NSString *fragment = [absoluteURL fragment];
    NSDictionary *options = optionsFromFragmentAndEvent(fragment);
    NSString *type = [self typeForContentsOfURL:absoluteURL error:NULL];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    if ([fragment length] > 0)
        absoluteURL = [NSURL fileURLWithPath:[absoluteURL path]];
    
    if ([ws type:type conformsToType:SKFolderDocumentType]) {
        
        NSError *err = nil;
        NSArray *urls = [self fileURLsInFolderAtURL:absoluteURL error:&err];
        
        if ([urls count] > 0) {
            
            __block NSInteger i = [urls count];
            __block NSMutableArray *errors = nil;

            for (NSURL *url in urls) {
                [super openDocumentWithContentsOfURL:url display:displayDocument completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){
                    if (document == nil && error) {
                        if (errors == nil)
                            errors = [[NSMutableArray alloc] init];
                        [errors addObject:error];
                    }
                    if (--i == 0) {
                        if (completionHandler) {
                            if (errors)
                                completionHandler(nil, NO, [NSError combineErrors:errors maximum:WARNING_LIMIT]);
                            else
                                completionHandler(document, documentWasAlreadyOpen, error);
                        }
                        SKDESTROY(errors);
                    }
                }];
            }
            
        } else if (completionHandler) {
            completionHandler(nil, NO, err);
        }
        
    } else {
        
        if ([ws type:type conformsToType:SKNotesDocumentType]) {
            NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
            if ([event eventID] == kAEOpenDocuments && [[[event descriptorForKeyword:keyAESearchText] stringValue] length]) {
                NSURL *pdfURL = [absoluteURL URLReplacingPathExtension:@"pdf"];
                if ([pdfURL checkResourceIsReachableAndReturnError:NULL])
                    absoluteURL = pdfURL;
            }
        }
        
        // don't open a file with a file reference URL, because the system messes those up, they become invalid when you save
        if ([absoluteURL isFileURL])
            absoluteURL = [absoluteURL filePathURL];
        
        [super openDocumentWithContentsOfURL:absoluteURL display:displayDocument completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError * error){
            if (document && options)
                [document applyOptions:options];
            if (completionHandler)
                completionHandler(document, documentWasAlreadyOpen, error);
        }];
    }
}

// By not responding to newWindowForTab: no "+" button is shown in the tab bar
- (BOOL)respondsToSelector:(SEL)aSelector {
    return aSelector != @selector(newWindowForTab:) && [super respondsToSelector:aSelector];
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

#pragma mark Services Support

- (void)openDocumentFromURLOnPboard:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)errorString {
    [self openDocumentWithURLFromPasteboard:pboard showNotes:NO completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){}];
}

- (void)openDocumentFromDataOnPboard:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)errorString {
    [self openDocumentWithImageFromPasteboard:pboard completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){}];
    
}

- (void)openNotesDocumentFromURLOnPboard:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)errorString {
    [self openDocumentWithURLFromPasteboard:pboard showNotes:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){}];
}

@end
