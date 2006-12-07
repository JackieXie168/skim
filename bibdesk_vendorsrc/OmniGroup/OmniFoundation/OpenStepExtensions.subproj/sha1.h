// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/sha1.h,v 1.10 2003/01/15 22:52:01 kc Exp $

#import <OmniFoundation/FrameworkDefines.h>

#define SHA1_SIGNATURE_LENGTH 20

typedef struct {
    unsigned long state[5];
    unsigned long count[2];
    unsigned char buffer[64];
} SHA1_CTX;

// Use OmniFoundation_PRIVATE_EXTERN so these functions are available within this framework, but not exported outside of the framework.
OmniFoundation_PRIVATE_EXTERN void SHA1Init(SHA1_CTX* context);
OmniFoundation_PRIVATE_EXTERN void SHA1Update(SHA1_CTX* context, const unsigned char* data, unsigned int len);
OmniFoundation_PRIVATE_EXTERN void SHA1Final(unsigned char digest[SHA1_SIGNATURE_LENGTH], SHA1_CTX* context);

