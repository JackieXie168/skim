//
//  ZOOMConnection.m
//  yaz
//
//  Created by Adam Maxwell on 12/25/06.
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

#import "ZOOMConnection.h"
#import "ZOOMQuery.h"
#import "ZOOMRecord.h"
#import <yaz/log.h>

@implementation ZOOMConnection

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
        
        // encoding to use when returning strings from records; default to marc-8
        [self setResultEncodingToIANACharSetName:nil];
        
        // Do not connect yet; resultsForQuery will do that for us, and this allows initWithPropertyList to setup first (and for user/password to be set if needed).  We were registering for NSApplicationWillTerminateNotification and destroying the ZOOM_connection in that callback, but since NSApplicationWillTerminateNotification can be delivered on a different thread, we end up with a race condition with -dealloc and possible crash.  Therefore, the owner is responsible for releasing the connection appropriately in order to destroy the underlying ZOOM_connection.
    }
    return self;
}

- (id)initWithHost:(NSString *)hostName port:(int)portNum;
{
    return [self initWithHost:hostName port:portNum database:nil];
}

- (void)dealloc
{
    [_results release]; // will destroy the result sets
    if (_connection)
        ZOOM_connection_destroy(_connection);
    _connection = NULL;
    [_hostName release];
    [_dataBase release];
    [_charSetName release];
    [_connectHost release];
    [_options release];
    [super dealloc];
}

- (id)propertyList;
{
    NSMutableDictionary *plist = [NSMutableDictionary dictionary];
    [plist setObject:_hostName forKey:@"_hostName"];
    [plist setObject:[NSNumber numberWithInt:_portNum] forKey:@"_portNum"];
    [plist setObject:_charSetName forKey:@"_charSetName"];
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
    
    // set to default in init...
    [self setResultEncodingToIANACharSetName:[plist objectForKey:@"_charSetName"]];
    
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

- (void)setPreferredRecordSyntax:(ZOOMSyntaxType)type;
{
    [self setOption:[ZOOMRecord stringWithSyntaxType:type] forKey:@"preferredRecordSyntax"];
}

- (void)setUsername:(NSString *)user;
{
    [self setOption:user forKey:@"user"];
}

- (void)setPassword:(NSString *)pass;
{
    [self setOption:pass forKey:@"password"];
}

- (void)setResultEncodingToIANACharSetName:(NSString *)encodingName;
{
    if (nil == encodingName)
        encodingName = @"MARC-8";
    _charSetName = [encodingName copy];
    [_results removeAllObjects];
}

- (ZOOMResultSet *)resultsForQuery:(ZOOMQuery *)query;
{
    NSParameterAssert(nil != query);
    ZOOMResultSet *resultSet = [_results objectForKey:query];
    if (nil == resultSet) {
        [self connect];
        ZOOM_resultset r = ZOOM_connection_search(_connection, [query zoomQuery]);

        int error;
        const char *errmsg, *addinfo;
        if ((error = ZOOM_connection_error(_connection, &errmsg, &addinfo)))
            NSLog(@"Error: %s (%d) %s\n", errmsg, error, addinfo);

        resultSet = [[ZOOMResultSet allocWithZone:[self zone]] initWithZoomResultSet:r charSet:_charSetName];
        [_results setObject:resultSet forKey:query];
        [resultSet release];
    }
    return resultSet;
}

- (ZOOMResultSet *)resultsForCCLQuery:(NSString *)queryString;
{
    ZOOMQuery *query = [ZOOMQuery queryWithCCLString:queryString config:nil];
    return query ? [self resultsForQuery:query] : nil;
}

@end
