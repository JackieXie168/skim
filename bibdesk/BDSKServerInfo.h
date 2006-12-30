//
//  BDSKServerInfo.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 30/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKServerInfo : NSObject {
    int type;
    NSString *name;
    NSString *host;
    NSString *port;
    NSString *database;
    NSString *password;
    NSString *username;
}

- (id)initWithType:(int)aType name:(NSString *)aName host:(NSString *)aHost port:(NSString *)aPort database:(NSString *)aDbase password:(NSString *)aPassword username:(NSString *)aUser;
- (id)initWithType:(int)aType dictionary:(NSDictionary *)info;

- (NSDictionary *)dictionaryValue;

- (int)type;
- (NSString *)name;
- (NSString *)host;
- (NSString *)port;
- (NSString *)database;
- (NSString *)password;
- (NSString *)username;

@end
