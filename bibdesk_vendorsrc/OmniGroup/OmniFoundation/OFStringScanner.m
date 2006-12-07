// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFStringScanner.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFStringScanner.m,v 1.33 2004/02/10 04:07:41 kc Exp $")

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


