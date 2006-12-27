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

- (id)initWithCCLString:(NSString *)queryString config:(NSString *)confString;
{
    self = [super init];
    if (self){
        if (nil == confString)
            confString = @"term t=l,r s=al\n" "ti u=4 s=pw\n";
        
        _query = ZOOM_query_create();
        _config = [confString copy];
        _queryString = [queryString copy];
        
        int status, error, errorPosition;
        const char *errstring;
        status = ZOOM_query_ccl2rpn(_query, [_queryString UTF8String], [_config UTF8String], &error, &errstring, &errorPosition);
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
