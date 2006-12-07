// 
//  BDSKKeyValuePair.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 18/5/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKKeyValuePair.h"
#import "BDSKComplexString.h"

#import "BDSKPublication.h"

@implementation BDSKKeyValuePair 

- (NSString *)value 
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"value"];
    tmpValue = [self primitiveValueForKey: @"value"];
    [self didAccessValueForKey: @"value"];
    
    if (tmpValue == nil) {
        NSString *bibtexValue = [self valueForKey:@"bibtexValue"];
        tmpValue = [BDSKComplexString complexStringWithBibTeXString:bibtexValue macroResolver:nil];
        [self setPrimitiveValue:tmpValue forKey:@"value"];
    }
    
    return tmpValue;
}

- (void)willSave {
    NSString *value = [self primitiveValueForKey:@"value"];
    [self setPrimitiveValue:[value stringAsBibTeXString] forKey:@"bibtexValue"];
    
    [super willSave];
}

@end
