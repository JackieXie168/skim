// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFPoint.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSScriptCoercionHandler.h>
#import <OmniFoundation/NSObject-OFExtensions.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFPoint.m,v 1.5 2004/02/10 04:07:43 kc Exp $");

/*
 A smarter wrapper for NSPoint than NSValue.  Used in OAVectorStyleAttribute.  This also has some AppleScript hooks (which are different from how OmniGraffle handles points -- i.e., we do not register a 'point' class).  Points in AppleScript are traditionally just 2 element lists.
*/

@interface OFPoint (PrivateAPI)
+ (NSArray *)_coercePoint:(OFPoint *)aPoint toArrayClass:(Class)aClass;
+ (OFPoint *)_coerceArray:(NSArray *)object toPointClass:(Class)pointClass;
@end

@implementation OFPoint

+ (void)initialize;
{
    OBINITIALIZE;

    // There is some chance that this will need to be a +didLoad, but we'd really like to avoid that if possible.
    NSScriptCoercionHandler *handler = [NSScriptCoercionHandler sharedCoercionHandler];
    [handler registerCoercer:self selector:@selector(_coercePoint:toArrayClass:) toConvertFromClass:self toClass:[NSArray class]];
    [handler registerCoercer:self selector:@selector(_coerceArray:toPointClass:) toConvertFromClass:[NSArray class] toClass:self];
}


+ (OFPoint *)pointWithPoint:(NSPoint)point;
{
    return [[[self alloc] initWithPoint:point] autorelease];
}

- initWithPoint:(NSPoint)point;
{
    _value = point;
    return self;
}

- initWithString:(NSString *)string;
{
    _value = NSPointFromString(string);
    return self;
}

- (NSPoint)point;
{
    return _value;
}

- (BOOL)isEqual:(id)otherObject;
{
    if (![otherObject isKindOfClass:[OFPoint class]])
        return NO;
    return NSEqualPoints(_value, ((OFPoint *)otherObject)->_value);
}

- (NSString *)description;
{
    return NSStringFromPoint(_value);
}

//
// NSCopying
//
- (id)copyWithZone:(NSZone *)zone;
{
    // We are immutable!
    return [self retain];
}

@end


@implementation OFPoint (PrivateAPI)
+ (OFPoint *)_coerceArray:(NSArray *)array toPointClass:(Class)pointClass;
{
    // Default unspecified elements to zero and ignore extra elements
    NSPoint point;
    switch ([array count]) {
        case 0:
            point = NSZeroPoint;
            break;
        case 1:
            point.x = [[array objectAtIndex:0] floatValue];
            point.y = 0.0f;
            break;
        case 2:
            point.x = [[array objectAtIndex:0] floatValue];
            point.y = [[array objectAtIndex:1] floatValue];
            break;
    }
    return [self pointWithPoint:point];
}

+ (NSArray *)_coercePoint:(OFPoint *)aPoint toArrayClass:(Class)aClass;
{
    NSPoint point = [aPoint point];
    return [NSArray arrayWithObjects:[NSNumber numberWithFloat:point.x], [NSNumber numberWithFloat:point.y], nil];
}

@end

