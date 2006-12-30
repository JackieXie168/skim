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

@interface BDSKZoomConnection : NSObject {
    ZOOM_connection       _connection;
    NSMutableDictionary  *_results;
    NSString             *_hostName;
    int                   _portNum;
    NSString             *_dataBase;
}

- (id)initWithHost:(NSString *)hostName port:(int)portNum database:(NSString *)dbase;
- (id)initWithHost:(NSString *)hostName port:(int)portNum;
- (void)connect;
- (void)setOption:(NSString *)option forKey:(NSString *)key;
- (NSString *)optionForKey:(NSString *)key;

// default record syntax is USMARC (MARC21)
- (void)setPreferredRecordSyntax:(BDSKZoomSyntaxType)type;

- (BDSKZoomResultSet *)resultsForQuery:(BDSKZoomQuery *)query;

// add methods for other query syntaxes as needed
- (BDSKZoomResultSet *)resultsForCCLQuery:(NSString *)queryString;

@end
