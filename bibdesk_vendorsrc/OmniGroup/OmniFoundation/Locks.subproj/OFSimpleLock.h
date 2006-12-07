// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Locks.subproj/OFSimpleLock.h,v 1.10 2004/02/10 04:07:45 kc Exp $

#ifdef __ppc__
#import <OmniFoundation/OFSimpleLock-ppc.h>
#endif

#ifdef __i386__
#import <OmniFoundation/OFSimpleLock-i386.h>
#endif

#ifdef __sparc__
#import <OmniFoundation/OFSimpleLock-sparc.h>
#endif

#ifdef __hppa__
#import <OmniFoundation/OFSimpleLock-hppa.h>
#endif


#ifndef OFSimpleLockDefined
#import <OmniFoundation/OFSimpleLock-pthreads.h>
#endif
