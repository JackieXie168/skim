// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniBase/NSData-OBObjectCompatibility.h>

#import <Foundation/Foundation.h>

#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/NSData-OBObjectCompatibility.m,v 1.12 2004/02/10 04:07:39 kc Exp $")

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

