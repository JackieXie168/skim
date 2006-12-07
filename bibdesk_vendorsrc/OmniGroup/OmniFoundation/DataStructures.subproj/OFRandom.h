// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFRandom.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>
#import <OmniFoundation/FrameworkDefines.h>

// Some platforms don't provide random number generation and of those that do, there are many different variants.  We provide a common random number generator rather than have to deal with each platform independently.  Additionally, we allow the user to maintain several random number generators.

typedef struct {
    unsigned long y; // current value any number between zero and M-1
} OFRandomState;

OmniFoundation_EXTERN float OFRandomMax;

OmniFoundation_EXTERN unsigned int OFRandomGenerateRandomSeed(void);	// returns a random number (generated from /dev/urandom if possible, otherwise generated via clock information) for use as a seed value for OFRandomSeed().
OmniFoundation_EXTERN void OFRandomSeed(OFRandomState *state, unsigned long y);
OmniFoundation_EXTERN unsigned long OFRandomNextState(OFRandomState *state);

OmniFoundation_EXTERN unsigned long OFRandomNext(void);	// returns a random number generated using a default, shared random state.
OmniFoundation_EXTERN float OFRandomGaussState(OFRandomState *state);

static inline float OFRandomFloat(OFRandomState *state)
/*.doc.
Returns a number in the range [0..1]
*/
{
    return (float)OFRandomNextState(state)/(float)OFRandomMax;
}

#define OF_RANDOM_MAX OFRandomMax // For backwards compatibility
