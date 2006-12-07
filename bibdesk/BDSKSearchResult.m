//
//  BDSKSearchResult.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/12/05.
/*
 This software is Copyright (c) 2005
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

#import "BDSKSearchResult.h"


@implementation BDSKSearchResult

- (id)initWithKey:(NSString *)key
{
    if(![super init])
        return nil;
    
    comparisonKey = [key copy];
    dictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
    hash = [comparisonKey hash];
    
    return self;
}

- (void)dealloc
{
    [comparisonKey release];
    [dictionary release];
    [super dealloc];
}

- (NSString *)comparisonKey
{
    return comparisonKey;
}

- (unsigned int)hash
{
    return hash;
}

- (BOOL)isEqual:(id)anObject
{
    if(anObject == self)
        return YES;
    
    return ([[anObject comparisonKey] isEqualToString:comparisonKey] ? YES : NO);
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return [dictionary valueForKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    [dictionary setValue:value forKey:key];
}

@end

