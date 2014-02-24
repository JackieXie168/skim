//
//  SKPDFSyncRecord.m
//  Skim
//
//  Created by Christiaan Hofman on 7/12/08.
/*
 This software is Copyright (c) 2008-2014
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
#import "NSPointerArray_SKExtensions.h"


@implementation SKPDFSyncRecord

@synthesize recordIndex, pageIndex, point, file, line;
@dynamic x, y;

- (id)initWithRecordIndex:(NSInteger)aRecordIndex {
    self = [super init];
    if (self) {
        recordIndex = aRecordIndex;
        pageIndex = NSNotFound;
        point = NSZeroPoint;
        file = nil;
        line = -1;
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(file);
    [super dealloc];
}

- (CGFloat)x {
    return point.x;
}

- (CGFloat)y {
    return point.y;
}

@end

#pragma mark -

@implementation SKPDFSyncRecords

- (id)init {
    self = [super init];
    if (self) {
        records = NSCreateMapTable(NSIntegerMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
    }
    return self;
}

- (void)dealloc {
    NSFreeMapTable(records);
    [super dealloc];
}

- (SKPDFSyncRecord *)recordForIndex:(NSInteger)recordIndex {
    SKPDFSyncRecord *record = NSMapGet(records, (const void *)recordIndex);
    if (record == nil) {
        record = [[SKPDFSyncRecord alloc] initWithRecordIndex:recordIndex];
        NSMapInsert(records, (const void *)recordIndex, record);
        [record release];
    }
    return record;
}

@end
