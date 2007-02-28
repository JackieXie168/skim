//
//  ZOOMConnection.h
//  yaz
//
//  Created by Adam Maxwell on 12/25/06.
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
#import <yaz/ZOOMResultSet.h>
#import <yaz/ZOOMRecord.h>

@class ZOOMQuery;

/*!
    @class       ZOOMConnection 
    @superclass  NSObject
    @abstract    This is the primary interface with the ZOOM objects.
    @discussion  ZOOMConnection allows you to create a connection, set various options, and fetch results for a given query.  All instance variables are private, and should not be relied upon.  A new ZOOMConnection instance should be created for a given host, which allows cleaner caching and option handling.  The connection is not established until results are asked for.
*/
@interface ZOOMConnection : NSObject 
{
    @private
    ZOOM_connection       _connection;
    NSString             *_hostName;
    int                   _portNum;
    NSString             *_dataBase;
    NSString             *_charSetName;    // can force result encoding, since we require a connection per-host
    
    NSString             *_connectHost;    // derived from arguments
    NSMutableDictionary  *_results;        // results cached by query
    NSMutableDictionary  *_options;        // copy explicitly set ZOOM_options
}

/*!
    @method     initWithHost:port:database:
    @abstract   Designated initializer.
    @discussion Creates and initializes a new instance, with default record syntax of USMARC and result encoding of MARC-8.
    @param      hostName Must not be nil.  May take the form "host.domain.com:port/database" if portNum is zero.
    @param      portNum Port number on the remote host.
    @param      dbase Database name.
    @result     (description)
*/
- (id)initWithHost:(NSString *)hostName port:(int)portNum database:(NSString *)dbase;

/*!
    @method     initWithPropertyList:
    @abstract   Initializes a new connection using the supplied property list, which should be provided by -propertyList.
    @discussion Property list keys are private and should not be relied upon.
    @param      plist (description)
    @result     (description)
*/
- (id)initWithPropertyList:(id)plist;

/*!
    @method     propertyList
    @abstract   Returns a property list representation of the receiver, suitable for archiving.
    @discussion Should only be used in conjunction with -initWithPropertyList:.  Keys are private.
    @result     (description)
*/
- (id)propertyList;

/*!
    @method     setOption:forKey:
    @abstract   Sets options for the underlying ZOOM_connection instance.  Any valid ZOOM_connection option and key may be supplied.
    @discussion (comprehensive description)
    @param      option Option value.  Pass nil to clear the option.
    @param      key Option name.
*/
- (void)setOption:(NSString *)option forKey:(NSString *)key;

/*!
    @method     optionForKey:
    @abstract   Returns the current ZOOM_connection option value for the specified key.
    @param      key (description)
    @result     (description)
*/
- (NSString *)optionForKey:(NSString *)key;

/*!
    @method     setUsername:
    @abstract   Calls setOption:forKey: with the correct key.
    @param      user (description)
*/
- (void)setUsername:(NSString *)user;

/*!
    @method     setPassword:
    @abstract   Calls setOption:forKey: with the correct key.
    @param      pass Password is not encrypted.
*/
- (void)setPassword:(NSString *)pass;

// default record syntax is USMARC
/*!
    @method     setPreferredRecordSyntax:
    @abstract   Calls setOption:forKey: with the correct key, converting type to a string.
    @discussion Sets the preferredRecordSyntax option on the ZOOM_connection.  Valid options are given by the ZOOMSyntaxType enum.
    @param      type Must be a valid ZOOMSyntaxType, or uses "Unknown".
*/
- (void)setPreferredRecordSyntax:(ZOOMSyntaxType)type;

/*!
    @method     setResultEncodingToIANACharSetName:
    @abstract   Sets the encoding that will be used when interpreting results.  This is not the charset used for communication.
    @discussion This is really a result option, but is server-specific, so provided here as a convenience.
    @param      encodingName Must be a valid IANA character set name.  Pass nil to use MARC-8 (default).
*/
- (void)setResultEncodingToIANACharSetName:(NSString *)encodingName;

/*!
    @method     resultsForQuery:
    @abstract   Returns results for the given query.  Returns nil in case of failure, and error messages may be loggged to the console.
    @param      query An initialized query object.  May not be nil.
    @result     Returns all results available for the given query.
*/
- (ZOOMResultSet *)resultsForQuery:(ZOOMQuery *)query;

/*!
    @method     resultsForCCLQuery:
    @abstract   Creates a ZOOMQuery instance from the provided string and returns the result of resultsForQuery:.
    @discussion This is a quick method to get results, but has no options for configuring the query.
    @param      queryString Must be a valid CCL query.
    @result     Returns nil in case of a failure.
*/
- (ZOOMResultSet *)resultsForCCLQuery:(NSString *)queryString;

@end
