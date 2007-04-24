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
        fileName = nil;
        lastModDate = nil;
    }
    return self;
}

- (void)dealloc {
    [pages release];
    [lines release];
    [fileName release];
    [lastModDate release];
    [super dealloc];
}

- (NSString *)fileName {
    return [[fileName retain] autorelease];
}

- (void)setFileName:(NSString *)newFileName {
    if (fileName != newFileName) {
        if ([fileName isEqualToString:newFileName] == NO && lastModDate) {
            [lastModDate release];
            lastModDate = nil;
        }
        [fileName release];
        fileName = [newFileName retain];
    }
}

- (BOOL)parsePdfsyncFileIfNeeded {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (fileName == nil || [fm fileExistsAtPath:fileName] == NO)
        return NO;
    
    NSDate *modDate = [[fm fileAttributesAtPath:fileName traverseLink:NO] fileModificationDate];
   
     if (lastModDate == nil || [modDate compare:lastModDate] == NSOrderedDescending)
        return [self parsePdfsyncFile];
    
    return YES;
}

static NSString *SKTeXSourceFile(NSString *file, NSString *base) {
    if ([[file pathExtension] caseInsensitiveCompare:@"tex"] != NSOrderedSame)
        file = [file stringByAppendingPathExtension:@"tex"];
    if ([file hasPrefix:@"/"] == NO)
        file = [base stringByAppendingPathComponent:file];
    return file;
}

static NSMutableDictionary *SKRecordForRecordIndex(NSMutableDictionary *records, int recordIndex) {
    NSNumber *recordNumber = [[NSNumber alloc] initWithInt:recordIndex];
    NSMutableDictionary *record = [records objectForKey:recordNumber];
    if (record == nil) {
        record = [[NSMutableDictionary alloc] initWithObjectsAndKeys:recordNumber, @"recordIndex", nil];
        [records setObject:record forKey:recordNumber];
        [record release];
    }
    [recordNumber release];
    return record;
}

- (BOOL)parsePdfsyncFile {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    [pages removeAllObjects];
    [lines removeAllObjects];
    
    if ([fm fileExistsAtPath:fileName] == NO)
        return NO;
    
    [lastModDate release];
    lastModDate = [[[fm fileAttributesAtPath:fileName traverseLink:NO] fileModificationDate] retain];
    
    NSString *basePath = [fileName stringByDeletingLastPathComponent];
    NSMutableDictionary *records = [NSMutableDictionary dictionary];
    NSMutableArray *files = [NSMutableArray array];
    NSString *pdfsyncString = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
    NSString *file;
    int recordIndex, line;
    float x, y;
    NSMutableDictionary *record;
    NSMutableArray *array;
    NSScanner *scanner;
    unichar ch;
    
    if ([pdfsyncString length] == 0)
        return NO;
    
    scanner = [[NSScanner alloc] initWithString:pdfsyncString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&file] == NO ||
        [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL] == NO) {
        [scanner release];
        return NO;
    }
    
    file = SKTeXSourceFile(file, basePath);
    [files addObject:file];
    
    array = [[NSMutableArray alloc] init];
    [lines setObject:array forKey:file];
    [array release];
    
    // we ignore the version
    if ([scanner scanString:@"version" intoString:NULL] == NO ||
        [scanner scanInt:NULL] == NO) {
        [scanner release];
        return NO;
    }
    
    [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
    
    while ([scanner isAtEnd] == NO) {
        
        [scanner scanCharacter:&ch];
        
        if (ch == 'l') {
            if ([scanner scanInt:&recordIndex] && [scanner scanInt:&line]) {
                // we ignore the column
                [scanner scanInt:NULL];
                record = SKRecordForRecordIndex(records, recordIndex);
                [record setObject:file forKey:@"file"];
                [record setIntValue:line forKey:@"line"];
                [[lines objectForKey:file] addObject:record];
            }
        } else if (ch == 'p') {
            // we ignore * and + modifiers
            [scanner scanString:@"*" intoString:NULL] || [scanner scanString:@"+" intoString:NULL];
            if ([scanner scanInt:&recordIndex] && [scanner scanFloat:&x] && [scanner scanFloat:&y]) {
                record = SKRecordForRecordIndex(records, recordIndex);
                [record setIntValue:[pages count] - 1 forKey:@"page"];
                [record setFloatValue:x / 65536 + pdfOffset.x forKey:@"x"];
                [record setFloatValue:y / 65536 + pdfOffset.y forKey:@"y"];
                [[pages lastObject] addObject:record];
            }
        } else if (ch == 's') {
            // start of a new page, the scanned integer should always equal [pages count]+1
            [scanner scanInt:NULL];
            array = [[NSMutableArray alloc] init];
            [pages addObject:array];
            [array release];
        } else if (ch == '(') {
            // start of a new source file
            if ([scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&file]) {
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
        
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
        [scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
    }
    
    [scanner release];
    
    NSSortDescriptor *lineSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"line" ascending:YES] autorelease];
    NSSortDescriptor *xSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"x" ascending:YES] autorelease];
    NSSortDescriptor *ySortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"y" ascending:NO] autorelease];
    
    [[lines allValues] makeObjectsPerformSelector:@selector(sortUsingDescriptors:)
                                       withObject:[NSArray arrayWithObjects:lineSortDescriptor, nil]];
    [pages makeObjectsPerformSelector:@selector(sortUsingDescriptors:)
                           withObject:[NSArray arrayWithObjects:ySortDescriptor, xSortDescriptor, nil]];
    
    return YES;
}

- (BOOL)getLine:(int *)line file:(NSString **)file forLocation:(NSPoint)point inRect:(NSRect)rect atPageIndex:(unsigned int)pageIndex {
    if ([self parsePdfsyncFileIfNeeded] == NO)
        return NO;
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
            *line = [[record objectForKey:@"line"] intValue];
        if (file)
            *file = [record objectForKey:@"file"];
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
    if ([self parsePdfsyncFileIfNeeded] == NO)
        return NO;
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
            *pageIndex = [[record objectForKey:@"page"] unsignedIntValue];
        if (point)
            *point = NSMakePoint([[record objectForKey:@"x"] floatValue], [[record objectForKey:@"y"] floatValue]);
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
