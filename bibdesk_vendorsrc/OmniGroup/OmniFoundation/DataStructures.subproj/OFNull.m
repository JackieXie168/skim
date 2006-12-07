// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFNull.h>

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFNull.m,v 1.9 2003/01/15 22:51:55 kc Exp $")

@interface OFNullString : NSString
@end

@implementation OFNull

NSString *OFNullStringObject;
static OFNull *nullObject;

+ (void) initialize;
{
    static BOOL                 initialized = NO;

    [super initialize];

    if (initialized)
	return;

    initialized = YES;
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

@implementation Object (Null)

- (BOOL)isNull;
{
    return NO;
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
