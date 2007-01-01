//
//  BDSKZoomRecord.m
//  yaz
//
//  Created by Adam Maxwell on 12/26/06.
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

#import "BDSKZoomRecord.h"
#import "yaz-iconv.h"
#import "z-core.h"
#include "zoom-p.h"

// could specify explicit character set conversions in the keys, but that's not very flexible
static NSString *renderKey = @"render";
static NSString *rawKey = @"raw";

@interface BDSKZoomRecord (Private)
- (void)cacheRepresentationForKey:(NSString *)aKey;
@end

@implementation BDSKZoomRecord

static NSStringEncoding fallbackEncoding = kCFStringEncodingInvalidId;

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
    // Note: yaz_matchstr() is case-insensitive and removes "-" characters
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

+ (id)recordWithZoomRecord:(ZOOM_record)record encoding:(NSStringEncoding)encoding;
{
    return [[[self allocWithZone:[self zone]] initWithZoomRecord:record encoding:encoding] autorelease];
}

- (id)initWithZoomRecord:(ZOOM_record)record encoding:(NSStringEncoding)encoding;
{
    self = [super init];
    if (self) {
        
        if(record){
            // copy it, since the owning result set could go away
            _record = ZOOM_record_clone(record);
            _representations = [[NSMutableDictionary allocWithZone:[self zone]] init];
            _recordEncoding = encoding;
            
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

// this doesn't use valueForKey:, since cacheRepresentationForKey: calls syntaxType
- (BDSKZoomSyntaxType)syntaxType;
{
    const char *cstr = ZOOM_record_get(_record, "syntax", NULL);
    return [BDSKZoomRecord syntaxTypeWithString:[NSString stringWithUTF8String:cstr]];
}

@end

@implementation BDSKZoomRecord (Private)

// yaz_iconv() usage example is in record_iconv_return() in zoom-c.c
static NSData *copyMARC8BytesToUTF8(const char *buf)
{
    yaz_iconv_t cd = 0;
    size_t sz = strlen(buf);
    
    NSMutableData *outputData = [[NSMutableData alloc] initWithCapacity:sz];
    
    if ((cd = yaz_iconv_open("utf-8", "marc-8")))
    {
        char outbuf[12];
        size_t inbytesleft = sz;
        const char *inp = buf;
                
        while (inbytesleft)
        {
            size_t outbytesleft = sizeof(outbuf);
            char *outp = outbuf;
            size_t r = yaz_iconv(cd, (char**) &inp, &inbytesleft,  &outp, &outbytesleft);
            
            if (r == (size_t) (-1))
            {
                int e = yaz_iconv_error(cd);
                if (e != YAZ_ICONV_E2BIG) {
                    [outputData release];
                    outputData = nil;
                    break;
                }
            }
            [outputData appendBytes:outbuf length:(outp - outbuf)];
        }
        yaz_iconv_close(cd);
    }
    return outputData;
}

// Returns IANA charset names, except for MARC-8 (which doesn't have one, and prevents us from using NSStringEncoding).  This relies on poking around in the ZOOM_record structure, which is generally a bad idea, but follows the same code as client.c for autodetection of encoding.  This is useful for debugging, or for determining if a MARC record is UTF-8, since the octet_buf[9] check is defined by the spec.
- (NSString *)guessedCharSetName;
{
    Z_NamePlusRecord *npr;
    npr = _record->npr;
    
    Z_External *r = (Z_External *)npr->u.databaseRecord;
    
    const char *guessedSet = NULL;

    if (r->which == Z_External_octet) {
        
        oident *ent = oid_getentbyoid(r->direct_reference);
        const char *octet_buf = (char*)r->u.octet_aligned->buf;
        
        char *charset = NULL;

        if (ent->value == VAL_USMARC) {
            if (octet_buf[9] == 'a')
                charset = "UTF-8";
            else
                charset = "MARC-8";
        } else {
            charset = "ISO-8859-1";
        }
        guessedSet = charset;
    }
    return guessedSet ? [NSString stringWithUTF8String:guessedSet] : nil;
}    

- (void)cacheRepresentationForKey:(NSString *)aKey;
{
    /* MARC-8 is a common encoding for MARC, but useless everywhere else.  We can pass "render;charset=marc-8,utf-8" to specify a source and destination charset, but yaz defaults to UTF-8 as destination.  
     
     - For keys without a specified charset, bytes are returned without conversion.
     - The "raw" key always ignores charset options.
     
     see http://www.loc.gov/marc/specifications/specchartables.html
     
     */

    id nsString = nil;
    const char *cstr = ZOOM_record_get(_record, [aKey UTF8String], NULL);
    if (NULL != cstr) {
        
        BDSKZoomSyntaxType type = [self syntaxType];
        NSData *utf8Data;
        
        // MARC records use MARC-8 encoding (MARC-21 is supposed to be UTF-8)
        // !!! Since there's no NSStringEncoding for MARC-8, we'll check the syntax type to see if that's what we should use.  Perhaps we should use a zero encoding to signify that MARC-8 is used?
        if ((USMARC == type || UKMARC == type) && (utf8Data = copyMARC8BytesToUTF8(cstr))) {
            nsString = [[NSString allocWithZone:[self zone]] initWithData:utf8Data encoding:NSUTF8StringEncoding];
        } else {
            // If it's not MARC, we'll hope that the sender knows the correct encoding, and use _recordEncoding; this is required for e.g. XML that is explicitly encoded as iso-8859-1 (COPAC does this).
            nsString = [[NSString allocWithZone:[self zone]] initWithCString:cstr encoding:_recordEncoding];
        }
        
        // should mainly be useful for debugging
        if (nil == nsString && kCFStringEncodingInvalidId != fallbackEncoding)
            nsString = [[NSString allocWithZone:[self zone]] initWithCString:cstr encoding:fallbackEncoding];
    }
    
    // if a given key fails, set @"" so we don't compute it again
    [_representations setObject:(nsString ? nsString : @"") forKey:aKey];
}

@end
