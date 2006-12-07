// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Locks.subproj/OFSimpleLock.h 68913 2005-10-03 19:36:19Z kc $

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
