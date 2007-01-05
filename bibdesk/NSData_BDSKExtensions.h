//
//  NSData_BDSKExtensions.h
//  Bibdesk
//
//  Created by Adam Maxwell on 09/06/06.
/*
 This software is Copyright (c) 2006,2007
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

#import <Cocoa/Cocoa.h>

extern NSString *BDSKEncodingConversionException;

@interface NSMutableData (BDSKExtensions)

/*!
    @method     appendUTF8DataFromStringstring
    @abstract   Appends the string to the receiver as UTF-8 data bytes.
    @discussion (comprehensive description)
*/
- (void)appendUTF8DataFromString:(NSString *)string;

/*!
    @method     appendDataFromString:encoding:error:error
    @abstract   Appends the string to the receiver using the specified data representation.  Raises BDSKEncodingConversionException exception if the conversion did not occur losslessly.
    @discussion (comprehensive description)
    @param      string (description)
    @param      encoding (description)
    @param      error (description)
*/
- (BOOL)appendDataFromString:(NSString *)string encoding:(NSStringEncoding)encoding error:(NSError **)error;

/*!
    @method     appendStringData:convertedFromUTF8ToEncoding:error:error
    @abstract   Appends the string data to the receiver after converting it from UTF-8 encoding to the specified encoding.
    @discussion (comprehensive description)
    @param      data (description)
    @param      ecoding (description)
*/
- (BOOL)appendStringData:(NSData *)data convertedFromUTF8ToEncoding:(NSStringEncoding)encoding error:(NSError **)error;

/*!
    @method     appendStringData:convertedFromEncoding:toEncoding:error:error
    @abstract   Appends the string data to the receiver after converting it using the specified encodings.  Raises BDSKEncodingConversionException exception if the conversion did not occur losslessly.
    @discussion (comprehensive description)
    @param      data (description)
    @param      fromEncoding (description)
    @param      toEncoding (description)
    @param      error (description)
*/
- (BOOL)appendStringData:(NSData *)data convertedFromEncoding:(NSStringEncoding)fromEncoding toEncoding:(NSStringEncoding)toEncoding error:(NSError **)error;

@end
