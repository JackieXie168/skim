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
        _hostName = [hostName copy];
        
        NSParameterAssert(nil != hostName);
        
        // we'll ignore the arguments when calling ZOOM_connection... functions by composing a host string
        if (_dataBase) {
            // we have to append port as well, if there's a specific database
            if (_portNum)
                _connectHost = [[hostName stringByAppendingFormat:@":%d/%@", _portNum, _dataBase] copy];
            else
                _connectHost = [[hostName stringByAppendingFormat:@"/%@", _dataBase] copy];
            
        } else {
            if (_portNum)
                _connectHost = [[hostName stringByAppendingFormat:@":%d", _portNum] copy];
            else
                _connectHost = [hostName copy];
        }
        
        // we maintain our own result cache, keyed by query, since a particular connection is only instantiated per-host
        _results = [[NSMutableDictionary alloc] init];
        
        // maintain a cache of options, only so we can archive the object
        _options = [[NSMutableDictionary alloc] init];
        
        // default options
        [self setPreferredRecordSyntax:USMARC];
        
        // encoding to use when returning strings from records
        [self setResultEncoding:NSUTF8StringEncoding];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleApplicationWillTerminate:) 
                                                     name:NSApplicationWillTerminateNotification 
                                                   object:nil];
        
        // no need to connect yet; resultsForQuery will do that for us, and this allows initWithPropertyList to setup first
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
    [_connectHost release];
    [_options release];
    [super dealloc];
}

- (id)propertyList;
{
    NSMutableDictionary *plist = [NSMutableDictionary dictionary];
    [plist setObject:_hostName forKey:@"_hostName"];
    [plist setObject:[NSNumber numberWithInt:_portNum] forKey:@"_portNum"];
    [plist setObject:[NSNumber numberWithInt:_resultEncoding] forKey:@"_resultEncoding"];
    [plist setObject:_options forKey:@"_options"];
    
    // this is the only object ivar that may be nil
    if (_dataBase)
        [plist setObject:_dataBase forKey:@"_dataBase"];

    // don't store any derived values
    return plist;
}

- (id)initWithPropertyList:(id)plist;
{
    self = [self initWithHost:[plist objectForKey:@"_hostName"] 
                         port:[[plist objectForKey:@"_portNum"] intValue] 
                     database:[plist objectForKey:@"_dataBase"]];
    
    // set to UTF-8 in init...
    if ([plist objectForKey:@"_resultEncoding"])
        _resultEncoding = [[plist objectForKey:@"_resultEncoding"] intValue];
    
    // options from the plist override any default options we've set (noop is self is nil)
    NSDictionary *options = [plist objectForKey:@"_options"];
    NSEnumerator *keyEnumerator = [options keyEnumerator];
    NSString *key;
    while (key = [keyEnumerator nextObject]) {
        // this will update the connection's options and our _options ivar
        [self setOption:[options objectForKey:key] forKey:key];
    }
    
    return self;
}

// no need to have this in the API at present
- (void)connect
{
    ZOOM_connection_connect(_connection, [_connectHost UTF8String], 0);
    int error;
    const char *errmsg, *addinfo;
    if ((error = ZOOM_connection_error(_connection, &errmsg, &addinfo)))
        NSLog(@"Error: %s (%d) %s\n", errmsg, error, addinfo);    
}

- (void)setOption:(NSString *)option forKey:(NSString *)key;
{
    // passing NULL for option will zero it out
    ZOOM_connection_option_set(_connection, [key UTF8String], [option UTF8String]);
    
    // cached results may now be invalid, if we're asking for a different charset/syntax
    [_results removeAllObjects];
    
    if (option)
        [_options setObject:option forKey:key];
    else
        [_options removeObjectForKey:key];
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

- (void)setResultEncoding:(NSStringEncoding)encoding;
{
    NSParameterAssert(encoding > 0);
    _resultEncoding = encoding;
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

        resultSet = [[BDSKZoomResultSet allocWithZone:[self zone]] initWithZoomResultSet:r encoding:_resultEncoding];
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
