// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFStringScanner.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFStringScanner.m,v 1.31 2003/01/15 22:51:51 kc Exp $")

@implementation OFStringScanner

- initWithString:(NSString *)aString;
{
    if ([super init] == nil)
	return nil;

    targetString = [aString retain];
    [self fetchMoreDataFromString:aString];

    return self;
}

- (void)dealloc;
{
    [targetString release];
    [super dealloc];
}

@end


