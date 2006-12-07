// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFSignature.h,v 1.12 2004/02/10 04:07:43 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSData;

// This is here so that those that want to define small buffers
// for a signature w/o yet having one can do so.
#define OF_SIGNATURE_LENGTH (20)

@interface OFSignature : OFObject
{
    void   *_private;
    NSData *_signatureData;
}

- initWithData: (NSData *) data;
- initWithBytes: (const void *) bytes length: (unsigned int) length;

- (void) addData: (NSData *) data;
- (void) addBytes: (const void *) bytes length: (unsigned int) length;

- (NSData *) signatureData;

@end
