// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniBase/NSObject-OBObjectCompatibility.h>

#import <Foundation/Foundation.h>

#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/NSObject-OBObjectCompatibility.m,v 1.13 2004/02/10 04:07:39 kc Exp $")

@implementation NSObject (OBObjectCompatibility)

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary        *debugDictionary;

    debugDictionary = [NSMutableDictionary dictionary];
    [debugDictionary setObject:[self shortDescription] forKey:@"__self__"];

    return debugDictionary;
}

- (NSString *)shortDescription;
{
    return [self description];
}

@end
