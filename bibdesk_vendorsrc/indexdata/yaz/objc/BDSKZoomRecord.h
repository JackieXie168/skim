//
//  BDSKZoomRecord.h
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

#import <Cocoa/Cocoa.h>
#import <yaz/zoom.h>

typedef enum {
	UNKNOWN,
    GRS1,
    SUTRS,
    USMARC,
    UKMARC,
    XML
} BDSKZoomSyntaxType;

@interface BDSKZoomRecord : NSObject
{
    ZOOM_record          _record;
    NSString            *_charSetName;
    NSMutableDictionary *_representations;
}

+ (NSArray *)validKeys;
+ (NSString *)stringWithSyntaxType:(BDSKZoomSyntaxType)type;
+ (BDSKZoomSyntaxType)syntaxTypeWithString:(NSString *)string;

// encoding of 0 (not used) means that only UTF-8 will be tried
+ (void)setFallbackEncoding:(NSStringEncoding)enc;

+ (id)recordWithZoomRecord:(ZOOM_record)record charSet:(NSString *)charSetName;
- (id)initWithZoomRecord:(ZOOM_record)record charSet:(NSString *)charSetName;

- (NSString *)renderedString;
- (NSString *)rawString;
- (NSData *)rawData;
- (BDSKZoomSyntaxType)syntaxType;

@end
