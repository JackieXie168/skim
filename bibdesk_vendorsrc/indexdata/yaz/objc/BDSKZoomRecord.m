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

@interface NSString (BDSKZoomExtensions)
// avoid polluting the NSString namespace by using this ugly prefix...
+ (NSStringEncoding)ZOOM_encodingWithIANACharSetName:(NSString *)charSetName;
@end


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

+ (id)recordWithZoomRecord:(ZOOM_record)record charSet:(NSString *)charSetName;
{
    return [[[self allocWithZone:[self zone]] initWithZoomRecord:record charSet:charSetName] autorelease];
}

- (id)initWithZoomRecord:(ZOOM_record)record charSet:(NSString *)charSetName;
{
    NSParameterAssert(NULL != record);
    NSParameterAssert(nil != charSetName);
    self = [super init];
    if (self) {        
        // copy it, since the owning result set could go away
        _record = ZOOM_record_clone(record);
        _representations = [[NSMutableDictionary allocWithZone:[self zone]] init];
        _charSetName = [charSetName copy];
        
        // make sure we always have these
        [self cacheRepresentationForKey:renderKey];
        [self cacheRepresentationForKey:rawKey];
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
    [_charSetName release];
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
static NSData *copyMARC8BytesToUTF8(const char *buf, int length)
{
    yaz_iconv_t cd = 0;
    size_t sz = length;
    
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

// This relies on poking around in the ZOOM_record structure, which is generally a bad idea, but follows the same code as client.c for autodetection of encoding.  This is useful for debugging, or for determining if a MARC record is UTF-8, since the octet_buf[9] check is defined by the spec.  Unfortunately, it doesn't work with aleph.unibas.ch:9909/IDS_ANSEL which returns the 'a' even for MARC-8.  That seems like a server problem, but means that we shouldn't try to guess encoding.
- (NSStringEncoding)guessedEncoding;
{
    Z_NamePlusRecord *npr;
    npr = _record->npr;
    
    Z_External *r = (Z_External *)npr->u.databaseRecord;
    
    NSStringEncoding enc = kCFStringEncodingInvalidId;
    
    if (r->which == Z_External_octet) {
        
        oident *ent = oid_getentbyoid(r->direct_reference);
        const char *octet_buf = (char*)r->u.octet_aligned->buf;
                
        if (ent->value == VAL_USMARC) {
            if (octet_buf[9] == 'a')
                enc = NSUTF8StringEncoding;
            else
                enc = kCFStringEncodingInvalidId;
        } else {
            enc = NSISOLatin1StringEncoding;
        }
    }
    return enc;
}

// Returns IANA charset names, except for MARC-8 (which doesn't have one).  
- (NSString *)guessedCharSetName;
{
    NSStringEncoding enc = [self guessedEncoding];
    return (kCFStringEncodingInvalidId != enc) ? (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(enc)) : @"MARC-8";
}

- (void)cacheRepresentationForKey:(NSString *)aKey;
{
    /* MARC-8 is a common encoding for MARC, but useless everywhere else.  We can pass "render;charset=marc-8,utf-8" to specify a source and destination charset, but yaz defaults to UTF-8 as destination.  
     
     - For keys without a specified charset in the key, bytes are returned without conversion.
     - The "raw" key always ignores charset options.
     - Checking syntax type is unreliable as a proxy for character set.
     - kCFStringEncodingInvalidId indicates that we should use MARC-8.
     - strlen() may give wrong results for MARC buffers, so should be avoided.
     
     see http://www.loc.gov/marc/specifications/specchartables.html
     
     */

    NSString *nsString = nil;
    int length;
    
    // length will be -1 for some types, so we'll use strlen for those
    const void *bytes = ZOOM_record_get(_record, [aKey UTF8String], &length);
    if (-1 == length)
        length = strlen((const char *)bytes);
    
    if (NULL != bytes) {
                
        NSData *utf8Data = nil;
        NSStringEncoding enc = [NSString ZOOM_encodingWithIANACharSetName:_charSetName];
        if (kCFStringEncodingInvalidId != enc) {
            // We'll hope that the sender knows the correct encoding; this is required for e.g. XML that is explicitly encoded as iso-8859-1 (COPAC does this).
            nsString = [[NSString allocWithZone:[self zone]] initWithBytes:bytes length:length encoding:enc];  
            
        } else if((utf8Data = copyMARC8BytesToUTF8(bytes, length))) {
            // now we've assumed it was MARC-8
            nsString = [[NSString allocWithZone:[self zone]] initWithData:utf8Data encoding:NSUTF8StringEncoding];
            [utf8Data release];
        }
        
        // should mainly be useful for debugging
        if (nil == nsString && kCFStringEncodingInvalidId != fallbackEncoding)
            nsString = [[NSString allocWithZone:[self zone]] initWithBytes:bytes length:length encoding:fallbackEncoding];
    }
    
    // if a given key fails, set @"" so we don't compute it again
    [_representations setObject:(nsString ? nsString : @"") forKey:aKey];
}

@end

@implementation NSString (BDSKZoomExtensions)

// yaz_iconv() usage example is in record_iconv_return() in zoom-c.c
- (const char *)ZOOM_MARC8String;
{
    const char *buf = [self UTF8String];
    yaz_iconv_t cd = 0;
    size_t sz = strlen(buf);
    
    NSMutableData *outputData = [NSMutableData dataWithCapacity:sz];
    
    if ((cd = yaz_iconv_open("marc-8", "utf-8")))
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
    const char terminator = 0;
    // have to null-terminate!
    [outputData appendBytes:&terminator length:sizeof(char)];
    return [outputData bytes];
}   

// Converts the _charSetName ivar to an encoding; returns kCFStringEncodingInvalidId for unrecognized names (ANSEL, MARC-8)
+ (NSStringEncoding)ZOOM_encodingWithIANACharSetName:(NSString *)charSetName;
{
    CFStringEncoding cfEnc = kCFStringEncodingInvalidId;
    if (charSetName)
        cfEnc = CFStringConvertIANACharSetNameToEncoding((CFStringRef)charSetName);
    return (kCFStringEncodingInvalidId != cfEnc) ? CFStringConvertEncodingToNSStringEncoding(cfEnc) : cfEnc;
}

@end

