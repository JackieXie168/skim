// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSNumberFormatter-OFFixes.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/NSDecimalNumber-OFExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSNumberFormatter-OFFixes.m,v 1.4 2003/01/15 22:52:00 kc Exp $")

@implementation NSNumberFormatter (OFFixes)

// In 10.1, NSNumberFormatter will incorrectly accept a string which is less than the formatter's minimum, or greater than the maximum, if it is zero and exactly fits the positive format.
//
// Examples:
// If you use the predefined integer formatter in IB (labeled "100 / -100"), and set a minimum of 10 and a maximum of 100, the string "0" is incorrectly accepted.  ("00", "0.0", etc. are still rejected.)
// If you use the default decimal formatter (labeled "9999.99 / -9999.99"), and set the same min/max, the string "0.00" is incorrectly accepted. ("0", "0.0", etc. are still rejected.)
//
// Fortunately, it's pretty easy to fix this.

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
