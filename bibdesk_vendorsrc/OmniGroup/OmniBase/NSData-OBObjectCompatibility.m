// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniBase/NSData-OBObjectCompatibility.h>

#import <Foundation/Foundation.h>

#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/NSData-OBObjectCompatibility.m,v 1.10 2003/01/15 22:51:46 kc Exp $")

@implementation NSData (OBObjectCompatibility)

unsigned int NSDataShortDescriptionLength = 40;

- (NSString *)shortDescription;
{
    NSString                   *description;

    description = [self description];
    if ([description length] <= NSDataShortDescriptionLength)
	return description;
    return [[description substringToIndex:NSDataShortDescriptionLength]
            stringByAppendingString:@"..."];
}

@end

