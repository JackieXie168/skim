// Copyright 2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSComparisonPredicate-OFExtensions.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header$");

#if defined(MAC_OS_X_VERSION_10_4) && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4

@implementation NSComparisonPredicate (OFExtensions)

+ (NSPredicate *)isKindOfClassPredicate:(Class)cls;
{
    NSExpression *classExpression = [NSExpression expressionForConstantValue:cls];
    NSExpression *inputObject = [NSExpression expressionForEvaluatedObject];
    return [[NSComparisonPredicate predicateWithLeftExpression:inputObject rightExpression:classExpression customSelector:@selector(isKindOfClass:)] retain];
}

+ (NSPredicate *)conformsToProtocolPredicate:(Protocol *)protocol;
{
    NSExpression *protocolExpression = [NSExpression expressionForConstantValue:protocol];
    NSExpression *inputObject = [NSExpression expressionForEvaluatedObject];
    return [[NSComparisonPredicate predicateWithLeftExpression:inputObject rightExpression:protocolExpression customSelector:@selector(conformsToProtocol:)] retain];
}

@end

#endif
