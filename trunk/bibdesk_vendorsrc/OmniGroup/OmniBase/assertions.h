// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniBase/assertions.h 68913 2005-10-03 19:36:19Z kc $

#ifndef _OmniBase_assertions_h_
#define _OmniBase_assertions_h_

#import <OmniBase/FrameworkDefines.h>
#import <objc/objc.h>

#if defined(DEBUG) || defined(OMNI_FORCE_ASSERTIONS)
#define OMNI_ASSERTIONS_ON
#endif

// This allows you to turn off assertions when debugging
#if defined(OMNI_FORCE_ASSERTIONS_OFF)
#undef OMNI_ASSERTIONS_ON
#warning Forcing assertions off!
#endif


// Make sure that we don't accidentally use the ASSERT macro instead of OBASSERT
#ifdef ASSERT
#undef ASSERT
#endif

typedef void (*OBAssertionFailureHandler)(const char *type, const char *expression, const char *file, unsigned int lineNumber);

#if defined(OMNI_ASSERTIONS_ON)

    OmniBase_EXTERN void OBSetAssertionFailureHandler(OBAssertionFailureHandler handler);

    OmniBase_EXTERN void OBAssertFailed(const char *type, const char *expression, const char *file, unsigned int lineNumber);


    #define OBPRECONDITION(expression)                                            \
    do {                                                                        \
        if (!(expression))                                                      \
            OBAssertFailed("PRECONDITION", #expression, __FILE__, __LINE__);    \
    } while (NO)

    #define OBPOSTCONDITION(expression)                                           \
    do {                                                                        \
        if (!(expression))                                                      \
            OBAssertFailed("POSTCONDITION", #expression, __FILE__, __LINE__);   \
    } while (NO)

    #define OBINVARIANT(expression)                                               \
    do {                                                                        \
        if (!(expression))                                                      \
            OBAssertFailed("INVARIANT", #expression, __FILE__, __LINE__);       \
    } while (NO)

    #define OBASSERT(expression)                                                  \
    do {                                                                        \
        if (!(expression))                                                      \
            OBAssertFailed("ASSERT", #expression, __FILE__, __LINE__);          \
    } while (NO)

    #define OBASSERT_NOT_REACHED(reason)                                        \
    do {                                                                        \
        OBAssertFailed("NOTREACHED", reason, __FILE__, __LINE__);              \
    } while (NO)


#else	// else insert blank lines into the code

    #define OBPRECONDITION(expression)
    #define OBPOSTCONDITION(expression)
    #define OBINVARIANT(expression)
    #define OBASSERT(expression)
    #define OBASSERT_NOT_REACHED(reason)

#endif


#endif // _OmniBase_assertions_h_
