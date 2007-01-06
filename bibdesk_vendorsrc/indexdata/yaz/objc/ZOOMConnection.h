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

- (id)initWithHost:(NSString *)hostName port:(int)portNum database:(NSString *)dbase;
- (id)initWithHost:(NSString *)hostName port:(int)portNum;

- (id)initWithPropertyList:(id)plist;
- (id)propertyList;

// pass nil for option to clear options for a particular key
- (void)setOption:(NSString *)option forKey:(NSString *)key;
- (NSString *)optionForKey:(NSString *)key;

// convenience methods that use setOption:forKey:
- (void)setUsername:(NSString *)user;
- (void)setPassword:(NSString *)pass;

// default record syntax is USMARC
- (void)setPreferredRecordSyntax:(ZOOMSyntaxType)type;

// pass nil to use MARC-8 (default)
- (void)setResultEncodingToIANACharSetName:(NSString *)encodingName;

- (ZOOMResultSet *)resultsForQuery:(ZOOMQuery *)query;

// add methods for other query syntaxes as needed
- (ZOOMResultSet *)resultsForCCLQuery:(NSString *)queryString;

@end
