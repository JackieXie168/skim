//
//  BDSKZoomRecord.m
//  yaz
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKZoomRecord.h"

@interface BDSKZoomRecord (Private)
- (void)cacheRepresentationForKey:(NSString *)aKey;
@end

@implementation BDSKZoomRecord

static NSStringEncoding fallbackEncoding = 0;

+ (void)setFallbackEncoding:(NSStringEncoding)enc;
{
    fallbackEncoding = enc;
}

+ (NSArray *)validKeys
{
    static NSArray *keys = nil;
    if (nil == keys)
        keys = [[NSArray alloc] initWithObjects:@"render", @"xml", @"raw", @"ext", @"opac", nil];
    return keys;
}

+ (id)recordWithZoomRecord:(ZOOM_record)record;
{
    return [[[self allocWithZone:[self zone]] initWithZoomRecord:record] autorelease];
}

- (id)initWithZoomRecord:(ZOOM_record)record;
{
    self = [super init];
    if (self) {
        
        // copy it, since the owning result set could go away
        _record = ZOOM_record_clone(record);
        _representations = [[NSMutableDictionary allocWithZone:[self zone]] init];
        
        // make sure we always have these
        [self cacheRepresentationForKey:@"render"];
        [self cacheRepresentationForKey:@"raw"];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\n *** %@\n ***", [super description], [self renderedString]];
}

- (void)dealloc
{
    ZOOM_record_destroy(_record);
    [_representations release];
    [super dealloc];
}

- (id)valueForUndefinedKey:(NSString *)aKey
{
    id value = [_representations objectForKey:aKey];
    if (nil == value) {
        [self cacheRepresentationForKey:aKey];
        value = [_representations objectForKey:aKey];
    }
    return value;
}

- (NSString *)renderedString;
{
    return [_representations objectForKey:@"render"];
}

- (NSString *)rawString;
{
    return [_representations objectForKey:@"raw"];
}

@end

@implementation BDSKZoomRecord (Private)

- (void)cacheRepresentationForKey:(NSString *)aKey;
{
    // !!! The key can use e.g. "render;charset=ISO-8859-1" to specify the record's charset, but from the source, it looks like it only converts to UTF-8.  I get weird conversion failures with Library of Congress' server searching for "ventin", so fall back to 8859-1 in that case.  I'm not really sure what the problem is.

    id nsString = nil;
    const char *cstr = ZOOM_record_get(_record, [aKey UTF8String], NULL);
    if (NULL != cstr) {
        nsString = [[NSString allocWithZone:[self zone]] initWithUTF8String:cstr];
        if (nil == nsString && fallbackEncoding)
            nsString = [[NSString allocWithZone:[self zone]] initWithCString:cstr encoding:fallbackEncoding];
    }
    [_representations setObject:(nsString ? nsString : @"") forKey:aKey];
}

@end
