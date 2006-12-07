// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSMutableData-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableData-OFExtensions.m,v 1.13 2004/02/10 04:07:45 kc Exp $")

@implementation NSMutableData (OFExtensions)

/* TODO: These should really use word operators as much as possible */

- (void) andWithData: (NSData *) aData;
{
    unsigned char              *bytes;
    const unsigned char        *otherBytes;
    unsigned long               length;

    OBPRECONDITION(aData);
    OBPRECONDITION([self length] == [aData length]);

    length = [self length];
    bytes = (unsigned char *)[self mutableBytes];
    otherBytes = (const unsigned char *)[aData bytes];

    while (length--)
	*bytes++ &= *otherBytes++;
}


- (void) orWithData: (NSData *) aData;
{
    unsigned char              *bytes;
    const unsigned char        *otherBytes;
    unsigned long               length;

    OBPRECONDITION(aData);
    OBPRECONDITION([self length] == [aData length]);

    length = [self length];
    bytes = (unsigned char *)[self mutableBytes];
    otherBytes = (const unsigned char *)[aData bytes];

    while (length--)
	*bytes++ |= *otherBytes++;
}


- (void) xorWithData: (NSData *) aData;
{
    unsigned char              *bytes;
    const unsigned char        *otherBytes;
    unsigned long               length;

    OBPRECONDITION(aData);
    OBPRECONDITION([self length] == [aData length]);

    length = [self length];
    bytes = (unsigned char *)[self mutableBytes];
    otherBytes = (const unsigned char *)[aData bytes];

    while (length--)
	*bytes++ ^= *otherBytes++;
}

@end
