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

@interface BDSKZoomConnection : NSObject {
    ZOOM_connection       _connection;
    NSMutableDictionary  *_results;
    NSString             *_hostName;
    int                   _portNum;
}

- (id)initWithHost:(NSString *)hostName port:(int)portNum;
- (void)connect;
- (void)setOption:(NSString *)option forKey:(NSString *)key;
- (NSString *)optionForKey:(NSString *)key;


// add methods for other query syntaxes as needed
- (BDSKZoomResultSet *)resultsForCCLQuery:(NSString *)queryString;

@end
