//
//  BDSKServerInfo.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 12/30/06.
/*
 This software is Copyright (c) 2006
 Christiaan Hofman. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Christiaan Hofman nor the names of any
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


@interface BDSKServerInfo : NSObject <NSCopying, NSMutableCopying> {
    NSString *type;
    NSString *name;
    NSString *host;
    NSString *port;
    NSString *database;
    NSString *password;
    NSString *username;
    NSMutableDictionary *options;
}

+ (id)defaultServerInfoWithType:(NSString *)aType;

- (id)initWithType:(NSString *)aType name:(NSString *)aName host:(NSString *)aHost port:(NSString *)aPort database:(NSString *)aDbase password:(NSString *)aPassword username:(NSString *)aUser options:(NSDictionary *)options;
- (id)initWithType:(NSString *)aType name:(NSString *)aName host:(NSString *)aHost port:(NSString *)aPort database:(NSString *)aDbase password:(NSString *)aPassword username:(NSString *)aUser;

- (id)initWithType:(NSString *)aType dictionary:(NSDictionary *)info;

- (NSDictionary *)dictionaryValue;

- (NSString *)type;
- (NSString *)name;
- (NSString *)host;
- (NSString *)port;
- (NSString *)database;
- (NSString *)password;
- (NSString *)username;
- (NSDictionary *)options;

@end

@interface BDSKMutableServerInfo : BDSKServerInfo {
    id delegate;
}

- (void)setDelegate:(id)newDelegate;
- (id)delegate;

- (void)setType:(NSString *)t;
- (void)setName:(NSString *)s;
- (void)setPort:(NSString *)p;
- (void)setHost:(NSString *)h;
- (void)setDatabase:(NSString *)d;
- (void)setPassword:(NSString *)p;
- (void)setUsername:(NSString *)u;
- (void)setOptions:(NSDictionary *)o;

@end
