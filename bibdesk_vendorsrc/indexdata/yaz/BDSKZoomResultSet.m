//
//  BDSKZoomResultSet.m
//  yaz
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

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

