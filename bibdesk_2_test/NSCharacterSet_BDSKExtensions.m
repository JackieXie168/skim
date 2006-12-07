//
//  NSCharacterSet_BDSKExtensions.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 18/5/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSCharacterSet_BDSKExtensions.h"


@implementation NSCharacterSet (BDSKExtensions)

static NSCharacterSet *curlyBraceCharacterSet = nil;
static NSCharacterSet *newlineCharacterSet = nil;

+ (NSCharacterSet *)curlyBraceCharacterSet;
{  
    if (curlyBraceCharacterSet == nil)
        curlyBraceCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"{}"] retain];
    return curlyBraceCharacterSet; 
}    

+ (NSCharacterSet *)newlineCharacterSet;
{
   if (newlineCharacterSet == nil) {
         // character set with all newline characters (including the weird Unicode ones)
        CFMutableCharacterSetRef newlineCFCharacterSet = NULL;
        newlineCFCharacterSet = CFCharacterSetCreateMutableCopy(CFAllocatorGetDefault(), CFCharacterSetGetPredefined(kCFCharacterSetWhitespace));
        CFCharacterSetInvert(newlineCFCharacterSet); // no whitespace in this one, but it also has all letters...
        CFCharacterSetIntersect(newlineCFCharacterSet, CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline));
        newlineCharacterSet = [(id)newlineCFCharacterSet copy];
        CFRelease(newlineCFCharacterSet);
    }
    return newlineCharacterSet;
}

@end
