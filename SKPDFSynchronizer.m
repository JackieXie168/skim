//
//  SKPDFSynchronizer.m
//  Skim
//
//  Created by Christiaan Hofman on 4/21/07.
/*
 This software is Copyright (c) 2007
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


@implementation SKPDFSynchronizer

// Offset of coordinates in PDFKit and what pdfsync tells us. Don't know what they are; is this implementation dependent?
static NSPoint pdfOffset = {0.0, 0.0};

- (id)init {
    if (self = [super init]) {
        pages = [[NSMutableArray alloc] init];
        lines = [[NSMutableDictionary alloc] init];
        records = [[NSMutableDictionary alloc] init];
        version = 0;
        fileName = nil;
        lastModDate = nil;
    }
    return self;
}

- (void)dealloc {
    [pages release];
    [lines release];
    [records release];
    [fileName release];
    [lastModDate release];
    [super dealloc];
}


- (BOOL)parsePdfsyncFileIfNeeded:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDate *modDate = [[fm fileAttributesAtPath:path traverseLink:NO] fileModificationDate];
    
    if ([fm fileExistsAtPath:path] == NO)
        return NO;
    
    if (lastModDate == nil || [path isEqualToString:fileName] == NO || [modDate compare:lastModDate] == NSOrderedDescending)
        return [self parsePdfsyncFile:path];
    
    return YES;
}

- (BOOL)parsePdfsyncFile:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    [pages removeAllObjects];
    [lines removeAllObjects];
    
    if ([fm fileExistsAtPath:path] == NO)
        return NO;
    
    [lastModDate release];
    lastModDate = [[[fm fileAttributesAtPath:path traverseLink:NO] fileModificationDate] retain];
    
    [fileName release];
    fileName = [path retain];
    
    NSString *basePath = [fileName stringByDeletingLastPathComponent];
    NSMutableArray *files = [NSMutableArray array];
    NSString *pdfsyncString = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
    NSString *file;
    int recordIndex, line, column;
    float x, y;
    NSMutableDictionary *record;
    NSMutableArray *array;
    NSNumber *recordNumber;
    NSNumber *lineNumber;
    NSNumber *pageNumber;
    NSNumber *xNumber;
    NSNumber *yNumber;
    
    if ([pdfsyncString length] == 0)
        return NO;
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:pdfsyncString];
    unichar ch;
    
    [scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&file] == NO ||
        [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL] == NO) {
        [scanner release];
        return NO;
    }
    
    if ([[file pathExtension] caseInsensitiveCompare:@"tex"] != NSOrderedSame)
        file = [file stringByAppendingPathExtension:@"tex"];
    
    file = [basePath stringByAppendingPathComponent:file];
    [files addObject:file];
    
    array = [[NSMutableArray alloc] init];
    [lines setObject:array forKey:file];
    [array release];
    
    if ([scanner scanString:@"version" intoString:NULL] == NO ||
        [scanner scanInt:&version] == NO) {
        [scanner release];
        return NO;
    }
    
    [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
    
    while ([scanner isAtEnd] == NO) {
        
        [scanner scanCharacter:&ch];
        
        if (ch == 'l') {
            if ([scanner scanInt:&recordIndex] && [scanner scanInt:&line]) {
                [scanner scanInt:&column];
                recordNumber = [[NSNumber alloc] initWithInt:recordIndex];
                lineNumber = [[NSNumber alloc] initWithInt:line];
                record = [records objectForKey:recordNumber];
                if (record == nil) {
                    record = [[NSMutableDictionary alloc] init];
                    [records setObject:record forKey:recordNumber];
                    [record release];
                }
                [record setObject:file forKey:@"file"];
                [record setObject:lineNumber forKey:@"line"];
                [[lines objectForKey:file] addObject:record];
                [lineNumber release];
                [recordNumber release];
            }
        } else if (ch == 'p') {
            [scanner scanString:@"*" intoString:NULL] || [scanner scanString:@"+" intoString:NULL];
            if ([scanner scanInt:&recordIndex] && [scanner scanFloat:&x] && [scanner scanFloat:&y]) {
                recordNumber = [[NSNumber alloc] initWithInt:recordIndex];
                pageNumber = [[NSNumber alloc] initWithUnsignedInt:[pages count] - 1];
                xNumber = [[NSNumber alloc] initWithFloat:x / 65536 + pdfOffset.x];
                yNumber = [[NSNumber alloc] initWithFloat:y / 65536 + pdfOffset.y];
                record = [records objectForKey:recordNumber];
                if (record == nil) {
                    record = [[NSMutableDictionary alloc] initWithObjectsAndKeys:recordNumber, @"recordIndex", nil];
                    [records setObject:record forKey:recordNumber];
                    [record release];
                }
                [record setObject:pageNumber forKey:@"page"];
                [record setObject:xNumber forKey:@"x"];
                [record setObject:yNumber forKey:@"y"];
                [[pages lastObject] addObject:record];
                [pageNumber release];
                [xNumber release];
                [yNumber release];
                [recordNumber release];
            }
        } else if (ch == 's') {
            [scanner scanInt:NULL];
            array = [[NSMutableArray alloc] init];
            [pages addObject:array];
            [array release];
        } else if (ch == '(') {
            if ([scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&file]) {
                if ([[file pathExtension] caseInsensitiveCompare:@"tex"] != NSOrderedSame)
                    file = [file stringByAppendingPathExtension:@"tex"];
                file = [basePath stringByAppendingPathComponent:file];
                [files addObject:file];
                record = [lines objectForKey:file];
                if (record == nil) {
                    array = [[NSMutableArray alloc] init];
                    [lines setObject:array forKey:file];
                    [array release];
                }
            }
        } else if (ch == ')') {
            [files removeLastObject];
            file = [files lastObject];
        }
        
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
        [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
    }
    
    [scanner release];
    
    NSSortDescriptor *lineSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"line" ascending:YES] autorelease];
    NSSortDescriptor *xSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"x" ascending:YES] autorelease];
    NSSortDescriptor *ySortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"y" ascending:NO] autorelease];
    NSEnumerator *e;
    NSArray *sortDescriptors;
    
    e = [lines objectEnumerator];
    sortDescriptors = [NSArray arrayWithObjects:lineSortDescriptor, nil];
    while (array = [e nextObject])
        [array sortUsingDescriptors:sortDescriptors];
    
    e = [pages objectEnumerator];
    sortDescriptors = [NSArray arrayWithObjects:ySortDescriptor, xSortDescriptor, nil];
    while (array = [e nextObject])
        [array sortUsingDescriptors:sortDescriptors];
    
    return YES;
}

- (BOOL)getLine:(int *)line file:(NSString **)file forLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex {
    if (pageIndex >= [pages count])
        return NO;
    
    NSDictionary *beforeRecord = nil;
    NSDictionary *afterRecord = nil;
    NSMutableDictionary *atRecords = [NSMutableDictionary dictionary];
    NSEnumerator *recordEnum = [[pages objectAtIndex:pageIndex] objectEnumerator];
    NSDictionary *record = nil;
    
    while (record = [recordEnum nextObject]) {
        if ([record objectForKey:@"line"] == nil)
            continue;
        float x = [[record objectForKey:@"x"] floatValue];
        float y = [[record objectForKey:@"y"] floatValue];
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
            [atRecords setObject:record forKey:[NSNumber numberWithFloat:fabs(x - point.x)]];
        }
    }
    
    record = nil;
    if ([atRecords count]) {
        NSNumber *nearest = [[[atRecords allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0];
        record = [atRecords objectForKey:nearest];
    } else if (beforeRecord && afterRecord) {
        float beforeX = [[beforeRecord objectForKey:@"x"] floatValue];
        float beforeY = [[beforeRecord objectForKey:@"y"] floatValue];
        float afterX = [[afterRecord objectForKey:@"x"] floatValue];
        float afterY = [[afterRecord objectForKey:@"y"] floatValue];
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
        if (line)
            *line = [record objectForKey:@"line"] ? [[record objectForKey:@"line"] intValue] : -1;
        if (file)
            *file = [record objectForKey:@"file"] ? [record objectForKey:@"file"] : nil;
        return YES;
    } else {
        if (line)
            *line = -1;
        if (file)
            *file = nil;
        return NO;
    }
}

- (BOOL)getPageIndex:(unsigned int *)pageIndex location:(NSPoint *)point forLine:(int)line inFile:(NSString *)file {
    if (line < 0 || file == nil || [lines objectForKey:file] == nil)
        return NO;
    
    NSDictionary *beforeRecord = nil;
    NSDictionary *afterRecord = nil;
    NSDictionary *atRecord = nil;
    NSEnumerator *recordEnum = [[lines objectForKey:file] objectEnumerator];
    NSDictionary *record = nil;
    
    while (record = [recordEnum nextObject]) {
        if ([record objectForKey:@"page"] == nil)
            continue;
        int l = [[record objectForKey:@"line"] intValue];
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
        int beforeLine = [[beforeRecord objectForKey:@"line"] intValue];
        int afterLine = [[afterRecord objectForKey:@"line"] intValue];
        if (beforeLine - line < line - afterLine)
            record = beforeRecord;
        else if (beforeLine - line > line - afterLine)
            record = afterRecord;
        else
            record = beforeRecord;
    } else if (beforeRecord) {
        record = beforeRecord;
    } else if (afterRecord) {
        record = afterRecord;
    }
    
    if (record) {
        if (pageIndex)
            *pageIndex = [record objectForKey:@"page"] ? [[record objectForKey:@"page"] unsignedIntValue] : NSNotFound;
        if (point)
            *point = [record objectForKey:@"x"] ? NSMakePoint([[record objectForKey:@"x"] floatValue], [[record objectForKey:@"y"] floatValue]) : NSZeroPoint;
        return YES;
    } else {
        if (pageIndex)
            *pageIndex = NSNotFound;
        if (point)
            *point = NSZeroPoint;
        return NO;
    }
}

@end
