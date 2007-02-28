// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniBase/macros.h 79079 2006-09-07 22:35:32Z kc $

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

#define OMNI_POOL_START				\
do {						\
    NSAutoreleasePool *__pool;			\
    __pool = [[NSAutoreleasePool alloc] init];	\
    @try {

#define OMNI_POOL_END \
    } @catch (NSException *__exc) { \
	[__exc retain]; \
	[__pool release]; \
	__pool = nil; \
	[__exc autorelease]; \
	[__exc raise]; \
    } @finally { \
	[__pool release]; \
    } \
} while(0)
