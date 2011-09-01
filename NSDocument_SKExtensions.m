//
//  NSDocument_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 5/23/08.
/*
 This software is Copyright (c) 2008-2011
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

#import "NSDocument_SKExtensions.h"
#import "SKApplicationController.h"
#import "SKTemplateParser.h"
#import "NSFileManager_SKExtensions.h"
#import "SKDocumentController.h"
#import "BDAlias.h"
#import "SKInfoWindowController.h"
#import "SKFDFParser.h"
#import "PDFAnnotation_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKTextFieldSheetController.h"
#import "SKBookmarkController.h"
#import "SKBookmark.h"
#import "NSWindowController_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKTemplateManager.h"

#define SKDisableExportAttributesKey @"SKDisableExportAttributes"

NSString *SKDocumentFileURLDidChangeNotification = @"SKDocumentFileURLDidChangeNotification";

@implementation NSDocument (SKExtensions)

+ (BOOL)isPDFDocument { return NO; }

- (SKInteractionMode)systemInteractionMode { return SKNormalMode; }

#pragma mark Document Setup

- (void)saveRecentDocumentInfo {}

- (void)applySetup:(NSDictionary *)setup {}

// these are necessary for the app controller, we may change it there
- (NSDictionary *)currentDocumentSetup {
    NSMutableDictionary *setup = [NSMutableDictionary dictionary];
    NSString *fileName = [[self fileURL] path];
    
    if (fileName) {
        NSData *data = [[BDAlias aliasWithPath:fileName] aliasData];
        
        [setup setObject:fileName forKey:SKDocumentSetupFileNameKey];
        if(data)
            [setup setObject:data forKey:SKDocumentSetupAliasKey];
    }
    
    return setup;
}

#pragma mark Bookmark Actions

enum { SKAddBookmarkTypeBookmark, SKAddBookmarkTypeSetup, SKAddBookmarkTypeSession };

- (void)bookmarkSheetDidEnd:(SKBookmarkSheetController *)controller returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSString *label = [controller stringValue];
        SKBookmark *folder = [controller selectedFolder] ?: [[SKBookmarkController sharedBookmarkController] bookmarkRoot];
        SKBookmark *bookmark = nil;
        switch ((NSInteger)contextInfo) {
            case SKAddBookmarkTypeBookmark:
            {
                NSString *path = [[self fileURL] path];
                PDFPage *page = [self currentPage];
                NSUInteger pageIndex = page ? [page pageIndex] : NSNotFound;
                bookmark = [SKBookmark bookmarkWithPath:path pageIndex:pageIndex label:label];
                break;
            }
            case SKAddBookmarkTypeSetup:
            {
                NSDictionary *setup = [self currentDocumentSetup];
                bookmark = [SKBookmark bookmarkWithSetup:setup label:label];
                break;
            }
            case SKAddBookmarkTypeSession:
            {
                NSArray *setups = [[NSApp orderedDocuments] valueForKey:@"currentDocumentSetup"];
                bookmark = [SKBookmark bookmarkSessionWithSetups:setups label:label];
                break;
            }
            default:
                break;
        }
        if (bookmark)
            [[folder mutableArrayValueForKey:@"children"] addObject:bookmark];
    }
}

- (IBAction)addBookmark:(id)sender {
    SKBookmarkSheetController *bookmarkSheetController = [[[SKBookmarkSheetController alloc] init] autorelease];
	[bookmarkSheetController setStringValue:[self displayName]];
    [bookmarkSheetController beginSheetModalForWindow:[self windowForSheet] 
                                        modalDelegate:self  
                                       didEndSelector:@selector(bookmarkSheetDidEnd:returnCode:contextInfo:) 
                                          contextInfo:(void *)[sender tag]];
}

#pragma mark PDF Document

- (PDFDocument *)pdfDocument { return nil; }

#pragma mark Notes

- (NSArray *)notes { return nil; }

- (NSData *)notesData {
    NSArray *array = [[self notes] valueForKey:@"SkimNoteProperties"];
    return array ? [NSKeyedArchiver archivedDataWithRootObject:array] : nil;
}

- (NSString *)notesStringForTemplateType:(NSString *)typeName {
    NSString *string = nil;
    if ([[SKTemplateManager sharedManager] isRichTextTemplateType:typeName] == NO) {
        NSString *templatePath = [[SKTemplateManager sharedManager] pathForTemplateType:typeName];
        NSError *error = nil;
        NSString *templateString = [[NSString alloc] initWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:&error];
        string = [SKTemplateParser stringByParsingTemplateString:templateString usingObject:self];
        [templateString release];
    }
    return string;
}

- (NSData *)notesDataForTemplateType:(NSString *)typeName {
    NSData *data = nil;
    if ([[SKTemplateManager sharedManager] isRichTextTemplateType:typeName]) {
        NSString *templatePath = [[SKTemplateManager sharedManager] pathForTemplateType:typeName];
        NSDictionary *docAttributes = nil;
        NSError *error = nil;
        NSAttributedString *templateAttrString = [[NSAttributedString alloc] initWithPath:templatePath documentAttributes:&docAttributes];
        NSAttributedString *attrString = [SKTemplateParser attributedStringByParsingTemplateAttributedString:templateAttrString usingObject:self];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableExportAttributesKey] == NO) {
            NSMutableDictionary *mutableAttributes = [[docAttributes mutableCopy] autorelease];
            [mutableAttributes addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:NSFullUserName(), NSAuthorDocumentAttribute, [NSDate date], NSCreationTimeDocumentAttribute, [[[[self fileURL] path] lastPathComponent] stringByDeletingPathExtension], NSTitleDocumentAttribute, nil]];
            docAttributes = mutableAttributes;
        }
        data = [attrString dataFromRange:NSMakeRange(0, [attrString length]) documentAttributes:docAttributes error:&error];
        [templateAttrString release];
    } else {
        data = [[self notesStringForTemplateType:typeName] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    }
    return data;
}

- (NSFileWrapper *)notesFileWrapperForTemplateType:(NSString *)typeName {
    NSFileWrapper *fileWrapper = nil;
    if ([[SKTemplateManager sharedManager] isPackageTemplateType:typeName]) {
        NSString *templatePath = [[SKTemplateManager sharedManager] pathForTemplateType:typeName];
        NSDictionary *docAttributes = nil;
        NSAttributedString *templateAttrString = [[NSAttributedString alloc] initWithPath:templatePath documentAttributes:&docAttributes];
        NSAttributedString *attrString = [SKTemplateParser attributedStringByParsingTemplateAttributedString:templateAttrString usingObject:self];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableExportAttributesKey] == NO) {
            NSMutableDictionary *mutableAttributes = [[docAttributes mutableCopy] autorelease];
            [mutableAttributes addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:NSFullUserName(), NSAuthorDocumentAttribute, [NSDate date], NSCreationTimeDocumentAttribute, [[[[self fileURL] path] lastPathComponent] stringByDeletingPathExtension], NSTitleDocumentAttribute, nil]];
            docAttributes = mutableAttributes;
        }
        fileWrapper = [attrString RTFDFileWrapperFromRange:NSMakeRange(0, [attrString length]) documentAttributes:docAttributes];
        [templateAttrString release];
    }
    return fileWrapper;
}

- (NSString *)notesString {
    return [self notesStringForTemplateType:@"notesTemplate.txt"];
}

- (NSData *)notesRTFData {
    return [self notesDataForTemplateType:@"notesTemplate.rtf"];
}

- (NSFileWrapper *)notesRTFDFileWrapper {
    return [self notesFileWrapperForTemplateType:@"notesTemplate.rtfd"];
}

- (NSData *)notesFDFDataForFile:(NSString *)filename fileIDStrings:(NSArray *)fileIDStrings {
    NSInteger i = 0;
    NSMutableString *string = [NSMutableString stringWithFormat:@"%%FDF-1.2\n%%%C%C%C%C\n", 0xe2, 0xe3, 0xcf, 0xd3];
    NSMutableString *annots = [NSMutableString string];
    for (PDFAnnotation *note in [self notes]) {
        [string appendFormat:@"%ld 0 obj<<%@>>\nendobj\n", (long)(++i), [note fdfString]];
        [annots appendFormat:@"%ld 0 R ", (long)i];
    }
    [string appendFormat:@"%ld 0 obj<<", (long)(++i)];
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
    [string appendFormat:@" %ld 0 R", (long)i];
    [string appendString:@">>\n"];
    [string appendString:@"%%EOF\n"];
    return [string dataUsingEncoding:NSISOLatin1StringEncoding];
}

#pragma mark Scripting

- (NSArray *)pages {
    NSMutableArray *pages = [NSMutableArray array];
    NSInteger i, count = [[self pdfDocument] pageCount];
    for (i = 0; i < count; i++)
        [pages addObject:[[self pdfDocument] pageAtIndex:i]];
    return pages;
}

- (NSUInteger)countOfPages {
    return [[self pdfDocument] pageCount];
}

- (PDFPage *)objectInPagesAtIndex:(NSUInteger)theIndex {
    return [[self pdfDocument] pageAtIndex:theIndex];
}

- (PDFPage *)currentPage { return nil; }

- (void)setCurrentPage:(PDFPage *)page {}

- (id)activeNote { return nil; }

- (NSTextStorage *)richText { return nil; }

- (id)selectionSpecifier { return nil; }

- (NSData *)selectionQDRect { return nil; }

- (id)selectionPage { return nil; }

- (NSDictionary *)pdfViewSettings { return nil; }

- (NSInteger)toolMode { return 0; }

- (NSDictionary *)documentAttributes {
    return [[SKInfoWindowController sharedInstance] infoForDocument:self];
}

- (BOOL)isPDFDocument { return NO; }

- (void)handleRevertScriptCommand:(NSScriptCommand *)command {
    if ([self fileURL] && [[NSFileManager defaultManager] fileExistsAtPath:[[self fileURL] path]]) {
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
    [command setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
    [command setScriptErrorString:@"Notes document does not understand the 'go' command."];
}

- (id)handleFindScriptCommand:(NSScriptCommand *)command {
    [command setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
    [command setScriptErrorString:@"Notes document does not understand the 'find' command."];
    return nil;
}

- (void)handleShowTeXScriptCommand:(NSScriptCommand *)command {
    [command setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
    [command setScriptErrorString:@"Notes document does not understand the 'show TeX file' command."];
}

- (void)handleConvertNotesScriptCommand:(NSScriptCommand *)command {
    [command setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
    [command setScriptErrorString:@"Notes document does not understand the 'convert notes' command."];
}

- (void)handleReadNotesScriptCommand:(NSScriptCommand *)command {
    [command setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
    [command setScriptErrorString:@"Notes document does not understand the 'read notes' command."];
}

@end
