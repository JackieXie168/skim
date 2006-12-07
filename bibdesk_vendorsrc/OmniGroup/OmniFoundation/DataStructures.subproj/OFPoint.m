// Copyright 2003-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFPoint.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSScriptCoercionHandler.h>
#import <Foundation/NSValueTransformer.h>
#import <OmniFoundation/NSObject-OFExtensions.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFPoint.m 79079 2006-09-07 22:35:32Z kc $");

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

//
// NSCoding
//

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [aCoder encodeValueOfObjCType:@encode(typeof(_value)) at:&_value];
}

- (id)initWithCoder:(NSCoder *)aCoder;
{
    [aCoder decodeValueOfObjCType:@encode(typeof(_value)) at:&_value];
    return self;
}

//
// Property list support
- (NSMutableDictionary *)propertyListRepresentation;
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithFloat:_value.x], @"x", 
        [NSNumber numberWithFloat:_value.y], @"y", 
        nil];
}

+ (OFPoint *)pointFromPropertyListRepresentation:(NSDictionary *)dict;
{
    if (![dict objectForKey:@"x"] || ![dict objectForKey:@"y"])
        return nil;
    
    NSPoint point;
    point.x = [[dict objectForKey:@"x"] floatValue];
    point.y = [[dict objectForKey:@"y"] floatValue];
    return [OFPoint pointWithPoint:point];
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
		default:
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


// Value transformer
NSString *OFPointToPropertyListTransformerName = @"OFPointToPropertyListTransformer";

@interface OFPointToPropertyListTransformer : NSValueTransformer
@end

@implementation OFPointToPropertyListTransformer

+ (void)didLoad;
{
    [NSValueTransformer setValueTransformer:[[self alloc] init] forName:OFPointToPropertyListTransformerName];
}

+ (Class)transformedValueClass;
{
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation;
{
    return YES;
}

- (id)transformedValue:(id)value;
{
    if ([value isKindOfClass:[OFPoint class]])
	return [(OFPoint *)value propertyListRepresentation];
    return nil;
}

- (id)reverseTransformedValue:(id)value;
{
    if ([value isKindOfClass:[NSDictionary class]])
	return [OFPoint pointFromPropertyListRepresentation:value];
    return nil;
}

@end
