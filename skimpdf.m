//
//  skimpdf.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 08/28/10.
/*
 This software is Copyright (c) 2010-2014
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

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "NSFileManager_SKNExtensions.h"
#import "PDFDocument_SKNExtensions.h"
#import "PDFAnnotation_SKNExtensions.h"
#import "SKNPDFAnnotationNote.h"

static char *usageStr = "Usage:\n"
                        " skimpdf embed IN_PDF_FILE [OUT_PDF_FILE]\n"
                        " skimpdf unembed IN_PDF_FILE [OUT_PDF_FILE]\n"
                        " skimpdf merge IN_PDF_FILE_1 IN_PDF_FILE_2 [OUT_PDF_FILE]\n"
                        " skimpdf extract IN_PDF_FILE [OUT_PDF_FILE] [-range START [LENGTH] | -page PAGE1... | -odd | -even]\n"
                        " skimpdf help [VERB]\n skimpdf version";
static char *versionStr = "SkimPDF command-line client, version 1.1.2";

static char *embedHelpStr = "skimpdf embed: embed Skim notes in a PDF\n"
                            "Usage: skimpdf embed IN_PDF_FILE [OUT_PDF_FILE]\n\n"
                            "Writes PDF with Skim notes from IN_PDF_FILE to PDF with annotations embedded in the PDF to OUT_PDF_FILE.\n"
                            "Writes to IN_PDF_FILE when OUT_PDF_FILE is not provided.";
static char *unembedHelpStr = "skimpdf unembed: converts annotations embedded in a PDF to Skim notes\n"
                             "Usage: skimpdf unembed IN_PDF_FILE [OUT_PDF_FILE]\n\n"
                             "Converts annotations embedded in IN_PDF_FILE to Skim notes and writes the PDF data with notes removed to OUT_PDF_FILE with the Skim notes written to the extended attributes.\n"
                             "Writes to IN_PDF_FILE when OUT_PDF_FILE is not provided.";
static char *mergeHelpStr = "skimpdf merge: Merges two PDF files with attached Skim notes\n"
                            "Usage: skimpdf merge IN_PDF_FILE_1 IN_PDF_FILE_2 [OUT_PDF_FILE]\n\n"
                            "Merges IN_PDF_FILE_1 and IN_PDF_FILE_2 and Skim notes from their extended attributes and writes to OUT_PDF_FILE.\n"
                            "Writes to IN_PDF_FILE_1 when OUT_PDF_FILE is not provided.";
static char *extractHelpStr = "skimpdf extract: Extracts part of a PDF with attached Skim notes\n"
                              "Usage: skimpdf extract IN_PDF_FILE [OUT_PDF_FILE] [-range START [LENGTH] | -page PAGE1... | -odd | -even]\n\n"
                              "Extracts pages from IN_PDF_FILE and attached Skim notes in the pages, given either as a page range or a series of pages, and writes them to OUT_PDF_FILE.\n"
                              "Writes to IN_PDF_FILE when OUT_PDF_FILE is not provided.";
static char *helpHelpStr = "skimpdf help: get help on the skimpdf tool\n"
                           "Usage: skimpdf help [VERB]\n\n"
                           "Get help on the verb VERB.";
static char *versionHelpStr = "skimpdf version: get version of the skimpdf tool\n"
                              "Usage: skimpdf version\n\n"
                              "Get the version of the tool and exit.";

#define ACTION_EMBED_STRING     @"embed"
#define ACTION_UNEMBED_STRING   @"unembed"
#define ACTION_MERGE_STRING     @"merge"
#define ACTION_EXTRACT_STRING   @"extract"
#define ACTION_VERSION_STRING   @"version"
#define ACTION_HELP_STRING      @"help"

#define RANGE_OPTION_STRING @"-range"
#define PAGE_OPTION_STRING  @"-page"
#define ODD_OPTION_STRING   @"-odd"
#define EVEN_OPTION_STRING  @"-even"

#define WRITE_OUT(msg)         fprintf(stdout, "%s\n", msg)
#define WRITE_OUT_VERSION(msg) fprintf(stdout, "%s\n%s\n", msg, versionStr)
#define WRITE_ERROR            fprintf(stderr, "%s\n%s\n", usageStr, versionStr)

#ifndef NSAppKitVersionNumber10_8
    #define NSAppKitVersionNumber10_8 1187
#endif

enum {
    SKNActionUnknown,
    SKNActionEmbed,
    SKNActionUnembed,
    SKNActionMerge,
    SKNActionExtract,
    SKNActionVersion,
    SKNActionHelp
};

static NSInteger SKNActionForName(NSString *actionString) {
    if ([actionString caseInsensitiveCompare:ACTION_EMBED_STRING] == NSOrderedSame)
        return SKNActionEmbed;
    else if ([actionString caseInsensitiveCompare:ACTION_UNEMBED_STRING] == NSOrderedSame)
        return SKNActionUnembed;
    else if ([actionString caseInsensitiveCompare:ACTION_MERGE_STRING] == NSOrderedSame)
        return SKNActionMerge;
    else if ([actionString caseInsensitiveCompare:ACTION_EXTRACT_STRING] == NSOrderedSame)
        return SKNActionExtract;
    else if ([actionString caseInsensitiveCompare:ACTION_VERSION_STRING] == NSOrderedSame)
        return SKNActionVersion;
    else if ([actionString caseInsensitiveCompare:ACTION_HELP_STRING] == NSOrderedSame)
        return SKNActionHelp;
    else
        return SKNActionUnknown;
}

static inline NSString *SKNNormalizedPath(NSString *path) {
    if ([path isAbsolutePath] == NO) {
        NSString *basePath = [[NSFileManager defaultManager] currentDirectoryPath];
        if (basePath)
            path = [basePath stringByAppendingPathComponent:path];
    }
    path = [path stringByStandardizingPath];
    return path;
}

static inline BOOL SKNCopyFileAndNotes(NSString *inPath, NSString *outPath, NSArray *notes, NSError **error) {
    BOOL success = YES;
    
    if ([outPath caseInsensitiveCompare:inPath] != NSOrderedSame) {
        NSFileManager *fm = [NSFileManager defaultManager];
        
        if ([fm fileExistsAtPath:outPath])
            [fm removeItemAtPath:outPath error:NULL];
        
        success = [fm copyItemAtPath:inPath toPath:outPath error:NULL];
        
        if (success) {
            NSURL *inURL = [NSURL fileURLWithPath:inPath];
            NSURL *outURL = [NSURL fileURLWithPath:outPath];
            NSString *textNotes = [fm readSkimTextNotesFromExtendedAttributesAtURL:inURL error:NULL];
            NSData *rtfNotesData = [fm readSkimRTFNotesFromExtendedAttributesAtURL:inURL error:NULL];
            success = [fm writeSkimNotes:notes textNotes:textNotes richTextNotes:rtfNotesData toExtendedAttributesAtURL:outURL error:error];
        } else {
            if (error)
                *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot write PDF document", NSLocalizedDescriptionKey, nil]];
        }
        
    }
    
    return success;
}

static inline BOOL SKNWritePDFAndNotes(PDFDocument *pdfDoc, NSString *outPath, NSArray *notes, NSError **error) {
    BOOL success = NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    char *template = strdup([[NSTemporaryDirectory() stringByAppendingPathComponent:@"skimpdf.XXXXXX"] fileSystemRepresentation]);
    const char *tempPath = mkdtemp(template);
    NSString *tmpDirPath = [fm stringWithFileSystemRepresentation:tempPath length:strlen(tempPath)];
    NSString *tmpPath = [tmpDirPath stringByAppendingPathComponent:[outPath lastPathComponent]];
    free(template);
    
    success = [pdfDoc writeToFile:tmpPath];
    
    if (success) {
        if ([fm fileExistsAtPath:outPath])
            [fm removeItemAtPath:outPath error:NULL];
        
        success = [fm moveItemAtPath:tmpPath toPath:outPath error:NULL];
        
        if (success) {
            if ([notes count]) {
                NSURL *outURL = [NSURL fileURLWithPath:outPath];
                success = [fm writeSkimNotes:notes toExtendedAttributesAtURL:outURL error:error];
            }
        } else if (error) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot write PDF document", NSLocalizedDescriptionKey, nil]];
        }
    } else if (error) {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot write PDF document", NSLocalizedDescriptionKey, nil]];
    }
    
    [fm removeItemAtPath:tmpDirPath error:NULL];
    
    return success;
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
 
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    
    if (argc < 2) {
        WRITE_ERROR;
        [pool release];
        exit(EXIT_FAILURE);
    }
    
    NSInteger action = SKNActionForName([args objectAtIndex:1]);
    
    BOOL success = NO;
    
    if (action == SKNActionUnknown) {
        
        WRITE_ERROR;
        [pool release];
        exit(EXIT_FAILURE);
        
    } else if (action == SKNActionHelp) {
        
        NSInteger helpAction = SKNActionForName([args count] > 2 ? [args objectAtIndex:2] : @"");
        
        switch (helpAction) {
            case SKNActionUnknown:
                WRITE_OUT_VERSION(usageStr);
                break;
            case SKNActionEmbed:
                WRITE_OUT(embedHelpStr);
                break;
            case SKNActionUnembed:
                WRITE_OUT(unembedHelpStr);
                break;
            case SKNActionMerge:
                WRITE_OUT(mergeHelpStr);
                break;
            case SKNActionExtract:
                WRITE_OUT(extractHelpStr);
                break;
            case SKNActionVersion:
                WRITE_OUT(versionHelpStr);
                break;
            case SKNActionHelp:
                WRITE_OUT(helpHelpStr);
                break;
        }
        success = YES;
        
    } else if (action == SKNActionVersion) {
        
        WRITE_OUT(versionStr);
        
    } else {
        
        int offset = (action == SKNActionMerge ? 1 : 0);
        
        if (argc < 3 + offset) {
            WRITE_ERROR;
            [pool release];
            exit(EXIT_FAILURE);
        }
        
        NSString *inPath = SKNNormalizedPath([args objectAtIndex:2]);
        NSURL *inURL = [NSURL fileURLWithPath:inPath];
        PDFDocument *pdfDoc = [[[PDFDocument alloc] initWithURL:inURL] autorelease];
        NSString *inPath2 = nil;
        NSURL *inURL2 = nil;
        PDFDocument *pdfDoc2 = nil;
        NSString *outPath = argc < offset + 4 ? inPath : SKNNormalizedPath([args objectAtIndex:offset + 3]);
        
        if (action == SKNActionMerge) {
            inPath2 = SKNNormalizedPath([args objectAtIndex:3]);
            inURL2 = [NSURL fileURLWithPath:inPath2];
            pdfDoc2 = [[[PDFDocument alloc] initWithURL:inURL2] autorelease];
        }
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        
        if ([fm fileExistsAtPath:inPath] == NO || (inPath2 && [fm fileExistsAtPath:inPath2] == NO)) {
            
            error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"PDF file does not exist", NSLocalizedDescriptionKey, nil]];
            
        } else if (pdfDoc == nil || [pdfDoc allowsPrinting] == NO || (inPath2 && (pdfDoc2 == nil || [pdfDoc2 allowsPrinting] == NO))) {
            
            error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot create PDF document", NSLocalizedDescriptionKey, nil]];
            
        } else if (action == SKNActionEmbed) {
            
            NSArray *notes = [fm readSkimNotesFromExtendedAttributesAtURL:inURL error:NULL];
            
            if ([notes count]) {
                
                [pdfDoc addSkimNotesWithProperties:notes];
                
                success = SKNWritePDFAndNotes(pdfDoc, outPath, nil, &error);
                
            } else {
                
                success = SKNCopyFileAndNotes(inPath, outPath, notes, &error);
                
            }
            
        } else if (action == SKNActionUnembed) {
            
            NSArray *inNotes = [fm readSkimNotesFromExtendedAttributesAtURL:inURL error:NULL];
            NSMutableArray *notes = [NSMutableArray arrayWithArray:inNotes];
            NSUInteger i, iMax = [pdfDoc pageCount];
            NSSet *convertibleTypes = [NSSet setWithObjects:SKNFreeTextString, SKNTextString, SKNNoteString, SKNCircleString, SKNSquareString, SKNMarkUpString, SKNHighlightString, SKNUnderlineString, SKNStrikeOutString, SKNLineString, SKNInkString, nil];
            
            for (i = 0; i < iMax; i++) {
                PDFPage *page = [pdfDoc pageAtIndex:i];
                NSPoint pageOrigin = [page boundsForBox:kPDFDisplayBoxMediaBox].origin;
                NSEnumerator *e = [[[[page annotations] copy] autorelease] objectEnumerator];
                PDFAnnotation *annotation;
                
                while ((annotation = [e nextObject])) {
                    if ([convertibleTypes containsObject:[annotation type]]) {
                        NSDictionary *note = [annotation SkimNoteProperties];
                        if ([[annotation type] isEqualToString:SKNTextString]) {
                            NSMutableDictionary *mutableNote = [[note mutableCopy] autorelease];
                            NSRect bounds = NSRectFromString([note objectForKey:SKNPDFAnnotationBoundsKey]);
                            NSString *contents = [note objectForKey:SKNPDFAnnotationContentsKey];
                            [mutableNote setObject:SKNNoteString forKey:SKNPDFAnnotationTypeKey];
                            bounds.origin.y = NSMaxY(bounds) - SKNPDFAnnotationNoteSize.height;
                            bounds.size = SKNPDFAnnotationNoteSize;
                            [mutableNote setObject:NSStringFromRect(bounds) forKey:SKNPDFAnnotationBoundsKey];
                            if (contents) {
                                NSRange r = [contents rangeOfString:@"  "];
                                if (NSMaxRange(r) < [contents length]) {
                                    NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:[contents substringFromIndex:NSMaxRange(r)]] autorelease];
                                    [mutableNote setObject:attrString forKey:SKNPDFAnnotationTextKey];
                                    [mutableNote setObject:[contents substringToIndex:r.location] forKey:SKNPDFAnnotationContentsKey];
                                }
                            }
                            note = mutableNote;
                        }
                        if (NSEqualPoints(pageOrigin, NSZeroPoint) == NO) {
                            NSMutableDictionary *mutableNote = [[note mutableCopy] autorelease];
                            NSRect bounds = NSRectFromString([note objectForKey:SKNPDFAnnotationBoundsKey]);
                            bounds.origin.x -= pageOrigin.x;
                            bounds.origin.y -= pageOrigin.y;
                            [mutableNote setObject:NSStringFromRect(bounds) forKey:SKNPDFAnnotationBoundsKey];
                            note = mutableNote;
                        }
                        [notes addObject:note];
                        [page removeAnnotation:annotation];
                    }
                }
            }
            
            if ([notes count] > [inNotes count]) {
                
                success = SKNWritePDFAndNotes(pdfDoc, outPath, notes, &error);
                
            } else {
                
                success = SKNCopyFileAndNotes(inPath, outPath, notes, &error);
                
            }
            
        } else if (action == SKNActionMerge) {
            
            NSUInteger i, count = [pdfDoc pageCount], count2 = [pdfDoc2 pageCount];
            for (i = 0; i < count2; i++)
                [pdfDoc insertPage:[pdfDoc2 pageAtIndex:i] atIndex:i + count];
            
            NSArray *notes1 = [fm readSkimNotesFromExtendedAttributesAtURL:inURL error:NULL];
            NSArray *notes2 = [fm readSkimNotesFromExtendedAttributesAtURL:inURL2 error:NULL];
            NSMutableArray *notes = [NSMutableArray arrayWithArray:notes1];
            NSEnumerator *e = [notes2 objectEnumerator];
            NSDictionary *note;
            
            while ((note = [e nextObject])) {
                NSMutableDictionary *mutableNote = [note mutableCopy];
                NSUInteger pageIndex = [[note objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntegerValue] + count;
                [mutableNote setObject:[NSNumber numberWithUnsignedInteger:pageIndex] forKey:SKNPDFAnnotationPageIndexKey];
                [notes addObject:mutableNote];
                [mutableNote release];
            }
            
            success = SKNWritePDFAndNotes(pdfDoc, outPath, notes, &error);
            
        } else if (action == SKNActionExtract) {
            
            if (argc < 4 || [[args objectAtIndex:3] hasPrefix:@"-"]) {
                offset = 0;
                outPath = inPath;
            } else {
                offset = 1;
            }
            
            NSUInteger pageCount = [pdfDoc pageCount];
            NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
            
            if (argc < 4 + offset) {
                [indexes addIndexesInRange:NSMakeRange(0, pageCount)];
            } else {
                NSString *option = [args objectAtIndex:offset + 3];
                
                if ([option caseInsensitiveCompare:RANGE_OPTION_STRING] == NSOrderedSame) {
                    NSInteger start = argc < 5 + offset ? 1 : [[args objectAtIndex:offset + 4] integerValue];
                    if (start < 0)
                        start += pageCount + 1;
                    NSInteger length = argc < 6 + offset ? (NSInteger)pageCount - start + 1 : [[args objectAtIndex:offset + 5] integerValue];
                    if (start > 0 && length > 0)
                        [indexes addIndexesInRange:NSMakeRange(start - 1, length)];
                } else if ([option caseInsensitiveCompare:PAGE_OPTION_STRING] == NSOrderedSame) {
                    NSInteger i;
                    for (i = offset + 4; i < argc; i++) {
                        NSInteger page = [[args objectAtIndex:i] integerValue];
                        if (page < 0)
                            page += pageCount + 1;
                        if (page > 0)
                            [indexes addIndex:page - 1];
                    }
                } else if ([option caseInsensitiveCompare:ODD_OPTION_STRING] == NSOrderedSame) {
                    NSUInteger i;
                    for (i = 0; i < pageCount; i += 2)
                        [indexes addIndex:i];
                } else if ([option caseInsensitiveCompare:EVEN_OPTION_STRING] == NSOrderedSame) {
                    NSUInteger i;
                    for (i = 1; i < pageCount; i += 2)
                        [indexes addIndex:i];
                }
            }
            
            if ([indexes count] == 0 || [indexes lastIndex] > pageCount) {
                
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Invalid page range", NSLocalizedDescriptionKey, nil]];
                
            } else if ([indexes count] < pageCount) {
                
                NSUInteger i = pageCount;
                while (i-- > 0) {
                    if ([indexes containsIndex:i] == NO)
                        [pdfDoc removePageAtIndex:i];
                }
                
                NSArray *inNotes = [fm readSkimNotesFromExtendedAttributesAtURL:inURL error:NULL];
                NSMutableArray *notes = [NSMutableArray array];
                NSEnumerator *e = [inNotes objectEnumerator];
                NSDictionary *note;
                
                while ((note = [e nextObject])) {
                    NSUInteger pageIndex = [[note objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntegerValue];
                    if ([indexes containsIndex:pageIndex]) {
                        NSUInteger newPageIndex = [indexes countOfIndexesInRange:NSMakeRange(0, pageIndex)];
                        if (newPageIndex != pageIndex) {
                            NSMutableDictionary *mutableNote = [note mutableCopy];
                            [mutableNote setObject:[NSNumber numberWithUnsignedInteger:newPageIndex] forKey:SKNPDFAnnotationPageIndexKey];
                            [notes addObject:mutableNote];
                            [mutableNote release];
                        } else {
                            [notes addObject:note];
                        }
                    }
                }
                
                success = SKNWritePDFAndNotes(pdfDoc, outPath, notes, &error);
                
            } else {
                
                NSArray *notes = [fm readSkimNotesFromExtendedAttributesAtURL:inURL error:NULL];
                success = SKNCopyFileAndNotes(inPath, outPath, notes, &error);
                
            }
            
        }
        
        if (success == NO && error)
            [(NSFileHandle *)[NSFileHandle fileHandleWithStandardError] writeData:[[[error localizedDescription] stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        
    }
    
    [pool release];
    
    return success ? EXIT_SUCCESS : EXIT_FAILURE;
}
