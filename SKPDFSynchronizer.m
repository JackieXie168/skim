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
#import "SKPDFSyncRecord.h"
#import "NSCharacterSet_SKExtensions.h"
#import "NSScanner_SKExtensions.h"
#import <Carbon/Carbon.h>
#import "Files_SKExtensions.h"
#import "NSString_SKExtensions.h"

#define SYNC_TO_PDF(coord) ((float)coord / 65536.0)
#define PDF_TO_SYNC(coord) (int)(coord * 65536.0)

static NSString *SKPDFSynchronizerTexExtension = @"tex";
static NSString *SKPDFSynchronizerPdfsyncExtension = @"pdfsync";

static NSString *SKTeXSourceFile(NSString *file, NSString *base) {
    if ([[file pathExtension] caseInsensitiveCompare:SKPDFSynchronizerTexExtension] != NSOrderedSame)
        file = [file stringByAppendingPathExtension:SKPDFSynchronizerTexExtension];
    if ([file hasPrefix:@"/"] == NO)
        file = [base stringByAppendingPathComponent:file];
    return file;
}

static SKPDFSyncRecord *SKRecordForRecordIndex(NSMutableDictionary *records, int recordIndex) {
    NSNumber *recordNumber = [[NSNumber alloc] initWithInt:recordIndex];
    SKPDFSyncRecord *record = [records objectForKey:recordNumber];
    if (record == nil) {
        record = [[SKPDFSyncRecord alloc] initWithRecordIndex:recordIndex];
        [records setObject:record forKey:recordNumber];
        [record release];
    }
    [recordNumber release];
    return record;
}

#pragma mark -

@protocol SKPDFSynchronizerServerThread
- (oneway void)cleanup; 
- (oneway void)serverFindFileLineForLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex;
- (oneway void)serverFindPageLocationForLine:(int)line inFile:(bycopy NSString *)file;
@end

@protocol SKPDFSynchronizerMainThread
- (oneway void)setLocalServer:(byref id)anObject;
- (oneway void)serverFoundLine:(int)line inFile:(bycopy NSString *)file;
- (oneway void)serverFoundLocation:(NSPoint)point atPageIndex:(unsigned int)pageIndex;
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
        pages = [[NSMutableArray alloc] init];
        lines = [[NSMutableDictionary alloc] init];
        fileName = nil;
        syncFileName = nil;
        lastModDate = nil;
        isPdfsync = YES;
#ifdef SYNCTEX_FEATURE
        scanner = NULL;
#endif        
        
        NSPort *port1 = [NSPort port];
        NSPort *port2 = [NSPort port];
        
        mainThreadConnection = [[NSConnection alloc] initWithReceivePort:port1 sendPort:port2];
        [mainThreadConnection setRootObject:self];
        [mainThreadConnection enableMultipleThreads];
        
        // these will be set when the background thread sets up
        localThreadConnection = nil;
        serverOnMainThread = nil;
        serverOnServerThread = nil;
       
        shouldKeepRunning = 1;
        serverReady = 1;
        
        // run a background thread to connect to the remote server
        // this will connect back to the connection we just set up
        [NSThread detachNewThreadSelector:@selector(runDOServerForPorts:) toTarget:self withObject:[NSArray arrayWithObjects:port2, port1, nil]];
        
        // wait till the server is set up
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            OSMemoryBarrier();
        } while (serverReady == 0 && shouldKeepRunning == 1);
    }
    return self;
}

- (void)dealloc {
    [pages release];
    [lines release];
    [fileName release];
    [syncFileName release];
    [lastModDate release];
    [super dealloc];
}

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

- (BOOL)shouldKeepRunning {
    OSMemoryBarrier();
    return shouldKeepRunning == 1;
}

#pragma mark API
#pragma mark | DO server

- (void)stopDOServer {
    // this cleans up the connections, ports and proxies on both sides
    [serverOnServerThread cleanup];
    // we're in the main thread, so set the stop flag
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&shouldKeepRunning);
    
    // clean up the connection in the main thread; don't invalidate the ports, since they're still in use
    [mainThreadConnection setRootObject:nil];
    [mainThreadConnection invalidate];
    [mainThreadConnection release];
    mainThreadConnection = nil;
    
    [serverOnServerThread release];
    serverOnServerThread = nil;    
}

#pragma mark | Finding

- (void)findFileLineForLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex {
    [serverOnServerThread serverFindFileLineForLocation:point inRect:rect atPageIndex:pageIndex];
}

- (void)findPageLocationForLine:(int)line inFile:(NSString *)file {
    [serverOnServerThread serverFindPageLocationForLine:line inFile:file];
}

#pragma mark Main thread
#pragma mark | DO server

- (oneway void)setLocalServer:(byref id)anObject {
    [anObject setProtocolForProxy:@protocol(SKPDFSynchronizerServerThread)];
    serverOnServerThread = [anObject retain];
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&serverReady);
}

#pragma mark | Finding

- (oneway void)serverFoundLine:(int)line inFile:(bycopy NSString *)file {
    if ([self shouldKeepRunning] && [delegate respondsToSelector:@selector(synchronizer:foundLine:inFile:)])
        [delegate synchronizer:self foundLine:line inFile:file];
}

- (oneway void)serverFoundLocation:(NSPoint)point atPageIndex:(unsigned int)pageIndex {
    if ([self shouldKeepRunning] && [delegate respondsToSelector:@selector(synchronizer:foundLocation:atPageIndex:)])
        [delegate synchronizer:self foundLocation:point atPageIndex:pageIndex];
}

#pragma mark Server thread
#pragma mark | DO server

- (oneway void)cleanup {   
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
    
#ifdef SYNCTEX_FEATURE
    if (scanner)
        synctex_scanner_free(scanner);
#endif
}

- (void)runDOServerForPorts:(NSArray *)ports {
    // detach a new thread to run this
    NSAssert(localThreadConnection == nil, @"server is already running");
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&shouldKeepRunning);
    
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
        
        NSRunLoop *rl = [NSRunLoop currentRunLoop];
        BOOL didRun;
        
        // see http://lists.apple.com/archives/cocoa-dev/2006/Jun/msg01054.html for a helpful explanation of NSRunLoop
        do {
            [pool release];
            pool = [NSAutoreleasePool new];
            didRun = [rl runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while ([self shouldKeepRunning] && didRun);
    }
    @catch(id exception) {
        NSLog(@"Discarding exception \"%@\" raised in object %@", exception, self);
        // reset the flag so we can start over; shouldn't be necessary
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&shouldKeepRunning);
        // allow the main thread to continue, anyway
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&serverReady);
    }
    
    @finally {
        [pool release];
    }
}

#pragma mark | Parsing and Finding

- (BOOL)parsePdfsyncFile:(NSString *)theFileName {

    [pages removeAllObjects];
    [lines removeAllObjects];
    
    [self setSyncFileName:theFileName];
    isPdfsync = YES;
    
    NSString *pdfsyncString = [NSString stringWithContentsOfFile:theFileName encoding:NSUTF8StringEncoding error:NULL];
    BOOL rv = NO;
    
    if ([pdfsyncString length]) {
        
        NSString *basePath = [theFileName stringByDeletingLastPathComponent];
        NSMutableDictionary *records = [NSMutableDictionary dictionary];
        NSMutableArray *files = [NSMutableArray array];
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
            
            file = SKTeXSourceFile(file, basePath);
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
                            record = SKRecordForRecordIndex(records, recordIndex);
                            [record setFile:file];
                            [record setLine:line];
                            [[lines objectForKey:file] addObject:record];
                        }
                    } else if (ch == 'p') {
                        // we ignore * and + modifiers
                        [sc scanString:@"*" intoString:NULL] || [sc scanString:@"+" intoString:NULL];
                        if ([sc scanInt:&recordIndex] && [sc scanFloat:&x] && [sc scanFloat:&y]) {
                            record = SKRecordForRecordIndex(records, recordIndex);
                            [record setPageIndex:[pages count] - 1];
                            [record setPoint:NSMakePoint(SYNC_TO_PDF(x) + pdfOffset.x, SYNC_TO_PDF(y) + pdfOffset.y)];
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
                            file = SKTeXSourceFile(file, basePath);
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
        
        [sc release];
    }
    
    return rv;
}

- (BOOL)parseSynctexFile:(NSString *)theFileName {
    BOOL rv = NO;
#ifdef SYNCTEX_FEATURE
    if (scanner)
        synctex_scanner_free(scanner);
    if (scanner = synctex_scanner_new_with_output_file([theFileName fileSystemRepresentation])) {
        [self setSyncFileName:SKPathFromFileSystemRepresentation(synctex_scanner_get_synctex(scanner))];
        isPdfsync = NO;
        rv = YES;
    }
#endif
    return rv;
}

- (BOOL)parseSyncFileIfNeeded {
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
                rv = [self parsePdfsyncFile:theSyncFileName];
            else
                rv = [self parseSynctexFile:theFileName];
        } else {
            theSyncFileName = [theFileName stringByReplacingPathExtension:SKPDFSynchronizerPdfsyncExtension];
            
            if (SKFileExistsAtPath(theSyncFileName))
                rv = [self parsePdfsyncFile:theSyncFileName];
            else
                rv = [self parseSynctexFile:theFileName];
        }
    }
    return rv;
}

- (BOOL)pdfsyncFindFileLine:(int *)line file:(NSString **)file forLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex {
    BOOL rv = NO;
    if (pageIndex < [pages count]) {
        
        SKPDFSyncRecord *record = nil;
        SKPDFSyncRecord *beforeRecord = nil;
        SKPDFSyncRecord *afterRecord = nil;
        NSMutableDictionary *atRecords = [NSMutableDictionary dictionary];
        NSEnumerator *recordEnum = [[pages objectAtIndex:pageIndex] objectEnumerator];
        
        while (record = [recordEnum nextObject]) {
            if ([record line] == -1)
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
            *line = [record line];
            *file = [record file];
            rv = YES;
        }
    }
    return rv;
}

- (BOOL)pdfsyncFindPage:(unsigned int *)pageIndex location:(NSPoint *)point forLine:(int)line inFile:(NSString *)file {
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
            *pageIndex = [record pageIndex];
            *point = [record point];
            rv = YES;
        }
    }
    return rv;
}

- (BOOL)synctexFindFileLine:(int *)line file:(NSString **)file forLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex {
    BOOL rv = NO;
#ifdef SYNCTEX_FEATURE
    if (synctex_edit_query(scanner, (int)pageIndex + 1, PDF_TO_SYNC(point.x), PDF_TO_SYNC(point.y)) > 0) {
        synctex_node_t node = synctex_next_result(scanner);
        if (node) {
            *line = synctex_node_line(node);
            *file = SKTeXSourceFile(SKPathFromFileSystemRepresentation(synctex_scanner_get_name(scanner, synctex_node_tag(node))), [[self fileName] stringByDeletingLastPathComponent]);
            rv = YES;
        }
    }
#endif
    return rv;
}

- (BOOL)synctexFindPage:(unsigned int *)pageIndex location:(NSPoint *)point forLine:(int)line inFile:(NSString *)file {
    BOOL rv = NO;
#ifdef SYNCTEX_FEATURE
    if (synctex_display_query(scanner, [file fileSystemRepresentation], line, 0) > 0) {
        synctex_node_t node = synctex_next_result(scanner);
        if (node) {
            unsigned int page = synctex_node_page(node);
            *pageIndex = page > 0 ? page - 1 : page;
            *point = NSMakePoint(SYNC_TO_PDF(synctex_node_h(node)), SYNC_TO_PDF(synctex_node_v(node)));
            rv = YES;
        }
    }
#endif
    return rv;
}

- (oneway void)serverFindFileLineForLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex {
    int foundLine = -1;
    NSString *foundFile = nil;
    BOOL success = NO;
    
    if ([self shouldKeepRunning] && [self parseSyncFileIfNeeded]) {
        if ([self shouldKeepRunning]) {
            if (isPdfsync)
                success = [self pdfsyncFindFileLine:&foundLine file:&foundFile forLocation:point inRect:rect atPageIndex:pageIndex];
            else
                success = [self synctexFindFileLine:&foundLine file:&foundFile forLocation:point inRect:rect atPageIndex:pageIndex];
        }
    }
    
    if (success && [self shouldKeepRunning])
        [serverOnMainThread serverFoundLine:foundLine inFile:foundFile];
}

- (oneway void)serverFindPageLocationForLine:(int)line inFile:(bycopy NSString *)file {
    unsigned int foundPageIndex = NSNotFound;
    NSPoint foundPoint = NSZeroPoint;
    
    if ([self shouldKeepRunning] && file && [self parseSyncFileIfNeeded] && [lines objectForKey:file]) {
        if ([self shouldKeepRunning]) {
            if (isPdfsync)
                [self pdfsyncFindPage:&foundPageIndex location:&foundPoint forLine:line inFile:file];
            else
                [self synctexFindPage:&foundPageIndex location:&foundPoint forLine:line inFile:file];
        }
    }
    
    if ([self shouldKeepRunning])
        [serverOnMainThread serverFoundLocation:foundPoint atPageIndex:foundPageIndex];
}

@end
