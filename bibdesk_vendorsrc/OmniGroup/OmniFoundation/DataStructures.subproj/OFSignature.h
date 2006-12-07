// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFSignature.h,v 1.9 2003/01/15 22:51:55 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSData;

// This is here so that those that want to define small buffers
// for a signature w/o yet having one can do so.
#define OF_SIGNATURE_LENGTH (20)

@interface OFSignature : OFObject
{
    void   *private;
    NSData *signatureData;
}

- initWithData: (NSData *) data;
- initWithBytes: (const void *) bytes length: (unsigned int) length;

- (void) addData: (NSData *) data;
- (void) addBytes: (const void *) bytes length: (unsigned int) length;

- (NSData *) signatureData;

@end
