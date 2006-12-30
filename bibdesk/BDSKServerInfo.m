//
//  BDSKServerInfo.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 30/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKServerInfo.h"
#import "BDSKSearchGroup.h"
#import "NSString_BDSKExtensions.h"


@implementation BDSKServerInfo

- (id)initWithType:(int)aType name:(NSString *)aName host:(NSString *)aHost port:(NSString *)aPort database:(NSString *)aDbase password:(NSString *)aPassword username:(NSString *)aUser;
{
    if (self = [super init]) {
        type = aType;
        name = [aName copy];
        if (type == BDSKSearchGroupEntrez) {
            host = nil;
            port = nil;
            database = [aDbase copy];
            password = nil;
            username = nil;
        } else {
            host = [aHost copy];
            port = [aPort copy];
            database = [aDbase copy];
            password = [aPassword copy];
            username = [aUser copy];
        }
    }
    return self;
}

- (id)initWithType:(int)aType dictionary:(NSDictionary *)info;
{
    self = [self initWithType:aType
                         name:[[info objectForKey:@"name"] stringByUnescapingGroupPlistEntities]
                         host:[[info objectForKey:@"host"] stringByUnescapingGroupPlistEntities]
                         port:[[info objectForKey:@"port"] stringByUnescapingGroupPlistEntities]
                     database:[[info objectForKey:@"database"] stringByUnescapingGroupPlistEntities]
                     password:[[info objectForKey:@"password"] stringByUnescapingGroupPlistEntities]
                     username:[[info objectForKey:@"username"] stringByUnescapingGroupPlistEntities]];
    return self;
}

- (id)copy {
    return [self initWithType:[self type] name:[self name] host:[self host] port:[self port] database:[self database] password:[self password] username:[self username]];
}

- (void)dealloc {
    [name release];
    [host release];
    [port release];
    [database release];
    [password release];
    [username release];
    [super dealloc];
}

static inline BOOL BDSKIsEqualOrNil(id first, id second) {
    return (first == nil && second == nil) || [first isEqual:second];
}

- (BOOL)isEqual:(id)other {
    BOOL isEqual = NO;
    // we don't compare the name, as that is just a label
    if ([self isMemberOfClass:[other class]] == NO || [self type] != [(BDSKServerInfo *)other type])
        isEqual = NO;
    else if ([self type] == BDSKSearchGroupEntrez)
        isEqual = BDSKIsEqualOrNil([self database], [other database]);
    else
        isEqual = BDSKIsEqualOrNil([self host], [other host]) && BDSKIsEqualOrNil([self port], [other port]) && BDSKIsEqualOrNil([self database], [other database]) && BDSKIsEqualOrNil([self password], [other password]) && BDSKIsEqualOrNil([self username], [other username]);
    return isEqual;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:7];
    [info setValue:[NSNumber numberWithInt:[self type]] forKey:@"type"];
    [info setValue:[self name] forKey:@"name"];
    if ([self type] == BDSKSearchGroupEntrez) {
        [info setValue:[[self database] stringByEscapingGroupPlistEntities] forKey:@"database"];
    } else {
        [info setValue:[[self host] stringByEscapingGroupPlistEntities] forKey:@"host"];
        [info setValue:[[self port] stringByEscapingGroupPlistEntities] forKey:@"port"];
        [info setValue:[[self database] stringByEscapingGroupPlistEntities] forKey:@"database"];
        [info setValue:[[self password] stringByEscapingGroupPlistEntities] forKey:@"password"];
        [info setValue:[[self username] stringByEscapingGroupPlistEntities] forKey:@"username"];
    }
    return info;
}

- (int)type { return type; }

- (NSString *)name { return name; }

- (NSString *)host { return host; }

- (NSString *)port { return port; }

- (NSString *)database { return database; }

- (NSString *)password { return password; }

- (NSString *)username { return username; }

@end
