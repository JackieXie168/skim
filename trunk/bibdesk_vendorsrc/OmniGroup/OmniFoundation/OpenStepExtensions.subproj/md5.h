// Copyright 1999-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/md5.h 68913 2005-10-03 19:36:19Z kc $
//
// Most of the contents of this file are owned by RSA Data Security, and
// are thus subject to RSA's license (see copyright below).

// This is an implementation of the MD5 Message Digest Algorithm (derived, somewhat indirectly, from the reference implementation in RFC 1321).

#import <OmniFoundation/FrameworkDefines.h>
#import <string.h>

// These redefinitions keep our symbols from clashing with other peoples' inclusions of MD5 into applications, bundles, etc.
#define MD5Init OFMD5Init
#define MD5Update OFMD5Update
#define MD5Final OFMD5Final

/* MD5.H - header file for MD5C.C */

/* Copyright (C) 1991, RSA Data Security, Inc. All rights reserved.

   License to copy and use this software is granted provided that it
   is identified as the "RSA Data Security, Inc. MD5 Message-Digest
   Algorithm" in all material mentioning or referencing this software
   or this function.

   License is also granted to make and use derivative works provided
   that such works are identified as "derived from the RSA Data
   Security, Inc. MD5 Message-Digest Algorithm" in all material
   mentioning or referencing the derived work.  
                                                                    
   RSA Data Security, Inc. makes no representations concerning either
   the merchantability of this software or the suitability of this
   software for any particular purpose. It is provided "as is"
   without express or implied warranty of any kind.  
                                                                    
   These notices must be retained in any copies of any part of this
   documentation and/or software.  
 */

/* POINTER defines a generic pointer type */
typedef unsigned char *POINTER;

/* UINT2 defines a two byte word */
typedef unsigned short int UINT2;

/* UINT4 defines a four byte word */
#ifdef __alpha
typedef unsigned int UINT4;
#else
typedef unsigned long int UINT4;
#endif

/* MD5 context. */
typedef struct {
  UINT4 state[4];                                           /* state (ABCD) */
  UINT4 count[2];                /* number of bits, modulo 2^64 (lsb first) */
  unsigned char buffer[64];                                 /* input buffer */
} MD5_CTX;

OmniFoundation_EXTERN void MD5Init(MD5_CTX *);
OmniFoundation_EXTERN void MD5Update(MD5_CTX *, const unsigned char *, unsigned int);
OmniFoundation_EXTERN void MD5Final(unsigned char [16], MD5_CTX *);
