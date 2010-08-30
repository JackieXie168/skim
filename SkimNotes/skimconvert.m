//
//  skimconvert.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 08/28/10.
/*
 This software is Copyright (c) 2010
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

static char *usageStr = "Usage:\n skimconvert embed IN_PDF_FILE [OUT_PDF_FILE]\n skimconvert unembed IN_PDF_FILE [OUT_PDF_FILE]\n skimconvert merge IN_PDF_FILE_1 IN_PDF_FILE_2 [OUT_PDF_FILE]\n skimconvert extract IN_PDF_FILE [OUT_PDF_FILE] [-range START [LENGTH] | -page PAGE1... | -odd | -even]\n skimnotes help [VERB]\n skimnotes version";
static char *versionStr = "SkimConvert command-line client, version 1.0";

static char *embedHelpStr = "skimconvert embed: embed Skim notes in a PDF\nUsage: skimconvert embed IN_PDF_FILE [OUT_PDF_FILE]\n\nWrites PDF with Skim notes from IN_PDF_FILE to PDF with annotations embedded in the PDF to OUT_PDF_FILE.\nWrites to IN_PDF_FILE when OUT_PDF_FILE is not provided.";
static char *unembedHelpStr = "skimconvert unembed: converts annotations embedded in a PDF to Skim notes\nUsage: skimconvert unembed IN_PDF_FILE [OUT_PDF_FILE]\n\nConverts annotations embedded in IN_PDF_FILE to Skim notes and writes the PDF data with notes removed to OUT_PDF_FILE with the Skim notes written to the extended attributes.\nWrites to IN_PDF_FILE when OUT_PDF_FILE is not provided.";
static char *mergeHelpStr = "skimconvert merge: Merges two PDF files with attached Skim notes\nUsage: skimconvert merge IN_PDF_FILE_1 IN_PDF_FILE_2 [OUT_PDF_FILE]\n\nMerges IN_PDF_FILE_1 and IN_PDF_FILE_2 and Skim notes from their extended attributes and writes to OUT_PDF_FILE.\nWrites to IN_PDF_FILE_1 when OUT_PDF_FILE is not provided.";
static char *extractHelpStr = "skimconvert extract: Extracts part of a PDF with attached Skim notes\nUsage: skimconvert extract IN_PDF_FILE [OUT_PDF_FILE] [-range START [LENGTH] | -page PAGE1... | -odd | -even]\n\nExtracts pages from IN_PDF_FILE and attached Skim notes in the pages, given either as a page range or a series of pages, and writes them to OUT_PDF_FILE.\nWrites to IN_PDF_FILE when OUT_PDF_FILE is not provided.";
static char *helpHelpStr = "skimconvert help: get help on the skimconvert tool\nUsage: skimconvert help [VERB]\n\nGet help on the verb VERB.";
static char *versionHelpStr = "skimconvert version: get version of the skimconvert tool\nUsage: skimconvert version\n\nGet the version of the tool and exit.";

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
        NSString *inPath2 = action == SKNActionMerge ? SKNNormalizedPath([args objectAtIndex:3]) : nil;
        NSString *outPath = argc < offset + 4 ? inPath : SKNNormalizedPath([args objectAtIndex:offset + 3]);
        NSURL *inURL = [NSURL fileURLWithPath:inPath];
        NSURL *inURL2 = inPath2 ? [NSURL fileURLWithPath:inPath2] : nil;
        NSURL *outURL = [NSURL fileURLWithPath:outPath];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        
        if ([fm fileExistsAtPath:inPath] == NO || (inPath2 && [fm fileExistsAtPath:inPath2] == NO)) {
            
            error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"PDF file does not exist", NSLocalizedDescriptionKey, nil]];
            
        } else if (action == SKNActionEmbed) {
            
            PDFDocument *pdfDoc = [[[PDFDocument alloc] initWithURL:inURL readSkimNotes:NULL] autorelease];
            
            if (pdfDoc == nil || [pdfDoc isLocked]) {
                
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot create PDF document", NSLocalizedDescriptionKey, nil]];
                
            } else {
                
                BOOL didExist = [fm fileExistsAtPath:outPath];
                
                success = [pdfDoc writeToURL:outURL];
                
                if (success == NO) {
                    error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot write PDF document", NSLocalizedDescriptionKey, nil]];
                } else if (didExist) {
                    [fm writeSkimNotes:nil toExtendedAttributesAtURL:outURL error:NULL];
                }
                
            }
            
        } else if (action == SKNActionUnembed) {
            
            PDFDocument *pdfDoc = [[[PDFDocument alloc] initWithURL:inURL] autorelease];
            
            if (pdfDoc == nil || [pdfDoc isLocked]) {
                
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot create PDF document", NSLocalizedDescriptionKey, nil]];
                
            } else {
                
                NSArray *inNotes = [fm readSkimNotesFromExtendedAttributesAtURL:inURL error:NULL];
                NSMutableArray *notes = [[NSMutableArray alloc] initWithArray:inNotes];
                NSUInteger i, iMax = [pdfDoc pageCount];
                NSSet *convertibleTypes = [NSSet setWithObjects:SKNFreeTextString, SKNTextString, SKNNoteString, SKNCircleString, SKNSquareString, SKNMarkUpString, SKNHighlightString, SKNUnderlineString, SKNStrikeOutString, SKNLineString, SKNInkString, nil];
                
                for (i = 0; i < iMax; i++) {
                    PDFPage *page = [pdfDoc pageAtIndex:i];
                    NSEnumerator *e = [[[[page annotations] copy] autorelease] objectEnumerator];
                    PDFAnnotation *annotation;
                    
                    while (annotation = [e nextObject]) {
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
                            [notes addObject:note];
                            [page removeAnnotation:annotation];
                        }
                    }
                }
                
                if ([notes count] > [inNotes count]) {
                    
                    success = [pdfDoc writeToURL:outURL];
                    
                    if (success == NO) {
                        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot write PDF document", NSLocalizedDescriptionKey, nil]];
                    } else {
                        success = [fm writeSkimNotes:notes toExtendedAttributesAtURL:outURL error:&error];
                    }
                    
                } else if ([outPath caseInsensitiveCompare:inPath] != NSOrderedSame) {
                    
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_4
                    success = [fm copyItemAtPath:inPath toPath:outPath error:NULL];
#else
                    success = [fm copyPath:inPath toPath:outPath handler:nil];
#endif
                    if (success == NO) {
                        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot write PDF document", NSLocalizedDescriptionKey, nil]];
                    } else {
                        NSString *textNotes = [fm readSkimTextNotesFromExtendedAttributesAtURL:inURL error:NULL];
                        NSData *rtfNotesData = [fm readSkimRTFNotesFromExtendedAttributesAtURL:inURL error:NULL];
                        success = [fm writeSkimNotes:notes textNotes:textNotes richTextNotes:rtfNotesData toExtendedAttributesAtURL:outURL error:&error];
                    }
                    
                }
                
            }
            
        } else if (action == SKNActionMerge) {
            
            PDFDocument *pdfDoc1 = [[[PDFDocument alloc] initWithURL:inURL] autorelease];
            PDFDocument *pdfDoc2 = [[[PDFDocument alloc] initWithURL:inURL2] autorelease];
            
            if (pdfDoc1 == nil || pdfDoc2 == nil || [pdfDoc1 isLocked] || [pdfDoc2 isLocked]) {
                
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot create PDF document", NSLocalizedDescriptionKey, nil]];
                
            } else {
                
                NSUInteger i, count1 = [pdfDoc1 pageCount], count2 = [pdfDoc2 pageCount];
                for (i = 0; i < count2; i++)
                    [pdfDoc1 insertPage:[pdfDoc2 pageAtIndex:i] atIndex:i + count1];
                
                NSArray *notes1 = [fm readSkimNotesFromExtendedAttributesAtURL:inURL error:NULL];
                NSArray *notes2 = [fm readSkimNotesFromExtendedAttributesAtURL:inURL2 error:NULL];
                NSMutableArray *notes = [NSMutableArray arrayWithArray:notes1];
                NSEnumerator *e = [notes2 objectEnumerator];
                NSDictionary *note;
                
                while (note = [e nextObject]) {
                    NSMutableDictionary *mutableNote = [note mutableCopy];
                    NSUInteger pageIndex = [[note objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntValue] + count1;
                    [mutableNote setObject:[NSNumber numberWithUnsignedInt:pageIndex] forKey:SKNPDFAnnotationPageIndexKey];
                    [notes addObject:mutableNote];
                    [mutableNote release];
                }
                
                success = [pdfDoc1 writeToURL:outURL];
                
                if (success == NO) {
                    error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot write PDF document", NSLocalizedDescriptionKey, nil]];
                } else {
                    success = [fm writeSkimNotes:notes toExtendedAttributesAtURL:outURL error:&error];
                }
                
            }
            
        } else if (action == SKNActionExtract) {
            
            if (argc < 4 || [[args objectAtIndex:3] hasPrefix:@"-"]) {
                offset = 0;
                outPath = inPath;
                outURL = inURL;
            } else {
                offset = 1;
            }
            
            PDFDocument *pdfDoc = [[[PDFDocument alloc] initWithURL:inURL] autorelease];
            NSUInteger pageCount = [pdfDoc pageCount];
            NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
            
            if (argc < 4 + offset) {
                [indexes addIndexesInRange:NSMakeRange(0, pageCount)];
            } else {
                NSString *option = [args objectAtIndex:offset + 3];
                
                if ([option caseInsensitiveCompare:RANGE_OPTION_STRING] == NSOrderedSame) {
                    NSInteger start = argc < 5 + offset ? 1 : [[args objectAtIndex:offset + 4] intValue];
                    NSInteger length = argc < 6 + offset ? (NSInteger)pageCount - start + 1 : [[args objectAtIndex:offset + 5] intValue];
                    if (start > 0 && length > 0)
                        [indexes addIndexesInRange:NSMakeRange(start - 1, length)];
                } else if ([option caseInsensitiveCompare:PAGE_OPTION_STRING] == NSOrderedSame) {
                    NSInteger i;
                    for (i = offset + 4; i < argc; i++) {
                        NSUInteger page = [[args objectAtIndex:i] intValue];
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
            
            if (pdfDoc == nil || [pdfDoc isLocked]) {
                
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot create PDF document", NSLocalizedDescriptionKey, nil]];
                
            } else if ([indexes count] == 0 || [indexes lastIndex] > pageCount) {
                
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Invalid page range", NSLocalizedDescriptionKey, nil]];
                
            } else {
                
                NSUInteger i = pageCount;
                while (i-- > 0) {
                    if ([indexes containsIndex:i] == NO)
                        [pdfDoc removePageAtIndex:i];
                }
                
                NSArray *inNotes = [fm readSkimNotesFromExtendedAttributesAtURL:inURL error:NULL];
                NSMutableArray *notes = [NSMutableArray array];
                NSEnumerator *e = [inNotes objectEnumerator];
                NSDictionary *note;
                
                while (note = [e nextObject]) {
                    NSUInteger pageIndex = [[note objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntValue];
                    if ([indexes containsIndex:pageIndex]) {
                        NSUInteger newPageIndex = [indexes countOfIndexesInRange:NSMakeRange(0, pageIndex)];
                        if (newPageIndex != pageIndex) {
                            NSMutableDictionary *mutableNote = [note mutableCopy];
                            [mutableNote setObject:[NSNumber numberWithUnsignedInt:newPageIndex] forKey:SKNPDFAnnotationPageIndexKey];
                            [notes addObject:mutableNote];
                            [mutableNote release];
                        } else {
                            [notes addObject:note];
                        }
                    }
                }
                
                success = [pdfDoc writeToURL:outURL];
                
                if (success == NO) {
                    error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot write PDF document", NSLocalizedDescriptionKey, nil]];
                } else {
                    success = [fm writeSkimNotes:notes toExtendedAttributesAtURL:outURL error:&error];
                }
                
            }
            
        }
        
        if (success == NO && error)
            [(NSFileHandle *)[NSFileHandle fileHandleWithStandardError] writeData:[[[error localizedDescription] stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        
    }
    
    [pool release];
    
    return success ? EXIT_SUCCESS : EXIT_FAILURE;
}
