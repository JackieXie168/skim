// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/NSNumber-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSNumber-OFExtensions.m,v 1.9 2003/01/15 22:52:00 kc Exp $")

@implementation NSNumber (OFExtensions)

static NSCharacterSet *dotCharacterSet = nil;

- initWithString:(NSString *)aString;
{
    /*
     * Currently this is a little lame -- it only will figure out a few types
     * of numbers.
     */
    NSRange range;

    if (!dotCharacterSet)
	dotCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"."] retain];

    range = [aString rangeOfCharacterFromSet:dotCharacterSet];
    if (!range.length) {
	[self release];
	return [[NSNumber alloc] initWithInt:[aString intValue]];
    } else {
	[self release];
	return [[NSNumber alloc] initWithFloat:[aString floatValue]];
    }
}

@end
