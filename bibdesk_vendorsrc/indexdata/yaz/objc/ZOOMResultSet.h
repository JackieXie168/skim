//
//  ZOOMResultSet.h
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

#import <Cocoa/Cocoa.h>
#import <yaz/zoom.h>

@class ZOOMRecord;

/*!
    @class       ZOOMResultSet 
    @superclass  NSObject
    @abstract    Interface for ZOOM_resultset primitive object.  Provides facilities for getting each record individually or in a batch.  In general, this object will only be created by a ZOOMConnection or other object that owns a result set.
*/
@interface ZOOMResultSet : NSObject
{
    ZOOM_resultset   _resultSet;
    NSString        *_charSetName;
}

/*!
    @method     initWithZoomResultSet:charSet:
    @abstract   Initializes the object.
    @discussion This is a thin wrapper around ZOOM_resultset.  No additional caching is provided at this time.
    @param      resultSet The ZOOM_resultset (may not be nil)
    @param      charSetName IANA character set name passed to ZOOMRecord instances (may not be nil)
    @result     Provides convenient access to ZOOMRecords.
*/
- (id)initWithZoomResultSet:(ZOOM_resultset)resultSet charSet:(NSString *)charSetName;

/*!
    @method     countOfRecords
    @abstract   Returns the number of records in the result set.
    @result     Returns zero for an empty result set.
*/
- (unsigned int)countOfRecords;

/*!
    @method     recordAtIndex:
    @abstract   Extracts each record individually.
    @discussion This may cause a network connection and read each time it is called, so it should only be used for a small number of records.
    @param      index Index of the record to extract.  Must not exceed the number of available records.
    @result     A ZOOMRecord instance.  The caller is responsible for retaining this object.
*/
- (ZOOMRecord *)recordAtIndex:(unsigned int)index;

/*!
    @method     allRecords
    @abstract   Returns all available records by calling recordsInRange: with NSMakeRange(0, [self countOfRecords]).
    @result     An array of ZOOMRecord instances.  The caller is responsible for retaining this object.
*/
- (NSArray *)allRecords;

// more efficient than getting all the records and then using NSArray methods to get a subset

/*!
    @method     recordsInRange:
    @abstract   Returns all records in the specified range.
    @discussion This is the most efficient way to get a subset of the available records (rather than recordAtIndex:).
    @param      range Range of records to return.
    @result     An array of ZOOMRecord instances.  The caller is responsible for retaining this object.
*/
- (NSArray *)recordsInRange:(NSRange)range;

@end
