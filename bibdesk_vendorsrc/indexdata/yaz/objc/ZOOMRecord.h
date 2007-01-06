//
//  ZOOMRecord.h
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

/*!
 @enum       ZOOMSyntaxType
 @abstract   Syntax types supported by the framework.
 @discussion Use these constants in favor of strings whenever possible.
 @constant   UNKNOWN 
 @constant   GRS1 
 @constant   SUTRS 
 @constant   USMARC 
 @constant   UKMARC 
 @constant   XML 
 */
enum {
	UNKNOWN = -1,
    GRS1    =  0,
    SUTRS   =  1,
    USMARC  =  2,
    UKMARC  =  3,
    XML     =  4
};
typedef int ZOOMSyntaxType;

/*!
    @class       ZOOMRecord 
    @superclass  NSObject
    @abstract    Provides a Cocoa interface to the low-level ZOOM_record results returned from a query.  Handles conversion to Unicode string objects.
    @discussion  Accessors are provided for the primary values of interest, but this object is KVC-compliant.  A list of valid keys is provided by the class method +validKeys; any key may return nil.  Values returned are NSData objects in the native encoding of the underlying ZOOM_record, unless you use one of the accessors that explicitly returns an NSString object.
*/
@interface ZOOMRecord : NSObject
{
    ZOOM_record          _record;
    NSString            *_charSetName;
    NSMutableDictionary *_representations;
}

/*!
    @method     validKeys
    @abstract   Provides a list of keys for which instances of the class are KVC-compliant.
    @result     An array of strings.
*/
+ (NSArray *)validKeys;

/*!
    @method     stringWithSyntaxType:
    @abstract   Returns a string description of the specified enumerated type value.
    @discussion Generally used by the framework to set options for a ZOOM_connection.
    @param      type The syntax type of interest.
*/
+ (NSString *)stringWithSyntaxType:(ZOOMSyntaxType)type;

/*!
    @method     syntaxTypeWithString:
    @abstract   Converts the given string to a syntax type.
    @discussion This comparison is case-insensitive, and ignores "-" characters.
    @param      string String description of the syntax type.
*/
+ (ZOOMSyntaxType)syntaxTypeWithString:(NSString *)string;

/*!
    @method     setFallbackEncoding:
    @abstract   Sets the fallback string encoding to be used when converting data to NSStrings.
    @discussion This is mainly useful for debugging, or if you don't know the encoding beforehand.
    @param      enc Pass kCFStringEncodingInvalidId to ensure that only the charset passed in initialization is used.
*/
+ (void)setFallbackEncoding:(NSStringEncoding)enc;

/*!
    @method     recordWithZoomRecord:charSet:
    @abstract   Factory method, returns an autoreleased instance.  See designated initializer for parameters.
*/
+ (id)recordWithZoomRecord:(ZOOM_record)record charSet:(NSString *)charSetName;

/*!
    @method     initWithZoomRecord:charSet:
    @abstract   Returns an initialized record instance using the provided ZOOM_record.  It copies the record in case the owning result set goes away.
    @param      record ZOOM_record, may not be nil.
    @param      charSetName An IANA character set name, used to convert data to NSStrings.  May not be nil.
*/
- (id)initWithZoomRecord:(ZOOM_record)record charSet:(NSString *)charSetName;

/*!
    @method     rawString
    @abstract   Converts the underlying data in its "raw" syntax to an NSString, using the character set supplied at initialization time.
    @discussion The directory information for character counts in a MARC record may not be correct if you use this accessor.  It converts the octets to a Unicode string, and the returned string length is not identical to the data length unless the record is entirely ASCII.
*/
- (NSString *)rawString;

/*!
    @method     renderedString
    @abstract   Converts the raw data to a format that is more-or-less human readable.
    @result     NSString instance.
*/
- (NSString *)renderedString;

/*!
    @method     stringValueForKey:
    @abstract   Converts the specified key to an NSString instance.
    @discussion Uses the character set passed at init time to create an NSString from the underlying data.
    @param      aKey An object for which instances of this class are KVC-compliant.
    @result     The call is responsible for retaining the value.  Guaranteed to be non-nil (may be the empty string).
*/
- (NSString *)stringValueForKey:(NSString *)aKey;

/*!
    @method     syntaxType
    @abstract   Returns the syntax type of the receiver.
    @discussion Other types (e.g. XML) may be available via an internal YAZ conversion.
    @result     Enumerated type.
*/
- (ZOOMSyntaxType)syntaxType;

@end
