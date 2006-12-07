// Copyright 2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OAUtilities.h 68950 2005-10-03 21:53:41Z kc $

#ifdef __ppc__

// Vanilla PPC code, but since PPC has a reciprocal square root estimate instruction,
// runs *much* faster than calling sqrt().  We'll use one Newton-Raphson
// refinement step to get bunch more precision in the 1/sqrt() value for very little cost.
// it returns fairly accurate results (error below 1.0e-5 up to 100000.0 in 0.1 increments).

// added -force_cpusubtype_ALL to get this to compile
static inline float OAFastReciprocalSquareRoot(float x)
{
    const float half = 0.5;
    const float one  = 1.0;
    float B, y0, y1;
    
    // This'll NaN if it hits frsqrte.  Handle both +0.0 and -0.0
    if (fabs(x) == 0.0)
        return x;
        
    B = x;
    asm("frsqrte %0,%1" : "=f" (y0) : "f" (B));

    /* First refinement step */
    y1 = y0 + half*y0*(one - B*y0*y0);

    return y1;
}

#else

#import <math.h>

static inline float OAFastReciprocalSquareRoot(float x)
{
    return 1.0f / sqrtf(x);
}

#endif
