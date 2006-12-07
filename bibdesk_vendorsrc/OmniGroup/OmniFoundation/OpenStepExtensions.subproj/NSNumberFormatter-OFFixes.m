// Copyright 2001-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSNumberFormatter-OFFixes.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/NSDecimalNumber-OFExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSNumberFormatter-OFFixes.m,v 1.8 2004/02/10 04:07:46 kc Exp $")

#ifdef FIX_NSFORMATTER_BUG_12753

@implementation NSNumberFormatter (OFFixes)

// In 10.1, NSNumberFormatter will incorrectly accept a string which is less than the formatter's minimum, or greater than the maximum, if it is zero and exactly fits the positive format.
//
// Examples:
// If you use the predefined integer formatter in IB (labeled "100 / -100"), and set a minimum of 10 and a maximum of 100, the string "0" is incorrectly accepted.  ("00", "0.0", etc. are still rejected.)
// If you use the default decimal formatter (labeled "9999.99 / -9999.99"), and set the same min/max, the string "0.00" is incorrectly accepted. ("0", "0.0", etc. are still rejected.)
//
// Fortunately, it's pretty easy to fix this.

/*
 TJW 2003/07/02: Tested on 10.2.6 and this seems to work now
 The following test case reports a error description of 'Fell short of minimum'.

 int main (int argc, const char * argv[])
 {
     NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

     NSNumberFormatter *formatter;

     formatter = [[NSNumberFormatter alloc] init];
     [formatter setNegativeFormat: @"-100"];
     [formatter setPositiveFormat: @"100"];
     [formatter setMinimum: (NSDecimalNumber *)[NSDecimalNumber numberWithInt: 10]];
     [formatter setMaximum: (NSDecimalNumber *)[NSDecimalNumber numberWithInt: 100]];

     NSNumber *value;
     NSString *errorDescription;
     if (![formatter getObjectValue:&value forString:@"-1" errorDescription:&errorDescription]) {
         NSLog(@"Unable to get replacement object for string: %@", errorDescription);
     } else {
         NSLog(@"value = %@", value);
     }

     [pool release];
     return 0;
 }
 */

static BOOL (*originalGetObjectValue)(id, SEL, id *, NSString *, NSString **);

+ (void)performPosing;
{
    originalGetObjectValue = (typeof(originalGetObjectValue))OBReplaceMethodImplementationWithSelector((Class)self, @selector(getObjectValue:forString:errorDescription:), @selector(replacementGetObjectValue:forString:errorDescription:));
    OBPOSTCONDITION(originalGetObjectValue != NULL);
}

- (BOOL)replacementGetObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error;
{
    BOOL result;
    
    result = originalGetObjectValue(self, _cmd, obj, string, error);
    if (result) {
        NSDecimalNumber *number;
        
        if (obj && (number = *obj) && [NSDecimalNumber decimalNumberIsEqualToZero:number]) {
            NSDecimalNumber *min, *max;
            
            min = [self minimum];
            if (min && ![min isNotANumber] && [number isLessThanDecimalNumber:min])
                return NO;

            max = [self maximum];
            if (max && ![max isNotANumber] && [number isGreaterThanDecimalNumber:max])
                return NO;
        }
    }

    return result;
}

@end

#endif  /* FIX_NSFORMATTER_BUG_12753 */

