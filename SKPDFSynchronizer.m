//
//  SKPDFSynchronizer.m
//  Skim
//
//  Created by Christiaan Hofman on 4/21/07.
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

#import "SKPDFSynchronizer.h"
#import <libkern/OSAtomic.h>
#import "SKPDFSyncRecord.h"
#import "NSCharacterSet_SKExtensions.h"
#import "NSScanner_SKExtensions.h"
#import <Carbon/Carbon.h>
#import "Files_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKCFCallBacks.h"

#define PDFSYNC_TO_PDF(coord) ((float)coord / 65536.0)

static NSString *SKPDFSynchronizerTexExtension = @"tex";
static NSString *SKPDFSynchronizerPdfsyncExtension = @"pdfsync";

#pragma mark -

struct SKServerFlags {
    volatile int32_t shouldKeepRunning;
    volatile int32_t serverReady;
};

@protocol SKPDFSynchronizerServerThread
- (oneway void)stopRunning; 
- (oneway void)serverFindFileAndLineForLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(unsigned int)pageIndex;
- (oneway void)serverFindPageAndLocationForLine:(int)line inFile:(bycopy NSString *)file;
@end

@protocol SKPDFSynchronizerMainThread
- (void)setLocalServer:(byref id)anObject;
- (oneway void)serverFoundLine:(int)line inFile:(bycopy NSString *)file;
- (oneway void)serverFoundLocation:(NSPoint)point atPageIndex:(unsigned int)pageIndex isFlipped:(BOOL)isFlipped;
@end

#pragma mark -

@interface SKPDFSynchronizer (SKPrivate)
- (void)runDOServerForPorts:(NSArray *)ports;
@end

#pragma mark -

@implementation SKPDFSynchronizer

// Offset of coordinates in PDFKit and what pdfsync tells us. Don't know what they are; is this implementation dependent?
static NSPoint pdfOffset = {0.0, 0.0};

- (id)init {
    if (self = [super init]) {
        fileName = nil;
        syncFileName = nil;
        lastModDate = nil;
        isPdfsync = YES;
        
        pages = nil;
        lines = nil;
        
        filenames = nil;
        scanner = NULL;
        
        NSPort *port1 = [NSPort port];
        NSPort *port2 = [NSPort port];
        
        mainThreadConnection = [[NSConnection alloc] initWithReceivePort:port1 sendPort:port2];
        [mainThreadConnection setRootObject:self];
        [mainThreadConnection enableMultipleThreads];
        
        // these will be set when the background thread sets up
        localThreadConnection = nil;
        serverOnMainThread = nil;
        serverOnServerThread = nil;
        
        serverFlags = NSZoneCalloc(NSDefaultMallocZone(), 1, sizeof(struct SKServerFlags));
        serverFlags->shouldKeepRunning = 1;
        serverFlags->serverReady = 0;
        
        stopRunning = NO;
        
        // run a background thread to connect to the remote server
        // this will connect back to the connection we just set up
        [NSThread detachNewThreadSelector:@selector(runDOServerForPorts:) toTarget:self withObject:[NSArray arrayWithObjects:port2, port1, nil]];
        
        // wait till the server is set up
        do {
            if (NO == [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]])
                OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&serverFlags->shouldKeepRunning);
            OSMemoryBarrier();
        } while (serverFlags->serverReady == 0 && serverFlags->shouldKeepRunning == 1);
    }
    return self;
}

- (void)dealloc {
    NSZoneFree(NSDefaultMallocZone(), serverFlags);
    [pages release];
    [lines release];
    [filenames release];
    [fileName release];
    [syncFileName release];
    [lastModDate release];
    [super dealloc];
}

#pragma mark DO server

#pragma mark | Accessor

- (BOOL)shouldKeepRunning {
    OSMemoryBarrier();
    return serverFlags->shouldKeepRunning == 1;
}

#pragma mark | API

- (void)stopDOServer {
    // tell the server thread to stop running, this is also necessary to tickle the server thread so the runloop can finish
    [serverOnServerThread stopRunning];
    // set the stop flag so any running task may finish
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&serverFlags->shouldKeepRunning);
    
    // clean up the connection in the main thread; don't invalidate the ports, since they're still in use
    [mainThreadConnection setRootObject:nil];
    [mainThreadConnection invalidate];
    [mainThreadConnection release];
    mainThreadConnection = nil;
    
    [serverOnServerThread release];
    serverOnServerThread = nil;    
}

#pragma mark | Main thread

- (void)setLocalServer:(byref id)anObject {
    [anObject setProtocolForProxy:@protocol(SKPDFSynchronizerServerThread)];
    serverOnServerThread = [anObject retain];
}

#pragma mark | Server thread

- (oneway void)stopRunning {
    stopRunning = YES;
}

- (void)runDOServerForPorts:(NSArray *)ports {
    // detach a new thread to run this
    NSAssert(localThreadConnection == nil, @"server is already running");
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    @try {
        // we'll use this to communicate between threads on the localhost
        localThreadConnection = [[NSConnection alloc] initWithReceivePort:[ports objectAtIndex:0] sendPort:[ports objectAtIndex:1]];
        if(localThreadConnection == nil)
            @throw @"Unable to get default connection";
        [localThreadConnection setRootObject:self];
        
        serverOnMainThread = [[localThreadConnection rootProxy] retain];
        [serverOnMainThread setProtocolForProxy:@protocol(SKPDFSynchronizerMainThread)];
        // handshake, this sets the proxy at the other side
        [serverOnMainThread setLocalServer:self];
        
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&serverFlags->serverReady);
        
        NSRunLoop *rl = [NSRunLoop currentRunLoop];
        BOOL didRun;
        
        // see http://lists.apple.com/archives/cocoa-dev/2006/Jun/msg01054.html for a helpful explanation of NSRunLoop
        do {
            [pool release];
            pool = [NSAutoreleasePool new];
            didRun = [rl runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (stopRunning == NO && didRun);
    }
    @catch(id exception) {
        NSLog(@"Discarding exception \"%@\" raised in object %@", exception, self);
        // allow the main thread to continue, anyway
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&serverFlags->serverReady);
    }
    
    @finally {
        // clean up the connection in the server thread
        [localThreadConnection setRootObject:nil];
        
        // this frees up the CFMachPorts created in -init
        [[localThreadConnection receivePort] invalidate];
        [[localThreadConnection sendPort] invalidate];
        [localThreadConnection invalidate];
        [localThreadConnection release];
        localThreadConnection = nil;
        
        [serverOnMainThread release];
        serverOnMainThread = nil;    
        
        if (scanner) {
            synctex_scanner_free(scanner);
            scanner = NULL;
        }
        
        [pool release];
    }
}

#pragma mark Finding and Parsing

#pragma mark Accessors

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
}

- (NSString *)fileName {
    NSString *file = nil;
    @synchronized(self) {
        file = [[fileName retain] autorelease];
    }
    return file;
}

- (void)setFileName:(NSString *)newFileName {
    @synchronized(self) {
        if (fileName != newFileName) {
            if ([fileName isEqualToString:newFileName] == NO) {
                [syncFileName release];
                syncFileName = nil;
                [lastModDate release];
                lastModDate = nil;
            }
            [fileName release];
            fileName = [newFileName retain];
        }
    }
}

- (NSString *)syncFileName {
    NSString *file = nil;
    @synchronized(self) {
        file = [[syncFileName retain] autorelease];
    }
    return file;
}

- (void)setSyncFileName:(NSString *)newSyncFileName {
    @synchronized(self) {
        if (syncFileName != newSyncFileName) {
            [syncFileName release];
            syncFileName = [newSyncFileName retain];
        }
        [lastModDate release];
        lastModDate = [(syncFileName ? SKFileModificationDateAtPath(syncFileName) : nil) retain];
    }
}

- (NSDate *)lastModDate {
    NSDate *date = nil;
    @synchronized(self) {
        date = [[lastModDate retain] autorelease];
    }
    return date;
}

#pragma mark | API

- (void)findFileAndLineForLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(unsigned int)pageIndex {
    [serverOnServerThread serverFindFileAndLineForLocation:point inRect:rect pageBounds:bounds atPageIndex:pageIndex];
}

- (void)findPageAndLocationForLine:(int)line inFile:(NSString *)file {
    [serverOnServerThread serverFindPageAndLocationForLine:line inFile:file];
}

#pragma mark | Main thread

- (oneway void)serverFoundLine:(int)line inFile:(bycopy NSString *)file {
    if ([self shouldKeepRunning] && [delegate respondsToSelector:@selector(synchronizer:foundLine:inFile:)])
        [delegate synchronizer:self foundLine:line inFile:file];
}

- (oneway void)serverFoundLocation:(NSPoint)point atPageIndex:(unsigned int)pageIndex isFlipped:(BOOL)isFlipped {
    if ([self shouldKeepRunning] && [delegate respondsToSelector:@selector(synchronizer:foundLocation:atPageIndex:isFlipped:)])
        [delegate synchronizer:self foundLocation:point atPageIndex:pageIndex isFlipped:isFlipped];
}

#pragma mark | Server thread

- (NSString *)sourceFileForFileName:(NSString *)file defaultExtension:(NSString *)extension {
    if (extension && [[file pathExtension] length] == 0)
        file = [file stringByAppendingPathExtension:extension];
    if ([file isAbsolutePath] == NO)
        file = [[[self fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent:file];
    return [file stringByStandardizingPath];
}

- (NSString *)sourceFileForFileSystemRepresentation:(const char *)fileRep defaultExtension:(NSString *)extension {
    NSString *file = (NSString *)CFStringCreateWithFileSystemRepresentation(NULL, fileRep);
    return [self sourceFileForFileName:[file autorelease] defaultExtension:extension];
}

#pragma mark || PDFSync

- (BOOL)loadPdfsyncFile:(NSString *)theFileName {

    if (pages)
        [pages removeAllObjects];
    else
        pages = [[NSMutableArray alloc] init];
    if (lines)
        [lines removeAllObjects];
    else
        lines = (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kSKCaseInsensitiveStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    [self setSyncFileName:theFileName];
    isPdfsync = YES;
    
    NSString *pdfsyncString = [NSString stringWithContentsOfFile:theFileName encoding:NSUTF8StringEncoding error:NULL];
    BOOL rv = NO;
    
    if ([pdfsyncString length]) {
        
        SKPDFSyncRecords *records = [[SKPDFSyncRecords alloc] init];
        NSMutableArray *files = [[NSMutableArray alloc] init];
        NSString *file;
        int recordIndex, line, pageIndex;
        float x, y;
        SKPDFSyncRecord *record;
        NSMutableArray *array;
        unichar ch;
        NSScanner *sc = [[NSScanner alloc] initWithString:pdfsyncString];
        
        [sc setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([sc scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&file] &&
            [sc scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL]) {
            
            file = [self sourceFileForFileName:file defaultExtension:SKPDFSynchronizerTexExtension];
            [files addObject:file];
            
            array = [[NSMutableArray alloc] init];
            [lines setObject:array forKey:file];
            [array release];
            
            // we ignore the version
            if ([sc scanString:@"version" intoString:NULL] && [sc scanInt:NULL]) {
                
                [sc scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
                
                while ([self shouldKeepRunning] && [sc scanCharacter:&ch]) {
                    
                    if (ch == 'l') {
                        if ([sc scanInt:&recordIndex] && [sc scanInt:&line]) {
                            // we ignore the column
                            [sc scanInt:NULL];
                            record = [records recordForIndex:recordIndex];
                            [record setFile:file];
                            [record setLine:line];
                            [[lines objectForKey:file] addObject:record];
                        }
                    } else if (ch == 'p') {
                        // we ignore * and + modifiers
                        [sc scanString:@"*" intoString:NULL] || [sc scanString:@"+" intoString:NULL];
                        if ([sc scanInt:&recordIndex] && [sc scanFloat:&x] && [sc scanFloat:&y]) {
                            record = [records recordForIndex:recordIndex];
                            [record setPageIndex:[pages count] - 1];
                            [record setPoint:NSMakePoint(PDFSYNC_TO_PDF(x) + pdfOffset.x, PDFSYNC_TO_PDF(y) + pdfOffset.y)];
                            [[pages lastObject] addObject:record];
                        }
                    } else if (ch == 's') {
                        // start of a new page, the scanned integer should always equal [pages count]+1
                        if ([sc scanInt:&pageIndex] == NO) pageIndex = [pages count] + 1;
                        while (pageIndex > (int)[pages count]) {
                            array = [[NSMutableArray alloc] init];
                            [pages addObject:array];
                            [array release];
                        }
                    } else if (ch == '(') {
                        // start of a new source file
                        if ([sc scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&file]) {
                            file = [self sourceFileForFileName:file defaultExtension:SKPDFSynchronizerTexExtension];
                            [files addObject:file];
                            if ([lines objectForKey:file] == nil) {
                                array = [[NSMutableArray alloc] init];
                                [lines setObject:array forKey:file];
                                [array release];
                            }
                        }
                    } else if (ch == ')') {
                        // closing of a source file
                        if ([files count]) {
                            [files removeLastObject];
                            file = [files lastObject];
                        }
                    }
                    
                    [sc scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
                    [sc scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
                }
                
                NSSortDescriptor *lineSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"line" ascending:YES] autorelease];
                NSSortDescriptor *xSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"x" ascending:YES] autorelease];
                NSSortDescriptor *ySortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"y" ascending:NO] autorelease];
                
                [[lines allValues] makeObjectsPerformSelector:@selector(sortUsingDescriptors:)
                                                   withObject:[NSArray arrayWithObjects:lineSortDescriptor, nil]];
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

- (BOOL)pdfsyncFindFileLine:(int *)linePtr file:(NSString **)filePtr forLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(unsigned int)pageIndex {
    BOOL rv = NO;
    if (pageIndex < [pages count]) {
        
        SKPDFSyncRecord *record = nil;
        SKPDFSyncRecord *beforeRecord = nil;
        SKPDFSyncRecord *afterRecord = nil;
        NSMutableDictionary *atRecords = [NSMutableDictionary dictionary];
        NSEnumerator *recordEnum = [[pages objectAtIndex:pageIndex] objectEnumerator];
        
        while (record = [recordEnum nextObject]) {
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
                [atRecords setObject:record forKey:[NSNumber numberWithFloat:fabsf(p.x - point.x)]];
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
    return rv;
}

- (BOOL)pdfsyncFindPage:(unsigned int *)pageIndexPtr location:(NSPoint *)pointPtr forLine:(int)line inFile:(NSString *)file {
    BOOL rv = NO;
    if ([lines objectForKey:file]) {
        
        SKPDFSyncRecord *record = nil;
        SKPDFSyncRecord *beforeRecord = nil;
        SKPDFSyncRecord *afterRecord = nil;
        SKPDFSyncRecord *atRecord = nil;
        NSEnumerator *recordEnum = [[lines objectForKey:file] objectEnumerator];
        
        while (record = [recordEnum nextObject]) {
            if ([record pageIndex] == NSNotFound)
                continue;
            int l = [record line];
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
            int beforeLine = [beforeRecord line];
            int afterLine = [afterRecord line];
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
    return rv;
}

#pragma mark || SyncTeX

- (BOOL)loadSynctexFile:(NSString *)theFileName {
    BOOL rv = NO;
    if (scanner)
        synctex_scanner_free(scanner);
    if (scanner = synctex_scanner_new_with_output_file([theFileName fileSystemRepresentation])) {
        [self setSyncFileName:[self sourceFileForFileSystemRepresentation:synctex_scanner_get_synctex(scanner) defaultExtension:nil]];
        if (filenames)
            [filenames removeAllObjects];
        else
            filenames = (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kSKCaseInsensitiveStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        NSString *filename;
        synctex_node_t node = synctex_scanner_input(scanner);
        do {
            filename = [(NSString *)CFStringCreateWithFileSystemRepresentation(NULL, synctex_scanner_get_name(scanner, synctex_node_tag(node))) autorelease];
            [filenames setObject:filename forKey:[self sourceFileForFileName:filename defaultExtension:SKPDFSynchronizerTexExtension]];
        } while (node = synctex_node_next(node));
        isPdfsync = NO;
        rv = [self shouldKeepRunning];
    }
    return rv;
}

- (BOOL)synctexFindFileLine:(int *)linePtr file:(NSString **)filePtr forLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(unsigned int)pageIndex {
    BOOL rv = NO;
    if (synctex_edit_query(scanner, (int)pageIndex + 1, point.x, NSMaxY(bounds) - point.y) > 0) {
        synctex_node_t node = synctex_next_result(scanner);
        if (node) {
            *linePtr = MAX(synctex_node_line(node), 1) - 1;
            *filePtr = [self sourceFileForFileSystemRepresentation:synctex_scanner_get_name(scanner, synctex_node_tag(node)) defaultExtension:SKPDFSynchronizerTexExtension];
            rv = YES;
        }
    }
    return rv;
}

- (BOOL)synctexFindPage:(unsigned int *)pageIndexPtr location:(NSPoint *)pointPtr forLine:(int)line inFile:(NSString *)file {
    BOOL rv = NO;
    NSString *filename = [filenames objectForKey:file] ?: [file lastPathComponent];
    if (synctex_display_query(scanner, [filename fileSystemRepresentation], line + 1, 0) > 0) {
        synctex_node_t node = synctex_next_result(scanner);
        if (node) {
            unsigned int page = synctex_node_page(node);
            *pageIndexPtr = MAX(page, 1u) - 1;
            *pointPtr = NSMakePoint(synctex_node_visible_h(node), synctex_node_visible_v(node));
            rv = YES;
        }
    }
    return rv;
}

#pragma mark || Generic

- (BOOL)loadSyncFileIfNeeded {
    NSString *theFileName = [self fileName];
    BOOL rv = NO;
    
    if (theFileName) {
        NSString *theSyncFileName = [self syncFileName];
        
        if (theSyncFileName && SKFileExistsAtPath(theSyncFileName)) {
            NSDate *modDate = SKFileModificationDateAtPath(theFileName);
            NSDate *currentModDate = [self lastModDate];
        
            if (currentModDate && [modDate compare:currentModDate] != NSOrderedDescending)
                rv = YES;
            else if (isPdfsync)
                rv = [self loadPdfsyncFile:theSyncFileName];
            else
                rv = [self loadSynctexFile:theFileName];
        } else {
            theSyncFileName = [theFileName stringByReplacingPathExtension:SKPDFSynchronizerPdfsyncExtension];
            
            if (SKFileExistsAtPath(theSyncFileName))
                rv = [self loadPdfsyncFile:theSyncFileName];
            else
                rv = [self loadSynctexFile:theFileName];
        }
    }
    return rv;
}

- (oneway void)serverFindFileAndLineForLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(unsigned int)pageIndex {
    if ([self shouldKeepRunning] && [self loadSyncFileIfNeeded]) {
        int foundLine = 0;
        NSString *foundFile = nil;
        BOOL success = NO;
        
        if (isPdfsync)
            success = [self pdfsyncFindFileLine:&foundLine file:&foundFile forLocation:point inRect:rect pageBounds:bounds atPageIndex:pageIndex];
        else
            success = [self synctexFindFileLine:&foundLine file:&foundFile forLocation:point inRect:rect pageBounds:bounds atPageIndex:pageIndex];
        
        if (success && [self shouldKeepRunning])
            [serverOnMainThread serverFoundLine:foundLine inFile:foundFile];
    }
}

- (oneway void)serverFindPageAndLocationForLine:(int)line inFile:(bycopy NSString *)file {
    if (file && [self shouldKeepRunning] && [self loadSyncFileIfNeeded]) {
        unsigned int foundPageIndex = NSNotFound;
        NSPoint foundPoint = NSZeroPoint;
        BOOL success = NO;
        
        file = [self sourceFileForFileName:file defaultExtension:SKPDFSynchronizerTexExtension];
        
        if (isPdfsync)
            success = [self pdfsyncFindPage:&foundPageIndex location:&foundPoint forLine:line inFile:file];
        else
            success = [self synctexFindPage:&foundPageIndex location:&foundPoint forLine:line inFile:file];
        
        if (success && [self shouldKeepRunning])
            [serverOnMainThread serverFoundLocation:foundPoint atPageIndex:foundPageIndex isFlipped:isPdfsync == NO];
    }
}

@end
