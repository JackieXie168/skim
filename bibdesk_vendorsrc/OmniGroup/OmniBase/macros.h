// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/macros.h,v 1.21 2003/01/15 22:51:47 kc Exp $

#import <Foundation/NSAutoreleasePool.h>
#import <OmniBase/SystemType.h>

#if !defined(SWAP)
#define SWAP(A, B) do { __typeof__(A) __temp = (A); (A) = (B); (B) = __temp;} while(0)
#endif

// On Solaris, when _TS_ERRNO is defined <errno.h> defines errno as the thread-safe ___errno() function.
// On NT, errno is defined to be '(*_errno())' and presumably this function is also thread safe.
// On MacOS X, errno is defined to be '(*__error())', which is also presumably thread safe. 

#import <errno.h>
#define OMNI_ERRNO() errno


// It might be good to put some exception handling in this.

#define OMNI_POOL_START				\
do {						\
    NSAutoreleasePool *__pool;			\
    __pool = [[NSAutoreleasePool alloc] init];	\
    {

#define OMNI_POOL_END	\
    }			\
    [__pool release];	\
} while(0)

// This reraise() works in an NS_DURING block and can handle both old-style and new-style exceptions.

#ifndef sun // OpenStep/Solaris doesn't need this.
#define NS_RERAISE() _NXRaiseError(_localHandler.code, \
			_localHandler.data1, _localHandler.data2)
#endif
