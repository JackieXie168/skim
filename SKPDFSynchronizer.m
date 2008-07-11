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
#import "NSCharacterSet_SKExtensions.h"
#import "NSScanner_SKExtensions.h"
#import <Carbon/Carbon.h>
#import "Files_SKExtensions.h"

#define SYNC_TO_PDF(coord) ((float)coord / 65536.0)
#define PDF_TO_SYNC(coord) (int)(coord * 65536.0)

static NSString *SKPDFSynchronizerRecordIndexKey = @"recordIndex";
static NSString *SKPDFSynchronizerPageKey = @"page";
static NSString *SKPDFSynchronizerXKey = @"x";
static NSString *SKPDFSynchronizerYKey = @"y";
static NSString *SKPDFSynchronizerFileKey = @"file";
static NSString *SKPDFSynchronizerLineKey = @"line";
static NSString *SKPDFSynchronizerTexExtension = @"tex";
static NSString *SKPDFSynchronizerPdfsyncExtension = @"pdfsync";

static NSString *SKTeXSourceFile(NSString *file, NSString *base) {
    if ([[file pathExtension] caseInsensitiveCompare:SKPDFSynchronizerTexExtension] != NSOrderedSame)
        file = [file stringByAppendingPathExtension:SKPDFSynchronizerTexExtension];
    if ([file hasPrefix:@"/"] == NO)
        file = [base stringByAppendingPathComponent:file];
    return file;
}

static NSMutableDictionary *SKRecordForRecordIndex(NSMutableDictionary *records, int recordIndex) {
    NSNumber *recordNumber = [[NSNumber alloc] initWithInt:recordIndex];
    NSMutableDictionary *record = [records objectForKey:recordNumber];
    if (record == nil) {
        record = [[NSMutableDictionary alloc] initWithObjectsAndKeys:recordNumber, SKPDFSynchronizerRecordIndexKey, nil];
        [records setObject:record forKey:recordNumber];
        [record release];
    }
    [recordNumber release];
    return record;
}

#pragma mark -

@protocol SKPDFSynchronizerServerThread
- (oneway void)cleanup; 
- (oneway void)serverFindLineForLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex;
- (oneway void)serverFindPageLocationForLine:(int)line inFile:(bycopy NSString *)file;
@end

@protocol SKPDFSynchronizerMainThread
- (oneway void)setLocalServer:(byref id)anObject;
- (oneway void)serverFoundLine:(int)line inFile:(bycopy NSString *)file;
- (oneway void)serverFoundLocation:(NSPoint)point atPageIndex:(unsigned int)pageIndex;
@end

#pragma mark -

@interface SKPDFSynchronizer (Private)
- (void)runDOServerForPorts:(NSArray *)ports;
// these following methods only be called on the server thread
- (BOOL)parseSyncFileIfNeeded;
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
        lastModDate = nil;
        isPdfsync = YES;
        
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
        serverReady = NO;
        
        // run a background thread to connect to the remote server
        // this will connect back to the connection we just set up
        [NSThread detachNewThreadSelector:@selector(runDOServerForPorts:) toTarget:self withObject:[NSArray arrayWithObjects:port2, port1, nil]];
        
        // wait till the server is set up
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            OSMemoryBarrier();
        } while (serverReady == NO && shouldKeepRunning == 1);
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

- (void)findLineForLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex {
    [serverOnServerThread serverFindLineForLocation:point inRect:rect atPageIndex:pageIndex];
}

- (void)findPageLocationForLine:(int)line inFile:(NSString *)file {
    [serverOnServerThread serverFindPageLocationForLine:line inFile:file];
}

#pragma mark Main thread
#pragma mark | DO server

- (oneway void)setLocalServer:(byref id)anObject {
    [anObject setProtocolForProxy:@protocol(SKPDFSynchronizerServerThread)];
    serverOnServerThread = [anObject retain];
    serverReady = YES;
}

#pragma mark | Finding

- (oneway void)serverFoundLine:(int)line inFile:(bycopy NSString *)file {
    OSMemoryBarrier();
    if (shouldKeepRunning && [delegate respondsToSelector:@selector(synchronizer:foundLine:inFile:)])
        [delegate synchronizer:self foundLine:line inFile:file];
}

- (oneway void)serverFoundLocation:(NSPoint)point atPageIndex:(unsigned int)pageIndex {
    OSMemoryBarrier();
    if (shouldKeepRunning && [delegate respondsToSelector:@selector(synchronizer:foundLocation:atPageIndex:)])
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
            OSMemoryBarrier();
        } while (shouldKeepRunning == 1 && didRun);
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
    
    NSString *basePath = [theFileName stringByDeletingLastPathComponent];
    NSMutableDictionary *records = [NSMutableDictionary dictionary];
    NSMutableArray *files = [NSMutableArray array];
    NSString *pdfsyncString = [NSString stringWithContentsOfFile:theFileName encoding:NSUTF8StringEncoding error:NULL];
    NSString *file;
    int recordIndex, line, pageIndex;
    float x, y;
    NSMutableDictionary *record;
    NSMutableArray *array;
    NSScanner *sc;
    unichar ch;
    
    if ([pdfsyncString length] == 0)
        return NO;
    
    sc = [[NSScanner alloc] initWithString:pdfsyncString];
    [sc setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([sc scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&file] == NO ||
        [sc scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL] == NO) {
        [sc release];
        return NO;
    }
    
    file = SKTeXSourceFile(file, basePath);
    [files addObject:file];
    
    array = [[NSMutableArray alloc] init];
    [lines setObject:array forKey:file];
    [array release];
    
    // we ignore the version
    if ([sc scanString:@"version" intoString:NULL] == NO ||
        [sc scanInt:NULL] == NO) {
        [sc release];
        return NO;
    }
    
    [sc scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
    
    OSMemoryBarrier();
    while (shouldKeepRunning && [sc scanCharacter:&ch]) {
        
        if (ch == 'l') {
            if ([sc scanInt:&recordIndex] && [sc scanInt:&line]) {
                // we ignore the column
                [sc scanInt:NULL];
                record = SKRecordForRecordIndex(records, recordIndex);
                [record setObject:file forKey:SKPDFSynchronizerFileKey];
                [record setIntValue:line forKey:SKPDFSynchronizerLineKey];
                [[lines objectForKey:file] addObject:record];
            }
        } else if (ch == 'p') {
            // we ignore * and + modifiers
            [sc scanString:@"*" intoString:NULL] || [sc scanString:@"+" intoString:NULL];
            if ([sc scanInt:&recordIndex] && [sc scanFloat:&x] && [sc scanFloat:&y]) {
                record = SKRecordForRecordIndex(records, recordIndex);
                [record setIntValue:[pages count] - 1 forKey:SKPDFSynchronizerPageKey];
                [record setFloatValue:SYNC_TO_PDF(x) + pdfOffset.x forKey:SKPDFSynchronizerXKey];
                [record setFloatValue:SYNC_TO_PDF(y) + pdfOffset.y forKey:SKPDFSynchronizerYKey];
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
        
        OSMemoryBarrier();
    }
    
    [sc release];
    
    NSSortDescriptor *lineSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKPDFSynchronizerLineKey ascending:YES] autorelease];
    NSSortDescriptor *xSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKPDFSynchronizerXKey ascending:YES] autorelease];
    NSSortDescriptor *ySortDescriptor = [[[NSSortDescriptor alloc] initWithKey:SKPDFSynchronizerYKey ascending:NO] autorelease];
    
    [[lines allValues] makeObjectsPerformSelector:@selector(sortUsingDescriptors:)
                                       withObject:[NSArray arrayWithObjects:lineSortDescriptor, nil]];
    [pages makeObjectsPerformSelector:@selector(sortUsingDescriptors:)
                           withObject:[NSArray arrayWithObjects:ySortDescriptor, xSortDescriptor, nil]];
    
    OSMemoryBarrier();
    BOOL returnValue = shouldKeepRunning == 1;

    return returnValue;
}

- (BOOL)parseSynctexFile:(NSString *)theFileName {
#ifdef SYNCTEX_FEATURE
    if (scanner)
        synctex_scanner_free(scanner);
    scanner = synctex_scanner_new_with_output_file([theFileName fileSystemRepresentation]);
    if (scanner) {
        NSString *theSyncFileName = [NSString stringWithUTF8String:synctex_scanner_get_synctex(scanner)];
        [self setSyncFileName:theSyncFileName];
        isPdfsync = NO;
        return YES;
    }
#endif
    return NO;
}

- (BOOL)parseSyncFileIfNeeded {
    NSString *theFileName = [self fileName];
    
    if (theFileName == nil)
        return NO;
    
    NSString *theSyncFileName = [self syncFileName];
    
    if (theSyncFileName && SKFileExistsAtPath(theSyncFileName)) {
        NSDate *modDate = SKFileModificationDateAtPath(theFileName);
        NSDate *currentModDate = [self lastModDate];
    
        if (currentModDate == nil || [modDate compare:currentModDate] == NSOrderedDescending)
            return isPdfsync ? [self parsePdfsyncFile:theSyncFileName] : [self parseSynctexFile:theFileName];
        else
            return YES;
    }
    
    theSyncFileName = [[theFileName stringByDeletingPathExtension] stringByAppendingPathExtension:SKPDFSynchronizerPdfsyncExtension];
    
    if (SKFileExistsAtPath(theSyncFileName))
        return [self parsePdfsyncFile:theSyncFileName];
    else
        return [self parseSynctexFile:theFileName];
}

- (BOOL)pdfsyncFindLine:(int *)line file:(NSString **)file forLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex {
    if (pageIndex < [pages count]) {
        
        NSDictionary *record = nil;
        NSDictionary *beforeRecord = nil;
        NSDictionary *afterRecord = nil;
        NSMutableDictionary *atRecords = [NSMutableDictionary dictionary];
        NSEnumerator *recordEnum = [[pages objectAtIndex:pageIndex] objectEnumerator];
        
        while (record = [recordEnum nextObject]) {
            if ([record objectForKey:SKPDFSynchronizerLineKey] == nil)
                continue;
            float x = [[record objectForKey:SKPDFSynchronizerXKey] floatValue];
            float y = [[record objectForKey:SKPDFSynchronizerYKey] floatValue];
            if (y > NSMaxY(rect)) {
                beforeRecord = record;
            } else if (y < NSMinY(rect)) {
                afterRecord = record;
                break;
            } else if (x < NSMinX(rect)) {
                beforeRecord = record;
            } else if (x > NSMaxX(rect)) {
                afterRecord = record;
                break;
            } else {
                [atRecords setObject:record forKey:[NSNumber numberWithFloat:fabsf(x - point.x)]];
            }
        }
        
        record = nil;
        if ([atRecords count]) {
            NSNumber *nearest = [[[atRecords allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0];
            record = [atRecords objectForKey:nearest];
        } else if (beforeRecord && afterRecord) {
            float beforeX = [[beforeRecord objectForKey:SKPDFSynchronizerXKey] floatValue];
            float beforeY = [[beforeRecord objectForKey:SKPDFSynchronizerYKey] floatValue];
            float afterX = [[afterRecord objectForKey:SKPDFSynchronizerXKey] floatValue];
            float afterY = [[afterRecord objectForKey:SKPDFSynchronizerYKey] floatValue];
            if (beforeY - point.y < point.y - afterY)
                record = beforeRecord;
            else if (beforeY - point.y > point.y - afterY)
                record = afterRecord;
            else if (beforeX - point.x < point.x - afterX)
                record = beforeRecord;
            else if (beforeX - point.x > point.x - afterX)
                record = afterRecord;
            else
                record = beforeRecord;
        } else if (beforeRecord) {
            record = beforeRecord;
        } else if (afterRecord) {
            record = afterRecord;
        }
        
        if (record) {
            *line = [[record objectForKey:SKPDFSynchronizerLineKey] intValue];
            *file = [record objectForKey:SKPDFSynchronizerFileKey];
            return YES;
        }
    }
    return NO;
}

- (BOOL)pdfsyncFindPage:(unsigned int *)pageIndex location:(NSPoint *)point forLine:(int)line inFile:(NSString *)file {
    if ([lines objectForKey:file]) {
        
        NSDictionary *record = nil;
        NSDictionary *beforeRecord = nil;
        NSDictionary *afterRecord = nil;
        NSDictionary *atRecord = nil;
        NSEnumerator *recordEnum = [[lines objectForKey:file] objectEnumerator];
        
        while (record = [recordEnum nextObject]) {
            if ([record objectForKey:SKPDFSynchronizerPageKey] == nil)
                continue;
            int l = [[record objectForKey:SKPDFSynchronizerLineKey] intValue];
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
            int beforeLine = [[beforeRecord objectForKey:SKPDFSynchronizerLineKey] intValue];
            int afterLine = [[afterRecord objectForKey:SKPDFSynchronizerLineKey] intValue];
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
            *pageIndex = [[record objectForKey:SKPDFSynchronizerPageKey] unsignedIntValue];
            *point = NSMakePoint([[record objectForKey:SKPDFSynchronizerXKey] floatValue], [[record objectForKey:SKPDFSynchronizerYKey] floatValue]);
            return YES;
        }
    }
    return NO;
}

- (BOOL)synctexFindLine:(int *)line file:(NSString **)file forLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex {
#ifdef SYNCTEX_FEATURE
    if (synctex_edit_query(scanner, (int)pageIndex - 1, PDF_TO_SYNC(point.x), PDF_TO_SYNC(point.y)) > 0) {
        synctex_node_t node;
        if (node = synctex_next_result(scanner)) {
            *line = synctex_node_line(node);
            *file = [NSString stringWithUTF8String:synctex_scanner_get_name(scanner, synctex_node_tag(node))];
            return YES;
        }
    }
#endif
    return NO;
}

- (BOOL)synctexFindPage:(unsigned int *)pageIndex location:(NSPoint *)point forLine:(int)line inFile:(NSString *)file {
#ifdef SYNCTEX_FEATURE
    if (synctex_display_query(scanner, [file fileSystemRepresentation], line, 0) > 0) {
        synctex_node_t node;
        if ((node = synctex_next_result(scanner))) {
            *pageIndex = synctex_node_page(node) + 1;
            *point = NSMakePoint(SYNC_TO_PDF(synctex_node_h(node)), SYNC_TO_PDF(synctex_node_v(node)));
            return YES;
        }
    }
#endif
    return NO;
}

- (oneway void)serverFindLineForLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex {
    int foundLine = -1;
    NSString *foundFile = nil;
    
    OSMemoryBarrier();
    if (shouldKeepRunning && [self parseSyncFileIfNeeded]) {
        OSMemoryBarrier();
        if (shouldKeepRunning) {
            if (isPdfsync)
                [self pdfsyncFindLine:&foundLine file:&foundFile forLocation:point inRect:rect atPageIndex:pageIndex];
            else
                [self synctexFindLine:&foundLine file:&foundFile forLocation:point inRect:rect atPageIndex:pageIndex];
        }
    }
    
    OSMemoryBarrier();
    if (shouldKeepRunning)
        [serverOnMainThread serverFoundLine:foundLine inFile:foundFile];
}

- (oneway void)serverFindPageLocationForLine:(int)line inFile:(bycopy NSString *)file {
    unsigned int foundPageIndex = NSNotFound;
    NSPoint foundPoint = NSZeroPoint;
    
    OSMemoryBarrier();
    if (shouldKeepRunning && file && [self parseSyncFileIfNeeded] && [lines objectForKey:file]) {
        OSMemoryBarrier();
        if (shouldKeepRunning) {
            if (isPdfsync)
                [self pdfsyncFindPage:&foundPageIndex location:&foundPoint forLine:line inFile:file];
            else
                [self synctexFindPage:&foundPageIndex location:&foundPoint forLine:line inFile:file];
        }
    }
    
    OSMemoryBarrier();
    if (shouldKeepRunning)
        [serverOnMainThread serverFoundLocation:foundPoint atPageIndex:foundPageIndex];
}

@end

#pragma mark -

@implementation NSMutableDictionary (SKExtensions)

- (void)setIntValue:(int)value forKey:(id)key {
    NSNumber *number = [[NSNumber alloc] initWithInt:value];
    [self setValue:number forKey:key];
    [number release];
}

- (void)setFloatValue:(float)value forKey:(id)key {
    NSNumber *number = [[NSNumber alloc] initWithFloat:value];
    [self setValue:number forKey:key];
    [number release];
}

@end
