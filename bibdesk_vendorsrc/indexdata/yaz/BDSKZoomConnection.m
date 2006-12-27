//
//  BDSKZoomConnection.m
//  yaz
//
//  Created by Adam Maxwell on 12/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKZoomConnection.h"
#import "BDSKZoomQuery.h"
#import "BDSKZoomRecord.h"

@implementation BDSKZoomConnection

- (id)initWithHost:(NSString *)hostName port:(int)portNum;
{
    self = [super init];
    if (self) {
        _connection = ZOOM_connection_create(0);
        _hostName = [hostName copy];
        _portNum = portNum;
        _results = [[NSMutableDictionary alloc] init];
        
        // default options
        ZOOM_connection_option_set(_connection, "preferredRecordSyntax", "USMARC");
        ZOOM_connection_option_set(_connection, "charset", "UTF-8");
        ZOOM_connection_option_set(_connection, "lang", "en-US");   
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleApplicationWillTerminate:) 
                                                     name:NSApplicationWillTerminateNotification 
                                                   object:nil];
        
        [self connect];
    }
    return self;
}

- (void)handleApplicationWillTerminate:(NSNotification *)note
{
    if (_connection)
        ZOOM_connection_destroy(_connection);
    _connection = NULL;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_connection)
        ZOOM_connection_destroy(_connection);
    _connection = NULL;
    [_results release]; // will destroy the result sets
    [_hostName release];
    [super dealloc];
}

- (void)connect
{
    ZOOM_connection_connect(_connection, [_hostName UTF8String], _portNum);
}

- (void)setOption:(NSString *)option forKey:(NSString *)key;
{
    ZOOM_connection_option_set(_connection, [key UTF8String], [option UTF8String]);
}

- (NSString *)optionForKey:(NSString *)key;
{
    const char *val = ZOOM_connection_option_get(_connection, [key UTF8String]);
    return val ? [NSString stringWithUTF8String:val] : nil;
}

- (BDSKZoomResultSet *)resultsForQuery:(BDSKZoomQuery *)query;
{
    BDSKZoomResultSet *resultSet = [_results objectForKey:query];
    if (nil == resultSet) {
        [self connect];
        ZOOM_resultset r = ZOOM_connection_search(_connection, [query zoomQuery]);
        resultSet = [[BDSKZoomResultSet allocWithZone:[self zone]] initWithZoomResultSet:r];
        [_results setObject:resultSet forKey:query];
        [resultSet release];
    }
    return resultSet;
}

- (BDSKZoomResultSet *)resultsForCCLQuery:(NSString *)queryString;
{
    return [self resultsForQuery:[BDSKZoomQuery queryWithCCLString:queryString config:nil]];
}

@end
