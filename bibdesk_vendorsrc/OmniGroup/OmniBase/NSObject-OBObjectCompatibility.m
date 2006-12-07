// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniBase/NSObject-OBObjectCompatibility.h>

#import <Foundation/Foundation.h>

#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniBase/NSObject-OBObjectCompatibility.m 68913 2005-10-03 19:36:19Z kc $")

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
