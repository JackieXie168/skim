// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFNull.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFNull.m 68913 2005-10-03 19:36:19Z kc $")

@interface OFNullString : NSString
@end

@implementation OFNull

NSString *OFNullStringObject;
static OFNull *nullObject;

+ (void) initialize;
{
    OBINITIALIZE;

    nullObject = [[OFNull alloc] init];
    OFNullStringObject = [[OFNullString alloc] init];
}

+ (id)nullObject;
{
    return nullObject;
}

+ (NSString *)nullStringObject;
{
    return OFNullStringObject;
}

- (BOOL)isNull;
{
    return YES;
}

- (float)floatValue;
{
    return 0.0;
}

- (int)intValue;
{
    return 0;
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale
                             indent:(unsigned)level
{
    return @"*null*";
}

- (NSString *)description;
{
    return @"*null*";
}

- (NSString *)shortDescription;
{
    return [self description];
}

@end

@implementation OFObject (Null)

- (BOOL)isNull;
{
    return NO;
}

@end

@implementation NSObject (Null)

- (BOOL)isNull;
{
    return NO;
}

@end

@implementation NSNull (OFNull)
- (BOOL) isNull
{
    return YES;
}
@end

@implementation OFNullString

- (unsigned int)length;
{
    return 0;
}

- (unichar)characterAtIndex:(unsigned)anIndex;
{
    [NSException raise:NSRangeException format:@""];
    return '\0';
}

- (BOOL)isNull;
{
    return YES;
}

- (NSString *)description;
{
    return @"*null*";
}

- (NSString *)shortDescription;
{
    return [self description];
}

@end

#import <objc/Object.h>

@interface Object (Null)
- (BOOL)isNull;
@end

@implementation Object (Null)

- (BOOL)isNull;
{
    return NO;
}

@end

