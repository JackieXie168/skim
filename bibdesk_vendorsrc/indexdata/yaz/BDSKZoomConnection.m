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
#import "log.h"

@implementation BDSKZoomConnection

+ (void)initialize;
{
    static BOOL didInit = NO;
    if (NO == didInit) {
        // pass empty string to use stderr
        yaz_log_init(YLOG_DEFAULT_LEVEL, NULL, "");
        didInit = YES;
    }
}

- (id)initWithHost:(NSString *)hostName port:(int)portNum database:(NSString *)dbase;
{
    if (self = [super init]) {
        
        _connection = ZOOM_connection_create(0);
        _portNum = portNum;
        _dataBase = [dbase copy];
        
        NSParameterAssert(nil != hostName);
        
        if (_dataBase) {
            // we have to append port as well, if there's a specific database
            if (_portNum)
                _hostName = [[hostName stringByAppendingFormat:@":%d/%@", _portNum, _dataBase] copy];
            else
                _hostName = [[hostName stringByAppendingFormat:@"/%@", _dataBase] copy];
            
            // set portNum to zero, since we've integrated it into the host name now
            _portNum = 0;
        } else {
            _hostName = [hostName copy];
        }
        
        // we maintain our own result cache, keyed by query, since a particular connection is only instantiated per-host
        _results = [[NSMutableDictionary alloc] init];
        
        // default options
        [self setPreferredRecordSyntax:USMARC];
        [self setOption:@"UTF-8" forKey:@"charset"];
        [self setOption:@"en-US" forKey:@"lang"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleApplicationWillTerminate:) 
                                                     name:NSApplicationWillTerminateNotification 
                                                   object:nil];
        
        [self connect];
    }
    return self;
}

- (id)initWithHost:(NSString *)hostName port:(int)portNum;
{
    return [self initWithHost:hostName port:portNum database:nil];
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
    int error;
    const char *errmsg, *addinfo;
    if ((error = ZOOM_connection_error(_connection, &errmsg, &addinfo)))
        NSLog(@"Error: %s (%d) %s\n", errmsg, error, addinfo);    
}

- (void)setOption:(NSString *)option forKey:(NSString *)key;
{
    ZOOM_connection_option_set(_connection, [key UTF8String], [option UTF8String]);
    
    // cached results may now be invalid, if we're asking for a different charset/syntax
    [_results removeAllObjects];
}

- (NSString *)optionForKey:(NSString *)key;
{
    const char *val = ZOOM_connection_option_get(_connection, [key UTF8String]);
    return val ? [NSString stringWithUTF8String:val] : nil;
}

- (void)setPreferredRecordSyntax:(BDSKZoomSyntaxType)type;
{
    [self setOption:[BDSKZoomRecord stringWithSyntaxType:type] forKey:@"preferredRecordSyntax"];
}

- (BDSKZoomResultSet *)resultsForQuery:(BDSKZoomQuery *)query;
{
    NSParameterAssert(nil != query);
    BDSKZoomResultSet *resultSet = [_results objectForKey:query];
    if (nil == resultSet) {
        [self connect];
        ZOOM_resultset r = ZOOM_connection_search(_connection, [query zoomQuery]);

        int error;
        const char *errmsg, *addinfo;
        if ((error = ZOOM_connection_error(_connection, &errmsg, &addinfo)))
            NSLog(@"Error: %s (%d) %s\n", errmsg, error, addinfo);

        resultSet = [[BDSKZoomResultSet allocWithZone:[self zone]] initWithZoomResultSet:r];
        [_results setObject:resultSet forKey:query];
        [resultSet release];
    }
    return resultSet;
}

- (BDSKZoomResultSet *)resultsForCCLQuery:(NSString *)queryString;
{
    BDSKZoomQuery *query = [BDSKZoomQuery queryWithCCLString:queryString config:nil];
    return query ? [self resultsForQuery:query] : nil;
}

@end
