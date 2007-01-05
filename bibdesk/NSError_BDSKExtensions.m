//
//  NSError_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/15/06.
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

#import "NSError_BDSKExtensions.h"

static NSString *BDSKErrorDomain = @"net.sourceforge.bibdesk.errors";
NSString *BDSKUnderlyingItemErrorKey = @"BDSKUnderlyingItemError";

@interface BDSKMutableError : NSError
{
    @private
    NSMutableDictionary *mutableUserInfo;
}
@end

@implementation BDSKMutableError

- (id)initWithDomain:(NSString *)domain code:(int)code userInfo:(NSDictionary *)dict;
{
    if (self = [super initWithDomain:domain code:code userInfo:nil]) {
        mutableUserInfo = [[NSMutableDictionary alloc] init];
        [mutableUserInfo addEntriesFromDictionary:dict];
        // we override code with our own storage so it can be set
        [self setCode:code];
    }
    return self;
}

- (id)initLocalErrorWithCode:(int)code localizedDescription:(NSString *)description;
{
    if (self = [self initWithDomain:[NSError localErrorDomain] code:code userInfo:nil]) {
        [self setValue:description forKey:NSLocalizedDescriptionKey];
    }
    return self;
}

- (void)dealloc
{
    [mutableUserInfo release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)aZone
{
    return [[NSError alloc] initWithDomain:[self domain] code:[self code] userInfo:[self userInfo]];
}

- (NSDictionary *)userInfo
{
    return mutableUserInfo;
}

- (id)valueForUndefinedKey:(NSString *)aKey
{
    return [[self userInfo] valueForKey:aKey];
}

// allow setting nil values
- (void)setValue:(id)value forUndefinedKey:(NSString *)key;
{
    if (value)
        [mutableUserInfo setValue:value forKey:key];
}

- (void)embedError:(NSError *)underlyingError;
{
    [self setValue:underlyingError forKey:NSUnderlyingErrorKey];
}

- (void)setCode:(int)code;
{
    [self setValue:[NSNumber numberWithInt:code] forKey:@"__BDSKErrorCode"];
}

- (int)code;
{
    return [[self valueForKey:@"__BDSKErrorCode"] intValue];
}

@end

@implementation NSError (BDSKExtensions)

+ (NSString *)localErrorDomain { return BDSKErrorDomain; }

- (BOOL)isLocalError;
{
    return [[self domain] isEqualToString:[NSError localErrorDomain]];
}

+ (id)mutableLocalErrorWithCode:(int)code localizedDescription:(NSString *)description;
{
    [[self init] release];
    return [[[BDSKMutableError alloc] initLocalErrorWithCode:code localizedDescription:description] autorelease];
}

+ (id)mutableErrorWithDomain:(NSString *)domain code:(int)code userInfo:(NSDictionary *)dict;
{
    [[self init] release];
    return [[[BDSKMutableError alloc] initWithDomain:domain code:code userInfo:dict] autorelease];
}

+ (id)mutableLocalErrorWithCode:(int)code localizedDescription:(NSString *)description underlyingError:(NSError *)underlyingError;
{
    [[self init] release];
    id error = [NSError mutableLocalErrorWithCode:code localizedDescription:description];
    [error embedError:underlyingError];
    return error;
}

- (id)mutableCopyWithZone:(NSZone *)aZone;
{
    return [[BDSKMutableError allocWithZone:aZone] initWithDomain:[self domain] code:[self code] userInfo:[self userInfo]];
}

- (void)embedError:(NSError *)underlyingError;
{
    [NSException raise:NSInternalInconsistencyException format:@"Mutating method sent to immutable NSError instance"];
}

- (void)setCode:(int)code;
{
    [NSException raise:NSInternalInconsistencyException format:@"Mutating method sent to immutable NSError instance"];
}

- (id)valueForUndefinedKey:(NSString *)aKey
{
    return [[self userInfo] valueForKey:aKey];
}

@end
