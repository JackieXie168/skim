// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFFastMutableData.h,v 1.5 2003/01/15 22:51:53 kc Exp $

#import <Foundation/NSData.h>

@interface OFFastMutableData : NSMutableData
{
    OFFastMutableData   *_nextBlock;

    unsigned int         _realLength;
    void                *_realBytes;

    unsigned int         _currentLength;
    void                *_currentBytes;
}
+ (OFFastMutableData *) newFastMutableDataWithLength: (unsigned) length;

- (void) fillWithZeros;

// NSData methods
- (unsigned) length;
- (const void *) bytes;

// NSMutableData methods
- (void *) mutableBytes;


- (void) setStartingOffset: (unsigned) offset;
- (unsigned) startingOffset;

- (void) setLength: (unsigned) length;

@end
