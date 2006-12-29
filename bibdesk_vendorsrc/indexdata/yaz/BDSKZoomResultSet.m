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

- (id)initWithZoomResultSet:(ZOOM_resultset)resultSet;
{
    self = [super init];
    if (self) {
        NSParameterAssert(NULL != resultSet);
        _resultSet = resultSet;
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
    return [BDSKZoomRecord recordWithZoomRecord:ZOOM_resultset_record(_resultSet, index)];
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
        BDSKZoomRecord *record = [[BDSKZoomRecord allocWithZone:zone] initWithZoomRecord:ZOOM_resultset_record(_resultSet, i)];
        if (record)
            [array addObject:record];
        [record release];
        i = [indexes indexGreaterThanIndex:i];
    }
    return array;
}

#define STACK_BUFFER_SIZE 256

- (NSArray *)recordsInRange:(NSRange)range;
{
    unsigned count = range.length;

    if (count)
        NSParameterAssert(NSMaxRange(range) <= [self countOfRecords]);
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    NSZone *zone = [self zone];
    
    ZOOM_record *recordBuffer, stackBuffer[STACK_BUFFER_SIZE];
    BDSKZoomRecord *record;
    unsigned i;
    
    size_t bufferSize = sizeof(ZOOM_record) * count;
    if (count > STACK_BUFFER_SIZE) {
        recordBuffer = NSZoneMalloc(zone, bufferSize);
    } else {
        recordBuffer = stackBuffer;
    }
    NSAssert1(NULL != recordBuffer, @"failed to allocate memory for results of length %d", count);
    
    memset(recordBuffer, 0, bufferSize);
    ZOOM_resultset_records(_resultSet, recordBuffer, range.location, count);
    
    for (i = 0; i < count; i++) {
        if (record = [[BDSKZoomRecord allocWithZone:zone] initWithZoomRecord:recordBuffer[i]])
            [array addObject:record];
        [record release];
    }
    
    // BDSKZoomRecord copies the record, so we can dispose of them safely
    if (recordBuffer != stackBuffer) NSZoneFree(zone, recordBuffer);
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

