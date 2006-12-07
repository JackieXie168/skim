// Copyright 1999-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFFastMutableData.h,v 1.7 2004/02/10 04:07:43 kc Exp $

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
