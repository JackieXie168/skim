//
//  SKPDFSyncRecord.m
//  Skim
//
//  Created by Christiaan Hofman on 7/12/08.
/*
 This software is Copyright (c) 2008-2009
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

#import "SKPDFSyncRecord.h"


@implementation SKPDFSyncRecord

- (id)initWithRecordIndex:(NSInteger)aRecordIndex {
    if (self = [super init]) {
        recordIndex = aRecordIndex;
        pageIndex = NSNotFound;
        point = NSZeroPoint;
        file = nil;
        line = -1;
    }
    return self;
}

- (void)dealloc {
    [file release];
    [super dealloc];
}

- (NSInteger)recordIndex {
    return recordIndex;
}

- (NSInteger)pageIndex {
    return pageIndex;
}

- (void)setPageIndex:(NSInteger)newPageIndex {
    if (pageIndex != newPageIndex) {
        pageIndex = newPageIndex;
    }
}

- (NSPoint)point {
    return point;
}

- (void)setPoint:(NSPoint)newPoint {
    point = newPoint;
}

- (CGFloat)x {
    return point.x;
}

- (CGFloat)y {
    return point.y;
}

- (NSString *)file {
    return file;
}

- (void)setFile:(NSString *)newFile {
    if (file != newFile) {
        [file release];
        file = [newFile retain];
    }
}

- (NSInteger)line {
    return line;
}

- (void)setLine:(NSInteger)newLine {
    line = newLine;
}

@end

#pragma mark -

@implementation SKPDFSyncRecords

- (id)init {
    if (self = [super init]) {
        NSPointerFunctions *keyFunctions = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsIntegerPersonality];
        NSPointerFunctions *valueFunctions = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
        records = [[NSMapTable alloc] initWithKeyPointerFunctions:keyFunctions valuePointerFunctions:valueFunctions capacity:0];
    }
    return self;
}

- (void)dealloc {
    [records release];
    [super dealloc];
}

- (SKPDFSyncRecord *)recordForIndex:(NSInteger)recordIndex {
    SKPDFSyncRecord *record = [records objectForKey:(id)recordIndex];
    if (record == nil) {
        record = [[SKPDFSyncRecord alloc] initWithRecordIndex:recordIndex];
        [records setObject:record forKey:(id)recordIndex];
        [record release];
    }
    return record;
}

@end
