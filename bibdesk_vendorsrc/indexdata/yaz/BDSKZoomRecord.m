//
//  BDSKZoomRecord.m
//  yaz
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKZoomRecord.h"

static NSString *renderKey = @"render;charset=marc-8";
static NSString *rawKey = @"raw;charset=marc-8";

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
        keys = [[NSArray alloc] initWithObjects:@"render", @"xml", @"raw", @"ext", @"opac", @"syntax", nil];
    return keys;
}

+ (NSString *)stringWithSyntaxType:(BDSKZoomSyntaxType)type;
{
    switch (type) {
    case XML:
        return @"xml";
    case GRS1:
        return @"grs-1";
    case SUTRS:
        return @"sutrs";
    case USMARC:
        return @"usmarc";
    case UKMARC:
        return @"ukmarc";
    default:
        return @"unknown";
    }
}

+ (BDSKZoomSyntaxType)syntaxTypeWithString:(NSString *)string;
{
    // these calls and the corresponding enum were lifted from zrec.cpp in yazpp-1.0.0
    const char *syn = [string UTF8String];

    // These string constants are from yaz/util/oid.c
    if (!yaz_matchstr(syn, "xml"))
        return XML;
    else if (!yaz_matchstr(syn, "GRS-1"))
        return GRS1;
    else if (!yaz_matchstr(syn, "SUTRS"))
        return SUTRS;
    else if (!yaz_matchstr(syn, "USmarc"))
        return USMARC;
    else if (!yaz_matchstr(syn, "UKmarc"))
        return UKMARC;
    else if (!yaz_matchstr(syn, "XML") ||
             !yaz_matchstr(syn, "text-XML") ||
             !yaz_matchstr(syn, "application-XML"))
        return XML;
    else 
        return UNKNOWN;
}

+ (id)recordWithZoomRecord:(ZOOM_record)record;
{
    return [[[self allocWithZone:[self zone]] initWithZoomRecord:record] autorelease];
}

- (id)initWithZoomRecord:(ZOOM_record)record;
{
    self = [super init];
    if (self) {
        
        if(record){
            // copy it, since the owning result set could go away
            _record = ZOOM_record_clone(record);
            _representations = [[NSMutableDictionary allocWithZone:[self zone]] init];
            
            // make sure we always have these
            [self cacheRepresentationForKey:renderKey];
            [self cacheRepresentationForKey:rawKey];
        }else{
            [self release];
            self = nil;
        }
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
    return [_representations objectForKey:renderKey];
}

- (NSString *)rawString;
{
    return [_representations objectForKey:rawKey];
}

- (BDSKZoomSyntaxType)syntaxType;
{
    return [BDSKZoomRecord syntaxTypeWithString:[self valueForKey:@"syntax"]];
}

@end

@implementation BDSKZoomRecord (Private)

- (void)cacheRepresentationForKey:(NSString *)aKey;
{
    /* !!! The key can use e.g. "render;charset=ISO-8859-1" to specify the record's charset, but from the source, it looks like it only converts to UTF-8.  I get weird conversion failures with Library of Congress' server searching for "ventin", so fall back to 8859-1 in that case.  I'm not really sure what the problem is.  
     
     Update: looks like we need to pass marc-8 as the encoding, so the caller should be aware of that.
     */

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
