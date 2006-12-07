//
//  BDSKStringEncodingManager.m
//  Bibdesk
//
//  Created by Adam Maxwell on 03/01/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

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

- (NSDictionary *)availableEncodings{
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:[NSNumber numberWithInt:NSASCIIStringEncoding] forKey:@"ASCII (TeX)"];
    [dictionary setObject:[NSNumber numberWithInt:NSNEXTSTEPStringEncoding] forKey:@"NEXTSTEP"];
    [dictionary setObject:[NSNumber numberWithInt:NSJapaneseEUCStringEncoding] forKey:@"Japanese EUC"];
    [dictionary setObject:[NSNumber numberWithInt:NSUTF8StringEncoding] forKey:@"UTF-8"];
    [dictionary setObject:[NSNumber numberWithInt:NSISOLatin1StringEncoding] forKey:@"ISO Latin 1"];
    [dictionary setObject:[NSNumber numberWithInt:NSNonLossyASCIIStringEncoding] forKey:@"Non-lossy ASCII"];
    [dictionary setObject:[NSNumber numberWithInt:NSISOLatin2StringEncoding] forKey:@"ISO Latin 2"];
    [dictionary setObject:[NSNumber numberWithInt:NSUnicodeStringEncoding] forKey:@"Unicode"];
    [dictionary setObject:[NSNumber numberWithInt:NSWindowsCP1251StringEncoding] forKey:@"Cyrillic"];
    [dictionary setObject:[NSNumber numberWithInt:NSWindowsCP1252StringEncoding] forKey:@"Windows Latin 1"];
    [dictionary setObject:[NSNumber numberWithInt:NSWindowsCP1253StringEncoding] forKey:@"Greek"];
    [dictionary setObject:[NSNumber numberWithInt:NSWindowsCP1254StringEncoding] forKey:@"Turkish"];
    [dictionary setObject:[NSNumber numberWithInt:NSWindowsCP1250StringEncoding] forKey:@"Windows Latin 2"];
    [dictionary setObject:[NSNumber numberWithInt:NSMacOSRomanStringEncoding] forKey:@"Mac OS Roman"];
    [dictionary setObject:[NSNumber numberWithInt:NSShiftJISStringEncoding] forKey:@"Shift JIS"];
    [dictionary setObject:[NSNumber numberWithInt:NSISO2022JPStringEncoding] forKey:@"ISO 2022"];
    
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
