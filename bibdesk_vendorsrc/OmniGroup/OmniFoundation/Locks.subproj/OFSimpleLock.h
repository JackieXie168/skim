// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Locks.subproj/OFSimpleLock.h,v 1.8 2003/01/15 22:51:58 kc Exp $

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
