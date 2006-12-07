//
//  NSData_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 09/06/06.
/*
 This software is Copyright (c) 2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSData_BDSKExtensions.h"

NSString *BDSKEncodingConversionException = @"BDSKEncodingConversionException";

@implementation NSMutableData (BDSKExtensions)

- (void)appendUTF8DataFromString:(NSString *)string;
{
    [self appendDataFromString:string useEncoding:NSUTF8StringEncoding];
}

// OmniFoundation implements an identical method (hence our different method signature); however, they raise an NSInvalidArgumentException, and I want something less generic.

- (void)appendDataFromString:(NSString *)string useEncoding:(NSStringEncoding)encoding;
{
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    
    // try this first; generally locale-specific, but it's really fast if it works
    const char *cstringPtr = CFStringGetCStringPtr((CFStringRef)string, cfEncoding);
    if (cstringPtr) {
        // Omni uses strlen, but it returns incorrect length for some strings with strange Unicode characters (bug #1558548)
        CFIndex length = CFStringGetLength((CFStringRef)string);
        CFIndex bufLen;
        CFIndex convertedLength = CFStringGetBytes((CFStringRef)string, CFRangeMake(0, length), cfEncoding, 0, FALSE, NULL, UINT_MAX, &bufLen);
        if (convertedLength != length)
            [NSException raise:BDSKEncodingConversionException format:@"Unable to convert string to encoding %@", [NSString localizedNameOfStringEncoding:encoding]];
        [self appendBytes:cstringPtr length:bufLen];
    } else {
        CFDataRef data = CFStringCreateExternalRepresentation(CFAllocatorGetDefault(), (CFStringRef)string, cfEncoding, 0);
     
        // raise if the conversion wasn't possible, since we're not using a loss byte
        if (NULL == data)
            [NSException raise:BDSKEncodingConversionException format:@"Unable to convert string to encoding %@", [NSString localizedNameOfStringEncoding:encoding]];
        
        // safe to append/CFRelease since the NULL case won't reach this point
        [self appendData:(NSData *)data];
        CFRelease(data);
    }
}

@end
