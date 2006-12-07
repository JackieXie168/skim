//
//  BDSKStringEncodingManager.m
//  BibDesk
//
//  Created by Adam Maxwell on 03/01/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKStringEncodingManager.h"

static BDSKStringEncodingManager *sharedEncodingManager = nil;

@implementation BDSKStringEncodingManager

+ (BDSKStringEncodingManager *)sharedEncodingManager{
    if(!sharedEncodingManager){
        sharedEncodingManager = [[BDSKStringEncodingManager alloc] init];
    }
    return sharedEncodingManager;
}

-(id)init{
    if(sharedEncodingManager != nil){
        [sharedEncodingManager release];
    } else if(self = [super init]){
        encodingsDict = [[self availableEncodings] retain];
    }
    return self;
}

- (void)dealloc{
    [encodingsDict release];
    [super dealloc];
}

// returns nil if no match can be found (NSNonLossyASCIIStringEncoding has no match)
// the names are correct, but terse.
- (NSString *)IANACharSetNameForEncoding:(NSStringEncoding)encoding{
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    
    if(cfEncoding == kCFStringEncodingInvalidId)
        return nil;

    return (NSString *)CFStringConvertEncodingToIANACharSetName(cfEncoding); 
}

- (NSDictionary *)availableEncodings{
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:[NSNumber numberWithInt:NSASCIIStringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSASCIIStringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSNEXTSTEPStringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSNEXTSTEPStringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSJapaneseEUCStringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSJapaneseEUCStringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSUTF8StringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSUTF8StringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSISOLatin1StringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSISOLatin1StringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSNonLossyASCIIStringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSNonLossyASCIIStringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSISOLatin2StringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSISOLatin2StringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSWindowsCP1251StringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSWindowsCP1251StringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSWindowsCP1252StringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSWindowsCP1252StringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSWindowsCP1253StringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSWindowsCP1253StringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSWindowsCP1254StringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSWindowsCP1254StringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSWindowsCP1250StringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSWindowsCP1250StringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSMacOSRomanStringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSMacOSRomanStringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSShiftJISStringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSShiftJISStringEncoding]];
    [dictionary setObject:[NSNumber numberWithInt:NSISO2022JPStringEncoding] forKey:[NSString localizedNameOfStringEncoding:NSISO2022JPStringEncoding]];
    
    return dictionary;
}

- (NSArray *)availableEncodingDisplayedNames{
    return [[NSMutableArray arrayWithArray:[encodingsDict allKeys]] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSNumber *)encodingNumberForDisplayedName:(NSString *)name{
    return [encodingsDict objectForKey:name];
}

- (NSStringEncoding)stringEncodingForDisplayedName:(NSString *)name{
    return [[encodingsDict objectForKey:name] intValue];
}

- (NSString *)displayedNameForStringEncoding:(NSStringEncoding)encoding{
    NSNumber *n = [NSNumber numberWithInt:encoding];
    NSArray *allKeys = [encodingsDict allKeysForObject:n];
    
    if([allKeys count] == 0){
        [NSException raise:NSStringFromClass([self class]) format:@"No matching encoding name was found for %@", n];
        return nil;
    }

    if([allKeys count] > 1){
        [NSException raise:NSStringFromClass([self class]) format:@"More than one encoding name found for %@", n];
        return nil;
    }
    
    return [allKeys objectAtIndex:0];
}
    

@end
