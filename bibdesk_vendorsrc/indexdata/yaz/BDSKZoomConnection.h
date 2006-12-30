//
//  BDSKZoomConnection.h
//  yaz
//
//  Created by Adam Maxwell on 12/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <yaz/zoom.h>
#import <yaz/BDSKZoomResultSet.h>
#import <yaz/BDSKZoomRecord.h>

@class BDSKZoomQuery;

@interface BDSKZoomConnection : NSObject 
{
    @private
    ZOOM_connection       _connection;
    NSString             *_hostName;
    int                   _portNum;
    NSString             *_dataBase;
    
    NSString             *_connectHost; // derived from arguments
    NSMutableDictionary  *_results;     // results cached by query
    NSMutableDictionary  *_options;     // copy explicitly set ZOOM_options
}

- (id)initWithHost:(NSString *)hostName port:(int)portNum database:(NSString *)dbase;
- (id)initWithHost:(NSString *)hostName port:(int)portNum;

- (id)initWithPropertyList:(id)plist;
- (id)propertyList;

// pass nil for option to clear options for a particular key
- (void)setOption:(NSString *)option forKey:(NSString *)key;
- (NSString *)optionForKey:(NSString *)key;

// default record syntax is USMARC (MARC21)
- (void)setPreferredRecordSyntax:(BDSKZoomSyntaxType)type;

- (BDSKZoomResultSet *)resultsForQuery:(BDSKZoomQuery *)query;

// add methods for other query syntaxes as needed
- (BDSKZoomResultSet *)resultsForCCLQuery:(NSString *)queryString;

@end
