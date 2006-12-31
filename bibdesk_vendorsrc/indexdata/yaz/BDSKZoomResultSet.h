//
//  BDSKZoomResultSet.h
//  yaz
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <yaz/zoom.h>

@class BDSKZoomRecord;
@interface BDSKZoomResultSet : NSObject
{
    ZOOM_resultset   _resultSet;
    NSStringEncoding _resultEncoding;
}

- (id)initWithZoomResultSet:(ZOOM_resultset)resultSet encoding:(NSStringEncoding)encoding;
- (BDSKZoomRecord *)recordAtIndex:(unsigned int)index;
- (unsigned int)countOfRecords;
- (NSArray *)allRecords;

// more efficient than getting all the records and then using NSArray methods to get a subset
- (NSArray *)recordsAtIndexes:(NSIndexSet *)indexes;
- (NSArray *)recordsInRange:(NSRange)range;

// conveniences
- (NSString *)rawStringForRecordAtIndex:(unsigned int)index;
- (NSArray *)rawStrings;

@end
