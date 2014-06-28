//
//  SKPDFSynchronizer.m
//  Skim
//
//  Created by Christiaan Hofman on 4/21/07.
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

#import "SKPDFSynchronizer.h"
#import <libkern/OSAtomic.h>
#import "SKPDFSyncRecord.h"
#import "NSCharacterSet_SKExtensions.h"
#import "NSScanner_SKExtensions.h"
#import <CoreFoundation/CoreFoundation.h>
#import "NSFileManager_SKExtensions.h"

#define PDFSYNC_TO_PDF(coord) ((CGFloat)coord / 65536.0)

// Offset of coordinates in PDFKit and what pdfsync tells us. Don't know what they are; is this implementation dependent?
static NSPoint pdfOffset = {0.0, 0.0};

#define SKPDFSynchronizerPdfsyncExtension @"pdfsync"
static NSArray *SKPDFSynchronizerTexExtensions = nil;

static BOOL caseInsensitiveStringEqual(const void *item1, const void *item2, NSUInteger (*size)(const void *item));
static NSUInteger caseInsensitiveStringHash(const void *item, NSUInteger (*size)(const void *item));

#pragma mark -

@implementation SKPDFSynchronizer

@synthesize delegate;
@dynamic fileName, shouldKeepRunning;

+ (void)initialize {
    SKINITIALIZE;
    SKPDFSynchronizerTexExtensions = [[NSArray alloc] initWithObjects:@"tex", @"ltx", @"latex", @"ctx", @"lyx", nil];
}

- (id)init {
    self = [super init];
    if (self) {
        queue = NULL;
        lockQueue = dispatch_queue_create("net.sourceforge.skim-app.lockQueue.SKPDFSynchronizer", NULL);
        
        fileName = nil;
        syncFileName = nil;
        lastModDate = nil;
        isPdfsync = YES;
        
        pages = nil;
        lines = nil;
        
        filenames = nil;
        scanner = NULL;
        
        shouldKeepRunning = 1;
        
        // it is not safe to use the defaultManager on background threads
        fileManager = [[NSFileManager alloc] init];
    }
    return self;
}

- (void)dealloc {
    SKDISPATCHDESTROY(queue);
    SKDISPATCHDESTROY(lockQueue);
    SKDESTROY(fileManager);
    SKDESTROY(pages);
    SKDESTROY(lines);
    SKDESTROY(filenames);
    SKDESTROY(fileName);
    SKDESTROY(syncFileName);
    SKDESTROY(lastModDate);
    if (scanner) synctex_scanner_free(scanner);
    scanner = NULL;
    [super dealloc];
}

- (void)terminate {
    // make sure we're not calling our delegate
    delegate = nil;
    // set the stop flag immediately, so any running task may stop in its tracks
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&shouldKeepRunning);
}

#pragma mark Thread safe accessors

- (BOOL)shouldKeepRunning {
    OSMemoryBarrier();
    return shouldKeepRunning == 1;
}

- (NSString *)fileName {
    NSString __block *file = nil;
    dispatch_sync(lockQueue, ^{
        file = [[fileName retain] autorelease];
    });
    return file;
}

- (void)setFileName:(NSString *)newFileName {
    // we compare filenames in canonical form throughout, so we need to make sure fileName also is in canonical form
    newFileName = [[newFileName stringByResolvingSymlinksInPath] stringByStandardizingPath];
    dispatch_async(lockQueue, ^{
        if (fileName != newFileName) {
            if ([fileName isEqualToString:newFileName] == NO) {
                SKDESTROY(syncFileName);
                SKDESTROY(lastModDate);
            }
            [fileName release];
            fileName = [newFileName retain];
        }
    });
}

- (NSString *)syncFileName {
    NSString __block *file = nil;
    dispatch_sync(lockQueue, ^{
        file = [[syncFileName retain] autorelease];
    });
    return file;
}

// this should only be used from the server thread
- (void)setSyncFileName:(NSString *)newSyncFileName {
    dispatch_async(lockQueue, ^{
        if (syncFileName != newSyncFileName) {
            [syncFileName release];
            syncFileName = [newSyncFileName retain];
        }
        [lastModDate release];
        lastModDate = [(syncFileName ? [[fileManager attributesOfItemAtPath:syncFileName error:NULL] fileModificationDate] : nil) retain];
    });
}

- (NSDate *)lastModDate {
    NSDate __block *date = nil;
    dispatch_sync(lockQueue, ^{
        date = [[lastModDate retain] autorelease];
    });
    return date;
}

#pragma mark Support

- (NSString *)sourceFileForFileName:(NSString *)file isTeX:(BOOL)isTeX removeQuotes:(BOOL)removeQuotes {
    if (removeQuotes && [file length] > 2 && [file characterAtIndex:0] == '"' && [file characterAtIndex:[file length] - 1] == '"')
        file = [file substringWithRange:NSMakeRange(1, [file length] - 2)];
    if ([file isAbsolutePath] == NO)
        file = [[[self fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent:file];
    if (isTeX && [fileManager fileExistsAtPath:file] == NO && [SKPDFSynchronizerTexExtensions containsObject:[[file pathExtension] lowercaseString]] == NO) {
        for (NSString *extension in SKPDFSynchronizerTexExtensions) {
            NSString *tryFile = [file stringByAppendingPathExtension:extension];
            if ([fileManager fileExistsAtPath:tryFile]) {
                file = tryFile;
                break;
            }
        }
    }
    // the docs say -stringByStandardizingPath uses -stringByResolvingSymlinksInPath, but it doesn't 
    return [[file stringByResolvingSymlinksInPath] stringByStandardizingPath];
}

#pragma mark PDFSync

- (BOOL)loadPdfsyncFile:(NSString *)theFileName {

    if (pages)
        [pages removeAllObjects];
    else
        pages = [[NSMutableArray alloc] init];
    if (lines) {
        [lines removeAllObjects];
    } else {
        NSPointerFunctions *keyPointerFunctions = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
        [keyPointerFunctions setIsEqualFunction:&caseInsensitiveStringEqual];
        [keyPointerFunctions setHashFunction:&caseInsensitiveStringHash];
        NSPointerFunctions *valuePointerFunctions = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
        lines = [[NSMapTable alloc] initWithKeyPointerFunctions:keyPointerFunctions valuePointerFunctions:valuePointerFunctions capacity:0];
    }
    
    [self setSyncFileName:theFileName];
    isPdfsync = YES;
    
    NSString *pdfsyncString = [NSString stringWithContentsOfFile:theFileName encoding:NSUTF8StringEncoding error:NULL];
    BOOL rv = NO;
    
    if ([pdfsyncString length]) {
        
        SKPDFSyncRecords *records = [[SKPDFSyncRecords alloc] init];
        NSMutableArray *files = [[NSMutableArray alloc] init];
        NSString *file;
        NSInteger recordIndex, line, pageIndex;
        double x, y;
        SKPDFSyncRecord *record;
        NSMutableArray *array;
        unichar ch;
        NSScanner *sc = [[NSScanner alloc] initWithString:pdfsyncString];
        NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
        
        [sc setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([sc scanUpToCharactersFromSet:newlines intoString:&file] &&
            [sc scanCharactersFromSet:newlines intoString:NULL]) {
            
            file = [self sourceFileForFileName:file isTeX:YES removeQuotes:YES];
            [files addObject:file];
            
            array = [[NSMutableArray alloc] init];
            [lines setObject:array forKey:file];
            [array release];
            
            // we ignore the version
            if ([sc scanString:@"version" intoString:NULL] && [sc scanInteger:NULL]) {
                
                [sc scanCharactersFromSet:newlines intoString:NULL];
                
                while ([self shouldKeepRunning] && [sc scanCharacter:&ch]) {
                    
                    switch (ch) {
                        case 'l':
                            if ([sc scanInteger:&recordIndex] && [sc scanInteger:&line]) {
                                // we ignore the column
                                [sc scanInteger:NULL];
                                record = [records recordForIndex:recordIndex];
                                [record setFile:file];
                                [record setLine:line];
                                [[lines objectForKey:file] addObject:record];
                            }
                            break;
                        case 'p':
                            // we ignore * and + modifiers
                            if ([sc scanString:@"*" intoString:NULL] == NO)
                                [sc scanString:@"+" intoString:NULL];
                            if ([sc scanInteger:&recordIndex] && [sc scanDouble:&x] && [sc scanDouble:&y]) {
                                record = [records recordForIndex:recordIndex];
                                [record setPageIndex:[pages count] - 1];
                                [record setPoint:NSMakePoint(PDFSYNC_TO_PDF(x) + pdfOffset.x, PDFSYNC_TO_PDF(y) + pdfOffset.y)];
                                [[pages lastObject] addObject:record];
                            }
                            break;
                        case 's':
                            // start of a new page, the scanned integer should always equal [pages count]+1
                            if ([sc scanInteger:&pageIndex] == NO) pageIndex = [pages count] + 1;
                            while (pageIndex > (NSInteger)[pages count]) {
                                array = [[NSMutableArray alloc] init];
                                [pages addObject:array];
                                [array release];
                            }
                            break;
                        case '(':
                            // start of a new source file
                            if ([sc scanUpToCharactersFromSet:newlines intoString:&file]) {
                                file = [self sourceFileForFileName:file isTeX:YES removeQuotes:YES];
                                [files addObject:file];
                                if ([lines objectForKey:file] == nil) {
                                    array = [[NSMutableArray alloc] init];
                                    [lines setObject:array forKey:file];
                                    [array release];
                                }
                            }
                            break;
                        case ')':
                            // closing of a source file
                            if ([files count]) {
                                [files removeLastObject];
                                file = [files lastObject];
                            }
                            break;
                        default:
                            // shouldn't reach
                            break;
                    }
                    
                    [sc scanUpToCharactersFromSet:newlines intoString:NULL];
                    [sc scanCharactersFromSet:newlines intoString:NULL];
                }
                
                NSSortDescriptor *lineSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"line" ascending:YES] autorelease];
                NSSortDescriptor *xSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"x" ascending:YES] autorelease];
                NSSortDescriptor *ySortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"y" ascending:NO] autorelease];
                NSArray *lineSortDescriptors = [NSArray arrayWithObjects:lineSortDescriptor, nil];
                
                for (array in [lines objectEnumerator])
                    [array sortUsingDescriptors:lineSortDescriptors];
                [pages makeObjectsPerformSelector:@selector(sortUsingDescriptors:)
                                       withObject:[NSArray arrayWithObjects:ySortDescriptor, xSortDescriptor, nil]];
                
                rv = [self shouldKeepRunning];
            }
        }
        
        [records release];
        [files release];
        [sc release];
    }
    
    return rv;
}

- (BOOL)pdfsyncFindFileLine:(NSInteger *)linePtr file:(NSString **)filePtr forLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(NSUInteger)pageIndex {
    BOOL rv = NO;
    if (pageIndex < [pages count]) {
        
        SKPDFSyncRecord *record = nil;
        SKPDFSyncRecord *beforeRecord = nil;
        SKPDFSyncRecord *afterRecord = nil;
        NSMutableDictionary *atRecords = [NSMutableDictionary dictionary];
        
        for (record in [pages objectAtIndex:pageIndex]) {
            if ([record line] == 0)
                continue;
            NSPoint p = [record point];
            if (p.y > NSMaxY(rect)) {
                beforeRecord = record;
            } else if (p.y < NSMinY(rect)) {
                afterRecord = record;
                break;
            } else if (p.x < NSMinX(rect)) {
                beforeRecord = record;
            } else if (p.x > NSMaxX(rect)) {
                afterRecord = record;
                break;
            } else {
                [atRecords setObject:record forKey:[NSNumber numberWithDouble:fabs(p.x - point.x)]];
            }
        }
        
        record = nil;
        if ([atRecords count]) {
            NSNumber *nearest = [[[atRecords allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0];
            record = [atRecords objectForKey:nearest];
        } else if (beforeRecord && afterRecord) {
            NSPoint beforePoint = [beforeRecord point];
            NSPoint afterPoint = [afterRecord point];
            if (beforePoint.y - point.y < point.y - afterPoint.y)
                record = beforeRecord;
            else if (beforePoint.y - point.y > point.y - afterPoint.y)
                record = afterRecord;
            else if (beforePoint.x - point.x < point.x - afterPoint.x)
                record = beforeRecord;
            else if (beforePoint.x - point.x > point.x - afterPoint.x)
                record = afterRecord;
            else
                record = beforeRecord;
        } else if (beforeRecord) {
            record = beforeRecord;
        } else if (afterRecord) {
            record = afterRecord;
        }
        
        if (record) {
            *linePtr = [record line];
            *filePtr = [record file];
            rv = YES;
        }
    }
    if (rv == NO)
        NSLog(@"PDFSync was unable to find file and line.");
    return rv;
}

- (BOOL)pdfsyncFindPage:(NSUInteger *)pageIndexPtr location:(NSPoint *)pointPtr forLine:(NSInteger)line inFile:(NSString *)file {
    BOOL rv = NO;
    NSArray *theLines = [lines objectForKey:file];
    if (theLines) {
        
        SKPDFSyncRecord *record = nil;
        SKPDFSyncRecord *beforeRecord = nil;
        SKPDFSyncRecord *afterRecord = nil;
        SKPDFSyncRecord *atRecord = nil;
        
        for (record in theLines) {
            if ([record pageIndex] == NSNotFound)
                continue;
            NSInteger l = [record line];
            if (l < line) {
                beforeRecord = record;
            } else if (l > line) {
                afterRecord = record;
                break;
            } else {
                atRecord = record;
                break;
            }
        }
        
        if (atRecord) {
            record = atRecord;
        } else if (beforeRecord && afterRecord) {
            NSInteger beforeLine = [beforeRecord line];
            NSInteger afterLine = [afterRecord line];
            if (beforeLine - line > line - afterLine)
                record = afterRecord;
            else
                record = beforeRecord;
        } else if (beforeRecord) {
            record = beforeRecord;
        } else if (afterRecord) {
            record = afterRecord;
        }
        
        if (record) {
            *pageIndexPtr = [record pageIndex];
            *pointPtr = [record point];
            rv = YES;
        }
    }
    if (rv == NO)
        NSLog(@"PDFSync was unable to find location and page.");
    return rv;
}

#pragma mark SyncTeX

- (BOOL)loadSynctexFileForFile:(NSString *)theFileName {
    BOOL rv = NO;
    if (scanner)
        synctex_scanner_free(scanner);
    scanner = synctex_scanner_new_with_output_file([theFileName UTF8String], NULL, 1);
    if (scanner) {
        const char *fileRep = synctex_scanner_get_synctex(scanner);
        [self setSyncFileName:[self sourceFileForFileName:[NSString stringWithUTF8String:fileRep] isTeX:NO removeQuotes:NO]];
        if (filenames) {
            NSResetMapTable(filenames);
        } else {
            NSPointerFunctions *keyPointerFunctions = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
            [keyPointerFunctions setIsEqualFunction:&caseInsensitiveStringEqual];
            [keyPointerFunctions setHashFunction:&caseInsensitiveStringHash];
            NSPointerFunctions *valuePointerFunctions = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsMallocMemory | NSPointerFunctionsCStringPersonality | NSPointerFunctionsCopyIn];
            filenames = [[NSMapTable alloc] initWithKeyPointerFunctions:keyPointerFunctions valuePointerFunctions:valuePointerFunctions capacity:0];
        }
        synctex_node_t node = synctex_scanner_input(scanner);
        do {
            if ((fileRep = synctex_scanner_get_name(scanner, synctex_node_tag(node)))) {
                NSMapInsert(filenames, [self sourceFileForFileName:[NSString stringWithUTF8String:fileRep] isTeX:YES removeQuotes:NO], fileRep);
            }
        } while ((node = synctex_node_next(node)));
        isPdfsync = NO;
        rv = [self shouldKeepRunning];
    }
    return rv;
}

- (BOOL)synctexFindFileLine:(NSInteger *)linePtr file:(NSString **)filePtr forLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(NSUInteger)pageIndex {
    BOOL rv = NO;
    if (synctex_edit_query(scanner, (int)pageIndex + 1, point.x, NSMaxY(bounds) - point.y) > 0) {
        synctex_node_t node;
        const char *file;
        while (rv == NO && (node = synctex_next_result(scanner))) {
            if ((file = synctex_scanner_get_name(scanner, synctex_node_tag(node)))) {
                *linePtr = MAX(synctex_node_line(node), 1) - 1;
                *filePtr = [self sourceFileForFileName:[NSString stringWithUTF8String:file] isTeX:YES removeQuotes:NO];
                rv = YES;
            }
        }
    }
    if (rv == NO)
        NSLog(@"SyncTeX was unable to find file and line.");
    return rv;
}

- (BOOL)synctexFindPage:(NSUInteger *)pageIndexPtr location:(NSPoint *)pointPtr forLine:(NSInteger)line inFile:(NSString *)file {
    BOOL rv = NO;
    char *filename = NSMapGet(filenames, file) ?: NSMapGet(filenames, [[file stringByResolvingSymlinksInPath] stringByStandardizingPath]);
    if (filename == NULL) {
        for (NSString *fn in filenames) {
            if ([[fn lastPathComponent] caseInsensitiveCompare:[file lastPathComponent]] == NSOrderedSame) {
                filename = NSMapGet(filenames, file);
                break;
            }
        }
        if (filename == NULL)
            filename = (char *)[[file lastPathComponent] UTF8String];
    }
    if (synctex_display_query(scanner, filename, (int)line + 1, 0) > 0) {
        synctex_node_t node = synctex_next_result(scanner);
        if (node) {
            NSUInteger page = synctex_node_page(node);
            *pageIndexPtr = MAX(page, 1u) - 1;
            *pointPtr = NSMakePoint(synctex_node_visible_h(node), synctex_node_visible_v(node));
            rv = YES;
        }
    }
    if (rv == NO)
        NSLog(@"SyncTeX was unable to find location and page.");
    return rv;
}

#pragma mark Generic

- (BOOL)loadSyncFileIfNeeded {
    NSString *theFileName = [self fileName];
    BOOL rv = NO;
    
    if (theFileName) {
        NSString *theSyncFileName = [self syncFileName];
        
        if (theSyncFileName && [fileManager fileExistsAtPath:theSyncFileName]) {
            NSDate *modDate = [[fileManager attributesOfItemAtPath:theFileName error:NULL] fileModificationDate];
            NSDate *currentModDate = [self lastModDate];
        
            if (currentModDate && [modDate compare:currentModDate] != NSOrderedDescending)
                rv = YES;
            else if (isPdfsync)
                rv = [self loadPdfsyncFile:theSyncFileName];
            else
                rv = [self loadSynctexFileForFile:theFileName];
        } else {
            rv = [self loadSynctexFileForFile:theFileName];
            if (rv == NO) {
                theSyncFileName = [[theFileName stringByDeletingPathExtension] stringByAppendingPathExtension:SKPDFSynchronizerPdfsyncExtension];
                if ([fileManager fileExistsAtPath:theSyncFileName])
                    rv = [self loadPdfsyncFile:theSyncFileName];
            }
        }
    }
    if (rv == NO)
        NSLog(@"Unable to find or load synctex or pdfsync file.");
    return rv;
}

#pragma mark Queue

- (dispatch_queue_t)queue {
    if (queue == NULL)
        queue = dispatch_queue_create("net.sourceforge.skim-app.queue.SKPDFSynchronizer", NULL);
    return queue;
}

#pragma mark Finding API

- (void)findFileAndLineForLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(NSUInteger)pageIndex {
    dispatch_async([self queue], ^{
        if ([self shouldKeepRunning] && [self loadSyncFileIfNeeded]) {
            NSInteger foundLine = 0;
            NSString *foundFile = nil;
            BOOL success = NO;
            
            if (isPdfsync)
                success = [self pdfsyncFindFileLine:&foundLine file:&foundFile forLocation:point inRect:rect pageBounds:bounds atPageIndex:pageIndex];
            else
                success = [self synctexFindFileLine:&foundLine file:&foundFile forLocation:point inRect:rect pageBounds:bounds atPageIndex:pageIndex];
            
            if (success && [self shouldKeepRunning]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate synchronizer:self foundLine:foundLine inFile:foundFile];
                });
            }
        }
    });
}

- (void)findPageAndLocationForLine:(NSInteger)line inFile:(NSString *)file options:(NSInteger)options {
    dispatch_async([self queue], ^{
        if (file && [self shouldKeepRunning] && [self loadSyncFileIfNeeded]) {
            NSUInteger foundPageIndex = NSNotFound;
            NSPoint foundPoint = NSZeroPoint;
            NSInteger foundOptions = options;
            BOOL success = NO;
            NSString *fixedFile = [self sourceFileForFileName:file isTeX:YES removeQuotes:NO];
            
            if (isPdfsync)
                success = [self pdfsyncFindPage:&foundPageIndex location:&foundPoint forLine:line inFile:fixedFile];
            else
                success = [self synctexFindPage:&foundPageIndex location:&foundPoint forLine:line inFile:fixedFile];
            
            if (success && [self shouldKeepRunning]) {
                if (isPdfsync)
                    foundOptions &= ~SKPDFSynchronizerFlippedMask;
                else
                    foundOptions |= SKPDFSynchronizerFlippedMask;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate synchronizer:self foundLocation:foundPoint atPageIndex:foundPageIndex options:foundOptions];
                });
            }
        }
    });
}

@end

#pragma mark -

#define STACK_BUFFER_SIZE 256

static BOOL caseInsensitiveStringEqual(const void *item1, const void *item2, NSUInteger (*size)(const void *item)) {
    return CFStringCompare(item1, item2, kCFCompareCaseInsensitive | kCFCompareNonliteral) == kCFCompareEqualTo;
}

static NSUInteger caseInsensitiveStringHash(const void *item, NSUInteger (*size)(const void *item)) {
    if(item == NULL) return 0;
    
    NSUInteger hash = 0;
    CFAllocatorRef allocator = CFGetAllocator(item);
    CFIndex len = CFStringGetLength(item);
    
    // use a generous length, in case the lowercase changes the number of characters
    UniChar *buffer, stackBuffer[STACK_BUFFER_SIZE];
    if (len + 10 >= STACK_BUFFER_SIZE)
        buffer = (UniChar *)CFAllocatorAllocate(allocator, (len + 10) * sizeof(UniChar), 0);
    else
        buffer = stackBuffer;
    CFStringGetCharacters(item, CFRangeMake(0, len), buffer);
    
    // If we create the string with external characters, CFStringGetCharactersPtr is guaranteed to succeed; since we're going to call CFStringGetCharacters anyway in fastHash if CFStringGetCharactsPtr fails, let's do it now when we lowercase the string
    CFMutableStringRef mutableString = CFStringCreateMutableWithExternalCharactersNoCopy(allocator, buffer, len, len + 10, (buffer != stackBuffer ? allocator : kCFAllocatorNull));
    CFStringLowercase(mutableString, NULL);
    hash = [(id)mutableString hash];
    // if we used the allocator, this should free the buffer for us
    CFRelease(mutableString);
    return hash;
}
