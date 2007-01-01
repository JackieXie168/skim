//
//  BDSKZoomResultSet.m
//  yaz
//
//  Created by Adam Maxwell on 12/26/06.
/*
 Copyright (c) 2006-2007, Adam Maxwell
 All rights reserved.
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of Adam Maxwell nor the names of its contributors
 may be used to endorse or promote products derived from this
 software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE CONTRIBUTORS ``AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE CONTRIBUTORS BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/ 

#import "BDSKZoomResultSet.h"
#import "BDSKZoomRecord.h"

@implementation BDSKZoomResultSet

- (id)initWithZoomResultSet:(ZOOM_resultset)resultSet encoding:(NSStringEncoding)encoding;
{
    self = [super init];
    if (self) {
        NSParameterAssert(NULL != resultSet);
        _resultSet = resultSet;
        _resultEncoding = encoding;
    }
    return self;
}

- (void)dealloc
{
    ZOOM_resultset_destroy(_resultSet);
    [super dealloc];
}

- (BDSKZoomRecord *)recordAtIndex:(unsigned int)index;
{
    NSParameterAssert(index < [self countOfRecords]);
    return [BDSKZoomRecord recordWithZoomRecord:ZOOM_resultset_record(_resultSet, index) encoding:_resultEncoding];
}

- (NSArray *)allRecords;
{
    return [self recordsInRange:NSMakeRange(0, [self countOfRecords])];
}

- (NSArray *)recordsAtIndexes:(NSIndexSet *)indexes;
{
    NSParameterAssert(nil != indexes);
    
    unsigned count = [indexes count];

    if (count)
        NSParameterAssert([indexes lastIndex] < [self countOfRecords]);
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    NSZone *zone = [self zone];
    unsigned i = [indexes firstIndex];

    while (i != NSNotFound) {
        BDSKZoomRecord *record = [[BDSKZoomRecord allocWithZone:zone] initWithZoomRecord:ZOOM_resultset_record(_resultSet, i) encoding:_resultEncoding];
        if (record)
            [array addObject:record];
        [record release];
        i = [indexes indexGreaterThanIndex:i];
    }
    return array;
}

// We define a fairly small batch size since some servers (library.usc.edu) return nil records if you ask for too many.  Calling ZOOM_resultset_records to get 25 at a time is still a significant performance improvement over call ZOOM_resultset_record on each one.
#define BATCH_SIZE 25

- (NSArray *)recordsInRange:(NSRange)range;
{
    unsigned count = range.length;

    if (count)
        NSParameterAssert(NSMaxRange(range) <= [self countOfRecords]);
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    NSZone *zone = [self zone];
    
    // since we're using a small buffer, we can keep everything on the stack
    ZOOM_record recordBuffer[BATCH_SIZE];
    BDSKZoomRecord *record;
    unsigned i;
    
    size_t bufferSize = sizeof(ZOOM_record) * BATCH_SIZE;
    
    NSRange rangeToGet = NSMakeRange(range.location, MIN(BATCH_SIZE, NSMaxRange(range)-range.location));
    
    while (rangeToGet.length) {

        memset(recordBuffer, 0, bufferSize);
        ZOOM_resultset_records(_resultSet, recordBuffer, rangeToGet.location, rangeToGet.length);
        
        // reset count, since we're now operating on a subrange
        count = rangeToGet.length;
        
        for (i = 0; i < count; i++) {
            if (record = [[BDSKZoomRecord allocWithZone:zone] initWithZoomRecord:recordBuffer[i] encoding:_resultEncoding])
                [array addObject:record];
            [record release];
        }        
        
        // advance the start of the range by it's previous length, since we know that was valid
        rangeToGet.location = rangeToGet.location + rangeToGet.length;
        
        // change the range length to be either our batch size or whatever's left in the original range
        rangeToGet.length = MIN(BATCH_SIZE, NSMaxRange(range)-rangeToGet.location);
    }
    return array;
}

- (unsigned int)countOfRecords;
{
    return ZOOM_resultset_size(_resultSet);
}

- (NSString *)rawStringForRecordAtIndex:(unsigned int)index;
{
    return [[self recordAtIndex:index] rawString];
}

- (NSArray *)rawStrings;
{
    unsigned i, iMax = [self countOfRecords];
    NSMutableArray *array = [NSMutableArray array];
    
    for (i = 0; i < iMax; i++) {
        [array addObject:[self rawStringForRecordAtIndex:i]];
    }
    return array;
}

@end

