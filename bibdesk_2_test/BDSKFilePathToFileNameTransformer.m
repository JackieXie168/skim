//
//  BDSKFilePathToFileNameTransformer.m
//  bd2xtest
//
//  Created by Michael McCracken on 5/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKFilePathToFileNameTransformer.h"


@implementation BDSKFilePathToFileNameTransformer
+ (Class)transformedValueClass { return [NSString self]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
    if (value == nil){
        return nil;
    }else{
        return [(NSString *)value lastPathComponent];
    }
}

@end
