//
//  BDSKZoomQuery.m
//  yaz
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKZoomQuery.h"

@implementation BDSKZoomQuery

+ (id)queryWithCCLString:(NSString *)queryString config:(NSString *)confString;
{
    return [[[self allocWithZone:[self zone]] initWithCCLString:queryString config:confString] autorelease];
}

+ (NSString *)defaultConfigString;
{
    static NSString *config = nil;
    if (nil == config) {
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.sourceforge.bibdesk.yaz"];
        config = [[NSString alloc] initWithContentsOfFile:[bundle pathForResource:@"default" ofType:@"bib"] encoding:NSASCIIStringEncoding error:NULL];
        if (nil == config) config = [@"" copy];
    }
    return config;
}

+ (const char *)defaultConfigCString;
{
    static const char *config = NULL;
    if (NULL == config) {
        NSString *str = [self defaultConfigString];
        unsigned len = ([str lengthOfBytesUsingEncoding:NSASCIIStringEncoding] + 1);
        char *buf = NSZoneMalloc(NULL, sizeof(char) * len);
        [str getCString:buf maxLength:len encoding:NSASCIIStringEncoding];
        config = buf ? buf : "";
    }
    return config;
}

- (id)initWithCCLString:(NSString *)queryString config:(NSString *)confString;
{
    self = [super init];
    if (self){
        
        const char *conf = NULL;
        
        if (confString) {
            _config = [confString copy];
            conf = [confString UTF8String];
        } else {
            _config = [[[self class] defaultConfigString] copy];
            conf = [[self class] defaultConfigCString];
        }
        
        _query = ZOOM_query_create();
        _queryString = [queryString copy];
        
        int status, error, errorPosition;
        const char *errstring;
        status = ZOOM_query_ccl2rpn(_query, [_queryString UTF8String], conf, &error, &errstring, &errorPosition);
        if (status) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void)dealloc
{
    ZOOM_query_destroy(_query);
    [_queryString release];
    [_config release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone { return [self retain]; }

- (unsigned int)hash { return [_queryString hash]; }

- (BOOL)isEqualToQuery:(BDSKZoomQuery *)aQuery;
{
    if (self == aQuery)
        return YES;
    return [_queryString isEqualToString:(aQuery->_queryString)] && [_config isEqualToString:(aQuery->_config)];
}

- (BOOL)isEqual:(id)other
{
    if ([other isKindOfClass:[self class]])
        return [other isEqualToQuery:self];
    return NO;
}

- (ZOOM_query)zoomQuery { return _query; }

@end

        
@implementation BDSKZoomCCLQueryFormatter

- (NSString *)stringForObjectValue:(id)obj { return obj; }

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error;
{
    BOOL success;
    if (string && [@"" isEqualToString:string] == NO) {
        int status, err, errorPosition;
        const char *errstring;
        ZOOM_query query = ZOOM_query_create();
        status = ZOOM_query_ccl2rpn(query, [string UTF8String], [BDSKZoomQuery defaultConfigCString], &err, &errstring, &errorPosition);
        if (status) {
            if (error) *error = [NSString stringWithFormat:@"%s (at position %d).", errstring, errorPosition];
            success = NO;
        } else {
            success = YES;
        }
        ZOOM_query_destroy(query);
    } else {
        success = YES;
    }
    *obj = string;
    return success;
}

@end

