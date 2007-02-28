//
//  ZOOMQuery.h
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
    @class       ZOOMQuery 
    @superclass  NSObject
    @abstract    Provides a convenient way to initialize a query instance to be used with a connection.
    @discussion  Unlike most of the classes in the Obj-C ZOOM API, this one is provided solely as a convenience for initializing and returning a primitive ZOOM type.  However, the underlying ZOOM_query should really only be used by the framework internally, and instances of the ZOOMQuery class should be used whenever possible.  This class conforms to NSCopying and instances may be used as keys in hashing collections.
*/
@interface ZOOMQuery : NSObject <NSCopying>
{
    ZOOM_query  _query;
    NSString   *_config;
    NSString   *_queryString;
}

/*!
    @method     queryWithCCLString:config:
    @abstract   Returns an autoreleased instance.  See designated initializer for parameters.
*/
+ (id)queryWithCCLString:(NSString *)queryString config:(NSString *)confString;

/*!
    @method     initWithCCLString:config:
    @abstract   CCL initializer.
    @discussion Creates and initializes a ZOOM_query instance using the provided query string.
    @param      queryString Should be a valid CCL query string.  See the YAZ documentation for supported syntax.
    @param      confString A configuration string that maps query terms to record fields.  Pass nil for the default.
    @result     Uses objc-default.bib as the default config, but other config strings may be provided.
*/
- (id)initWithCCLString:(NSString *)queryString config:(NSString *)confString;

/*!
    @method     zoomQuery
    @abstract   Returns an initialized ZOOM_query.
    @result     A ZOOM_query that may be used with a ZOOM_connection.
*/
- (ZOOM_query)zoomQuery;

@end

/*!
    @class       ZOOMCCLQueryFormatter 
    @superclass  NSFormatter
    @abstract    An NSFormatter subclass that validates the query syntax by attempting to convert it to RPN.  The formatter's control delegate should implement the appropriate failure message to display an error to the user.
*/
@interface ZOOMCCLQueryFormatter : NSFormatter
{
    const void *_config;
}

/*!
    @method     initWithConfigString:
    @abstract   Initializes an NSFormatter.
    @discussion (comprehensive description)
    @param      config A config string.  Pass nil or simply use -init to use the framework's objc-default.bib config.
*/
- (id)initWithConfigString:(NSString *)config;

@end
