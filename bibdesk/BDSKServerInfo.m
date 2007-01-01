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

+ (id)defaultServerInfoWithType:(NSString *)aType;
{
    return [[[[self class] alloc] initWithType:aType 
                                          name:NSLocalizedString(@"New Server",@"")
                                          host:BDSKSearchGroupEntrez ? nil : @"host.domain.com"
                                          port:[aType isEqualToString:BDSKSearchGroupEntrez] ? nil : @"0" 
                                      database:@"database" 
                                      password:nil
                                      username:nil
                                       options:[NSDictionary dictionary]] autorelease];
}

- (id)initWithType:(NSString *)aType name:(NSString *)aName host:(NSString *)aHost port:(NSString *)aPort database:(NSString *)aDbase password:(NSString *)aPassword username:(NSString *)aUser options:(NSDictionary *)opts;
{
    if (self = [super init]) {
        type = [aType copy];
        name = [aName copy];
        if ([[self type] isEqualToString:BDSKSearchGroupEntrez]) {
            host = nil;
            port = nil;
            database = [aDbase copy];
            password = nil;
            username = nil;
            options = nil;
        } else {
            host = [aHost copy];
            port = [aPort copy];
            database = [aDbase copy];
            password = [aPassword copy];
            username = [aUser copy];
            options = [opts mutableCopy];
        }
    }
    return self;
}

- (id)initWithType:(NSString *)aType name:(NSString *)aName host:(NSString *)aHost port:(NSString *)aPort database:(NSString *)aDbase password:(NSString *)aPassword username:(NSString *)aUser;
{
    return [self initWithType:aType name:aName host:aHost port:aPort database:aDbase password:aPassword username:aUser options:[NSDictionary dictionary]];
}

- (id)initWithType:(NSString *)aType dictionary:(NSDictionary *)info;
{
    NSMutableDictionary *opts = [[[info objectForKey:@"options"] mutableCopy] autorelease];
    NSEnumerator *keyEnum = [opts  keyEnumerator];
    NSString *key;
    id value;
    while (key = [keyEnum nextObject]) {
        value = [opts objectForKey:key];
        if ([value respondsToSelector:@selector(stringByUnescapingGroupPlistEntities)])
            [opts setObject:[value stringByUnescapingGroupPlistEntities] forKey:key];
    }
    
    self = [self initWithType:aType
                         name:[[info objectForKey:@"name"] stringByUnescapingGroupPlistEntities]
                         host:[[info objectForKey:@"host"] stringByUnescapingGroupPlistEntities]
                         port:[[info objectForKey:@"port"] stringByUnescapingGroupPlistEntities]
                     database:[[info objectForKey:@"database"] stringByUnescapingGroupPlistEntities]
                     password:[[info objectForKey:@"password"] stringByUnescapingGroupPlistEntities]
                     username:[[info objectForKey:@"username"] stringByUnescapingGroupPlistEntities]
                      options:opts];
    return self;
}

- (id)copyWithZone:(NSZone *)aZone {
    id copy = [[[self class] allocWithZone:aZone] initWithType:[self type] name:[self name] host:[self host] port:[self port] database:[self database] password:[self password] username:[self username] options:[self options]];
    return copy;
}

- (void)dealloc {
    [type release];
    [name release];
    [host release];
    [port release];
    [database release];
    [password release];
    [username release];
    [options release];
    [super dealloc];
}

static inline BOOL BDSKIsEqualOrNil(id first, id second) {
    return (first == nil && second == nil) || [first isEqual:second];
}

- (BOOL)isEqual:(id)other {
    BOOL isEqual = NO;
    // we don't compare the name, as that is just a label
    if ([self isMemberOfClass:[other class]] == NO || [[self type] isEqualToString:[(BDSKServerInfo *)other type]] == NO)
        isEqual = NO;
    else if ([[self type] isEqualToString:BDSKSearchGroupEntrez])
        isEqual = BDSKIsEqualOrNil([self database], [other database]);
    else
        isEqual = BDSKIsEqualOrNil([self host], [other host]) && BDSKIsEqualOrNil([self port], [other port]) && BDSKIsEqualOrNil([self database], [other database]) && BDSKIsEqualOrNil([self password], [other password]) && BDSKIsEqualOrNil([self username], [other username]);
    return isEqual;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:7];
    [info setValue:[self type] forKey:@"type"];
    [info setValue:[self name] forKey:@"name"];
    if ([[self type] isEqualToString:BDSKSearchGroupEntrez]) {
        [info setValue:[[self database] stringByEscapingGroupPlistEntities] forKey:@"database"];
    } else {
        NSMutableDictionary *opts = [[[self options] mutableCopy] autorelease];
        NSEnumerator *keyEnum = [opts  keyEnumerator];
        NSString *key;
        id value;
        while (key = [keyEnum nextObject]) {
            value = [opts objectForKey:key];
            if ([value respondsToSelector:@selector(stringByEscapingGroupPlistEntities)])
                [opts setObject:[value stringByEscapingGroupPlistEntities] forKey:key];
        }
        
        [info setValue:[[self host] stringByEscapingGroupPlistEntities] forKey:@"host"];
        [info setValue:[[self port] stringByEscapingGroupPlistEntities] forKey:@"port"];
        [info setValue:[[self database] stringByEscapingGroupPlistEntities] forKey:@"database"];
        [info setValue:[[self password] stringByEscapingGroupPlistEntities] forKey:@"password"];
        [info setValue:[[self username] stringByEscapingGroupPlistEntities] forKey:@"username"];
        [info setValue:opts forKey:@"options"];
    }
    return info;
}

- (NSString *)type { return type; }

- (NSString *)name { return name; }

- (NSString *)host { return host; }

- (NSString *)port { return port; }

- (NSString *)database { return database; }

- (NSString *)password { return password; }

- (NSString *)username { return username; }

- (NSDictionary *)options { return options; }

- (void)setType:(NSString *)t;
{
    [type autorelease];
    type = [t copy];
}

- (void)setName:(NSString *)s;
{
    [name autorelease];
    name = [s copy];
}

- (void)setPort:(NSString *)p;
{
    [port autorelease];
    port = [p copy];
}

- (void)setHost:(NSString *)h;
{
    [host autorelease];
    host = [h copy];
}

- (void)setDatabase:(NSString *)d;
{
    [database autorelease];
    database = [d copy];
}

- (void)setPassword:(NSString *)p;
{
    [password autorelease];
    password = [p copy];
}

- (void)setUsername:(NSString *)u;
{
    [username autorelease];
    username = [u copy];
}

- (void)setOptions:(NSDictionary *)o;
{
    [options autorelease];
    options = [o mutableCopy];
}

- (BOOL)validateHost:(id *)value error:(NSError **)error {
    NSString *string = *value;
    NSRange range = [string rangeOfString:@"://"];
    if(range.location != NSNotFound){
        // ZOOM gets confused when the host has a protocol
        string = [string substringFromIndex:NSMaxRange(range)];
    }
    // split address:port/dbase in components
    range = [string rangeOfString:@"/"];
    if(range.location != NSNotFound){
        [self setDatabase:[string substringFromIndex:NSMaxRange(range)]];
        string = [string substringToIndex:range.location];
    }
    range = [string rangeOfString:@":"];
    if(range.location != NSNotFound){
        [self setPort:[string substringFromIndex:NSMaxRange(range)]];
        string = [string substringToIndex:range.location];
    }
    *value = string;
    return YES;
}

- (BOOL)validatePort:(id *)value error:(NSError **)error {
    if (nil != *value)
    *value = [NSString stringWithFormat:@"%i", [*value intValue]];
    return YES;
}


@end
